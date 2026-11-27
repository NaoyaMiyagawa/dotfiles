---
name: custom-gh-comment-footer
description: Standard footer for autonomous agent-posted GitHub comments (assessments, summaries). Skip on replies to people.
---

# Agent Comment Footer

End every GitHub comment you post on your own with this line:

```md
<sub>Posted by {tool} ({model}) at {datetime}</sub>
```

- `{tool}` — the agent that ran: `Claude Code`, `Codex`.
- `{model}` — the model ID you are running as, from your own system context, without a context-size suffix: `claude-opus-5-5`, not `claude-opus-5-5[1m]`.
- `{datetime}` — Singapore time from `TZ=Asia/Singapore date '+%Y-%m-%d %H:%M +08 (SGT)'`, taken just before posting.

Example: `<sub>Posted by Claude Code (claude-opus-5-5) at 2026-09-24 14:05 +08 (SGT)</sub>`

Skip it on replies to a person (review-comment replies, answers in a thread). Those read as the user's own voice.

When a skill needs an HTML marker comment (`<!-- ... -->`) as the last line, put the footer directly above the marker. On an edit of an existing comment, replace the old footer instead of adding a second one.
