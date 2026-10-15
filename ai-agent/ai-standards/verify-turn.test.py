"""Exercise verify-turn.py against temporary repositories and a temporary HOME."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parent / "verify-turn.py"
PASSING = "node -e \"\""
FAILING = "node -e \"console.error('LINT_FAIL_MARKER'); process.exit(1)\""


@unittest.skipUnless(shutil.which("npm") and shutil.which("node"), "npm and node are required")
class VerifyTurnTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="verify-turn-")
        self.home = Path(self.temporary.name)
        self.repo = self.home / "workspace" / "example"
        self.repo.mkdir(parents=True)
        self.git("init", "-q")
        (self.repo / "node_modules").mkdir()
        (self.repo / ".gitignore").write_text("node_modules/\n")
        self.scripts({"lint": PASSING})
        (self.repo / "index.ts").write_text("export const value = 1;\n")
        self.git("add", ".")
        self.git("-c", "user.name=t", "-c", "user.email=t@example.com", "commit", "-qm", "init")

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args):
        subprocess.run(["git", "-C", str(self.repo), *args], check=True, capture_output=True)

    def scripts(self, scripts):
        (self.repo / "package.json").write_text(json.dumps({"name": "example", "scripts": scripts}))

    def hook(self, host, event, payload):
        result = subprocess.run(
            ["python3", "-B", str(SCRIPT), host, event],
            input=json.dumps(payload),
            text=True,
            capture_output=True,
            env={**os.environ, "HOME": str(self.home)},
            cwd=self.home,
            check=True,
        )
        return result.stdout.strip()

    def turn(self, edit, host="claude", **stop_fields):
        payload = {"session_id": "s1", "cwd": str(self.repo)}
        self.assertEqual(self.hook(host, "start", payload), "{}" if host == "cursor" else "")
        edit()
        return self.hook(host, "stop", {**payload, **stop_fields})

    def write(self, name, text="export const changed = 2;\n"):
        return lambda: (self.repo / name).write_text(text)

    def test_unchanged_turn_runs_nothing(self):
        self.scripts({"lint": FAILING})
        self.assertEqual(self.turn(lambda: None), "")

    def test_preexisting_dirty_file_is_not_attributed_to_turn(self):
        self.scripts({"lint": FAILING})
        (self.repo / "index.ts").write_text("export const dirty = 3;\n")
        self.assertEqual(self.turn(lambda: None), "")

    def test_failing_check_blocks_with_output(self):
        self.scripts({"lint": FAILING})
        output = json.loads(self.turn(self.write("index.ts")))
        self.assertEqual(output["decision"], "block")
        self.assertIn("LINT_FAIL_MARKER", output["reason"])
        self.assertIn("pre-existing", output["reason"])

    def test_continued_stop_does_not_block_again(self):
        self.scripts({"lint": FAILING})
        self.assertEqual(self.turn(self.write("index.ts"), stop_hook_active=True), "")

    def test_writing_script_is_never_run(self):
        marker = self.repo / "fix-ran"
        self.scripts({"lint": f"node -e \"require('fs').writeFileSync('{marker}', '')\" --fix"})
        self.turn(self.write("index.ts"))
        self.assertFalse(marker.exists())

    def test_lint_check_is_preferred_over_fixing_lint(self):
        self.scripts({"lint": "eslint . --fix", "lint:check": FAILING})
        self.assertIn("LINT_FAIL_MARKER", json.loads(self.turn(self.write("index.ts")))["reason"])

    def test_documentation_only_turn_runs_nothing(self):
        self.scripts({"lint": FAILING})
        self.assertEqual(self.turn(self.write("README.md", "notes\n")), "")

    def test_untrusted_root_is_skipped(self):
        outside = self.home / "elsewhere"
        shutil.move(str(self.repo), outside)
        self.repo = outside
        self.scripts({"lint": FAILING})
        self.assertEqual(self.turn(self.write("index.ts")), "")

    def test_multi_file_change_requests_review_once(self):
        def edit():
            for name in ("a.ts", "b.ts", "c.ts"):
                self.write(name)()
        output = json.loads(self.turn(edit))
        self.assertEqual(output["decision"], "block")
        self.assertIn("independent review", output["reason"])
        self.assertIn("npm run lint", output["reason"])

    def test_cursor_uses_followup_message_and_loop_count(self):
        self.scripts({"lint": FAILING})
        payload = {"conversation_id": "c1", "workspace_roots": [str(self.repo)], "status": "completed"}
        self.assertEqual(self.hook("cursor", "start", payload), "{}")
        self.write("index.ts")()
        repeat = self.hook("cursor", "stop", {**payload, "loop_count": 1})
        self.assertEqual(json.loads(repeat), {})
        self.write("index.ts", "export const again = 4;\n")()
        first = json.loads(self.hook("cursor", "stop", {**payload, "loop_count": 0}))
        self.assertIn("LINT_FAIL_MARKER", first["followup_message"])

    def test_invalid_payload_fails_open(self):
        result = subprocess.run(
            ["python3", "-B", str(SCRIPT), "claude", "stop"],
            input="{", text=True, capture_output=True,
            env={**os.environ, "HOME": str(self.home)}, check=True,
        )
        self.assertEqual(result.stdout.strip(), "")


if __name__ == "__main__":
    unittest.main()
