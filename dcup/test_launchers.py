import json
import os
from pathlib import Path
import pty
import subprocess
import sys
import tempfile
import unittest


BIN = Path(__file__).resolve().parent / ".local/bin"


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.home = root / "home"
        self.home.mkdir()
        self.workspace = root / "workspace with spaces"
        self.workspace.mkdir()
        self.dotfiles = root / "dotfiles"
        self.dotfiles.mkdir()
        stub_bin = root / "bin"
        stub_bin.mkdir()
        self.log = root / "calls.jsonl"
        stub = f"""#!{sys.executable}
import json
import os
from pathlib import Path
import sys

command = Path(sys.argv[0]).name
call = {{
    "command": command,
    "argv": sys.argv[1:],
    "agent": os.environ.get("HERDR_AGENT"),
}}
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps(call) + "\\n")
if command == "docker" and os.environ.get("EXISTING_CONTAINER"):
    print("container-id")
"""
        for command in ("devcontainer", "docker"):
            path = stub_bin / command
            path.write_text(stub)
            path.chmod(0o755)
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "DOTFILES": str(self.dotfiles),
            "PATH": f"{stub_bin}:{os.environ['PATH']}",
            "CALL_LOG": str(self.log),
        }
        self.env.pop("EXISTING_CONTAINER", None)
        self.env.pop("HERDR_AGENT", None)

    def run_launcher(self, name, *args, answers=None):
        command = [str(BIN / name), *map(str, args)]
        if answers is None:
            result = subprocess.run(
                command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, env=self.env, timeout=10,
            )
            output = result.stdout
            returncode = result.returncode
        else:
            master, slave = pty.openpty()
            try:
                process = subprocess.Popen(
                    command, stdin=slave, stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT, env=self.env,
                )
                os.close(slave)
                slave = None
                try:
                    os.write(master, answers.encode())
                    output, _ = process.communicate(timeout=10)
                finally:
                    if process.poll() is None:
                        process.kill()
                        process.communicate()
                returncode = process.returncode
            finally:
                os.close(master)
                if slave is not None:
                    os.close(slave)
        self.assertEqual(returncode, 0, output.decode())
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return calls, output.decode()

    def assert_install(self, calls):
        devcontainer = [call["argv"] for call in calls if call["command"] == "devcontainer"]
        self.assertEqual(len(devcontainer), 2)
        self.assertEqual(devcontainer[1], [
            "exec", "--workspace-folder", str(self.workspace),
            "/dotfiles/install.sh", "container",
        ])
        mounts = [arg for arg in devcontainer[0] if arg.startswith("type=volume,")]
        self.assertEqual(mounts, [
            "type=volume,source=nix-store,target=/nix",
            "type=volume,source=claude-state,target=/claude",
            "type=volume,source=codex-state,target=/codex",
        ])

    def test_dcup_new_container_asks_only_for_token(self):
        calls, output = self.run_launcher(
            "dcup", self.workspace, "--log-level", "debug", answers="1\n",
        )
        self.assertNotIn("coding agent", output)
        self.assertIn("which token", output)
        self.assert_install(calls)
        self.assertEqual(calls[0]["argv"], [
            "ps", "-aq", "--filter",
            f"label=devcontainer.local_folder={self.workspace}",
        ])
        self.assertEqual(calls[1]["argv"][-2:], ["--log-level", "debug"])

    def test_dcup_existing_container_does_not_ask(self):
        self.env["EXISTING_CONTAINER"] = "1"
        calls, output = self.run_launcher("dcup", self.workspace, answers="")
        self.assertNotIn("which token", output)
        self.assert_install(calls)

    def test_dcup_without_terminal_does_not_ask(self):
        calls, _ = self.run_launcher("dcup", self.workspace)
        self.assertTrue(all(call["command"] == "devcontainer" for call in calls))
        self.assert_install(calls)

    def test_dccodex_preserves_arguments_and_labels_agent(self):
        calls, _ = self.run_launcher(
            "dccodex", self.workspace, "--model", "model name", "a prompt with spaces",
        )
        self.assertEqual(calls, [{
            "command": "devcontainer",
            "argv": [
                "exec", "--workspace-folder", str(self.workspace),
                "zsh", "-c", 'exec codex "$@"', "codex",
                "--model", "model name", "a prompt with spaces",
            ],
            "agent": "codex",
        }])

    def test_dccodex_defaults_to_current_folder(self):
        calls, _ = self.run_launcher("dccodex")
        self.assertEqual(calls[0]["argv"], [
            "exec", "--workspace-folder", ".", "zsh", "-c", 'exec codex "$@"', "codex",
        ])
        self.assertEqual(calls[0]["agent"], "codex")


if __name__ == "__main__":
    unittest.main()
