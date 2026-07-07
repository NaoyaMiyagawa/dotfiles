---
name: custom-obsidian-wiki-query
description: Answer domain-knowledge or codebase-knowledge questions from the personal Obsidian knowledge wiki (vault root in `$OBSIDIAN_VAULT`). Use when the user asks what a project or module does, its requirements, specs, business rules, flows, or architecture — e.g. "how does Nexus auth work", "what are the billing requirements", "what does the wiki say about verification", "explain the workflow module" — or explicitly references the Obsidian vault/wiki. Read-only by default; can file a reusable answer back as a new wiki page. This is the Obsidian vault, NOT the LLM Wiki desktop app (use the `llm-wiki` skill for that).
---

# Custom Obsidian Wiki Query

Implements the **query** workflow of the vault's LLM Wiki method. The vault's own
`CLAUDE.md` (`$OBSIDIAN_VAULT/CLAUDE.md`) is the schema — read it if you need the conventions.

## Scope

- Use for domain / spec / architecture / codebase questions that a project wiki may already answer.
- Skip if the user wants a fresh code search unrelated to documented knowledge, or names the **LLM Wiki** app (that's the separate `llm-wiki` skill).
- Read-only by default. Only write pages back when the user asks or confirms.

## Vault layout

- Root: `$OBSIDIAN_VAULT` — resolve it once (`echo "${OBSIDIAN_VAULT:?set OBSIDIAN_VAULT in your shell env}"`) and use that absolute path with Read/Grep, which don't expand env vars.
- Project wikis: `projects/<name>/wiki/` (e.g. `nexus`, `nucleus`)
- Spine: `projects/<name>/index.md` (catalog), `log.md` (history); raw inputs in `sources/`
- The whole vault is indexed as the **qmd collection `obsidian`** (hybrid lexical + semantic search). qmd paths mirror vault-relative paths: `qmd://obsidian/projects/nexus/wiki/Auth.md` ⇄ `$OBSIDIAN_VAULT/projects/nexus/wiki/Auth.md`.
- Reading needs no setup — qmd/Grep/Read work directly. Writing a page back may require `/add-dir "$OBSIDIAN_VAULT"`.

## Search with qmd

Discovery goes through the local **qmd** CLI (see `qmd skill show` for full query craft). Default to the structured hybrid query — **you** author the fields, don't paste the user's sentence and lean on expansion:

```bash
qmd query $'intent: <what to find, and the nearby-but-wrong concepts to avoid>\nlex: <exact page titles, entities, code symbols>\nvec: <the idea paraphrased in source-like wording>'
qmd query "..." -c obsidian        # scope to the vault collection when the index holds other collections too
qmd search '"exact phrase" title terms' -n 10   # BM25 only — faster when you know exact titles/symbols
```

Then pull full pages before answering — snippets are only leads:

```bash
qmd get "#f40328"                  # by docid (line-numbered, carries path + docid)
qmd multi-get "#f40328,#db3667" --format md
```

If a model-backed command fails (models/GPU unavailable), fall back to `qmd search`, then to Grep/Read over the resolved `$OBSIDIAN_VAULT` paths.

## Workflow

1. **Scope the project.** If the user names one, use it. Else infer from CWD (working in the Nexus repo → `projects/nexus`). Else search the whole collection.
2. **Find relevant pages.** Run `qmd query` (see above) with intent tuned to the project/topic. Skim the project `index.md` for the catalog when useful, then `qmd get`/`multi-get` the top hits for full content.
3. **Answer with citations.** Synthesize from the wiki content. Cite the pages used as `[[Page]]`, and pass through the repo paths / source pages those pages themselves cite. Distinguish documented fact from inference, and surface any relevant `> [!question] Open questions`.
4. **Handle gaps honestly.** If the wiki doesn't cover it, say so — do not fabricate. Offer to **ingest**: read the actual codebase/source (the repo you're working in) to answer now and, if useful, write a new page per the method.
5. **Optionally file back** (only on request/confirmation). Create or update a page under `projects/<name>/wiki/` using the vault conventions (frontmatter, `[[wikilinks]]`), add it to `index.md`, bump `updated:`, and append a `## [DATE] query | ...` line to `log.md`. Then re-index so it's searchable: `qmd update -c obsidian && qmd embed` (see the `custom-obsidian-wiki-write` skill for the full file-back workflow).
