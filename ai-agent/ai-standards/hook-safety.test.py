"""Exercise hook decisions with inert payloads; never execute their commands."""

import json
import subprocess
import tempfile
import unittest
from pathlib import Path


HOOKS = Path(__file__).resolve().parents[1] / ".cursor" / "hooks"


class HookSafetyTests(unittest.TestCase):
    def decision(self, hook, payload):
        result = subprocess.run(
            [str(HOOKS / hook)], input=json.dumps(payload), text=True,
            capture_output=True, check=True,
        )
        return json.loads(result.stdout)["permission"]

    def test_invalid_payloads_fail_closed(self):
        for hook in ("gate-shell.sh", "gate-mcp.sh", "gate-read.sh"):
            for payload in (None, [], {}, {"command": 1, "tool_name": 1, "path": 1}):
                with self.subTest(hook=hook, payload=payload):
                    self.assertEqual(self.decision(hook, payload), "deny")

    def test_shell_decisions(self):
        cases = {
            "git status --short": "allow",
            "git -C '/tmp/example directory' diff": "allow",
            "touch local.txt": "allow",
            "git commit -m example": "ask",
            "git -C /tmp/example commit -m example": "ask",
            "git -c user.name=Example -C '/tmp/example directory' push origin topic": "ask",
            "git --git-dir=/tmp/example/.git reset --hard": "deny",
            "git -C /tmp/example push --force origin main": "deny",
            "gh pr create --title example --body example": "ask",
            "gh pr view 1": "allow",
            "bkt --repo example pr comment 1 --text example": "ask",
            "bkt pr diff 1": "allow",
            "terraform -chdir=/tmp/example apply": "ask",
            "terraform -chdir='/tmp/example directory' plan": "ask",
            "terraform fmt -check": "allow",
            "rm -rf /": "deny",
        }
        for command, expected in cases.items():
            with self.subTest(command=command):
                self.assertEqual(self.decision("gate-shell.sh", {"command": command}), expected)

    def test_mcp_decisions(self):
        cases = [
            ({"tool_name": "list_issues"}, "allow"),
            ({"tool_name": "mcp__github__get_pull_request"}, "allow"),
            ({"tool_name": "get_input_schema"}, "allow"),
            ({"tool_name": "read_output"}, "allow"),
            ({"tool_name": "get_and_delete"}, "ask"),
            ({"tool_name": "getAndDelete"}, "ask"),
            ({"tool_name": "update_issue"}, "ask"),
            ({"toolName": "query", "serverName": "database", "arguments": {"query": "DELETE FROM example"}}, "ask"),
            ({"tool_name": "query", "arguments": {"query": "SELECT 1"}}, "ask"),
            ({"tool_name": "find", "serverName": "mongodb"}, "ask"),
            ({"tool_name": "custom_action"}, "ask"),
            ({"serverName": "github"}, "deny"),
        ]
        for payload, expected in cases:
            with self.subTest(payload=payload):
                self.assertEqual(self.decision("gate-mcp.sh", payload), expected)

    def test_read_paths(self):
        cases = {
            "src/app.py": "allow", ".env.example": "allow",
            ".env": "deny", ".env.production": "deny",
            ".aws/credentials": "deny", ".ssh/config": "deny",
            "secrets/.env.example": "deny", "secrets/token.txt": "deny",
            "folder/../.aws/credentials": "deny",
            "C:\\Users\\example\\.aws\\credentials": "deny",
        }
        for path, expected in cases.items():
            with self.subTest(path=path):
                self.assertEqual(self.decision("gate-read.sh", {"file_path": path}), expected)
        with tempfile.TemporaryDirectory(prefix="read-hook-check-") as directory:
            root = Path(directory)
            (root / "alias.txt").symlink_to(root / ".env")
            self.assertEqual(self.decision("gate-read.sh", {
                "path": "alias.txt", "cwd": directory,
            }), "deny")


if __name__ == "__main__":
    unittest.main()
