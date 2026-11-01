import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest


REPO = Path(__file__).resolve().parent
BROWSER_LIBRARIES = " ".join([
    "libnspr4.so", "libnss3.so", "libnssutil3.so", "libglib-2.0.so.0", "libatk-1.0.so.0",
    "libatk-bridge-2.0.so.0", "libatspi.so.0", "libdbus-1.so.3", "libX11.so.6", "libxcb.so.1",
    "libXcomposite.so.1", "libXdamage.so.1", "libXext.so.6", "libXfixes.so.3", "libXrandr.so.2",
    "libxkbcommon.so.0", "libgbm.so.1", "libasound.so.2", "libexpat.so.1",
])


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
ldconfig() { printf '%s\\n' "$LDCONFIG_OUTPUT"; }
fc-match() { printf '%s' "${FC_MATCH_OUTPUT-/fonts/sans.ttf}"; }
apt-cache() {
  if [[ $2 == "$APT_OFFERS" ]]; then printf '  Installed: (none)\\n  Candidate: 1\\n'
  else printf '  Installed: (none)\\n  Candidate: (none)\\n'; fi
}
sudo() { "$@"; }
apt-get() {
  printf '%s\\n' "$*" >> "$APT_LOG"
  return "${APT_STATUS:-0}"
}
''')
        self.env = {
            **os.environ,
            "HOME": str(self.home),
            "BASH_ENV": str(env_file),
            "BUILD_LOG": str(self.log),
            "APT_LOG": str(self.home / "apt.log"),
            "T3_BROWSER": "1",
            "LDCONFIG_OUTPUT": BROWSER_LIBRARIES,
            "APT_OFFERS": "",
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

    def assert_apt_ran(self, ran):
        result = self.run_install("container")
        self.assertEqual(result.returncode, 89, result.stderr)
        self.assertEqual((self.home / "apt.log").exists(), ran)

    def test_browser_libraries_skip_install_unless_enabled(self):
        del self.env["T3_BROWSER"]
        self.env["LDCONFIG_OUTPUT"] = ""
        self.assert_apt_ran(False)

    def test_browser_libraries_skip_install_when_all_present(self):
        self.assert_apt_ran(False)

    def test_browser_libraries_install_when_any_is_missing(self):
        self.env["LDCONFIG_OUTPUT"] = BROWSER_LIBRARIES.replace("libnss3.so", "")
        self.assert_apt_ran(True)

    def test_browser_fonts_install_when_no_font_is_found(self):
        self.env["FC_MATCH_OUTPUT"] = ""
        self.assert_apt_ran(True)

    def test_browser_libraries_use_t64_names_only_where_apt_offers_them(self):
        self.env |= {"LDCONFIG_OUTPUT": "", "APT_OFFERS": "libasound2t64"}
        self.assert_apt_ran(True)
        packages = (self.home / "apt.log").read_text().split()
        self.assertIn("libasound2t64", packages)
        self.assertIn("libatk1.0-0", packages)
        self.assertNotIn("libasound2", packages)

    def test_browser_library_failure_does_not_stop_install(self):
        self.env |= {"LDCONFIG_OUTPUT": "", "APT_STATUS": "1"}
        result = self.run_install("container")
        self.assertEqual(result.returncode, 89, result.stderr)
        self.assertIn("T3's browser", result.stderr)

    def test_codex_defaults_to_full_permissions(self):
        config = tomllib.loads((REPO / "codex/.codex/config.toml").read_text())
        self.assertEqual(config["approval_policy"], "never")
        self.assertEqual(config["sandbox_mode"], "danger-full-access")

    def hook_returncode(self, command):
        return subprocess.run(
            ["bash", str(REPO / "agents/deny-pr-merge.sh")],
            input=json.dumps({"tool_input": {"command": command}}),
            capture_output=True, text=True, timeout=10,
        ).returncode

    def test_hook_denies_merging_a_pr(self):
        for command in (
            "tea pr merge 5",
            "tea pulls merge --style squash 5",
            "tea pr m 5",
            "cd repo && tea pr merge 5",
            "git push\ntea pr merge 5",
            "tea api -X POST repos/o/r/pulls/5/merge",
            'tea api -X POST "repos/$R/pulls/$n/merge" -d @body',
            "echo 'a; b' && tea pr merge 5",
            'result="$(tea pr merge 5)"',
            "cat <<EOF\ntext\nEOF\ntea pr merge 5",
        ):
            with self.subTest(command):
                self.assertEqual(self.hook_returncode(command), 2)

    def test_hook_allows_other_commands(self):
        for command in (
            "tea pr list --state merged",
            "tea pr view 5",
            'tea pr create --title "pr merge docs"',
            'git commit -m "tea pr merge"',
            'tea comment 5 "tea pr merge fails"',
            "tea api repos/o/r/pulls/5",
            "grep 'tea api' pulls/5/merge",
            "tea comment 5 'Do not run this; tea pr merge 5'",
            'tea comment 5 "see (tea pr merge 5)"',
            "git commit -m 'Example: $(tea pr merge 5)'",
            'tea comment 5 "first\ntea pr merge 5"',
            "tea comment 5 \"don't; tea pr merge 5\"",
            "git commit -F - <<'EOF'\nDon't merge\ntea pr merge 5\nEOF",
            "cat <<EOF | tea comment 5\ntea api -X POST repos/o/r/pulls/5/merge\nEOF",
        ):
            with self.subTest(command):
                self.assertEqual(self.hook_returncode(command), 0)


if __name__ == "__main__":
    unittest.main()
