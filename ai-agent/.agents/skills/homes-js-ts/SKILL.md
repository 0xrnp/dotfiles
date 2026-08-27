---
name: homes-js-ts
description: TypeScript/JavaScript conventions for ASBL Homes API (Node) and Angular web app. Use when editing homes-api-app, homes-web-app, lambdas, or any Homes JS/TS.
paths: "**/*.{ts,tsx,js,jsx},**/package.json,**/angular.json"
---

# Homes JS/TS

Match the repo you are in. API and Angular are different codebases. Do not copy Flutter patterns here. Do not add NgRx, a new ORM, or a new folder tree.

`any` is the enemy. Inferred types are the friend. Adapt to change at the boundary instead of rewriting every caller. Avoid one-line functions that only cast. Touch least code; match the file's style.

If this is `homes-api-app`, also follow that repo's `.cursor/skills` and `.cursor/rules` (tenant, verification, logging). They are the project source of truth.

## API (`homes-api-app`)

- Controllers thin. Business logic in `src/services/`. Models/enums/interfaces stay where the repo already puts them.
- Mobile vs web: `src/controllers/mobile` and `src/controllers/web` (and matching services). Do not mix.
- **Tenant:** non-public data is scoped by `project` (usually `req.headers.project`). Do not add a query or write that skips it.
- Auth/permission middleware stays on. Do not suggest bypasses.
- Errors: keep the existing status codes and body shape. No silent `catch` that returns success.
- Tests: Mocha, focused, next to the existing `test/` layout. Not endless smoke. High-risk (auth, payments, tenant) needs an explicit risk note if you cannot run tests.
- Do not add dependencies. Prefer stdlib + what is already in `package.json`.

## Angular (`homes-web-app`)

- Angular 19. Feature folders under `src/app/layouts/dashboard/modules/<area>/` with `components/`, `services/`, `models/` (`*.interface.ts`, `*.enum.ts`) as neighbors do.
- Services hold HTTP. Components stay presentational enough to match the module you are in.
- No NgRx. No new global store. RxJS as the module already uses it.
- Shared bits go in `src/app/shared/` only when two modules already share that way.
- Templates: match existing Material / dialog / table patterns. Do not restyle the design system.
- User-visible copy: match existing i18n/string style in that module. Do not invent a new i18n framework.

## Lambdas / small Node (`homes-razorpay-webhooks-lambda`, similar)

- Smallest change. Payments = blast radius: name it before touching.
- Keep the existing handler/error contract.

## Verify

- API: targeted Mocha or `lint:check` on touched files when that is what the task needs. Quote the command you ran.
- Web: targeted test or `ng`/existing script if the module has it. Otherwise say exactly what you could not run.
- Do not claim production or staging deploy unless Rudra asked and you ran it.
