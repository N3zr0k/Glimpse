local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Orte für alle Erweiterungen: Karten, Position des Spielers, Entfernungen, Koordinaten, Wegpunkte und die
-- Einheit der Entfernungen. Erweiterungen holen sich das Modul mit
--   local Locations = Glimpse:GetModule("Locations")
-- und rufen dessen Funktionen auf (siehe DEVELOPER.md). Alles hier benutzt nur Spielfunktionen. Weitere
-- Addons (TomTom) sind optional.
local Locations = Glimpse:NewModule("Locations")

-- Version der Schnittstelle, wird erhöht, wenn sich Funktionen ändern oder wegfallen
Locations.API_VERSION = 1

local function Clean(value)
    if value ~= nil and Glimpse.IsSecret and Glimpse:IsSecret(value) then return nil end
    return value
end
Locations.Clean = Clean

-- Alle Blizzard-Funktionen an einer Stelle. Fehlt eine, bleibt der Eintrag nil und die Funktionen
-- liefern nil. Tests können die Einträge ersetzen.
Locations.api = {
    GetBestMapForUnit = C_Map and C_Map.GetBestMapForUnit,
    GetPlayerMapPosition = C_Map and C_Map.GetPlayerMapPosition,
    GetMapInfo = C_Map and C_Map.GetMapInfo,
    GetMapWorldSize = C_Map and C_Map.GetMapWorldSize,
    GetWorldPosFromMapPos = C_Map and C_Map.GetWorldPosFromMapPos,
    IsInInstance = IsInInstance,
    GetInstanceInfo = GetInstanceInfo,
}
