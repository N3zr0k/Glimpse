-- luacheck: ignore 113
local stub = require("wowstub")

local function Export(DB, names)
    local text, err
    DB:Export(names, function(t, e) text, err = t, e end)
    stub.flush()
    assert(text, err)
    return text
end

local function Import(DB, text)
    local result, err
    DB:Import(text, function(r, e) result, err = r, e end)
    stub.flush()
    return result, err
end

-- Daten auf "Rechner A" sammeln und exportieren
local function Source()
    local DB = stub.load()
    local fishing = DB:Register("fishing", { area = "Professions", zones = true })
    fishing:Count("catch", 6303, 1429, 3)
    local loot = DB:Register("loot", { area = "Gathering", world = { drop = true } })
    loot:Count("drop", 2589, nil, 4)
    loot:Count("drop:299", 2589, nil, 2)
    loot:AddLocation(1617, 1429, 0.4, 0.5)
    return Export(DB)
end

test("Export ist kopierbarer Text mit Kopfzeile", function()
    local text = Source()
    eq(text:sub(1, 13), "!GlimpseDB:1!", "Kopf")
    eq(text:find("[^%w%(%)!:]"), nil, "nur druckbare Zeichen")
end)

test("Import auf einem anderen Rechner, gleicher Charakter", function()
    local text = Source()
    stub.reset()
    local DB = stub.load() -- neue Installation, gleicher Spieler
    local result = Import(DB, text)
    eq(result.characters, 1, "persönlich angewendet")
    eq(DB:Get("fishing"):GetCount("catch", 6303), 3, "Fänge")
    eq(DB:Get("fishing"):GetCount("catch", 6303, { sources = "own" }), 0, "als imported")
    eq(DB:Get("fishing"):GetZones("catch", 6303)[1429], 3, "Zone")
    eq(#DB:Get("loot"):GetLocations(1429), 1, "Ort")
    eq(DB:Get("loot"):GetCount("drop", 2589), 4, "Weltwissen beim eigenen Charakter")

    Import(DB, text)
    eq(DB:Get("fishing"):GetCount("catch", 6303), 3, "zweiter Import zählt nicht doppelt")
end)

test("Fremder Spieler: nur Weltwissen sofort, persönliches wartet", function()
    local text = Source()
    stub.reset()
    stub.player.guid, stub.player.name = "Player-1-00000099", "sMash"
    local DB = stub.load()
    local result = Import(DB, text)
    eq(result.pending, 1, "wartet")
    eq(DB:Get("fishing"), nil, "keine fremden Fänge")
    eq(DB:Get("loot"):GetCount("drop", 2589, "all"), 4, "Weltwissen unter fremdem Charakter")
    eq(DB:Get("loot"):GetCount("drop", 2589, "account"), 0, "nicht im eigenen Account")
    eq(DB:Get("loot"):GetCount("drop:299", 2589, "all"), 2, "Unterart ist auch Weltwissen")
    eq(#DB:GetCharacters(), 1, "fremder Charakter nicht in der Liste")

    -- Der Charakter loggt später auf diesem Rechner ein
    DB = stub.restart(stub.saved(), { guid = "Player-1-00000001", name = "Flovy" })
    eq(DB:Get("fishing"):GetCount("catch", 6303), 3, "beim Login angewendet")
    eq(GlimpseDB_Meta.pending[GlimpseDB_Meta.characters[DB:GetCharacter()].key], nil, "Warteschlange leer")
end)

test("Eigenen Export nicht zurück importieren", function()
    local DB = stub.load()
    DB:Register("fishing", { area = "Professions" }):Count("catch", 1)
    local result, err = Import(DB, Export(DB))
    eq(result, nil, "abgelehnt")
    eq(err, "SAME_INSTALL", "Grund")
end)

test("Unbekanntes Format und Konverter", function()
    local DB = stub.load()
    local _, err = Import(DB, "irgendwas")
    eq(err, "UNKNOWN_FORMAT", "ohne Konverter")

    DB:RegisterImportConverter("old", function(text) return text:sub(1, 4) == "OLD:" end, function()
        return {
            origin = { key = "abcdef01", name = "Alt" },
            namespaces = { stats = { area = "Misc", version = 1 } },
            world = { stats = { counts = { kill = { [299] = 7 } } } },
        }
    end)
    local result = Import(DB, "OLD:123")
    eq(result.namespaces, 1, "konvertiert")
    eq(DB:Get("stats"):GetCount("kill", 299, "all"), 7, "Werte")
end)

test("Kaputter Text wird abgelehnt", function()
    local DB = stub.load()
    local _, err = Import(DB, "!GlimpseDB:1!abc")
    eq(err, "BROKEN", "Grund")
end)

test("Unterschiedliche Schema-Version wird übersprungen", function()
    local text = Source()
    stub.reset()
    local DB = stub.load()
    DB:Register("fishing", { area = "Professions", version = 2 })
    local result = Import(DB, text)
    eq(result.skipped.fishing, "VERSION", "übersprungen")
end)
