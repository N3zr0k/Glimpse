# Glimpse: Entwickler-Dokumentation

Glimpse ist ein Ace3-Grundgerüst für Tooltip-Addons. Dieses Dokument beschreibt den Aufbau, die
Schnittstellen für Erweiterungen und die Arbeitsweise im Repo.

## Aufbau

```
Glimpse.toc          Einzige Quelle für Titel, Version, Notes, Icon (siehe unten)
Glimpse.xml          Zentrale Ladeliste, nur Include-Zeilen
Core/                Init, Debug, Options, Modifiers, Commands, Tooltip
Commands/            ein Slash-Befehl = eine Datei (Help, Info, Config, Debug)
Locales/             enUS (Default) und deDE, eingetragen in Locales.xml
Modules/             interne Module (Locations, Example als Vorlage, TooltipDebug)
Libs/                Ace3 (mitgeliefert, damit ein Klon sofort läuft)
tests/               Logik-Tests ohne WoW (lua tests/run.lua)
tools/check.py       Strukturprüfung von TOC und XML
```

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
(`## SavedVariables:`), nicht in `GlimpseDB`. Beispiel: GatheringDB.

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
}
```

Regeln, die der Core für dich übernimmt:

* **Eine Trennlinie** pro Tooltip, vor der ersten Zeile von irgendeiner Erweiterung.
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
`args` im ersten Tab "Optionen", dazu ein letzter Tab "Credits", die Version klein unter dem ganzen Rahmen. Mit `tabs = true` sind `args` keine Optionen, sondern
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

### Credits (`Glimpse:BuildCreditsArgs`)

Jede Optionsseite (und der Kern) hat einen letzten Tab "Credits" mit einem Bereich wie bei TomTom: Trennlinie mit Überschrift,
goldene Bezeichnungen, weißer Text. Der Autor kommt automatisch aus der TOC (`## Author`). Weitere Angaben übergibt die
Erweiterung als vierten Parameter von `RegisterAddonOptions(addonName, args, tabs, credits)`:

```lua
Glimpse:RegisterAddonOptions(ADDON_NAME, options, false, {
    contributors = { "Name (wofür)" },
    images = { "Pin - Autor (Flaticon)" },   -- Bildnachweis
    thanks = { "..." },
})
```

Der Tab "Credits" steht bei jeder Seite ganz hinten. Im Kern steht der Autor nur dort, nicht in der Übersicht.

### Slash-Befehle (`Core/Commands.lua`)

```lua
Glimpse:RegisterCommand("name", "Beschreibung für /gli help", function(glimpse, args) ... end)
```

Ein Befehl pro Datei. Im Core liegen sie in `Commands/` und stehen in `Commands/Commands.xml`; eine
Erweiterung registriert ihren Befehl in einer eigenen Datei (siehe `Glimpse_KeybindsTooltip/Commands/`).

### Debug (`Core/Debug.lua`)

`Glimpse:IsDebug()`, `Glimpse:SetDebug(enabled)`, `Glimpse:Debug(...)`, in Modulen `self:Debug(...)` (Ausgabe als `Glimpse(Modul): ...`,
nur bei aktivem Debug-Modus). Der Schalter ist im Profil gespeichert. Auch Tooltip-Provider sollten
Debug-Ausgaben vor dem Aufbau teurer Strings über `IsDebug()` absichern.

### Lokalisierung

Pro Addon ein Ordner `Locales/` mit `enUS.lua` (Default, `L["Text"] = true`) und weiteren Sprachen.
`NewLocale` gibt auf einem anderen Client `nil` zurück, die Datei bricht dann mit `if not L then return end`
ab. Neue Sprache: Datei kopieren und in `Locales.xml` eintragen.

### Gemeinsame Regeln

* Secret-Werte (`issecretvalue`) nie vergleichen, verketten oder als Schlüssel benutzen.
* Blizzard-Funktionen, die zwischen Client-Ständen wandern, über einen Alias mit Fallback ansprechen
  (`C_Item.GetItemInfoInstant or GetItemInfoInstant`).
* Eigene Daten nie in `GlimpseDB` außerhalb des eigenen Namespace ablegen.

## Prüfen

```
lua tests/run.lua          # Logik-Tests (Locations, Einheiten, Zusatztasten, Credits) mit nachgebauter WoW-Umgebung
luacheck .                 # Konfiguration in .luacheckrc
python3 tools/check.py     # TOC, XML und Dateiverweise
```

Dasselbe läuft bei jedem Push in GitHub Actions (`.github/workflows/ci.yml`). Meldet luacheck eine
unbekannte Variable, ist es ein Tippfehler oder eine echte API-Funktion, die in `.luacheckrc` unter
`read_globals` fehlt.

## Veröffentlichen

1. Version in der TOC erhöhen (SemVer), Abschnitt `## [x.y.z]` im `CHANGELOG.md` ergänzen.
2. Auf `main` pushen. Ist die Pipeline (Struktur, luacheck, Tests) grün und gibt es zur TOC-Version noch
   kein Tag, setzt `ci.yml` das Tag `vX.Y.Z` selbst und startet `release.yml` darauf (workflow_dispatch).
3. `release.yml` prüft Tag, TOC-Version und CHANGELOG, baut das ZIP mit dem BigWigs-Packager und legt ein
   GitHub-Release an.

Steht im CHANGELOG noch kein Abschnitt für die Version, aber `## [Unreleased]`, entsteht stattdessen
eine Vorabversion `vX.Y.Z-beta.1` (der Packager markiert sie als Prerelease). Pro Version gibt es nur
eine solche Vorabversion; das richtige Release folgt, sobald der Abschnitt `## [X.Y.Z]` im CHANGELOG steht.

Fehlt beides oder weichen TOC-Versionen ab, wird kein Tag gesetzt und der Lauf schlägt
fehl. Bleibt die Version gleich, passiert nichts. Ein von Hand gepushtes Tag (`git tag v0.2.2 && git push
--tags`) löst `release.yml` weiterhin direkt aus.

Erweiterungen, die neue Core-Funktionen brauchen, tragen `## X-Glimpse-MinVersion` in ihre TOC ein.
