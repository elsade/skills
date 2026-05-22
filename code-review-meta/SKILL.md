---
description: Run a meta code review that fans out to architecture, code-quality, and Codex reviewers, aggregates findings into a prioritized fix list, clarifies ambiguities, then offers to resolve.
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
2. Dispatch the three reviewers **in parallel** (one message with three Agent tool calls).
3. Aggregate and deduplicate findings, preserving source attribution.
4. Emit the final markdown report with a recommended fix order.
5. Flag every ambiguity in a `Clarifications needed` section and stop for user input.
6. Only after all ambiguities are answered, offer to resolve. Do not edit files until the user confirms.