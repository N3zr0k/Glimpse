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
Modules/             interne Module (Example als Vorlage, TooltipDebug)
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
Glimpse:GetMeta("Notes", "Glimpse_Keybinds") -- eine Erweiterung
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
`args` im Rahmen "Optionen", Version klein darunter. Mit `tabs = true` sind `args` keine Optionen, sondern
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

### Slash-Befehle (`Core/Commands.lua`)

```lua
Glimpse:RegisterCommand("name", "Beschreibung für /gli help", function(glimpse, args) ... end)
```

Ein Befehl pro Datei. Im Core liegen sie in `Commands/` und stehen in `Commands/Commands.xml`; eine
Erweiterung registriert ihren Befehl in einer eigenen Datei (siehe `Glimpse_Keybinds/Commands/`).

### Debug (`Core/Debug.lua`)

`Glimpse:IsDebug()`, `Glimpse:Debug(...)`, in Modulen `self:Debug(...)` (Ausgabe als `Glimpse(Modul): ...`,
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
lua tests/run.lua          # Logik-Tests mit nachgebauter WoW-Umgebung (Lua 5.4 reicht)
luacheck .                 # Konfiguration in .luacheckrc
python3 tools/check.py     # TOC, XML und Dateiverweise
```

Dasselbe läuft bei jedem Push in GitHub Actions (`.github/workflows/ci.yml`). Meldet luacheck eine
unbekannte Variable, ist es ein Tippfehler oder eine echte API-Funktion, die in `.luacheckrc` unter
`read_globals` fehlt.

## Veröffentlichen

1. Version in der TOC erhöhen (SemVer), Abschnitt im `CHANGELOG.md` ergänzen.
2. Committen, Tag setzen und pushen: `git tag v0.2.0 && git push --tags`.
3. `release.yml` prüft Tag, TOC-Version und CHANGELOG, baut das ZIP mit dem BigWigs-Packager und legt ein
   GitHub-Release an.

Erweiterungen, die neue Core-Funktionen brauchen, tragen `## X-Glimpse-MinVersion` in ihre TOC ein.
