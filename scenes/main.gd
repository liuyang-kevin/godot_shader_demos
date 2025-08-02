extends HBoxContainer

@onready var pop_ui: CanvasLayer = $PopUI
var popup = preload("res://scenes/ReadingPopup.tscn").instantiate()


func _on_l_btn滚动星空_pressed() -> void:
	$"PanelContainer/BG_滚动星空".visible = true
	popup.file_path = "res://docs/滚动星空.md"
	pop_ui.add_child(popup)
	popup.show_popup()

	


func _on_goto3d_button_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/main_3d.tscn')
