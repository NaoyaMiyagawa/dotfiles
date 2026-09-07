select(.type=="user")
| (input_filename | split("/") | .[-1]) as $f
| .message.content
| select(type=="array")
| .[]
| select(.type=="tool_result")
| .content
| if type=="string" then . elif type=="array" then (map(select(.type=="text").text) | join("\n")) else empty end
| select(test("=====\n[^\n]+:L[0-9]+"))
| "### [\($f)]\n" + .
