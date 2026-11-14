/*
  Standalone addon postInit. Called on each machine at every mission start.
  Mission mode (description.ext) and addon mode must NOT be active together.
  No change to an existing mission.sqm is required.
*/
if (!isMultiplayer) exitWith {};
if (isClass (missionConfigFile >> "DYN_Settings")) exitWith {
    diag_log "[DMCS-Addon] Mission-level DMCS detected: addon bootstrap skipped.";
};
if (isServer) then {
    if (isNil "DYN_registry") then {
        // Markers must exist before the normal server registry starts.
        [] call DYN_fnc_autoZones;
        [] call compile preprocessFileLineNumbers
            "\z\dmcs\addons\core\initServer.sqf";
        diag_log "[DMCS-Addon] Server initialized (standalone mode).";
    };
};
if (hasInterface) then {
    [] execVM "\z\dmcs\addons\core\initPlayerLocal.sqf";
};
