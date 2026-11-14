// Auswahl eines vorhandenen Tasks uebernimmt seinen Entwurfs-Typ und Einsatzraum.
if (!hasInterface) exitWith {};
params ["_control", "_index"];
if (_index < 0) exitWith {};
private _id = _control lbData _index;
private _data = (missionNamespace getVariable ["DYN_publicTasks", []]) select {(_x # 0) isEqualTo _id};
if (count _data isEqualTo 0) exitWith {};
private _row = _data # 0;
private _d = findDisplay 7970;
if (isNull _d) exitWith {};
{
    _x params ["_ctrl", "_wanted"];
    if (!isNull _ctrl) then {
        for "_i" from 0 to ((lbSize _ctrl) - 1) do {
            if ((_ctrl lbData _i) isEqualTo _wanted) exitWith {_ctrl lbSetCurSel _i;};
        };
    };
} forEach [[_d displayCtrl 1801, _row # 1], [_d displayCtrl 1802, _row # 2]];
