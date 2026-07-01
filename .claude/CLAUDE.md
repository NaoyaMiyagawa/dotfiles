## Baseline
@~/dotfiles/.ai/AGENTS.md

## Orchestrator Model Strategy (capable models)

When the session runs on a **smart orchestrator-tier model** — Fable 5, or Opus 4.8 at `high`/`xhigh` reasoning — treat it as the **orchestrator brain**, not the workhorse. The goal is fewer tokens and faster results by pushing execution down to cheaper, parallel workers.

- **Reserve the orchestrator for thinking:** planning, decomposing tasks, reviewing results, making architectural decisions, and synthesizing the final answer.
- **Delegate execution to cheaper workers:** spawn subagents with `model: "sonnet"` (or `haiku` for trivial lookups) via the Agent tool, or hand the task to the Codex CLI per the Subagents section below. Fan out independent work in parallel.
- **Good delegation targets:** file searches and exploration, mechanical edits across many files, running tests/linters and reporting results, drafting boilerplate, research sweeps.
- **Keep in-session:** ambiguous design choices, tricky debugging that needs full conversation context, small one-off edits where delegation overhead exceeds the work itself.
- **Verify, don't trust:** review worker output before integrating it; the orchestrator owns correctness.

## Subagents

When work is a good fit for a **subagent** (exploration, research, parallel tasks, or an isolated implementation pass), **delegate to a cheaper, faster model** — any of these is fine:

- **Claude subagents** via the Agent tool with `model: "sonnet"` (Sonnet 5 is a strong default) or `model: "haiku"` for trivial lookups. This is usually the simplest path — fan out independent work in parallel.
- **Codex CLI** when you want to use it — e.g. to burn Codex's (often higher) usage limits instead of this session's, or for a second engine on the same task. Skip Codex if it recently returned rate-limit or auth errors.

Whichever you pick, give the subagent a **self-contained** task: paths, goal, constraints, and what "done" means.

Codex CLI example (adjust subcommand/flags to your install; `codex --help`):

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
codex exec "Read apps/web/src/foo.ts; summarize data flow; list risks; do not edit files."
```

### Cross-review with a second engine

For code review, a **second engine reviewing from a different perspective** catches issues one model misses. When reviewing a diff, PR, or your own changes, consider also running the review through the **Codex CLI** and reconciling both sets of findings. See the code-review / PR-review skills for the concrete workflow.
