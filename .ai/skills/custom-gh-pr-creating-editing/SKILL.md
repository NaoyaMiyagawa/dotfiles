---
name: custom-gh-pr-creating-editing
description: Create or edit a GitHub PR for the current branch — title format, concise body, reference bullets, labels, and assignee. Use when asked to create or edit a PR.
---

# Custom GitHub PR Creating/Editing

## Title

- **Jira-driven** (key in branch, named by user, or created in session): `[KEY] Summary` verbatim from Jira (`[AN-1000] User Management Page`). Fetch Summary from Jira if you only have the key.
- **Not Jira-driven**: `[TAG] <Area or tool> - <Outcome>` matching the label (`[FIX] API Doc - Show one document in trigger example`, `[REFACTOR] Switch Organization endpoint - Use model-binding`). Name the outcome, not mechanics; never invent a Jira key.
- **Sentry fix**: `[Sentry Fix] <outcome>`, or `[KEY] [Sentry Fix] <outcome>` once a Jira ticket exists.
- **Follow-up on shipped ticket**: reuse `[KEY]` — `[KEY] Follow up - <what this PR does>`. Review-fix follow-up: `[KEY] Follow up - Review fixes (#<earlier PR>)` on `<earlier branch>--follow-up`.
- **Stacked PRs**: every PR in a stack shares the same `[KEY]` (or bracketed effort tag) and ticket link. If only the last PR has screenshots, earlier PRs say `The last PR in the chain ({PR link}) has screenshots`.
- **Sibling series**: copy siblings' title prefix after `[KEY]` and milestone (`gh pr view <n> --json title,milestone`).

## Description

Follow the repo's PR template (`.github/pull_request_template.md` / `PULL_REQUEST_TEMPLATE*.md`) if one exists; place rules below inside its headings. Target a <30-second read above the fold:

- Lead with motivation in 1–3 sentences (skip "Background" if the title covers it).
- Short bullets per behavioural change — don't list every touched file. Put per-line rationale in inline review comments, not the body.
- Cut "Notes" sections unless they carry non-derivable info (out-of-scope decision, follow-up PR, test gap). **Link, don't duplicate** existing docs/tickets.
- For refactors moving a validation rule or guard, state where it lived and why.
- **Editing an existing PR**: preserve user-added screenshots, videos, and notes; edit only requested sections.
- **Unfamiliar subsystem/protocol**: add a reading guide at the bottom per `custom-gh-pr-reading-guide` (`~/dotfiles/.ai/skills/custom-gh-pr-reading-guide/SKILL.md`).
- **Before/after evidence or Sentry fix**: read [references/special-sections.md](references/special-sections.md).

### References (top of description)

Per global rule, every GitHub issue/PR reference sits on its own `- ` bullet line (blank line before list, never inline). Stack applicable blocks at the very top in this order:

```md
- close: #{issue_number}

Previous:
- #{base_pr_number}

Next:
- #{child_pr_number}
```

Use `close:` only when the PR fully resolves the issue.

### Validation run (end of description)

Omit entirely if no validation ran; otherwise fold at the bottom:

```md
<details>
<summary>Validation run:</summary>
- {command A}
</details>
```

## Metadata & post-create

- **Assignee**: `@NaoyaMiyagawa`.
- **Reviewers**: none unless user names them.
- **Labels**: use `Refactoring` / `[REFACTOR]` only when behaviour (including UI) is unchanged.
- **No review bots**: never `@`-mention review bots. Code is pre-reviewed by the `custom-general-coding` review gate; run `/custom-pr-self-review` only when asked (if this session didn't write the commits, note the gate may not have run and offer it).
- **Dependency bumps**: if the diff touches `package.json`, `composer.json`, a lockfile, or a workflow `uses:`, run `custom-gh-dependabot-assess` on the new PR right after creating it.
