import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { projectTools } from "./detect.js";

function project(t, files) {
  const root = mkdtempSync(join(tmpdir(), "pi-tools-test-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  mkdirSync(join(root, ".git"));
  for (const [name, contents] of Object.entries(files)) {
    const path = join(root, name);
    mkdirSync(join(path, ".."), { recursive: true });
    writeFileSync(path, typeof contents === "string" ? contents : JSON.stringify(contents));
  }
  return root;
}

test("empty and malformed manifests leave tools off", (t) => {
  assert.deepEqual(projectTools(project(t, {})), { lens: false, playwright: false });
  assert.deepEqual(projectTools(project(t, { "package.json": "{" })), { lens: false, playwright: false });
});

test("TypeScript config and direct dependencies select the matching tools", (t) => {
  assert.deepEqual(projectTools(project(t, { "tsconfig.build.json": "{}" })), { lens: true, playwright: false });
  for (const group of ["dependencies", "devDependencies", "peerDependencies", "optionalDependencies"]) {
    const root = project(t, { "package.json": { [group]: { typescript: "*", "@playwright/test": "*" } } });
    assert.deepEqual(projectTools(root), { lens: true, playwright: true });
  }
  assert.deepEqual(projectTools(project(t, {
    "package.json": { dependencies: { playwright: "*" } },
  })), { lens: false, playwright: true });
});

test("npm workspaces are detected from a subdirectory without inspecting fixtures", (t) => {
  const root = project(t, {
    "package.json": { workspaces: ["packages/*", "!packages/ignored"] },
    "packages/app/package.json": { devDependencies: { typescript: "*" } },
    "packages/ignored/package.json": { devDependencies: { playwright: "*" } },
    "tests/fixture/package.json": { dependencies: { playwright: "*" } },
    "node_modules/example/package.json": { dependencies: { playwright: "*" } },
  });
  assert.deepEqual(projectTools(join(root, "packages/app")), { lens: true, playwright: false });
});

test("workspace objects and pnpm YAML support nested packages", (t) => {
  for (const files of [
    { "package.json": { workspaces: { packages: ["packages/**"] } } },
    { "pnpm-workspace.yaml": "packages:\n  - 'packages/**'\n" },
  ]) {
    const root = project(t, {
      ...files,
      "packages/frontend/app/package.json": { devDependencies: { playwright: "*" } },
      "packages/frontend/app/tsconfig.json": "{}",
    });
    assert.deepEqual(projectTools(root), { lens: true, playwright: true });
  }
});

test("scans ignore symlinked directories outside the repository", (t) => {
  const outside = project(t, { "tsconfig.json": "{}" });
  const root = project(t, { "package.json": { workspaces: ["packages/*"] } });
  mkdirSync(join(root, "packages"));
  symlinkSync(outside, join(root, "packages/external"));
  assert.deepEqual(projectTools(root), { lens: false, playwright: false });
});
