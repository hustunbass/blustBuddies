"""Generates original placeholder sound effects (public domain / CC0).

Run: python3 tool/gen_audio.py
Replace the files in assets/audio with final audio before release.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')


def write(name, samples):
    with wave.open(os.path.join(OUT, name), 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))


def tone(freq, dur, vol=0.5, slide=0.0, decay=3.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        f = freq + slide * t
        phase += 2 * math.pi * f / RATE
        out.append(math.sin(phase) * vol * math.exp(-decay * t))
    return out


def noise(dur, vol=0.6, decay=4.0):
    n = int(RATE * dur)
    rng = random.Random(1)
    return [(rng.random() * 2 - 1) * vol * math.exp(-decay * i / n) for i in range(n)]


def seq(*parts):
    out = []
    for p in parts:
        out += p
    return out


os.makedirs(OUT, exist_ok=True)
write('place.wav', tone(300, 0.12, 0.5, slide=-120))
write('explosion.wav', [a + b for a, b in zip(noise(0.6, 0.7, 5), tone(90, 0.6, 0.5, slide=-50, decay=4))])
write('pickup.wav', seq(tone(660, 0.07, 0.4, decay=1), tone(990, 0.12, 0.4)))
write('hit.wav', tone(220, 0.35, 0.5, slide=-160, decay=2))
write('win.wav', seq(tone(523, 0.12, 0.4, decay=1), tone(659, 0.12, 0.4, decay=1), tone(784, 0.25, 0.4)))
write('lose.wav', seq(tone(392, 0.18, 0.4, decay=1), tone(330, 0.18, 0.4, decay=1), tone(262, 0.35, 0.4)))
notes = [262, 330, 392, 330, 294, 349, 440, 349]
write('music.wav', seq(*[tone(n, 0.25, 0.18, decay=1.5) for n in notes]))
