#!/usr/bin/env bash
# PreToolUse hook on Bash: nudge Claude away from `grep`/`find` for file searching.
# - Denies standalone `grep PATTERN ...` and `grep -r/-R` (suggests `rg`).
# - Denies `find ... -name/-type/...` (suggests `fd`).
# - Allows piped grep/find (e.g. `ps aux | grep foo`, `cmd | find`) since those
#   are different use cases — filtering existing stdout, not file searching.
# - Ignores heredoc bodies (prose such as a PR body is not a command) and reads
#   `x=$(git grep ...)` as the `git` command it is, not as `grep`.
#
# Composes with rtk-rewrite.sh: each hook gets its own stdin copy, denials win.

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Drop heredoc bodies: everything after a `<<WORD` / `<<-WORD` line up to the
# WORD terminator line. `(^|[^<])` keeps `<<<` here-strings out.
# e.g. (in) "cat > f <<'EOF'\nuse grep here\nEOF\nls" → (out) "cat > f <<'EOF'\nls"
cmd=$(printf '%s\n' "$cmd" | awk '
  skip { t = $0; if (dash) sub(/^\t+/, "", t); if (t == term) skip = 0; next }
  {
    print
    if (match($0, /(^|[^<])<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*/)) {
      h = substr($0, RSTART, RLENGTH)
      sub(/^[^<]?<</, "", h)
      dash = (h ~ /^-/)
      gsub(/^-?[ \t]*["\047]?/, "", h)
      term = h; skip = 1
    }
  }')

# Split the command into pipelines by `;`, `&&`, `||`, and `$(` (a command
# substitution starts a new command).
# For each pipeline, look only at the FIRST segment (before any `|`) —
# that's where a standalone `grep`/`find` invocation lives. Anything after
# `|` is filtering, which is a legitimate use of grep/find.
while IFS= read -r pipeline; do
  first_segment="${pipeline%%|*}"
  # Tokenize (best-effort; quoted args with spaces are imperfect but fine for our purpose).
  # shellcheck disable=SC2206
  tokens=($first_segment)
  # Skip leading `VAR=val` assignments and wrappers like sudo/time/env/nice.
  i=0
  while [ $i -lt ${#tokens[@]} ]; do
    tok="${tokens[$i]}"
    case "$tok" in
      *=*) i=$((i + 1)); continue ;;
      sudo|time|nice|env|command|builtin|exec) i=$((i + 1)); continue ;;
      *) break ;;
    esac
  done
  first_cmd="${tokens[$i]:-}"
  rest="${tokens[*]:$((i + 1))}"

  case "$first_cmd" in
    grep | egrep | fgrep | /usr/bin/grep | /bin/grep)
      deny "Use \`rg\` (ripgrep) instead of \`$first_cmd\` for searching file contents. rg is much faster and respects .gitignore by default. Examples: \`rg pattern\` (recursive from cwd), \`rg pattern path/\`, \`rg -i pattern\` (case-insensitive), \`rg -t py pattern\` (only Python files). NOTE: piped grep like \`cmd | grep foo\` is fine — only standalone grep is blocked by this hook."
      ;;
    find | /usr/bin/find)
      # Only deny if it looks like file searching (has -name, -type, etc.).
      # Bare `find .` or `find --version` slips through; that's fine.
      if echo " $rest " | grep -qE -- ' -(name|iname|type|path|ipath|regex|iregex|maxdepth|mindepth) '; then
        deny "Use \`fd\` instead of \`find\` for locating files. fd is faster, has saner defaults, and respects .gitignore. Examples: \`fd pattern\` (by name), \`fd -e ts\` (by extension), \`fd -t d pattern\` (directories only), \`fd -H pattern\` (include hidden). For complex expressions fd may not cover, you may still use find — just rerun with an explicit comment noting why."
      fi
      ;;
  esac
done < <(printf '%s\n' "$cmd" | sed -E 's/(\&\&|\|\||;|\$\()/\n/g')

exit 0
