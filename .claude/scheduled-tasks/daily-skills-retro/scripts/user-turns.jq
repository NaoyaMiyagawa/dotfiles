select(.type=="user")
| (input_filename | split("/") | .[-1] | .[0:8]) as $f
| .message.content
| if type=="string" then [.] elif type=="array" then map(select(.type=="text").text) else [] end
| map(select(test("^\\s*<(system-reminder|command-|local-command|task-notification|ci-monitor|scheduled-task)") | not))
| map(select(test("Base directory for this skill") | not))
| join("\n")
| select(. != "")
| "### [\($f)] " + .
