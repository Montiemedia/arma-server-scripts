/*
  Returns one read-only scenario Config or configNull.
  Input is a five-character catalog ID, e.g. C-021.
  Never reads an arbitrary client-supplied path or executes scenario text.
*/
params [["_id", "", [""]]];
if (count _id != 5) exitWith {configNull};

private _parts = _id splitString "-";
if (count _parts != 2) exitWith {configNull};
_parts params ["_prefix", "_number"];
if (count _number != 3) exitWith {configNull};

private _side = switch (_prefix) do {
    case "W": {"WEST"};
    case "E": {"EAST"};
    case "G": {"GUER"};
    case "C": {"CIV"};
    default {""};
};
if (_side isEqualTo "") exitWith {configNull};

private _cfg = missionConfigFile >> "DYN_ScenarioCatalog" >>
    _side >> ("S" + _number);
// Exact ID check prevents aliases, malformed numbers and class-name tricks.
if (!isClass _cfg || {getText (_cfg >> "id") != _id}) exitWith {
    configNull
};
_cfg
