local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Locations = Glimpse:GetModule("Locations")
local Clean = Locations.Clean

--- Die Instanz, in der der Spieler ist: { instance (instanceID), name } oder nil in der offenen Welt (oder
-- wenn sie sich nicht bestimmen lässt). Dort gibt es keine brauchbaren Koordinaten, die Instanz selbst
-- ist der Ort.
function Locations:GetPlayerInstance()
    local isInside, getInfo = self.api.IsInInstance, self.api.GetInstanceInfo
    if not isInside or not getInfo then return nil end

    local inside, kind = isInside()
    inside, kind = Clean(inside), Clean(kind)
    if not inside or kind == "none" then return nil end

    -- GetInstanceInfo: Name, Art, Schwierigkeit, Schwierigkeitsname, Größe, dynamisch, ?, Instanz-ID ...
    local name, _, _, _, _, _, _, instanceID = getInfo()
    name, instanceID = Clean(name), Clean(instanceID)
    if type(instanceID) ~= "number" or instanceID < 1 then return nil end

    return { instance = instanceID, name = type(name) == "string" and name or nil }
end

--- Position des Spielers in der offenen Welt: { map (uiMapID), x, y (0 bis 1) } oder nil, wenn sie sich
-- nicht bestimmen lässt (Instanzen, keine Kartenfunktionen, geschützte Werte).
function Locations:GetPlayerPosition()
    local get, best = self.api.GetPlayerMapPosition, self.api.GetBestMapForUnit
    if not get or not best then return nil end
    if self:GetPlayerInstance() then return nil end

    local map = Clean(best("player"))
    if type(map) ~= "number" or map < 1 then return nil end

    local position = get(map, "player")
    if not position or not position.GetXY then return nil end

    local x, y = position:GetXY()
    x, y = Clean(x), Clean(y)
    -- (0, 0) heißt: keine Position bekannt
    if type(x) ~= "number" or type(y) ~= "number" or x <= 0 or y <= 0 or x > 1 or y > 1 then return nil end

    return { map = map, x = x, y = y }
end

--- Wo der Spieler gerade ist: { instance, name } in einer Instanz, sonst { map, x, y }, oder nil, wenn sich
-- beides nicht bestimmen lässt.
function Locations:GetPlayerArea()
    return self:GetPlayerInstance() or self:GetPlayerPosition()
end

--- Der Ort als kurzer Text für die Debug-Ausgabe: "Instanz Die Todesminen (36)" oder
-- "Karte Elwynn (37) 41.2 / 56.8" (Koordinaten in Prozent), oder nil ohne Ort.
function Locations:DescribeArea(area)
    if type(area) ~= "table" then return nil end

    if area.instance then
        return format("Instanz %s (%d)", tostring(area.name or "?"), area.instance)
    end
    if type(area.map) == "number" and type(area.x) == "number" and type(area.y) == "number" then
        return format("Karte %s (%d) %.1f / %.1f", tostring(self:GetMapName(area.map) or "?"), area.map, area.x * 100, area.y * 100)
    end
end
