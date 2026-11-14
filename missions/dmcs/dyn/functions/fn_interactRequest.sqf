/*
  CLIENT: Liefert ausschliesslich Task-ID und Aktionsname.
  Server prueft den echten Remote-Absender und die Weltposition erneut.
*/
params [["_step", "", [""]]];
if (!hasInterface) exitWith {};
private _id = [_step] call DYN_fnc_interactionAvailable;
if (_id isEqualTo "") exitWith {};
if (isServer) then {
    [_id, _step] call DYN_fnc_interact;
} else {
    [_id, _step] remoteExecCall ["DYN_fnc_interact", 2];
};
