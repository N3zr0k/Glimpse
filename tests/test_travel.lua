-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Modul Reisen (Modules/Travel) mit falscher Position und einem Namespace, der nur mitschreibt
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = false, debugOff = {} } }
    _G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    _G.LibStub = function() return { GetAddon = function() return Glimpse end } end
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Data.lua", "Glimpse")
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Core/IDs.lua", "Glimpse")
    for _, file in ipairs({ "Travel", "TravelDistance", "TravelZones" }) do
        stub.load("Modules/Travel/" .. file .. ".lua", "Glimpse")
    end

    local zone = { map = 1429 }
    Glimpse.modules.Locations = { GetPlayerArea = function() return zone end, GetMapName = function() end }

    local pos = { x = 0, y = 0, instance = 0 }
    local state = { mounted = false }
    local Travel = Glimpse.modules.Travel
    -- Die Dateien halten die Tabelle als Upvalue, daher füllen statt ersetzen
    for key, value in pairs({
        GetTime = function() return stub.now end,
        UnitOnTaxi = function() return false end,
        UnitIsGhost = function() return false end,
        IsSwimming = function() return false end,
        IsMounted = function() return state.mounted end,
        HBD = {
            GetPlayerWorldPosition = function() return pos.x, pos.y, pos.instance end,
            GetWorldDistance = function(_, _, x1, y1, x2, y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end,
        },
    }) do Travel.api[key] = value end

    local counts = {}
    local ns = { Count = function(_, kind, id, _, amount) counts[#counts + 1] = { kind = kind, id = id, amount = amount or 1 } end }
    _G.CreateFrame = function() return { SetScript = function() end } end
    _G.GlimpseDB = { Register = function() return ns end }
    Travel:OnInitialize()
    Travel:OnEnable()
    _G.GlimpseDB = nil
    return Travel, counts, pos, state, zone
end

local function Sum(counts, kind, id)
    local total = 0
    for _, entry in ipairs(counts) do
        if entry.kind == kind and (id == nil or entry.id == id) then total = total + entry.amount end
    end
    return total
end

test("Reisen: Strecke je Fortbewegungsart", function()
    local Travel, counts, pos, state = setup()
    Travel:Measure()
    for i = 1, 4 do
        stub.now = i * 0.5
        pos.x = i * 3
        Travel:Measure()
    end
    state.mounted = true
    stub.now = 2.5
    pos.x = 20
    Travel:Measure()
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.walk), 12, "gelaufen")
    eq(Sum(counts, "distance", Travel.MODES.mount), 8, "geritten")
end)

test("Reisen: Sprünge und Kontinentwechsel zählen nicht", function()
    local Travel, counts, pos = setup()
    Travel:Measure()
    stub.now = 0.5
    pos.x = 500
    eq(Travel:Measure(), 0, "Teleport")
    stub.now = 1
    pos.instance = 1
    pos.x = 510
    eq(Travel:Measure(), 0, "anderer Kontinent")
    Travel:FlushDistance()
    eq(Sum(counts, "distance"), 0, "nichts gezählt")
end)

test("Reisen: Zone betreten und Aufenthaltsdauer", function()
    local Travel, counts, _, _, zone = setup()
    eq(Sum(counts, "zone", 1429), 1, "beim Start betreten")
    stub.now = 90
    zone.map = 1411
    Travel:UpdateZone()
    eq(Sum(counts, "zonetime", 1429), 90, "Sekunden")
    eq(Sum(counts, "zone", 1411), 1, "neue Zone")
    Travel:UpdateZone()
    eq(Sum(counts, "zone", 1411), 1, "gleiche Zone zählt nicht erneut")
end)
