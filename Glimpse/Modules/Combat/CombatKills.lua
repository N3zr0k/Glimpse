local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")

-- Kills ohne Kampflog (für Addons gesperrt). Quellen:
--   PARTY_KILL      Killer ist Spieler oder eigenes Pet; kennt der Client das Event, gilt nur diese Quelle
--   Tod des Ziels   Ersatz ohne PARTY_KILL; fremd getappte Ziele zählen nicht
--   Leiche geplündert  Kills ohne Ziel (Fläche, Pet), aufgerufen aus CombatLoot.lua
-- Jede Leiche zählt einmal über ihre GUID, egal aus welcher Quelle; dieselbe GUID nach CREATURE_REPEAT Sekunden
-- wieder (GUIDs werden wiederverwendet).

local api, Clean = Combat.api, Combat.Clean

local CREATURE_REPEAT = 600
local Seen = Combat.NewSeen(CREATURE_REPEAT, 2000)

local targetGUID -- letzte lesbare GUID des Ziels, im Kampf ist sie teils gesperrt

function Combat:CountKill(guid, source)
    local npc = Glimpse.IDs:NPCFromGUID(guid)
    if not npc then return false end
    if Seen(guid, api.GetTime()) then return false end

    self.debug:Log("kill", "%s via %s", tostring(npc), source)
    self:Count("kill", npc)
    return true
end

function Combat:OnPartyKill(_, killer, victim)
    killer, victim = Clean(killer), Clean(victim)
    if type(killer) ~= "string" or type(victim) ~= "string" then return end
    if killer ~= Clean(api.UnitGUID("player")) and killer ~= Clean(api.UnitGUID("pet")) then return end
    self:CountKill(victim, "party kill")
end

-- nil bei geschützten Werten; Health 0 zählt, weil UnitIsDead beim Event teils noch false ist
local function TargetDead()
    local ok, dead = pcall(api.UnitIsDead, "target")
    if ok and Clean(dead) == true then return true end
    local hOK, health = pcall(api.UnitHealth, "target")
    health = hOK and Clean(health) or nil
    if type(health) == "number" then return health <= 0 end
end

function Combat:CheckTargetKill()
    if self.partyKill or TargetDead() ~= true then return end

    local guid = Clean(api.UnitGUID("target"))
    if type(guid) ~= "string" then guid = targetGUID end
    if type(guid) ~= "string" then return end

    local ok, denied = pcall(api.UnitIsTapDenied, "target")
    if ok and Clean(denied) == true then return end
    self:CountKill(guid, "target death")
end

function Combat:OnTargetEvent(event)
    local guid = Clean(api.UnitGUID("target"))
    if type(guid) == "string" then
        targetGUID = guid
    elseif event == "PLAYER_TARGET_CHANGED" then
        targetGUID = nil
    end
    self:CheckTargetKill()

    -- Tod ist am Kampfende teils noch nicht sichtbar
    if event == "PLAYER_REGEN_ENABLED" and api.After then
        api.After(0.5, function() self:CheckTargetKill() end)
        api.After(2, function() self:CheckTargetKill() end)
    end
end

function Combat:StartKills()
    -- Ohne PARTY_KILL bleibt der Tod des Ziels als Ersatz
    self.partyKill = pcall(self.RegisterEvent, self, "PARTY_KILL", "OnPartyKill")
    self:RegisterEvent("PLAYER_TARGET_CHANGED", "OnTargetEvent")
    -- UNIT_HEALTH registriert CombatDeaths.lua, PLAYER_REGEN_ENABLED CombatTime.lua; beide rufen OnTargetEvent
end
