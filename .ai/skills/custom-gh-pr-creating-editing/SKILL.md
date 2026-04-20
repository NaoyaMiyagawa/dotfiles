---
name: custom-gh-pr-creating-editing
description: Creating/Editing GitHub pull request with better title and comprehensive description for the current branch. Use when the user asks for creating/editing a PR.
---

# Custom GitHub PR Creating/Editing

## Command
Use GitHub CLI.

## Reviewers (Copilot)

Always **assign GitHub Copilot as a reviewer** on the PR (not only a `@copilot` mention in the description). Use the GitHub CLI handle **`@copilot`** so Copilot code review runs.

- **Creating a PR:** pass `--reviewer @copilot` on `gh pr create` (combine with other `--reviewer` values if needed).
- **Editing an existing PR:** if Copilot is not already listed under reviewers, run `gh pr edit --add-reviewer @copilot` (with the PR number if not on that branch: `gh pr edit <number> --add-reviewer @copilot`).

Before adding, you may confirm with `gh pr view --json reviewRequests` to avoid duplicate requests when the API rejects duplicates.

Requires [GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review) and a recent `gh` (reviewer support for Copilot is documented there).

## Assignees
Assign @NaoyaMiyagawa.

## Labels
When it's a refactoring work, tag "Refactoring".

## Title
When the branch or PR is Jira-driven (ticket key in the branch name, or the work clearly maps to a Jira issue you can identify), set the GitHub PR title to **bracketed issue key, space, then title**: `[KEY] Title` where `KEY` is the Jira issue key (e.g. `AN-1000`) and `Title` is the Jira **Summary** verbatim (no rephrasing).

Example: `[AN-1000] User Management Page`

If you only have the key, fetch Summary from Jira (CLI or UI) before `gh pr create` / `gh pr edit`. Prefer this format over an invented title unless the repository documents a different naming rule that takes precedence.

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
If GitHub PR template has a dedicated section for Jira ticket link and you find applicable ticket based on the ticket key in branch name, put a ticket link in the dedicated section in the template. (PR title should still use the **`[KEY] Title`** pattern from the **Title** section when the work is Jira-driven, with `Title` taken from Jira Summary.)

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
