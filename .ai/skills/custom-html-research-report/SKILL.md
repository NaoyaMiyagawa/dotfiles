---
name: custom-html-research-report
description: Render research/learning output as a self-contained HTML page — diagrams for flows and architectures, tables for comparisons — instead of a long markdown file. Use when a research or explanation task ends in a deliverable about a new concept, standard, ecosystem, workflow, or data flow; when the user asks for an HTML report/page of findings; or when another skill (e.g. deep-research) needs a visual report format.
---

# HTML Research Report

Research lands better as one styled HTML page than a 100-line markdown wall: readers actually engage with it, and flows/architectures are seen, not parsed. Research is the thinking step; HTML is the rendering step — never let page-building displace source-reading.

## Workflow

1. **Finish the research first.** Gather and synthesize until you could answer follow-up questions without the page.
2. **Plan the visual skeleton.** Map each finding to its form: flow / architecture / lifecycle → inline SVG diagram; comparison of options or standards → table; sequence or history → timeline; everything else → prose. If nothing earns a visual, say so and deliver markdown instead — don't decorate text.
3. **Write one self-contained `.html` file** at `~/dotfiles/.ai/research/<yyyy-mm-dd>-<slug>.html` (create the dir) — research pages accumulate centrally here, not in whatever repo you happen to be in. If a page for this topic already exists there, update it instead of creating a sibling.
4. **Open it for the user** (`open <file>` on macOS). If the harness has an Artifact tool and the user wants a shareable link, publish it there too.
5. **Treat it as a living reference.** In later sessions, extend the same file as understanding deepens rather than minting a new page.

## Page rules

- **Zero network.** Inline all CSS/JS, hand-write diagrams as inline SVG, no CDNs/web fonts/mermaid — the file must render offline from disk.
- **Structure:** title + one-paragraph TL;DR → the main diagram → sections deep-diving each part of it → open questions → sources as real links.
- **Diagrams are the payload.** Boxes-and-arrows SVG for data flow and architecture; label every arrow with what crosses it (payload, protocol, trigger). A diagram that just restates section headings is decoration — cut it.
- **Readable defaults:** ~900px max-width centered, system font stack, generous spacing, `prefers-color-scheme` dark support, code in `<pre>` with horizontal scroll.
- **Interactivity only when it earns it** — tabs to compare alternatives, a toggle between overview/detail — in vanilla JS. No frameworks.
- **Distinguish fact from inference:** claims carry source links; your own synthesis is visually marked (e.g. an "analysis" callout), not blended in.

## Bilingual pages

Only when the user wants a second language. Both languages ship as real `lang="en"` / `lang="ja"` markup with one side hidden by CSS — never machine-translated at view time. Paste in `assets/lang-switch.html` rather than rebuilding it: it carries the switch markup, the CSS, the persisted preference, the `s` shortcut and the scroll anchoring.

The whole risk is **layout drift**: if the column or the type metrics change with the language, the passage under the reader's eye moves, and switching becomes unpleasant enough that they stop doing it. Three rules prevent it:

- **Widths in `rem`, never `ch` or `em`.** A font-relative measure resizes the entire column when the font stack changes.
- **One type scale for both.** Per-language `font-size` and `line-height` overrides *are* the drift. If the display face lacks the second script's glyphs, extend the font stack to cover both scripts — fallback resolves per character — rather than switching family by language.
- **Anchor the scroll across the switch.** The snippet handles this; keep its `ANCHOR_SELECTOR` in step with the page's actual block elements.

Translate prose, headings, captions and UI labels. Leave code, identifiers, file paths and URLs untranslated on both sides. Diagrams stay single-copy: keep SVG labels to identifiers so one diagram serves both languages, and where a label has to be prose, pair the `<text>` elements by `lang` — SVG text sits at fixed coordinates, so it cannot drift.

Before publishing, check that every `lang="en"` element has a `lang="ja"` counterpart of the same tag. An unpaired block silently vanishes in one language, and that is invisible until someone switches.
