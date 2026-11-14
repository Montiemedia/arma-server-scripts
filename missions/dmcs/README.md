# DMCS v0.1 – Dynamic Mission Control System (Arma 3)

**Status: Prototyp, nicht in Arma 3 getestet. Kein fertiges PBO.**

Ein modularer SQF-Missionskern fuer Arma 3 mit Host-Menue, serverautoritativem Auftragsmanagement, Task-Framework und Skalierung nach aktiven BLUFOR-Spielern.

## Spielmodus: ausschliesslich COOP (PvE)

DMCS ist ausschliesslich fuer kooperative Einsaetze konzipiert: Alle menschlichen Teilnehmer spielen gemeinsam auf BLUFOR (west); OPFOR (east) wird nur von der KI gesteuert. Keine PvP-, TvT-, gemischten Spielerfraktions- oder menschlichen Gegenspieler-Modi. Geisel-/Zivilisten-NPCs sind nicht spielbar. Auch Zeus und Lagedarsteller muessen in v0.1 einen BLUFOR-Spielerslot verwenden.

## Inhalt

Auftragstypen: Aufklaerung, Sicherung, Zerstoerung, Geisel sichern, Versorgung sichern. Anlage, Bearbeitung (Entwuerfe), Aktivierung, Pause der Auswertung, Fortsetzen und Entfernen. Vanilla-Settings ohne Pflichtmods.

## 3DEN installieren

1. Im 3DEN-Editor die gewuenschte Karte laden und ausschliesslich BLUFOR-Spielereinheiten als Playable anlegen. Keine spielbaren OPFOR-, INDEPENDENT- oder Zivilisten-Slots.
2. Mindestens einen Marker respawn_west setzen.
3. Drei geeignete Landmarker dyn_zone_1, dyn_zone_2 und dyn_zone_3 setzen, moeglichst mit 50 m freier Umgebung und mindestens 200 m vom Spielerspawn.
4. Die Mission als DMCS.Altis (bzw. DMCS.<WorldName>) speichern.
5. description.ext, initServer.sqf, initPlayerLocal.sqf und den gesamten dyn-Ordner aus diesem Verzeichnis in den Missionsordner kopieren. Die mission.sqm wird ausschliesslich in 3DEN erstellt.
6. Im Multiplayer testen. Berechtigter Host/Admin: Spieleraktion "DMCS | Einsatzfuehrung".
7. Fuer Dedicated Server einen Administrator per #login anmelden oder UIDs bewusst in DYN_Settings.trustedUIDs[] freigeben.

## Skalierung

1–4 Spieler: 4 Gegner; 5–8: 6; 9–12: 8; 13–16: 10; 17–24: maximal 12. Modifikatoren: Ohne Medic ab 5 Spielern minus 1; bei Zerstoerung ohne ExplosiveSpecialist minus 1; mindestens 2 Gegner. Die Berechnung erfolgt beim Aktivieren und bleibt fuer diesen Auftrag unveraendert.

## Hinweise

* Dieses GitHub-Verzeichnis ist Quellcode, keine lauffaehige Arma-3-Mission ohne mission.sqm.
* Wenn ein lebender menschlicher Teilnehmer auf einer anderen Seite als BLUFOR steht, wird die Aktivierung neuer Auftraege serverseitig verweigert. Bestehende Auftraege werden dadurch nicht automatisch beendet.
* Geisel und Versorgung sind in v0.1 einfache Sicherungsauftraege, ohne Evakuierung oder Transport.
* Pausieren unterbricht nur die Zielauswertung, nicht die KI.
* Die modifizierte Missions-RPC-Whitelist kann mit ACE/CBA/ACRE und anderen Mods kollidieren; vor Produktiveinsatz pruefen.
* Kein Ingame-, JIP-, Dedicated-Server- oder Mod-Kompatibilitaetstest wurde durchgefuehrt.
* Keine automatische Uebertragbarkeit auf alle Terrains. Weitere Hinweise: docs/MAPS.md.
* Originalstand aus dem DMCS_0_1-Prototyp; keine privaten Zugangsdaten enthalten.

## Testen

Im Multiplayer testen: Host-Rechte, unberechtigte Clientanfrage, 2 gleichzeitige Auftraege, JIP, Spielerbeitritt/-austritt, Auftragsabschluss, Cleanup, RPT-Fehler.
