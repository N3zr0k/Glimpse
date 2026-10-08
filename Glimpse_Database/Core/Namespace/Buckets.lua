local _, P = ...
local DB = GlimpseDB
local Reader = P.Reader

-- Stunden-Buckets: Stunden seit DB.EPOCH (UTC). Je Art gesamt (hours) und je ID nur die Stunden mit Werten (idHours).
-- Kein Ereignis-Log; Zeiträume wie "heute" oder "letzte 7 Tage" werden daraus summiert.

function P.AddHour(block, char, kind, id, hour, amount)
    local total = P.Path(block, "hours", char, kind)
    total[hour] = (total[hour] or 0) + amount

    local byId = P.Path(block, "idHours", char, kind, id)
    byId[hour] = (byId[hour] or 0) + amount
end

-- Stunden-Tabelle einer Art (id = nil) oder einer ID
local function Hours(kinds, kind, id, idKinds)
    if id then return P.Peek(idKinds, kind, id) end
    return kinds[kind]
end

--- Ruft func(hour, n) für alle Buckets im Zeitraum auf
local function EachHour(self, kind, id, query, func)
    local first, last = DB:HourOf(query.from), DB:HourOf(query.to)
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.hours, query, function(kinds, char)
            local hours = Hours(kinds, kind, id, P.Peek(block, "idHours", char))
            for hour, n in pairs(hours or {}) do
                if hour >= first and hour <= last then func(hour, n) end
            end
        end)
    end)
end

--- Summe im Zeitraum query.from bis query.to (aus P.Query). Lieber GetCount mit range/from/to nutzen.
function Reader:GetCountBetween(kind, id, query)
    local total = 0
    EachHour(self, kind, id, query, function(_, n) total = total + n end)
    return total
end

--- { [hour] = n } im Zeitraum, dünn besetzt. scope braucht range oder from/to. Für Graphen: DB:HourStart(hour).
function Reader:GetSeries(kind, id, scope)
    local query = P.Query(scope)
    if not query.from then error("GetSeries needs a range or from/to", 2) end

    local series = {}
    EachHour(self, kind, id, query, function(hour, n) series[hour] = (series[hour] or 0) + n end)
    return series
end
