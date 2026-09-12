#!/usr/bin/env python3
"""Derive CRIA Production OS v03 requirements from repository data.

Fail-closed principles:
- missing sources become source_blockers; they never become zero-content success;
- the noncanonical Ruan x Davi KG fixture can drive P1 only;
- derivation never approves, integrates or ships an asset;
- output is deterministic for a fixed repository tree.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = ROOT / "data/visual/production_manifest_v03.json"
DEFAULT_OUT = ROOT / "production/generated/production_manifest_v03.materialized.json"


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def canonical_json(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def semantic_key(category: str, source_id: str, kind: str) -> str:
    return f"{category}:{source_id}:{kind}".lower()


def safe_id(value: str) -> str:
    return str(value).strip().lower().replace(" ", "_").replace("/", "_")


class Derivator:
    def __init__(self, root: Path, contract: dict[str, Any]) -> None:
        self.root = root
        self.contract = contract
        self.requirements: dict[str, dict[str, Any]] = {}
        self.blockers: list[dict[str, Any]] = []
        self.sources: dict[str, Any] = {}
        self.source_snapshot: dict[str, Any] = {}

    def source_path(self, name: str) -> Path:
        return self.root / self.contract["sources"][name]["path"]

    def load_source(self, name: str, *, blocker_if_missing: bool = False) -> Any | None:
        path = self.source_path(name)
        if path.exists():
            data = load_json(path)
            self.sources[name] = data
            return data
        if blocker_if_missing:
            self.add_blocker(
                code=f"missing_source:{name}",
                path=str(path.relative_to(self.root)),
                impact="FULL_SHIPPING_BLOCKED",
            )
        return None

    def add_blocker(self, code: str, path: str, impact: str, detail: str = "") -> None:
        item = {"code": code, "path": path, "impact": impact}
        if detail:
            item["detail"] = detail
        if item not in self.blockers:
            self.blockers.append(item)

    def add_requirement(
        self,
        *,
        category: str,
        source_id: str,
        kind: str,
        priority: int,
        source_refs: list[str],
        expected_product_prefix: str,
        scope: str = "FULL_GAME",
        blockers: list[str] | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        sem = semantic_key(category, source_id, kind)
        req = {
            "requirement_id": sem,
            "category": category,
            "source_id": source_id,
            "kind": kind,
            "scope": scope,
            "priority": priority,
            "status": "pending",
            "shipping": False,
            "source_refs": sorted(set(source_refs)),
            "expected_product_prefix": expected_product_prefix.rstrip("/") + "/",
            "blockers": sorted(set(blockers or [])),
        }
        if metadata:
            req["metadata"] = metadata
        current = self.requirements.get(sem)
        if current is None or priority < current["priority"]:
            self.requirements[sem] = req
        elif current is not None:
            current["source_refs"] = sorted(set(current["source_refs"] + req["source_refs"]))
            current["blockers"] = sorted(set(current["blockers"] + req["blockers"]))

    def derive_p1(self) -> None:
        queue = self.load_source("p1_queue", blocker_if_missing=True)
        if not queue:
            return
        commands = [cmd for batch in queue.get("batches", []) for cmd in batch.get("commands", [])]
        self.source_snapshot["p1_commands"] = len(commands)
        policy = self.contract["policies"]["p1_isolation"]
        excluded = set(policy["excluded_fixture_techniques"])
        allowed_fighters = set(policy["fighters"])
        for cmd in commands:
            source_id = str(cmd.get("source_id", "")).strip()
            if source_id in excluded:
                raise SystemExit(f"P1 isolation violation: excluded technique {source_id} entered queue")
            for key in ("attacker_id", "defender_id"):
                fighter = cmd.get(key)
                if fighter and fighter not in allowed_fighters:
                    raise SystemExit(f"P1 isolation violation: {fighter} is outside Ruan x Davi")
            kind = str(cmd.get("kind", "UNKNOWN")).lower()
            category = "p1_" + str(cmd.get("kind", "asset")).split("_")[0].lower()
            self.add_requirement(
                category=category,
                source_id=source_id or cmd["id"],
                kind=kind,
                priority=1,
                source_refs=list(cmd.get("auth", [])) + [self.contract["sources"]["p1_queue"]["path"]],
                expected_product_prefix=cmd["out"],
                scope="P1_GOLD_SLICE",
                metadata={"command_id": cmd["id"], "qa": cmd.get("qa", [])},
            )

    def derive_characters(self) -> None:
        roster = self.load_source("roster", blocker_if_missing=True)
        if not roster:
            return
        fighters = roster.get("fighters", [])
        self.source_snapshot["roster_fighters"] = len(fighters)
        kinds = self.contract["derivation"]["characters"]["requirements"]
        for fighter in fighters:
            fid = fighter["id"]
            identity_path = self.root / f"data/chars/canon/{fid}.json"
            local_blockers = [] if identity_path.exists() else ["identity_master_missing"]
            refs = [self.contract["sources"]["roster"]["path"]]
            if identity_path.exists():
                refs.append(str(identity_path.relative_to(self.root)))
            for kind in kinds:
                self.add_requirement(
                    category="character",
                    source_id=fid,
                    kind=kind,
                    priority=2,
                    source_refs=refs,
                    expected_product_prefix=f"assets/production/chars/{fid}/{kind}",
                    blockers=local_blockers,
                    metadata={"role": fighter.get("role"), "display_name": fighter.get("display_name")},
                )

    def select_techniques(self) -> tuple[list[dict[str, Any]], str, bool]:
        full = self.load_source("full_bjj_kg")
        required = self.contract["policies"]["full_graph_claim_requires"]
        if full:
            positions = full.get("positions", full.get("posicoes", []))
            techniques = full.get("techniques", full.get("tecnicas", []))
            chains = full.get("chains", [])
            complete = len(positions) >= required["positions"] and len(techniques) >= required["techniques"] and len(chains) >= required["chains"]
            if complete:
                self.source_snapshot["bjj_graph"] = {"mode": "full", "positions": len(positions), "techniques": len(techniques), "chains": len(chains)}
                return techniques, self.contract["sources"]["full_bjj_kg"]["path"], True
            self.add_blocker("full_bjj_kg_incomplete", self.contract["sources"]["full_bjj_kg"]["path"], "FULL_BJJ_SCALE_BLOCKED")
        else:
            self.add_blocker("full_bjj_kg_missing", self.contract["sources"]["full_bjj_kg"]["path"], "FULL_BJJ_SCALE_BLOCKED")
        slice_kg = self.load_source("slice_kg", blocker_if_missing=True) or {}
        techniques = [t for t in slice_kg.get("techniques", []) if t.get("id") not in set(self.contract["policies"]["p1_isolation"]["excluded_fixture_techniques"])]
        self.source_snapshot["bjj_graph"] = {"mode": "slice_fixture", "positions": len(slice_kg.get("positions", [])), "techniques": len(techniques), "chains": len(slice_kg.get("chains", []))}
        return techniques, self.contract["sources"]["slice_kg"]["path"], False

    def derive_techniques(self) -> None:
        techniques, source_ref, full = self.select_techniques()
        for tech in techniques:
            tid = tech["id"]
            for kind in self.contract["derivation"]["techniques"]["requirements"]:
                self.add_requirement(
                    category="technique",
                    source_id=tid,
                    kind=kind,
                    priority=2,
                    source_refs=[source_ref],
                    expected_product_prefix=f"assets/production/techniques/{tid}/{kind}",
                    scope="FULL_GAME" if full else "P1_FIXTURE_ONLY",
                    blockers=[] if full else ["full_graph_not_available_for_scale"],
                    metadata={"from": tech.get("from", tech.get("de")), "to": tech.get("to", tech.get("para")), "type": tech.get("type", tech.get("tipo"))},
                )

    def derive_cards(self) -> None:
        cards = self.load_source("cards")
        if not cards:
            self.add_blocker("cards_source_missing", self.contract["sources"]["cards"]["path"], "CARD_ART_SCALE_BLOCKED")
            return
        rows = cards.get("techniques", cards.get("tecnicas", cards.get("cards", [])))
        self.source_snapshot["cards"] = len(rows)
        for card in rows:
            cid = card.get("id")
            if cid:
                self.add_requirement(category="card", source_id=cid, kind="card_art", priority=3, source_refs=[self.contract["sources"]["cards"]["path"]], expected_product_prefix=f"assets/production/cards/{cid}")

    def derive_arenas(self) -> None:
        data = self.load_source("arena_info", blocker_if_missing=True)
        if not data:
            return
        arenas = data.get("arenas", [])
        self.source_snapshot["world_locations"] = len(arenas)
        kinds = self.contract["derivation"]["arenas"]["requirements"]
        fight_types = set(self.contract["derivation"]["arenas"]["fight_ui_types"])
        for arena in arenas:
            aid = arena["id"]
            refs = [self.contract["sources"]["arena_info"]["path"]]
            for kind in kinds:
                self.add_requirement(category="arena", source_id=aid, kind=kind, priority=2, source_refs=refs, expected_product_prefix=f"assets/production/arenas/{aid}/{kind}", metadata={"type": arena.get("tipo"), "municipality": arena.get("mun")})
            if arena.get("tipo") in fight_types:
                self.add_requirement(category="arena", source_id=aid, kind="fight_ui", priority=2, source_refs=refs, expected_product_prefix=f"assets/production/arenas/{aid}/fight_ui", metadata={"type": arena.get("tipo")})

    def derive_narrative(self) -> None:
        acts = self.load_source("narrative_acts", blocker_if_missing=True)
        if not acts:
            return
        count = 0
        for act in acts.get("acts", []):
            for beat in act.get("required_beats", []):
                bid = f"{act['id']}__{beat['id']}"
                self.add_requirement(category="story", source_id=bid, kind="story_scene", priority=3, source_refs=[self.contract["sources"]["narrative_acts"]["path"]], expected_product_prefix=f"assets/production/story/{safe_id(bid)}", metadata={"act": act["id"], "location": beat.get("location")})
                count += 1
        for scene in acts.get("adult_scenes", []):
            sid = scene["id"]
            self.add_requirement(category="story", source_id=sid, kind="story_scene", priority=3, source_refs=[self.contract["sources"]["narrative_acts"]["path"]], expected_product_prefix=f"assets/production/story/{safe_id(sid)}", metadata={"act": scene.get("act")})
            count += 1
        self.source_snapshot["story_scenes_from_acts"] = count
        missions = self.load_source("missions")
        if not missions:
            self.add_blocker("missions_source_missing", self.contract["sources"]["missions"]["path"], "MISSION_SCENE_SCALE_BLOCKED")
        else:
            self.source_snapshot["missions"] = len(missions.get("missions", []))

    def derive_icons(self) -> None:
        icons = self.load_source("icons", blocker_if_missing=True)
        if not icons:
            return
        count = 0
        for group_name in ("arena_icons", "ui_icons"):
            for subgroup, names in icons.get(group_name, {}).items():
                for name in names:
                    iid = f"{group_name}:{subgroup}:{name}"
                    self.add_requirement(category="icon", source_id=iid, kind="icon", priority=3, source_refs=[self.contract["sources"]["icons"]["path"]], expected_product_prefix=f"assets/production/icons/{group_name}/{safe_id(name)}")
                    count += 1
        self.source_snapshot["icons"] = count

    def derive_legacy_packages(self) -> None:
        legacy = self.load_source("legacy_visual", blocker_if_missing=True)
        if not legacy:
            return
        for screen in legacy.get("ui_screens", []):
            self.add_requirement(category="ui", source_id=screen, kind="ui_screen", priority=2, source_refs=[self.contract["sources"]["legacy_visual"]["path"]], expected_product_prefix=f"assets/production/ui/{screen}")
        for package in legacy.get("audio_packages", []):
            self.add_requirement(category="audio", source_id=package, kind="audio_package", priority=3, source_refs=[self.contract["sources"]["legacy_visual"]["path"]], expected_product_prefix=f"assets/production/audio/{package}")
        self.source_snapshot["ui_screens"] = len(legacy.get("ui_screens", []))
        self.source_snapshot["audio_packages"] = len(legacy.get("audio_packages", []))

    def run(self) -> dict[str, Any]:
        self.derive_p1()
        self.derive_characters()
        self.derive_techniques()
        self.derive_cards()
        self.derive_arenas()
        self.derive_narrative()
        self.derive_icons()
        self.derive_legacy_packages()
        reqs = sorted(self.requirements.values(), key=lambda x: (x["priority"], x["category"], x["source_id"], x["kind"]))
        counts: dict[str, int] = {}
        for req in reqs:
            counts[req["category"]] = counts.get(req["category"], 0) + 1
        output = {
            "$schema": "cria.production_manifest.materialized.v03",
            "version": self.contract["version"],
            "status": "DERIVED_NOT_APPROVED",
            "shipping": False,
            "contract": str(CONTRACT_PATH.relative_to(self.root)),
            "source_snapshot": self.source_snapshot,
            "source_blockers": sorted(self.blockers, key=lambda x: (x["code"], x["path"])),
            "counts": {"total": len(reqs), "by_category": dict(sorted(counts.items()))},
            "requirements": reqs,
        }
        digest_input = dict(output)
        digest_input.pop("derivation_sha256", None)
        output["derivation_sha256"] = hashlib.sha256(canonical_json(digest_input).encode("utf-8")).hexdigest()
        return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default=str(DEFAULT_OUT))
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args()
    contract = load_json(CONTRACT_PATH)
    result = Derivator(ROOT, contract).run()
    text = json.dumps(result, ensure_ascii=False, indent=2, sort_keys=False) + "\n"
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")
    if args.stdout:
        print(text, end="")
    else:
        print(f"PRODUCTION_OS_V03 requirements={result['counts']['total']} blockers={len(result['source_blockers'])} sha256={result['derivation_sha256']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
