from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODS = ROOT / "config" / "mods.csv"

with MODS.open(encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle))

assert len(rows) == 25, len(rows)
assert sum(row["type"] == "workshop" for row in rows) == 23
assert sum(row["type"] == "local" for row in rows) == 2
assert len({row["target"] for row in rows}) == len(rows)
assert len({row["workshop_id"] for row in rows if row["workshop_id"]}) == 23
assert all(row["target"].startswith("@") for row in rows)
assert all(row["target"] == row["target"].lower() for row in rows)
assert all(row["enabled"] in {"0", "1"} for row in rows)

print("test_config: OK")
