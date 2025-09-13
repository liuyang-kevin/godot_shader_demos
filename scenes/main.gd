extends HBoxContainer

@onready var main: HBoxContainer = $"."
## 子场景展示区域
@onready var sub_viewport: SubViewport = $PanelContainer/SubViewportContainer/SubViewport
@onready var sub_viewport_container: SubViewportContainer = $PanelContainer/SubViewportContainer

@onready var pop_ui: CanvasLayer = $PopUI
var popup = preload("res://scenes/ReadingPopup.tscn").instantiate()

var is_subviewport_focused := false


# 存储当前加载的子场景
var current_subscene: Node = null
# 关闭按钮
var close_button: Button = null

func _ready():
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "关闭"
	close_button.hide()
	close_button.focus_mode = Control.FOCUS_CLICK # 只能鼠标点击, 不能根据焦点模式选中
	close_button.pressed.connect(_on_close_button_pressed)
	$Control/ScrollContainer/HFlowContainer.add_child(close_button)
	
	# 设置关闭按钮的位置（右上角）
	close_button.position = Vector2(sub_viewport_container.position.x + sub_viewport_container.size.x - 100, 10)

func _input(event: InputEvent) -> void:
	if is_subviewport_focused && event.is_action_pressed("ui_accept"): # 主动拦截输入, 防止ui冲突
		accept_event()



func _on_l_btn滚动星空_pressed() -> void:
	_invisibleAllShaderContainer()
	$"PanelContainer/BG_滚动星空".visible = true
	popup.file_path = "res://docs/滚动星空.md"
	pop_ui.add_child(popup)
	popup.show_popup()

func _on_goto3d_button_pressed() -> void:
	get_tree().change_scene_to_file('res://scenes/main_3d.tscn')

func _on_btn抖动dither_pressed():
	_invisibleAllShaderContainer()
	$"PanelContainer/S_抖动Dither".visible = true
	popup.file_path = "res://docs/抖动Dither.md"
	pop_ui.add_child(popup)
	popup.show_popup()

func _on_btn圣光_pressed():
	_invisibleAllShaderContainer()
	$"PanelContainer/圣光效果".visible = true

func _invisibleAllShaderContainer():
	for c in $"PanelContainer".get_children():
		if c is Control:
			c.visible = false
	# 也隐藏SubViewportContainer
	sub_viewport_container.visible = false
	# 隐藏关闭按钮
	close_button.hide()
	# 清理子场景
	_cleanup_subscene()

func _on_btn精灵拖影_pressed() -> void:
	_invisibleAllShaderContainer()
	is_subviewport_focused = true # 拦截UI操作锁
	# 显示SubViewportContainer
	sub_viewport_container.visible = true
	
	# 加载并显示精灵拖影场景
	var scene = load("res://scenes/examples/精灵拖影/精灵拖影.tscn")
	if scene:
		current_subscene = scene.instantiate()
		sub_viewport.add_child(current_subscene)
		
		# 设置SubViewport大小与场景匹配
		if current_subscene is Node2D:
			var scene_size = current_subscene.get_viewport_rect().size
			sub_viewport.size = scene_size
			sub_viewport_container.size = scene_size
			
		# 显示关闭按钮
		close_button.show()
	
	# 显示说明文档
	popup.file_path = "res://docs/精灵拖影.md"
	pop_ui.add_child(popup)
	popup.show_popup()

func _on_close_button_pressed():
	is_subviewport_focused = false # 释放 拦截UI操作锁
	# 隐藏SubViewportContainer
	sub_viewport_container.visible = false
	# 隐藏关闭按钮
	close_button.hide()
	# 清理子场景
	_cleanup_subscene()

func _cleanup_subscene():
	if current_subscene:
		# 从SubViewport中移除子场景
		sub_viewport.remove_child(current_subscene)
		# 释放子场景
		current_subscene.queue_free()
		current_subscene = null

# 确保在节点退出时清理资源
func _exit_tree():
	_cleanup_subscene()
	if close_button:
		close_button.queue_free()


func _on_btn树丛摇曳_pressed() -> void:
	_invisibleAllShaderContainer()
	is_subviewport_focused = true # 拦截UI操作锁
	# 显示SubViewportContainer
	sub_viewport_container.visible = true
	
	# 加载并显示精灵拖影场景
	var scene = load("res://scenes/examples/2D精灵_植物风吹摇摆/MainScene.tscn")
	if scene:
		current_subscene = scene.instantiate()
		sub_viewport.add_child(current_subscene)
		
		# 设置SubViewport大小与场景匹配
		if current_subscene is Node2D:
			var scene_size = current_subscene.get_viewport_rect().size
			sub_viewport.size = scene_size
			sub_viewport_container.size = scene_size
			
		# 显示关闭按钮
		close_button.show()
	
	# 显示说明文档
	popup.file_path = "res://docs/精灵摇曳.md"
	pop_ui.add_child(popup)
	popup.show_popup()


func _on_btn双色dither_pressed() -> void:
	_invisibleAllShaderContainer()
	$"PanelContainer/S_双色Dither".visible = true
	popup.file_path = "res://docs/双色Dither.md"
	pop_ui.add_child(popup)
	popup.show_popup()


func _on_btn_3d_pressed() -> void:
	_invisibleAllShaderContainer()
	is_subviewport_focused = true # 拦截UI操作锁
	sub_viewport_container.visible = true
	var scene = load("res://scenes/main_3d.tscn")
	if scene:
		current_subscene = scene.instantiate()
		sub_viewport.add_child(current_subscene)
		close_button.show()
