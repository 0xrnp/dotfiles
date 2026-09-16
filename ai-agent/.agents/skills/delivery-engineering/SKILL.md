---
name: delivery-engineering
description: Implement and review CI pipelines, container builds, artifact promotion, rollout, rollback, and recovery procedures. Use for delivery configuration or deployment design, not as authorization to deploy.
---

# Delivery engineering

Inspect pipeline files, build scripts, lockfiles, image definitions, deployment
manifests, environment ownership, and existing release procedures. Match the
repository's platform, including Bitbucket Pipelines where present. Read official
documentation for the installed platform when syntax or semantics are uncertain.

## Build and supply chain

- Keep builds reproducible with repository-supported dependency and toolchain
  pins. Promote the tested immutable artifact instead of rebuilding per environment.
- Give untrusted pull-request jobs no deployment credentials or privileged
  runners. Avoid executing untrusted checkout code in a privileged follow-up job.
- Use minimum token/IAM permissions and short-lived identity where supported.
  Keep secrets out of build arguments, image layers, caches, logs, and artifacts.
  Use the existing secret delivery mechanism.
- Cache by relevant inputs and trust scope. A cache hit must not skip required
  validation or substitute an unverified artifact.
- Use existing scanners, provenance, and signing controls where applicable.
  Adding tools requires a concrete risk reduction, not a checklist quota.

## Containers and environments

Inspect runtime user, writable paths, persistent volumes, exposed interfaces,
resource limits, signal delivery, and shutdown grace. Distinguish startup,
readiness, and liveness checks; a dependency outage should not automatically
cause an endless restart loop. Use minimal compatible images, not an incidental
base-image upgrade. Do not bake machine-specific state into an artifact.

## Rollout and recovery

- Identify artifact, account, region, environment, state, and deployment owner.
  Preserve required approvals. Local configuration work does not authorize a
  deployment, production read, secret access, or infrastructure apply.
- Explain mixed-version compatibility between clients, services, workers, and
  storage. Sequence additive schema changes, backfill, reader/writer transitions,
  and eventual removal. A code rollback cannot undo every data transformation.
- Specify rollout stages, health signals, observation window, abort threshold,
  and who can stop or roll back. Use existing release controls proportionately.
- Serialize conflicting deployments and migrations. Consider retries and partial
  failure of pipeline jobs as well as application requests.
- For stateful changes, define backup and restore evidence, acceptable loss,
  recovery time, and how recovery will be tested. A configured backup is not
  proof of restorability.

## Verify without deploying

Run the repository's static configuration checks and relevant build/tests using
local or explicitly authorized resources. Inspect generated artifacts and
permissions. Keep secrets out of rendered configuration output. Report separately:
static validation, build execution, test-environment rollout, and production
verification. Never imply that one proves another.

For Terraform resources and state movement, also use terraform-engineering.
