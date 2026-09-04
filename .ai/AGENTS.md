# Global Agent Rules

## Planning

Prefer plan mode for multi-step or architectural work — including verification
passes, not just building. If the approach stops working, stop and re-plan
rather than pushing through.

## Core Principles

- **Prove It Before Guarding**: Don't add a guard, fallback, or refetch for a state you haven't shown is reachable — an optional constructor arg the caller never omits, a null check on a non-nullable value, a re-read of data nothing else mutates, a `catch` on a path that can't throw. Trace the concrete sequence that produces the bad state first; if you can't, leave the code bare. Unreachable defensive code is dead weight that misdirects the next reader about where the real risk is.
- **Verify Before Removing**: Before deleting or replacing code, search the codebase for remaining callers, routes, or references. Never infer something is dead from local context alone — a component can look unused where you're editing yet still power an active flow elsewhere.
- **Comments Stand Alone**: A code comment must make sense to a future reader with no access to this chat. Don't leave notes that only parse with the conversation's context ("as discussed", "the value we picked above"); state the durable why, or drop the comment.
- **Make Claims Checkable**: When you report a defect, root cause, or review finding that turns on third-party or runtime behaviour, hand over the evidence with it — the file and line in the dependency's own source, or output from a probe you actually ran. Reasoning from code shape about what a library "probably" does is where these claims go wrong, and the user can neither confirm nor refute it.
- **Separate Pre-Existing From Introduced**: When you surface a defect while reviewing or building, say whether the change in flight introduced it or it was already there. A pre-existing issue belongs in its own follow-up change — don't fold drive-by fixes into the current branch. Keep each change small enough that a reviewer can take it in without a big context switch, and split larger work into sequenced changes rather than one wide one. When those sequenced changes become dependent PRs, invoke the `gh-stack` skill and stack them with `gh stack` — never chain PR bases by hand.
- **Write Plainly**: Everything a human reads — chat replies, commit messages, PR bodies, code comments, decision notes, docs, review replies — reads like a senior engineer writing to a colleague: short declarative sentences, ordinary words, active voice, a concrete number where an adjective would go. Drop the AI register: inflated adjectives, rule-of-three flourishes, "it's not just X, it's Y", throat-clearing openers ("here's the thing"), faux-insight setups ("what most people miss"), and a closing line that restates what was just said. The test is whether you could say the sentence out loud to a colleague without rephrasing it first. The user shouldn't have to rewrite your prose to sound like themselves. When editing or auditing a draft for these patterns, use the `no-ai-slop` skill — it carries the full catalog, so don't restate it here.
- **Ask For A Reference You Can't See**: When the output is supposed to match an artifact you weren't handed or can't open — a design file, a spec, a ticket behind auth, a tool you lack access to — say so and ask for it before building. Guessing at it burns a whole pass and the result reads as if you'd followed something you never saw; the fix is a link or a screenshot, not more inference.
- **Name Reflects Behavior, Not Assumption**: When a method or variable's real behavior doesn't match what its name implies — a qualifier it doesn't actually check, a filter it silently applies that the name doesn't mention, a descriptor that overstates precision (`getLatestX` with no such ordering) — rename it to match the real behavior instead of leaving the mismatch for the next reader to trip over.

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
