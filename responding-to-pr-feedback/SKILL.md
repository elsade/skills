---
name: responding-to-pr-feedback
description: Use when asked to address, handle, or respond to PR review comments or feedback. Covers fetching the PR, reading code for context, evaluating each comment, asking the user when ambiguous, and staging changes for review without committing.
---

# Responding to PR Feedback

## Overview

PR feedback requires evaluation before action. Some comments are valid and should be addressed. Some are wrong and need a clear technical rebuttal. Some are ambiguous — stop and ask the user before touching code.

**Core principle:** Fetch → Read → Evaluate every comment → Ask about ambiguity FIRST → Then act → Quality gate → Stage for review. Never commit.

## The Iron Law

**DO NOT COMMIT OR PUSH CHANGES.**

Your job is to prepare changes for the human to review. Leave everything staged (or unstaged) and summarize what changed and what you pushed back on. The human decides what gets committed.

## Workflow

```
1. FETCH
   Pull the PR and all its review comments using gh CLI.
   Pull the diff to see exactly what changed.

2. READ CODE
   Read the actual source files involved in the PR diff.
   Understand the changes in context before evaluating any comment.

3. SURVEY ALL COMMENTS FIRST
   Read every comment before acting on any.
   Identify: already addressed? valid? invalid? ambiguous?

4. STOP — ASK ABOUT AMBIGUITY
   IF any comment is ambiguous (unclear intent, conflicting constraints,
   architectural tradeoff that affects the user's preferences):
     Ask the user to clarify ALL ambiguous items at once.
     Do not implement anything yet.
     Wait for a response before continuing.

5. ACT (after all ambiguity resolved)
   For each remaining unaddressed comment, in priority order:
     IF valid   → implement the fix
     IF invalid → prepare a technical rebuttal (do not implement)

6. QUALITY GATE
   After ALL changes are made:
     make lint   (ruff + mypy)
     Run affected tests
   If anything fails, fix it before reporting back.

7. REPLY TO EVERY COMMENT ON GITHUB
   After changes are staged and quality gate passes, reply to EVERY
   comment thread on the PR. Do not skip any.

   For addressed comments:
     "Fixed in <commit_sha>. <brief description of what changed>."

   For already-addressed comments:
     "Already addressed in <commit_sha> — <field/code> now uses <X>."

   For pushback:
     "Not implementing. <technical reason with evidence>."

   Use:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
     -f body="Your response here"
   ```

   **IMPORTANT:** The reply endpoint REQUIRES the PR number in the path:
   `.../pulls/{number}/comments/{comment_id}/replies`
   NOT `.../pulls/comments/{comment_id}/replies` (this returns 404).

   This is NOT optional. Reviewers need closure on every comment.

8. REPORT
   Summarize:
   - What you fixed (with file:line references)
   - What you pushed back on (with technical reasoning)
   - What quality checks passed
   - Remind the user: nothing is committed — review before committing
```

## Fetching PR Data

```bash
# Get PR diff
gh pr diff <number> --repo owner/repo

# Get all review comments (inline)
gh api repos/{owner}/{repo}/pulls/{number}/comments

# Get general review thread comments
gh api repos/{owner}/{repo}/pulls/{number}/reviews

# Get issue/PR description
gh pr view <number> --repo owner/repo
```

## Already-Addressed Check

Before implementing anything, check if a comment was addressed in a later commit:

```bash
git log --oneline origin/main..HEAD
git diff origin/main -- <file>
```

If the comment is already addressed, note it and skip — do not re-implement.

## Validity Evaluation

```
FOR each unaddressed comment:

  Is the suggestion technically correct for THIS codebase?
    Check actual files, patterns, conventions in use.
    A suggestion that is "best practice" elsewhere may be wrong here.

  Does it break existing functionality or tests?
    grep/read for usage before changing interfaces.

  Does it violate YAGNI?
    If the feature/interface is unused, flag it rather than expand it.

  Does it conflict with an architectural decision already made?
    Check CLAUDE.md, AGENTS.md, or prior commits for intent.

  Is it consistent with the rest of the codebase?
    "The rest of the codebase uses X" is valid. Verify it's actually true.
```

## Pushing Back on Invalid Feedback

When a comment is technically wrong:

```
✅ "Pushing back: [specific technical reason]. [Evidence from codebase].
   Current approach is correct because [reason]."

❌ "I'll implement that" (when it's wrong)
❌ "Great point!" (performative)
❌ Silent non-implementation
```

State pushback clearly and specifically. Always reply in the GitHub thread — reviewers need closure.

```bash
# Reply to a specific inline comment thread
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body="Your technical response here"
```

## When to Ask the User

Ask when:
- The right fix is unclear and multiple valid interpretations exist
- The comment conflicts with an existing architectural decision
- The comment requires a tradeoff the user should make (e.g. breaking change vs. compat)
- You genuinely cannot verify correctness from the codebase alone

Ask ALL ambiguous questions in a single message. Do not interleave asking and implementing.

## Quality Gate Commands

```bash
make lint          # ruff + mypy
poetry run pytest tests/unit -n 4          # fast unit tests
poetry run pytest tests/unit tests/integration -n 4  # if integration available
```

If lint or tests fail after your changes: fix them before reporting. Do not report "done" while broken.

## Red Flags — Stop and Re-evaluate

| Thought | Reality |
|---------|---------|
| "This seems right, I'll just implement it" | Check the codebase first. Reviewer may lack context. |
| "I'll implement first, ask about the ambiguous ones later" | Ask ALL ambiguous items FIRST. Items may interact. |
| "I'll commit so the user can see the diff on GitHub" | Never commit. Show the diff locally. |
| "The reviewer is an expert, so they must be right" | Verify against THIS codebase. Experts miss context. |
| "I already pushed back, I should just implement it" | Stand by correct pushback unless user overrides. |
| "I'll skip the lint run, the change is tiny" | Run the quality gate. Always. |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Implementing before reading all comments | Survey all first, then act |
| Deciding on ambiguous items unilaterally | Ask the user — it's their codebase |
| Committing changes | Never. Stage and report. |
| Skipping quality checks | Always run `make lint` + tests |
| Applying feedback that was already addressed | Check git diff vs main first |
| Implementing feedback that breaks interfaces | grep for callers before changing signatures |
| Not replying to comments on GitHub | Reply to EVERY comment — reviewers need closure |
| Using wrong reply API path (missing PR number) | Must be `pulls/{number}/comments/{id}/replies`, NOT `pulls/comments/{id}/replies` |

## Reporting Format

After completing all changes:

```
## PR Feedback Summary

### Addressed
- Comment 1 (alice): Fixed. Changed X to Y in `src/foo/bar.py:42`. Reason: [why valid].
- Comment 4 (bob): Fixed. Updated call sites in `bruteforce_backend.py:18`, `faiss_backend.py:22`.

### Pushed Back
- Comment 3 (alice): Not implementing. [Technical reason with evidence].
  Suggest replying: "[draft reply text]"

### Quality Checks
- make lint: passed
- Unit tests (42 tests): passed

### Next Steps
Nothing is committed. Review the changes with `git diff` and commit when ready.
```