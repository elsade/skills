---
name: code-review-frontend
description: Frontend code review for local branches or remote PRs. Fans out to frontend-security-coder, ui-ux-designer, and optionally react-best-practices and typescript-pro based on code detection. Aggregates findings, deduplicates, and offers to resolve or post comments.
argument-hint: "[PR number | empty for local branch vs main]"
allowed-tools: Read, Glob, Grep, Bash(git:*), Bash(gh:*), Bash(codex:*), Agent, Skill, Edit, Write
---

# Code Review — Frontend

Frontend-focused code review for local branches or remote PRs. Dispatches specialized reviewers in parallel (frontend security, UI/UX design, React patterns, TypeScript), aggregates findings into a prioritized list, clarifies ambiguities, then offers to resolve or post.

## When to Use

- Review frontend/UI code on current branch (local mode)
- Review a frontend PR on GitHub (remote mode)
- Want security, UX, React patterns, and TypeScript checks in one pass

Do NOT use for backend-only reviews — use `code-review-meta` or `code-review-remote` instead.

## Inputs

- **Required:** PR number N (remote mode) OR empty string (local mode)
- **Optional:** repo in `owner/repo` format if not the current repo

## Workflow

### 1. Scope resolution

- If argument is a **positive integer** → **PR mode**: review GitHub PR #N in current repo
- If argument is **empty** → **Local mode**: review current branch against `origin/main` base
- Anything else → ask user to clarify

### 2. Fetch diff

**PR mode:**
```bash
gh pr view <N> --json number,title,headRefName,baseRefName,body,author
gh pr diff <N>
```

**Local mode:**
```bash
git merge-base HEAD origin/main  # find base commit
git diff <base>..HEAD
```

If diff exceeds ~3000 lines, warn and ask whether to proceed.

### 3. Fetch existing comments (PR mode only)

Pull all existing review comments for deduplication:

```bash
gh pr view <N> --json reviews,comments
gh api repos/{owner}/{repo}/pulls/{N}/comments --paginate
gh api repos/{owner}/{repo}/issues/{N}/comments --paginate
```

Parse into normalized list with keys: `author`, `file`, `lines`, `body`, `type`.

### 4. Detect frontend tech stack

Scan diff for patterns. For each file:
- **React** → patterns like `import React`, `.jsx`, `.tsx`, `React.`, `useState`, `useEffect`, `useCallback`, `useMemo`, component exports, `JSX`
- **TypeScript** → `.ts`, `.tsx` files, type annotations, `interface`, `type`

Track booleans: `has_react`, `has_typescript`.

### 5. Fan out reviewers in parallel

Send **single message with all applicable Agent tool calls** so they run concurrently. Always dispatch A–B. Only dispatch C–D if detected.

Give each reviewer the full diff plus commit context. Reviewers return findings as JSON array: `file`, `lines`, `severity` (critical|high|medium|low|nit), `category`, `summary`, `suggested_fix`.

**Reviewer A — Frontend security:**
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `frontend-security-coder` skill. Flag XSS vulnerabilities, unsafe DOM manipulation, insecure API calls, missing CSRF protections, insecure storage, authentication/session handling flaws, and frontend security best practices. Focus on security only, NOT performance, design, or code quality — those are covered by other reviewers. Return JSON findings."

**Reviewer B — UI/UX design:**
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `ui-ux-designer` skill. Flag issues with component design patterns, accessibility (WCAG compliance, semantic HTML, ARIA), interaction patterns, visual consistency, responsive design, state management clarity, and user experience flows. Focus on UX and design patterns only, NOT code quality or security — those are covered by other reviewers. Return JSON findings."

**Reviewer C — React best practices (conditional):**
- **Only dispatch if** `has_react == true` (detected `.jsx`/`.tsx` or React imports/hooks)
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `react-best-practices` skill. Flag issues with component structure, hook usage, re-render optimization, state lifting, prop drilling, side effects, dependency arrays, key props in lists, controlled vs uncontrolled components, and React patterns. Focus on React concerns only, NOT security or UX design — those are covered by other reviewers. Return JSON findings."

**Reviewer D — TypeScript (conditional):**
- **Only dispatch if** `has_typescript == true` (detected `.ts`/`.tsx` or type annotations)
- `subagent_type: general-purpose`
- Prompt: "Review this diff using the `typescript-pro` skill. Flag issues with type safety, unnecessary `any` types, overly broad/narrow type signatures, missing type exports, type inference opportunities, generic constraints, and TypeScript best practices. Focus on type concerns only, NOT React, security, or UX — those are covered by other reviewers. Return JSON findings."

### 6. Aggregate and deduplicate (reviewers)

Collect all findings. Deduplicate across reviewers using:

1. **Exact location match**: same `file` + overlapping `lines` + same `category` → merge, record all sources
2. **Semantic match**: same `file` + similar `summary` (same root cause) → merge even if lines differ slightly
3. **Conflict handling**: if reviewers disagree on severity, take **highest** and note disagreement in merged summary

Multi-source findings signal higher confidence — surface that in output.

### 7. Deduplicate against existing PR comments (PR mode only)

For each finding from step 6, compare against existing comments from step 3:

1. **Exact match**: existing comment targets same `file` + overlapping `lines` and raises same concern → **drop finding entirely**
2. **Partial match**: existing comment raises same root cause in different location or covers topic generally → **drop finding**, note it was already covered
3. **Tangential match**: existing comment touches same area but different concern → **keep finding**, add note referencing existing comment

After dedup, if zero findings remain: "Existing reviews already cover everything I found. No additional feedback to add."

### 8. Humanize output

Apply `humanizer` skill to all `summary` and `suggested_fix` text:

- Strip AI writing patterns (significance inflation, -ing phrases, copula avoidance, filler, hedging, sycophancy, em dash overuse, boldface overuse, rule-of-three, signposting)
- Use direct, natural language — write like a colleague leaving a review, not a report generator
- Keep technical precision intact
- Vary sentence structure; short and direct is fine
- Have opinions where appropriate
- No emojis, no inline-header bullet lists, no generic positive conclusions

### 9. Present report

**Local mode:**
```markdown
## Code Review — Frontend (Branch)
**Branch:** <branch> | **Base:** main | **Diff size:** <lines> changed
**Findings:** <count> total

### Critical
- **<file>:<lines>** — <summary> _(sources: A, B)_
  - Fix: <action>

### High / Medium / Low / Nit
...

### Recommended fix order
1. <file:lines> — <rationale>
2. ...
```

**PR mode:**
```markdown
## Code Review — PR #N: <title>
**Author:** <author> | **Diff size:** <lines> | **Existing comments:** <count>
**Findings after dedup:** <remaining> / <total before> (dropped <count> already covered)

### Critical / High / Medium / Low / Nit
...

### Already covered by existing reviews
- <file:lines> — <summary> _(covered by @<author>'s comment)_

### Recommended fix order
1. <file:lines> — <rationale>
2. ...
```

### 10. Clarify ambiguities

Walk every finding and flag anything ambiguous:

- **Vague fix action** — `suggested_fix` is generic with no concrete target
- **Multiple valid approaches** — reviewers disagree on direction
- **Unclear scope** — fix may touch files outside diff
- **Contested severity** — reviewers split on how bad it is
- **Conflicting findings** — two reviewers propose incompatible fixes

For each flagged finding:

```markdown
#### Ambiguity: <file>:<lines> — <one-line summary>
- **What's unclear:** <what decision user needs>
- **Options:**
  1. <option A>
  2. <option B>
  3. <skip / defer>
- **Recommendation:** <your pick or "no strong preference">
```

Group under `### Clarifications needed`. If none: `_None — all findings are actionable as written._`

**Stop and wait for user's answers.**

### 11. Resolve or post

**Local mode — offer to fix:**

> Ready to resolve findings on this branch. Want me to auto-fix where possible, or just apply the ones you approve?

Options:
- **Auto-fix safe ones** — apply fixes where there's no ambiguity
- **Show all, then ask per-finding** — user decides which to apply
- **Don't fix** — just wanted analysis

**PR mode — offer to post:**

> Ready to post feedback on PR #N. Scope: `<N>` findings, `<M>` deferred, `<K>` dismissed. Post as individual line comments or single review summary?

Options:
- **Individual line comments** — use `gh api` to post on specific files/lines
- **Single review** — post full report as one comment
- **Don't post** — just wanted analysis

Do **NOT** post or resolve until user confirms which option.

## Quick Reference

| Step | Tool | Parallel? |
|------|------|-----------|
| Fetch diff | Bash (`git`/`gh`) | — |
| Fetch existing comments | Bash (`gh api`) | Yes (with above) |
| Detect tech stack | Grep / pattern scan | — |
| Dispatch 2–4 reviewers | Agent x 2–4 in one message | **Yes** |
| Aggregate/dedupe reviewers | In-context reasoning | — |
| Dedupe vs existing comments | In-context reasoning | — (PR mode only) |
| Humanize output | Apply humanizer patterns | — |
| Present report | Direct text output | — |
| Clarify ambiguities | Direct text output + wait | — |
| Resolve or post | Bash (`git` / `gh api`) | — |

## Common Mistakes

- **Sequential dispatch** — always run reviewers in parallel.
- **Reviewing non-frontend code** — use `code-review-meta` or `code-review-remote` for backend.
- **Passing truncated diffs** — check diff size first; warn if >3000 lines.
- **Losing source attribution** — every merged finding must list which reviewers raised it.
- **Duplicating existing feedback** — be aggressive about dropping duplicates (PR mode).
- **Robotic language** — run humanizer. Sound like a colleague, not a tool.
- **Posting/resolving without permission** — never without explicit user confirmation.
- **Skipping the clarification step** — surface all ambiguities before offering action.
- **Asking one question at a time** — batch all ambiguities so user can answer in one pass.
