# Code Review Remote

## Overview

Reviews other people's PRs on GitHub. Runs five core reviewers in parallel (plus conditional reviewers for API, database, infrastructure, and observability changes), fetches all existing PR comments to avoid duplicate feedback, deduplicates findings against both reviewer overlap and prior comments, then humanizes the final output before presenting it.

## When to Use

- User asks to review someone else's PR
- User invokes `/code-review-remote` with a PR number
- User shares a PR URL for review

Do NOT use for reviewing your own branch or local changes — use `code-review-meta` instead.

## Inputs

- **Required:** PR number `N` (or full GitHub PR URL — extract the number)
- **Optional:** repo in `owner/repo` format if not the current repo

## Workflow

### 1. Fetch PR metadata and diff

```bash
gh pr view <N> --json number,title,headRefName,baseRefName,body,author
gh pr diff <N>
```

If diff exceeds ~3000 lines, warn the user and ask whether to proceed or narrow scope.

### 2. Fetch existing PR comments

Pull all existing review comments so we can deduplicate against them:

```bash
gh pr view <N> --json reviews,comments
gh api repos/{owner}/{repo}/pulls/{N}/comments --paginate
gh api repos/{owner}/{repo}/issues/{N}/comments --paginate
```

Parse into a normalized list with keys: `author`, `file`, `lines`, `body`, `type` (review_comment | issue_comment | review_body).

### 3. Fan out reviewers in parallel (5 core + 6 conditional)

Send a **single message with all applicable Agent tool calls** so they run concurrently. Always dispatch A-E. Only dispatch F-K whose gate condition matches the diff — each is independent, so a PR can trigger any combination of them (or none). Give each reviewer the full diff plus commit context. Tell each to return findings as a JSON array of objects with keys: `file`, `lines`, `severity` (critical|high|medium|low|nit), `category`, `summary`, `suggested_fix`.

**Reviewer A — Architectural perspective:**
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `architecture-patterns` skill (Clean/Hexagonal/DDD principles). Flag boundary violations, leaky abstractions, coupling issues, misplaced logic, and port/adapter breakage. Do NOT comment on style or small bugs — architecture only. Return JSON findings."

**Reviewer B — Code quality / craft:**
- `subagent_type: code-reviewer` (superpowers:code-reviewer)
- Prompt: "Review this diff for correctness, maintainability, security, test coverage, and adherence to project conventions. Return JSON findings."

**Reviewer C — Codex second opinion:**
- `subagent_type: codex-rescue`
- Prompt: "REVIEW ONLY — do not write code or propose patches. Read this diff and flag correctness bugs, design risks, and edge cases the author may have missed. Return JSON findings in the shape described."
- If `codex-rescue` is unavailable, fall back to `Bash: codex exec --sandbox read-only "<review prompt + diff>"`.

**Reviewer D — Clean Code (Uncle Bob):**
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `uncle-bob-craft` skill (Clean Code principles). Flag violations of SOLID, function size/complexity, naming clarity, abstraction levels, side effects, and command-query separation. Focus on craftsmanship and readability, NOT architecture or correctness bugs — those are covered by other reviewers. Return JSON findings."

**Reviewer E — Simplification / efficiency:**
- `subagent_type: general-purpose`
- Prompt: "Review this diff for reuse opportunities, unnecessary complexity, and efficiency issues — the same lens as the `/simplify` command, but review only. Flag redundant or duplicated logic that should reuse existing code, premature or unnecessary abstraction, dead code, and the change operating at the wrong altitude (over-engineered for what was asked, or missing an obvious simplification). Do NOT flag correctness bugs, security issues, or naming/SOLID concerns — those are covered by other reviewers. Do NOT edit any files, only return JSON findings."

**Reviewer F — API design (conditional):**
- **Only dispatch if** the diff touches HTTP API surface: route definitions, endpoint decorators (`@app.get`, `@app.post`, `@router`, `APIRouter`), request/response models used in route signatures, OpenAPI schema files, or nginx/gateway route configs.
- Quick heuristic: scan the diff for patterns like `@(app|router)\.(get|post|put|patch|delete)`, `APIRouter`, `location ~`, `proxy_pass`, or files matching `**/api/**`, `**/routes.*`. If none match, skip Reviewer F entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `api-design-principles` skill. Flag issues with endpoint naming, HTTP method usage, request/response schemas, versioning, error responses, pagination, and REST conventions. Focus on API surface design only, NOT internal implementation or architecture — those are covered by other reviewers. Return JSON findings."

**Reviewer G — Database architecture (conditional):**
- **Only dispatch if** the diff touches database concerns: migration files, SQLAlchemy models (`Column`, `Table`, `ForeignKey`, `relationship`), repository implementations, raw SQL, or Alembic config.
- Quick heuristic: scan the diff for patterns like `op.create_table`, `op.add_column`, `Column(`, `ForeignKey(`, `Base = declarative_base`, `AsyncSession`, `SELECT`, `INSERT`, `UPDATE`, `DELETE`, or files matching `**/migrations/**`, `**/db/**`, `**/repositories/**`. If none match, skip Reviewer G entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `database-architect` skill. Flag issues with schema design, normalization, indexing, foreign key constraints, migration safety (data loss, locking), naming conventions, query performance, and transaction boundaries. Focus on database concerns only, NOT application logic or API design — those are covered by other reviewers. Return JSON findings."

**Reviewer H — Terraform (conditional):**
- **Only dispatch if** the diff touches Terraform: `.tf`, `.tfvars`, `.tfvars.json`, `.terraform.lock.hcl` files, or files under `**/terraform/**`, `**/infra/**`, `**/environments/**`.
- Quick heuristic: scan the diff for patterns like `resource "`, `module "`, `provider "`, `data "`, `terraform {`, `backend "s3"` / `backend "gcs"` / `backend "azurerm"`, `variable "`, `output "`. If none match, skip Reviewer H entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `terraform-specialist` skill. Flag issues with state management, module design, resource naming, provider version pinning, unsafe changes (implicit resource replacement, missing lifecycle blocks, hardcoded secrets), and IaC best practices. Focus on Terraform/infrastructure-as-code concerns only, NOT application logic. Return JSON findings."

**Reviewer I — Kubernetes / GitOps (conditional):**
- **Only dispatch if** the diff touches Kubernetes manifests, Helm charts, or GitOps config: files under `**/k8s/**`, `**/kubernetes/**`, `**/charts/**`, `**/manifests/**`, `kustomization.yaml`, `Chart.yaml`, `values*.yaml`, `templates/**/*.yaml`.
- Quick heuristic: scan the diff for `apiVersion:` combined with `kind: (Deployment|Service|StatefulSet|DaemonSet|Ingress|ConfigMap|Secret|HorizontalPodAutoscaler|PodDisruptionBudget|CronJob)`, or GitOps kinds `kind: Application` (ArgoCD) / `kind: HelmRelease` / `kind: Kustomization` (Flux), or Helm template syntax `{{ .Values`, `{{- if`, `helm.sh/chart`. If none match, skip Reviewer I entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `kubernetes-architect` skill. Flag issues with resource requests/limits, pod security context, missing PodDisruptionBudgets or HPA misconfiguration, GitOps drift risk, Helm templating mistakes, and orchestration/cluster-level concerns. Focus on Kubernetes and GitOps concerns only, NOT application logic. Return JSON findings."

**Reviewer J — Docker (conditional):**
- **Only dispatch if** the diff touches container build files: `Dockerfile`, `Dockerfile.*`, or files under `**/docker/**`.
- Quick heuristic: scan the diff for `FROM `, `RUN `, `COPY --from=`, `ENTRYPOINT`, `CMD`. If none match, skip Reviewer J entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `docker-expert` skill. Flag issues with image size/layer efficiency, multi-stage build opportunities, security hardening (running as root, unpinned base images, leaked build secrets), and container best practices. Focus on Docker/container build concerns only, NOT application logic or Kubernetes deployment concerns — those are covered by other reviewers. Return JSON findings."

**Reviewer K — Observability / OTel (conditional):**
- **Only dispatch if** the diff touches OTel instrumentation or observability config: SDK initialization, span/trace/metric/log code, OTel Collector config files, or telemetry utility modules.
- Quick heuristic: scan the diff for patterns like `opentelemetry`, `init_otel`, `get_current_span`, `set_attribute`, `record_exception`, `set_status`, `StatusCode`, `TracerProvider`, `MeterProvider`, `BatchSpanProcessor`, `OTEL_`, `otlp`, or files matching `**/telemetry/**`, `**/otel*.py`, `**/tracing/**`, `*otel-collector*.yaml`, `*otel*.yaml`. If none match, skip Reviewer K entirely.
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `observability-engineer` skill. Focus on: OTel semantic convention compliance (attribute naming, span status, error recording), context propagation correctness (traceparent injection/extraction), sampling strategy soundness, metric naming and cardinality, log-to-trace correlation, collector pipeline ordering and processor correctness, missing required span attributes, and performance implications (sync vs batch export, SDK no-op guard correctness). Focus on observability correctness only, NOT general code quality or architecture — those are covered by other reviewers. Return JSON findings."

### 4. Aggregate and deduplicate (reviewers)

Collect all findings into one list. Deduplicate across reviewers using:

1. **Exact location match**: same `file` + overlapping `lines` + same `category` — merge into one finding, record all `sources` that raised it.
2. **Semantic match**: same `file` + similar `summary` (same root cause) — merge even if `lines` differ slightly.
3. **Conflict handling**: if reviewers disagree on severity, take the **highest** and note the disagreement in the merged `summary`.

Multi-source findings signal higher confidence — surface that in the output.

### 5. Deduplicate against existing PR comments

For each finding from step 4, compare against the existing comments from step 2:

1. **Exact match**: an existing comment targets the same `file` + overlapping `lines` and raises the same concern — **drop the finding entirely**.
2. **Partial match**: an existing comment raises the same root cause but in a different location, or covers the topic generally — **drop the finding** and note it was already covered.
3. **Tangential match**: an existing comment touches the same area but raises a different concern — **keep the finding**, but add a note referencing the existing comment so reviewer context is preserved.

After deduplication, if zero findings remain, report that to the user: "Existing reviews already cover everything I found. No additional feedback to add."

### 6. Humanize the output

Before presenting findings, apply the `humanizer` skill to all `summary` and `suggested_fix` text:

- Strip AI writing patterns (significance inflation, -ing phrases, copula avoidance, filler, hedging, sycophancy, em dash overuse, boldface overuse, rule-of-three, signposting)
- Use direct, natural language — write like a colleague leaving a code review, not a report generator
- Keep technical precision intact — don't dumb down the actual issue
- Vary sentence structure; short and direct is fine
- Have opinions where appropriate ("this will break if...", "I'd move this because...")
- No emojis, no inline-header bullet lists, no generic positive conclusions
- Do a final anti-AI pass: ask "what makes this obviously AI generated?" and revise any remaining tells

### 7. Present the report

```markdown
## Code Review — PR #N: <title>
**Author:** <author> | **Diff size:** <lines changed> | **Existing comments:** <count>
**Findings after dedup:** <count remaining> / <count before dedup> (dropped <count> already covered)

### Critical
- **<file>:<lines>** — <summary> _(sources: A, B)_
  - Fix: <concrete action>

### High
...

### Medium / Low / Nit
...

### Already covered by existing reviews
- <file>:<lines> — <summary> _(covered by @<author>'s comment)_
- ...

### Recommended fix order
1. <file:lines> — <one-line rationale>
2. ...
```

### 8. Clarify ambiguities before offering to post

Walk every finding and flag anything ambiguous using these criteria:

- **Vague fix action** — `suggested_fix` is generic with no concrete target
- **Multiple valid approaches** — reviewers disagree on direction
- **Unclear scope** — fix may touch files outside the diff
- **Contested severity** — reviewers split on how bad it is
- **Conflicting findings** — two reviewers propose incompatible fixes
- **Out-of-scope vs in-scope** — real issue but might belong to a follow-up
- **Premise check needed** — fix depends on runtime behavior or a convention you cannot verify from the diff alone

For each flagged finding:

```markdown
#### Ambiguity: <file>:<lines> — <one-line finding summary>
- **What's unclear:** <what decision the user needs to make>
- **Options:**
  1. <option A>
  2. <option B>
  3. <skip / defer>
- **Recommendation:** <your pick, or "no strong preference">
```

Group under `### Clarifications needed`. If none: `_None — all findings are actionable as written._`

**Stop and wait for the user's answers.**

### 9. Offer to post comments on the PR

Once ambiguities are resolved, offer:

> Ready to post feedback on PR #N. Scope: `<N>` findings to comment on, `<M>` deferred, `<K>` dismissed. Want me to post as individual review comments on the relevant lines, or as a single review summary?

Options:
- **Individual line comments**: use `gh api` to post review comments on specific files/lines
- **Single review**: post the full report as one review comment
- **Don't post**: user just wanted the analysis

Do **not** post anything until the user confirms which option.

When posting individual comments, use:
```bash
gh api repos/{owner}/{repo}/pulls/{N}/reviews \
  --method POST \
  -f event="COMMENT" \
  -f body="<overall summary>" \
  --jq '.id'
```

Or for line-level comments:
```bash
gh api repos/{owner}/{repo}/pulls/{N}/comments \
  --method POST \
  -f body="<comment>" \
  -f path="<file>" \
  -F line=<line> \
  -f side="RIGHT"
```

## Quick Reference

| Step | Tool | Parallel? |
|------|------|-----------|
| Fetch PR metadata + diff | Bash (`gh`) | — |
| Fetch existing comments | Bash (`gh api`) | **Yes** (with above) |
| Dispatch 5-11 reviewers | Agent x 5-11 in one message | **Yes** |
| Aggregate/dedupe reviewers | In-context reasoning | — |
| Dedupe vs existing comments | In-context reasoning | — |
| Humanize output | Apply humanizer patterns | — |
| Present report | Direct text output | — |
| Clarify ambiguities | Direct text output + wait | — |
| Offer to post | Direct text output + wait | — |

## Common Mistakes

- **Sequential dispatch** — always run reviewers in parallel.
- **Letting reviewers fix things** — review only, never patch.
- **Passing truncated diffs** — check diff size first; warn if >3000 lines.
- **Losing source attribution** — every merged finding must list which reviewers raised it.
- **Duplicating existing feedback** — the whole point of step 5 is to not repeat what others said. Be aggressive about dropping duplicates.
- **Robotic comment language** — run humanizer. Comments should read like a human colleague wrote them, not a linting tool.
- **Posting without permission** — never post comments to the PR without explicit user confirmation.
- **Skipping the clarification step** — surface ambiguities before offering to post.
- **Asking one question at a time** — batch all ambiguities so the user can answer in one pass.
- **Reviewing your own PR** — this skill is for other people's PRs. Use `code-review-meta` for your own work.
