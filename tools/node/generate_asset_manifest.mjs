import { mkdir, readdir, writeFile } from "node:fs/promises";
import { dirname, extname, join, relative } from "node:path";

const roots = ["assets", "art"];
const output = "production/generated/ASSET_MANIFEST.json";
const allowed = new Set([".png", ".jpg", ".jpeg", ".webp", ".svg", ".aseprite", ".kra", ".ogg", ".wav", ".mp3", ".ttf", ".otf"]);
const assets = [];

async function walk(dir) {
  const items = await readdir(dir, { withFileTypes: true }).catch(() => []);
  for (const item of items) {
    const path = join(dir, item.name);
    if (item.isDirectory()) await walk(path);
    else if (allowed.has(extname(item.name).toLowerCase())) assets.push(relative(".", path).replaceAll("\\", "/"));
  }
}

for (const root of roots) await walk(root);
assets.sort();

await mkdir(dirname(output), { recursive: true });
await writeFile(
  output,
  `${JSON.stringify({ schema_version: 1, generated_at: new Date().toISOString(), count: assets.length, assets }, null, 2)}\n`,
);
console.log(`Asset manifest generated with ${assets.length} asset(s): ${output}`);
