"""调用 Gemini 图片生成 API 生成图片并保存到本地。

用法:
    python gemini_image_gen.py <prompt> [filename] [output_dir]

参数:
    prompt      (必填) 图片生成的提示词
    filename    (可选) 保存的文件名（不含扩展名），缺省时使用 日期时间+随机数
    output_dir  (可选) 保存目录，缺省时保存到当前工作目录

环境变量:
    IMAGE_TOKEN_GEMINI  API 访问令牌（必须提前设置）
"""

import os
import sys
import base64
import requests
import random
from pathlib import Path
from datetime import datetime

# API 端点与默认生成配置
API_URL = "https://img-api.apinebula.ai/v1beta/models/gemini-3.1-flash-image:generateContent"
ASPECT_RATIO = "1:1"
IMAGE_SIZE = "1K"
REQUEST_TIMEOUT = 600  # 秒


def main() -> int:
    # ---- 解析命令行参数 ----
    # 第二个参数（argv[1]）：prompt，必填
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("错误: 缺少必填参数 prompt。", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        return 1
    prompt = sys.argv[1]

    # 第三个参数（argv[2]）：文件名，可选；缺省用 日期时间+随机数
    if len(sys.argv) >= 3 and sys.argv[2].strip():
        filename = sys.argv[2].strip()
        # 去掉用户可能自带的扩展名，统一使用 .jpg
        filename = Path(filename).stem
    else:
        time_str = datetime.now().strftime("%Y%m%d%H%M%S")
        random_num = random.randint(1000, 9999)
        filename = f"{time_str}{random_num}"

    # 第四个参数（argv[3]）：保存路径，可选；缺省保存到当前目录
    if len(sys.argv) >= 4 and sys.argv[3].strip():
        output_dir = Path(sys.argv[3])
    else:
        output_dir = Path.cwd()

    # ---- 读取 API 令牌 ----
    token = os.environ.get("IMAGE_TOKEN_GEMINI")
    if not token:
        print("错误: 未设置环境变量 IMAGE_TOKEN_GEMINI。", file=sys.stderr)
        return 1

    # ---- 调用图片生成 API ----
    resp = requests.post(
        API_URL,
        headers={
            "Authorization": token,
            "Content-Type": "application/json",
        },
        json={
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "responseModalities": ["TEXT", "IMAGE"],
                "imageConfig": {"aspectRatio": ASPECT_RATIO, "imageSize": IMAGE_SIZE},
            },
        },
        timeout=REQUEST_TIMEOUT,
    )
    resp.raise_for_status()

    # ---- 从响应中提取图片数据 ----
    parts = resp.json()["candidates"][0]["content"]["parts"]
    image = next(part["inlineData"] for part in parts if "inlineData" in part)

    # ---- 保存图片 ----
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{filename}.jpg"
    output_path.write_bytes(base64.b64decode(image["data"]))

    # 打印保存的完整路径，方便调用方（如 agent）获取结果
    print(output_path.resolve())
    return 0


if __name__ == "__main__":
    sys.exit(main())
