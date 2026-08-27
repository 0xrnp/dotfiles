---
name: homes-flutter
description: Flutter/Dart conventions for ASBL Homes apps (manage, resident, security) and homes_shared / homes_chat. Use when editing Dart, pubspec, BLoC, use cases, models, widgets, or codegen.
paths: "**/*.dart,**/pubspec.yaml,**/analysis_options.yaml"
---

# Homes Flutter

Match **this app**. Do not invent Riverpod, GetX, a new layer, or a new folder shape.

## App map

| Repo | Feature root | Notes |
|---|---|---|
| `manage-mobile-app` | `lib/features/<feature>/{data,domain,presentation}` | snake_case features; `lib/gen/` for `*.g.dart` |
| `resident-mobile-app` | `lib/features/<feature>/...` | Same shape as manage |
| `sec-mobile-app` | `lib/src/features/<feature>/...` | kebab-case folders; more Freezed |
| `homes-shared-package` | `lib/src/` | `UseCase`, `Failure`, shared widgets. Change here if 2+ apps need it |
| `homes-chat-package` | package code | Chat only |

Copy neighbors in the same app. Do not copy manage layout into sec.

## Layers

```
presentation  Bloc/Cubit, screens, widgets. No Dio. No *Model.
domain        Entity (Equatable, no json), repository interface, UseCase
data          *Model, datasource, repository impl. toEntity() at repo only
```

- Use cases extend `UseCase<T, Params>` from `homes_shared`. Return `Future<Either<Failure, T>>`.
- Repos: `@LazySingleton(as: XRepository)`. Blocs/use cases: `@injectable`.
- Register like existing features. Run build_runner if `injection.config.dart` must change. Never hand-edit `*.config.dart`.

## Models

**New or rewritten files:** composition, not inheritance.

- Entity: plain `Equatable`. No `json_annotation`, no `toJson`.
- Model: standalone class, API shape, `@JsonSerializable`. `implements EntityMappable<XEntity>` from `homes_shared`. `toEntity()`.
- Only repositories call `toEntity()`. Use cases, blocs, widgets see entities only.

**Existing files** that `extends XEntity`: leave them unless this task already rewrites that file.

Do not hand-edit `*.g.dart`, `*.freezed.dart`, `*.gen.dart`. After model/Freezed changes: `dart run build_runner build --delete-conflicting-outputs` (or the app's existing script).

## Network and errors

- Dio through the app's existing network wrapper. Endpoints live in `core/constants/endpoints.dart` (path varies per app).
- Parse `{success, message, data}` with existing `executeSafely` (manage) or the local equivalent.
- Map `NetworkExceptions` → `NetworkFailure`; unknown → `UnknownFailure`. Same `fold` in the bloc: error state vs `processData`.
- Do not swallow. Do not invent a new Failure type if one exists.

## BLoC

- `flutter_bloc` + `equatable` events/states. `copyWith`. Parts: `*_event.dart` / `*_state.dart` when neighbors use parts.
- List fetches: `bloc_concurrency` `restartable()` when the existing bloc does.
- `PagingEntity` + `loadingState` / `errorState` / `processData` when the feature already pages that way.
- No navigation/snackbars inside the bloc if the feature uses `BlocListener` in the widget. Match the feature.
- Do not put `BuildContext` use across `await` without `mounted` (analyzer error).

## UI

- `very_good_analysis`. `prefer_const` is an error. Relative imports. User-facing strings go through l10n ARB, not raw literals, when the screen already does.
- Widgets stay dumb. Logic in bloc/usecase.
- Extract a widget only when the file already splits that way (`*_btm_sheet`, `*_card`), not as a new abstraction layer.
- go_router: add to the existing routes file. Do not add a second router.

## Do not

- New dependencies. New state-management library. Bump `homes_shared` git ref unless asked.
- Touch SOS, CallKit, visitor gate, Razorpay, or Shorebird without naming it first (`AGENTS.md` and `blast-radius`).
- Claim a device/emulator run you did not do.

## Verify

- `dart analyze` on touched files (or the app's analyzer).
- Run existing tests only if this feature already has them. Manage has almost none; do not add a suite unless asked.
- If codegen changed, confirm generated files updated and were not edited by hand.
