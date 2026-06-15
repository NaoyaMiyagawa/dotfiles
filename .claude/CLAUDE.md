## Baseline
@AGENTS.md

## CLI Tool Calling
- Prefer faster, purpose-built CLI tools over slower legacy defaults.
- Use `rg` instead of `grep` for searching file contents or line matches.
- Use `fd` instead of `find` when locating files by name or pattern.
- Use structured tools or parsers when available instead of ad hoc shell pipelines.
- If you reach for a slow default, pause and ask whether a faster alternative exists.

## Orchestrator Model Strategy (capable models)

When the session runs on a **smart orchestrator-tier model** — Fable 5, or Opus 4.8 at `high`/`xhigh` reasoning — treat it as the **orchestrator brain**, not the workhorse. The goal is fewer tokens and faster results by pushing execution down to cheaper, parallel workers.

- **Reserve the orchestrator for thinking:** planning, decomposing tasks, reviewing results, making architectural decisions, and synthesizing the final answer.
- **Delegate execution to cheaper workers:** spawn subagents with `model: "sonnet"` (or `haiku` for trivial lookups) via the Agent tool, or hand the task to the Codex CLI per the Subagents section below. Fan out independent work in parallel.
- **Good delegation targets:** file searches and exploration, mechanical edits across many files, running tests/linters and reporting results, drafting boilerplate, research sweeps.
- **Keep in-session:** ambiguous design choices, tricky debugging that needs full conversation context, small one-off edits where delegation overhead exceeds the work itself.
- **Verify, don't trust:** review worker output before integrating it; the orchestrator owns correctness.

## Subagents

When work is a good fit for a **subagent** (exploration, research, parallel tasks, or an isolated implementation pass), **delegate via the Codex CLI first** if Codex is **not** rate-limited and the CLI runs cleanly. Codex usually has **higher usage limits** than this session, so prefer burning Codex capacity over Claude-only delegation when both can do the job.

- **Before spawning:** If Codex recently returned rate-limit or auth errors, skip it and use Claude’s native tools or stay in-session.
- **Prompting:** Give Codex a **self-contained** task: paths, goal, constraints, and what “done” means.

Example (adjust subcommand/flags to your install; `codex --help`):

```bash
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
codex exec "Read apps/web/src/foo.ts; summarize data flow; list risks; do not edit files."
```

If not available, use default Claude ones.

@RTK.md
