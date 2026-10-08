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
