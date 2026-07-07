---
name: custom-obsidian-wiki-write
description: Write or update knowledge in the personal Obsidian knowledge wiki (vault root in `$OBSIDIAN_VAULT`) (the ingest / file-back workflow). Use when the user wants to capture a requirement, spec, business rule, decision, or architecture note; record what was just built or learned; ingest a source document; or save a synthesized answer back as a wiki page — e.g. "add this to the wiki", "document this in Obsidian", "ingest these notes", "update the Nexus auth page". This is the Obsidian vault, NOT the LLM Wiki desktop app (use the `llm-wiki` skill for that). For Obsidian syntax details, also use the `obsidian-markdown` skill.
---

# Custom Obsidian Wiki Write

Implements the **ingest / file-back** workflow of the vault's LLM Wiki method. The vault's
own `CLAUDE.md` (`$OBSIDIAN_VAULT/CLAUDE.md`) is the authoritative schema — follow its
conventions and workflows.

## Scope

- Use to add or update durable knowledge: requirements, specs, business rules, decisions, architecture, or a reusable answer.
- Capture the *what* and *why* (intent, rules, constraints) — NOT code mechanics; those live in git.
- Names the **LLM Wiki** app → use `llm-wiki` instead. Pure Markdown-syntax questions → `obsidian-markdown`.

## Vault layout

- Root: `$OBSIDIAN_VAULT` — resolve it once (`echo "${OBSIDIAN_VAULT:?set OBSIDIAN_VAULT in your shell env}"`); Read/Grep/Write need the absolute path, they don't expand env vars.
- Project wikis: `projects/<name>/wiki/` (pages live here); spine: `projects/<name>/index.md`, `log.md`; raw inputs: `projects/<name>/sources/`
- Templates: `templates/topic.md`, `templates/source-summary.md`
- The vault is outside your repo — to write, run `/add-dir "$OBSIDIAN_VAULT"` first.
- The vault is indexed as the **qmd collection `obsidian`**; anything you write must be re-indexed (step 8) before it's searchable.

## Workflow

1. **Scope the project.** Use the one the user names, else infer from CWD (Nexus repo → `projects/nexus`), else ask.
2. **Pick the target.** Read `index.md` and Grep `wiki/` to find an existing page to update; otherwise create a new page from the matching template. One concept per page — split rather than sprawl.
3. **Write at the right altitude.** Requirements/specs/why. Use frontmatter (`type`, `tags`, `updated`), `[[wikilinks]]` for internal links, and callouts. Cite where it came from in a `## Sources` section (repo paths, source pages, PR/ticket). For pages that document code, also stamp **provenance frontmatter** (see below) so drift can be detected later.
4. **Keep the graph healthy.** Create pages for referenced concepts that lack one; update cross-references on related pages; flag conflicts with the existing wiki using `> [!warning]` instead of silently overwriting. Resolve any `> [!question] Open questions` the new knowledge answers.
5. **Update the spine.** Add/refresh the entry in `index.md` (correct category), and bump the page's `updated:` to today's date.
6. **Log it.** Append one line to `log.md`: `## [YYYY-MM-DD] ingest | <what changed; link the pages>` (use today's date).
7. **Raw sources.** Drop raw files into `sources/` (immutable — never edit them), then summarize each as a `type: source` page from `templates/source-summary.md`.
8. **Re-index qmd.** After the files are written, refresh the search index so the new/changed pages are findable:

   ```bash
   qmd update -c obsidian && qmd embed   # re-index changed files, then refresh vectors for the semantic query mode
   ```

   `qmd update` alone makes pages findable via `qmd search` (lexical); `qmd embed` is what lets `qmd query`'s semantic/hybrid mode see them. Run both after any write. If embedding fails (models/GPU unavailable), the lexical index is still updated.

## Provenance (code-derived pages)

Pages that document a codebase must carry machine-readable provenance so staleness can be detected automatically. In addition to the standard frontmatter, add:

```yaml
source_repo: Accredifysg/Nexus        # repo the page describes
source_commit: 3c7ed12                # repo HEAD (short SHA) when the page was last verified
source_paths:                         # the code this page is derived from
  - app-modules/workflow/src/WorkflowSteps/Actions
  - app-modules/workflow/src/Services/Document
```

- Set `source_commit` to that repo's `git rev-parse --short HEAD` at write time, and **re-stamp it (and `updated`) whenever you re-verify** the page against the code.
- List the narrowest `source_paths` the page actually describes — a staleness check diffs exactly these: `git log <source_commit>..HEAD -- <source_paths>`. Non-empty ⇒ the page is stale.
- Document-derived pages (articles, transcripts) don't need these; their provenance is the file in `sources/`.
