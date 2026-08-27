---
name: react-native
description: React Native and Expo working rules. Use when the repo is (or will be) RN/Expo — app.json, expo, react-native, metro, eas, React Navigation, native modules. Do not invent APIs; read this project's versions and current official docs.
paths: "**/*.{tsx,jsx},**/app.json,**/app.config.*,**/metro.config.*,**/eas.json,**/react-native.config.js"
---

# React Native

There is no Homes RN app yet. Do not copy Flutter (`homes-flutter`) or Angular into RN. Do not invent a stack.

**Order is mandatory.** Memory of RN/Expo APIs is untrusted.

## 1. Detect

| Signal | Treat as |
|---|---|
| `expo` in `package.json` / `app.json` / `app.config.*` | Expo (managed or prebuild) |
| `react-native` without `expo` | RN CLI / bare |
| Neither, and Rudra asked to start an app | Greenfield — ask Expo vs bare if unclear. Then use **today's** official template (`create-expo-app` or current RN docs). Do not pick an SDK number from this file. |
| Neither, and this is a question | Answer. Do not scaffold. |

If `package.json` and this skill disagree, `package.json` wins.

## 2. Versions and docs

Read exact `expo`, `react-native`, `react`, navigation, and related versions from **this** `package.json`.

Then read current official docs **for those versions** (not a blog, not training data):

- Expo: https://docs.expo.dev
- RN: https://reactnative.dev/docs/getting-started
- If Expo: `npx expo-doctor` / install guidance on that docs site for that SDK

Do not use APIs, config keys, or CLI flags you did not see there or in this repo this session.

## 3. Match this repo

Copy neighbors: folders, state, styling, lists, navigation, TypeScript strictness.

Do **not** add Redux, Zustand, NativeWind, Tamagui, FlashList, Reanimated, etc. unless already in `package.json` or Rudra asked.

Do **not** introduce Flutter clean-arch / BLoC / GetIt unless this RN tree already uses that shape.

`any` is the enemy. Use existing types. Do not cast away nulls.

## 4. Nearby topics (checks, not APIs)

Only apply a row if this project already has that tool, or Rudra asked for it. Look up the **installed** docs; do not recall APIs.

| Area | Do |
|---|---|
| Expo config | Change `app.json` / `app.config` the way this app already does. Config plugins: follow Expo docs for this SDK. |
| Prebuild / native dirs | If `ios/` `android/` are generated, say so before editing them. Prefer Expo config + plugin over hand-editing native when the app is prebuild-based. |
| EAS | Follow this repo's `eas.json`. Do not submit a store build unless asked. |
| Navigation | Use the library already imported (often React Navigation). Do not add a second navigator. |
| Platform files | `*.ios.tsx` / `*.android.tsx` when neighbors do. |
| Lists / gestures | `FlatList`/`SectionList` unless a list library is already a dependency. Reanimated/Gesture Handler: only if already depended on. |
| Native modules | New Architecture: whatever **this** RN/Expo version requires (read that version's docs). Don't toggle `newArchEnabled` from memory. Don't write a native module if an Expo/RN API in the project already covers it. |
| Env / secrets | Same as Homes: no secrets in source. No prod channels unless asked. |

## 5. Verify

- Typecheck/lint this repo already uses (`tsc`, `expo lint`, ESLint). Quote the command.
- Do not claim a simulator/device run you did not do.
- Before "done" on non-trivial work: `self-review`.

## Don't

- Upgrade Expo/RN "while here".
- Mix old bridge tutorials with a New Architecture app (or the reverse) without reading this version's docs.
- Ship a guessed approach because RN is unfamiliar. Say you need the docs or a template, and wait.
