-- luacheck: ignore 113 122
local stub = require("wowstub")

-- 2026-01-05 12:00 Ortszeit als Stunden-Bucket
local function NoonHour(DB, day)
    return DB:HourOf(os.time({ year = 2026, month = 1, day = day, hour = 12 }))
end

local function StatisticsSV()
    return {
        char = {
            ["Flovy - Forever"] = {
                totals = { kills = 15, deaths = 3, ["fishing.casts"] = 10, ["fishing.catches"] = 9,
                    ["fishing.items"] = 7, ["gathering.herb"] = 2 },
                baseline = { kills = 5, ["fishing.catches"] = 2 },
                by = {
                    kills = { [299] = { n = 6, first = 100, last = 200 }, [30] = { n = 2, first = 150, last = 160 } },
                    ["kills.zone"] = { ["299@1429"] = { n = 4 }, ["299@i33"] = { n = 2 } },
                    deaths = { [299] = { n = 1 } },
                    ["fishing.casts"] = { [1429] = { n = 8 }, i33 = { n = 2 } },
                    ["fishing.catches"] = { [1429] = { n = 7 } },
                    ["fishing.items"] = { [6303] = { n = 7, first = 300, last = 400 } },
                    ["fishing.items.zone"] = { ["6303@1429"] = { n = 7 } },
                    ["gathering.herb"] = { [1617] = { n = 2 } },
                },
                first = { kills = 90 }, last = { kills = 210 },
                days = { kills = { [20260105] = 8 } },
            },
            ["Twink - Forever"] = { totals = { kills = 4 }, by = { kills = { [299] = { n = 4 } } } },
        },
        global = { totals = { kills = 999 } },
    }
end

local function GatheringSV()
    return {
        global = {
            nodes = {
                [1617] = { name = "Silberblatt", category = "herb", attempts = 10,
                    items = { [765] = { hits = 10, amount = 14 }, [2452] = { hits = 2, amount = 2 } },
                    spots = { { map = 1429, x = 4250, y = 6000, n = 3 }, { inst = 33, n = 1 } } },
            },
            npcs = {
                [299] = { name = "Wolf", loot = { attempts = 20, items = { [750] = { hits = 5, amount = 5 } } },
                    skinning = { attempts = 4, items = { [2318] = { hits = 4, amount = 6 } } },
                    spots = { { map = 1429, x = 100, y = 100, n = 2 } } },
            },
            fishing = { [1429] = { attempts = 30, items = { [6303] = { hits = 25, amount = 25 } },
                spots = { { map = 1429, x = 5000, y = 5000, n = 30 } } } },
        },
    }
end

test("Statistics: Kills, Tode und Startwerte nach combat", function()
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    local combat = DB:Get("combat")
    eq(combat:GetCount("kill", 299), 6, "Kills NPC")
    eq(combat:GetCount("kill", 0), 2, "Rest ohne Aufschlüsselung")
    eq(combat:GetCount("kill"), 10, "ohne Startwert")
    eq(combat:GetCount("kill", nil, { sources = "baseline" }), 5, "Startwert")
    eq(combat:GetZones("kill", 299)[1429], 4, "Zone")
    eq(combat:GetZones("kill", 299)[-33], 2, "Instanz")
    eq(combat:GetCount("death", 299), 1, "Tod durch NPC")
    eq(combat:GetCount("death", 0), 2, "Tod unbekannt")
    local first, last = combat:GetSeen("kill", 299)
    eq(first, 100, "erster")
    eq(last, 200, "letzter")
    eq(GlimpseDB_Core.combat.own.hours[1].kill[NoonHour(DB, 5)], 8, "Tageswert als Stunde")
end)

test("Statistics: Angeln und Sammeln", function()
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    local fishing = DB:Get("fishing")
    eq(fishing:GetCount("cast"), 10, "Würfe")
    eq(fishing:GetZones("cast", 0)[-33], 2, "Würfe in Instanz")
    eq(fishing:GetCount("catch"), 7, "Fänge ohne Startwert")
    eq(fishing:GetCount("catch", nil, { sources = "baseline" }), 2, "Startwert Fänge")
    eq(fishing:GetCount("fish", 6303), 7, "Fisch")
    eq(fishing:GetZones("fish", 6303)[1429], 7, "Fisch je Zone")
    eq(DB:Get("gathering"):GetCount("herb", 1617), 2, "Kraut")
end)

test("Statistics: nur der eingeloggte Charakter, der Twink bei seinem Login", function()
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    eq(DB:Get("combat"):GetCount("kill", 299, "account"), 6, "nur Flovy")
    eq(#DB:GetCharacters(), 1, "kein Charakter über den Namen angelegt")

    DB = stub.restart(stub.saved(), { guid = "Player-1-00000002", name = "Twink" })
    eq(DB:Get("combat"):GetCount("kill", 299), 4, "Twink nach Login")
    eq(DB:Get("combat"):GetCount("kill", 299, "account"), 10, "Account")
    eq(#DB:GetCharacters(), 2, "zwei Charaktere")
end)

test("Statistics: Charakter ohne alte Daten wird trotzdem vermerkt", function()
    stub.player.name = "Neu"
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    eq(DB:Get("combat"), nil, "nichts übernommen")
    eq(type(DB:GetMigrations().statistics), "number", "vermerkt")
end)

test("Statistics: anderer Charakter mit gleichem Namen übernimmt nichts doppelt", function()
    stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    local DB = stub.restart(stub.saved())
    eq(DB:Get("combat"):GetCount("kill", 299), 6, "gleiche GUID, nicht doppelt")
end)

test("Vermerk einer früheren Alpha bleibt gültig", function()
    stub.load()
    local saved = stub.saved()
    saved.GlimpseDB_Meta.migrated = { statistics = 123 }
    saved.GlimpseStatisticsDB = StatisticsSV()
    local DB = stub.restart(saved)
    eq(DB:Get("combat"), nil, "nicht erneut")
    eq(DB:GetMigrations().statistics, 123, "alter Zeitpunkt")
end)

test("Ohne Alpha-Version keine Übernahme", function()
    local version = stub.version
    stub.version = "0.4.0-beta.1"
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV(), GlimpseGatheringDB = GatheringSV() })
    stub.version = version
    eq(DB.GetMigrations, nil, "keine API")
    eq(DB:Get("combat"), nil, "nichts übernommen")
end)

test("Übernahme läuft nur einmal", function()
    stub.load({ GlimpseStatisticsDB = StatisticsSV(), GlimpseGatheringDB = GatheringSV() })
    local saved = stub.saved()
    saved.GlimpseStatisticsDB, saved.GlimpseGatheringDB = StatisticsSV(), GatheringSV()
    local DB = stub.restart(saved)
    eq(DB:Get("combat"):GetCount("kill", 299), 6, "nicht doppelt")
    eq(DB:Get("gathering"):GetCount("node", 1617, "account"), 10, "nicht doppelt")
    eq(type(DB:GetMigrations().statistics), "number", "vermerkt")
end)

test("Ohne altes Addon wird nichts vermerkt, später schon", function()
    eq(stub.load():GetMigrations().statistics, nil, "noch offen")
    local saved = stub.saved()
    saved.GlimpseStatisticsDB = StatisticsSV()
    local DB = stub.restart(saved)
    eq(DB:Get("combat"):GetCount("kill", 299), 6, "nachgeholt")
end)

test("GatheringDB: Knoten, Kreaturen, Angeln und Orte", function()
    local DB = stub.load({ GlimpseGatheringDB = GatheringSV() })
    local gathering = DB:Get("gathering")
    eq(gathering:GetCount("node", 1617, "account"), 10, "Versuche")
    eq(gathering:GetCount("nodeloot:1617", 765, "account"), 14, "Menge")
    eq(gathering:GetCount("nodedrop:1617", 2452, "account"), 2, "Funde")
    eq(gathering:GetZones("node", 1617, "account")[-33], 1, "Instanz")
    eq(gathering:GetCount("npc", 299, "account"), 20, "Kills als Versuche")
    eq(gathering:GetCount("skinloot:299", 2318, "account"), 6, "Kürschnern")
    eq(gathering:GetZones("npc", 299, "account")[1429], 2, "Zone Kreatur")

    local spots = gathering:GetLocations(1429, nil, "account")
    eq(#spots, 1, "nur Knotenorte")
    eq(spots[1].id, 1617, "Knoten")
    near(spots[1].x, 0.425, "x")

    local fishing = DB:Get("fishing")
    eq(fishing:GetCount("looted", 1429, "account"), 30, "Angelversuche")
    eq(fishing:GetCount("drop:1429", 6303, "account"), 25, "Fänge")
    eq(#fishing:GetLocations(1429, nil, "account"), 1, "Angelort")
end)

test("GatheringDB: Weltwissen gehört keinem Charakter", function()
    local DB = stub.load({ GlimpseGatheringDB = GatheringSV() })
    eq(DB:Get("gathering"):GetCount("node", 1617), 0, "nicht beim eingeloggten Charakter")
    eq(#DB:GetCharacters(), 1, "kein zusätzlicher Charakter in der Liste")

    DB = stub.restart(stub.saved(), { guid = "Player-1-00000002", name = "Twink" })
    eq(DB:Get("gathering"):GetCount("node", 1617, "account"), 10, "Twink sieht es im Account, nicht doppelt")
end)

test("Späterer Schreiber findet die übernommenen Daten", function()
    local DB = stub.load({ GlimpseStatisticsDB = StatisticsSV() })
    local ns = DB:Register("combat", { area = "Core", zones = true, world = { looted = true, loot = true } })
    ns:Count("kill", 299)
    eq(ns:GetCount("kill", 299), 7, "weitergezählt")
end)

test("Weltwissen der Übernahme geht in den Export", function()
    local DB = stub.load({ GlimpseGatheringDB = GatheringSV() })
    local text
    DB:Export(nil, function(result) text = result end)
    stub.flush()

    -- zweiter Rechner ohne alte Daten
    stub.reset()
    DB = stub.load()
    DB:Import(text, function() end)
    stub.flush()
    eq(DB:Get("gathering"):GetCount("nodeloot:1617", 765, "all"), 14, "Beute importiert")
end)
