"""Renders the game's synthesized sounds and music to WAV files, to listen without Godot (D78).

    python3 tools/audio/preview_audio.py [out_dir]

Reads data/audio/sfx.json and data/audio/music.json and writes out_dir (default build/audio_preview)/
sfx_<id>.wav and music_<track>.wav. Same algorithm as core/audio/sound_synth.gd (keep them in step).
Prints each sound's length and how loud it is before normalisation.
"""
import json
import math
import os
import re
import struct
import sys
import wave

RATE = 22050
SFX_PEAK = 0.85
MUSIC_PEAK = 0.8
NOTE_RE = re.compile(r"^([A-G])([#b]?)(-?\d)$")
PITCH = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")


def osc(wave_kind, phase, duty, noise):
    p = phase - math.floor(phase)
    if wave_kind == "square":
        return 1.0 if p < duty else -1.0
    if wave_kind == "triangle":
        return 4.0 * abs(p - 0.5) - 1.0
    if wave_kind == "saw":
        return 2.0 * p - 1.0
    if wave_kind == "sine":
        return math.sin(2.0 * math.pi * phase)
    # noise: a new random value each cycle (the pitch sets how fast it changes)
    cycle = math.floor(phase)
    if cycle != noise[2]:
        noise[0] = (noise[0] * 1103515245 + 12345) & 0x7FFFFFFF
        noise[1] = noise[0] / 2147483647.0 * 2.0 - 1.0
        noise[2] = cycle
    return noise[1]


def pitch_at(layer, t, u):
    f0 = float(layer["freq"])
    f1 = float(layer.get("freq_end", f0))
    f = f0 * (f1 / f0) ** u
    arp = layer.get("arp", [])
    if arp:
        f *= 2.0 ** (arp[int(t * float(layer.get("arp_rate", 0.0))) % len(arp)] / 12.0)
    vibrato = layer.get("vibrato")
    if vibrato:
        f *= 2.0 ** (float(vibrato[1]) * math.sin(2.0 * math.pi * float(vibrato[0]) * t) / 12.0)
    return f


def render_layer(buf, layer, offset=0, scale=1.0, wrap=0):
    """Adds one sound layer to buf from sample `offset`; `wrap` > 0 wraps indices (looping music)."""
    dur = float(layer["dur"])
    n = int(dur * RATE)
    start = offset + int(float(layer.get("start", 0.0)) * RATE)
    attack = float(layer.get("attack", 0.003))
    curve = float(layer.get("curve", 2.0))
    vol = float(layer.get("vol", 0.5)) * scale
    duty = float(layer.get("duty", 0.5))
    lowpass = float(layer.get("lowpass", 0.0))
    alpha = 1.0 - math.exp(-2.0 * math.pi * lowpass / RATE) if lowpass > 0.0 else 0.0
    noise = [int(layer.get("seed", 1)), 0.0, -1]
    phase = 0.0
    y = 0.0
    for i in range(n):
        t = i / RATE
        phase += pitch_at(layer, t, i / n) / RATE
        x = osc(layer["wave"], phase, duty, noise)
        if t < attack:
            env = t / attack
        else:
            env = max(0.0, 1.0 - (t - attack) / max(dur - attack, 1e-6)) ** curve
        v = x * env * vol
        if alpha > 0.0:
            y += alpha * (v - y)
            v = y
        index = start + i
        if wrap > 0:
            index %= wrap
        if 0 <= index < len(buf):
            buf[index] += v


def render_sfx(recipe):
    length = max(float(l.get("start", 0.0)) + float(l["dur"]) for l in recipe["layers"])
    buf = [0.0] * (int(length * RATE) + 1)
    for layer in recipe["layers"]:
        render_layer(buf, layer)
    return buf


def midi_of(token):
    m = NOTE_RE.match(token)
    if not m:
        raise ValueError("bad note " + token)
    letter, accidental, octave = m.groups()
    shift = 1 if accidental == "#" else -1 if accidental == "b" else 0
    return (int(octave) + 1) * 12 + PITCH[letter] + shift


def note_env(ch, t, dur):
    attack = float(ch.get("attack", 0.01))
    decay = float(ch.get("decay", 0.1))
    sustain = float(ch.get("sustain", 0.7))
    release = float(ch.get("release", 0.1))

    def held(time):
        if time < attack:
            return time / attack
        return sustain + (1.0 - sustain) * max(0.0, 1.0 - (time - attack) / decay)

    if t < dur:
        return held(t)
    return held(dur) * max(0.0, 1.0 - (t - dur) / release)


def render_note(buf, ch, freq, start, dur):
    release = float(ch.get("release", 0.1))
    n = int((dur + release) * RATE)
    vol = float(ch.get("vol", 0.3))
    duty = float(ch.get("duty", 0.5))
    lowpass = float(ch.get("lowpass", 0.0))
    alpha = 1.0 - math.exp(-2.0 * math.pi * lowpass / RATE) if lowpass > 0.0 else 0.0
    layer = {"freq": freq, "vibrato": ch.get("vibrato")}
    noise = [1, 0.0, -1]
    phase = 0.0
    y = 0.0
    for i in range(n):
        t = i / RATE
        phase += pitch_at(layer, t, 0.0) / RATE
        v = osc(ch["wave"], phase, duty, noise) * note_env(ch, t, dur) * vol
        if alpha > 0.0:
            y += alpha * (v - y)
            v = y
        buf[(start + i) % len(buf)] += v


def render_track(track):
    step = 60.0 / float(track["bpm"]) / 4.0
    bars = len(track["channels"][0]["bars"])
    total = round(bars * 16 * step * RATE)
    buf = [0.0] * total
    for ch in track["channels"]:
        tokens = " ".join(ch["bars"]).split()
        for i, token in enumerate(tokens):
            if token in ("-", "."):
                continue
            start = round(i * step * RATE)
            if ch.get("drums"):
                render_layer(buf, track["kit"][token], start, float(ch.get("vol", 0.3)), total)
                continue
            hold = 1
            while i + hold < len(tokens) and tokens[i + hold] == "-":
                hold += 1
            freq = 440.0 * 2.0 ** ((midi_of(token) - 69) / 12.0)
            render_note(buf, ch, freq, start, hold * step)
    return buf


def save(buf, path, peak_target, center=False):
    if center:
        # Music loops: remove the DC offset (square waves with a narrow duty).
        mean = sum(buf) / len(buf)
        buf = [v - mean for v in buf]
    peak = max(abs(v) for v in buf) or 1.0
    scale = peak_target / peak
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v * scale)) * 32767)) for v in buf))
    return peak


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "build", "audio_preview")
    os.makedirs(out, exist_ok=True)
    sfx = json.load(open(os.path.join(ROOT, "data", "audio", "sfx.json")))
    for sound_id, recipe in sfx.items():
        if sound_id.startswith("_"):
            continue
        buf = render_sfx(recipe)
        peak = save(buf, os.path.join(out, "sfx_%s.wav" % sound_id), SFX_PEAK)
        print("sfx %-20s %.2fs  raw peak %.2f  %+d dB" % (sound_id, len(buf) / RATE, peak, recipe["volume_db"]))
    music = json.load(open(os.path.join(ROOT, "data", "audio", "music.json")))
    for track_id, track in music.items():
        if track_id.startswith("_"):
            continue
        buf = render_track(track)
        peak = save(buf, os.path.join(out, "music_%s.wav" % track_id), MUSIC_PEAK, True)
        print("music %-8s %.1fs  raw peak %.2f" % (track_id, len(buf) / RATE, peak))


if __name__ == "__main__":
    main()
