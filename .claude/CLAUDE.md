## Baseline
@~/dotfiles/.ai/AGENTS.md

## Branching

- When asked to create a new branch, run `git fetch --all` first so the base is current, then always create it from `origin/develop`. If that branch doesn't exist in the repo, create it from `origin/main` instead.

## Long-running commands

- Never wait with polling loops in Bash (`until/while ...; do sleep N; done`) — they block the turn with no output and look like a hang. A PreToolUse hook denies them.
- Launch long-running work with `run_in_background: true` and end the turn; you are re-invoked when it completes. To check progress once, use a single bounded read (`tail -n 50 <file>`), never a loop.

## Orchestrator Model Strategy (capable models)

When the session runs on a **smart orchestrator-tier model** — Fable 5, or Opus 4.8 at `high`/`xhigh` reasoning — treat it as the **orchestrator brain**, not the workhorse. The goal is fewer tokens and faster results by pushing execution down to cheaper, parallel workers.

- **Reserve the orchestrator for thinking:** planning, decomposing tasks, reviewing results, making architectural decisions, and synthesizing the final answer.
- **Delegate execution** to the named subagents already listed in context (defined in `~/.claude/agents/`), or hand the task to the Codex CLI. Fan out independent work in parallel; use `model: "haiku"` for trivial lookups.
- **Keep in-session:** ambiguous design choices, tricky debugging that needs full conversation context, small one-off edits where delegation overhead exceeds the work itself.
- **Verify, don't trust:** after workers implement, dispatch `verifier` (and `code-reviewer` for non-trivial diffs) before calling work done; the orchestrator owns correctness.

## Subagents

Claude subagents via the Agent tool are usually the simplest path. Reach for the **Codex CLI** instead when you want to burn Codex's (often higher) usage limits rather than this session's, or want a second engine on the same task — including a cross-review pass whose findings you reconcile with your own. Skip Codex if it recently returned rate-limit or auth errors.

Whichever you pick, give the subagent a **self-contained** task: paths, goal, constraints, and what "done" means. For Codex model selection and invocation flags, see the `codex` skill.
