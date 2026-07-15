---
name: daily-small-refactoring-based-on-github-issue
description: Raise refactoring PR for github issue
---

## 
Look at the GitHub issues I (@NaoyaMiyagawa) raised and assigned to myself. If there's no linked standing PR for the part of the work you are about to do, raise a PR to work on it. But I don't want a mess in the PR, so the code changes should preferably be fewer than 200 lines in total, so that the other devs and I can review them easily without a big context switch from my main work.

If one PR cannot resolve the issue, you can edit the issue to record progress in a checklist so the next round can continue working on it separately.

Use skills for writing code and creating PR. When creating a git branch, run `git fetch --all`, then create the branch based on "origin/develop".
Fix CI errors until linter and tests pass on CI.

## Review
Do in this flow:

1. Self-review
2. Fix + Push
3. Cross-review using different ai model (Codex) + Leave a comment about review
4. Fix + Push

## "Do not" s
- Don't create more than 2 PR per run. Limiting the number so as not to mess with the PR listing.
- Don't create new PRs if there are more than or equal to 2 of my open PRs for refactoring/fixing from this routine.