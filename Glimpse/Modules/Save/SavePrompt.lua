local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Save = Glimpse:GetModule("Save")
local L = Glimpse.L

-- Rückfrage beim Betreten eines Ruhebereichs (Gasthaus, Stadt). Die Taste im Dialog ist ein Klick des Spielers, so
-- darf das Addon neu laden. "Später" fragt erst beim nächsten Ruhebereich oder nach der eingestellten Zeit wieder.

local DIALOG = "GLIMPSE_SAVE_DATA"

--- true, wenn jetzt gefragt werden soll
function Save:ShouldAsk()
    local settings = self.settings.profile
    if not settings.ask or self.pending <= 0 then return false end
    if self.api.InCombatLockdown() or self.api.UnitIsDeadOrGhost("player") then return false end

    if self.pending >= settings.changes then return true end
    return settings.minutes > 0 and self:SecondsSinceMark() >= settings.minutes * 60
end

function Save:Ask()
    -- ab jetzt zählt die Zeit bis zur nächsten Rückfrage neu
    self.mark = self.api.GetTime()
    if StaticPopup_Show then StaticPopup_Show(DIALOG, self.pending) end
end

--- Aus PLAYER_UPDATE_RESTING: nur beim Betreten
function Save:OnResting()
    if self.api.IsResting() and self:ShouldAsk() then self:Ask() end
end

--- Neu laden, damit die SavedVariables geschrieben werden
function Save:ReloadNow()
    self.api.ReloadUI()
end

function Save:StartPrompt()
    if StaticPopupDialogs then
        StaticPopupDialogs[DIALOG] = {
            text = L["Glimpse: %d changes are not saved yet. Reload the interface now to save them?"],
            button1 = L["Reload now"],
            button2 = L["Later"],
            OnAccept = function() Save:ReloadNow() end,
            timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
        }
    end
    self:RegisterEvent("PLAYER_UPDATE_RESTING", "OnResting")
end
