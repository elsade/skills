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

### create-linear-issue

Gathers context from the codebase (git log, branch, domain files), asks clarifying questions, then creates a well-structured Linear issue via MCP with proper title conventions and bidirectional linking.

**Usage:** `/create-linear-issue` or triggered when user says "file a ticket", "create an issue", etc.

**Depends on:**
- `mcp__linear-server__save_issue` (MCP) — creates the issue in Linear

### create-pull-request

Commits staged changes, pushes, opens a GitHub PR with a Linear issue link in the body, then comments the PR URL back on the Linear issue for bidirectional linking.

**Usage:** `/create-pull-request`

**Depends on:**
- `mcp__linear-server__save_comment` (MCP) — links PR back to Linear issue
- `gh` CLI — creates PR and pushes branch

### responding-to-pr-feedback

Evaluates PR review comments before acting — checks if already addressed, validates against the codebase, asks the user about ambiguous items, implements valid fixes, pushes back on invalid ones with technical reasoning, runs quality gates, then replies to every comment thread on GitHub. Never commits — stages changes for human review.

**Usage:** `/responding-to-pr-feedback` or triggered when user says "address PR feedback", "handle review comments", etc.

**Depends on:**
- `gh` CLI — fetches PR data and posts comment replies

### update-aws-secret

Safely adds or updates a key in an AWS Secrets Manager YAML secret. Downloads existing content first, appends the key, diffs, confirms with user, pushes, verifies, and cleans up temp files.

**Usage:** `/update-aws-secret`

**Depends on:**
- AWS CLI with SSO login — reads/writes Secrets Manager
- Python `yaml` module — safe YAML parsing
