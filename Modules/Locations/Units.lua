local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L
local Locations = Glimpse:GetModule("Locations")

-- Entfernungen für alle Erweiterungen: Der Spielwert ist in Yards. Der Spieler wählt in den Glimpse-Optionen
-- (Allgemein), ob Yards oder Meter angezeigt werden, oder lässt es nach der Sprache seines Clients entscheiden.
-- Alle Erweiterungen zeigen Entfernungen dadurch einheitlich an.
--
-- Benutzung in einer Erweiterung:
--   Locations:FormatDistance(yards)   -> "120 yd", "1.3 mi", "91 m" oder "3,4 km"
--   Locations:GetDistanceUnit()       -> "yards" oder "meters" (für eigene Rechnungen)
-- Dieselben Funktionen gibt es auch direkt am Addon (Glimpse:FormatDistance), das ältere Erweiterungen benutzen.

-- Welches Maßsystem zu welcher Sprache des Spielclients passt (für distanceUnit = "auto"). Der Client kennt nur die
-- Sprache, nicht das Land: Yards und Meilen nutzen vor allem die USA und das Vereinigte Königreich, alle anderen
-- Sprachen des Spiels gehören zu Ländern mit metrischem System. Unbekannte Sprachen bekommen Yards, die Einheit des Spiels.
Locations.LOCALE_UNITS = {
    enUS = "yards", -- USA
    enGB = "yards", -- Vereinigtes Königreich
    deDE = "meters", -- Deutschland
    frFR = "meters", -- Frankreich
    esES = "meters", -- Spanien
    esMX = "meters", -- Mexiko und Lateinamerika
    itIT = "meters", -- Italien
    ptBR = "meters", -- Brasilien
    ruRU = "meters", -- Russland
    koKR = "meters", -- Südkorea
    zhCN = "meters", -- China
    zhTW = "meters", -- Taiwan
}

local YARDS_PER_MILE = 1760
local METERS_PER_YARD = 0.9144

--- Die Einheit der Entfernungen: "yards" oder "meters". Bei "auto" (Standard) nach der Sprache des Clients.
function Locations:GetDistanceUnit()
    local unit = Glimpse.db and Glimpse.db.profile.distanceUnit
    if unit == "yards" or unit == "meters" then return unit end
    return self.LOCALE_UNITS[GetLocale and GetLocale() or ""] or "yards"
end

--- Entfernung (in Yards, wie das Spiel sie liefert) als Text in der gewählten Einheit. Ab einer Meile (1760 yd)
-- bzw. einem Kilometer (1000 m) geht es in die nächste Einheit. Im Deutschen mit Dezimalkomma.
function Locations:FormatDistance(yards)
    local text
    if self:GetDistanceUnit() == "meters" then
        local meters = yards * METERS_PER_YARD
        if meters >= 1000 then
            text = format(L["%.1f km"], meters / 1000)
        else
            text = format(L["%d m"], math.floor(meters + 0.5))
        end
    elseif yards >= YARDS_PER_MILE then
        text = format(L["%.1f mi"], yards / YARDS_PER_MILE)
    else
        text = format(L["%d yd"], math.floor(yards + 0.5))
    end

    if GetLocale and GetLocale() == "deDE" then text = text:gsub("(%d)%.(%d)", "%1,%2") end
    return text
end

--- Optionen für die Einheit (für die Glimpse-Optionen)
function Locations:BuildDistanceOptions(order)
    return {
        type = "select", order = order or 10, width = "double",
        name = L["Distance unit"],
        desc = L["Unit for distances in all extensions. Automatic uses yards for English clients and metres for all other languages. From one mile (1760 yards) or one kilometre the larger unit is used."],
        values = function() return { auto = L["Automatic (by client language)"], yards = L["Yards"], meters = L["Meters"] } end,
        sorting = { "auto", "yards", "meters" },
        get = function() return Glimpse.db.profile.distanceUnit or "auto" end,
        set = function(_, value) Glimpse.db.profile.distanceUnit = value end,
    }
end

-- Kurzwege am Addon: der Kern und ältere Erweiterungen rufen sie darüber auf
Glimpse.LOCALE_UNITS = Locations.LOCALE_UNITS
function Glimpse:GetDistanceUnit() return Locations:GetDistanceUnit() end
function Glimpse:FormatDistance(yards) return Locations:FormatDistance(yards) end
function Glimpse:BuildDistanceOptions(order) return Locations:BuildDistanceOptions(order) end
