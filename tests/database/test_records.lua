-- luacheck: ignore 113
local stub = require("wowstub")

test("SetMax speichert nur bessere Werte", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core" })
    local ok, old = ns:SetMax("speedmax", 1, 7, 1429)
    eq(ok, true, "erster Wert ist Rekord")
    eq(old, nil, "kein alter Wert")
    ok, old = ns:SetMax("speedmax", 1, 9)
    eq(ok, true, "besser")
    eq(old, 7, "alter Wert")
    ok, old = ns:SetMax("speedmax", 1, 8)
    eq(ok, false, "schlechter")
    eq(old, 9, "bleibt")
    local value, _, mapID = ns:GetMax("speedmax", 1)
    eq(value, 9, "Höchstwert")
    eq(mapID, nil, "Zone des zweiten Eintrags")
    eq(ns:GetMax("speedmax", 2), nil, "andere ID leer")
end)

test("SetMin speichert nur kleinere Werte", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core" })
    eq(ns:SetMin("speedmin", 1, 4.5), true, "erster")
    eq(ns:SetMin("speedmin", 1, 5), false, "größer zählt nicht")
    eq(ns:SetMin("speedmin", 1, 3), true, "kleiner")
    eq(ns:GetMin("speedmin", 1), 3, "Tiefstwert")
end)

test("Rekorde ignorieren ungültige Werte", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core" })
    eq(ns:SetMax("x", 0, "viel"), false, "Text")
    eq(ns:SetMax("x", 0, 0 / 0), false, "NaN")
    eq(ns:GetMax("x", 0), nil, "nichts gespeichert")
end)

test("account nimmt den besten Charakter", function()
    local DB = stub.load()
    DB:Register("travel", { area = "Core" }):SetMax("speedmax", 1, 7)
    local saved = stub.saved()

    DB = stub.restart(saved, { guid = "Player-1-00000002", name = "Twink" })
    local ns = DB:Register("travel", { area = "Core" })
    ns:SetMax("speedmax", 1, 5)
    eq(ns:GetMax("speedmax", 1), 5, "Charakter")
    eq(ns:GetMax("speedmax", 1, "account"), 7, "Account")
end)

test("Rekord löst EVENT_CHANGED aus", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core" })
    local got
    local listener = {}
    DB.RegisterCallback(listener, DB.EVENT_CHANGED, function(_, name, kind, id) got = name .. kind .. id end)
    ns:SetMax("fallmax", 0, 30)
    eq(got, "travelfallmax0", "Meldung")
end)

local function Export(DB)
    local text
    DB:Export(nil, function(t) text = t end)
    stub.flush()
    return text
end

test("Import führt Rekorde mit dem besseren Wert zusammen, doppelt schadet nicht", function()
    local DB = stub.load()
    local ns = DB:Register("travel", { area = "Core" })
    ns:SetMax("speedmax", 1, 12, 1429)
    ns:SetMin("speedmin", 1, 2)
    local text = Export(DB)

    stub.reset()
    DB = stub.load()
    ns = DB:Register("travel", { area = "Core" })
    ns:SetMax("speedmax", 1, 20)
    ns:SetMin("speedmin", 1, 5)
    for _ = 1, 2 do
        DB:Import(text, function() end)
        stub.flush()
    end
    eq(ns:GetMax("speedmax", 1), 20, "eigener Wert besser")
    eq(ns:GetMin("speedmin", 1), 2, "importierter Wert besser")
end)
