local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Sprünge mit der Leertaste: je Druck auf die Sprungtaste ein jump, aber nur vom Boden aus. Im Wasser (Auftauchen),
-- in der Luft und auf der Flugroute zählt der Tastendruck nicht.

local api = Travel.api

function Travel:OnJump()
    if Travel.Ask(api.UnitOnTaxi, "player") or Travel.Ask(api.IsSwimming) then return false end
    if Travel.Ask(api.IsFalling) then return false end
    -- Sprung vom Boden: der Sturzmesser (TravelRecordsFall.lua) fängt neu an, mehrere Sprünge hintereinander
    -- ergeben so nie einen Sturz
    self:ResetFall()
    self:Count("jump", 0)
    self:CheckJumpMilestone()
    return true
end

function Travel:StartJumps()
    if api.hooksecurefunc then
        api.hooksecurefunc("JumpOrAscendStart", function() self:OnJump() end)
    end
end
