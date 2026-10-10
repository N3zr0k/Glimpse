local _, P = ...
local DB = GlimpseDB

-- Import eines Exports (Export.lua):
--   * Weltwissen landet als imported beim Charakter, von dem der Export stammt (fremde Charaktere werden mit
--     foreign = true angelegt und zählen nicht zum eigenen Account).
--   * Persönliche Daten nur beim selben Charakter. Ist der Charakter hier noch unbekannt, wartet der Teil in
--     Meta.pending und wird beim ersten Login dieses Charakters angewendet (neuer PC, Twinks).
--   * Exporte derselben Installation werden abgelehnt, sonst stünden eigene Daten doppelt da.
-- Schutz gegen Versehen, nicht gegen Absicht.
--
-- Fremde Formate (z. B. alte Exporte von GatheringDB oder Statistics) laufen über Konverter:
--   DB:RegisterImportConverter(name, detect(text) -> bool, convert(text) -> payload | nil, Fehler)
-- convert läuft in der Import-Coroutine und darf P.Yield über DB:Yield() nutzen. Ohne passenden Konverter wird
-- ein unbekanntes Format abgelehnt.

P.converters = {}

function DB:RegisterImportConverter(name, detect, convert)
    P.converters[#P.converters + 1] = { name = name, detect = detect, convert = convert }
end

--- Pause in langer Arbeit eines Konverters
function DB:Yield()
    P.Yield()
end

-- Namespace für den Import vorbereiten: Meta-Eintrag und Bereich. Gibt die Daten oder nil, Grund zurück.
local function Target(name, info)
    if type(name) ~= "string" or type(info) ~= "table" then return nil, "BROKEN" end
    local known = P.meta.namespaces[name]
    local version = tonumber(info.version) or 1

    if known then
        if version ~= (known.version or 1) then return nil, "VERSION" end
    else
        local area = DB:IsArea(info.area) and info.area or "Misc"
        known = { area = area, version = version }
        P.meta.namespaces[name] = known
    end

    if not DB:LoadArea(known.area) then return nil, "AREA" end
    return P.Data({ name = name, area = known.area, version = known.version }, true)
end

-- Persönliche Daten eines Namespace in imported des Charakters übernehmen
local function MergePersonal(data, char, part)
    local block = P.Path(data, "imported")
    for field, kinds in pairs(part) do
        if field == "seen" then
            P.MergeSeen(P.Path(block, "seen", char), kinds)
        elseif field == "max" or field == "min" then
            P.MergeRecords(P.Path(block, field, char), kinds, field == "max")
        elseif field == "counts" or field == "zones" or field == "hours" or field == "idHours"
            or field == "days" then
            P.MergeMax(P.Path(block, field, char), kinds)
        end
    end
end

--- Persönliche Teile anwenden, die auf diesen Charakter warten (beim Login, Events.lua)
function P.ApplyPending()
    local char, key = P.CurrentChar(), P.charKey
    local list = char and P.meta.pending[key]
    if not list then return end

    for _, entry in ipairs(list) do
        for name, part in pairs(entry.data or {}) do
            local data = Target(name, entry.namespaces[name] or {})
            if data and type(part) == "table" then MergePersonal(data, char, part) end
        end
    end
    P.meta.pending[key] = nil
    P.Fire(nil)
end

local function Apply(payload)
    local result = { namespaces = 0, characters = 0, pending = 0, skipped = {} }

    if type(payload.origin) ~= "table" or type(payload.origin.key) ~= "string" then return nil, "BROKEN" end
    if payload.install and payload.install == P.meta.install then return nil, "SAME_INSTALL" end
    local namespaces = type(payload.namespaces) == "table" and payload.namespaces or {}

    local origin = P.CharIndex(payload.origin.key, payload.origin)
    for name, part in pairs(type(payload.world) == "table" and payload.world or {}) do
        local data, reason = Target(name, namespaces[name])
        if data and type(part) == "table" then
            P.MergeMax(P.Path(data, "imported", "counts", origin), part.counts)
            P.MergePlaces(P.Path(data, "places", "imported"), part.places)
            P.MergeLabels(P.Path(data, "labels"), part.labels)
            result.namespaces = result.namespaces + 1
        else
            result.skipped[name] = reason
        end
        P.Yield()
    end

    for key, personal in pairs(type(payload.personal) == "table" and payload.personal or {}) do
        local index = type(key) == "string" and P.meta.index[key]
        local valid = type(key) == "string" and type(personal) == "table" and type(personal.data) == "table"
        if valid and index and not P.meta.characters[index].foreign then
            for name, part in pairs(personal.data) do
                local data, reason = Target(name, namespaces[name])
                if data and type(part) == "table" then
                    MergePersonal(data, index, part)
                else
                    result.skipped[name] = reason
                end
            end
            result.characters = result.characters + 1
        elseif valid then
            local list = P.Path(P.meta.pending, key)
            list[#list + 1] = { data = personal.data, namespaces = namespaces }
            result.pending = result.pending + 1
        end
        P.Yield()
    end

    P.Fire(nil)
    return result
end

--- Import eines Textes, asynchron. callback(result) mit
--   { namespaces = n, characters = n, pending = n, skipped = { [name] = Grund } }
-- oder callback(nil, Fehler): UNKNOWN_FORMAT, BROKEN, SAME_INSTALL, NO_CHARACTER oder Fehler eines Konverters.
function DB:Import(text, callback)
    P.RequireLoaded()
    text = strtrim(text or "")

    P.RunAsync(function()
        if not P.CurrentChar() then return nil, "NO_CHARACTER" end

        local payload, err
        if P.Detect(text) then
            payload, err = P.Decode(text)
        else
            err = "UNKNOWN_FORMAT"
            for _, converter in ipairs(P.converters) do
                if converter.detect(text) then
                    payload, err = converter.convert(text)
                    break
                end
            end
        end
        if not payload then return nil, err end
        return Apply(payload)
    end, function(ok, result, err)
        if not ok then
            callback(nil, result)
        else
            callback(result, err)
        end
    end)
end
