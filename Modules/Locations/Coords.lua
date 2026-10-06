local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Locations = Glimpse:GetModule("Locations")

--- Koordinaten (0 bis 1) als Text in Prozent, wie sie auf der Karte stehen: "41.2, 56.8" (mit Dezimalkomma im
-- deutschen Client). decimals: Nachkommastellen, Standard 1. Ohne gültige Zahlen nil.
function Locations:FormatCoords(x, y, decimals)
    if type(x) ~= "number" or type(y) ~= "number" then return nil end

    local pattern = "%." .. (decimals or 1) .. "f"
    local text = format(pattern .. ", " .. pattern, x * 100, y * 100)
    if GetLocale and GetLocale() == "deDE" then text = text:gsub("(%d)%.(%d)", "%1,%2") end
    return text
end
