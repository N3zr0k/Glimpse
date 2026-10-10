local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Sichern: WoW schreibt SavedVariables nur bei Logout und /reload, nach einem Absturz fehlt alles seit dem letzten
-- Mal. Das Modul zählt die Änderungen in Glimpse: Database seit dem Start und fragt beim Betreten eines
-- Ruhebereichs, ob neu geladen werden soll (SavePrompt.lua). Optionen im Tab "Daten": SaveOptions.lua.
-- Ohne Database bleibt das Modul still.
local Save = Glimpse:NewModule("Save", "AceEvent-3.0")

Save.defaults = {
    ask = true,    -- beim Betreten eines Ruhebereichs fragen
    changes = 100, -- ab so vielen Änderungen
    minutes = 30,  -- oder nach so vielen Minuten mit mindestens einer Änderung, 0 = aus
}

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
Save.api = {
    GetTime = GetTime,
    IsResting = IsResting,
    InCombatLockdown = InCombatLockdown,
    UnitIsDeadOrGhost = UnitIsDeadOrGhost,
    ReloadUI = ReloadUI,
}

Save.pending = 0 -- Änderungen seit dem Start (ein Reload setzt sie zurück)

function Save:OnInitialize()
    self.settings = Glimpse.db:RegisterNamespace("Save", { profile = self.defaults })
end

function Save:OnEnable()
    local DB = _G.GlimpseDB
    if not DB then return end

    self.mark = self.api.GetTime()
    DB.RegisterCallback(self, DB.EVENT_CHANGED, "OnDataChanged")
    self:StartPrompt()
end

function Save:OnDataChanged()
    self.pending = self.pending + 1
end

--- Sekunden seit dem Start oder der letzten Rückfrage
function Save:SecondsSinceMark()
    return self.api.GetTime() - (self.mark or self.api.GetTime())
end
