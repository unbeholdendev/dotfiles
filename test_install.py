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
  python3 -c 'import json, os; from pathlib import Path; Path(os.environ["BUILD_LOG"]).write_text(json.dumps({"argv": __import__("sys").argv[1:]}))' "$@"
  return 89
}
''')
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "BASH_ENV": str(env_file),
            "BUILD_LOG": str(self.log),
        }

    def run_install(self, *args):
        return subprocess.run(
            ["bash", str(REPO / "install.sh"), *args], env=self.env,
            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=10,
        )

    def test_container_build_needs_no_agent_selection(self):
        result = self.run_install("container")
        self.assertEqual(result.returncode, 89, result.stderr)
        self.assertFalse((self.home / ".coding-agent").exists())
        build = json.loads(self.log.read_text())
        self.assertIn("--impure", build["argv"])
        self.assertIn(str(REPO) + "#homeConfigurations.container.activationPackage", build["argv"])

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
