---
name: custom-gh-address-comments
description: Help address review/issue comments on the open GitHub PR for the current branch using gh CLI; verify gh auth first and prompt the user to authenticate if not logged in.
metadata:
  short-description: Custom Address comments in a GitHub PR review
---

# PR Comment Handler

Guide to find the open PR for the current branch and address its comments with gh CLI. Run all `gh` commands with elevated network access.

Prereq: ensure `gh` is authenticated (for example, run `gh auth login` once), then run `gh auth status` with escalated permissions (include workflow/repo scopes) so `gh` commands succeed. If sandboxing blocks `gh auth status`, rerun it with `sandbox_permissions=require_escalated`.

## 1) Inspect comments needing attention
- Run scripts/fetch_comments.py which will print out all the comments and review threads on the PR
  - script: `~/dotfiles/.ai/skills/custom-gh-address-comments/scripts/fetch_comments.py`

## 2) Ask the user for clarification
- Number all the review threads and comments and provide a short summary of what would be required to apply a fix for it
- Ask the user which numbered comments should be addressed
- Don't need to show already resolved ones, or ones that you don't need any fix.

## 3) If user chooses comments
- Apply fixes for the selected comments
- Give a template for user to answer

## 4) Commit a fix one by one
- If user wants you to commit, commit it. If not, ask user if he wants you to commit after fixing one by one.
- This is to leave a commit hash as a reply to the review comment. (e.g. `Fixed: {commit hash}`)

## 5) Push and reply to comments
- Reply to the original comment with `Fixed: {commit hash}` if it's addressed. Don't close the thread if the comment is not from a bot.
- If it's a review comment from a bot such as Copilot, Codex, close the thread after replying.
- Give list of your replies to user at the end for reference.

Notes:
- If gh hits auth/rate issues mid-run, prompt the user to re-authenticate with `gh auth login`, then retry.
