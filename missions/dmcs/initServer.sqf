// Nur Server: die Registry niemals an Clients publizieren.
DYN_registry = createHashMap;
DYN_nextId = 1;
DYN_lastRequests = createHashMap;
DYN_lastInteractions = createHashMap;
DYN_publicTasks = [];
publicVariable "DYN_publicTasks";
DYN_civEnabled = (getNumber (missionConfigFile >> "DYN_Settings" >> "ambientCivEnabled")) > 0;
DYN_civAgents = [];
DYN_publicCiv = [DYN_civEnabled, 0];
publicVariable "DYN_publicCiv";
diag_log "[DMCS] Server initialisiert";
[] spawn DYN_fnc_tick;
[] spawn DYN_fnc_civLoop;
