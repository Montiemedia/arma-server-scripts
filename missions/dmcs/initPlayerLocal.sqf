// Lokaler, guenstiger Respawn/JIP-Waechter; keine Aktionen auf dem Dedicated Server.
// Aktualisiert offene Host-Dialoge bei Serverstatus-Aenderungen, auch durch andere Hosts.
if (hasInterface) then {
    "DYN_publicTasks" addPublicVariableEventHandler {
        [] call DYN_fnc_uiRefresh;
    };
    "DYN_publicCiv" addPublicVariableEventHandler {
        [] call DYN_fnc_uiRefresh;
    };
};
[] spawn {
    waitUntil { sleep 1; !isNull player };
    while { true } do {
        if (isNil { player getVariable "DYN_menuBound" }) then {
            player setVariable ["DYN_menuBound", true, false];
            player addAction [
                "DMCS | Einsatzfuehrung",
                { if (isNull (findDisplay 7970)) then {createDialog "DYN_HostDialog";}; },
                nil, 6, false, true, "",
                "(isServer && hasInterface) || {serverCommandAvailable '#lock'} || {(getPlayerUID player) in (getArray (missionConfigFile >> 'DYN_Settings' >> 'trustedUIDs'))}"
            ];
        };
        sleep 3;
    };
};
