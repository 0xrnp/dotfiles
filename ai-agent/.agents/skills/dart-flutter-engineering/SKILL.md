---
name: dart-flutter-engineering
description: Implement and review Dart or Flutter using the repository's SDK, analyzer, architecture, state management, platform, and code-generation conventions. Use outside ASBL Homes projects.
---

# Dart and Flutter engineering

Read `pubspec.yaml`, SDK constraints, `analysis_options.yaml`, routing,
dependency injection, state management, and neighboring features before
choosing a pattern.

## Dart

- Preserve sound null safety. Do not cast away nullable values or use `!`
  without a proved invariant.
- Prefer immutable values and exhaustive sealed or enum handling when the
  repository supports them.
- Keep async errors visible and preserve `Future` and `Stream` cancellation,
  subscription, and cleanup behavior.
- Use typed parsing at external boundaries. Do not pass dynamic maps through
  domain code when an existing model fits.
- Follow the repository's effective Dart and analyzer configuration rather than
  imposing a global line length or lint set.

## Flutter

- Match the app's state-management, navigation, dependency-injection, network,
  localization, theming, and feature-folder patterns.
- Keep business behavior out of widgets when the repository has a domain or
  state layer. Do not invent that layer in a simple app.
- Guard `BuildContext` use across async gaps and respect widget lifecycle,
  disposal, focus, controllers, and subscriptions.
- Consider loading, empty, error, retry, accessibility, text scaling, and
  platform behavior when the changed UI path needs them.
- Use existing platform channels and plugins. Check Android and iOS code only
  when the change crosses that boundary.

## Generated code and dependencies

Never hand-edit generated files. Use the repository's generator command and
inspect generated diffs. Do not add a package, router, state library, or
architecture layer when the project already has an answer.

## Verify

Run formatting and analysis on touched code, focused tests where they exist,
and code generation when inputs changed. Do not claim a device or platform run
that was not performed.
