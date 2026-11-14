/* Client -> Server: ausschliesslich kleine Strings, niemals Klassen oder Koordinaten.
   Der Absender wird ueber remoteExecutedOwner ermittelt, NICHT aus _this. */
if (!isServer) exitWith {};
params [
    ["_verb", "", [""]],
    ["_id", "", [""]],
    ["_type", "", [""]],
    ["_zone", "", [""]]
];
private _sender = if (isRemoteExecuted) then { remoteExecutedOwner } else {
    if (hasInterface) then {clientOwner} else {-1}
};
private _reply = "Aktion abgelehnt";
// Leichtgewichtige Anti-Spam-Drossel schon VOR der Rechtepruefung.
private _now = diag_tickTime;
private _last = DYN_lastRequests getOrDefault [_sender, -100];
if ((_now - _last) < 0.3) exitWith {};
DYN_lastRequests set [_sender, _now];
if !([_sender] call DYN_fnc_authorized) exitWith {
    diag_log format ["[DMCS] UNAUTHORIZED owner=%1 verb=%2", _sender, _verb];
    // Keine Antwort an untrusted Sender: verhindert Missbrauch als Broadcast-Ziel.
};
private _zones = getArray (missionConfigFile >> "DYN_Settings" >> "zones");
private _validZone = (_zone in _zones) && {markerShape _zone != ""} && {!surfaceIsWater (getMarkerPos _zone)};
private _types = ["recon", "secure", "destroy", "rescue", "supply", "civ_visit", "civ_courier"];
private _known = _id in (keys DYN_registry);
private _r = if (_known) then {DYN_registry get _id} else {createHashMap};
private _maxTasks = getNumber (missionConfigFile >> "DYN_Settings" >> "maxTasks");
private _maxActive = getNumber (missionConfigFile >> "DYN_Settings" >> "maxActive");
private _changed = false;

switch (_verb) do {
    case "create": {
        if (_type in _types && {_validZone} && {count DYN_registry < _maxTasks}) then {
            private _newId = format ["DMCS_%1", DYN_nextId];
            DYN_nextId = DYN_nextId + 1;
            private _new = createHashMapFromArray [
                ["id", _newId], ["type", _type], ["zone", _zone],
                ["state", "DRAFT"], ["side", sideUnknown], ["profile", createHashMap],
                ["target", objNull], ["units", []], ["groups", []],
                ["position", [0,0,0]], ["progress", 0], ["cleanupAt", -1]
            ];
            DYN_registry set [_newId, _new];
            _reply = format ["Auftrag %1 angelegt", _newId];
            _changed = true;
        } else { _reply = "Typ, Zone oder Auftragslimit ungueltig"; };
    };
    case "edit": {
        if (_known && {_type in _types} && {_validZone} && {(_r get "state") isEqualTo "DRAFT"}) then {
            _r set ["type", _type];
            _r set ["zone", _zone];
            _reply = format ["Entwurf %1 bearbeitet", _id];
            _changed = true;
        } else { _reply = "Bearbeitung nur an gueltigen Entwuerfen"; };
    };
    case "activate": {
        private _active = {((_x get "state") in ["ACTIVE", "PAUSED"])} count (values DYN_registry);
        if (_known && {(_r get "state") isEqualTo "DRAFT"} && {_active < _maxActive}) then {
            if ([_r] call DYN_fnc_start) then {
                _reply = format ["%1 aktiviert", _id];
                _changed = true;
            } else { _reply = "Aktivierung fehlgeschlagen: Spieler, Position oder Klasse pruefen"; };
        } else { _reply = "Auftrag ungueltig oder gleichzeitig aktives Auftragslimit erreicht"; };
    };
    case "pause": {
        if (_known && {(_r get "state") isEqualTo "ACTIVE"}) then {
            _r set ["state", "PAUSED"];
            [_id, [format ["[PAUSIERT] %1", _r get "brief"], format ["[PAUSIERT] %1", _r get "title"], ""]] call BIS_fnc_taskSetDescription;
            _reply = format ["%1 pausiert (nur Zielauswertung)", _id];
            _changed = true;
        };
    };
    case "resume": {
        if (_known && {(_r get "state") isEqualTo "PAUSED"}) then {
            _r set ["state", "ACTIVE"];
            _r set ["lastTick", time];
            [_id, [_r get "brief", _r get "title", ""]] call BIS_fnc_taskSetDescription;
            _reply = format ["%1 fortgesetzt", _id];
            _changed = true;
        };
    };
    case "remove": {
        if (_known) then {
            if ((_r get "state") in ["ACTIVE", "PAUSED"]) then {
                [_id, "CANCELED", true] call BIS_fnc_taskSetState;
            };
            if !((_r get "state") isEqualTo "DRAFT") then {
                [_id, _r get "side", true] call BIS_fnc_deleteTask;
            };
            _r set ["state", "REMOVING"];
            if ([_r] call DYN_fnc_cleanup) then {
                DYN_registry deleteAt _id;
            };
            _reply = format ["%1 entfernt / Bereinigung gestartet", _id];
            _changed = true;
        };
    };
    case "civ_on": {
        private _classes = getArray (
            missionConfigFile >> "DYN_Settings" >> "ambientCivClasses"
        );
        private _valid = _classes select {
            isClass (configFile >> "CfgVehicles" >> _x)
        };
        if (count _valid isEqualTo 0) then {
            _reply = "Zivilleben nicht aktivierbar: keine gueltigen CfgVehicles-Klassen";
        } else {
            if (!DYN_civEnabled) then {
                DYN_civEnabled = true;
                DYN_publicCiv = [true, count DYN_civAgents];
                publicVariable "DYN_publicCiv";
                _changed = true;
            };
            _reply = "Dynamisches Zivilleben ist aktiviert";
        };
    };
    case "civ_off": {
        if (DYN_civEnabled || {count DYN_civAgents > 0}) then {
            DYN_civEnabled = false;
            {if (!isNull _x) then {deleteVehicle _x;};} forEach DYN_civAgents;
            DYN_civAgents = [];
            DYN_publicCiv = [false, 0];
            publicVariable "DYN_publicCiv";
            _changed = true;
        };
        _reply = "Dynamisches Zivilleben ist deaktiviert";
    };
    default { _reply = "Unbekannter Befehl"; };
};
if (_changed) then {
    diag_log format ["[DMCS] owner=%1 %2 id=%3 type=%4 zone=%5", _sender, _verb, _id, _type, _zone];
    [] call DYN_fnc_publish;
};
if (hasInterface && {_sender isEqualTo clientOwner}) then {
    [_reply] call DYN_fnc_feedback;
} else {
    if (_sender > 2) then {[_reply] remoteExecCall ["DYN_fnc_feedback", _sender];};
};
