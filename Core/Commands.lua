local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Registry: Befehlsname (klein) -> { desc = Text für /glimpse help, func = Handler }
Glimpse.commands = {}

--- Registriert einen Unterbefehl, aufrufbar als /glimpse <name> [args].
-- func wird mit (self, args) aufgerufen, args ist der Rest der Eingabe als String.
-- Wer denselben Namen nochmal registriert, überschreibt den alten Befehl.
function Glimpse:RegisterCommand(name, desc, func)
    self.commands[strlower(name)] = { desc = desc, func = func }
end

-- Zentraler Einstiegspunkt für /glimpse und /gli
function Glimpse:OnSlashCommand(input)
    -- erstes Wort = Befehl, alles danach = Argumente
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