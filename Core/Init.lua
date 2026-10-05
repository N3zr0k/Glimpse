local ADDON_NAME = ...

-- Das Addon-Objekt. AceConsole liefert :Print/:Printf und die Slash-Registrierung,
-- AceEvent die Event-Funktionen. Weitere Mixins können hier ergänzt werden.
local Glimpse = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")

-- Global verfügbar machen, damit externe Erweiterungen (eigene Addons) drankommen.
-- Das ist die einzige Stelle, über die von außen auf den Core zugegriffen wird.
_G[ADDON_NAME] = Glimpse -- luacheck: ignore 122

Glimpse.name = ADDON_NAME
Glimpse.L = LibStub("AceLocale-3.0"):GetLocale(ADDON_NAME)

-- Seit Dragonflight liegt die Funktion in C_AddOns, das alte Global kann weg sein.
local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata

--- Liest ein Feld aus der TOC (Version, Author, X-Repo, ...).
-- Mit addonName kann man auch die TOC einer Erweiterung auslesen.
-- Beim Feld "Title" wird ein angehängter Farbblock abgeschnitten. In der TOC steht dort z. B.
-- "Glimpse |cff00ff00v0.0.1|r", damit die Version in der Ingame-Addon-Liste erscheint. Überall
-- sonst im Addon (Optionen, /gli info) soll nur der Name stehen.
function Glimpse:GetMeta(field, addonName)
    local value = GetMeta(addonName or ADDON_NAME, field)
    if field == "Title" and value then
        value = strtrim((gsub(value, "%s*|c%x%x%x%x%x%x%x%x.-|r%s*$", "")))
    end
    return value
end

-- Prototyp für alle Module, auch die aus externen Addons. Muss gesetzt sein,
-- bevor das erste NewModule() aufgerufen wird, sonst bekommen die Module ihn nicht.
-- Dadurch hat jedes Modul self:Debug() und die AceEvent-Funktionen.
local ModuleProto = {}
Glimpse.ModuleProto = ModuleProto -- Core/Tooltip.lua hängt dort die Tooltip-Funktionen an
function ModuleProto:Debug(...)
    Glimpse:DebugTagged(self:GetName(), ...)
end

-- Prototyp und Bibliotheken sind zwei getrennte Einstellungen in AceAddon.
Glimpse:SetDefaultModulePrototype(ModuleProto)
Glimpse:SetDefaultModuleLibraries("AceEvent-3.0")

-- Standardwerte der SavedVariables. Module/Erweiterungen sollten für ihre eigenen
-- Werte einen Namespace benutzen (siehe DEVELOPER.md) und nichts hier eintragen.
local defaults = {
    profile = {
        debug = false,
    },
}

function Glimpse:OnInitialize()
    -- true = Standardprofil "Default" für alle Charaktere teilen
    self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", defaults, true)

    -- Bei Profilwechsel muss das Optionen-Panel neu gezeichnet werden
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:SetupOptions()

    -- Kurzform und ausgeschriebene Form
    self:RegisterChatCommand("gli", "OnSlashCommand")
    self:RegisterChatCommand("glimpse", "OnSlashCommand")
end

function Glimpse:OnEnable()
    self:Debug("Enabled, version", self:GetMeta("Version"))
end

function Glimpse:RefreshConfig()
    LibStub("AceConfigRegistry-3.0"):NotifyChange(self.name)
end
