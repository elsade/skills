---
name: create-linear-issue
description: Use when the user wants to file, log, create, or add an issue, bug, task, or ticket in Linear. Handles context gathering from the codebase, clarifying questions, and issue creation via Linear MCP.
---

# Create Linear Issue

## Overview

Gather context from the codebase and the user, then create a well-structured Linear issue via MCP. Good issues have a clear summary, root cause or motivation, impact, and proposed fix or approach.

## Process

### 1. Gather Codebase Context

Before asking questions, read relevant files to understand what the user is describing:

- Check `git log --oneline -20` and `git status` to understand recent work
- Read the current branch name — it often signals the active feature or domain
- If the user mentions a file, service, or domain, read it
- Skim `docs/AGENTS.md` or `CLAUDE.md` for project/team structure if unfamiliar

### 2. Ask Clarifying Questions

Use `AskUserQuestion` to gather what you don't already know. Cover all unknowns in a single round:

**Problem / Feature:**
- What is the problem or feature? (one-sentence summary)
- For bugs: What is the root cause? What is the impact?
- For features: What is the motivation? What should it do?

**Project** (ask only if you can't infer it):
- Look at the current branch, recent commits, and domain structure first
- If the codebase maps to a known Linear project (e.g. "Trust Dashboard", "Dome"), infer it
- Otherwise ask: "Which Linear project should this belong to?"

**Priority** (ask only if not obvious):

| Priority | When |
|----------|------|
| Urgent (1) | Data loss, security issue, system down |
| High (2) | Major feature broken, blocking work |
| Normal (3) | Feature request, non-blocking bug, improvement |
| Low (4) | Nice-to-have, minor polish |

If the user already said "urgent" or described a severe impact, infer it. Otherwise ask.

### 3. Draft the Issue

Use this structure for the description:

```markdown
## Summary
<1–2 sentence description of the problem or feature>

## Root Cause / Motivation
<Why is this happening? Or why do we want this?>

## Impact
<What breaks or is missing without this?>

## Fix / Approach
<What needs to change? Reference specific files, lines, or components if known>

## Notes
<Any caveats, edge cases, or related context>
```

Omit sections that don't apply (e.g. no "Root Cause" for pure features).

### 4. Create the Issue

Use the Linear MCP tool. Required fields: `title`, `team`. Map priority to numbers: Urgent=1, High=2, Normal=3, Low=4.

```
mcp__linear-server__save_issue(
  title="<concise imperative title>",
  team="<team name>",
  project="<project name>",   // if known
  priority=<1–4>,
  description="<markdown body>"
)
```

Return the issue identifier and URL to the user.

## Title Conventions

- Bug fixes: `fix: <short description>`
- Features: `feat: <short description>`
- Refactors: `refactor: <short description>`
- Docs: `docs: <short description>`
- Keep under 80 characters

## Common Mistakes

- **Skipping codebase context** — always read relevant files before asking questions; you may already know the answer
- **Asking questions you can infer** — check git log, branch name, and domain structure first
- **Vague descriptions** — reference specific files and line numbers when known
- **Wrong team** — the project's `CLAUDE.md` or `AGENTS.md` usually lists the team; check it