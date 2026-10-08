local ADDON_NAME = ...

local Glimpse = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

-- Einziger globaler Zugriffspunkt für Erweiterungen
_G[ADDON_NAME] = Glimpse -- luacheck: ignore 122

Glimpse.name = ADDON_NAME
Glimpse.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Ältere Clients haben nur das Global
local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

--- TOC-Feld lesen, optional einer anderen Erweiterung (addonName).
-- Bei "Title" wird der farbige Versionsblock aus der TOC abgeschnitten.
function Glimpse:GetMeta(field, addonName)
    local value = GetMeta(addonName or ADDON_NAME, field)
    if field == "Title" and value then
        value = strtrim((gsub(value, "%s*|c%x%x%x%x%x%x%x%x.-|r%s*$", "")))
    end
    return value
end

-- Prototyp für alle Module inkl. Erweiterungen, muss vor dem ersten NewModule() stehen
local ModuleProto = {}
Glimpse.ModuleProto = ModuleProto -- Tooltip-Funktionen kommen aus Core/Tooltip.lua
function ModuleProto:Debug(...)
    Glimpse:DebugTagged(self:GetName(), ...)
end

Glimpse:SetDefaultModulePrototype(ModuleProto)
Glimpse:SetDefaultModuleLibraries("AceEvent-3.0")

-- Module/Erweiterungen nutzen eigene Namespaces (DEVELOPER.md), nicht diese Tabelle
local defaults = {
    profile = {
        debug = false,
        distanceUnit = "auto", -- auto (nach Client-Sprache), yards, meters
    },
}

function Glimpse:OnInitialize()
    -- true = Profil "Default" für alle Charaktere
    self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", defaults, true)

    -- Optionen-Panel nach Profilwechsel neu zeichnen
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:SetupOptions()

    self:RegisterChatCommand("gli", "OnSlashCommand")
    self:RegisterChatCommand("glimpse", "OnSlashCommand")
end

function Glimpse:OnEnable()
    self:Debug("Enabled, version", self:GetMeta("Version"))
end

function Glimpse:RefreshConfig()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.name)
end
