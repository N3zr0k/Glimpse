local _, P = ...
local DB = GlimpseDB

-- Herkunft der Daten eines Namespace für die Diagnose (/gli probe db sources): wo er liegt, wer schreibt und wie viel
-- in jedem Block steckt. Lädt den Bereich bei Bedarf.

local function Sum(byChar, perKind)
    local total, chars = 0, 0
    for _, kinds in pairs(byChar or {}) do
        chars = chars + 1
        for kind, ids in pairs(kinds) do
            for _, n in pairs(ids) do
                total = total + n
                if perKind then perKind[kind] = (perKind[kind] or 0) + n end
            end
        end
    end
    return total, chars
end

local function CountPlaces(maps)
    local n = 0
    for _, spots in pairs(maps or {}) do
        for _ in pairs(spots) do n = n + 1 end
    end
    return n
end

--- Angaben zu einem Namespace, nil wenn unbekannt:
--   area, version, loaded (Bereich geladen), reason (warum nicht), writer (Addon-Name, true = ohne Namen, nil = keiner)
--   sources[own|imported|baseline] = { total, chars }   Summe aller Zähler und Anzahl Charaktere
--   kinds[kind][source] = Summe                         nur mit detail = true
--   places[source] = Anzahl Orte
--   adapters[Quelle] = true/false (verfügbar)
function DB:GetNamespaceInfo(name, detail)
    P.RequireLoaded()
    local meta = P.meta.namespaces[name]
    if not meta then return nil end

    local info = {
        area = meta.area, version = meta.version, sources = {}, places = {}, adapters = {},
        writer = P.writers[name] and (P.writerAddons[name] or true) or nil,
        kinds = detail and {} or nil,
    }
    for source, adapter in pairs(P.adapters[name] or {}) do
        info.adapters[source] = not adapter.IsAvailable or adapter.IsAvailable() == true
    end

    local area, reason = self:LoadArea(meta.area)
    info.loaded, info.reason = area ~= nil, reason
    local data = area and area[name]
    if not data then return info end

    for _, source in ipairs(DB.SOURCES) do
        local block = data[source]
        if block then
            local perKind = detail and {} or nil
            local total, chars = Sum(block.counts, perKind)
            info.sources[source] = { total = total, chars = chars }
            for kind, n in pairs(perKind or {}) do
                P.Path(info.kinds, kind)[source] = n
            end
        end
    end
    for source, maps in pairs(data.places or {}) do
        info.places[source] = CountPlaces(maps)
    end
    return info
end
