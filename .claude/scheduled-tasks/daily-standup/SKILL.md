---
name: daily-standup
description: Summarise activities of mine and others separately
---

Summarise activities from the commit history of this Git repository, or activities on GitHub PRs yesterday, or last weekday if you are running on Monday.

Cover my activity across every repo I work in, not just this one: check local repos under `~/dev/work/*`, `~/dev/*` and `~/dotfiles` for my commits and `gh pr list --author "@me"` for my PRs. Others' activity only needs this repository.

The preferred format for the report is one bullet per repo, with one bullet per activity nested under it. Repo names are bold, and the action word (**Merged**, **Opened**, **Updated**) is bold at the start of each activity line. Each activity is a PR link followed by a short explanation. Use **Updated** for PRs created earlier that changed yesterday. A repo with no PRs lists its direct commits in one line. Use "No commits or PRs" for a repo with nothing.
```
Your activities (last 24h)

- **{Repo 1}**:
   - **Merged** {PR link} {title} ({short explanation})
   - **Opened** {PR link} {title} ({short explanation})
   - **Updated** {PR link} {title} ({short explanation})
- **{Repo 2}**:
   - ...

Others' activities (FYI)

- {Member 1}:
   - **Opened** {PR link} {title} ({short explanation})
```

Skip bulk metadata touches (many old PRs sharing one updated timestamp); they are not real activity.

I'll use this report to recap as a prep for team stand-up call every morning.
Also, please write it down the activities on Obsidian (/Users/miyagawa/Documents/Obsidian/main) under `journal/YYYY/YYYY-Www/YYYY-MM-DD.md` (dated today, covering the previous day), in the same format.
