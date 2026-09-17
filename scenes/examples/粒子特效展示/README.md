# 粒子特效展示（CPUParticles2D / GPUParticles2D）

从第三方插件 `GODOT-VFX-LIBRARY`（`addons/vfx_library/`）移植过来的 **30 个粒子特效**，
以「精灵拖影」场景为模板克隆出本演示：**同一条瓦片路面上，把 30 个粒子对象一字排开铺满**，
每个特效上方有 Label 标注【效果名称 + 场景文件地址】。

插件本身已经在移植完成后删除。

## 目录

```
scenes/examples/粒子特效展示/
├── README.md             本文档
├── 粒子特效展示.tscn      演示场景（瓦片路 + 可操作骑士 + UI）
├── 粒子特效展示.gd        铺路 + 摆放特效 + 导航 + 一次性特效重播
├── Player.gd             可操作角色（←/→ 移动，空格跳，F 冲刺）
└── effects/              30 个粒子特效场景（从插件移植）
```

特效用到的 4 张贴图已经搬到 `assets/effect/`：`fire_particle.png`、`firefly.png`、`leaf.png`、`spark_particle2.png`。

## 运行

主菜单 → **「粒子特效展示」** 按钮；或直接运行 `scenes/examples/粒子特效展示/粒子特效展示.tscn`。

- `←/→`（或 `A/D`）走路，沿路逐个看特效
- 空格跳、`F` 冲刺
- 顶栏 `← 上一个` / `下一个 →` 直接传送到某个特效（同时显示它的名称、路径、要点）
- `Esc` 返回主菜单

## 场景是怎么搭起来的

1. **铺路**：`_extend_road()` 先读 `TileMapLayer` 已有的格子（`get_used_cells()`），
   把「一整段路面」当成快照，然后 `set_cell()` 重复拼接到需要的长度，
   所以特效增删时路会自动变长，不用手改瓦片数据。
   路面顶部的世界 y 由 `min(y) * tile_size.y` 算出来，特效就摆在这一条线上。
2. **摆特效**：`_spawn_effects()` 按 `EFFECTS` 表依次 `instantiate()`，
   间距 `SPACING = 180px`，位置 `(START_X + i * SPACING, ground_y)`。
3. **一次性特效重播**：`blood_splash`、`sparks`、`water_splash` 这类 `one_shot = true` 的特效
   播完一次就停了。脚本递归找出实例里所有粒子节点，
   按各自的 `lifetime + 0.8s` 周期性 `restart()`，并用下标错开时间，避免 30 个同时闪。
   `dust_cloud / sparks / steam / water_splash / wood_debris` 原本 `emitting = false`，
   这里统一强制 `emitting = true`。
4. **说明标签**：每个特效上方一个 `Label`（名称 + `res://.../xxx.tscn`），
   悬停/顶栏还能看到这个特效在练什么参数。

## 特效清单（30 个）

| 场景 | 名称 | 在练什么 |
|---|---|---|
| `ash_particles.tscn` | 灰烬 | 负重力 + 大 spread，模拟热气流托举 |
| `blood_splash.tscn` | 血溅 | `one_shot` + `explosiveness = 1.0` |
| `campfire_smoke.tscn` | 篝火烟 | 尺寸 Curve 先涨后缩 |
| `candle_flame.tscn` | 烛火 | 极短 lifetime(0.8s) + 黄→红渐变 |
| `combat_particle.tscn` | 打击粒子 | 短促的命中爆发 |
| `combo_ring.tscn` | 连击光环 | `explosiveness = 0.5` 的半爆发环形扩散 |
| `dash_trail.tscn` | 冲刺拖尾 | 沿运动反方向的粒子尾 |
| `dust_cloud.tscn` | 尘土 | 默认不发射，留给落地时触发 |
| `energy_burst.tscn` | 能量爆发 | 一次性冲击波 + 加色混合 |
| `falling_leaves.tscn` | 落叶 | 长 lifetime(5s) + 随机角速度 |
| `fireball_trail.tscn` | 火球拖尾 | 持续火焰尾迹 |
| `fireflies.tscn` | 萤火虫 | 小范围随机漂移 |
| `heal_particles.tscn` | 治疗 | 向上飘的绿色光点 |
| `ice_frost.tscn` | 冰霜 | 一次性冷色爆发 |
| `jump_dust.tscn` | 起跳尘 | 低角度向两侧扩散 |
| `lightning_chain.tscn` | 闪电链 | 6 段 CPUParticles2D 组合（根是 Node2D） |
| `magic_aura.tscn` | 魔法光环 | **唯一的 GPUParticles2D**：环形发射 + 444 粒子 |
| `poison_cloud.tscn` | 毒云 | 低速大 spread 长 lifetime |
| `portal_vortex.tscn` | 传送门漩涡 | `tangential_accel` 让粒子旋转 |
| `rain_drops.tscn` | 雨滴 | 100 粒子高速下落（环境类） |
| `shield_break.tscn` | 护盾破碎 | 一次性碎片四散 |
| `snow_flakes.tscn` | 雪花 | lifetime=5s 缓慢飘落（和雨滴对比） |
| `sparks.tscn` | 火花 | 高 explosiveness 火星四溅 |
| `steam.tscn` | 蒸汽 | 向上扩散的白雾 + alpha 淡出 |
| `summon_circle.tscn` | 召唤法阵 | 环形发射 + 上升 |
| `torch_fire.tscn` | 火炬火焰 | 带火焰贴图的持续燃烧 |
| `wall_slide_spark.tscn` | 滑墙火花 | 只用 8 个粒子做反馈 |
| `waterfall_mist.tscn` | 瀑布水雾 | 负重力 + 大 spread 向上翻腾 |
| `water_splash.tscn` | 水花 | 入水一次性溅射 |
| `wood_debris.tscn` | 木屑 | 一次性碎片 + 重力 + 旋转 |

## 几个值得对照着看的知识点

- **一次播放 vs 持续播放**：`one_shot` 决定只播一轮还是循环；`explosiveness` 决定
  这一轮是"同时炸开"(1.0) 还是"陆续冒出"(0)。看 `blood_splash` vs `steam`。
- **炸开 vs 扩散**：`initial_velocity` 给初速，`gravity` 给持续加速度；
  负 gravity 就是"往上飘"（灰烬、蒸汽、水雾）。
- **旋转**：`tangential_accel`（切向）让粒子绕圈，`angular_velocity` 让粒子自己转（落叶、木屑）。
- **淡入淡出**：`scale_amount_curve`（Curve）+ `color_ramp`（Gradient）几乎是所有特效的标配，
  前者管大小，后者管颜色与 alpha。
- **CPU vs GPU**：`magic_aura` 是 GPUParticles2D，参数在 `ParticleProcessMaterial` 里；
  其余都是 CPUParticles2D，参数直接写在节点上。CPU 版可脚本逐帧干预，GPU 版能扛上千粒子。

## 没有移植的两个

- `torch.tscn`：是个带 `res://src/effect/interactive_torch.gd` 的 StaticBody2D 交互物，
  脚本在原项目里、这里缺失，且不是粒子特效。
- `vfx_test.tscn`：原插件的测试 UI，依赖缺失的 `res://src/effect/vfx_test.gd`。
