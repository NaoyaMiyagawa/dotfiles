---
description: "Commit current changes: lint first, then follow custom git committing skill"
---

1. Read `~/dotfiles/.ai/skills/custom-git-commiting/SKILL.md` in full and treat it as the only spec for **how** to commit (message, hooks, hash). If your dotfiles live elsewhere, use the same path under your checkout.

2. **Before** staging or committing, ensure **linting/formatting is covered** for what will go in the commit: run the project’s usual checks on the touched paths and fix failures (or stop with a clear blocker). For PHP changes in a repo that uses Pint, follow `~/dotfiles/.ai/skills/custom-php-running-linter/SKILL.md`. For other stacks, use that repo’s standard lint/format commands for the files you changed.

3. If there is nothing to commit after that, say so and stop.

4. Otherwise complete the commit per the committing skill and report the commit hash.
