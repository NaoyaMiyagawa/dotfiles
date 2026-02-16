# Global Agent Rules (Lean)

This file stays minimal on purpose. Task-specific rules live in custom skills.

## Skill Routing

Load custom skills only when relevant:

- `custom-gh-pr-context`
  - Trigger: User asks for PR context, PR summary, or PR-related task details.
- `custom-gh-pr-review-fix`
  - Trigger: PR review comment fix requests.
- `custom-laravel-backend`
  - Trigger: Laravel/PHP backend implementation or refactoring.
- `custom-laravel-testing`
  - Trigger: Pest tests, feature tests, factories, datasets, TDD workflow.
- `custom-laravel-static-analysis`
  - Trigger: Formatting/static analysis commands (Pint/PHPStan policy).

For non-Laravel tasks, do not apply Laravel-specific skill rules.
