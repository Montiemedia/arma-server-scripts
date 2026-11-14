/* Server: Ziel, Gegner und Vanilla-Auftrag. Liefert booleschen Status.
   Positionsmarker muessen vom Missionsbauer in freier Landflaeche liegen. */
params [["_r", createHashMap, [createHashMap]]];
if (!isServer || {!((_r get "state") isEqualTo "DRAFT")}) exitWith { false };
// COOP-only (PvE): keine aktiven menschlichen Einheiten ausserhalb BLUFOR.
// Headless Clients zaehlen nicht als menschliche Teilnehmer.
private _wrongSide = allPlayers findIf {
    !isNull _x && {isPlayer _x} && {alive _x} &&
    {typeOf _x != "HeadlessClient_F"} &&
    {side group _x != west}
};
if (_wrongSide >= 0) exitWith {
    diag_log "[DMCS] COOP-only: Auftrag verweigert (aktiver nicht-BLUFOR-Spieler).";
    false
};
private _profile = [_r get "type"] call DYN_fnc_scale;
if ((_profile get "players") < 1) exitWith { false };
private _pos = getMarkerPos (_r get "zone");
if (surfaceIsWater _pos) exitWith { false };
private _type = _r get "type";
private _target = objNull;
private _groups = [];
private _units = [];
private _cfg = missionConfigFile >> "DYN_Settings";

private _class = switch (_type) do {
    case "destroy": { getText (_cfg >> "destroyTarget") };
    case "rescue":  { getText (_cfg >> "rescueTarget") };
    case "supply":  { getText (_cfg >> "supplyTarget") };
    default { "" };
};
if !(_class isEqualTo "") then {
    if !(isClass (configFile >> "CfgVehicles" >> _class)) exitWith {
        diag_log format ["[DMCS] Ungueltige Zielklasse: %1", _class];
        false
    };
    if (_type isEqualTo "rescue") then {
        private _cg = createGroup civilian;
        if (isNull _cg) exitWith { false };
        _groups pushBack _cg;
        _target = _cg createUnit [_class, _pos, [], 0, "NONE"];
        if (!isNull _target) then {
            _target setCaptive true;
            _target disableAI "MOVE";
        };
    } else {
        _target = createVehicle [_class, _pos, [], 0, "NONE"];
        if (_type isEqualTo "destroy" && {!isNull _target}) then {
            _target setFuel 0;
            _target lock true;
        };
    };
};
// Fallback verhindert halb erzeugte Szenarien bei fehlerhaften Objekten.
if (!(_class isEqualTo "") && {isNull _target}) exitWith {
    { if (count units _x isEqualTo 0) then { deleteGroup _x; }; } forEach _groups;
    false
};

private _g = createGroup east;
if (isNull _g) exitWith {
    if (!isNull _target) then { deleteVehicle _target; };
    { if (!isNull _x) then { deleteGroup _x; }; } forEach _groups;
    false
};
_groups pushBack _g;
private _n = _profile get "enemies";
private _rifle = getText (_cfg >> "enemyRifle");
private _ar = getText (_cfg >> "enemyAR");
if !(isClass (configFile >> "CfgVehicles" >> _rifle) && {isClass (configFile >> "CfgVehicles" >> _ar)}) exitWith {
    diag_log "[DMCS] Ungueltige Gegnerklassen";
    { if (!isNull _x) then {deleteVehicle _x;}; } forEach [_target];
    { if (!isNull _x) then {deleteGroup _x;}; } forEach _groups;
    false
};
for "_i" from 0 to (_n - 1) do {
    private _spawnPos = _pos getPos [25 + 6 * (_i mod 3), (360 / _n) * _i];
    if (surfaceIsWater _spawnPos) then { _spawnPos = _pos; };
    private _unitType = if ((_i mod 4) isEqualTo 3) then {_ar} else {_rifle};
    private _u = _g createUnit [_unitType, _spawnPos, [], 0, "NONE"];
    if (!isNull _u) then { _u setSkill 0.45; _units pushBack _u; };
};
if (count _units isNotEqualTo _n) exitWith {
    { if (!isNull _x) then {deleteVehicle _x;}; } forEach _units;
    if (!isNull _target) then {deleteVehicle _target;};
    { if (!isNull _x) then {deleteGroup _x;}; } forEach _groups;
    diag_log "[DMCS] KI-Spawn unvollstaendig, Auftrag abgebrochen";
    false
};
_g setCombatMode "RED";
_g setBehaviour "AWARE";

private _spec = switch (_type) do {
    case "recon": { ["Aufklaerung", "Den Einsatzraum mindestens die geforderte Zeit aufklaeren."] };
    case "secure": { ["Sicherung", "Gegner ausschalten und den Einsatzraum halten."] };
    case "destroy": { ["Zerstoerung", "Das feindliche Kurierfahrzeug zerstoeren."] };
    case "rescue": { ["Geisel sichern", "Geisel lebend erreichen und sichern. Keine Evakuierung in V0.1."] };
    case "supply": { ["Versorgung sichern", "Nachschubpunkt erreichen und sichern. Kein Transport in V0.1."] };
};
private _id = _r get "id";
private _brief = format ["%1 Gegner. %2 Spieler beim Start; %3 Sanitaeter, %4 Sprengstoffspezialisten. Haltezeit: %5 s. %6", _n, _profile get "players", _profile get "medics", _profile get "explosives", _profile get "hold", _spec # 1];
// BI-Task-Framework uebernimmt MP-/JIP-Synchronisation.
private _title = format ["%1 %2", _spec # 0, _id];
private _taskOK = [west, _id, [_brief, _title, ""], _pos, "ASSIGNED", 1, true, "", false] call BIS_fnc_taskCreate;
if (!_taskOK) exitWith {
    { if (!isNull _x) then {deleteVehicle _x;}; } forEach _units;
    if (!isNull _target) then {deleteVehicle _target;};
    { if (!isNull _x) then {deleteGroup _x;}; } forEach _groups;
    diag_log format ["[DMCS] Task-Framework konnte %1 nicht anlegen", _id];
    false
};
_r set ["brief", _brief];
_r set ["title", _title];
_r set ["groups", _groups];
_r set ["units", _units];
_r set ["target", _target];
_r set ["position", _pos];
_r set ["profile", _profile];
_r set ["progress", 0];
_r set ["lastTick", time];
_r set ["state", "ACTIVE"];
diag_log format ["[DMCS] Start %1 Typ=%2 Spieler=%3 Gegner=%4", _id, _type, _profile get "players", _n];
true
