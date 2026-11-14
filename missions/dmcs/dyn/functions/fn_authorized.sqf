/* Server: vertraue nie einer UID, die der Client sendet.
   _owner ist die vom Engine-Remoteexec gelieferte Netzwerk-ID. */
params [["_owner", -1, [0]]];
if (!isServer || {_owner < 2}) exitWith { false };
// Direkte Aufrufe vom lokalen Listenserver-Host (nicht remote).
if (hasInterface && {_owner isEqualTo clientOwner} && {!isRemoteExecuted}) exitWith { true };
private _permitted = false;
private _trusted = getArray (missionConfigFile >> "DYN_Settings" >> "trustedUIDs");
{
    private _u = getUserInfo _x;
    if (count _u > 10) then {
        if ((_u # 1) isEqualTo _owner && {!(_u # 7)}) then {
            if ((_u # 8) isEqualTo 2 || {(_u # 2) in _trusted}) then {
                _permitted = true;
            };
        };
    };
} forEach allUsers;
_permitted
