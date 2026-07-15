---
name: custom-jira-ticket-management
description: Create and organize Jira tickets with the installed `jira-cli`. Use when the user asks to create one or more Jira tickets, break a feature/epic/project down into tickets, rewrite or improve a ticket's summary/description, or link and structure related tickets. Covers decomposition into right-sized tickets, clear scope and acceptance criteria, context sharing, and issue linking.
---

# Custom Jira Ticket Management

Turn work into Jira tickets that a teammate with zero conversation context can pick up, execute, and track. Reading existing ticket context is [custom-jira-context-fetching](../custom-jira-context-fetching/SKILL.md)'s job; this skill is for writing and structuring tickets.

## Workflow

1. **Gather scope.** Understand the work well enough to slice it: read the relevant code, docs, or existing tickets first. Fetch any referenced tickets before writing new ones so links and decomposition build on what already exists.
2. **Decompose** (rules below). Decide the shape: single ticket, or epic/parent with children.
3. **Draft everything, then confirm.** Present all ticket drafts (summary, description, type, links) to the user in one pass before creating anything — creating tickets is outward-facing; never create on the first pass without approval. Fold in feedback.
4. **Create.** Write each description to a scratchpad file and pass it with `-T` to avoid shell-quoting damage:
   - `jira issue create -t Task -s "Summary" -T /path/to/body.md --no-input`
   - Children of an epic: add `-P EPIC-KEY`. Sub-tasks require `-P`.
   - If auth or config fails, report it and stop; setup is described in the context-fetching skill.
5. **Link** after creation: `jira issue link KEY-1 KEY-2 Blocks` (link types vary per instance — if a link type is rejected, list valid ones rather than guessing synonyms).
6. **Report** every created key with its URL and the link structure, so the user can verify in one glance.

## Decomposition

- One ticket = one independently deliverable, verifiable outcome — roughly one PR. "Done" must be demoable or testable on its own.
- Slice vertically (user-visible outcome) rather than by layer; split by layer only when different people/teams own the layers.
- If describing the ticket's status would take more than a sentence, it is too big — split it. If a ticket can't fail code review on its own, it is too small — merge it.
- No grab-bag tickets ("misc fixes", "cleanup") — each hides untrackable work. Give each fix its own ticket or drop it.
- Unknowns that block slicing become a timeboxed spike ticket whose deliverable is an answered question, not code.
- Ordering dependencies between siblings become `Blocks` links, not prose.

## Ticket description template

Write descriptions in markdown (jira-cli converts it). Sections, in order — drop a section only when it is genuinely empty:

```markdown
## Why
1–3 sentences: the problem or goal, and why now. Link the source
(Confluence page, Slack thread, parent ticket) instead of restating it.

## What
The change in concrete terms: affected flows, code areas, or endpoints.

## Out of scope
What this ticket deliberately does NOT cover (usually a sibling ticket — link it).

## Acceptance criteria
- [ ] Checkable, observable statements — each one testable by a reviewer
- [ ] Include the negative cases that matter, not just the happy path

## References
Related tickets, docs, code paths, designs.
```

- Summary: outcome-first, starts with a verb, specific enough to identify the ticket in a board column ("Add rate limiting to webhook endpoint", not "Webhook improvements").
- Write for a reader with no context from this conversation: name the systems, spell out acronyms once, and prefer links to source material over summaries of it.
- Acceptance criteria are the traceability contract — vague criteria ("works correctly") make progress unreportable. If you can't write a checkable criterion, the scope isn't understood yet; resolve that before creating the ticket.

## Linking

- Parent/epic membership expresses *belongs to*; use `-P` at creation.
- `Blocks` expresses *must happen first*; add it wherever siblings have an order.
- `Relates` is for shared context worth one click (same subsystem, same incident); don't relate everything to everything.
- When creating a ticket spawned by an existing one (follow-up, split-out scope), always link back to the origin ticket.
