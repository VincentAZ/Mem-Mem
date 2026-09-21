#!/usr/bin/env python3
"""Read alpha silhouettes and record atlas regions; never alter generated images.

Pillow is needed only for authoring/validation, not by the game at runtime.
"""
from pathlib import Path
from collections import deque
import argparse
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PACKS = ['cast-expansion', 'woodland', 'snacks', 'mythical']


def regions(path):
    image = Image.open(path)
    assert image.mode == 'RGBA', f'{path}: real alpha required'
    width, height = image.size
    pixels = bytearray(1 if a > 16 else 0 for a in image.getchannel('A').tobytes())
    found = []
    for start in range(len(pixels)):
        if not pixels[start]:
            continue
        pixels[start] = 0
        pending = deque([start])
        count = 0
        left = right = start % width
        top = bottom = start // width
        while pending:
            p = pending.popleft()
            x, y = p % width, p // width
            count += 1
            left, right, top, bottom = min(left,x), max(right,x), min(top,y), max(bottom,y)
            for adjacent in ([p-1] if x else []) + ([p+1] if x+1 < width else []) + ([p-width] if y else []) + ([p+width] if y+1 < height else []):
                if pixels[adjacent]:
                    pixels[adjacent] = 0
                    pending.append(adjacent)
        if count > 5000:
            found.append((left, top, right+1, bottom+1))
    assert len(found) == 8, f'{path}: expected 8 distinct silhouettes, got {found}'
    found.sort(key=lambda b: ((b[1]+b[3])//height, (b[0]+b[2])/2))
    return [(max(0,l-3), max(0,t-3), min(width,r+3)-max(0,l-3), min(height,b+3)-max(0,t-3)) for l,t,r,b in found]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    result = 'class_name ExpandedAtlas\nextends RefCounted\n## Alpha silhouette bounds measured from unchanged generated PNGs.\n'
    for pose, suffix in [('NORMAL',''), ('CHEER','-cheer')]:
        result += f'const {pose}: Array[Rect2] = [\n'
        for pack in PACKS:
            boxes = regions(ROOT / 'game/assets/characters' / f'{pack}{suffix}.png')
            print(pack+suffix, boxes)
            result += ''.join('\tRect2(%d, %d, %d, %d),\n' % box for box in boxes)
        result += ']\n'
    dest = ROOT / 'game/presentation/expanded_atlas.gd'
    if args.check:
        assert dest.read_text() == result, 'Atlas bounds are stale'
    else:
        dest.write_text(result)

if __name__ == '__main__':
    main()
