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
