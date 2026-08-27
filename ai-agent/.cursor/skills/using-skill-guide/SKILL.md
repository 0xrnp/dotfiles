---
name: using-skill-guide
description: Routes which personal skill to read. Use when no skill is named, when several skills might apply, or before starting work in Homes repos (Flutter, API, Angular, RN, git, tickets).
---

# Using skill guide

Read this first when Rudra did not name a skill **and the message is not a question**. Then read only the skills that apply. Do not load every skill.

Skills live in `~/.cursor/skills/<name>/SKILL.md`. Project `.cursor/skills` still win for that repo (homes-api-app already has its own).

## Pick

| Situation | Read |
|---|---|
| Question-only ("how hard", "should we", "is it possible", …) | Nothing. Answer. Do not edit. |
| Rudra named a skill | That skill's current `SKILL.md` only |
| `*.dart`, `pubspec.yaml`, manage/resident/sec apps, `homes_shared`, `homes_chat` | `homes-flutter` |
| `homes-api-app`, `*.ts`/`*.js` API, Angular `homes-web-app` | `homes-js-ts` |
| New or changed stored shape (models, collections, tables, fields, indexes, migrations) | `schema-design` |
| Updating an existing feature or shared entity; "what else breaks" | `blast-radius` |
| `.aggregate()`, `$lookup`, `$match` pipelines, list/dashboard Mongo queries | `mongo-aggregations` |
| Expo, `react-native`, `app.json` / `app.config`, Metro, EAS, RN screens | `react-native` |
| Branch, worktree, Linear ticket, commit, PR, pull from remote | `homes-git` |
| PR body, docs, new skill text, user-facing prose | `unslop` |
| About to claim done on non-trivial or multi-file code | `self-review` |
| Bug in a repo that has `debug-bug` / `implement-with-verification` | That **project** skill |

If two rows match, read both. If none match, follow `~/ai-standards/universal.md` + `identity.md` and ask.

## Rules

- Read the file. Do not recall an older version.
- After reading, do the work. Do not announce the skill list unless Rudra asked.
- Still plan → ask for approval (print the phrase list, primary `gooo`) → edit, unless this turn already has an approval phrase.
- Repo > skill > memory. Do not invent APIs or approaches.
