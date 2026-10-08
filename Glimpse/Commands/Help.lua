local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

Glimpse:RegisterCommand("help", L["Shows this help"], function(self)
    local names = {}
    for name in pairs(self.commands) do tinsert(names, name) end
    table.sort(names)

    self:Print(L["Available commands:"])
    for _, name in ipairs(names) do
        self:Printf("  |cffffd100/glimpse %s|r - %s", name, self.commands[name].desc)
    end
end)
