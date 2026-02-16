---
name: custom-gh-pr-review-fix
description: Address GitHub PR review comments with the project's one-comment-at-a-time workflow. Use when the user asks to fix PR comments, review feedback, or unresolved review discussions.
---

# Custom PR Review Fix Workflow

## Scope

Apply this skill only when the task is PR comment fixing/review feedback handling.

## Fetch Review Context

Use:

```bash
gh pr view --json comments --jq .comments
gh api repos/:owner/:repo/pulls/$(gh pr view --json number --jq .number)/comments
```

Ignore:

- comments from `sonarqubecloud`
- comments starting with `## Pull Request Overview`

## Execution Policy

1. Build a list of fixes from unresolved latest comments.
2. Implement only one review item at a time.
3. After each item, stop and wait for user approval before proceeding.
