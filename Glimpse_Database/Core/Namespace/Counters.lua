local _, P = ...
local DB = GlimpseDB
local Reader, Writer = P.Reader, P.Writer

-- Zähler pro Charakter, Art (kind, Text) und ID (Zahl; 0, wenn die Art keine IDs hat), optional pro Zone.
-- Jeder Count schreibt auch erste/letzte Zeit und die Stunden-Buckets (Buckets.lua).

--- Zählen für den eingeloggten Charakter. amount Standard 1, mapID nur bei zones = true gespeichert.
function Writer:Count(kind, id, mapID, amount)
    local char = P.CurrentChar()
    if not char then return false end

    id = id or 0
    amount = amount or 1
    local block = P.Path(P.Data(self, true), "own")

    local ids = P.Path(block, "counts", char, kind)
    ids[id] = (ids[id] or 0) + amount

    if self.zones and mapID then
        local zones = P.Path(block, "zones", char, kind, id)
        zones[mapID] = (zones[mapID] or 0) + amount
    end

    local now = P.Now()
    local seen = P.Path(block, "seen", char, kind)
    if seen[id] then
        seen[id][2] = now
    else
        seen[id] = { now, now }
    end

    P.AddHour(block, char, kind, id, DB:HourOf(now), amount)
    P.Fire(self.name, kind, id)
    return true
end

--- Startwert vor Glimpse (z. B. Blizzard-Statistik beim ersten Login). Wird nur einmal gesetzt.
function Writer:SetBaseline(kind, id, value)
    local char = P.CurrentChar()
    if not char then return false end

    local ids = P.Path(P.Data(self, true), "baseline", "counts", char, kind)
    id = id or 0
    if ids[id] ~= nil then return false end
    ids[id] = value
    P.Fire(self.name, kind, id)
    return true
end

function Reader:HasBaseline(kind, id)
    local char = P.CurrentChar()
    return P.Peek(P.Data(self), "baseline", "counts", char, kind, id or 0) ~= nil
end

local function Sum(ids, id)
    if id then return ids[id] or 0 end
    local total = 0
    for _, n in pairs(ids) do total = total + n end
    return total
end

--- Summe eines Zählers. id = nil summiert alle IDs der Art. scope siehe Query.lua; mit Zeitraum aus Buckets.
function Reader:GetCount(kind, id, scope)
    local query = P.Query(scope)
    if query.from then return self:GetCountBetween(kind, id, query) end

    local total = 0
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.counts, query, function(kinds)
            if kinds[kind] then total = total + Sum(kinds[kind], id) end
        end)
    end)
    return total + P.ExternalCount(self, kind, id, query)
end

--- { [id] = Summe } aller IDs einer Art
function Reader:GetCounts(kind, scope)
    local query = P.Query(scope)
    local result = {}
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.counts, query, function(kinds)
            for id, n in pairs(kinds[kind] or {}) do result[id] = (result[id] or 0) + n end
        end)
    end)
    return result
end

--- { [mapID] = Summe } für eine ID
function Reader:GetZones(kind, id, scope)
    local query = P.Query(scope)
    local result = {}
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.zones, query, function(kinds)
            for mapID, n in pairs(P.Peek(kinds, kind, id or 0) or {}) do
                result[mapID] = (result[mapID] or 0) + n
            end
        end)
    end)
    return result
end

--- Erster und letzter Zeitpunkt (Unix-Zeit) einer ID, nil ohne Daten
function Reader:GetSeen(kind, id, scope)
    local query = P.Query(scope)
    local first, last
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.seen, query, function(kinds)
            local seen = P.Peek(kinds, kind, id or 0)
            if seen then
                if not first or seen[1] < first then first = seen[1] end
                if not last or seen[2] > last then last = seen[2] end
            end
        end)
    end)
    return first, last
end
