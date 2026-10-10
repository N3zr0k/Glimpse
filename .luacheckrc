-- luacheck-Konfiguration für alle Glimpse-Addons (WoW Forever, Lua 5.1-Dialekt)
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "**/Libs/**" }
ignore = {
    "212/self",   -- ungenutztes self
    "212/_.*",    -- ungenutzte Argumente mit Unterstrich
    "211/ADDON_NAME",
}

-- Globale, die die Addons selbst setzen
globals = {
    "Glimpse", "GlimpseSettings", "GlimpseGatheringDB", "GlimpseStatisticsDB", "SLASH_GLIMPSE1", "StaticPopupDialogs",
    -- Glimpse_Database: API und SavedVariables
    "GlimpseDB", "GlimpseDB_Meta", "GlimpseDB_Core", "GlimpseDB_Gathering", "GlimpseDB_Professions",
    "GlimpseDB_Reputation", "GlimpseDB_Misc",
}

-- Blizzard-API und Mixins (nur lesen)
read_globals = {
    "LibStub", "CreateFrame", "C_Timer", "C_Item", "C_Loot", "C_AddOns", "C_ClickBindings", "C_Spell",
    "C_Container", "C_TooltipInfo", "C_ActionBar", "Enum", "TooltipDataProcessor",
    "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2", "UIParent", "Settings",
    "GetTime", "UnitGUID", "UnitName", "UnitLevel", "GetLocale", "GetAddOnMetadata", "IsAddOnLoaded",
    "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "issecretvalue", "hooksecurefunc",
    "GetProfessions", "GetProfessionInfo", "GetItemInfoInstant", "GetNumLootItems", "GetLootSlotType",
    "GetLootSlotLink", "GetLootSourceInfo", "GetBindingKey", "GetBindingText", "GetBindingAction",
    "GetActionInfo", "GetMacroInfo", "GetMacroBody", "GetShapeshiftForm", "GetBonusBarOffset",
    "GetActionBarPage", "GetOverrideBarIndex", "HasVehicleActionBar", "HasOverrideActionBar",
    "HasBonusActionBar", "GetNumShapeshiftForms", "InCombatLockdown", "GetCVar",
    "tinsert", "tremove", "wipe", "format", "strsplit", "strjoin", "strmatch", "strtrim", "strlower",
    "strupper", "strfind", "gsub", "strsub", "tostringall", "date", "time", "ceil", "floor",
    "tContains", "CopyTable", "Mixin", "_G",
    "SlashCmdList", "NUM_ACTIONBAR_BUTTONS", "bit", "geterrorhandler", "issecrettable", "TooltipUtil",
    "GetBuildInfo", "GetNumAddOns", "GetAddOnInfo", "GetAddOnDependencies", "MAX_ACCOUNT_MACROS",
    "GetNumBindings", "GetBinding", "GetShapeshiftFormInfo", "GetNumMacros", "GetMacroItem",
    "GetMacroSpell", "ITEM_QUALITY_COLORS",
    -- Doppelklick-Verteiler (Core/DoubleClick)
    "GetUnitSpeed", "IsFalling", "IsFlying", "IsFlyableArea", "IsSubmerged", "GetMirrorTimerInfo", "IsIndoors", "IsOutdoors", "UnitAffectingCombat",
    "C_TaxiMap", "GetTaxiMapID",
    "SetOverrideBindingClick", "ClearOverrideBindings", "IsMouselooking", "MouselookStop", "IsMouseButtonDown",
    "SHIFT_KEY_TEXT", "CTRL_KEY_TEXT", "ALT_KEY_TEXT",
    -- Orte, Wegpunkte und Fehlerfenster (Modul Locations, GatheringTooltip); TomTom ist optional
    "C_Map", "C_SuperTrack", "UiMapPoint", "CreateVector2D", "IsInInstance", "GetInstanceInfo", "TomTom",
    "StaticPopup_Show", "OKAY", "UISpecialFrames", "YES", "NO",
    -- Module Kampf und Reisen, ID-Helfer; Glimpse_Database ist optional
    "Item", "GetItemInfo", "GetSpellInfo", "UnitIsDead", "UnitHealth", "UnitExists", "UnitIsUnit",
    "UnitCanAttack", "UnitIsTapDenied", "IsFishingLoot", "UnitOnTaxi", "UnitIsGhost", "IsSwimming", "IsMounted",
    -- Glimpse_Database
    "GetServerTime", "UnitClass", "GetRealmName", "debugprofilestop", "debugstack", "unpack",
}

