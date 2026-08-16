# networthy

Offline-first Flutter bookkeeping app.

## Local development

Use suppressed Flutter analytics in this sandboxed environment:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
```

Drift schema code is generated. After changing files that declare Drift tables
or databases, regenerate checked-in generated code:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true dart run build_runner build
```

If CocoaPods is installed but fails because the shell points `GEM_HOME` or
`GEM_PATH` at stale Ruby gem directories, run iOS commands with those variables
removed:

```bash
env -u GEM_HOME -u GEM_PATH FLUTTER_SUPPRESS_ANALYTICS=true flutter run -d <ios-device-id>
```

## Release acceptance

Use these gates before treating a local build as release-accepted:

```bash
FLUTTER_SUPPRESS_ANALYTICS=true flutter test
FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze
FLUTTER_SUPPRESS_ANALYTICS=true flutter build apk --release
FLUTTER_SUPPRESS_ANALYTICS=true flutter build ios --simulator
```

The Android local acceptance APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The iOS simulator app bundle is
written to `build/ios/iphonesimulator/Runner.app`.

Store distribution is intentionally separate from local release acceptance
because it requires private signing credentials and store metadata that should
not be checked into this repository.
