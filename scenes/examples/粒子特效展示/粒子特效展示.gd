extends Node2D
## 粒子特效展示（从 addons/vfx_library/effects 移植）
##
## 做法：
##   1. 以「精灵拖影」为模板克隆出本场景（同样的瓦片路面 + 可操作的骑士）；
##   2. 运行时把原插件里的 30 个 CPUParticles2D / GPUParticles2D 特效场景
##      沿路面一字排开，"铺满"整条路；
##   3. 每个特效上方用 Label 标注【效果名称 + 场景文件地址】；
##   4. 一次性（one_shot）的特效会自动周期性 restart，否则播一次就没了。
##
## 用法：
##   ←/→ 走路看特效；顶栏「上一个 / 下一个」直接传送到某个特效；Esc 返回主菜单。

# ===== 配置 =====

const EFFECT_DIR := "res://scenes/examples/粒子特效展示/effects/"
const MAIN_SCENE := "res://scenes/main.tscn"

## 相邻两个特效的间距（像素）
const SPACING := 180.0
## 第一个特效的 x 坐标
const START_X := 260.0
## 一次性特效重播时，在 lifetime 之外额外等待的秒数
const RESTART_GAP := 0.8

## 特效清单：file = 场景文件名，name = 中文名，desc = 这个特效在练什么
const EFFECTS: Array = [
	{"file": "ash_particles.tscn", "name": "灰烬", "desc": "负重力 + 大 spread，模拟被热气流托着往上飘的余烬"},
	{"file": "blood_splash.tscn", "name": "血溅", "desc": "one_shot + explosiveness=1.0：所有粒子同一瞬间炸开"},
	{"file": "campfire_smoke.tscn", "name": "篝火烟", "desc": "尺寸 Curve 先涨后缩，做出烟团扩散再消散"},
	{"file": "candle_flame.tscn", "name": "烛火", "desc": "极短 lifetime(0.8s) + 黄→红渐变，做出跳动的小火苗"},
	{"file": "combat_particle.tscn", "name": "打击粒子", "desc": "命中最常用的短促爆发反馈"},
	{"file": "combo_ring.tscn", "name": "连击光环", "desc": "explosiveness=0.5 的半爆发，环形向外扩散"},
	{"file": "dash_trail.tscn", "name": "冲刺拖尾", "desc": "沿运动反方向拖出的粒子尾巴（和『精灵拖影』是两种实现）"},
	{"file": "dust_cloud.tscn", "name": "尘土", "desc": "默认 emitting=false，留给落地/冲刺时脚本触发"},
	{"file": "energy_burst.tscn", "name": "能量爆发", "desc": "一次性冲击波，配合加色混合材质发光"},
	{"file": "falling_leaves.tscn", "name": "落叶", "desc": "长 lifetime(5s) + 随机角速度 → 打着旋往下落"},
	{"file": "fireball_trail.tscn", "name": "火球拖尾", "desc": "飞行物身后的持续火焰尾迹"},
	{"file": "fireflies.tscn", "name": "萤火虫", "desc": "小范围随机漂移 + 渐变色，模拟夜间光点"},
	{"file": "heal_particles.tscn", "name": "治疗", "desc": "向上飘的绿色光点，正反馈类特效的通用写法"},
	{"file": "ice_frost.tscn", "name": "冰霜", "desc": "一次性霜冻爆发，冷色调 + 短 lifetime"},
	{"file": "jump_dust.tscn", "name": "起跳尘", "desc": "起跳瞬间向两侧低角度扩散的尘土"},
	{"file": "lightning_chain.tscn", "name": "闪电链", "desc": "6 段 CPUParticles2D 拼成一条链，演示多节点组合特效"},
	{"file": "magic_aura.tscn", "name": "魔法光环", "desc": "本组唯一的 GPUParticles2D：环形发射 + 444 粒子 + 切向加速度"},
	{"file": "poison_cloud.tscn", "name": "毒云", "desc": "低速、大 spread、长 lifetime 的有色云团"},
	{"file": "portal_vortex.tscn", "name": "传送门漩涡", "desc": "tangential_accel 让粒子绕中心旋转（对照 portal_vortex.gdshader）"},
	{"file": "rain_drops.tscn", "name": "雨滴", "desc": "100 个粒子高速下落，典型的环境类特效"},
	{"file": "shield_break.tscn", "name": "护盾破碎", "desc": "一次性碎片四散， explosiveness=1.0"},
	{"file": "snow_flakes.tscn", "name": "雪花", "desc": "lifetime=5s 的缓慢飘落，和雨滴对比看『速度 + 生命周期』"},
	{"file": "sparks.tscn", "name": "火花", "desc": "高 explosiveness 的火星四溅，常配合金属碰撞"},
	{"file": "steam.tscn", "name": "蒸汽", "desc": "向上扩散的白色雾团，靠 alpha 渐变淡出"},
	{"file": "summon_circle.tscn", "name": "召唤法阵", "desc": "环形发射 + 上升，做法阵/吟唱条的标准套路"},
	{"file": "torch_fire.tscn", "name": "火炬火焰", "desc": "带火焰贴图的持续燃烧，是 candle_flame 的加强版"},
	{"file": "wall_slide_spark.tscn", "name": "滑墙火花", "desc": "只有 8 个粒子，演示『少量粒子也能有反馈感』"},
	{"file": "waterfall_mist.tscn", "name": "瀑布水雾", "desc": "向上翻腾的水雾，用负重力 + 大 spread"},
	{"file": "water_splash.tscn", "name": "水花", "desc": "入水瞬间的一次性溅射"},
	{"file": "wood_debris.tscn", "name": "木屑", "desc": "一次性碎木片，带重力下落 + 旋转"},
]

# ===== 节点引用 =====

@onready var _tilemap: TileMapLayer = $TileMapLayer
@onready var _effects_root: Node2D = $Effects
@onready var _player: CharacterBody2D = $Player
@onready var _info: Label = $UI/Panel/VBox/Info
@onready var _prev_button: Button = $UI/Panel/VBox/Bar/Prev
@onready var _next_button: Button = $UI/Panel/VBox/Bar/Next
@onready var _back_button: Button = $UI/Panel/VBox/Bar/Back

# ===== 运行时状态 =====

var _ground_y := 0.0                 ## 路面顶部的世界 y
var _spots: Array = []               ## 每个特效的坐标，供"上一个/下一个"使用
var _timed: Array = []               ## 需要周期性 restart 的特效
var _index := 0                      ## 当前聚焦到第几个
var _time := 0.0


func _ready() -> void:
	_prev_button.pressed.connect(func() -> void: _goto(_index - 1))
	_next_button.pressed.connect(func() -> void: _goto(_index + 1))
	_back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_SCENE))

	_extend_road()
	_spawn_effects()

	_goto(0)


func _process(delta: float) -> void:
	_time += delta

	# 一次性特效播完就没了，这里按各自 lifetime 周期重播
	for item in _timed:
		if _time >= item["next"]:
			item["next"] = _time + item["period"]
			for p in item["particles"]:
				p.restart()
				p.emitting = true


# =========================================================
# 路面
# =========================================================

## 把场景里那段短路面，按"整段复制"的方式拼成一条足够长的路
func _extend_road() -> void:
	var used := _tilemap.get_used_cells()
	if used.is_empty():
		push_warning("瓦片层是空的，跳过路面扩展")
		return

	var tile_size := _tilemap.tile_set.tile_size

	# 求出原始路面的范围
	var min_x := used[0].x
	var max_x := used[0].x
	for c in used:
		min_x = mini(min_x, c.x)
		max_x = maxi(max_x, c.x)

	# 路面 = 格子最多的那一行（本场景 y=22 那行有 72 格，上面几格只是零星装饰）
	var row_count := {}
	for c in used:
		row_count[c.y] = int(row_count.get(c.y, 0)) + 1
	var surface_y := used[0].y
	var best_count := -1
	for y in row_count:
		if int(row_count[y]) > best_count:
			best_count = int(row_count[y])
			surface_y = int(y)
	_ground_y = float(surface_y * tile_size.y)

	# 快照：把每个格子的内容记下来（相对 x、y、source、atlas、alternative）
	var snapshot: Array = []
	for c in used:
		snapshot.append([
			c.x - min_x,
			c.y,
			_tilemap.get_cell_source_id(c),
			_tilemap.get_cell_atlas_coords(c),
			_tilemap.get_cell_alternative_tile(c),
		])

	# 需要多长：覆盖到最后一个特效再往后留 600 像素
	var segment_width := max_x - min_x + 1
	var need_cells := int((START_X + EFFECTS.size() * SPACING + 600.0) / float(tile_size.x))
	var repeats := ceili(float(need_cells) / float(segment_width))

	for k in range(1, repeats):
		for s in snapshot:
			_tilemap.set_cell(Vector2i(s[0] + k * segment_width, s[1]), s[2], s[3], s[4])


# =========================================================
# 特效
# =========================================================

## 沿路面把所有特效场景实例化并摆放好
func _spawn_effects() -> void:
	for i in EFFECTS.size():
		var e: Dictionary = EFFECTS[i]
		var x := START_X + i * SPACING

		var scene: PackedScene = load(EFFECT_DIR + e["file"])
		if scene == null:
			push_error("粒子特效展示：加载失败 -> %s" % (EFFECT_DIR + e["file"]))
			continue

		var inst := scene.instantiate()
		inst.position = Vector2(x, _ground_y)
		_effects_root.add_child(inst)
		_spots.append(Vector2(x, _ground_y))

		# 收集实例内部的所有粒子节点（lightning_chain 有 6 个子节点）
		var particles: Array = []
		_collect_particles(inst, particles)

		var period := 0.0
		var need_restart := false
		for p in particles:
			p.emitting = true
			if p.one_shot:
				need_restart = true
			period = maxf(period, float(p.lifetime) + RESTART_GAP)

		if need_restart:
			# 用下标错开重播时间，避免 30 个特效同时闪
			_timed.append({"particles": particles, "period": period, "next": i * 0.17})

		# 上方标注：名称 + 场景文件地址
		_effects_root.add_child(_make_label(x, e))


## 递归找出节点树里的 CPUParticles2D / GPUParticles2D
func _collect_particles(node: Node, out: Array) -> void:
	if node is CPUParticles2D or node is GPUParticles2D:
		out.append(node)
	for c in node.get_children():
		_collect_particles(c, out)


## 生成悬浮在特效上方的说明标签
func _make_label(x: float, e: Dictionary) -> Label:
	var label := Label.new()
	label.text = "%s\n%s" % [e["name"], EFFECT_DIR + e["file"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.position = Vector2(x - 110.0, _ground_y - 165.0)
	label.size = Vector2(220.0, 64.0)
	return label


# =========================================================
# 导航
# =========================================================

## 聚焦到第 i 个特效：更新说明文字，并把角色传送过去
func _goto(i: int) -> void:
	if EFFECTS.is_empty():
		return
	_index = wrapi(i, 0, EFFECTS.size())

	var e: Dictionary = EFFECTS[_index]
	_info.text = "[%d/%d]  %s\n%s\n%s" % [
		_index + 1, EFFECTS.size(), e["name"], EFFECT_DIR + e["file"], e["desc"],
	]

	if _player != null:
		_player.position = Vector2(START_X + _index * SPACING, _ground_y - 30.0)
		_player.velocity = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_SCENE)
