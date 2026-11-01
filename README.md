# UMZ Self

Unofficial Flutter client (Windows + Android) for the UMZ food reservation
system at <https://self.umz.ac.ir>. Reverse-engineering notes are in
[NOTES.md](NOTES.md).

Status: v0.1 — login, balance, week menu, reserve. Cancel, reserved list,
auto-reserve and stats are not built yet.

## Layout

- `lib/src/api/` – pure-Dart API client and models (no Flutter imports)
- `lib/src/state/`, `lib/src/ui/` – app state and screens (Persian + English)
- `lib/src/storage/` – saved logins in the OS secure store
- `test/` – unit tests; the login flow runs against a scripted fake server
- `bin/check.dart` – read-only live check from the command line

## CI

`.github/workflows/build.yml` analyzes and tests, then builds a Windows
release folder and an Android APK. Download them from the run's Artifacts.
Platform folders (`android/`, `windows/`) are generated in CI with
`flutter create`, so they are not committed yet.

## Local use (with Flutter installed)

```bash
flutter pub get
flutter test
flutter create --platforms=windows,android --org ir.umz --project-name umz_self .
flutter run -d windows
```

Read-only live check (never reserves anything):

```bash
UMZ_USER=... UMZ_PASS=... dart run bin/check.dart
```

## Security

Passwords are only ever stored in the OS secure store (Windows DPAPI /
Android Keystore). Never commit `.env`; it is git-ignored.
