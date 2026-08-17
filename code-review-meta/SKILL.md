---
description: Run a meta code review that fans out to architecture, code-quality, Clean Code, simplification/efficiency, and Codex reviewers (plus conditional API-design, database, Terraform, Kubernetes, and Docker reviewers), aggregates findings into a prioritized fix list, clarifies ambiguities, then offers to resolve.
argument-hint: "[PR number | empty for local branch vs main]"
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(gh:*), Bash(codex:*), Bash(node:*), Agent, Skill, Edit, Write
---

Invoke the `code-review-meta` skill to review the following scope.

Raw argument: `$ARGUMENTS`

Scope resolution:
- If `$ARGUMENTS` is a positive integer → **PR mode**: review GitHub PR #$ARGUMENTS in the current repo (use `gh pr view` and `gh pr diff`).
- If `$ARGUMENTS` is empty → **Local branch mode**: review the current branch against `origin/main` (base = `git merge-base HEAD origin/main`).
- Anything else → ask the user to clarify before proceeding.

Then follow the `code-review-meta` skill exactly:
1. Resolve the diff.
2. Dispatch reviewers **in parallel** (one message with all applicable Agent tool calls):
   - **Architecture** — `general-purpose`, using the `architecture-patterns` skill. Flag boundary violations, leaky abstractions, coupling issues, misplaced logic. No style or small-bug comments.
   - **Code quality / craft** — `code-reviewer` (superpowers:code-reviewer). Correctness, maintainability, security, test coverage, project conventions.
   - **Clean Code (Uncle Bob)** — `general-purpose`, using the `uncle-bob-craft` skill. Flag SOLID violations, function size/complexity, naming clarity, abstraction levels, side effects, command-query separation. Craftsmanship and readability only — not architecture or correctness bugs.
   - **Simplification / efficiency** — `general-purpose`, same lens as the `/simplify` command but review only. Flag redundant/duplicated logic that should reuse existing code, unnecessary abstraction, dead code, and wrong-altitude changes (over-engineered or missing an obvious simplification). Not correctness, security, or naming/SOLID — those are covered by other reviewers. Return findings, do not edit files.
   - **Codex second opinion** — `codex-rescue` (fallback: `Bash: codex exec --sandbox read-only "<review prompt + diff>"`). Review only, never patch. Correctness bugs, design risks, edge cases the author may have missed.
   - **API design (conditional)** — dispatch only if the diff touches HTTP API surface: route decorators (`@app.get`, `@router`), request/response models used in route signatures, OpenAPI schema files, or nginx/gateway route configs. Use the `api-design-principles` skill; API surface design only.
   - **Database architecture (conditional)** — dispatch only if the diff touches migration files, ORM models (`Column`, `ForeignKey`, `relationship`), repository implementations, or raw SQL/Alembic config. Use the `database-architect` skill; schema/migration/query concerns only.
   - **Terraform (conditional)** — dispatch only if the diff touches `.tf`/`.tfvars`/`.terraform.lock.hcl` files or `**/terraform/**`, `**/infra/**`. Use the `terraform-specialist` skill. Flag state management, module design, provider pinning, unsafe changes (implicit replacement, missing lifecycle blocks, hardcoded secrets). IaC concerns only.
   - **Kubernetes / GitOps (conditional)** — dispatch only if the diff touches K8s manifests, Helm charts, or GitOps config (`apiVersion:`/`kind:` blocks, `Chart.yaml`, `values*.yaml`, `templates/**/*.yaml`, ArgoCD `Application`, Flux `HelmRelease`/`Kustomization`). Use the `kubernetes-architect` skill. Flag resource limits, pod security context, missing PDB/HPA, GitOps drift risk, Helm templating mistakes.
   - **Docker (conditional)** — dispatch only if the diff touches `Dockerfile`/`Dockerfile.*` or `**/docker/**`. Use the `docker-expert` skill. Flag image size/layer efficiency, multi-stage build opportunities, security hardening (root user, unpinned base images, leaked secrets). Container build concerns only.
3. Aggregate and deduplicate findings, preserving source attribution. If reviewers disagree on severity, take the highest and note the disagreement.
4. Apply the `humanizer` skill to every finding's summary and suggested fix before presenting — strip AI writing tells, write like a colleague, keep technical precision.
5. Emit the final markdown report with a recommended fix order.
6. Flag every ambiguity in a `Clarifications needed` section and stop for user input.
7. Only after all ambiguities are answered, offer to resolve. Do not edit files until the user confirms.