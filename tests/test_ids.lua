-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

local function setup()
    local Glimpse = stub.newGlimpse()
    stub.load("Core/IDs.lua", "Glimpse")
    stub.load("Core/IDsNames.lua", "Glimpse")
    return Glimpse, Glimpse.IDs
end

test("IDs: NPC aus der GUID", function()
    local _, IDs = setup()
    eq(IDs:NPCFromGUID("Creature-0-3131-2552-14367-179891-0000A5C2B1"), 179891, "Kreatur")
    eq(IDs:NPCFromGUID("Player-1-00000001"), nil, "Spieler")
    eq(IDs:NPCFromGUID(nil), nil, "nil")
end)

test("IDs: Item beschreiben, auch aus dem Cache nachgeladen", function()
    local _, IDs = setup()
    local names = {}
    IDs.api = { GetItemNameByID = function(id) return names[id] end }
    names[2589] = "Leinenstoff"
    local text
    IDs:DescribeItem(2589, function(t) text = t end)
    eq(text, "Leinenstoff [2589]", "sofort")

    local waiting
    IDs.api.CreateItem = function()
        return { IsItemEmpty = function() return false end, ContinueOnItemLoad = function(_, f) waiting = f end }
    end
    IDs:DescribeItem(4306, function(t) text = t end)
    names[4306] = "Seidenstoff"
    waiting()
    eq(text, "Seidenstoff [4306]", "nachgeladen")
end)

test("IDs: Zone in Instanzen negativ", function()
    local G, IDs = setup()
    G.modules.Locations = {
        GetPlayerArea = function() return { instance = 36, name = "Todesminen" } end,
        GetMapName = function() end,
    }
    eq(IDs:ZoneKey(), -36, "Instanz")
    G.modules.Locations.GetPlayerArea = function() return { map = 1429, x = 0.4, y = 0.5 } end
    eq(IDs:ZoneKey(), 1429, "Karte")
    local map, x = IDs:Where()
    eq(map, 1429, "Where Karte")
    eq(x, 0.4, "Where x")
end)

test("IDs: Namen lernen und lesen", function()
    local _, IDs = setup()
    local labels, writes = {}, 0
    _G.GlimpseDB = { Register = function()
        return {
            SetLabel = function(_, kind, id, name) writes = writes + 1; labels[kind .. id] = name end,
            GetLabel = function(_, kind, id) return labels[kind .. id] end,
        }
    end }
    IDs.api.UnitGUID = function() return "Creature-0-1-2-3-299-0000A5C2B1" end
    IDs.api.UnitName = function() return "Wolf" end

    eq(IDs:LearnUnit("target"), true, "gelernt")
    eq(IDs:LearnUnit("target"), false, "schon bekannt")
    eq(writes, 1, "nur ein Schreibzugriff")
    eq(IDs:NPCName(299), "Wolf", "NPC")
    eq(IDs:NPCName(5), nil, "unbekannt")

    eq(IDs:LearnName("object", 1731, "Kupfervorkommen"), true, "Objekt")
    eq(IDs:ObjectName(1731), "Kupfervorkommen", "Objektname")
    eq(IDs:LearnName("quest", 1, "x"), false, "unbekannte Art")
    eq(IDs:LearnName("npc", 2, ""), false, "leerer Name")

    IDs:ForgetNames()
    eq(IDs:NPCName(299), "Wolf", "aus Database nachgeladen")
    _G.GlimpseDB = nil
end)
