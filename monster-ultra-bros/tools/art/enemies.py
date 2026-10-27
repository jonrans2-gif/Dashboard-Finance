"""Enemies, hazards and bosses."""
import math

from pix import Canvas, Sheet, hexc, mix, shade, rng

PUPIL = hexc("101018")
WHITE = hexc("ffffff")
RED = hexc("ff3048")
DARK = hexc("1a1a24")


def angry_eyes(c, x, y, gap=4, pupil_dx=0, color=WHITE, pupil=PUPIL, size=2):
    for ex in (x, x + gap):
        c.rect(ex, y, size, size + 1, color)
        c.set(ex + (1 if pupil_dx >= 0 else 0), y + 1, pupil)
        c.set(ex + (1 if pupil_dx >= 0 else 0), y + size, pupil)
    # angry brows
    c.line(x - 1, y - 2, x + size - 1, y - 1, DARK)
    c.line(x + gap + size, y - 2, x + gap, y - 1, DARK)


# ---------------------------------------------------------------- Empty can
def empty_can_frame(step, squash=False, palette=None):
    pal = palette or {"a": hexc("b3a68e"), "b": hexc("8f826b"), "c": hexc("6d6252"), "rim": hexc("5a5146")}
    c = Canvas(16, 20)
    if squash:
        c.rect(2, 15, 12, 4, pal["b"])
        c.hline(2, 13, 15, pal["a"])
        c.hline(2, 13, 18, pal["c"])
        c.set(5, 16, PUPIL); c.set(10, 16, PUPIL)
        c.line(4, 16, 6, 17, PUPIL); c.line(9, 17, 11, 16, PUPIL)
        c.outline()
        return c
    bob = -1 if step in (1, 3) else 0
    y1 = 16 + bob
    x0, x1 = 3, 12
    for y in range(3 + bob, y1 + 1):
        for x in range(x0, x1 + 1):
            t = (x - x0) / (x1 - x0)
            col = pal["a"] if t < 0.45 else (pal["b"] if t < 0.8 else pal["c"])
            c.set(x, y, col)
    # crushed open top (jagged)
    for i, x in enumerate(range(x0, x1 + 1)):
        c.set(x, 3 + bob + (i % 3 == 0), DARK if i % 2 else pal["rim"])
    c.hline(x0 + 1, x1 - 1, 4 + bob, hexc("3a342c"))
    # dents
    c.line(x0 + 1, 9 + bob, x0 + 3, 11 + bob, pal["c"])
    c.line(x1 - 1, 12 + bob, x1 - 3, 13 + bob, pal["a"])
    c.hline(x0, x1, y1 - 1, pal["rim"])
    angry_eyes(c, 5, 7 + bob, gap=4)
    c.hline(6, 9, 11 + bob, DARK)
    c.set(6, 12 + bob, WHITE); c.set(9, 12 + bob, WHITE)  # fangs
    # feet
    fl = [(4, 17), (5, 17), (4, 18), (9, 18), (10, 18), (11, 17)][step % 4: step % 4 + 1]
    if step % 2 == 0:
        c.rect(3, 17, 3, 2, DARK); c.rect(10, 17, 3, 2, DARK)
    else:
        c.rect(4, 17, 3, 2, DARK); c.rect(9, 16, 3, 2, DARK)
    c.outline()
    return c


# ---------------------------------------------------------------- Sugar cube
def sugar_cube_frame(kind, palette=None):
    base = hexc("f4f7ff")
    mid = hexc("d5deef")
    dark = hexc("a9b6cf")
    c = Canvas(16, 16)
    if kind == "squash":
        c.rect(2, 11, 12, 4, mid); c.hline(2, 13, 11, base)
        c.set(5, 12, PUPIL); c.set(10, 12, PUPIL)
        c.outline(); return c
    if kind == "crouch":
        x0, y0, w, h = 1, 6, 14, 9
    elif kind == "jump":
        x0, y0, w, h = 3, 1, 10, 14
    else:
        x0, y0, w, h = 2, 3 + (1 if kind == "idle2" else 0), 12, 12 - (1 if kind == "idle2" else 0)
    c.rect(x0, y0, w, h, mid)
    c.rect(x0, y0, w, 3, base)
    c.rect(x0, y0, 2, h, base)
    c.rect(x0 + w - 2, y0 + 3, 2, h - 3, dark)
    c.hline(x0, x0 + w - 1, y0 + h - 1, dark)
    r = rng(7)
    for _ in range(8):
        c.set(x0 + 2 + r.randrange(max(1, w - 4)), y0 + 4 + r.randrange(max(1, h - 6)), WHITE)
    ey = y0 + max(3, h // 2 - 2)
    cx = x0 + w // 2
    angry_eyes(c, cx - 4, ey, gap=5)
    c.hline(cx - 2, cx + 1, ey + 4, DARK)
    c.set(cx - 2, ey + 5, WHITE); c.set(cx + 1, ey + 5, WHITE)
    c.outline()
    return c


# ---------------------------------------------------------------- Energy drone
def drone_frame(step, charging=False, broken=False):
    c = Canvas(24, 18)
    body = hexc("5d6475"); hi = hexc("8a93a8"); lo = hexc("3a3f4c")
    c.ellipse(12, 10, 8, 5.5, body)
    c.ellipse(11, 8.5, 6, 3, hi)
    c.hline(5, 19, 13, lo)
    # visor eye
    eye = RED if charging else hexc("39e6ff")
    c.rect(9, 8, 7, 3, DARK)
    c.rect(10 + (step % 2), 9, 3, 1, eye)
    if charging:
        c.rect(9, 8, 7, 3, mix(eye, DARK, 0.4)); c.rect(10, 9, 5, 1, hexc("ffe0e4"))
    # rotor
    c.vline(12, 2, 4, lo)
    if not broken:
        if step % 2 == 0:
            c.hline(4, 20, 1, hexc("c9ced8"))
        else:
            c.hline(8, 16, 1, hexc("c9ced8")); c.set(6, 2, hexc("c9ced8")); c.set(18, 2, hexc("c9ced8"))
    # cannon
    c.rect(11, 15, 3, 2, lo)
    if broken:
        c.line(6, 6, 10, 13, DARK); c.line(15, 6, 18, 12, DARK)
    c.outline()
    return c


# ---------------------------------------------------------------- Corrupted can
def corrupted_frame(step, squash=False):
    c = Canvas(16, 20)
    body = hexc("2f2540"); hi = hexc("4b3d63"); glow = hexc("7dff5a")
    if squash:
        c.rect(2, 15, 12, 4, body); c.hline(2, 13, 15, hi)
        c.line(4, 16, 9, 17, glow)
        c.outline(); return c
    bob = -1 if step % 2 else 0
    for y in range(3 + bob, 17 + bob):
        for x in range(3, 13):
            c.set(x, y, hi if x < 6 else body)
    for i, x in enumerate(range(3, 13)):
        c.set(x, 2 + bob + (i % 2), DARK)
    # glowing cracks
    for (a, b) in [((5, 4), (7, 8)), ((7, 8), (6, 11)), ((10, 9), (12, 14)), ((4, 13), (6, 15))]:
        c.line(a[0], a[1] + bob, b[0], b[1] + bob, glow)
    # red eyes
    for ex in (5, 9):
        c.rect(ex, 6 + bob, 2, 2, RED); c.set(ex, 6 + bob, hexc("ffd0d6"))
    c.line(4, 4 + bob, 7, 5 + bob, DARK); c.line(11, 4 + bob, 8, 5 + bob, DARK)
    c.hline(6, 10, 10 + bob, DARK); c.set(7, 11 + bob, WHITE); c.set(9, 11 + bob, WHITE)
    # spikes
    c.set(2, 9 + bob, hi); c.set(13, 7 + bob, hi); c.set(13, 12 + bob, hi)
    if step % 2 == 0:
        c.rect(3, 17, 3, 2, DARK); c.rect(10, 17, 3, 2, DARK)
    else:
        c.rect(5, 17, 3, 2, DARK); c.rect(8, 16, 3, 2, DARK)
    c.outline()
    return c


# ---------------------------------------------------------------- Static slime
def slime_frame(step, charged=False, squash=False):
    c = Canvas(16, 14)
    body = hexc("2bb7ff"); hi = hexc("9ee9ff"); lo = hexc("1468b8")
    if charged:
        body, hi, lo = hexc("ffe14a"), hexc("fff8c4"), hexc("e09b12")
    if squash:
        c.ellipse(8, 12, 7, 2, body); c.outline(); return c
    wob = [0, 1, 0, -1][step % 4]
    c.ellipse(8, 9 - wob * 0.5, 6.5 + wob * 0.5, 4.5 - wob * 0.5, body)
    c.ellipse(6, 7.5, 3, 1.6, hi)
    c.hline(3, 12, 12, lo)
    c.set(6, 9, PUPIL); c.set(10, 9, PUPIL); c.set(6, 8, PUPIL); c.set(10, 8, PUPIL)
    c.hline(7, 9, 11, lo)
    if charged:
        spark = hexc("ffffff")
        pts = [(1, 3), (14, 2), (2, 11), (14, 10), (8, 1)] if step % 2 == 0 else [(3, 1), (12, 4), (0, 8), (15, 7), (8, 2)]
        for (x, y) in pts:
            c.set(x, y, spark); c.set(x + 1, y + 1, hexc("ffe14a"))
    c.outline()
    return c


# ---------------------------------------------------------------- Mega crusher
def crusher_frame(state):
    c = Canvas(32, 32)
    steel = hexc("7f8798"); hi = hexc("aeb6c6"); lo = hexc("4c5262")
    c.rect(1, 2, 30, 28, steel)
    c.rect(1, 2, 30, 3, hi)
    c.rect(27, 5, 4, 25, lo)
    # hazard stripes at the bottom
    for x in range(1, 31):
        for y in range(24, 30):
            if ((x + y) // 3) % 2 == 0:
                c.set(x, y, hexc("ffc928"))
            else:
                c.set(x, y, hexc("26262e"))
    # bolts
    for (x, y) in [(3, 6), (27, 6), (3, 21), (27, 21)]:
        c.set(x, y, hi); c.set(x + 1, y + 1, lo)
    # face
    eye = RED if state in ("warn", "slam") else hexc("ffe14a")
    c.rect(6, 9, 20, 8, hexc("2a2d36"))
    if state == "slam":
        c.rect(8, 11, 6, 3, eye); c.rect(18, 11, 6, 3, eye)
        for x in range(8, 24, 2):
            c.set(x, 15, WHITE)
    else:
        c.rect(8, 11, 6, 2 if state == "idle" else 3, eye)
        c.rect(18, 11, 6, 2 if state == "idle" else 3, eye)
        c.line(7, 9, 13, 11, DARK); c.line(24, 9, 18, 11, DARK)
    c.outline()
    return c


def piston():
    c = Canvas(8, 16)
    c.rect(1, 0, 6, 16, hexc("5c6272"))
    c.vline(2, 0, 15, hexc("9aa1b0"))
    c.vline(6, 0, 15, hexc("3a3f4c"))
    for y in (3, 11):
        c.hline(1, 6, y, hexc("3a3f4c"))
    return c


# ---------------------------------------------------------------- projectiles / small hazards
def orb(step, color=hexc("39e6ff")):
    c = Canvas(8, 8)
    c.circle(4, 4, 3.4 if step else 3, color)
    c.circle(4, 4, 1.6, WHITE)
    if step:
        c.set(0, 4, color); c.set(7, 3, color)
    return c


def icicle():
    c = Canvas(8, 16)
    c.poly([(0, 0), (8, 0), (4, 16)], hexc("bfeaff"))
    c.poly([(1, 0), (4, 0), (4, 13)], WHITE)
    c.hline(0, 7, 0, hexc("7fc8f0"))
    c.outline(hexc("3a6f9a"))
    return c


def shockwave(step):
    c = Canvas(16, 12)
    h = [6, 9][step]
    col = hexc("fffbe0")
    for x in range(16):
        y = 12 - int(h * math.sin(math.pi * (x + 0.5) / 16))
        c.vline(x, y, 11, col if x % 3 else hexc("ffd84a"))
    c.outline(hexc("e09b12"))
    return c


def lightning_marker(step):
    c = Canvas(16, 6)
    col = hexc("ffe14a") if step else hexc("ff8a2a")
    c.ellipse(8, 3, 7, 2, col)
    c.ellipse(8, 3, 4, 1, WHITE)
    return c


def bolt_column(step):
    c = Canvas(12, 64)
    x = 6
    r = rng(step + 3)
    for y in range(0, 64, 4):
        nx = max(2, min(9, x + r.choice([-2, -1, 1, 2])))
        c.line(x, y, nx, y + 4, hexc("fff6a8"))
        c.line(x + 1, y, nx + 1, y + 4, WHITE)
        x = nx
    c.outline(hexc("ffb21a"))
    return c


# ---------------------------------------------------------------- Bosses
def sugar_king(state):
    c = Canvas(48, 48)
    base = hexc("f4f7ff"); mid = hexc("d5deef"); dark = hexc("a9b6cf")
    if state == "squat":
        x0, y0, w, h = 3, 16, 42, 31
    elif state == "jump":
        x0, y0, w, h = 8, 6, 32, 41
    elif state == "defeat":
        x0, y0, w, h = 4, 28, 40, 19
    else:
        x0, y0, w, h = 6, 12, 36, 35
    c.rect(x0, y0, w, h, mid)
    c.rect(x0, y0, w, 6, base)
    c.rect(x0, y0, 4, h, base)
    c.rect(x0 + w - 5, y0 + 6, 5, h - 6, dark)
    c.hline(x0, x0 + w - 1, y0 + h - 1, dark)
    r = rng(11)
    for _ in range(40):
        c.set(x0 + 3 + r.randrange(w - 6), y0 + 7 + r.randrange(max(1, h - 9)), WHITE)
    # crown
    if state != "defeat":
        gold = hexc("ffd23f"); gdk = hexc("c98e12")
        cx = x0 + w // 2
        c.poly([(cx - 10, y0), (cx - 10, y0 - 8), (cx - 5, y0 - 3), (cx, y0 - 10), (cx + 5, y0 - 3), (cx + 10, y0 - 8), (cx + 10, y0)], gold)
        c.hline(cx - 10, cx + 9, y0 - 1, gdk)
        c.set(cx, y0 - 6, RED); c.set(cx - 7, y0 - 4, hexc("39e6ff")); c.set(cx + 7, y0 - 4, hexc("39e6ff"))
    cx = x0 + w // 2
    ey = y0 + h // 2 - 6
    if state == "stunned" or state == "defeat":
        for ex in (cx - 9, cx + 4):
            c.line(ex, ey, ex + 4, ey + 4, DARK); c.line(ex + 4, ey, ex, ey + 4, DARK)
        c.ellipse(cx, ey + 10, 4, 2, DARK)
    else:
        for ex in (cx - 10, cx + 4):
            c.rect(ex, ey, 6, 5, WHITE)
            c.rect(ex + 2 + (1 if state != "hurt" else 0), ey + 1, 3, 3, PUPIL)
        c.line(cx - 12, ey - 3, cx - 3, ey, DARK); c.line(cx - 12, ey - 2, cx - 3, ey + 1, DARK)
        c.line(cx + 11, ey - 3, cx + 2, ey, DARK); c.line(cx + 11, ey - 2, cx + 2, ey + 1, DARK)
        c.rect(cx - 7, ey + 8, 14, 4, DARK)
        for x in range(cx - 6, cx + 7, 3):
            c.rect(x, ey + 8, 2, 2, WHITE)
        if state == "hurt":
            c.rect(cx - 7, ey + 8, 14, 4, hexc("ff8fa3"))
    if state == "stunned":
        for (sx, sy) in [(x0 + 4, y0 - 6), (x0 + w - 8, y0 - 8), (cx, y0 - 13)]:
            star(c, sx, sy)
    c.outline()
    return c


def star(c, x, y, col=hexc("ffe14a")):
    c.set(x, y - 1, col); c.set(x, y + 1, col); c.set(x - 1, y, col); c.set(x + 1, y, col); c.set(x, y, WHITE)


def crusher_prime(state):
    """Boss of world 2. The weak point is the core hatch on TOP of the machine."""
    c = Canvas(64, 56)
    steel = hexc("6f7788"); hi = hexc("a3abbb"); lo = hexc("434958")
    # core housing on top
    core_open = state in ("open", "hurt")
    c.rect(20, 2, 24, 14, lo)
    c.rect(22, 4, 20, 10, hexc("1a1d26"))
    if core_open:
        col = hexc("7dff5a") if state == "open" else WHITE
        c.ellipse(32, 9, 8, 4.5, col)
        c.ellipse(32, 9, 4, 2, WHITE)
    else:
        c.hline(22, 41, 8, hexc("5c6272")); c.hline(22, 41, 10, hexc("5c6272"))
        c.hline(22, 41, 4, hi)
    # main body
    c.rect(4, 16, 56, 38, steel)
    c.rect(4, 16, 56, 4, hi)
    c.rect(54, 20, 6, 34, lo)
    for x in range(4, 60):
        for y in range(47, 54):
            c.set(x, y, hexc("ffc928") if ((x + y) // 3) % 2 == 0 else hexc("26262e"))
    for y in range(24, 44, 4):
        c.hline(7, 13, y, lo); c.hline(50, 56, y, lo)
    eye = RED if state in ("warn", "slam", "hurt") else hexc("ffe14a")
    c.rect(18, 24, 28, 12, hexc("2a2d36"))
    c.rect(21, 27, 8, 4, eye); c.rect(35, 27, 8, 4, eye)
    c.line(19, 24, 28, 27, DARK); c.line(44, 24, 35, 27, DARK)
    if state == "slam":
        for x in range(21, 43, 3):
            c.set(x, 34, WHITE)
    if state == "broken":
        c.line(10, 18, 24, 44, DARK); c.line(40, 20, 52, 46, DARK)
        c.rect(21, 27, 8, 4, hexc("3a3f4c")); c.rect(35, 27, 8, 4, hexc("3a3f4c"))
    c.outline()
    return c


def frost_volt(state):
    c = Canvas(48, 40)
    ice = hexc("bfeaff"); ice2 = hexc("7fc8f0"); ice3 = hexc("3a7fb5")
    # cloud-like icy shell
    for (x, y, r) in [(14, 18, 10), (24, 14, 12), (34, 18, 10), (24, 22, 11)]:
        c.circle(x, y, r, ice2)
    for (x, y, r) in [(13, 15, 6), (23, 10, 7), (33, 15, 5)]:
        c.circle(x, y, r, ice)
    c.hline(8, 40, 30, ice3)
    # spikes
    for x in range(10, 40, 6):
        c.poly([(x, 30), (x + 4, 30), (x + 2, 36)], ice)
    # core
    exposed = state in ("stunned", "hurt")
    core = hexc("ffe14a") if not exposed else (WHITE if state == "hurt" else hexc("ff6ad5"))
    c.circle(24, 19, 6 if exposed else 4, hexc("1a2a3a"))
    c.circle(24, 19, 4 if exposed else 2.5, core)
    # eyes
    if state == "defeat":
        for ex in (15, 30):
            c.line(ex, 14, ex + 3, 17, DARK); c.line(ex + 3, 14, ex, 17, DARK)
    else:
        for ex in (15, 30):
            c.rect(ex, 14, 4, 3, DARK)
            c.set(ex + 1, 15, RED if state == "charge" else WHITE)
    if state == "charge":
        for (x, y) in [(4, 8), (44, 10), (6, 30), (42, 28), (24, 1)]:
            c.line(x, y, x + 2, y + 3, hexc("fff6a8"))
    c.outline(hexc("1d3b57"))
    return c


def overload_core(state):
    c = Canvas(96, 96)
    hull = hexc("3a2f55"); hull2 = hexc("54457a"); lo = hexc("221b33")
    neon = hexc("ff3fd8"); cyan = hexc("39e6ff")
    c.rect(8, 10, 80, 80, hull)
    c.rect(8, 10, 80, 6, hull2)
    c.rect(80, 16, 8, 74, lo)
    # armour plates and pipes
    for y in range(22, 86, 12):
        c.hline(12, 76, y, lo)
    for x in (16, 72):
        c.rect(x, 18, 5, 66, hexc("2c2442"))
        for y in range(20, 84, 8):
            c.set(x + 2, y, cyan if state != "dead" else lo)
    # cables
    for (x0, y0, x1, y1) in [(8, 30, 0, 60), (88, 26, 95, 70), (8, 70, 2, 95)]:
        c.line(x0, y0, x1, y1, hexc("1a1426")); c.line(x0, y0 + 1, x1, y1 + 1, hexc("1a1426"))
    # cracks (damaged machine)
    crack = hexc("ff8a2a") if state != "dead" else lo
    for (a, b) in [((24, 14), (32, 30)), ((32, 30), (28, 40)), ((66, 60), (76, 80)), ((60, 18), (70, 26))]:
        c.line(a[0], a[1], b[0], b[1], crack)
    # eye slit
    eye = RED if state in ("charge", "hurt") else neon
    c.rect(30, 26, 36, 8, lo)
    if state != "dead":
        c.rect(32 + (6 if state == "idle2" else 0), 28, 26, 4, eye)
        c.rect(40, 29, 8, 2, WHITE)
    # central core (weak point)
    open_ = state in ("open", "hurt")
    c.circle(48, 58, 16, lo)
    c.circle(48, 58, 14, hexc("2c2442"))
    if open_:
        col = WHITE if state == "hurt" else hexc("7dff5a")
        c.circle(48, 58, 11, mix(col, lo, 0.25))
        c.circle(48, 58, 7, col)
        c.circle(48, 58, 3, WHITE)
    else:
        for a in range(0, 360, 45):
            r = math.radians(a)
            c.line(48, 58, 48 + 13 * math.cos(r), 58 + 13 * math.sin(r), hull2)
        c.circle(48, 58, 3, neon if state != "dead" else lo)
    # warning lights
    for x in (20, 76):
        c.circle(x, 8, 3, RED if state in ("charge",) else hexc("ffc928"))
    c.outline(hexc("0d0a14"))
    return c


def build():
    s = Sheet(16, 20)
    s.anim("walk", [empty_can_frame(i) for i in range(4)], fps=6)
    s.anim("squash", [empty_can_frame(0, squash=True)], fps=1, loop=False)
    s.save("sprites/empty_can.png")

    s = Sheet(16, 16)
    s.anim("idle", [sugar_cube_frame("idle"), sugar_cube_frame("idle2")], fps=4)
    s.anim("crouch", [sugar_cube_frame("crouch")], fps=1, loop=False)
    s.anim("jump", [sugar_cube_frame("jump")], fps=1, loop=False)
    s.anim("squash", [sugar_cube_frame("squash")], fps=1, loop=False)
    s.save("sprites/sugar_cube.png")

    s = Sheet(24, 18)
    s.anim("fly", [drone_frame(i) for i in range(4)], fps=12)
    s.anim("charge", [drone_frame(0, True), drone_frame(1, True)], fps=12)
    s.anim("broken", [drone_frame(0, broken=True)], fps=1, loop=False)
    s.save("sprites/energy_drone.png")

    s = Sheet(16, 20)
    s.anim("walk", [corrupted_frame(i) for i in range(4)], fps=10)
    s.anim("squash", [corrupted_frame(0, squash=True)], fps=1, loop=False)
    s.save("sprites/corrupted_can.png")

    s = Sheet(16, 14)
    s.anim("move", [slime_frame(i) for i in range(4)], fps=8)
    s.anim("charged", [slime_frame(i, charged=True) for i in range(2)], fps=12)
    s.anim("squash", [slime_frame(0, squash=True)], fps=1, loop=False)
    s.save("sprites/static_slime.png")

    s = Sheet(32, 32)
    s.anim("idle", [crusher_frame("idle")], fps=1)
    s.anim("warn", [crusher_frame("warn"), crusher_frame("idle")], fps=10)
    s.anim("slam", [crusher_frame("slam")], fps=1)
    s.save("sprites/mega_crusher.png")
    piston().save("sprites/piston.png")

    s = Sheet(8, 8)
    s.anim("fly", [orb(0), orb(1)], fps=12)
    s.anim("fly_red", [orb(0, RED), orb(1, RED)], fps=12)
    s.anim("fly_green", [orb(0, hexc("7dff5a")), orb(1, hexc("7dff5a"))], fps=12)
    s.anim("fly_pink", [orb(0, hexc("ff3fd8")), orb(1, hexc("ff3fd8"))], fps=12)
    s.save("sprites/orb.png")
    icicle().save("sprites/icicle.png")
    s = Sheet(16, 12)
    s.anim("wave", [shockwave(0), shockwave(1)], fps=12)
    s.save("sprites/shockwave.png")
    s = Sheet(16, 6)
    s.anim("blink", [lightning_marker(0), lightning_marker(1)], fps=10)
    s.save("sprites/marker.png")
    s = Sheet(12, 64)
    s.anim("zap", [bolt_column(0), bolt_column(1), bolt_column(2)], fps=20)
    s.save("sprites/bolt.png")

    s = Sheet(48, 48)
    s.anim("idle", [sugar_king("idle")], fps=1)
    s.anim("squat", [sugar_king("squat")], fps=1, loop=False)
    s.anim("jump", [sugar_king("jump")], fps=1, loop=False)
    s.anim("stunned", [sugar_king("stunned")], fps=1)
    s.anim("hurt", [sugar_king("hurt")], fps=1, loop=False)
    s.anim("defeat", [sugar_king("defeat")], fps=1, loop=False)
    s.save("sprites/boss_sugar_king.png")

    s = Sheet(64, 56)
    for st in ("idle", "warn", "slam", "open", "hurt", "broken"):
        s.anim(st, [crusher_prime(st)], fps=1, loop=st != "broken")
    s.save("sprites/boss_crusher_prime.png")

    s = Sheet(48, 40)
    for st in ("idle", "charge", "stunned", "hurt", "defeat"):
        s.anim(st, [frost_volt(st)], fps=1)
    s.save("sprites/boss_frost_volt.png")

    s = Sheet(96, 96)
    s.anim("idle", [overload_core("idle"), overload_core("idle2")], fps=2)
    for st in ("charge", "open", "hurt", "dead"):
        s.anim(st, [overload_core(st)], fps=1)
    s.save("sprites/boss_overload_core.png", cols=4)


if __name__ == "__main__":
    build()
