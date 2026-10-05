local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Der Debug-Schalter liegt im Profil, damit er pro Profil getrennt eingestellt werden kann.
-- db kann beim sehr frühen Aufruf noch nil sein, deshalb die Prüfung.
function Glimpse:IsDebug()
    return self.db ~= nil and self.db.profile.debug
end

function Glimpse:SetDebug(enabled)
    self.db.profile.debug = enabled and true or false

    -- Ohne das bleibt die Checkbox im Settings-Panel auf dem alten Wert,
    -- wenn man den Modus per Slash-Befehl umschaltet.
    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.name)

    self:Print(self.db.profile.debug and L["Debug mode enabled"] or L["Debug mode disabled"])
end

--- Debug-Ausgabe mit Quelle.
-- Module werden als Glimpse(Modulname) ausgegeben.
-- Der Debug-Status wird zentral geprüft.
function Glimpse:DebugTagged(tag, ...)
    if not self:IsDebug() then return end

    local source
    if tag then
        source = format("%s(%s)", self.name, tag)
    else
        source = self.name
    end

    self:Print(format("|cff9d9d9d[DEBUG]|r %s: %s", source, strjoin(" ", tostringall(...))))
end

function Glimpse:Debug(...)
    self:DebugTagged(nil, ...)
end