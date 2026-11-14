/*
  Ermittelt die gemeinsame Coop-Seite (WEST, EAST, GUER, CIV).
  Kein Spieler / gemischte Seiten / Konflikt mit fest konfigurierter
  Seite => sideUnknown. Headless Clients werden ignoriert.
*/
if (!isServer) exitWith { sideUnknown };

private _humans = allPlayers select {
    !isNull _x &&
    {isPlayer _x} &&
    {typeOf _x != "HeadlessClient_F"}
};
if (count _humans isEqualTo 0) exitWith { sideUnknown };

private _team = side group (_humans # 0);
if !(_team in [west, east, resistance, civilian]) exitWith { sideUnknown };
if ((_humans findIf {side group _x != _team}) >= 0) exitWith {
    sideUnknown
};

private _configured = toUpper getText (
    missionConfigFile >> "DYN_Settings" >> "playerSide"
);
private _wanted = switch (_configured) do {
    case "WEST": {west};
    case "EAST": {east};
    case "GUER": {resistance};
    case "CIV": {civilian};
    default {sideUnknown};
};
if (_wanted != sideUnknown && {_wanted != _team}) exitWith {
    sideUnknown
};
_team
