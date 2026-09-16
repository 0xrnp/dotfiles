---
name: systematic-debugging
description: >-
  Find root causes before patching. Use when tests fail, builds break, runtime
  behavior is wrong, or a fix would otherwise chase symptoms.
---

# Systematic debugging

Use for failures and wrong behavior. Do not jump to a speculative patch.

Adapted from the Superpowers debugging workflow. Keep it short; repository
evidence outranks this skill.

## When not to use

- The failure is already localized to one known line with a failing check.
- The task is a clean feature with no bug report.

## Process

1. **Reproduce** - Get a reliable failing signal (command, test, log, UI step).
   If it cannot be reproduced, gather what differs (env, data, branch, timing).
2. **Localize** - Bisect to the smallest component, commit, or input that
   changes the outcome. Read nearby code and recent diffs.
3. **Root cause** - Name the underlying invariant that broke (wrong state,
   bad assumption, race, contract mismatch). Symptom-only explanations are not
   done.
4. **Fix** - Change the minimum code that restores the invariant.
5. **Guard** - Add or tighten the smallest check that would have caught this
   (test, assert, validation). Run the reproduction path again.

## Red flags

- "Just try this change" without a reproduction.
- Editing call sites while the callee contract is still unclear.
- Multiple unrelated fixes in one pass.
- Declaring success without re-running the failing signal.

## Report

State the reproduction, root cause, fix, guard, and what was re-run.
