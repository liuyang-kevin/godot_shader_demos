class_name AfterimageTrail
extends Node2D

@export_node_path("Node2D") var source_path: NodePath
@export var life := 0.3                  # 每个残影生存时间
@export var emit_interval := 0.05        # 残影生成间隔
@export var trail_length := 6            # 历史缓存长度
@export var initial_color := Color(1, 1, 1, 0.8)
@export var use_additive := true         # 是否用加色混合
@export var z_index_offset := -1         # 残影层级偏移

var _src: Node2D
var _time_accum := 0.0
var _history: Array = []

func _ready():
	_src = get_node_or_null(source_path)
	assert(_src != null, "AfterimageTrail: source_path 无效，必须指向 Sprite2D 或 AnimatedSprite2D")

func _process(delta: float) -> void:
	if _src == null or not _src.is_visible_in_tree():
		return

	# 记录历史状态
	var state := {
		"pos": _src.global_position,
		"rot": _src.global_rotation,
		"scale": _src.global_scale,
		"type": _src.get_class(),
	}

	if _src is AnimatedSprite2D:
		state["frames"] = _src.sprite_frames
		state["anim"] = _src.animation
		state["frame"] = _src.frame
	elif _src is Sprite2D:
		state["tex"] = _src.texture
		state["region_enabled"] = _src.region_enabled
		state["region_rect"] = _src.region_rect
		state["hframes"] = _src.hframes
		state["vframes"] = _src.vframes
		state["frame"] = _src.frame
		state["frame_coords"] = _src.frame_coords
		state["centered"] = _src.centered

	_history.push_front(state)

	# 保持队列长度
	if _history.size() > trail_length:
		_time_accum += delta
		if _time_accum >= emit_interval:
			_time_accum = 0.0
			var old_state = _history.pop_back()
			_spawn_ghost(old_state)

func _spawn_ghost(state: Dictionary) -> void:
	var ghost := Sprite2D.new()
	ghost.position = state["pos"]
	ghost.rotation = state["rot"]
	ghost.scale = state["scale"]
	ghost.modulate = initial_color
	ghost.z_index = (_src.z_index + z_index_offset)

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


		ghost.position = to_local(state["pos"])
		ghost.rotation = _src.global_rotation
		ghost.scale = _src.global_scale


	if use_additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		ghost.material = mat

	add_child(ghost)

	# Tween 淡出并删除
	var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ghost, "modulate:a", 0.0, life)
	tw.tween_callback(ghost.queue_free)
