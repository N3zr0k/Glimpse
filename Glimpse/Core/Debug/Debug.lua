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

--- Debug-Ausgabe mit Addon-Kennung und Quelle: [Glimpse: Gathering] GatheringTooltip: Text.
-- addon = Addon-Ordner (nil = Core), tag = Modulname oder nil
function Glimpse:DebugFrom(addon, tag, ...)
    if not self:IsDebug() then return end

    local text = strjoin(" ", tostringall(...))
    if tag then text = tag .. ": " .. text end
    self:AddLogLine(self:DebugTag(addon, true) .. " " .. text)
    self:Print(self:DebugTag(addon) .. " |cff9d9d9d" .. text .. "|r")
end

function Glimpse:Debug(...)
    if not self:IsDebug() then return end
    self:DebugFrom(self:FindCallerAddon(2), nil, ...)
end
