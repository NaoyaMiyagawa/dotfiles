---
name: custom-gh-pr-reading-guide
description: Add a reviewer's reading guide to a GitHub PR description — a mermaid mental-model diagram plus an ordered "read this, then this" table that routes a reviewer into unfamiliar code. Use when a PR introduces a subsystem, protocol, format, or vocabulary of types the reviewer has no prior model of, or when asked for a reading guide, a mental model, or a "fastest path to understanding this PR" section.
metadata:
  short-description: Add a mental-model + reading-order guide to a PR description
---

# PR Reading Guide

A reviewer facing unfamiliar code doesn't need a list of what changed — the diff has that. They need a **route**: one picture of how the pieces fit, then an order to open files in, so each file makes sense by the time they reach it.

Earn it first. This is for a PR that introduces something the reviewer holds no prior model of — a wire format, an encoder, a protocol, a state machine, a new vocabulary of types. A CRUD endpoint or a refactor doesn't need one; say so rather than writing one anyway.

## Workflow

1. `gh pr view --json number,url,headRefOid,body` — the SHA pins every link you write, and you need the current body to splice into.
2. Read the diff and answer one question for yourself: **what invariant makes this design work?** ("the encoder picks type from the PHP type, never from content"). Everything below is built to deliver that answer; if you can't state it in a sentence, you can't write the guide yet.
3. Draw the mental model.
4. Build the reading order.
5. Splice it into the description.

## Mental model

A `flowchart LR` mermaid block — GitHub renders mermaid in PR descriptions natively.

- **Every node label carries its job or its invariant, not just its name.** `head() — one byte states type + size` teaches; `head()` decorates. This rule is what separates a diagram worth posting from a boxes-and-arrows sketch.
- One node per *concept*, not per class. Group a family of types into a single node labelled with what the family is for.
- Draw the system's key property as a **dotted edge back to where it closes** — the round-trip, the idempotency, the invalidation. That edge is usually the thing a reviewer most needs to see and least likely to infer.
- Seven nodes is the ceiling. If it won't fit, the PR wants splitting, not a bigger diagram.

## Reading order

A table, introduced by a line that names where the core is (`read in this order; steps 3–4 are the core`).

| # | Read | What you get |
|---|------|--------------|

- Order by **what must be understood first**, never by diff order, file order, or alphabet. Step *n* should be readable because the reviewer did step *n-1*.
- **Read** names one exact symbol, class, or directory, linked to the pinned SHA (`blob/<headRefOid>/path#L40-L80`). Not "the changes in `src/`".
- **What you get** is the payoff — the question that opening it answers. It is not a description of the code, and it is not "what changed"; the moment a row reads like a changelog entry, cut the row.
- Bold the one or two core rows so a reviewer short on time knows where to spend it.
- End on the **proof**: the tests. Name the single test worth reading and what it demonstrates end-to-end ("decodes the official example and re-encodes it byte-for-byte").
- Four to seven rows. Longer than that isn't a path, it's an index.

## Placing it in the description

Goes at the **bottom** of the PR body, below the motivation and the change bullets, under its own heading. Everything above it stays as short as `custom-gh-pr-creating-editing` requires — the guide is what a reviewer scrolls to when they're ready to start reading code, not what greets them.

Delimit the block so a re-run can replace it rather than append a second copy:

```md
<!-- pr-reading-guide -->
## Reading guide
...diagram + table...
<!-- /pr-reading-guide -->
```

`gh pr edit` **replaces the entire body**, so never hand it the guide alone. Read the current body, splice the block in (or swap what's between the existing markers), write the whole thing to a scratch file, then:

```bash
gh pr edit <number> --body-file <path>
```

The guide is orientation and nothing else. It doesn't restate the description's *why* above it, and it isn't a delta timeline — that's `custom-gh-pr-summary-comment`.
