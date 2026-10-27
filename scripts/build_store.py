#!/usr/bin/env python3
"""Validate store inputs and export a signed AAB from an isolated project copy."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent


def validate(config, env):
    errors = []
    if type(config.get('version_code')) is not int or config['version_code'] <= 10:
        errors.append('version_code: provide an integer above 10 (and above every prior Play upload)')
    if not re.fullmatch(r'\d+\.\d+\.\d+', str(config.get('version_name', ''))):
        errors.append('version_name: provide a release version such as 0.7.0')
    for name in ('GODOT_ANDROID_KEYSTORE_RELEASE_PATH', 'GODOT_ANDROID_KEYSTORE_RELEASE_USER', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD'):
        if not env.get(name):
            errors.append(f'{name}: required for signing (supply it in the environment)')
    signing = Path(env.get('GODOT_ANDROID_KEYSTORE_RELEASE_PATH') or '/nonexistent')
    if not signing.is_file():
        errors.append('upload keystore: file does not exist')
    if signing.name == 'debug.keystore' or env.get('GODOT_ANDROID_KEYSTORE_RELEASE_USER') == 'androiddebugkey':
        errors.append('upload keystore: the Android debug certificate cannot sign a store build')
    return errors


def stage(config):
    destination = ROOT / 'build/store-project'
    if destination.exists():
        shutil.rmtree(destination)
    shutil.copytree(ROOT / 'game', destination, ignore=shutil.ignore_patterns(
        '.godot', 'android', 'addons', 'tests', 'export_credentials.cfg', 'monetization.cfg'))
    android = destination / 'android/build'
    android.mkdir(parents=True)
    with zipfile.ZipFile(ROOT / '.tools/xdg-data/godot/export_templates/4.7.2.stable/android_source.zip') as archive:
        archive.extractall(android)
    (android / '.gdignore').touch()
    (android.parent / '.build_version').write_text('4.7.2.stable')
    (android / 'gradlew').chmod(0o755)
    preset = (destination / 'export_presets.cfg').read_text()
    preset = preset.replace('name="Android"', 'name="Android Store"\ncustom_features="production"', 1)
    preset = preset.replace('gradle_build/export_format=0', 'gradle_build/export_format=1')
    preset = re.sub(r'version/code=\d+', f'version/code={config["version_code"]}', preset)
    preset = re.sub(r'version/name="[^"]*"', f'version/name={json.dumps(config["version_name"])}', preset)
    (destination / 'export_presets.cfg').write_text(preset)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('config', type=Path)
    parser.add_argument('--check', action='store_true', help='validate inputs without staging or exporting')
    args = parser.parse_args()
    try:
        config = json.loads(args.config.read_text())
        if not isinstance(config, dict):
            raise ValueError('expected a JSON object')
        errors = validate(config, os.environ)
    except (OSError, ValueError, TypeError) as error:
        parser.exit(1, f'Cannot read store configuration: {error}\n')
    if errors:
        parser.exit(1, 'Store export is blocked:\n' + ''.join(f'  - {item}\n' for item in errors))
    # Check the actual key alias, rather than relying only on its filename.
    keycheck = subprocess.run(['keytool', '-list', '-v', '-keystore', os.environ['GODOT_ANDROID_KEYSTORE_RELEASE_PATH'],
        '-alias', os.environ['GODOT_ANDROID_KEYSTORE_RELEASE_USER'], '-storepass:env', 'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD'],
        capture_output=True, text=True, env={**os.environ, 'LC_ALL': 'C'})
    if keycheck.returncode or 'Android Debug' in keycheck.stdout:
        parser.exit(1, 'Upload key could not be verified, or is a debug certificate.\n')
    if args.check:
        print('Store configuration and upload key passed local checks. Console and device validation are still required.')
        return
    destination = stage(config)
    godot = os.environ['GODOT']
    artifact = ROOT / 'build/mem-mem-store.aab'
    artifact.unlink(missing_ok=True)
    for name, command in (
        ('store-import', [godot, '--headless', '--path', str(destination), '--editor', '--import']),
        ('store-export', [godot, '--headless', '--path', str(destination), '--export-release', 'Android Store', str(artifact)]),
    ):
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (ROOT / f'build/{name}.log').write_text(result.stdout)
        if result.returncode or re.search(r'SCRIPT ERROR|Parse Error|Project export .* failed', result.stdout):
            parser.exit(1, f'{name} failed; see build/{name}.log\n')
    if not artifact.is_file() or artifact.stat().st_size == 0:
        parser.exit(1, 'Store export did not produce an AAB.\n')
    verification = subprocess.run(['jarsigner', '-verify', str(artifact)], capture_output=True, text=True)
    if verification.returncode or 'jar verified.' not in verification.stdout:
        parser.exit(1, 'AAB signature verification failed.\n')
    import hashlib
    artifact.with_suffix('.aab.sha256').write_text(hashlib.sha256(artifact.read_bytes()).hexdigest() + '  ' + artifact.name + '\n')
    print(f'Signed store bundle: {artifact}\nUpload to internal testing and complete the device checks before production.')


if __name__ == '__main__':
    main()
