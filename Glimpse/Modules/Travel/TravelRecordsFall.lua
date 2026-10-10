local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Fallrekord. Die Tiefe wird aus der Fallzeit geschätzt (freier Fall mit Endgeschwindigkeit), der Client nennt keine
-- Höhe. Gezählt wird ab 14 Yards, wo auch der Fallschaden beginnt; Sprünge liegen deutlich darunter. Das Ende ist
-- die Landung oder das Eintauchen ins Wasser. Prüfung alle 0,1 s, damit die Zeit genau genug ist.

local api = Travel.api

local GRAVITY = 19.29  -- Yards pro Sekunde zum Quadrat
local TERMINAL = 60    -- Endgeschwindigkeit in Yards pro Sekunde
local MIN_DEPTH = 14
local INTERVAL = 0.1

local startedAt

--- Fallhöhe in Yards nach der angegebenen Fallzeit
function Travel:FallDepth(seconds)
    local reach = TERMINAL / GRAVITY
    if seconds <= reach then return 0.5 * GRAVITY * seconds * seconds end
    return 0.5 * GRAVITY * reach * reach + TERMINAL * (seconds - reach)
end

function Travel:ResetFall()
    startedAt = nil
end

function Travel:FallTick(now)
    local falling = Travel.Ask(api.IsFalling) and not Travel.Ask(api.IsSwimming)
        and not Travel.Ask(api.UnitOnTaxi, "player")
    if falling then
        startedAt = startedAt or now
        return
    end
    if not startedAt then return end

    local depth = self:FallDepth(now - startedAt)
    startedAt = nil
    if depth < MIN_DEPTH then return end
    if self:NewRecord("fallmax", 0, depth) then
        self:Announce("fall", { depth = self:FormatDistance(depth) })
    end
end

function Travel:StartFalls()
    local frame = CreateFrame("Frame")
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < INTERVAL then return end
        elapsed = 0
        local ok, err = pcall(self.FallTick, self, api.GetTime())
        if not ok then self.debug:Error("records", "%s", tostring(err)) end
    end)
    self.fallFrame = frame
end
