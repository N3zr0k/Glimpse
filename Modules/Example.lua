local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Beispielmodul als Vorlage, kann gelöscht werden (dann auch aus Modules.xml nehmen).
-- Externe Erweiterungen sehen genauso aus, nur mit Glimpse statt dem GetAddon-Aufruf.
local Example = Glimpse:NewModule("Example")

function Example:OnEnable()
    -- erscheint nur im Chat, wenn der Debug-Modus an ist
    self:Debug("Example module enabled")
end
