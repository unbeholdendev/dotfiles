import json
import os
from pathlib import Path
import pty
import shlex
import socket
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
    "folder": os.environ.get("T3_FOLDER"),
}}
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps(call) + "\\n")
if command == "docker" and os.environ.get("EXISTING_CONTAINER"):
    print("container-id")
"""
        for command in ("devcontainer", "docker", "socat"):
            path = stub_bin / command
            path.write_text(stub)
            path.chmod(0o755)
        setsid = stub_bin / "setsid"
        setsid.write_text('#!/bin/sh\nshift\nexec "$@"\n')
        setsid.chmod(0o755)
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
        self.assertEqual(len(devcontainer), 3)
        self.assertEqual(devcontainer[1], [
            "exec", "--workspace-folder", str(self.workspace),
            "/dotfiles/install.sh", "container",
        ])
        self.assertEqual(devcontainer[2][:3], [
            "exec", "--workspace-folder", str(self.workspace),
        ])
        self.assertIn("t3 serve", devcontainer[2][-1])
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
        self.assertEqual(
            {call["command"] for call in calls}, {"devcontainer", "socat"},
        )
        self.assert_install(calls)

    def forward_port(self, calls):
        forward = next(call for call in calls if call["command"] == "socat")
        self.assertEqual(forward["folder"], str(self.workspace))
        return forward["argv"][0].split(":")[1].split(",")[0]

    def test_dcup_keeps_a_workspace_on_one_port(self):
        first, output = self.run_launcher("dcup", self.workspace)
        self.log.unlink()
        second, _ = self.run_launcher("dcup", self.workspace)
        self.assertEqual(self.forward_port(first), "37731")
        self.assertEqual(self.forward_port(second), "37731")
        self.assertIn(":37731", output)

    def test_dcup_gives_each_workspace_its_own_port(self):
        self.run_launcher("dcup", self.workspace)
        self.log.unlink()
        self.workspace = self.workspace.parent / "another"
        self.workspace.mkdir()
        calls, _ = self.run_launcher("dcup", self.workspace)
        self.assertEqual(self.forward_port(calls), "37732")

    def test_dcup_skips_a_port_something_else_holds(self):
        with socket.socket() as held:
            held.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            held.bind(("127.0.0.1", 37731))
            held.listen()
            calls, _ = self.run_launcher("dcup", self.workspace)
        self.assertEqual(self.forward_port(calls), "37732")

    def test_dcup_concurrent_workspaces_get_different_ports(self):
        workspaces = [self.workspace.parent / f"w{i}" for i in range(8)]
        processes = []
        for workspace in workspaces:
            workspace.mkdir()
            processes.append(subprocess.Popen(
                [str(BIN / "dcup"), str(workspace)], stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=self.env,
            ))
        for process in processes:
            self.assertEqual(process.wait(timeout=10), 0)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        ports = [
            call["argv"][0].split(":")[1].split(",")[0]
            for call in calls if call["command"] == "socat"
        ]
        self.assertEqual(len(ports), len(workspaces))
        self.assertEqual(len(set(ports)), len(workspaces))

    def test_dcup_concurrent_runs_of_a_workspace_claim_one_port(self):
        processes = [
            subprocess.Popen(
                [str(BIN / "dcup"), str(self.workspace)], stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, env=self.env,
            )
            for _ in range(8)
        ]
        for process in processes:
            self.assertEqual(process.wait(timeout=10), 0)
        claims = list((self.home / ".devcontainer-state/t3-ports").glob("[0-9]*"))
        self.assertEqual([claim.name for claim in claims], ["37731"])

    def test_dcup_prints_a_pair_command_that_survives_spaces(self):
        _, output = self.run_launcher("dcup", self.workspace)
        command = next(
            line.split("pair with: ")[1] for line in output.splitlines()
            if "pair with: " in line
        )
        self.assertEqual(shlex.split(command)[:3], [
            "devcontainer", "exec", "--workspace-folder",
        ])
        self.assertEqual(shlex.split(command)[3], str(self.workspace))

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
            "folder": None,
        }])

    def test_dccodex_defaults_to_current_folder(self):
        calls, _ = self.run_launcher("dccodex")
        self.assertEqual(calls[0]["argv"], [
            "exec", "--workspace-folder", ".", "zsh", "-c", 'exec codex "$@"', "codex",
        ])
        self.assertEqual(calls[0]["agent"], "codex")


if __name__ == "__main__":
    unittest.main()
