---
name: daily-skills-retro
description: Review my feedbacks to generated code or review comments and extract essences to adopt to skills
---

Mine my feedback from the past 24 hours for coding-standard essence, and adopt what's durable into my dotfiles instructions.

## Sources
- Claude Code session transcripts: my corrections/feedback on generated code.
- GitHub review comments I authored: for each repo inferred from the transcripts, e.g.
  `gh api "repos/<owner>/<repo>/pulls/comments?sort=created&direction=desc&per_page=100" --jq '[.[] | select(.user.login=="<my-login>" and .created_at > "<24h-ago ISO>") | {path, body, html_url}]'`

Ground everything in repositories I've actually been working in — infer them from the recent transcripts' project directories (or the current working directory), never from a hardcoded repo name.

## How to mine the transcripts
Run the bundled extractor — it already handles every trap below:

```bash
~/dotfiles/.claude/scheduled-tasks/daily-skills-retro/scripts/mine.sh <scratchpad>/mine <this-session-id>
```

It shortlists `~/.claude/projects/**/*.jsonl` changed in the last 24h (skipping this run's own transcript and `subagents/`), then runs two jq programs from `scripts/` in one pass each:
- `user-turns.jq` → `turns.jsonl`: user text turns, one JSON string per line, prefixed `### [<session>]`. Drops `<system-reminder>`, `<command-*>`, `<scheduled-task>` and skill-body blocks at the block level (dropping whole turns loses feedback that arrived with an attached reminder).
- `difit-comments.jq` → `difit.txt`: inline review comments left through difit. These arrive as a **tool_result**, not a text turn, matching `=====\n<path>:L<n>\n<comment>`. This stream carried ~200 comments in Aug 2026 against ~30 in text turns — it is the primary source, not a supplement. Blocks mix authors: the agent preloads its own findings with `difit --comment`. A block is user feedback only when it sits under a `Reply N (User)` marker or reads in the user's terse imperative voice; multi-sentence explanatory prose and "Applied — …" notes are agent-authored and are not evidence.

Skip transcripts whose only user turns are scheduled-task prompts — they contain no live feedback. A retro run re-reads earlier transcripts, so the same difit batch can show up under two sessions; check yesterday's skill commits before adopting something already absorbed.

If you must run jq by hand: pass ABSOLUTE paths (the `<slug>` dirs start with `-`), use `fd --no-ignore` / `rg -u` (transcripts are gitignored via the `~/.claude` symlink), load programs with `-f <file>` written via the Write tool (heredocs with control chars trip a command guard), feed files through `xargs` (zsh doesn't word-split `$VAR`), and never stash anything in a shell variable across Bash calls — state doesn't persist.

## Grounding (anti-hallucination)
Before adopting anything, re-verify the supporting quote exists VERBATIM in the transcript (absolute file path + a grep that matches). Mining sub-agents hallucinate quotes; a candidate whose quote can't be located is rejected, not paraphrased into acceptance.

## What to adopt, and where
Triage first: check whether an existing rule already covers the correction. If it does, that's a compliance failure, not a coverage gap — rewording or appending prose won't fix it. Route those instead:
- Mechanically checkable → add a row to ~/dotfiles/.ai/skills/custom-laravel-coding/references/tooling-candidates.md (destined for lint tooling in the work repo).
- A judgment rule sitting in a long-tail checklist → promote it into the owning skill's core SKILL.md (move, don't copy).

Otherwise route each verified essence to exactly one destination:
1. An existing skill in ~/dotfiles/.ai/skills/ already owns the topic → edit it in place; prefer sharpening or replacing an existing line over appending a new one. Where a skill is split into a core SKILL.md plus references/checklist.md (e.g. custom-laravel-coding), new rules go to the checklist — the core stays capped at ~15 rules, so adding one there requires demoting one out.
2. Language/framework/tool-specific with no existing home → create a new skill, only if the pattern will plausibly recur.
3. Not language-specific (process, workflow, verification habits, general engineering judgment) → add one lean bullet to the matching section of ~/dotfiles/.ai/AGENTS.md (the global baseline), e.g. Core Principles.

Adoption bar — judge by generalizability, not by how often I said it. Adopt a piece of feedback when it states or implies a rule that would apply to future code in other tasks or repos, even if I expressed it only once. Strong adopt signals: I corrected something the agent generated; imperative phrasing ("always", "never", "prefer", "don't", "instead of", "why is this..."); a style, structure, naming, or testing preference. The only two rejection reasons are: (a) task-local — tied to one specific file, bug, or business rule; (b) project-specific — only meaningful inside that repo's domain and not generalizable. Being said once is never a rejection reason. If a candidate is genuinely borderline (you can't tell whether it generalizes), don't drop it — record it in the ledger below. Generalise before writing: generic wording, no domain- or project-specific vocabulary — skills and AGENTS.md must stay generic across repositories.

Because once-stated preferences now get adopted, the lean-file rules below are mandatory every run, not occasional hygiene.

## Candidate ledger (cross-run memory for borderline items)
A single 24h window can't observe "expressed more than once" — repetition happens across days. Maintain ~/dotfiles/.ai/mining-ledger.md (local only — it holds verbatim quotes and transcript paths from work repos, so it is untracked and never committed): one line per borderline candidate (`date | proposed rule | verbatim quote | transcript path`). Read it at the start of each run; if today's mining surfaces a candidate expressing the same underlying rule as an existing entry (same intent, not verbatim text), promote it to a real destination and delete its ledger line. Prune entries older than 30 days.

Keep instruction files lean: don't restate what a capable model already does by default; if a new rule supersedes an old one, replace it rather than append. While editing a skill, merge duplicate or overlapping rules you notice and delete any rule the work repo's tooling now enforces. A no-op run (nothing cleared the bar) is a valid outcome — say so and change nothing.

## Delegation rules (avoid stuck background agents)
- Run mining/extraction sub-agents synchronously — do NOT use run_in_background for work that finishes in a couple of minutes; background mode hides failures and gives no benefit here.
- Keep delegation one level deep: fan out from here, never from inside a sub-agent.
- Give each sub-agent these execution rules verbatim:
  - Do all the work yourself this turn. Do NOT spawn sub-agents (no nesting). Filter large input with grep/jq in the same command — load any jq program from a file with `-f`, and never rely on shell variables surviving between Bash calls (they don't).
  - Your final message must BE the findings — never end a turn with a status or "I'll wait for X" message; a deferred result is a lost result.
  - Do NOT read/tail/cat your own output or transcript file.
  - Stay within scope; if you can't finish, return partial findings, not a promise to continue.

## Report
End with a short summary: what was adopted (destination file + the verbatim evidence quote), what was added to or promoted from the ledger, and what was rejected (one-line reason each).