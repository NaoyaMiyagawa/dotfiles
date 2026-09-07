#!/bin/zsh
# Extract the last 24h of user feedback from Claude Code transcripts.
# Usage: mine.sh <out-dir> [current-session-id]
# Writes <out-dir>/turns.jsonl (one JSON string per user text turn, prefixed
# "### [<8-char session>] ") and <out-dir>/difit.txt (difit review tool_results).
set -euo pipefail
out=$1; self=${2:-__none__}
here=${0:A:h}
mkdir -p "$out"
fd --no-ignore -e jsonl --changed-within 24h . ~/.claude/projects \
  | grep -v -e "$self" -e /subagents/ > "$out/files.txt"
xargs jq -c -f "$here/user-turns.jq" < "$out/files.txt" > "$out/turns.jsonl"
xargs jq -rc -f "$here/difit-comments.jq" < "$out/files.txt" > "$out/difit.txt"
wc -l "$out/files.txt" "$out/turns.jsonl" "$out/difit.txt"
