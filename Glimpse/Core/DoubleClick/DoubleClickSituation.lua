local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local DC = Glimpse:GetModule("DoubleClick")

-- Lage beim zweiten Klick. Jeder Handler bekommt sie als ctx und kann mit "when" darauf filtern:
--   standing, moving, falling, swimming, underwater, mounted, canMount, flying, flyable, indoors, outdoors
--   (true/false), dazu modifier, button, now. Die Namen folgen den Makro-Bedingungen ([mounted], [swimming] ...).
-- Wer im Makro selbst Bedingungen braucht, kann als Aktion macrotext liefern; die prüft dann der Client.
-- canMount ist geschätzt (draußen, nicht im Wasser, nicht im Kampf, nicht schon aufgesessen); der Client hat dafür
-- keine eigene Abfrage.

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
DC.api = {
    GetTime = GetTime,
    GetUnitSpeed = GetUnitSpeed,
    IsFalling = IsFalling,
    IsSwimming = IsSwimming,
    IsSubmerged = IsSubmerged,
    GetMirrorTimerInfo = GetMirrorTimerInfo,
    IsMounted = IsMounted,
    IsFlying = IsFlying,
    IsFlyableArea = IsFlyableArea,
    IsIndoors = IsIndoors,
    IsOutdoors = IsOutdoors,
    InCombatLockdown = InCombatLockdown,
    UnitAffectingCombat = UnitAffectingCombat,
    IsShiftKeyDown = IsShiftKeyDown,
    IsControlKeyDown = IsControlKeyDown,
    IsAltKeyDown = IsAltKeyDown,
}
local api = DC.api

-- true/false aus einer Abfrage, die es im Client nicht geben muss
local function Ask(func, ...)
    if not func then return false end
    local ok, value = pcall(func, ...)
    if not ok or Glimpse:IsSecret(value) then return false end -- geschützte Werte nicht vergleichen
    return value == true or value == 1
end

-- Ohne IsSubmerged: die Atemleiste läuft nur unter Wasser
local function Underwater()
    if api.IsSubmerged then return Ask(api.IsSubmerged) end
    if not api.GetMirrorTimerInfo then return false end
    for index = 1, 3 do
        local ok, timer, _, _, scale, paused = pcall(api.GetMirrorTimerInfo, index)
        if ok and timer == "BREATH" and (scale or 0) < 0 and not paused then return true end
    end
    return false
end

function DC:InCombat()
    return Ask(api.InCombatLockdown) or Ask(api.UnitAffectingCombat, "player")
end

--- "SHIFT", "CTRL", "ALT", "NONE" oder nil bei mehreren Tasten zugleich
function DC:HeldModifier()
    local shift, ctrl, alt = Ask(api.IsShiftKeyDown), Ask(api.IsControlKeyDown), Ask(api.IsAltKeyDown)
    local count = (shift and 1 or 0) + (ctrl and 1 or 0) + (alt and 1 or 0)
    if count == 0 then return "NONE" end
    if count > 1 then return nil end
    return shift and "SHIFT" or ctrl and "CTRL" or "ALT"
end

function DC:Situation(modifier, button)
    local speed = 0
    if api.GetUnitSpeed then
        local ok, value = pcall(api.GetUnitSpeed, "player")
        speed = ok and not Glimpse:IsSecret(value) and tonumber(value) or 0
    end
    local falling = Ask(api.IsFalling)
    local swimming = Ask(api.IsSwimming)
    local mounted = Ask(api.IsMounted)
    local indoors = Ask(api.IsIndoors) or (api.IsOutdoors ~= nil and not Ask(api.IsOutdoors))

    return {
        modifier = modifier,
        button = button,
        now = api.GetTime and api.GetTime() or 0,
        moving = speed > 0,
        standing = speed == 0 and not falling,
        falling = falling,
        swimming = swimming,
        underwater = Underwater(),
        mounted = mounted,
        flying = Ask(api.IsFlying),
        flyable = Ask(api.IsFlyableArea),
        indoors = indoors,
        outdoors = not indoors,
        canMount = not mounted and not swimming and not indoors and not self:InCombat(),
    }
end
