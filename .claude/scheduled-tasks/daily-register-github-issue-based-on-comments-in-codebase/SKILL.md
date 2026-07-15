---
name: daily-register-github-issue-based-on-comments-in-codebase
description: Register GitHub issues based on TODO/FIX/REFACTOR comments in the codebase
---

## Prepare
Do git-pull to fetch the latest state of "develop" branch.

## Main
Grep TODO/FIX/REFACTOR comments in the codebase that were written by me, and also, if there's no GitHub issue for it, create a new GitHub issue with `[TODO]`/`[FIX]`/`[REFACTOR]` prefix in the title. Refer to skills for creating PR.

Write down the original comment as quote in the issue description e.g.

> TODO: Refactor with DTO
> (app/Services/XxxService.php:80)

## Do-not Rules
- Don't create GitHub issue if the comments are not written by me.
- Don't duplicate GitHub issues. If there's a very similar one already, edit its description to cover the comments portion.
- Don't assign me as an assignee. I'll review the new issues and assign myself by myself, so that another routine picks it up to work on later.