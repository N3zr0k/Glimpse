local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Wasser-Rekorde: längste Zeit unter Wasser am Stück (breathmax, Sekunden) und längste Strecke am Stück
-- geschwommen (swimmax, Yards). Gewertet wird beim Auftauchen bzw. Verlassen des Wassers, damit die Meldung nicht
-- mitten im Tauchgang kommt. Eine Strecke endet erst, wenn der Charakter 2 Messungen lang nicht schwimmt.

local api = Travel.api
local MODES = Travel.MODES

local MIN_BREATH = 5   -- Sekunden
local MIN_SWIM = 20    -- Yards
local DRY_STEPS = 2

local breathStart
local swim, dry = 0, 0

-- Atem wird gehalten, wenn der Charakter getaucht ist und die Atemleiste läuft (mit Wasseratmung steht sie)
local function BreathTimerRuns()
    if not api.GetMirrorTimerInfo then return true end
    for index = 1, 3 do
        local timer, _, _, scale, paused = api.GetMirrorTimerInfo(index)
        if timer == "BREATH" and (scale or 0) < 0 and not paused then return true end
    end
    return false
end

function Travel:FinishBreath(now)
    if not breathStart then return end
    local seconds = now - breathStart
    breathStart = nil
    if seconds >= MIN_BREATH and self:NewRecord("breathmax", 0, seconds) then
        self:Announce("breath", { time = self:FormatDuration(seconds) })
    end
end

function Travel:FinishSwim()
    local yards = swim
    swim, dry = 0, 0
    if yards >= MIN_SWIM and self:NewRecord("swimmax", 0, yards) then
        self:Announce("swim", { distance = self:FormatDistance(yards) })
    end
end

function Travel:ResetWater(now)
    self:FinishBreath(now)
    self:FinishSwim()
end

--- Eine Messung. yards und mode kommen aus der Streckenmessung (mode nil im Stehen)
function Travel:RecordWaterTick(now, yards, mode)
    local swimming = Travel.Ask(api.IsSwimming)

    if swimming then
        dry = 0
        if mode == MODES.swim or mode == MODES.underwater then swim = swim + yards end
    elseif swim > 0 then
        dry = dry + 1
        if dry >= DRY_STEPS then self:FinishSwim() end
    end

    if swimming and self.IsUnderwater() and BreathTimerRuns() then
        breathStart = breathStart or now
    elseif breathStart then
        self:FinishBreath(now)
    end
end
