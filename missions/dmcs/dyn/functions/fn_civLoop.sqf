/*
  Optionale, serverseitige Ambient-Civilian-Simulation.
  Nur createAgent, nicht createUnit. Keine spielbaren Slots, keine RPCs.
  Ortsfilter: benannte Staedte/Doerfer und Strassensegmente.
  Dynamische Obergrenze: min(max, perPlayer * lebende Spieler).
*/
if (!isServer) exitWith {};

private _cfg = missionConfigFile >> "DYN_Settings";
private _max = (getNumber (_cfg >> "ambientCivMax")) max 0 min 40;
private _perPlayer = (getNumber (_cfg >> "ambientCivPerPlayer")) max 0 min 5;
private _classes = getArray (_cfg >> "ambientCivClasses");
private _valid = _classes select {
    isClass (configFile >> "CfgVehicles" >> _x)
};
if (count _valid isEqualTo 0) then {
    diag_log "[DMCS] Keine gueltigen Zivilistenklassen; Ambient-Civ deaktiviert.";
    DYN_civEnabled = false;
};

while {true} do {
    sleep 25;
    private _humans = allPlayers select {
        !isNull _x && {isPlayer _x} && {alive _x} &&
        {typeOf _x != "HeadlessClient_F"}
    };
    private _limit = if (DYN_civEnabled) then {
        _max min (_perPlayer * count _humans)
    } else {0};

    // Eigene Agenten: Tote, verlassene Gebiete und Ueberhang bereinigen.
    private _kept = [];
    {
        private _agent = _x;
        private _near = (_humans findIf {
            _x distance2D _agent < 650
        }) >= 0;
        if (!isNull _agent && {alive _agent} && {_near} &&
            {count _kept < _limit}) then {
            _kept pushBack _agent;
        } else {
            if (!isNull _agent) then {deleteVehicle _agent;};
        };
    } forEach DYN_civAgents;
    DYN_civAgents = _kept;

    // Max. zwei neue Agenten pro Durchlauf, kein Massenspawn.
    private _toSpawn = ((_limit - count DYN_civAgents) max 0) min 2;
    for "_i" from 1 to _toSpawn do {
        if (count _humans > 0) then {
            private _p = selectRandom _humans;
            private _posP = getPosATL _p;
            private _towns = nearestLocations [
                _posP, ["NameCityCapital", "NameCity", "NameVillage"], 350
            ];
            if (count _towns > 0) then {
                private _roads = _posP nearRoads 275;
                private _candidates = _roads select {
                    private _rPos = getPosATL _x;
                    (_posP distance2D _rPos) >= 90 &&
                    {(_posP distance2D _rPos) <= 260} &&
                    {!surfaceIsWater _rPos}
                };
                if (count _candidates > 0) then {
                    private _road = selectRandom _candidates;
                    private _spawn = (getPosATL _road) getPos [
                        4 + random 3, random 360
                    ];
                    if (!surfaceIsWater _spawn) then {
                        private _agent = createAgent [
                            selectRandom _valid, _spawn, [], 0, "NONE"
                        ];
                        if (!isNull _agent) then {
                            _agent setBehaviour "CARELESS";
                            _agent setSpeedMode "LIMITED";
                            DYN_civAgents pushBack _agent;
                        };
                    };
                };
            };
        };
    };

    // Gelegentliches, langsames Gehen ueber die oertliche Strassenstruktur.
    // Agenten besitzen keine Gruppen-FSM. setDestination ist dafuer gedacht.
    {
        if (alive _x && {random 1 < 0.45}) then {
            private _paths = (getPosATL _x) nearRoads 95;
            if (count _paths > 0) then {
                _x setDestination [
                    getPosATL (selectRandom _paths),
                    "LEADER PLANNED",
                    false
                ];
            };
        };
    } forEach DYN_civAgents;

    private _public = [DYN_civEnabled, count DYN_civAgents];
    if !(DYN_publicCiv isEqualTo _public) then {
        DYN_publicCiv = _public;
        publicVariable "DYN_publicCiv";
    };
};
