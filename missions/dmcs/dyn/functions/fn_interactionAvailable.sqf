/*
  CLIENT: Findet einen interaktiven, aktiven medizinischen Auftrag in
  unmittelbarer Naehe. Wird aus addAction-condition pro Frame abgefragt:
  nur kleine replizierte Metadaten, keine Netzwerkaufrufe.
  Rueckgabe: Task-ID oder "".
*/
params [["_step", "", [""]]];
if (!hasInterface || {isNull player} || {!alive player} ||
    {vehicle player != player}) exitWith {""};
if !(_step in ["assess", "treat"]) exitWith {""};

private _stage = if (_step isEqualTo "assess") then {0} else {1};
private _playerSide = str (side group player);
private _result = "";
{
    if (count _x >= 8) then {
        _x params [
            "_id", "_type", "_zone", "_state",
            "_players", "_enemies", "_phase", "_side"
        ];
        if (_type isEqualTo "civ_medical" &&
            {_state isEqualTo "ACTIVE"} &&
            {_phase isEqualTo _stage} &&
            {_side isEqualTo _playerSide} &&
            {markerShape _zone != ""} &&
            {player distance2D (getMarkerPos _zone) <= 6}) exitWith {
            _result = _id;
        };
    };
} forEach (missionNamespace getVariable ["DYN_publicTasks", []]);
_result
