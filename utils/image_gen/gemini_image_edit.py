"""调用 Gemini 图片编辑 API，以参考图为基础进行编辑并保存到本地。

用法:
    python gemini_image_edit.py <source_image> <prompt> [filename] [output_dir]

参数:
    source_image (必填) 参考图（源图片）的路径，支持 jpg/jpeg/png/webp/gif
    prompt       (必填) 图片编辑的提示词
    filename     (可选) 保存的文件名（不含扩展名），缺省时使用 原文件名_edit+日期时间+随机数
    output_dir   (可选) 保存目录，缺省时保存到当前工作目录

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
REQUEST_TIMEOUT = 300  # 秒
MAX_ATTEMPTS = 5  # 网络不稳定时的最大重试次数

# 常见图片扩展名对应的 MIME 类型
MIME_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".gif": "image/gif",
}


def main() -> int:
    # ---- 解析命令行参数 ----
    # 第二个参数（argv[1]）：参考图路径，必填
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("错误: 缺少必填参数 source_image。", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        return 1
    source_path = Path(sys.argv[1])
    if not source_path.is_file():
        print(f"错误: 找不到参考图文件: {source_path}", file=sys.stderr)
        return 1

    # 根据扩展名确定图片的 MIME 类型
    ext = source_path.suffix.lower()
    mime_type = MIME_TYPES.get(ext)
    if mime_type is None:
        supported = ", ".join(MIME_TYPES)
        print(f"错误: 不支持的图片格式 '{ext}'，仅支持: {supported}。", file=sys.stderr)
        return 1

    # 第三个参数（argv[2]）：prompt，必填
    if len(sys.argv) < 3 or not sys.argv[2].strip():
        print("错误: 缺少必填参数 prompt。", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        return 1
    prompt = sys.argv[2]

    # 第四个参数（argv[3]）：文件名，可选；缺省用 原文件名_edit+日期时间+随机数
    if len(sys.argv) >= 4 and sys.argv[3].strip():
        filename = sys.argv[3].strip()
        # 去掉用户可能自带的扩展名，统一使用 .jpg
        filename = Path(filename).stem
    else:
        time_str = datetime.now().strftime("%Y%m%d%H%M%S")
        random_num = random.randint(1000, 9999)
        filename = f"{source_path.stem}_edit_{time_str}{random_num}"

    # 第五个参数（argv[4]）：保存路径，可选；缺省保存到当前目录
    if len(sys.argv) >= 5 and sys.argv[4].strip():
        output_dir = Path(sys.argv[4])
    else:
        output_dir = Path.cwd()

    # ---- 读取 API 令牌 ----
    token = os.environ.get("IMAGE_TOKEN_GEMINI")
    if not token:
        print("错误: 未设置环境变量 IMAGE_TOKEN_GEMINI。", file=sys.stderr)
        return 1

    # ---- 读取参考图并编码为 base64 ----
    source_b64 = base64.b64encode(source_path.read_bytes()).decode()

    # ---- 调用图片编辑 API ----
    # 注意：必须绕过系统代理（trust_env=False）。
    # Windows 下 requests 会自动读取注册表中的系统代理，而本机代理
    # 无法连通该 API（连接建立后服务器永不响应），会导致请求一直卡住。
    session = requests.Session()
    session.trust_env = False

    resp = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            resp = session.post(
                API_URL,
                headers={
                    "Authorization": token,
                    "Content-Type": "application/json",
                },
                json={
                    "contents": [
                        {
                            "role": "user",
                            "parts": [
                                {"text": prompt},
                                {"inlineData": {"mimeType": mime_type, "data": source_b64}},
                            ],
                        }
                    ],
                    "generationConfig": {
                        "responseModalities": ["TEXT", "IMAGE"],
                        "imageConfig": {"aspectRatio": ASPECT_RATIO, "imageSize": IMAGE_SIZE},
                    },
                },
                timeout=REQUEST_TIMEOUT,
            )
            break
        except requests.RequestException as e:
            print(f"警告: 第 {attempt}/{MAX_ATTEMPTS} 次请求失败: {e}", file=sys.stderr)
            if attempt == MAX_ATTEMPTS:
                print("错误: 多次重试后仍无法连接 API。", file=sys.stderr)
                return 1
    assert resp is not None
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
    exit_code = main()
    sys.exit(exit_code)
