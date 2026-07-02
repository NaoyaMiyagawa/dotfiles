---
name: custom-jira-context-fetching
description: Fetch Jira issue context from a Jira URL or issue key using the installed `jira-cli`. Use when the user shares a Jira ticket URL or key, asks for ticket summary or description context, wants implementation guidance from Jira ticket details, or wants branch naming context derived from a Jira issue.
---

# Custom Jira Context Fetching

## Scope

Run this only when Jira ticket context is actually needed. Do not run it if the user already pasted the relevant ticket details into the chat.

## Setup

If `jira` is not configured yet, ask the user to do so.

Reference: [jira-cli getting started](https://github.com/ankitpokhrel/jira-cli#getting-started)

## Workflow

1. Extract the issue key.
   - If the user gives a Jira URL, parse the key from the URL with a pattern like `[A-Z][A-Z0-9]+-[0-9]+` (e.g. `PN-3429`).
   - If parsing fails, ask the user for the exact issue key instead of guessing.
2. Fetch the ticket.
   - Run `jira issue view {KEY}`. If auth or config fails, report that clearly and stop.
   - Fetch richer context when useful: `jira issue view {KEY} --comments 5` for recent comments, or `jira issue list -q "key = {KEY}" --raw` when structured output is easier to inspect.
3. Summarize the ticket for the user.
   - Treat the description as the primary implementation context; if it is thin, inspect recent comments before concluding the ticket lacks context.
   - Capture the summary/title, acceptance criteria, constraints, linked work, and recent comment context if present.
   - If the user gave a URL, report both the parsed issue key and the fetched summary so the user can verify the match.
4. Derive branch context carefully (when asked).
   - Prefer the repository's existing branch naming convention if visible in git history or current branches.
   - Otherwise suggest a slug derived from the Jira key and summary, such as `KEY-short-summary`, and state clearly that it is a fallback, not a repo convention.
   - Do not claim that `jira-cli` itself generates branch names unless the local environment explicitly adds that behavior.
