// Nur Server: die Registry niemals an Clients publizieren.
DYN_registry = createHashMap;
DYN_nextId = 1;
DYN_lastRequests = createHashMap;
DYN_publicTasks = [];
publicVariable "DYN_publicTasks";
diag_log "[DMCS] Server initialisiert";
[] spawn DYN_fnc_tick;
