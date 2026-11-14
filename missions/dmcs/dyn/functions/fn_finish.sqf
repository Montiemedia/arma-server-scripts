// Beendet einen aktiven Task einmalig, von Serverloop aus.
params [["_r", createHashMap, [createHashMap]], ["_outcome", "FAILED", [""]]];
if (!isServer || {!((_r get "state") isEqualTo "ACTIVE")}) exitWith {};
if !(_outcome in ["SUCCEEDED", "FAILED"]) exitWith {};
_r set ["state", _outcome];
_r set ["cleanupAt", time + 90];
[_r get "id", _outcome, true] call BIS_fnc_taskSetState;
diag_log format ["[DMCS] %1 => %2", _r get "id", _outcome];
[] call DYN_fnc_publish;
