"""16x16 tilesets. Every theme shares the same atlas layout (8x6 tiles) so the
level builder can map level characters to atlas coordinates once; only the art
differs per theme. Layout (col,row):

 row0: ground TL, ground T, ground TR, fill, brick, energy-block x3 (anim)
 row1: used block, hard block, platform L/M/R, barrier, spikes, ice floor
 row2: pipe top L/R, pipe body L/R, conveyor-left x2 (anim), conveyor-right x2
 row3: wall L, wall R, (empty), deco bush, deco flower, deco fence, deco lamp, deco arrow
 row4: bg wall, bg wall alt, deco chain, goo top x2 (anim), goo fill, cloud, snow cap
 row5: fill-variant, grass-variant, cracked brick, deco window, deco torch x2, deco sign, deco crystal
"""
from pix import Canvas, hexc, mix, shade, rng

T = 16
WHITE = hexc("ffffff")
DARK = hexc("1a1a24")

THEMES = {
    "hills": dict(top=[hexc("7be35a"), hexc("4fbf3f"), hexc("2f8a33")], fill=[hexc("b97b45"), hexc("98613a"), hexc("6e4428")],
                  brick=[hexc("d9774a"), hexc("a84f2f"), hexc("5c2a1a")], hard=[hexc("c8ccd6"), hexc("9aa1b0"), hexc("5f6676")],
                  plat=[hexc("ffffff"), hexc("d8e2f0"), hexc("9fb2cc")], pipe=[hexc("ffffff"), hexc("c4c9d4"), hexc("6b7282")],
                  goo=[hexc("ff9a3a"), hexc("ff5a1f"), hexc("b8300f")], bg=[hexc("6e4428"), hexc("5a3720")], accent=hexc("23252d")),
    "cave": dict(top=[hexc("6f8fd6"), hexc("4a67b0"), hexc("2c3f78")], fill=[hexc("3a4f8a"), hexc("2c3d6e"), hexc("1d2a50")],
                 brick=[hexc("5f86d8"), hexc("3b5aa8"), hexc("1f2f63")], hard=[hexc("8a9cc4"), hexc("5f7098"), hexc("38446a")],
                 plat=[hexc("9fb4e0"), hexc("6f86bd"), hexc("3f5288")], pipe=[hexc("ffffff"), hexc("c4c9d4"), hexc("6b7282")],
                 goo=[hexc("5affe0"), hexc("1ec8b0"), hexc("0f7a6c")], bg=[hexc("1d2a50"), hexc("17223f")], accent=hexc("23252d")),
    "fortress": dict(top=[hexc("f2f4f8"), hexc("c8ccd6"), hexc("8d94a3")], fill=[hexc("b4bac6"), hexc("8d94a3"), hexc("5f6676")],
                     brick=[hexc("e6e9ef"), hexc("b4bac6"), hexc("6b7282")], hard=[hexc("9aa1b0"), hexc("6b7282"), hexc("3f4452")],
                     plat=[hexc("c8ccd6"), hexc("9aa1b0"), hexc("5f6676")], pipe=[hexc("ffffff"), hexc("c4c9d4"), hexc("6b7282")],
                     goo=[hexc("ffb03a"), hexc("ff5a1f"), hexc("a8200f")], bg=[hexc("4a4f5e"), hexc("3c4050")], accent=hexc("23252d")),
    "factory": dict(top=[hexc("ffc928"), hexc("8a93a8"), hexc("4c5262")], fill=[hexc("6f7788"), hexc("565d6d"), hexc("3a3f4c")],
                    brick=[hexc("c98a4a"), hexc("9a6535"), hexc("5a3a1e")], hard=[hexc("9aa1b0"), hexc("6f7788"), hexc("434958")],
                    plat=[hexc("aeb6c6"), hexc("7f8798"), hexc("4c5262")], pipe=[hexc("7dff5a"), hexc("3fbf3a"), hexc("1f6b22")],
                    goo=[hexc("b8ff3a"), hexc("6fd11f"), hexc("2f7a12")], bg=[hexc("2e3240"), hexc("262a36")], accent=hexc("ff3fd8")),
    "ice": dict(top=[hexc("ffffff"), hexc("dff3ff"), hexc("a8d6f2")], fill=[hexc("8fc0e0"), hexc("6a9cc4"), hexc("466f99")],
                brick=[hexc("cdeeff"), hexc("8fd0f2"), hexc("3f86b8")], hard=[hexc("bcd6ea"), hexc("8aaac6"), hexc("55708f")],
                plat=[hexc("ffffff"), hexc("cfeaff"), hexc("8fc0e0")], pipe=[hexc("ffffff"), hexc("c4c9d4"), hexc("6b7282")],
                goo=[hexc("8afcff"), hexc("39d8ff"), hexc("1a7fb8")], bg=[hexc("466f99"), hexc("3a5d80")], accent=hexc("39e6ff")),
    "ultra": dict(top=[hexc("39e6ff"), hexc("5a3fa0"), hexc("2c1f55")], fill=[hexc("3a2a6e"), hexc("2c1f55"), hexc("1c133a")],
                  brick=[hexc("ff3fd8"), hexc("8a2fb0"), hexc("3a1260")], hard=[hexc("6a5aa8"), hexc("4a3c85"), hexc("2a1f55")],
                  plat=[hexc("39e6ff"), hexc("2a9fd0"), hexc("1a5a8a")], pipe=[hexc("ffffff"), hexc("c4c9d4"), hexc("6b7282")],
                  goo=[hexc("ff6af0"), hexc("d02fd0"), hexc("7a128a")], bg=[hexc("1c133a"), hexc("160f2e")], accent=hexc("ff3fd8")),
}


def tile():
    return Canvas(T, T)


def fill_tile(st, r, variant=0):
    c = tile()
    a, b, d = st["fill"]
    c.rect(0, 0, T, T, b)
    for _ in range(10 + variant * 6):
        x, y = r.randrange(T), r.randrange(T)
        c.set(x, y, d)
        c.set(x + 1, y, a if r.random() < 0.5 else d)
    return c


def ground_top(st, r, edge=None, variant=0):
    c = fill_tile(st, r)
    t0, t1, t2 = st["top"]
    for x in range(T):
        h = 4 + (1 if (x * 7 + variant) % 5 == 0 else 0)
        c.vline(x, 0, h - 1, t1)
        c.set(x, 0, t0)
        c.set(x, h, t2)
        if (x + variant) % 4 == 0:
            c.set(x, 1, t0)
    if variant:
        c.set(4, 0, WHITE); c.set(11, 1, WHITE)
    if edge == "L":
        c.vline(0, 0, T - 1, st["fill"][2]); c.vline(0, 0, 4, t2)
    if edge == "R":
        c.vline(T - 1, 0, T - 1, st["fill"][2]); c.vline(T - 1, 0, 4, t2)
    return c


def wall(st, r, side):
    c = fill_tile(st, r)
    x = 0 if side == "L" else T - 1
    c.vline(x, 0, T - 1, st["top"][2])
    c.vline(x + (1 if side == "L" else -1), 0, T - 1, st["top"][1])
    return c


def brick(st, cracked=False):
    c = tile()
    a, b, d = st["brick"]
    c.rect(0, 0, T, T, b)
    for row in range(4):
        y = row * 4
        c.hline(0, T - 1, y + 3, d)
        off = 0 if row % 2 == 0 else 4
        for x in range(off, T, 8):
            c.vline(x, y, y + 2, d)
            c.set(x + 1, y, a)
        c.hline(0, T - 1, y, a)
    if cracked:
        c.line(3, 2, 8, 9, DARK); c.line(8, 9, 12, 13, DARK)
    return c


def energy_block(st, frame):
    c = tile()
    gold = [hexc("ffe15a"), hexc("ffc928"), hexc("c98e12")]
    glow = [hexc("ffffff"), hexc("fff3b0"), hexc("ffe15a")][frame]
    c.rect(0, 0, T, T, gold[1])
    c.hline(0, T - 1, 0, gold[0]); c.vline(0, 0, T - 1, gold[0])
    c.hline(0, T - 1, T - 1, gold[2]); c.vline(T - 1, 0, T - 1, gold[2])
    for (x, y) in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        c.set(x, y, gold[2])
    bolt = [(10, 2), (4, 9), (7.5, 9), (5, 14), (12, 6.5), (8.5, 6.5), (11, 2)]
    c.poly(bolt, glow)
    for (x, y) in [(10, 2), (9, 3), (8, 4), (7, 5), (6, 6), (5, 7), (4, 8)]:
        c.set(x, y + 1, gold[2])
    c.set(5, 14, gold[2]); c.set(6, 13, gold[2])
    return c


def used_block(st):
    c = tile()
    c.rect(0, 0, T, T, hexc("8a6a4a"))
    c.hline(0, T - 1, 0, hexc("a8865f")); c.vline(0, 0, T - 1, hexc("a8865f"))
    c.hline(0, T - 1, T - 1, hexc("4a3420")); c.vline(T - 1, 0, T - 1, hexc("4a3420"))
    for (x, y) in [(2, 2), (13, 2), (2, 13), (13, 13)]:
        c.set(x, y, hexc("4a3420"))
    return c


def hard_block(st):
    c = tile()
    a, b, d = st["hard"]
    c.rect(0, 0, T, T, b)
    c.poly([(0, 0), (16, 0), (13, 3), (3, 3), (3, 13), (0, 16)], a)
    c.poly([(16, 0), (16, 16), (0, 16), (3, 13), (13, 13), (13, 3)], d)
    c.rect(3, 3, 10, 10, b)
    return c


def platform(st, part):
    c = tile()
    a, b, d = st["plat"]
    c.rect(0, 0, T, 6, b)
    c.hline(0, T - 1, 0, a)
    c.hline(0, T - 1, 5, d)
    if part == "L":
        c.vline(0, 0, 5, d); c.set(0, 0, CLEAR_())
    if part == "R":
        c.vline(T - 1, 0, 5, d); c.set(T - 1, 0, CLEAR_())
    for x in range(3, T, 6):
        c.set(x, 2, d); c.set(x, 3, d)
    return c


def CLEAR_():
    return (0, 0, 0, 0)


def barrier():
    c = tile()
    col = [hexc("ff8af0"), hexc("ff3fd8"), hexc("9a1a90")]
    c.rect(1, 1, 14, 14, col[1])
    c.poly([(1, 1), (15, 1), (8, 8)], col[0])
    c.poly([(1, 15), (15, 15), (8, 8)], col[2])
    c.line(4, 4, 11, 11, WHITE); c.line(11, 4, 4, 11, hexc("ffd0f8"))
    c.outline(DARK)
    return c


def spikes():
    c = tile()
    for i in range(4):
        x = i * 4
        c.poly([(x, 16), (x + 4, 16), (x + 2, 5)], hexc("c8ccd6"))
        c.vline(x + 2, 6, 15, WHITE)
        c.vline(x + 3, 9, 15, hexc("8d94a3"))
    c.hline(0, 15, 15, hexc("5f6676"))
    return c


def ice_floor(st):
    c = tile()
    c.rect(0, 0, T, T, hexc("a8e4ff"))
    c.rect(0, 0, T, 3, hexc("e8f8ff"))
    c.line(2, 6, 7, 3, WHITE); c.line(9, 12, 14, 8, WHITE); c.line(3, 13, 5, 11, hexc("e8f8ff"))
    c.hline(0, T - 1, T - 1, hexc("5fa8d8"))
    return c


def pipe(st, part):
    c = tile()
    a, b, d = st["pipe"]
    ring = DARK
    left = part in ("TL", "L")
    def body(y0):
        if left:
            c.rect(2, y0, 14, T - y0, b); c.vline(1, y0, T - 1, ring); c.rect(3, y0, 4, T - y0, a)
        else:
            c.rect(0, y0, 14, T - y0, b); c.vline(14, y0, T - 1, ring); c.rect(9, y0, 4, T - y0, d)
    if part in ("TL", "TR"):
        c.rect(0, 0, T, 8, b)
        c.hline(0, T - 1, 0, ring); c.hline(0, T - 1, 7, ring)
        if left:
            c.vline(0, 0, 7, ring); c.rect(2, 1, 4, 6, a)
        else:
            c.vline(T - 1, 0, 7, ring); c.rect(10, 1, 4, 6, d)
        body(8)
        c.hline(0 if left else 0, T - 1, 8, shade(b, 0.7))
    else:
        body(0)
    return c


def conveyor(direction, frame):
    c = tile()
    c.rect(0, 0, T, T, hexc("3a3f4c"))
    c.rect(0, 0, T, 4, hexc("26262e"))
    for x in range(-8, T + 8, 4):
        xx = x + (frame * 2 if direction > 0 else -frame * 2)
        c.vline(xx % T, 0, 3, hexc("ffc928"))
    for cx in (4, 12):
        c.circle(cx, 10, 3, hexc("8a93a8"))
        c.set(cx + (1 if frame else -1), 9, DARK)
    c.hline(0, T - 1, 15, DARK)
    arrow = hexc("7dff5a")
    if direction > 0:
        c.set(7, 13, arrow); c.set(8, 13, arrow); c.set(9, 13, arrow); c.set(8, 12, arrow); c.set(8, 14, arrow); c.set(10, 13, arrow)
    else:
        c.set(6, 13, arrow); c.set(7, 13, arrow); c.set(8, 13, arrow); c.set(7, 12, arrow); c.set(7, 14, arrow); c.set(5, 13, arrow)
    return c


def goo(st, frame, top=True):
    c = tile()
    a, b, d = st["goo"]
    c.rect(0, 0 if not top else 4, T, T, b)
    if top:
        for x in range(T):
            y = 3 + int(1.5 * (1 + __import__("math").sin((x + frame * 4) * 0.8)))
            c.vline(x, y, 6, a)
            c.set(x, y, WHITE if (x + frame) % 7 == 0 else a)
    for (x, y) in [(3, 10), (11, 13), (7, 8)]:
        c.set((x + frame * 3) % T, y, d)
    return c


def bg_wall(st, alt=False):
    c = tile()
    a, b = st["bg"]
    c.rect(0, 0, T, T, a)
    if not alt:
        for row in range(2):
            y = row * 8
            c.hline(0, T - 1, y + 7, b)
            off = 0 if row % 2 == 0 else 8
            c.vline(off, y, y + 6, b)
    else:
        c.rect(3, 3, 10, 10, b)
        c.hline(3, 12, 3, mix(a, WHITE, 0.08))
    return c


def cloud_plat():
    c = tile()
    c.ellipse(4, 5, 4.5, 4, WHITE); c.ellipse(11, 4, 5, 4, WHITE)
    c.hline(0, 15, 8, hexc("cfe0f4"))
    c.rect(0, 5, 16, 3, WHITE)
    return c


def snow_cap(st):
    c = hard_block(st)
    c.rect(0, 0, T, 4, WHITE)
    for x in range(0, T, 3):
        c.set(x, 4, WHITE)
    return c


# --- decorations ---------------------------------------------------------
def deco_bush(st, r):
    c = tile()
    g = st["top"]
    for (x, y, rr) in [(4, 11, 4), (9, 9, 5), (13, 12, 3)]:
        c.circle(x, y, rr, g[1])
    c.circle(8, 8, 2, g[0]); c.circle(4, 10, 1.5, g[0])
    c.rect(0, 13, T, 3, g[1])
    c.outline(g[2])
    return c


def deco_flower(st, r):
    c = tile()
    c.vline(7, 9, 15, st["top"][2])
    c.set(6, 12, st["top"][1]); c.set(8, 11, st["top"][1])
    col = st["accent"] if st["accent"] != hexc("23252d") else hexc("ff6a8a")
    c.circle(7, 7, 2.5, col); c.set(7, 7, hexc("ffe15a"))
    c.vline(12, 12, 15, st["top"][1]); c.vline(3, 13, 15, st["top"][1])
    return c


def deco_fence(st, r):
    c = tile()
    col = st["plat"][1]
    for x in (2, 8, 14):
        c.vline(x, 5, 15, col); c.set(x, 4, st["plat"][0])
    c.hline(0, 15, 7, col); c.hline(0, 15, 12, col)
    c.outline(st["plat"][2])
    return c


def deco_lamp(st, r):
    c = tile()
    c.vline(7, 6, 15, hexc("3a3f4c")); c.vline(8, 6, 15, hexc("23252d"))
    c.circle(7.5, 4, 3, st["accent"] if st["accent"] != hexc("23252d") else hexc("ffe15a"))
    c.circle(7.5, 4, 1.4, WHITE)
    return c


def deco_arrow(st, r):
    c = tile()
    c.vline(7, 8, 15, hexc("6e4428")); c.vline(8, 8, 15, hexc("5a3720"))
    c.rect(2, 2, 12, 7, hexc("d9a066"))
    c.outline(hexc("5a3720"))
    for (x, y) in [(5, 5), (6, 5), (7, 5), (8, 5), (9, 5), (8, 4), (8, 6), (10, 5)]:
        c.set(x, y, DARK)
    return c


def deco_window(st, r):
    c = tile()
    c.rect(3, 2, 10, 12, hexc("1a1d26"))
    c.rect(4, 3, 8, 10, hexc("ffd86a"))
    c.vline(7, 3, 12, hexc("1a1d26")); c.vline(8, 3, 12, hexc("1a1d26")); c.hline(4, 11, 7, hexc("1a1d26"))
    c.rect(4, 3, 3, 3, hexc("fff3c0"))
    return c


def deco_torch(st, frame):
    c = tile()
    c.rect(6, 9, 4, 6, hexc("5a3720"))
    c.hline(5, 10, 9, hexc("8a5a30"))
    flame = [hexc("fff3a0"), hexc("ffb21a"), hexc("ff5a1f")]
    h = 6 if frame == 0 else 5
    c.ellipse(8, 9 - h / 2, 2.5, h / 2 + 0.5, flame[2])
    c.ellipse(8, 9 - h / 2 + 0.5, 1.6, h / 2 - 0.5, flame[1])
    c.set(8, 7, flame[0]); c.set(7 + frame, 6, flame[0])
    return c


def deco_sign(st, r):
    c = tile()
    c.vline(7, 9, 15, hexc("5a3720"))
    c.rect(1, 1, 14, 9, hexc("d9a066")); c.outline(hexc("5a3720"))
    # little can icon on sign
    c.rect(6, 3, 4, 5, WHITE); c.hline(6, 9, 3, DARK); c.set(7, 5, DARK); c.set(8, 6, DARK)
    return c


def deco_crystal(st, r):
    c = tile()
    col = st["accent"] if st["accent"] != hexc("23252d") else hexc("8fe8ff")
    c.poly([(4, 16), (6, 6), (9, 16)], col)
    c.poly([(8, 16), (11, 3), (14, 16)], mix(col, WHITE, 0.35))
    c.vline(11, 5, 14, WHITE)
    c.outline(shade(col, 0.5))
    return c


def build_theme(name, st):
    r = rng(hash(name) & 0xffff)
    atlas = Canvas(8 * T, 6 * T)
    def put(cx, cy, t):
        atlas.blit(t, cx * T, cy * T)
    put(0, 0, ground_top(st, r, "L")); put(1, 0, ground_top(st, r)); put(2, 0, ground_top(st, r, "R"))
    put(3, 0, fill_tile(st, r)); put(4, 0, brick(st))
    for i in range(3):
        put(5 + i, 0, energy_block(st, i))
    put(0, 1, used_block(st)); put(1, 1, hard_block(st))
    put(2, 1, platform(st, "L")); put(3, 1, platform(st, "M")); put(4, 1, platform(st, "R"))
    put(5, 1, barrier()); put(6, 1, spikes()); put(7, 1, ice_floor(st))
    put(0, 2, pipe(st, "TL")); put(1, 2, pipe(st, "TR")); put(2, 2, pipe(st, "L")); put(3, 2, pipe(st, "R"))
    put(4, 2, conveyor(-1, 0)); put(5, 2, conveyor(-1, 1)); put(6, 2, conveyor(1, 0)); put(7, 2, conveyor(1, 1))
    put(0, 3, wall(st, r, "L")); put(1, 3, wall(st, r, "R"))
    put(3, 3, deco_bush(st, r)); put(4, 3, deco_flower(st, r)); put(5, 3, deco_fence(st, r)); put(6, 3, deco_lamp(st, r)); put(7, 3, deco_arrow(st, r))
    put(0, 4, bg_wall(st)); put(1, 4, bg_wall(st, True))
    ch = tile(); [ch.set(7 + (y % 2), y, hexc("8d94a3")) for y in range(16)]; put(2, 4, ch)
    put(3, 4, goo(st, 0)); put(4, 4, goo(st, 1)); put(5, 4, goo(st, 0, top=False))
    put(6, 4, cloud_plat()); put(7, 4, snow_cap(st))
    put(0, 5, fill_tile(st, r, 1)); put(1, 5, ground_top(st, r, variant=3)); put(2, 5, brick(st, cracked=True))
    put(3, 5, deco_window(st, r)); put(4, 5, deco_torch(st, 0)); put(5, 5, deco_torch(st, 1)); put(6, 5, deco_sign(st, r)); put(7, 5, deco_crystal(st, r))
    atlas.save(f"tiles/{name}.png")


def build():
    for name, st in THEMES.items():
        build_theme(name, st)


if __name__ == "__main__":
    build()
