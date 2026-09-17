extends CharacterBody2D
## 演示用的可操作角色（从「精灵拖影」场景克隆而来）
##
## 作用：让你可以沿着铺满粒子特效的路面走过去，逐个观察每个特效。
## 操作：
##   ←/→ (A/D) 左右移动
##   空格         跳跃
##   F            冲刺
##   Esc          返回主菜单
##
## 动画通过 AnimationPlayer 播放 idle / run / jump / fall 四段。

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

# 移动参数
@export var max_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# 跳跃参数
@export var jump_velocity: float = -400.0

# 冲刺参数
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.2

var can_dash: bool = true
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

# 引擎默认重力
var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))


func _physics_process(delta: float) -> void:
	if not is_dashing:
		# 重力
		if not is_on_floor():
			velocity.y += gravity * delta

		# 跳跃
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity

		var input_direction := Input.get_axis("ui_left", "ui_right")

		# 水平加速 / 减速
		if input_direction != 0:
			velocity.x = move_toward(velocity.x, input_direction * max_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

		# 冲刺
		if Input.is_action_just_pressed("dash") and can_dash:
			start_dash(input_direction)
	else:
		dash_timer -= delta
		if dash_timer <= 0.0:
			end_dash()

	update_animation()
	move_and_slide()


func start_dash(input_direction: float) -> void:
	if input_direction != 0:
		dash_direction = Vector2(input_direction, 0.0)
	else:
		dash_direction = Vector2(1.0 if sprite_2d.flip_h else -1.0, 0.0)

	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	velocity = dash_direction * dash_speed

	# 冲刺时跳过瓦片碰撞，方便快速穿过整条路
	set_collision_mask_value(1, false)


func end_dash() -> void:
	is_dashing = false
	velocity.x *= 0.5

	set_collision_mask_value(1, true)

	# 冲刺冷却
	await get_tree().create_timer(0.5).timeout
	can_dash = true


func update_animation() -> void:
	if is_dashing:
		return

	if is_on_floor():
		_play("run" if absf(velocity.x) > 10.0 else "idle")
	else:
		_play("jump" if velocity.y < 0.0 else "fall")

	# 朝向
	if velocity.x > 0.0:
		sprite_2d.flip_h = false
	elif velocity.x < 0.0:
		sprite_2d.flip_h = true


## 只在动画切换时才 play()，否则每帧重新播放会把动画卡在第一帧
func _play(name: StringName) -> void:
	if animation_player.current_animation != name:
		animation_player.play(name)
