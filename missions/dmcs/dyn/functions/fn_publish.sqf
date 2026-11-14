// Nur kompakte, nicht sensible Aufgabenmetadaten fuer UI/JIP senden.
if (!isServer) exitWith {};
private _out = [];
{
    private _r = DYN_registry get _x;
    private _profile = _r get "profile";
    _out pushBack [
        _r get "id", _r get "type", _r get "zone", _r get "state",
        _profile getOrDefault ["players", 0], _profile getOrDefault ["enemies", 0]
    ];
} forEach (keys DYN_registry);
_out sort true;
DYN_publicTasks = _out;
publicVariable "DYN_publicTasks";
