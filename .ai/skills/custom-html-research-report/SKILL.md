---
name: custom-html-research-report
description: Render research/learning output as a self-contained HTML page — diagrams for flows and architectures, tables for comparisons — instead of a long markdown file. Use when a research or explanation task ends in a deliverable about a new concept, standard, ecosystem, workflow, or data flow; when the user asks for an HTML report/page of findings; or when another skill (e.g. deep-research) needs a visual report format.
---

# HTML Research Report

Research lands better as one styled HTML page than a 100-line markdown wall: readers actually engage with it, and flows/architectures are seen, not parsed. Research is the thinking step; HTML is the rendering step — never let page-building displace source-reading.

## Workflow

1. **Finish the research first.** Gather and synthesize until you could answer follow-up questions without the page.
2. **Plan the visual skeleton.** Map each finding to its form: flow / architecture / lifecycle → inline SVG diagram; comparison of options or standards → table; sequence or history → timeline; everything else → prose. If nothing earns a visual, say so and deliver markdown instead — don't decorate text.
3. **Write one self-contained `.html` file.** Default location: `.ai/research/<yyyy-mm-dd>-<slug>.html` in the repo root (create the dir); outside a repo, use the cwd. If a page for this topic already exists there, update it instead of creating a sibling.
4. **Open it for the user** (`open <file>` on macOS). If the harness has an Artifact tool and the user wants a shareable link, publish it there too.
5. **Treat it as a living reference.** In later sessions, extend the same file as understanding deepens rather than minting a new page.

## Page rules

- **Zero network.** Inline all CSS/JS, hand-write diagrams as inline SVG, no CDNs/web fonts/mermaid — the file must render offline from disk.
- **Structure:** title + one-paragraph TL;DR → the main diagram → sections deep-diving each part of it → open questions → sources as real links.
- **Diagrams are the payload.** Boxes-and-arrows SVG for data flow and architecture; label every arrow with what crosses it (payload, protocol, trigger). A diagram that just restates section headings is decoration — cut it.
- **Readable defaults:** ~900px max-width centered, system font stack, generous spacing, `prefers-color-scheme` dark support, code in `<pre>` with horizontal scroll.
- **Interactivity only when it earns it** — tabs to compare alternatives, a toggle between overview/detail — in vanilla JS. No frameworks.
- **Distinguish fact from inference:** claims carry source links; your own synthesis is visually marked (e.g. an "analysis" callout), not blended in.
