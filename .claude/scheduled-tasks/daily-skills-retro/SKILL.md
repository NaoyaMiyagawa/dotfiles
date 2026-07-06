---
name: daily-skills-retro
description: Review my feedbacks to generated code or review comments and extract essences to adopt to skills
---

Look at my feedback comments to generate codes on Claude Code, or review comments for suggestions about coding standards from the past 24 hours, and see if there's any essence to extract and adopt as a new coding standard.

Ground your suggestions in the repositories I've actually been working in — infer them from the recent session transcripts' project directories (or the current working directory), not from any hardcoded repo name.

Keep the skills in my dotfiles generic across repositories. When you extract essence, generalise it: use a generic model and avoid domain- or project-specific vocabulary.

## How to mine the transcripts
Session transcripts live under ~/.claude/projects/<slug>/*.jsonl. Extract only user turns with:
  jq -rc 'select(.type=="user") | .message.content | if type=="string" then . elif type=="array" then (map(select(.type=="text").text) | join("\n")) else empty end' FILE | grep -v '^$'
Skip transcripts whose only user turns are scheduled-task prompts — they contain no live feedback. Real feedback comes from interactive coding sessions.

## Delegation rules (avoid stuck background agents)
- Run mining/extraction sub-agents synchronously — do NOT use run_in_background for work that finishes in a couple of minutes; background mode hides failures and gives no benefit here.
- Keep delegation one level deep: fan out from here, never from inside a sub-agent.
- Give each sub-agent these execution rules verbatim:
  - Do all the work yourself this turn. Do NOT spawn sub-agents (no nesting). Filter large input with grep/jq in the same command.
  - Your final message must BE the findings — never end a turn with a status or "I'll wait for X" message; a deferred result is a lost result.
  - Do NOT read/tail/cat your own output or transcript file.
  - Stay within scope; if you can't finish, return partial findings, not a promise to continue.
