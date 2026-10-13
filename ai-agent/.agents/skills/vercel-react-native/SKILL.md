---
name: vercel-react-native
description: Vercel's React Native and Expo performance patterns. Use automatically when writing or reviewing React Native components, lists, scroll, Reanimated animations, gestures, or navigation. Distilled from vercel-labs/agent-skills vercel-react-native-skills 1.0.0 (MIT).
paths: "**/*.{tsx,jsx},**/app.json,**/app.config.*,**/metro.config.*"
---

# Vercel React Native

Distilled from `vercel-react-native-skills` 1.0.0 (MIT, January 2026):
https://github.com/vercel-labs/agent-skills/tree/e23951b8/skills/react-native-skills

Not a copy of that skill. Their full write-up with examples is `AGENTS.md`
there. Read it when a rule below is too terse for the change.

**Order when advice conflicts:** this repo's rules and installed libraries,
then `meta-react-native` (compiler and frames), then this skill. Do not add a
package to satisfy a rule. Skip any rule whose library is not in
`package.json`.

If `experiments.reactCompiler` is on, skip the manual `memo` / `useCallback` /
`useMemo` steps. The compiler does them. The crash rules and the UI-thread
rules still apply.

## Crashes (do these always)

- Never `{value && <Node/>}` when `value` can be `0` or `""`. React Native
  renders that falsy value as text and crashes. Use a ternary, `!!value`, or
  an early return. `react/jsx-no-leaked-render` catches it.
- A string is a child of `Text`, never of `View`.

## Lists

Use the virtualized list already installed (`FlatList`, `SectionList`, or a
list library in `package.json`). `.map()` is for short, bounded, constant
arrays.

- Pass the item, or primitive fields, into the row. Do not build a fresh
  object or style object inside `renderItem`.
- One callback for the list, defined at the list root. The row calls it with
  its id. Do not close over `item` inside `renderItem`.
- A row renders props. It does not fetch, subscribe to a wide context, or run
  an expensive computation. Precompute in the parent.
- Do not `.map()` or `.filter()` the list `data` on each parent render if the
  result is a new array of new objects. Virtualizers use reference identity.
  Memoize that derived array, or keep the source array stable.
- Stable ids for keys, not the index, when rows can move.
- Heterogeneous rows: give each kind a type and a renderer, instead of one
  row full of conditionals.
- Images in a row are sized for the row, not the source file's full
  resolution.

## Scroll and animation

- Do not put scroll offset in `useState`. Use a Reanimated shared value for
  anything animated from scroll, or a ref when nothing needs to re-render.
- Animate `transform` and `opacity`. Animating width, height, margin, or top
  forces layout. Collapse with scale and opacity, not height.
- Derive a shared value with `useDerivedValue`. `useAnimatedReaction` is for
  a side effect (haptics, `runOnJS`), not for computing the next value.
- Press feedback that animates (scale, opacity) goes through
  `GestureDetector` when gesture-handler is installed, so the animation stays
  on the UI thread. Store pressed as `0` or `1` and derive the scale. Call JS
  with `runOnJS`.
- With the compiler on, read and write shared values with `.get()` and
  `.set()`, not `.value`.

## State

- State is the source of truth, not a copy of props or of other state. Derive
  the rest during render.
- When the next value depends on the current one, use the dispatch updater
  form (`setCount(c => c + 1)`).

## UI, only when it matches this repo

- `Pressable` over `TouchableOpacity` / `TouchableHighlight` for new code.
- Dynamic header or footer space on a `ScrollView` uses `contentInset`, not a
  spacer view that changes layout. Safe area on iOS scroll views uses
  `contentInsetAdjustmentBehavior` when the screen does not already pad
  insets itself.
- Measure a view with `onLayout`. Do not guess with `Dimensions` for something
  that depends on layout.
- Create `Intl` formatters once at module scope, not inside render.
- Load fonts with the repo's existing font setup (in Homes, forge tokens).
  Do not add `expo-font` loading at runtime if fonts are already native.

## Do not import from this skill

Vercel also recommends `expo-image`, Galeria, native menus, native modals
instead of JS sheets, LegendList, and a local design-system barrel. Use those
only when this repo already does. In `homes-ecosystem`, UI is `@asbl/forge`,
sheets are forge's, and a missing component is an upstream request.
