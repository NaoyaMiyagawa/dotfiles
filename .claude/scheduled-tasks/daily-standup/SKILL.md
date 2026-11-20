---
name: daily-standup
description: Summarise activities of mine and others separately
---

Summarise activities from the commit history of this Git repository, or activities on GitHub PRs yesterday, or last weekday if you are running on Monday.

Cover my activity across every repo I work in, not just this one: check local repos under `~/dev/work/*`, `~/dev/*` and `~/dotfiles` for my commits and `gh pr list --author "@me"` for my PRs.

Read `~/.claude/scheduled-tasks/daily-standup/local.md` first. It holds the GitHub org, my login, and the stand-up members and observers; `<org>` and `<me>` below mean those values. If the file is missing, stop and say so.

Others' activity covers the whole `<org>` org. Read it from the org event feed (`gh api "users/<me>/events/orgs/<org>?per_page=100&page=N"`, pages 1–3). The feed holds at most 300 events; if its oldest event is newer than the start of the window (likely on Mondays), fall back to `gh search prs --owner <org>` with `created:`, `merged:` and `closed:` qualifiers for the window, and say in the report that reviews and pushes on still-open PRs are missing. Skip bots.

List the stand-up members first in full, then the observers marked "(observer)" with one line per group of related work, then everyone else under "Rest of the org", one line per person.

Count only what I did myself: opening PRs or issues, pushing commits, commenting, reviewing others' PRs, merging, closing, releasing. Read them from my GitHub event feed (`gh api users/<me>/events`) and confirm pushes from the commit dates on each PR, since the feed can omit them. A PR whose only change yesterday was someone else's review or comment is not my activity.

The preferred format for the report is one bullet per repo, with one bullet per activity nested under it. Repo names are bold, and the action word (**Merged**, **Opened**, **Updated**, **Reviewed**, **Commented**, **Closed**, **Released**) is bold at the start of each activity line. Each link's text is `#{number} {title}`; don't add an explanation that repeats the title. **Updated** lines add what I did, based on the commit messages ("pushed ...", "changed ..."). When several items share a purpose (a stack I opened, a stack I reviewed, a batch of issues), write one action line naming the purpose and list the links as nested bullets under it. A repo with no PRs lists its direct commits in one line. Use "No commits or PRs" for a repo with nothing.
```
Your activities (last 24h)

- **{Repo 1}**:
   - **Merged** [#{number} {title}]({url})
   - **Updated** [#{number} {title}]({url}): pushed {what the commits do}
   - **Opened** the {purpose} stack:
      - [#{number} {title}]({url})
      - [#{number} {title}]({url})
   - **Reviewed** {author}'s {purpose}:
      - [#{number} {title}]({url}): approved
- **{Repo 2}**:
   - ...

Today (draft)

- {2–3 suggested next steps drawn from the two sections below, e.g. merge approved PRs bottom of stack first, chase a reviewer, review the newest requests}

Waiting on others

- **Approved, ready to merge**:
   - [#{number} {title}]({url}): {approver}
- **Waiting for review**:
   - {stack purpose}, {review state}:
      - [#{number} {title}]({url})
- **Has conflicts**:
   - [#{number} {title}]({url}): open since {date}
- {n} draft PRs not listed

Waiting on me

- [#{number} {title}]({url}): {author}, {n} days   (open PRs with review-requested:@me, newest first)

Others' activities (FYI)

- **{Name} ({login})**:
   - **Opened** [#{number} {title}]({url})
- **{Name} ({login})** (observer):
   - ...
- **Rest of the org**:
   - {login} {one-line summary with links}
```

"Waiting on others" lists my open non-draft PRs across the org (`gh search prs --author @me --state open --owner <org>`) grouped by `reviewDecision` and `mergeable` from `gh pr view`.

Skip bulk metadata touches (many old PRs sharing one updated timestamp); they are not real activity.

I'll use this report to recap as a prep for team stand-up call every morning.
Also, please write it down the activities on Obsidian (/Users/miyagawa/Documents/Obsidian/main) under `journal/YYYY/YYYY-Www/YYYY-MM-DD.md` (dated today, covering the previous day), in the same format.
