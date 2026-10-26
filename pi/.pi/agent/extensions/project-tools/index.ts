import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { delimiter, dirname, join } from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { projectTools } from "./detect.js";

export default async function (pi: ExtensionAPI) {
  const root = dirname(fileURLToPath(import.meta.url));
  const require = createRequire(import.meta.url);
  const tools = projectTools(process.cwd());

  if (tools.lens) {
    process.env.PI_LENS_DISABLE_TOOL_INSTALL ??= "1";
    process.env.PI_LENS_DISABLE_LSP_INSTALL ??= "1";
    const { default: lens } = await import("pi-lens");
    lens(pi);
    pi.on("resources_discover", () => ({
      skillPaths: [join(root, "node_modules/pi-lens/skills")],
    }));
  }

  if (tools.playwright) {
    const browser = (process.env.PATH ?? "").split(delimiter)
      .map((dir) => join(dir, "chromium")).find((path) => existsSync(path));
    if (!browser) throw new Error("Chromium is missing from PATH; run dots.");
    pi.registerMcpServer("playwright", {
      command: process.execPath,
      args: [
        join(dirname(require.resolve("@playwright/mcp/package.json")), "cli.js"),
        "--headless", "--isolated", "--executable-path", browser,
        "--output-dir", join(existsSync("/history") ? "/history/pi" : join(homedir(), ".local/state/pi"), "playwright"),
        // Chromium cannot use its sandbox when the container runs as root.
        ...(process.getuid?.() === 0 ? ["--no-sandbox"] : []),
      ],
      cwd: process.cwd(),
      exposure: "codemode",
    });
  }
}
