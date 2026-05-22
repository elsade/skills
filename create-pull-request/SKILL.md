---
name: create-pull-request
description: Use when creating a pull request that should be linked to a Linear issue, or when committing, pushing, and opening a PR in one workflow. Handles commit, push, gh pr create, and bidirectional Linear↔GitHub linking.
---

# Create Pull Request

## Overview

Commit staged changes, push, open a GitHub PR with a Linear issue link, then attach the PR back to the Linear issue. Always link in both directions.

## Process

### 1. Gather Context

Run these in parallel before doing anything:

```bash
git status
git diff --staged
git log --oneline -10        # match commit message style
```

### 2. Commit

Follow the repo's commit style (usually conventional commits). Always include the Linear issue ID and `Co-Authored-By`:

```bash
git commit -m "$(cat <<'EOF'
type(scope): short description

Longer body if needed.

Linear: CON-XXX
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 3. Push

```bash
git push -u origin <branch-name>
```

### 4. Create the PR

```bash
gh pr create --title "type(scope): short description" --body "$(cat <<'EOF'
## Summary
- Bullet 1
- Bullet 2

## Test plan
- [ ] Step 1
- [ ] Step 2

Closes https://linear.app/vijil/issue/CON-XXX/...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- Use `Closes <linear-url>` (not just a bare URL) so Linear's GitHub integration picks it up
- Keep the title under 70 characters

### 5. Capture the PR URL

`gh pr create` prints the PR URL on success. Read it from stdout — you'll need it for step 6.

### 6. Link PR back in Linear

Use `mcp__linear-server__save_comment` to post the PR link on the Linear issue.

Get the `issueId` (UUID) from a prior `list_issues` or `get_issue` call if you only have the identifier (e.g. CON-317).

```
mcp__linear-server__save_comment(
  issueId: "<linear-issue-id>",
  body: "GitHub PR opened: https://github.com/org/repo/pull/NNN"
)
```

## Key Rules

- **Always link both directions**: PR body → Linear, and Linear comment → PR
- **Don't rely on Linear's auto-detection** from branch names — always comment explicitly
- If no Linear issue exists, skip steps 6 and omit `Closes` from the PR body

## Title Conventions

| Type | Format |
|------|--------|
| Bug fix | `fix(scope): description` |
| Feature | `feat(scope): description` |
| Infra/helm | `feat(helm): description` |
| Docs | `docs(scope): description` |