"""调用图片 API 生成或编辑图片并保存到本地。

默认使用 GPT（gpt-image-2.5）后端，传入 --gemini 可改用 Gemini，
传入 --seedream 可改用火山方舟 Seedream 图片模型。

用法:
    python image_gen.py [gen] <prompt> [filename] [output_dir] [--gemini | --seedream]
    python image_gen.py edit <source_images> <prompt> [filename] [output_dir] [--gemini | --seedream]

模式与参数:
    gen           生成图片（默认模式，可省略不写）
    edit          编辑图片：以参考图为基础进行修改
    source_images (edit 必填) 参考图，多张用英文逗号分隔。
                  GPT/Gemini 支持本地 jpg/jpeg/png/webp/gif；
                  Seedream 还支持 http(s) URL 和 asset:// ID
    prompt        (必填) 图片提示词。gen 模式下会自动附加风格语句（以空格分隔）：
                  GPT/Gemini 默认 style.md，Seedream 默认 style_cn.md；
                  可用 --style 显式覆盖，用 --no-style 关闭
    filename      (可选) 保存的文件名（不含扩展名，扩展名按返回图片格式自动选择）。
                  gen 缺省为 日期时间+随机数；edit 缺省为 原文件名_edit+日期时间+随机数
    output_dir    (可选) 保存目录，缺省时保存到当前工作目录
    --gemini      强制使用 Gemini 后端
    --seedream    强制使用 Seedream 后端（默认 pro；可用 --seedream-model 修改）
    --seedream-model=flash|pro
                  Seedream 模型档位，默认 pro
    --seedream-size=<尺寸>
                  Seedream 输出尺寸。Pro: 1K/1.5K/2K 或 宽x高；flash: 2K/3K/4K。
                  默认 1024x1024
    --seedream-watermark
                  Seedream 生成时添加「AI生成」水印（默认不加）
    --no-style    仅 gen 模式有效：不附加任何风格语句
    --style=<file> 仅 gen 模式有效：显式指定风格语句文件；缺省按后端选择
                  style.md 或 style_cn.md，与 --no-style 互斥
    --transparent 仅 GPT gen 模式有效：请求透明背景

环境变量:
    IMAGE_TOKEN_GPT       GPT 后端的 API 访问令牌（默认后端，必须提前设置）
    IMAGE_TOKEN_GEMINI    Gemini 后端的 API 访问令牌（使用 --gemini 时必须设置）
    RELAY_API_KEY_CN      Seedream 后端的 API 访问令牌（使用 --seedream 时必须设置；
                          未设置时以 ARK_API_KEY 兜底）
"""

import os
import sys
import base64
import ipaddress
import random
import socket
from pathlib import Path
from datetime import datetime
from urllib.parse import urlparse

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

# ---- Seedream 后端配置 ----
SEEDREAM_BASE_URL = os.environ.get(
    "ARK_API_BASE_URL", "https://ark.cn-beijing.volces.com/api/plan/v3"
).rstrip("/")
SEEDREAM_IMAGE_URL = f"{SEEDREAM_BASE_URL}/images/generations"
SEEDREAM_MODELS = {
    "flash": "doubao-seedream-5-0-flash-260915",
    "pro": "doubao-seedream-5-0-pro-260628",
}
SEEDREAM_DEFAULT_MODEL = "pro"
SEEDREAM_DEFAULT_SIZE = "1024x1024"

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


def load_style_prompt(style_file: str = "style.md") -> str:
    """读取同目录下指定的风格语句文件；文件不存在或为空时返回空串。"""
    style_path = Path(__file__).resolve().parent / style_file
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


def call_gpt_gen(prompt, token, transparent=False):
    """调用 GPT images/generations 接口文生图；transparent 时请求透明背景。"""
    session = make_session()
    payload = {
        "model": GPT_MODEL,
        "prompt": prompt,
        "size": GPT_SIZE,
        "quality": GPT_GEN_QUALITY,
        "response_format": "url",
    }
    if transparent:
        payload["background"] = "transparent"
    resp = request_with_retry(
        session,
        "post",
        GPT_GEN_URL,
        headers={"Authorization": bearer(token), "Content-Type": "application/json"},
        json=payload,
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


# ---- Seedream 后端 ----


def seedream_api_key():
    """Seedream 使用 AgentPlan/火山方舟 key；RELAY_API_KEY_CN 优先，ARK_API_KEY 兜底。"""
    for name in ("RELAY_API_KEY_CN", "ARK_API_KEY"):
        value = os.environ.get(name, "").strip()
        if value:
            return value
    return ""


def seedream_local_ref(path: Path) -> str:
    """把本地参考图转换为 Seedream 接受的 data URI。"""
    if not path.is_file():
        print(f"错误: 找不到参考图文件: {path}", file=sys.stderr)
        return ""
    if path.stat().st_size > 30 * 1024 * 1024:
        print(f"错误: 参考图超过 30MB 上限: {path}", file=sys.stderr)
        return ""
    mime = MIME_TYPES.get(path.suffix.lower(), "image/png")
    encoded = base64.b64encode(path.read_bytes()).decode()
    return f"data:{mime};base64,{encoded}"


def resolve_seedream_ref(ref: str) -> str:
    """Seedream 参考素材：http(s)/asset:// 原样传递，本地文件转 data URI。"""
    if ref.startswith(("http://", "https://", "asset://")):
        return ref
    return seedream_local_ref(Path(ref))


# 火山官方对象存储域名来自 API 响应，可信；其他域名仍做内网/回环地址防护。
SEEDREAM_TRUSTED_HOSTS = (
    ".volces.com",
    ".volcengine.com",
    ".volcdns.com",
    ".volcengineapi.com",
)


def validate_seedream_download_url(url: str) -> bool:
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        print(f"错误: 非法下载地址：{url[:120]}", file=sys.stderr)
        return False
    host = parsed.hostname.lower()
    if any(host.endswith(domain) for domain in SEEDREAM_TRUSTED_HOSTS):
        return True
    try:
        addresses = socket.getaddrinfo(parsed.hostname, None)
    except socket.gaierror:
        print(f"错误: 下载地址域名无法解析：{url[:120]}", file=sys.stderr)
        return False
    for info in addresses:
        ip = ipaddress.ip_address(info[4][0])
        if ip.is_private or ip.is_loopback or ip.is_link_local:
            print(f"错误: 拒绝内网/回环下载地址：{url[:120]}", file=sys.stderr)
            return False
    return True


def download_seedream_image(session, url: str):
    """下载 Seedream 返回的产物 URL；返回 (图片字节, 扩展名)。"""
    if not validate_seedream_download_url(url):
        return None
    resp = request_with_retry(session, "get", url)
    if resp is None or not check_response(resp):
        return None
    mime = resp.headers.get("Content-Type", "").split(";")[0].strip().lower()
    return resp.content, EXT_BY_MIME.get(mime, ".png")


def call_seedream(prompt, token, refs=None, model=SEEDREAM_DEFAULT_MODEL,
                  size=SEEDREAM_DEFAULT_SIZE, watermark=False):
    """调用 Seedream images/generations；refs 非空时执行参考图生图/编辑。"""
    model_id = SEEDREAM_MODELS[model]
    ref_limit = 14 if model == "flash" else 10
    refs = refs or []
    if len(refs) > ref_limit:
        print(f"错误: Seedream {model} 参考图上限 {ref_limit} 张，当前 {len(refs)} 张。",
              file=sys.stderr)
        return None

    resolved_refs = []
    for ref in refs:
        resolved = resolve_seedream_ref(ref)
        if not resolved:
            return None
        resolved_refs.append(resolved)

    payload = {
        "model": model_id,
        "prompt": prompt,
        "size": size,
        "response_format": "url",
        "watermark": bool(watermark),
    }
    if resolved_refs:
        payload["image"] = resolved_refs[0] if len(resolved_refs) == 1 else resolved_refs

    print(f"生成中：model={model_id} size={size} 参考图 {len(resolved_refs)} 张")
    session = make_session()
    resp = request_with_retry(
        session,
        "post",
        SEEDREAM_IMAGE_URL,
        headers={"Authorization": bearer(token), "Content-Type": "application/json"},
        json=payload,
    )
    if resp is None or not check_response(resp):
        return None

    data = resp.json().get("data") or []
    urls = [entry["url"] for entry in data if entry.get("url")]
    if not urls:
        print(f"错误: Seedream 响应中没有图片 URL：{str(resp.json())[:500]}", file=sys.stderr)
        return None
    return download_seedream_image(session, urls[0])


def take_option_value(args, flag, default):
    """从位置参数中取出 --flag=value 形式的选项；重复或不带值时返回 None 表示参数错误。"""
    matches = [arg for arg in args if arg.startswith(f"{flag}=")]
    if not matches:
        return default, args
    if len(matches) > 1:
        print(f"错误: {flag} 只能指定一次。", file=sys.stderr)
        return None, args
    value = matches[0][len(flag) + 1:].strip()
    args.remove(matches[0])
    if not value:
        print(f"错误: {flag} 缺少值。", file=sys.stderr)
        return None, args
    return value, args


def main() -> int:
    # ---- 解析命令行参数 ----
    args = sys.argv[1:]
    if "--help" in args or "-h" in args:
        print(__doc__)
        return 0

    # 选项参数可写在任意位置，先从位置参数中剔除
    use_gemini = "--gemini" in args
    if use_gemini:
        args.remove("--gemini")
    use_seedream = "--seedream" in args
    if use_seedream:
        args.remove("--seedream")
    if use_gemini and use_seedream:
        print("错误: --gemini 与 --seedream 不能同时使用。", file=sys.stderr)
        return 1

    no_style = "--no-style" in args
    if no_style:
        args.remove("--no-style")
    transparent = "--transparent" in args
    if transparent:
        args.remove("--transparent")
    seedream_watermark = "--seedream-watermark" in args
    if seedream_watermark:
        args.remove("--seedream-watermark")

    seedream_model, args = take_option_value(args, "--seedream-model", SEEDREAM_DEFAULT_MODEL)
    if seedream_model is None:
        return 1
    if seedream_model not in SEEDREAM_MODELS:
        print(f"错误: --seedream-model 只能是 {'|'.join(SEEDREAM_MODELS)}。",
              file=sys.stderr)
        return 1

    seedream_size, args = take_option_value(args, "--seedream-size", SEEDREAM_DEFAULT_SIZE)
    if seedream_size is None:
        return 1

    if transparent and (use_gemini or use_seedream):
        print("错误: --transparent 仅 GPT gen 模式支持。", file=sys.stderr)
        return 1

    # --style=<file> 显式指定风格语句文件；未指定时 GPT/Gemini 用英文 style.md，
    # Seedream 用中文 style_cn.md。与 --no-style 互斥。
    style_file = None
    style_args = [arg for arg in args if arg.startswith("--style=")]
    if style_args:
        if len(style_args) > 1:
            print("错误: --style 只能指定一次。", file=sys.stderr)
            return 1
        style_file = style_args[0][len("--style="):].strip()
        args.remove(style_args[0])
        if not style_file:
            print("错误: --style 缺少文件名。", file=sys.stderr)
            return 1
        if no_style:
            print("错误: --style 与 --no-style 不能同时使用。", file=sys.stderr)
            return 1
        style_path = Path(__file__).resolve().parent / style_file
        if not style_path.is_file():
            print(f"错误: 找不到风格语句文件: {style_path}", file=sys.stderr)
            return 1
    if style_file is None:
        style_file = "style_cn.md" if use_seedream else "style.md"

    # 首个位置参数决定模式：edit 为编辑；gen 可省略（默认生成）
    mode = "gen"
    if args and args[0] == "edit":
        mode = "edit"
        args = args[1:]
    elif args and args[0] == "gen":
        args = args[1:]

    # ---- edit 模式：解析并校验参考图 ----
    image_paths = []
    source_refs = []
    if mode == "edit":
        if not args or not args[0].strip():
            print("错误: edit 模式缺少必填参数 source_images。", file=sys.stderr)
            print(__doc__, file=sys.stderr)
            return 1
        for item in args[0].split(","):
            item = item.strip()
            if not item:
                continue
            source_refs.append(item)
            if use_seedream and item.startswith(("http://", "https://", "asset://")):
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
        if not source_refs:
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

    # gen 模式下附加风格语句（默认 style.md，可用 --style 指定其他文件，--no-style 可忽略）
    if mode == "gen" and not no_style:
        style_prompt = load_style_prompt(style_file)
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
            source_name = image_paths[0].stem if image_paths else "reference"
            filename = f"{source_name}_edit_{time_str}{random_num}"
        else:
            filename = f"{time_str}{random_num}"

    if len(args) >= 3 and args[2].strip():
        output_dir = Path(args[2])
    else:
        output_dir = Path.cwd()

    # ---- 读取 API 令牌 ----
    if use_seedream:
        token = seedream_api_key()
        if not token:
            print("错误: 使用 Seedream 需要设置 RELAY_API_KEY_CN（或以 ARK_API_KEY 兜底）。",
                  file=sys.stderr)
            return 1
    else:
        token_env = "IMAGE_TOKEN_GEMINI" if use_gemini else "IMAGE_TOKEN_GPT"
        token = os.environ.get(token_env)
        if not token:
            print(f"错误: 未设置环境变量 {token_env}。", file=sys.stderr)
            return 1

    # ---- 调用对应后端 ----
    if mode == "edit":
        if use_seedream:
            result = call_seedream(
                prompt,
                token,
                refs=source_refs,
                model=seedream_model,
                size=seedream_size,
                watermark=seedream_watermark,
            )
        elif use_gemini:
            result = call_gemini(prompt, token, image_paths)
        else:
            result = call_gpt_edit(prompt, image_paths, token)
    else:
        if use_seedream:
            result = call_seedream(
                prompt,
                token,
                model=seedream_model,
                size=seedream_size,
                watermark=seedream_watermark,
            )
        elif use_gemini:
            result = call_gemini(prompt, token)
        else:
            result = call_gpt_gen(prompt, token, transparent=transparent)
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
