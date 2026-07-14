import { readFile, readdir } from "node:fs/promises";
import { join } from "node:path";

const folders = ["data", "schemas"];
let checked = 0;
let failed = false;

for (const folder of folders) {
  const files = await readdir(folder).catch(() => []);
  for (const file of files.filter((name) => name.endsWith(".json"))) {
    const filePath = join(folder, file);
    checked += 1;
    try {
      JSON.parse(await readFile(filePath, "utf8"));
      console.log(`OK ${filePath}`);
    } catch (error) {
      failed = true;
      console.error(`INVALID ${filePath}: ${error.message}`);
    }
  }
}

if (checked === 0) {
  console.error("No JSON files were found in data/ or schemas/.");
  process.exit(1);
}

if (failed) process.exit(1);
console.log(`Validated ${checked} JSON file(s).`);
