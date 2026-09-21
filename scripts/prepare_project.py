#!/usr/bin/env python3
"""Install pinned addons and Android build template, configure isolated editor settings."""
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.tools'
GAME = ROOT / 'game'
addons = GAME / 'addons'
addons.mkdir(exist_ok=True)
shutil.copytree(TOOLS / 'billing-unpacked/GodotGooglePlayBilling', addons / 'GodotGooglePlayBilling', dirs_exist_ok=True)
for source in (TOOLS / 'admob-unpacked/res/addons').iterdir():
    shutil.copytree(source, addons / source.name, dirs_exist_ok=True)
# Explicit export config is needed because the SDK node is created lazily at runtime.
(addons / 'AdmobPlugin/android_export.cfg').write_text(
    '[General]\nis_real=false\n[Debug]\n'
    'app_id="ca-app-pub-3940256099942544~3347511713"\n'
    '[Release]\napp_id="ca-app-pub-3940256099942544~3347511713"\n'
    '[Mediation]\nenabled_networks=[]\n'
)
android = GAME / 'android/build'
if not (android / 'build.gradle').exists():
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
print('Pinned addons and Android Gradle template installed.')
