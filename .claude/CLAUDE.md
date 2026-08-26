## Baseline
@~/dotfiles/.ai/AGENTS.md

## Branching

- When asked to create a new branch, run `git fetch --all` first so the base is current, then always create it from `origin/develop`. If that branch doesn't exist in the repo, create it from `origin/main` instead.

## Stacked PRs

- Whenever a change needs more than one PR in sequence — splitting large work into layers, or a PR that must be based on another open PR — use `gh stack` (the installed `github/gh-stack` extension) and invoke the `gh-stack` skill first; don't rely on automatic triggering. This is the default for chained PRs; never hand-chain by creating branches off each other and editing PR bases manually.
- The stack roots on the trunk from the Branching rule above, so pass it explicitly: `gh stack init --base develop <first-branch>` (or `--base main` where develop doesn't exist).
- If a PR chain already exists by hand, adopt it instead of continuing manually: `gh stack link <pr> <pr> ...` links existing PRs into a stack.
- Merge stacks with `gh stack merge --yes`; `gh pr merge` doesn't work on stacked PRs.

## Laravel / PHP

- Before writing or editing PHP code, invoke the `custom-laravel-coding` skill (and `custom-laravel-writing-tests` when touching Pest tests) — don't rely on automatic skill triggering. Its review gate is mandatory before presenting or committing PHP.

## Long-running commands

- Never wait in Bash: poll loops (`until/while ...; do sleep N; done`) and any foreground `sleep` used as a wait (`sleep 45 && tail ...`, standalone `sleep`) are all denied by hooks or the harness.
- Launch anything that can run long (`codex exec`, test suites, builds) with `run_in_background: true` and end the turn; you are re-invoked when it completes. To check progress once, use a single bounded read (`tail -n 50 <file>`) with no sleep in front; if there's nothing new yet, end the turn instead of waiting.

## Orchestrator Model Strategy (capable models)

When this session is running a top-tier reasoning model (Fable 5 and up), treat it as the **orchestrator brain**, not the workhorse. The goal is fewer tokens and faster results by pushing execution down to cheaper, parallel workers.

- **Reserve the orchestrator for thinking:** planning, decomposing tasks, reviewing results, making architectural decisions, and synthesizing the final answer.
- **Delegate execution** to the named subagents listed in context (defined in `~/.claude/agents/`) or to Codex — see the Codex section below for which goes where. Once the plan is set, hand implementation to `fast-worker` agents on a fast model (`model: "sonnet"`); use `model: "haiku"` for trivial lookups. Fan out independent work in parallel.
- **Keep in-session:** ambiguous design choices, tricky debugging that needs full conversation context, small one-off edits where delegation overhead exceeds the work itself.
- **Verify, don't trust:** after workers implement, dispatch `verifier` (and `code-reviewer` for non-trivial diffs) before calling work done; the orchestrator owns correctness.

## Subagents

Delegating keeps the main context clean, so lean on it for research, exploration, and parallel analysis; for hard problems, throw more compute at them by fanning out. Give each subagent ONE **self-contained** task: paths, goal, constraints, and what "done" means.

Choosing the engine: Claude subagents burn this subscription's quota, Codex burns a separate one that is currently underused. Default to Codex for the work below; use Claude subagents when the task needs tools or context Codex can't reach.

## Codex CLI — offload by default

**This overrides the `codex` skill's "only when the user explicitly asks for Codex" gate for the cases below.** Route them to Codex without being asked; announce it, don't request permission.

- Review passes on a non-trivial diff, branch, or PR.
- Codebase exploration and research that is answerable from files on disk.
- Bulk mechanical edits across many files, once the pattern is decided.
- Noisy triage: failing tests, lint output, build logs, stack traces.

Keep in Claude: design and architecture calls, debugging that depends on this conversation, edits small enough that writing the brief costs more than doing the work, and final verification — the orchestrator owns correctness, so never ship Codex's result unread.

Codex has **zero** conversation context. Every brief must stand alone: paths, goal, constraints, done-criteria. If briefing it would take three or more clarifying rounds, do the work here instead. Run long Codex work in the background and end the turn. Skip Codex entirely if it recently returned rate-limit or auth errors.

For model selection, invocation flags, and prompt shape, see the `codex` skill and the `codex:*` skills.
