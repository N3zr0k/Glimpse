-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Credits der Suite, einmal in der Core-Übersicht (Core/Options/Credits.lua)
local function setup()
    local Glimpse = stub.newGlimpse()
    local titles = { Glimpse_Gathering = "Glimpse: Gathering", Glimpse_Statistics = "Glimpse: Statistics",
        Glimpse_Test = "Glimpse: Test" }
    Glimpse.GetMeta = function(_, key, addonName)
        if key == "Title" and addonName then return titles[addonName] end
        return ({ Author = "N3zr0k", Title = "Glimpse", Version = "1.0" })[key]
    end
    stub.load("Core/Options/Options.lua", "Glimpse")
    stub.load("Core/Options/Credits.lua", "Glimpse")
    stub.load("Core/Debug/DebugTag.lua", "Glimpse")
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Options/Data.lua", "Glimpse")
    _G.GetBuildInfo = function() return "1.0", "1", "date", 16001 end
    return Glimpse
end

test("Credits: Autor, Bildnachweise der Erweiterungen und Dank", function()
    local G = setup()
    local args = G:BuildCreditsArgs(20)
    eq(args.creditsHeader.type, "header", "Trennlinie")
    eq(args.creditsHeader.order, 20, "Position")
    local text = args.credits.name()
    eq(text:find("|cffffd100Author:|r N3zr0k", 1, true) ~= nil, true, "Autor")
    eq(text:find("- Glimpse: Gathering: Pin - Karacis (Flaticon) |cff66ccff(https://www.flaticon.com/de/kostenloses-icon/ort_5338544)|r", 1, true) ~= nil, true, "Gathering")
    eq(text:find("- Glimpse: Statistics: Analytics - Pixel perfect (Flaticon)", 1, true) ~= nil, true, "Statistics")
    eq(text:find("|cffffd100Special thanks:|r\n- Flovy (Tester)\n- sMash (Tester)", 1, true) ~= nil, true, "Dank")
end)

test("Credits: Angaben einer Erweiterung erscheinen in der Übersicht, bekannte Links nicht doppelt", function()
    local G = setup()
    G:AddCredits("Glimpse_Test", { contributors = { "Anna (Grafik)" } })
    G:AddCredits("Glimpse_Gathering", { images = { "Stecknadel - Karacis |cff66ccff(https://www.flaticon.com/de/kostenloses-icon/ort_5338544)|r" } })
    local text = G:BuildCreditsArgs().credits.name()
    eq(text:find("|cffffd100Contributors:|r\n- Glimpse: Test: Anna (Grafik)", 1, true) ~= nil, true, "Mitwirkende")
    eq(text:find("Stecknadel", 1, true), nil, "Link schon bekannt")
end)

test("Credits: nur in der Core-Übersicht, nicht auf den Seiten der Erweiterungen", function()
    local G = setup()
    local plain = G:BuildAddonPage("Glimpse_Test", { a = { type = "toggle" } }, false, { images = { "x" } })
    eq(plain.args.options.args.a.type, "toggle", "Optionen im Tab")
    eq(plain.args.creditsTab, nil, "kein Credits-Tab")
    eq(G:BuildCreditsArgs().credits.name():find("- Glimpse: Test: x", 1, true) ~= nil, true, "Angabe in der Übersicht")

    local tabbed = G:BuildAddonPage("Glimpse_Test", { general = { type = "group", order = 1, args = {} } }, true)
    eq(tabbed.args.creditsTab, nil, "auch mit Tabs keiner")

    local overview = G:BuildOverview()
    eq(overview.args.creditsHeader.type, "header", "Trennlinie in der Übersicht")
    eq(overview.args.creditsHeader.order > overview.args.extensions.order, true, "unter den Erweiterungen")
    G.BuildDistanceOptions = function() return { type = "select" } end
    G.BuildCombatOptions = function() return { type = "group" } end
    G.BuildDoubleClickOptions = function() return { type = "group" } end
    eq(G:BuildOptions().args.credits, nil, "kein eigener Credits-Tab im Core")
end)
