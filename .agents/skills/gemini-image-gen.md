---
name: gemini-image-gen
description: 调用 Gemini 图片 API 生成或编辑图片并保存到本地。当用户要求生成、绘制、创作图片（如角色立绘、场景图、卡牌插画等美术资源），或要求基于现有图片进行修改、编辑、局部替换时使用。
---

# Gemini 图片生成 / 编辑

- 生成图片：`utils/image_gen/gemini_image_gen.py`
- 编辑图片（基于参考图）：`utils/image_gen/gemini_image_edit.py`

## 前置条件

- 环境变量 `IMAGE_TOKEN_GEMINI` 必须已设置（API 令牌）。
- 运行环境需要安装 `requests` 库。

## 生成图片

在项目根目录下执行：

```bash
python utils/image_gen/gemini_image_gen.py "<prompt>" [文件名] [保存目录]
```

参数（按位置顺序，均不含脚本名）：

1. `prompt`（必填）：图片提示词。用双引号包裹，避免 shell 转义问题。如果生成卡牌插画，可以使用 `utils/image_gen/prompt.md` 里面的提示词来统一风格。
2. `文件名`（可选）：保存的文件名（无需扩展名，自动使用 `.jpg`）。缺省时自动生成 `日期时间+随机数` 格式的文件名。
3. `保存目录`（可选）：相对或绝对路径，目录不存在时会自动创建。缺省时保存到当前工作目录。

### 示例

```bash
# 最简单调用：只给提示词，文件保存到当前目录，文件名自动生成
python utils/image_gen/gemini_image_gen.py "一位御剑飞行的白衣仙侠修士，水墨风格"

# 指定文件名和保存目录（本项目美术资源通常放在 assets/images/ 下）
python utils/image_gen/gemini_image_gen.py "火焰法术卡牌插画，玄幻风格" fire_spell assets/images/cards
```

## 编辑图片

在项目根目录下执行：

```bash
python utils/image_gen/gemini_image_edit.py <参考图路径> "<prompt>" [文件名] [保存目录]
```

参数（按位置顺序，均不含脚本名）：

1. `参考图路径`（必填）：作为编辑基础的源图片路径，支持 jpg/jpeg/png/webp/gif。
2. `prompt`（必填）：编辑提示词。建议明确说明要修改哪些部分、保留哪些部分（构图、风格、视角、光照等），避免模型过度发挥。
3. `文件名`（可选）：保存的文件名（无需扩展名，自动使用 `.jpg`）。缺省时自动生成 `原文件名_edit_日期时间+随机数` 格式的文件名。
4. `保存目录`（可选）：同上。

### 示例

```bash
# 基于现有卡牌插画做变体：改配色，其余保持不变
python utils/image_gen/gemini_image_edit.py assets/images/cards/fire_spell.jpg "仅将火焰改为冰蓝色寒冰效果，保持构图、风格和其他所有元素不变" ice_spell assets/images/cards

# 文件名自动生成，保存到当前目录
python utils/image_gen/gemini_image_edit.py output/202401011200001234.jpg "将背景替换为夜晚星空，人物保持不变"
```

## 输出

- 成功时脚本标准输出打印生成图片的**完整绝对路径**，可用 `ReadMediaFile` 查看结果确认质量。
- 失败时（缺少参数、参考图不存在、未设置令牌、API 错误）会向 stderr 打印错误信息并返回非零退出码。

## 注意

- 图片生成/编辑耗时较长（脚本超时设为 300 秒，最多自动重试 5 次），用 Bash 工具调用时建议设置足够的 `timeout`，或使用 `run_in_background=true`。
- 当前 API 配置为 1:1 宽高比、1K 分辨率，如需调整请修改脚本顶部的 `ASPECT_RATIO` / `IMAGE_SIZE` 常量。编辑图片时该配置同样生效，如需保持与参考图一致的画幅，请先确认参考图的宽高比。
