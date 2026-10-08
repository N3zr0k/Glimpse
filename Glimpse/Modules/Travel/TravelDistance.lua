local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Strecke: alle 0,5 s die Weltposition über HereBeDragons, Abstände je Fortbewegungsart aufsummiert. Sprünge
-- (Teleport, Ladebildschirm, anderer Kontinent) werden verworfen. Geschrieben wird gesammelt, nicht jede Messung.

local api = Travel.api
local MODES = Travel.MODES

local INTERVAL = 0.5
local MAX_SPEED = 60     -- Yards pro Sekunde; schneller ist ein Sprung
local FLUSH_EVERY = 30   -- Sekunden

local last         -- { x, y, instance, at }
local pending = {} -- mode -> Yards seit dem letzten Schreiben
local lastFlush = 0

function Travel:GetMode()
    if api.UnitOnTaxi("player") then return MODES.taxi end
    if api.UnitIsGhost("player") then return MODES.ghost end
    if api.IsSwimming() then return MODES.swim end
    if api.IsMounted() then return MODES.mount end
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
    lastFlush = api.GetTime()
end

--- Eine Messung; gibt die gezählten Yards zurück (0 bei Sprung oder ohne Position)
function Travel:Measure()
    local x, y, instance = api.HBD:GetPlayerWorldPosition()
    local now = api.GetTime()
    if not (x and y and instance) then
        last = nil
        return 0
    end

    local previous = last
    last = { x = x, y = y, instance = instance, at = now }
    if not previous or previous.instance ~= instance then return 0 end

    local yards = api.HBD:GetWorldDistance(instance, previous.x, previous.y, x, y) or 0
    if yards <= 0 then return 0 end
    if yards > MAX_SPEED * math.max(now - previous.at, INTERVAL) then
        self.debug:Log("distance", "jump of %.0f yd ignored", yards)
        return 0
    end

    local mode = self:GetMode()
    pending[mode] = (pending[mode] or 0) + yards
    if now - lastFlush >= FLUSH_EVERY then self:FlushDistance() end
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
    end)
    self.distanceFrame = frame

    -- Ladebildschirm: Position danach nicht mit der davor verrechnen
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function()
        last = nil
        self:FlushDistance()
    end)
end
