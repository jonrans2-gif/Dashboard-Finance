"""Small chiptune synthesizer + sequencer (numpy). Generates original music
and sound effects as 16-bit mono WAV files.

Music files carry a RIFF 'smpl' chunk with loop points; Godot's WAV importer
("Loop Mode: Detect From WAV") picks these up so tracks loop seamlessly.
"""
from __future__ import annotations

import os
import struct

import numpy as np
from scipy.signal import lfilter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")

NOTE_BASE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name: str) -> int:
    n = NOTE_BASE[name[0]]
    i = 1
    while i < len(name) and name[i] in "#b":
        n += 1 if name[i] == "#" else -1
        i += 1
    octave = int(name[i:])
    return 12 * (octave + 1) + n


def freq(m: float) -> float:
    return 440.0 * 2 ** ((m - 69) / 12.0)


# ----------------------------------------------------------------- oscillators
def t_axis(n):
    return np.arange(n) / SR


def osc_pulse(f, n, duty=0.5, vib=0.0, vib_rate=5.5, vib_delay=0.12):
    t = t_axis(n)
    if vib:
        depth = np.clip((t - vib_delay) / 0.15, 0, 1) * vib
        f_t = f * (1 + depth * np.sin(2 * np.pi * vib_rate * t))
        phase = np.cumsum(f_t) / SR
    else:
        phase = f * t
    ph = phase % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def osc_tri(f, n):
    ph = (f * t_axis(n)) % 1.0
    tri = 4 * np.abs(ph - 0.5) - 1
    return np.round(tri * 7.5) / 7.5  # 4-bit-ish steps, NES flavour


def osc_saw(f, n, harmonics=10):
    t = t_axis(n)
    out = np.zeros(n)
    for k in range(1, harmonics + 1):
        if f * k > SR / 2.2:
            break
        out += np.sin(2 * np.pi * f * k * t) / k
    return out * 0.6


def osc_sine(f, n):
    return np.sin(2 * np.pi * f * t_axis(n))


def noise(n, seed=0, period=1):
    r = np.random.default_rng(seed)
    x = r.uniform(-1, 1, (n + period - 1) // period)
    return np.repeat(x, period)[:n]


def env_adsr(n, a=0.005, d=0.08, s=0.6, r=0.05, gate=None):
    gate = n if gate is None else min(n, gate)
    e = np.zeros(n)
    ia, id_ = int(a * SR), int(d * SR)
    ir = int(r * SR)
    idx = np.arange(n)
    e = np.where(idx < ia, idx / max(1, ia), 0.0)
    dec = (idx >= ia) & (idx < ia + id_)
    e = np.where(dec, 1 - (1 - s) * (idx - ia) / max(1, id_), e)
    e = np.where((idx >= ia + id_) & (idx < gate), s, e)
    rel = idx >= gate
    e = np.where(rel, s * np.clip(1 - (idx - gate) / max(1, ir), 0, 1), e)
    return e


def env_exp(n, decay):
    return np.exp(-t_axis(n) / decay)


# ----------------------------------------------------------------- instruments
def inst_lead(f, dur, vol=0.22, duty=0.25, vib=0.006):
    n = int((dur + 0.06) * SR)
    w = osc_pulse(f, n, duty, vib=vib)
    return w * env_adsr(n, 0.004, 0.09, 0.55, 0.06, gate=int(dur * SR)) * vol


def inst_pluck(f, dur, vol=0.2, duty=0.125):
    n = int((dur + 0.05) * SR)
    w = osc_pulse(f, n, duty)
    return w * env_exp(n, 0.09 + 0.05 * min(dur, 1)) * vol


def inst_arp(f, dur, vol=0.09, duty=0.5):
    n = int(dur * SR)
    return osc_pulse(f, n, duty) * env_adsr(n, 0.002, 0.04, 0.5, 0.01, gate=int(n * 0.85)) * vol


def inst_bass(f, dur, vol=0.32):
    n = int((dur + 0.02) * SR)
    return osc_tri(f, n) * env_adsr(n, 0.003, 0.05, 0.85, 0.02, gate=int(dur * SR * 0.92)) * vol


def inst_bell(f, dur, vol=0.22):
    n = int((dur + 0.6) * SR)
    w = osc_sine(f, n) + 0.35 * osc_sine(f * 2.0, n) * env_exp(n, 0.2) + 0.15 * osc_sine(f * 3.01, n) * env_exp(n, 0.08)
    return w * env_exp(n, 0.45) * vol


def inst_saw(f, dur, vol=0.16):
    n = int((dur + 0.08) * SR)
    w = osc_saw(f, n) + 0.5 * osc_saw(f * 1.006, n)
    return w * env_adsr(n, 0.01, 0.12, 0.7, 0.08, gate=int(dur * SR)) * vol


def inst_pad(f, dur, vol=0.07):
    n = int((dur + 0.15) * SR)
    w = osc_pulse(f, n, 0.5) * 0.5 + osc_pulse(f * 1.003, n, 0.25) * 0.5
    return w * env_adsr(n, 0.08, 0.2, 0.8, 0.15, gate=int(dur * SR)) * vol


def drum(kind, vol=1.0):
    if kind == "k":
        n = int(0.16 * SR)
        t = t_axis(n)
        f = 50 + 120 * np.exp(-t / 0.03)
        w = np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.06)
        return w * 0.55 * vol
    if kind == "s":
        n = int(0.16 * SR)
        w = noise(n, 3, 2) * env_exp(n, 0.05) * 0.32 + osc_tri(190, n) * env_exp(n, 0.03) * 0.25
        return w * vol
    if kind == "r":  # rim / short snare
        n = int(0.06 * SR)
        return noise(n, 5, 3) * env_exp(n, 0.015) * 0.25 * vol
    if kind == "h":
        n = int(0.04 * SR)
        x = noise(n, 7)
        x = np.diff(np.concatenate([[0], x]))
        return x * env_exp(n, 0.01) * 0.12 * vol
    if kind == "o":
        n = int(0.18 * SR)
        x = noise(n, 9)
        x = np.diff(np.concatenate([[0], x]))
        return x * env_exp(n, 0.06) * 0.09 * vol
    if kind == "c":  # crash
        n = int(0.9 * SR)
        x = noise(n, 11)
        x = np.diff(np.concatenate([[0], x]))
        return x * env_exp(n, 0.3) * 0.12 * vol
    if kind == "t":  # tom
        n = int(0.2 * SR)
        t = t_axis(n)
        f = 90 + 80 * np.exp(-t / 0.05)
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * env_exp(n, 0.08) * 0.4 * vol
    raise ValueError(kind)


# ----------------------------------------------------------------- sequencing
CHORDS = {
    "": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11], "sus4": [0, 5, 7], "dim": [0, 3, 6], "5": [0, 7],
}


def parse_chord(sym):
    root = sym[0]
    rest = sym[1:]
    if rest[:1] in ("#", "b"):
        root += rest[0]
        rest = rest[1:]
    return NOTE_BASE[root[0]] + (1 if "#" in root else -1 if "b" in root else 0), CHORDS[rest]


def parse_seq(s):
    """'C5.2 E5.2 -.4' -> [(midi or None, steps)]"""
    out = []
    for tok in s.split():
        name, d = tok.rsplit(".", 1)
        out.append((None if name == "-" else midi(name), int(d)))
    return out


class Song:
    def __init__(self, bpm, bars, steps_per_bar=16, swing=0.0):
        self.bpm = bpm
        self.step = 60.0 / bpm / 4
        self.bars = bars
        self.spb = steps_per_bar
        self.n = int(round(bars * steps_per_bar * self.step * SR))
        self.tail = int(2.5 * SR)
        self.buses = {}
        self.swing = swing

    def bus(self, name):
        if name not in self.buses:
            self.buses[name] = np.zeros(self.n + self.tail)
        return self.buses[name]

    def t_of(self, step):
        t = step * self.step
        if self.swing and step % 2 == 1:
            t += self.step * self.swing
        return t

    def add(self, busname, start_step, wave):
        b = self.bus(busname)
        i = int(round(self.t_of(start_step) * SR))
        j = min(len(b), i + len(wave))
        if i < len(b):
            b[i:j] += wave[: j - i]

    def melody(self, seq, inst, bus="lead", start=0, transpose=0, **kw):
        pos = start
        for m, d in parse_seq(seq) if isinstance(seq, str) else seq:
            if m is not None:
                self.add(bus, pos, inst(freq(m + transpose), d * self.step, **kw))
            pos += d
        return pos

    def chords_arp(self, chords, inst, octave=4, pattern=(0, 1, 2, 3), rate=1, bus="arp", **kw):
        for bar, sym in enumerate(chords):
            root, iv = parse_chord(sym)
            tones = [root + i for i in iv] + [root + 12]
            base = 12 * (octave + 1)
            for k in range(self.spb // rate):
                deg = pattern[k % len(pattern)]
                m = base + tones[deg % len(tones)] + 12 * (deg // len(tones))
                self.add(bus, bar * self.spb + k * rate, inst(freq(m), rate * self.step, **kw))

    def chords_bass(self, chords, style="root8", octave=2, inst=inst_bass, bus="bass", **kw):
        base = 12 * (octave + 1)
        for bar, sym in enumerate(chords):
            root, iv = parse_chord(sym)
            r = base + root
            fifth = r + 7
            s0 = bar * self.spb
            if style == "root8":
                for k in range(0, 16, 2):
                    self.add(bus, s0 + k, inst(freq(r + (12 if k % 4 == 2 else 0)), 2 * self.step, **kw))
            elif style == "bounce":
                for k, (st, m) in enumerate([(0, r), (4, fifth), (8, r + 12), (12, fifth)]):
                    self.add(bus, s0 + st, inst(freq(m), 3 * self.step, **kw))
            elif style == "walk":
                notes = [r, r + iv[1], fifth, r + iv[1]]
                for k, m in enumerate(notes):
                    self.add(bus, s0 + k * 4, inst(freq(m), 3.5 * self.step, **kw))
            elif style == "ostinato":
                for st, m in [(0, r), (4, r + 12), (8, r + 10), (12, fifth)]:
                    self.add(bus, s0 + st, inst(freq(m), 2 * self.step, **kw))
            elif style == "long":
                self.add(bus, s0, inst(freq(r), 8 * self.step, **kw))
                self.add(bus, s0 + 8, inst(freq(fifth if bar % 2 else r), 8 * self.step, **kw))
            elif style == "drive":
                for k in range(16):
                    self.add(bus, s0 + k, inst(freq(r + (12 if k % 8 in (3, 6) else 0)), 1 * self.step, **kw))

    def pads(self, chords, octave=4, bus="pad", inst=inst_pad, **kw):
        base = 12 * (octave + 1)
        for bar, sym in enumerate(chords):
            root, iv = parse_chord(sym)
            for i in iv[:3]:
                self.add(bus, bar * self.spb, inst(freq(base + root + i), self.spb * self.step, **kw))

    def drums(self, patterns, bars=None, bus="drums", vol=1.0):
        """patterns: list of 16-char strings, cycled per bar ('.' = none)."""
        bars = bars or self.bars
        for bar in range(bars):
            pat = patterns[bar % len(patterns)]
            for k, ch in enumerate(pat):
                if ch != ".":
                    for c in ch.split("+") if "+" in ch else [ch]:
                        self.add(bus, bar * self.spb + k, drum(c, vol))

    def drums_multi(self, rows, bars=None, bus="drums", vol=1.0):
        for row in rows:
            self.drums(row, bars, bus, vol)

    def mix(self, levels=None, echo=None, lowpass=0.6, loop=True):
        levels = levels or {}
        out = np.zeros(self.n + self.tail)
        for name, b in self.buses.items():
            x = b * levels.get(name, 1.0)
            if echo and name in echo:
                delay_steps, fb = echo[name]
                d = int(delay_steps * self.step * SR)
                y = x.copy()
                g = fb
                for k in range(1, 4):
                    y[d * k:] += x[: len(x) - d * k] * g
                    g *= fb
                x = y
            out += x
        # gentle one-pole low-pass to soften raw square edges
        a = lowpass
        out = lfilter([a], [1, -(1 - a)], out)
        if loop:
            body = out[: self.n].copy()
            tail = out[self.n:]
            body[: len(tail)] += tail[: len(body)]
            out = body
        peak = np.max(np.abs(out)) or 1
        out = np.tanh(out / peak * 1.25) / np.tanh(1.25) * 0.89
        return out


def write_wav(rel, samples, loop=False):
    path = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    pcm = np.clip(samples, -1, 1)
    pcm = (pcm * 32767).astype("<i2").tobytes()
    chunks = [b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16)]
    chunks.append(b"data" + struct.pack("<I", len(pcm)) + pcm + (b"\x00" if len(pcm) % 2 else b""))
    if loop:
        n = len(samples)
        smpl = struct.pack("<9I", 0, 0, int(1e9 / SR), 60, 0, 0, 0, 1, 0)
        smpl += struct.pack("<6I", 0, 0, 0, n - 1, 0, 0)
        chunks.append(b"smpl" + struct.pack("<I", len(smpl)) + smpl)
    body = b"WAVE" + b"".join(chunks)
    with open(path, "wb") as fh:
        fh.write(b"RIFF" + struct.pack("<I", len(body)) + body)
