# Kartenkompatibilitaet und Mod-Abhaengigkeiten

Der SQF-Kern ist nicht an Altis gebunden. Je Terrain wird jedoch eine eigene mission.sqm benoetigt; Welt-Endung wie DMCS.Altis, DMCS.Enoch usw.

## Pflichtpruefungen

1. Karte auf Server und allen Clients vorhanden; Abhaengigkeiten und Keys korrekt.
2. Playable BLUFOR-Slots, respawn_west und dyn_zone_1 bis dyn_zone_3 in 3DEN anlegen.
3. Markerzentren sowie Spawnradius landseitig, ausreichend frei und von Objekten/Wasser entfernt.
4. Konfigurierte CfgVehicles-Klassen auf dem Server vorhanden.
5. Verhalten von KI-Navigation, Gefechtsbereich und Zielspawn auf der konkreten Karte testen.
6. Fuer ACE, RHS, 3CB, CUP, BWMod, LAMBS und ACRE: Schnittstellen und CfgRemoteExec im konkreten Modset pruefen.

## Bekannte technische Grenze

Version 0.1 prueft im Wesentlichen nur die Marker-Mittelposition auf Wasser, nicht alle spawnbaren Offsets auf Kollisionsfreiheit oder Gefahren. Es gibt noch keine Terrain-Adapter, keine automatische Positionssuche und keine Garantie fuer beliebige Mod-Konflikte.

## Geplante Erweiterung

Ein Terrain-Profil je Mission mit validierten Einsatzsektoren, erlaubten Spawnzonen, Blacklists, Klassensatz und Sicherheitstest. Die Serverlogik bleibt dabei ueber Karten hinweg gleich.

**Status:** Architekturansatz, keine nachgewiesene Vollkompatibilitaet.
