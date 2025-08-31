extends ColorRect

# 着色器参数对应的控制条
var sliders = {}
var labels = {}

func _ready():
	# 创建着色器实例
	var shader_material = ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/stylized/圣光.gdshader") # 请替换为你的着色器路径
	material = shader_material
		
	# 创建控制面板
	create_control_panel()
	
	# 初始更新所有参数
	update_all_parameters()

func create_control_panel():
	# 创建垂直容器
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# 设置控制面板位置和大小，不充满全屏
	vbox.position = Vector2(20, 20)  # 固定在左上角，留一些边距
	vbox.size = Vector2(400, 650)    # 增加高度以容纳随机按钮
	
	# 添加背景面板，方便查看控制条
	var panel = Panel.new()
	panel.size = Vector2(400, 650)
	panel.self_modulate = Color(0, 0, 0, 0.7)  # 半透明黑色背景
	vbox.add_child(panel)
	
	# 在面板内创建另一个VBox用于内容
	var content_vbox = VBoxContainer.new()
	content_vbox.position = Vector2(10, 10)
	content_vbox.size = Vector2(380, 630)
	panel.add_child(content_vbox)
	
	# 添加标题
	var title = Label.new()
	title.text = "God Rays Shader Controls"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(title)
	
	# 添加分隔线
	var separator = HSeparator.new()
	content_vbox.add_child(separator)
	
	# 着色器参数配置
	var parameters = [
		{"name": "angle", "min": -3.14, "max": 3.14, "step": 0.01, "default": -0.3},
		{"name": "position", "min": -2.0, "max": 2.0, "step": 0.01, "default": -0.2},
		{"name": "spread", "min": 0.0, "max": 1.0, "step": 0.01, "default": 0.5},
		{"name": "cutoff", "min": -1.0, "max": 1.0, "step": 0.01, "default": 0.1},
		{"name": "falloff", "min": 0.0, "max": 1.0, "step": 0.01, "default": 0.2},
		{"name": "edge_fade", "min": 0.0, "max": 1.0, "step": 0.01, "default": 0.15},
		{"name": "speed", "min": 0.0, "max": 10.0, "step": 0.1, "default": 1.0},
		{"name": "ray1_density", "min": 1.0, "max": 100.0, "step": 1.0, "default": 8.0},
		{"name": "ray2_density", "min": 1.0, "max": 100.0, "step": 1.0, "default": 30.0},
		{"name": "ray2_intensity", "min": 0.0, "max": 1.0, "step": 0.01, "default": 0.3},
		{"name": "seed", "min": 0.0, "max": 100.0, "step": 0.1, "default": 5.0}
	]
	
	# 为每个参数创建滑块和标签
	for param in parameters:
		# 创建水平容器
		var hbox = HBoxContainer.new()
		content_vbox.add_child(hbox)
		
		# 参数名称标签
		var name_label = Label.new()
		name_label.text = param["name"] + ": "
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x = 120
		hbox.add_child(name_label)
		
		# 参数值标签
		var value_label = Label.new()
		value_label.name = param["name"] + "_label"
		value_label.text = str(param["default"])
		value_label.custom_minimum_size.x = 50
		hbox.add_child(value_label)
		labels[param["name"]] = value_label
		
		# 滑块
		var slider = HSlider.new()
		slider.name = param["name"] + "_slider"
		slider.min_value = param["min"]
		slider.max_value = param["max"]
		slider.step = param["step"]
		slider.value = param["default"]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.connect("value_changed", Callable(self, "_on_slider_changed").bind(param["name"]))
		hbox.add_child(slider)
		sliders[param["name"]] = slider
	
	# 创建颜色选择器
	var color_hbox = HBoxContainer.new()
	content_vbox.add_child(color_hbox)
	
	var color_label = Label.new()
	color_label.text = "Color: "
	color_label.custom_minimum_size.x = 120
	color_hbox.add_child(color_label)
	
	var color_picker = ColorPickerButton.new()
	color_picker.color = Color(1.0, 0.9, 0.65, 0.8)
	color_picker.connect("color_changed", Callable(self, "_on_color_changed"))
	color_hbox.add_child(color_picker)
	
	# 创建 HDR 复选框
	var hdr_hbox = HBoxContainer.new()
	content_vbox.add_child(hdr_hbox)
	
	var hdr_label = Label.new()
	hdr_label.text = "HDR: "
	hdr_label.custom_minimum_size.x = 120
	hdr_hbox.add_child(hdr_label)
	
	var hdr_checkbox = CheckBox.new()
	hdr_checkbox.button_pressed = false
	hdr_checkbox.connect("toggled", Callable(self, "_on_hdr_toggled"))
	hdr_hbox.add_child(hdr_checkbox)
	
	# 添加分隔线
	var separator2 = HSeparator.new()
	content_vbox.add_child(separator2)
	
	# 添加随机参数按钮
	var random_button_hbox = HBoxContainer.new()
	content_vbox.add_child(random_button_hbox)
	
	# 添加一个占位符让按钮居中
	var spacer_left = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_button_hbox.add_child(spacer_left)
	
	var random_button = Button.new()
	random_button.text = "随机参数"
	random_button.connect("pressed", Callable(self, "_on_random_button_pressed"))
	random_button_hbox.add_child(random_button)
	
	var spacer_right = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	random_button_hbox.add_child(spacer_right)
	
	# 添加一些间距
	content_vbox.add_child(Control.new())

func _on_slider_changed(value, param_name):
	# 更新标签显示
	labels[param_name].text = str(value)
	
	# 更新着色器参数
	if material is ShaderMaterial:
		material.set_shader_parameter(param_name, value)

func _on_color_changed(color):
	if material is ShaderMaterial:
		material.set_shader_parameter("color", color)

func _on_hdr_toggled(toggled):
	if material is ShaderMaterial:
		material.set_shader_parameter("hdr", toggled)

# 随机参数按钮按下时的处理
func _on_random_button_pressed():
	randomize_parameters()

func randomize_parameters():
	# 随机颜色
	var random_color = Color(
		randf_range(0.5, 1.0),  # R
		randf_range(0.5, 1.0),  # G
		randf_range(0.5, 1.0),  # B
		randf_range(0.5, 0.9)   # A
	)
	_on_color_changed(random_color)
	
	# 随机 HDR 状态
	var random_hdr = randf() > 0.7  # 30% 的概率启用 HDR
	if material is ShaderMaterial:
		material.set_shader_parameter("hdr", random_hdr)
	
	# 随机所有滑块参数
	for param_name in sliders:
		var slider = sliders[param_name]
		var random_value = randf_range(slider.min_value, slider.max_value)
		
		# 对于某些参数，使用更合理的随机范围
		match param_name:
			"angle":
				random_value = randf_range(-1.0, 1.0)  # 限制角度范围
			"position":
				random_value = randf_range(-1.0, 1.0)  # 限制位置范围
			"speed":
				random_value = randf_range(0.5, 5.0)   # 限制速度范围
			"ray1_density", "ray2_density":
				random_value = randf_range(5.0, 50.0)  # 限制密度范围
		
		slider.value = random_value
		labels[param_name].text = str(random_value)
		
		if material is ShaderMaterial:
			material.set_shader_parameter(param_name, random_value)

func update_all_parameters():
	# 更新所有参数到着色器
	for param_name in sliders:
		var slider = sliders[param_name]
		if material is ShaderMaterial:
			material.set_shader_parameter(param_name, slider.value)
		labels[param_name].text = str(slider.value)
