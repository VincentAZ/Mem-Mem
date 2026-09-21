#!/usr/bin/env python3
"""Collection tap regression on the dedicated emulator; never runs on a phone.

Run smoke_desktop.sh for control positions, and smoke_android.py to prepare owned
characters plus saved choices. Installs the current APK; spends one emulator choice.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess
import time
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = 'io.github.vincentaz.memmem'
ACTIVITY = PACKAGE + '/com.godot.game.GodotAppLauncher'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--serial', default='emulator-5554')
args = parser.parse_args()
if not args.serial.startswith('emulator-'):
    parser.error('This input test is restricted to the dedicated emulator.')
ADB = str(Path(os.environ['ANDROID_HOME']) / 'platform-tools/adb')
LAYOUT = json.loads((ROOT / 'build/smoke-layout.json').read_text())
SHOTS = ROOT / 'build/screenshots'


def adb(*command):
    return subprocess.check_output([ADB, '-s', args.serial, *command], stderr=subprocess.PIPE)


def snapshot():
    slots = []
    for slot in range(2):
        envelope = json.loads(adb('shell', 'run-as', PACKAGE, 'cat', f'files/progress.{slot}.json'))
        assert hashlib.sha256(envelope['payload'].encode()).hexdigest() == envelope['checksum']
        slots.append((envelope['revision'], json.loads(envelope['payload'])))
    return max(slots, key=lambda item: item[0])[1]


def wait_for(predicate):
    for _ in range(60):
        value = snapshot()
        if predicate(value):
            return value
        time.sleep(.1)
    raise AssertionError('Saved state did not reach the expected condition')


def point(x, y):
    return round(12 + x * 408 / 432), round(24 + y * 852 / 900)


def tap(x, y):
    adb('shell', 'input', 'tap', *map(str, point(x, y)))


def tap_ui(name):
    tap(*LAYOUT[name])


def frame(name):
    data = adb('exec-out', 'screencap', '-p')
    (SHOTS / f'android-reactions-{name}.png').write_bytes(data)
    return Image.open(io.BytesIO(data)).convert('RGB')


def badge(image):
    x, y = LAYOUT['first_character']
    return image.crop((*point(x - 43, y + 82), *point(x + 43, y + 94)))


def same(a, b):
    return ImageChops.difference(a, b).getbbox() is None


def verify(condition, message):
    if not condition:
        raise AssertionError(message)
    print('PASS: ' + message, flush=True)


def back():
    adb('shell', 'input', 'keyevent', '4')
    time.sleep(.15)


def preference(key, control, desired):
    tap_ui('settings')
    time.sleep(.2)
    if snapshot()[key] != desired:
        tap_ui(control)
        wait_for(lambda value: value[key] == desired)
    back()


verify('432x900' in adb('shell', 'wm', 'size').decode(), 'fixed test emulator viewport')
before = snapshot()
candidates = [i for i in range(6) if i not in before['collected']]
verify(bool(before['collected']) and before['choice_tokens'] > 0 and bool(candidates), 'test fixture has ownership and a saved choice')
adb('shell', 'am', 'force-stop', PACKAGE)
adb('install', '-r', str(ROOT / 'build/mem-mem-debug.apk'))
adb('logcat', '-c')
adb('shell', 'am', 'start', '-n', ACTIVITY)
time.sleep(2)
verify(snapshot() == before, 'APK update preserves exact progress and collection')
preference('sound', 'sound', True)
preference('reduced_motion', 'motion', False)
tap_ui('collection')
time.sleep(.4)
previous_badge = badge(frame('owned-idle'))
for index in range(5):
    tap_ui('first_character')
    current = frame(f'owned-tap-{index}')
    current_badge = badge(current)
    verify(not same(previous_badge, current_badge), 'owned tap gives a different reaction without an immediate repeat')
    previous_badge = current_badge
    time.sleep(.23)
verify(snapshot()['collected'] == before['collected'] and snapshot()['choice_tokens'] == before['choice_tokens'], 'owned taps cannot spend choices or change ownership')
adb('shell', 'input', 'keyevent', '3')
adb('shell', 'am', 'start', '-n', ACTIVITY)
time.sleep(.6)
frame('foreground')
verify(snapshot()['round'] == before['round'], 'background/resume during a reaction preserves the board')
tap_ui('discover')
time.sleep(.3)
candidate = candidates[0]
x, y = LAYOUT['first_character']
column_step = LAYOUT['second_character'][0] - x
tap(x + candidate % 3 * column_step, y + candidate // 3 * 224)
frame('selection-fireworks')
verify(snapshot()['collected'] == before['collected'] and snapshot()['choice_tokens'] == before['choice_tokens'], 'fireworks selection does not claim or spend before Collect')
tap_ui('claim')
claimed = wait_for(lambda value: candidate in value['collected'])
frame('confirmed-fireworks')
verify(claimed['choice_tokens'] == before['choice_tokens'] - 1 and claimed['collected'] == before['collected'] + [candidate], 'Collect saves exactly the chosen character and spends one choice')
back()
preference('sound', 'sound', False)
preference('reduced_motion', 'motion', True)
tap_ui('collection')
time.sleep(.35)
tap_ui('first_character')
a = frame('reduced-tap')
time.sleep(.3)
b = frame('reduced-still')
x, y = LAYOUT['first_character']
portrait = (*point(x - 42, y - 92), *point(x + 42, y + 50))
verify(same(a.crop(portrait), b.crop(portrait)), 'Reduce motion keeps the tapped character still')
back()
preference('sound', 'sound', before['sound'])
preference('reduced_motion', 'motion', before['reduced_motion'])
adb('shell', 'am', 'force-stop', PACKAGE)
adb('shell', 'am', 'start', '-n', ACTIVITY)
time.sleep(1.7)
after = snapshot()
verify(after['round'] == before['round'] and after['banked_points'] == before['banked_points'] and after['collected'] == claimed['collected'] and after['choice_tokens'] == claimed['choice_tokens'], 'restart preserves the explicit claim and leaves gameplay unchanged')
log = adb('logcat', '-d', '-s', 'godot:V', 'Godot:V', 'AndroidRuntime:E')
(ROOT / 'build/android-reactions-runtime.log').write_bytes(log)
verify(all(token not in log for token in [b'SCRIPT ERROR', b'ERROR:', b'FATAL EXCEPTION']), 'Android runtime is free of script and fatal errors')
(ROOT / 'build/android-reactions-results.json').write_text(json.dumps({'status': 'passed', 'apk_sha256': hashlib.sha256((ROOT / 'build/mem-mem-debug.apk').read_bytes()).hexdigest(), 'final_progress': after}, indent=2) + '\n')
