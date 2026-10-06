local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Locations = Glimpse:GetModule("Locations")

-- Karten: Name, Größe in Yards, Kontinent und Weltposition. Größe und Kontinent werden je Karte gemerkt.
local mapSizes, continents = {}, {}

local function PositiveNumber(value)
    return type(value) == "number" and value == value and value > 0 and value < 1e7
end

local function ReadMapSize(api, map)
    -- Blizzard kennt die Größe direkt (nicht in jedem Client)
    if api.GetMapWorldSize then
        local width, height = api.GetMapWorldSize(map)
        if PositiveNumber(width) and PositiveNumber(height) then return width, height end
    end

    -- sonst aus zwei Weltpositionen der Karte: Ecke oben links und Mitte, Strecke verdoppelt
    -- (die Ecke unten rechts wird auf manchen Karten ungenau umgerechnet)
    if api.GetWorldPosFromMapPos and CreateVector2D then
        local _, corner = api.GetWorldPosFromMapPos(map, CreateVector2D(0, 0))
        local _, center = api.GetWorldPosFromMapPos(map, CreateVector2D(0.5, 0.5))
        if corner and center then
            -- Weltkoordinaten: die erste Zahl läuft in Kartenrichtung "oben", die zweite "links"
            local top, left = corner:GetXY()
            local middleTop, middleLeft = center:GetXY()
            local width, height = math.abs(left - middleLeft) * 2, math.abs(top - middleTop) * 2
            if PositiveNumber(width) and PositiveNumber(height) then return width, height end
        end
    end
end

--- Name einer Karte (Zone) oder nil.
function Locations:GetMapName(map)
    local get = self.api.GetMapInfo
    if not get or type(map) ~= "number" then return nil end
    local ok, info = pcall(get, map)
    return ok and type(info) == "table" and info.name or nil
end

--- Größe einer Karte in Yards: Breite, Höhe. Ohne Angabe (Instanzen, Städte ohne Weltposition, fehlende
-- Kartenfunktionen) nil.
function Locations:GetMapSize(map)
    if type(map) ~= "number" then return nil end

    local known = mapSizes[map]
    if not known then
        -- nur Erfolge merken: beim Laden kann die Größe noch fehlen, später klappt es
        local ok, width, height = pcall(ReadMapSize, self.api, map)
        if not (ok and width) then return nil end
        known = { width, height }
        mapSizes[map] = known
    end

    return known[1], known[2]
end

--- Der Kontinent einer Karte (uiMapID des Kontinents) über die übergeordneten Karten, oder nil, wenn er sich
-- nicht bestimmen lässt (Karte unbekannt, keine Kartenfunktion).
function Locations:GetContinent(map)
    if type(map) ~= "number" then return nil end
    if continents[map] then return continents[map] end

    local getInfo = self.api.GetMapInfo
    if not getInfo then return nil end

    local continentType = (Enum and Enum.UIMapType and Enum.UIMapType.Continent) or 2
    local current = map
    for _ = 1, 10 do
        local ok, info = pcall(getInfo, current)
        if not ok or type(info) ~= "table" then return nil end
        if info.mapType == continentType then
            continents[map] = current
            return current
        end

        local parent = info.parentMapID
        if type(parent) ~= "number" or parent <= 0 or parent == current then return nil end
        current = parent
    end
end

--- Weltposition eines Kartenpunkts (x, y von 0 bis 1): Welt-ID (gleiche ID = gleicher Kontinent) und die zwei
-- Weltkoordinaten in Yards, oder nil, wenn der Client sie nicht liefert.
function Locations:GetWorldPosition(map, x, y)
    local get = self.api.GetWorldPosFromMapPos
    if not get or not CreateVector2D or type(map) ~= "number" then return nil end

    local ok, world, vector = pcall(get, map, CreateVector2D(x, y))
    if not ok or type(world) ~= "number" or type(vector) ~= "table" or not vector.GetXY then return nil end

    local a, b = vector:GetXY()
    if type(a) ~= "number" or type(b) ~= "number" then return nil end
    return world, a, b
end

--- Gemerkte Kartengrößen und Kontinente vergessen (für Tests)
function Locations:ResetCaches()
    mapSizes, continents = {}, {}
end
