# Global Agent Rules (Lean)

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `.ai/tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Plan First**: Write plan to `.ai/tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `.ai/tasks/todo.md`

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
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

@docs/RTK.md
