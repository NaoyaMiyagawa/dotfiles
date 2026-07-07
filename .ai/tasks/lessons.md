# Lessons

Patterns captured after user corrections (see AGENTS.md → Self-Improvement Loop).

<!-- Add entries as: ## YYYY-MM-DD — short title / what went wrong / rule to prevent it -->

## 2026-07-07 — Generated shell scripts must run under macOS zsh
- **What went wrong:** Hand-written helper/smoke-test scripts used bash-isms that broke or silently misbehaved under the user's macOS zsh (BSD userland).
- **Rule:** When authoring shell scripts here, target macOS zsh, not bash/Linux. Use `[[ … ]]` for tests instead of the `[ … ] && A || B` idiom (the `||` branch also fires when `A` fails). Anchor `grep` patterns so partial matches don't pass. Avoid `!` inside double-quoted strings (zsh history expansion). Prefer BSD-compatible flags, or invoke GNU tools explicitly when a GNU-only flag is required.
