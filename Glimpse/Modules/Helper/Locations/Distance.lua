local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Locations = Glimpse:GetModule("Locations")

--- Yards zwischen zwei Punkten (0 bis 1) derselben Karte, nil bei unbekannter Kartengröße.
function Locations:GetMapDistance(map, x1, y1, x2, y2)
    local width, height = self:GetMapSize(map)
    if not width then return nil end

    local dx, dy = (x1 - x2) * width, (y1 - y2) * height
    return math.sqrt(dx * dx + dy * dy)
end

--- Luftlinie in Yards. Gleiche Karte über die Kartengröße, sonst über Weltpositionen (nur gleicher Kontinent).
function Locations:GetDistance(map1, x1, y1, map2, x2, y2)
    if type(map1) ~= "number" or type(map2) ~= "number" then return nil end
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" then return nil end

    if map1 == map2 then return self:GetMapDistance(map1, x1, y1, x2, y2) end

    local world1, a1, b1 = self:GetWorldPosition(map1, x1, y1)
    local world2, a2, b2 = self:GetWorldPosition(map2, x2, y2)
    if not world1 or world1 ~= world2 then return nil end

    local da, db = a1 - a2, b1 - b2
    return math.sqrt(da * da + db * db)
end

--- Yards vom Spieler zum Kartenpunkt, nil in Instanzen oder auf anderem Kontinent.
function Locations:GetDistanceFromPlayer(map, x, y)
    local position = self:GetPlayerPosition()
    if not position then return nil end
    return self:GetDistance(position.map, position.x, position.y, map, x, y)
end
