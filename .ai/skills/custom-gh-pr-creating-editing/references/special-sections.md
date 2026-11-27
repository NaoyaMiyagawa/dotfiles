# Special PR Description Sections

Read this only when a PR includes before/after performance or visual evidence, or fixes a Sentry issue.

## Before/after evidence

When the PR makes something faster, cheaper, or smaller, or proves rendered output stayed unchanged, show the result under the template's screenshots/results section:

- Use a two-column HTML `<table>` (`Before` / `After` headers), one row per screenshot pair. Inside each `<td>`, put the markdown image between blank lines (`![before](./before.png)`) so `--attach` rewrites it, plus a one-line caption with step and measurement (`Before: container init took 42s` / **After: container init took 9s**). Bold the After cells.
- One table per change lever so gains map to specific changes. State the mechanism in one sentence.
- New flow with no before state (and no template screenshots section): add `## Screenshots` before closing notes, `###` per flow, table with one-line labels.
- Hide browser chrome (bookmark bar) before capturing.
- Upload images yourself via `--attach './before.png#alt text'` on `gh pr create`/`gh pr edit` — never hand upload to the user.

## Sentry fix summary

Put under the Jira link in the PR body, and use the same block (without the ticket line) for the Jira ticket (show and ask before editing Jira unless already asked). Bold every label and pull fresh figures from Sentry (including environment tag distribution):

```md
- **Ticket:** https://<org>.atlassian.net/browse/PROJ-1234

**Sentry:** APP-294 (https://<org>.sentry.io/issues/APP-294)
- **Type:** N+1 Query (performance issue, not an exception)
- **Endpoint:** GET `/workflows/{workflow}/runs` (workflow runs index)
- **Repeated query:** `select * from document_templates where id = ? ...`
- **First seen:** 2026-09-11 · **Last seen:** 2026-09-24
- **Occurrences:** 3 (UAT 2, Staging 1); none in Production; 0 users impacted
- **Impact:** one extra query per run on the page, so 10 on a default page
```

Adapt lines to issue type (error message for exceptions, page/browser for frontend). Add `**Related Sentry:**` for linked issues. **Impact** explains how cost/failure scales or who it hits.
