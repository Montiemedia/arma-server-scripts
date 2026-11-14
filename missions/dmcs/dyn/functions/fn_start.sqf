/*
  Serverautoritativ. Pro Auftrag genau eine Coop-Seite (beliebige Fraktion
  innerhalb WEST/EAST/GUER/CIV). Fuer zivile Rollen kein Gegnerzwang.
  Achtung: Modklassen werden nur auf Existenz in CfgVehicles geprueft.
*/
params [["_r", createHashMap, [createHashMap]]];
if (!isServer || {!((_r get "state") isEqualTo "DRAFT")}) exitWith {false};

private _teamSide = [] call DYN_fnc_teamSide;
if (_teamSide isEqualTo sideUnknown) exitWith {
    diag_log "[DMCS] Aktivierung verweigert: keine Spieler oder mehrere menschliche Seiten.";
    false
};

private _type = _r get "type";
if (_teamSide isEqualTo civilian && {_type in ["secure", "destroy"]}) exitWith {
    diag_log "[DMCS] Fuer zivile Spieler sind Sicherung/Zerstoerung deaktiviert.";
    false
};
private _profile = [_type] call DYN_fnc_scale;
if ((_profile get "players") < 1) exitWith {false};

private _pos = getMarkerPos (_r get "zone");
if (surfaceIsWater _pos) exitWith {false};
private _cfg = missionConfigFile >> "DYN_Settings";
private _drop = getText (_cfg >> "civilDropoffMarker");
private _dropPos = [0,0,0];
if (_type isEqualTo "civ_courier") then {
    if (markerShape _drop isEqualTo "") exitWith {
        diag_log format ["[DMCS] Fehlender Abgabemarker: %1", _drop];
    };
    _dropPos = getMarkerPos _drop;
};
if (_type isEqualTo "civ_courier" && {
    markerShape _drop isEqualTo "" ||
    {surfaceIsWater _dropPos} ||
    {_dropPos distance2D _pos < 60}
}) exitWith {false};

private _noCombat = _teamSide isEqualTo civilian ||
    {_type in ["civ_visit", "civ_courier", "civ_medical"]};
if (_noCombat) then {_profile set ["enemies", 0];};

// Gegner der jeweils anderen Seite. GUER verwendet EAST.
// Keine setFriend-Manipulationen gegen CIV.
private _enemySide = if (_teamSide isEqualTo east) then {west} else {east};
private _rifle = if (_enemySide isEqualTo west) then {
    getText (_cfg >> "enemyWestRifle")
} else {
    getText (_cfg >> "enemyEastRifle")
};
private _ar = if (_enemySide isEqualTo west) then {
    getText (_cfg >> "enemyWestAR")
} else {
    getText (_cfg >> "enemyEastAR")
};

private _n = _profile get "enemies";
if (_n > 0 && {
    !isClass (configFile >> "CfgVehicles" >> _rifle) ||
    {!isClass (configFile >> "CfgVehicles" >> _ar)}
}) exitWith {
    diag_log "[DMCS] Gegnerklasse nicht vorhanden.";
    false
};

private _targetClass = switch (_type) do {
    case "destroy": {getText (_cfg >> "destroyTarget")};
    case "rescue": {getText (_cfg >> "rescueTarget")};
    case "civ_medical": {getText (_cfg >> "rescueTarget")};
    case "supply": {getText (_cfg >> "supplyTarget")};
    default {""};
};
if (_targetClass != "" && {
    !isClass (configFile >> "CfgVehicles" >> _targetClass)
}) exitWith {
    diag_log format ["[DMCS] Zielklasse nicht vorhanden: %1", _targetClass];
    false
};

private _target = objNull;
private _groups = [];
private _units = [];
private _failed = false;

// Zielobjekt mit eigenem Besitz; wird beim Cleanup nachvollziehbar geloescht.
if (_targetClass != "") then {
    if (_type in ["rescue", "civ_medical"]) then {
        private _gC = createGroup civilian;
        if (isNull _gC) then {
            _failed = true;
        } else {
            _groups pushBack _gC;
            _target = _gC createUnit [_targetClass, _pos, [], 0, "NONE"];
            if (!isNull _target) then {
                _target setCaptive true;
                _target disableAI "MOVE";
            };
        };
    } else {
        _target = createVehicle [_targetClass, _pos, [], 0, "NONE"];
        if (_type isEqualTo "destroy" && {!isNull _target}) then {
            _target setFuel 0;
            _target lock true;
        };
    };
    if (isNull _target) then {_failed = true;};
};

// Gegenmissionen brauchen echte Feinde; rein zivile Aufgaben bleiben friedlich.
if (!_failed && {_n > 0}) then {
    private _g = createGroup _enemySide;
    if (isNull _g) then {
        _failed = true;
    } else {
        _groups pushBack _g;
        for "_i" from 0 to (_n - 1) do {
            private _spawn = _pos getPos [
                25 + 6 * (_i mod 3), (360 / _n) * _i
            ];
            if (surfaceIsWater _spawn) then {_spawn = _pos;};
            private _unitClass = if ((_i mod 4) isEqualTo 3) then {_ar} else {_rifle};
            private _u = _g createUnit [_unitClass, _spawn, [], 0, "NONE"];
            if (!isNull _u) then {
                _u setSkill 0.45;
                _units pushBack _u;
            };
        };
        if (count _units != _n) then {
            _failed = true;
        } else {
            _g setCombatMode "RED";
            _g setBehaviour "AWARE";
        };
    };
};

private _spec = switch (_type) do {
    case "recon": {["Aufklaerung", "Einsatzgebiet beobachten und Informationen gewinnen."]};
    case "secure": {["Sicherung", "Gegner ausschalten und Gebiet halten."]};
    case "destroy": {["Zerstoerung", "Feindliches Objekt zerstoeren."]};
    case "rescue": {["Personenschutz", "Zivilperson lebend erreichen und sichern (ohne Evakuierung)."]};
    case "supply": {["Versorgung", "Nachschubstelle aufsuchen und sichern (ohne Transport)."]};
    case "civ_visit": {["Ortsbesichtigung", "Eine zivile Ortsbegehung abschliessen."]};
    case "civ_courier": {["Botengang", "Am Startpunkt Unterlagen abholen und am Zielpunkt abgeben (simulierte Uebergabe)."]};
    case "civ_medical": {["Medizinischer Notfall", "Patient vor Ort untersuchen und anschliessend Erste Hilfe leisten. Interaktion ueber das Aktionsmenue, keine ACE-Behandlung."]};
    default {["Auftrag", "Einsatzraum aufsuchen."]};
};

private _id = _r get "id";
private _title = format ["%1 %2", _spec # 0, _id];
private _brief = format [
    "%1 Mensch(en) bei Aktivierung, %2 Gegner-KI. %3",
    _profile get "players", _n, _spec # 1
];

private _taskOK = false;
if (!_failed) then {
    _taskOK = [
        _teamSide, _id, [_brief, _title, ""], _pos,
        "ASSIGNED", 1, true, "", false
    ] call BIS_fnc_taskCreate;
};

if (!_taskOK) exitWith {
    {
        if (!isNull _x && {!isPlayer _x}) then {deleteVehicle _x;};
    } forEach _units;
    if (!isNull _target) then {deleteVehicle _target;};
    {
        if (!isNull _x && {count units _x isEqualTo 0}) then {
            deleteGroup _x;
        };
    } forEach _groups;
    diag_log format ["[DMCS] Auftrag konnte nicht starten: %1", _id];
    false
};

_r set ["side", _teamSide];
_r set ["enemySide", _enemySide];
_r set ["brief", _brief];
_r set ["title", _title];
_r set ["groups", _groups];
_r set ["units", _units];
_r set ["target", _target];
_r set ["position", _pos];
_r set ["dropPosition", _dropPos];
_r set ["stage", 0];
_r set ["profile", _profile];
_r set ["progress", 0];
_r set ["lastTick", time];
_r set ["state", "ACTIVE"];
diag_log format [
    "[DMCS] %1 %2 / Team=%3 / Personen=%4 / Gegner=%5",
    _id, _type, _teamSide, _profile get "players", _n
];
true
