local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Locations = Glimpse:GetModule("Locations")

function Locations:HasTomTom()
    return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

--- Wegpunkt per TomTom, sonst per Spielmarkierung. x, y von 0 bis 1. true, wenn gesetzt.
function Locations:SetWaypoint(map, x, y, title)
    if type(map) ~= "number" or type(x) ~= "number" or type(y) ~= "number" then return false end
    if x <= 0 or y <= 0 or x > 1 or y > 1 then return false end

    if self:HasTomTom() then
        local ok, result = pcall(TomTom.AddWaypoint, TomTom, map, x, y, { title = title, from = "Glimpse" })
        if ok and result ~= false then return true end
    end

    if C_Map and C_Map.SetUserWaypoint and C_Map.CanSetUserWaypointOnMap and CreateVector2D and UiMapPoint
        and UiMapPoint.CreateFromCoordinates then
        local ok = pcall(function()
            if not C_Map.CanSetUserWaypointOnMap(map) then error("not allowed") end
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end)
        if ok then return true end
    end

    return false
end
