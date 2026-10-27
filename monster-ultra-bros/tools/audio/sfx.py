"""Sound effects."""
import numpy as np
from scipy.signal import lfilter

from synth import SR, drum, env_exp, freq, midi, noise, osc_pulse, osc_sine, osc_tri, t_axis, write_wav


def sweep(f0, f1, dur, duty=0.5, curve=1.0, wave="pulse"):
    n = int(dur * SR)
    t = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * t
    ph = np.cumsum(f) / SR
    if wave == "pulse":
        return np.where((ph % 1) < duty, 1.0, -1.0)
    if wave == "tri":
        p = ph % 1
        return 4 * np.abs(p - 0.5) - 1
    return np.sin(2 * np.pi * ph)


def notes(seq, step, inst="pulse", duty=0.5, decay=0.08):
    out = []
    for name in seq:
        n = int(step * SR)
        if name == "-":
            out.append(np.zeros(n)); continue
        f = freq(midi(name))
        w = osc_pulse(f, n, duty) if inst == "pulse" else osc_tri(f, n) if inst == "tri" else osc_sine(f, n)
        out.append(w * env_exp(n, decay))
    return np.concatenate(out)


def fade(x, ms=8):
    n = int(ms / 1000 * SR)
    if len(x) > n:
        x[-n:] *= np.linspace(1, 0, n)
    return x


def lp(x, a=0.5):
    return lfilter([a], [1, -(1 - a)], x)


def norm(x, peak=0.8):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


def save(name, x, peak=0.8):
    write_wav(f"sfx/{name}.wav", norm(fade(lp(x)), peak))


def build():
    save("jump", sweep(300, 760, 0.14, 0.25, 0.6) * env_exp(int(0.14 * SR), 0.09))
    save("jump2", sweep(450, 1100, 0.14, 0.125, 0.6) * env_exp(int(0.14 * SR), 0.09))
    n = int(0.08 * SR)
    save("land", noise(n, 2, 6) * env_exp(n, 0.02) + sweep(140, 60, 0.08, wave="sine") * env_exp(n, 0.03), 0.5)
    save("token", np.concatenate([notes(["B5"], 0.05, duty=0.25, decay=0.2), notes(["E6"], 0.22, duty=0.25, decay=0.12)]), 0.6)
    save("shard", np.concatenate([notes(["E6", "G6", "B6", "E7"], 0.05, duty=0.25, decay=0.1), notes(["B6"], 0.3, "sine", decay=0.15)]))
    save("oneup", notes(["E5", "G5", "E6", "C6", "D6", "G6"], 0.08, duty=0.25, decay=0.12))
    n = int(0.12 * SR)
    save("stomp", sweep(600, 120, 0.12, 0.5, 0.5) * env_exp(n, 0.05) + noise(n, 4, 4) * env_exp(n, 0.02) * 0.4)
    n = int(0.25 * SR)
    save("kick", sweep(900, 200, 0.25, 0.25, 0.4) * env_exp(n, 0.1))
    n = int(0.35 * SR)
    save("hurt", (sweep(500, 180, 0.35, 0.5, 1.0) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 30 * t_axis(n))))) * env_exp(n, 0.15))
    save("death", np.concatenate([notes(["B4", "F5", "-", "F5", "F5", "E5", "D5", "C5"], 0.1, duty=0.5, decay=0.12),
                                  sweep(300, 60, 0.4, 0.5) * env_exp(int(0.4 * SR), 0.2)]))
    n = int(0.45 * SR)
    save("powerup_appear", sweep(200, 900, 0.45, 0.5, 1.0) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 24 * t_axis(n)))) * env_exp(n, 0.4))
    save("powerup", notes(["C5", "E5", "G5", "C6", "E6", "G6", "C7"], 0.045, duty=0.25, decay=0.1))
    n = int(0.4 * SR)
    save("shield_break", noise(n, 8, 1) * env_exp(n, 0.08) * 0.6 + sweep(1400, 300, 0.4, 0.5) * env_exp(n, 0.1) * 0.5)
    n = int(0.1 * SR)
    save("bump", sweep(220, 110, 0.1, 0.5) * env_exp(n, 0.04), 0.7)
    n = int(0.35 * SR)
    save("brick", noise(n, 12, 3) * env_exp(n, 0.07) + sweep(300, 80, 0.35, wave="tri") * env_exp(n, 0.06))
    save("door", np.concatenate([sweep(120, 180, 0.15, 0.5) * 0.5, sweep(180, 90, 0.2, 0.5) * 0.5]) * 0.7)
    save("secret", notes(["G5", "F#5", "D#5", "A4", "G#4", "E5", "G#5", "C6"], 0.07, duty=0.25, decay=0.15))
    save("checkpoint", notes(["C5", "G5", "C6", "-", "G5", "C6"], 0.06, duty=0.25, decay=0.1))
    n = int(0.28 * SR)
    save("dash", noise(n, 14, 1) * env_exp(n, 0.1) * 0.6 + sweep(200, 900, 0.28, 0.25, 0.4) * env_exp(n, 0.12) * 0.6)
    n = int(0.3 * SR)
    save("spring", sweep(200, 1200, 0.3, 0.5, 0.3) * (0.6 + 0.4 * np.sin(2 * np.pi * 40 * t_axis(n))) * env_exp(n, 0.2))
    n = int(0.3 * SR)
    save("zap", noise(n, 15, 2) * (np.sign(np.sin(2 * np.pi * 60 * t_axis(n))) * 0.5 + 0.5) * env_exp(n, 0.12), 0.6)
    n = int(0.6 * SR)
    save("charge", sweep(100, 1200, 0.6, 0.5, 2.0) * np.linspace(0.2, 1, n), 0.5)
    n = int(0.7 * SR)
    save("explosion", noise(n, 16, 6) * env_exp(n, 0.2) + sweep(120, 30, 0.7, wave="sine") * env_exp(n, 0.25))
    n = int(0.3 * SR)
    save("boss_hit", np.concatenate([sweep(800, 200, 0.12, 0.5) * env_exp(int(0.12 * SR), 0.06),
                                     noise(n, 17, 2) * env_exp(n, 0.08)]))
    n = int(0.8 * SR)
    save("roar", (sweep(160, 90, 0.8, 0.5) * 0.6 + noise(n, 18, 8) * 0.4) * np.minimum(1, t_axis(n) * 10) * env_exp(n, 0.5))
    n = int(0.15 * SR)
    save("shoot", sweep(1200, 300, 0.15, 0.25, 0.5) * env_exp(n, 0.06), 0.55)
    n = int(0.35 * SR)
    save("slam", np.concatenate([drum("k"), np.zeros(n)])[:n] + noise(n, 19, 10) * env_exp(n, 0.1))
    save("pause", notes(["E6", "C6", "E6", "C6"], 0.05, duty=0.5, decay=0.06), 0.5)
    save("ui_move", notes(["A5"], 0.04, duty=0.25, decay=0.03), 0.4)
    save("ui_select", notes(["E5", "B5"], 0.05, duty=0.25, decay=0.08), 0.5)
    save("ui_back", notes(["B5", "E5"], 0.05, duty=0.25, decay=0.08), 0.45)
    n = int(0.4 * SR)
    save("splash", noise(n, 20, 2) * env_exp(n, 0.12) * lfilter([0.2], [1, -0.8], np.ones(n)), 0.6)
    save("tick", notes(["C7"], 0.025, duty=0.5, decay=0.01), 0.35)
    save("hurry", notes(["C6", "-", "C6", "-", "C6"], 0.07, duty=0.5, decay=0.06), 0.5)
    save("break_barrier", np.concatenate([notes(["C6", "G6"], 0.04, duty=0.25), noise(int(0.3 * SR), 21, 1) * env_exp(int(0.3 * SR), 0.06)]))
    save("magnet", notes(["C5", "D5", "E5", "F5"], 0.04, "sine", decay=0.1), 0.5)
    save("grow", np.concatenate([notes([n_, m_], 0.05, duty=0.5) for n_, m_ in [("C4", "G4"), ("D4", "A4"), ("E4", "B4"), ("G4", "D5")]]), 0.6)
    save("shrink", np.concatenate([notes([n_, m_], 0.05, duty=0.5) for n_, m_ in [("G4", "D5"), ("E4", "B4"), ("D4", "A4"), ("C4", "G4")]]), 0.6)


if __name__ == "__main__":
    build()
