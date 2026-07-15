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
Transcripts live under ~/.claude/projects/<slug>/*.jsonl. Always pass ABSOLUTE paths — the <slug> dirs start with `-`, so relative paths parse as flags. Transcripts are gitignored (dotfiles .gitignore covers `/.claude/**` via the ~/.claude symlink), so shortlist with `fd --no-ignore -e jsonl --changed-within 24h . ~/.claude/projects` and pass `-u` to any rg over them — without those flags the search silently returns nothing. Then extract user turns in ONE jq pass over all shortlisted files — no per-file shell loop (loops here have hung):
1. Write this jq program to a scratchpad file with the Write tool (not a heredoc — literal control chars trip a command guard), then run `jq -rc -f <program.jq> <absolute files...>` (use `input_filename` in the program if you need per-file attribution):
  select(.type=="user") | .message.content | if type=="string" then . elif type=="array" then (map(select(.type=="text").text) | join("\n")) else empty end | select(. != "")
Skip transcripts whose only user turns are scheduled-task prompts — they contain no live feedback. Real feedback comes from interactive coding sessions. Exclude this run's own live transcript.

Shell state does NOT persist between Bash calls — never stash the jq filter (or any value) in a shell variable for a later command; it evaporates and jq runs with the filename as its program. The `-f <file>` approach above avoids this entirely.

## Grounding (anti-hallucination)
Before adopting anything, re-verify the supporting quote exists VERBATIM in the transcript (absolute file path + a grep that matches). Mining sub-agents hallucinate quotes; a candidate whose quote can't be located is rejected, not paraphrased into acceptance.

## What to adopt, and where
Route each verified essence to exactly one destination:
1. An existing skill in ~/dotfiles/.ai/skills/ already owns the topic → edit it in place; prefer sharpening or replacing an existing line over appending a new one.
2. Language/framework/tool-specific with no existing home → create a new skill, only if the pattern will plausibly recur.
3. Not language-specific (process, workflow, verification habits, general engineering judgment) → add one lean bullet to the matching section of ~/dotfiles/.ai/AGENTS.md (the global baseline), e.g. Core Principles.

Adoption bar: an explicit correction, or a preference I've expressed more than once. One-off, task-local, or purely project-specific remarks are not standards. Generalise before writing: generic wording, no domain- or project-specific vocabulary — skills and AGENTS.md must stay generic across repositories.

Keep instruction files lean: don't restate what a capable model already does by default; if a new rule supersedes an old one, replace it rather than append. A no-op run (nothing cleared the bar) is a valid outcome — say so and change nothing.

## Delegation rules (avoid stuck background agents)
- Run mining/extraction sub-agents synchronously — do NOT use run_in_background for work that finishes in a couple of minutes; background mode hides failures and gives no benefit here.
- Keep delegation one level deep: fan out from here, never from inside a sub-agent.
- Give each sub-agent these execution rules verbatim:
  - Do all the work yourself this turn. Do NOT spawn sub-agents (no nesting). Filter large input with grep/jq in the same command — load any jq program from a file with `-f`, and never rely on shell variables surviving between Bash calls (they don't).
  - Your final message must BE the findings — never end a turn with a status or "I'll wait for X" message; a deferred result is a lost result.
  - Do NOT read/tail/cat your own output or transcript file.
  - Stay within scope; if you can't finish, return partial findings, not a promise to continue.

## Report
End with a short summary: what was adopted (destination file + the verbatim evidence quote) and what was rejected (one-line reason each).