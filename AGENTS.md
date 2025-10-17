# Repository Guidelines

## Preferred Development Flow (TDD)
- Start by writing a focused test that expresses the desired behaviour; it should fail because the feature is not implemented yet.
- Run `flutter test` immediately to confirm the failure and capture compiler/runtime errors before writing production code.
- Implement the minimal code to satisfy the test, rerun `flutter test`, and repeat until the suite is green.
- Keep this loop tight: modify tests → run → code → run. Do not rely on reviewers to execute tests for you.
- When tests require time to stream results (e.g., fake LLM), lower `tokenDelay` inside the test to keep cycles fast.
- If the suite fails to compile, create the minimal scaffolding first; re-run tests until they fail on assertions instead of import errors, then continue iterating.
- Use Mobile MCP for UI validation on Android emulators and iOS simulators: `mobile_list_available_devices` → pick the active device → drive interactions with `mobile_list_elements_on_screen`, `mobile_click_on_screen_at_coordinates`, `mobile_swipe_on_screen`, or `mobile_type_keys`; keep the existing `flutter run` session open, watch host logs (paragraph ids, slider readings), and only rebuild if the app is no longer running.
- Debug iOS builds launched via `flutter run` cannot be started from Spotlight or the home screen—always keep the original `flutter run` session alive while using Mobile MCP.
- When driving the UI with Mobile MCP, prefer elements surfaced via Flutter semantics/`ValueKey`s (use `mobile_list_elements_on_screen` to locate them) instead of hard-coded coordinates; only fall back to raw coordinates if no semantic identifier is available.
- Apple Foundation Model work stays iOS-only: write/override tests so they keep using `FakeLlmRepository`, and validate the native bridge manually on real hardware (or the provided simulator) before shipping.
- Before claiming the task is complete, run platform builds; iOS today via `flutter build ios --no-codesign` (Android instructions TBD once implemented).

## Project Structure & Module Organization
- `lib/` holds Flutter application code (`main.dart` currently drives the sample counter UI).
- `lib/data/apple_foundation_flutter_repository.dart` hosts the Apple Intelligence bridge that implements `LlmRepository`; the fake repository remains in `lib/data/fake_llm_repository.dart`.
- Apple Intelligence integration uses the `apple_foundation_flutter` plugin; native glue lives in the dependency, so the Runner target no longer maintains a custom method channel.
- We vendor the plugin under `packages/apple_foundation_flutter`; make changes there (not in `.pub-cache`) and keep `pubspec.yaml` pointing at the path dependency.
- `assets/` contains static resources such as icons; update `pubspec.yaml` when adding new assets.
- Mock LLM content for the fake repository lives under `assets/mock_data/llm/`; keep JSON there and remember to register new files in `pubspec.yaml`.
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
- When tests rely on assets or data sources, provide overrides/mocks (see `_StubDataSource` in `test/unit/llm_providers_test.dart`) so suites stay fast and deterministic.
- For Apple Foundation Model features, override `appleFoundationModelRepositoryProvider` with a fake implementation in tests to avoid real device dependencies. Leave hardware validation to manual MCP/phys-device loops.
- After coding + test iterations, run `dart format` on touched Dart files before wrapping up; this keeps diffs clean and satisfies analyzer/lint rules.

## CI Workflow
- GitHub Actions runs `flutter test` automatically on pushes to `develop`, `main`, and `release/*`, and on pull requests targeting those branches.
- Manual reruns: open GitHub → Actions → “Flutter Tests” → “Run workflow”, then pick a branch.
- CI caching (`flutter-action` cache + pub cache) keeps subsequent runs faster; expect the first run per branch to take longer.

## Commit & Pull Request Guidelines
- Write concise commit messages in imperative mood (e.g., `Add chat input widget`). Squash commits before merging when possible.
- Pull requests should target `develop` unless you are preparing a hotfix (`main`) or release (`release/<version>`).
- Include a summary, testing notes, and screenshots for UI changes. Link related issues and mark PRs as drafts while work is in progress.
