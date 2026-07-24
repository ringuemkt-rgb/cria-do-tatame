import { readFile, readdir } from "node:fs/promises";
import { join, relative } from "node:path";

const folders = ["data", "schemas"];
let checked = 0;
let failed = false;

const walkJson = async (folder) => {
  const entries = await readdir(folder, { withFileTypes: true }).catch(() => []);
  const nested = await Promise.all(
    entries.map(async (entry) => {
      const path = join(folder, entry.name);
      if (entry.isDirectory()) return walkJson(path);
      return entry.isFile() && entry.name.endsWith(".json") ? [path] : [];
    }),
  );
  return nested.flat();
};

for (const folder of folders) {
  const files = (await walkJson(folder)).sort();
  for (const filePath of files) {
    checked += 1;
    try {
      JSON.parse(await readFile(filePath, "utf8"));
      console.log(`OK ${relative(".", filePath)}`);
    } catch (error) {
      failed = true;
      console.error(`INVALID ${relative(".", filePath)}: ${error.message}`);
    }
  }
}

if (checked === 0) {
  console.error("No JSON files were found in data/ or schemas/.");
  process.exit(1);
}

if (failed) process.exit(1);
console.log(`Validated ${checked} JSON file(s).`);
