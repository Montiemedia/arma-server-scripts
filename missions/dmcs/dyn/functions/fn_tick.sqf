/* Server-only Kontrollschleife; keine clientseitigen Trigger oder pro-Einheit-EHs. */
if (!isServer) exitWith {};
while {true} do {
    sleep 5;
    private _now = time;
    private _remove = [];
    {
        private _r = _y;
        private _state = _r get "state";
        if (_state isEqualTo "REMOVING") then {
            if ([_r] call DYN_fnc_cleanup) then { _remove pushBack _x; };
        };
        if (_state in ["SUCCEEDED", "FAILED"]) then {
            if (_now >= (_r get "cleanupAt") && {(_r get "cleanupAt") >= 0}) then {
                if ([_r] call DYN_fnc_cleanup) then {_r set ["cleanupAt", -1];};
            };
        };
        if (_state isEqualTo "ACTIVE") then {
            private _dt = ((_now - (_r get "lastTick")) max 0) min 10;
            _r set ["lastTick", _now];
            private _type = _r get "type";
            private _p = _r get "position";
            private _tgt = _r get "target";
            private _hold = (_r get "profile") get "hold";
            private _aliveEnemies = {alive _x} count (_r get "units");
            private _radius = switch (_type) do {
                case "recon": {80}; case "secure": {80};
                case "rescue": {8}; case "supply": {10};
                default {10};
            };
            // Bei Geisel/Nachschub wirklich dem Objekt folgen, nicht dem urspruenglichen Marker.
            private _goalPos = if (_type in ["rescue", "supply"] && {!isNull _tgt}) then {getPosATL _tgt} else {_p};
            private _near = (allPlayers findIf {
                !isNull _x && {alive _x} && {isPlayer _x} &&
                {side group _x isEqualTo west} && {_x distance2D _goalPos <= _radius}
            }) >= 0;
            private _finish = "";
            switch (_type) do {
                case "recon": {
                    if (_near) then {_r set ["progress", (_r get "progress") + _dt];}
                    else {_r set ["progress", 0];};
                    if ((_r get "progress") >= _hold) then {_finish = "SUCCEEDED";};
                };
                case "secure": {
                    if (_near && {_aliveEnemies isEqualTo 0}) then {
                        _r set ["progress", (_r get "progress") + _dt];
                    } else {_r set ["progress", 0];};
                    if ((_r get "progress") >= _hold) then {_finish = "SUCCEEDED";};
                };
                case "destroy": {
                    if (isNull _tgt || {!alive _tgt}) then {_finish = "SUCCEEDED";};
                };
                case "rescue": {
                    if (isNull _tgt || {!alive _tgt}) then {_finish = "FAILED";}
                    else {
                        if (_near) then {_r set ["progress", (_r get "progress") + _dt];}
                        else {_r set ["progress", 0];};
                        if ((_r get "progress") >= _hold) then {_finish = "SUCCEEDED";};
                    };
                };
                case "supply": {
                    if (isNull _tgt || {!alive _tgt}) then {_finish = "FAILED";}
                    else {
                        if (_near) then {_r set ["progress", (_r get "progress") + _dt];}
                        else {_r set ["progress", 0];};
                        if ((_r get "progress") >= _hold) then {_finish = "SUCCEEDED";};
                    };
                };
            };
            if !(_finish isEqualTo "") then {[_r, _finish] call DYN_fnc_finish;};
        };
    } forEach DYN_registry;
    if (count _remove > 0) then {
        {DYN_registry deleteAt _x;} forEach _remove;
        [] call DYN_fnc_publish;
    };
};
