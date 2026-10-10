-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Modul Reisen (Modules/Travel) mit falscher Position und einem Namespace, der nur mitschreibt
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = false, debugOff = {} } }
    _G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    _G.LibStub = function() return { GetAddon = function() return Glimpse end } end
    stub.load("Core/Debug/DebugTag.lua", "Glimpse")
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Data.lua", "Glimpse")
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Core/IDs.lua", "Glimpse")
    for _, file in ipairs({ "Travel", "TravelDistance", "TravelTeleports", "TravelJumps", "TravelTram", "TravelZones", "TravelFlightPoints", "TravelFlights" }) do
        stub.load("Modules/Travel/" .. file .. ".lua", "Glimpse")
    end

    local zone = { map = 1429 }
    Glimpse.modules.Locations = { GetPlayerArea = function() return zone end, GetMapName = function() end }

    local pos = { x = 0, y = 0, instance = 0 }
    local state = { mounted = false }
    local Travel = Glimpse.modules.Travel
    -- Die Dateien halten die Tabelle als Upvalue, daher füllen statt ersetzen
    for key, value in pairs({
        GetTime = function() return stub.now end,
        UnitOnTaxi = function() return state.taxi end,
        GetTaxiMapID = function() return state.taxiMap end,
        C_TaxiMap = { GetAllTaxiNodes = function() return state.nodes end },
        hooksecurefunc = false,
        UnitIsGhost = function() return false end,
        IsSwimming = function() return state.swimming or false end,
        IsSubmerged = function() return state.under or false end,
        IsMounted = function() return state.mounted end,
        GetUnitSpeed = function() return state.speed or 7 end,
        IsInInstance = function() return state.inside or false end,
        IsFalling = function() return state.falling or false end,
        HBD = {
            GetPlayerWorldPosition = function() return pos.x, pos.y, pos.instance end,
            GetWorldDistance = function(_, _, x1, y1, x2, y2) return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) end,
        },
    }) do Travel.api[key] = value end

    local counts = {}
    local ns = {
        Count = function(_, kind, id, _, amount) counts[#counts + 1] = { kind = kind, id = id, amount = amount or 1 } end,
        AddLocation = function(_, id, mapID, x, y) counts[#counts + 1] = { kind = "location", id = id, amount = 1, mapID = mapID, x = x, y = y } end,
    }
    ns.GetCount = function(_, kind, id)
        local total = 0
        for _, entry in ipairs(counts) do if entry.kind == kind and entry.id == id then total = total + entry.amount end end
        return total
    end
    _G.CreateFrame = function() return { SetScript = function() end } end
    _G.GlimpseDB = { Register = function() return ns end }
    Travel:OnInitialize()
    Travel:OnEnable()
    _G.GlimpseDB = nil
    return Travel, counts, pos, state, zone, Glimpse
end

local function Sum(counts, kind, id)
    local total = 0
    for _, entry in ipairs(counts) do
        if entry.kind == kind and (id == nil or entry.id == id) then total = total + entry.amount end
    end
    return total
end

test("Reisen: geschützte Werte (Secret) lassen den Tick aus", function()
    local Travel, counts, pos, _, _, Glimpse = setup()
    Travel:Measure()
    local protected = false
    function Glimpse:IsSecret() return protected end
    protected = true                 -- Geschwindigkeit geschützt, z. B. beim Zaubern im Stehen
    stub.now = 0.5
    pos.x = 5
    eq(Travel:Measure(), 0, "kein Fehler, nichts gezählt")
    eq(Travel:OnJump(), true, "Sprung ohne Abfragefehler")
    protected = false
    stub.now = 1
    pos.x = 10
    Travel:Measure()
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.walk), 10, "Strecke des ausgelassenen Ticks wird mitgerechnet")
    function Glimpse:IsSecret() return false end
end)

test("Reisen: Strecke je Fortbewegungsart", function()
    local Travel, counts, pos, state = setup()
    Travel:Measure()
    for i = 1, 4 do
        stub.now = i * 0.5
        pos.x = i * 3
        Travel:Measure()
    end
    state.mounted = true
    stub.now = 2.5
    pos.x = 20
    Travel:Measure()
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.walk), 12, "gelaufen")
    eq(Sum(counts, "distance", Travel.MODES.mount), 8, "geritten")
end)

test("Reisen: Sprünge und Kontinentwechsel zählen nicht", function()
    local Travel, counts, pos = setup()
    Travel:Measure()
    stub.now = 0.5
    pos.x = 500
    eq(Travel:Measure(), 0, "Teleport")
    stub.now = 1
    pos.instance = 1
    pos.x = 510
    eq(Travel:Measure(), 0, "anderer Kontinent")
    Travel:FlushDistance()
    eq(Sum(counts, "distance"), 0, "nichts gezählt")
end)

test("Reisen: Zone betreten und Aufenthaltsdauer", function()
    local Travel, counts, _, _, zone = setup()
    eq(Sum(counts, "zone", 1429), 1, "beim Start betreten")
    stub.now = 90
    zone.map = 1411
    Travel:UpdateZone()
    eq(Sum(counts, "zonetime", 1429), 90, "Sekunden")
    eq(Sum(counts, "zone", 1411), 1, "neue Zone")
    Travel:UpdateZone()
    eq(Sum(counts, "zone", 1411), 1, "gleiche Zone zählt nicht erneut")
end)

test("Reisen: Reisezeit je Fortbewegungsart", function()
    local Travel, counts, pos = setup()
    Travel:Measure()
    for i = 1, 6 do
        stub.now = i * 0.5
        pos.x = i * 3
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "traveltime", Travel.MODES.walk), 3, "3 Sekunden gelaufen")
end)

-- Flugkarte in Brachland: 23 = hier, 25 und 40 bekannt, 77 unbekannt
local function TaxiMap(state)
    state.taxiMap = 1413
    state.nodes = {
        { nodeID = 23, slotIndex = 1, state = 0, name = "Crossroads", position = { x = 0.5, y = 0.3 } },
        { nodeID = 25, slotIndex = 2, state = 1, name = "Ratchet", position = { x = 0.6, y = 0.4 } },
        { nodeID = 40, slotIndex = 3, state = 1, name = "Camp Taurajo", position = { x = 0.4, y = 0.6 } },
        { nodeID = 77, slotIndex = 4, state = 2, name = "Unknown", position = { x = 0.1, y = 0.1 } },
    }
end

test("Reisen: Flugpunkte von der Flugkarte", function()
    local Travel, counts, _, state = setup()
    TaxiMap(state)
    eq(Travel:RecordFlightPoints(), 3, "drei bekannte neu")
    eq(Sum(counts, "location"), 4, "alle als Ort")
    eq(Sum(counts, "flightpoint", 77), 0, "unbekannter zählt nicht")
    eq(Travel:RecordFlightPoints(), 0, "beim zweiten Öffnen nichts neu")
    eq(Sum(counts, "flightpoint", 23), 1, "nur einmal je Charakter")
end)

test("Reisen: Flugzeit von Start bis Landung", function()
    local Travel, counts, _, state = setup()
    TaxiMap(state)
    stub.now = 100
    Travel:PlanFlight(2)
    Travel:OnTaxiState()
    eq(Sum(counts, "flight"), 0, "noch am Boden")
    stub.now = 101
    state.taxi = true
    Travel:OnTaxiState()
    Travel:AddFlightYards(1200)
    Travel:AddFlightYards(300.4)
    stub.now = 185
    Travel:OnTaxiState()
    state.taxi = false
    Travel:OnTaxiState()
    local route = Travel.RouteID(23, 25)
    eq(Sum(counts, "flight", route), 1, "ein Flug")
    eq(Sum(counts, "flighttime", route), 84, "Sekunden")
    eq(Sum(counts, "flightdistance", route), 1500, "Yards")
end)

test("Reisen: Flug ohne Abflug verfällt, Ausloggen zählt nicht", function()
    local Travel, counts, _, state = setup()
    TaxiMap(state)
    stub.now = 10
    Travel:PlanFlight(3)
    stub.now = 30
    Travel:OnTaxiState()
    state.taxi = true
    Travel:OnTaxiState()
    state.taxi = false
    Travel:OnTaxiState()
    eq(Sum(counts, "flight"), 0, "zu spät abgeflogen")

    Travel:PlanFlight(3)
    state.taxi = true
    Travel:OnTaxiState()
    Travel:CancelFlight()
    state.taxi = false
    Travel:OnTaxiState()
    eq(Sum(counts, "flight"), 0, "ausgeloggt")
end)

test("Reisen: Schiff und Zeppelin als eigene Art, Stehenbleiben zählt nicht dazu", function()
    local Travel, counts, pos, state = setup()
    Travel:Measure()
    stub.now = 0.5
    pos.x = 3
    state.speed = 0 -- nach dem Laufen stehen geblieben
    Travel:Measure()
    for i = 2, 5 do
        stub.now = i * 0.5
        pos.x = 3 + (i - 1) * 10 -- das Schiff fährt
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.walk), 13, "erster Schritt noch als Laufen")
    eq(Sum(counts, "distance", Travel.MODES.transport), 30, "Schiff")
end)

test("Reisen: kurzes Laufen zwischen zwei Messungen im Stehen ist keine Fahrt", function()
    local Travel, counts, pos, state = setup()
    state.speed = 0
    Travel:Measure()
    stub.now = 0.5
    pos.x = 3                  -- losgelaufen und gleich wieder stehen geblieben
    Travel:Measure()
    stub.now = 1
    Travel:Measure()
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.transport), 0, "kein Schiff")
    eq(Sum(counts, "distance", Travel.MODES.walk), 3, "gelaufen")
end)

test("Reisen: Teleports je Charakter, ohne Strecke", function()
    local Travel, counts, pos, state = setup()
    Travel:Measure()
    stub.now = 0.5
    pos.x = 800 -- Teleport ohne Ladebildschirm
    Travel:Measure()
    eq(Sum(counts, "teleport"), 1, "Teleport")

    Travel:BeforeLoading({ x = 800, y = 0, instance = 0, standing = true })
    pos.instance = 1 -- Ruhestein auf einen anderen Kontinent
    Travel:CheckLoadingTeleport({ x = 10, y = 10, instance = 1 })
    eq(Sum(counts, "teleport"), 2, "Ruhestein mit Ladebildschirm")

    Travel:BeforeLoading({ x = 10, y = 10, instance = 1, mode = Travel.MODES.transport })
    Travel:CheckLoadingTeleport({ x = 10, y = 10, instance = 0 })
    eq(Sum(counts, "teleport"), 2, "Schiff zählt nicht")

    Travel:BeforeLoading({ x = 10, y = 10, instance = 0, standing = true })
    Travel:CheckLoadingTeleport({ x = 50, y = 10, instance = 0 })
    eq(Sum(counts, "teleport"), 2, "gleicher Ort nach dem Ladebildschirm")

    Travel:BeforeLoading({ x = 10, y = 10, instance = 0, standing = false })
    Travel:CheckLoadingTeleport({ x = 10, y = 10, instance = 369 })
    eq(Sum(counts, "teleport"), 2, "in die Tiefenbahn hineingelaufen")

    Travel:BeforeLoading({ x = 10, y = 10, instance = 0, standing = true })
    state.inside = true
    Travel:CheckLoadingTeleport({ x = 5000, y = 10, instance = 36 })
    eq(Sum(counts, "teleport"), 2, "Instanz betreten")
    eq(Sum(counts, "distance"), 0, "keine Strecke")
end)

test("Reisen: Schwimmen und unter Wasser getrennt", function()
    local Travel, counts, pos, state = setup()
    state.swimming = true
    Travel:Measure()
    stub.now = 0.5
    pos.x = 2
    Travel:Measure()
    state.under = true
    stub.now = 1
    pos.x = 5
    Travel:Measure()
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.swim), 2, "Oberfläche")
    eq(Sum(counts, "distance", Travel.MODES.underwater), 3, "getaucht")
end)

test("Reisen: Sprünge mit der Leertaste nur vom Boden", function()
    local Travel, counts, _, state = setup()
    eq(Travel:OnJump(), true, "vom Boden")
    state.falling = true
    eq(Travel:OnJump(), false, "in der Luft")
    state.falling, state.swimming = false, true
    eq(Travel:OnJump(), false, "im Wasser")
    state.swimming, state.taxi = false, true
    eq(Travel:OnJump(), false, "auf der Flugroute")
    eq(Sum(counts, "jump"), 1, "ein Sprung")
    eq(Sum(counts, "teleport"), 0, "kein Teleport")
end)

test("Reisen: Tiefenbahn als eigene Art", function()
    local Travel, counts, pos, state = setup()
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    for i = 1, 8 do
        stub.now = i * 0.5
        pos.x = i * 10
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.tram), 50, "Tiefenbahn ab der dritten Sekunde")
    eq(Sum(counts, "distance", Travel.MODES.walk), 30, "davor noch Laufen")
    eq(Sum(counts, "distance", Travel.MODES.transport), 0, "kein Schiff")
end)

test("Reisen: Laufen in der Tiefenbahn-Instanz ist keine Fahrt", function()
    local Travel, counts, pos = setup()
    pos.instance = Travel.TRAM_INSTANCE
    Travel:Measure()
    for i = 1, 12 do
        stub.now = i * 0.5
        pos.x = i * 4                -- 8 Yards pro Sekunde
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.tram), 0, "keine Tiefenbahn")
    eq(Sum(counts, "distance", Travel.MODES.walk), 48, "gelaufen")
end)

test("Reisen: schnell bewegen ohne Stillstand ist keine Tiefenbahn", function()
    local Travel, counts, pos = setup()
    pos.instance = Travel.TRAM_INSTANCE     -- eigene Geschwindigkeit 7: der Charakter läuft selbst
    Travel:Measure()
    for i = 1, 12 do
        stub.now = i * 0.5
        pos.x = i * 15
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.tram), 0, "keine Tiefenbahn")
    eq(Sum(counts, "tram"), 0, "keine Fahrt")
end)

test("Reisen: Geschwindigkeitsprofil der Tiefenbahn läuft ohne Fehler durch", function()
    local Travel, counts, pos, state = setup()
    eq(Travel:TramProbe("profile")[1]:find("on", 1, true) ~= nil, true, "Profil an")
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    local x, t = 0, 0
    for _, speed in ipairs({ 4, 8, 14, 20, 30, 30, 22, 12, 4, 0, 0 }) do
        t = t + 1
        stub.now = t
        x = x + speed
        pos.x = x
        Travel:Measure()
    end
    Travel:FlushDistance()
    eq(Sum(counts, "distance", Travel.MODES.tram) > 0, true, "Fahrt erkannt")
end)

test("Reisen: Zonenwechsel (UpdateZone) merkt die Stadt für die Tiefenbahn", function()
    local Travel, _, pos, _, zone = setup()
    zone.map = 1455
    Travel:UpdateZone()
    pos.instance = Travel.TRAM_INSTANCE
    Travel:Measure()
    eq(Travel:GetTramStation(), 2, "Eisenschmiede")
end)

test("Reisen: Login in der Stadt wird bei der ersten Messung erkannt", function()
    local Travel, _, pos, _, zone = setup()
    zone.map = 1453
    Travel:Measure()
    zone.map = 1429
    pos.instance = Travel.TRAM_INSTANCE
    stub.now = 0.5
    Travel:Measure()
    eq(Travel:GetTramStation(), 1, "Sturmwind")
end)

test("Reisen: Stadt wird zwischengespeichert und beim Betreten der Instanz zur Startstadt", function()
    local Travel, _, pos, _, zone = setup()
    zone.map = 1455                  -- Eisenschmiede
    Travel:CheckCity()
    zone.map = 1429                  -- danach eine andere Zone: Stadt bleibt gemerkt
    Travel:CheckCity()
    stub.now = 0.5
    Travel:Measure()
    eq(Travel:GetTramStation(), nil, "noch nicht in der Instanz")
    pos.instance = Travel.TRAM_INSTANCE
    stub.now = 1
    Travel:Measure()
    eq(Travel:GetTramStation(), 2, "Start Eisenschmiede")
end)

test("Reisen: Fahrten mit der Tiefenbahn, Halt beendet eine Fahrt", function()
    local Travel, counts, pos, state = setup()
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    local t = 0
    local function Ride(steps, yards)
        for _ = 1, steps do
            t = t + 0.5
            stub.now = t
            pos.x = pos.x + yards
            Travel:Measure()
        end
    end
    Ride(10, 15)                 -- 150 Yards Richtung Sturmwind
    Ride(8, 0)                   -- Halt, 4 Sekunden
    eq(Sum(counts, "tram"), 1, "erste Fahrt nach dem Halt")
    Ride(10, -15)                -- zurück ohne Aussteigen
    Ride(8, 0)
    eq(Sum(counts, "tram"), 2, "Rückfahrt zählt extra")
    Ride(2, 15)                  -- kurz angefahren
    Ride(8, 0)
    eq(Sum(counts, "tram"), 2, "zu kurz")
end)

local function Messages(Travel, name)
    local list = {}
    for _, m in ipairs(Travel.messages) do if m[1] == name then list[#list + 1] = m end end
    return list
end

test("Reisen: Laufen im Wagen beendet die Fahrt nicht, erst die Haltestelle", function()
    local Travel, counts, pos, state = setup()
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    local t = 0
    local function Ride(steps, yards)
        for _ = 1, steps do
            t = t + 0.5
            stub.now = t
            pos.x = pos.x + yards
            Travel:Measure()
        end
    end
    Ride(10, 15)                 -- Bahn fährt, ab der dritten Sekunde Fahrt
    eq(Travel:GetTramRide() ~= nil, true, "Fahrt läuft")
    state.speed = 7              -- im Wagen losgelaufen
    Ride(6, 18)                  -- Bahn plus Laufen
    state.speed = 0
    Ride(4, 14)
    eq(Travel:GetTramRide() ~= nil, true, "Fahrt läuft weiter")
    eq(#Messages(Travel, "GLIMPSE_TRAVEL_RIDE_START"), 1, "kein zweiter Start")
    eq(#Messages(Travel, "GLIMPSE_TRAVEL_RIDE_END"), 0, "kein Ende")
    Ride(10, 1)                  -- Bahn steht an der Haltestelle, nur noch Laufen
    eq(Travel:GetTramRide(), nil, "Haltestelle beendet die Fahrt")
    eq(Sum(counts, "tram"), 1, "eine Fahrt")
    eq(#Messages(Travel, "GLIMPSE_TRAVEL_RIDE_END"), 1, "ein Ende")
end)

test("Reisen: Tiefenbahn merkt Ziel und Dauer, meldet Start und Ende", function()
    local Travel, counts, pos, state, zone = setup()
    zone.map = 1453                  -- Sturmwind
    Travel:CheckCity()
    zone.map, zone.instance = nil, Travel.TRAM_INSTANCE
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    eq(Travel:GetTramStation(), 1, "Einstieg in Sturmwind")
    local t = 0
    for _ = 1, 20 do
        t = t + 0.5
        stub.now = t
        pos.x = pos.x + 15
        Travel:Measure()
    end
    local starts = Messages(Travel, "GLIMPSE_TRAVEL_RIDE_START")
    eq(#starts, 1, "ein Start")
    eq(starts[1][2], "tram", "kind")
    eq(starts[1][3], 2, "Ziel Eisenschmiede")
    for _ = 1, 8 do                  -- Halt
        t = t + 0.5
        stub.now = t
        Travel:Measure()
    end
    eq(Sum(counts, "tram", 2), 1, "Fahrt zum Ziel")
    eq(Sum(counts, "tramtime"), 0, "kein tramtime")
    eq(Sum(counts, "traveltime", Travel.MODES.tram), Travel.TRAM_SECONDS, "feste Zeit je Fahrt")
    eq(starts[1][5], Travel.TRAM_SECONDS, "feste Fahrzeit im Start")
    local ends = Messages(Travel, "GLIMPSE_TRAVEL_RIDE_END")
    eq(#ends, 1, "ein Ende")
    eq(ends[1][3], 2, "Ziel im Ende")

    for _ = 1, 20 do                 -- Rückfahrt ohne Aussteigen
        t = t + 0.5
        stub.now = t
        pos.x = pos.x - 15
        Travel:Measure()
    end
    eq(Messages(Travel, "GLIMPSE_TRAVEL_RIDE_START")[2][3], 1, "Rückfahrt nach Sturmwind")
end)

test("Reisen: Tiefenbahn ohne bekannte Haltestelle zählt mit Ziel 0", function()
    local Travel, counts, pos, state = setup()
    pos.instance = Travel.TRAM_INSTANCE
    state.speed = 0
    Travel:Measure()
    for i = 1, 20 do
        stub.now = i * 0.5
        pos.x = i * 15
        Travel:Measure()
    end
    Travel:EndTramRide()
    eq(Sum(counts, "tram", 0), 1, "Fahrt mit Ziel 0")
    eq(Sum(counts, "tram", 1) + Sum(counts, "tram", 2), 0, "kein Ziel")
    eq(Messages(Travel, "GLIMPSE_TRAVEL_RIDE_START")[1][3], 0, "Ziel 0")
end)

test("Reisen: Flug meldet Abheben und Landung", function()
    local Travel, _, _, state = setup()
    TaxiMap(state)
    stub.now = 100
    Travel:PlanFlight(2)
    stub.now = 101
    state.taxi = true
    Travel:OnTaxiState()
    local route = Travel.RouteID(23, 25)
    local starts = Messages(Travel, "GLIMPSE_TRAVEL_RIDE_START")
    eq(starts[1][2], "flight", "kind")
    eq(starts[1][3], route, "Route")
    eq(starts[1][4], 101, "Startzeit")
    state.taxi = false
    Travel:OnTaxiState()
    eq(Messages(Travel, "GLIMPSE_TRAVEL_RIDE_END")[1][3], route, "Landung")

    Travel:PlanFlight(2)
    state.taxi = true
    Travel:OnTaxiState()
    Travel:CancelFlight()
    eq(#Messages(Travel, "GLIMPSE_TRAVEL_RIDE_END"), 2, "Abbruch")
end)
