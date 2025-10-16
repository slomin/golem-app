# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds Flutter application code (`main.dart` currently drives the sample counter UI).
- `assets/` contains static resources such as icons; update `pubspec.yaml` when adding new assets.
- `test/` stores widget and future unit/integration tests; use subfolders (`widget/`, `unit/`, etc.) for clarity.
- Platform scaffolding lives under `android/` and `ios/`; edit cautiously unless you are working on platform-specific features.

## Build, Test, and Development Commands
- `flutter pub get` installs or updates Dart/Flutter dependencies.
- `flutter run -d <device>` launches the app on a connected device or simulator (e.g., `flutter run -d ios`).
- `flutter test` executes all unit and widget tests; run before opening or updating a pull request.

## Coding Style & Naming Conventions
- Follow Dart’s official style: 2-space indentation, lowerCamelCase for variables/functions, UpperCamelCase for classes.
- Use the analyzer rules enforced by `analysis_options.yaml` and `flutter_lints`. Run `dart format <file>` when needed.
- Group related widgets and logic into files under `lib/` using feature-based folders as the app grows.

## Testing Guidelines
- Tests use the Flutter testing framework (`flutter_test`). Add pure Dart unit tests under `test/unit/` and widget tests under `test/widget/`.
- Name test files with `_test.dart` suffix and keep individual test descriptions clear (e.g., `"ChatInput sends message"`).
- Ensure `flutter test` passes locally; add targeted tests for new features, bug fixes, and regressions.
- Run `flutter test` locally before pushing; this mirrors the CI command.
- Work iteratively: after each meaningful change, run the relevant tests yourself before requesting reviews or handing off.

## CI Workflow
- GitHub Actions runs `flutter test` automatically on pushes to `develop`, `main`, and `release/*`, and on pull requests targeting those branches.
- Manual reruns: open GitHub → Actions → “Flutter Tests” → “Run workflow”, then pick a branch.
- CI caching (`flutter-action` cache + pub cache) keeps subsequent runs faster; expect the first run per branch to take longer.

## Commit & Pull Request Guidelines
- Write concise commit messages in imperative mood (e.g., `Add chat input widget`). Squash commits before merging when possible.
- Pull requests should target `develop` unless you are preparing a hotfix (`main`) or release (`release/<version>`).
- Include a summary, testing notes, and screenshots for UI changes. Link related issues and mark PRs as drafts while work is in progress.
