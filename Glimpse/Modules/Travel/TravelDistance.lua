local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Strecke: alle 0,5 s die Weltposition über HereBeDragons, Abstände je Fortbewegungsart aufsummiert. Sprünge
-- (Teleport, Ladebildschirm, anderer Kontinent) werden verworfen. Dazu die Reisezeit: Sekunden in Bewegung je Art.
-- Geschrieben wird gesammelt, nicht jede Messung.

local api = Travel.api
local MODES = Travel.MODES

local INTERVAL = 0.5
local MAX_SPEED = 60     -- Yards pro Sekunde; schneller ist ein Sprung
local FLUSH_EVERY = 30   -- Sekunden

local last         -- { x, y, instance, at }
local pending = {} -- mode -> Yards seit dem letzten Schreiben
local pendingTime = {} -- mode -> Sekunden in Bewegung seit dem letzten Schreiben
local lastFlush = 0

-- Steht der Charakter (eigene Geschwindigkeit 0) bei zwei Messungen hintereinander und bewegt sich trotzdem, wird er
-- getragen. Als Schiff oder Zeppelin gilt das erst, wenn es bei zwei Schritten nacheinander zutrifft: Wer steht,
-- kurz läuft und wieder steht, erfüllt es sonst schon einmal.
local CARRY_STEPS = 2
-- Eigene Geschwindigkeit: Zahl, oder nil und true, wenn der Client sie gerade schützt (Secret). Dann lässt Step die
-- Messung aus.
local function Speed()
    if not api.GetUnitSpeed then return nil end
    local ok, speed = pcall(api.GetUnitSpeed, "player")
    if not ok then return nil end
    if Glimpse:IsSecret(speed) then return nil, true end
    return speed
end


-- Ohne IsSubmerged: die Atemleiste läuft nur unter Wasser
local function Underwater()
    if api.IsSubmerged then return Travel.Ask(api.IsSubmerged) end
    if not api.GetMirrorTimerInfo then return false end
    for index = 1, 3 do
        local timer, _, _, scale, paused = api.GetMirrorTimerInfo(index)
        if timer == "BREATH" and (scale or 0) < 0 and not paused then return true end
    end
    return false
end

--- Fortbewegungsart für eine Messung, bei der sich die Position geändert hat. carrySteps = Schritte in Folge im Stehen bewegt,
-- instance = Instanz der Messung (Tiefenbahn)
function Travel:GetMode(carrySteps, instance, fast)
    if Travel.Ask(api.UnitOnTaxi, "player") then return MODES.taxi end
    if Travel.Ask(api.UnitIsGhost, "player") then return MODES.ghost end
    if Travel.Ask(api.IsSwimming) then return Underwater() and MODES.underwater or MODES.swim end
    if instance == Travel.TRAM_INSTANCE then
        if fast then return MODES.tram end
    elseif carrySteps >= CARRY_STEPS then
        return MODES.transport
    end
    if Travel.Ask(api.IsMounted) then return MODES.mount end
    return MODES.walk
end

function Travel:FlushDistance()
    for mode, yards in pairs(pending) do
        -- auf 0,1 Yard gerundet, kleine Reste bleiben bis zum nächsten Mal
        local amount = math.floor(yards * 10) / 10
        if amount > 0 then
            self:Count("distance", mode, amount)
            pending[mode] = yards - amount
        end
    end
    for mode, seconds in pairs(pendingTime) do
        local amount = math.floor(seconds)
        if amount > 0 then
            self:Count("traveltime", mode, amount)
            pendingTime[mode] = seconds - amount
        end
    end
    lastFlush = api.GetTime()
end

-- Eine Messung: gezählte Yards (0 bei Sprung oder ohne Position) und die Fortbewegungsart, falls bewegt
local function Step(self)
    local x, y, instance = api.HBD:GetPlayerWorldPosition()
    local now = api.GetTime()
    if Glimpse:IsSecret(x) or Glimpse:IsSecret(y) or Glimpse:IsSecret(instance) then return 0 end -- Tick auslassen
    if not (x and y and instance) then
        last = nil
        return 0
    end

    local speed, secret = Speed()
    if secret then return 0 end -- Tick auslassen, der nächste rechnet die Strecke mit

    local previous = last
    self:TramZone(instance)
    last = { x = x, y = y, instance = instance, at = now, standing = speed == 0, carry = 0, mode = previous and previous.mode }
    if not previous then
        self:CheckLoadingTeleport(last)
        return 0
    end
    if previous.instance ~= instance then return 0 end

    local yards = api.HBD:GetWorldDistance(instance, previous.x, previous.y, x, y) or 0
    last.speed = yards / math.max(now - previous.at, 0.01)
    if yards <= 0 then return 0 end
    if yards > MAX_SPEED * math.max(now - previous.at, INTERVAL) then
        self.debug:Log("distance", "teleport of %.0f yd, distance ignored", yards)
        self:CountTeleport()
        return 0
    end

    if previous.standing and last.standing then last.carry = (previous.carry or 0) + 1 end
    local fast = self:IsTramMotion(previous, last, yards)
    local mode = self:GetMode(last.carry, instance, fast)
    last.mode = mode
    if mode == MODES.taxi then self:AddFlightYards(yards) end
    pending[mode] = (pending[mode] or 0) + yards
    -- Die Tiefenbahn braucht immer gleich lang: ihre Zeit trägt EndTramRide fest ein, sie wird nicht gemessen
    if mode ~= MODES.tram then pendingTime[mode] = (pendingTime[mode] or 0) + (now - previous.at) end
    if now - lastFlush >= FLUSH_EVERY then self:FlushDistance() end
    return yards, mode
end

--- Eine Messung; gibt die gezählten Yards zurück
function Travel:Measure()
    local yards, mode = Step(self)
    if last then self:TramProfile(last) end
    self:TramTick(mode, yards, last)
    return yards
end

function Travel:StartDistance()
    if not api.HBD then
        self.debug:Error("distance", "HereBeDragons-2.0 missing")
        return
    end

    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < INTERVAL then return end
        elapsed = 0
        local ok, err = pcall(self.Measure, self)
        if not ok then self.debug:Error("distance", "%s", tostring(err)) end
        ok, err = pcall(self.OnTaxiState, self)
        if not ok then self.debug:Error("flight", "%s", tostring(err)) end
    end)
    self.distanceFrame = frame

    -- Stadt für die Tiefenbahn nur bei Zonenwechsel prüfen. ZONE_CHANGED_NEW_AREA und PLAYER_ENTERING_WORLD
    -- gehören TravelZones (ein Handler je Ereignis), von dort wird CheckCity mit aufgerufen.
    self:RegisterEvent("ZONE_CHANGED", "CheckCity")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "CheckCity")

    -- Ladebildschirm: Position danach nicht mit der davor verrechnen, nur auf einen Sprung prüfen
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function()
        self:BeforeLoading(last)
        self:EndTramRide()
        last = nil
        self:FlushDistance()
    end)
end
