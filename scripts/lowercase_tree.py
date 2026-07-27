#!/usr/bin/env python3
"""Lowercase every file and directory below a root without silent collisions."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


def lowercase_tree(root: Path) -> int:
    if not root.is_dir():
        print(f"Kein Verzeichnis: {root}", file=sys.stderr)
        return 2

    renamed = 0
    for current, dirs, files in os.walk(root, topdown=False):
        current_path = Path(current)
        for name in files + dirs:
            source = current_path / name
            lowered = name.lower()
            if name == lowered:
                continue
            target = current_path / lowered
            if target.exists() and target != source:
                raise RuntimeError(f"Namenskollision: {source} -> {target}")
            source.rename(target)
            renamed += 1

    print(f"{renamed} Einträge in Kleinbuchstaben umbenannt: {root}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    try:
        return lowercase_tree(args.root.resolve())
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
