local _, P = ...
local DB = GlimpseDB
local Reader = P.Reader

-- Tageswerte für Namespaces mit days = true: je Charakter, Art und ID ein Wert pro Tag (lokales Datum JJJJMMTT).
-- "Heute" und "letzte 7 Tage" sind Summen dieser Tage. Ältere Tage bleiben, sie sind klein.

--- Lokales Datum als Zahl, z. B. 20261009
function DB:DayOf(stamp)
    return tonumber(date("%Y%m%d", stamp))
end

function P.AddDay(block, char, kind, id, day, amount)
    local days = P.Path(block, "days", char, kind, id)
    days[day] = (days[day] or 0) + amount
end

--- Die letzten count Tage bis heute, neuester zuerst
function DB:LastDays(count)
    local list = {}
    for offset = 0, (count or 7) - 1 do
        list[#list + 1] = self:DayOf(self:LocalDayStart(-offset))
    end
    return list
end

--- { [day] = Summe } der letzten count Tage (Standard 7, heute = 1). id = nil summiert alle IDs der Art.
-- Tage ohne Wert fehlen in der Tabelle.
function Reader:GetDays(kind, id, scope, count)
    local wanted = {}
    for _, day in ipairs(DB:LastDays(count)) do wanted[day] = true end

    local result = {}
    local query = P.Query(scope)
    P.EachBlock(P.Data(self), query, function(block)
        P.EachChar(block.days, query, function(kinds)
            for currentId, days in pairs(kinds[kind] or {}) do
                if id == nil or currentId == id then
                    for day, n in pairs(days) do
                        if wanted[day] then result[day] = (result[day] or 0) + n end
                    end
                end
            end
        end)
    end)
    return result
end

--- Summe der letzten count Tage aus den Tageswerten (count = 1: heute)
function Reader:GetDayCount(kind, id, scope, count)
    local total = 0
    for _, n in pairs(self:GetDays(kind, id, scope, count)) do total = total + n end
    return total
end
