# skills

Custom Claude Code skills for code review workflows.

## Skills

### code-review-meta

Meta code review for your own branches. Fans out to three parallel reviewers (architecture, code quality, and Codex), aggregates and deduplicates findings into a prioritized fix list, surfaces ambiguities for clarification, then offers to resolve.

**Usage:** `/code-review-meta` (reviews current branch vs main) or `/code-review-meta 123` (reviews PR #123)

**Depends on:**
- `superpowers:code-reviewer` (agent) — code quality reviewer
- `codex:codex-rescue` (agent) — Codex second-opinion reviewer

### code-review-remote

Reviews other people's PRs on GitHub. Dispatches 4-6 reviewers in parallel (architecture, code quality, Codex, Clean Code, plus conditional API and database reviewers), fetches all existing PR comments to avoid duplicate feedback, deduplicates findings, humanizes the output, and optionally posts comments back to the PR.

**Usage:** `/code-review-remote 123` (reviews PR #123 in current repo)

**Depends on:**
- `architecture-patterns` (skill) — architectural review perspective
- `uncle-bob-craft` (skill) — Clean Code principles review
- `api-design-principles` (skill, conditional) — API surface design review
- `database-architect` (skill, conditional) — database schema/query review
- `humanizer` (skill) — strips AI writing patterns from output
- `superpowers:code-reviewer` (agent) — code quality reviewer
- `codex:codex-rescue` (agent) — Codex second-opinion reviewer
