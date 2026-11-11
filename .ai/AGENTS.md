# Global Agent Rules

## Planning

Prefer plan mode for multi-step or architectural work — including verification
passes, not just building. If the approach stops working, stop and re-plan
rather than pushing through.

## Core Principles

- **Load `custom-general-coding` Before Writing Code**: Before writing or reviewing code in any language, invoke the `custom-general-coding` skill — the catalogue of comments worth keeping, plus rules on naming, paired helpers, denormalized copies, dependency fixes, and library swaps.
- **Prove It Before Guarding**: Don't add a guard, fallback, or refetch for a state you haven't shown is reachable. Trace the concrete sequence that produces the bad state first; if you can't, leave the code bare.
- **Verify Before Removing**: Before deleting or replacing code, search the codebase for remaining callers, routes, or references. Never infer something is dead from local context alone — a component can look unused where you're editing yet still power an active flow elsewhere.
- **Comments Stand Alone**: A code comment, PR body, or issue description must make sense to a future reader with no access to this chat. Don't leave notes that only parse with the conversation's context ("as discussed", "the value we picked above"); state the durable why, or drop the comment.
- **Comments Carry Only What Code Can't Say**: Delete a comment that restates the code; a previous implementation belongs in git, not in a comment or a decision note. Keep only what a reader can't derive, and state the real reason — when you don't know it, state the rule plainly instead of inventing a justification.
- **Make Claims Checkable**: When you report a defect, root cause, or review finding that turns on third-party or runtime behaviour, hand over the evidence with it — the file and line in the dependency's own source, or output from a probe you actually ran. Reasoning from code shape about what a library "probably" does is where these claims go wrong, and the user can neither confirm nor refute it. The same goes for choosing between options on cost or speed: measure both (`EXPLAIN` against the real engine, a timing run) rather than estimating.
- **Someone Else's PR Is Read-Only**: When reviewing a PR another person authored, report findings; don't edit, commit, or push to its branch unless the user explicitly asks.
- **Prove Removal Is Safe**: Before removing or tightening something live callers or data depend on (an endpoint, a validation rule, a field), name the read-only check that shows it is safe (a per-environment count query, an access-log filter) and put it in the ticket.
- **Start What Verification Needs**: When a check depends on a local service that isn't running (a database, search engine, queue container), start it and run the check. "Couldn't test, the service isn't up" is not a finished verification.
- **Separate Pre-Existing From Introduced**: When you surface a defect while reviewing or building, say whether the change in flight introduced it or it was already there. A pre-existing issue belongs in its own follow-up change — don't fold drive-by fixes into the current branch. Park what gets deferred where the next attempt will look — a GitHub issue for repo work, a wiki note for findings — not in chat. Renaming an existing identifier, reformatting lines you didn't change (a formatter or package manager re-indenting or re-sorting a whole file), or dropping an existing comment outside the change's purpose is a drive-by too; leave them as they were. Keep each change small enough that a reviewer can take it in without a big context switch, and split larger work into sequenced changes rather than one wide one. When those sequenced changes become dependent PRs, invoke the `gh-stack` skill and stack them with `gh stack` — never chain PR bases by hand.
- **Write Plainly**: Everything a human reads — chat replies, commit messages, PR bodies, code comments, decision notes, docs, review replies — reads like a senior engineer writing to a colleague: short declarative sentences, ordinary words, active voice, a concrete number where an adjective would go. The test is whether you could say the sentence out loud to a colleague without rephrasing it first. When editing or auditing a draft for AI-register patterns, use the `humanizer` skill — it carries the catalog.
- **GitHub Links On Their Own Bullet**: In any GitHub comment, reply, issue, or PR body, put each issue or PR link on its own `- ` bullet line so GitHub expands its title. Never inline it in a sentence.
- **Ask For A Reference You Can't See**: When the output is supposed to match an artifact you weren't handed or can't open — a design file, a spec, a ticket behind auth, a tool you lack access to — say so and ask for it before building. Guessing at it burns a whole pass and the result reads as if you'd followed something you never saw; the fix is a link or a screenshot, not more inference.
- **Code Wins Over Stale Docs**: When a repo's documentation (CLAUDE.md, AGENTS.md, READMEs, skills) and its existing code disagree, follow the conventions in the existing code, and list every mismatch you found in your final reply. Agents tend to obey a stale instruction even after noticing it's stale, and rewrite working code to match it.

## CLI Tool Calling
Prefer fast, purpose-built tools; fall back to a legacy default only when the modern tool genuinely can't do the job.
- Search file contents → `rg` (not `grep`)
- Find files by name → `fd` (not `find`)
- Find or rewrite code by shape (every call to a method, every class extending a base) → `ast-grep run -l php -p '$OBJ->middleware($$$)' app`. `$NAME` matches one node, `$$$` any number. Reach for it when `rg` on the name also returns comments, strings, and unrelated methods.
- Find code by what it does, when you have no name to search for → `ccc search --lang php "<what the code does>"`, only in a repo that has a `.cocoindex_code/` directory. Pass `--lang`: unfiltered results are mostly JSON and text files. Add `--refresh` after large changes. Hits are leads; confirm them with `rg` before relying on one.
- Search the Obsidian vault's notes and specs → `qmd query "<question>" -c obsidian`. qmd indexes Markdown notes, not code; the `custom-obsidian-wiki-query` skill covers query craft.
- Simple find-and-replace in files → `sd` (not `sed`)
- Query/edit JSON → `jq`; YAML → `yq`
- Fetch URLs, call HTTP APIs, extract from pages → `ax` (not `curl` + throwaway parsing scripts); run `ax agent-context` for usage
- Sentry issue or event → the Sentry MCP (`get_sentry_resource` with the issue URL)
- Browser checks and screenshots → `ego-browser` skill (ego lite, built for agents), not the built-in browser pane. Repo scripts that call a browser tool on purpose stay as written.
- Diff → `delta`; benchmark a command → `hyperfine`; quick command examples → `tldr`
- `fd`/`rg` honor gitignore: `~/.claude` symlinks into the dotfiles repo whose .gitignore covers `/.claude/**`, so searches there silently return nothing — add `--no-ignore` (fd) / `-u` (rg). Diagnose empty results as ignore rules before blaming the filesystem.
- Shell scripts you author here run under macOS zsh with BSD userland, not bash/Linux. Use `[[ … ]]` for tests — the `[ … ] && A || B` idiom also fires the `||` branch when `A` fails. Anchor `grep` patterns so partial matches don't pass, avoid `!` inside double quotes (zsh history expansion), and prefer BSD-compatible flags or invoke GNU tools explicitly.
