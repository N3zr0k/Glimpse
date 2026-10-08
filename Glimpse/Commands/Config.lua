local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

Glimpse:RegisterCommand("config", L["Opens the addon settings"], function(self)
    self:OpenOptions()
end)
