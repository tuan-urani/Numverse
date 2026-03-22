#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


WIDTH = 1440
HEIGHT = 3200

MIDNIGHT = (10, 3, 24)
COSMIC_INDIGO = (18, 7, 43)
DEEP_VIOLET = (30, 20, 56)
COSMIC_PURPLE = (44, 19, 97)
NEBULA_MAGENTA = (90, 43, 135)
RICH_GOLD = (212, 175, 55)
STARLIGHT = (253, 233, 169)
WHITE = (255, 255, 255)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
    )


def gradient_point_color(t: float) -> tuple[int, int, int]:
    stops = (0.0, 0.36, 0.78, 1.0)
    colors = (MIDNIGHT, COSMIC_INDIGO, DEEP_VIOLET, MIDNIGHT)
    if t <= stops[1]:
        local_t = (t - stops[0]) / (stops[1] - stops[0])
        return lerp_color(colors[0], colors[1], local_t)
    if t <= stops[2]:
        local_t = (t - stops[1]) / (stops[2] - stops[1])
        return lerp_color(colors[1], colors[2], local_t)
    local_t = (t - stops[2]) / (stops[3] - stops[2])
    return lerp_color(colors[2], colors[3], local_t)


def build_base_gradient() -> Image.Image:
    image = Image.new('RGBA', (WIDTH, HEIGHT))
    pixels = image.load()
    for y in range(HEIGHT):
        ny = y / max(HEIGHT - 1, 1)
        for x in range(WIDTH):
            nx = x / max(WIDTH - 1, 1)
            t = min(max(nx * 0.55 + ny * 0.45, 0.0), 1.0)
            r, g, b = gradient_point_color(t)
            pixels[x, y] = (r, g, b, 255)
    return image


def add_nebula(base: Image.Image) -> None:
    layer = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)

    def soft_blob(cx: float, cy: float, radius: float, color: tuple[int, int, int], alpha: int) -> None:
        box = (
            int(cx - radius),
            int(cy - radius),
            int(cx + radius),
            int(cy + radius),
        )
        draw.ellipse(box, fill=(*color, alpha))

    soft_blob(WIDTH * 0.10, HEIGHT * 0.10, WIDTH * 0.80, NEBULA_MAGENTA, 95)
    soft_blob(WIDTH * 0.88, HEIGHT * 0.30, WIDTH * 0.72, COSMIC_PURPLE, 88)
    soft_blob(WIDTH * 0.42, HEIGHT * 1.02, WIDTH * 0.90, DEEP_VIOLET, 115)

    layer = layer.filter(ImageFilter.GaussianBlur(radius=150))
    base.alpha_composite(layer)


def add_stars(base: Image.Image) -> None:
    stars = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(stars)

    for i in range(176):
        dx = (((i * 53) + (i * i * 3)) % 1000) / 1000 * WIDTH
        dy = (((i * 97) + (i * i * 7)) % 1000) / 1000 * HEIGHT
        radius = 0.6 + ((i % 4) * 0.25)
        is_accent = i % 13 == 0

        if is_accent:
            fill = (*STARLIGHT, 190)
            glow = (*RICH_GOLD, 45)
        else:
            fill = (*WHITE, 98)
            glow = None

        draw.ellipse(
            (
                dx - radius,
                dy - radius,
                dx + radius,
                dy + radius,
            ),
            fill=fill,
        )

        if glow:
            glow_r = radius * 5.0
            draw.ellipse(
                (
                    dx - glow_r,
                    dy - glow_r,
                    dx + glow_r,
                    dy + glow_r,
                ),
                fill=glow,
            )

    stars = stars.filter(ImageFilter.GaussianBlur(radius=0.35))
    base.alpha_composite(stars)


def draw_arc(
    draw: ImageDraw.ImageDraw,
    center_x: float,
    center_y: float,
    radius: float,
    start_radians: float,
    sweep_radians: float,
    color: tuple[int, int, int, int],
    width: int,
) -> None:
    bbox = (
        center_x - radius,
        center_y - radius,
        center_x + radius,
        center_y + radius,
    )
    start_deg = math.degrees(start_radians)
    end_deg = math.degrees(start_radians + sweep_radians)
    draw.arc(bbox, start=start_deg, end=end_deg, fill=color, width=width)


def add_white_orbits(base: Image.Image) -> None:
    crisp = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    glow = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    crisp_draw = ImageDraw.Draw(crisp)
    glow_draw = ImageDraw.Draw(glow)

    # Strong white orbits (matching star tone), no dark/gray tint.
    draw_arc(
        crisp_draw,
        WIDTH * 0.50,
        HEIGHT * 0.28,
        min(WIDTH * 0.45, 210),
        math.pi * 0.12,
        math.pi * 1.30,
        (*WHITE, 130),
        2,
    )
    draw_arc(
        crisp_draw,
        WIDTH * 0.32,
        HEIGHT * 0.82,
        min(WIDTH * 0.58, 260),
        -math.pi * 0.20,
        math.pi * 0.90,
        (*WHITE, 125),
        2,
    )

    # Soft white glow for the orbits.
    draw_arc(
        glow_draw,
        WIDTH * 0.50,
        HEIGHT * 0.28,
        min(WIDTH * 0.45, 210),
        math.pi * 0.12,
        math.pi * 1.30,
        (*WHITE, 70),
        5,
    )
    draw_arc(
        glow_draw,
        WIDTH * 0.32,
        HEIGHT * 0.82,
        min(WIDTH * 0.58, 260),
        -math.pi * 0.20,
        math.pi * 0.90,
        (*WHITE, 65),
        5,
    )

    glow = glow.filter(ImageFilter.GaussianBlur(radius=1.5))
    base.alpha_composite(glow)
    base.alpha_composite(crisp)


def add_shimmer_lines(base: Image.Image) -> None:
    shimmer = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shimmer)
    line_color = (*WHITE, 8)
    for y in range(0, HEIGHT, 14):
        draw.line(
            ((WIDTH * 0.08, y), (WIDTH * 0.92, y + 2)),
            fill=line_color,
            width=1,
        )
    shimmer = shimmer.filter(ImageFilter.GaussianBlur(radius=0.4))
    base.alpha_composite(shimmer)


def main() -> None:
    output_path = Path('assets/images/generated/mystical_background.png')
    output_path.parent.mkdir(parents=True, exist_ok=True)

    image = build_base_gradient()
    add_nebula(image)
    add_stars(image)
    add_white_orbits(image)
    add_shimmer_lines(image)
    image.save(output_path, format='PNG', optimize=True)

    print(f'Generated: {output_path} ({WIDTH}x{HEIGHT})')


if __name__ == '__main__':
    main()
