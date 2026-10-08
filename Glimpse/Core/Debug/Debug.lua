local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Debug-Modus an/aus und die einfache Ausgabe für Module (ModuleProto:Debug). Kategorien, Stufen und das Log für
-- Tester stehen in Debugger.lua.

-- db ist bei sehr frühen Aufrufen noch nil
function Glimpse:IsDebug()
    return self.db ~= nil and self.db.profile.debug
end

function Glimpse:SetDebug(enabled)
    self.db.profile.debug = enabled and true or false

    -- Checkbox im Panel nachziehen, wenn per Slash-Befehl umgeschaltet
    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.name)

    self:Print(self.db.profile.debug and L["Debug mode enabled"] or L["Debug mode disabled"])
end

--- Debug-Ausgabe mit Quelle, Module erscheinen als Glimpse(Modulname)
function Glimpse:DebugTagged(tag, ...)
    if not self:IsDebug() then return end

    local source
    if tag then
        source = format("%s(%s)", self.name, tag)
    else
        source = self.name
    end

    local text = format("%s: %s", source, strjoin(" ", tostringall(...)))
    self:AddLogLine(text)
    self:Print("|cff9d9d9d[DEBUG]|r " .. text)
end

function Glimpse:Debug(...)
    self:DebugTagged(nil, ...)
end
