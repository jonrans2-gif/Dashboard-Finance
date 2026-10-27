"""Collectibles, power-ups, interactive level objects and small FX."""
import math

from pix import Canvas, Sheet, hexc, mix, shade, rng
from player import draw_can

WHITE = hexc("ffffff")
DARK = hexc("1a1a24")
GOLD = [hexc("fff3a0"), hexc("ffd23f"), hexc("e0a315"), hexc("9a6a0a")]


def token(step):
    """Energy Token: a spinning gold coin with a lightning bolt."""
    c = Canvas(12, 12)
    widths = [5, 4, 2, 0.8, 2, 4]
    w = widths[step]
    c.ellipse(6, 6, w, 5, GOLD[2])
    if w > 1:
        c.ellipse(6 - 0.5, 6, max(0.6, w - 1.2), 4, GOLD[1])
        if w >= 4:
            for (x, y) in [(6, 3), (5, 5), (7, 5), (6, 7), (5, 8)]:
                c.set(x, y, GOLD[0] if step else WHITE)
    c.outline(GOLD[3])
    return c


def shard(step):
    """Ultra Shard: big collectible crystal (3 per level)."""
    c = Canvas(16, 16)
    col = [hexc("ffffff"), hexc("d8f6ff"), hexc("8fe0ff"), hexc("3a9fd0")]
    bob = [0, -1, -1, 0][step]
    c.poly([(8, 1 + bob), (14, 7 + bob), (8, 15 + bob), (2, 7 + bob)], col[2])
    c.poly([(8, 1 + bob), (8, 15 + bob), (2, 7 + bob)], col[1])
    c.line(8, 2 + bob, 8, 14 + bob, col[0])
    c.line(3, 7 + bob, 13, 7 + bob, col[1])
    if step == 1:
        c.set(4, 4, WHITE); c.set(12, 3, WHITE)
    c.outline(col[3])
    return c


def silver_can(step):
    """Silver can = extra life."""
    c = Canvas(12, 16)
    draw_can(c, 6, 14 - (1 if step else 0), w=8, h=12, eyes="happy", mouth="smile", look=0, band=False)
    c.outline()
    return c


def energy_core(step):
    """Hidden Energy Core: one per level in a secret area."""
    c = Canvas(16, 16)
    pulse = [5.5, 6, 6.5, 6][step]
    c.circle(8, 8, pulse + 1.5, hexc("7dff5a", 90))
    c.circle(8, 8, pulse, hexc("3fd13a"))
    c.circle(8, 8, pulse - 2, hexc("b8ff9a"))
    c.circle(8, 8, 2, WHITE)
    for a in range(4):
        ang = math.radians(a * 90 + step * 22)
        c.set(8 + 7 * math.cos(ang), 8 + 7 * math.sin(ang), WHITE)
    return c


def icon_bg(c, col):
    c.circle(8, 8, 7, shade(col, 0.55))
    c.circle(8, 8, 6, col)
    c.ellipse(6.5, 5.5, 3, 2, mix(col, WHITE, 0.45))


def pu_boost():
    c = Canvas(16, 16); icon_bg(c, hexc("39e6ff"))
    # winged sneaker / speed lines
    c.rect(5, 8, 7, 3, WHITE); c.rect(9, 6, 3, 2, WHITE); c.hline(4, 12, 11, DARK)
    for y in (6, 8, 10):
        c.hline(1, 3, y, WHITE)
    c.outline(DARK); return c


def pu_shield():
    c = Canvas(16, 16)
    c.circle(8, 8, 7, hexc("bfefff"))
    c.circle(8, 8, 5.5, hexc("e8fbff"))
    c.poly([(5, 4), (11, 4), (11, 9), (8, 12), (5, 9)], hexc("39b6ff"))
    c.line(8, 5, 8, 10, WHITE)
    c.outline(hexc("1a5a8a")); return c


def pu_surge():
    c = Canvas(16, 16); icon_bg(c, hexc("ff3fd8"))
    c.poly([(10, 1), (4, 9), (8, 9), (6, 15), (12, 6), (8, 6), (10, 1)], hexc("fff6a8"))
    c.outline(DARK); return c


def pu_mega():
    c = Canvas(16, 16); icon_bg(c, hexc("ff6a3a"))
    draw_can(c, 8, 13, w=6, h=9, eyes="happy", mouth="smile", look=0, band=False)
    c.poly([(8, 0), (12, 4), (4, 4)], hexc("fff6a8"))
    c.outline(DARK); return c


def pu_double():
    c = Canvas(16, 16); icon_bg(c, hexc("7dff5a"))
    for side in (-1, 1):
        cx = 8 + side * 3
        c.poly([(cx, 6), (cx + side * 4, 3), (cx + side * 4, 6), (cx + side * 3, 9), (cx, 10)], WHITE)
    c.vline(8, 4, 11, hexc("1f6b22"))
    c.outline(DARK); return c


def pu_magnet():
    c = Canvas(16, 16); icon_bg(c, hexc("ffd23f"))
    red = hexc("ff3048")
    c.rect(4, 4, 3, 7, red); c.rect(9, 4, 3, 7, red)
    c.rect(4, 10, 8, 3, red)
    c.rect(4, 3, 3, 2, WHITE); c.rect(9, 3, 3, 2, WHITE)
    c.outline(DARK); return c


def pu_overload(step):
    c = Canvas(16, 16)
    cols = [hexc("ff3fd8"), hexc("39e6ff"), hexc("7dff5a"), hexc("ffd23f")]
    col = cols[step % 4]
    pts = []
    for i in range(10):
        r = 7 if i % 2 == 0 else 3.2
        a = math.radians(-90 + i * 36)
        pts.append((8 + r * math.cos(a), 8.5 + r * math.sin(a)))
    c.poly(pts, col)
    c.circle(8, 8.5, 2, WHITE)
    c.set(6, 8, DARK); c.set(10, 8, DARK)
    c.outline(DARK); return c


# --- level objects -------------------------------------------------------
def checkpoint(active, step=0):
    c = Canvas(16, 32)
    c.vline(3, 2, 31, hexc("c8ccd6")); c.vline(4, 2, 31, hexc("8d94a3"))
    c.circle(3.5, 2, 2, hexc("ffd23f"))
    if active:
        col = hexc("7dff5a"); wave = [0, 1, 0, -1][step]
        c.poly([(5, 4), (15, 6 + wave), (15, 13 + wave), (5, 12)], col)
        c.rect(8, 7 + wave // 2, 4, 4, WHITE); c.hline(8, 11, 7 + wave // 2, DARK)
    else:
        c.poly([(5, 20), (12, 22), (12, 27), (5, 26)], hexc("8d94a3"))
    c.rect(1, 29, 6, 3, hexc("5f6676"))
    c.outline()
    return c


def goal_pole():
    c = Canvas(16, 160)
    c.vline(7, 8, 159, hexc("ffffff")); c.vline(8, 8, 159, hexc("c4c9d4"))
    for y in range(12, 160, 10):
        c.hline(7, 8, y, hexc("23252d"))
    c.circle(7.5, 5, 4.5, hexc("ffd23f")); c.circle(6.5, 4, 1.5, WHITE)
    c.outline()
    return c


def goal_flag(step):
    c = Canvas(24, 18)
    wave = [0, 1, 0, -1][step]
    c.poly([(0, 1), (22, 3 + wave), (22, 15 + wave), (0, 15)], hexc("23252d"))
    c.poly([(2, 3), (20, 5 + wave), (20, 13 + wave), (2, 13)], WHITE)
    # claw logo on flag
    for k, x in enumerate((8, 11, 14)):
        c.line(x, 5 + wave // 2, x - 1, 12 + wave // 2, DARK)
    return c


def goal_base():
    c = Canvas(16, 16)
    c.rect(0, 0, 16, 16, hexc("9aa1b0"))
    c.rect(1, 1, 14, 14, hexc("c8ccd6"))
    c.rect(4, 4, 8, 8, hexc("7dff5a"))
    c.outline()
    return c


def door(open_):
    c = Canvas(16, 32)
    c.rect(1, 2, 14, 30, hexc("5a3720"))
    c.ellipse(8, 4, 7, 4, hexc("5a3720"))
    if open_:
        c.rect(3, 4, 10, 28, hexc("0d0a14"))
        c.ellipse(8, 5, 5, 3, hexc("0d0a14"))
    else:
        c.rect(3, 4, 10, 28, hexc("a86a3a"))
        c.ellipse(8, 5, 5, 3, hexc("a86a3a"))
        c.vline(8, 3, 31, hexc("7a4a22"))
        c.set(11, 18, hexc("ffd23f")); c.set(5, 18, hexc("ffd23f"))
        c.rect(5, 8, 6, 3, hexc("ffd86a"))
    c.outline()
    return c


def spring(state):
    c = Canvas(16, 16)
    if state == 0:
        c.rect(1, 4, 14, 3, hexc("ff3048")); c.hline(1, 14, 4, hexc("ff8a9a"))
        for y in range(7, 14, 2):
            c.hline(4, 11, y, hexc("c8ccd6")); c.hline(5, 10, y + 1, hexc("8d94a3"))
    else:
        c.rect(1, 9, 14, 3, hexc("ff3048")); c.hline(1, 14, 9, hexc("ff8a9a"))
        c.hline(4, 11, 12, hexc("c8ccd6")); c.hline(4, 11, 13, hexc("8d94a3"))
    c.rect(2, 14, 12, 2, hexc("5f6676"))
    c.outline()
    return c


def moving_platform(theme_col):
    c = Canvas(48, 8)
    a, b, d = theme_col
    c.rect(0, 0, 48, 8, b)
    c.hline(0, 47, 0, a); c.hline(0, 47, 7, d)
    for x in range(4, 48, 8):
        c.rect(x, 3, 2, 2, d)
    c.rect(20, 2, 8, 4, hexc("7dff5a"))
    c.outline()
    return c


def falling_platform(shake=False):
    c = Canvas(32, 8)
    c.rect(0, 0, 32, 8, hexc("d9a066"))
    c.hline(0, 31, 0, hexc("ffd09a")); c.hline(0, 31, 7, hexc("8a5a30"))
    for x in range(0, 32, 8):
        c.vline(x, 1, 6, hexc("8a5a30"))
    if shake:
        c.line(10, 1, 14, 6, hexc("5a3720"))
    c.outline()
    return c


def zapper(on):
    c = Canvas(16, 16)
    c.rect(3, 9, 10, 7, hexc("4c5262")); c.rect(3, 9, 10, 2, hexc("8a93a8"))
    c.rect(6, 4, 4, 5, hexc("2a2d36"))
    c.circle(8, 4, 2.5, hexc("ffe14a") if on else hexc("5c6272"))
    c.outline()
    return c


def beam(step):
    c = Canvas(16, 16)
    r = rng(step)
    x = 8
    for y in range(0, 16, 2):
        nx = max(5, min(10, x + r.choice([-1, 0, 1])))
        c.line(x, y, nx, y + 2, hexc("fff6a8"))
        c.line(x + 1, y, nx + 1, y + 2, WHITE)
        x = nx
    c.outline(hexc("ffb21a"))
    return c


def lever():
    c = Canvas(16, 16)
    c.rect(2, 11, 12, 5, hexc("5f6676"))
    c.line(8, 11, 12, 3, hexc("c8ccd6"))
    c.circle(12, 3, 2, hexc("ff3048"))
    c.outline()
    return c


def boost_pad(step):
    c = Canvas(16, 8)
    c.rect(0, 3, 16, 5, hexc("2c1f55"))
    for i in range(3):
        x = (i * 6 + step * 2) % 16
        c.poly([(x, 3), (x + 3, 5), (x, 7)], hexc("39e6ff"))
    c.hline(0, 15, 3, hexc("ff3fd8"))
    c.outline()
    return c


# --- FX --------------------------------------------------------------------
def dust(step):
    c = Canvas(8, 8)
    r = [2.5, 3, 2.5, 1.5][step]
    a = [230, 200, 150, 90][step]
    c.circle(4, 4, r, (240, 240, 245, a))
    return c


def sparkle(step):
    c = Canvas(8, 8)
    s = [1, 2, 3, 2][step]
    col = hexc("fff6c0")
    c.hline(4 - s, 4 + s, 4, col); c.vline(4, 4 - s, 4 + s, col)
    c.set(4, 4, WHITE)
    return c


def debris(kind):
    c = Canvas(8, 8)
    c.rect(1, 1, 6, 6, kind)
    c.hline(1, 6, 1, mix(kind, WHITE, 0.4))
    c.outline()
    return c


def puff(step):
    c = Canvas(16, 16)
    r = [3, 5, 6.5, 7][step]
    a = [255, 220, 160, 90][step]
    c.circle(8, 8, r, (255, 255, 255, a))
    if step < 3:
        c.circle(8, 8, r - 2, (255, 246, 168, a))
    return c


def build():
    s = Sheet(12, 12); s.anim("spin", [token(i) for i in range(6)], fps=10); s.save("sprites/token.png")
    s = Sheet(16, 16); s.anim("idle", [shard(i) for i in range(4)], fps=6); s.save("sprites/shard.png")
    s = Sheet(12, 16); s.anim("idle", [silver_can(0), silver_can(1)], fps=3); s.save("sprites/silver_can.png")
    s = Sheet(16, 16); s.anim("idle", [energy_core(i) for i in range(4)], fps=8); s.save("sprites/energy_core.png")
    s = Sheet(16, 16)
    s.anim("boost", [pu_boost()], fps=1)
    s.anim("shield", [pu_shield()], fps=1)
    s.anim("surge", [pu_surge()], fps=1)
    s.anim("mega", [pu_mega()], fps=1)
    s.anim("double", [pu_double()], fps=1)
    s.anim("magnet", [pu_magnet()], fps=1)
    s.anim("overload", [pu_overload(i) for i in range(4)], fps=10)
    s.save("sprites/powerups.png")
    s = Sheet(16, 32)
    s.anim("inactive", [checkpoint(False)], fps=1)
    s.anim("active", [checkpoint(True, i) for i in range(4)], fps=8)
    s.save("sprites/checkpoint.png")
    goal_pole().save("sprites/goal_pole.png")
    s = Sheet(24, 18); s.anim("wave", [goal_flag(i) for i in range(4)], fps=8); s.save("sprites/goal_flag.png")
    goal_base().save("sprites/goal_base.png")
    s = Sheet(16, 32); s.anim("closed", [door(False)], fps=1); s.anim("open", [door(True)], fps=1); s.save("sprites/door.png")
    s = Sheet(16, 16); s.anim("idle", [spring(0)], fps=1); s.anim("bounce", [spring(1), spring(0)], fps=12, loop=False); s.save("sprites/spring.png")
    from tiles import THEMES
    for name, st in THEMES.items():
        moving_platform(st["plat"]).save(f"sprites/platform_{name}.png")
    s = Sheet(32, 8); s.anim("idle", [falling_platform()], fps=1); s.anim("shake", [falling_platform(True)], fps=1); s.save("sprites/falling_platform.png")
    s = Sheet(16, 16); s.anim("off", [zapper(False)], fps=1); s.anim("on", [zapper(True)], fps=1); s.save("sprites/zapper.png")
    s = Sheet(16, 16); s.anim("zap", [beam(i) for i in range(3)], fps=18); s.save("sprites/beam.png")
    s = Sheet(16, 8); s.anim("idle", [boost_pad(i) for i in range(3)], fps=10); s.save("sprites/boost_pad.png")
    lever().save("sprites/lever.png")
    s = Sheet(8, 8); s.anim("puff", [dust(i) for i in range(4)], fps=14, loop=False); s.save("sprites/dust.png")
    s = Sheet(8, 8); s.anim("twinkle", [sparkle(i) for i in range(4)], fps=14, loop=False); s.save("sprites/sparkle.png")
    s = Sheet(16, 16); s.anim("pop", [puff(i) for i in range(4)], fps=16, loop=False); s.save("sprites/puff.png")
    debris(hexc("a84f2f")).save("sprites/debris.png")


if __name__ == "__main__":
    build()
