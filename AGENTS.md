# AGENTS.md

## Must-follow constraints

- **Package name:** `neuroup` (not `eduplay`). All imports use `package:neuroup/...`. Binary name is `neuroup`.
- **App display name:** "Neuroup" everywhere — never "EduPlay". `core/env/env.dart` has `Env.appName = 'Neuroup'`.
- **Linux binary path:** `./build/linux/x64/debug/bundle/neuroup`. `flutter run -d linux` opens it.
- **Application ID:** `com.neuroup.app` (set in `linux/CMakeLists.txt` and `linux/runner/my_application.cc`). Do not change to `com.eduplay.eduplay`.

## Validation before finishing

Run in order — each must pass with zero output for error case:

```bash
dart analyze                          # must show 0 errors
flutter test                          # 21+ tests must pass
flutter build linux --debug           # produces ./build/linux/x64/debug/bundle/neuroup
```

If only changing widget code, `dart analyze` + `flutter build linux --debug` is sufficient.

## Demo mode vs Firebase mode

- `Env.firebaseConfigured` (in `core/env/env.dart`) gates all Firebase access.
- When `false` (default), every feature uses an in-memory repository:
  - News → `InMemoryNewsRepository` (`features/news/data/in_memory_reels_repository.dart`)
  - Chat/Support → `_InMemorySupportChatRepository` (`features/chat/presentation/providers/chat_providers.dart`)
  - Reels → `InMemoryReelsRepository` (`features/reels/data/in_memory_reels_repository.dart`)
  - Learning progress → `LearningProgressNotifier` (`features/learning/presentation/providers/learning_providers.dart`)
- Adding a new Firebase-backed feature requires both a `*RepositoryImpl` (Firestore) AND a `*InMemoryRepository` fallback in the provider. Do not skip the in-memory variant.

## Yellow-black overflow stripes in debug mode

The `RenderFlex overflowed by N pixels` warnings (yellow-black diagonal stripes) are intentionally suppressed in `app/bootstrap.dart` via `FlutterError.onError`. **Do not remove this filter** — it hides non-critical 1-3px rounding errors only. Real overflows ≥4px still log. If you see `overflowed by 4+ pixels`, fix it.

## Print output filter

`bootstrap.dart` monkey-patches `debugPrint` to suppress Firebase Linux noise: `core/no-app`, `has been created`, `Call Firebase.initializeApp()`. Keep this filter.

## TextEditor expansion rule

`TextField` with `expands: true` MUST NOT have `minLines` or `maxLines`. Use only `expands: true` (fixed, see `node_editor_page.dart:315`). Asserts fail at runtime if violated.

## Mock uygulamayı gerçeğe çevirirken

`core/providers/core_providers.dart` provides `FirebaseAuth`, `Firestore`, `Storage`, `Messaging` instances. In demo mode these are never accessed because `Env.firebaseConfigured == false` causes feature providers to swap in `InMemory*` variants. **Production transition requires only**: add `google-services.json` + `firebase_options.dart` + set `Env.firebaseConfigured = true` via `--dart-define`.

## Important locations (non-obvious)

- **`lib/app/bootstrap.dart`** — Firebase init, Sentry init, error handlers, print filter. All app-level concerns.
- **`lib/app/pages/demo_landing_page.dart`** — Landing page shown when `!Env.firebaseConfigured`. The app does **not** auto-navigate here on launch; the router sets `initialLocation` to `/demo` in that case (see `app_router.dart`).
- **`lib/shared/models/user_level.dart`** — Level/tier/badge system (Bronze/Silver/Gold/Diamond/Master). Used by `features/profile` and `features/learning`.
- **`lib/features/learning/presentation/pages/island_map_page.dart`** — Fancade-style snake-path map. Lesson nodes use `_SnakePathPainter` for curved connecting lines.

## Change-safety rules

- **Never change the package name** `neuroup` without a coordinated rename across all files (`pubspec.yaml`, `linux/CMakeLists.txt`, `linux/runner/`, all `package:` imports, all `com.neuroup.app` references).
- **Sealed classes** (`Failure`, `Result<T>`, `Lesson`, `MapNode`) — adding a new subclass requires updating all `switch` expressions that match them (the compiler enforces exhaustiveness).
- **Test mocking:** use `mocktail` for repos, `fake_cloud_firestore` for Firestore-backed tests. New tests should follow the pattern in `test/features/auth/auth_controller_test.dart`.
- **In-memory repos are mutable.** `InMemoryNewsRepository`, `InMemoryReelsRepository`, `_InMemorySupportChatRepository` hold state in `List`/stream. Tests that depend on clean state must construct a fresh repo per test.

## Known gotchas

- **`MediaQuery.textScalerOf(context).scale(...)`** is the way to scale font sizes by screen size. Do not wrap with custom scale factors inside widgets — let `MaterialApp.builder`'s `MediaQuery` wrapper handle it.
- **Riverpod `StateNotifierProvider.family`** — the family function must return a `StateNotifier`, not a value. See `features/learning/presentation/providers/quiz_session_controller.dart`.
- **Flutter Linux build can hit JVM/kapt issues** — this project uses Flutter-only deps; do not add `google_maps_flutter` or other plugins that require Android-side initialization.
- **`flutter pub upgrade`** can break pinned versions in `pubspec.yaml`. After upgrade, run `flutter test` before committing.
- **The `analysis_options.yaml`** extends `very_good_analysis`. Adding new lints requires testing on the full codebase — many strict rules will fail at first.

## Don'ts

- Do not add `package:eduplay/` imports anywhere — package name is `neuroup`.
- Do not hardcode `http://localhost` or any non-Firebase URL without confirming it routes through `Env.apiBaseUrl`.
- Do not commit `google-services.json` or `GoogleService-Info.plist` — they are gitignored. Use Firebase Console + `flutterfire configure` for local dev.
- Do not remove the `demo` route from `app_router.dart` even after Firebase is wired — it remains useful for previews and offline runs.
