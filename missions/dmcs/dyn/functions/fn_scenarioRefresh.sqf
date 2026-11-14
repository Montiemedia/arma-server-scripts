/*
  Client-only scenario library browser. Reads missionConfigFile, never RPCs.
  Controls: 2801 side, 2802 category, 2803 scenarios,
            2804 duration, 2805 player count, 2806 zone, 2807 preview,
            2808 count/status.
  Rebuilds only on relevant user changes; at most 200 configs on a side.
*/
if (!hasInterface) exitWith {};
params [["_reason", "init", [""]]];
private _display = findDisplay 7980;
if (isNull _display) exitWith {};

// lbClear / lbSetCurSel can fire nested LBSelChanged events.
if (uiNamespace getVariable ["DYN_scenarioUiBusy", false]) exitWith {};
uiNamespace setVariable ["DYN_scenarioUiBusy", true];

private _sides = _display displayCtrl 2801;
private _categories = _display displayCtrl 2802;
private _scenarios = _display displayCtrl 2803;
private _durations = _display displayCtrl 2804;
private _counts = _display displayCtrl 2805;
private _zones = _display displayCtrl 2806;
private _preview = _display displayCtrl 2807;
private _status = _display displayCtrl 2808;

private _currentData = {
    params ["_ctrl", ["_default", ""]];
    private _selected = lbCurSel _ctrl;
    if (_selected < 0) exitWith {_default};
    _ctrl lbData _selected
};

if (_reason isEqualTo "init") then {
    lbClear _sides;
    private _team = str (side group player);
    {
        private _row = _sides lbAdd _x;
        _sides lbSetData [_row, _x];
        if (_x isEqualTo _team) then {
            _sides lbSetCurSel _row;
        };
    } forEach ["WEST", "EAST", "GUER", "CIV"];
    if (lbCurSel _sides < 0) then {_sides lbSetCurSel 0;};

    lbClear _durations;
    {
        _x params ["_label", "_limit"];
        private _row = _durations lbAdd _label;
        _durations lbSetData [_row, str _limit];
    } forEach [
        ["Jede Dauer", 0], ["bis 30 Min", 30],
        ["bis 60 Min", 60], ["bis 90 Min", 90],
        ["bis 120 Min", 120]
    ];
    _durations lbSetCurSel 0;

    lbClear _counts;
    {
        _x params ["_label", "_amount"];
        private _row = _counts lbAdd _label;
        _counts lbSetData [_row, str _amount];
    } forEach [
        ["Jede Groesse", 0], ["Aktuelle Spieler", -1],
        ["1 Spieler", 1], ["2 Spieler", 2],
        ["4 Spieler", 4], ["8 Spieler", 8],
        ["12 Spieler", 12], ["16 Spieler", 16],
        ["24 Spieler", 24]
    ];
    // Start with all 200 visible even for a lone mission builder.
    // "Aktuelle Spieler" is an optional filter.
    _counts lbSetCurSel 0;

    lbClear _zones;
    {
        private _row = _zones lbAdd _x;
        _zones lbSetData [_row, _x];
    } forEach ((getArray (
        missionConfigFile >> "DYN_Settings" >> "zones"
    )) select {
        markerShape _x != "" && {!surfaceIsWater (getMarkerPos _x)}
    });
    if (lbSize _zones > 0) then {_zones lbSetCurSel 0;};
};

private _selectedSide = [_sides] call _currentData;
private _root = missionConfigFile >> "DYN_ScenarioCatalog" >> _selectedSide;
private _entries = if (isClass _root) then {
    "true" configClasses _root
} else {[]};

// Collect only when the side changes; category choice persists across filters.
if (_reason in ["init", "side"]) then {
    private _options = [];
    {
        _options pushBackUnique (getText (_x >> "category"));
    } forEach _entries;
    _options sort true;

    lbClear _categories;
    private _first = _categories lbAdd "Alle Kategorien";
    _categories lbSetData [_first, ""];
    {
        private _row = _categories lbAdd _x;
        _categories lbSetData [_row, _x];
    } forEach _options;
    _categories lbSetCurSel 0;
};

if (_reason != "selected") then {
    private _category = [_categories] call _currentData;
    private _maxMinutes = parseNumber ([_durations, "0"] call _currentData);
    private _requested = parseNumber ([_counts, "0"] call _currentData);

    if (_requested < 0) then {
        private _sideConst = switch (_selectedSide) do {
            case "WEST": {west};
            case "EAST": {east};
            case "GUER": {resistance};
            case "CIV": {civilian};
            default {sideUnknown};
        };
        _requested = {
            isPlayer _x && {alive _x} &&
            {side group _x isEqualTo _sideConst} &&
            {typeOf _x != "HeadlessClient_F"}
        } count allPlayers;
        if (_requested < 1) then {_requested = 0;};
    };

    private _oldId = [_scenarios] call _currentData;
    lbClear _scenarios;
    private _matched = 0;
    {
        private _cat = getText (_x >> "category");
        private _min = getNumber (_x >> "minPlayers");
        private _max = getNumber (_x >> "maxPlayers");
        private _minutes = getNumber (_x >> "estimatedMinutes");

        if ((_category isEqualTo "" || {_category isEqualTo _cat}) &&
            {(_maxMinutes isEqualTo 0 || {_minutes <= _maxMinutes})} &&
            {(_requested isEqualTo 0 ||
                {_requested >= _min && {_requested <= _max}})}) then {
            private _scenarioId = getText (_x >> "id");
            private _title = getText (_x >> "title");
            private _row = _scenarios lbAdd format [
                "%1 | %2 (%3 Min, %4-%5 Spieler)",
                _scenarioId, _title, _minutes, _min, _max
            ];
            _scenarios lbSetData [_row, _scenarioId];
            if (_scenarioId isEqualTo _oldId) then {
                _scenarios lbSetCurSel _row;
            };
            _matched = _matched + 1;
        };
    } forEach _entries;

    if (lbCurSel _scenarios < 0 && {lbSize _scenarios > 0}) then {
        _scenarios lbSetCurSel 0;
    };
    _status ctrlSetText format [
        "%1 von 200 Szenarien | Auswahlseite: %2 | Spielerseite: %3",
        _matched, _selectedSide, str (side group player)
    ];
};

private _id = [_scenarios] call _currentData;
private _cfg = [_id] call DYN_fnc_scenarioGet;
if (isClass _cfg) then {
    private _nl = toString [10];
    private _category = getText (_cfg >> "category");
    private _title = getText (_cfg >> "title");
    private _story = getText (_cfg >> "briefing");
    private _target = getText (_cfg >> "objective");
    private _mechanic = getText (_cfg >> "mechanic");
    _preview ctrlSetText format [
        "%1 | %2%3%4%3%3%5%3%3Ziel: %6%3%3" +
        "Prototyp-Mechanik: %7%3" +
        "Die geschilderten Spezialablaeufe sind noch nicht simuliert.",
        _id, _title, _nl, _category, _story, _target, _mechanic
    ];
} else {
    _preview ctrlSetText "Keine Szenarien unter den Filtern.";
};

uiNamespace setVariable ["DYN_scenarioUiBusy", false];
