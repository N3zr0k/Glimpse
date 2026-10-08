local _, P = ...
local DB = GlimpseDB
local Reader, Writer = P.Reader, P.Writer

local floor = math.floor

-- Orte: X und Y (0 bis 1 auf der Zonenkarte) auf 0..9999 gerundet und zu einer Zahl verpackt (x * 10000 + y).
-- places[source][mapID][xy] = id. Orte sind Weltwissen und hängen an keinem Charakter.

local function Clamp(value)
    value = floor(value * 10000 + 0.5)
    if value < 0 then return 0 end
    if value > 9999 then return 9999 end
    return value
end

function DB:PackXY(x, y)
    return Clamp(x) * 10000 + Clamp(y)
end

function DB:UnpackXY(xy)
    return floor(xy / 10000) / 10000, (xy % 10000) / 10000
end

function Writer:AddLocation(id, mapID, x, y)
    if not (id and mapID and x and y) then return false end
    local places = P.Path(P.Data(self, true), "places", "own", mapID)
    places[DB:PackXY(x, y)] = id
    P.Fire(self.name, "location", id)
    return true
end

function Writer:RemoveLocation(mapID, x, y)
    local places = P.Peek(P.Data(self), "places", "own", mapID)
    if places then places[DB:PackXY(x, y)] = nil end
end

--- Liste { mapID, x, y, id, source } aller Orte, gefiltert nach mapID und/oder id (beide optional).
-- Herkünfte wie bei Zählern (scope.sources), externe Quellen über ihre Adapter.
function Reader:GetLocations(mapID, id, scope)
    local query = P.Query(scope)
    local list = {}

    local function Add(map, xy, value, source)
        if id == nil or value == id then
            local x, y = DB:UnpackXY(xy)
            list[#list + 1] = { mapID = map, x = x, y = y, id = value, source = source }
        end
    end

    local places = P.Peek(P.Data(self), "places")
    for _, source in ipairs(DB.SOURCES) do
        local maps = places and places[source]
        if maps and query.sources[source] then
            if mapID then
                for xy, value in pairs(maps[mapID] or {}) do Add(mapID, xy, value, source) end
            else
                for map, spots in pairs(maps) do
                    for xy, value in pairs(spots) do Add(map, xy, value, source) end
                end
            end
        end
    end

    P.ExternalLocations(self, mapID, id, query, list)
    return list
end
