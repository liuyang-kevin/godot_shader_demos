extends Node3D

@onready var pop_ui: CanvasLayer = $PopUI
var popup = preload("res://scenes/ReadingPopup.tscn").instantiate()

# --- 绑定与导出 ---
@onready var proto_controller: CharacterBody3D = $ProtoController
@onready var label_4_input_hint: Label3D = $ProtoController/Label4InputHint
@export var camera: Camera3D              # 在 Inspector 里拖入你的 Camera3D
@export var use_screen_center: bool = true
@export var ray_distance: float = 20.0

# --- 状态 ---
var hint_hidden: bool = false
var current_lookat_target: StaticBody3D = null
var lookat_label: Label3D = null
var interactive_labels: Array = []

# --- 调试可视化 ---
@export var debug_enabled: bool = true
var debug_ray: MeshInstance3D = null
var debug_hit_point: MeshInstance3D = null
var debug_thickness: float = 0.02  # 圆柱半径

# --- 游戏状态 ---
var game_paused: bool = false

# --- 准星 UI ---
var crosshair: Label

func _ready() -> void:
	#process_mode = Node.PROCESS_MODE_ALWAYS  # 即使暂停也能收到输入
	# 捕获鼠标（游戏开始）
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# 延迟模拟一次点击（如果你需要在进入场景时触发点击）
	call_deferred("simulate_mouse_click")
	# 查找并缓存所有 interactive_labels 组内节点
	find_interactive_labels()
	# 初始化调试可视化（如果打开）
	if debug_enabled:
		init_debug_visuals()
	# 初始化准星 UI（无论 debug 是否开着都需要）
	init_crosshair()

# ---------- 查找交互标签 ----------
func find_interactive_labels() -> void:
	interactive_labels.clear()
	var label_nodes = get_tree().get_nodes_in_group("interactive_labels")
	for label in label_nodes:
		if label is Label3D:
			var static_body: StaticBody3D = null
			for child in label.get_children():
				if child is StaticBody3D:
					static_body = child
					break
			if static_body:
				interactive_labels.append({
					"body": static_body,
					"label": label,
					"original_modulate": label.modulate
				})
			else:
				push_warning("interactive Label3D '%s' 没有 StaticBody3D 子节点" % label.name)
		else:
			push_warning("组 'interactive_labels' 中有非 Label3D 节点: %s" % str(label))

# ---------- 调试可视化（圆柱 + 击中点） ----------
func init_debug_visuals() -> void:
	# 射线用圆柱（细长）
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = debug_thickness
	cylinder.bottom_radius = debug_thickness
	cylinder.height = 1.0
	cylinder.radial_segments = 8
	cylinder.rings = 1

	debug_ray = MeshInstance3D.new()
	debug_ray.mesh = cylinder
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)  # 红色
	debug_ray.material_override = mat
	debug_ray.visible = debug_enabled
	add_child(debug_ray)

	# 击中点用小球
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	debug_hit_point = MeshInstance3D.new()
	debug_hit_point.mesh = sphere
	var hit_mat = StandardMaterial3D.new()
	hit_mat.albedo_color = Color(0, 1, 0)  # 绿色
	debug_hit_point.material_override = hit_mat
	debug_hit_point.visible = false
	add_child(debug_hit_point)

	print("调试可视化已初始化")

# 把圆柱正确对齐到 from->to（Cylinder 本地轴为 +Y）
func update_debug_ray(from: Vector3, to: Vector3, hit: bool) -> void:
	if not debug_ray:
		return

	var dir = to - from
	var distance = dir.length()
	if distance <= 0.00001:
		debug_ray.visible = false
		if debug_hit_point:
			debug_hit_point.visible = false
		return

	var dirn = dir.normalized()
	var mid_point = from.lerp(to, 0.5)

	var up = Vector3.UP
	var dot = clamp(up.dot(dirn), -1.0, 1.0)
	var basis: Basis
	var axis = up.cross(dirn)
	if axis.length() < 1e-6:
		# 平行或反向
		if dot > 0.9999:
			basis = Basis()
		else:
			# 反向：绕 X 轴 180°
			var q_flip = Quaternion(Vector3(1, 0, 0), PI)
			basis = Basis(q_flip)
	else:
		var angle = acos(dot)
		var q = Quaternion(axis.normalized(), angle)
		basis = Basis(q)

	var t = Transform3D(basis, mid_point)
	debug_ray.global_transform = t
	# Cylinder 高度从 -0.5..+0.5，因此 scale.y = distance * 0.5
	debug_ray.scale = Vector3(1.0, distance * 0.5, 1.0)
	debug_ray.visible = debug_enabled

	# 更新击中点
	if debug_hit_point:
		if hit:
			debug_hit_point.global_position = to
			debug_hit_point.visible = true
		else:
			debug_hit_point.visible = false

# ---------- 准星（UI，始终存在） ----------
func init_crosshair() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "CrosshairCanvas"
	add_child(canvas)

	crosshair = Label.new()
	crosshair.text = "+"
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.add_theme_font_size_override("font_size", 32)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	canvas.add_child(crosshair)


# 更新准星的颜色/缩放（用于提示交互目标）
func update_crosshair_state(hit_interactive: bool) -> void:
	if not crosshair:
		return
	if hit_interactive:
		crosshair.add_theme_color_override("font_color", Color.YELLOW)
		crosshair.add_theme_font_size_override("font_size", 36) # 放大一点
	else:
		crosshair.add_theme_color_override("font_color", Color.WHITE)
		crosshair.add_theme_font_size_override("font_size", 32)

# ---------- 每帧射线检测 ----------
func _process(delta: float) -> void:
	if game_paused:
		return
	perform_raycast()

func perform_raycast() -> void:
	if camera == null:
		return

	# 屏幕点（中心或鼠标）
	var vp_rect = get_viewport().get_visible_rect()
	var screen_point = vp_rect.size * 0.5 if use_screen_center else get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(screen_point)
	var to = from + camera.project_ray_normal(screen_point) * ray_distance

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [proto_controller]  # 排除玩家自身

	var result: Dictionary = space_state.intersect_ray(query)

	# 默认将调试线画到 to；如果命中则画到命中点
	var draw_to = to
	var hit = false
	var hit_interactive = false

	if result and result.size() > 0:
		hit = true
		draw_to = result.position
		var collider = result.collider
		# 检查是否命中 interactive_labels 中的 body
		for item in interactive_labels:
			if collider == item["body"]:
				hit_interactive = true
				if current_lookat_target != item["body"]:
					on_lookat_start(item)
				current_lookat_target = item["body"]
				lookat_label = item["label"]
				break
		# 命中但不是交互目标
		if not hit_interactive and current_lookat_target:
			on_lookat_end()
	else:
		# 未命中任何东西
		if current_lookat_target:
			on_lookat_end()

	# 更新准星（始终存在）
	update_crosshair_state(hit_interactive)

	# 调试可视化（仅当 debug_enabled=true）
	if debug_enabled:
		update_debug_ray(from, draw_to, hit)

# ---------- 注视开始/结束处理 ----------
func on_lookat_start(item: Dictionary) -> void:
	# 高亮 Label3D（3D 标签）
	if item.has("label") and item["label"]:
		item["label"].modulate = Color(1, 1, 0.6)
	# 显示交互提示（如果没被手动隐藏）
	if label_4_input_hint and not hint_hidden:
		label_4_input_hint.text = "按左键与 '" + str(item["label"].text) + "' 交互"
		label_4_input_hint.visible = true

func on_lookat_end() -> void:
	if current_lookat_target:
		for item in interactive_labels:
			if item.has("label") and item["label"]:
				var orig = item.get("original_modulate", null)
				if orig != null:
					item["label"].modulate = orig
				else:
					item["label"].modulate = Color(1,1,1)
		if label_4_input_hint and not hint_hidden:
			label_4_input_hint.visible = false
		current_lookat_target = null
		lookat_label = null

# ---------- 点击与输入 ----------
func _input(event):
	# 暂停/恢复快捷键（Q）
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if game_paused:
				resume_game()
			else:
				pause_game()
			return

		# 调试开关 F1（在任何情况下切换 debug 可视化）
		if event.keycode == KEY_F1 and event.pressed:
			debug_enabled = !debug_enabled
			if debug_enabled:
				if not debug_ray:
					init_debug_visuals()
				debug_ray.visible = true
				if debug_hit_point:
					debug_hit_point.visible = false
				print("调试已启用")
			else:
				print("调试已禁用")
				if debug_ray:
					debug_ray.visible = false
				if debug_hit_point:
					debug_hit_point.visible = false

		# ESC：回到主场景（并确保鼠标可见）
		if event.keycode == KEY_ESCAPE and event.pressed:
			if game_paused:
				resume_game()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			# 你可以改成你项目的主场景路径
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			return

	# 如果游戏暂停，不处理其他输入
	if game_paused:
		return

	# 鼠标左键点击交互
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_lookat_target and lookat_label:
			on_label_clicked(lookat_label)
		else:
			# 如果未注视任何标签，可用于调试反馈
			if debug_enabled:
				print("点击时未注视任何标签")

func on_label_clicked(label: Label3D) -> void:
	print("标签被点击: ", label.text)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	popup.file_path = "res://docs/菲涅尔_Fresnel.md"
	pop_ui.add_child(popup)
	popup.show_popup()
	match label.text:
		"标签1":
			print("执行标签1的操作")
		"标签2":
			print("执行标签2的操作")
		"标签3":
			print("执行标签3的操作")
		_:
			print("执行默认操作: ", label.text)

# 隐藏输入提示
func hide_input_hint():
	if label_4_input_hint and not hint_hidden:
		label_4_input_hint.visible = false
		hint_hidden = true
		print("输入提示已隐藏")

# 模拟一次鼠标点击（用于一些场景自动触发）
func simulate_mouse_click() -> void:
	var mouse_press = InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	# 使用屏幕中心作为模拟点击位置
	mouse_press.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(mouse_press)

	var mouse_release = InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	mouse_release.position = get_viewport().get_visible_rect().size * 0.5
	# 给引擎一点时间再发释放事件
	await get_tree().create_timer(0.05).timeout
	Input.parse_input_event(mouse_release)
	print("模拟鼠标点击完成")

# 暂停与恢复
func pause_game():
	game_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#get_tree().paused = true
	print("游戏已暂停")

func resume_game():
	game_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#get_tree().paused = false
	print("游戏已恢复")

# 窗口焦点通知
func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if not get_tree().paused:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	
