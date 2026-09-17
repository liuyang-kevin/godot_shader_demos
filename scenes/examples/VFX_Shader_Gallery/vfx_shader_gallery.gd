extends Control
## VFX Shader 画廊（学习用演示场景）
##
## 把 shaders/vfx/ 下两类 shader 全部铺在同一张 2D 界面上：
##   - particles/ 粒子 / 环境 / 画面氛围类
##   - status/    状态影响类
##
## 每个格子的**上方**是两个 Label：效果名称 + shader 文件地址（鼠标悬停可看完整路径），
## 下方是实时运行的效果预览，参数会自动做正弦动画，方便对照源码看变化。
##
## 数据表的字段说明：
##   name   显示名
##   path   shader 文件地址（会原样显示在格子上）
##   host   "rect" = 挂在 ColorRect 上（程序化生成 / 后处理类）
##          "sprite" = 挂在 TextureRect 上（需要底图的状态类）
##   tex    host 为 sprite 时使用的底图："sprite"（程序生成的小怪，带 alpha）/ "photo"（照片）
##   params 静态 uniform 初值；字符串 "noise"/"noise_fine" 会被替换成运行时生成的噪声贴图
##   anim   需要动画的 uniform：{ 参数名: [中心值, 振幅, 速度] }
##   hue    需要按色相循环的颜色参数名
##   drive_time  为 true 时每帧把累加时间写进 "time" uniform（受击抖动类 shader 需要）

# ===== 常量 =====

const PREVIEW_SIZE := Vector2(240, 140)
const GRID_COLUMNS := 4
const PHOTO_PATH := "res://assets/132647718_p0.png"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"

## 全部：0 / 只看粒子：1 / 只看状态：2
const FILTER_ALL := 0
const FILTER_PARTICLES := 1
const FILTER_STATUS := 2

# ===== shader 清单：粒子 / 环境 / 画面氛围 =====

const PARTICLES_DATA := [
	{
		"name": "🌟 滚动星空",
		"path": "res://shaders/vfx/particles/starSky.gdshader",
		"host": "rect", "rect_color": Color(0.03, 0.03, 0.08),
		"params": {
			"dimensions": Vector2(240.0, 140.0),
			"small_stars": 40.0, "large_stars": 6.0,
			"far_stars_color": Color(0.5, 0.0, 1.0), "near_stars_color": Color(1.0, 1.0, 1.0),
			"base_scroll_speed": 0.04, "additional_scroll_speed": 0.08,
		},
	},
	{
		"name": "🌫️ 雾气",
		"path": "res://shaders/vfx/particles/fog.gdshader",
		"host": "rect", "rect_color": Color(0.82, 0.9, 1.0),
		"params": {"noise_texture": "noise", "speed": Vector2(0.02, 0.01)},
		"anim": {"density": [0.6, 0.35, 0.7]},
	},
	{
		"name": "🌊 水面波纹",
		"path": "res://shaders/vfx/particles/water_surface.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"wave_direction": Vector2(1.0, 0.0), "wave_frequency": 6.0,
			"water_tint": Color(0.65, 0.8, 1.0, 0.9)},
		"anim": {"wave_speed": [2.0, 1.0, 0.6], "wave_amplitude": [0.022, 0.014, 0.9]},
	},
	{
		"name": "🔥 热浪扭曲",
		"path": "res://shaders/vfx/particles/heat_distortion.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"noise_texture": "noise", "distortion_speed": 2.0},
		"anim": {"distortion_amount": [0.035, 0.02, 1.4]},
	},
	{
		"name": "🌀 传送门漩涡",
		"path": "res://shaders/vfx/particles/portal_vortex.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"vortex_speed": 1.5, "vortex_strength": 0.7,
			"portal_color1": Color(0.5, 0.2, 1.0), "portal_color2": Color(0.2, 0.8, 1.0)},
		"anim": {"vortex_strength": [0.7, 0.25, 0.5]},
	},
	{
		"name": "🛡️ 能量屏障",
		"path": "res://shaders/vfx/particles/energy_barrier.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"hex_scale": 14.0, "barrier_color": Color(0.3, 0.7, 1.0, 0.8),
			"pulse_speed": 3.0, "edge_brightness": 1.5},
	},
	{
		"name": "💧 像素风水面",
		"path": "res://shaders/vfx/particles/water.gdshader",
		"host": "rect", "backdrop": true, "rect_color": Color(1.0, 1.0, 1.0, 1.0),
		"params": {
			"level": 0.35, "water_albedo": Color(0.12, 0.42, 0.72, 1.0), "water_opacity": 0.45,
			"water_speed": 0.06, "wave_distortion": 0.25, "wave_multiplyer": 7,
			"water_texture_on": true,
			"noise_texture": "noise", "noise_texture2": "noise_fine",
			"pixel_resolution_x": 120.0, "pixel_resolution_y": 70.0, "edge_fade_width": 0.05,
		},
		"anim": {"level": [0.35, 0.12, 0.5]},
	},
	{
		"name": "🌫️ 均值模糊",
		"path": "res://shaders/vfx/particles/blur_amount.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {},
		"anim": {"blur_amount": [0.006, 0.005, 0.7]},
	},
	{
		"name": "🌀 径向模糊",
		"path": "res://shaders/vfx/particles/radial_blur.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"blur_center": Vector2(0.5, 0.5), "samples": 16},
		"anim": {"blur_strength": [0.05, 0.04, 1.1]},
	},
	{
		"name": "🌈 RGB 色差",
		"path": "res://shaders/vfx/particles/chromatic_aberration.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"aberration_direction": Vector2(1.0, 0.0)},
		"anim": {"aberration_amount": [0.012, 0.010, 1.6]},
	},
	{
		"name": "🔲 晕影红边",
		"path": "res://shaders/vfx/particles/vignette.gdshader",
		"host": "sprite", "tex": "photo",
		"params": {"vignette_size": 0.8, "vignette_color": Color(1.0, 0.15, 0.15)},
		"anim": {"vignette_strength": [0.6, 0.35, 1.0]},
	},
]

# ===== shader 清单：状态影响 =====

const STATUS_DATA := [
	{
		"name": "🔥 燃烧",
		"path": "res://shaders/vfx/status/burning.gdshader",
		"host": "sprite",
		"params": {"fire_color1": Color(1.0, 0.8, 0.2), "fire_color2": Color(1.0, 0.3, 0.0),
			"distortion_texture": "noise", "distortion_strength": 0.03},
		"anim": {"burn_amount": [0.5, 0.45, 0.5]},
	},
	{
		"name": "❄️ 冰冻",
		"path": "res://shaders/vfx/status/frozen.gdshader",
		"host": "sprite",
		"params": {"ice_color": Color(0.5, 0.85, 1.0), "ice_texture": "noise", "crystal_intensity": 0.6},
		"anim": {"freeze_amount": [0.6, 0.35, 0.6]},
	},
	{
		"name": "☠️ 中毒",
		"path": "res://shaders/vfx/status/poison.gdshader",
		"host": "sprite",
		"params": {"poison_color": Color(0.3, 1.0, 0.3), "pulse_speed": 3.0},
		"anim": {"poison_amount": [0.75, 0.25, 2.4]},
	},
	{
		"name": "🗿 石化",
		"path": "res://shaders/vfx/status/petrify.gdshader",
		"host": "sprite",
		"params": {"stone_color": Color(0.55, 0.55, 0.55), "crack_texture": "noise", "crack_intensity": 0.7},
		"anim": {"petrify_amount": [0.6, 0.35, 0.5]},
	},
	{
		"name": "👻 隐身",
		"path": "res://shaders/vfx/status/invisibility.gdshader",
		"host": "sprite",
		"params": {"distortion_texture": "noise", "distortion_amount": 0.03},
		"anim": {"invisibility_amount": [0.5, 0.45, 0.9]},
	},
	{
		"name": "💥 溶解",
		"path": "res://shaders/vfx/status/dissolve.gdshader",
		"host": "sprite",
		"params": {"dissolve_texture": "noise", "edge_color": Color(1.0, 0.5, 0.0), "edge_width": 0.06},
		"anim": {"dissolve_amount": [0.5, 0.45, 0.5]},
	},
	{
		"name": "⚡ 无敌闪烁",
		"path": "res://shaders/vfx/status/blink.gdshader",
		"host": "sprite",
		"params": {"blink_speed": 9.0, "min_alpha": 0.25},
	},
	{
		"name": "🔆 受击闪白",
		"path": "res://shaders/vfx/status/flash_white.gdshader",
		"host": "sprite",
		"params": {"flash_color": Color(1.0, 1.0, 1.0)},
		"anim": {"flash_amount": [0.5, 0.5, 3.2]},
	},
	{
		"name": "🎨 变色染色",
		"path": "res://shaders/vfx/status/color_change.gdshader",
		"host": "sprite",
		"params": {"mix_amount": 0.8, "preserve_luminance": true},
		"hue": "target_color",
	},
	{
		"name": "🎭 灰度",
		"path": "res://shaders/vfx/status/grayscale.gdshader",
		"host": "sprite",
		"params": {"luminance_weights": Vector3(0.299, 0.587, 0.114)},
		"anim": {"grayscale_amount": [0.5, 0.5, 0.9]},
	},
	{
		"name": "📳 抖动",
		"path": "res://shaders/vfx/status/shake_intensity.gdshader",
		"host": "sprite",
		"params": {"shake_intensity": 0.012},
		"drive_time": true,
	},
	{
		"name": "💢 受击(抖+糊+白)",
		"path": "res://shaders/vfx/status/enemy.gdshader",
		"host": "sprite",
		"params": {"shake_intensity": 0.01, "blur_amount": 0.004},
		"anim": {"white_intensity": [0.5, 0.5, 3.0]},
		"drive_time": true,
	},
	{
		"name": "✨ 轮廓发光",
		"path": "res://shaders/vfx/status/outline_glow.gdshader",
		"host": "sprite",
		"params": {"outline_width": 3.0, "glow_intensity": 1.4},
		"hue": "outline_color",
	},
]

# ===== 节点引用 =====

@onready var _content: VBoxContainer = $Margin/VBox/Scroll/Content
@onready var _filter: OptionButton = $Margin/VBox/TopBar/Filter
@onready var _count_label: Label = $Margin/VBox/TopBar/CountLabel
@onready var _back_button: Button = $Margin/VBox/TopBar/BackButton

# ===== 运行时数据 =====

var _noise: NoiseTexture2D          ## 低频噪声（雾、热浪、溶解…）
var _noise_fine: NoiseTexture2D     ## 高频噪声（水纹、冰晶…）
var _sprite_tex: Texture2D          ## 程序生成的小怪（带 alpha，适合状态类）
var _photo_tex: Texture2D           ## 照片（细节多，适合看扭曲/模糊）

var _entries: Array = []            ## 当前正在展示的条目（与 _mats 一一对应）
var _mats: Array = []               ## 当前正在展示的 ShaderMaterial
var _time := 0.0


func _ready() -> void:
	_noise = _make_noise_texture(256, 3.0)
	_noise_fine = _make_noise_texture(128, 12.0)
	_sprite_tex = _make_demo_sprite()
	_photo_tex = load(PHOTO_PATH)

	_filter.clear()
	_filter.add_item("全部", FILTER_ALL)
	_filter.add_item("粒子 / 环境", FILTER_PARTICLES)
	_filter.add_item("状态影响", FILTER_STATUS)
	_filter.item_selected.connect(_on_filter_selected)

	_back_button.pressed.connect(_on_back_pressed)

	_rebuild(FILTER_ALL)


func _process(delta: float) -> void:
	_time += delta
	for i in _mats.size():
		var mat: ShaderMaterial = _mats[i]
		var data: Dictionary = _entries[i]

		# 受击抖动类：shader 用的是自定义 time uniform，必须手动喂时间
		if data.get("drive_time", false):
			mat.set_shader_parameter("time", _time)

		# 颜色按色相循环
		if data.has("hue"):
			mat.set_shader_parameter(data["hue"], Color.from_hsv(fmod(_time * 0.15, 1.0), 0.85, 1.0))

		# 正弦动画：值 = 中心值 + sin(时间 * 速度) * 振幅
		var anim: Dictionary = data.get("anim", {})
		for key in anim:
			var a: Array = anim[key]
			mat.set_shader_parameter(key, float(a[0]) + sin(_time * float(a[2])) * float(a[1]))


# =========================================================
# 构建界面
# =========================================================

## 按筛选模式重建整个画廊
func _rebuild(mode: int) -> void:
	# 清掉旧内容
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	_entries.clear()
	_mats.clear()

	if mode != FILTER_STATUS:
		_add_section(
			"粒子 / 环境 / 画面氛围  (particles)",
			"主要靠 UV、TIME、噪声「算」出画面：程序化图案、天气、扭曲与后处理。挂在 ColorRect / TextureRect 上做背景或全屏效果。",
			PARTICLES_DATA
		)
	if mode != FILTER_PARTICLES:
		_add_section(
			"状态影响  (status)",
			"作用在已有的精灵上，用 xxx_amount(0~1) 表达「烧到几成 / 冻到几成」：燃烧、中毒、隐身、溶解、受击反馈等。",
			STATUS_DATA
		)

	_count_label.text = "共 %d 个 shader" % _mats.size()


## 添加一个分区（标题 + 说明 + 网格）
func _add_section(title: String, desc: String, data: Array) -> void:
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 20)
	_content.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.62, 0.68, 0.78))
	_content.add_child(desc_label)

	var grid := GridContainer.new()
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(grid)

	for d in data:
		grid.add_child(_build_cell(d))


## 构建单个展示格：上方 Label（名称 + 文件地址），下方实时预览
func _build_cell(data: Dictionary) -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(PREVIEW_SIZE.x + 24, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	cell.add_child(vbox)

	# ---- 上方：名称 ----
	var name_label := Label.new()
	name_label.text = data["name"]
	name_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(name_label)

	# ---- 上方：shader 文件地址 ----
	var path_label := Label.new()
	path_label.text = String(data["path"]).trim_prefix("res://")
	path_label.tooltip_text = data["path"]   # 悬停看完整 res:// 路径
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	path_label.custom_minimum_size = Vector2(PREVIEW_SIZE.x, 0)
	path_label.add_theme_font_size_override("font_size", 10)
	path_label.add_theme_color_override("font_color", Color(0.45, 0.75, 0.95))
	vbox.add_child(path_label)

	# ---- 下方：预览 ----
	var frame := PanelContainer.new()
	frame.custom_minimum_size = PREVIEW_SIZE
	vbox.add_child(frame)
	frame.add_child(_build_preview(data))

	return cell


## 构建预览节点，并登记需要每帧动画的 material
func _build_preview(data: Dictionary) -> Control:
	var shader: Shader = load(data["path"])
	if shader == null:
		push_error("VFX 画廊：无法加载 shader -> %s" % data["path"])
		var err := Label.new()
		err.text = "加载失败"
		return err

	var mat := ShaderMaterial.new()
	mat.shader = shader
	for key in data.get("params", {}):
		mat.set_shader_parameter(key, _resolve_value(data["params"][key]))

	var root := Control.new()
	root.custom_minimum_size = PREVIEW_SIZE

	# 需要"背后有东西"的 shader（如水面反射）先垫一层底图
	if data.get("backdrop", false):
		root.add_child(_make_full_rect_texture(_photo_tex))

	if data["host"] == "rect":
		var rect := ColorRect.new()
		rect.color = data.get("rect_color", Color.WHITE)
		rect.material = mat
		_set_full_rect(rect)
		root.add_child(rect)
	else:
		var tex: Texture2D = _photo_tex if data.get("tex", "sprite") == "photo" else _sprite_tex
		var rect := _make_full_rect_texture(tex)
		rect.material = mat
		root.add_child(rect)

	_entries.append(data)
	_mats.append(mat)
	return root


# =========================================================
# 工具
# =========================================================

## 把一个 Control 铺满父节点
func _set_full_rect(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL


## 生成一张铺满父节点的 TextureRect
func _make_full_rect_texture(tex: Texture2D) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_set_full_rect(r)
	return r


## 把数据表中的占位字符串替换成真正的资源
func _resolve_value(v):
	if v is String:
		match v:
			"noise":
				return _noise
			"noise_fine":
				return _noise_fine
	return v


## 用 FastNoiseLite 生成无缝噪声贴图（雾 / 热浪 / 溶解 / 冰晶都用它）
func _make_noise_texture(size: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.seed = randi()

	var tex := NoiseTexture2D.new()
	tex.width = size
	tex.height = size
	tex.seamless = true
	tex.noise = noise
	return tex


## 程序化画一只"小怪"：带 alpha 的圆润身体 + 眼睛
## 用它当状态类 shader 的底图，比用现成图片更能看清染色的变化
func _make_demo_sprite() -> Texture2D:
	var S := 128
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	var center := Vector2(S * 0.5, S * 0.52)
	var radius := S * 0.44

	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(center) / radius
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			# 左上打光，做出球体明暗
			var light := clampf(1.15 - d * 0.55 - (p.x - center.x + p.y - center.y) / radius * 0.35, 0.0, 1.0)
			var col := Color(0.95, 0.58, 0.28) * (0.35 + 0.8 * light)
			col.a = 1.0 - smoothstep(0.94, 1.0, d)   # 边缘留一点抗锯齿
			img.set_pixel(x, y, col)

	# 眼睛
	for eye_pos in [Vector2(S * 0.38, S * 0.44), Vector2(S * 0.62, S * 0.44)]:
		for y in S:
			for x in S:
				if Vector2(x + 0.5, y + 0.5).distance_to(eye_pos) < S * 0.075:
					img.set_pixel(x, y, Color(0.08, 0.06, 0.12, 1.0))

	return ImageTexture.create_from_image(img)


# =========================================================
# 回调
# =========================================================

func _on_filter_selected(_index: int) -> void:
	_rebuild(_filter.get_selected_id())


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)
