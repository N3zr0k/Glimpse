# Dateien

Alle Dateien, die WoW lädt, je Addon-Ordner. Libs werden nur als Ordner genannt.

Spalte **Datenbank**: *schreibt* oder *liest* einen Namespace bzw. Bereich von Glimpse: Database (`GlimpseDB`).
Namespace `combat` und `travel` liegen im Bereich Core (`GlimpseDB_Core`). Ein Strich heißt: kein Zugriff.

## Glimpse

| Datei | Beschreibung | Datenbank | Abhängigkeiten |
| --- | --- | --- | --- |
| `Glimpse.toc` | Addon-Info, Version, SavedVariables `GlimpseSettings`, lädt `Glimpse.xml` | – | OptionalDeps: Glimpse_Database |
| `Glimpse.xml` | Lädt Libs, Locales, Core, Commands, Modules in dieser Reihenfolge | – | – |
| `LICENSE` | MIT-Lizenz | – | – |
| `Libs/Libs.xml` | Lädt die eingebetteten Bibliotheken | – | – |
| `Libs/Ace3/` | LibStub, CallbackHandler, AceAddon, AceEvent, AceConsole, AceDB, AceDBOptions, AceLocale, AceGUI, AceConfig | – | extern |
| `Libs/HereBeDragons/` | Welt- und Kartenkoordinaten | – | extern, nur Modul Travel |
| `Locales/Locales.xml` | Lädt die Sprachdateien | – | – |
| `Locales/enUS.lua` | Englische Texte (Standard) | – | AceLocale |
| `Locales/deDE.lua` | Deutsche Texte | – | AceLocale |
| `Media/Icon.tga` | Addon-Icon (TOC `IconTexture`) | – | – |
| `Core/Core.xml` | Lädt die Core-Dateien | – | – |
| `Core/Init.lua` | Legt das Addon an, Modul-Prototyp, Einstellungen, `/gli` und `/glimpse`, `Glimpse:GetMeta` | – (Einstellungen in `GlimpseSettings`) | AceAddon, AceConsole, AceDB, AceConfigRegistry |
| `Core/Commands.lua` | Liste der Unterbefehle von `/gli` (`Glimpse:RegisterCommand`); `/gli` selbst meldet Init.lua an | – | Init.lua |
| `Core/Tooltip.lua` | Tooltip-API: ein PostCall, Handler und Zeilen-Provider, Trennlinie, `Glimpse:IsSecret` | – | TooltipDataProcessor |
| `Core/Modifiers.lua` | Tooltip-Zeilen nur bei gehaltener Shift/Strg/Alt-Taste, Optionsgruppe dazu | – | – |
| `Core/DoubleClick/DoubleClick.lua` | Doppelklick-Verteiler: Handler anmelden, Einstellungen, Handler wählen (Priorität, Bedingungen) | – (Einstellungen in `Glimpse.db` Namespace „DoubleClick“) | – |
| `Core/DoubleClick/DoubleClickSituation.lua` | Lage beim Klick: Stehen, Bewegung, Fallen, Wasser, Mount, drinnen/draußen | – | – |
| `Core/DoubleClick/DoubleClickButton.lua` | Erkennung per `GLOBAL_MOUSE_DOWN`, Secure-Button, Override-Bindung, Mouselook | – | DoubleClick.lua, DoubleClickSituation.lua |
| `Core/DoubleClick/DoubleClickOptions.lua` | Block „Doppelklick“ im Tab „Allgemein“: zentrale Taste, je Handler an/aus und Priorität | – | Core/Options.lua |
| `Core/DoubleClick/DoubleClickDebug.lua` | Log der letzten Doppelklicks, Probe `click handlers` | – | Core/Debug |
| `Core/Options.lua` | Optionsfenster: Übersicht, Erweiterungen mit Version und Mindestversion, Profile | – | AceConfig, AceConfigDialog, AceDBOptions |
| `Core/Credits.lua` | Credits der Suite (Autor, Bildnachweise aller Addons, Dank) einmal in der Übersicht | – | Core/Options.lua |
| `Core/Data.lua` | Tab „Daten“: Sichern (Modul Save), Bereiche mit Größe, Export, Import, Zurücksetzen; Probe `db migration` | liest alle Bereiche (Größe), Export, Import, Zurücksetzen | Glimpse_Database optional |
| `Core/IDs.lua` | ID-Helfer: GUID zerlegen, NPC-ID, Namen von Item/Zauber/Karte, Zonen-Schlüssel, Position | – | Modul Locations |
| `Core/Debug/Debug.lua` | Debug-Modus an/aus, einfache Ausgabe `module:Debug` | – | AceConfigRegistry |
| `Core/Debug/DebugTag.lua` | Addon-Kennung `[Glimpse: Name]` in Blau für Debug-Ausgaben in Chat und Tooltip, Addon aus dem Aufrufstapel | – | – |
| `Core/Debug/Debugger.lua` | Debugger mit Kategorien (`Glimpse:NewDebugger`), Log im Speicher | – | – |
| `Core/Debug/LogWindow.lua` | Fenster mit dem Debug-Log zum Kopieren | – | AceGUI |
| `Core/Debug/Probes.lua` | Probes für Tester (`Glimpse:RegisterProbe`) | – | – |
| `Core/Debug/Sources.lua` | Probe `db sources`: Herkunft der Daten aller Namespaces mit Besitzer, alte SavedVariables, `Glimpse:RegisterDataSource` | liest alle Namespaces (`GetNamespaceInfo`) | Glimpse_Database optional |
| `Commands/Commands.xml` | Lädt die Slash-Befehle | – | – |
| `Commands/Config.lua` | `/gli config`: öffnet die Optionen | – | – |
| `Commands/Debug.lua` | `/gli debug`: Modus, Log-Fenster, Kategorien schalten | – | – |
| `Commands/Help.lua` | `/gli help`: alle Befehle | – | – |
| `Commands/Info.lua` | `/gli info`: Version, Autor, Links aus der TOC | – | – |
| `Commands/Probe.lua` | `/gli probe`: Probes auflisten und ausführen | – | – |
| `Commands/Database.lua` | `/gli db owner <Namespace> [reset]`: Besitzer eines Namespace zeigen oder freigeben | liest/schreibt `GlimpseDB_Meta.namespaces` (Besitzer) | Glimpse_Database optional |
| `Modules/Modules.xml` | Lädt die Module | – | – |
| `Modules/Example/Example.lua` | Vorlage für ein Modul, kann gelöscht werden | – | – |
| `Modules/TooltipDebug/TooltipDebug.lua` | Tooltip-Infos für Entwickler im Debug-Modus (Ziel, ID, Datentyp) | – | – |
| `Modules/Combat/Combat.xml` | Lädt das Modul Combat | – | – |
| `Modules/Combat/Combat.lua` | Modul Combat: `api`-Tabelle, Anmeldung als Schreiber, Helfer `Clean`, `NewSeen`, `Count` | **schreibt** `combat` (Anmeldung) | Glimpse_Database optional, ohne bleibt das Modul still |
| `Modules/Combat/CombatKills.lua` | Kills aus `PARTY_KILL`, Tod des Ziels, geplünderten Leichen; je GUID einmal | **schreibt** `combat`: `kill` | Combat.lua |
| `Modules/Combat/CombatDeaths.lua` | Eigene Tode, Verursacher geschätzt über die zuletzt gesehenen Angreifer | **schreibt** `combat`: `death` | Combat.lua |
| `Modules/Combat/CombatLoot.lua` | Beutefenster: geplünderte Leichen und Items je NPC, meldet Kills an CombatKills | **schreibt** `combat`: `looted`, `loot:<NPC>` | Combat.lua, CombatKills.lua |
| `Modules/Combat/CombatTime.lua` | Kampfzeit in Sekunden, prüft am Kampfende den Tod des Ziels | **schreibt** `combat`: `time` | Combat.lua, CombatKills.lua |
| `Modules/Combat/CombatTooltip.lua` | Kills und Tode im Kreatur-Tooltip, optional mit Account-Wert | **liest** `combat`: `kill`, `death` | Combat.lua, Core/Tooltip.lua |
| `Modules/Combat/CombatOptions.lua` | Tab „Kampf“: Beispielzeile, Schalter, Position | – (Einstellungen in `Glimpse.db` Namespace „Combat“) | CombatTooltip.lua |
| `Modules/Locations/Locations.xml` | Lädt das Modul Locations | – | – |
| `Modules/Locations/Locations.lua` | Modul Locations: API-Version, `api`-Tabelle | – | TomTom optional |
| `Modules/Locations/Maps.lua` | Kartennamen, Kartengröße, Kontinent, Weltposition (mit Cache) | – | – |
| `Modules/Locations/Position.lua` | Spielerposition oder Instanz, Debug-Text | – | – |
| `Modules/Locations/Distance.lua` | Entfernungen in Yards (gleiche Karte oder Welt) | – | Maps.lua, Position.lua |
| `Modules/Locations/Coords.lua` | Koordinaten als Text | – | – |
| `Modules/Locations/Units.lua` | Entfernung in Yards/Meilen oder Metern/Kilometern, Option dazu | – (Einstellung in `GlimpseSettings`) | – |
| `Modules/Locations/Waypoint.lua` | Wegpunkt über TomTom, sonst Spielmarkierung | – | TomTom optional |
| `Modules/Travel/Travel.xml` | Lädt das Modul Travel | – | – |
| `Modules/Save/Save.xml` | Lädt das Modul Save | – | – |
| `Modules/Save/Save.lua` | Modul Save: `api`-Tabelle, Einstellungen, zählt die Änderungen der Database seit dem Start | liest: nur die Änderungsmeldung `EVENT_CHANGED`, keine Daten | Glimpse_Database optional, ohne bleibt das Modul still |
| `Modules/Save/SavePrompt.lua` | Rückfrage mit Neuladen beim Betreten eines Ruhebereichs, ab Menge oder Zeit | – | Blizzard: `IsResting`, `StaticPopup`, `ReloadUI` |
| `Modules/Save/SaveOptions.lua` | Block „Sichern“ im Tab „Daten“: Status, Schalter, zwei Regler, „Jetzt sichern“ | – | `Core/Data.lua` hängt ihn ein |
| `Modules/Travel/Travel.lua` | Modul Travel: `api`-Tabelle, Anmeldung als Schreiber mit Tageswerten, `Count` | **schreibt** `travel` (Anmeldung) | Glimpse_Database optional, HereBeDragons |
| `Modules/Travel/TravelDistance.lua` | Strecke und Reisezeit je Fortbewegungsart (auch Schiff/Zeppelin, Tiefenbahn, unter Wasser), Sprünge werden verworfen; Takt für die Flugzeit | **schreibt** `travel`: `distance`, `traveltime` | Travel.lua, HereBeDragons |
| `Modules/Travel/TravelTeleports.lua` | Teleport, Ruhestein, Portal je Charakter, mit und ohne Ladebildschirm | **schreibt** `travel`: `teleport` | Travel.lua, TravelDistance.lua, HereBeDragons |
| `Modules/Travel/TravelJumps.lua` | Sprünge mit der Leertaste je Charakter (Hook auf JumpOrAscendStart) | **schreibt** `travel`: `jump` | Travel.lua |
| `Modules/Travel/TravelTram.lua` | Fahrten mit der Tiefenbahn: Startstadt, Ziel, Erkennung in der Instanz (Haltestelle oder Verlassen der Instanz beendet eine Fahrt, Laufen im Wagen nicht), Probe `travel tram` mit Geschwindigkeitsprofil | **schreibt** `travel`: `tram`; sendet `GLIMPSE_TRAVEL_RIDE_*` | Travel.lua, TravelDistance.lua |
| `Modules/Travel/TravelRecords.lua` | Rekorde: Eintragen in die Database (ab 1 % besser), Meldung mit Pause und Ausgabe (Bildschirm/Chat), Formate für Tempo, Strecke und Zeit, Einstellungen | **schreibt** `travel`: Rekordarten (`speedmax`, `speedmin`, `fallmax`, `breathmax`, `swimmax`, `jumpmilestone`) | Travel.lua, Glimpse_Database (`SetMax`/`SetMin`) |
| `Modules/Travel/TravelRecordsTexts.lua` | Meldungstexte (mehrere Varianten je Art, ein Text je Sprung-Meilenstein), Deutsch und Englisch | – | – |
| `Modules/Travel/TravelRecordsSpeed.lua` | Tempo-Rekord zu Fuß und beim Reiten (4 Messungen = 2 Sekunden), Name des Reittiers | **schreibt** `travel`: `speedmax`, `speedmin` | TravelDistance.lua, C_MountJournal oder Buff-Symbol |
| `Modules/Travel/TravelRecordsFall.lua` | Fallrekord aus der Fallzeit (Aufprall ab 23 Yards pro Sekunde, Sprung vom Boden setzt neu an), Prüfung alle 0,1 s | **schreibt** `travel`: `fallmax` | Blizzard: `IsFalling` |
| `Modules/Travel/TravelRecordsWater.lua` | Zeit unter Wasser am Stück und Schwimmstrecke am Stück, gewertet beim Auftauchen | **schreibt** `travel`: `breathmax`, `swimmax` | TravelDistance.lua, `GetMirrorTimerInfo` |
| `Modules/Travel/TravelRecordsJumps.lua` | Sprung-Meilensteine mit Spruch, einmal je Charakter | **liest** `travel`: `jump`; **schreibt** `jumpmilestone` | TravelJumps.lua |
| `Modules/Travel/TravelRecordsList.lua` | Rekordliste im Chat (Knopf „Rekorde anzeigen“) | **liest** `travel`: Rekordarten, Charakter und Account | – |
| `Modules/Travel/TravelRecordsOptions.lua` | Tab „Rekorde“: Schalter je Art, Ausgabe, Knopf | – (Einstellungen in `GlimpseSettings`) | Core/Options.lua |
| `Modules/Travel/TravelZones.lua` | Betretene Zonen und Aufenthaltsdauer | **schreibt** `travel`: `zone`, `zonetime` | Travel.lua |
| `Modules/Travel/TravelFlightPoints.lua` | Flugpunkte von der offenen Flugkarte, bekannte je Charakter | **schreibt** `travel`: Orte, `flightpoint` | Travel.lua, C_TaxiMap |
| `Modules/Travel/TravelFlights.lua` | Flugzeit und Strecke je Route vom Abheben bis zur Landung | **schreibt** `travel`: `flight`, `flighttime`, `flightdistance` | Travel.lua, TravelFlightPoints.lua |

## Glimpse_Database

Keine Oberfläche, kein Ace3. API über das Global `GlimpseDB`, private Tabelle `P`.

| Datei | Beschreibung | Datenbank | Abhängigkeiten |
| --- | --- | --- | --- |
| `Glimpse_Database.toc` | Addon-Info, Icon, SavedVariables `GlimpseDB_Meta`, `GlimpseDB_Core` | – | – |
| `Media/Icon.tga` | Addon-Icon (TOC `IconTexture`) | – | – |
| `Glimpse_Database.xml` | Lädt Libs und Core | – | – |
| `LICENSE` | MIT-Lizenz | – | – |
| `Libs/Libs.xml` | Lädt die eingebetteten Bibliotheken | – | – |
| `Libs/LibStub/`, `Libs/CallbackHandler-1.0/` | Bibliotheksverwaltung, Callbacks (`DB.RegisterCallback`) | – | extern |
| `Libs/LibSerialize/`, `Libs/LibDeflate/` | Serialisieren und Packen für Export/Import | – | extern |
| `Core/Core.xml` | Lädt die Core-Dateien | – | – |
| `Core/Init.lua` | Global `GlimpseDB`, Callbacks, Hilfen `P.Path` | – | CallbackHandler |
| `Core/Time.lua` | Stunden-Buckets ab 2026-01-01 UTC, Zeiträume „heute“, „Woche“, „Monat“ | – | – |
| `Core/Areas.lua` | Bereiche laden (LoadOnDemand), Größe, Zurücksetzen | liest/schreibt alle Bereiche `GlimpseDB_<Bereich>` | Glimpse_Database_<Bereich> |
| `Core/Characters.lua` | Charakterliste (Schlüssel aus der GUID), Weltwissen-Charakter `world` | schreibt `GlimpseDB_Meta.characters` | – |
| `Core/Events.lua` | SavedVariables beim Laden übernehmen, Charakter beim Login, startet die Alpha-Übernahme | schreibt `GlimpseDB_Meta`, `GlimpseDB_Core` | – |
| `Core/AlphaMigration.lua` | Nur Alpha: übernimmt Statistics (je Charakter über GUID) und GatheringDB (Weltwissen) | liest `GlimpseStatisticsDB`, `GlimpseGatheringDB`; **schreibt** `combat`, `fishing`, `gathering`, `GlimpseDB_Meta.migrated` | alte Addons müssen aktiv sein |
| `Core/Namespace/Namespace.lua` | Namespaces anmelden (ein Schreiber), Besitzer je Addon-Ordner, lesen, Umzug zwischen Bereichen | schreibt `GlimpseDB_Meta.namespaces` | Areas.lua, `debugstack` |
| `Core/Namespace/Query.lua` | `scope` und Herkunft (own, imported, baseline, external) für alle Abfragen | liest | – |
| `Core/Namespace/Counters.lua` | Zähler je Charakter, Art, ID und Zone, Startwerte, Summen | schreibt/liest Namespace-Daten | Buckets.lua |
| `Core/Namespace/Records.lua` | Rekorde (Höchst- und Tiefstwerte) je Charakter, Art und ID: `SetMax`, `SetMin`, `GetMax`, `GetMin` | schreibt/liest Namespace-Daten (`max`, `min`) | Counters.lua |
| `Core/Namespace/Buckets.lua` | Stunden-Buckets für Zeiträume | schreibt/liest Namespace-Daten | Time.lua |
| `Core/Namespace/Days.lua` | Tageswerte (ein Wert je Tag) für Namespaces mit `days = true`, heute und letzte 7 Tage | schreibt/liest Namespace-Daten | Time.lua |
| `Core/Namespace/Locations.lua` | Orte (Karte, X, Y) verpackt speichern und abfragen | schreibt/liest Namespace-Daten | Adapters.lua |
| `Core/Namespace/Adapters.lua` | Externe Quellen (z. B. GatherMate2) live lesen, nie kopieren | liest externe Addons | – |
| `Core/Namespace/Info.lua` | `DB:GetNamespaceInfo`: Bereich, Schreiber, Besitzer, Summen je Herkunft (für `db sources`) | liest alle Namespaces | – |
| `Core/Transfer/Async.lua` | Export/Import über mehrere Frames verteilen | – | LibSerialize |
| `Core/Transfer/Codec.lua` | Textform eines Exports (Kopfzeile, Serialisieren, Packen) | – | LibSerialize, LibDeflate |
| `Core/Transfer/Export.lua` | Export: Weltwissen und persönliche Daten, nur `own` | liest alle Namespaces | Codec.lua, Async.lua |
| `Core/Transfer/Import.lua` | Import mit Konvertern, wartende Teile für unbekannte Charaktere | **schreibt** `imported`, `GlimpseDB_Meta.pending` | Codec.lua, Merge.lua |
| `Core/Transfer/Merge.lua` | Importe per Maximum zusammenführen, prüft fremde Daten | schreibt Namespace-Daten (`imported`) | – |

## Datenbereiche (LoadOnDemand)

Nur TOC und Lizenz, kein Code. Glimpse_Database lädt sie bei Bedarf und liest und schreibt ihre Tabelle.

| Datei | Beschreibung | Datenbank | Abhängigkeiten |
| --- | --- | --- | --- |
| `Glimpse_Database_Gathering/Glimpse_Database_Gathering.toc` | Bereich Gathering: Fundorte und Knoten | SavedVariables `GlimpseDB_Gathering` (Namespace `gathering`) | Glimpse_Database |
| `Glimpse_Database_Professions/Glimpse_Database_Professions.toc` | Bereich Professions: Berufe | SavedVariables `GlimpseDB_Professions` (Namespace `fishing`) | Glimpse_Database |
| `Glimpse_Database_Reputation/Glimpse_Database_Reputation.toc` | Bereich Reputation, noch leer | SavedVariables `GlimpseDB_Reputation` | Glimpse_Database |
| `Glimpse_Database_Misc/Glimpse_Database_Misc.toc` | Bereich Misc, noch leer | SavedVariables `GlimpseDB_Misc` | Glimpse_Database |
| `*/LICENSE` | MIT-Lizenz | – | – |
