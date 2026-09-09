---
name: slack-review-request
description: Use when the user wants to request a code review on a PR by posting it to the backend Slack channel. Gathers PR context, composes a short summary with GitHub issue links, and sends a draft message tagging the reviewers.
---

# Slack Review Request

## Overview

Post a PR review request to the backend Slack channel. Tag the reviewers, include a short summary of the PR, and link to the related GitHub issues. Always send as a draft so the user can review before it goes out.

## Process

### 1. Gather PR Context

```bash
# Single call — includes author for exclusion in reviewer recommendations
gh pr view --json title,url,number,body,labels,author
```

If no PR exists on the current branch, ask the user for the PR number or URL.

For commit-message-based issue references:

```bash
git log --oneline origin/main..HEAD
```

### 2. Extract GitHub Issue Links

Parse issue references from:
- PR body (`Closes #123`, `Fixes #456`, `https://github.com/org/repo/issues/123`)
- PR title (e.g. `[CON-625]`)
- Commit messages on the branch

Always expand shorthand references (`#123`) to full URLs using the PR's base repository (e.g. `https://github.com/org/repo/issues/123`).

Collect all unique GitHub issue URLs.

### 3. Compose the Message

Format:

```
<@UXXXXXXXX> <@UYYYYYYYY> <@UZZZZZZZZ> (category):

<summary> [<ticket-id>]

[<issue-title-1>](<github-issue-url-1>)
[<issue-title-2>](<github-issue-url-2>)
```

Rules:
- **Reviewer tags** — always use Slack ID format `<@UXXXXXXXX>`, never `@DisplayName`
- **Category** — infer from PR labels or content (e.g. `(security)`, `(feature)`, `(fix)`, `(infra)`)
- **Summary** — one line, plain language, what the PR does
- **Ticket ID** — Linear issue ID if present (e.g. `[CON-625]`)
- **Issue links** — markdown links with issue title as text and GitHub URL as href, one per line. Fetch issue titles with `gh issue view <number> --json title`

### 4. Find the Backend Channel

```bash
# Search for the backend channel
slack_search_channels("backend")
```

Cache the channel ID for sending.

### 5. Send as Draft

Use `mcp__plugin_slack_slack__slack_send_message_draft` so the user can review before sending:

```
mcp__plugin_slack_slack__slack_send_message_draft(
  channel_id="<backend-channel-id>",
  message="<composed message>"
)
```

### 6. Report

Tell the user:
- Draft posted to backend channel
- Link to view the draft in Slack
- Remind them to check that GitHub link previews render correctly before sending

## Reviewer Tags

Reviewers depend on the repo:

| Repo / Context | How to detect | Reviewers |
|----------------|---------------|-----------|
| Backend Console | Repo name contains `console` or is in the Console GitHub org | Varun, Kai, Raja Badri (resolve to Slack IDs) |
| Other repos | Everything else | Recommend from git history (see below), then confirm with user |

If unsure whether a repo is Console, ask the user.

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
3. Exclude the PR author (from `gh pr view --json author`)
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
| Using `#123` instead of full URL | Always expand to `https://github.com/org/repo/issues/123` |
| Verbose summary | Keep to one line — reviewers skim |
| Forgetting ticket ID | Check PR title, body, and branch name for Linear IDs |
| Using `@DisplayName` in Slack | Always resolve to `<@UXXXXXXXX>` Slack ID format |
| GitHub link previews missing | Remind user to verify previews render in draft before sending |
