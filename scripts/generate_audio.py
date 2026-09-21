#!/usr/bin/env python3
"""Rebuild Mem-Mem's original short UI sounds with Python's standard library.

Deterministic 44.1 kHz mono PCM, no samples or external licenses. These are effects,
not a music loop. Use --check to verify checked-in WAVs match the source and do not clip.
"""
import argparse
import io
import math
from pathlib import Path
import random
import struct
import wave

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / 'game/assets/audio'


def shuffle_sound():
    """Dry card/riffle swishes following the longer gather, riffle, and spread."""
    rng = random.Random(804)
    samples = []
    previous = 0.0
    for index in range(round(1.30 * RATE)):
        t = index / RATE
        noise = rng.uniform(-1, 1)
        high = (noise - previous) * .5
        previous = noise
        envelope = 0.0
        for start in [.03, .14, .29, .38, .47, .56, .66, .76, .87, .97, 1.08]:
            age = t - start
            if 0 <= age < .12:
                envelope += math.sin(math.pi * age / .12) ** 2
        samples.append(round(high * envelope * .23 * 32767))
    result = io.BytesIO()
    with wave.open(result, 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack(f'<{len(samples)}h', *samples))
    return result.getvalue()


def render(name, duration, notes, noise=0.0):
    rng = random.Random(name)
    samples = []
    for index in range(round(duration * RATE)):
        t = index / RATE
        value = 0.0
        for start, frequency, decay, volume in notes:
            age = t - start
            if age < 0:
                continue
            attack = min(1.0, age / .004)
            envelope = attack * math.exp(-age / decay)
            # A struck wooden/mallet tone, with quiet upper partials.
            tone = math.sin(math.tau * frequency * age)
            tone += .22 * math.sin(math.tau * frequency * 2.01 * age) * math.exp(-age / .045)
            tone += .07 * math.sin(math.tau * frequency * 3.98 * age) * math.exp(-age / .02)
            value += tone * envelope * volume
        value += rng.uniform(-1, 1) * noise * min(1, t / .003) * math.exp(-t / .018)
        value *= min(1.0, max(0.0, (duration - t) / .025))
        assert abs(value) < .96, (name, 'clipping', value)
        samples.append(round(value * 32767))
    result = io.BytesIO()
    with wave.open(result, 'wb') as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack(f'<{len(samples)}h', *samples))
    rms = math.sqrt(sum((x / 32768) ** 2 for x in samples) / len(samples))
    print(f'{name}: {duration:.2f}s, peak {max(abs(x) for x in samples)/32768:.3f}, RMS {20*math.log10(rms):.1f} dBFS')
    return result.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    cues = {
        'reveal': (.13, [(0, 620, .024, .27)], .06),
        'shuffle': (.20, [(0, 330, .025, .16), (.06, 440, .03, .15)], .05),
        'match': (.43, [(0, 659.25, .07, .27), (.085, 830.61, .075, .26), (.17, 987.77, .085, .25)], 0),
        'mismatch': (.22, [(0, 310, .035, .18), (.065, 277, .035, .14)], .025),
        'complete': (.78, [(0, 523.25, .10, .23), (.09, 659.25, .10, .23), (.18, 783.99, .10, .23), (.30, 1046.5, .14, .24), (.30, 659.25, .14, .09)], 0),
        'fireworks': (.85, [(0, 830.61, .045, .15), (.09, 1244.5, .08, .14), (.18, 1661.2, .10, .13), (.34, 2093, .10, .10)], .12),
        'dance': (.66, [(0, 196, .05, .20), (.12, 392, .055, .19), (.24, 293.66, .05, .20), (.37, 587.33, .07, .18)], .035),
        'wave': (.45, [(0, 783.99, .06, .17), (.09, 1046.5, .065, .17), (.20, 987.77, .07, .13)], 0),
        'next': (.27, [(0, 493.88, .055, .22), (.065, 659.25, .065, .22)], 0),
    }
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (duration, notes, noise) in cues.items():
        data = shuffle_sound() if name == 'shuffle' else render(name, duration, notes, noise)
        dest = OUT / f'{name}.wav'
        if args.check:
            assert dest.read_bytes() == data, f'{dest} needs regeneration'
        else:
            dest.write_bytes(data)


if __name__ == '__main__':
    main()
