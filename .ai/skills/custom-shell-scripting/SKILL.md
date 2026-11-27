---
name: custom-shell-scripting
description: Shell script conventions (header/function comments, step markers, result separator, purpose naming). Use when writing or editing scripts under `scripts/`, `bin/`, or CI.
---

# Shell scripts

A script is read far more often by someone unfamiliar with the flow than by its author. Write it for that reader.

## Rules

1. **Header comment first.** Below the shebang: why the script exists, the flow as numbered steps, and what a zero exit proves. A reader must be able to describe what the script does from the header alone.
2. **A comment above every function** stating what it does and, where it isn't obvious, why it exists.
3. **Step markers in the body.** Each numbered step from the header appears as a comment where it starts, so the header and the code line up.
4. **A separator before the result.** Print a visible line such as `--------- Result ---------` before the final output so it stands out from progress noise.
5. **Name by purpose and consumer.** A script that exists for a PR flow says so in its name (`visual-check-artifacts-for-pr.sh`); its output file does the same (`comparison-table-for-pr.md`).
6. **Same structure across sibling scripts.** When a repo has several scripts, apply rules 1–4 to all of them, not only the one under review.
