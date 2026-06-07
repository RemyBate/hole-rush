#!/usr/bin/env python3
"""Generate lightweight procedural WAV files for Hole Rush (original, no external samples)."""
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 22050
OUT = Path(__file__).resolve().parent.parent / "audio"


def write_wav(path: Path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(1)
        wf.setframerate(SAMPLE_RATE)
        data = bytearray()
        for s in samples:
            data.append(int(max(0, min(255, 128 + s * 127))))
        wf.writeframes(data)


def tone(freq, length, envelope=lambda t: 1.0):
    n = int(SAMPLE_RATE * length)
    return [math.sin(2 * math.pi * freq * i / SAMPLE_RATE) * envelope(i / n) for i in range(n)]


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak * 0.85 for v in out]


def ui_click():
    return mix(tone(880, 0.05, lambda t: 1 - t), tone(1320, 0.04, lambda t: 1 - t))


def coin_collect():
    return mix(
        tone(1046, 0.08, lambda t: 1 - t),
        tone(1318, 0.1, lambda t: max(0, 1 - t * 1.2)),
        tone(1567, 0.12, lambda t: max(0, 1 - t * 1.4)),
    )


def win_jingle():
    seq = []
    for f in [523, 659, 784, 1046]:
        seq.extend(tone(f, 0.14, lambda t: max(0, 1 - t)))
    return seq


def lose_tone():
    return mix(tone(220, 0.35, lambda t: 1 - t * 0.7), tone(165, 0.4, lambda t: max(0, 1 - t)))


def music_loop():
    # Simple cheerful loop ~4s
    melody = [392, 440, 494, 523, 494, 440, 392, 349]
    seq = []
    for f in melody:
        seq.extend(tone(f, 0.25, lambda t: 0.35 + 0.25 * math.sin(t * math.pi)))
    # pad to ~4 seconds
    while len(seq) < SAMPLE_RATE * 4:
        seq.extend(seq[: int(SAMPLE_RATE * 0.5)])
    return seq[: SAMPLE_RATE * 4]


if __name__ == "__main__":
    write_wav(OUT / "ui_click.wav", ui_click())
    write_wav(OUT / "coin_collect.wav", coin_collect())
    write_wav(OUT / "win_jingle.wav", win_jingle())
    write_wav(OUT / "lose_tone.wav", lose_tone())
    write_wav(OUT / "music_loop.wav", music_loop())
    print(f"Wrote audio to {OUT}")
