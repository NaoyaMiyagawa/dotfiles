## Baseline
@~/dotfiles/.ai/AGENTS.md

## Branching

- When asked to create a new branch, run `git fetch --all` first so the base is current, then always create it from `origin/develop`. If that branch doesn't exist in the repo, create it from `origin/main` instead.

## Skills to invoke first

Invoke these explicitly before starting the work — don't rely on automatic skill triggering:

- Chained PRs → `gh-stack`. Root the stack on the trunk from the Branching rule: `gh stack init --base develop <first-branch>` (or `--base main`). Adopt a hand-made chain with `gh stack link <pr> <pr> ...`.
- A question about what a project or module does, or its requirements, business rules, or flows → `custom-obsidian-wiki-query` before reading the code. The wiki holds the work projects' specs and decisions that the code doesn't state.
- Writing or editing PHP → `custom-laravel-coding` (plus `custom-laravel-writing-tests` for Pest tests). Its review gate is mandatory before presenting or committing PHP.
- React components or pages → `custom-react-coding`
- Shell scripts → `custom-shell-scripting`
- Files under `.github/workflows/` or `.github/actions/` → `custom-github-actions-workflows`

## Long-running commands

- Launch anything that can run long (`codex exec`, test suites, builds) with `run_in_background: true` and end the turn; you are re-invoked when it completes. Poll loops and foreground `sleep` are denied. To check progress once, use a single `tail -n 50 <file>`.

## Delegation

When this session runs a top-tier model (Opus or Fable), act as the orchestrator: plan, decide, review results, synthesize. Push execution down to cheaper workers, and own correctness — never ship a worker's result unread.

**Keep in-session:** design and architecture calls, debugging that depends on this conversation, edits small enough that writing the brief costs more than the work, and final verification.

**Codex by default.** Codex burns a separate, currently underused quota. Route these to Codex without being asked, and announce it rather than request permission.

- Review passes on a non-trivial diff, branch, or PR. Code review never goes to a Claude agent.
- Codebase exploration and research answerable from files on disk.
- Bulk mechanical edits across many files, once the pattern is decided.
- Noisy triage: failing tests, lint output, build logs, stack traces.

Skip Codex if it recently returned rate-limit or auth errors. If briefing it would take three or more clarifying rounds, do the work here instead. Read `~/dotfiles/.ai/docs/CODEX.md` before the first Codex run of a session: it pins model and effort per task and overrides the `codex` skill's "explicit ask only" gate.

**Execution workers** are Codex `gpt-5.6-luna` (very cheap; the default for well-specified implementation) or the sonnet-backed `fast-worker` when the task needs tools or context Codex can't reach. Verify every task before calling it done: run the check inline, and hand it to `verifier` only when the output is noisy (a full test suite, a long build log). Unpinned agents default to sonnet via `CLAUDE_CODE_SUBAGENT_MODEL`, so don't pass a `model` unless the task needs opus. Every subagent re-reads its whole context against this subscription's 5-hour quota, and parallel agents draw from it at once:

- At most **two Claude subagents running at once** per session. Sequence the rest.
- Delegate only when the task returns a small result from a large read (exploration, verification, noisy logs). Don't delegate to "throw more compute" at a hard problem — reason about it here.

**Every brief stands alone.** Write it as if the worker has zero conversation context (Codex always does): give ONE task with paths, goal, constraints, and what "done" means.

@RTK.md
