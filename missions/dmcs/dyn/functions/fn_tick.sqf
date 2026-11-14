/*
  Zentrale serverseitige Zielauswertung, alle 5 Sekunden.
  Keine clientseitigen Trigger. "PAUSED" haelt den Missionsfortschritt
  an, aber nicht die Bewegung der vorhandenen KI.
*/
if (!isServer) exitWith {};

while {true} do {
    sleep 5;
    private _now = time;
    private _removing = [];
    {
        private _id = _x;
        private _r = _y;
        private _state = _r get "state";

        if (_state isEqualTo "REMOVING") then {
            if ([_r] call DYN_fnc_cleanup) then {
                _removing pushBack _id;
            };
        };
        if (_state in ["SUCCEEDED", "FAILED"]) then {
            private _cleanupAt = _r get "cleanupAt";
            if (_cleanupAt >= 0 && {_now >= _cleanupAt}) then {
                if ([_r] call DYN_fnc_cleanup) then {
                    _r set ["cleanupAt", -1];
                };
            };
        };
        if (_state isEqualTo "ACTIVE") then {
            private _dt = ((_now - (_r get "lastTick")) max 0) min 10;
            _r set ["lastTick", _now];
            private _type = _r get "type";
            private _p = _r get "position";
            private _tgt = _r get "target";
            private _hold = (_r get "profile") get "hold";
            private _side = _r get "side";
            private _aliveEnemies = {alive _x} count (_r get "units");
            private _radius = switch (_type) do {
                case "recon": {80};
                case "secure": {80};
                case "rescue": {8};
                case "supply": {10};
                case "civ_visit": {25};
                case "civ_courier": {12};
                default {10};
            };
            private _stage = _r getOrDefault ["stage", 0];
            private _goal = _p;
            if (_type in ["rescue", "supply"] && {!isNull _tgt}) then {
                _goal = getPosATL _tgt;
            };
            if (_type isEqualTo "civ_courier" && {_stage isEqualTo 1}) then {
                _goal = _r get "dropPosition";
            };

            private _near = (allPlayers findIf {
                !isNull _x && {isPlayer _x} && {alive _x} &&
                {typeOf _x != "HeadlessClient_F"} &&
                {side group _x isEqualTo _side} &&
                {_x distance2D _goal <= _radius}
            }) >= 0;

            private _finish = "";
            switch (_type) do {
                case "recon";
                case "civ_visit": {
                    if (_near) then {
                        _r set ["progress", (_r get "progress") + _dt];
                    } else {
                        _r set ["progress", 0];
                    };
                    if ((_r get "progress") >= _hold) then {
                        _finish = "SUCCEEDED";
                    };
                };
                case "secure": {
                    if (_near && {_aliveEnemies isEqualTo 0}) then {
                        _r set ["progress", (_r get "progress") + _dt];
                    } else {
                        _r set ["progress", 0];
                    };
                    if ((_r get "progress") >= _hold) then {
                        _finish = "SUCCEEDED";
                    };
                };
                case "destroy": {
                    if (isNull _tgt || {!alive _tgt}) then {
                        _finish = "SUCCEEDED";
                    };
                };
                case "rescue";
                case "supply": {
                    if (isNull _tgt || {!alive _tgt}) then {
                        _finish = "FAILED";
                    } else {
                        if (_near) then {
                            _r set ["progress", (_r get "progress") + _dt];
                        } else {
                            _r set ["progress", 0];
                        };
                        if ((_r get "progress") >= _hold) then {
                            _finish = "SUCCEEDED";
                        };
                    };
                };
                case "civ_courier": {
                    // Zwei echte sequenzielle Task-Zustandsphasen:
                    // zuerst Dokumentenabholung, dann simulierte Uebergabe.
                    if (_near) then {
                        _r set ["progress", (_r get "progress") + _dt];
                    } else {
                        _r set ["progress", 0];
                    };
                    if ((_r get "progress") >= 10) then {
                        if (_stage isEqualTo 0) then {
                            _r set ["stage", 1];
                            _r set ["progress", 0];
                            [_id, _r get "dropPosition"] call BIS_fnc_taskSetDestination;
                            [_id, [
                                "Unterlagen aufgenommen. Zum Abgabepunkt fahren und die Uebergabe abschliessen.",
                                _r get "title", ""
                            ]] call BIS_fnc_taskSetDescription;
                            diag_log format ["[DMCS] %1 Botengang Phase 2", _id];
                        } else {
                            _finish = "SUCCEEDED";
                        };
                    };
                };
            };
            if (_finish != "") then {
                [_r, _finish] call DYN_fnc_finish;
            };
        };
    } forEach DYN_registry;

    if (count _removing > 0) then {
        {DYN_registry deleteAt _x;} forEach _removing;
        [] call DYN_fnc_publish;
    };
};
