-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- /gli probe db sources (Core/Debug/Sources.lua) mit einer nachgebauten Database
local function setup(namespaces)
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = false, debugOff = {} } }
    Glimpse.printed = {}
    function Glimpse:Print(text) self.printed[#self.printed + 1] = text end
    function Glimpse:Printf(text, ...) self:Print(format(text, ...)) end
    function Glimpse:AddLogLine() end
    _G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
    _G.strlower = string.lower
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Debug/Sources.lua", "Glimpse")

    _G.GlimpseDB = namespaces and {
        SOURCES = { "own", "imported", "baseline" },
        GetNamespaces = function()
            local list = {}
            for name in pairs(namespaces) do list[#list + 1] = name end
            table.sort(list)
            return list
        end,
        GetNamespaceInfo = function(_, name, detail)
            local info = namespaces[name]
            if info and not detail then info.kinds = nil end
            return info
        end,
    }
    _G.GlimpseStatisticsDB, _G.GlimpseGatheringDB = nil, nil
    return Glimpse
end

local function Output(G)
    local text = table.concat(G.printed, "\n")
    G.printed = {}
    return text
end

local function Has(text, part)
    return text:find(part, 1, true) ~= nil
end

local GATHERING = {
    area = "Gathering", loaded = true, writer = "Glimpse_GatheringDB",
    sources = { own = { total = 12, chars = 2 }, imported = { total = 30, chars = 1 } },
    places = { own = 5 }, adapters = { GatherMate2 = true },
}

test("Sources: Namespace mit Bereich, Schreiber und Herkünften", function()
    local G = setup({ gathering = GATHERING, travel = { area = "Core", loaded = true, sources = {}, places = {},
        adapters = {} } })
    G:RunProbe("db", "sources")
    local text = Output(G)
    eq(Has(text, "gathering|r: Gathering, writer Glimpse_GatheringDB"), true, "Kopf")
    eq(Has(text, "own 12 (2 chars), imported 30 (1 chars), places own 5, external GatherMate2 (active)"), true,
        "Herkünfte")
    eq(Has(text, "travel|r: Core, no writer"), true, "ohne Schreiber")
    eq(Has(text, "no data"), true, "leer")
end)

test("Sources: nicht geladener Bereich nennt den Grund", function()
    local G = setup({ fishing = { area = "Professions", loaded = false, reason = "DISABLED", sources = {}, places = {},
        adapters = {} } })
    G:RunProbe("db", "sources")
    eq(Has(Output(G), "Professions (not loaded: DISABLED)"), true, "Grund")
end)

test("Sources: alte SavedVariables und Angaben der Erweiterungen", function()
    local G = setup({})
    _G.GlimpseGatheringDB = {}
    G:RegisterDataSource("Glimpse_GatheringDB", function() return { "names: GlimpseGatheringNames" } end)
    G:RegisterDataSource("Glimpse_Broken", function() error("kaputt") end)
    G:RunProbe("db", "sources")
    local text = Output(G)
    eq(Has(text, "Old data GlimpseStatisticsDB: not loaded (addon not active)"), true, "Statistics fehlt")
    eq(Has(text, "Old data GlimpseGatheringDB: loaded"), true, "GatheringDB geladen")
    eq(Has(text, "Glimpse_GatheringDB|r: names: GlimpseGatheringNames"), true, "Erweiterung")
    eq(Has(text, "kaputt"), true, "Fehler einer Erweiterung wird gezeigt")
    eq(Has(text, "Glimpse: Database holds no data yet."), true, "leer")
end)

test("Sources: mit Namespace Summen je Art", function()
    local info = {}
    for key, value in pairs(GATHERING) do info[key] = value end
    info.kinds = { herb = { own = 10, imported = 30 }, skin = { own = 2 } }
    local G = setup({ gathering = info })
    G:RunProbe("db", "sources", "Gathering")
    local text = Output(G)
    eq(Has(text, "herb: own 10, imported 30"), true, "herb")
    eq(Has(text, "skin: own 2"), true, "skin")
    G:RunProbe("db", "sources", "nope")
    eq(Has(Output(G), "Unknown namespace: nope"), true, "unbekannt")
end)

test("Sources: ohne Database ein Hinweis", function()
    local G = setup(nil)
    G:RunProbe("db", "sources")
    eq(Has(Output(G), "Glimpse: Database is not installed"), true, "Hinweis")
end)
