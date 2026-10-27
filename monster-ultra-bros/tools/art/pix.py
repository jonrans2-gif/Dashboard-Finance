"""Tiny pixel-art toolkit used by the asset generators.

Everything is drawn at 1x on RGBA canvases and saved as PNG; Godot renders
them with nearest-neighbour filtering so the pixels stay crisp.
"""
from __future__ import annotations

import json
import math
import os
import random
from typing import Iterable

from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets")


def hexc(s: str, a: int = 255) -> tuple[int, int, int, int]:
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def mix(c1, c2, t: float):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(4))


def shade(c, f: float):
    """f < 1 darkens, f > 1 brightens."""
    if f >= 1:
        return mix(c, (255, 255, 255, c[3]), min(1.0, f - 1))
    return (int(c[0] * f), int(c[1] * f), int(c[2] * f), c[3])


CLEAR = (0, 0, 0, 0)
OUTLINE = hexc("1a1a24")


class Canvas:
    def __init__(self, w: int, h: int, fill=CLEAR):
        self.w, self.h = w, h
        self.img = Image.new("RGBA", (w, h), fill)
        self.px = self.img.load()

    # --- primitives -------------------------------------------------------
    def set(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            if c[3] == 255 or c[3] == 0:
                self.px[x, y] = c
            else:
                self.px[x, y] = blend(self.px[x, y], c)

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[x, y]
        return CLEAR

    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y + h)):
            for xx in range(int(x), int(x + w)):
                self.set(xx, yy, c)

    def hline(self, x0, x1, y, c):
        for x in range(int(x0), int(x1) + 1):
            self.set(x, y, c)

    def vline(self, x, y0, y1, c):
        for y in range(int(y0), int(y1) + 1):
            self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.set(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, c, fill=True):
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                d = ((x + 0.5 - cx) / max(rx, 0.01)) ** 2 + ((y + 0.5 - cy) / max(ry, 0.01)) ** 2
                if fill and d <= 1.0:
                    self.set(x, y, c)
                elif not fill and 0.7 <= d <= 1.15:
                    self.set(x, y, c)

    def circle(self, cx, cy, r, c, fill=True):
        self.ellipse(cx, cy, r, r, c, fill)

    def poly(self, pts, c):
        """Scanline polygon fill."""
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            yc = y + 0.5
            xs = []
            n = len(pts)
            for i in range(n):
                x0, y0 = pts[i]
                x1, y1 = pts[(i + 1) % n]
                if (y0 <= yc < y1) or (y1 <= yc < y0):
                    xs.append(x0 + (yc - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(math.ceil(xs[i] - 0.5)), int(math.floor(xs[i + 1] - 0.5)) + 1):
                    self.set(x, y, c)

    def blit(self, other: "Canvas", ox, oy, flip_x=False):
        for y in range(other.h):
            for x in range(other.w):
                c = other.px[other.w - 1 - x if flip_x else x, y]
                if c[3]:
                    self.set(ox + x, oy + y, c)

    # --- effects ------------------------------------------------------------
    def outline(self, c=OUTLINE, diagonal=False):
        """Add a 1px outline around opaque pixels."""
        src = [[self.px[x, y][3] > 0 for x in range(self.w)] for y in range(self.h)]
        nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            nb += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
        for y in range(self.h):
            for x in range(self.w):
                if src[y][x]:
                    continue
                for dx, dy in nb:
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < self.w and 0 <= yy < self.h and src[yy][xx]:
                        self.px[x, y] = c
                        break

    def recolor(self, mapping: dict):
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[x, y]
                if c in mapping:
                    self.px[x, y] = mapping[c]

    def noise(self, x, y, w, h, colors, density, rng):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                if rng.random() < density and self.get(xx, yy)[3]:
                    self.set(xx, yy, rng.choice(colors))

    def flipped(self) -> "Canvas":
        out = Canvas(self.w, self.h)
        out.img = self.img.transpose(Image.FLIP_LEFT_RIGHT)
        out.px = out.img.load()
        return out

    def save(self, rel):
        path = os.path.join(OUT, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        self.img.save(path, optimize=True)
        return path


def blend(dst, src):
    a = src[3] / 255.0
    da = dst[3] / 255.0
    oa = a + da * (1 - a)
    if oa <= 0:
        return CLEAR
    r = [(src[i] * a + dst[i] * da * (1 - a)) / oa for i in range(3)]
    return (int(r[0]), int(r[1]), int(r[2]), int(oa * 255))


class Sheet:
    """Collects equally sized frames into a horizontal strip + JSON metadata.

    The JSON maps animation name -> {frames:[indices], fps, loop} and is read
    by res://scripts/core/sprite_lib.gd to build SpriteFrames at runtime.
    """

    def __init__(self, fw: int, fh: int):
        self.fw, self.fh = fw, fh
        self.frames: list[Canvas] = []
        self.anims: dict = {}

    def add(self, c: Canvas) -> int:
        assert c.w == self.fw and c.h == self.fh, (c.w, c.h, self.fw, self.fh)
        self.frames.append(c)
        return len(self.frames) - 1

    def anim(self, name, canvases: Iterable[Canvas], fps=8, loop=True):
        idx = [self.add(c) for c in canvases]
        self.anims[name] = {"frames": idx, "fps": fps, "loop": loop}

    def save(self, rel, cols=None):
        n = len(self.frames)
        cols = cols or min(n, 16)
        rows = (n + cols - 1) // cols
        img = Canvas(cols * self.fw, rows * self.fh)
        for i, f in enumerate(self.frames):
            img.blit(f, (i % cols) * self.fw, (i // cols) * self.fh)
        img.save(rel)
        meta = {"frame_w": self.fw, "frame_h": self.fh, "cols": cols, "animations": self.anims}
        path = os.path.join(OUT, rel.rsplit(".", 1)[0] + ".json")
        with open(path, "w") as fh:
            json.dump(meta, fh, indent=1)


def rng(seed) -> random.Random:
    return random.Random(seed)
