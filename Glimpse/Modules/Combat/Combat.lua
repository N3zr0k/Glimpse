local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Kampf: erfasst für jeden Charakter Kills, Tode, Kampfzeit und Beute. Schreibt in den Namespace "combat" von
-- Glimpse: Database; ohne Database bleibt das Modul still. Erfassung: CombatKills.lua, CombatDeaths.lua, CombatLoot.lua,
-- CombatTime.lua. Anzeige im Kreatur-Tooltip: CombatTooltip.lua, Optionen: CombatOptions.lua.
--
-- Arten (kind) und IDs, Zonen = uiMapID, in Instanzen -instanceID:
--   kill          NPC-ID                 eigene Kills, pro Zone
--   death         NPC-ID des Verursachers, 0 = unbekannt; pro Zone
--   time          0                      Sekunden im Kampf
--   looted        NPC-ID                 geplünderte Leichen (Weltwissen, Nenner für Drop-Chancen)
--   loot:<NPC>    Item-ID                Anzahl erbeutet (Weltwissen)
local Combat = Glimpse:NewModule("Combat")

Combat.NAMESPACE = "combat"

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
Combat.api = {
    GetTime = GetTime,
    After = C_Timer and C_Timer.After,
    UnitGUID = UnitGUID,
    UnitName = UnitName,
    UnitIsDead = UnitIsDead,
    UnitHealth = UnitHealth,
    UnitExists = UnitExists,
    UnitIsUnit = UnitIsUnit,
    UnitCanAttack = UnitCanAttack,
    UnitIsTapDenied = UnitIsTapDenied,
    IsFishingLoot = IsFishingLoot,
    GetNumLootItems = (C_Loot and C_Loot.GetNumLootItems) or GetNumLootItems,
    GetLootSlotType = (C_Loot and C_Loot.GetLootSlotType) or GetLootSlotType,
    GetLootSlotLink = (C_Loot and C_Loot.GetLootSlotLink) or GetLootSlotLink,
    GetLootSourceInfo = (C_Loot and C_Loot.GetLootSourceInfo) or GetLootSourceInfo,
}

function Combat.Clean(value)
    if value ~= nil and Glimpse:IsSecret(value) then return nil end
    return value
end

--- Merkt sich GUIDs für window Sekunden; true, wenn die GUID darin schon vorkam
function Combat.NewSeen(window, max)
    local seen, size = {}, 0
    return function(guid, now)
        local at = seen[guid]
        if at and now - at <= window then return true end
        if not at then
            if size >= max then
                wipe(seen)
                size = 0
            end
            size = size + 1
        end
        seen[guid] = now
        return false
    end
end

function Combat:OnInitialize()
    self.debug = Glimpse:NewDebugger("Combat", { "kill", "death", "loot", "time" })
    self.settings = Glimpse.db:RegisterNamespace("Combat", { profile = self.tooltipDefaults })
end

function Combat:OnEnable()
    local DB = GlimpseDB
    if not DB then return end

    local ns, reason = DB:Register(self.NAMESPACE, { area = "Core", zones = true, world = { loot = true, looted = true } })
    if not ns then
        self.debug:Error("kill", "Database: %s", tostring(reason))
        return
    end
    self.ns = ns

    self:StartKills()
    self:StartDeaths()
    self:StartLoot()
    self:StartTime()
    self:StartTooltip()
end

--- Zählen mit aktueller Zone. Fehler dürfen den Kampf nicht stören.
function Combat:Count(kind, id, amount)
    if not self.ns then return end
    local ok, err = pcall(function()
        self.ns:Count(kind, id, Glimpse.IDs:ZoneKey(), amount)
    end)
    if not ok then self.debug:Error(kind, "%s", tostring(err)) end
end
