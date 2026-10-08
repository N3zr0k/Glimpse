local _, P = ...
local DB = GlimpseDB

local floor = math.floor

-- Stunden-Buckets zählen in UTC-Stunden ab diesem Zeitpunkt (2026-01-01 00:00 UTC). Geschrieben wird mit der
-- Serverzeit; "heute" usw. rechnet erst die Abfrage in Ortszeit um.
local EPOCH = 1767225600
DB.EPOCH = EPOCH

-- In Tests ersetzbar
function P.Now()
    return GetServerTime()
end

function DB:HourOf(stamp)
    return floor((stamp - EPOCH) / 3600)
end

function DB:HourStart(hour)
    return EPOCH + hour * 3600
end

--- Lokale Mitternacht als Unix-Zeit. offset in Tagen: 0 = heute, -6 = vor sechs Tagen.
-- Über date/time, damit Zeitzone und Sommerzeit stimmen.
function DB:LocalDayStart(offset)
    local today = date("*t", P.Now())
    return time({ year = today.year, month = today.month, day = today.day + (offset or 0), hour = 0 })
end

-- Benannte Zeiträume für Abfragen: from (einschließlich) bis jetzt
local RANGES = { today = 0, week = -6, month = -29 }

--- from, to (Unix-Zeit) für "today", "week" (letzte 7 Tage) oder "month" (letzte 30 Tage)
function DB:GetRange(name)
    local offset = RANGES[name]
    if not offset then error("unknown range " .. tostring(name), 2) end
    return self:LocalDayStart(offset), P.Now()
end
