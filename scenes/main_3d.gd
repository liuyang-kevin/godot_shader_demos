extends Node3D
@onready var proto_controller: CharacterBody3D = $ProtoController
@onready var label_4_input_hint: Label3D = $ProtoController/Label4InputHint
@export var camera: Camera3D  # 假设摄像机在ProtoController下

# 添加一个标志来跟踪是否已经隐藏了提示
var hint_hidden = false

# 用于跟踪当前注视的对象
var current_lookat_target: StaticBody3D = null
var lookat_label: Label3D = null

# 存储所有可交互标签的引用
var interactive_labels: Array = []

# 调试相关变量
@export var debug_enabled: bool = true  # 是否启用调试模式
var debug_ray: MeshInstance3D  # 用于可视化射线的网格实例
var debug_hit_point: MeshInstance3D  # 用于可视化击中点的网格实例

# 游戏暂停状态
var game_paused: bool = false

func _ready() -> void:
	# 设置鼠标模式为捕获，确保进入场景时鼠标被隐藏并限制在窗口内
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# 延迟一帧后模拟鼠标点击
	call_deferred("simulate_mouse_click")
	
	# 查找场景中所有可交互的标签
	find_interactive_labels()
	
	# 初始化调试可视化
	if debug_enabled:
		init_debug_visuals()
	
func find_interactive_labels():
	# 获取所有属于"interactive_labels"组的Label3D节点
	var label_nodes = get_tree().get_nodes_in_group("interactive_labels")
	print("找到 ", label_nodes.size(), " 个可交互标签节点")
	
	for label in label_nodes:
		if label is Label3D:
			# 查找标签下的StaticBody3D
			var static_body = find_child_by_type(label, "StaticBody3D")
			
			if static_body:
				interactive_labels.append({
					"body": static_body,
					"label": label,
					"original_modulate": label.modulate  # 保存原始颜色
				})
				print("添加可交互标签: ", label.text, " (节点: ", label.name, ")")
			else:
				print("警告: 标签 '", label.name, "' 缺少 StaticBody3D 子节点")
		else:
			print("警告: 组 'interactive_labels' 中的节点不是 Label3D: ", label.name)

# 辅助函数：查找指定类型的子节点
func find_child_by_type(node: Node, type: String) -> Node:
	for child in node.get_children():
		if child.get_class() == type:
			return child
	return null

# 初始化调试可视化
func init_debug_visuals():
	# 创建射线可视化
	var cylinder = CylinderMesh.new()
	cylinder.set_top_radius(0.01)
	cylinder.set_bottom_radius(0.01)
	cylinder.set_height(1.0)
	
	debug_ray = MeshInstance3D.new()
	debug_ray.mesh = cylinder
	debug_ray.material_override = StandardMaterial3D.new()
	debug_ray.material_override.albedo_color = Color(1, 0, 0, 0.5)  # 红色半透明
	add_child(debug_ray)
	
	# 创建击中点可视化
	var sphere = SphereMesh.new()
	sphere.set_radius(0.05)
	sphere.height = 0.1
	
	debug_hit_point = MeshInstance3D.new()
	debug_hit_point.mesh = sphere
	debug_hit_point.material_override = StandardMaterial3D.new()
	debug_hit_point.material_override.albedo_color = Color(0, 1, 0, 0.8)  # 绿色
	add_child(debug_hit_point)
	
	print("调试可视化已初始化")

func _process(delta: float) -> void:
	# 如果游戏暂停，不进行射线检测
	if game_paused:
		return
		
	# 每帧进行射线检测，检测玩家正在观看的对象
	perform_raycast()

func perform_raycast() -> void:
	# 从摄像机位置向前发射射线
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 10.0
	
	# 更新调试射线可视化
	if debug_enabled:
		update_debug_ray(from, to)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [proto_controller]  # 排除玩家自身
	
	var result = space_state.intersect_ray(query)
	
	# 检查是否击中了任何可交互标签
	if result:
		if debug_enabled:
			# 更新击中点可视化
			debug_hit_point.global_position = result.position
			debug_hit_point.visible = true
			print("射线击中: ", result.collider.name, " 位置: ", result.position)
		
		var collider = result.collider
		# 检查是否击中了可交互标签的碰撞体
		for item in interactive_labels:
			if collider == item.body:
				# 玩家正在注视标签
				if current_lookat_target != item.body:
					on_lookat_start(item)
				current_lookat_target = item.body
				lookat_label = item.label
				return
			else:
				if debug_enabled:
					print("击中的对象不是可交互标签: ", collider.name, " 类型: ", collider.get_class())
	else:
		if debug_enabled:
			debug_hit_point.visible = false
			print("射线未击中任何对象")
	
	# 如果没有击中任何可交互标签
	if current_lookat_target:
		on_lookat_end()

# 更新调试射线可视化 - 修复方向问题
func update_debug_ray(from: Vector3, to: Vector3):
	var direction = to - from
	var distance = direction.length()
	
	if distance > 0:
		var mid_point = from + direction * 0.5
		
		debug_ray.global_position = mid_point
		
		# 正确设置圆柱体的方向和缩放
		debug_ray.rotation = Vector3.ZERO
		debug_ray.look_at(to, Vector3.UP if abs(direction.y) < 0.9 else Vector3.FORWARD)
		
		# 圆柱体默认沿Y轴，所以需要旋转90度使其沿Z轴
		debug_ray.rotate_object_local(Vector3.RIGHT, PI/2)
		
		# 设置缩放
		debug_ray.scale = Vector3(1, distance, 1)
		debug_ray.visible = true

func on_lookat_start(item: Dictionary) -> void:
	# 当开始注视标签时调用
	print("开始注视标签: ", item.label.text)
	# 高亮标签 - 改变颜色
	item.label.modulate = Color(1, 1, 0.5)  # 浅黄色高亮
	
	# 如果有全局提示标签，显示相关信息
	if label_4_input_hint and not hint_hidden:
		label_4_input_hint.text = "按左键与 '" + item.label.text + "' 交互"
		label_4_input_hint.visible = true

func on_lookat_end() -> void:
	# 当停止注视标签时调用
	if current_lookat_target:
		print("停止注视标签")
		# 恢复所有标签的原始颜色
		for item in interactive_labels:
			item.label.modulate = item.original_modulate
		
		# 隐藏全局提示
		if label_4_input_hint and not hint_hidden:
			label_4_input_hint.visible = false
		
		current_lookat_target = null
		lookat_label = null

# 暂停游戏
func pause_game():
	game_paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# 暂停物理处理和输入处理
	get_tree().paused = true
	print("游戏已暂停")

# 恢复游戏
func resume_game():
	game_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# 恢复物理处理和输入处理
	get_tree().paused = false
	print("游戏已恢复")

func _input(event):
	# 处理游戏暂停/恢复的输入
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			if game_paused:
				resume_game()
			else:
				pause_game()
			return
			
		if event.keycode == KEY_ESCAPE:
			if game_paused:
				resume_game()  # 先恢复游戏，再退出
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # 把鼠标显示出来, 不然回去2d场景, 鼠标一直隐藏了
			get_tree().change_scene_to_file("res://scenes/main.tscn")
			return
	
	# 如果游戏暂停，不处理其他输入
	if game_paused:
		return
		
	if event is InputEventKey:
		# 检测左右移动键是否被按下
		if not hint_hidden and (
			event.keycode == KEY_A or event.keycode == KEY_D or 
			event.keycode == KEY_W or event.keycode == KEY_S or 
			event.keycode == KEY_LEFT or event.keycode == KEY_RIGHT
			) and event.pressed:
			hide_input_hint()
		
		# 添加调试快捷键
		elif event.keycode == KEY_F1 and event.pressed:
			debug_enabled = !debug_enabled
			if debug_enabled:
				print("调试模式已启用")
				if not debug_ray:
					init_debug_visuals()
				debug_ray.visible = true
			else:
				print("调试模式已禁用")
				if debug_ray:
					debug_ray.visible = false
					debug_hit_point.visible = false
	
	# 检测鼠标点击事件
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_lookat_target and lookat_label:
			on_label_clicked(lookat_label)
		elif debug_enabled:
			print("点击时未注视任何标签")

func on_label_clicked(label: Label3D) -> void:
	# 当点击标签时调用
	print("标签被点击: ", label.text)
	
	# 根据标签文本执行不同的操作
	match label.text:
		"标签1":
			print("执行标签1的操作")
			# 在这里添加标签1的特定操作
		"标签2":
			print("执行标签2的操作")
			# 在这里添加标签2的特定操作
		"标签3":
			print("执行标签3的操作")
			# 在这里添加标签3的特定操作
		_:
			print("执行默认操作")
			# 默认操作

# 隐藏输入提示的函数
func hide_input_hint():
	if label_4_input_hint and not hint_hidden:
		label_4_input_hint.visible = false
		hint_hidden = true
		print("输入提示已隐藏") # 可选：用于调试

# 模拟鼠标点击的函数
func simulate_mouse_click():
	# 创建鼠标按下事件
	var mouse_press = InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	mouse_press.position = get_viewport().get_visible_rect().size / 2
	
	# 创建鼠标释放事件
	var mouse_release = InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	mouse_release.position = get_viewport().get_visible_rect().size / 2
	
	# 发送事件
	Input.parse_input_event(mouse_press)
	# 稍等一小段时间再发送释放事件
	await get_tree().create_timer(0.05).timeout
	Input.parse_input_event(mouse_release)
	
	print("模拟鼠标点击完成")

func _notification(what):
	match what:
		NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			# 窗口失去焦点时，可选操作，例如暂停游戏或显示鼠标
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NOTIFICATION_WM_WINDOW_FOCUS_IN:
			# 窗口获得焦点时，重新捕获鼠标（可根据游戏状态添加条件判断）
			if get_tree().paused == false: # 假设只在游戏未暂停时重新捕获
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
