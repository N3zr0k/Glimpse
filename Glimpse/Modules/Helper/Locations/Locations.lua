local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Karten, Spielerposition, Entfernungen, Koordinaten, Wegpunkte für Erweiterungen (DEVELOPER.md):
--   local Locations = Glimpse:GetModule("Locations")
-- TomTom ist optional.
local Locations = Glimpse:NewModule("Locations")

-- Erhöhen, wenn Funktionen sich ändern oder wegfallen
Locations.API_VERSION = 1

local function Clean(value)
    if value ~= nil and Glimpse.IsSecret and Glimpse:IsSecret(value) then return nil end
    return value
end
Locations.Clean = Clean

-- Blizzard-API gebündelt, damit Tests sie ersetzen können. Fehlende Einträge = nil-Ergebnisse.
Locations.api = {
    GetBestMapForUnit = C_Map and C_Map.GetBestMapForUnit,
    GetPlayerMapPosition = C_Map and C_Map.GetPlayerMapPosition,
    GetMapInfo = C_Map and C_Map.GetMapInfo,
    GetMapWorldSize = C_Map and C_Map.GetMapWorldSize,
    GetWorldPosFromMapPos = C_Map and C_Map.GetWorldPosFromMapPos,
    IsInInstance = IsInInstance,
    GetInstanceInfo = GetInstanceInfo,
}
