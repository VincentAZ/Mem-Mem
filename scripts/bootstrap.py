#!/usr/bin/env python3
"""Download checksum-pinned Linux x86_64 development dependencies locally."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.tools'
DOWNLOADS = TOOLS / 'downloads'
LOCK = json.loads((ROOT / 'scripts/dependencies.json').read_text())


def download(item):
    name, dep = item
    dest = DOWNLOADS / (name + '.archive')
    algorithm = 'sha256' if 'sha256' in dep else 'sha1'
    def valid():
        if not dest.exists():
            return False
        with dest.open('rb') as stream:
            return hashlib.file_digest(stream, algorithm).hexdigest() == dep[algorithm]
    if not valid():
        print('Downloading ' + name, flush=True)
        partial = dest.with_suffix('.partial')
        subprocess.run(['curl', '-fL', '--retry', '3', '--silent', '--show-error',
                        dep['url'], '-o', str(partial)], check=True)
        partial.replace(dest)
        if not valid():
            raise RuntimeError('Checksum mismatch: ' + name)
    return name, dest


def unzip(source, destination, predicate=lambda _: True):
    with zipfile.ZipFile(source) as archive:
        for member in archive.infolist():
            if not predicate(member.filename):
                continue
            target = (destination / member.filename).resolve()
            if not target.is_relative_to(destination.resolve()):
                raise RuntimeError('Unsafe archive path')
            archive.extract(member, destination)
            mode = member.external_attr >> 16
            if mode and target.is_file():
                target.chmod(mode & 0o777)


def main():
    DOWNLOADS.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        archives = dict(pool.map(download, LOCK.items()))
    unzip(archives['godot'], TOOLS / 'godot')
    godot = TOOLS / 'godot/Godot_v4.7.2-stable_linux.x86_64'
    godot.chmod(0o755)
    with tarfile.open(archives['jdk']) as archive:
        archive.extractall(TOOLS / 'java', filter='data')
    jdk = next((TOOLS / 'java').glob('*/bin/java')).parent.parent
    link = TOOLS / 'jdk'
    if not link.exists():
        link.symlink_to(jdk.relative_to(TOOLS), target_is_directory=True)
    unzip(archives['android_tools'], TOOLS / 'android-temp')
    sdk_tools = TOOLS / 'android-sdk/cmdline-tools/23.0'
    if not sdk_tools.exists():
        sdk_tools.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(TOOLS / 'android-temp/cmdline-tools'), sdk_tools)
    template_root = TOOLS / 'xdg-data/godot/export_templates/4.7.2.stable'
    template_root.mkdir(parents=True, exist_ok=True)
    # Extract only Android templates instead of all desktop/console targets.
    with zipfile.ZipFile(archives['templates']) as archive:
        for name in archive.namelist():
            if Path(name).name in ('android_source.zip', 'android_debug.apk', 'android_release.apk', 'version.txt'):
                with archive.open(name) as src, (template_root / Path(name).name).open('wb') as dst:
                    shutil.copyfileobj(src, dst)
    for name in ('billing', 'admob'):
        unzip(archives[name], TOOLS / (name + '-unpacked'))
    print('Archives verified and extracted. Run scripts/setup.sh to install SDK packages.', flush=True)


if __name__ == '__main__':
    main()
