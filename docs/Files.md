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
| `Core/Options.lua` | Optionsfenster: Übersicht, Erweiterungen mit Version und Mindestversion, Profile | – | AceConfig, AceConfigDialog, AceDBOptions |
| `Core/Data.lua` | Tab „Daten“: Bereiche mit Größe, Export, Import, Zurücksetzen; Probe `db migration` | liest alle Bereiche (Größe), Export, Import, Zurücksetzen | Glimpse_Database optional |
| `Core/IDs.lua` | ID-Helfer: GUID zerlegen, NPC-ID, Namen von Item/Zauber/Karte, Zonen-Schlüssel, Position | – | Modul Locations |
| `Core/Debug/Debug.lua` | Debug-Modus an/aus, einfache Ausgabe `module:Debug` | – | AceConfigRegistry |
| `Core/Debug/Debugger.lua` | Debugger mit Kategorien (`Glimpse:NewDebugger`), Log im Speicher | – | – |
| `Core/Debug/LogWindow.lua` | Fenster mit dem Debug-Log zum Kopieren | – | AceGUI |
| `Core/Debug/Probes.lua` | Probes für Tester (`Glimpse:RegisterProbe`) | – | – |
| `Core/Debug/Sources.lua` | Probe `db sources`: Herkunft der Daten aller Namespaces, alte SavedVariables, `Glimpse:RegisterDataSource` | liest alle Namespaces (`GetNamespaceInfo`) | Glimpse_Database optional |
| `Commands/Commands.xml` | Lädt die Slash-Befehle | – | – |
| `Commands/Config.lua` | `/gli config`: öffnet die Optionen | – | – |
| `Commands/Debug.lua` | `/gli debug`: Modus, Log-Fenster, Kategorien schalten | – | – |
| `Commands/Help.lua` | `/gli help`: alle Befehle | – | – |
| `Commands/Info.lua` | `/gli info`: Version, Autor, Links aus der TOC | – | – |
| `Commands/Probe.lua` | `/gli probe`: Probes auflisten und ausführen | – | – |
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
| `Modules/Travel/Travel.lua` | Modul Travel: `api`-Tabelle, Anmeldung als Schreiber, `Count` | **schreibt** `travel` (Anmeldung) | Glimpse_Database optional, HereBeDragons |
| `Modules/Travel/TravelDistance.lua` | Strecke je Fortbewegungsart, Sprünge werden verworfen | **schreibt** `travel`: `distance` | Travel.lua, HereBeDragons |
| `Modules/Travel/TravelZones.lua` | Betretene Zonen und Aufenthaltsdauer | **schreibt** `travel`: `zone`, `zonetime` | Travel.lua |

## Glimpse_Database

Keine Oberfläche, kein Ace3. API über das Global `GlimpseDB`, private Tabelle `P`.

| Datei | Beschreibung | Datenbank | Abhängigkeiten |
| --- | --- | --- | --- |
| `Glimpse_Database.toc` | Addon-Info, SavedVariables `GlimpseDB_Meta`, `GlimpseDB_Core` | – | – |
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
| `Core/Namespace/Namespace.lua` | Namespaces anmelden (ein Schreiber), lesen, Umzug zwischen Bereichen | schreibt `GlimpseDB_Meta.namespaces` | Areas.lua |
| `Core/Namespace/Query.lua` | `scope` und Herkunft (own, imported, baseline, external) für alle Abfragen | liest | – |
| `Core/Namespace/Counters.lua` | Zähler je Charakter, Art, ID und Zone, Startwerte, Summen | schreibt/liest Namespace-Daten | Buckets.lua |
| `Core/Namespace/Buckets.lua` | Stunden-Buckets für Zeiträume | schreibt/liest Namespace-Daten | Time.lua |
| `Core/Namespace/Locations.lua` | Orte (Karte, X, Y) verpackt speichern und abfragen | schreibt/liest Namespace-Daten | Adapters.lua |
| `Core/Namespace/Adapters.lua` | Externe Quellen (z. B. GatherMate2) live lesen, nie kopieren | liest externe Addons | – |
| `Core/Namespace/Info.lua` | `DB:GetNamespaceInfo`: Bereich, Schreiber, Summen je Herkunft (für `db sources`) | liest alle Namespaces | – |
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
