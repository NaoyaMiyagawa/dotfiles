---
name: custom-gh-address-comments
description: Help address review/issue comments on the open GitHub PR for the current branch using gh CLI; verify gh auth first and prompt the user to authenticate if not logged in.
metadata:
  short-description: Custom Address comments in a GitHub PR review
---

# PR Comment Handler

Find the open PR for the current branch and address its review comments with the gh CLI.

Prereq: `gh auth status` must report a logged-in account. If it doesn't, ask the user to run `gh auth login` and stop. If the sandbox blocks network access for `gh`, rerun the command with escalated permissions rather than substituting another tool.

## 1) Inspect comments needing attention

- Run `~/dotfiles/.ai/skills/custom-gh-address-comments/scripts/fetch_comments.py` — it prints every comment and review thread on the PR.

## 2) Ask the user which comments to address

- Number all the review threads and comments and give a short summary of what a fix would require. Skip threads that are already resolved or need no fix. Use this template:
  ```md
  #: 1
  File:Line: {filename}:{line numbers}
  Summary: {summary}
  Needs a fix?: {Yes/No} — {Reason}
  ────────────────────────────────────────
  #: 2
  ...
  ────────────────────────────────────────
  ```
- Then state the default and ask for exceptions only: "Default: fix every thread marked Needs a fix: Yes, commit each fix, push, and reply on each thread. Reply `go` to proceed or list exceptions (e.g. `skip #3, no reply`)." Don't hand over a fill-in template — one line covers it.

## 3) Apply fixes

- Apply fixes for the comments the user selected

## 4) Commit a fix one by one

- Commit each fix separately (per the `custom-git-committing` skill) unless the user opted out — one commit per comment gives each reply a hash to cite (`Fixed: {commit hash}`).

## 5) Push and reply to comments

- Reply to each addressed comment with `Fixed: {commit hash}` plus one plain sentence on how. Never resolve a thread opened by a human reviewer; resolve a bot's thread after replying.
- End with the list of replies you posted, with their URLs.

Notes:

- If gh hits auth/rate issues mid-run, prompt the user to re-authenticate with `gh auth login`, then retry.
