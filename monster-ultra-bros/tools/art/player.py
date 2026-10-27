"""The hero: an animated Monster Energy Ultra White can.

Original pixel-art interpretation (white/silver body, black lid and accents,
a three-stroke claw mark). Frames are 24x32, facing right; Godot flips them.
"""
from pix import Canvas, Sheet, hexc

FW, FH = 24, 32

LID = hexc("23252d")
LID_HI = hexc("4b4f5c")
TAB = hexc("cfd4dc")
RING = hexc("8d94a3")
BAND = hexc("1e2027")
BAND_TXT = hexc("c9ced8")
CLAW = hexc("1c1e25")
CLAW_HI = hexc("7b8291")
ARM = hexc("2a2d36")
GLOVE = hexc("ffffff")
SHOE = hexc("e9ecf1")
SOLE = hexc("1d1f26")
PUPIL = hexc("101018")
SHINE = hexc("ffffff")
MOUTH = hexc("3a1820")
TONGUE = hexc("e05570")
BLUSH = hexc("ffb3c1")

# Cylinder shading from left edge to right edge.
BODY_RAMP = [hexc("c4c9d4"), hexc("eef0f4"), hexc("ffffff"), hexc("ffffff"),
             hexc("f4f6f9"), hexc("e6e9ef"), hexc("d6dae2"), hexc("c4c9d4"), hexc("9aa1b0")]


def body_color(t):
    i = min(len(BODY_RAMP) - 1, int(t * len(BODY_RAMP)))
    return BODY_RAMP[i]


def draw_can(c: Canvas, cx, y1, w=12, h=24, eyes="normal", mouth="smile", look=1,
             dent=False, band=True):
    x0 = cx - w // 2
    x1 = x0 + w - 1
    y0 = y1 - h + 1
    # body
    for y in range(y0 + 2, y1 + 1):
        for x in range(x0, x1 + 1):
            c.set(x, y, body_color((x - x0) / max(1, w - 1)))
    # lid (black) + tab
    c.hline(x0 + 1, x1 - 1, y0, LID)
    c.hline(x0, x1, y0 + 1, LID)
    c.hline(x0 + 2, x0 + 4, y0 + 1, LID_HI)
    c.hline(cx - 1, cx + 1, y0 - 1, TAB)
    c.set(cx, y0 - 1, LID)
    c.hline(x0, x1, y0 + 2, RING)
    # bottom ring
    c.hline(x0, x1, y1 - 1, RING)
    c.hline(x0 + 1, x1 - 1, y1, hexc("6b7282"))
    # black accent band with "text"
    if band and h >= 18:
        by = y1 - 4
        c.hline(x0, x1, by, BAND)
        c.hline(x0, x1, by + 1, BAND)
        for i, on in enumerate("x.xx.xx.x"):
            if on == "x":
                c.set(cx - 4 + i, by, BAND_TXT)
    # claw mark: three long jagged strokes (2px wide at the top, tapering)
    ctop = y0 + 11
    cbot = y1 - 5 if band else y1 - 2
    if cbot - ctop >= 2:
        span = cbot - ctop
        for k, sx in enumerate((cx - 4, cx - 1, cx + 2)):
            top = ctop + (0 if k == 1 else 1)
            for y in range(top, cbot + 1):
                t = (y - top) / max(1, span)
                jag = 1 if (y - top) % 4 in (1, 2) else 0
                x = sx + jag + (1 if t > 0.6 and k == 2 else 0)
                c.set(x, y, CLAW)
                if t < 0.55:
                    c.set(x + 1, y, CLAW)
    if dent:
        c.line(x0 + 2, y0 + 6, x0 + 6, y0 + 9, RING)
        c.line(x1 - 1, y0 + 12, x1 - 4, y0 + 14, RING)
    draw_face(c, cx + look, y0, eyes, mouth)
    return x0, x1, y0


def draw_face(c, cx, y0, eyes, mouth):
    ey = y0 + 4
    lx, rx = cx - 3, cx + 1
    if eyes in ("normal", "determined", "look_up"):
        for ex in (lx, rx):
            c.rect(ex, ey, 2, 3, PUPIL)
            c.set(ex + (1 if eyes != "look_up" else 0), ey, SHINE)
        if eyes == "determined":
            c.line(lx - 1, ey - 2, lx + 1, ey - 1, PUPIL)
            c.line(rx + 2, ey - 2, rx, ey - 1, PUPIL)
    elif eyes == "blink":
        c.hline(lx, lx + 1, ey + 2, PUPIL)
        c.hline(rx, rx + 1, ey + 2, PUPIL)
    elif eyes == "happy":
        for ex in (lx, rx):
            c.set(ex, ey + 1, PUPIL)
            c.set(ex + 1, ey, PUPIL)
            c.set(ex + 2, ey + 1, PUPIL)
    elif eyes == "hurt":
        c.line(lx, ey, lx + 1, ey + 1, PUPIL)
        c.line(lx + 1, ey + 1, lx, ey + 2, PUPIL)
        c.line(rx + 1, ey, rx, ey + 1, PUPIL)
        c.line(rx, ey + 1, rx + 1, ey + 2, PUPIL)
    elif eyes == "dead":
        for ex in (lx, rx):
            c.line(ex - 1, ey, ex + 1, ey + 2, PUPIL)
            c.line(ex + 1, ey, ex - 1, ey + 2, PUPIL)
    elif eyes == "surprised":
        for ex in (lx, rx):
            c.rect(ex, ey - 1, 2, 4, PUPIL)
            c.set(ex, ey - 1, SHINE)
    if eyes in ("happy", "normal") and mouth in ("grin", "open_smile"):
        c.set(lx - 1, ey + 3, BLUSH)
        c.set(rx + 2, ey + 3, BLUSH)
    my = y0 + 8
    mx = cx - 1
    if mouth == "smile":
        c.set(mx - 1, my, MOUTH)
        c.hline(mx, mx + 1, my + 1, MOUTH)
        c.set(mx + 2, my, MOUTH)
    elif mouth == "grin":
        c.hline(mx - 1, mx + 2, my, MOUTH)
        c.hline(mx, mx + 1, my + 1, TONGUE)
    elif mouth == "open_smile":
        c.hline(mx - 1, mx + 2, my, MOUTH)
        c.hline(mx - 1, mx + 2, my + 1, MOUTH)
        c.hline(mx, mx + 1, my + 1, TONGUE)
    elif mouth == "open":
        c.rect(mx, my, 2, 2, MOUTH)
        c.set(mx, my + 1, TONGUE)
    elif mouth == "frown":
        c.set(mx - 1, my + 1, MOUTH)
        c.hline(mx, mx + 1, my, MOUTH)
        c.set(mx + 2, my + 1, MOUTH)
    elif mouth == "flat":
        c.hline(mx - 1, mx + 2, my, MOUTH)
    elif mouth == "wavy":
        c.set(mx - 1, my + 1, MOUTH)
        c.set(mx, my, MOUTH)
        c.set(mx + 1, my + 1, MOUTH)
        c.set(mx + 2, my, MOUTH)


def draw_arms(c, x0, x1, y0, pose):
    ay = y0 + 12
    if pose == "down":
        c.vline(x0 - 1, ay, ay + 2, ARM); c.set(x0 - 1, ay + 3, GLOVE)
        c.vline(x1 + 1, ay, ay + 2, ARM); c.set(x1 + 1, ay + 3, GLOVE)
    elif pose == "up":
        c.line(x0 - 1, ay - 1, x0 - 3, ay - 5, ARM); c.set(x0 - 3, ay - 6, GLOVE); c.set(x0 - 4, ay - 6, GLOVE)
        c.line(x1 + 1, ay - 1, x1 + 3, ay - 5, ARM); c.set(x1 + 3, ay - 6, GLOVE); c.set(x1 + 4, ay - 6, GLOVE)
    elif pose == "out":
        c.hline(x0 - 3, x0 - 1, ay - 2, ARM); c.set(x0 - 4, ay - 3, GLOVE)
        c.hline(x1 + 1, x1 + 3, ay - 2, ARM); c.set(x1 + 4, ay - 3, GLOVE)
    elif pose == "swing_a":
        c.line(x0 - 1, ay, x0 - 2, ay + 2, ARM); c.set(x0 - 3, ay + 3, GLOVE)
        c.line(x1 + 1, ay, x1 + 2, ay - 1, ARM); c.set(x1 + 3, ay - 2, GLOVE)
    elif pose == "swing_b":
        c.line(x0 - 1, ay, x0 - 2, ay - 1, ARM); c.set(x0 - 3, ay - 2, GLOVE)
        c.line(x1 + 1, ay, x1 + 2, ay + 2, ARM); c.set(x1 + 3, ay + 3, GLOVE)
    elif pose == "back":
        c.line(x0 - 1, ay, x0 - 4, ay + 1, ARM); c.set(x0 - 5, ay + 1, GLOVE)
        c.line(x1 + 1, ay + 1, x1 + 2, ay + 2, ARM); c.set(x1 + 2, ay + 3, GLOVE)
    elif pose == "victory":
        c.line(x0 - 1, ay - 1, x0 - 3, ay - 5, ARM); c.set(x0 - 3, ay - 6, GLOVE); c.set(x0 - 4, ay - 6, GLOVE)
        c.hline(x1 + 1, x1 + 3, ay, ARM); c.set(x1 + 4, ay - 1, GLOVE)


def draw_feet(c, cx, y1, pose):
    fy = y1
    def shoe(x, y, flip=False):
        c.rect(x, y, 4, 2, SHOE)
        c.set(x + 3, y, hexc("9aa1b0"))
        c.hline(x, x + 4, y + 2, SOLE)
    if pose == "stand":
        shoe(cx - 6, fy); shoe(cx + 2, fy)
    elif pose == "run1":
        shoe(cx - 8, fy - 1); shoe(cx + 3, fy)
    elif pose == "run2":
        shoe(cx - 5, fy); shoe(cx + 1, fy - 2)
    elif pose == "run3":
        shoe(cx - 3, fy - 1); shoe(cx, fy)
    elif pose == "run4":
        shoe(cx + 3, fy - 1); shoe(cx - 8, fy)
    elif pose == "run5":
        shoe(cx + 1, fy); shoe(cx - 5, fy - 2)
    elif pose == "run6":
        shoe(cx, fy - 1); shoe(cx - 3, fy)
    elif pose == "tuck":
        shoe(cx - 5, fy - 2); shoe(cx + 1, fy - 1)
    elif pose == "dangle":
        shoe(cx - 7, fy); shoe(cx + 3, fy + 0)
    elif pose == "wide":
        shoe(cx - 8, fy); shoe(cx + 4, fy)
    elif pose == "skid":
        shoe(cx - 2, fy); shoe(cx + 4, fy - 1)


def frame(w=12, h=24, bob=0, eyes="normal", mouth="smile", arms="down", feet="stand",
          look=1, dent=False, cx=12):
    c = Canvas(FW, FH)
    y1 = 28 + bob
    x0 = cx - w // 2
    x1 = x0 + w - 1
    y0 = y1 - h + 1
    draw_arms(c, x0, x1, y0, arms)
    draw_feet(c, cx, y1, feet)
    draw_can(c, cx, y1, w, h, eyes, mouth, look, dent)
    c.outline()
    return c


def build():
    s = Sheet(FW, FH)
    s.anim("idle", [frame(), frame(h=23, bob=0), frame(), frame(eyes="blink")], fps=4)
    run_feet = ["run1", "run2", "run3", "run4", "run5", "run6"]
    run_bob = [0, -1, -1, 0, -1, -1]
    run_arms = ["swing_a", "swing_a", "down", "swing_b", "swing_b", "down"]
    s.anim("run", [frame(bob=b, feet=f, arms=a, eyes="determined", mouth="grin")
                   for f, b, a in zip(run_feet, run_bob, run_arms)], fps=14)
    s.anim("skid", [frame(feet="skid", eyes="surprised", mouth="open", arms="out", look=0)], fps=1, loop=False)
    s.anim("jump", [frame(w=11, h=26, bob=-2, feet="tuck", arms="up", mouth="open_smile"),
                    frame(w=12, h=25, bob=-2, feet="tuck", arms="up", mouth="open_smile")], fps=10, loop=False)
    s.anim("fall", [frame(feet="dangle", arms="out", eyes="surprised", mouth="open"),
                    frame(feet="dangle", arms="up", eyes="surprised", mouth="open", bob=-1)], fps=8)
    s.anim("land", [frame(w=13, h=22, feet="wide", arms="out", eyes="blink", mouth="flat"),
                    frame(w=13, h=22, feet="wide", arms="down", mouth="smile")], fps=16, loop=False)
    s.anim("hurt", [frame(eyes="hurt", mouth="frown", arms="up", feet="wide", look=-1),
                    frame(eyes="hurt", mouth="wavy", arms="out", feet="wide", look=-1)], fps=10)
    s.anim("death", [frame(eyes="surprised", mouth="open", arms="up", feet="dangle"),
                     frame(eyes="dead", mouth="wavy", arms="out", feet="dangle", dent=True),
                     frame(w=14, h=20, eyes="dead", mouth="wavy", arms="out", feet="wide", dent=True)], fps=5, loop=False)
    s.anim("victory", [frame(eyes="happy", mouth="open_smile", arms="up", feet="stand"),
                       frame(eyes="happy", mouth="grin", arms="up", feet="tuck", bob=-3),
                       frame(eyes="happy", mouth="open_smile", arms="victory", feet="tuck", bob=-4),
                       frame(eyes="happy", mouth="grin", arms="up", feet="stand", w=13, h=23)], fps=7)
    s.anim("dash", [frame(eyes="determined", mouth="grin", arms="back", feet="run1", w=13, h=23),
                    frame(eyes="determined", mouth="grin", arms="back", feet="run4", w=13, h=23)], fps=14)
    s.anim("look_up", [frame(eyes="look_up", mouth="smile")], fps=1, loop=False)
    s.save("sprites/player.png", cols=8)

    # Soft glow aura used for power-ups (drawn additive behind the can).
    g = Canvas(40, 48)
    for y in range(g.h):
        for x in range(g.w):
            dx = (x + 0.5 - 20) / 18.0
            dy = (y + 0.5 - 26) / 22.0
            d = (dx * dx + dy * dy) ** 0.5
            if d < 1:
                a = int(255 * (1 - d) ** 1.6)
                g.set(x, y, (255, 255, 255, a))
    g.save("sprites/glow.png")


if __name__ == "__main__":
    build()
