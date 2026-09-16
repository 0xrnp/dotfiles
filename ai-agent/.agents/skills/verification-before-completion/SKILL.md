---
name: verification-before-completion
description: >-
  Require runnable evidence before claiming done. Use before finishing
  non-trivial implementation, bug fixes, or when about to say the work is
  complete.
---

# Verification before completion

Do not claim done on "looks right." Pair with `self-review` for diff quality;
this skill is about evidence.

## When not to use

- Pure questions or read-only review with no code change.
- Trivial one-line edits where the repo has no meaningful check.

## Before saying done

1. Re-state the success criteria from the request.
2. Run the narrowest meaningful verification (test, typecheck, lint, script,
   or manual reproduction). Broaden only as shared risk requires.
3. Confirm the original failure or acceptance path passes.
4. Report commands actually run and their outcomes. Say what was skipped and
   why.

Choose checks that can refute the change: negative authorization cases,
boundaries, duplicate requests, cancellation, or concurrent updates when
relevant. A test that reproduces the implementation's algorithm is weak evidence.
For bug fixes, verify the regression fails on the prior behavior when practical.
Use a focused fixture or reproduction if there is no suitable test harness;
explain the remaining gap instead of claiming compilation proves correctness.

## Red flags

- "Should work" without a command or reproduction.
- Relying only on compilation when behavior changed.
- Skipping the failing test that motivated the fix.

## Report

List checks run, results, skipped checks, and residual risks.
