#!/usr/bin/env python3
"""Validate a HEMTT DMCS release archive before offering it to testers.

Checks only package structure and signing files, not Arma execution.
"""
from pathlib import Path
from zipfile import ZipFile, BadZipFile
import sys

ROOT = Path(__file__).resolve().parents[1]
ARCHIVES = sorted((ROOT / "releases").glob("*-latest.zip"))

def main() -> int:
    if not ARCHIVES:
        print("ERROR: no latest ZIP in mod/releases/", file=sys.stderr)
        return 1
    path = ARCHIVES[-1]
    try:
        with ZipFile(path) as archive:
            names = archive.namelist()
            lowered = [name.lower().replace("\\", "/") for name in names]
    except (OSError, BadZipFile) as exc:
        print(f"ERROR: cannot read {path}: {exc}", file=sys.stderr)
        return 1

    required = [".pbo", ".bisign", ".bikey"]
    missing = [
        ending for ending in required
        if not any(name.endswith(ending) for name in lowered)
    ]
    if missing:
        print(f"ERROR: missing addon artifacts: {missing}", file=sys.stderr)
        return 1
    if any(name.endswith(".biprivatekey") for name in lowered):
        print("ERROR: signing private key must never be distributed!", file=sys.stderr)
        return 1

    print(f"PASS: {path.name} contains PBO, BIsign and public BIkey")
    print("NOTE: structure validation only. Multiplayer game test is pending.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
