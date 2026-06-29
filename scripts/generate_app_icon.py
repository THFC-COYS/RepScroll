#!/usr/bin/env python3
"""Generate RepScroll 1024x1024 app icon."""
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
OUT = Path(__file__).resolve().parent.parent / "RepScroll/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def pixel(x, y):
    # Dark background
    t = y / SIZE
    r = lerp(12, 28, t)
    g = lerp(10, 18, t)
    b = lerp(18, 42, t)

    cx, cy = SIZE * 0.5, SIZE * 0.52
    dx, dy = (x - cx) / (SIZE * 0.32), (y - cy) / (SIZE * 0.38)
    d = math.sqrt(dx * dx + dy * dy)

    # Flame / rep ring
    if 0.55 < d < 0.92:
        ring_t = (d - 0.55) / 0.37
        r = lerp(255, 247, ring_t)
        g = lerp(107, 197, ring_t)
        b = lerp(53, 72, ring_t)

    # Inner glow
    if d < 0.5:
        glow = 1 - d / 0.5
        r = lerp(r, 255, glow * 0.5)
        g = lerp(g, 120, glow * 0.4)
        b = lerp(b, 80, glow * 0.3)

    # "R" barbell motif — horizontal bar
    if abs(y - cy) < SIZE * 0.04 and SIZE * 0.28 < x < SIZE * 0.72:
        r, g, b = 255, 245, 240

    # Vertical posts
    for px in (SIZE * 0.34, SIZE * 0.66):
        if abs(x - px) < SIZE * 0.035 and SIZE * 0.36 < y < SIZE * 0.68:
            r, g, b = 255, 107, 53

    return r, g, b


def write_png(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = bytearray()
    for y in range(SIZE):
        raw.append(0)
        for x in range(SIZE):
            r, g, b = pixel(x, y)
            raw.extend((r, g, b))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 9)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    path.write_bytes(png)
    print(f"Wrote {path}")


if __name__ == "__main__":
    write_png(OUT)