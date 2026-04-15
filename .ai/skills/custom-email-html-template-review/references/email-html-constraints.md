# Email HTML constraints (audit reference)

Table of contents: [Cross-check support](#cross-check-support) · [Structure](#structure-and-doctype) · [CSS](#css) · [Images and media](#images-and-media) · [SVG and advanced graphics](#svg-and-advanced-graphics) · [Typography and icons](#typography-and-icons) · [Interactivity and scripts](#interactivity-and-scripts) · [Forms](#forms) · [Links and URLs](#links-and-urls) · [Tables and layout](#tables-and-layout) · [Dark mode](#dark-mode) · [Common ESP placeholders](#common-esp-placeholders)

Use this file while auditing **rendered** HTML. Severity is relative to **Gmail (web + app)**, **Outlook Windows (Word HTML)**, **Apple Mail**, **Yahoo**.

---

## Cross-check support

When a rule here is too coarse or the markup uses an **unfamiliar element or CSS feature**, look it up on **[Can I email… — feature index](https://www.caniemail.com/features/)**. Filter or read the matrix for the same clients you care about (at minimum Outlook Windows and Gmail web). Prefer that source over guessing for borderline cases (e.g. `border-radius`, `@media (prefers-color-scheme)`, embedded SVG).

---

## Structure and doctype

- Use HTML email doctype commonly recommended for email: `<!DOCTYPE html>` with **HTML4-ish habits** (tables, inline styles) still dominates production.
- Include `meta charset="utf-8"` and viewport meta for mobile; some clients ignore viewport but it does not hurt.
- **Single root**: one outer layout table or centered wrapper pattern is fine; avoid deep unnecessary nesting (Outlook nesting limits).

---

## CSS

**Assume most clients:**

- Honor **inline `style`** most reliably on the element that needs the rule.
- Partially honor **`<style>` in `<head>`**; webmail may strip `<head>`, rewrite selectors, or scope CSS so class-based rules **disappear or misfire**.
- **Strip** `position: fixed/absolute` for many layouts; **avoid** relying on z-index stacks.

**Treat as high risk / blocker for layout:**

- **Flexbox and CSS Grid** for primary structure (especially Outlook Word).
- **`margin: auto` centering** as the only centering strategy for full-width layouts; prefer **wrapper table `align="center"`** + fixed width inner.
- **`float`** — inconsistent; prefer tables for multi-column.
- **`gap`**, **`transform`**, **`filter`**, **`clip-path`** — generally unsafe for core layout.
- **Viewport units** (`vh`, `vw`) — unreliable.
- **Custom fonts** — web fonts are **partially supported**; always provide **system font fallbacks** and expect Outlook to ignore `@font-face`.

**Safer patterns:**

- **Tables** for rows/columns; **`align` / `valign`** where helpful.
- **Inline** `width`, `max-width`, `font-family`, `font-size`, `line-height`, `color`, `background-color`, `padding`, `border`, `text-align`.
- **Bulletproof buttons**: table-based or VML for Outlook if pixel-perfect buttons are required (optional advanced pattern).

---

## Images and media

- **Always** `width` and `height` attributes (or inline styles) and meaningful **`alt`**.
- **HTTPS absolute** URLs; no protocol-relative `//`.
- **`background-image`**: spotty in Outlook; for hero backgrounds use **nested table + `bgcolor`** fallback or VML (advanced).
- **Video / audio / `<iframe>`** — not viable in email for broad compatibility; use **still image + link**.
- **Animated GIF** — widely supported; heavy assets hurt load.
- **Base64 inline images** — often blocked or stripped by size; prefer hosted or CID.

---

## SVG and advanced graphics

- **Inline SVG**, `<object>`, `<embed>` — **unsafe** for broad email; many clients strip or ignore.
- **SVG as `<img src="...svg">`** — **inconsistent**; prefer **PNG** (or JPEG) for logos/diagrams when compatibility matters.
- **CSS gradients** as critical backgrounds — unreliable; use **flat color** or **image**.

---

## Typography and icons

- **Icon fonts** — often blocked or fall back poorly; prefer **small raster** or **Unicode** with care.
- **`line-height`**: use px or unitless with testing; `%` can behave oddly in some clients.
- **`webfont`**: see CSS section — never rely on it as the only readable face.

---

## Interactivity and scripts

- **No JavaScript** (`<script>`, inline handlers). Strip or replace with static content.
- **`<map>` / image maps** — avoid.
- **Hover-dependent** critical UI — fine as enhancement only.

---

## Forms

- **Forms** (`<form>`, inputs) — **do not rely** on submission inside email; many clients strip or block. Prefer **CTA link** to a web form.

---

## Links and URLs

- Use **full absolute** URLs for `href` and `src`.
- **`mailto:`** — ok; test on mobile.
- **Anchor fragments** — limited use in some clients.
- **Preheader text**: hidden span/table row technique if the user needs it; keep it short.

---

## Tables and layout

- **`<div>`-only layouts** fail or degrade in Outlook Word HTML; use **tables** for main structure.
- **`role="presentation"`** on layout tables improves accessibility; keep **semantic text** in cells.
- **Padding**: prefer **cellpadding** / **nested spacer** rows for Outlook quirks when padding “disappears”.
- **Max-width fluid**: common pattern is fixed-width inner table (e.g. 600px) + fluid outer; test mobile wrapping.

---

## Dark mode

- Clients may **invert** colors or honor `prefers-color-scheme` only partially.
- Avoid **pure white `#fff` on pure black** without testing; consider **meta color-scheme** and targeted overrides only if the stack supports tested templates.

---

## Common ESP placeholders

- Merge tags (`{{ unsubscribe }}`, `<% ... %`, etc.) must remain **valid HTML** around them; do not break table structure when substituting.

---

## Rewrite tactics (quick)

1. Replace flex/grid sections with **table rows/columns**.
2. Move critical visual rules **inline**; trim unused classes if `<style>` is stripped.
3. Swap **SVG/icon font** to **PNG** where needed.
4. Remove **video/iframe/form/script**.
5. Fix **relative URLs** to absolute; add **alt/size** on images.
6. Re-test **Outlook** and **Gmail** mentally against each change.
