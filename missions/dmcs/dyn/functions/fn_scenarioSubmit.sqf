/*
  Client: submit only catalog ID + allowed 3DEN zone marker.
  Server resolves all scenario content and rejects other player sides.
*/
if (!hasInterface) exitWith {};

private _display = findDisplay 7980;
if (isNull _display) exitWith {};
private _scenarios = _display displayCtrl 2803;
private _zones = _display displayCtrl 2806;
private _selected = lbCurSel _scenarios;
private _zoneIndex = lbCurSel _zones;
if (_selected < 0 || {_zoneIndex < 0}) exitWith {
    hint "DMCS: Zuerst Szenario und Einsatzsektor auswaehlen.";
};

private _scenarioId = _scenarios lbData _selected;
private _zone = _zones lbData _zoneIndex;
if (!isClass ([_scenarioId] call DYN_fnc_scenarioGet)) exitWith {
    hint "DMCS: Ungueltige Szenario-ID.";
};
if (markerShape _zone isEqualTo "" ||
    {surfaceIsWater (getMarkerPos _zone)}) exitWith {
    hint "DMCS: Einsatzsektor fehlt oder liegt auf Wasser.";
};

hint "DMCS: Szenarioentwurf angefragt. Serverrueckmeldung beachten.";
if (isServer) then {
    ["scenario", _scenarioId, "", _zone] call DYN_fnc_request;
} else {
    ["scenario", _scenarioId, "", _zone] remoteExecCall [
        "DYN_fnc_request", 2
    ];
};
