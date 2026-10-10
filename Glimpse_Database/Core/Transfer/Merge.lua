local _, P = ...

-- Importierte Werte werden per Maximum zusammengeführt: derselbe Export zweimal importiert zählt nicht doppelt.
-- Nur Zahlen-Blätter mit Text- oder Zahlenschlüssel werden übernommen, alles andere still verworfen; das ist
-- zugleich die Prüfung der fremden Daten.

local MAX_DEPTH = 6
local MAX_NUMBER = 1e15

local function IsKey(key)
    return type(key) == "string" or type(key) == "number"
end

local function IsNumber(value)
    return type(value) == "number" and value == value and value < MAX_NUMBER and value > -MAX_NUMBER
end

--- Zahlen aus source in target übernehmen, je Blatt das Maximum
function P.MergeMax(target, source, depth)
    depth = depth or 0
    if type(source) ~= "table" or depth > MAX_DEPTH then return end
    for key, value in pairs(source) do
        if IsKey(key) then
            if IsNumber(value) then
                local old = target[key]
                if type(old) ~= "number" or value > old then target[key] = value end
            elseif type(value) == "table" then
                if type(target[key]) ~= "table" then target[key] = {} end
                P.MergeMax(target[key], value, depth + 1)
            end
        end
    end
end

-- seen[kind][id] = { erster, letzter }: frühester erster, spätester letzter
function P.MergeSeen(target, source)
    if type(source) ~= "table" then return end
    for kind, ids in pairs(source) do
        if IsKey(kind) and type(ids) == "table" then
            local into = P.Path(target, kind)
            for id, pair in pairs(ids) do
                if IsKey(id) and type(pair) == "table" and IsNumber(pair[1]) and IsNumber(pair[2]) then
                    local old = into[id]
                    if old then
                        old[1] = math.min(old[1], pair[1])
                        old[2] = math.max(old[2], pair[2])
                    else
                        into[id] = { pair[1], pair[2] }
                    end
                end
            end
        end
    end
end

-- Orte: places[mapID][xy] = id, Zahlen auf allen Ebenen
function P.MergePlaces(target, source)
    if type(source) ~= "table" then return end
    for mapID, spots in pairs(source) do
        if IsNumber(mapID) and type(spots) == "table" then
            local into = P.Path(target, mapID)
            for xy, id in pairs(spots) do
                if IsNumber(xy) and xy >= 0 and xy <= 99999999 and IsKey(id) then into[xy] = id end
            end
        end
    end
end

-- Namen: labels[Sprache][Art][ID] = Text; vorhandene Namen bleiben
function P.MergeLabels(target, source)
    if type(source) ~= "table" then return end
    for locale, kinds in pairs(source) do
        if type(locale) == "string" and #locale <= 8 and type(kinds) == "table" then
            for kind, ids in pairs(kinds) do
                if IsKey(kind) and type(ids) == "table" then
                    local into = P.Path(target, locale, kind)
                    for id, name in pairs(ids) do
                        if IsKey(id) and type(name) == "string" and name ~= "" and #name <= 120 and into[id] == nil then
                            into[id] = name
                        end
                    end
                end
            end
        end
    end
end

-- Rekorde: records[kind][id] = { Wert, Zeit, mapID }; der bessere Wert gewinnt (higher = true für max)
function P.MergeRecords(target, source, higher)
    if type(source) ~= "table" then return end
    for kind, ids in pairs(source) do
        if IsKey(kind) and type(ids) == "table" then
            local into = P.Path(target, kind)
            for id, entry in pairs(ids) do
                if IsKey(id) and type(entry) == "table" and IsNumber(entry[1]) and IsNumber(entry[2]) then
                    local old = into[id]
                    local better = not old or (higher and entry[1] > old[1]) or (not higher and entry[1] < old[1])
                    if better then
                        into[id] = { entry[1], entry[2], IsNumber(entry[3]) and entry[3] or nil }
                    end
                end
            end
        end
    end
end
