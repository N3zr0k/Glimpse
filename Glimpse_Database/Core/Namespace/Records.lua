local _, P = ...
local Reader, Writer = P.Reader, P.Writer

-- Rekorde pro Charakter, Art und ID: der höchste (max) oder niedrigste (min) Wert, den es je gab.
-- Ablage: max/min[char][kind][id] = { Wert, Zeit, mapID }. Zählt nicht zu den Zählern (Counters.lua).

local function Record(self, field, kind, id, value, mapID, better)
    local char = P.CurrentChar()
    if not char or type(value) ~= "number" or value ~= value then return false end

    id = id or 0
    local ids = P.Path(P.Data(self, true), "own", field, char, kind)
    local old = ids[id]
    if old and not better(value, old[1]) then return false, old[1] end

    ids[id] = { value, P.Now(), mapID }
    P.Fire(self.name, kind, id)
    return true, old and old[1]
end

--- Neuen Höchstwert melden. Gibt true und den alten Wert zurück, wenn es ein Rekord ist, sonst false und den Rekord.
function Writer:SetMax(kind, id, value, mapID)
    return Record(self, "max", kind, id, value, mapID, function(new, old) return new > old end)
end

--- Neuen Tiefstwert melden, Rückgabe wie SetMax
function Writer:SetMin(kind, id, value, mapID)
    return Record(self, "min", kind, id, value, mapID, function(new, old) return new < old end)
end

-- Bester Eintrag über alle Charaktere der Abfrage
local function Best(self, field, kind, id, scope, better)
    local query = P.Query(scope)
    local best
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block[field], query, function(kinds)
            local entry = P.Peek(kinds, kind, id or 0)
            if entry and (not best or better(entry[1], best[1])) then best = entry end
        end)
    end)
    if best then return best[1], best[2], best[3] end
end

--- Höchstwert, Zeit (Unix) und mapID oder nil. scope siehe Query.lua (Zeiträume gelten hier nicht).
function Reader:GetMax(kind, id, scope)
    return Best(self, "max", kind, id, scope, function(new, old) return new > old end)
end

--- Tiefstwert, Zeit (Unix) und mapID oder nil
function Reader:GetMin(kind, id, scope)
    return Best(self, "min", kind, id, scope, function(new, old) return new < old end)
end
