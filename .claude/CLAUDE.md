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

- Launch anything that can run long (`codex exec`, test suites, builds) with `run_in_background: true`, carry on with any work that doesn't need its result, then end the turn; you are re-invoked when it completes. Poll loops and foreground `sleep` are denied. To check progress once, use a single `tail -n 50 <file>`.

## Delegation

On top-tier models (Opus/Fable), act as orchestrator: plan, decide, review, synthesize. Delegate execution to cheaper workers, and never ship a worker's result unread.

**Keep in-session:** design/architecture calls, conversation-dependent debugging, small edits where briefing costs more than doing, and final verification.

**Codex (reviews only):** reserve Codex for second-opinion code/PR reviews from a different model (read `~/dotfiles/.ai/docs/CODEX.md` before the first Codex run of a session; fall back to Claude Opus 5.5 at medium effort on rate/usage limit or empty `-o` file, and say so). Don't route general exploration or triage to Codex.

**Claude workers (default for delegation — Sonnet / Haiku):**
- `fast-worker` (Haiku; pass `model: sonnet` if Haiku misses): well-specified implementation and bulk mechanical edits.
- `connector-reader` (Haiku, read-only): long Notion/Sentry/Jira/etc. items; read short ones in-session (`fast-worker`/`verifier` have no MCP tools).
- `verifier` (Sonnet): noisy verification (full test suite, long build log); run quiet checks inline.
- Unpinned subagents (including codebase exploration and noisy triage) default to Sonnet via `CLAUDE_CODE_SUBAGENT_MODEL`. At most **two Claude subagents running at once**; delegate only when a large read returns a small result.

**Every brief stands alone** (zero conversation context): one task, paths, goal, constraints, and definition of done.

@RTK.md
