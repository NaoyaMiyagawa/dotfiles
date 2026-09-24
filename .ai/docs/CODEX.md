# Codex model → task mapping

Tracked copy of the mapping that lives in the `codex` skill
(`~/.agents/skills/codex/SKILL.md`, symlinked as `.ai/skills/codex/`). That
directory is outside this repo, so this file is the version-controlled record —
keep the two in sync when either changes.

Run from the repo root: `cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`.
Plain `codex exec "..."` inherits the `~/.codex/config.toml` defaults (gpt-5.6-sol
at medium as of 2026-09; it was xhigh a month earlier). For delegated runs
always pass an explicit effort so a config change can't silently turn a routine
task into a 30-minute run. Tighten the prompt before reaching for a bigger
model. Override per task:

| Task | Invocation |
|---|---|
| Deep reasoning | `codex exec -m gpt-5.5 -c model_reasoning_effort=high "..."` — `xhigh` for the hardest problems |
| Mechanical execution | `codex exec -m gpt-5.6-luna -c model_reasoning_effort=low "..."` — drop `-m` (config default) if luna struggles |
| Code / cross review | `timeout 600 codex exec review -c model_reasoning_effort=medium -o <file>` (current repo; `high` only for security-sensitive or large refactors) or `codex exec -m gpt-5.5 -c model_reasoning_effort=medium "..."` |
| Quick lookup / small Q&A | `codex exec -m gpt-5.6-luna -c model_reasoning_effort=minimal "..."` |

gpt-5.6-luna is the cheapest model, so prefer it for routine work.

Accepted `--effort` values: none, minimal, low, medium, high, xhigh. When a task
doesn't clearly fit a row, leave the model unset but still pass a medium effort —
the config default has changed before, so an unset effort is not a neutral choice.

Reviews get a wall-clock budget: wrap them in `timeout 600` (Homebrew coreutils).
A review that hasn't exited in 10 minutes is rerun with a narrower scope or at
`low`, not waited on.
