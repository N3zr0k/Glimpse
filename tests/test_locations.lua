-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

local function vector(a, b)
    return { GetXY = function() return a, b end }
end

local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.db = { profile = {} }
    _G.CreateVector2D = function(x, y) return vector(x, y) end
    _G.GetLocale = nil
    local Locations = stub.loadLocations()
    return Glimpse, Locations
end

-- Zwei Karten (10 und 11) auf Kontinent 1, Karte 20 auf Kontinent 2
local function maps(Locations)
    local info = {
        [10] = { name = "Zone A", mapType = 3, parentMapID = 1 },
        [11] = { name = "Zone B", mapType = 3, parentMapID = 1 },
        [20] = { name = "Zone C", mapType = 3, parentMapID = 2 },
        [1] = { name = "Kontinent 1", mapType = 2, parentMapID = 0 },
        [2] = { name = "Kontinent 2", mapType = 2, parentMapID = 0 },
    }
    Locations.api.GetMapInfo = function(map) return info[map] end
    Locations.api.GetMapWorldSize = function(map)
        if map == 10 then return 1000, 500 end
    end
    -- Karte 11 liegt 2000 Yards "unter" Karte 10; Karte 11 hat keine Größe, nur Weltpositionen
    Locations.api.GetWorldPosFromMapPos = function(map, point)
        local x, y = point:GetXY()
        if map == 10 then return 100, vector(1000 - y * 500, 1000 - x * 1000) end
        if map == 11 then return 100, vector(3000 - y * 400, 600 - x * 600) end
        if map == 20 then return 200, vector(0, 0) end
    end
end

test("Locations: Kartenname, Größe und Kontinent", function()
    local _, L = setup()
    maps(L)
    eq(L:GetMapName(10), "Zone A", "Name")
    eq(L:GetMapName(99), nil, "unbekannt")
    local w, h = L:GetMapSize(10)
    eq(w, 1000, "Breite") eq(h, 500, "Höhe")
    -- Größe aus Weltpositionen (Ecke und Mitte, verdoppelt)
    w, h = L:GetMapSize(11)
    eq(w, 600, "Breite aus Weltposition") eq(h, 400, "Höhe aus Weltposition")
    eq(L:GetContinent(10), 1, "Kontinent")
    eq(L:GetContinent(20), 2, "anderer Kontinent")
    eq(L:GetContinent(1), 1, "Kontinent einer Kontinentkarte")
    eq(L:GetContinent(99), nil, "unbekannt")
end)

test("Locations: Entfernungen", function()
    local _, L = setup()
    maps(L)
    near(L:GetDistance(10, 0, 0, 10, 0.5, 0), 500, "gleiche Karte")
    near(L:GetDistance(10, 0, 0, 10, 0, 1), 500, "gleiche Karte, Höhe")
    local d = L:GetDistance(10, 0, 0, 11, 0, 0)
    eq(d ~= nil, true, "gleicher Kontinent hat Entfernung")
    eq(L:GetDistance(10, 0, 0, 20, 0, 0), nil, "anderer Kontinent")
    eq(L:GetDistance(10, 0, 0, nil, 0, 0), nil, "ungültig")
    eq(L:GetDistance(10, nil, 0, 10, 0, 0), nil, "ungültige Koordinate")
    L.api.GetMapWorldSize, L.api.GetWorldPosFromMapPos = nil, nil
    L:ResetCaches()
    eq(L:GetMapDistance(10, 0, 0, 1, 1), nil, "ohne Größe keine Entfernung")
end)

test("Locations: Position und Instanz", function()
    local _, L = setup()
    maps(L)
    local inside, instanceID = false, 36
    L.api.IsInInstance = function() return inside, inside and "party" or "none" end
    L.api.GetInstanceInfo = function() return "Die Todesminen", "party", 1, "", 5, 0, false, instanceID end
    L.api.GetBestMapForUnit = function() return 10 end
    L.api.GetPlayerMapPosition = function() return vector(0.4, 0.6) end

    local pos = L:GetPlayerPosition()
    eq(pos.map, 10, "Karte") near(pos.x, 0.4, "x") near(pos.y, 0.6, "y")
    eq(L:GetPlayerInstance(), nil, "nicht in einer Instanz")
    eq(L:GetPlayerArea().map, 10, "Gebiet ist die Karte")
    eq(L:DescribeArea(pos), "Karte Zone A (10) 40.0 / 60.0", "Beschreibung Karte")
    near(L:GetDistanceFromPlayer(10, 0.9, 0.6), 500, "Entfernung vom Spieler")

    inside = true
    eq(L:GetPlayerInstance().instance, 36, "Instanz")
    eq(L:GetPlayerPosition(), nil, "in Instanzen keine Position")
    eq(L:GetPlayerArea().instance, 36, "Gebiet ist die Instanz")
    eq(L:DescribeArea(L:GetPlayerArea()), "Instanz Die Todesminen (36)", "Beschreibung Instanz")
    eq(L:GetDistanceFromPlayer(10, 0.9, 0.6), nil, "in Instanzen keine Entfernung")

    inside = false
    L.api.GetPlayerMapPosition = function() return vector(0, 0) end
    eq(L:GetPlayerPosition(), nil, "(0, 0) ist keine Position")
    L.api = {}
    eq(L:GetPlayerArea(), nil, "ohne Funktionen kein Gebiet")
end)

test("Locations: Koordinaten als Text", function()
    local _, L = setup()
    eq(L:FormatCoords(0.412, 0.568), "41.2, 56.8", "Prozent")
    eq(L:FormatCoords(0.412, 0.568, 0), "41, 57", "ohne Nachkommastellen")
    eq(L:FormatCoords(nil, 0.5), nil, "ungültig")
    _G.GetLocale = function() return "deDE" end
    eq(L:FormatCoords(0.412, 0.568), "41,2, 56,8", "Dezimalkomma")
    _G.GetLocale = nil
end)

test("Locations: Wegpunkt", function()
    local _, L = setup()
    eq(L:SetWaypoint(nil, 0.5, 0.5), false, "ohne Karte")
    eq(L:SetWaypoint(10, 0, 0.5), false, "ungültige Koordinate")
    eq(L:SetWaypoint(10, 0.5, 0.5), false, "ohne TomTom und Markierung")

    local added
    _G.TomTom = { AddWaypoint = function(_, map, x, y, opts) added = { map, x, y, opts.title } return {} end }
    eq(L:SetWaypoint(10, 0.4, 0.6, "Kupfer"), true, "mit TomTom")
    eq(added[1], 10, "Karte") eq(added[4], "Kupfer", "Titel")

    _G.TomTom = nil
    local set, tracked
    _G.UiMapPoint = { CreateFromCoordinates = function(map, x, y) return { map, x, y } end }
    _G.C_Map = { CanSetUserWaypointOnMap = function() return true end, SetUserWaypoint = function(p) set = p end }
    _G.C_SuperTrack = { SetSuperTrackedUserWaypoint = function(v) tracked = v end }
    eq(L:SetWaypoint(10, 0.4, 0.6, "Kupfer"), true, "mit Spielmarkierung")
    eq(set[1], 10, "Markierung gesetzt") eq(tracked, true, "verfolgt")
    _G.C_Map, _G.UiMapPoint, _G.C_SuperTrack = nil, nil, nil
end)
