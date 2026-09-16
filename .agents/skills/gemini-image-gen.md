---
name: gemini-image-gen
description: 调用 Gemini 图片生成 API 生成图片并保存到本地。当用户要求生成、绘制、创作图片（如角色立绘、场景图、卡牌插画等美术资源）时使用。
---

# Gemini 图片生成

通过 `image_gen/gemini_image_gen.py` 脚本调用 Gemini 图片生成 API。

## 前置条件

- 环境变量 `IMAGE_TOKEN_GEMINI` 必须已设置（API 令牌）。
- 运行环境需要安装 `requests` 库。

## 用法

在项目根目录下执行：

```bash
python image_gen/gemini_image_gen.py "<prompt>" [文件名] [保存目录]
```

参数（按位置顺序，均不含脚本名）：

1. `prompt`（必填）：图片提示词。用双引号包裹，避免 shell 转义问题。如果生成卡牌插画，可以使用 `image_gen/prompt.md` 里面的提示词来统一风格。
2. `文件名`（可选）：保存的文件名（无需扩展名，自动使用 `.jpg`）。缺省时自动生成 `日期时间+随机数` 格式的文件名。
3. `保存目录`（可选）：相对或绝对路径，目录不存在时会自动创建。缺省时保存到当前工作目录。

## 示例

```bash
# 最简单调用：只给提示词，文件保存到当前目录，文件名自动生成
python image_gen/gemini_image_gen.py "一位御剑飞行的白衣仙侠修士，水墨风格"

# 指定文件名和保存目录（本项目美术资源通常放在 assets/images/ 下）
python image_gen/gemini_image_gen.py "火焰法术卡牌插画，玄幻风格" fire_spell assets/images/cards
```

## 输出

- 成功时脚本标准输出打印生成图片的**完整绝对路径**，可用 `ReadMediaFile` 查看结果确认质量。
- 失败时（缺少参数、未设置令牌、API 错误）会向 stderr 打印错误信息并返回非零退出码。

## 注意

- 图片生成耗时较长（脚本超时设为 600 秒），用 Bash 工具调用时建议设置足够的 `timeout`，或使用 `run_in_background=true`。
- 当前 API 配置为 1:1 宽高比、1K 分辨率，如需调整请修改脚本顶部的 `ASPECT_RATIO` / `IMAGE_SIZE` 常量。
