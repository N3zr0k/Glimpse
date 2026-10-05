local ADDON_NAME = ...

-- Default-Locale. Die Schlüssel sind der englische Text selbst, deshalb "= true".
-- Das letzte true (silent) sorgt dafür, dass fehlende Keys in anderen Sprachen
-- einfach den Key zurückgeben statt einen Fehler zu werfen.
local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", true, true)

-- allgemein
L["General"] = true
L["Profiles"] = true
L["Options"] = true
L["Overview"] = true
L["Installed extensions"] = true
L["No extensions installed."] = true
L["Not loaded"] = true
L["Requires Glimpse %s or newer"] = true

-- /glimpse info
L["Version"] = true
L["Author"] = true
L["Notes"] = true
L["Website"] = true
L["License"] = true
L["Game version"] = true

-- Debug
L["Debug mode"] = true
L["Debug mode enabled"] = true
L["Debug mode disabled"] = true
L["Prints additional diagnostic messages to chat."] = true
L["Target"] = true
L["Data type"] = true
L["Tooltip frame"] = true
L["Secret fields"] = true

-- Slash-Befehle
L["Available commands:"] = true
L["Unknown command: %s"] = true
L["Shows this help"] = true
L["Shows addon information from the TOC"] = true
L["Opens the addon settings"] = true
L["Toggles debug mode (on/off)"] = true
L["Only while a key is held"] = true
L["Show the tooltip additions only while the selected keys are held. If several are selected, all of them must be held. If none is selected, they are always shown."] = true
L["Shift"] = true
L["Ctrl"] = true
L["Alt"] = true
