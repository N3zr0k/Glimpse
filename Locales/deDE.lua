local ADDON_NAME = ...

-- NewLocale liefert nil, wenn der Client nicht deDE ist. Dann ist hier nichts zu tun
-- und L bleibt auf Englisch.
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE")
if not L then return end

-- allgemein
L["General"] = "Allgemein"
L["Profiles"] = "Profile"
L["Options"] = "Optionen"
L["Overview"] = "Übersicht"
L["Installed extensions"] = "Installierte Erweiterungen"
L["No extensions installed."] = "Keine Erweiterungen installiert."
L["Not loaded"] = "Nicht geladen"
L["Requires Glimpse %s or newer"] = "Benötigt Glimpse %s oder neuer"

-- /glimpse info
L["Version"] = "Version"
L["Author"] = "Autor"
L["Notes"] = "Beschreibung"
L["Website"] = "Webseite"
L["License"] = "Lizenz"
L["Game version"] = "Spielversion"

-- Debug
L["Debug mode"] = "Debug-Modus"
L["Debug mode enabled"] = "Debug-Modus aktiviert"
L["Debug mode disabled"] = "Debug-Modus deaktiviert"
L["Prints additional diagnostic messages to chat."] = "Gibt zusätzliche Diagnose-Meldungen im Chat aus."
L["Target"] = "Ziel"
L["Data type"] = "Datentyp"
L["Tooltip frame"] = "Tooltip-Frame"
L["Secret fields"] = "Geschützte Felder"

-- Slash-Befehle
L["Available commands:"] = "Verfügbare Befehle:"
L["Unknown command: %s"] = "Unbekannter Befehl: %s"
L["Shows this help"] = "Zeigt diese Hilfe"
L["Shows addon information from the TOC"] = "Zeigt Addon-Informationen aus der TOC"
L["Opens the addon settings"] = "Öffnet die Addon-Einstellungen"
L["Toggles debug mode (on/off)"] = "Schaltet den Debug-Modus um (on/off)"
L["Only while a key is held"] = "Nur bei gedrückter Taste"
L["Show the tooltip additions only while the selected keys are held. If several are selected, all of them must be held. If none is selected, they are always shown."] = "Zeigt die Ergänzungen im Tooltip nur an, solange die gewählten Tasten gehalten werden. Sind mehrere gewählt, müssen alle gehalten werden. Ist keine gewählt, werden sie immer angezeigt."
L["Shift"] = "Umschalt"
L["Ctrl"] = "Strg"
L["Alt"] = "Alt"
