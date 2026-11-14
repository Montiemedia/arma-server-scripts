#!/usr/bin/env python3
"""DMCS static preflight. Uses only Python 3 stdlib.

This is NOT an SQF parser or an in-game/MP test. It checks probable
structural mistakes in source files and cross-file registrations.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CFG = ROOT / "description.ext"
FUNC_DIR = ROOT / "dyn" / "functions"

PAIRS = {")": "(", "]": "[", "}": "{"}
CODE_SUFFIXES = {".sqf", ".ext", ".hpp"}


def check_brackets(path: Path) -> list[str]:
    """Ignore comments and double-quoted SQF strings ("" escapes a quote)."""
    source = path.read_text(encoding="utf-8")
    pos, line, state = 0, 1, "code"
    stack: list[tuple[str, int]] = []
    issues: list[str] = []
    while pos < len(source):
        char = source[pos]
        next_char = source[pos + 1] if pos + 1 < len(source) else ""
        if char == "\n":
            line += 1
        if state == "line":
            if char == "\n":
                state = "code"
            pos += 1
            continue
        if state == "block":
            if char == "*" and next_char == "/":
                state = "code"
                pos += 2
                continue
            pos += 1
            continue
        if state == "string":
            if char == '"' and next_char == '"':
                pos += 2
                continue
            if char == '"':
                state = "code"
            pos += 1
            continue

        if char == "/" and next_char == "/":
            state = "line"
            pos += 2
            continue
        if char == "/" and next_char == "*":
            state = "block"
            pos += 2
            continue
        if char == '"':
            state = "string"
            pos += 1
            continue
        if char in "([{":
            stack.append((char, line))
        elif char in ")]}":
            if not stack:
                issues.append(f"line {line}: unexpected {char}")
            else:
                opening, origin = stack.pop()
                if PAIRS[char] != opening:
                    issues.append(
                        f"line {line}: {char} does not match "
                        f"{opening} from line {origin}"
                    )
        pos += 1
    for opening, origin in stack:
        issues.append(f"line {origin}: unclosed {opening}")
    if state in ("string", "block"):
        issues.append(f"unterminated {state}")
    return issues


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    if not CFG.is_file():
        print(f"Missing config: {CFG}", file=sys.stderr)
        return 1
    cfg = CFG.read_text(encoding="utf-8")
    registered = set(re.findall(r"\bclass\s+(\w+)\s*\{\s*\};", cfg))
    existing = {x.name[3:-4] for x in FUNC_DIR.glob("fn_*.sqf")}

    for name in sorted(registered - existing):
        errors.append(f"CfgFunctions class {name} has no fn_{name}.sqf")
    for name in sorted(existing - registered):
        errors.append(f"fn_{name}.sqf is not registered in CfgFunctions")

    source_files = [
        file for file in ROOT.rglob("*")
        if file.is_file() and file.suffix.lower() in CODE_SUFFIXES
    ]
    for file in source_files:
        for issue in check_brackets(file):
            errors.append(f"{file.relative_to(ROOT)}: {issue}")

    for name in ["request", "interact", "feedback"]:
        if not re.search(
            rf"\bclass\s+DYN_fnc_{re.escape(name)}\s*\{{", cfg
        ):
            errors.append(f"Missing CfgRemoteExec DYN_fnc_{name}")

    request = (FUNC_DIR / "fn_request.sqf").read_text(encoding="utf-8")
    start = (FUNC_DIR / "fn_start.sqf").read_text(encoding="utf-8")
    tick = (FUNC_DIR / "fn_tick.sqf").read_text(encoding="utf-8")
    ui = (FUNC_DIR / "fn_uiRefresh.sqf").read_text(encoding="utf-8")
    for name, src in [
        ("request", request), ("start", start),
        ("tick", tick), ("uiRefresh", ui)
    ]:
        if '"civ_medical"' not in src:
            errors.append(f"Missing civ_medical support in fn_{name}.sqf")

    if 'remoteExecutedOwner' not in (
        FUNC_DIR / "fn_interact.sqf"
    ).read_text(encoding="utf-8"):
        errors.append("Interaction RPC does not validate the remote sender")

    if "mode = 1;" in cfg:
        warnings.append(
            "CfgRemoteExec is a strict whitelist: mod/ACE and BI Task Framework "
            "remote-exec behaviour needs dedicated MP verification"
        )
    warnings.append(
        "Static checks do not prove SQF syntax, AI pathfinding, "
        "JIP correctness, permissions or multiplayer behaviour"
    )

    print(f"DMCS static preflight: {len(source_files)} code files")
    for issue in errors:
        print("FAIL:", issue)
    for note in warnings:
        print("WARN:", note)
    if errors:
        print(f"FAILED: {len(errors)} error(s)")
        return 1
    print("PASS: registrations, bracket structure, feature references")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
