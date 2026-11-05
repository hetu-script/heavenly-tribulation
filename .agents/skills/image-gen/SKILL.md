---
name: image-gen
description: 调用图片 API（默认 GPT，可选 Gemini、Seedream）生成或编辑图片并保存到本地。当用户要求生成、绘制、创作图片（如角色立绘、场景图、卡牌插画、道具图标等美术资源），或要求基于现有图片进行修改、编辑、局部替换、多图融合时使用。
---

# 图片生成 / 编辑（GPT 默认，可选 Gemini / Seedream）

统一脚本：`utils/image_gen/image_gen.py`

- 默认使用 **GPT**（gpt-image-2.5）。
- 加 `--gemini` 强制使用 Gemini 后端。
- 加 `--seedream` 强制使用火山方舟 Seedream 图片模型（默认 `pro`，可用参数切换 `flash`）。
- 支持文生图与参考图编辑两种模式；本 skill 只包含图片能力，不包含视频生成。

## 前置条件

- GPT：环境变量 `IMAGE_TOKEN_GPT`
- Gemini：环境变量 `IMAGE_TOKEN_GEMINI`
- Seedream：环境变量 `RELAY_API_KEY_CN`，未设置时使用 `ARK_API_KEY` 兜底
- Python 依赖：`requests`

## 生成图片

在项目根目录下执行：

```bash
python utils/image_gen/image_gen.py [gen] "<prompt>" [文件名] [保存目录] \
  [--gemini | --seedream] [--no-style] [--style=风格文件]
```

参数（按位置顺序，均不含脚本名）：

1. `gen`（可选）：生成模式子命令，可省略（默认即生成）。
2. `prompt`（必填）：图片提示词，用双引号包裹。默认按后端自动附加风格语句：GPT/Gemini 使用 `style.md`，Seedream 使用 `style_cn.md`；`--no-style` 可关闭。
3. `文件名`（可选）：保存文件名，不含扩展名；扩展名按返回图片实际格式决定。缺省时自动生成时间戳文件名。
4. `保存目录`（可选）：目录不存在时自动创建；缺省保存到当前工作目录。
5. `--gemini`：使用 Gemini 后端。
6. `--seedream`：使用 Seedream 后端。
7. `--seedream-model=flash|pro`：Seedream 档位，默认 `pro`。
8. `--seedream-size=<尺寸>`：Seedream 输出尺寸。Pro 支持 `1K` / `1.5K` / `2K` / `宽x高`；flash 支持 `2K` / `3K` / `4K`。默认 `1024x1024`。
9. `--seedream-watermark`：添加「AI生成」水印（默认不加）。
10. `--no-style`：不附加风格语句。
11. `--style=<文件名>`：显式指定 `utils/image_gen/` 目录下的风格文件，覆盖后端默认选择，与 `--no-style` 互斥。
12. `--transparent`：仅 GPT 文生图支持，请求透明背景。

### 生成示例

```bash
# 默认 GPT，自动附加 style.md
python utils/image_gen/image_gen.py "一位御剑飞行的白衣仙侠修士"

# 指定文件名和保存目录
python utils/image_gen/image_gen.py "火焰法术卡牌插画" fire_spell assets/images/battlecard/illustration

# 使用 Gemini
python utils/image_gen/image_gen.py --gemini "炼丹炉道具图标" alchemy_furnace assets/images/icon

# 使用 Seedream Pro，强制 1024×1024
python utils/image_gen/image_gen.py --seedream --seedream-model=pro --seedream-size=1024x1024 \
  "手绘古风仙侠卡牌插画" card_draft assets/images/battlecard/illustration

# 不使用任何默认风格文件
python utils/image_gen/image_gen.py --no-style "像素风格的宝箱" pixel_chest assets/images/item
```

## 编辑图片

```bash
python utils/image_gen/image_gen.py edit <参考图> "<prompt>" [文件名] [保存目录] \
  [--gemini | --seedream]
```

参数：

1. `参考图`（必填）：多张参考图用英文逗号分隔。
   - GPT / Gemini：本地 `jpg/jpeg/png/webp/gif`
   - Seedream：本地图片、`http(s)` URL、`asset://` ID
2. `prompt`（必填）：编辑指令。明确说明要修改什么、保留什么。edit 模式不会附加风格文件。
3. `文件名`、`保存目录`：同生成模式。
4. `--gemini` / `--seedream`：选择编辑后端；缺省为 GPT。

### 编辑示例

```bash
# GPT 编辑：基于现有图改配色
python utils/image_gen/image_gen.py edit assets/images/battlecard/illustration/fire_spell.png \
  "仅将火焰改为冰蓝色，保持构图、人物、风格和其他元素不变" ice_spell assets/images/battlecard/illustration

# Seedream 参考图编辑：本地图，强制方形输出
python utils/image_gen/image_gen.py edit --seedream --seedream-size=1024x1024 \
  assets/images/battlecard/illustration/reference.jpg \
  "保持构图和线条不变，只把外袍改成竹绿色" reference_green assets/images/battlecard/illustration

# 多张参考图（GPT 多图融合）
python utils/image_gen/image_gen.py edit assets/images/hero.png,assets/images/bg.jpg \
  "将图1的角色自然融入图2的场景，保持光照和透视一致" hero_in_scene assets/images/battlecard/illustration
```

## 风格语句文件

`utils/image_gen/` 目录下每个 `*.md` 文件都是一套可复用风格语句，通过 `--style=<文件名>` 显式使用；不指定时按后端自动选择。

当前可用：

| 文件 | 默认后端 | 风格 |
| --- | --- | --- |
| `style.md` | GPT / Gemini | 简洁数码工笔：连续线条、平净设色、干净留白 |
| `style_cn.md` | Seedream | 中文手绘古风仙侠插画提示词，明确排除真人摄影和电影写实 |
| `style2.md` | 无 | 美漫粗黑描边、赛璐璐平涂、高对比度 |

新增风格时在同目录新建 `.md` 文件即可，无需修改脚本；需要指定时用 `--style=<文件名>`。

## 输出与排错

- 成功时打印已保存图片的完整绝对路径；生成后应立即用 `ReadMediaFile` 检查质量、构图、比例和是否误加文字/水印。
- 失败时会向 stderr 输出缺少参数、令牌、参考图、API 错误等信息。
- 脚本禁用系统代理（`trust_env=False`），避免 Windows 系统代理导致请求卡死。
- GPT/Gemini/Seedream 的耗时和返回格式不同；建议 Bash 超时设置为 300 秒。
- 旧 `storm-media` skill 已合并到本 skill；视频生成、视频任务轮询和 `media/registry.json` 台账要求已移除，不需要也不应再维护 registry。
