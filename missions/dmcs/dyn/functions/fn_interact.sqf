/*
  SERVER: Interaktions-RPC. Der Client darf weder die Unit noch
  das Zielobjekt noch einen Fortschrittsstand uebergeben.
  Nach Eigentumer-ID, Teamseite, Distanz und Phasenabgleich wird
  genau eine Zustandsaenderung vorgenommen.
*/
if (!isServer) exitWith {};
params [["_id", "", [""]], ["_step", "", [""]]];
if !(_step in ["assess", "treat"]) exitWith {};
if (count _id > 48 || {_id isEqualTo ""}) exitWith {};

private _sender = if (isRemoteExecuted) then {
    remoteExecutedOwner
} else {
    if (hasInterface) then {clientOwner} else {-1}
};
if (_sender < 2) exitWith {};

private _now = diag_tickTime;
private _last = DYN_lastInteractions getOrDefault [_sender, -100];
if (_now - _last < 0.35) exitWith {};
DYN_lastInteractions set [_sender, _now];

private _index = allPlayers findIf {
    !isNull _x && {isPlayer _x} &&
    {typeOf _x != "HeadlessClient_F"} &&
    {owner _x isEqualTo _sender}
};
if (_index < 0) exitWith {};
private _actor = allPlayers # _index;
if (!alive _actor || {vehicle _actor != _actor}) exitWith {};

if !(_id in (keys DYN_registry)) exitWith {};
private _r = DYN_registry get _id;
if !((_r get "state") isEqualTo "ACTIVE" &&
    {(_r get "type") isEqualTo "civ_medical"} &&
    {_r get "side" isEqualTo side group _actor}) exitWith {};

private _patient = _r get "target";
if (isNull _patient || {!alive _patient}) exitWith {};
if (_actor distance2D _patient > 5) exitWith {};

private _phase = _r getOrDefault ["stage", 0];
private _expected = if (_phase isEqualTo 0) then {"assess"} else {"treat"};
if !(_step isEqualTo _expected) exitWith {};
private _message = "";

if (_step isEqualTo "assess") then {
    _r set ["stage", 1];
    [_id, [
        "Patient untersucht. Jetzt vor Ort die Erste Hilfe durchfuehren.",
        _r get "title", ""
    ]] call BIS_fnc_taskSetDescription;
    [] call DYN_fnc_publish;
    _message = "Patient untersucht. Erste Hilfe ist jetzt verfuegbar.";
} else {
    // Missionszustand, keine ACE/Vanilla-Behandlungsmechanik.
    // Keine Aussage ueber reale medizinische Simulation.
    _patient setDamage 0;
    [_r, "SUCCEEDED"] call DYN_fnc_finish;
    _message = "Erste Hilfe abgeschlossen. Auftrag erfolgreich.";
};

diag_log format [
    "[DMCS] civilian medical task=%1 action=%2 owner=%3",
    _id, _step, _sender
];
if (hasInterface && {_sender isEqualTo clientOwner}) then {
    [_message] call DYN_fnc_feedback;
} else {
    if (_sender > 2) then {
        [_message] remoteExecCall ["DYN_fnc_feedback", _sender];
    };
};
