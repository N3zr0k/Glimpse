local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")

-- Tode per PLAYER_DEAD, pro Zone. Ohne Kampflog wird der Verursacher geschätzt: bei Schaden werden Einheiten
-- gesampelt, die den Spieler im Ziel haben (Ziel, Fokus, Bosse, Namensplaketten). Verursacher = zuletzt gesehen,
-- bei Gleichstand die frühere Einheit der Liste. Ohne lesbaren Angreifer zählt der Tod mit ID 0.

local api, Clean = Combat.api, Combat.Clean

local SAMPLE_INTERVAL = 0.3
local ATTACKER_MAX_AGE = 20
local DEATH_REPEAT = 5
local MAX_ATTACKERS = 40

local units = { "target", "focus", "boss1", "boss2", "boss3", "boss4", "boss5" }
for index = 1, 40 do units[#units + 1] = "nameplate" .. index end

local attackers, attackerCount = {}, 0 -- guid -> { npc, at, rank }
local lastSample, lastDeath = -1e9, -1e9

local function Forget()
    wipe(attackers)
    attackerCount = 0
end

local function Ask(func, ...)
    local ok, value = pcall(func, ...)
    return ok and Clean(value) or nil
end

-- NPC-ID einer Kreatur, die den Spieler angreift, sonst nil
local function Attacker(unit)
    if Ask(api.UnitExists, unit) ~= true then return nil end
    local guid = Clean(api.UnitGUID(unit))
    local npc = Glimpse.IDs:NPCFromGUID(guid)
    if not npc then return nil end
    Glimpse.IDs:LearnUnit(unit)
    if Ask(api.UnitCanAttack, "player", unit) ~= true or Ask(api.UnitIsDead, unit) == true then return nil end
    if Ask(api.UnitIsUnit, unit .. "target", "player") ~= true then return nil end
    return guid, npc
end

function Combat:SampleAttackers()
    local now = api.GetTime()
    lastSample = now
    for rank, unit in ipairs(units) do
        local guid, npc = Attacker(unit)
        if guid then
            local entry = attackers[guid]
            if not entry then
                if attackerCount >= MAX_ATTACKERS then Forget() end
                attackerCount = attackerCount + 1
                entry = { rank = rank }
                attackers[guid] = entry
            elseif entry.at ~= now then
                entry.rank = rank
            end
            entry.npc, entry.at = npc, now
        end
    end
end

local function Killer(now)
    local best
    for _, entry in pairs(attackers) do
        if now - entry.at <= ATTACKER_MAX_AGE then
            if not best or entry.at > best.at or (entry.at == best.at and entry.rank < best.rank) then best = entry end
        end
    end
    return best
end

function Combat:OnPlayerDead()
    local now = api.GetTime()
    if now - lastDeath < DEATH_REPEAT then return end
    lastDeath = now

    -- beim Tod haben die Gegner meist schon das Ziel gewechselt, daher zuerst die Samples aus dem Kampf
    local killer = Killer(now)
    if not killer then
        self:SampleAttackers()
        killer = Killer(now)
    end
    Forget()

    self.debug:Log("death", "killer %s", killer and tostring(killer.npc) or "unknown")
    self:Count("death", killer and killer.npc or 0)
end

function Combat:OnPlayerDamaged()
    if api.GetTime() - lastSample >= SAMPLE_INTERVAL then self:SampleAttackers() end
end

function Combat:StartDeaths()
    self:RegisterEvent("PLAYER_DEAD", "OnPlayerDead")
    self:RegisterEvent("UNIT_HEALTH", function(event, unit)
        if unit == "player" then
            self:OnPlayerDamaged()
        elseif unit == "target" then
            self:OnTargetEvent(event)
        end
    end)
end
