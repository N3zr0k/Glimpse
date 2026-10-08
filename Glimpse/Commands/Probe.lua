local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- /glimpse probe                         Liste der Probes
-- /glimpse probe <Gruppe> <Name> [args]  eine Probe ausführen (Core/Debug/Probes.lua)
Glimpse:RegisterCommand("probe", L["Runs a test probe (without arguments: list)"], function(self, args)
    local group, name, rest = strmatch(strtrim(args or ""), "^(%S*)%s*(%S*)%s*(.-)$")
    if group == "" then
        self:ListProbes()
    else
        self:RunProbe(group, name, rest)
    end
end)
