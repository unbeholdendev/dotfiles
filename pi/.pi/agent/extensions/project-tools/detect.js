import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join, matchesGlob, relative, resolve } from "node:path";
import { load } from "js-yaml";

export function projectTools(cwd) {
  let root = resolve(cwd);
  for (let dir = root; ; dir = dirname(dir)) {
    if (existsSync(join(dir, ".git"))) {
      root = dir;
      break;
    }
    if (dirname(dir) === dir) break;
  }

  const manifest = (dir) => {
    try {
      return JSON.parse(readFileSync(join(dir, "package.json"), "utf8"));
    } catch {
      return {};
    }
  };
  const pkg = manifest(root);
  let patterns = pkg.workspaces?.packages ?? pkg.workspaces ?? [];
  if (existsSync(join(root, "pnpm-workspace.yaml"))) {
    patterns = load(readFileSync(join(root, "pnpm-workspace.yaml"), "utf8"))?.packages ?? patterns;
  }
  if (!Array.isArray(patterns) || patterns.some((p) => typeof p !== "string")) {
    throw new Error("Invalid workspace package patterns");
  }

  const tools = { lens: false, playwright: false };
  const pending = [root];
  let visited = 0;
  while (pending.length && visited++ < 2000) {
    const dir = pending.pop();
    const path = relative(root, dir).split("\\").join("/");
    const workspace = dir === root || (
      patterns.some((p) => !p.startsWith("!") && matchesGlob(path, p)) &&
      !patterns.some((p) => p.startsWith("!") && matchesGlob(path, p.slice(1)))
    );
    const entries = readdirSync(dir, { withFileTypes: true });
    if (workspace) {
      const p = dir === root ? pkg : manifest(dir);
      const deps = Object.assign({}, p.dependencies, p.devDependencies, p.peerDependencies, p.optionalDependencies);
      tools.lens ||= Object.hasOwn(deps, "typescript") || entries.some((e) => e.isFile() && /^tsconfig(?:\..+)?\.json$/.test(e.name));
      tools.playwright ||= Object.hasOwn(deps, "@playwright/test") || Object.hasOwn(deps, "playwright");
    }
    if (tools.lens && tools.playwright) break;
    if (!patterns.length) continue;
    for (const entry of entries) {
      if (entry.isDirectory() && !entry.name.startsWith(".") &&
          !["node_modules", "dist", "build", "coverage", "vendor"].includes(entry.name)) {
        pending.push(join(dir, entry.name));
      }
    }
  }
  return tools;
}
