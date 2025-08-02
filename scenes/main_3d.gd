extends Node3D
@onready var proto_controller: CharacterBody3D = $ProtoController

func _ready() -> void:
	pass

func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # 把鼠标显示出来, 不然回去2d场景, 鼠标一直隐藏了
			get_tree().change_scene_to_file("res://scenes/main.tscn")
