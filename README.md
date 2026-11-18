# skills

Custom Claude Code skills for code review workflows.

## Third-party skill dependencies

Several skills below fan out to reviewer agents that use skills not included in this repo. Most of these are not installed as marketplace plugins (`claude plugin install` won't find them) — they're loose `SKILL.md`/command files that need to be placed under `~/.claude/skills/<name>/` (or `~/.claude/commands/<name>.md` for command-style ones) before the reviews that depend on them will work. The one exception is `superpowers:code-reviewer`, which is a real marketplace plugin — see its row below for the install command.

| Name | Type | Source | Install as |
|------|------|--------|------------|
| `architecture-patterns` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/architecture-patterns) | `~/.claude/skills/architecture-patterns/` |
| `uncle-bob-craft` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/uncle-bob-craft) | `~/.claude/skills/uncle-bob-craft/` |
| `clean-code` | skill | [ClawForge](https://github.com/jackjin1997/ClawForge) | `~/.claude/skills/clean-code/` |
| `api-design-principles` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/api-design-principles) | `~/.claude/skills/api-design-principles/` |
| `database-architect` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/database-architect) | `~/.claude/skills/database-architect/` |
| `terraform-specialist` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/terraform-specialist) | `~/.claude/skills/terraform-specialist/` |
| `kubernetes-architect` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/kubernetes-architect) | `~/.claude/skills/kubernetes-architect/` |
| `docker-expert` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/docker-expert) | `~/.claude/skills/docker-expert/` |
| `observability-engineer` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/observability-engineer) | `~/.claude/skills/observability-engineer/` |
| `humanizer` | skill/command | [blader/humanizer](https://github.com/blader/humanizer) | `~/.claude/skills/humanizer/` or `~/.claude/commands/humanizer.md` |
| `frontend-security-coder` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/frontend-security-coder) | `~/.claude/skills/frontend-security-coder/` |
| `react-best-practices` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/react-best-practices) | `~/.claude/skills/react-best-practices/` |
| `typescript-pro` | skill | [antigravity-awesome-skills](https://github.com/iradoweck/antigravity-awesome-skills/tree/main/skills/typescript-pro) | `~/.claude/skills/typescript-pro/` |
| `superpowers:code-reviewer` | plugin agent | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) (`superpowers` plugin) | `claude plugin install superpowers@claude-plugins-official` |
| `codex:codex-rescue` (or `codex` CLI fallback) | plugin agent / CLI | [openai/codex](https://github.com/openai/codex) | Codex CLI on `PATH`; the `codex-rescue` subagent is optional — both skills fall back to `codex exec --sandbox read-only` if it isn't registered |

The `antigravity-awesome-skills` skills came in with generic `source: community` frontmatter and no upstream link, which is why they weren't credited before — the link above is to the current copy in that collection, not a guarantee of exact version parity with what's installed locally.

Four of the eight skills are tagged `risk: critical` in that collection's catalog: `terraform-specialist`, `kubernetes-architect`, `docker-expert`, and `observability-engineer`. The remaining four are tagged `none` or `safe` (`architecture-patterns`, `database-architect`, `api-design-principles`, `uncle-bob-craft`). The critical-tagged skills are used read-only here — they review diffs and return findings, they never write files or execute commands on your behalf — but the `risk:` tags reflect the upstream author's assessment of what those skills could do in a broader context. These tags aren't version-pinned; upstream is a moving target.

> **Note:** Every `SKILL.md` must include both a `name:` and a `description:` key in its frontmatter or Claude Code won't index it for description-based matching — it can only be invoked by its exact name. The `code-review-remote` skill was missing its entire frontmatter block for this reason.

## Skills

### code-review-meta

Meta code review for your own branches. Fans out to core reviewers (architecture, code quality, Clean Code, simplification/efficiency, Codex — plus conditional API, database, Terraform, Kubernetes, Docker, and observability reviewers), aggregates and deduplicates findings into a prioritized fix list, surfaces ambiguities for clarification, then offers to resolve.

**Usage:** `/code-review-meta` (reviews current branch vs main) or `/code-review-meta 123` (reviews PR #123)

**Depends on** (see [Third-party skill dependencies](#third-party-skill-dependencies) for sources/install):
- `architecture-patterns` (skill) — architectural review perspective
- `uncle-bob-craft` (skill) — Clean Code principles review
- `clean-code` (skill) — comment-verbosity review criteria
- `api-design-principles` (skill, conditional) — API surface design review
- `database-architect` (skill, conditional) — database schema/query review
- `terraform-specialist` (skill, conditional) — Terraform/IaC review
- `kubernetes-architect` (skill, conditional) — Kubernetes manifest/Helm/GitOps review
- `docker-expert` (skill, conditional) — Dockerfile/container build review
- `observability-engineer` (skill, conditional) — OTel instrumentation/observability review
- `humanizer` (skill) — strips AI writing patterns from output
- `superpowers:code-reviewer` (agent) — code quality reviewer
- `codex:codex-rescue` (agent) — Codex second-opinion reviewer

### code-review-remote

Reviews other people's PRs on GitHub. Dispatches 6-12 reviewers in parallel (architecture, code quality, Codex, Clean Code, comment-verbosity, simplification/efficiency, plus conditional API, database, Terraform, Kubernetes, Docker, and observability reviewers), fetches all existing PR comments to avoid duplicate feedback, deduplicates findings, humanizes the output, and optionally posts comments back to the PR.

**Usage:** `/code-review-remote 123` (reviews PR #123 in current repo)

**Depends on** (see [Third-party skill dependencies](#third-party-skill-dependencies) for sources/install):
- `architecture-patterns` (skill) — architectural review perspective
- `uncle-bob-craft` (skill) — Clean Code principles review
- `clean-code` (skill) — comment-verbosity review criteria
- `api-design-principles` (skill, conditional) — API surface design review
- `database-architect` (skill, conditional) — database schema/query review
- `terraform-specialist` (skill, conditional) — Terraform/IaC review
- `kubernetes-architect` (skill, conditional) — Kubernetes manifest/Helm/GitOps review
- `docker-expert` (skill, conditional) — Dockerfile/container build review
- `observability-engineer` (skill, conditional) — OTel instrumentation/observability review
- `humanizer` (skill) — strips AI writing patterns from output
- `superpowers:code-reviewer` (agent) — code quality reviewer
- `codex:codex-rescue` (agent) — Codex second-opinion reviewer

### code-review-frontend

Frontend-focused code review for local branches or remote PRs. Dispatches 2-4 reviewers in parallel (frontend security, UI/UX design, optionally React best practices and TypeScript when detected), aggregates and deduplicates findings, clarifies ambiguities, then offers to resolve locally or post to GitHub PR.

**Usage:** `/code-review-frontend` (reviews current branch vs main) or `/code-review-frontend 123` (reviews PR #123)

**Depends on** (see [Third-party skill dependencies](#third-party-skill-dependencies) for sources/install):
- `frontend-security-coder` (skill) — frontend security review
- `ui-ux-designer` (skill) — UI/UX design patterns and accessibility review
- `react-best-practices` (skill, conditional) — React-specific patterns and hooks review
- `typescript-pro` (skill, conditional) — TypeScript type safety and best practices review
- `humanizer` (skill) — strips AI writing patterns from output

### slack-review-request

Posts a PR review request to the backend Slack channel, including a summary of the PR, linked GitHub issues with titles, and tagged reviewers (detected from git history or hardcoded for known repos). Always sends as a draft for user approval before posting.

**Usage:** `/slack-review-request` or `/slack-review-request 123`

**Depends on:**
- `mcp__plugin_slack_slack__slack_send_message_draft` (MCP) — posts draft message to Slack
- `mcp__plugin_slack_slack__slack_search_channels` (MCP) — finds backend channel
- `mcp__plugin_slack_slack__slack_search_users` (MCP) — resolves reviewers to Slack IDs
- `gh` CLI — fetches PR context

### understand-pr

Reads a GitHub PR, extracts the problem statement, intent, design decisions, and test coverage from the PR body, commits, and diff. Returns a structured summary suitable for sharing with teammates or for pre-review context gathering.

**Usage:** `/understand-pr 123` or `/understand-pr` (for current branch if it has a PR)

**Depends on:**
- `gh` CLI — fetches PR data

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

### explain-and-decide

Turns a question into a decision. Restates the question, explains the subject in plain language, supplies the context and binding constraints (reading the repo for evidence), draws ASCII component/stack/sequence diagrams when relationships or ordering are the hard part, lays out 2-4 real options with trade-offs and a recommendation, then answers follow-up questions until the user commits. Explains and advises only — never implements; offers the implementation as a separate step after the decision.

**Usage:** `/explain-and-decide <question>` or triggered when the user asks to explain something, compare approaches, or help choose between options

**Depends on:** nothing beyond built-in file reading and shell access

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

## Installation

### Install globally

Clone the skills repo to `~/.claude/skill-repos/`:

```bash
git clone https://github.com/elsade/skills ~/.claude/skill-repos/skills
```

Symlink each skill folder into `~/.claude/skills/`:

```bash
ln -s ~/.claude/skill-repos/skills/code-review-meta ~/.claude/skills/code-review-meta
ln -s ~/.claude/skill-repos/skills/code-review-remote ~/.claude/skills/code-review-remote
ln -s ~/.claude/skill-repos/skills/code-review-frontend ~/.claude/skills/code-review-frontend
# ... and so on for each skill
```

**Or** use the included `install.sh` to symlink all skills at once:

```bash
~/.claude/skill-repos/skills/install.sh
```

### Update

Pull the latest from upstream:

```bash
cd ~/.claude/skill-repos/skills && git pull origin main
```

Or use the symlinked skills and pull from wherever they're installed — the symlink will pick up changes automatically on the next Claude Code session.
