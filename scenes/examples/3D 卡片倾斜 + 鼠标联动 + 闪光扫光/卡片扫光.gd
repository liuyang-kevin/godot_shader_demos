extends Node2D

@onready var sprite := $Sprite2D

func _ready():
	# 初始化 Shader 全局参数
	RenderingServer.global_shader_parameter_set("mouse_screen_pos", Vector2.ZERO)

func _process(_delta):
	# 获取鼠标在屏幕上的位置
	var mouse_pos = get_viewport().get_mouse_position()
	# 更新全局 uniform
	RenderingServer.global_shader_parameter_set("mouse_screen_pos", mouse_pos)
