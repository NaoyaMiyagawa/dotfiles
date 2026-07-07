## Baseline
@~/dotfiles/.ai/AGENTS.md

## Branching

- When asked to create a new branch, always create it from `origin/develop`. If that branch doesn't exist in the repo, create it from `origin/main` instead.

## Long-running commands

- Never wait with polling loops in Bash (`until/while ...; do sleep N; done`) — they block the turn with no output and look like a hang. A PreToolUse hook denies them.
- Launch long-running work with `run_in_background: true` and end the turn; you are re-invoked when it completes. To check progress once, use a single bounded read (`tail -n 50 <file>`), never a loop.

## Orchestrator Model Strategy (capable models)

When the session runs on a **smart orchestrator-tier model** — Fable 5, or Opus 4.8 at `high`/`xhigh` reasoning — treat it as the **orchestrator brain**, not the workhorse. The goal is fewer tokens and faster results by pushing execution down to cheaper, parallel workers.

- **Reserve the orchestrator for thinking:** planning, decomposing tasks, reviewing results, making architectural decisions, and synthesizing the final answer.
- **Delegate execution to the named subagents** (defined in `~/.claude/agents/`), or hand the task to the Codex CLI per the Subagents section below. Fan out independent work in parallel:
  - `fast-worker` (Sonnet) — mechanical, well-specified execution: multi-file edits, boilerplate, tests, formatting, running linters/tests. Use `model: "haiku"` for trivial lookups.
  - `deep-reasoner` (Opus, read-only) — isolated reasoning-heavy analysis: architecture options, complex debugging, algorithm design. It returns a conclusion; the orchestrator decides and dispatches implementation.
  - `code-reviewer` (Opus, read-only) — adversarial review of a diff/branch/PR; returns ranked findings.
  - `verifier` (Sonnet) — proves a change works by running tests/linters/the affected flow; returns verdict + evidence, absorbing noisy logs.
- **Keep in-session:** ambiguous design choices, tricky debugging that needs full conversation context, small one-off edits where delegation overhead exceeds the work itself.
- **Verify, don't trust:** after workers implement, dispatch `verifier` (and `code-reviewer` for non-trivial diffs) before calling work done; the orchestrator owns correctness.

## Subagents

When work is a good fit for a **subagent** (exploration, research, parallel tasks, or an isolated implementation pass), **delegate to a cheaper, faster model** — any of these is fine:

- **Claude subagents** via the Agent tool — `fast-worker` for execution, `deep-reasoner` for analysis (see above), or a plain agent with `model: "sonnet"`/`"haiku"` when neither fits. This is usually the simplest path — fan out independent work in parallel.
- **Codex CLI** when you want to use it — e.g. to burn Codex's (often higher) usage limits instead of this session's, or for a second engine on the same task. Skip Codex if it recently returned rate-limit or auth errors.

Whichever you pick, give the subagent a **self-contained** task: paths, goal, constraints, and what "done" means.

### Codex model → task mapping

Run from the repo root: `cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`. Plain `codex exec "..."` uses the config default (gpt-5.5, medium effort) — a fine middle ground. Override per task:

| Task | Invocation |
|---|---|
| Deep reasoning (≈ `deep-reasoner`) | `codex exec -m gpt-5.5 -c model_reasoning_effort=high "..."` — `xhigh` for the hardest problems |
| Mechanical execution (≈ `fast-worker`) | `codex exec -m gpt-5.4-mini -c model_reasoning_effort=low "..."` — `gpt-5.4` if mini struggles |
| Code / cross review | `codex exec review` (current repo) or `codex exec -m gpt-5.5 -c model_reasoning_effort=high "..."` |
| Quick lookup / small Q&A | `codex exec -m gpt-5.4-mini -c model_reasoning_effort=minimal "..."` |

gpt-5.4-mini has ~3-4× higher rate limits than gpt-5.5 on ChatGPT plans, so prefer it for routine work to stretch usage.

### Cross-review with a second engine

For code review, a **second engine reviewing from a different perspective** catches issues one model misses. When reviewing a diff, PR, or your own changes, consider also running the review through the **Codex CLI** and reconciling both sets of findings. See the code-review / PR-review skills for the concrete workflow.
