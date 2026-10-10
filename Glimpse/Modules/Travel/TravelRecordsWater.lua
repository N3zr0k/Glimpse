local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Wasser-Rekorde: längste Zeit mit angehaltenem Atem am Stück (breathmax, Sekunden), längste Strecke dabei
-- getaucht (divemax, Yards) und längste Strecke am Stück geschwommen (swimmax, Yards). Gewertet wird beim Auftauchen bzw. Verlassen des Wassers, damit die Meldung nicht
-- mitten im Tauchgang kommt. Eine Strecke endet erst, wenn der Charakter 2 Messungen lang nicht schwimmt.

local api = Travel.api
local MODES = Travel.MODES

local MIN_BREATH = 5   -- Sekunden
local MIN_SWIM = 20    -- Yards
local MIN_DIVE = 20
local DRY_STEPS = 2

local breathStart
local dive = 0
local swim, dry = 0, 0

-- Die Atemleiste läuft, solange der Atem angehalten wird (mit Wasseratmung steht sie). nil, wenn der Client keine
-- Leisten meldet; dann entscheidet "getaucht".
local function BreathTimerRuns()
    if not api.GetMirrorTimerInfo then return nil end
    for index = 1, 3 do
        local timer, _, _, scale, paused = api.GetMirrorTimerInfo(index)
        if timer == "BREATH" and (scale or 0) < 0 and not Travel.TimerPaused(paused) then return true end
    end
    return false
end

function Travel:FinishBreath(now)
    if not breathStart then return end
    local seconds, yards = now - breathStart, dive
    breathStart, dive = nil, 0
    if yards >= MIN_DIVE and self:NewRecord("divemax", 0, yards) then
        self:Announce("dive", { distance = self:FormatDistance(yards) })
    end
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

    -- Die Zeit läuft ab dem Moment, in dem die Atemleiste startet, nicht erst beim Abtauchen
    local bar = BreathTimerRuns()
    local holding = bar
    if bar == nil then holding = swimming and self.IsUnderwater() end
    if holding then
        breathStart = breathStart or now
        if mode == MODES.swim or mode == MODES.underwater then dive = dive + yards end
    elseif breathStart then
        self:FinishBreath(now)
    end
end

-- /gli probe travel water: Rohwerte des Clients und der Stand der laufenden Messung
function Travel:WaterProbe()
    local lines = {
        format("IsSwimming: %s", tostring(Travel.Ask(api.IsSwimming))),
        format("IsSubmerged: %s", api.IsSubmerged and tostring(Travel.Ask(api.IsSubmerged)) or "missing"),
        format("underwater: %s, breath bar runs: %s", tostring(Travel.IsUnderwater()), tostring(BreathTimerRuns())),
        format("holding breath since: %s", breathStart and format("%.1f s ago", api.GetTime() - breathStart) or "no"),
        format("swim distance: %.0f yd (dry steps %d), dived: %.0f yd", swim, dry, dive),
    }
    if not api.GetMirrorTimerInfo then
        lines[#lines + 1] = "GetMirrorTimerInfo: missing"
        return lines
    end
    for index = 1, 3 do
        local timer, initial, maximum, scale, paused, label = api.GetMirrorTimerInfo(index)
        lines[#lines + 1] = format("timer %d: %s initial=%s max=%s scale=%s paused=%s label=%s", index, tostring(timer),
            tostring(initial), tostring(maximum), tostring(scale), tostring(paused), tostring(label))
    end
    return lines
end
