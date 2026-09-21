#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "$0")/env.sh"
sdkmanager 'emulator' 'system-images;android-35;google_apis;x86_64'
if [[ ! -f "$ANDROID_AVD_HOME/MemMemTest.ini" ]]; then
  printf 'no\n' | avdmanager create avd --name MemMemTest --package 'system-images;android-35;google_apis;x86_64' --device pixel_2
fi
# KVM is preferred; software emulation remains available on hosts without /dev/kvm.
acceleration=auto
if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then acceleration=off; fi
exec "$ANDROID_HOME/emulator/emulator" -avd MemMemTest -no-audio -no-boot-anim \
  -accel "$acceleration" -gpu swangle -memory 2048 -cores 2 \
  -no-snapshot -skin 432x900 "$@"
