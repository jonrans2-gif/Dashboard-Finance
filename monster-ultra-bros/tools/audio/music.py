"""Original soundtrack for Monster Ultra Bros. (all melodies written for this game)."""
from synth import (Song, inst_arp, inst_bass, inst_bell, inst_lead, inst_pad, inst_pluck,
                   inst_saw, write_wav, parse_seq)

KICK4 = "k...k...k...k..."
BACK = "....s.......s..."
HAT8 = "h.h.h.h.h.h.h.h."
HAT16 = "hhhhhhhhhhhhhhhh"


def transpose_seq(seq, semis):
    return [(None if m is None else m + semis, d) for m, d in parse_seq(seq)]


# ------------------------------------------------------------------ main menu
MENU_A = ("E5.2 G5.2 C6.4 B5.2 G5.2 E5.4 "
          "D5.2 G5.2 B5.4 A5.2 G5.2 D5.4 "
          "C5.2 E5.2 A5.4 G5.2 E5.2 C5.2 E5.2 "
          "F5.4 A5.4 G5.2 F5.2 E5.2 D5.2 "
          "E5.2 G5.2 C6.4 D6.2 C6.2 B5.2 G5.2 "
          "B5.4 D6.4 G5.6 -.2 "
          "A5.2 C6.2 A5.2 F5.2 G5.2 A5.2 G5.2 F5.2 "
          "E5.4 D5.4 G5.8 ")
MENU_B = ("A5.6 G5.2 E5.4 C5.4 "
          "F5.6 E5.2 F5.2 G5.2 A5.4 "
          "G5.6 E5.2 C5.4 E5.4 "
          "D5.6 E5.2 G5.8 "
          "A5.4 B5.4 C6.4 A5.4 "
          "F5.4 G5.4 A5.4 C6.4 "
          "F#5.4 A5.4 D6.4 C6.4 "
          "B5.4 A5.2 G5.2 D6.8 ")
MENU_CH = ["C", "G", "Am", "F", "C", "G", "F", "G", "Am", "F", "C", "G", "Am", "F", "D", "G"]


def menu():
    s = Song(132, 16)
    s.melody(MENU_A + MENU_B, inst_lead, duty=0.25)
    s.chords_arp(MENU_CH, inst_arp, octave=4, pattern=(0, 1, 2, 1, 3, 2, 1, 2))
    s.chords_bass(MENU_CH, "bounce")
    s.drums_multi([[KICK4.replace("k...k...", "k.....k.")], [BACK], [HAT8]])
    write_wav("music/menu.wav", s.mix({"arp": 0.8}, echo={"lead": (3, 0.25)}), loop=True)


def credits():
    s = Song(108, 16)
    s.melody(MENU_A + MENU_B, inst_bell, vol=0.3)
    s.pads(MENU_CH, octave=4)
    s.chords_arp(MENU_CH, inst_pluck, octave=4, pattern=(0, 2, 1, 2), rate=2, vol=0.12)
    s.chords_bass(MENU_CH, "long")
    s.drums_multi([["k.......k......."], ["........r......."], ["h...h...h...h..."]])
    write_wav("music/credits.wav", s.mix({"pad": 1.0}, echo={"lead": (3, 0.35)}), loop=True)


# ------------------------------------------------------------------ overworld
HILLS = ("C5.3 F5.3 A5.2 G5.2 F5.2 C5.4 "
         "D5.2 F5.2 A5.3 C6.3 A5.2 F5.4 "
         "D6.3 C6.3 Bb5.2 A5.2 G5.2 F5.4 "
         "A5.4 F5.2 -.2 C5.4 -.4 "
         "G5.3 Bb5.3 D6.2 C6.2 Bb5.2 G5.4 "
         "E5.3 G5.3 C6.2 Bb5.2 A5.2 G5.4 "
         "A5.2 C6.2 F6.4 E6.2 D6.2 C6.4 "
         "Bb5.2 A5.2 G5.4 E5.4 C5.4 "
         "F5.2 A5.2 D6.6 C6.2 A5.4 "
         "Bb5.2 D6.2 F6.6 D6.2 Bb5.4 "
         "A5.2 C6.2 F6.4 C6.2 A5.2 F5.4 "
         "G5.6 A5.2 Bb5.4 C6.4 "
         "D6.4 Bb5.4 F5.4 Bb5.4 "
         "C6.4 G5.4 E5.4 G5.4 "
         "F5.2 A5.2 C6.2 F6.2 E6.2 C6.2 A5.2 G5.2 "
         "F5.8 -.8 ")
HILLS_CH = ["F", "F", "Bb", "F", "Gm", "C", "F", "C", "Dm", "Bb", "F", "C", "Bb", "C", "F", "F"]


def overworld():
    s = Song(150, 16, swing=0.18)
    s.melody(HILLS, inst_lead, duty=0.5, vol=0.2)
    s.chords_arp(HILLS_CH, inst_arp, octave=4, pattern=(0, 2, 1, 2), rate=2, duty=0.25)
    s.chords_bass(HILLS_CH, "walk")
    fill = "k.k.k...s.s.ssss"
    s.drums_multi([["k.....k.k......."] * 7 + ["k.......k......."], ["....s.......s..."] * 7 + ["....s.....s.s.ss"], [HAT8]])
    write_wav("music/overworld.wav", s.mix({"arp": 0.9}, echo={"lead": (3, 0.2)}), loop=True)


# ------------------------------------------------------------------ underground
CAVE = ("A4.2 -.2 C5.2 -.2 E5.2 -.2 D5.2 C5.2 "
        "B4.4 A4.2 -.2 E4.8 "
        "F4.2 -.2 A4.2 -.2 C5.2 -.2 B4.2 A4.2 "
        "G#4.4 B4.4 E5.8 "
        "A5.2 -.2 G5.2 -.2 E5.2 -.2 C5.2 D5.2 "
        "E5.6 D5.2 C5.4 B4.4 "
        "D5.2 -.2 F5.2 -.2 A5.2 G5.2 F5.2 D5.2 "
        "E5.4 G#5.4 B5.4 -.4 ")
CAVE_CH = ["Am", "Am", "F", "E", "Am", "Am", "Dm", "E"]


def underground():
    s = Song(116, 16)
    s.melody(CAVE + CAVE, inst_pluck, vol=0.26)
    s.chords_bass(CAVE_CH * 2, "ostinato", octave=2)
    s.chords_arp(CAVE_CH * 2, inst_arp, octave=5, pattern=(2, 1, 0, 1), rate=4, vol=0.04)
    s.drums_multi([["k.......k......."], ["....r.......r..r"], ["..h...h...h...h."]])
    write_wav("music/underground.wav", s.mix({"arp": 1.0}, echo={"lead": (3, 0.4)}), loop=True)


# ------------------------------------------------------------------ fortress
FORT = ("D5.4 F5.2 E5.2 D5.4 A4.4 "
        "Bb4.4 D5.2 C5.2 Bb4.4 F4.4 "
        "C5.4 E5.2 D5.2 C5.4 G4.4 "
        "A4.4 C#5.4 E5.4 A5.4 "
        "A5.2 G5.2 F5.2 E5.2 D5.4 F5.4 "
        "G5.2 F5.2 E5.2 D5.2 Bb4.4 D5.4 "
        "C#5.4 E5.4 G5.4 F5.2 E5.2 "
        "C#5.8 A4.8 ")
FORT_CH = ["Dm", "Bb", "C", "A", "Dm", "Gm", "A", "A"]


def fortress():
    s = Song(128, 16)
    s.melody(FORT + FORT, inst_lead, duty=0.125, vol=0.22)
    s.chords_bass(FORT_CH * 2, "root8", octave=2)
    s.pads(FORT_CH * 2, octave=3, vol=0.05)
    s.drums_multi([["k.......k.k....."], ["....s.......s.ss", "....s.......sss."], ["h.h.h.h.h.h.h.h."]])
    write_wav("music/fortress.wav", s.mix(echo={"lead": (2, 0.25)}), loop=True)


# ------------------------------------------------------------------ factory
FACT = ("E5.2 E5.1 -.1 G5.2 E5.2 B5.2 A5.2 G5.2 F#5.2 "
        "E5.2 -.2 B4.2 -.2 D5.2 E5.2 -.4 "
        "C5.2 E5.2 G5.2 C6.2 B5.2 G5.2 E5.2 G5.2 "
        "F#5.4 A5.4 D6.4 C6.2 A5.2 "
        "B5.2 B5.1 -.1 A5.2 G5.2 A5.2 G5.2 F#5.2 E5.2 "
        "G5.4 F#5.2 E5.2 D5.4 E5.4 "
        "E5.2 G5.2 C6.4 B5.2 A5.2 G5.4 "
        "F#5.4 D#5.4 B4.4 D#5.4 ")
FACT_CH = ["Em", "Em", "C", "D", "Em", "Em", "C", "B"]


def factory():
    s = Song(140, 16)
    s.melody(FACT + FACT, inst_lead, duty=0.25, vol=0.21)
    s.chords_bass(FACT_CH * 2, "drive", octave=2)
    s.chords_arp(FACT_CH * 2, inst_arp, octave=4, pattern=(0, 1, 2, 3, 2, 1), rate=1, vol=0.05, duty=0.125)
    s.drums_multi([[KICK4], ["....s.......s..."] * 3 + ["....s.......s.ss"], ["hhohhhohhhohhhoh"]])
    write_wav("music/factory.wav", s.mix({"arp": 1.0}, echo={"lead": (3, 0.15)}), loop=True)


# ------------------------------------------------------------------ ice
ICE = ("B5.4 G5.4 E5.4 G5.4 "
       "C6.4 G5.4 E5.4 G5.4 "
       "D6.6 B5.2 G5.8 "
       "A5.4 F#5.4 D5.4 F#5.4 "
       "E6.4 D6.4 B5.4 G5.4 "
       "C6.4 B5.4 G5.4 E5.4 "
       "A5.4 C6.4 E6.4 D6.2 C6.2 "
       "B5.8 D#5.8 ")
ICE_CH = ["Em", "C", "G", "D", "Em", "C", "Am", "B"]


def ice():
    s = Song(108, 16)
    s.melody(ICE + ICE, inst_bell, vol=0.3)
    s.pads(ICE_CH * 2, octave=4, vol=0.06)
    s.chords_arp(ICE_CH * 2, inst_pluck, octave=5, pattern=(0, 1, 2, 3, 2, 1, 2, 1), rate=2, vol=0.08)
    s.chords_bass(ICE_CH * 2, "long", octave=2)
    s.drums_multi([["k.........k....."], ["........r......."], ["h...h.h.h...h.h."]], vol=0.8)
    write_wav("music/ice.wav", s.mix(echo={"lead": (3, 0.4), "arp": (3, 0.3)}), loop=True)


# ------------------------------------------------------------------ ultra dimension
ULTRA = ("A5.3 C6.3 E6.2 D6.2 C6.2 B5.2 A5.2 "
         "F5.3 A5.3 C6.2 D6.2 C6.2 A5.2 F5.2 "
         "G5.3 C6.3 E6.2 G6.4 E6.4 "
         "D6.3 B5.3 G5.2 A5.2 B5.2 D6.4 "
         "E6.4 D6.2 C6.2 D6.4 E6.4 "
         "F6.4 E6.2 D6.2 C6.4 A5.4 "
         "B5.4 D6.4 G6.4 F6.2 D6.2 "
         "E6.4 B5.4 G#5.4 B5.4 ")
ULTRA_CH = ["Am", "F", "C", "G", "Am", "F", "G", "E"]


def ultra():
    s = Song(156, 16)
    s.melody(ULTRA + ULTRA, inst_saw, vol=0.2)
    s.chords_arp(ULTRA_CH * 2, inst_arp, octave=4, pattern=(0, 1, 2, 3, 4, 3, 2, 1), rate=1, vol=0.06, duty=0.25)
    s.chords_bass(ULTRA_CH * 2, "root8", octave=2)
    s.pads(ULTRA_CH * 2, octave=3, vol=0.04)
    s.drums_multi([[KICK4], [BACK], ["..h...h...h...h."], ["c..............."] + ["................"] * 7])
    write_wav("music/ultra.wav", s.mix({"arp": 1.0}, echo={"lead": (3, 0.3)}), loop=True)


# ------------------------------------------------------------------ boss
BOSS = ("C5.2 C5.2 Eb5.2 C5.2 G5.2 F5.2 Eb5.2 D5.2 "
        "C5.2 -.2 G4.2 -.2 Bb4.2 B4.2 C5.4 "
        "Ab4.2 C5.2 Eb5.2 Ab5.2 G5.2 Eb5.2 C5.2 Eb5.2 "
        "Bb4.2 D5.2 F5.2 Bb5.2 A5.2 F5.2 D5.2 F5.2 "
        "G5.4 Eb5.4 C6.4 Bb5.2 G5.2 "
        "Ab5.2 G5.2 F5.2 Eb5.2 D5.2 Eb5.2 F5.2 G5.2 "
        "Ab5.4 C6.4 Eb6.4 C6.4 "
        "B5.4 D6.4 G5.4 B4.4 ")
BOSS_CH = ["Cm", "Cm", "Ab", "Bb", "Cm", "Cm", "Ab", "G"]


def boss(final=False):
    semis = 2 if final else 0
    s = Song(176 if final else 168, 16)
    s.melody(transpose_seq(BOSS + BOSS, semis), inst_lead, duty=0.25, vol=0.22)
    if final:
        s.melody(transpose_seq(BOSS + BOSS, semis - 12), inst_saw, bus="harm", vol=0.1)
    ch = BOSS_CH * 2
    if final:
        ch = ["Dm", "Dm", "Bb", "C", "Dm", "Dm", "Bb", "A"] * 2
    s.chords_bass(ch, "drive", octave=2)
    s.chords_arp(ch, inst_arp, octave=4, pattern=(0, 2, 1, 3), rate=1, vol=0.04, duty=0.125)
    s.drums_multi([["k.k...k.k.k...k."], ["....s.......s..."] * 3 + ["....s...s.s.ssss"], [HAT16], ["c..............."] + ["................"] * 3])
    name = "music/final_boss.wav" if final else "music/boss.wav"
    write_wav(name, s.mix({"arp": 1.0, "harm": 1.0}, echo={"lead": (2, 0.15)}), loop=True)


# ------------------------------------------------------------------ jingles
def victory():
    s = Song(150, 3)
    s.melody("C5.2 E5.2 G5.2 C6.4 G5.2 C6.2 E6.10 D6.2 E6.2 F6.2 G6.16 -.4", inst_lead, duty=0.5, vol=0.25)
    s.melody("E4.2 G4.2 C5.2 E5.4 C5.2 E5.2 G5.10 B4.2 C5.2 D5.2 E5.16", inst_lead, bus="harm", duty=0.25, vol=0.14)
    s.melody("C3.8 G2.8 C3.8 G2.4 G2.4 C3.16", inst_bass)
    s.drums_multi([["k...k...k...k...", "k...k...k.k.kkkk", "c..............."], ["....s.......s...", "....s.......s...", "................"]])
    write_wav("music/victory.wav", s.mix(echo={"lead": (3, 0.25)}, loop=False))


def game_over():
    s = Song(84, 3)
    s.melody("C5.4 B4.4 Bb4.4 A4.6 Ab4.2 G4.8 Eb4.4 F4.4 D4.4 C4.16", inst_lead, duty=0.5, vol=0.22)
    s.melody("C3.16 F2.8 G2.8 C2.16", inst_bass)
    s.pads(["Cm", "Fm", "Cm"], octave=3, vol=0.05)
    write_wav("music/game_over.wav", s.mix(echo={"lead": (3, 0.35)}, loop=False))


def build():
    for fn in (menu, credits, overworld, underground, fortress, factory, ice, ultra, victory, game_over):
        fn()
    boss(False)
    boss(True)


if __name__ == "__main__":
    build()
