-- luacheck: ignore 113
local stub = require("wowstub")

test("Koordinaten verpacken", function()
    local DB = stub.load()
    eq(DB:PackXY(0.4123, 0.5678), 41235678, "verpackt")
    local x, y = DB:UnpackXY(41235678)
    near(x, 0.4123, "x")
    near(y, 0.5678, "y")
    eq(DB:PackXY(1.2, -0.1), 99990000, "begrenzt")
end)

test("Orte schreiben und finden", function()
    local DB = stub.load()
    local ns = DB:Register("gathering", { area = "Gathering" })
    ns:AddLocation(1617, 1429, 0.4, 0.5)
    ns:AddLocation(1618, 1429, 0.6, 0.5)
    ns:AddLocation(1617, 12, 0.1, 0.1)
    eq(#ns:GetLocations(1429), 2, "pro Karte")
    eq(#ns:GetLocations(nil, 1617), 2, "pro ID")
    eq(ns:GetLocations(12)[1].source, "own", "Herkunft")
end)

test("Adapter nur auf Wunsch", function()
    local DB = stub.load()
    local ns = DB:Register("gathering", { area = "Gathering" })
    DB:RegisterAdapter("gathering", "GatherMate2", {
        GetLocations = function(_, _, add) add(1429, 0.3, 0.3, 1617) end,
        GetCount = function() return 10 end,
    })
    eq(#ns:GetLocations(1429), 0, "ohne external")
    local list = ns:GetLocations(1429, nil, { sources = { "own", "external" } })
    eq(list[1].source, "external:GatherMate2", "mit external")
    eq(ns:GetCount("node", 1, { sources = "external:GatherMate2" }), 10, "Zähler")
end)
