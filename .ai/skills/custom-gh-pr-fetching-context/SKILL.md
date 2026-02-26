---
name: custom-gh-pr-fetching-context
description: Fetches GitHub pull request context for the current branch. Use when the user asks for PR context or PR summary, or when implementation depends on open PR details.
---

# Custom GitHub PR Context Fetch

## Scope

Run this only for PR-related requests. Do not run on every task.

## Commands

```bash
gh pr view --json title --jq .title
gh pr view --json body --jq .body
gh pr view --json comments --jq .comments
```

## Behavior

1. Run the commands above and summarize key task context.
2. If no PR exists for the current branch, report that PR context is unavailable and continue with non-PR task context.
3. Do not block implementation when PR is missing unless user explicitly requires PR-based work.
