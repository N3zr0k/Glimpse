local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Rekord: längste Strecke am Stück gelaufen (walkmax, Yards). Die Strecke endet, wenn der Charakter länger als
-- 5 Sekunden steht oder die Fortbewegungsart wechselt (aufsitzen, schwimmen, Flugroute ...). Sprünge und Stürze
-- unterbrechen sie nicht. Gewertet und gemeldet wird beim Ende.

local MODES = Travel.MODES

local MIN_WALK = 200  -- Yards
local STAND_STEPS = 10 -- Messungen im Stehen (5 Sekunden), dann endet die Strecke

local walked, standing = 0, 0

function Travel:FinishWalk()
    local yards = walked
    walked, standing = 0, 0
    if yards >= MIN_WALK and self:NewRecord("walkmax", 0, yards) then
        self:Announce("walkdist", { distance = self:FormatDistance(yards) })
    end
end

--- Eine Messung; mode ist nil im Stehen
function Travel:RecordWalkTick(mode, yards)
    if mode == MODES.walk then
        walked, standing = walked + yards, 0
    elseif mode == nil then
        standing = standing + 1
        if standing >= STAND_STEPS and walked > 0 then self:FinishWalk() end
    elseif walked > 0 then
        self:FinishWalk()
    end
end
