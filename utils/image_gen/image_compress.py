"""使用 Pillow 在本地压缩图片，并可等比例调整尺寸。

用法:
    python image_compress.py <input> [output] [--width 像素] [--height 像素]
                             [--quality 1-100] [--format jpeg|png|webp]
                             [--allow-upscale] [--overwrite]

参数:
    input           输入图片路径
    output          输出文件或已有目录；缺省时保存到原图所在目录，
                    文件名为 原文件名_compressed.扩展名
    --width         目标最大宽度，保持宽高比
    --height        目标最大高度，保持宽高比；与 --width 同时指定时缩放到两者范围内
    --quality       JPEG/WebP 压缩质量，1-100，默认 85；PNG 忽略此参数
    --format        强制输出格式；缺省按 output 扩展名或原图格式判断
    --allow-upscale 允许放大图片；默认只缩小，不放大
    --overwrite     允许覆盖已有文件或原图

输出格式支持 JPEG、PNG、WebP。JPEG 使用有损压缩，PNG 使用无损压缩。
包含透明通道的图片转为 JPEG 时，会使用白色背景。
"""

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError


FORMAT_EXTENSIONS = {
    "JPEG": ".jpg",
    "PNG": ".png",
    "WEBP": ".webp",
}
EXTENSION_FORMATS = {
    ".jpg": "JPEG",
    ".jpeg": "JPEG",
    ".png": "PNG",
    ".webp": "WEBP",
}


def positive_int(value: str) -> int:
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("必须是正整数")
    return number


def quality(value: str) -> int:
    number = int(value)
    if not 1 <= number <= 100:
        raise argparse.ArgumentTypeError("必须在 1-100 之间")
    return number


def parse_args():
    parser = argparse.ArgumentParser(
        description="使用 Pillow 压缩图片并等比例调整尺寸。",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="示例:\n"
               "  python image_compress.py input.png output.jpg --width 1024 --quality 80\n"
               "  python image_compress.py input.png --height 150 --overwrite",
    )
    parser.add_argument("input", type=Path, help="输入图片路径")
    parser.add_argument("output", nargs="?", type=Path, help="输出文件或已有目录")
    parser.add_argument("--width", type=positive_int, help="目标最大宽度")
    parser.add_argument("--height", type=positive_int, help="目标最大高度")
    parser.add_argument("--quality", type=quality, default=85, help="JPEG/WebP 质量，默认 85")
    parser.add_argument("--format", choices=("jpeg", "png", "webp"), help="强制输出格式")
    parser.add_argument("--allow-upscale", action="store_true", help="允许放大图片")
    parser.add_argument("--overwrite", action="store_true", help="允许覆盖已有文件")
    return parser.parse_args()


def resolve_output(input_path: Path, output_arg: Path | None, format_arg: str | None,
                   source_format: str | None):
    output_is_dir = output_arg is not None and output_arg.is_dir()
    suffix = "" if output_arg is None or output_is_dir else output_arg.suffix.lower()
    suffix_format = EXTENSION_FORMATS.get(suffix)

    if suffix and suffix_format is None:
        raise ValueError(f"不支持的输出扩展名 '{suffix}'，仅支持 jpg、jpeg、png、webp。")
    if format_arg and suffix_format and format_arg.upper() != suffix_format:
        raise ValueError("--format 与 output 的文件扩展名不一致。")

    if format_arg:
        image_format = format_arg.upper()
    elif suffix_format:
        image_format = suffix_format
    else:
        image_format = source_format if source_format in FORMAT_EXTENSIONS else "PNG"

    extension = FORMAT_EXTENSIONS[image_format]
    if output_arg is None:
        output_path = input_path.with_name(f"{input_path.stem}_compressed{extension}")
    elif output_is_dir:
        output_path = output_arg / f"{input_path.stem}_compressed{extension}"
    elif output_arg.suffix:
        output_path = output_arg
    else:
        output_path = output_arg.with_suffix(extension)

    return output_path, image_format


def resize_image(image: Image.Image, width: int | None, height: int | None,
                 allow_upscale: bool) -> Image.Image:
    if width is None and height is None:
        return image

    scales = []
    if width is not None:
        scales.append(width / image.width)
    if height is not None:
        scales.append(height / image.height)
    scale = min(scales)
    if not allow_upscale:
        scale = min(scale, 1.0)

    target_size = (
        max(1, round(image.width * scale)),
        max(1, round(image.height * scale)),
    )
    if target_size == image.size:
        return image
    return image.resize(target_size, Image.Resampling.LANCZOS)


def prepare_for_format(image: Image.Image, image_format: str) -> Image.Image:
    if image_format == "JPEG":
        if "A" in image.getbands() or "transparency" in image.info:
            rgba = image.convert("RGBA")
            background = Image.new("RGB", rgba.size, "white")
            background.paste(rgba, mask=rgba.getchannel("A"))
            return background
        return image.convert("RGB")
    if image_format == "WEBP" and image.mode not in ("RGB", "RGBA"):
        return image.convert("RGBA" if "A" in image.getbands() else "RGB")
    if image_format == "PNG" and image.mode == "CMYK":
        return image.convert("RGB")
    return image


def format_size(size: int) -> str:
    if size >= 1024 * 1024:
        return f"{size / (1024 * 1024):.2f} MiB"
    if size >= 1024:
        return f"{size / 1024:.1f} KiB"
    return f"{size} B"


def compress_image(args) -> tuple[Path, tuple[int, int], tuple[int, int], int, int]:
    input_path = args.input
    if not input_path.is_file():
        raise ValueError(f"找不到输入图片: {input_path}")

    original_size = input_path.stat().st_size
    with Image.open(input_path) as source:
        source_format = source.format
        output_path, image_format = resolve_output(
            input_path, args.output, args.format, source_format
        )
        image = ImageOps.exif_transpose(source)
        image.load()
        original_dimensions = image.size
        icc_profile = source.info.get("icc_profile")

    if output_path.exists() and not args.overwrite:
        raise ValueError(f"输出文件已存在: {output_path}；如需覆盖请添加 --overwrite。")

    image = resize_image(image, args.width, args.height, args.allow_upscale)
    output_dimensions = image.size
    image = prepare_for_format(image, image_format)

    save_options = {}
    if icc_profile:
        save_options["icc_profile"] = icc_profile
    if image_format == "JPEG":
        save_options.update(quality=args.quality, optimize=True, progressive=True)
    elif image_format == "PNG":
        save_options.update(optimize=True, compress_level=9)
    else:
        save_options.update(quality=args.quality, method=6)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path, format=image_format, **save_options)
    return (
        output_path,
        original_dimensions,
        output_dimensions,
        original_size,
        output_path.stat().st_size,
    )


def main() -> int:
    args = parse_args()
    try:
        output_path, old_dimensions, new_dimensions, old_size, new_size = compress_image(args)
    except (UnidentifiedImageError, OSError, ValueError) as error:
        print(f"错误: {error}", file=sys.stderr)
        return 1

    print(output_path.resolve())
    print(f"尺寸: {old_dimensions[0]}x{old_dimensions[1]} -> "
          f"{new_dimensions[0]}x{new_dimensions[1]}")
    print(f"大小: {format_size(old_size)} -> {format_size(new_size)} "
          f"({new_size / old_size:.1%})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
