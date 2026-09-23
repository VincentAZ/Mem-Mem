#!/usr/bin/env python3
"""Check the shipped binary, including native SDK classes and ELF page alignment."""
import json
from pathlib import Path
import struct
import sys
import zipfile

apk = Path(sys.argv[1] if len(sys.argv) > 1 else 'build/mem-mem-debug.apk')
with zipfile.ZipFile(apk) as archive:
    dex = b''.join(archive.read(n) for n in archive.namelist() if n.endswith('.dex'))
    for name in (
        b'Lorg/godotengine/plugin/googleplaybilling/GodotGooglePlayBilling;',
        b'Lorg/godotengine/plugin/admob/AdmobPlugin;',
        b'Lcom/android/billingclient/api/BillingClient;',
        b'Lcom/google/android/gms/ads/MobileAds;',
        b'Lio/github/vincentaz/memmem/MemMemConsent;',
        b'Lcom/google/android/ump/UserMessagingPlatform;',
    ):
        if name not in dex:
            raise SystemExit('Native class absent from APK: ' + name.decode())
    libraries = []
    for name in archive.namelist():
        if not name.endswith('.so'):
            continue
        data = archive.read(name)
        if data[:6] != b'\x7fELF\x02\x01':
            raise SystemExit('Expected little-endian ELF64: ' + name)
        offset = struct.unpack_from('<Q', data, 32)[0]
        entry_size, count = struct.unpack_from('<HH', data, 54)
        alignments = []
        for i in range(count):
            header = offset + i * entry_size
            kind = struct.unpack_from('<I', data, header)[0]
            if kind == 1:  # PT_LOAD
                alignment = struct.unpack_from('<Q', data, header + 48)[0]
                if alignment < 16384:
                    raise SystemExit('ELF lacks 16 KB alignment: ' + name)
                alignments.append(alignment)
        libraries.append({'library': name, 'load_segment_alignment': alignments})
    if not any('arm64-v8a/libgodot_android.so' in x['library'] for x in libraries):
        raise SystemExit('ARM64 Godot library missing')
    if not any('x86_64/libgodot_android.so' in x['library'] for x in libraries):
        raise SystemExit('x86_64 Godot library missing')
print(json.dumps({'apk': str(apk), 'native_plugins': 'present', 'libraries': libraries}, indent=2))
