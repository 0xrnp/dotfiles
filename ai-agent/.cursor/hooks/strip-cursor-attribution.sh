#!/usr/bin/env bash
set -euo pipefail

jq -c '
  .tool_input as $tool_input
  | if (($tool_input.command? | type) == "string") then
      ($tool_input.command
        | gsub("Co-authored-by: Cursor <cursoragent@cursor\\.com>"; "")) as $command
      | if $command != $tool_input.command then
          {
            permission: "allow",
            updated_input: ($tool_input + {command: $command})
          }
        else
          {permission: "allow"}
        end
    else
      {permission: "allow"}
    end
'
