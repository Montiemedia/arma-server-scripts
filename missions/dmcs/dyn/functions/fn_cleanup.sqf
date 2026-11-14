// Loescht nur vom System erzeugte Objekte; keine Spielereinheiten.
params [["_r", createHashMap, [createHashMap]]];
if (!isServer) exitWith { false };
{ if (!isNull _x && {!isPlayer _x}) then { deleteVehicle _x; }; } forEach (_r get "units");
private _target = _r get "target";
private _pending = false;
if (!isNull _target) then {
    if (({isPlayer _x} count crew _target) > 0) then {
        _pending = true;
    } else {
        deleteVehicle _target;
    };
};
{
    if (!isNull _x && {count units _x isEqualTo 0}) then { deleteGroup _x; };
} forEach (_r get "groups");
if (!_pending) then {
    _r set ["units", []];
    _r set ["groups", []];
    _r set ["target", objNull];
};
!_pending
