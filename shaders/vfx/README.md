# VFX Shader 拆解笔记

这一批 shader 来自拷贝进来的第三方插件 `GODOT-VFX-LIBRARY`。
本项目的目标是**学 shader**，所以只把其中的 `.gdshader` 抽出来、按用途重新归类，并逐个补上中文注释。

> 插件后续已经拆分完毕并删除：
> - shader → 本目录（`particles/` + `status/`），演示见 `scenes/examples/VFX_Shader_Gallery/`
> - 粒子特效场景 → `scenes/examples/粒子特效展示/effects/`，演示见 `scenes/examples/粒子特效展示/`
> - 其余（粒子管理器 `vfx.gd` / `env_vfx.gd`、插件本体）已清理

## 目录结构

```
shaders/vfx/
├── particles/   粒子 / 环境 / 画面氛围类
└── status/      状态影响类（贴在角色、精灵上表达某种状态）
```

## 两类怎么分？

判断标准只有一句话：**这个 shader 是在"凭空生成画面"，还是在"修饰一张已有的图"？**

| | particles（粒子 / 环境） | status（状态影响） |
|---|---|---|
| 作用对象 | 铺满的背景层、全屏后处理、程序化图案 | 角色 / 道具精灵 |
| 数据来源 | 主要靠 UV、TIME、噪声**算出来** | 主要读 `TEXTURE`，在其上做修改 |
| 典型手法 | 极坐标、噪声流动、多重采样卷积 | 混色、遮罩裁剪、alpha 动画 |
| 是否常驻 | 常驻场景（天气、水面、UI 底纹） | 随状态挂载/卸载（0 → 1 的进度参数） |
| 关键参数 | 无"进度"，多是速度/密度/强度 | 几乎都有一个 `xxx_amount : hint_range(0,1)` |

> 现实中有第三类"纯后处理"（blur / radial_blur / vignette / chromatic_aberration），
> 它们既不生成粒子也不表达状态。这里按"作用范围更接近环境层"归到了 `particles/`。

---

## particles/ 粒子 / 环境 / 画面氛围（11 个）

| 文件 | 效果 | 核心知识点 |
|---|---|---|
| `starSky.gdshader` | 滚动星空 | `fract(sin(x)*k)` 伪随机、hash 分层、视差滚动 |
| `fog.gdshader` | 流动雾气 | 只改 alpha 的遮罩型 shader、噪声对比度拉伸 |
| `water_surface.gdshader` | 水面波纹 | **UV 扰动**：`texture(TEXTURE, UV + offset)` |
| `heat_distortion.gdshader` | 热浪扭曲 | 噪声当偏移量（UV 扰动的另一个数据源） |
| `portal_vortex.gdshader` | 传送门漩涡 | 极坐标变换 `angle + dist * k` |
| `energy_barrier.gdshader` | 六边形能量护盾 | SDF 距离场、交错网格取最近格点 |
| `blur_amount.gdshader` | 均值模糊 | 9×9 卷积、可分离卷积优化思路 |
| `radial_blur.gdshader` | 径向模糊 | 沿方向多次采样（`UV - dir * strength * t`） |
| `chromatic_aberration.gdshader` | RGB 色差 | 三通道错位采样 |
| `vignette.gdshader` | 晕影 / 红边 | 基于到中心距离的遮罩 |
| `water.gdshader` | 像素风水面 | 综合型：像素化 + 屏幕纹理反射 + 噪声二值化 |

## status/ 状态影响（13 个）

| 文件 | 效果 | 核心知识点 |
|---|---|---|
| `burning.gdshader` | 燃烧 | 噪声热浪 + 火焰色流动 + 自下而上的推进边界 |
| `frozen.gdshader` | 冰冻 | 混冷色 + 加法叠加冰晶 |
| `poison.gdshader` | 中毒 | `sin` 呼吸脉动驱动混色强度（最简状态 shader） |
| `petrify.gdshader` | 石化 | Rec.601 去饱和 + 裂纹遮罩压暗 |
| `invisibility.gdshader` | 隐身 | 折射 + 部分淡出 + 边缘微光 |
| `dissolve.gdshader` | 溶解消失 | 噪声当"消失顺序表"，双 smoothstep 做边缘环带 |
| `blink.gdshader` | 无敌闪烁 | 正弦 alpha 动画 |
| `flash_white.gdshader` | 受击闪白 | 混色权重乘 `alpha`，避免透明区被涂白 |
| `color_change.gdshader` | 变色染色 | **亮度补偿**：混色后把亮度拉回原值 |
| `grayscale.gdshader` | 灰度 | 亮度点积、Rec.601 / Rec.709 权重 |
| `shake_intensity.gdshader` | 抖动 | 自定义 `time` uniform 才能"只在受击时抖" |
| `enemy.gdshader` | 受击（抖+糊+白） | 三种基础效果的叠加顺序：先抖 → 再糊 → 最后泛白 |
| `outline_glow.gdshader` | 轮廓发光 | 邻域 alpha 采样的边缘检测 |

---

## 贯穿全部文件的几条通用技巧

1. **`sin(TIME * speed) * 0.5 + 0.5`** —— 把 `[-1,1]` 的正弦变成 `[0,1]` 的呼吸系数，
   几乎所有"脉动"效果都是这一行。
2. **`smoothstep(a, b, x)`** —— 软阈值。想让过渡"反过来"（x 越大结果越小）就把 a、b 对调。
3. **`mix(a, b, t)`** —— 线性插值，是混色 / 过渡 / 遮罩的万能胶水。
4. **改 alpha 而非 rgb** —— 做遮罩类效果（雾、溶解、闪烁）优先动 alpha。
5. **混色时乘一次 `texture_color.a`** —— 精灵带透明区域时，能防止出现色块。
6. **`texture(TEXTURE, UV + offset)`** —— UV 扰动，是扭曲 / 水面 / 热浪 / 折射的统一写法。
7. **`TIME` 无法暂停**，需要"只在某段时间生效"的效果（受击抖动、闪白），
   要用脚本控制的自定义 `time` / `amount` uniform。

## 演示

`scenes/examples/VFX_Shader_Gallery/` 下的画廊场景会把上面 24 个 shader 全部铺在一个 2D 界面上，
每个格子上方标注**效果名称**和 **shader 文件地址**，参数随时间自动动画，方便对照源码看效果。
