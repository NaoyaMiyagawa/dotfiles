# React coding checklist — style rules

The review gate in `../SKILL.md` enforces this list; the design rules live there. A rule belongs here when its fix can be applied after the code is written without changing a signature or moving a file; a rule that needs either belongs in the core (move, don't copy). Cross-references use section and rule names, not numbers, so a reorder doesn't break them.

## File layout

1. **Entry point first, helpers below.** The exported entry point comes first as a short list of calls;
   the helpers it calls follow below it as function declarations, in call order. A helper that reads none of the enclosing function's
   variables sits at module level, not nested inside that function.

## Types and naming

2. **Explicit return types on module functions.** Every function in a `.ts` module
   states its return type. This is `@typescript-eslint/explicit-function-return-type`
   — enable it where the repo's linter offers it rather than checking by hand.
3. **No redundant type assertion.** `as const` already fixes a literal's type; don't
   add `satisfies`, a `Record<...>` annotation, or an `as readonly T[]` cast on top
   of a declaration that already carries the type.
4. **Name a collection as a plural noun and a lookup by its key.** `availableActions`,
   not `available` (reads as a boolean); `errorsByActionType` for an
   `{ [actionType]: error }` map. A value that holds a UUID is named `uuid` or
   `documentUuid`, never `id`. A type is as narrow as the data: no `| null` or `?`
   on a value that is always present. Group related top-level values under one named object (`resources.backendModules`,
   `storageKeys.lastReload`) rather than a run of standalone consts. Name a helper
   that decides what the UI does `shouldX` (`shouldLockAction`, `shouldShowAction`);
   keep `isX` for a plain state predicate. A `useState` boolean that decides what
   the UI shows is `showX`/`shouldX` (`showDocumentsPanel`); a boolean prop that
   describes the component's own state is `isX` (`isOpen`). A module-level constant
   is camelCase like any other const (`maxRetries`). When a parameter accepts a
   fixed set of string values, export them as a const object so callers write
   `resourceType.invoice`, not the string literal.
   - **Type an API payload after the backend resource that sends it.** The interface
     takes the resource's class name (`OrderDetailResource` ↔ `OrderDetailResource`)
     and lists fields in the resource's key order, so a reader can map one to the
     other line by line.

## Props

5. **Defaulted props last.** In a props type and its destructuring, required
   props come first and any prop with a default value sits at the end.

## Formatting

6. **Blank line between sibling elements.** Separate adjacent tags at the same
   nesting level with one blank line, including after a closing `)}` of a
   conditional. Elements that render as one unit (a visual badge and its sr-only
   text) sit together with no blank line. A tag with two or more props puts one
   prop per line. The blank-line part is `react/jsx-newline`
   (`{"prevent": false}`) in eslint-plugin-react — enable it where the repo lints
   JSX rather than fixing it by hand.

```tsx
<Typography component="h6">{label}</Typography>

<div className="flex items-center gap-2">
  <Typography component="p2">{url}</Typography>

  <CopyToClipBoardButton textToCopy={url} />
</div>
```

7. **Blank lines mark sections.** Set a group of statements that belong together
   (a hook call and the consts derived from it) apart from its neighbours with one
   blank line above and below. When statements precede a `return`, separate them
   with one blank line. The `return` case is ESLint `padding-line-between-statements`
   (`{ blankLine: "always", prev: "*", next: "return" }`, under `@stylistic` on
   ESLint 9) — enable it where the repo lints TS rather than fixing it by hand.
   Brace every `if`/loop body, even a one-line `continue` or `return` (ESLint
   `curly: ["error", "all"]`). A chain of calls breaks one call per line as soon
   as any call takes an inline callback; a chain of plain references stays on one
   line (`Object.entries(users).filter(isActive).map(toName)`).

## Tests

8. **AAA comments in every spec.** Each test body carries `// Arrange`, `// Act`,
   `// Assert` markers, same as the Laravel test convention.
9. **Drive interactions through `userEvent.setup()`.** Create the instance in the
   Arrange step (`const user = userEvent.setup();`, before `render`) and call
   `user.click()`, `user.type()`, `user.hover()` on it. Never call
   `userEvent.click()` directly. Each direct call builds its own fresh session,
   so pointer and keyboard state does not carry from one step to the next. When you add a test to a file whose older tests call `userEvent.*`
   directly, use `setup()` in the new test and leave the old tests alone.
10. **Use a shared fixture by its own name.** Reference an imported mock directly;
    don't rebind it to a local alias (`const mockPdfContent = mockSignedDocument;`).
    Name a fixture `mock` + the type it stands in for (`mockOrderDetail`).
11. **Declare cases with `it()`, not `test()`,** wherever the runner exports it.

## Comments

12. **Doc comment form.** A function's doc comment is a multi-line `/** */` block
    even when the text fits on one line; an interface field or object property
    takes a `//` line above it.

## Functions and rendering

13. **A handler is named `onX`,** the same as the prop it is passed to
    (`<DocumentList onSelectDocument={onSelectDocument} />`).
14. **Two mutually exclusive elements render from one ternary,** not two
    complementary `&&` blocks.
15. **A tooltip is the app's styled tooltip component,** never the browser's
    native `title` attribute.
