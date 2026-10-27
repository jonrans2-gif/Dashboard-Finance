"""Touch buttons, HUD icons, title logo and launcher icons."""
import math
import os

from PIL import Image, ImageDraw, ImageFont

from pix import Canvas, Sheet, hexc, mix, shade, OUT
from player import frame as player_frame

WHITE = hexc("ffffff")
DARK = hexc("1a1a24")
FONT = os.path.join(OUT, "fonts", "ultrapixel.ttf")


def button(icon, pressed):
    """48x48 round touch button; the game scales it with the size setting."""
    c = Canvas(48, 48)
    rim = hexc("ffffff", 200 if pressed else 150)
    face = hexc("ffffff", 120) if pressed else hexc("1a1a24", 110)
    c.circle(24, 24, 22.5, rim)
    c.circle(24, 24, 20.5, face)
    col = DARK if pressed else WHITE
    if icon == "left":
        c.poly([(13, 24), (29, 12), (29, 36)], col)
    elif icon == "right":
        c.poly([(35, 24), (19, 12), (19, 36)], col)
    elif icon == "jump":
        c.poly([(24, 10), (37, 25), (29, 25), (29, 37), (19, 37), (19, 25), (11, 25)], col)
    elif icon == "dash":
        c.poly([(28, 8), (14, 27), (23, 27), (19, 40), (34, 20), (25, 20), (28, 8)], col)
    elif icon == "pause":
        c.rect(16, 13, 6, 22, col); c.rect(26, 13, 6, 22, col)
    return c


def icons():
    s = Sheet(12, 12)
    # energy cell (HP)
    def cell(full):
        c = Canvas(12, 12)
        c.rect(2, 1, 8, 10, DARK); c.rect(4, 0, 4, 1, DARK)
        if full:
            c.rect(3, 2, 6, 8, hexc("7dff5a")); c.rect(3, 2, 2, 8, hexc("c6ffb0"))
        else:
            c.rect(3, 2, 6, 8, hexc("3a3f4c"))
        return c
    s.anim("cell_full", [cell(True)], fps=1)
    s.anim("cell_empty", [cell(False)], fps=1)
    life = Canvas(12, 12)
    from player import draw_can
    draw_can(life, 6, 11, w=7, h=10, eyes="happy", mouth="smile", look=0, band=False)
    life.outline()
    s.anim("life", [life], fps=1)
    tok = Canvas(12, 12)
    tok.ellipse(6, 6, 5, 5, hexc("e0a315")); tok.ellipse(5.5, 6, 3.8, 4, hexc("ffd23f"))
    for (x, y) in [(6, 3), (5, 5), (7, 5), (6, 7), (5, 8)]:
        tok.set(x, y, WHITE)
    tok.outline(hexc("9a6a0a"))
    s.anim("token", [tok], fps=1)
    def shard(full):
        c = Canvas(12, 12)
        col = hexc("8fe0ff") if full else hexc("3a3f4c")
        c.poly([(6, 0), (11, 5), (6, 12), (1, 5)], col)
        if full:
            c.line(6, 1, 6, 10, WHITE)
        c.outline(hexc("1a3a5a") if full else DARK)
        return c
    s.anim("shard_full", [shard(True)], fps=1)
    s.anim("shard_empty", [shard(False)], fps=1)
    clock = Canvas(12, 12)
    clock.circle(6, 6, 5, WHITE); clock.circle(6, 6, 5, DARK, fill=False)
    clock.vline(6, 3, 6, DARK); clock.hline(6, 8, 6, DARK)
    s.anim("clock", [clock], fps=1)
    core = Canvas(12, 12)
    core.circle(6, 6, 5, hexc("3fd13a")); core.circle(6, 6, 2.5, WHITE)
    core.outline()
    s.anim("core", [core], fps=1)
    lock = Canvas(12, 12)
    lock.rect(2, 5, 8, 7, hexc("c8ccd6")); lock.rect(3, 1, 6, 5, DARK); lock.rect(4, 2, 4, 4, (0, 0, 0, 0))
    lock.set(6, 8, DARK); lock.set(6, 9, DARK)
    lock.outline()
    s.anim("lock", [lock], fps=1)
    skull = Canvas(12, 12)
    skull.circle(6, 5, 4.5, WHITE); skull.rect(4, 8, 5, 3, WHITE)
    skull.rect(3, 4, 2, 2, DARK); skull.rect(7, 4, 2, 2, DARK)
    skull.outline()
    s.anim("enemy", [skull], fps=1)
    s.save("ui/icons.png")


def text_img(text, size, fill, outline=DARK, stroke=1):
    f = ImageFont.truetype(FONT, size)
    l, t, r, b = f.getbbox(text)
    pad = stroke + 2
    im = Image.new("RGBA", (r - l + pad * 2, b - t + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((pad - l, pad - t), text, font=f, fill=fill, stroke_width=stroke, stroke_fill=outline)
    return im


def logo():
    # Rendered at 1 pixel-font pixel = 2 px (size 20), then upscaled in-game.
    big = text_img("MONSTER ULTRA", 20, (255, 255, 255, 255), stroke=0)
    bros = text_img("BROS.", 30, (255, 255, 255, 255), stroke=0)
    sub = text_img("WHITE EDITION", 10, (35, 37, 45, 255), stroke=0)
    W = max(big.width, bros.width) + 24
    H = big.height + bros.height + sub.height + 22
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # claw marks behind the title
    d = ImageDraw.Draw(img)
    for k in range(3):
        x = W // 2 - 26 + k * 24
        d.polygon([(x, 2), (x + 10, 2), (x + 2, H - 4), (x - 4, H - 4)], fill=(35, 37, 45, 255))
        d.polygon([(x + 2, 4), (x + 7, 4), (x + 1, H - 8), (x - 2, H - 8)], fill=(80, 86, 100, 255))
    def silver(im):
        px = im.load()
        for y in range(im.height):
            t = y / max(1, im.height - 1)
            col = (255, 255, 255) if t < 0.45 else (int(230 - 70 * (t - 0.45)), int(234 - 70 * (t - 0.45)), int(242 - 60 * (t - 0.45)))
            for x in range(im.width):
                if px[x, y][3]:
                    px[x, y] = col + (255,)
        return im
    big = silver(big); bros = silver(bros)
    y = 4
    img.alpha_composite(big, ((W - big.width) // 2, y)); y += big.height + 2
    img.alpha_composite(bros, ((W - bros.width) // 2, y)); y += bros.height + 4
    # subtitle plate
    pw = sub.width + 12
    plate = Image.new("RGBA", (pw, sub.height + 4), (255, 255, 255, 255))
    plate.alpha_composite(sub, (6, 2))
    img.alpha_composite(plate, ((W - pw) // 2, y))
    # outline pass
    c = Canvas(W + 4, H + 4)
    c.img.alpha_composite(img, (2, 2))
    c.px = c.img.load()
    c.outline(DARK, diagonal=True)
    c.outline(hexc("000000", 120))
    c.save("ui/logo.png")


def app_icons():
    p = player_frame(eyes="happy", mouth="open_smile", arms="up", feet="stand")
    def claws(c, x0, step, width, col):
        for k in range(3):
            x = x0 + k * step
            c.poly([(x, 0), (x + width, 0), (x + 1, c.h), (x - width // 2, c.h)], col)
    base = Canvas(32, 32)
    base.rect(0, 0, 32, 32, hexc("23252d"))
    claws(base, 7, 8, 4, hexc("30333e"))
    base.blit(p, 4, 0)
    img = base.img.resize((192, 192), Image.NEAREST)
    os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)
    img.save(os.path.join(OUT, "icons", "icon_192.png"))
    fg = Canvas(54, 54)
    fg.blit(p, 15, 11)
    fg.img.resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "icons", "icon_fg_432.png"))
    bg = Canvas(54, 54)
    bg.rect(0, 0, 54, 54, hexc("23252d"))
    claws(bg, 14, 12, 6, hexc("30333e"))
    bg.img.resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "icons", "icon_bg_432.png"))
    mono = Canvas(54, 54)
    mono.blit(p, 15, 11)
    for y in range(mono.h):
        for x in range(mono.w):
            if mono.px[x, y][3]:
                mono.px[x, y] = (255, 255, 255, 255)
    mono.img.resize((432, 432), Image.NEAREST).save(os.path.join(OUT, "icons", "icon_mono_432.png"))
    img.resize((128, 128), Image.NEAREST).save(os.path.join(OUT, "..", "icon.png"))


def build():
    s = Sheet(48, 48)
    for ic in ("left", "right", "jump", "dash", "pause"):
        s.anim(ic, [button(ic, False), button(ic, True)], fps=1)
    s.save("ui/buttons.png", cols=10)
    icons()
    logo()
    app_icons()


if __name__ == "__main__":
    build()
