# AGENTS.md

## Cursor Cloud specific instructions

### Product

**轻松血压 (bp_companion)** is a privacy-first Flutter mobile/web app for blood pressure tracking. All data is stored locally via `shared_preferences`; there is no backend, database, or Docker stack.

### Flutter SDK

Flutter stable is installed at `$HOME/flutter` and added to `PATH` in `~/.bashrc`. If `flutter` is not found, use `$HOME/flutter/bin/flutter` directly.

### Common commands (run from repo root)

| Task | Command |
|---|---|
| Install deps | `flutter pub get` |
| Lint / analyze | `flutter analyze` |
| Tests | `flutter test` |
| Run (Web) | `flutter run -d chrome --web-port=8080 --web-browser-flag=--no-sandbox` |
| Run (Linux desktop) | `flutter run -d linux` |

See `README.md` for iOS/Android targets (require macOS / Android SDK respectively).

### Platform notes

- **Web (Chrome)** is the preferred target in this Linux cloud VM. Use `--web-browser-flag=--no-sandbox` because Chrome runs inside a container.
- **Linux desktop** works after `ninja-build` and `libgtk-3-dev` are installed (already present in the VM image).
- **Android SDK** is not installed; `flutter doctor` will report Android toolchain as missing. This does not block Web/Linux development or `flutter test`.
- **No services to start** — the app is fully offline after `flutter pub get`.

### Demo / smoke flow

To verify the app end-to-end: open the home dashboard → tap the FAB (+) to add a record → enter systolic/diastolic/pulse → save → confirm the reading appears on the Records (记录) tab.

Optional: `--dart-define=INITIAL_TAB=2` jumps directly to the Stats tab for demos.
