-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Debugger mit Kategorien, Log und Probes (Core/Debug)
local function setup(debug)
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = debug, debugOff = {} } }
    Glimpse.printed = {}
    function Glimpse:Print(text) self.printed[#self.printed + 1] = text end
    function Glimpse:Printf(text, ...) self:Print(format(text, ...)) end
    _G.date = os.date
    _G.strjoin = function(sep, ...) return table.concat({ ... }, sep) end
    _G.tostringall = function(...) local t = { ... } for i = 1, select("#", ...) do t[i] = tostring(t[i]) end return (table.unpack or unpack)(t, 1, select("#", ...)) end
    _G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    Glimpse.GetMeta = function(_, key, addon)
        if key == "Title" then return ({ Glimpse = "Glimpse", Glimpse_Professions = "Glimpse: Professions" })[addon or "Glimpse"] end
    end
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/DebugTag.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    return Glimpse
end

test("Debugger: nur im Debug-Modus, Fehler immer", function()
    local G = setup(false)
    local debug = G:NewDebugger("Professions", { "lure" })
    debug:Log("lure", "nichts")
    eq(#G.printed, 0, "aus")
    debug:Error("lure", "kaputt %d", 1)
    eq(#G.printed, 1, "Fehler sichtbar")
    eq(G.printed[1]:find("[|cff6a9fd4Glimpse|r] ", 1, true) == 1, true, "Addon-Kennung blau vorn")
    eq(G.printed[1]:find("Professions/lure: kaputt 1", 1, true) ~= nil, true, "Format")
end)

test("Debugger: Kategorie einzeln abschalten", function()
    local G = setup(true)
    local debug = G:NewDebugger("Professions", { "lure", "fishing" })
    debug:SetCategory("lure", false)
    debug:Log("lure", "aus")
    debug:Log("fishing", "an")
    eq(#G.printed, 1, "nur fishing")
    eq(G:NewDebugger("Professions"), debug, "gleicher Name, gleicher Debugger")
end)

test("Debugger: gleiche Zeilen werden zusammengefasst", function()
    local G = setup(true)
    local debug = G:NewDebugger("Combat", { "kill" })
    for _ = 1, 5 do debug:Log("kill", "gleich") end
    eq(#G.printed, 1, "einmal ausgegeben")
    debug:Log("kill", "anders")
    eq(#G.printed, 3, "Zähler und neue Zeile")
    eq(G.printed[2]:find("(4x)", 1, true) ~= nil, true, "Wiederholungen")
end)

test("Log: Ringpuffer behält die letzten 500 Zeilen", function()
    local G = setup(true)
    for i = 1, 520 do G:AddLogLine("Zeile " .. i) end
    local lines = G:GetLogLines()
    eq(#lines, 500, "Größe")
    eq(lines[1]:find("Zeile 21$") ~= nil, true, "älteste")
    eq(lines[500]:find("Zeile 520$") ~= nil, true, "neueste")
end)

test("Probes: anmelden, ausführen, Fehler abfangen", function()
    local G = setup(false)
    G:RegisterProbe("prof", "lure", function(args) return { "Köder " .. args } end, "Köder")
    G:RegisterProbe("prof", "bad", function() error("kaputt") end)
    G:RunProbe("PROF", "lure", "x")
    eq(G.printed[1], "[|cff6a9fd4Glimpse|r] prof/lure: Köder x", "Ausgabe")
    G:RunProbe("prof", "bad")
    eq(G.printed[2]:find("kaputt", 1, true) ~= nil, true, "Fehler als Zeile")
end)

test("Debug-Kennung: Addon aus dem Aufrufstapel, im Log ohne Farbe", function()
    local G = setup(true)
    _G.debugstack = function() return [[Interface/AddOns/Glimpse_Professions/Modules/Fishing/Fishing.lua:12: in function]] end
    local debug = G:NewDebugger("Fishing", { "cast" })
    _G.debugstack = nil
    eq(debug.addon, "Glimpse_Professions", "Addon beim Anlegen gemerkt")
    debug:Log("cast", "Wurf")
    eq(G.printed[1], "[Glimpse: |cff6a9fd4Professions|r] |cff9d9d9dFishing/cast: Wurf|r", "Chat")
    local lines = G:GetLogLines()
    eq(lines[#lines]:find("[Glimpse: Professions] Fishing/cast: Wurf", 1, true) ~= nil, true, "Log ohne Farbcodes")
    eq(G:DebugTag("Glimpse_Professions", true), "[Glimpse: Professions]", "ohne Farbe")
end)

test("Debug-Kennung: Glimpse:Debug zeigt das aufrufende Addon", function()
    local G = setup(true)
    _G.debugstack = function() return [[Interface\AddOns\Glimpse_Professions\Core\Professions.lua:5: in main chunk]] end
    G:Debug("Hallo", 1)
    _G.debugstack = nil
    eq(G.printed[1], "[Glimpse: |cff6a9fd4Professions|r] |cff9d9d9dHallo 1|r", "Chat")
end)
