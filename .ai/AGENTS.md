# Global Agent Rules

## Planning

Prefer plan mode for multi-step or architectural work — including verification
passes, not just building. If the approach stops working, stop and re-plan
rather than pushing through.

## Core Principles

- **Prove It Before Guarding**: Don't add a guard, fallback, or refetch for a state you haven't shown is reachable — an optional constructor arg the caller never omits, a null check on a non-nullable value, a re-read of data nothing else mutates, a `catch` on a path that can't throw. Trace the concrete sequence that produces the bad state first; if you can't, leave the code bare. Unreachable defensive code is dead weight that misdirects the next reader about where the real risk is.
- **Verify Before Removing**: Before deleting or replacing code, search the codebase for remaining callers, routes, or references. Never infer something is dead from local context alone — a component can look unused where you're editing yet still power an active flow elsewhere.
- **Comments Stand Alone**: A code comment must make sense to a future reader with no access to this chat. Don't leave notes that only parse with the conversation's context ("as discussed", "the value we picked above"); state the durable why, or drop the comment.
- **Write Plainly**: Prose the user will publish under their name — decision notes, docs, PR bodies, review replies — must read like a person wrote it: short, direct sentences and ordinary words. Skip AI-flavored register (inflated adjectives, rule-of-three flourishes, "it's not just X, it's Y"). Padded prose makes review harder, and the user shouldn't have to rewrite it to sound like themselves.

## CLI Tool Calling
Prefer fast, purpose-built tools; fall back to a legacy default only when the modern tool genuinely can't do the job.
- Search file contents → `rg` (not `grep`)
- Find files by name → `fd` (not `find`)
- Search/rewrite code by syntax, not text → `ast-grep` / `sg`
- Simple find-and-replace in files → `sd` (not `sed`)
- Query/edit JSON → `jq`; YAML → `yq`
- Fetch URLs, call HTTP APIs, extract from pages → `ax` (not `curl` + throwaway parsing scripts); run `ax agent-context` for usage
- Diff → `delta`; benchmark a command → `hyperfine`; quick command examples → `tldr`
- Prefer structured tools or parsers over ad hoc shell pipelines.
- If you reach for a slow default, pause and check for a faster alternative.
- `fd`/`rg` honor gitignore: `~/.claude` symlinks into the dotfiles repo whose .gitignore covers `/.claude/**`, so searches there silently return nothing — add `--no-ignore` (fd) / `-u` (rg). Diagnose empty results as ignore rules before blaming the filesystem.
- Shell scripts you author here run under macOS zsh with BSD userland, not bash/Linux. Use `[[ … ]]` for tests — the `[ … ] && A || B` idiom also fires the `||` branch when `A` fails. Anchor `grep` patterns so partial matches don't pass, avoid `!` inside double quotes (zsh history expansion), and prefer BSD-compatible flags or invoke GNU tools explicitly.

@docs/RTK.md
