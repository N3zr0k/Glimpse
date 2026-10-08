local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Vorlage, kann gelöscht werden (dann auch aus Modules.xml). Erweiterungen nutzen das globale Glimpse.
local Example = Glimpse:NewModule("Example")

function Example:OnEnable()
    self:Debug("Example module enabled")
end
