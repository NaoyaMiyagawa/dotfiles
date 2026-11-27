# Global Agent Rules

## Planning

Prefer plan mode for multi-step or architectural work — including verification
passes, not just building. If the approach stops working, stop and re-plan
rather than pushing through.

## Core Principles

- **Load `custom-general-coding` Before Writing Code**: Before writing or reviewing code in any language, invoke `custom-general-coding` (comments, guards, naming, structure, and review gate).
- **Verify Before Removing**: Before deleting or replacing code, search the codebase for remaining callers, routes, or references. Never infer something is dead from local context alone.
- **Comments Stand Alone**: Code comments, PR bodies, and issue descriptions must make sense without this chat. State the durable why — never "as discussed" or "above" — or drop the note.
- **Make Claims Checkable**: When reporting a defect, root cause, or review finding that turns on third-party or runtime behaviour, include the evidence (file:line in the dependency source, or output from a probe you ran). For cost or speed choices, measure (`EXPLAIN`, timing run) rather than estimating.
- **Someone Else's PR Is Read-Only**: When reviewing another person's PR, report findings in chat; don't post comments, edit, commit, or push to its branch unless explicitly asked.
- **Prove Removal Is Safe**: Before removing or tightening something live callers or data depend on (endpoint, validation rule, field), name the read-only check proving it's safe (per-environment count query, access-log filter) and put it in the ticket.
- **Start What Verification Needs**: When a check depends on a local service that isn't running (DB, search, queue container), start it and run the check.
- **Separate Pre-Existing From Introduced**: Distinguish defects introduced by the current change from pre-existing ones. Don't fold drive-by fixes, unrelated renames, whole-file reformatting, or dropped comments into the current branch; park deferred work in a GitHub issue or wiki note, not in chat. Keep changes small and split larger work into sequenced PRs.
- **Keep Reviewed PRs In Scope**: Non-blocking review feedback and small corrections go on the approved PR; only new scope goes in a later PR in the stack.
- **Write Plainly**: Everything a human reads reads like a senior engineer writing to a colleague: short declarative sentences, ordinary words, active voice, concrete numbers over adjectives. For AI-register audits, use `humanizer`.
- **GitHub Links On Their Own Bullet**: In GitHub comments, issues, and PR bodies, put each issue/PR link on its own `- ` bullet line so GitHub expands its title (never inline). In chat replies, write PR/issue numbers as clickable links.
- **Show Design Choices As Mockups**: When the user chooses between UI/visual options, show rendered mockups to compare rather than prose lists.
- **Ask For A Reference You Can't See**: If output must match an artifact you lack access to (design, spec, auth-gated ticket), ask for it before building rather than guessing.
- **Code Wins Over Stale Docs**: When repo docs (CLAUDE.md, AGENTS.md, READMEs, skills) disagree with existing code, follow the code and list every mismatch in your final reply.

## CLI Tool Calling
Prefer fast, purpose-built tools; fall back to legacy defaults only when needed.
- Contents → `rg` (not `grep`); files → `fd` (not `find`); replace → `sd` (not `sed`); JSON → `jq`; YAML → `yq`
- Code by AST shape → `ast-grep run -l <lang> -p '<pattern>' <dir>` (when `rg` hits comments/strings)
- Semantic code search → `ccc search --lang <lang> "<query>"` (only in repos with `.cocoindex_code/`; confirm hits with `rg`)
- Obsidian vault search → `qmd query "<question>" -c obsidian` (see `custom-obsidian-wiki-query`); rename/move/backlinks → `obsidian` CLI (needs desktop app running; ask to bypass sandbox if `~/.obsidian-cli.sock` is blocked)
- HTTP/URLs/extraction → `ax` (not `curl` + parsing scripts; `ax agent-context` for usage)
- Sentry → Sentry MCP (`get_sentry_resource` with issue URL)
- Browser checks/screenshots → `ego-browser` skill, not the built-in browser pane
- Diff → `delta`; benchmark → `hyperfine`; examples → `tldr`
- Scripts run under macOS zsh + BSD userland: use `[[ … ]]` (avoid `[ … ] && A || B`), anchor `grep`, avoid `!` inside double quotes, and use BSD-compatible flags.
