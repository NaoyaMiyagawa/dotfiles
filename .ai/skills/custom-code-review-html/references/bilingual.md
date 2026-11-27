# Bilingual Code Review Pages

Read this only when the user explicitly requests a bilingual (EN/JA) report. For English-only reports, remove the template's `lang="ja"` markup and language switch.

Both languages ship as real `lang="en"` / `lang="ja"` markup with one hidden by CSS — never machine-translated at view time.

Prevent **layout drift** when toggling languages (the template already obeys these three rules):
- **Widths in `rem`, never `ch` or `em`** (font-relative units resize columns on font change).
- **One type scale for both** — no per-language `font-size`/`line-height` overrides; extend the font stack to cover both scripts instead of switching families.
- **Anchor scroll across switch** — record nearest block to viewport top and offset, swap, then correct scroll drift.

Translate prose, headings, severity words, and UI labels; leave code, identifiers, file paths, and line numbers untranslated.

Guard keyboard shortcuts so they never fire while typing: skip when target is an input/textarea/contenteditable, a modifier is held, or during IME composition (`isComposing` or `keyCode === 229`).
