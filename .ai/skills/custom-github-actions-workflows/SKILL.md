---
name: custom-github-actions-workflows
description: Applies GitHub Actions authoring conventions — composite actions, step naming, multi-flag commands, and repo-local workflow rules. Use when adding or editing anything under .github/workflows/ or .github/actions/.
---

# GitHub Actions workflows

1. **Read the repo's workflow README first.** If `.github/workflows/README.md` exists, its rules win over these (for example action-pinning style imposed by org tooling). When you learn such a repo- or org-imposed constraint mid-task and no README holds it, add one beside the files so the next reader, human or agent, gets the context. Formatting preferences (step spacing, comment style) live in this skill, not in the repo README.
2. **A repeated step block is a composite action.** When the same sequence of steps (checkout + toolchain setup + dependency install, and the like) appears in two jobs or workflows, extract it to `.github/actions/<name>/action.yml` and `uses: ./.github/actions/<name>` from each site.
3. **One flag per line, each with its reason.** Split a multi-flag `options:` or `run:` command so each flag sits on its own line with a comment stating what the option does and why it's there. Word the comment so it stays true when the value is retuned: describe the option's role, never the number set today. A single opaque line (a checksum, a `cat` of a report) gets the same one-line comment.
4. **No `name:` that restates `uses:`.** A step whose action path already says what it does (`uses: ./.github/actions/setup-node`) carries no `name:`; keep `name:` for `run:` steps and for actions whose purpose isn't obvious from their path.
5. **Blank line between steps.** Separate every step in a `steps:` list, and every top-level block in an `action.yml`, with one blank line so each step reads as its own unit.
