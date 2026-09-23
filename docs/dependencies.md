# Dependency and build notes

`scripts/dependencies.json` pins archive versions, official URLs, and checksums.
`bootstrap.py` verifies downloads before extraction. Third-party package license
files remain in the installed archives/addons; none of their binaries are committed.

- Godot 4.7.2 stable, MIT: https://godotengine.org/license/
- GodotGooglePlayBilling 3.3.0, MIT; Google Billing 9.1.0:
  https://github.com/godot-sdk-integrations/godot-google-play-billing
- AdmobPlugin Android 7.0, MIT; Google Mobile Ads 24.9.0:
  https://github.com/godot-sdk-integrations/godot-admob
- Eclipse Temurin JDK 17 (specific archive recorded in the lockfile), GPLv2 with
  Classpath Exception: https://adoptium.net/
- Android command-line tools 23.0, platform 36, Build Tools 36.1.0, NDK
  29.0.14206865, and CMake 3.10.2.4988404 under their supplied licenses.
- Godot's matching Android template supplies Gradle 8.11.1, Android Gradle Plugin
  8.6.1, and Kotlin 2.1.21. These versions come from the pinned engine template.

The engine's matching Android template is authoritative for build-tool and NDK
versions. General Godot website setup examples may describe an older template.

Android platform-tools and the optional emulator are SDK-managed development
utilities. They are not linked into the app. The optional test image is Google
APIs Android 35 x86_64, and is not a Play Store purchase-testing environment.

The tracked Android consent extension explicitly pins UMP 3.2.0, matching the
installed ad SDK's transitive dependency. It compiles into Godot's generated Gradle
project; no third-party plugin binary is modified. Node.js 22+ runs the verifier
and server tests using only built-in modules (no npm dependencies).

Debug builds use Google demo ad IDs and the developer lab. The isolated store export
selects native billing, signed verification and UMP, hides the lab, and requires real
configuration. Live store validation and third-party attribution remain launch work.
