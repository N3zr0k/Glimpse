local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Sprung-Meilensteine: bei jedem erreichten Stand der Sprünge dieses Charakters ein Spruch. Ab 10000 folgen nur
-- noch 100000 und 1 Million, danach kommt nichts mehr. Welcher Meilenstein zuletzt gemeldet wurde, steht pro
-- Charakter in der Database (jumpmilestone), damit keiner doppelt kommt.

Travel.JUMP_MILESTONES = { 100, 500, 1000, 2500, 5000, 10000, 100000, 1000000 }

local nextMilestone

--- Nach jedem gezählten Sprung aufrufen
function Travel:CheckJumpMilestone()
    local ns = self.ns
    if not (ns and ns.GetCount and ns.SetMax) then return end

    local total = ns:GetCount("jump", 0)
    if nextMilestone and total < nextMilestone then return end

    local reached, upcoming
    for _, milestone in ipairs(self.JUMP_MILESTONES) do
        if total >= milestone then reached = milestone elseif not upcoming then upcoming = milestone end
    end
    nextMilestone = upcoming or math.huge
    if not reached then return end

    if self:NewRecord("jumpmilestone", 0, reached) then
        self:Announce("jump", { pick = reached })
    end
end
