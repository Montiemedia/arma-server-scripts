// Client UI aus kompaktem, repliziertem Snapshot neu aufbauen.
if (!hasInterface) exitWith {};
private _d = findDisplay 7970;
if (isNull _d) exitWith {};
private _list = _d displayCtrl 1800;
private _type = _d displayCtrl 1801;
private _zone = _d displayCtrl 1802;
private _civState = missionNamespace getVariable ["DYN_publicCiv", [false, 0]];
(_d displayCtrl 1803) ctrlSetText format [
    "Zivilisten: %1 | %2 aktiv",
    if (_civState # 0) then {"EIN"} else {"AUS"},
    _civState # 1
];
private _selected = lbCurSel _list;
private _old = if (_selected >= 0) then {_list lbData _selected} else {""};
private _oldType = if (lbCurSel _type >= 0) then {_type lbData (lbCurSel _type)} else {""};
private _oldZone = if (lbCurSel _zone >= 0) then {_zone lbData (lbCurSel _zone)} else {""};
lbClear _list;
{
    _x params ["_id", "_ty", "_zn", "_state", "_players", "_enemies"];
    private _i = _list lbAdd format ["%1 | %2 | %3 | %4 | P:%5 KI:%6", _id, _ty, _zn, _state, _players, _enemies];
    _list lbSetData [_i, _id];
    if (_id isEqualTo _old) then {_list lbSetCurSel _i;};
} forEach (missionNamespace getVariable ["DYN_publicTasks", []]);
if (lbCurSel _list < 0 && {lbSize _list > 0}) then {_list lbSetCurSel 0;};
lbClear _type;
{
    _x params ["_label", "_key"];
    private _i = _type lbAdd _label;
    _type lbSetData [_i, _key];
    if (_key isEqualTo _oldType) then {_type lbSetCurSel _i;};
} forEach [
    ["Aufklaerung", "recon"], ["Sicherung", "secure"],
    ["Zerstoerung", "destroy"], ["Geisel sichern", "rescue"],
    ["Versorgung sichern", "supply"],
    ["Zivil: Ortsbesichtigung", "civ_visit"],
    ["Zivil: Botengang", "civ_courier"]
];
if (lbCurSel _type < 0) then {_type lbSetCurSel 0;};
lbClear _zone;
{
    private _i = _zone lbAdd _x;
    _zone lbSetData [_i, _x];
    if (_x isEqualTo _oldZone) then {_zone lbSetCurSel _i;};
} forEach (getArray (missionConfigFile >> "DYN_Settings" >> "zones"));
if (lbCurSel _zone < 0 && {lbSize _zone > 0}) then {_zone lbSetCurSel 0;};
// Nach dem Wiederaufbau wird auch die Typ-/Zonenauswahl synchronisiert.
if (lbCurSel _list >= 0) then {[_list, lbCurSel _list] call DYN_fnc_uiSelect;};
