# Dotfiles Repo Rules

- **Dotfiles Are Public**: `~/dotfiles` is a public GitHub repo, and `~/.claude` symlinks into it. Never put an employer, org, work project or repo name, a teammate's name or login, a work email, or internal infrastructure detail in a tracked file here. Write a placeholder (`<org>`, `<me>`) in the tracked file and keep the real value in a gitignored sibling the tracked file tells the agent to read, such as `local.md` beside a `SKILL.md`. Before committing, search the staged diff for those names.
- **Searching gitignored paths**: `fd`/`rg` honor `.gitignore`, which covers `/.claude/**` here — searches under `.claude` silently return nothing unless you pass `--no-ignore` (`fd`) or `-u` (`rg`).
