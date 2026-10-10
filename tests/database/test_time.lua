-- luacheck: ignore 113
local stub = require("wowstub")

test("Stunden-Buckets ab 2026-01-01 UTC", function()
    local DB = stub.load()
    eq(DB:HourOf(DB.EPOCH), 0, "Start")
    eq(DB:HourOf(DB.EPOCH + 3599), 0, "gleiche Stunde")
    eq(DB:HourOf(DB.EPOCH + 3600), 1, "nächste Stunde")
    eq(DB:HourStart(24), DB.EPOCH + 86400, "Rückweg")
end)

test("Zeitraum heute und Woche aus Buckets", function()
    local DB = stub.load()
    local ns = DB:Register("fishing", { area = "Core" })
    local today = DB:LocalDayStart(0)
    stub.serverTime = today - 9 * 86400 + 3600 -- vor neun Tagen
    ns:Count("catch", 1, nil, 5)
    stub.serverTime = today + 7200
    ns:Count("catch", 1, nil, 2)
    ns:Count("catch", 2, nil, 1)

    eq(ns:GetCount("catch", nil, { range = "today" }), 3, "heute alle")
    eq(ns:GetCount("catch", 1, { range = "today" }), 2, "heute ID 1")
    eq(ns:GetCount("catch", 1, { range = "week" }), 2, "Woche ohne den Fang vor neun Tagen")
    eq(ns:GetCount("catch", 1, { range = "month" }), 7, "Monat")
end)

test("Serie für Graphen", function()
    local DB = stub.load()
    local ns = DB:Register("fishing", { area = "Core" })
    ns:Count("catch", 1)
    stub.serverTime = stub.serverTime + 3600
    ns:Count("catch", 1, nil, 2)
    local series = ns:GetSeries("catch", 1, { from = DB.EPOCH, to = stub.serverTime })
    local hour = DB:HourOf(stub.serverTime)
    eq(series[hour], 2, "letzte Stunde")
    eq(series[hour - 1], 1, "Stunde davor")
end)

test("Tageswerte: ein Wert je Tag, heute und letzte 7 Tage daraus", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core", days = true })
    local today = DB:LocalDayStart(0)
    stub.serverTime = today - 9 * 86400 + 3600 -- vor neun Tagen
    ns:Count("distance", 1, nil, 500)
    stub.serverTime = today - 2 * 86400 + 3600
    ns:Count("distance", 1, nil, 300)
    ns:Count("distance", 2, nil, 50)
    stub.serverTime = today + 3600
    ns:Count("distance", 1, nil, 100)
    stub.serverTime = today + 7200
    ns:Count("distance", 1, nil, 20)

    local days = ns:GetDays("distance", 1)
    eq(days[DB:DayOf(today)], 120, "heute ein Wert")
    eq(days[DB:DayOf(today - 2 * 86400)], 300, "vorgestern")
    eq(days[DB:DayOf(today - 9 * 86400)], nil, "vor neun Tagen nicht in den 7 Tagen")
    eq(ns:GetDayCount("distance", 1, nil, 1), 120, "heute")
    eq(ns:GetDayCount("distance", 1), 420, "letzte 7 Tage")
    eq(ns:GetDayCount("distance", nil), 470, "alle Arten der Fortbewegung")
    eq(ns:GetCount("distance", 1), 920, "insgesamt")
    eq(#DB:LastDays(7), 7, "sieben Tage")
end)

test("Tageswerte nur mit days = true", function()
    local DB = stub.load()
    local ns = DB:Register("fishing", { area = "Core" })
    ns:Count("catch", 1)
    eq(ns:GetDayCount("catch", 1), 0, "keine Tageswerte")
end)
