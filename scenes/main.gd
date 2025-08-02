extends HBoxContainer

@onready var pop_ui: CanvasLayer = $PopUI
var popup = preload("res://scenes/ReadingPopup.tscn").instantiate()


func _ready():
	#$PanelContainer/SubViewportContainer/SubViewport.world_2d = get_world_2d()
	#$PanelContainer/SubViewportContainer/SubViewport = $"PanelContainer/S_相机遮挡抖动".texture
	pass

func _on_l_btn滚动星空_pressed() -> void:
	$"PanelContainer/BG_滚动星空".visible = true
	popup.file_path = "res://docs/滚动星空.md"
	pop_ui.add_child(popup)
	popup.show_popup()

	
