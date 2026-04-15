---
name: custom-gh-pr-creating-editing
description: Creating/Editing GitHub pull request with better title and comprehensive description for the current branch. Use when the user asks for creating/editing a PR.
---

# Custom GitHub PR Creating/Editing

## Command
Use GitHub CLI.

## Reviewers
Request to @Copilot if it's not requested yet.

## Assignees
Assign @NaoyaMiyagawa.

## Labels
When it's a refactoring work, tag "Refactoring".

## Title
When the branch or PR is Jira-driven (ticket key in the branch name, or the work clearly maps to a Jira issue you can identify), set the GitHub PR title to **match the Jira ticket Summary** (the issue title). If you only have the key, fetch Summary from Jira (CLI or UI) before `gh pr create` / `gh pr edit`. Prefer this over an invented title unless the repository documents a different naming rule that takes precedence.

## Description

### Repository PR template
Before drafting or editing the PR body, look for the repo's GitHub pull request template (common paths: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, or `.github/PULL_REQUEST_TEMPLATE/*.md`). **Follow that template:** keep its section headings and fill every section it defines; add the rules below (references, Jira, validation) *inside* the template structure rather than ignoring the template. If the repo has no template, use a clear structured body consistent with team practice.

### Reference

When putting a reference links of GitHub Issues or Pull Requests, write it using bullet item (-) so that GitHub UI will display corresponding page title.
```md
- #{issue_number}
```

When the task is to solve a GitHub Issue, and the code changes covers the all required changes to solve the GitHub Issue, use `close:` prefix to auto-close the issue. This should be placed at the top of PR description.
```md
- close: #{issue_number}
```

When there is a base branch, and it has a PR, write this at the top of the description.
```md
Previous:
- #{pr_number}
```

When there is a branch based on the this branch, write this at the top of the description. (after "Previous" if there is.)
```md
Next:
- #{pr_number}
```

### Jira ticket link
If GitHub PR template has a dedicated section for Jira ticket link and you find applicable ticket based on the ticket key in branch name, put a ticket link in the dedicated section in the template. (PR title should still follow the **Title** section above when the work is Jira-driven.)

### Validation Run
If there are commands you used for validation, you can leave at the end of the description, but it should be written using "details" block not to mess the PR description.
```md
<details>
<summary>Validation run:</summary>
- {validation command A}
- {validation command B}
- ...
</details>
```
