#!/usr/bin/env python3
"""Validate the four authored DMCS scenario catalogs (Python stdlib only).

This checks data shape, counts and references. It cannot verify the realism
of a fictional story, map compatibility or in-game SQF behaviour.
"""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "scenarios"
SIDES = ("WEST", "EAST", "GUER", "CIV")
PREFIX = {"WEST": "W", "EAST": "E", "GUER": "G", "CIV": "C"}
REQUIRED = (
    "id", "side", "category", "title", "location", "premise",
    "complication", "objective", "story", "suggested_mechanic",
    "implementation", "estimated_minutes", "players_recommended"
)
ALLOWED = (
    "recon", "secure", "destroy", "rescue", "supply",
    "civ_visit", "civ_courier", "civ_medical"
)


def main() -> int:
    errors = []
    global_ids = set()
    total = 0
    for side in SIDES:
        path = ROOT / (side + ".json")
        if not path.is_file():
            errors.append(f"Missing {path}")
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeError, json.JSONDecodeError) as exc:
            errors.append(f"Invalid JSON in {path.name}: {exc}")
            continue
        entries = data.get("scenarios")
        if not isinstance(entries, list):
            errors.append(f"{side}: scenarios must be an array")
            continue
        if data.get("side") != side or data.get("count") != 200:
            errors.append(f"{side}: top-level metadata must identify 200 entries")
        if len(entries) != 200:
            errors.append(f"{side}: expected 200, got {len(entries)}")
        titles = []
        categories = Counter()
        for n, entry in enumerate(entries, 1):
            if not isinstance(entry, dict):
                errors.append(f"{side}:{n}: entry must be an object")
                continue
            identifier = f"{PREFIX[side]}-{n:03d}"
            if entry.get("id") != identifier:
                errors.append(f"{side}:{n}: ID must equal {identifier}")
            if identifier in global_ids:
                errors.append(f"Global ID duplicate: {identifier}")
            global_ids.add(identifier)
            for key in REQUIRED:
                val = entry.get(key)
                if val is None or val == "":
                    errors.append(f"{identifier}: empty {key}")
            if entry.get("side") != side:
                errors.append(f"{identifier}: wrong side")
            if entry.get("implementation") != "CONCEPT_ONLY":
                errors.append(f"{identifier}: cannot claim an implemented mission")
            if entry.get("suggested_mechanic") not in ALLOWED:
                errors.append(f"{identifier}: unknown mechanic")
            if not (entry.get("lead") or entry.get("characters")):
                errors.append(f"{identifier}: character attribution missing")
            if len(str(entry.get("story", ""))) < 120:
                errors.append(f"{identifier}: briefing is too short")
            if not isinstance(entry.get("estimated_minutes"), int):
                errors.append(f"{identifier}: duration must be an integer")
            titles.append(entry.get("title"))
            categories[entry.get("category")] += 1
        if len(set(titles)) != len(titles):
            errors.append(f"{side}: duplicate titles")
        if len(categories) != 10 or any(c != 20 for c in categories.values()):
            errors.append(f"{side}: expected 10 categories of 20")
        total += len(entries)
        print(f"{side}: {len(entries)} scenarios / {len(categories)} categories")
    if total != 800:
        errors.append(f"Expected 800 scenarios, counted {total}")
    for message in errors[:50]:
        print("FAIL:", message, file=sys.stderr)
    if len(errors) > 50:
        print(f"...and {len(errors) - 50} further errors", file=sys.stderr)
    if errors:
        return 1
    print("PASS: 800 unique IDs, 4 sides, 40 categories, required fields")
    print("NOTE: static data check only; missions are not automatically playable")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
