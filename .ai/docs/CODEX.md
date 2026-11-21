# Codex: local rules

Local rules for running Codex. They win over the `codex` skill where the two
disagree. The skill is third-party (`dzhng/skills`) and `npx skills update -g`
overwrites it, so local rules live here, not in the skill.

- Delegate without being asked, per the Delegation section of `~/.claude/CLAUDE.md`; the skill's "explicit ask only" gate does not apply.
- Pin model and effort per the table below; the skill says to leave both at their defaults.
- Done = process exited and the `-o` file is non-empty.

Run from the repo root: `cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"`.
Plain `codex exec "..."` inherits the `~/.codex/config.toml` defaults, and
those drift: the model and the effort both changed during 2026. For delegated runs
always pass an explicit effort so a config change can't silently turn a routine
task into a 30-minute run. Tighten the prompt before reaching for a bigger
model. Override per task:

| Task | Invocation |
|---|---|
| Deep reasoning | `codex exec -c model_reasoning_effort=high "..."` — `xhigh` for the hardest problems |
| Mechanical execution | `codex exec -m "$luna" -c model_reasoning_effort=low "..."` — drop `-m` (config default) if luna struggles |
| Code / cross review | `timeout 600 codex exec review -m gpt-6.2-sol -c model_reasoning_effort=medium -o <file>` (current repo; `-m gpt-6.2-astra` for security-sensitive or large refactors, `high` only if medium misses) or `codex exec -m gpt-6.2-sol -c model_reasoning_effort=medium "..."` |
| Quick lookup / small Q&A | `codex exec -m "$luna" -c model_reasoning_effort=low "..."` |

Luna is the cheapest series, so prefer it for routine work. Codex has no alias for
"latest luna", so resolve the newest one from the model list Codex caches on every run:

```sh
luna=$(jq -r '.models[].slug | select(test("^gpt-[0-9.]+-luna$"))' ~/.codex/models_cache.json | sort -V | tail -n 1)
```

Accepted `model_reasoning_effort` values: none, low, medium, high, xhigh, max. When a task
doesn't clearly fit a row, leave the model unset but still pass a medium effort —
the config default has changed before, so an unset effort is not a neutral choice.

Reviews get a wall-clock budget: wrap them in `timeout 600` (Homebrew coreutils).
A review that hasn't exited in 10 minutes is rerun with a narrower scope or at
`low`, not waited on.
