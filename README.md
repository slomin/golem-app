# Golem — Offline LLM Chat (MVP)

**Fast offline LLM chat. Runs fully on your device.**

Golem is a **privacy‑first chat app** for **Android & iOS**. It runs **entirely on‑device** (no accounts, no cloud calls), built with **Flutter**.

## Why

* **Private by default:** your text never leaves the phone.
* **Truly offline:** works in airplane mode.
* **Cross‑platform:** one codebase, Android + iOS.

## Build (dev)

```bash
# Prereqs: Flutter installed, device/simulator available
flutter pub get
# Android
aflutter run -d android
# iOS (on macOS with Xcode)
flutter run -d ios
```

## Tests

Run the full test suite locally with:

```bash
flutter test
```

CI runs the same command on pushes to `main`, `develop`, and any `release/*` branch and on pull requests targeting those branches (see `.github/workflows/flutter-tests.yml`). You can also trigger a manual run via the "Flutter Tests" workflow dispatch in GitHub.

## Status

Early MVP. Expect rough edges; performance and UX are WIP.

## Links

* Website: [https://golem.app](https://golem.app)
* Issues: use GitHub to file bugs/feature requests.

## License

Mozilla Public License 2.0
