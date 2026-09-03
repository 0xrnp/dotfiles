---
name: using-skill-guide
description: Routes work to the smallest relevant set of personal skills. Use before non-question work when no skill was named.
---

# Using skill guide

Read this first when Rudra did not name a skill and the request is not only a
question. Read repository instructions before personal skills.

Personal skills live in `~/.agents/skills/<name>/SKILL.md`. Project skills and
repository code remain authoritative.

## Route by task

| Situation | Read |
|---|---|
| Question-only request | Nothing. Answer without editing. |
| Rudra named a skill | That skill only |
| Existing behavior, shared code, or "what else breaks" | `blast-radius` |
| Stored shape, collection, table, field, index, or migration | `schema-design` |
| API, DTO, event, CLI, module, or public type contract | `contract-design` |
| New subsystem, cross-service flow, reliability, scale, or architecture | `system-design` |
| Mongo aggregation or list/dashboard query | `mongo-aggregations` |
| Rust, `.rs`, `Cargo.toml`, or toolchains | `rust-engineering` |
| Python, `.py`, `pyproject.toml`, FastAPI, or Pydantic | `python-engineering` |
| Terraform, HCL, state, providers, or modules | `terraform-engineering` |
| Dart or Flutter outside Homes | `dart-flutter-engineering` |
| JavaScript or TypeScript outside Homes | `js-ts-engineering` |
| React Native or Expo | `react-native` and `js-ts-engineering` |
| Homes Dart/Flutter apps and packages | `homes-flutter` and `homes-git` |
| Homes API, Angular, or Node lambdas | `homes-js-ts` and `homes-git` |
| Branch, worktree, or ticket in Homes | `homes-git` |
| Commit drafting, creation, or amend | `commit-authoring`; in Homes also `homes-git` |
| PR drafting, preview, creation, or update | `pr-authoring`; in Homes also `homes-git` |
| Review someone else's Bitbucket PR (read-only) | `pr-review`; stack/domain skills as needed |
| Review and post Bitbucket PR comments in one step | `pr-review-and-comment` |
| Post finalized Bitbucket PR comments after discussion | `add-pr-comments` |
| Docs, skill text, or other user-facing prose | `unslop` |
| Before finishing non-trivial or multi-file code | `self-review` |
| A repository has a narrower matching skill | That project skill |

Read multiple skills only when the task genuinely crosses concerns. A new
persisted API field may need `schema-design`, `contract-design`, and one
language skill. A one-line rename does not.

## Rules

- Read the current file. Do not recall an older version.
- Do not announce skill loading unless it changes a decision.
- Skills guide work. They do not authorize edits or external writes.
- Repo > skill > memory. Do not invent APIs or approaches.
- If no skill fits, use `~/ai-standards/AGENTS.md` and repository evidence.
- Before first mutate on an implement task, obey the **Checkout gate** in
  `~/ai-standards/AGENTS.md` (`WORKTREE` or `MAIN`). Homes path and ticket
  details stay in `homes-git`.
