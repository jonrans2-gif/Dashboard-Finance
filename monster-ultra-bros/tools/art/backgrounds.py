"""Horizontally tileable parallax layers (512 px wide) for every theme.

Sky colours are not baked: the game draws a vertical gradient behind the
layers (see THEME_SKY in scripts/level/theme_db.gd), so layers stay small.
"""
import math

from pix import Canvas, hexc, mix, shade, rng

W = 512
WHITE = hexc("ffffff")


def wrap_set(c, x, y, col):
    c.set(int(x) % c.w, y, col)


def ridge(c, base_y, amp, waves, col, top_col=None, phase=0.0, rough=0):
    r = rng(int(base_y * 31 + amp))
    for x in range(c.w):
        t = x / c.w * 2 * math.pi
        y = base_y
        for k, (m, a) in enumerate(waves):
            y -= a * amp * math.sin(m * t + phase + k)
        if rough:
            y += r.randint(-rough, rough)
        y = int(y)
        c.vline(x, max(0, y), c.h - 1, col)
        if top_col:
            c.vline(x, max(0, y), max(0, y + 2), top_col)


def blob_wrapped(c, cx, cy, rx, ry, col):
    for dx in (-c.w, 0, c.w):
        c.ellipse(cx + dx, cy, rx, ry, col)


def cloud(c, x, y, s, col=WHITE, shade_col=None):
    shade_col = shade_col or hexc("dbe9f7")
    for (dx, dy, r) in [(0, 0, 9), (10, -5, 11), (22, 0, 9), (11, 3, 10)]:
        blob_wrapped(c, x + dx * s, y + dy * s, r * s, r * s * 0.8, shade_col)
    for (dx, dy, r) in [(0, -1, 8), (10, -6, 10), (22, -1, 8), (11, 1, 9)]:
        blob_wrapped(c, x + dx * s, y + dy * s, r * s, r * s * 0.8, col)


def tree(c, x, base, h, col, snow=False):
    for i in range(3):
        w = (3 - i) * h // 6 + 2
        y0 = base - h + i * h // 4
        for yy in range(h // 3):
            ww = int(w * (yy + 1) / (h / 3))
            c.hline(x - ww, x + ww, y0 + yy + i * 2, col)
            if snow and yy < 2:
                c.hline(x - ww, x + ww, y0 + yy + i * 2, WHITE)
    c.rect(x - 1, base - 2, 3, 4, shade(col, 0.6))


def hills():
    far = Canvas(W, 180)
    ridge(far, 120, 22, [(2, 1), (5, 0.4)], hexc("a8dcc0"), hexc("e6fff0"))
    for x in range(0, W, 128):
        c0 = x + 40
        far.poly([(c0 - 60, 140), (c0, 70), (c0 + 60, 140)], hexc("c3e8d6"))
        far.poly([(c0 - 16, 86), (c0, 70), (c0 + 16, 86), (c0 + 6, 90), (c0, 84), (c0 - 8, 90)], WHITE)
    near = Canvas(W, 140)
    ridge(near, 80, 18, [(3, 1), (7, 0.3)], hexc("5fc44f"), hexc("9be87a"))
    r = rng(4)
    for i in range(14):
        x = r.randrange(W)
        blob_wrapped(near, x, 78 + r.randrange(20), 10, 7, hexc("3f9a3a"))
        blob_wrapped(near, x - 2, 76 + r.randrange(16), 6, 4, hexc("7bd65f"))
    clouds = Canvas(W, 100)
    for (x, y, s) in [(20, 30, 1.0), (150, 55, 0.8), (260, 25, 1.2), (390, 60, 0.7), (450, 35, 0.9)]:
        cloud(clouds, x, y, s)
    return {"far": far, "near": near, "clouds": clouds}


def cave():
    far = Canvas(W, 270)
    r = rng(9)
    col = hexc("1a2446")
    for x in range(0, W, 2):
        h = int(30 + 25 * math.sin(x / W * 2 * math.pi * 3) + r.randint(0, 8))
        far.rect(x, 0, 2, h, col)
        hb = int(40 + 20 * math.sin(x / W * 2 * math.pi * 2 + 1) + r.randint(0, 6))
        far.rect(x, 270 - hb, 2, hb, col)
    for i in range(10):
        x = r.randrange(W); l = r.randrange(20, 60)
        far.poly([(x - 6, 0), (x + 6, 0), (x, l)], col)
    near = Canvas(W, 270)
    col2 = hexc("27346a")
    for i in range(6):
        x = i * W // 6 + r.randrange(30)
        near.rect(x, 0, 18, 270, col2)
        near.vline(x, 0, 269, hexc("324288"))
    for i in range(14):
        x = r.randrange(W); y = r.randrange(40, 230)
        cc = [hexc("5affe0"), hexc("8fe8ff"), hexc("b88aff")][i % 3]
        near.poly([(x - 3, y + 8), (x, y - 6), (x + 3, y + 8)], cc)
        near.set(x, y - 3, WHITE)
    return {"far": far, "near": near}


def fortress():
    far = Canvas(W, 200)
    col = hexc("2a2648")
    ridge(far, 170, 8, [(2, 1)], col)
    for i in range(5):
        x = i * W // 5 + 20
        h = 70 + (i * 37) % 50
        far.rect(x, 200 - h, 34, h, col)
        for k in range(0, 34, 8):
            far.rect(x + k, 200 - h - 6, 5, 6, col)
        far.poly([(x - 4, 200 - h - 6), (x + 17, 200 - h - 40), (x + 38, 200 - h - 6)], col)
        for k in range(3):
            far.rect(x + 8 + k * 8, 200 - h + 20, 3, 6, hexc("ffd86a"))
    near = Canvas(W, 270)
    for i in range(4):
        x = i * W // 4 + 40
        near.rect(x, 0, 22, 270, hexc("3a3658"))
        near.vline(x + 1, 0, 269, hexc("4a4670"))
        near.rect(x + 3, 40, 16, 40, hexc("c8ccd6"))
        near.poly([(x + 3, 80), (x + 19, 80), (x + 11, 90)], hexc("c8ccd6"))
        near.rect(x + 9, 52, 4, 14, hexc("23252d"))
    return {"far": far, "near": near}


def factory():
    far = Canvas(W, 220)
    col = hexc("2b2030")
    r = rng(5)
    x = 0
    while x < W:
        w = r.randrange(30, 70); h = r.randrange(60, 150)
        far.rect(x, 220 - h, w, h, col)
        if r.random() < 0.6:
            far.rect(x + w // 3, 220 - h - 40, 10, 40, col)
            for k in range(4):
                blob_wrapped(far, x + w // 3 + 5 + k * 6, 220 - h - 48 - k * 10, 8 + k * 2, 6 + k, hexc("3a2c3a"))
        for wy in range(220 - h + 10, 210, 14):
            for wx in range(x + 4, x + w - 6, 10):
                if r.random() < 0.4:
                    far.rect(wx, wy, 4, 5, hexc("ff9a3a"))
        x += w + r.randrange(0, 10)
    near = Canvas(W, 270)
    pipe = hexc("3a3f4c"); hi = hexc("565d6d")
    near.rect(0, 30, W, 10, pipe); near.hline(0, W - 1, 31, hi)
    near.rect(0, 230, W, 8, pipe); near.hline(0, W - 1, 231, hi)
    for i in range(5):
        x = i * W // 5 + 30
        near.rect(x, 40, 10, 190, pipe); near.vline(x + 2, 40, 229, hi)
        near.circle(x + 5, 120, 4, hexc("7dff5a"))
    for (gx, gy, gr) in [(90, 160, 26), (300, 90, 20), (430, 180, 30)]:
        for a in range(0, 360, 30):
            rr = math.radians(a)
            near.circle(gx + gr * math.cos(rr), gy + gr * math.sin(rr), 5, hexc("2e3240"))
        near.circle(gx, gy, gr, hexc("2e3240"))
        near.circle(gx, gy, gr * 0.35, hexc("1a1420"))
    return {"far": far, "near": near}


def ice():
    far = Canvas(W, 200)
    for i, x in enumerate(range(0, W, 128)):
        c0 = x + 64
        h = 120 + (i % 2) * 30
        far.poly([(c0 - 110, 200), (c0, 200 - h), (c0 + 110, 200)], hexc("a9cbe6"))
        far.poly([(c0 - 30, 200 - h + 32), (c0, 200 - h), (c0 + 30, 200 - h + 32), (c0 + 10, 200 - h + 38), (c0, 200 - h + 30), (c0 - 14, 200 - h + 40)], WHITE)
    ridge(far, 180, 6, [(4, 1)], hexc("c9e3f5"))
    near = Canvas(W, 150)
    ridge(near, 120, 10, [(3, 1)], hexc("eef8ff"), WHITE)
    r = rng(8)
    for i in range(18):
        x = r.randrange(W)
        tree(near, x, 122 + r.randrange(6), 30 + r.randrange(20), hexc("3f7a8a"), snow=True)
    clouds = Canvas(W, 100)
    for (x, y, s) in [(30, 40, 0.9), (200, 25, 1.1), (360, 55, 0.8)]:
        cloud(clouds, x, y, s, hexc("f4fbff"), hexc("d4e8f5"))
    return {"far": far, "near": near, "clouds": clouds}


def ultra():
    far = Canvas(W, 270)
    r = rng(12)
    for i in range(120):
        far.set(r.randrange(W), r.randrange(200), [WHITE, hexc("8fe8ff"), hexc("ff9af0")][i % 3])
    # neon grid horizon
    hz = 190
    for y in range(hz, 270):
        if (y - hz) in (0, 3, 8, 15, 25, 38, 55, 76):
            far.hline(0, W - 1, y, hexc("ff3fd8"))
    for x in range(0, W, 32):
        far.line(x, hz, x + (x - W // 2) // 1.5, 269, hexc("8a2fb0"))
    far.hline(0, W - 1, hz, hexc("39e6ff"))
    near = Canvas(W, 270)
    for i in range(7):
        x = r.randrange(W); y = r.randrange(30, 170); s = r.randrange(8, 18)
        col = [hexc("39e6ff"), hexc("ff3fd8"), hexc("7dff5a")][i % 3]
        pts = [(x, y - s), (x + s, y), (x, y + s), (x - s, y)]
        for k in range(4):
            a, b = pts[k], pts[(k + 1) % 4]
            near.line(a[0], a[1], b[0], b[1], col)
        near.set(x, y, WHITE)
    for i in range(6):
        y = r.randrange(20, 200); x = r.randrange(W); l = r.randrange(20, 60)
        near.hline(x, x + l, y, hexc("39e6ff", 160))
    return {"far": far, "near": near}


def build():
    for name, fn in [("hills", hills), ("cave", cave), ("fortress", fortress),
                     ("factory", factory), ("ice", ice), ("ultra", ultra)]:
        for layer, cv in fn().items():
            cv.save(f"bg/{name}_{layer}.png")


if __name__ == "__main__":
    build()
