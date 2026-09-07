---
name: custom-react-coding
description: Applies React/TSX component conventions — file layout, component boundaries, and JSX formatting. Use when implementing or refactoring React components, pages, or their types.
---

# React Coding Conventions

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

## Data lifecycle

6. **Branch on the fetch hook's lifecycle flags.** Render loading, error, and
   success states from what the data hook already exposes (`isLoading`, `isError`,
   `data`) — `isLoading && <Spinner />`, `data && <Content />`. Don't derive a
   parallel status from the presence or absence of fields; when the render logic
   follows the data lifecycle it reads top to bottom.

## JSX formatting

7. **Blank line between sibling elements.** Separate adjacent tags at the same
   nesting level with one blank line, including after a closing `)}` of a
   conditional. This is `react/jsx-newline` (`{"prevent": false}`) in
   eslint-plugin-react — enable it where the repo lints JSX rather than fixing it
   by hand.

```tsx
<Typography component="h6">{label}</Typography>

<div className="flex items-center gap-2">
  <Typography component="p2">{url}</Typography>

  <CopyToClipBoardButton textToCopy={url} />
</div>
```

## Tests

8. **AAA comments in every spec.** Each test body carries `// Arrange`, `// Act`,
   `// Assert` markers, same as the Laravel test convention.
