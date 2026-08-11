#!/usr/bin/env python3
"""Generate Hole Rush Android launcher + Play Store icons from the master artwork."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"
ANDROID = BRANDING / "android"
MASTER = BRANDING / "hole_rush_icon_master.png"
PLAY_STORE = BRANDING / "icon_512_play_store.png"
SOURCE = MASTER


def _is_black(r: int, g: int, b: int, a: int) -> bool:
    return a > 200 and r < 28 and g < 28 and b < 28


def _radial_blue_background(size: int) -> Image.Image:
    """Match the bright blue radial backdrop from the supplied icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    cx = cy = size // 2
    max_r = int(size * 0.72)
    for i in range(max_r, 0, -1):
        t = i / max_r
        # Outer deep blue -> inner brighter cyan-blue rays.
        r = int(20 + (1 - t) * 35 + t * 10)
        g = int(80 + (1 - t) * 90)
        b = int(180 + (1 - t) * 75)
        draw.ellipse((cx - i, cy - i, cx + i, cy + i), fill=(r, g, b, 255))
    # Soft centre glow.
    glow_r = int(size * 0.42)
    for i in range(glow_r, 0, -4):
        t = i / glow_r
        alpha = int(55 * (1 - t))
        draw.ellipse(
            (cx - i, cy - i, cx + i, cy + i),
            fill=(120, 190, 255, alpha),
        )
    return img


def _strip_black_corners(src: Image.Image) -> Image.Image:
    """Replace pure-black corner padding with the blue background."""
    rgba = src.convert("RGBA")
    bg = _radial_blue_background(rgba.width)
    px = rgba.load()
    mask = Image.new("L", rgba.size, 0)
    mpx = mask.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if not _is_black(r, g, b, a):
                mpx[x, y] = 255
    out = bg.copy()
    out.paste(rgba, (0, 0), mask)
    return out


def _foreground_layer(src: Image.Image, canvas: int = 432, safe: int = 288) -> Image.Image:
    """Adaptive foreground: artwork inside Android safe zone, transparent elsewhere."""
    rgba = src.convert("RGBA")
    px = rgba.load()
    # Transparent where source is pure black (outside squircle).
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if _is_black(r, g, b, a):
                px[x, y] = (0, 0, 0, 0)

    # Scale artwork to fit safe zone with a small inset so masks do not clip objects.
    inset = int(safe * 0.94)
    scale = inset / max(rgba.width, rgba.height)
    new_w = max(1, int(rgba.width * scale))
    new_h = max(1, int(rgba.height * scale))
    scaled = rgba.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas_img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    ox = (canvas - new_w) // 2
    oy = (canvas - new_h) // 2
    canvas_img.paste(scaled, (ox, oy), scaled)
    return canvas_img


def _background_layer(size: int = 432) -> Image.Image:
    return _radial_blue_background(size)


def _save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    # Play Store / launcher icons must not have unintended transparency in outer area.
    rgb = Image.new("RGB", img.size, (21, 56, 133))
    rgb.paste(img, mask=img.split()[3])
    rgb.save(path, format="PNG", optimize=True)
    print(f"Wrote {path} ({path.stat().st_size} bytes)")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source icon: {SOURCE}")

    raw = Image.open(SOURCE)
    master = _strip_black_corners(raw)
    master.save(MASTER, format="PNG", optimize=True)
    print(f"Wrote {MASTER} ({MASTER.stat().st_size} bytes)")

    # Google Play Store listing icon (exact 512×512, full colour, no black border).
    play = master.resize((512, 512), Image.Resampling.LANCZOS)
    _save_png(play, PLAY_STORE)
    _save_png(play, BRANDING / "icon_512.png")

    icon_1024 = master.resize((1024, 1024), Image.Resampling.LANCZOS)
    _save_png(icon_1024, BRANDING / "icon_1024.png")

    main_192 = master.resize((192, 192), Image.Resampling.LANCZOS)
    _save_png(main_192, ANDROID / "main_192x192.png")

    fg = _foreground_layer(master, 432, 288)
    fg.save(ANDROID / "adaptive_foreground_432x432.png", format="PNG", optimize=True)
    print(
        f"Wrote {ANDROID / 'adaptive_foreground_432x432.png'} "
        f"({(ANDROID / 'adaptive_foreground_432x432.png').stat().st_size} bytes)"
    )

    bg = _background_layer(432)
    _save_png(bg, ANDROID / "adaptive_background_432x432.png")

    print("Done.")


if __name__ == "__main__":
    main()
