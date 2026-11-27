---
name: custom-react-coding
description: React/TypeScript conventions (component boundaries, file layout, props, data lifecycle, browser cache checks). Use when writing or refactoring React/TS modules or specs.
---

# React Coding Conventions

The core rules below decide a component's shape, its files, and its signatures, so hold them in mind while writing. Style rules (naming, formatting, comments, spec conventions) live in [references/checklist.md](references/checklist.md) — the review gate enforces them, so don't try to hold them in mind; read one only when its detail matters.

## Component boundaries

1. **No pass-through wrapper component.** A component whose only job is to fetch
   data and forward it as props to one child does not earn a file. Move the fetch
   into the child. Add a wrapper only when a second consumer needs the child with
   different data.
2. **Reach for the shared component library first.** Before hand-rolling a dialog,
   field, or layout primitive, check what the design system already exports and use
   it. A custom variant needs a stated reason the shared one couldn't cover.
3. **Split a long page or component by section.** When a file grows past what fits
   on screen, extract its distinct visual sections into child components under a
   nested `Partials/` directory next to the parent — one component per section, not
   one per JSX block.
4. **Name the component for what it renders.** `Modal` describes a mechanism;
   `UserInviteModal` describes the thing. When the content narrows during review,
   rename the file and component to match.

## File layout

5. **Colocate types with the component.** Props and local types live in the `.tsx`
   file that uses them. Create a sibling `Component.types.ts` only when a second
   module imports those types.
6. **Export only what another module imports.** A helper used in one file stays
   module-private.

## Props and parameters

7. **An entity is one prop.** A component
   that reads several fields of one entity takes the entity as one prop, typed by
   its resource interface, not each field picked out by the parent.
8. **Three or more parameters, or any boolean parameter, become one object,** so
   the call site reads as named arguments; up to two stay positional.
9. **A label helper gets its own translator.** A helper or hook that builds translated labels gets the
   translator itself (the shared `i18n.t("ns:key")` in a plain function, the
   translation hook in a hook) instead of taking `t` as a parameter, so callers
   pass only data.

## Data lifecycle

10. **Branch on the fetch hook's lifecycle flags.** Render loading, error, and
    success states from what the data hook already exposes (`isLoading`, `isError`,
    `data`). Rename them to their subject as you destructure
    (`{ data: invoice, isLoading: isLoadingInvoice }`), so the JSX reads
    `isLoadingInvoice && <Spinner />`, `invoice && <Content />` — a bare `data`
    hides what it holds. Don't derive a parallel status from the presence or
    absence of fields; when the render logic follows the data lifecycle it reads
    top to bottom.

## Unavailable states

11. **Disable at the point of choice, and say why.** When an option or input is
    unavailable under the current state, disable it where the user would pick it and
    state the governing rule in a tooltip. Don't hide it, and don't let the user
    select it only to reject it later.

## Checking a design fix in the browser

12. **Load the page past every cache, then confirm which build it loaded.** A stale
    copy looks exactly like a fix that didn't work. A hard reload is not enough: it
    skips the cache only for the top page, not for an iframe whose `src` script sets
    later, which is how rendered certificates and embeds load.
    - Before judging the result, open the page in a fresh or private profile, or
      with DevTools "Disable cache" ticked for the whole session. When asking the
      user to check, tell them to use a private window.
    - Confirm the frame that shows the design loaded the new build: its hashed CSS/JS
      filename, or a rule you just added, read from that frame's own document.
    - For a deployed check, first confirm the server sends the new build.
      `curl -sI` each path and compare `last-modified` and `x-cache`. A CDN can keep
      serving an old `index.html` that has no `Cache-Control`.

## Review gate (mandatory)

Changed React or TypeScript is not done until it has passed the review gate in the `custom-general-coding` skill. Its checklist is the core rules above and [references/checklist.md](references/checklist.md).
