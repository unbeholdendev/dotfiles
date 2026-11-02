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
    "folder": os.environ.get("T3_FOLDER"),
}}
if command == "docker" and sys.argv[1] == "exec":
    call["stdin"] = sys.stdin.read()
with open(os.environ["CALL_LOG"], "a") as log:
    log.write(json.dumps(call) + "\\n")
if command == "docker" and os.environ.get("EXISTING_CONTAINER"):
    print("container-id")
if command == "devcontainer" and "pairing create" in " ".join(sys.argv):
    print(json.dumps({{"pairUrl": sys.argv[-1] + "/pair#token=SECRET"}}))
if command == "hostname":
    print("192.0.2.7 10.0.0.1 ")
if command == "jq":
    print(json.load(sys.stdin)["pairUrl"])
if command == "qrencode":
    print("QR:" + sys.stdin.read())
"""
        for command in ("devcontainer", "docker", "socat", "hostname", "jq", "qrencode"):
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
        self.assertIn("t3 start", devcontainer[2][-1])
        mounts = [arg for arg in devcontainer[0] if arg.startswith("type=volume,")]
        self.assertEqual(mounts, [
            "type=volume,source=nix-store,target=/nix",
            "type=volume,source=claude-state,target=/claude",
            "type=volume,source=codex-state,target=/codex",
        ])

    def test_dcup_new_container_asks_only_for_token(self):
        calls, output = self.run_launcher(
            "dcup", self.workspace, "--log-level", "debug", answers="1\nn\n",
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
        calls, output = self.run_launcher("dcup", self.workspace, answers="n\n")
        self.assertNotIn("which token", output)
        self.assert_install(calls)

    def test_dcup_without_terminal_does_not_ask(self):
        calls, _ = self.run_launcher("dcup", self.workspace)
        self.assertEqual(
            {call["command"] for call in calls}, {"devcontainer", "docker", "hostname", "socat"},
        )
        self.assert_install(calls)

    def test_dcup_writes_an_excluded_default_config_when_the_repo_has_none(self):
        subprocess.run(["git", "init", "-q", self.workspace], check=True)
        self.run_launcher("dcup", self.workspace)
        self.run_launcher("dcup", self.workspace)
        config = json.loads((self.workspace / ".devcontainer.json").read_text())
        self.assertEqual(config["remoteUser"], "root")
        status = subprocess.run(
            ["git", "-C", self.workspace, "status", "--porcelain"],
            check=True, capture_output=True, text=True,
        )
        self.assertEqual(status.stdout, "")
        exclude = self.workspace / ".git/info/exclude"
        self.assertEqual(exclude.read_text().splitlines().count(".devcontainer.json"), 1)

    def test_dcup_writes_a_default_config_outside_a_repo(self):
        self.run_launcher("dcup", self.workspace)
        self.assertTrue((self.workspace / ".devcontainer.json").exists())

    def test_dcup_leaves_an_existing_config_alone(self):
        for existing in (".devcontainer.json", ".devcontainer/devcontainer.json", ".devcontainer/a/devcontainer.json"):
            with self.subTest(existing):
                workspace = self.workspace.parent / existing.replace("/", "-")
                path = workspace / existing
                path.parent.mkdir(parents=True)
                path.write_text("{}")
                self.run_launcher("dcup", workspace)
                self.assertEqual(path.read_text(), "{}")
                if existing != ".devcontainer.json":
                    self.assertFalse((workspace / ".devcontainer.json").exists())

    def dotfiles_mount(self, *remotes):
        subprocess.run(["git", "init", "-q", self.workspace], check=True)
        for index, url in enumerate(remotes):
            subprocess.run(
                ["git", "-C", self.workspace, "remote", "add", f"r{index}", url], check=True,
            )
        subprocess.run(["git", "init", "-q", self.dotfiles], check=True)
        subprocess.run(
            ["git", "-C", self.dotfiles, "-c", "user.name=t", "-c", "user.email=t@example.com",
             "commit", "-q", "--allow-empty", "-m", "seed"],
            check=True,
        )
        tokens = self.home / ".github-tokens"
        tokens.mkdir()
        (tokens / "me").write_text("token")
        calls, _ = self.run_launcher("dcup", self.workspace)
        up = next(call["argv"] for call in calls if call["argv"][0] == "up")
        self.up_args = up
        return next(arg for arg in up if arg.endswith("target=/dotfiles"))

    def assert_own(self, *remotes):
        self.assertEqual(
            self.dotfiles_mount(*remotes), f"type=bind,source={self.dotfiles},target=/dotfiles",
        )

    def test_dcup_mounts_the_clone_for_a_repo_without_remotes(self):
        self.assert_own()

    def test_dcup_mounts_the_clone_for_an_owned_github_repo(self):
        self.assert_own("git@github.com:me/project.git")

    def test_dcup_mounts_the_clone_for_a_forgejo_repo(self):
        self.assert_own("https://git.home.unbeholden.dev/someone/project.git")

    def test_dcup_mounts_a_separate_clone_for_a_foreign_repo(self):
        for remotes in (
            ["https://github.com/stranger/project.git"],
            ["https://github.com/me/project.git", "https://github.com/stranger/project.git"],
            ["https://example.com/git.home.unbeholden.dev/project.git"],
        ):
            with self.subTest(remotes):
                self.setUp()
                mount = self.dotfiles_mount(*remotes)
                source = Path(mount.split(",")[1].removeprefix("source="))
                history = next(
                    arg for arg in self.up_args if arg.endswith("target=/history")
                ).split(",")[1].removeprefix("source=")
                self.assertFalse(source.is_relative_to(history))
                self.assertNotEqual(source, self.dotfiles)
                self.assertTrue((source / ".git").is_dir())
                objects = list((source / ".git/objects").rglob("*"))
                host = list((self.dotfiles / ".git/objects").rglob("*"))
                shared = {p.stat().st_ino for p in objects if p.is_file()} & {
                    p.stat().st_ino for p in host if p.is_file()
                }
                self.assertEqual(shared, set())

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

    def test_dcup_prints_the_host_address_and_a_pair_command(self):
        _, output = self.run_launcher("dcup", self.workspace)
        line = next(line for line in output.splitlines() if line.startswith("t3: "))
        self.assertIn("http://192.0.2.7:37731", line)
        self.assertEqual(
            shlex.split(line.split("pair with: ")[1]), ["dcpair", str(self.workspace)],
        )

    def test_dcpair_links_to_the_forward_and_keeps_the_token_out_of_argv(self):
        self.run_launcher("dcup", self.workspace)
        calls, output = self.run_launcher("dcpair", self.workspace)
        url = "http://192.0.2.7:37731/pair#token=SECRET"
        self.assertIn(url, output)
        self.assertIn("QR:" + url, output)
        qrencode = next(call for call in calls if call["command"] == "qrencode")
        self.assertNotIn("SECRET", " ".join(qrencode["argv"]))

    def test_dcpair_without_a_claimed_port_says_to_run_dcup(self):
        result = subprocess.run(
            [str(BIN / "dcpair"), str(self.workspace)], stdin=subprocess.DEVNULL,
            capture_output=True, text=True, env=self.env, timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("dcup", result.stderr)

    def test_dcup_labels_the_server_with_the_folder_name_before_starting_it(self):
        self.env["EXISTING_CONTAINER"] = "1"
        calls, _ = self.run_launcher("dcup", self.workspace)
        label = next(
            index for index, call in enumerate(calls)
            if call["command"] == "docker" and call["argv"][0] == "exec"
        )
        self.assertEqual(
            calls[label]["stdin"], "PRETTY_HOSTNAME=workspace with spaces\n",
        )
        self.assertEqual(calls[label]["argv"][:5], ["exec", "-i", "-u", "root", "container-id"])
        server = next(
            index for index, call in enumerate(calls)
            if call["command"] == "devcontainer" and "t3 start" in " ".join(call["argv"])
        )
        self.assertLess(label, server)

    def test_dcup_starts_t3_with_the_command_that_adds_the_workspace_project(self):
        calls, _ = self.run_launcher("dcup", self.workspace)
        commands = " ".join(
            " ".join(call["argv"]) for call in calls if call["command"] == "devcontainer"
        )
        self.assertIn("t3 start --no-browser", commands)
        self.assertNotIn("t3 serve", commands)

    def dcup_exec_calls(self, answers):
        self.log.unlink(missing_ok=True)
        calls, _ = self.run_launcher("dcup", self.workspace, answers=answers)
        return [call["argv"] for call in calls if call["command"] == "devcontainer"][1:3]

    def test_dcup_enables_the_browser_only_when_asked_and_remembers(self):
        self.env["EXISTING_CONTAINER"] = "1"
        for argv in self.dcup_exec_calls("y\n"):
            self.assertEqual(argv[3:5], ["--remote-env", "T3_BROWSER=1"])
        for argv in self.dcup_exec_calls(""):
            self.assertEqual(argv[3:5], ["--remote-env", "T3_BROWSER=1"])

    def test_dcup_leaves_the_browser_off_when_declined_and_remembers(self):
        self.env["EXISTING_CONTAINER"] = "1"
        for answers in ("n\n", ""):
            for argv in self.dcup_exec_calls(answers):
                self.assertNotIn("--remote-env", argv)

    def test_dcup_does_not_ask_about_the_browser_without_a_terminal(self):
        calls, output = self.run_launcher("dcup", self.workspace)
        self.assertNotIn("T3 browser", output)
        self.assertFalse(any("--remote-env" in call["argv"] for call in calls))

    def test_dcup_disables_the_browser_sandbox_only_when_enabled_and_root(self):
        calls, _ = self.run_launcher("dcup", self.workspace)
        script = next(
            call["argv"][-1] for call in calls
            if call["command"] == "devcontainer" and "t3 start" in " ".join(call["argv"])
        )
        self.assertIn(
            "[[ -n $T3_BROWSER ]] && export T3CODE_SERVER_BROWSER_SANDBOX=$((EUID != 0))",
            script,
        )

    def test_dccodex_preserves_arguments(self):
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
            "folder": None,
        }])

    def test_dccodex_defaults_to_current_folder(self):
        calls, _ = self.run_launcher("dccodex")
        self.assertEqual(calls[0]["argv"], [
            "exec", "--workspace-folder", ".", "zsh", "-c", 'exec codex "$@"', "codex",
        ])


if __name__ == "__main__":
    unittest.main()
