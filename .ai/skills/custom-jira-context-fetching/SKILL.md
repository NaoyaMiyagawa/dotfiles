---
name: custom-jira-context-fetching
description: Fetch Jira issue context from a Jira URL or issue key using the installed `jira-cli`. Use when the user shares a Jira ticket URL or key, asks for ticket summary or description context, wants implementation guidance from Jira ticket details, or wants branch naming context derived from a Jira issue.
---

# Custom Jira Context Fetching

## Scope

Run this only when Jira ticket context is actually needed.

Do not run it if the user already pasted the relevant ticket details into the chat.

## Setup

If `jira` is not configured yet, ask user to do so.

Reference: [jira-cli getting started](https://github.com/ankitpokhrel/jira-cli#getting-started)

## Workflow

1. Extract the issue key.
   - If the user gives a Jira URL, parse the key from the URL.
   - Use a pattern like `[A-Z][A-Z0-9]+-[0-9]+`. (e.g. `PN-3429`)
   - If parsing fails, ask the user for the exact issue key instead of guessing.
2. Verify CLI access.
   - Run `jira issue view {KEY}`.
   - If auth or config fails, report that clearly and stop.
3. Fetch richer context when useful.
   - Use `jira issue view {KEY} --comments 5` to include recent comments.
   - Use `jira issue list -q "key = {KEY}" --raw` when structured output is easier to inspect or summarize.
4. Summarize the ticket for the user.
   - Capture the summary/title.
   - Pull implementation context from the description.
   - Note acceptance criteria, constraints, linked work, or recent comment context if present.
5. Derive branch context carefully.
   - Prefer the repository's existing branch naming convention if it is already visible in git history or current branches.
   - If no local convention is visible, suggest a branch slug derived from the Jira key and summary, such as `KEY-short-summary`.
   - Do not claim that `jira-cli` itself generates branch names unless the local environment explicitly adds that behavior.

## Commands

```bash
jira issue view {KEY}
jira issue view {KEY} --comments 5
jira issue list -q "key = {KEY}" --raw
jira open {KEY}
```

## Behavior

1. Prefer the issue description as the primary implementation context.
2. If the description is thin, inspect recent comments before concluding the ticket lacks context.
3. If the user gave a Jira URL, report both the parsed issue key and the fetched summary so the user can verify the match.
4. If the user asks for a branch name, state clearly whether it is a repo convention or just a safe fallback slug.
