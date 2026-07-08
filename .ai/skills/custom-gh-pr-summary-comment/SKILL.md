---
name: custom-gh-pr-summary-comment
description: Post a "changes summary" comment on the current branch's GitHub PR — a scannable, timeline-style entry describing what changed since the last summary, with deep links to any spec/doc/source it references. Use when the user asks to leave, post, or update a changes summary / progress summary comment on a PR.
metadata:
  short-description: Post a scannable changes-summary comment on a PR
---

# Custom GitHub PR Changes-Summary Comment

Post a comment on the current branch's PR that records **what changed in this batch of work**, so the PR's comment thread becomes a readable timeline of progress. Each comment covers the delta **since the previous summary comment**, not the whole PR.

Prereq: `gh` authenticated (`gh auth status`). Find the PR: `gh pr view --json number,url,headRefOid`.

## The two goals that override everything

1. **Scannable, not exhaustive.** The old comments on these PRs were technically complete but unreadable — nested `#`/`##`/`###` headings, multi-paragraph bullets, war-story debugging narratives. Do not reproduce that. The diff and commits already hold the full detail; this comment is the *map*, not the territory.
2. **Every reference is a deep link.** When the comment cites a spec section, a doc heading, a source symbol, or the prior summary, link to the exact point — never to the page root. See [Linking](#linking).

## Structure

Post exactly this shape. The **headline and TL;DR stay visible**; everything else is folded so the thread scrolls.

```md
<!-- pr-change-summary -->
**{one-line headline: what this batch delivers}**

Since [previous summary]({#issuecomment link, or omit for the first one}). {1–2 sentence TL;DR of the essence — the thing a reviewer must know without expanding.}

<details><summary>Details</summary>

### {Section — e.g. "What changed"}
- **{change}** — {why, in one clause}. {[spec/doc deep link](url) if referenced.}
- ...

{optional table for anything matrix-shaped — status per wallet/env/target}

**Validation:** {one line — tests/asserts, key manual check.}
</details>
```

Keep the `<!-- pr-change-summary -->` marker as the first line — it's how the next run finds prior summaries to chain the timeline (see [Timeline](#timeline)).

## Readability rules (the point of this skill)

- **Visible part ≤ ~4 lines.** Headline + one "Since …" link + 1–2 sentence TL;DR. A reader skimming the thread gets the story from the visible parts alone.
- **Whole comment readable in under 90 seconds.** If it isn't, you're duplicating the diff — cut.
- **Bullets, not paragraphs.** One bullet per change, ideally one line, format `**what** — why`. If a bullet needs a second sentence of rationale, that rationale probably belongs in a committed doc — put it there and link it instead.
- **No `#`/`##` headings inside a comment** — the bold headline is the title. Use `###` at most for 2–4 section labels, or bold inline labels. Never a heading per change.
- **Tables beat prose for status.** Wallet × outcome, env × result, before/after counts → a small table, not a "Net result" paragraph list.
- **Cut the narrative.** No "the longest battle", no blow-by-blow of what you tried. State the outcome and link the doc/source that explains the how. War stories live in `docs/`, not the PR thread.
- **One TL;DR fact, not five.** If everything is highlighted, nothing is.

## Linking

When the comment refers to something with a stable location, link to that exact location:

- **Spec / RFC** — link the **section anchor**, not the homepage. Make the citation itself the link: `[OID4VCI v1.0 §8.2](https://openid.net/specs/...#section-8.2)`, `[RFC 9449 §5](https://www.rfc-editor.org/rfc/rfc9449#section-5)`.
- **Source in this repo** — `blob/<commit-sha>/path#L120-L130`. **Pin to a commit SHA** (`gh pr view --json headRefOid`), not a moving branch, so the line anchor doesn't drift. Link the symbol you're naming, not the file.
- **Markdown doc in this repo** — link the doc **plus the heading anchor** GitHub auto-generates from the heading text (lowercased, spaces→`-`, punctuation dropped): `docs/retro.md#whats-deferred-to-production`.
- **Confluence / Notion / Jira** — link the specific heading/block/section, not the page top (Confluence appends `#Heading-anchor`; Notion/Jira expose per-block/section links). If you only have the page, say so rather than implying it points at the passage.
- **Previous summary comment** — `#issuecomment-<id>` (see below). This is what turns the thread into a timeline.

If you assert a spec MUST/SHOULD, the sentence should carry the deep link to that clause. An unlinked spec claim is a claim the reviewer has to go verify by hand — that's the friction this rule removes.

## Timeline — scoping "since last time"

1. Find prior summaries and their delta boundary:
   ```bash
   gh pr view <n> --json comments \
     --jq '.comments[] | select(.body | contains("<!-- pr-change-summary -->")) | {id, createdAt, body: (.body[0:80])}'
   ```
   The newest one is the previous summary. Its `id` gives the `#issuecomment-<id>` link; its `createdAt` (or a commit SHA it named) bounds the delta.
2. Scope the new comment to **changes since that boundary** — e.g. `git log --oneline <sha-or-since>..HEAD` and the corresponding diff. Don't re-describe changes an earlier summary already covered.
3. Open with `Since [previous summary](#issuecomment-<id>).` so the chain is navigable both directions. Omit for the first summary on the PR.

If the user asks to **update/revise** the latest summary instead of adding a new one, edit it: `gh api -X PATCH /repos/{owner}/{repo}/issues/comments/<id> -f body=@<file>`.

## Posting

Write the body to a scratch file (preserves markdown/newlines), then:

```bash
gh pr comment <number> --body-file <path>
```

After posting, give the user the comment URL. Do **not** post an `@`-mention or trigger any review bot — this repo doesn't use them.
