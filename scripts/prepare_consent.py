#!/usr/bin/env python3
"""Install the tracked UMP extension into Godot's generated Android source tree."""
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parent.parent

def install(game=ROOT / 'game'):
    build = game / 'android/build'
    source = build / 'src/main/java/io/github/vincentaz/memmem/MemMemConsent.java'
    source.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / 'android/consent/MemMemConsent.java', source)
    manifest = build / 'src/main/AndroidManifest.xml'
    text = manifest.read_text()
    marker = 'org.godotengine.plugin.v2.MemMemConsent'
    if marker not in text:
        text = text.replace('</application>',
            '<meta-data android:name="' + marker + '" '
            'android:value="io.github.vincentaz.memmem.MemMemConsent" />\n    </application>')
        manifest.write_text(text)
    # Explicitly pin the UMP version also used transitively by the installed ad SDK.
    gradle = build / 'build.gradle'
    text = gradle.read_text()
    dependency = 'implementation "com.google.android.ump:user-messaging-platform:3.2.0"'
    if dependency not in text:
        gradle.write_text(text.replace('dependencies {', 'dependencies {\n    ' + dependency, 1))

if __name__ == '__main__':
    install()
