local _, P = ...
local DB = GlimpseDB

-- Externe Daten (GatherMate2, Blizzard-Statistik ...) werden nie kopiert, sondern zur Laufzeit über einen Adapter
-- gelesen. Ein Adapter ist eine Tabelle mit optionalen Funktionen:
--   IsAvailable()                         false, wenn die Quelle gerade fehlt (Addon nicht geladen)
--   GetCount(kind, id)                    Zahl oder nil
--   GetLocations(mapID, id, add)          ruft add(mapID, x, y, id) für jeden Ort auf
-- Abfragen sehen einen Adapter nur, wenn sources "external" oder "external:<Quelle>" enthält.

P.adapters = {} -- nsName -> { source -> adapter }

function DB:RegisterAdapter(nsName, source, adapter)
    P.Path(P.adapters, nsName)[source] = adapter
end

local function EachAdapter(ns, query, func)
    local list = P.adapters[ns.name]
    if not list then return end
    for source, adapter in pairs(list) do
        local key = "external:" .. source
        if (query.sources.external or query.sources[key])
            and (not adapter.IsAvailable or adapter.IsAvailable()) then
            func(adapter, key)
        end
    end
end

function P.ExternalCount(ns, kind, id, query)
    local total = 0
    EachAdapter(ns, query, function(adapter)
        if adapter.GetCount then total = total + (adapter.GetCount(kind, id) or 0) end
    end)
    return total
end

function P.ExternalLocations(ns, mapID, id, query, list)
    EachAdapter(ns, query, function(adapter, source)
        if not adapter.GetLocations then return end
        adapter.GetLocations(mapID, id, function(map, x, y, value)
            list[#list + 1] = { mapID = map, x = x, y = y, id = value, source = source }
        end)
    end)
end
