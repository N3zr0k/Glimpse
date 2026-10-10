local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Flugpunkte: beim Öffnen der Flugkarte alle Knoten als Orte (nodeID auf der Karte) und die bekannten einmal je
-- Charakter als flightpoint. Namen speichern wir nicht, die liefert der Client über C_TaxiMap in jeder Sprache.

local api = Travel.api

local UNREACHABLE = Enum and Enum.FlightPathState and Enum.FlightPathState.Unreachable or 2

--- Knoten der offenen Flugkarte: Liste { nodeID, slotIndex, x, y, state, name }, mapID; nil ohne Flugkarte
function Travel:TaxiNodes()
    if not (api.C_TaxiMap and api.C_TaxiMap.GetAllTaxiNodes) then return nil end
    local mapID = api.GetTaxiMapID and api.GetTaxiMapID()
    if not mapID then return nil end
    local nodes = {}
    for _, node in ipairs(api.C_TaxiMap.GetAllTaxiNodes(mapID) or {}) do
        local x, y = node.position and node.position.x, node.position and node.position.y
        if node.nodeID and x and y then
            nodes[#nodes + 1] = {
                nodeID = node.nodeID, slotIndex = node.slotIndex, x = x, y = y, state = node.state, name = node.name,
            }
        end
    end
    return nodes, mapID
end

--- Flugkarte auslesen; gibt die Zahl neu bekannter Flugpunkte zurück
function Travel:RecordFlightPoints()
    local nodes, mapID = self:TaxiNodes()
    if not (nodes and self.ns) then return 0 end
    local added = 0
    for _, node in ipairs(nodes) do
        self.ns:AddLocation(node.nodeID, mapID, node.x, node.y)
        if node.state ~= UNREACHABLE and (self.ns:GetCount("flightpoint", node.nodeID) or 0) == 0 then
            self:Count("flightpoint", node.nodeID)
            added = added + 1
        end
    end
    self.debug:Log("flight", "%d nodes on map %d, %d new", #nodes, mapID, added)
    return added
end
