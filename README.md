# skills

Custom Claude Code skills for code review workflows.

## Third-party skill dependencies

Several skills below fan out to reviewer agents that use skills not included in this repo. Most of these are not installed as marketplace plugins (`claude plugin install` won't find them) — they're loose `SKILL.md`/command files that need to be placed under `~/.claude/skills/<name>/` (or `~/.claude/commands/<name>.md` for command-style ones) before the reviews that depend on them will work. The one exception is `superpowers:code-reviewer`, which is a real marketplace plugin — see its row below for the install command.

| Name | Type | Source | Install as |
|------|------|--------|------------|
| `architecture-patterns` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/architecture-patterns) | `~/.claude/skills/architecture-patterns/` |
| `uncle-bob-craft` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/uncle-bob-craft) | `~/.claude/skills/uncle-bob-craft/` |
| `api-design-principles` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/api-design-principles) | `~/.claude/skills/api-design-principles/` |
| `database-architect` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/database-architect) | `~/.claude/skills/database-architect/` |
| `terraform-specialist` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/terraform-specialist) | `~/.claude/skills/terraform-specialist/` |
| `kubernetes-architect` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/kubernetes-architect) | `~/.claude/skills/kubernetes-architect/` |
| `docker-expert` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/docker-expert) | `~/.claude/skills/docker-expert/` |
| `humanizer` | skill/command | [blader/humanizer](https://github.com/blader/humanizer) | `~/.claude/skills/humanizer/` or `~/.claude/commands/humanizer.md` |
| `superpowers:code-reviewer` | plugin agent | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) (`superpowers` plugin) | `claude plugin install superpowers@claude-plugins-official` |
| `codex:codex-rescue` (or `codex` CLI fallback) | plugin agent / CLI | [openai/codex](https://github.com/openai/codex) | Codex CLI on `PATH`; the `codex-rescue` subagent is optional — both skills fall back to `codex exec --sandbox read-only` if it isn't registered |

The `antigravity-awesome-skills` skills came in with generic `source: community` frontmatter and no upstream link, which is why they weren't credited before — the link above is to the current copy in that collection, not a guarantee of exact version parity with what's installed locally. Note `kubernetes-architect` is tagged `risk: unknown` in that collection's catalog (vs. `none`/`safe` for the others) — nobody's explicitly vetted it, though it's read-only in this use.

## Skills

### code-review-meta

Meta code review for your own branches. Fans out to core reviewers (architecture, code quality, Clean Code, simplification/efficiency, Codex — plus conditional API, database, Terraform, Kubernetes, and Docker reviewers), aggregates and deduplicates findings into a prioritized fix list, surfaces ambiguities for clarification, then offers to resolve.

**Usage:** `/code-review-meta` (reviews current branch vs main) or `/code-review-meta 123` (reviews PR #123)

**Depends on** (see [Third-party skill dependencies](#third-party-skill-dependencies) for sources/install):
- `architecture-patterns` (skill) — architectural review perspective
- `uncle-bob-craft` (skill) — Clean Code principles review
- `api-design-principles` (skill, conditional) — API surface design review
- `database-architect` (skill, conditional) — database schema/query review
- `terraform-specialist` (skill, conditional) — Terraform/IaC review
- `kubernetes-architect` (skill, conditional) — Kubernetes manifest/Helm/GitOps review
- `docker-expert` (skill, conditional) — Dockerfile/container build review
- `humanizer` (skill) — strips AI writing patterns from output
- `superpowers:code-reviewer` (agent) — code quality reviewer
- `codex:codex-rescue` (agent) — Codex second-opinion reviewer

### code-review-remote

Reviews other people's PRs on GitHub. Dispatches 5-10 reviewers in parallel (architecture, code quality, Codex, Clean Code, simplification/efficiency, plus conditional API, database, Terraform, Kubernetes, and Docker reviewers), fetches all existing PR comments to avoid duplicate feedback, deduplicates findings, humanizes the output, and optionally posts comments back to the PR.

**Usage:** `/code-review-remote 123` (reviews PR #123 in current repo)

**Depends on** (see [Third-party skill dependencies](#third-party-skill-dependencies) for sources/install):
- `architecture-patterns` (skill) — architectural review perspective
- `uncle-bob-craft` (skill) — Clean Code principles review
- `api-design-principles` (skill, conditional) — API surface design review
- `database-architect` (skill, conditional) — database schema/query review
- `terraform-specialist` (skill, conditional) — Terraform/IaC review
- `kubernetes-architect` (skill, conditional) — Kubernetes manifest/Helm/GitOps review
- `docker-expert` (skill, conditional) — Dockerfile/container build review
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
