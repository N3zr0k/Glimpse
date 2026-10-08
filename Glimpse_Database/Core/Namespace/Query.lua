local _, P = ...
local DB = GlimpseDB

-- Herkunft der Daten:
--   own        von Glimpse erfasst
--   imported   aus einem Import
--   baseline   Stand vor Glimpse (z. B. Blizzard-Statistik), nur in Gesamtsummen, nie in Zeiträumen
--   external   live über einen Adapter gelesen (Adapters.lua), "external:<Quelle>" für eine bestimmte Quelle
DB.SOURCES = { "own", "imported", "baseline" }

local DEFAULT_SOURCES = { own = true, imported = true }

-- scope für alle Abfragen, als Text oder Tabelle:
--   "char" (Standard)  eingeloggter Charakter
--   "account"          alle eigenen Charaktere
--   "all"              zusätzlich fremde Charaktere aus Importen (Weltwissen)
--   Zahl               ein Charakter-Index
--   { chars = eins der obigen, sources = "own" | { "own", "external:GatherMate2", ... },
--     range = "today" | "week" | "month"  oder  from = Unix-Zeit, to = Unix-Zeit }
-- Ergebnis: { chars = Menge der Indizes, sources = Menge, from, to }. Mit from/to wird aus Stunden-Buckets gezählt.
function P.Query(scope)
    if type(scope) ~= "table" then scope = { chars = scope } end

    local query = { sources = {} }

    local sources = scope.sources or DEFAULT_SOURCES
    if type(sources) == "string" then
        query.sources[sources] = true
    elseif sources[1] then
        for _, source in ipairs(sources) do query.sources[source] = true end
    else
        query.sources = sources
    end

    local chars = scope.chars or "char"
    local set = {}
    if chars == "char" then
        local current = P.CurrentChar()
        if current then set[current] = true end
    elseif chars == "account" or chars == "all" then
        for index, entry in ipairs(P.meta.characters) do
            if chars == "all" or not entry.foreign then set[index] = true end
        end
    elseif type(chars) == "number" then
        set[chars] = true
    else
        error("bad scope " .. tostring(chars), 3)
    end
    query.chars = set

    if scope.range then
        query.from, query.to = DB:GetRange(scope.range)
    elseif scope.from or scope.to then
        query.from, query.to = scope.from or DB.EPOCH, scope.to or P.Now()
    end
    return query
end

--- Ruft func(block, source) für jeden vorhandenen Block der gewünschten Herkünfte auf
function P.EachBlock(data, query, func)
    if not data then return end
    for _, source in ipairs(DB.SOURCES) do
        local block = data[source]
        if block and query.sources[source] then func(block, source) end
    end
end

--- Ruft func(value, char) für alle Charaktere der Abfrage auf, die in byChar etwas haben
function P.EachChar(byChar, query, func)
    if not byChar then return end
    for char, value in pairs(byChar) do
        if query.chars[char] then func(value, char) end
    end
end
