class_name AfterimageTrail
extends Node2D

@export_node_path("Node2D") var source_path: NodePath
@export_node_path("Node2D") var parent_source_path: NodePath
@export var life := 0.3                  # 每个残影生存时间
@export var emit_interval := 0.05        # 残影生成间隔
@export var trail_length := 10           # 历史缓存长度
@export var initial_color := Color(1, 1, 1, 0.8)
@export var use_additive := true         # 是否用加色混合
@export var z_index_offset := -1         # 残影层级偏移

# 纹理过滤模式枚举
enum GhostTextureFilterMode {
	FILTER_PARENT,    # 继承父节点的过滤模式
	FILTER_NEAREST,   # 最近邻过滤（像素化）
	FILTER_LINEAR,    # 线性过滤（平滑）
}

@export var ghost_texture_filter: GhostTextureFilterMode = GhostTextureFilterMode.FILTER_PARENT

# Shader 相关属性
@export var use_custom_shader: bool = false
@export var shader_material: ShaderMaterial

var _src: Node2D
var _parent_node: Node2D
var _time_accum := 0.0
var _history: Array = []
var _ghost_parent: Node
var _additive_material: CanvasItemMaterial  # 共享材质实例
var _default_shader_material: ShaderMaterial  # 默认着色器材质

# 对象池相关变量
var _ghost_pool: Array = []
var _max_pool_size := 15

func _ready():
	_src = get_node_or_null(source_path)
	_parent_node = get_node_or_null(parent_source_path)
	assert(_src != null, "AfterimageTrail: source_path 无效，必须指向 Sprite2D 或 AnimatedSprite2D")
	
	# 将残影父节点设置为场景根节点
	if _parent_node:
		_ghost_parent = _parent_node
	else:
		_ghost_parent = get_tree().current_scene
	
	# 预创建材质（如果使用加色混合）
	if use_additive:
		_additive_material = CanvasItemMaterial.new()
		_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	# 创建默认着色器材质
	_create_default_shader_material()
	
	# 预创建一些残影对象到对象池
	for i in range(5):
		var ghost = _create_ghost()
		_ghost_pool.append(ghost)

func _create_default_shader_material():
	# 创建一个默认的着色器，提供丰富的拖影效果
	var shader_code = """
	shader_type canvas_item;

	uniform float time_offset : hint_range(0, 1) = 0.0;
	uniform vec4 base_color : source_color = vec4(1.0);
	uniform float distortion_strength : hint_range(0, 0.1) = 0.02;
	uniform float color_shift_speed : hint_range(0, 5) = 1.0;
	uniform float wave_frequency : hint_range(0, 20) = 5.0;
	uniform float wave_amplitude : hint_range(0, 0.1) = 0.02;

	void fragment() {
		// 时间计算
		float time = TIME * color_shift_speed + time_offset * 10.0;
		
		// 创建扭曲效果
		vec2 distorted_uv = UV;
		distorted_uv.x += sin(UV.y * wave_frequency + time) * wave_amplitude;
		distorted_uv.y += cos(UV.x * wave_frequency + time) * wave_amplitude;
		
		// 采样纹理
		vec4 tex_color = texture(TEXTURE, distorted_uv);
		
		// 颜色偏移效果
		vec4 shifted_color = tex_color;
		shifted_color.r = texture(TEXTURE, distorted_uv + vec2(distortion_strength * sin(time), 0.0)).r;
		shifted_color.g = texture(TEXTURE, distorted_uv + vec2(distortion_strength * cos(time * 0.7), 0.0)).g;
		shifted_color.b = texture(TEXTURE, distorted_uv + vec2(distortion_strength * sin(time * 1.3), 0.0)).b;
		
		// 应用基础颜色和透明度
		COLOR = shifted_color * base_color;
		
		// 添加发光效果
		COLOR.rgb += vec3(0.1) * (sin(time * 2.0) * 0.5 + 0.5);
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	_default_shader_material = ShaderMaterial.new()
	_default_shader_material.shader = shader
	_default_shader_material.set_shader_parameter("base_color", initial_color)
	_default_shader_material.set_shader_parameter("time_offset", 0.0)
	_default_shader_material.set_shader_parameter("distortion_strength", 0.02)
	_default_shader_material.set_shader_parameter("color_shift_speed", 1.0)
	_default_shader_material.set_shader_parameter("wave_frequency", 5.0)
	_default_shader_material.set_shader_parameter("wave_amplitude", 0.02)

func _process(delta: float) -> void:
	if _src == null or not _src.is_visible_in_tree():
		return

	# 更新计时器
	_time_accum += delta
	
	# 每当达到生成间隔时创建残影
	if _time_accum >= emit_interval:
		_time_accum = 0.0
		
		# 记录当前状态
		var state := {
			"pos": _src.global_position,
			"rot": _src.global_rotation,
			"scale": _src.global_scale,
			"type": _src.get_class(),
		}

		# 根据源节点类型记录特定属性
		if _src is AnimatedSprite2D:
			state["frames"] = _src.sprite_frames
			state["anim"] = _src.animation
			state["frame"] = _src.frame
			state["progress"] = _src.frame_progress
		elif _src is Sprite2D:
			state["tex"] = _src.texture
			state["region_enabled"] = _src.region_enabled
			if _src.region_enabled:
				state["region_rect"] = _src.region_rect
			state["hframes"] = _src.hframes
			state["vframes"] = _src.vframes
			state["frame"] = _src.frame
			state["frame_coords"] = _src.frame_coords
			state["centered"] = _src.centered
			state["flip_h"] = _src.flip_h
			state["flip_v"] = _src.flip_v

		# 添加到历史记录
		_history.push_front(state)
		
		# 保持历史记录长度
		if _history.size() > trail_length:
			_history.pop_back()
		
		# 生成残影
		_spawn_ghost(state)

func _create_ghost() -> Sprite2D:
	var ghost := Sprite2D.new()
	ghost.z_as_relative = false
	
	if use_additive and _additive_material:
		ghost.material = _additive_material
	
	return ghost

func _spawn_ghost(state: Dictionary) -> void:
	var ghost: Sprite2D
	
	# 从对象池获取或创建新的残影
	if _ghost_pool.size() > 0:
		ghost = _ghost_pool.pop_back()
	else:
		ghost = _create_ghost()
	
	# 设置残影属性
	ghost.global_position = state["pos"]
	ghost.global_rotation = state["rot"]
	ghost.scale = state["scale"]
	ghost.modulate = initial_color
	ghost.z_index = (_src.z_index + z_index_offset)
	
	# 设置纹理过滤模式
	match ghost_texture_filter:
		GhostTextureFilterMode.FILTER_PARENT:
			# 继承源节点的过滤模式
			if _src is CanvasItem:
				ghost.texture_filter = _src.texture_filter
		GhostTextureFilterMode.FILTER_NEAREST:
			ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		GhostTextureFilterMode.FILTER_LINEAR:
			ghost.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	# 设置纹理和动画状态
	if state["type"] == "AnimatedSprite2D":
		if state["frames"] and state["frames"].has_animation(state["anim"]):
			ghost.texture = state["frames"].get_frame_texture(state["anim"], state["frame"])
	elif state["type"] == "Sprite2D":
		ghost.texture = state["tex"]
		ghost.region_enabled = state["region_enabled"]
		if state["region_enabled"]:
			ghost.region_rect = state["region_rect"]
		ghost.hframes = state["hframes"]
		ghost.vframes = state["vframes"]
		ghost.frame = state["frame"]
		ghost.frame_coords = state["frame_coords"]
		ghost.centered = state["centered"]
		ghost.flip_h = state["flip_h"]
		ghost.flip_v = state["flip_v"]
	
	# 应用着色器材质
	if use_custom_shader:
		if shader_material:
			# 使用自定义着色器材质
			ghost.material = shader_material.duplicate()
		else:
			# 使用默认着色器材质
			var material = _default_shader_material.duplicate()
			# 设置时间偏移，使每个残影有不同的效果
			material.set_shader_parameter("time_offset", randf())
			ghost.material = material
	elif use_additive and _additive_material:
		# 使用加色混合材质
		ghost.material = _additive_material
	
	# 添加到场景
	_ghost_parent.add_child(ghost)
	
	# 使用Tween淡出
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "modulate:a", 0.0, life)
	tw.tween_callback(_recycle_ghost.bind(ghost))

func _recycle_ghost(ghost: Sprite2D) -> void:
	# 从场景中移除
	if is_instance_valid(ghost) and ghost.is_inside_tree():
		ghost.get_parent().remove_child(ghost)
	
	# 如果对象池未满，则回收利用
	if _ghost_pool.size() < _max_pool_size:
		_ghost_pool.append(ghost)
	else:
		# 对象池已满，直接释放
		ghost.queue_free()

# 清理函数
func _exit_tree():
	# 清理对象池
	for ghost in _ghost_pool:
		if is_instance_valid(ghost):
			ghost.queue_free()
	_ghost_pool.clear()
