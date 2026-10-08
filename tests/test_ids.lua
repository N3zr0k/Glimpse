-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

local function setup()
    local Glimpse = stub.newGlimpse()
    stub.load("Core/IDs.lua", "Glimpse")
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
