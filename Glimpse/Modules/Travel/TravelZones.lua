local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Zonen: zone [Zone] beim Betreten, zonetime [Zone] mit den Sekunden beim Verlassen und Ausloggen.

local api = Travel.api

local current, enteredAt

function Travel:LeaveZone()
    if not current then return end
    local seconds = math.floor(api.GetTime() - enteredAt)
    if seconds > 0 then self:Count("zonetime", current, seconds) end
    current, enteredAt = nil, nil
end

function Travel:UpdateZone()
    local zone = Glimpse.IDs:ZoneKey()
    if zone == current then return end

    self:LeaveZone()
    if not zone then return end
    current, enteredAt = zone, api.GetTime()
    self.debug:Log("zone", "%s", tostring(zone))
    self:Count("zone", zone)
end

function Travel:StartZones()
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "UpdateZone")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateZone")
    self:UpdateZone()
end
