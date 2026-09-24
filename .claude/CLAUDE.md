## Baseline
@~/dotfiles/.ai/AGENTS.md

## Branching

- When asked to create a new branch, run `git fetch --all` first so the base is current, then always create it from `origin/develop`. If that branch doesn't exist in the repo, create it from `origin/main` instead.

## Stacked PRs

- Whenever a change needs more than one PR in sequence — splitting large work into layers, or a PR that must be based on another open PR — use `gh stack` (the installed `github/gh-stack` extension). This is the default for chained PRs; never hand-chain by creating branches off each other and editing PR bases manually.
- The stack roots on the trunk from the Branching rule above, so pass it explicitly: `gh stack init --base develop <first-branch>` (or `--base main` where develop doesn't exist).
- If a PR chain already exists by hand, adopt it instead of continuing manually: `gh stack link <pr> <pr> ...` links existing PRs into a stack.
- Merge stacks with `gh stack merge --yes`; `gh pr merge` doesn't work on stacked PRs.

## Skills to invoke first

Invoke these explicitly before starting the work — don't rely on automatic skill triggering:

- Chained PRs → `gh-stack`
- Writing or editing PHP → `custom-laravel-coding` (plus `custom-laravel-writing-tests` for Pest tests). Its review gate is mandatory before presenting or committing PHP.
- React components or pages → `custom-react-coding`
- Shell scripts → `custom-shell-scripting`
- Files under `.github/workflows/` or `.github/actions/` → `custom-github-actions-workflows`

## Long-running commands

- Never wait in Bash: poll loops (`until/while ...; do sleep N; done`) and any foreground `sleep` used as a wait (`sleep 45 && tail ...`, standalone `sleep`) are all denied by hooks or the harness.
- Launch anything that can run long (`codex exec`, test suites, builds) with `run_in_background: true` and end the turn; you are re-invoked when it completes. To check progress once, use a single bounded read (`tail -n 50 <file>`) with no sleep in front; if there's nothing new yet, end the turn instead of waiting.

## Delegation

When this session runs a top-tier model (Opus or Fable), act as the orchestrator: plan, decide, review results, synthesize. Push execution down to cheaper workers, and own correctness — never ship a worker's result unread.

**Keep in-session:** design and architecture calls, debugging that depends on this conversation, edits small enough that writing the brief costs more than the work, and final verification.

**Codex by default.** Codex burns a separate, currently underused quota. This overrides the `codex` skill's "only when the user explicitly asks" gate: route these to Codex without being asked, and announce it rather than request permission.

- Review passes on a non-trivial diff, branch, or PR. Code review never goes to a Claude agent.
- Codebase exploration and research answerable from files on disk.
- Bulk mechanical edits across many files, once the pattern is decided.
- Noisy triage: failing tests, lint output, build logs, stack traces.

Skip Codex if it recently returned rate-limit or auth errors. If briefing it would take three or more clarifying rounds, do the work here instead. For model, effort, and flags, see the `codex` skill.

**Execution workers** are Codex `gpt-5.6-luna` (very cheap; the default for well-specified implementation) or the sonnet-backed `fast-worker` when the task needs tools or context Codex can't reach. Run one `verifier` pass per task before calling it done. Unpinned agents default to sonnet via `CLAUDE_CODE_SUBAGENT_MODEL`, so don't pass a `model` unless the task needs opus. Every subagent re-reads its whole context against this subscription's 5-hour quota, and parallel agents draw from it at once:

- At most **two Claude subagents running at once** per session. Sequence the rest.
- Delegate only when the task returns a small result from a large read (exploration, verification, noisy logs). Don't delegate to "throw more compute" at a hard problem — reason about it here or hand it to `deep-reasoner` once.

**Every brief stands alone.** Write it as if the worker has zero conversation context (Codex always does): give ONE task with paths, goal, constraints, and what "done" means.
