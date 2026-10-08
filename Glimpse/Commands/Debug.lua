local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- /glimpse debug       -> umschalten
-- /glimpse debug on    -> an
-- /glimpse debug off   -> aus
Glimpse:RegisterCommand("debug", L["Toggles debug mode (on/off)"], function(self, args)
    args = strlower(args or "")
    if args == "on" then
        self:SetDebug(true)
    elseif args == "off" then
        self:SetDebug(false)
    else
        self:SetDebug(not self:IsDebug())
    end
end)
