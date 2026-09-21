#!/usr/bin/env bash
# Source from project scripts. All build state stays inside the ignored .tools folder.
set -euo pipefail
MEMMEM_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export MEMMEM_ROOT
export JAVA_HOME="$MEMMEM_ROOT/.tools/jdk"
export ANDROID_HOME="$MEMMEM_ROOT/.tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export GRADLE_USER_HOME="$MEMMEM_ROOT/.tools/gradle"
export XDG_DATA_HOME="$MEMMEM_ROOT/.tools/xdg-data"
export XDG_CONFIG_HOME="$MEMMEM_ROOT/.tools/xdg-config"
export XDG_CACHE_HOME="$MEMMEM_ROOT/.tools/xdg-cache"
export ANDROID_USER_HOME="$MEMMEM_ROOT/.tools/android-user"
export ANDROID_EMULATOR_HOME="$ANDROID_USER_HOME"
export ANDROID_AVD_HOME="$MEMMEM_ROOT/.tools/avd"
export GODOT="$MEMMEM_ROOT/.tools/godot/Godot_v4.7.2-stable_linux.x86_64"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/23.0/bin:$PATH"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$ANDROID_USER_HOME" "$ANDROID_AVD_HOME"
