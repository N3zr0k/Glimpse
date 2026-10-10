-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Entfernungen für alle Erweiterungen (Modules/Helper/Locations)
local function setup(unit)
    local Glimpse = stub.newGlimpse()
    Glimpse.db = { profile = { distanceUnit = unit } }
    stub.loadLocations()
    return Glimpse
end

test("Einheiten: Yards, ab einer Meile Meilen", function()
    local G = setup("yards")
    eq(G:FormatDistance(120), "120 yd", "Yards")
    eq(G:FormatDistance(1000), "1000 yd", "1000 Yards bleiben Yards")
    eq(G:FormatDistance(1759), "1759 yd", "knapp unter einer Meile")
    eq(G:FormatDistance(1760), "1.0 mi", "ab einer Meile")
    eq(G:FormatDistance(2300), "1.3 mi", "Meilen")
end)

test("Einheiten: Meter, ab 1000 m Kilometer", function()
    local G = setup("meters")
    eq(G:FormatDistance(100), "91 m", "Meter (1 yd = 0,9144 m)")
    eq(G:FormatDistance(1093), "999 m", "knapp unter einem Kilometer")
    eq(G:FormatDistance(1094), "1.0 km", "ab 1000 Kilometer")
    eq(G:FormatDistance(3690), "3.4 km", "Kilometer")

    _G.GetLocale = function() return "deDE" end
    eq(G:FormatDistance(3690), "3,4 km", "Dezimalkomma im Deutschen")
    _G.GetLocale = nil
end)

test("Einheiten: automatisch nach der Sprache des Clients", function()
    local G = setup(nil)
    local realLocale = _G.GetLocale
    for locale, unit in pairs({ enUS = "yards", enGB = "yards", deDE = "meters", frFR = "meters", koKR = "meters", zhTW = "meters", xxXX = "yards" }) do
        _G.GetLocale = function() return locale end
        eq(G:GetDistanceUnit(), unit, locale)
    end

    _G.GetLocale = function() return "deDE" end
    G.db.profile.distanceUnit = "yards"
    eq(G:GetDistanceUnit(), "yards", "feste Auswahl gilt vor der Sprache")
    G.db.profile.distanceUnit = "auto"
    eq(G:FormatDistance(100), "91 m", "automatisch in Metern im deutschen Client")
    _G.GetLocale = realLocale
end)

test("Einheiten: die Option schreibt ins Profil", function()
    local G = setup(nil)
    local option = G:BuildDistanceOptions(2)
    eq(option.get(), "auto", "Standard")
    option.set(nil, "meters")
    eq(G.db.profile.distanceUnit, "meters", "gesetzt")
    eq(option.get(), "meters", "gelesen")
    eq(option.values().auto ~= nil, true, "Eintrag Automatisch")
end)
