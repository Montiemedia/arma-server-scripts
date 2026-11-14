/*
  Server-only automatic location discovery.
  No static mission marker requirements; limited to 12 sectors.
  Terrain and pathfinding still require real in-game verification.
*/
if (!isServer) exitWith {0};

private _maxZones = 12;
private _mapSize = worldSize max 1000;
private _center = [_mapSize / 2, _mapSize / 2, 0];
private _area = nearestLocations [
    _center,
    ["NameCityCapital", "NameCity", "NameVillage"],
    _mapSize
];
private _selected = [];

private _validate = {
    params ["_candidate"];
    private _result = [];
    if !(_candidate isEqualType []) exitWith {_result};
    if (count _candidate < 2 || {surfaceIsWater _candidate}) exitWith {_result};

    private _empty = _candidate findEmptyPosition [
        5, 75, "C_Offroad_01_F"
    ];
    if (count _empty < 2) then {
        _empty = _candidate findEmptyPosition [3, 100];
    };
    if (count _empty < 2 || {surfaceIsWater _empty}) exitWith {_result};

    // Do not create a mission right at an existing player start.
    if ((playableUnits findIf {
        _x distance2D _empty < 350
    }) >= 0) exitWith {_result};

    if ((_selected findIf {
        _x distance2D _empty < 750
    }) >= 0) exitWith {_result};
    _empty
};

{
    if (count _selected < _maxZones) then {
        private _candidate = [locationPosition _x] call _validate;
        if (count _candidate >= 2) then {
            _selected pushBack _candidate;
        };
    };
} forEach _area;

// Sparse mod terrains: search for a few additional land points.
// Finite search; never place a marker on water as fallback.
private _attempts = 0;
while {count _selected < _maxZones && {_attempts < 250}} do {
    _attempts = _attempts + 1;
    private _random = [
        150 + random ((_mapSize - 300) max 100),
        150 + random ((_mapSize - 300) max 100),
        0
    ];
    private _candidate = [_random] call _validate;
    if (count _candidate >= 2) then {
        _selected pushBack _candidate;
    };
};

{
    private _name = format ["DMCS_AUTO_%1", (_forEachIndex + 1)];
    if !(_name in allMapMarkers) then {
        createMarker [_name, _x];
        _name setMarkerShape "ICON";
        _name setMarkerType "mil_dot";
        _name setMarkerColor "ColorOrange";
        _name setMarkerText format [
            "DMCS Einsatzraum %1", (_forEachIndex + 1)
        ];
    } else {
        diag_log format [
            "[DMCS-Addon] Auto marker collision, left unchanged: %1",
            _name
        ];
    };
} forEach _selected;
diag_log format [
    "[DMCS-Addon] AutoZones: %1/%2 valid areas, map=%3",
    count _selected, _maxZones, worldName
];
count _selected
