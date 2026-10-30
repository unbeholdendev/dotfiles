import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


REPO = Path(__file__).resolve().parent


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.log = self.home / "build.json"
        env_file = self.home / "env.sh"
        env_file.write_text('''nix() {
  python3 -c 'import json, os; from pathlib import Path; Path(os.environ["BUILD_LOG"]).write_text(json.dumps({"agents": os.environ.get("CONTAINER_AGENTS"), "argv": __import__("sys").argv[1:]}))' "$@"
  return 89
}
''')
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "BASH_ENV": str(env_file),
            "BUILD_LOG": str(self.log),
        }
        self.env.pop("CONTAINER_AGENTS", None)

    def run_install(self, *args):
        return subprocess.run(
            ["bash", str(REPO / "install.sh"), *args], env=self.env,
            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=10,
        )

    def assert_selection(self, args, expected):
        result = self.run_install(*args)
        self.assertEqual(result.returncode, 89, result.stderr)
        self.assertEqual((self.home / ".coding-agent").read_text(), expected + "\n")
        build = json.loads(self.log.read_text())
        self.assertEqual(build["agents"], expected)
        self.assertIn("--impure", build["argv"])
        self.assertIn(str(REPO) + "#homeConfigurations.container.activationPackage", build["argv"])

    def test_multiple_agents_are_saved_and_passed_to_build(self):
        self.assert_selection(["container", "claude", "pi", "codex"], "claude pi codex")
        self.assert_selection(["container"], "claude pi codex")

    def test_legacy_single_selection_is_preserved(self):
        (self.home / ".coding-agent").write_text("pi\n")
        self.assert_selection(["container"], "pi")

    def test_explicit_selection_replaces_saved_agents(self):
        (self.home / ".coding-agent").write_text("pi\n")
        self.assert_selection(["container", "codex", "claude"], "codex claude")

    def test_noninteractive_default_is_claude(self):
        self.assert_selection(["container"], "claude")

    def test_unknown_agent_does_not_change_selection_or_build(self):
        saved = self.home / ".coding-agent"
        saved.write_text("pi\n")
        result = self.run_install("container", "codex", "unknown")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unknown coding agent: unknown", result.stderr)
        self.assertEqual(saved.read_text(), "pi\n")
        self.assertFalse(self.log.exists())

    def test_codex_defaults_to_full_permissions_and_forgejo_mcp(self):
        config = tomllib.loads((REPO / "codex/.codex/config.toml").read_text())
        self.assertEqual(config["approval_policy"], "never")
        self.assertEqual(config["sandbox_mode"], "danger-full-access")
        forgejo = config["mcp_servers"]["forgejo"]
        self.assertEqual(forgejo["command"], "sh")
        self.assertIn("FORGEJO_ACCESS_TOKEN=", forgejo["args"][1])
        self.assertIn("forgejo-mcp --transport stdio --url https://git.home.unbeholden.dev", forgejo["args"][1])


if __name__ == "__main__":
    unittest.main()
