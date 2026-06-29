#!/usr/bin/env python3
"""Generate App Store screenshot frames (6.7\" iPhone — 1290×2796)."""
import math
import struct
import zlib
from pathlib import Path

W, H = 1290, 2796
OUT_DIR = Path(__file__).resolve().parent.parent / "AppStore/screenshots"

FRAMES = [
    ("01-home", "Reps before\nyou scroll", "Build streaks. Earn scroll time.", "flame"),
    ("02-challenge", "AI counts\nyour reps", "Push-ups, squats, plank — on-device.", "camera"),
    ("03-gate", "Earn your\nscroll time", "10 push-ups unlocks the feed.", "lock"),
    ("04-history", "Track every\nsession", "Streaks, charts, achievements.", "chart"),
    ("05-premium", "Go Premium", "Unlimited gates · 30-min unlocks.", "crown"),
]

BG_TOP = (10, 10, 16)
BG_BOTTOM = (22, 14, 32)
ACCENT = (255, 107, 53)
ACCENT2 = (247, 197, 72)
TEXT = (245, 245, 247)
SUBTEXT = (150, 150, 158)


def lerp(a, b, t):
    return int(a + (b - a) * t)


def bg_color(y):
    t = y / H
    return tuple(lerp(BG_TOP[i], BG_BOTTOM[i], t) for i in range(3))


def draw_phone_mock(x0, y0, pw, ph):
    """Return list of (x,y,r,g,b) pixels for phone bezel + screen."""
    pixels = []
    radius = 48
    for y in range(y0, y0 + ph):
        for x in range(x0, x0 + pw):
            # Bezel
            inside = (
                radius < x - x0 < pw - radius or radius < y - y0 < ph - radius
                or ((x - x0 - radius) ** 2 + (y - y0 - radius) ** 2) >= radius ** 2
                and ((x - x0 - (pw - radius)) ** 2 + (y - y0 - radius) ** 2) >= radius ** 2
                and ((x - x0 - radius) ** 2 + (y - y0 - (ph - radius)) ** 2) >= radius ** 2
                and ((x - x0 - (pw - radius)) ** 2 + (y - y0 - (ph - radius)) ** 2) >= radius ** 2
            )
            if x0 <= x < x0 + pw and y0 <= y < y0 + ph:
                if inside:
                    # Screen gradient
                    t = (y - y0) / ph
                    r = lerp(18, 32, t)
                    g = lerp(16, 22, t)
                    b = lerp(28, 48, t)
                    # Orange accent bar at top
                    if y - y0 < 120:
                        r, g, b = lerp(r, ACCENT[0], 0.35), lerp(g, ACCENT[1], 0.35), lerp(b, ACCENT[2], 0.35)
                    pixels.append((x, y, r, g, b))
                else:
                    pixels.append((x, y, 40, 40, 45))
    return pixels


def draw_icon(cx, cy, kind, size=120):
    pixels = []
    for dy in range(-size, size):
        for dx in range(-size, size):
            x, y = cx + dx, cy + dy
            if not (0 <= x < W and 0 <= y < H):
                continue
            d = math.sqrt(dx * dx + dy * dy) / size
            if d > 1:
                continue
            if kind == "flame":
                r, g, b = ACCENT if d > 0.4 else ACCENT2
            elif kind == "camera":
                r, g, b = (60, 60, 70) if d > 0.75 else ACCENT
            elif kind == "lock":
                r, g, b = ACCENT2 if d < 0.5 else ACCENT
            elif kind == "chart":
                r, g, b = ACCENT if dx > 0 else ACCENT2
            else:
                r, g, b = ACCENT2
            pixels.append((x, y, r, g, b))
    return pixels


def write_png(path: Path, headline: str, subtitle: str, icon: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    buf = [[bg_color(y) for _ in range(W)] for y in range(H)]

    # Phone mock centered lower
    pw, ph = 900, 1840
    x0, y0 = (W - pw) // 2, 820
    for x, y, r, g, b in draw_phone_mock(x0, y0, pw, ph):
        buf[y][x] = (r, g, b)

    # Icon in phone screen
    for x, y, r, g, b in draw_icon(W // 2, y0 + 520, icon, 100):
        buf[y][x] = (r, g, b)

    # Headline area — simple block letters via rectangles (decorative bars)
    hy = 180
    for y in range(hy, hy + 12):
        for x in range(120, W - 120):
            buf[y][x] = ACCENT

    raw = bytearray()
    for y in range(H):
        raw.append(0)
        for x in range(W):
            raw.extend(buf[y][x])

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 9)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    path.write_bytes(png)

    # Sidecar caption file for ASC upload reference
    txt = path.with_suffix(".txt")
    txt.write_text(f"{headline.replace(chr(10), ' ')}\n{subtitle}\n", encoding="utf-8")
    print(f"Wrote {path}")


def main():
    for slug, headline, subtitle, icon in FRAMES:
        write_png(OUT_DIR / f"{slug}-6.7.png", headline, subtitle, icon)
    print(f"\n{len(FRAMES)} frames in {OUT_DIR}")
    print("Replace phone mock with real device screenshots before App Store submit.")


if __name__ == "__main__":
    main()