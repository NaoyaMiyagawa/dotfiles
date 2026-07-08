---
name: custom-gh-pr-creating-editing
description: Create or edit the GitHub pull request for the current branch — title format, concise description, reference bullets, assignee, and a local different-model code review. Use when the user asks to create or edit a PR.
---

# Custom GitHub PR Creating/Editing

## Title
When the branch or PR is Jira-driven (ticket key in the branch name, or the work clearly maps to a Jira issue you can identify), set the GitHub PR title to **bracketed issue key, space, then title**: `[KEY] Title` where `KEY` is the Jira issue key (e.g. `AN-1000`) and `Title` is the Jira **Summary** verbatim (no rephrasing).

Example: `[AN-1000] User Management Page`

If you only have the key, fetch Summary from Jira (CLI or UI) before `gh pr create` / `gh pr edit`. Prefer this format over an invented title unless the repository documents a different naming rule that takes precedence.

**The title must be scannable at a glance.** A reviewer browsing the PR list should grasp what the PR does without opening it. Lead with the outcome, not the mechanics. Avoid stacked qualifiers, internal-only jargon, or trailing "(...)" notes that belong in the body.

- Good: `[REFACTOR] Use model-binding in Switch Organization endpoint`
- Bad:   `[REFACTOR] Refactor SwitchOrganizationRequest to remove authorize() block and migrate org_id to route param for cleaner auth (SonarCloud)`

When the PR is **not** Jira-driven, either lead with a short bracketed tag that mirrors the label (e.g. `[REFACTOR]`) or use no tag at all — never invent a Jira-style key.

## Description

### Keep it concise
Long PR descriptions hurt review more than they help. The diff and commit messages already say *what* changed; the description's job is **why** and the small handful of non-obvious notes a reviewer needs.

- Lead with the motivation in 1–3 sentences. Skip a "Background" preamble if the title already conveys it.
- List concrete changes as short bullets, not paragraphs. One bullet per behavioural change is enough — don't enumerate every touched file (the diff's file list already covers that).
- Move per-line rationale to inline PR review comments on your own diff (single-PR self-review), not into the description.
- Cut "Notes" / "Behavioural notes" / "Further comments" sections unless they carry information not derivable from the diff (e.g. an out-of-scope decision, a follow-up PR, a non-obvious test gap).
- **Link, don't duplicate.** When a detail already lives in a committed doc, issue, or ticket, link to it instead of pasting its content into the description — a second copy drifts from the source the moment either side changes. Keep the canonical version in one place and point the PR at it.
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

These blocks all sit at the top of the description; when more than one applies, stack them in this order — `close:`, then `Previous:`, then `Next:`, then the motivation.

When the task is to solve a GitHub Issue, and the code changes covers the all required changes to solve the GitHub Issue, use `close:` prefix to auto-close the issue. Place it at the very top.
```md
- close: #{issue_number}
```

When there is a base branch, and it has a PR, write this below the `close:` line (if any).
```md
Previous:
- #{pr_number}
```

When there is a branch based on this branch, write this after `Previous:` (if any).
```md
Next:
- #{pr_number}
```

### Jira ticket link
If GitHub PR template has a dedicated section for Jira ticket link and you find applicable ticket based on the ticket key in branch name, put a ticket link in the dedicated section in the template. (PR title should still use the **`[KEY] Title`** pattern from the **Title** section when the work is Jira-driven, with `Title` taken from Jira Summary.)

### Validation Run
If you ran validation commands, put them at the end of the description inside a `<details>` block so they don't dominate the body. If you ran none, omit the block entirely — don't leave an empty placeholder.
```md
<details>
<summary>Validation run:</summary>
- {validation command A}
- {validation command B}
- ...
</details>
```

## Assignees
Assign @NaoyaMiyagawa.

## Labels
When it's a refactoring work, tag "Refactoring".

## Code review (local, different model)
This repo does not use PR review bots — do not post any `@`-mention review trigger on the PR. After creating or editing the PR, run the review **locally with the Codex CLI** — a different model from Claude Code, for an unbiased, different-perspective check. Review against the applicable coding-standard skills under `~/dotfiles/.ai/skills/` (Laravel coding, Laravel tests, PHP linter/static-analysis/test, email templates), not generic advice.

Use the `/custom-pr-self-review` command (it loads these standards and includes the Codex step), or invoke Codex directly:

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
codex exec "Review \`gh pr diff\` for this PR against the applicable coding-standard skills under ~/dotfiles/.ai/skills/ (read the ones relevant to the changed files for criteria). Flag violations, bugs, risks, and missing tests with file:line and a concrete fix. Do not edit files."
```

Skip only if Codex is rate-limited/unauthenticated; note that you couldn't get the second opinion. Surface its findings to the user — don't silently accept or discard them.
