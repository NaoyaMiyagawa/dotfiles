---
name: custom-email-html-template-review
description: Review and refactor Blade-rendered email HTML for client compatibility. Audit for unsupported CSS, risky assets (e.g. inline SVG, video), web fonts without fallbacks, external stylesheets, and layout that breaks in Gmail, Outlook (Word HTML), Yahoo, and Apple Mail. Return prioritized findings and rewrites (tables, inline styles). Use for Laravel mail Blade views, rendered MIME HTML checks, and pre-send audits. Triggers include Blade email template review and "will this work in Outlook/Gmail".
---

# Email HTML template review

## Goal

Take **rendered HTML** (or a Blade view plus its sample render) and determine whether it is safe for email clients. Return **structured feedback** and **rewritten HTML** (and, when relevant, **template-level changes**) that remove client-breaking patterns.

Email HTML is not web HTML. Assume **no flexbox/grid for layout**, **limited `<style>` support**, and **no JavaScript**. Treat Outlook (Word engine) and Gmail web as mandatory compatibility targets unless the user names a narrower audience.

## Inputs to request if missing

- The **final HTML string** from the Blade render (preferred), or the **`.blade.php` source** plus how to render it (e.g. `view()`, fixture data).
- **Audience**: B2B Outlook-heavy vs consumer Gmail, dark mode requirements, RTL.
- **Image hosting**: absolute HTTPS URLs available or must be CID attachments.

## Workflow

1. **Obtain rendered output**
   If only the template is available, render with representative data so conditionals/partials expand. Flag any paths still pointing at dev-only hosts.

2. **Run the audit**
   Apply the checklist in [references/email-html-constraints.md](references/email-html-constraints.md). Classify each issue: **blocker** (likely broken in major clients), **high** (common strip/break), **medium** (degraded), **low** (polish). For **specific HTML elements or CSS properties** you are unsure about, open the feature on [Can I email…](https://www.caniemail.com/features/) and compare support for the user’s target clients (e.g. Gmail, Outlook Windows).

3. **Report**
   Emit a short table: Issue | Severity | Evidence (selector/snippet) | Client impact | Fix strategy.

4. **Rewrite**
   - Prefer **nested tables** for layout, **inline `style`** on elements that need reliable sizing/spacing.
   - Keep a **single** `<style>` block only for resets/media queries the user explicitly needs; assume many webmail clients strip or scope it.
   - Replace unsupported patterns (e.g. flex centering) with **table + `align`/`valign`** or **ghost spacer** patterns where appropriate.

5. **Map back to the Blade view**
   State what to change in **source** (e.g. remove `@vite`/linked CSS for mail views, move dimensions inline, replace SVG logo with PNG + `width`/`height` + `alt`).

6. **Validate mentally or with tools**
   Use [Can I email…](https://www.caniemail.com/features/) to double-check borderline properties or elements before calling something safe. If the user can run checks, suggest **Litmus/Email on Acid** or **HTML Email Check** class tools; do not claim pixel parity without client tests.

## Blade (non-obvious)

- Avoid **bundled CSS** (`@vite`, `mix()`, global layouts) in mail views; output must not depend on external stylesheets unless the user accepts web-only behavior.
- **`asset()` / relative URLs**: email requires **absolute** `https://` (or `cid:`) URLs.
- **Components** that assume a web layout (flex, div grid) need **email-specific partials**.

## Progressive disclosure

- Full constraint list and examples: [references/email-html-constraints.md](references/email-html-constraints.md)

## References

- [references/email-html-constraints.md](references/email-html-constraints.md) — audit checklist, blocked/allowed patterns, rewrite tactics
- [Can I email… — feature index](https://www.caniemail.com/features/) — per-property / per-element support across email clients
