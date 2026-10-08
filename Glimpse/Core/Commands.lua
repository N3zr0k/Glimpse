local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Name (klein) -> { desc = Text für /glimpse help, func = Handler }
Glimpse.commands = {}

--- Unterbefehl /glimpse <name> [args]. func(self, args), args = Resteingabe als String.
-- Gleicher Name überschreibt.
function Glimpse:RegisterCommand(name, desc, func)
    self.commands[strlower(name)] = { desc = desc, func = func }
end

function Glimpse:OnSlashCommand(input)
    local cmd, args = strmatch(strtrim(input or ""), "^(%S*)%s*(.-)$")
    cmd = strlower(cmd)
    if cmd == "" then cmd = "help" end

    local entry = self.commands[cmd]
    if not entry then
        self:Print(format(L["Unknown command: %s"], cmd))
        entry = self.commands.help
    end
    entry.func(self, args)
end