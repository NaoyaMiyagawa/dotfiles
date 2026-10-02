# Condense one transcript into a timeline of user turns, tool calls, and tool errors,
# for spotting where an agent spent calls searching before it acted.
# Usage: jq -r -f timeline.jq /abs/path/<session>.jsonl
# e.g. (out) "  T Bash: fd -u -i brewfile ." / "U: Commit and push" / "  ERR: Exit code 1 …"
def trunc(n): if length > n then .[0:n] + "…" else . end;
def toolarg:
  if .name == "Bash" then (.input.command // "")
  elif .name == "Read" then (.input.file_path // "") + (if .input.offset then " @" + (.input.offset|tostring) else "" end)
  elif (.name == "Grep" or .name == "Glob") then (.input.pattern // "") + " " + (.input.path // "")
  elif (.name == "Edit" or .name == "Write") then (.input.file_path // "")
  elif .name == "Skill" then (.input.skill // "")
  elif .name == "Agent" then (.input.subagent_type // "") + ": " + (.input.description // "")
  else (.input | tostring) end;
select(.type == "user" or .type == "assistant")
| select(.isSidechain != true)
| if .type == "user" then
    (.message.content
     | if type == "string" then
         (gsub("(?s)<system-reminder>.*?</system-reminder>"; "") | gsub("(?s)<command-[a-z]+>.*?</command-[a-z]+>"; "")
          | select(test("\\S")) | "U: " + (gsub("\\s+"; " ") | trunc(300)))
       else
         (.[] | select(.type == "tool_result" and .is_error == true)
          | "  ERR: " + ((.content | if type == "array" then map(.text? // "") | join(" ") else tostring end) | gsub("\\s+"; " ") | trunc(200)))
       end)
  else
    (.message.content[]? | select(.type == "tool_use")
     | "  T " + .name + ": " + (toolarg | gsub("\\s+"; " ") | trunc(220)))
  end
