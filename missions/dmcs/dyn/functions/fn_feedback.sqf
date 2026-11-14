// Rueckmeldung ist rein lokal; hier niemals Serverstatus aendern.
if (!hasInterface) exitWith {};
// Bei Remote-Ausfuehrung ausschliesslich Meldungen vom Server akzeptieren.
if (isRemoteExecuted && {remoteExecutedOwner != 2}) exitWith {};
params [["_message", "", [""]]];
hintSilent format ["DMCS: %1", _message];
private _library = findDisplay 7980;
if (!isNull _library) then {
    (_library displayCtrl 2808) ctrlSetText _message;
};
[] call DYN_fnc_uiRefresh;
