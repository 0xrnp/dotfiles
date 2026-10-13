---
name: react-native
description: React Native and Expo working rules and code quality bar. Use for app.json, Expo, React Native, Metro, EAS, Expo Router or React Navigation, native modules, and any RN component, hook, list, animation, or screen. Read project versions and current official docs.
paths: "**/*.{tsx,jsx},**/app.json,**/app.config.*,**/metro.config.*,**/eas.json,**/react-native.config.js"
---

# React Native

Detect the repository from its manifests. Read its package boundaries, scripts,
and local rules. Do not copy Flutter or Angular architecture into React Native,
or hard-code versions from this skill.

**Order is mandatory.** Memory of RN/Expo APIs is untrusted.

## 1. Detect

| Signal | Treat as |
|---|---|
| `expo` in `package.json` / `app.json` / `app.config.*` | Expo (managed or prebuild) |
| `react-native` without `expo` | RN CLI / bare |
| Neither, and Rudra asked to start an app | Greenfield. Ask Expo vs bare if unclear. Then use today's official template (`create-expo-app` or current RN docs). Do not pick an SDK number from this file. |
| Neither, and this is a question | Answer. Do not scaffold. |

If `package.json` and this skill disagree, `package.json` wins.

## 2. Versions and docs

Read exact `expo`, `react-native`, `react`, navigation, Reanimated, and list
library versions from **this** `package.json`.

Then read current official docs **for those versions** (not a blog, not training data):

- Expo: https://docs.expo.dev
- RN: https://reactnative.dev/docs/getting-started
- React: https://react.dev (effects, rendering, React Compiler)
- If Expo: `npx expo-doctor` / install guidance on that docs site for that SDK

Do not use APIs, config keys, or CLI flags you did not see there or in this repo this session.

## 3. Match this repo

Copy neighbors: folders, state, styling, lists, navigation, TypeScript strictness.

Do **not** add Redux, Zustand, NativeWind, Tamagui, FlashList, Reanimated, an image library, etc. unless already in `package.json` or Rudra asked.

Do **not** introduce Flutter clean-arch / BLoC / GetIt unless this RN tree already uses that shape.

`any` is the enemy. Use existing types. Do not cast away nulls.

**Homes `homes-ecosystem`:** its `.cursor/rules/` (`10-app`, `20-data`,
`25-session`) are authoritative and stricter: forge components and tokens,
layering, `strings.ts` copy, query keys, error taxonomy. This skill fills the
gaps they leave. Where they conflict, the repo wins.

## 4. Quality bar

Rendering, lists, animation, and the React Compiler are owned by
`meta-react-native` and `vercel-react-native`. Follow both. This section is
what they do not cover.

Apply to code you write or change. Existing misses are findings, not a sweep.

### Effects

- An effect synchronizes with something outside React: a subscription, a native
  API, a timer, an imperative view. Nothing else.
- Not an effect: derived data (compute it), responding to a user action (do it
  in the handler), resetting state when an id changes (use `key`), fetching
  server data (use the repo's data layer).
- No effect chains where one effect sets state that triggers another.
- Every subscription, listener, timer, and animation is cleaned up. In-flight
  requests are cancelled through the abort signal, not ignored after unmount.
- Respect Reduce Motion.

### Component shape

- One component, one job. Behavior lives in hooks; presentational pieces
  receive state and emit actions.
- Flag a component over about 300 lines or with more than 3 effects. Split it
  when the current task already changes it, not as a separate sweep.

### Startup

- No heavy work at module top level. Defer non-critical setup until after the
  first frame. Hold the splash until the first screen can render real state
  rather than flashing an empty one.

### Accessibility

- Custom pressables carry role, label, and state (disabled, selected,
  expanded).
- Touch targets reach 44 pt on iOS and 48 dp on Android, through size or
  `hitSlop`.
- Text survives the largest system font size: no fixed heights on text
  containers. Decorative images are hidden from screen readers.

### Platform

- Check behavior on both platforms where they differ (shadows vs elevation,
  keyboard, back button, safe areas). Use `*.ios.tsx` / `*.android.tsx` only
  when neighbors do.

## 5. Nearby topics (checks, not APIs)

Only apply a row if this project already has that tool, or Rudra asked for it. Look up the **installed** docs; do not recall APIs.

| Area | Do |
|---|---|
| Expo config | Change `app.json` / `app.config` the way this app already does. Config plugins: follow Expo docs for this SDK. |
| Prebuild / native dirs | If `ios/` `android/` are generated, say so before editing them. Prefer Expo config + plugin over hand-editing native when the app is prebuild-based. |
| EAS | Follow this repo's `eas.json`. Do not submit a store build unless asked. |
| Navigation | Use the router or navigator already imported. Do not add a second one. |
| Native modules | New Architecture: whatever **this** RN/Expo version requires (read that version's docs). Don't toggle `newArchEnabled` from memory. Don't write a native module if an Expo/RN API in the project already covers it. |
| Env / secrets | Same as Homes: no secrets in source. No prod channels unless asked. |

## 6. Measure

No performance claim without a before/after number.

- Re-renders: React DevTools Profiler, with "why did this render" on.
- Frame rate: the Perf Monitor (JS and UI FPS) during the interaction.
- JS hot paths: the Hermes sampling profiler.
- Measure on a release build on a physical device, preferably a low-end
  Android. A Metro dev session says nothing about shipped performance.

If you cannot run a device or release build, say so and list what Rudra
should measure.

## 7. Verify

- Typecheck/lint/tests this repo already uses (`tsc`, `expo lint`, ESLint, Jest). Quote the command.
- Walk section 4 against the diff before calling it done.
- Do not claim a simulator/device run you did not do.
- Before "done" on non-trivial work: `self-review`.

## Don't

- Upgrade Expo/RN "while here".
- Mix old bridge tutorials with a New Architecture app (or the reverse) without reading this version's docs.
- Add memoization, a list library, or an animation library on instinct. Measure or follow the repo.
- Ship a guessed approach because RN is unfamiliar. Say you need the docs or a template, and wait.
