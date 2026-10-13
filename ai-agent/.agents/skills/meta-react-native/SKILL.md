---
name: meta-react-native
description: Meta's React and React Native performance model. Use automatically when writing or reviewing React Native or Expo UI, lists, animations, effects, or re-renders. Covers the frame budget, the Rules of React, and the React Compiler.
paths: "**/*.{tsx,jsx},**/app.json,**/app.config.*,**/babel.config.*,**/metro.config.*"
---

# Meta React Native

How Meta expects React Native to be written, from their docs. This is not a
copy of those docs. Read the installed version's pages when a detail matters:

- https://reactnative.dev/docs/performance
- https://react.dev/reference/rules
- https://react.dev/learn/react-compiler/introduction
- https://docs.expo.dev/guides/react-compiler/

`react-native` owns detecting this repo. `vercel-react-native` owns concrete
list and animation patterns. Where this skill and that one disagree about
manual memoization, this one wins: follow the compiler. Where either disagrees
with the repo's rules or `package.json`, the repo wins.

Apply to code you write or change. Existing misses are findings, not a sweep.

## Frames

A frame is 16.67 ms at 60 fps. There are two rates, visible in the Dev Menu
Perf Monitor:

- **JS thread:** React, business logic, touch handling. A long render drops
  frames and freezes JS-driven animation and press feedback.
- **UI thread:** native scroll and native stack transitions keep moving while
  JS is busy. Prefer work that can stay here.

Dev mode and `console.log` (including from a dependency) tank the JS thread.
Judge performance on a release build on a device. A Metro session is not
evidence.

## Rules of React

The compiler only optimizes code that follows these. Breaking them is a bug
whether or not the compiler is on.

- Render and hooks are pure. Same inputs, same output. No mutation of props,
  state, or values passed into a hook.
- Derive during render. Do not copy props or server data into state and sync
  with an effect.
- An effect only subscribes to something outside React, and it cleans up.
- Hooks stay unconditional and top-level.
- Do not declare a component inside another component.

## React Compiler

Check this repo before assuming it is on: Expo uses
`experiments.reactCompiler` (SDK 54+ wires the Babel plugin). Do not flip that
flag, or the ESLint preset, unless Rudra asked. It is an app-config change.

- **On:** write plain components. Do not add `useMemo`, `useCallback`, or
  `memo` for speed. Keep a manual one only where identity is the behavior
  (a subscription or effect depends on that exact function). Leave existing
  manual memoization until you are changing that code and have checked it.
- **Off:** do not pretend the compiler will save a bad render. Follow
  `vercel-react-native` for the manual list and callback rules.
- Opt out of a file that the compiler cannot handle with the directive the
  current Expo docs name. Do not disable the compiler for the app.
- Enable the `eslint-plugin-react-hooks` recommended preset when Rudra asks.
  Its compiler rules (purity, refs, set-state-in-effect, set-state-in-render,
  static-components) catch the violations. Do not add the plugin yourself.

## What Meta still makes you do by hand

- Virtualize long lists. For `FlatList`, set `getItemLayout` when row height
  is fixed so it skips measurement.
- Do not do heavy JS in the same frame as a transition or a press. Defer with
  `requestIdleCallback` or `requestAnimationFrame`, or run the animation on
  the native driver.
- `Animated`: `useNativeDriver: true` unless you are animating something the
  installed version cannot drive natively. Read that version. React Native
  0.85's shared animation backend can drive layout props; confirm against the
  version in `package.json` before relying on it. If Reanimated is installed,
  use it instead of adding `Animated`.
- Animate an image's size with `transform: [{ scale }]`, not width and height.
  iOS re-crops the source bitmap on every layout change.
- `renderToHardwareTextureAndroid` / `shouldRasterizeIOS` only for a view that
  is moving and expensive to composite. Turn it off when the view stops, and
  only after measuring memory.
- Do not add FlashList, LegendList, or another list library from this skill.
  Use the list component already in `package.json`.
