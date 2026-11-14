#!/usr/bin/env python3
"""Deterministically compile the four 200-entry JSON catalogs for Arma 3.

Arma missions cannot read JSON as missionConfigFile entries by themselves.
The generated .hpp files are included in description.ext. No runtime JSON
parsing and no mod dependency is required.

Usage:
    python3 tools/build_scenario_catalog.py
    python3 tools/build_scenario_catalog.py --check
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INPUT = ROOT / "scenarios"
OUTPUT = ROOT / "dyn" / "scenarios"
SIDES = {"WEST": "west", "EAST": "east", "GUER": "guer", "CIV": "civ"}
PREFIXES = {"WEST": "W", "EAST": "E", "GUER": "G", "CIV": "C"}
PLAYER_RANGE = re.compile(r"(\d+)\D+(\d+)$")


def cfg_string(text: object) -> str:
    """Escape double quotes in a Cfg string and flatten line breaks."""
    value = re.sub(r"\s+", " ", str(text or "")).strip()
    return '"' + value.replace('"', '""') + '"'


def compile_side(side: str, suffix: str) -> str:
    path = INPUT / f"{side}.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    entries = data["scenarios"]
    if len(entries) != 200 or data.get("side") != side:
        raise ValueError(f"{path}: expected 200 entries for {side}")

    lines = [
        f"// GENERATED FROM scenarios/{side}.json - DO NOT EDIT MANUALLY",
        f"// {side}: 200 narrative templates; mechanics are generic prototypes.",
    ]
    for index, entry in enumerate(entries, 1):
        expected_id = f"{PREFIXES[side]}-{index:03d}"
        if entry["id"] != expected_id:
            raise ValueError(f"{path}: entry {index} should be {expected_id}")

        match = PLAYER_RANGE.fullmatch(entry["players_recommended"])
        if match is None:
            raise ValueError(f"{path}: bad player range {expected_id}")
        min_players, max_players = map(int, match.groups())
        duration = int(entry["estimated_minutes"])
        if min_players < 1 or max_players < min_players or duration < 1:
            raise ValueError(f"{path}: invalid range or duration {expected_id}")

        values = {
            "id": entry["id"],
            "side": side,
            "category": entry["category"],
            "title": entry["title"],
            "briefing": entry["story"],
            "objective": entry["objective"],
            "mechanic": entry["suggested_mechanic"],
        }
        fields = " ".join(
            f"{key} = {cfg_string(value)};" for key, value in values.items()
        )
        lines.append(
            f"class S{index:03d} {{ {fields} "
            f"estimatedMinutes = {duration}; "
            f"minPlayers = {min_players}; maxPlayers = {max_players}; }};"
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Compare without writing"
    )
    args = parser.parse_args()
    if not args.check:
        OUTPUT.mkdir(parents=True, exist_ok=True)

    errors = []
    for side, suffix in SIDES.items():
        content = compile_side(side, suffix)
        destination = OUTPUT / f"{suffix}.hpp"
        if args.check:
            if not destination.is_file() or (
                destination.read_text(encoding="utf-8") != content
            ):
                errors.append(f"{destination}: not synchronized with JSON")
        else:
            destination.write_text(content, encoding="utf-8", newline="\n")
            print(f"Wrote {destination.relative_to(ROOT)}")
    if errors:
        for item in errors:
            print("FAIL:", item, file=sys.stderr)
        return 1
    print("PASS: all four 200-entry Arma config catalogs synchronized")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
