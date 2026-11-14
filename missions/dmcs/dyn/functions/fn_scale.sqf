/* Server: deterministische Skalierung, Snapshot zum Aktivierungszeitpunkt.
   Nur lebende, spielergesteuerte BLUFOR-Figuren (kein HC). */
params [["_type", "", [""]]];
private _players = allPlayers select {
    !isNull _x && {isPlayer _x} && {alive _x} && {side group _x isEqualTo west} && {typeOf _x != "HeadlessClient_F"}
};
private _n = count _players;
private _med = { _x getUnitTrait "Medic" } count _players;
private _exp = { _x getUnitTrait "ExplosiveSpecialist" } count _players;
// 1-4:4, 5-8:6, 9-12:8, 13-16:10, ab 17:12 Gegner vor Abzug.
private _bands = ceil (_n / 4);
private _enemy = (4 + 2 * ((_bands max 1) - 1)) min 12;
if (_n >= 5 && {_med isEqualTo 0}) then { _enemy = _enemy - 1; };
if (_type isEqualTo "destroy" && {_exp isEqualTo 0}) then { _enemy = _enemy - 1; };
_enemy = (_enemy max 2) min 12;
createHashMapFromArray [
    ["players", _n], ["medics", _med], ["explosives", _exp],
    ["enemies", _enemy], ["hold", (12 + 4 * ((_bands max 1) - 1)) min 32]
]
