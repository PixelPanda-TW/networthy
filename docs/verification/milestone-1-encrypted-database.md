# Milestone 1 Encrypted Database Verification

## Current Status

Milestone 1 implementation is verified.

Completed:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Host SQLite3MultipleCiphers provider smoke test
- Host plaintext search against generated probe database
- Android debug APK build
- Android emulator runtime smoke test
- Android app-container database plaintext inspection
- iOS simulator runtime smoke test
- iOS app-container database plaintext inspection

Milestone 1 runtime verification is complete for the available iOS simulator and Android emulator.

## Provider Decision

Selected initial provider: SQLite3MultipleCiphers through `package:sqlite3` 3.x build hooks.

`pubspec.yaml` sets:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

Reason: `package:sqlite3` documentation states native builds can select SQLite3MultipleCiphers or SQLCipher through build-hook user defines, and SQLite3MultipleCiphers is the first provider named in the product design doc.

Reference:

- https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html

Important implementation note:

- SQLCipher can be detected with `pragma cipher_version`.
- SQLite3MultipleCiphers can be detected with `pragma cipher`.
- The spike accepts either detection path so the provider can be switched later without changing orchestration code.

## Local Automated Checks

Run date: 2026-08-14

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter pub get
```

Result:

- Passed.
- `pubspec.lock` generated.

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
```

Result:

- Passed.
- Output: `No issues found!`

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

Result:

- Passed.
- Output: `00:00 +9: All tests passed!`

Covered behaviors:

- 256-bit key generation.
- Stored key reuse.
- Existing database with missing key does not generate a replacement key.
- Missing-key state maps to a safe spike status.
- Provider failure maps to a safe spike status without sensitive details.
- SQLite3MultipleCiphers provider creates, reopens, reads, and rejects wrong-key access on the host test runtime.
- App shell widget renders expected title.

## Host Plaintext Probe

Run date: 2026-08-14

Command:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true dart run tool/encrypted_database_spike_probe.dart build/verification/networthy_spike_probe.db
```

Result:

- Passed.
- Output: `Encrypted database probe completed.`

Plaintext search command:

```bash
find build/verification -maxdepth 1 -type f -name 'networthy_spike_probe.db*' -print -exec sh -c 'strings "$1" | grep -F "NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG" >/dev/null && echo "PLAINTEXT_FOUND $1" || echo "NO_PLAINTEXT $1"' sh {} \;
```

Result:

```text
build/verification/networthy_spike_probe.db
NO_PLAINTEXT build/verification/networthy_spike_probe.db
```

Limitation:

- This verifies the host test/runtime database only.
- It does not replace iOS/Android app-container inspection.

## Android Build Check

Run date: 2026-08-14

Command:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --debug
```

Result:

- Passed.
- Output: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

Limitation:

- Build success confirms Android native integration compiles.
- It does not prove runtime encrypted database behavior on an Android emulator/device.

## iOS Runtime Verification

Device discovered:

```text
iPhone 17 Pro (mobile) • 23565751-3D6D-495E-8177-418BEB788C45 • ios • iOS simulator
```

Runtime command:

```bash
env -u GEM_HOME -u GEM_PATH FLUTTER_SUPPRESS_ANALYTICS=true flutter run -d 23565751-3D6D-495E-8177-418BEB788C45
```

Result:

- Passed.
- `pod install` completed.
- Xcode build completed.
- App launched on iPhone 17 Pro simulator.

Runtime output:

```text
Launching lib/main.dart on iPhone 17 Pro in debug mode...
Running pod install...                                             766ms
Running Xcode build...
Xcode build done.                                           23.4s
Syncing files to device iPhone 17 Pro...                            68ms
```

Runtime output did not include the database key, marker text, SQL bind values, notes, amounts, or full database path.

Environment note:

- CocoaPods was installed but the shell `GEM_HOME`/`GEM_PATH` pointed at older Ruby 3.3 gem directories. The iOS run used `env -u GEM_HOME -u GEM_PATH` so Homebrew CocoaPods 1.17.0 could run with its own bundled gem environment.

Plaintext inspection:

Container lookup command:

```bash
xcrun simctl get_app_container 23565751-3D6D-495E-8177-418BEB788C45 com.example.networthy data
```

Result:

```text
/Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A
```

File listing found:

```text
Documents/networthy.db
Documents/networthy_spike.db
```

No `networthy_spike.db-wal` or `networthy_spike.db-journal` sidecar files were listed.

Plaintext search command:

```bash
find /Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A/Documents -maxdepth 1 -type f -name 'networthy*.db*' -print -exec sh -c 'strings "$1" | grep -F "NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG" >/dev/null && echo "PLAINTEXT_FOUND $1" || echo "NO_PLAINTEXT $1"' sh {} \;
```

Result:

```text
/Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A/Documents/networthy.db
NO_PLAINTEXT /Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A/Documents/networthy.db
/Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A/Documents/networthy_spike.db
NO_PLAINTEXT /Users/erinli/Library/Developer/CoreSimulator/Devices/23565751-3D6D-495E-8177-418BEB788C45/data/Containers/Data/Application/FF323568-F233-4681-960B-BCC6B44BF22A/Documents/networthy_spike.db
```

Marker searched:

```text
NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG
```

## Android Runtime Verification

Available emulator:

```text
Medium_Phone_API_36.1 • Medium Phone API 36.1 • Generic • android
```

Launch command:

```bash
/Users/erinli/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 -no-window -no-audio -no-snapshot
```

Result:

- Passed.
- Emulator booted successfully.

Device check:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter devices
```

Result:

```text
sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64 • Android 16 (API 36) (emulator)
```

Runtime command:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter run -d emulator-5554
```

Result:

- Passed.
- App built, installed, launched, and created `app_flutter/networthy_spike.db`.
- Runtime output did not include the database key, marker text, SQL bind values, notes, amounts, or full database path.

Plaintext inspection:

File listing command:

```bash
/Users/erinli/Library/Android/sdk/platform-tools/adb exec-out run-as com.example.networthy find . -maxdepth 4 -type f
```

Relevant result:

```text
./app_flutter/networthy_spike.db
```

No `networthy_spike.db-wal` or `networthy_spike.db-journal` sidecar files were listed.

Extraction command:

```bash
/Users/erinli/Library/Android/sdk/platform-tools/adb exec-out run-as com.example.networthy cat app_flutter/networthy_spike.db > build/verification/android-networthy_spike.db
```

Plaintext search command:

```bash
strings build/verification/android-networthy_spike.db | grep -F 'NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG'
```

Result:

- Passed.
- `grep` exited with code 1, meaning the marker was not found.

Marker searched:

```text
NETWORTHY_ENCRYPTION_SPIKE_MARKER_DO_NOT_LOG
```
