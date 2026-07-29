# Codex model → task mapping

Tracked copy of the mapping that lives in the `codex` skill
(`~/.agents/skills/codex/SKILL.md`, symlinked as `.ai/skills/codex/`). That
directory is outside this repo, so this file is the version-controlled record —
keep the two in sync when either changes.

Run from the repo root: `cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`.
Plain `codex exec "..."` uses the config default (gpt-5.5, medium effort) — a
fine middle ground, and the right starting point when the task shape is unclear.
Tighten the prompt before reaching for a bigger model. Override per task:

| Task | Invocation |
|---|---|
| Deep reasoning | `codex exec -m gpt-5.5 -c model_reasoning_effort=high "..."` — `xhigh` for the hardest problems |
| Mechanical execution | `codex exec -m gpt-5.4-mini -c model_reasoning_effort=low "..."` — `gpt-5.4` if mini struggles |
| Code / cross review | `codex exec review` (current repo) or `codex exec -m gpt-5.5 -c model_reasoning_effort=high "..."` |
| Quick lookup / small Q&A | `codex exec -m gpt-5.4-mini -c model_reasoning_effort=minimal "..."` |

gpt-5.4-mini has ~3-4× higher rate limits than gpt-5.5 on ChatGPT plans, so
prefer it for routine work to stretch usage.

Accepted `--effort` values: none, minimal, low, medium, high, xhigh. When a task
doesn't clearly fit a row, leave model and effort unset and tighten the prompt
instead.
