#!/usr/bin/env python3
"""Stage Arma 3 DMCS as a standalone, no-mission.sqm HEMTT addon.

Source of truth: missions/dmcs/{dyn,initServer,initPlayerLocal,description.ext}.
Build-only copies are generated below mod/addons/core and never edited by hand.

Run from anywhere:
  python3 missions/dmcs/mod/tools/stage_addon.py
  cd missions/dmcs/mod && hemtt release
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path

DMCS = Path(__file__).resolve().parents[2]
MOD = DMCS / "mod"
ADDON = MOD / "addons" / "core"
PREFIX = "z\\dmcs\\addons\\core"
FUNC_SOURCE = DMCS / "dyn" / "functions"
SCENARIO_SOURCE = DMCS / "dyn" / "scenarios"
OVERRIDES = MOD / "overrides"
AUTO_ZONE_COUNT = 12
AUTO_ZONES = [f"DMCS_AUTO_{i}" for i in range(1, AUTO_ZONE_COUNT + 1)]


def safe_config_settings(text: str) -> str:
    """Convert mission settings into global mod settings with auto sectors."""
    match = re.search(
        r"class DYN_Settings\s*\{(.*?)^\};",
        text, flags=re.DOTALL | re.MULTILINE,
    )
    if match is None:
        raise RuntimeError("Cannot identify DYN_Settings in description.ext")
    settings = match.group(1)
    old = re.compile(r"\bzones\[\]\s*=\s*\{[^}]*\}\s*;")
    new_zones = 'zones[] = {' + ", ".join(f'"{name}"' for name in AUTO_ZONES) + '};'
    settings, count = old.subn(new_zones, settings, count=1)
    if count != 1:
        raise RuntimeError("Expected exactly one DYN_Settings.zones[]")
    return "class DYN_Settings {\n" + settings.strip() + "\n};\n"


def main() -> int:
    original = (DMCS / "description.ext").read_text(encoding="utf-8")
    settings = safe_config_settings(original)

    expected = {"fn_bootstrap.sqf", "fn_autoZones.sqf"}
    all_functions = list(sorted(FUNC_SOURCE.glob("fn_*.sqf")))
    if len(all_functions) < 15:
        raise RuntimeError("Core functions missing: is the DMCS repo complete?")
    if any(not f.is_file() for f in (
        OVERRIDES / "fn_bootstrap.sqf",
        OVERRIDES / "fn_autoZones.sqf",
    )):
        raise RuntimeError("Missing mod-specific bootstrap or auto-zone implementation")

    # Remove only our generated subtree, never repository canonical sources.
    if ADDON.exists():
        shutil.rmtree(ADDON)
    functions = ADDON / "functions"
    scenarios = ADDON / "scenarios"
    functions.mkdir(parents=True)
    scenarios.mkdir(parents=True)

    names = []
    for source in all_functions:
        target = functions / source.name
        body = source.read_text(encoding="utf-8")
        # Config settings/cat are located in configFile for addons,
        # not missionConfigFile. Script-local references remain unchanged.
        body = body.replace("missionConfigFile", "configFile")
        target.write_text(body, encoding="utf-8", newline="\n")
        names.append(source.stem.removeprefix("fn_"))
    for name in expected:
        shutil.copyfile(OVERRIDES / name, functions / name)
        names.append(name.removeprefix("fn_").removesuffix(".sqf"))

    for source in sorted(SCENARIO_SOURCE.glob("*.hpp")):
        shutil.copyfile(source, scenarios / source.name)
    if len(list(scenarios.glob("*.hpp"))) != 5:
        raise RuntimeError("Expected four generated side catalogs and catalog.hpp")

    shutil.copyfile(DMCS / "dyn" / "dialog.hpp", ADDON / "dialog.hpp")
    for entry in ("initServer.sqf", "initPlayerLocal.sqf"):
        body = (DMCS / entry).read_text(encoding="utf-8")
        body = body.replace("missionConfigFile", "configFile")
        (ADDON / entry).write_text(body, encoding="utf-8", newline="\\n")
    (ADDON / "$PBOPREFIX$").write_text(PREFIX + "\n", encoding="utf-8")

    # All addon functions must be loaded from the PBO prefix, not
    # from mission-relative paths. Module has no mandatory CBA dependency.
    declarations = [
        "            class bootstrap { postInit = 1; };"
    ]
    declarations.extend(
        f"            class {n} {{}};" for n in sorted(set(names) - {"bootstrap"})
    )
    config = "\n".join([
        "// GENERATED: run python3 mod/tools/stage_addon.py",
        "class CfgPatches {",
        "    class dmcs_core {",
        '        name = "Dynamic Mission Control System";',
        '        author = "Montiemedia";',
        "        units[] = {};",
        "        weapons[] = {};",
        '        requiredAddons[] = {"A3_Functions_F"};',
        "        requiredVersion = 2.14;",
        '        versionStr = "0.5.0";',
        "    };",
        "};",
        "",
        "class CfgFunctions {",
        "    class DYN {",
        "        class Core {",
        r'            file = "\z\dmcs\addons\core\functions";',
        *declarations,
        "        };",
        "    };",
        "};",
        "",
        "// Do not set global mode=1: missions can have their own whitelist.",
        "class CfgRemoteExec {",
        "    class Functions {",
        "        class DYN_fnc_request { allowedTargets = 2; jip = 0; };",
        "        class DYN_fnc_interact { allowedTargets = 2; jip = 0; };",
        "        class DYN_fnc_feedback { allowedTargets = 1; jip = 0; };",
        "    };",
        "};",
        "",
        settings,
        '#include "dialog.hpp"',
        '#include "scenarios/catalog.hpp"',
        "",
    ])
    (ADDON / "config.cpp").write_text(config, encoding="utf-8", newline="\n")

    assert all((functions / f"fn_{n}.sqf").is_file() for n in set(names))
    print(f"Staged DMCS addon: {ADDON.relative_to(DMCS)}")
    print(f"Functions: {len(set(names))}; scenario files: 5; auto sectors: 12")
    print("Next: cd missions/dmcs/mod && hemtt release")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
