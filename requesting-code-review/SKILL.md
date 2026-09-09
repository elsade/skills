---
name: requesting-code-review
description: Use when the user wants to request a code review on a PR by posting it to the backend Slack channel. Gathers PR context, composes a short summary with GitHub issue links, and sends a draft message tagging the reviewers.
---

# Requesting Code Review

## Overview

Post a PR review request to the backend Slack channel. Tag the reviewers, include a short summary of the PR, and link to the related GitHub issues. Always send as a draft so the user can review before it goes out.

## Process

### 1. Gather PR Context

Run in parallel:

```bash
# Current branch PR (or user provides PR number)
gh pr view --json title,url,number,body,labels

# Get linked issues from PR body or commits
gh pr view --json body
```

If no PR exists on the current branch, ask the user for the PR number or URL.

### 2. Extract GitHub Issue Links

Parse issue references from:
- PR body (`Closes #123`, `Fixes #456`, `https://github.com/org/repo/issues/123`)
- PR title (e.g. `[CON-625]`)
- Commit messages on the branch

Collect all unique GitHub issue URLs.

### 3. Compose the Message

Format:

```
@Varun @Kai @Raja Badri <category>:

<summary> [<ticket-id>]

<github-issue-url-1>
<github-issue-url-2>
```

Rules:
- **Category** — infer from PR labels or content (e.g. `(security)`, `(feature)`, `(fix)`, `(infra)`)
- **Summary** — one line, plain language, what the PR does
- **Ticket ID** — Linear issue ID if present (e.g. `[CON-625]`)
- **Issue links** — full GitHub URLs, one per line

### 4. Find the Backend Channel

```bash
# Search for the backend channel
slack_search_channels("backend")
```

Cache the channel ID for sending.

### 5. Send as Draft

Use `slack_send_message_draft` so the user can review before sending:

```
mcp__plugin_slack_slack__slack_send_message_draft(
  channel_id: "<backend-channel-id>",
  message: "<composed message>"
)
```

Enable `unfurl_app_links: true` when the user sends the final message so GitHub links render with rich previews.

### 6. Report

Tell the user:
- Draft posted to backend channel
- Link to view the draft in Slack
- Remind them to review and send

## Reviewer Tags

Reviewers depend on the repo:

| Repo / Context | Reviewers |
|----------------|-----------|
| Backend Console | @Varun @Kai @Raja Badri |
| Other repos | Recommend from git history (see below), then confirm with user |

### Recommending Reviewers from Git History

For non-Console repos, analyze the PR's changed files to suggest reviewers:

```bash
# Get list of changed files in the PR
gh pr diff <number> --name-only

# For each changed file, find top contributors (excluding the PR author)
git log --format='%aN' --since='6 months ago' -- <file> | sort | uniq -c | sort -rn | head -5
```

Aggregate across all changed files:
1. Count how many changed files each contributor has touched
2. Weight by recency — recent commits matter more
3. Exclude the PR author
4. Pick top 2–3 contributors as recommended reviewers

Present recommendations to the user:

```
Recommended reviewers based on git history of changed files:
  1. Alice (touched 4/6 changed files, most recent: 2 weeks ago)
  2. Bob (touched 3/6 changed files, most recent: 1 month ago)

Who should I tag?
```

User confirms or overrides before composing the message.

### Resolving GitHub Handles to Slack Users

Git log returns display names. To tag reviewers in Slack:

1. Get the GitHub username from the commit:
   ```bash
   git log --format='%aN|%aE' --since='6 months ago' -- <file> | sort -u
   ```
   The email often contains the GitHub username (e.g. `user@users.noreply.github.com`).

2. Search for the person in Slack by name or email:
   ```
   slack_search_users("<display name or email>")
   ```

3. Use the returned Slack user ID to format the tag as `<@UXXXXXXXX>` in the message.

If a Slack match can't be found, ask the user for the correct Slack handle or ID. Do not send the message with unresolved reviewers.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Sending directly without draft | Always draft first — user reviews before sending |
| Missing GitHub issue links | Parse PR body, title, and commits for references |
| Verbose summary | Keep to one line — reviewers skim |
| Forgetting ticket ID | Check PR title, body, and branch name for Linear IDs |
| Not enabling link unfurling | Remind user to send with unfurl_app_links for rich previews |
