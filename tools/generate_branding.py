#!/usr/bin/env python3
"""Generate Hole Rush branding PNG assets matching scripts/hole_rush_icon.gd."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "branding"
ANDROID_DIR = OUT_DIR / "android"

BG_TOP = (82, 122, 173)
BG_BOTTOM = (20, 56, 133)


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_vertical_gradient(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    draw = ImageDraw.Draw(image)
    for y in range(height):
        t = y / max(height - 1, 1)
        color = lerp_color(BG_TOP, BG_BOTTOM, t)
        draw.line([(0, y), (width, y)], fill=color)
    return image


def draw_hole_logo(
    image: Image.Image,
    center_x: float,
    center_y: float,
    canvas_min: float,
    radius_scale: float = 0.38,
) -> None:
    draw = ImageDraw.Draw(image)
    radius = canvas_min * radius_scale
    scale = canvas_min / 128.0

    for ring in range(5, 0, -1):
        glow_r = radius + ring * 7.0 * scale
        alpha = int((0.08 + ring * 0.05) * 255)
        draw.ellipse(
            (center_x - glow_r, center_y - glow_r, center_x + glow_r, center_y + glow_r),
            fill=(51, 140, 255, alpha),
        )

    halo_r = radius + 10.0 * scale
    draw.ellipse(
        (center_x - halo_r, center_y - halo_r, center_x + halo_r, center_y + halo_r),
        fill=(31, 82, 184, 89),
    )

    arc_r = radius + 8.0 * scale
    ring_width = max(2, int(4.0 * scale))
    for offset in range(ring_width):
        r = arc_r - offset * 0.55
        draw.ellipse(
            (center_x - r, center_y - r, center_x + r, center_y + r),
            outline=(115, 199, 255, 242),
        )

    body_r = radius * 0.94
    draw.ellipse(
        (center_x - body_r, center_y - body_r, center_x + body_r, center_y + body_r),
        fill=(10, 15, 31, 255),
    )

    inner_r = radius * 0.72
    draw.ellipse(
        (center_x - inner_r, center_y - inner_r, center_x + inner_r, center_y + inner_r),
        fill=(0, 0, 5, 255),
    )

    highlight_x = center_x - radius * 0.28
    highlight_y = center_y - radius * 0.32
    highlight_r = radius * 0.14
    draw.ellipse(
        (
            highlight_x - highlight_r,
            highlight_y - highlight_r,
            highlight_x + highlight_r,
            highlight_y + highlight_r,
        ),
        fill=(140, 209, 255, 102),
    )


def make_icon_with_background(size: int, radius_scale: float = 0.38) -> Image.Image:
    image = draw_vertical_gradient((size, size)).convert("RGBA")
    draw_hole_logo(image, size * 0.5, size * 0.5, float(size), radius_scale)
    return image


def make_adaptive_foreground(size: int) -> Image.Image:
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_hole_logo(image, size * 0.5, size * 0.5, float(size), radius_scale=0.30)
    return image


def make_adaptive_background(size: int) -> Image.Image:
    return draw_vertical_gradient((size, size)).convert("RGBA")


def _load_title_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for font_name in ("arialbd.ttf", "Arial Bold.ttf", "segoeuib.ttf", "calibrib.ttf"):
        try:
            return ImageFont.truetype(font_name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_splash(width: int, height: int) -> Image.Image:
    image = draw_vertical_gradient((width, height)).convert("RGBA")
    logo_size = int(width * 0.52)
    logo = make_icon_with_background(logo_size)
    logo_x = (width - logo_size) // 2
    logo_y = int(height * 0.30)
    image.alpha_composite(logo, (logo_x, logo_y))

    draw = ImageDraw.Draw(image)
    font = _load_title_font(int(width * 0.11))
    title = "HOLE RUSH"
    text_bbox = draw.textbbox((0, 0), title, font=font)
    text_w = text_bbox[2] - text_bbox[0]
    text_x = (width - text_w) // 2
    text_y = logo_y + logo_size + int(height * 0.035)
    for offset_x, offset_y in ((-2, -2), (2, -2), (-2, 2), (2, 2)):
        draw.text((text_x + offset_x, text_y + offset_y), title, font=font, fill=(13, 26, 56, 255))
    draw.text((text_x, text_y), title, font=font, fill=(255, 255, 255, 255))
    return image


def main() -> None:
    ANDROID_DIR.mkdir(parents=True, exist_ok=True)

    outputs = {
        ANDROID_DIR / "main_192x192.png": make_icon_with_background(192),
        ANDROID_DIR / "adaptive_foreground_432x432.png": make_adaptive_foreground(432),
        ANDROID_DIR / "adaptive_background_432x432.png": make_adaptive_background(432),
        OUT_DIR / "icon_512.png": make_icon_with_background(512),
        OUT_DIR / "icon_1024.png": make_icon_with_background(1024),
        OUT_DIR / "splash.png": make_splash(720, 1280),
    }

    for path, image in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path, "PNG")
        print(f"Wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
