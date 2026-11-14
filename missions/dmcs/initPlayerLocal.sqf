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
        // Pro Spielerkoerper einmalig: JIP/Respawn erzeugen keine doppelten Aktionen.
        // Die Sichtbarkeitsbedingungen werten nur einen kompakten Client-Snapshot aus.
        if (isNil { player getVariable "DYN_interactionBound" }) then {
            player setVariable ["DYN_interactionBound", true, false];
            player addAction [
                "DMCS | Patient untersuchen",
                { ["assess"] call DYN_fnc_interactRequest; },
                nil, 2, false, true, "",
                "!((['assess'] call DYN_fnc_interactionAvailable) isEqualTo '')"
            ];
            player addAction [
                "DMCS | Erste Hilfe leisten",
                { ["treat"] call DYN_fnc_interactRequest; },
                nil, 2, false, true, "",
                "!((['treat'] call DYN_fnc_interactionAvailable) isEqualTo '')"
            ];
        };
        sleep 3;
    };
};
