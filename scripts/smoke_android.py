#!/usr/bin/env python3
"""Touch/lifecycle regression for the bundled 432x900 API 35 test emulator only.

Requires an installed APK. Resets only the emulator's game-progress files, never
desktop saves or purchase ownership. Run with scripts/env.sh sourced.
"""
import argparse
import hashlib
import json
import io
import os
from pathlib import Path
import subprocess
import time
from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parent.parent
PACKAGE = 'io.github.vincentaz.memmem'
ACTIVITY = PACKAGE + '/com.godot.game.GodotAppLauncher'
ARTIFACTS = ROOT / 'build'
SHOTS = ARTIFACTS / 'screenshots'
# Captured from the actual UI by smoke_desktop.sh, avoiding duplicate layout constants.
LAYOUT = json.loads((ARTIFACTS / 'smoke-layout.json').read_text())
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--serial', default='emulator-5554')
parser.add_argument('--reset-test-progress', action='store_true', required=True)
args = parser.parse_args()
if not args.serial.startswith('emulator-'):
    parser.error('This fixed-layout test is restricted to the bundled emulator.')
adb_path = str(Path(os.environ['ANDROID_HOME']) / 'platform-tools/adb')


def adb(*command):
    return subprocess.check_output([adb_path, '-s', args.serial, *command], stderr=subprocess.PIPE)


def snapshot():
    valid = []
    for slot in range(2):
        try:
            envelope = json.loads(adb('shell', 'run-as', PACKAGE, 'cat', f'files/progress.{slot}.json'))
            assert hashlib.sha256(envelope['payload'].encode()).hexdigest() == envelope['checksum']
            valid.append((envelope['revision'], json.loads(envelope['payload'])))
        except (subprocess.CalledProcessError, ValueError, KeyError, AssertionError):
            pass
    return max(valid, key=lambda item: item[0])[1] if valid else None


def wait_for(predicate, timeout=12):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = snapshot()
        if value and predicate(value):
            return value
        time.sleep(.15)
    raise AssertionError('Timed out waiting for saved state: ' + repr(snapshot()))


def shot(name):
    (SHOTS / f'android-collection-{name}.png').write_bytes(adb('exec-out', 'screencap', '-p'))


def tap_point(x, y):
    # Fixed test emulator: 432x900 viewport letterboxed below the Android status bar.
    adb('shell', 'input', 'tap', str(round(12 + x * 408 / 432)), str(round(24 + y * 852 / 900)))


def tap_ui(name):
    tap_point(*LAYOUT[name])


def tap(index, count):
    columns = 4 if count == 16 else 3 if count == 12 else 2
    rows = (count + columns - 1) // columns
    left, top, board_width, board_height = LAYOUT['board']
    width = int((board_width - 10 * (columns - 1)) / columns)
    height = int((board_height - 10 * (rows - 1)) / rows)
    tap_point(left + (index % columns) * (width + 10) + width / 2,
              top + (index // columns) * (height + 10) + height / 2)


def pair(first, state):
    identities = state['round']['identities']
    mate = next(i for i, identity in enumerate(identities) if i != first and identity == identities[first])
    tap(first, len(identities))
    tap(mate, len(identities))
    return mate


def launch():
    adb('shell', 'am', 'start', '-n', ACTIVITY)


def restart():
    adb('shell', 'am', 'force-stop', PACKAGE)
    launch()
    time.sleep(1.7)


def next_level(level):
    time.sleep(3.4)  # Longer than the old auto-advance delay; allow the whole cast to return.
    current = snapshot()
    verify(current['round']['level'] == level, f'level {level} result stays on screen without input')
    verify(len(current['round']['removed']) == len(current['round']['identities']), 'held result is the completed board')
    shot(f'complete-level-{level}')
    # Center of the Next level button in the bundled emulator viewport.
    tap_ui('next')
    tap_ui('next')
    result = wait_for(lambda s: s['round']['level'] == level + 1 and not s['round']['opening'])
    verify(result['round']['attempts'] == 0, 'repeated Next level tap cannot skip a level or reveal a new pair')
    return result


def verify(condition, message):
    if not condition:
        raise AssertionError(message)
    print('PASS: ' + message, flush=True)


SHOTS.mkdir(parents=True, exist_ok=True)
verify('432x900' in adb('shell', 'wm', 'size').decode(), 'bundled emulator resolution')
adb('shell', 'wm', 'density', '160')
adb('shell', 'am', 'force-stop', PACKAGE)
prior = snapshot()
if prior and prior.get('version', 1) < 4:
    launch()
    migrated = wait_for(lambda s: s.get('version') == 4)
    verify(all(migrated[key] == prior[key] for key in ['seed', 'banked_points', 'sound', 'haptics', 'reduced_motion']), 'installed update preserves score and preferences')
    verify(all(migrated['round'][key] == value for key, value in prior['round'].items()), 'installed update preserves the exact legacy board')
    verify(migrated['easy_from_level'] == prior['round']['level'] + 1, 'expanded wave begins after the saved board')
    if prior.get('version') == 2:
        verify(all(migrated[key] == prior[key] for key in ['collected', 'choice_tokens', 'reward_level', 'dark_mode', 'background']), 'installed update preserves collection, choices and appearance')
    adb('shell', 'am', 'force-stop', PACKAGE)
adb('shell', 'run-as', PACKAGE, 'rm', '-f', 'files/progress.0.json', 'files/progress.1.json')
adb('logcat', '-c')
launch()
state = wait_for(lambda s: not s['round']['opening'])
verify(state['round']['level'] == 1, 'new journey starts at level 1')
shot('board')
identities = state['round']['identities']
other = next(i for i, value in enumerate(identities) if value != identities[0])
tap(0, 4)
tap(other, 4)
time.sleep(.3)
shot('mismatch')
time.sleep(1.1)
verify(snapshot()['round']['attempts'] == 1 and not snapshot()['round']['removed'], 'mismatch records one attempt and removes no cards')
shot('mismatch-reset')
# One more mismatch makes this four-card board exactly 50%.
for _ in range(1):
    tap(0, 4)
    tap(other, 4)
    time.sleep(1.3)
verify(snapshot()['round']['attempts'] == 2, 'two deliberate mismatches are recorded')
mate = pair(0, snapshot())
state = wait_for(lambda s: len(s['round']['removed']) == 2)
time.sleep(.35)
shot('walking')
restart()
verify(snapshot() == state, 'process termination during departure preserves layout, attempts and score')
shot('restarted')
while len(snapshot()['round']['removed']) < 4:
    state = snapshot()
    first = next(i for i in range(4) if i not in state['round']['removed'])
    pair(first, state)
    time.sleep(.70)
completed = snapshot()
verify(len(completed['round']['removed']) == 4 and completed['round']['attempts'] == 4, 'complete board records two matches in four comparisons: exactly 50 percent')
# Kill before choosing Next: restore this result and wait for explicit input.
restart()
verify(snapshot()['round'] == completed['round'] and snapshot()['banked_points'] == completed['banked_points'], 'completed level survives restart without advancing or changing score')
verify(snapshot()['reward_level'] == 1 and snapshot()['choice_tokens'] == 0 and not snapshot()['collected'], '50 percent completion earns no choice and never auto-collects')
completed = snapshot()
adb('shell', 'input', 'keyevent', '3')
time.sleep(.4)
launch()
time.sleep(.4)
verify(snapshot() == completed, 'completed result also survives background/resume')
state = next_level(1)
verify(state['banked_points'] == 220, 'Next level banks the completion bonus exactly once')
shot('level-two')
pair(0, state)
state = wait_for(lambda s: len(s['round']['removed']) == 2)
adb('shell', 'input', 'keyevent', '3')
time.sleep(.5)
launch()
time.sleep(1.5)
verify(snapshot() == state, 'Android background/resume preserves unfinished level 2')
adb('shell', 'input', 'keyevent', '4')
time.sleep(.3)
shot('pause')
# Phase 3 sound control: actual touch, immediate save, lifecycle, process restart.
tap_ui('sound')
muted = wait_for(lambda s: s.get('sound') is False)
verify(muted['round'] == state['round'] and muted['banked_points'] == state['banked_points'], 'muting changes only the preference, not progress')
state = muted
shot('sound-muted')
adb('shell', 'input', 'keyevent', '3')
launch()
time.sleep(.4)
shot('pause-after-resume')
verify(snapshot()['sound'] is False, 'muted preference survives background/resume')
adb('shell', 'input', 'keyevent', '4')
time.sleep(.3)
# An offline restart must use the same local progression.
wifi_before = adb('shell', 'settings', 'get', 'global', 'wifi_on').strip()
data_before = adb('shell', 'settings', 'get', 'global', 'mobile_data').strip()
try:
    adb('shell', 'svc', 'wifi', 'disable')
    adb('shell', 'svc', 'data', 'disable')
    restart()
    verify(snapshot() == state, 'offline relaunch preserves score and fixed board')
    shot('offline')
finally:
    if wifi_before == b'1':
        adb('shell', 'svc', 'wifi', 'enable')
    if data_before == b'1':
        adb('shell', 'svc', 'data', 'enable')
# Play through the peak and back down, using touch input for every match.
for level in range(2, 10):
    state = wait_for(lambda s: s['round']['level'] == level and not s['round']['opening'])
    if level in [5, 9]:
        shot('twelve-board' if level == 5 else 'sixteen-board')
    if level == 9:
        verify(len(state['round']['identities']) == 16, 'level 9 uses all 16 touch targets')
    count = len(state['round']['identities'])
    while True:
        state = snapshot()
        if state['round']['level'] != level or len(state['round']['removed']) == count:
            break
        first = next(i for i in range(count) if i not in state['round']['removed'])
        pair(first, state)
        time.sleep(.70)
    if level == 2:
        earned = wait_for(lambda s: s['reward_level'] == 2)
        verify(earned['choice_tokens'] == 1, 'perfect board earns a free character choice')
        time.sleep(1.4)
        shot('perfect-choice')
        tap_ui('reward')
        time.sleep(.4)
        shot('collection')
        tap_ui('first_character')
        tap_ui('claim')
        claimed = wait_for(lambda s: 0 in s['collected'] and s['choice_tokens'] == 0)
        time.sleep(.4)  # Allow the saved claim to be rendered before capturing it.
        shot('collected')
        restart()
        verify(snapshot() == claimed, 'collected character and spent choice persist; restart does not re-award')
    state = next_level(level)
    verify(state['round']['level'] == level + 1, f'button advances level {level} → {level + 1}')
verify(len(state['round']['identities']) == 4 and state['banked_points'] == 4180, 'difficulty eases after the 16-card peak with exact cumulative score')
verify(state['sound'] is False, 'mute remains saved across restart and the full difficulty wave')
verify(state['choice_tokens'] == 7 and state['collected'] == [0], 'eight perfect boards bank choices; only the explicitly chosen character is collected')
shot('breather')
adb('shell', 'input', 'keyevent', '4')
time.sleep(.3)
tap_ui('sound')
state = wait_for(lambda s: s.get('sound') is True)
tap_ui('dark')
state = wait_for(lambda s: s.get('dark_mode') is True)
# Open the background popup and select Orbit.
tap_ui('background')
time.sleep(.25)
shot('background-menu')
# Native popup: Orbit is the fourth 26px row below this 46px control.
tap_point(LAYOUT['background'][0], LAYOUT['background'][1] + 123)
state = wait_for(lambda s: s.get('background') == 3)
shot('dark-settings')
restart()
verify(snapshot() == state, 'sound, dark mode, background, and collection persist across restart')
tap_ui('collection')
time.sleep(.5)
shot('my-collection')
first_frame = adb('exec-out', 'screencap', '-p')
time.sleep(.35)
second_frame = adb('exec-out', 'screencap', '-p')
first_image = Image.open(io.BytesIO(first_frame)).convert('RGB').crop((12, 300, 420, 800))
second_image = Image.open(io.BytesIO(second_frame)).convert('RGB').crop((12, 300, 420, 800))
verify(ImageChops.difference(first_image, second_image).getbbox() is not None, 'owned collection has visible animation on Android')
adb('shell', 'input', 'keyevent', '4')
tap_ui('settings')
time.sleep(.3)
tap_ui('motion')
state = wait_for(lambda s: s['reduced_motion'])
adb('shell', 'input', 'keyevent', '4')
tap_ui('collection')
time.sleep(.8)
first_frame = adb('exec-out', 'screencap', '-p')
time.sleep(.25)
second_frame = adb('exec-out', 'screencap', '-p')
# Check only the game viewport; the Android status bar clock is unrelated.
first_image = Image.open(io.BytesIO(first_frame)).convert('RGB').crop((12, 24, 420, 876))
second_image = Image.open(io.BytesIO(second_frame)).convert('RGB').crop((12, 24, 420, 876))
verify(ImageChops.difference(first_image, second_image).getbbox() is None, 'Reduce motion freezes collection animation on Android')
shot('my-collection-reduced')
adb('shell', 'input', 'keyevent', '4')
tap_ui('settings')
time.sleep(.3)
tap_ui('motion')
state = wait_for(lambda s: not s['reduced_motion'])
adb('shell', 'input', 'keyevent', '4')
log = adb('logcat', '-d', '-s', 'godot:V', 'Godot:V', 'AndroidRuntime:E')
(ARTIFACTS / 'android-collection-runtime.log').write_bytes(log)
verify(all(token not in log for token in [b'SCRIPT ERROR', b'ERROR:', b'FATAL EXCEPTION']), 'no Godot errors or Android fatal exceptions')
(ARTIFACTS / 'android-collection-results.json').write_text(json.dumps({'status': 'passed', 'tests': 'touch, mismatch, departure restart, persistent completion, explicit Next level, completion restart, pause, lifecycle, offline, 16-card peak and full returning cast, mute/unmute persistence, animated owned collection, Reduce motion, schema migration, perfect choice, explicit collection claim only, dark mode, backgrounds', 'final_progress': state}, indent=2) + '\n')
