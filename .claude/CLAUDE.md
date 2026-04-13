## Baseline
@AGENTS.md

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
