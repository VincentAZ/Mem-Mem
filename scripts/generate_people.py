#!/usr/bin/env python3
"""Original vector people, shared by portrait cards and animated figures.

Run after editing this source; generated SVGs are checked in. Each accessory pair
uses the exact same face/outfit. No network, model, or third-party artwork needed.
"""
import argparse
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / 'game/assets/people'
SKIN = ['#d49b76', '#996347', '#efc6a4', '#bf865f', '#795341', '#dfa87c']
HAIR = ['#46382f', '#302e2c', '#b49059', '#835341', '#393236', '#c4c0b3']
SHIRT = ['#b76e53', '#738979', '#647f96', '#a07383', '#ba914c', '#748c8c']
BACK = ['#f0e6d7', '#e6eade', '#e2eaf0', '#efe3e8', '#eee7d3', '#e3ece7']


def path(d, fill, stroke='none', width=1):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'


def ellipse(x, y, rx, ry, fill, stroke='none', width=1):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'


def head(family, pearl):
    skin, hair = SKIN[family], HAIR[family]
    # Six silhouettes; all fit the same head frame, including hair and earrings.
    backs = [
        'M-35 27 L-36-14 Q-36-46-5-45 Q32-46 35-12 L35 27 Q19 38-35 27Z',
        'M-31 2 Q-43-29-18-37 Q-29-57-2-54 Q23-57 18-35 Q42-20 30 3Z',
        'M-33 25 Q-40 9-32-10 Q-43-32-17-38 Q8-57 30-32 Q39-17 32-1 Q46 18 27 30Z',
        'M-32 28 Q-40 8-33-20 Q-31-48 1-46 Q37-42 33-8 Q43 16 33 31Z',
        'M-32 5 Q-42-1-35-13 Q-44-23-31-31 Q-33-45-19-43 Q-10-55 1-46 Q17-53 24-41 Q42-41 35-27 Q45-17 34-8 Q39 4 29 10Z',
        'M-33 26 Q-40 0-31-26 Q-22-49 6-46 Q40-41 34-4 L32 30 Q2 36-33 26Z',
    ]
    faces = [
        'M-26-19 Q-30 3-21 19 Q-13 32 0 32 Q17 31 24 16 Q30-3 25-22Z',
        'M-25-22 Q-30-3-22 18 Q-15 32 0 32 Q20 28 25 10 L25-24Z',
        'M-25-24 Q-28-4-22 15 Q-16 31-1 33 Q17 31 24 13 Q30-7 24-24Z',
        'M-26-21 Q-30-2-19 20 Q-9 33 2 30 Q23 26 26 5 L24-24Z',
        'M-27-22 Q-32 4-23 19 Q-17 32 0 32 Q20 33 26 15 Q32-2 25-23Z',
        'M-25-22 Q-30-5-22 15 Q-15 29-2 33 Q13 33 22 18 Q30 0 26-21Z',
    ]
    fronts = [
        'M-33-8 Q-36-41-9-43 Q28-49 34-15 L28-4 Q21-13 18-28 Q-4-19-22-23 L-27 7Z',
        'M-29-5 Q-38-36-7-39 Q27-42 32-11 L25-7 Q18-18 17-29 Q0-18-22-23 L-25 3Z',
        'M-32-2 Q-41-28-22-35 Q-4-48 15-35 Q39-33 32-10 L25-3 Q17-16 17-28 Q5-14-13-22 Q-13-6-26-8Z',
        'M-33 5 Q-37-29-16-41 Q19-56 33-23 L29-7 Q19-24 5-29 Q-6-7-27-7 L-27 21Z',
        'M-30-5 Q-36-20-28-30 Q-23-43-9-37 Q4-49 16-36 Q33-37 33-19 L27-4 L22-17 Q12-24 6-18 Q-8-24-20-16 L-24 3Z',
        'M-32 11 Q-41-30-14-41 Q17-56 33-24 L30-5 Q17-13 10-30 Q-5-10-24-13 L-27 23Z',
    ]
    s = path(backs[family], hair)
    if family == 1:
        for x, y in [(-13, -43), (0, -48), (12, -41), (-23, -25), (22, -24)]:
            s += path(f'M{x-4} {y+2} Q{x-7} {y-6} {x+3} {y-5}', 'none', '#55534b', 1.5)
    if family == 4:
        for x, y in [(-24, -31), (-10, -39), (7, -38), (23, -29), (-30, -13), (30, -12)]:
            s += path(f'M{x-4} {y+3} Q{x-8} {y-5} {x} {y-5} Q{x+5} {y-3} {x+1} {y+1}', 'none', '#5c5149', 1.6)
    s += ellipse(-27, 6, 6, 10, skin) + ellipse(28, 7, 6, 10, skin)
    s += path(faces[family], skin)
    s += '<g opacity=".15">' + path('M22-15 Q18 6 20 17 Q12 30-2 32 Q22 36 27 13 L27-15Z', '#553026') + '</g>'
    s += '<g opacity=".18">' + ellipse(-17, 12, 7, 3.8, '#cc675d') + ellipse(17, 12, 6.5, 3.8, '#cc675d') + '</g>'
    s += path('M-31 4 Q-25 0-26 11 M30 4 Q26 3 28 12', 'none', '#765044', .9)
    s += path(fronts[family], hair)
    # Restrained strands, not noise at the smallest card size.
    s += '<g opacity=".22">' + path([
        'M-28-20 Q-27-37-11-36 M22-31 Q31-16 29 8',
        'M-24-26 Q-13-35 0-32 M7-34 Q22-35 26-21',
        'M-29-24 Q-18-33-9-28 M5-36 Q24-33 25-21',
        'M-26-23 Q-15-37 0-38 M27-18 Q38 9 29 22',
        'M-23-21 Q-27-28-19-30 M4-32 Q12-39 19-29',
        'M-27-24 Q-15-36-3-36 M18-30 Q30-11 27 17',
    ][family], 'none', '#fff4dd', 2) + '</g>'
    brow = '#775b43' if family in (2, 5) else hair
    s += path('M-20-7 Q-14-11-8-7 M8-7 Q14-11 20-6', 'none', brow, 2)
    s += path('M-20 0 Q-14-5-8 0 Q-14 4-20 0Z M8 0 Q14-5 20 0 Q14 4 8 0Z', '#fff5e4')
    s += ellipse(-13.5, -.2, 2.6, 3, '#403b32') + ellipse(14, -.2, 2.6, 3, '#403b32')
    s += ellipse(-12.8, -1, .75, .8, '#fffdf2') + ellipse(14.7, -1, .75, .8, '#fffdf2')
    s += path('M-20 0 Q-14-5-8 0 M8 0 Q14-5 20 0', 'none', brow, 1.3)
    s += path('M1 1 L-2 11 Q0 14 4 11', 'none', '#9d6952' if family != 4 else '#bd896a', 1.25)
    if family in (1, 4):
        s += path('M-9 19 Q0 22 10 17 Q5 29-3 26 Q-7 24-9 19Z', '#733f38')
        s += path('M-7 20 Q1 22 8 19 L5 23 Q-1 25-5 22Z', '#fff7e7')
    else:
        s += path('M-8 19 Q0 27 10 18', 'none', '#855044' if family != 3 else '#7d453d', 1.9)
        s += path('M-3 27 Q1 28 4 26', 'none', '#bb8069', .8)
    if family == 3:
        s += '<g opacity=".6">' + ''.join(ellipse(x, y, .8, .8, '#875038') for x, y in [(-17, 8), (-12, 9), (-8, 7), (10, 8), (15, 10), (19, 8)]) + '</g>'
    if family == 5:
        s += path('M-23 8 L-20 9 M21 8 L24 6 M-15 24 L-12 27 M13 24 L10 28', 'none', '#ad755a', .85)
    if family in (2, 5):
        frame = '#705941' if family == 2 else '#526b67'
        s += ellipse(-14, 1, 11, 10, 'none', frame, 1.9) + ellipse(14, 1, 11, 10, 'none', frame, 1.9)
        s += path('M-3 0 Q0-3 3 0 M-25 0 L-29-2 M25 0 L29-2', 'none', frame, 1.9)
    # Accessory geometry is the ONLY difference between a family's two identities.
    if pearl:
        s += ellipse(31, 19, 6, 6, '#f9f0d9', '#b29665', 1.2)
        s += ellipse(29.5, 17.4, 2, 1.6, '#ffffff')
    else:
        s += ellipse(31, 22, 6.5, 8, 'none', '#78521e', 3.4)
        s += ellipse(31, 21.7, 6.5, 8, 'none', '#e6b55e', 2.1)
    return s


def portrait(family, pearl):
    skin, shirt = SKIN[family], SHIRT[family]
    s = ellipse(83, 79, 65, 65, BACK[family])
    s += path('M29 50 Q37 30 59 22', 'none', '#fffcf3', 2.5)
    s += path('M20 166 Q24 134 42 128 L67 117 L99 117 L125 128 Q143 135 146 166Z', shirt)
    s += path('M71 98 L95 98 L96 121 Q83 138 70 121Z', skin)
    s += '<g opacity=".17">' + path('M71 102 L95 102 L95 114 Q81 121 71 110Z', '#5d392e') + '</g>'
    outfits = [
        path('M65 119 L86 139 L105 121 L96 147 L82 155 L61 126Z', '#c88565') + path('M65 120 L86 140 L105 121 M86 140 L75 166', 'none', '#e3b298', 1.7),
        path('M63 120 L76 139 L83 163 L55 133Z M101 120 L90 137 L83 163 L112 133Z', '#92a28d') + path('M74 125 L83 150 L94 124Z', '#f5ead6') + ellipse(108, 142, 2, 2, '#e6bf76'),
        path('M65 119 L83 129 L75 140 L58 126Z M101 119 L83 129 L92 140 L109 126Z', '#90a8b4') + path('M83 130 L83 166', 'none', '#b2c1c3', 1.1) + ellipse(88, 146, 1.5, 1.5, '#efeddd') + ellipse(88, 158, 1.5, 1.5, '#efeddd'),
        path('M66 122 Q83 149 102 122', 'none', '#d5afb4', 2) + path('M68 128 Q83 151 100 128', 'none', '#e4ba79', 1.2) + ellipse(83, 143, 2.8, 3.5, '#e4ba79'),
        path('M66 122 Q83 148 102 122', 'none', '#e0b567', 5) + path('M40 146 L38 166 M126 146 L128 166', 'none', '#a9803d', 1.4),
        path('M67 121 L83 134 L100 121', 'none', '#dedcca', 2.5) + path('M30 151 L136 151 M27 161 L141 161', 'none', '#a2b4aa', 2),
    ]
    s += outfits[family]
    s += path('M39 144 L36 166 M127 144 L131 166', 'none', '#3d3e36', .6)
    s += '<g transform="translate(83 77)">' + head(family, pearl) + '</g>'
    return s


def svg(viewbox, content):
    # Rasterize SVG imports at 3x so portraits stay crisp on high-density phones.
    width, height = [int(x) * 3 for x in viewbox.split()[2:]]
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{viewbox}">{content}</svg>\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify generated assets without rewriting them')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    for family in range(6):
        for pearl in (False, True):
            identity = family * 2 + int(pearl)
            for name, contents in [
                (f'portrait-{identity:02}.svg', svg('0 0 166 174', portrait(family, pearl))),
                (f'head-{identity:02}.svg', svg('-48 -55 96 96', head(family, pearl))),
            ]:
                dest = OUT / name
                if args.check:
                    assert dest.read_text() == contents, f'{dest} needs regeneration'
                else:
                    dest.write_text(contents)
    print(('Verified' if args.check else 'Generated') + ' 12 matching portraits and 12 shared heads.')


if __name__ == '__main__':
    main()
