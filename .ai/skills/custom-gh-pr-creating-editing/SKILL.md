---
name: custom-gh-pr-creating-editing
description: Creating/Editing GitHub pull request with better title and comprehensive description for the current branch. Use when the user asks for creating/editing a PR.
---

# Custom GitHub PR Creating/Editing

## Command
Use GitHub CLI.

## Reviewers (Copilot)

Always **assign GitHub Copilot as a reviewer** on the PR (not only a `@copilot` mention in the description).

### `gh` version gate (required)

Before using Copilot reviewer flags on `gh pr create` or `gh pr edit`:

1. Run `gh version` and confirm the CLI version is **≥ 2.88**.
2. If `gh` is older than 2.88, **do not** pass `--reviewer` / `--add-reviewer` for Copilot. Create or edit the PR without those flags, then tell the user to add Copilot in the GitHub PR UI (**Reviewers** → **Copilot**).

### Exact reviewer handle (strict)

Use **only** the quoted literal **`'@copilot'`** in `gh` flags:

- `--reviewer '@copilot'`
- `--add-reviewer '@copilot'`

**Never** use unquoted `@copilot`, bare `copilot`, `github-copilot`, `copilot-pull-request-reviewer`, or any other invented bot login. Wrong handles cause API failures and pointless agent retries.

```bash
gh pr create ... --reviewer '@copilot'
gh pr edit --add-reviewer '@copilot'
gh pr edit <number> --add-reviewer '@copilot'
```

### Workflow

- **Creating a PR:** pass `--reviewer '@copilot'` on `gh pr create` (combine with other `--reviewer` values if needed).
- **Editing an existing PR:** if Copilot is not already listed under reviewers, run `gh pr edit --add-reviewer '@copilot'` (with the PR number if not on that branch: `gh pr edit <number> --add-reviewer '@copilot'`).
- Before adding, you may confirm with `gh pr view --json reviewRequests` to avoid duplicate requests when the API rejects duplicates.

### On failure

If `gh pr create` or `gh pr edit` fails when adding the Copilot reviewer:

- **Do not** guess alternate bot usernames or retry with invented logins.
- Finish PR create/edit without the Copilot reviewer flag if needed.
- Tell the user explicitly: open the PR on GitHub → **Reviewers** → add **Copilot** in the UI.

Requires [GitHub Copilot code review](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/request-a-code-review/use-code-review) on the org/repo.

## Post-create review (independent Codex pass)
After creating the PR, run an **independent review with Codex CLI** — a different model from Claude Code, for an unbiased, different-perspective check.

**Review against the applicable coding-standard skills**, not generic advice. Pick the skills relevant to what the diff touches, e.g.:

- Laravel app code → `~/dotfiles/.ai/skills/custom-laravel-coding/SKILL.md`
- Pest/feature tests, factories → `~/dotfiles/.ai/skills/custom-laravel-writing-tests/SKILL.md`
- PHP formatting/lint, static analysis, tests → `~/dotfiles/.ai/skills/custom-php-running-{linter,static-analysis,test}/SKILL.md`
- Blade email templates → `~/dotfiles/.ai/skills/custom-email-html-template-review/SKILL.md`

Use the `/custom-pr-self-review` command (it loads these standards and includes the Codex step), or invoke Codex directly:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
codex exec "Review \`gh pr diff\` for this PR against the applicable coding-standard skills under ~/dotfiles/.ai/skills/ (read the ones relevant to the changed files for criteria). Flag violations, bugs, risks, and missing tests with file:line and a concrete fix. Do not edit files."
```

Skip only if Codex is rate-limited/unauthenticated; note that you couldn't get the second opinion. Surface its findings to the user — don't silently accept or discard them.

## Assignees
Assign @NaoyaMiyagawa.

## Labels
When it's a refactoring work, tag "Refactoring".

## Title
When the branch or PR is Jira-driven (ticket key in the branch name, or the work clearly maps to a Jira issue you can identify), set the GitHub PR title to **bracketed issue key, space, then title**: `[KEY] Title` where `KEY` is the Jira issue key (e.g. `AN-1000`) and `Title` is the Jira **Summary** verbatim (no rephrasing).

Example: `[AN-1000] User Management Page`

If you only have the key, fetch Summary from Jira (CLI or UI) before `gh pr create` / `gh pr edit`. Prefer this format over an invented title unless the repository documents a different naming rule that takes precedence.

**The title must be scannable at a glance.** A reviewer browsing the PR list should grasp what the PR does without opening it. Lead with the outcome, not the mechanics. Avoid stacked qualifiers, internal-only jargon, or trailing "(...)" notes that belong in the body.

- Good: `[REFACTOR] Use model-binding in Switch Organization endpoint`
- Bad:   `[REFACTOR] Refactor SwitchOrganizationRequest to remove authorize() block and migrate org_id to route param for cleaner auth (SonarCloud)`

## Description

### Keep it concise
Long PR descriptions hurt review more than they help. The diff and commit messages already say *what* changed; the description's job is **why** and the small handful of non-obvious notes a reviewer needs.

- Lead with the motivation in 1–3 sentences. Skip a "Background" preamble if the title already conveys it.
- List concrete changes as short bullets, not paragraphs. One bullet per behavioural change is enough — don't enumerate every touched file (Copilot's reviewed-files table covers that).
- Move per-line rationale to inline PR review comments on your own diff (single-PR self-review), not into the description.
- Cut "Notes" / "Behavioural notes" / "Further comments" sections unless they carry information not derivable from the diff (e.g. an out-of-scope decision, a follow-up PR, a non-obvious test gap).
- Validation logs go inside the `<details>` block (see below) so they don't dominate the visible body.

If the resulting body feels short, that's the goal. A reviewer should be able to read it in under 30 seconds.

### Repository PR template
Before drafting or editing the PR body, look for the repo's GitHub pull request template (common paths: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, or `.github/PULL_REQUEST_TEMPLATE/*.md`). **Follow that template:** keep its section headings and fill every section it defines; add the rules below (references, Jira, validation) *inside* the template structure rather than ignoring the template. If the repo has no template, use a clear structured body consistent with team practice.

### Reference

**Rule (enforced):** Every GitHub Issue or Pull Request reference (`#{number}`, full `https://github.com/...` URL, or `owner/repo#{number}`) **must** be written as its own bullet item starting with `- ` on its own line. This is the only way GitHub's UI expands the reference into the linked page's title.

```md
- #{issue_number}
```

- One reference per `- ` bullet line — never two refs on the same line.
- The `- ` bullet must be the start of a new line (blank line before the list if it follows a paragraph), or GitHub will not expand it.
- **Never embed a reference inline** inside a sentence or a change bullet (e.g. `Fixes the bug from #123`). Inline refs still render but defeat title expansion and make the line hard to scan — pull the ref onto its own `- ` line instead.

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
