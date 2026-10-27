#!/usr/bin/env python3
"""Install pinned addons and Android build template, configure isolated editor settings."""
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.tools'
GAME = ROOT / 'game'
# Remove cached monetization plugins from earlier checkouts as well as fresh builds.
shutil.rmtree(GAME / 'addons', ignore_errors=True)
shutil.rmtree(GAME / 'android/plugins', ignore_errors=True)
android = GAME / 'android/build'
# Recreate the generated template so older consent Gradle dependencies and Java
# sources cannot survive an upgrade of an existing working copy.
shutil.rmtree(android, ignore_errors=True)
android.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(TOOLS / 'xdg-data/godot/export_templates/4.7.2.stable/android_source.zip') as archive:
    archive.extractall(android)
(android / '.gdignore').touch()
(GAME / 'android/.build_version').write_text('4.7.2.stable')
gradlew = android / 'gradlew'
if gradlew.exists():
    gradlew.chmod(0o755)
config = TOOLS / 'xdg-config/godot'
config.mkdir(parents=True, exist_ok=True)
# Separate editor configuration leaves the user's normal Godot settings unchanged.
(config / 'editor_settings-4.7.tres').write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    f'export/android/java_sdk_path = "{TOOLS / "jdk"}"\n'
    f'export/android/android_sdk_path = "{TOOLS / "android-sdk"}"\n'
    'export/android/shutdown_adb_on_exit = false\n'
)
print('Offline Android Gradle template installed.')
