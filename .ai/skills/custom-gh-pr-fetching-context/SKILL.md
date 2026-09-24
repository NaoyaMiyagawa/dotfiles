---
name: custom-gh-pr-fetching-context
description: Fetches GitHub pull request context for the current branch. Use when the user asks for PR context or PR summary, or when implementation depends on open PR details.
---

# Custom GitHub PR Context Fetch

Run `gh pr view --json title,body,comments` and summarize the task context. If the branch has no PR, say so and continue without it unless the user requires PR-based work.
