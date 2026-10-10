local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Reisen: Strecke pro Fortbewegungsart und Zonen mit Aufenthaltsdauer, für jeden Charakter. Schreibt in den
-- Namespace "travel" von Glimpse: Database; ohne Database bleibt das Modul still. Keine Wegverläufe.
-- Dazu Flugpunkte und gemessene Flugzeiten. Lesen (z. B. Glimpse: Travel) über GlimpseDB:Get("travel").
--
-- Arten (kind) und IDs:
--   distance    Fortbewegungsart (Travel.MODES)   Yards
--   zone        uiMapID, in Instanzen -instanceID  Betreten
--   zonetime    wie zone                           Sekunden
--   traveltime  Fortbewegungsart                   Sekunden in Bewegung
--   teleport    0                                  Teleport, Ruhestein, Portal; ohne Strecke
--   jump        0                                  Sprünge mit der Leertaste
--   speedmax    Fortbewegungsart (1 gehen, 2 Reittier)   Höchsttempo, Yards pro Sekunde (Rekord, TravelRecords*.lua)
--   speedmin    wie speedmax                      niedrigstes Tempo über 1 Yard pro Sekunde, 2 s gehalten
--   fallmax     0                                 tiefster Sturz in Yards (Schätzung)
--   breathmax   0                                 längste Zeit unter Wasser am Stück, Sekunden
--   swimmax     0                                 längste Strecke am Stück geschwommen, Yards
--   jumpmilestone 0                               zuletzt gemeldeter Sprung-Meilenstein
--   tram        Ziel (1 Sturmwind, 2 Eisenschmiede, 0 unbekannt)  Fahrten mit der Tiefenbahn; Summe über alle IDs = alle Fahrten
-- Nachrichten (AceEvent, z. B. für eine Ankunftsanzeige):
--   GLIMPSE_TRAVEL_RIDE_START, kind, id, startTime, seconds   kind "tram" (id = Ziel, 0 = unbekannt; seconds = feste
--                                                    Fahrzeit Travel.TRAM_SECONDS) oder "flight" (Route, seconds nil)
--   GLIMPSE_TRAVEL_RIDE_END, kind, id                Ankunft, Landung oder Abbruch
--   flightpoint Flugpunkt (nodeID)                 1 = dem Charakter bekannt
--   flight      Strecke (von * 10000 + nach)       Flüge
--   flighttime  wie flight                         Sekunden; Schnitt = flighttime / flight
--   flightdistance wie flight                      Yards; Tempo = flightdistance / flighttime
-- Orte (AddLocation): Flugpunkte mit nodeID auf ihrer Zonenkarte.
local Travel = Glimpse:NewModule("Travel")

Travel.NAMESPACE = "travel"
-- swim: an der Oberfläche, underwater: getaucht; transport: Schiff oder Zeppelin, der Charakter steht und wird bewegt;
-- tram: nur in der Instanz der Tiefenbahn, nach 2 s schneller als Laufen (TravelTram.lua)
Travel.MODES = { walk = 1, mount = 2, swim = 3, taxi = 4, ghost = 5, transport = 6, underwater = 7, tram = 8 }
Travel.TRAM_INSTANCE = 369 -- Instanz-ID der Tiefenbahn (Karte zwischen Eisenschmiede und Sturmwind)

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
Travel.api = {
    GetTime = GetTime,
    UnitOnTaxi = UnitOnTaxi,
    C_TaxiMap = C_TaxiMap,
    GetTaxiMapID = GetTaxiMapID,
    hooksecurefunc = hooksecurefunc,
    UnitIsGhost = UnitIsGhost,
    IsSwimming = IsSwimming,
    IsSubmerged = IsSubmerged,
    GetMirrorTimerInfo = GetMirrorTimerInfo,
    IsMounted = IsMounted,
    GetUnitSpeed = GetUnitSpeed,
    IsFalling = IsFalling,
    C_MountJournal = C_MountJournal,
    UnitBuff = UnitBuff,
    ShowNotice = function(text)
        if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
            RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage(text, 1, 0.82, 0)
        end
    end,
    IsInInstance = IsInInstance,
    HBD = LibStub("HereBeDragons-2.0", true),
}

-- Antwort einer Abfrage als echtes true/false. Geschützte Werte (Secret, z. B. beim Zaubern) dürfen nicht verglichen
-- werden und zählen als nicht erfüllt; fehlt die Abfrage im Client, gilt dasselbe.
function Travel.Ask(func, ...)
    if not func then return false end
    local ok, value = pcall(func, ...)
    if not ok or Glimpse:IsSecret(value) then return false end
    return value == true or value == 1
end

function Travel:OnInitialize()
    if Glimpse.db and Glimpse.db.RegisterNamespace then
        self.recordSettings = Glimpse.db:RegisterNamespace("TravelRecords", { profile = self.RECORD_DEFAULTS })
    end
    self.debug = Glimpse:NewDebugger("Travel", { "distance", "zone", "flight", "records" })
    Glimpse:RegisterProbe("travel", "tram", function(args) return self:TramProbe(args) end,
        "Stadt, Start und Fahrt der Tiefenbahn; \"profile\" schaltet das Geschwindigkeitsprofil um")
end

function Travel:OnEnable()
    local DB = GlimpseDB
    if not DB then return end

    local ns, reason = DB:Register(self.NAMESPACE, { area = "Core", days = true })
    if not ns then
        self.debug:Error("distance", "Database: %s", tostring(reason))
        return
    end
    self.ns = ns

    self:StartDistance()
    self:StartZones()
    self:StartFlights()
    self:StartJumps()
    self:StartRecords()
    self:RegisterEvent("PLAYER_LOGOUT", function()
        self:ResetRecords()
        self:FlushDistance()
        self:LeaveZone()
        self:CancelFlight()
    end)
end

function Travel:Count(kind, id, amount)
    if not self.ns then return end
    local ok, err = pcall(self.ns.Count, self.ns, kind, id, nil, amount)
    if not ok then self.debug:Error(kind, "%s", tostring(err)) end
end
