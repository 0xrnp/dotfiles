---
name: terraform-engineering
description: Design, change, and review Terraform or HCL with state, provider, replacement, environment, and deployment safety. Use for .tf, .tfvars, modules, backends, plans, imports, or moved resources.
---

# Terraform engineering

Infrastructure changes can destroy or replace live resources. Read the nearest
Terraform files, module callers, provider locks, backend, environment layout,
CI workflow, and repository documentation before proposing a change.

## Design

- Match the repository's file, module, naming, tagging, and environment
  conventions. HashiCorp style is a fallback, not a reason to reformat neighbors.
- Create a module only for a cohesive reusable boundary with a stable typed
  interface. Do not modularize one-off resources for appearance.
- Give variables precise types and validation where invalid input would be
  costly. Keep outputs to actual consumers.
- Prefer `for_each` when stable identity matters. Understand address changes
  before replacing `count` or changing keys.
- Pin Terraform and providers according to repository policy. Do not upgrade
  them incidentally.

## State and safety

- Identify the workspace, backend, account, region, and environment before any
  command that can access state.
- Treat state, plans, variable files, and provider output as potentially
  sensitive.
- Never run `apply`, `destroy`, import, state mutation, or a production plan
  without explicit authorization for the named environment.
- For renames or module moves, map exact resource addresses and prefer `moved`
  blocks when supported. A refactor should not recreate infrastructure.
- Inspect replacement, dependency, IAM, networking, data-loss, downtime, and
  rollback implications.
- Do not use `-target` as a routine workflow or bypass lifecycle protections.

## Before code

Report affected modules and environments, expected state-address changes,
replacement risk, provider/version assumptions, and the safe verification path.

## Verify

Run repository-supported formatting and static validation first. Run
`terraform plan` only with explicit environment authorization and after
confirming credentials and backend. Read the complete plan and report create,
change, destroy, replacement, and unknown counts without claiming an apply.
