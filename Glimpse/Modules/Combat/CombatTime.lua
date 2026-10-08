local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")

-- Kampfzeit in Sekunden (time [0]), gezählt am Kampfende

local api = Combat.api

local started

function Combat:OnRegenDisabled()
    started = api.GetTime()
end

function Combat:OnRegenEnabled(event)
    if started then
        local seconds = api.GetTime() - started
        started = nil
        self.debug:Log("time", "%.1f s", seconds)
        self:Count("time", 0, seconds)
    end
    self:OnTargetEvent(event)
end

function Combat:StartTime()
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnRegenDisabled")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnRegenEnabled")
end
