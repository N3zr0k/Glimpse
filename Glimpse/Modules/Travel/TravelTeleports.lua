local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Teleports: Teleport, Ruhestein, Portal. Gezählt je Charakter als teleport, die Strecke zählt nicht.
--   ohne Ladebildschirm  Position springt schneller als MAX_SPEED (TravelDistance.lua)
--   mit Ladebildschirm   danach woanders als davor
-- Kein Teleport: Schiff, Zeppelin und Flugroute (Ladebildschirm unterwegs), Betreten und Verlassen von Instanzen und
-- Ladebildschirme, in die man hineinläuft (z. B. Tiefenbahn). Teleport und Ruhestein wirkt man im Stehen.

local api = Travel.api
local MODES = Travel.MODES

local MIN_YARDS = 200 -- nach dem Ladebildschirm; weniger ist derselbe Ort

local before -- Position und Lage vor dem Ladebildschirm

local function InInstance()
    if not api.IsInInstance then return false end
    local ok, inside = pcall(api.IsInInstance)
    return ok and not Glimpse:IsSecret(inside) and inside == true
end

function Travel:CountTeleport()
    self.debug:Log("distance", "teleport counted")
    self:Count("teleport", 0)
end

--- Lage vor dem Ladebildschirm merken; last = letzte Messung oder nil
function Travel:BeforeLoading(last)
    if not last then
        before = nil
        return
    end
    -- standing kommt aus der letzten Messung (eigene Geschwindigkeit 0)
    local carried = Travel.Ask(api.UnitOnTaxi, "player") or last.mode == MODES.transport or last.mode == MODES.tram
        or last.standing == false
    before = { x = last.x, y = last.y, instance = last.instance, carried = carried, inside = InInstance() }
end

--- Erste Messung nach dem Ladebildschirm: Sprung, wenn der Charakter woanders ist
function Travel:CheckLoadingTeleport(now)
    local old = before
    before = nil
    if not old or old.carried or old.inside or InInstance() then return false end
    if old.instance == now.instance then
        local yards = api.HBD:GetWorldDistance(now.instance, old.x, old.y, now.x, now.y) or 0
        if yards < MIN_YARDS then return false end
    end
    self:CountTeleport()
    return true
end
