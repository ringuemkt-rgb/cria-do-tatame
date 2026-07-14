import { readFile } from "node:fs/promises";

const readJson = async (path) => JSON.parse(await readFile(path, "utf8"));
const errors = [];
const fail = (message) => errors.push(message);
const duplicateIds = (items) => {
  const seen = new Set();
  return items.map((item) => item?.id).filter((id) => id && (seen.has(id) || !seen.add(id)));
};

const [{ characters = [] }, { techniques = [] }, { missions = [] }, { arenas = [] }] = await Promise.all([
  readJson("data/characters.json"),
  readJson("data/techniques.json"),
  readJson("data/missions.json"),
  readJson("data/arenas.json"),
]);

for (const [kind, items] of Object.entries({ characters, techniques, missions, arenas })) {
  for (const id of duplicateIds(items)) fail(`${kind}: duplicate id ${id}`);
}

const characterIds = new Set(characters.map(({ id }) => id));
const arenaIds = new Set(arenas.map(({ id }) => id));
const missionIds = new Set(missions.map(({ id }) => id));

for (const character of characters) {
  if (!character.id || !character.name || !character.role) fail("character without id, name or role");
  if (character.stats) {
    for (const [stat, value] of Object.entries(character.stats)) {
      if (typeof value !== "number" || value < 0 || value > 100) {
        fail(`character ${character.id}: invalid stat ${stat}=${value}`);
      }
    }
  }
}

for (const technique of techniques) {
  if (!technique.id || !(technique.name || technique.nome)) fail("technique without id or name");
  if (!(technique.entry_state || technique.estado_entrada)) fail(`technique ${technique.id}: missing entry state`);
  if (!(technique.exit_state || technique.estado_saida)) fail(`technique ${technique.id}: missing exit state`);
  const chance = technique.base_chance ?? technique.chance_sucesso;
  if (typeof chance !== "number" || chance < 0 || chance > 1) fail(`technique ${technique.id}: invalid success chance`);
  if ((technique.gas_cost ?? technique.cost?.gas ?? technique.custo?.gas ?? 0) < 0) fail(`technique ${technique.id}: negative gas cost`);
}

for (const mission of missions) {
  if (!mission.id || !mission.title || !mission.type) fail("mission without id, title or type");
  if (mission.opponent_id && !characterIds.has(mission.opponent_id)) {
    fail(`mission ${mission.id}: missing opponent ${mission.opponent_id}`);
  }
  if (mission.arena_id && !arenaIds.has(mission.arena_id)) {
    fail(`mission ${mission.id}: missing arena ${mission.arena_id}`);
  }
  for (const requirement of mission.requirements ?? []) {
    if (!missionIds.has(requirement)) fail(`mission ${mission.id}: missing requirement ${requirement}`);
  }
  for (const nextMission of mission.next ?? []) {
    if (!missionIds.has(nextMission)) fail(`mission ${mission.id}: missing next mission ${nextMission}`);
  }
}

for (const arena of arenas) {
  if (!arena.id || !arena.name || !arena.type) fail("arena without id, name or type");
}

if (errors.length) {
  for (const error of errors) console.error(`DATA ERROR: ${error}`);
  process.exit(1);
}

console.log(`Game data validated: ${characters.length} characters, ${techniques.length} techniques, ${missions.length} missions and ${arenas.length} arenas.`);
