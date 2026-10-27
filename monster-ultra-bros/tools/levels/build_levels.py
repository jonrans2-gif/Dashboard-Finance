"""Level authoring script. Composes the 12 levels with small helpers and writes
res://levels/<id>.txt. The text files are what the game loads (and what the
reachability test checks); this script only makes authoring less error-prone.

Physics budget used for design (verified by tests/test_physics.gd):
  * jump height ~3.7 tiles (required climbs <= 3 tiles)
  * same-height jump distance >= 4 tiles walking, ~6 running (required gaps <= 4)
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "levels")


class L:
    def __init__(self, w, h=17, gt=13, **header):
        self.w, self.h, self.gt = w, h, gt
        self.g = [["." for _ in range(w)] for _ in range(h)]
        self.header = header

    # -- primitives
    def put(self, x, y, ch):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.g[y][x] = ch

    def get(self, x, y):
        return self.g[y][x] if 0 <= x < self.w and 0 <= y < self.h else "#"

    def rect(self, x0, y0, x1, y1, ch):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, ch)

    def text(self, x, y, s):
        for i, ch in enumerate(s):
            if ch != " ":
                self.put(x + i, y, ch)

    # -- terrain helpers
    def ground(self, x0, x1, top=None, ch="#"):
        top = self.gt if top is None else top
        self.rect(x0, top, x1, self.h - 1, ch)

    def pit(self, x0, x1):
        """Bottomless gap: clears the ground rows only (ceilings stay)."""
        for x in range(x0, x1 + 1):
            for y in range(self.gt, self.h):
                self.put(x, y, ".")

    def goo_pit(self, x0, x1, top=None):
        top = self.gt + 2 if top is None else top
        for x in range(x0, x1 + 1):
            for y in range(self.gt, self.h):
                self.put(x, y, "~" if y >= top else ".")

    def pipe(self, x, top, base=None):
        base = self.gt - 1 if base is None else base
        for y in range(top, base + 1):
            self.put(x, y, "[")
            self.put(x + 1, y, "]")

    def stairs(self, x, n, up=True, ch="B", base=None):
        base = self.gt - 1 if base is None else base
        for i in range(n):
            hgt = i + 1 if up else n - i
            for k in range(hgt):
                self.put(x + i, base - k, ch)

    def column(self, x, y0, y1, ch):
        for y in range(y0, y1 + 1):
            self.put(x, y, ch)

    def tokens(self, x0, x1, y, step=1):
        for x in range(x0, x1 + 1, step):
            if self.get(x, y) == ".":
                self.put(x, y, "o")

    def arc_tokens(self, x0, y0, n=5):
        ys = [0, -1, -2, -2, -1, 0, 1][:n]
        for i in range(n):
            self.put(x0 + i, y0 + ys[i], "o")

    def platform(self, x0, x1, y, ch="_"):
        for x in range(x0, x1 + 1):
            self.put(x, y, ch)

    def mover_h(self, x, y, travel):
        self.put(x, y, "m")
        for i in range(1, travel + 1):
            self.put(x + i, y, "-")

    def mover_v(self, x, y, travel):
        self.put(x, y, "v")
        for i in range(1, travel + 1):
            self.put(x, y + i, ":")

    def ceiling(self, x0, x1, bottom, ch="#"):
        self.rect(x0, 0, x1, bottom, ch)

    def backwall(self, x0, x1, y0, y1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                if self.get(x, y) == ".":
                    self.put(x, y, "b")

    def goal(self, x):
        self.put(x, self.gt - 1, "G")

    def save(self, lid):
        os.makedirs(OUT, exist_ok=True)
        lines = [f"{k}={v}" for k, v in self.header.items()]
        lines.append("---")
        lines += ["".join(r).rstrip(".") or "." for r in self.g]
        lines.append("---")
        with open(os.path.join(OUT, f"{lid}.txt"), "w") as fh:
            fh.write("\n".join(lines) + "\n")


# =============================================================== WORLD 1
def level_1_1():
    L1 = L(212, name="The Beginning", theme="hills", bg="hills", music="overworld", time=300,
           powerups="mega,shield,double,magnet", items="")
    L1.ground(0, 211)
    # start area with signs
    L1.put(3, 12, "S"); L1.put(6, 12, "s"); L1.put(1, 12, "*"); L1.put(9, 12, "f")
    # first blocks: learn to jump
    L1.text(14, 9, "?")
    L1.text(19, 9, "=?=!=")
    L1.text(21, 5, "?")
    L1.put(24, 12, "e")
    L1.tokens(19, 23, 8, 2)
    # pipes of increasing height
    L1.pipe(30, 11); L1.put(28, 12, "f")
    L1.pipe(38, 10); L1.put(35, 12, "e")
    L1.pipe(46, 10); L1.put(43, 12, "e"); L1.put(44, 12, "e")
    L1.put(47, 6, "$")                         # shard 1: on top of the tallest pipe
    L1.pipe(54, 10)
    L1.put(51, 12, "*")
    # hidden 1-up block before the first gap
    L1.put(61, 9, "H")
    # first pit (2 wide)
    L1.pit(66, 67)
    L1.tokens(65, 68, 9)
    # brick ledge with power block, mega teaching
    L1.text(74, 9, "=!=")
    L1.text(78, 6, "=======")
    L1.put(81, 5, "$")                         # shard 2: on top of the upper bricks
    L1.text(78, 5, "ooo"); L1.text(82, 5, "ooo")
    L1.put(78, 12, "u")
    L1.put(86, 12, "e"); L1.put(88, 12, "e")
    L1.text(90, 9, "=?")
    L1.put(96, 12, "C")
    # second section: 3-wide pit and floating platforms
    L1.pit(102, 104)
    L1.platform(101, 105, 9, "c")
    L1.tokens(101, 105, 8)
    L1.text(110, 9, "?=?=?")
    L1.put(112, 5, "!")
    L1.put(114, 12, "e"); L1.put(117, 12, "u")
    # spring up to the secret clouds with the energy core
    L1.put(121, 12, "j")
    L1.platform(118, 127, 5, "c")
    L1.tokens(118, 125, 4)
    L1.put(126, 4, "@")
    # stairs and pit
    L1.stairs(130, 4)
    L1.pit(134, 135)
    L1.stairs(136, 4, up=False)
    L1.tokens(133, 136, 7)
    L1.put(142, 12, "e"); L1.put(145, 12, "e")
    L1.text(147, 9, "==?==")
    L1.put(149, 5, "$")                        # shard 3: above the brick row (needs a jump from the bricks)
    L1.pipe(156, 10); L1.put(160, 12, "u")
    L1.put(164, 12, "e"); L1.put(167, 12, "e")
    L1.text(170, 9, "?")
    # final staircase to the goal
    L1.stairs(180, 8)
    L1.column(188, 5, 12, "B")
    L1.pit(189, 190)
    L1.goal(200)
    L1.put(205, 12, "*"); L1.put(207, 12, "F"); L1.put(208, 12, "F")
    L1.save("1-1")


def level_1_2():
    L2 = L(206, name="Underground Energy", theme="cave", bg="cave", music="underground", time=300,
           backdrop="wall", backdrop_top=2, powerups="mega,surge,shield", items="")
    L2.ground(0, 205)
    L2.ceiling(0, 205, 1, "=")
    L2.rect(0, 0, 0, 16, "#")
    L2.put(3, 12, "S")
    L2.text(8, 9, "?????")
    L2.put(14, 12, "u"); L2.put(18, 12, "e")
    # low passage with bricks overhead
    L2.ceiling(22, 34, 7, "=")
    L2.tokens(23, 33, 11, 2)
    L2.put(28, 12, "e")
    L2.text(26, 8, "!")
    # rising rock steps
    L2.ground(38, 42, 11); L2.ground(43, 47, 9); L2.ground(48, 52, 11)
    L2.put(45, 8, "u")
    L2.put(45, 4, "$")                          # shard 1: above the peak
    L2.tokens(43, 47, 5)
    # pit with moving platform
    L2.pit(53, 60)
    L2.mover_h(54, 10, 3)
    L2.tokens(55, 59, 7)
    L2.ground(61, 70)
    L2.put(64, 12, "e"); L2.put(67, 12, "e")
    # rock outcrop (climb over it). Its lower part is a fake wall: walking
    # into it at floor level reveals a hidden chamber with the energy core.
    L2.ground(71, 82, 10)
    L2.rect(71, 11, 80, 12, "%")
    L2.put(78, 12, "@")
    L2.text(73, 12, "o.o")
    L2.put(86, 12, "C")
    # mid section: sugar cube pit hop
    L2.pit(88, 90)
    L2.ground(91, 96)
    L2.put(90, 12, "u"); L2.put(93, 12, "u")
    L2.text(89, 9, "=?=?=")
    L2.pit(97, 100)
    L2.platform(97, 100, 10, "_")
    L2.ground(101, 120)
    # door to the bonus room (bottom-left room hidden under the floor)
    L2.put(104, 12, "D")
    L2.put(110, 12, "e"); L2.put(113, 12, "k")
    L2.text(108, 9, "=!==")
    # vertical lift section
    L2.pit(121, 128)
    L2.mover_v(122, 6, 5)
    L2.ground(126, 130, 6)
    L2.rect(126, 7, 130, 12, "#")
    L2.put(128, 5, "$")                         # shard 2: on the high ledge
    L2.tokens(126, 130, 4)
    L2.ground(131, 150)
    L2.put(135, 12, "e"); L2.put(137, 12, "e"); L2.put(139, 12, "e")
    L2.text(141, 9, "?=?")
    L2.pipe(146, 10)
    # pit sequence with platforms
    L2.pit(151, 162)
    L2.platform(152, 153, 10); L2.platform(156, 157, 9); L2.platform(160, 161, 10)
    L2.tokens(152, 161, 7, 2)
    L2.ground(163, 205)
    L2.put(166, 12, "u"); L2.put(171, 12, "z")
    L2.stairs(176, 5)
    L2.ceiling(176, 183, 3, "=")
    L2.put(183, 8, "$")                         # shard 3: tucked under the ceiling above the stairs
    L2.column(181, 8, 12, "B"); L2.column(182, 8, 12, "B")
    L2.goal(194)
    # bonus room: reached through the door at 104, exit door brings you back
    L2.save("1-2")
    return L2


def patch_1_2_bonus():
    # The bonus room lives in a sealed chamber above the ceiling line at the far
    # left; easier: extend the level with a closed room at the end of the map.
    path = os.path.join(OUT, "1-2.txt")
    with open(path) as fh:
        text = fh.read()
    head, grid, tail = text.split("---\n")
    rows = grid.rstrip("\n").split("\n")
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    room = [
        "################",
        "################",
        "#bbbbbbbbbbbbbb#",
        "#bbbbbbbbbbbbbb#",
        "#bbbbbbbbbbbbbb#",
        "#bbbbbbbbbbbbbb#",
        "#booooooooooobb#",
        "#bbbbbbbbbbbbbb#",
        "#bboooooooooobb#",
        "#bbbbbbbbbbbbbb#",
        "#bbbbbbbbbbbbbb#",
        "#bbbbbbbbbbbbbb#",
        "#bDbbbbbb+bbbbb#",
        "################",
        "################",
        "################",
        "################",
    ]
    rows = [rows[i] + "." * 4 + room[i] for i in range(len(rows))]
    with open(path, "w") as fh:
        fh.write(head + "---\n" + "\n".join(rows) + "\n---" + tail)


def level_1_3():
    L3 = L(232, name="The White Fortress", theme="fortress", bg="fortress", music="fortress", time=360,
           backdrop="wall", backdrop_top=0, boss="sugar_king", powerups="mega,shield,double", items="")
    L3.ground(0, 231)
    L3.ceiling(0, 160, 1, "B")
    L3.put(3, 12, "S")
    L3.put(7, 12, "t"); L3.put(12, 12, "t")
    # lava moat with falling platforms
    L3.goo_pit(16, 23)
    L3.put(17, 10, "x"); L3.put(21, 10, "x")
    L3.ground(24, 40)
    L3.text(27, 9, "=!=")
    L3.put(30, 12, "e"); L3.put(34, 12, "e")
    # spikes corridor with low ceiling
    L3.ceiling(36, 50, 7, "B")
    L3.text(42, 12, "^^^")
    L3.tokens(41, 45, 10)
    L3.ground(41, 50)
    L3.text(42, 12, "^^^")
    L3.put(47, 12, "u")
    # pillars over lava
    L3.goo_pit(51, 66)
    L3.column(53, 10, 12, "B"); L3.column(54, 10, 12, "B")
    L3.column(58, 9, 12, "B"); L3.column(59, 9, 12, "B")
    L3.column(63, 10, 12, "B"); L3.column(64, 10, 12, "B")
    for x in (53, 54, 58, 59, 63, 64):
        L3.rect(x, 13, x, 16, "B")
    L3.tokens(53, 64, 6, 1)
    L3.put(58, 5, "$")                          # shard 1: above the middle pillar
    L3.ground(67, 90)
    L3.put(70, 12, "C")
    L3.text(74, 9, "?=?=?")
    L3.put(78, 12, "e"); L3.put(81, 12, "u"); L3.put(84, 12, "e")
    # secret: a hop-over wall whose lower-left face is fake; inside is the core
    L3.rect(86, 10, 90, 12, "B")
    L3.rect(86, 11, 89, 12, "%")
    L3.put(88, 12, "@")
    L3.ground(91, 110)
    L3.text(98, 12, "^^")
    L3.text(103, 12, "^^")
    L3.put(100, 9, "=")
    L3.put(100, 6, "$")                         # shard 2: above the brick between spike beds
    L3.put(107, 12, "e")
    # falling platform chain
    L3.goo_pit(111, 124)
    L3.put(112, 10, "x"); L3.put(116, 9, "x"); L3.put(120, 10, "x")
    L3.tokens(112, 122, 7, 2)
    L3.ground(125, 160)
    L3.put(128, 12, "C")
    L3.stairs(132, 3)
    L3.text(137, 8, "=?=")
    L3.put(138, 4, "$")                         # shard 3
    L3.put(141, 12, "u"); L3.put(144, 12, "e"); L3.put(147, 12, "u")
    L3.put(152, 12, "t"); L3.put(156, 12, "t")
    # boss arena: gate at 162, arena 163..231 (wide enough for every screen)
    L3.put(162, 12, "Y")
    L3.ceiling(162, 231, 1, "B")
    L3.platform(176, 179, 9); L3.platform(214, 217, 9)
    L3.put(196, 12, "Q")
    L3.goal(224)
    L3.save("1-3")


# =============================================================== WORLD 2
def level_2_1():
    L4 = L(224, name="Factory Run", theme="factory", bg="factory", music="factory", time=300,
           powerups="surge,mega,shield,surge", items="")
    L4.ground(0, 223)
    L4.put(3, 12, "S")
    L4.put(7, 12, "l")
    # conveyor intro (rows 12 are standing level; conveyors are the floor tiles)
    L4.rect(12, 13, 21, 13, ">")
    L4.text(15, 9, "?!?")
    L4.put(19, 12, "e")
    L4.rect(26, 13, 33, 13, "<")
    L4.put(30, 12, "e"); L4.put(32, 12, "e")
    # first drone over a pit
    L4.pit(37, 40)
    L4.platform(37, 40, 10)
    L4.put(39, 6, "d")
    L4.ground(41, 60)
    # barrier wall: dash through for the shard, or climb over
    L4.column(50, 9, 12, "X")
    L4.column(51, 9, 12, "X")
    L4.rect(50, 8, 51, 8, "B")
    L4.put(48, 12, "o")
    L4.stairs(45, 3)
    L4.platform(48, 52, 6)
    L4.put(53, 12, "$")                         # shard 1: behind the barrier (or drop down)
    L4.put(57, 12, "k")
    # crusher row
    L4.put(64, 2, "K"); L4.put(72, 2, "K")
    L4.tokens(62, 76, 12, 2)
    L4.put(68, 12, "C")
    L4.pipe(78, 10)
    L4.ground(78, 100)
    L4.put(84, 12, "k"); L4.put(88, 12, "e")
    L4.text(86, 9, "=?=!=")
    L4.rect(92, 13, 99, 13, ">")
    # acid pit with moving platforms and a drone
    L4.goo_pit(101, 114)
    L4.mover_h(102, 10, 7)
    L4.put(108, 5, "d")
    L4.tokens(103, 112, 7, 3)
    L4.ground(115, 140)
    L4.put(120, 12, "z"); L4.put(126, 12, "k")
    L4.text(123, 9, "?=?")
    # secret core: barrier block cache high up, reached with the spring
    L4.put(131, 12, "j")
    L4.platform(128, 136, 5)
    L4.rect(137, 2, 139, 5, "X")
    L4.put(138, 4, "@")
    L4.rect(137, 6, 139, 6, "B"); L4.rect(140, 2, 140, 6, "B")
    L4.put(133, 4, "$")                         # shard 2: on the high catwalk
    L4.put(142, 12, "C")
    L4.ground(141, 223)
    L4.put(148, 2, "K"); L4.put(154, 2, "K"); L4.put(160, 2, "K")
    L4.tokens(146, 162, 11, 2)
    L4.rect(166, 13, 176, 13, "<")
    L4.put(170, 12, "k"); L4.put(173, 12, "e")
    L4.put(172, 6, "d")
    L4.text(180, 9, "?=?")
    L4.put(181, 5, "$")                         # shard 3
    L4.stairs(190, 6)
    L4.goal(206)
    L4.save("2-1")


def level_2_2():
    # Taller level: climb through the energy storage tanks (stand rows noted).
    L5 = L(150, h=34, gt=30, name="Energy Storage", theme="factory", bg="factory", music="factory", time=320,
           backdrop="wall", backdrop_top=0, powerups="double,mega,shield,surge", items="")
    L5.ground(0, 100)
    L5.goo_pit(101, 149, top=31)
    L5.put(3, 29, "S")
    L5.text(8, 26, "?!?")
    L5.put(13, 29, "e")
    # tank 1: optional climb inside for shard 1 (walk under the walls to skip)
    L5.rect(18, 8, 19, 26, "B"); L5.rect(30, 8, 31, 26, "B"); L5.rect(18, 8, 31, 8, "B")
    for (x0, row) in [(20, 27), (25, 24), (20, 21), (25, 18), (20, 15)]:
        L5.platform(x0, x0 + 4, row)
        L5.put(x0 + 2, row - 1, "o")
    L5.put(22, 12, "$")
    L5.put(26, 29, "u")
    # lift up to the catwalk (stand row 10)
    L5.mover_v(33, 11, 17)
    L5.rect(36, 11, 60, 11, "#")
    L5.put(40, 10, "C")
    L5.put(46, 10, "k"); L5.put(52, 10, "e")
    L5.text(44, 7, "=?=")
    L5.put(56, 1, "K")
    L5.tokens(54, 59, 10)
    # shaft back down (lined with tokens); the walls leave a gap at the floor
    L5.rect(61, 11, 61, 26, "B")
    L5.rect(64, 15, 64, 26, "B")
    L5.column(62, 14, 26, "o")
    # lower factory floor
    L5.rect(68, 30, 80, 30, ">")
    L5.put(72, 29, "z"); L5.put(78, 29, "k")
    L5.put(76, 24, "d")
    L5.text(82, 26, "?=!=?")
    # spring + platforms up to tank 2
    L5.put(87, 29, "j")
    L5.platform(85, 89, 22)
    L5.platform(86, 89, 19)
    L5.rect(90, 16, 100, 29, "B")
    # secret: the lower-left face of tank 2 is fake; the core hides inside
    L5.rect(90, 26, 93, 29, "%")
    L5.put(92, 29, "@")
    L5.tokens(91, 99, 14, 2)
    # over the acid: step platforms and a moving platform to the top catwalk
    L5.platform(101, 105, 13)
    L5.platform(106, 110, 10)
    L5.put(108, 6, "$")
    L5.put(103, 12, "C")
    L5.mover_h(111, 10, 6)
    L5.rect(121, 10, 149, 10, "#")
    L5.put(125, 9, "k"); L5.put(131, 9, "u")
    L5.text(127, 6, "=?=")
    L5.put(128, 4, "$")
    L5.put(140, 9, "G")
    L5.save("2-2")


def level_2_3():
    L6 = L(236, name="The Machine Core", theme="factory", bg="factory", music="factory", time=360,
           backdrop="wall", backdrop_top=0, boss="crusher_prime", powerups="mega,surge,shield,double", items="")
    L6.ground(0, 235)
    L6.ceiling(0, 160, 1, "B")
    L6.put(3, 12, "S")
    L6.text(8, 9, "?!?")
    L6.put(14, 2, "K"); L6.put(20, 2, "K"); L6.put(26, 2, "K")
    L6.tokens(12, 30, 12, 2)
    L6.put(32, 12, "k")
    L6.goo_pit(35, 46)
    L6.mover_h(36, 10, 4); L6.mover_h(43, 8, 0)
    L6.platform(41, 42, 8)
    L6.put(41, 7, "$")                          # shard 1
    L6.ground(47, 80)
    L6.rect(50, 13, 60, 13, "<")
    L6.put(54, 12, "k"); L6.put(57, 12, "z")
    L6.put(55, 6, "d")
    L6.put(64, 12, "C")
    L6.text(66, 9, "=!=")
    # secret room sealed by an energy barrier: dash through it (Energy Surge
    # comes from the "!" block above). The main route goes over its roof.
    L6.rect(72, 10, 73, 12, "X")
    L6.rect(74, 9, 79, 9, "B")
    L6.column(79, 10, 12, "B")
    L6.put(76, 12, "@")
    L6.text(75, 11, "o.o")
    L6.ground(81, 92, 11)
    L6.goo_pit(93, 110)
    L6.put(95, 10, "x"); L6.put(99, 9, "x"); L6.put(103, 10, "x"); L6.put(107, 9, "x")
    L6.put(101, 5, "d")
    L6.ground(111, 160)
    L6.put(113, 12, "C")
    L6.put(118, 2, "K"); L6.put(122, 2, "K"); L6.put(126, 2, "K"); L6.put(130, 2, "K")
    L6.put(124, 12, "$")                        # shard 2: under the crusher gauntlet
    L6.rect(134, 13, 146, 13, ">")
    L6.put(138, 12, "k"); L6.put(142, 12, "e"); L6.put(144, 12, "z")
    L6.text(149, 9, "?=?")
    L6.put(150, 5, "$")                         # shard 3
    L6.put(156, 12, "C")
    L6.put(162, 12, "Y")
    L6.ceiling(162, 235, 1, "B")
    L6.platform(170, 173, 9); L6.platform(224, 227, 9)
    L6.put(198, 12, "Q")
    L6.goal(229)
    L6.save("2-3")


# =============================================================== WORLD 3
def level_3_1():
    H = 26
    L7 = L(210, h=H, gt=22, name="Frozen Peaks", theme="ice", bg="ice", music="ice", time=320,
           powerups="double,shield,mega,magnet", items="")
    L7.ground(0, 209)
    L7.put(3, 21, "S")
    L7.text(8, 18, "?!?")
    L7.rect(14, 22, 24, 22, "I")
    L7.put(20, 21, "z")
    # first peak (climb up 3s)
    L7.ground(26, 31, 19); L7.ground(32, 37, 16); L7.ground(38, 43, 13)
    L7.rect(32, 16, 37, 16, "n"); L7.rect(38, 13, 43, 13, "n")
    L7.put(40, 12, "z")
    L7.put(41, 8, "$")                          # shard 1: above the first summit
    L7.tokens(38, 43, 10)
    L7.ground(44, 49, 16); L7.ground(50, 55, 19)
    L7.put(52, 18, "e")
    # icy valley with slimes
    L7.rect(56, 22, 70, 22, "I")
    L7.put(60, 21, "z"); L7.put(66, 21, "z")
    L7.text(61, 18, "=?=")
    L7.put(72, 21, "C")
    # spring to high plateau
    L7.put(76, 21, "j")
    L7.ground(78, 96, 14)
    L7.rect(78, 14, 96, 14, "I")
    L7.put(84, 13, "z"); L7.put(90, 13, "k")
    L7.text(86, 10, "?=?")
    L7.put(94, 12, "$")                         # shard 2 on the high plateau
    # plateau drops into a pit area with platforms
    L7.pit(97, 110)
    L7.platform(98, 100, 16, "c"); L7.platform(103, 105, 14, "c"); L7.platform(108, 110, 17, "c")
    L7.tokens(98, 110, 12, 3)
    L7.ground(111, 130)
    L7.put(115, 21, "e"); L7.put(120, 21, "u"); L7.put(125, 21, "z")
    L7.text(117, 18, "=!=")
    # snowy hill; the lower part of its first step is a fake wall hiding the core
    L7.ground(131, 136, 19); L7.ground(137, 142, 16); L7.ground(143, 148, 13)
    L7.rect(131, 19, 136, 19, "n"); L7.rect(137, 16, 142, 16, "n"); L7.rect(143, 13, 148, 13, "n")
    L7.rect(131, 20, 135, 21, "%")
    L7.put(134, 21, "@")
    L7.put(145, 12, "C")
    L7.put(140, 15, "z")
    L7.ground(149, 154, 16); L7.ground(155, 160, 19)
    L7.put(151, 11, "$")                        # shard 3 above the far slope
    L7.ground(159, 209)
    L7.rect(162, 22, 176, 22, "I")
    L7.put(166, 21, "z"); L7.put(170, 21, "k"); L7.put(174, 21, "z")
    L7.stairs(182, 6, base=21)
    L7.goal(198)
    L7.save("3-1")


def level_3_2():
    L8 = L(214, name="Ice Caverns", theme="ice", bg="cave", music="ice", time=320,
           backdrop="wall", backdrop_top=2, powerups="shield,mega,double", items="")
    L8.ground(0, 213)
    L8.ceiling(0, 213, 2, "#")
    L8.put(3, 12, "S")
    L8.rect(8, 13, 20, 13, "I")
    L8.put(12, 3, "i"); L8.put(16, 3, "i")
    L8.text(13, 9, "?!?")
    L8.put(19, 12, "z")
    L8.ceiling(22, 40, 6, "#")
    L8.put(26, 7, "i"); L8.put(31, 7, "i"); L8.put(36, 7, "i")
    L8.tokens(24, 38, 11, 2)
    L8.put(33, 12, "z")
    # zapper corridor
    L8.put(44, 3, "Z"); L8.put(50, 3, "Z"); L8.put(56, 3, "Z")
    L8.put(52, 12, "e")
    L8.text(46, 9, "?")
    L8.put(47, 5, "$")                          # shard 1 between zappers
    L8.put(60, 12, "C")
    # icy pit with falling platforms
    L8.pit(64, 78)
    L8.put(65, 10, "x"); L8.put(69, 9, "x"); L8.put(73, 10, "x")
    L8.tokens(65, 76, 7, 2)
    L8.ground(79, 110)
    L8.rect(82, 13, 96, 13, "I")
    L8.put(86, 12, "z"); L8.put(92, 12, "k")
    L8.put(89, 3, "i")
    L8.text(98, 9, "=?=")
    # door to the hidden ice grotto (core) at the end of the map
    L8.put(104, 12, "D")
    L8.put(108, 12, "C")
    L8.ground(111, 120, 10)
    L8.rect(111, 10, 120, 10, "I")
    L8.put(116, 9, "z")
    L8.put(118, 5, "$")                         # shard 2 on the raised ice shelf
    L8.ground(121, 160)
    L8.put(124, 3, "Z"); L8.put(130, 3, "Z")
    L8.put(127, 12, "z"); L8.put(133, 12, "e")
    L8.pit(136, 142)
    L8.mover_h(136, 10, 3)
    L8.ground(143, 213)
    L8.put(146, 3, "i"); L8.put(150, 3, "i"); L8.put(154, 3, "i")
    L8.put(148, 12, "k"); L8.put(152, 12, "z")
    L8.text(158, 9, "?!?")
    L8.put(165, 3, "Z")
    L8.put(167, 12, "$")                        # shard 3 right after the last zapper
    L8.stairs(178, 5)
    L8.goal(200)
    L8.save("3-2")


def patch_3_2_grotto():
    path = os.path.join(OUT, "3-2.txt")
    with open(path) as fh:
        text = fh.read()
    head, grid, tail = text.split("---\n")
    rows = grid.rstrip("\n").split("\n")
    w = max(len(r) for r in rows)
    rows = [r.ljust(w, ".") for r in rows]
    room = [
        "##############",
        "##############",
        "##############",
        "#bbbbbbbbbbbb#",
        "#bbbbbbbbbbbb#",
        "#bbbbbbbbbbbb#",
        "#bbbybbbbybbb#",
        "#bbbbbbbbbbbb#",
        "#bbooooooobbb#",
        "#bbbbbbbbbbbb#",
        "#bbbbbbbbbbbb#",
        "#bbbbbbbbbbbb#",
        "#bDbbbbb@bbbb#",
        "##############",
        "##############",
        "##############",
        "##############",
    ]
    rows = [rows[i] + "...." + room[i] for i in range(len(rows))]
    with open(path, "w") as fh:
        fh.write(head + "---\n" + "\n".join(rows) + "\n---" + tail)


def level_3_3():
    L9 = L(240, name="The Storm Bridge", theme="ice", bg="ice", music="ice", time=360,
           boss="frost_volt", powerups="double,shield,mega,magnet", items="")
    L9.ground(0, 14)
    L9.put(3, 12, "S")
    L9.text(7, 9, "?!?")
    # the bridge: one-way planks over a bottomless gorge
    L9.platform(15, 40, 12, "_")
    L9.put(22, 11, "z"); L9.put(32, 11, "k")
    L9.put(27, 2, "Z")
    L9.rect(26, 0, 28, 1, "#")
    L9.tokens(17, 38, 9, 3)
    L9.platform(43, 48, 12, "_")
    L9.platform(51, 56, 11, "_")
    L9.put(53, 6, "d")
    L9.put(54, 5, "$")                          # shard 1 above the bridge gap
    L9.platform(59, 90, 12, "_")
    L9.put(62, 11, "C")
    L9.put(66, 2, "Z"); L9.put(74, 2, "Z"); L9.put(82, 2, "Z")
    for x in (66, 74, 82):
        L9.rect(x - 1, 0, x + 1, 1, "#")
    L9.put(70, 11, "z"); L9.put(78, 11, "e")
    # towers: climb the bridge pillars
    L9.ground(91, 96, 10)
    L9.platform(97, 103, 8, "_")
    L9.put(100, 7, "d")
    L9.ground(104, 109, 10)
    L9.put(106, 6, "$")                         # shard 2 on the second tower
    L9.mover_h(110, 11, 6)
    L9.platform(119, 150, 12, "_")
    L9.put(124, 11, "C")
    L9.put(128, 11, "z"); L9.put(134, 11, "k"); L9.put(140, 11, "z")
    L9.put(131, 6, "d")
    # secret: a cloud ledge below the bridge with the energy core (spring on the bridge)
    L9.platform(144, 150, 15, "c")
    L9.put(147, 14, "@")
    L9.put(145, 14, "o"); L9.put(146, 14, "o")
    L9.put(149, 14, "j")
    L9.platform(153, 158, 12, "_")
    L9.put(156, 8, "$")                         # shard 3
    L9.ground(160, 239)
    L9.put(163, 12, "C")
    L9.put(167, 12, "Y")
    L9.platform(178, 181, 9, "_"); L9.platform(225, 228, 9, "_")
    L9.put(202, 12, "Q")
    L9.goal(232)
    L9.save("3-3")


# =============================================================== WORLD 4
def level_4_1():
    L10 = L(250, name="Ultra Highway", theme="ultra", bg="ultra", music="ultra", time=300,
            powerups="surge,shield,overload,mega", items="")
    L10.ground(0, 249)
    L10.put(3, 12, "S")
    L10.put(8, 12, "r"); L10.put(9, 12, "r")
    L10.text(14, 9, "?!?")
    L10.pit(20, 22)
    L10.put(26, 12, "k"); L10.put(30, 12, "k")
    L10.put(34, 12, "r")
    L10.pit(38, 40)
    L10.tokens(37, 43, 9)
    L10.put(46, 6, "d")
    L10.put(50, 12, "z")
    L10.text(52, 9, "?=?")
    L10.put(53, 5, "$")                         # shard 1 (stand on the blocks)
    L10.pit(58, 70)
    L10.mover_h(59, 10, 8)
    L10.put(64, 5, "d")
    L10.put(74, 12, "C")
    L10.put(78, 12, "r"); L10.put(79, 12, "r")
    L10.pit(84, 86)
    L10.put(92, 12, "k"); L10.put(95, 12, "k"); L10.put(98, 12, "z")
    # secret room behind an energy barrier (dash with Energy Surge); walk over the roof
    L10.column(98, 11, 12, "B")                 # step up to the roof
    L10.rect(102, 10, 103, 12, "X")
    L10.rect(102, 9, 109, 9, "B")
    L10.column(109, 10, 12, "B")
    L10.put(106, 12, "@")
    L10.ground(110, 140)
    L10.text(114, 9, "=!=")
    L10.put(119, 12, "k"); L10.put(122, 12, "e"); L10.put(125, 12, "k")
    L10.put(123, 6, "d")
    L10.pit(130, 132)
    L10.put(130, 9, "$")                        # shard 2 over the gap
    L10.put(136, 12, "r")
    L10.pit(141, 160)
    L10.mover_h(142, 10, 5); L10.mover_h(151, 8, 5)
    L10.tokens(143, 158, 6, 3)
    L10.ground(161, 249)
    L10.put(164, 12, "C")
    L10.put(168, 12, "r"); L10.put(169, 12, "r")
    L10.put(175, 12, "k"); L10.put(178, 12, "k"); L10.put(181, 12, "k")
    L10.put(180, 6, "d")
    L10.text(186, 9, "?=?=?")
    L10.put(188, 5, "$")                        # shard 3
    L10.pit(194, 196)
    L10.put(202, 12, "z"); L10.put(206, 12, "k")
    L10.stairs(214, 7)
    L10.goal(232)
    L10.save("4-1")


def level_4_2():
    L11 = L(228, name="Energy Reactor", theme="ultra", bg="ultra", music="ultra", time=340,
            backdrop="wall", backdrop_top=0, powerups="surge,mega,shield,double,surge", items="")
    L11.ground(0, 227)
    L11.ceiling(0, 227, 1, "#")
    L11.put(3, 12, "S")
    L11.text(7, 9, "?!?")
    L11.put(12, 2, "Z"); L11.put(18, 2, "Z")
    L11.put(15, 12, "z")
    L11.goo_pit(22, 33)
    L11.mover_v(24, 5, 6); L11.mover_v(29, 7, 4)
    L11.put(27, 4, "$")                         # shard 1 between the lifts
    L11.ground(34, 70)
    L11.put(38, 2, "K"); L11.put(44, 2, "K")
    L11.put(48, 12, "k"); L11.put(52, 12, "z")
    L11.text(55, 9, "=!=")
    L11.rect(60, 2, 61, 9, "X")                 # hanging barrier: walk under or dash through
    L11.put(64, 12, "C")
    L11.put(67, 12, "e")
    L11.goo_pit(71, 90)
    L11.put(72, 10, "x"); L11.put(76, 9, "x"); L11.put(80, 10, "x"); L11.put(84, 9, "x")
    L11.put(78, 5, "d")
    L11.ground(91, 130)
    L11.put(94, 2, "Z"); L11.put(100, 2, "Z"); L11.put(106, 2, "Z")
    L11.put(97, 12, "z"); L11.put(103, 12, "k")
    L11.text(110, 9, "?=?")
    L11.put(111, 5, "$")                        # shard 2
    # secret: hidden reactor vent with the core, under the fake floor at 118..122
    L11.rect(117, 13, 123, 16, "%")
    L11.put(120, 15, "@")
    L11.rect(117, 16, 123, 16, "#")
    L11.put(126, 12, "C")
    L11.goo_pit(131, 150)
    L11.mover_h(132, 10, 6)
    L11.mover_v(142, 4, 6)
    L11.platform(145, 150, 6)
    L11.put(148, 5, "$")                        # shard 3 high on the reactor ledge
    L11.ground(151, 227)
    L11.put(154, 2, "K"); L11.put(160, 2, "K"); L11.put(166, 2, "K")
    L11.put(170, 12, "z"); L11.put(174, 12, "k"); L11.put(177, 12, "k")
    L11.put(176, 6, "d")
    L11.rect(184, 2, 184, 9, "X")
    L11.text(188, 9, "?!?")
    L11.stairs(196, 5)
    L11.goal(214)
    L11.save("4-2")


def level_4_3():
    L12 = L(200, name="The Final Overload", theme="ultra", bg="ultra", music="ultra", time=420,
            backdrop="wall", backdrop_top=0, boss="overload_core", powerups="mega,surge,shield,overload,double,surge", items="")
    L12.ground(0, 199)
    L12.ceiling(0, 199, 1, "#")
    L12.put(3, 12, "S")
    L12.text(7, 9, "?!?")
    L12.put(12, 12, "r")
    L12.put(16, 12, "k"); L12.put(19, 12, "k")
    L12.put(22, 2, "K"); L12.put(28, 2, "K")
    L12.goo_pit(32, 44)
    L12.mover_h(33, 10, 6)
    L12.put(38, 5, "d")
    L12.put(40, 4, "$")                         # shard 1
    L12.ground(45, 80)
    L12.put(48, 2, "Z"); L12.put(54, 2, "Z")
    L12.put(51, 12, "z"); L12.put(57, 12, "u"); L12.put(60, 12, "k")
    L12.text(63, 9, "=!=")
    L12.put(68, 12, "C")
    # secret room behind an energy barrier; hop the step and walk over the roof
    L12.text(70, 9, "!")
    L12.column(69, 11, 12, "B")
    L12.rect(72, 10, 73, 12, "X")
    L12.rect(72, 9, 79, 9, "#")
    L12.column(79, 10, 12, "#")
    L12.put(76, 12, "@")
    L12.ground(74, 80)
    L12.goo_pit(81, 100)
    L12.put(82, 10, "x"); L12.put(86, 9, "x"); L12.put(90, 10, "x"); L12.put(94, 9, "x")
    L12.mover_h(97, 10, 2)
    L12.ground(101, 150)
    L12.put(104, 12, "C")
    L12.put(108, 2, "K"); L12.put(112, 2, "K"); L12.put(116, 2, "K")
    L12.put(120, 12, "$")                       # shard 2 at the end of the crusher row
    L12.put(124, 2, "Z"); L12.put(130, 2, "Z")
    L12.put(126, 12, "z"); L12.put(132, 12, "k"); L12.put(136, 12, "u")
    L12.put(134, 6, "d")
    L12.text(140, 9, "?=?")
    L12.put(141, 5, "$")                        # shard 3
    L12.put(146, 12, "C")
    # final arena (152..199)
    L12.put(152, 12, "Y")
    L12.platform(162, 166, 10); L12.platform(172, 176, 8)
    L12.text(164, 6, "!"); L12.text(174, 4, "!")
    L12.put(192, 12, "Q")
    L12.goal(158)
    L12.save("4-3")


if __name__ == "__main__":
    level_1_1()
    level_1_2(); patch_1_2_bonus()
    level_1_3()
    level_2_1(); level_2_2(); level_2_3()
    level_3_1(); level_3_2(); patch_3_2_grotto(); level_3_3()
    level_4_1(); level_4_2(); level_4_3()
    print("levels written")
