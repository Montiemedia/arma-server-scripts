// Lokaler Controller: Server bekommt ausschliesslich whitelisted Strings.
if (!hasInterface) exitWith {};
params [["_verb", "", [""]]];
private _d = findDisplay 7970;
if (isNull _d) exitWith {};
private _list = _d displayCtrl 1800;
private _ty = _d displayCtrl 1801;
private _zn = _d displayCtrl 1802;
private _id = if (lbCurSel _list >= 0) then {_list lbData (lbCurSel _list)} else {""};
private _type = if (lbCurSel _ty >= 0) then {_ty lbData (lbCurSel _ty)} else {""};
private _zone = if (lbCurSel _zn >= 0) then {_zn lbData (lbCurSel _zn)} else {""};
if (_verb isEqualTo "refresh") exitWith { [] call DYN_fnc_uiRefresh; };
if (isServer) then {
    [_verb, _id, _type, _zone] call DYN_fnc_request;
} else {
    [_verb, _id, _type, _zone] remoteExecCall ["DYN_fnc_request", 2];
};
