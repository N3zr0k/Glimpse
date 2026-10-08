-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Credits-Bereich der Optionsseiten (Core/Options.lua)
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.GetMeta = function(_, key) return ({ Author = "N3zr0k", Title = "Glimpse: Test", Version = "1.0" })[key] end
    stub.load("Core/Options.lua", "Glimpse")
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Data.lua", "Glimpse")
    return Glimpse
end

test("Credits: Autor aus der TOC, Listen mit goldener Bezeichnung", function()
    local G = setup()
    local args = G:BuildCreditsArgs("Test", { contributors = { "Anna (Grafik)" }, images = { "Pin - Karacis (Flaticon)" }, thanks = { "Alle Tester" } }, 20)
    eq(args.creditsHeader.type, "header", "Trennlinie")
    eq(args.creditsHeader.order, 20, "Position")
    local text = args.credits.name()
    eq(text:find("|cffffd100Author:|r N3zr0k", 1, true) ~= nil, true, "Autor")
    eq(text:find("|cffffd100Contributors:|r\n- Anna (Grafik)", 1, true) ~= nil, true, "Mitwirkende")
    eq(text:find("|cffffd100Image credits:|r\n- Pin - Karacis (Flaticon)", 1, true) ~= nil, true, "Bildnachweis")
    eq(text:find("|cffffd100Special thanks:|r\n- Alle Tester", 1, true) ~= nil, true, "Dank")
end)

test("Credits: ohne Angaben Autor und der allgemeine Dank an die Tester", function()
    local G = setup()
    local text = G:BuildCreditsArgs("Test").credits.name()
    eq(text, "|cffffd100Author:|r N3zr0k\n\n|cffffd100Special thanks:|r\n- Flovy (Tester)\n- sMash (Tester)", "Autor, Tester")
end)

test("Credits: jede Seite hat Tabs, Credits ist immer der letzte", function()
    local G = setup()
    -- ohne tabs: die Optionen kommen in den Tab "Optionen"
    local plain = G:BuildAddonPage("Test", { a = { type = "toggle" } }, false, { images = { "x" } })
    eq(plain.childGroups, "tab", "Tabs")
    eq(plain.args.options.type, "group", "Tab Optionen")
    eq(plain.args.options.args.a.type, "toggle", "Optionen darin")
    eq(plain.args.creditsHeader, nil, "nichts über den Tabs")
    eq(plain.args.creditsTab.order > plain.args.options.order, true, "Credits zuletzt")
    eq(plain.args.creditsTab.args.creditsHeader.type, "header", "Trennlinie im Tab")
    eq(plain.args.creditsTab.args.credits.name():find("- x", 1, true) ~= nil, true, "Text im Tab")
    eq(plain.args.version, nil, "keine Versionszeile in der Seite (steht unter dem Rahmen)")

    -- mit tabs: die Gruppen bleiben, Credits kommt dazu
    local tabbed = G:BuildAddonPage("Test", { general = { type = "group", order = 1, args = {} }, other = { type = "group", order = 2, args = {} } }, true)
    eq(tabbed.args.general.args.credits, nil, "nicht mehr in Allgemein")
    eq(tabbed.args.creditsTab.order > tabbed.args.other.order, true, "letzter Tab")
    eq(tabbed.args.creditsTab.args.credits.name(), "|cffffd100Author:|r N3zr0k\n\n|cffffd100Special thanks:|r\n- Flovy (Tester)\n- sMash (Tester)", "Autor und Dank ohne weitere Angaben")
end)

test("Credits: der Kern hat den Tab ebenfalls, der Autor steht nur dort", function()
    local G = setup()
    _G.GetBuildInfo = function() return "1.0", "1", "date", 16001 end
    local overview = G:BuildOverview()
    eq(overview.args.info.name():find("N3zr0k", 1, true), nil, "Autor nicht im Kopf der Übersicht")
    eq(overview.args.creditsHeader, nil, "nicht in der Übersicht")
    G.BuildDistanceOptions = function() return { type = "select" } end
    G.BuildCombatOptions = function() return { type = "group" } end
    local options = G:BuildOptions()
    eq(options.args.credits.type, "group", "eigener Tab")
    eq(options.args.credits.order > 100, true, "nach Profile (Order 100)")
    eq(options.args.credits.args.credits.name():find("N3zr0k", 1, true) ~= nil, true, "Autor in den Credits")
end)
