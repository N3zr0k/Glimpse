# Glimpse: Entwickler-Dokumentation

Glimpse ist ein Ace3-Grundgerüst für Tooltip-Addons. Dieses Dokument beschreibt den Aufbau, die
Schnittstellen für Erweiterungen und die Arbeitsweise im Repo. Die verbindlichen Regeln für alle Glimpse-Addons stehen
in [docs/REGELN.md](docs/REGELN.md).

## Aufbau

```
Glimpse/             Das Addon, nur was WoW lädt (die Junction im AddOns-Ordner zeigt hierher)
  Glimpse.toc        Einzige Quelle für Titel, Version, Notes, Icon (siehe unten)
  Glimpse.xml        Zentrale Ladeliste, nur Include-Zeilen
  Core/              Init, IDs, Options, Data (Tab "Daten"), Modifiers, Commands, Tooltip
    Debug/           Debug (Schalter), Debugger (Kategorien, Log), Probes, LogWindow
  Commands/          ein Slash-Befehl = eine Datei (Help, Info, Config, Debug, Probe)
  Locales/           enUS (Default) und deDE, eingetragen in Locales.xml
  Modules/           interne Module, je Modul ein Ordner (Locations, Combat, Travel, Example als Vorlage, TooltipDebug)
  Libs/              Ace3 und HereBeDragons (mitgeliefert, damit ein Klon sofort läuft)
Glimpse_Database*/   Glimpse: Database und ihre vier Datenbereiche (Kapitel "Glimpse_Database")
docs/REGELN.md       Regeln für alle Glimpse-Addons
tests/               Logik-Tests ohne WoW (lua tests/run.lua, Database: lua tests/database/run.lua)
tools/check.py       Strukturprüfung von TOC und XML
.pkgmeta             Paket für den Packager: Addon-Ordner nach oben, Beziehungen für CurseForge
```

Alle Glimpse-Repos sind so aufgebaut: ein Ordner je Addon mit dem Namen des Addons, alles für die Entwicklung daneben.

Regeln für den Addon-Ordner (gelten für alle Glimpse-Addons):
* Die TOC nennt nur eine XML, alle Lua-Dateien werden über XML geladen (Glimpse.xml als Vorbild).
* Lieber viele kleine Lua-Dateien als eine große, getrennt nach Thema. Helfer heißen nach ihrer Hauptdatei (`Fishing.lua`, `FishingLure.lua`).
* Oberste Ebene nur: `Core/` (eigentliche Funktionen, Unterordner nach Bedarf), `Libs/` (externe Libraries), `Commands/` (Slash-Befehle),
  `Locales/` (Übersetzungen), `Modules/` (Erweiterungen nur für dieses Addon, jede in einem eigenen Ordner), `Media/` (Icons, Bilder).

Ladereihenfolge in `Glimpse.xml`: Libs, Locales, Core, Commands, Modules. `Core/Init.lua` legt das
Addon-Objekt an, alle anderen Core-Dateien erweitern es nur und holen es mit
`LibStub("AceAddon-3.0"):GetAddon((...))`.

## Die TOC als einzige Info-Quelle

Titel, Version, Notes, Autor, Icon und Links stehen nur in der TOC. Gelesen wird mit

```lua
Glimpse:GetMeta("Version")                 -- Core
Glimpse:GetMeta("Notes", "Glimpse_KeybindsTooltip") -- eine Erweiterung
```

`Notes-deDE` und weitere Sprachen liest der Client selbst. Bei `Title` wird ein angehängter Farbblock
abgeschnitten (`Glimpse |cff00ff00v0.1.0|r` wird zu `Glimpse`).

Für Erweiterungen sind diese Felder wichtig:

| Feld | Zweck |
| --- | --- |
| `## Title: Glimpse: Name` | Panel-Überschrift; im Einstellungsbaum steht nur `Name` |
| `## Dependencies: Glimpse` | macht das Addon zur Erweiterung (so findet die Übersicht es) |
| `## IconTexture:` | Icon vor dem Namen in den Optionen |
| `## X-Glimpse-MinVersion: 0.1.0` | die Übersicht warnt, wenn der Core älter ist |

## Eigene Erweiterung schreiben

Eine Erweiterung ist ein eigenes Addon mit `## Dependencies: Glimpse`. Sie legt ein Modul an:

```lua
local ADDON_NAME = ...
local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

local MyExt = Glimpse:NewModule("MyExt")   -- hat self:Debug() und AceEvent
MyExt.L = L

local defaults = { profile = { enabled = true } }

function MyExt:OnInitialize()
    -- Einstellungen im eigenen Namespace der Glimpse-Datenbank, sie folgen dem Profil
    self.db = Glimpse.db:RegisterNamespace("MyExt", defaults)
    Glimpse:RegisterAddonOptions(ADDON_NAME, self:BuildOptions())
end

function MyExt:OnEnable()
    self:RegisterTooltipLine(Enum.TooltipDataType.Item, function(module, data)
        return "Hallo " .. tostring(data.id)
    end)
end
```

Eigene Daten, die über Profile hinweg gelten sollen, gehören in eine eigene SavedVariable
(`## SavedVariables:`) oder nach Glimpse: Database, nicht in `GlimpseSettings`. Beispiel: GatheringDB.

Interne Module (im Core-Repo unter `Modules/`) sehen genauso aus und werden in `Modules/Modules.xml`
eingetragen.

## API-Übersicht

### Tooltips (`Core/Tooltip.lua`)

Blizzard erlaubt keinen Callback, der sich wieder entfernen lässt. Glimpse hängt deshalb genau einen
`TooltipDataProcessor`-PostCall an und verteilt selbst, mit pcall um jeden Provider. Der Aufruf wird erst
beim ersten Provider installiert.

| Funktion | Beschreibung |
| --- | --- |
| `module:RegisterTooltipLine(dataType, provider)` | einfachster Weg: Zeilen anhängen. `provider(module, data, tooltip, hidden)` |
| `module:RegisterTooltip(dataType, handler)` | roher Handler `handler(module, tooltip, data)`, für Sonderfälle |
| `module:UnregisterAllTooltips()` | entfernt alles dieses Moduls |
| `Glimpse:RegisterTooltipLine(key, dataType, func)` | dasselbe ohne Modul, `func(data, tooltip, hidden)` |
| `Glimpse:RegisterTooltipHandler(key, dataType, func)` | roher Handler ohne Modul |
| `Glimpse:UnregisterTooltipHandler(key)` / `...Handlers(prefix)` | Entfernen über den Key |
| `Glimpse:AddTooltipLine(tooltip, left, right, r, g, b, icon, iconSize)` | eine Zeile direkt setzen (nur in rohen Handlern nötig) |
| `Glimpse:AddTooltipSeparator(tooltip)` | eine weitere Trennlinie zwischen zwei Gruppen von Zeilen (nur in rohen Handlern nötig) |
| `Glimpse:IsSecret(value)` | true bei geschützten Werten (`issecretvalue`) |

`dataType` ist ein `Enum.TooltipDataType`-Wert, der Name als String oder `"ALL"`.

Was ein Zeilen-Provider zurückgibt:

```lua
return nil                                   -- nichts
return "Text"                                -- eine Zeile
return "Text", r, g, b                       -- eine Zeile mit Farbe
return {
    "Nur links",
    { "Links", "Rechts", r, g, b },          -- zweispaltig, Farbe optional
    { "Mit Icon", nil, 1, 1, 1, icon = "Interface\\Icons\\INV_Misc_Eye_01", iconSize = 14 },
    { separator = true },                    -- Trennlinie zwischen zwei Gruppen (am Ende der Liste fällt sie weg)
}
```

Regeln, die der Core für dich übernimmt:

* **Die erste Trennlinie** setzt der Core vor der ersten Zeile von irgendeiner Erweiterung, einmal pro Tooltip.
  Weitere Linien zwischen deinen eigenen Gruppen kommen mit `{ separator = true }` in der Zeilenliste (oder
  `Glimpse:AddTooltipSeparator` in rohen Handlern).
* **`data` ist bereinigt:** nur Felder, die keine Secret-Werte sind (String, Zahl, Boolean). Die Namen der
  entfernten Felder stehen in `hidden`.
* Ein deaktiviertes Modul liefert keine Zeilen.
* Ein Fehler im Provider bricht weder den Tooltip noch andere Erweiterungen ab (wird über den
  Fehler-Handler gemeldet).

Weltobjekte (Erzadern, Kräuter) liefern in `data` kein `id`/`guid`, nur `dataInstanceID` und `type`.
Der Name steht in der ersten Tooltip-Zeile (`tooltip:GetName() .. "TextLeft1"`).

### Optionen (`Core/Options.lua`)

| Funktion | Beschreibung |
| --- | --- |
| `Glimpse:RegisterAddonOptions(addonName, args, tabs)` | einheitliche Seite für eine Erweiterung |
| `Glimpse:RegisterOptions(key, options, displayName, addonName)` | freie Options-Tabelle als Unterpunkt |
| `Glimpse:GetIcon(addonName)` / `Glimpse:WithAddonIcon(text, addonName)` | TOC-Icon holen / vor Text setzen |

`RegisterAddonOptions` baut die Seite immer gleich auf: Überschrift mit Icon, Notes (klein, grau), die
`args` im ersten Tab "Optionen", die Version klein unter dem ganzen Rahmen. Mit `tabs = true` sind `args` keine Optionen, sondern
Gruppen (`type = "group"`), die als Tabs erscheinen. Alle Optionen mit `width = "full"` stehen untereinander.

Aufruf frühestens in `OnInitialize` des Moduls, weil das Haupt-Panel vorher noch nicht existiert.

### Zusatztasten (`Core/Modifiers.lua`)

Eine Erweiterung kann ihre Ergänzungen nur bei gehaltenen Tasten (Shift, Strg, Alt, auch kombiniert)
anzeigen. Die Auswahl liegt im Profil der Erweiterung (`modShift`, `modCtrl`, `modAlt`, Standard `false`).

```lua
-- Optionen
args.modifiers = Glimpse:BuildModifierOptions(self.db.profile, function() self:RefreshTooltip() end, 10)

-- im Provider
if not Glimpse:ModifiersHeld(self.db.profile) then return nil end

-- Tooltip beim Drücken und Loslassen neu aufbauen
self:RegisterEvent("MODIFIER_STATE_CHANGED", function()
    if Glimpse:ModifiersRequired(self.db.profile) then self:RefreshTooltip() end
end)
```

### Doppelklick (`Core/DoubleClick/`)

Erweiterungen reagieren auf einen Doppelklick in der Spielwelt (z. B. Angel auswerfen). Der Core erkennt den Doppelklick
über `GLOBAL_MOUSE_DOWN`, bestimmt die Lage, wählt den Handler und legt die Taste für diesen einen Klick per
Override-Bindung auf einen gemeinsamen Secure-Button. Der erste Klick bleibt beim Spiel.

```lua
Glimpse:RegisterDoubleClick("fishing", {
    title    = "Professions: Angeln",       -- Name im Block "Doppelklick", sonst der Schlüssel
    modifier = function() return P:CastModifier() end,  -- oder "SHIFT", "CTRL", "ALT", "NONE"
    button   = "RightButton",               -- oder Left/MiddleButton, Button4, Button5; Standard RightButton
    priority = 10,                          -- höher gewinnt, Standard 0
    when     = { standing = true, mounted = false },    -- Felder aus ctx, die genau so sein müssen
    Match    = function(ctx) return true end,           -- optional, weitere Bedingungen
    Prepare  = function(ctx)                -- im PreClick, einmal je Klick
        return { type = "spell", spell = name }          -- oder type "macro" mit macrotext, "item" mit item
    end,                                    -- nil: dieser Klick wirkt nichts
    Done     = function(ctx, action) end,   -- optional, nach dem Klick
})
Glimpse:UnregisterDoubleClick("fishing")
Glimpse:IsDoubleClickCentral()              -- true: Taste zentral, eigene Tasten-Option ausgrauen
Glimpse:GetDoubleClickKey("fishing")        -- wirksame Zusatztaste, Maustaste
Glimpse:GetDoubleClickText("fishing")       -- "Umschalt + Doppelklick rechts"

-- Tastenauswahl in den eigenen Optionen, gleich in allen Addons (ausgegraut, wenn die Taste zentral ist)
Glimpse:AddDoubleClickKeyOptions(args, self.db.profile, 22, {
    modifier = "castKey", button = "castButton",  -- Felder im Profil, Standard "modifier" und "button"
    onChange = function() end, disabled = function() return false end,  -- optional
    hidden = function() return not profile.autoMount end,                -- optional, Funktion im Addon aus
})
-- Ist die Funktion im Addon aus, meldet es den Handler ab (UnregisterDoubleClick); dann verschwindet er auch im Core-Block.
```

`ctx` enthält `standing`, `moving`, `falling`, `swimming`, `underwater`, `mounted`, `canMount`, `flying`, `flyable`,
`indoors`, `outdoors` (true/false), dazu `modifier`, `button`, `now`. Die Namen folgen den Makro-Bedingungen.
`canMount` ist geschätzt (draußen, nicht im Wasser, nicht aufgesessen, nicht im Kampf). Bedingungen, die nur ein Makro
kennt, prüft der Client, wenn `Prepare` einen `macrotext` liefert.

Passen mehrere Handler, gewinnt die höhere Priorität, bei Gleichstand der Name. Im Block „Doppelklick“ unter „Allgemein“ der Glimpse-Optionen
lässt sich je Handler die Priorität überschreiben oder der Handler abschalten, und die Taste zentral für alle festlegen.
Im Kampf sperrt der Client Bindungen und Secure-Attribute für alle Addons; dann passiert nichts. Diagnose:
`/gli probe click handlers`, Debug-Kategorie `DoubleClick click`.

### Orte (`Modules/Locations/`)

Das Modul `Locations` bündelt alles rund um Karten, Position, Entfernungen und Wegpunkte, damit Erweiterungen es nicht
selbst bauen müssen. Es benutzt nur Spielfunktionen; TomTom ist optional (keine harte Abhängigkeit). Schnittstellenversion:
`Locations.API_VERSION` (aktuell 1).

```lua
local Locations = Glimpse:GetModule("Locations")
local yards = Locations:GetDistanceFromPlayer(map, x, y)
if yards then line = Locations:FormatDistance(yards) end
```

| Funktion | Beschreibung |
| --- | --- |
| `GetMapName(map)` | Name der Karte (Zone) oder nil |
| `GetMapSize(map)` | Breite, Höhe in Yards oder nil |
| `GetContinent(map)` | uiMapID des Kontinents oder nil |
| `GetWorldPosition(map, x, y)` | Welt-ID, a, b (Yards) oder nil |
| `GetPlayerInstance()` | `{ instance, name }` in einer Instanz, sonst nil |
| `GetPlayerPosition()` | `{ map, x, y }` (0 bis 1) in der offenen Welt, sonst nil |
| `GetPlayerArea()` | Instanz oder Position, sonst nil |
| `DescribeArea(area)` | Kurztext für die Debug-Ausgabe |
| `GetMapDistance(map, x1, y1, x2, y2)` | Yards auf einer Karte oder nil |
| `GetDistance(map1, x1, y1, map2, x2, y2)` | Luftlinie in Yards: gleiche Karte oder gleicher Kontinent, sonst nil |
| `GetDistanceFromPlayer(map, x, y)` | wie `GetDistance`, vom Spieler aus |
| `FormatDistance(yards)` | Text in der gewählten Einheit: `120 yd`, ab 1760 yd `1.3 mi`; `91 m`, ab 1000 m `3.4 km` (im Deutschen mit Komma) |
| `GetDistanceUnit()` | `"yards"` oder `"meters"`, wie sie gerade gelten |
| `FormatCoords(x, y, decimals)` | `"41.2, 56.8"` (Prozent, im Deutschen mit Komma) |
| `SetWaypoint(map, x, y, title)` | Wegpunkt mit TomTom, sonst mit der Spielmarkierung; true bei Erfolg, false ohne Karte/Koordinaten (Instanzen) |
| `HasTomTom()` | ist TomTom geladen |
| `BuildDistanceOptions(order)` | Auswahlfeld für die Einheit (die Allgemein-Seite benutzt es; Kurzweg `Glimpse:BuildDistanceOptions`) |
| `ResetCaches()` | gemerkte Kartengrößen und Kontinente vergessen (Tests) |

Der Spieler stellt die Einheit in den Glimpse-Optionen (Allgemein) ein: automatisch nach der Sprache des Clients
(Tabelle `Locations.LOCALE_UNITS`), Yards oder Meter. Der Spielwert (`C_Map`, Weltpositionen) ist immer in Yards.
`Glimpse:FormatDistance`, `Glimpse:GetDistanceUnit` und `Glimpse:BuildDistanceOptions` gibt es weiterhin als Kurzwege.
Für Tests ersetzt man Einträge in `Locations.api` (die Blizzard-Funktionen).

### Credits (`Core/Credits.lua`)

Die Credits der ganzen Suite stehen einmal in der Core-Übersicht unter einer Trennlinie mit Überschrift: Autor aus der
TOC (`## Author`), Mitwirkende, Bildnachweise und Dank. Erweiterungen haben keinen eigenen Credits-Tab. Bildnachweise
der Erweiterungen stehen fest in `IMAGE_CREDITS` (Addon-Ordner -> Bild, Autor, Link), der Dank an die Tester in
`SPECIAL_THANKS`. Was eine Erweiterung als vierten Parameter von `RegisterAddonOptions(addonName, args, tabs, credits)`
mitgibt, erscheint dort ebenfalls, mit dem Titel des Addons davor; Links, die schon in `IMAGE_CREDITS` stehen, nicht doppelt:

```lua
Glimpse:RegisterAddonOptions(ADDON_NAME, options, false, {
    contributors = { "Name (wofür)" },
    images = { "Pin - Autor (Flaticon) |cff66ccff(https://...)|r" },
})
```

Neues Bild in einer Erweiterung: Eintrag in `IMAGE_CREDITS` im Core ergänzen (und in der README der Erweiterung).

### Slash-Befehle (`Core/Commands.lua`)

```lua
Glimpse:RegisterCommand("name", "Beschreibung für /gli help", function(glimpse, args) ... end)
```

Ein Befehl pro Datei. Im Core liegen sie in `Commands/` und stehen in `Commands/Commands.xml`; eine
Erweiterung registriert ihren Befehl in einer eigenen Datei (siehe `Glimpse_KeybindsTooltip/Commands/`).

### Debug (`Core/Debug/`)

`Glimpse:IsDebug()`, `Glimpse:SetDebug(enabled)`, `Glimpse:Debug(...)`, in Modulen `self:Debug(...)` (Ausgabe als `Glimpse(Modul): ...`,
nur bei aktivem Debug-Modus). Der Schalter ist im Profil gespeichert. Auch Tooltip-Provider sollten
Debug-Ausgaben vor dem Aufbau teurer Strings über `IsDebug()` absichern.

Für Erweiterungen und Core-Module mit mehreren Themen gibt es Debugger mit Kategorien:

```lua
local debug = Glimpse:NewDebugger("Professions", { "fishing", "lure" })
debug:Log("lure", "Köder %s", name)    -- nur im Debug-Modus und bei eingeschalteter Kategorie
debug:Warn("lure", ...)                 -- wie Log, gelb
debug:Error("lure", ...)                -- immer sichtbar
if debug:IsOn("lure") then ... end      -- vor teurer Arbeit
```

* Ausgabe einheitlich als `[Glimpse: Professions] Professions/lure: ...`; gleiche Zeilen kurz hintereinander werden gezählt statt wiederholt.
* Jede Debug-Ausgabe (Debugger, `module:Debug`, `Glimpse:Debug`, Probes) beginnt mit der Addon-Kennung in eckigen Klammern,
  Name aus der TOC; nur der Teil hinter „Glimpse: “ ist dezent blau (beim Core „Glimpse“). Das Addon ermittelt der Core aus dem Aufrufstapel (beim Debugger beim Anlegen,
  sonst beim Aufruf). Debug-Zeilen im Tooltip beginnen mit `Glimpse:DebugTag()`, z. B.
  `return Glimpse:DebugTag() .. " GatheringDB", 0.6, 0.6, 0.6`. Im Log (`/gli debug log`) steht die Kennung ohne Farbe.
* Kategorien sind an, solange der Debug-Modus an ist; `/gli debug Professions lure off` schaltet eine ab, `/gli debug list` zeigt alle.
* Die letzten 500 Zeilen bleiben im Speicher, `/gli debug log` öffnet sie in einem Fenster zum Kopieren.

Probes sind kleine Prüfungen für Tester, die der Core auflistet und ausgibt:

```lua
Glimpse:RegisterProbe("prof", "lure", function(args) return { "Zeile 1", "Zeile 2" } end, "Zeigt den Köder")
-- /gli probe            Liste
-- /gli probe prof lure  ausführen
```

`/gli probe db sources` zeigt, woher die Daten aller Addons kommen: je Namespace Bereich, Schreiber (Addon), Summen je
Herkunft (`own`, `imported`, `baseline`), Orte und externe Quellen, dazu ob die alten SavedVariables von Statistics und
GatheringDB geladen sind. `/gli probe db sources <Namespace>` schlüsselt nach Art auf. Daten außerhalb von Database
(eigene SavedVariables, Live-Quellen wie GatherMate2 oder die Spiel-Statistik) meldet jede Erweiterung selbst:

```lua
if Glimpse.RegisterDataSource then
    Glimpse:RegisterDataSource("Glimpse_GatheringDB", function() return { "names: GlimpseGatheringNames" } end)
end
```

### IDs (`Core/IDs.lua`)

`Glimpse.IDs:ParseGUID(guid)`, `:NPCFromGUID(guid)`, `:DescribeItem(id, callback)` (wartet auf den Item-Cache),
`:DescribeSpell(id)`, `:DescribeMap(mapID)` (Text `Name [ID]`), `:ZoneKey()` (uiMapID, in Instanzen `-instanceID`) und
`:Where()` (mapID, x, y, Zonenname).

### Daten (Glimpse: Database)

Alle gespeicherten Daten der Suite mit Beispielen zum Abruf stehen in `docs/API.md`.
Glimpse_Database liegt im selben Repo und Paket (Kapitel unten). Der Core führt es unter `## OptionalDeps`, damit es
vorher lädt; fehlt es, laufen die Module still. Kampf und Reisen erfassen für jeden Charakter; Kampf zeigt Kills und
Tode im Kreatur-Tooltip (`Modules/Combat/CombatTooltip.lua`, Tab "Kampf"). Erfasst wird in `CombatKills.lua`,
`CombatDeaths.lua`, `CombatLoot.lua` und `CombatTime.lua`. Erweiterungen lesen über `GlimpseDB:Get(name)`:

| Namespace | Art (kind) | ID | Wert |
| --- | --- | --- | --- |
| `combat` | `kill` | NPC-ID | Kills, pro Zone |
| `combat` | `death` | NPC-ID des Verursachers, 0 = unbekannt | Tode, pro Zone |
| `combat` | `time` | 0 | Sekunden im Kampf |
| `combat` | `looted` | NPC-ID | Kontrolle für `kill`: geplünderte Leichen (Weltwissen), keine Beute-Statistik |
| `combat` | `loot:<NPC-ID>` | Item-ID | Kontrolldaten zu `looted` (Weltwissen); Beute-Auswertung macht Gathering |
| `travel` | `distance` | 1 gelaufen, 2 beritten, 3 geschwommen (Oberfläche), 4 Flugroute, 5 Geist, 6 Schiff/Zeppelin, 7 unter Wasser, 8 Tiefenbahn | Yards |
| `travel` | `zone` | uiMapID, in Instanzen `-instanceID` | Betreten |
| `travel` | `zonetime` | wie `zone` | Sekunden |
| `travel` | `teleport` | 0 | Teleport, Ruhestein, Portal, ohne Strecke |
| `travel` | `jump` | 0 | Sprünge mit der Leertaste (vom Boden) |
| `travel` | `tram` | Ziel (1 Sturmwind, 2 Eisenschmiede, 0 unbekannt) | Fahrten je Ziel (feste Fahrzeit 58 s, `Travel.TRAM_SECONDS`, als `traveltime` Art 8 je Fahrt fest eingetragen); Nachrichten `GLIMPSE_TRAVEL_RIDE_START/_END` (kind `tram` oder `flight`) |
| `travel` | `traveltime` | wie `distance` (4 = Flugroute) | Sekunden in Bewegung |
| `travel` | `flightpoint` | nodeID | 1 = dem Charakter bekannt |
| `travel` | `flight` | Strecke `von * 10000 + nach` (nodeIDs) | Flüge |
| `travel` | `flighttime` | wie `flight` | Sekunden; Schnitt = `flighttime` / `flight` |
| `travel` | `flightdistance` | wie `flight` | Yards; Tempo = `flightdistance` / `flighttime` |

Zonen sind uiMapIDs, in Instanzen `-instanceID`. Reisen misst alle 0,5 s über HereBeDragons und verwirft Sprünge
(Teleport, Ladebildschirm). Schiff/Zeppelin: Position ändert sich, die eigene Geschwindigkeit ist in zwei Schritten
hintereinander 0 (Kurzes Laufen zwischen zwei Stillständen zählt als Laufen). Die Tiefenbahn gilt nur in der Instanz 369, wenn der Charakter selbst steht und seit 2 Sekunden schneller als 10 Yards pro Sekunde bewegt wird; `/gli probe travel tram` zeigt Stadt, Start und Fahrt, `... tram profile` schaltet ein Geschwindigkeitsprofil im Debug um (Anfahren, Maximum, Bremsen); Startstadt und Ziel siehe `TravelTram.lua`. Teleports zählt `TravelTeleports.lua`: ohne Ladebildschirm ab
`MAX_SPEED`, mit Ladebildschirm, wenn der Charakter danach woanders ist; nicht bei Schiff, Zeppelin, Flugroute und
Instanzen und nicht, wenn man in den Ladebildschirm hineinläuft (Tiefenbahn). Eine Gesamtstrecke gibt es nicht als eigenen Zähler, sie ist `GetCount("distance")` über alle Arten. Flugpunkte stehen als Orte im Namespace (`GetLocations(mapID)`, id = nodeID auf der
Zonenkarte), erfasst beim Öffnen der Flugkarte; Namen liefert der Client über `C_TaxiMap`. Die Flugzeit läuft vom
Abheben bis zur Landung. `travel` speichert alle Arten zusätzlich als Tageswerte: Strecke und Zeit je Charakter
insgesamt über `GetCount`, heute und die letzten 7 Tage über `GetDayCount(kind, id, scope, 1 | 7)`. Der Tab "Daten" in den Optionen zeigt die Bereiche, Export, Import und Zurücksetzen.

### Rekorde (`Modules/Travel/TravelRecords*.lua`)

Die Database kennt neben Zählern Rekorde (`Writer:SetMax/SetMin`, `Reader:GetMax/GetMin`, `Records.lua`; Ablage
`max/min[char][kind][id] = { Wert, Zeit, mapID }`, Import behält den besseren Wert). Das Reise-Modul trägt sie ein
(`Travel:NewRecord`, nur ab 1 % besser) und meldet sie (`Travel:Announce`, Pause 30 Sekunden je Art, Ausgabe nach
Option). Gespeichert wird immer, der Schalter betrifft nur die Meldung. Die Erkennung hängt an `Travel:Measure`
(`RecordsTick`): Tempo aus der Streckenmessung in Abschnitten von 10 Messungen (5 Sekunden, Höchstwert zählt), Wasser (Atem, Strecke)
im selben Takt (Laufstrecke am Stück in `TravelRecordsWalk.lua`, Atemzeit und Tauchstrecke ab Start der Atemleiste, Probe `/gli probe travel water` zeigt die Rohwerte), der Sturz in einem eigenen 0,1-Sekunden-Takt aus der Fallzeit (der Client nennt keine Höhe). Texte
stehen in `TravelRecordsTexts.lua`; neue Art: Texte dort, Schalter in `RECORD_DEFAULTS` und `TravelRecordsOptions.lua`,
Zeile in `docs/API.md`.

### Sichern (`Modules/Save/`)

WoW schreibt SavedVariables nur bei Logout und `/reload`. Das Modul zählt die Änderungsmeldungen von Glimpse: Database
(`EVENT_CHANGED`, `Save.pending`) und fragt beim Betreten eines Ruhebereichs (`PLAYER_UPDATE_RESTING`, `IsResting`),
ob neu geladen werden soll. Gefragt wird nur außerhalb von Kampf und nicht als Toter. Auslöser ist die Menge
(`changes`, 10 bis 1000) oder die Zeit seit Start oder letzter Frage (`minutes`, 0 bis 120, 0 = aus) mit mindestens
einer Änderung. Das Neuladen löst der Klick im Dialog aus. Optionen im Tab "Daten" (`SaveOptions.lua`).

### Lokalisierung

Pro Addon ein Ordner `Locales/` mit `enUS.lua` (Default, `L["Text"] = true`) und weiteren Sprachen.
`NewLocale` gibt auf einem anderen Client `nil` zurück, die Datei bricht dann mit `if not L then return end`
ab. Neue Sprache: Datei kopieren und in `Locales.xml` eintragen.

### Gemeinsame Regeln

* Secret-Werte (`issecretvalue`) nie vergleichen, verketten oder als Schlüssel benutzen.
* Blizzard-Funktionen, die zwischen Client-Ständen wandern, über einen Alias mit Fallback ansprechen
  (`C_Item.GetItemInfoInstant or GetItemInfoInstant`).
* Eigene Einstellungen nie in `GlimpseSettings` außerhalb des eigenen Namespace ablegen.

## Glimpse_Database

Unterste Schicht der Glimpse-Addons. Speichert, migriert, exportiert und meldet Änderungen; keine Oberfläche, kein
Ace3. Alle anderen Addons schreiben nur in ihren eigenen Namespace und lesen überall.

### Aufbau

```
Glimpse_Database/               Hauptaddon, immer geladen. SavedVariables: GlimpseDB_Meta, GlimpseDB_Core
  Core/                         Init (Global, Callback, Helfer), Time (Stunden, Zeiträume), Characters (Index, Schlüssel),
                                Areas (Bereiche laden, Größe, Zurücksetzen), Events (ADDON_LOADED, PLAYER_LOGIN)
    Namespace/                  Namespace (Register, Get), Query (scope, Herkunft), Counters, Buckets, Locations, Adapters
    Transfer/                   Async (Arbeit über Frames), Codec (Text), Export, Merge (Prüfen und Zusammenführen), Import
    AlphaMigration.lua          Übernahme aus Statistics und GatheringDB, nur in Alpha-Versionen
  Libs/                         LibStub, CallbackHandler-1.0, LibSerialize, LibDeflate
Glimpse_Database_Gathering/     LoadOnDemand-Bereiche, nur TOC und SavedVariables GlimpseDB_<Bereich>
Glimpse_Database_Professions/
Glimpse_Database_Reputation/
Glimpse_Database_Misc/
tests/database/                 Logik-Tests ohne WoW (wowstub lädt die echten Libraries und alle Dateien nach XML)
```

Jede Datei bekommt vom Client `(addonName, P)`; `P` ist die private Tabelle des Addons. Alles, was nicht API ist,
hängt dort.

### Bereiche und Namespaces

| Bereich | SavedVariables | Inhalt | Laden |
| --- | --- | --- | --- |
| (Meta) | GlimpseDB_Meta | Charakterliste, Namespaces mit Bereich und Version, Warteschlange für Importe | immer |
| Core | GlimpseDB_Core | Core-Module: combat, travel | immer |
| Gathering | GlimpseDB_Gathering | Fundorte, Knoten | bei Bedarf |
| Professions | GlimpseDB_Professions | Angeln und weitere Berufe | bei Bedarf |
| Reputation | GlimpseDB_Reputation | Ruf pro NPC und Fraktion | bei Bedarf |
| Misc | GlimpseDB_Misc | alles andere (Standard) | bei Bedarf |

Ein Bereich wird geladen, wenn ein Namespace darin angemeldet oder gelesen wird (`C_AddOns.LoadAddOn`). Eine
Erweiterung, die einen Bereich immer braucht, kann ihn auch in der TOC unter `## Dependencies` führen.

Namespace und Bereich sind getrennt: Meldet ein Addon seinen Namespace mit einem anderen Bereich an, ziehen die Daten
beim nächsten Login mit um.

### Besitzer eines Namespace

Ein Namespace gehört dem Addon-Ordner, der ihn zuerst mit `DB:Register` anmeldet; Database merkt sich das in
`GlimpseDB_Meta` (`owner`). Den Ordner liest Database aus dem Aufrufstapel (`debugstack`), Erweiterungen geben nichts mit.
Meldet ein anderer Ordner denselben Namespace an, bekommt er `nil, "NOT_OWNER"`, auch wenn er in einer Sitzung zuerst
lädt. Code ohne Addon-Ordner (z. B. `loadstring`) bekommt `nil, "NO_ADDON"`. Lesen über `DB:Get` darf jeder.

Die Namespaces aus der Zeit vor dem Schutz haben feste Besitzer: `combat` und `travel` (Glimpse), `fishing`
(Glimpse_Professions), `gathering` (Glimpse_Gathering, früher Glimpse_GatheringDB; ein gespeicherter alter Besitzer zählt als der neue,
`P.OWNER_RENAMES`). Nach dem Umbenennen eines Addon-Ordners gibt
`/gli db owner <Namespace> reset` den Namespace frei (`DB:ResetOwner`, nur aus Glimpse); der nächste Register wird
Besitzer. `/gli db owner <Namespace>` zeigt den Besitzer.

Der Schutz gilt für die API, gegen Versehen. Gegen Absicht schützt er nicht: SavedVariables sind für jedes Addon offen.
Außerhalb des Clients (Tests ohne `debugstack`) ist er aus.

### API

```lua
local DB = GlimpseDB            -- nil, wenn Database fehlt; DB.API_VERSION prüfen

-- Schreiben (genau ein Schreiber pro Namespace)
local ns = DB:Register("fishing", {
    area = "Professions",             -- Standard "Misc"
    version = 1,                      -- Schema-Version, Standard 1
    migrate = function(data, from, to) end,
    zones = true,                     -- Zähler auch pro Zone
    days = true,                      -- Zähler auch als ein Wert je Tag (lokales Datum)
    world = { loot = true },          -- Arten, die als Weltwissen exportiert werden
})                                    -- nil, Grund ("NOT_OWNER", "NO_ADDON", "DISABLED", "NEWER_DATA" ...)

ns:Count(kind, id, mapID, amount)     -- id Standard 0, amount Standard 1; schreibt Zähler, Zone, Zeiten, Stunden
ns:SetBaseline(kind, id, value)       -- Startwert vor Glimpse, nur einmal
ns:AddLocation(id, mapID, x, y)       -- x, y von 0 bis 1
ns:RemoveLocation(mapID, x, y)

-- Lesen (jeder, auch der Schreiber)
local reader = DB:Get("fishing")      -- lädt den Bereich bei Bedarf; nil, wenn unbekannt
reader:GetCount(kind, id, scope)      -- id nil = alle IDs
reader:GetCounts(kind, scope)         -- { [id] = n }
reader:GetZones(kind, id, scope)      -- { [mapID] = n }
reader:GetSeen(kind, id, scope)       -- erster, letzter Zeitpunkt
reader:GetSeries(kind, id, scope)     -- { [Stunde] = n }, scope braucht range oder from/to
reader:GetDays(kind, id, scope, count)     -- nur mit days = true: { [JJJJMMTT] = n } der letzten count Tage (Standard 7)
reader:GetDayCount(kind, id, scope, count) -- Summe daraus; count = 1 heute, 7 letzte 7 Tage
reader:GetLocations(mapID, id, scope) -- Liste { mapID, x, y, id, source }

-- scope: "char" (Standard), "account", "all" (mit fremden Charakteren aus Importen), Charakter-Index oder
-- { chars = ..., sources = "own" | { "own", "imported", "baseline", "external", "external:GatherMate2" },
--   range = "today" | "week" | "month"  oder  from = Unix-Zeit, to = Unix-Zeit }
-- Ohne sources zählen own und imported. baseline nur auf Wunsch und nie in Zeiträumen.

DB.RegisterCallback(self, DB.EVENT_CHANGED, function(event, nsName, kind, id) end)
-- nsName nil: viele Änderungen auf einmal (Import, Bereich zurückgesetzt)

DB:RegisterAdapter("gathering", "GatherMate2", adapter)   -- externe Daten live lesen, siehe Namespace/Adapters.lua
DB:Export(names, function(text, err) end)                  -- names nil = alle Namespaces, asynchron
DB:Import(text, function(result, err) end)                 -- asynchron, Fehler siehe Transfer/Import.lua
DB:RegisterImportConverter(name, detect, convert)           -- fremde Exportformate

DB:GetCharacters()                    -- eigene Charaktere (Index), aktueller zuerst
DB:GetCharacterInfo(index)            -- name, realm, class, key, foreign
DB:GetNamespaces()
DB:GetNamespaceInfo(name, detail)     -- Bereich, Schreiber, Besitzer, Summen je Herkunft, Orte, Adapter (db sources)
DB:GetOwner(name)                     -- Addon-Ordner, dem der Namespace gehört, oder nil
DB:ResetOwner(name)                   -- Besitzer freigeben, nur aus Glimpse (/gli db owner <Namespace> reset)
DB:LoadArea(area) / DB:GetAreaSize(area) / DB:ResetArea(area)
DB:GetRange("week")                   -- from, to; lokale Mitternacht über date/time
DB:HourOf(stamp) / DB:HourStart(hour) / DB:PackXY(x, y) / DB:UnpackXY(xy)
```

### Datenformat

Pro Namespace eine Tabelle im Bereich:

```
version
own / imported / baseline        Blöcke nach Herkunft
  counts[char][kind][id] = n
  zones[char][kind][id][mapID] = n
  seen[char][kind][id] = { erster, letzter }
  hours[char][kind][Stunde] = n
  idHours[char][kind][id][Stunde] = n
places[source][mapID][x * 10000 + y] = id
```

- `char` ist der Index in `GlimpseDB_Meta.characters`, bei `imported` der Charakter, von dem die Daten stammen.
- Stunden zählen ab 2026-01-01 00:00 UTC (`DB.EPOCH`), geschrieben mit `GetServerTime()`.
- Charakter-Schlüssel: kurzer Hash der Spieler-GUID. `foreign = true` heißt: nur aus einem Import bekannt.

### Export und Import

- Text: `!GlimpseDB:1!` + LibSerialize, LibDeflate, `EncodeForPrint`; beides asynchron über mehrere Frames.
- **Weltwissen** (Orte, Arten aus `world`) ist die Summe aller eigenen Charaktere und landet beim Empfänger als
  `imported` unter dem Charakter, der exportiert hat.
- **Persönliche Daten** (alle anderen Arten) gehen nur an denselben Charakter. Ist er auf dem Rechner noch unbekannt,
  wartet der Teil in `GlimpseDB_Meta.pending` bis zu seinem Login.
- Exportiert wird nur `own`; zusammengeführt per Maximum, ein doppelter Import zählt nicht doppelt.
- Exporte derselben Installation werden abgelehnt (`SAME_INSTALL`).
- Unterschiedliche Schema-Version eines Namespace: der Namespace wird übersprungen (`skipped`).

### Übernahme alter Daten

`Glimpse_Database/Core/AlphaMigration.lua` übernimmt beim Login die SavedVariables von Glimpse: Statistics
(`GlimpseStatisticsDB`) und Glimpse: GatheringDB (`GlimpseGatheringDB`) in den Block `own`. Die SavedVariables sind
nur da, solange das alte Addon aktiv ist; sonst wartet die Übernahme auf den nächsten Login mit aktivem Addon.
Erledigtes steht mit Zeitpunkt in `GlimpseDB_Meta.migrated` (`DB:GetMigrations()`, im Spiel `/gli probe db migration`).
Die alten Addons behalten ihre Daten und laufen unverändert weiter.

Charaktere werden nur über die GUID zugeordnet. Statistics speichert je "Name - Realm"; übernommen wird nur der
eingeloggte Charakter, jeder Twink bei seinem eigenen Login (`migrated.statistics[Charakter-Schlüssel]`, auch wenn er
in Statistics keine Daten hat). GatheringDB ist Weltwissen und wird beim ersten Login übernommen, ohne Charakter: es steht unter dem Eintrag
`world` (Schlüssel "world"), der zum Account zählt, aber in `DB:GetCharacters()` fehlt. Abfragen brauchen dafür den
scope "account" oder "all".

| Namespace | Art | ID | Herkunft |
| --- | --- | --- | --- |
| combat | kill, death | NPC (0 = ohne Zuordnung) | Statistics, Startwerte im Block baseline |
| fishing | cast, catch | 0, je Zone | Statistics, Startwert für catch |
| fishing | fish | Item, je Zone | Statistics |
| fishing | looted, loot:\<Zone>, drop:\<Zone> | Zone, Item | Glimpse_Gathering (Weltwissen), dazu Orte |
| gathering | herb, ore, other, skin | Objekt bzw. NPC | Statistics |
| gathering | node, nodeloot:\<Objekt>, nodedrop:\<Objekt> | Objekt, Item | Glimpse_Gathering (Weltwissen), dazu Zonen und Orte |
| gathering | npc, npcloot:\<NPC>, npcdrop:\<NPC> | NPC, Item | Glimpse_Gathering (Weltwissen), Versuche = Kills |
| gathering | skinned, skinloot:\<NPC>, skindrop:\<NPC> | NPC, Item | Glimpse_Gathering (Weltwissen) |

`*loot` zählt die Menge, `*drop` die Beutefenster mit dem Item (Grundlage der Drop-Chance). Wer einen dieser
Namespaces später als Schreiber anmeldet, übernimmt die Arten und die `world`-Liste aus `AlphaMigration.lua`.

### Alpha-Migration

Die Übernahme läuft nur in `-alpha`-Versionen (Versions-Check am Anfang der Datei), ohne eigene Optionen. Alte Exporte
(`GSTAT1:`, `GGDB1:`) werden nicht umgewandelt, weil sie keine GUID enthalten. `tools/check.py` bricht ab, wenn es die
Datei in einer anderen Version noch gibt: vor der ersten Beta Datei und XML-Zeile löschen.

## Prüfen

```
lua tests/run.lua          # Logik-Tests (Locations, Einheiten, Zusatztasten, Credits, Kampf, Reisen) mit nachgebauter WoW-Umgebung
lua tests/database/run.lua # Logik-Tests von Glimpse_Database mit den echten Libraries
luacheck .                 # Konfiguration in .luacheckrc
python3 tools/check.py     # TOC, XML und Dateiverweise
```

Dasselbe läuft bei jedem Push in GitHub Actions (`.github/workflows/ci.yml`). Meldet luacheck eine
unbekannte Variable, ist es ein Tippfehler oder eine echte API-Funktion, die in `.luacheckrc` unter
`read_globals` fehlt.

## Veröffentlichen

Versionsschema (alle Glimpse-Addons): `X.Y.Z-PHASE.N`, Tag `vX.Y.Z-PHASE.N`, z. B. `0.3.4-alpha.2`.
* `X` Major-Release, `Y` Minor-Release, `PHASE` (`alpha`, `beta`, `latest`): gibt nur Sven vor und frei.
* `Z` Bugfix/Features: steigt bei jeder Änderung in einem Addon-Ordner des Repos (Code, TOC, Kommentare, Medien).
* `N` Repository-Version: steigt bei Änderungen außerhalb der Addon-Ordner (Checks, Tests, Workflows, Doku, README).
  Ein neues `Z` setzt `N` auf 1 zurück.
* Ändert sich nur `N`, wird kein Release gebaut (kein Tag durch `ci.yml`, ein Tag von Hand bricht `release.yml` ohne
  Release ab).
* Bevor ein Repo gebaut wird, werden die Änderungen aufgelistet und von Sven freigegeben.

Die Phase steht in der Version der TOC (`## Version:`), das Tag heißt immer `v` + diese Version:

| `## Version:` in der TOC | Tag | GitHub | CurseForge |
| --- | --- | --- | --- |
| `X.Y.Z-alpha.N` | `vX.Y.Z-alpha.N` | Prerelease | nichts |
| `X.Y.Z-beta.N` | `vX.Y.Z-beta.N` | Release mit „(Beta)“ im Titel, nicht „Latest“ | Beta |
| `X.Y.Z-latest.N` | `vX.Y.Z-latest.N` | Release, als „Latest“ markiert | Release |

Wago und WoWInterface sind abgeschaltet, bis Sven sie freigibt. Eine Version ohne Phase lehnt `tools/check.py` ab;
alte Tags ohne Phase (`v0.2.3`) zählen wie latest.

Alle TOCs eines Repos müssen dieselbe Version haben. Im `CHANGELOG.md` brauchen beta und latest den Abschnitt
`## [X.Y.Z]`, bei alpha reicht `## [Unreleased]`. Die Phase steht nicht im CHANGELOG.

1. Version in der TOC setzen und den CHANGELOG-Abschnitt schreiben.
2. Auf `main` pushen. Ist die Pipeline (Struktur, luacheck, Tests) grün und gibt es für die Basisversion noch kein Tag
   derselben oder einer höheren Phase (alpha < beta < latest, `N` zählt nicht), setzt `ci.yml` das Tag selbst und
   startet `release.yml` per `workflow_dispatch` auf dem Tag (ein mit dem `GITHUB_TOKEN` gepushtes Tag löst keinen
   Push-Workflow aus).
3. `release.yml` prüft Tag, TOC-Version und CHANGELOG, baut das ZIP mit dem BigWigs-Packager, legt das GitHub-Release
   an und kennzeichnet es nach der Tabelle oben.

Eine Version erscheint so nacheinander als alpha, beta und latest: nur die Phase in der TOC ändern
(`0.2.3-alpha.1` → `0.2.3-beta.1` → `0.2.3-latest.1`) und pushen. `0.2.3-beta.2` baut kein Release, weil sich nur das
Repo geändert hat. Von Hand geht es auch (`git tag v0.2.4-beta.1 && git push --tags`), das löst `release.yml` direkt aus.

Was jetzt anstünde, zeigt `python3 tools/check.py --next-tag` (leer: nichts). Fehlt der CHANGELOG-Abschnitt für die Version
oder weichen TOC-Versionen ab, wird kein Tag gesetzt und der Lauf schlägt fehl. Bleibt die Version gleich, passiert
nichts. Gibt es ein Tag, aber noch kein Release (ein früherer Lauf ist gescheitert), wird nur das Release gebaut.

**CurseForge:** Die Projekt-ID steht als `## X-Curse-Project-ID` in der TOC (Glimpse 1730173, KeybindsTooltip 1730180,
Gathering 1730186, dort zusätzlich als `-p` im Packager-Schritt von `release.yml`, weil das Paket keine TOC im
Hauptordner hat). Hochgeladen wird nur, wenn das Repo-Secret `CF_API_KEY` gesetzt ist (GitHub: Settings > Secrets and
variables > Actions). Der Token gehört nie ins Repo. Hochgeladen werden nur beta (als Beta) und latest (als Release).

Erweiterungen, die neue Core-Funktionen brauchen, tragen `## X-Glimpse-MinVersion` in ihre TOC ein.
