"""调用图片 API 生成或编辑图片并保存到本地。

默认使用 GPT（gpt-image-2.5）后端，传入 --gemini 可强制改用 Gemini 后端。

用法:
    python image_gen.py [gen] <prompt> [filename] [output_dir] [--gemini] [--no-style]
    python image_gen.py edit <source_images> <prompt> [filename] [output_dir] [--gemini]

模式与参数:
    gen           生成图片（默认模式，可省略不写）
    edit          编辑图片：以参考图为基础进行修改
    source_images (edit 必填) 参考图路径，多张用英文逗号分隔；支持 jpg/jpeg/png/webp/gif
    prompt        (必填) 提示词。gen 模式下会自动附加同目录 prompt.md 中的
                  风格语句（以空格分隔），用于统一美术风格
    filename      (可选) 保存的文件名（不含扩展名，扩展名按返回图片格式自动选择）。
                  gen 缺省为 日期时间+随机数；edit 缺省为 原文件名_edit+日期时间+随机数
    output_dir    (可选) 保存目录，缺省时保存到当前工作目录
    --gemini      (可选) 强制使用 Gemini 后端（默认使用 GPT）
    --no-style    (可选) 仅 gen 模式有效：忽略 prompt.md 的默认风格语句

环境变量:
    IMAGE_TOKEN_GPT     GPT 后端的 API 访问令牌（默认后端，必须提前设置）
    IMAGE_TOKEN_GEMINI  Gemini 后端的 API 访问令牌（使用 --gemini 时必须设置）
"""

import os
import sys
import base64
import random
from pathlib import Path
from datetime import datetime

import requests

# ---- Gemini 后端配置 ----
GEMINI_API_URL = "https://img-api.apinebula.ai/v1beta/models/gemini-3.1-flash-image:generateContent"
GEMINI_ASPECT_RATIO = "1:1"
GEMINI_IMAGE_SIZE = "1K"

# ---- GPT 后端配置 ----
GPT_GEN_URL = "https://img-api.apinebula.ai/v1/images/generations"
GPT_EDIT_URL = "https://img-api.apinebula.ai/v1/images/edits"
GPT_MODEL = "gpt-image-2.5"
GPT_SIZE = "1024x1024"
GPT_GEN_QUALITY = "medium"  # low / medium / high
GPT_EDIT_QUALITY = "high"

REQUEST_TIMEOUT = 300  # 秒
MAX_ATTEMPTS = 5  # 网络不稳定时的最大重试次数

# 常见图片扩展名与 MIME 类型的互查表
MIME_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".gif": "image/gif",
}
EXT_BY_MIME = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "image/gif": ".gif",
}


def make_session() -> requests.Session:
    # 注意：必须绕过系统代理（trust_env=False）。
    # Windows 下 requests 会自动读取注册表中的系统代理，而本机代理
    # 无法连通该 API（连接建立后服务器永不响应），会导致请求一直卡住。
    session = requests.Session()
    session.trust_env = False
    return session


def request_with_retry(session, method, url, **kwargs):
    """带重试的 HTTP 请求；多次失败时打印错误并返回 None。"""
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            return session.request(method, url, timeout=REQUEST_TIMEOUT, **kwargs)
        except requests.RequestException as e:
            print(f"警告: 第 {attempt}/{MAX_ATTEMPTS} 次请求失败: {e}", file=sys.stderr)
    print("错误: 多次重试后仍无法连接 API。", file=sys.stderr)
    return None


def check_response(resp) -> bool:
    """检查 HTTP 状态码，出错时打印 API 返回的错误信息。"""
    if resp.status_code >= 400:
        print(f"错误: API 返回 {resp.status_code}: {resp.text[:500]}", file=sys.stderr)
        return False
    return True


def bearer(token: str) -> str:
    """按规范为 Authorization 头补 Bearer 前缀；令牌已带前缀时原样返回。"""
    return token if token.lower().startswith("bearer ") else f"Bearer {token}"


def load_style_prompt() -> str:
    """读取同目录下 prompt.md 的默认风格语句；文件不存在或为空时返回空串。"""
    style_path = Path(__file__).resolve().parent / "prompt.md"
    if style_path.is_file():
        return style_path.read_text(encoding="utf-8").strip()
    return ""


# ---- Gemini 后端 ----


def call_gemini(prompt, token, image_paths=None):
    """调用 Gemini generateContent 接口；image_paths 为空时即纯文生图。

    返回 (图片字节, 扩展名)，失败返回 None。
    """
    parts = [{"text": prompt}]
    for path in image_paths or []:
        parts.append({
            "inlineData": {
                "mimeType": MIME_TYPES[path.suffix.lower()],
                "data": base64.b64encode(path.read_bytes()).decode(),
            }
        })

    session = make_session()
    resp = request_with_retry(
        session,
        "post",
        GEMINI_API_URL,
        headers={"Authorization": bearer(token), "Content-Type": "application/json"},
        json={
            "contents": [{"role": "user", "parts": parts}],
            "generationConfig": {
                "responseModalities": ["TEXT", "IMAGE"],
                "imageConfig": {"aspectRatio": GEMINI_ASPECT_RATIO, "imageSize": GEMINI_IMAGE_SIZE},
            },
        },
    )
    if resp is None or not check_response(resp):
        return None

    resp_parts = resp.json()["candidates"][0]["content"]["parts"]
    image = next(part["inlineData"] for part in resp_parts if "inlineData" in part)
    ext = EXT_BY_MIME.get(image.get("mimeType", ""), ".jpg")
    return base64.b64decode(image["data"]), ext


# ---- GPT 后端 ----


def fetch_gpt_image(session, resp):
    """从 GPT 接口响应中提取图片：优先按 URL 下载，其次解码 b64_json。

    返回 (图片字节, 扩展名)，失败返回 None。
    """
    data = resp.json()["data"][0]
    if data.get("url"):
        dl = request_with_retry(session, "get", data["url"])
        if dl is None or not check_response(dl):
            return None
        mime = dl.headers.get("Content-Type", "").split(";")[0].strip().lower()
        return dl.content, EXT_BY_MIME.get(mime, ".png")
    return base64.b64decode(data["b64_json"]), ".png"


def call_gpt_gen(prompt, token):
    """调用 GPT images/generations 接口文生图。"""
    session = make_session()
    resp = request_with_retry(
        session,
        "post",
        GPT_GEN_URL,
        headers={"Authorization": bearer(token), "Content-Type": "application/json"},
        json={
            "model": GPT_MODEL,
            "prompt": prompt,
            "size": GPT_SIZE,
            "quality": GPT_GEN_QUALITY,
            "response_format": "url",
        },
    )
    if resp is None or not check_response(resp):
        return None
    return fetch_gpt_image(session, resp)


def call_gpt_edit(prompt, image_paths, token):
    """调用 GPT images/edits 接口编辑图片（multipart 上传，支持多张参考图）。"""
    files = [
        ("image", (path.name, path.read_bytes(), MIME_TYPES[path.suffix.lower()]))
        for path in image_paths
    ]
    session = make_session()
    resp = request_with_retry(
        session,
        "post",
        GPT_EDIT_URL,
        headers={"Authorization": bearer(token)},
        data={
            "model": GPT_MODEL,
            "prompt": prompt,
            "size": GPT_SIZE,
            "quality": GPT_EDIT_QUALITY,
            "response_format": "url",
            "input_fidelity": "high",
        },
        files=files,
    )
    if resp is None or not check_response(resp):
        return None
    return fetch_gpt_image(session, resp)


def main() -> int:
    # ---- 解析命令行参数 ----
    args = sys.argv[1:]

    # 选项参数可写在任意位置，先从位置参数中剔除
    use_gemini = "--gemini" in args
    if use_gemini:
        args.remove("--gemini")
    no_style = "--no-style" in args
    if no_style:
        args.remove("--no-style")

    # 首个位置参数决定模式：edit 为编辑；gen 可省略（默认生成）
    mode = "gen"
    if args and args[0] == "edit":
        mode = "edit"
        args = args[1:]
    elif args and args[0] == "gen":
        args = args[1:]

    # ---- edit 模式：解析并校验参考图 ----
    image_paths = []
    if mode == "edit":
        if not args or not args[0].strip():
            print("错误: edit 模式缺少必填参数 source_images。", file=sys.stderr)
            print(__doc__, file=sys.stderr)
            return 1
        for item in args[0].split(","):
            item = item.strip()
            if not item:
                continue
            path = Path(item)
            if not path.is_file():
                print(f"错误: 找不到参考图文件: {path}", file=sys.stderr)
                return 1
            if path.suffix.lower() not in MIME_TYPES:
                supported = ", ".join(MIME_TYPES)
                print(f"错误: 不支持的图片格式 '{path.suffix}'，仅支持: {supported}。", file=sys.stderr)
                return 1
            image_paths.append(path)
        if not image_paths:
            print("错误: edit 模式缺少必填参数 source_images。", file=sys.stderr)
            print(__doc__, file=sys.stderr)
            return 1
        args = args[1:]

    # ---- prompt，必填 ----
    if not args or not args[0].strip():
        print("错误: 缺少必填参数 prompt。", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        return 1
    prompt = args[0]

    # gen 模式下附加 prompt.md 默认风格语句（--no-style 可忽略）
    if mode == "gen" and not no_style:
        style_prompt = load_style_prompt()
        if style_prompt:
            prompt = f"{prompt} {style_prompt}"

    # ---- 文件名与保存目录 ----
    if len(args) >= 2 and args[1].strip():
        # 去掉用户可能自带的扩展名，扩展名按返回图片格式决定
        filename = Path(args[1].strip()).stem
    else:
        time_str = datetime.now().strftime("%Y%m%d%H%M%S")
        random_num = random.randint(1000, 9999)
        if mode == "edit":
            filename = f"{image_paths[0].stem}_edit_{time_str}{random_num}"
        else:
            filename = f"{time_str}{random_num}"

    if len(args) >= 3 and args[2].strip():
        output_dir = Path(args[2])
    else:
        output_dir = Path.cwd()

    # ---- 读取 API 令牌（GPT 与 Gemini 后端各用各的环境变量）----
    token_env = "IMAGE_TOKEN_GEMINI" if use_gemini else "IMAGE_TOKEN_GPT"
    token = os.environ.get(token_env)
    if not token:
        print(f"错误: 未设置环境变量 {token_env}。", file=sys.stderr)
        return 1

    # ---- 调用对应后端 ----
    if mode == "edit":
        if use_gemini:
            result = call_gemini(prompt, token, image_paths)
        else:
            result = call_gpt_edit(prompt, image_paths, token)
    else:
        if use_gemini:
            result = call_gemini(prompt, token)
        else:
            result = call_gpt_gen(prompt, token)
    if result is None:
        return 1
    image_bytes, ext = result

    # ---- 保存图片 ----
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{filename}{ext}"
    output_path.write_bytes(image_bytes)

    # 打印保存的完整路径，方便调用方（如 agent）获取结果
    print(output_path.resolve())
    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
