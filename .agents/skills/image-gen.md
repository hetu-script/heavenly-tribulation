---
name: image-gen
description: 调用图片 API（默认 GPT，可选 Gemini）生成或编辑图片并保存到本地。当用户要求生成、绘制、创作图片（如角色立绘、场景图、卡牌插画等美术资源），或要求基于现有图片进行修改、编辑、局部替换、多图融合时使用。
---

# 图片生成 / 编辑（GPT 默认，可选 Gemini）

统一脚本：`utils/image_gen/image_gen.py`

- 默认使用 **GPT**（gpt-image-2.5）后端；加 `--gemini` 强制使用 Gemini 后端。
- 生成（`gen`，默认模式）与编辑（`edit`）两种模式，通过子命令区分。

## 前置条件

- API 令牌环境变量必须已设置：GPT 后端（默认）使用 `IMAGE_TOKEN_GPT`，Gemini 后端（`--gemini`）使用 `IMAGE_TOKEN_GEMINI`。
- 运行环境需要安装 `requests` 库。

## 生成图片

在项目根目录下执行：

```bash
python utils/image_gen/image_gen.py [gen] "<prompt>" [文件名] [保存目录] [--gemini] [--no-style]
```

参数（按位置顺序，均不含脚本名）：

1. `gen`（可选）：生成模式子命令，可省略（默认即生成）。
2. `prompt`（必填）：图片提示词。用双引号包裹，避免 shell 转义问题。脚本会**自动将同目录下 `utils/image_gen/prompt.md` 的内容附加到 prompt 末尾**（以空格分隔），用于统一美术风格；修改该文件即可调整全局默认风格。
3. `文件名`（可选）：保存的文件名（无需扩展名，扩展名按返回图片的实际格式自动选择，如 `.png`/`.jpg`）。缺省时自动生成 `日期时间+随机数` 格式的文件名。
4. `保存目录`（可选）：相对或绝对路径，目录不存在时会自动创建。缺省时保存到当前工作目录。
5. `--gemini`（可选）：可写在任意位置。传入后强制使用 Gemini 后端（默认 GPT）。
6. `--no-style`（可选）：可写在任意位置。传入后忽略 `prompt.md` 的默认风格语句，仅使用原始 prompt 生成。

### 示例

```bash
# 最简单调用：只给提示词（默认 GPT，自动附加 prompt.md 风格语句）
python utils/image_gen/image_gen.py "一位御剑飞行的白衣仙侠修士"

# 指定文件名和保存目录（本项目美术资源通常放在 assets/images/ 下）
python utils/image_gen/image_gen.py "火焰法术卡牌插画" fire_spell assets/images/cards

# 强制使用 Gemini 后端生成
python utils/image_gen/image_gen.py --gemini "炼丹炉道具图标" alchemy_furnace assets/images/items

# 忽略默认风格语句，完全使用自定义 prompt
python utils/image_gen/image_gen.py --no-style "像素风格的宝箱" pixel_chest assets/images/items
```

## 编辑图片

```bash
python utils/image_gen/image_gen.py edit <参考图路径> "<prompt>" [文件名] [保存目录] [--gemini]
```

参数（按位置顺序，均不含脚本名）：

1. `参考图路径`（必填）：作为编辑基础的源图片路径，支持 jpg/jpeg/png/webp/gif。**多张参考图用英文逗号分隔**（GPT 后端支持多图融合，例如"把图1的角色放进图2的场景"）。
2. `prompt`（必填）：编辑提示词。建议明确说明要修改哪些部分、保留哪些部分（构图、风格、视角、光照等），避免模型过度发挥。**edit 模式不会附加 prompt.md 的风格语句**（`--no-style` 在 edit 模式下无意义），如需风格约束请直接写进 prompt。
3. `文件名`（可选）：保存的文件名（无需扩展名）。缺省时自动生成 `原文件名_edit_日期时间+随机数` 格式的文件名。
4. `保存目录`（可选）：同上。

### 示例

```bash
# 基于现有卡牌插画做变体（默认 GPT）：改配色，其余保持不变
python utils/image_gen/image_gen.py edit assets/images/cards/fire_spell.png "仅将火焰改为冰蓝色寒冰效果，保持构图、风格和其他所有元素不变" ice_spell assets/images/cards

# 多图融合：把第一张图的角色放入第二张图的场景
python utils/image_gen/image_gen.py edit assets/images/hero.png,assets/images/bg.jpg "将图1的角色自然融入图2的场景，保持光照和透视一致" hero_in_scene assets/images/cards

# 强制使用 Gemini 后端编辑，文件名自动生成，保存到当前目录
python utils/image_gen/image_gen.py edit --gemini output/202401011200001234.jpg "将背景替换为夜晚星空，人物保持不变"
```

## 输出

- 成功时脚本标准输出打印生成图片的**完整绝对路径**，可用 `ReadMediaFile` 查看结果确认质量。
- 失败时（缺少参数、参考图不存在、未设置令牌、API 错误）会向 stderr 打印错误信息并返回非零退出码。

## 注意

- 图片生成/编辑耗时较长（脚本超时设为 300 秒，最多自动重试 5 次），用 Bash 工具调用时建议设置足够的 `timeout`，或使用 `run_in_background=true`。
- GPT 后端配置：`GPT_SIZE`（默认 1024x1024）、`GPT_GEN_QUALITY`（生成默认 medium）、`GPT_EDIT_QUALITY`（编辑默认 high，且 `input_fidelity=high`）；Gemini 后端配置：1:1 宽高比、1K 分辨率。如需调整请修改 `image_gen.py` 顶部的对应常量。
- 脚本已禁用系统代理（`trust_env=False`）：本机系统代理无法连通该 API，会导致请求卡死。
