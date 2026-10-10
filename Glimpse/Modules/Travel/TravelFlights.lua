local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Flugzeit: TakeTaxiNode merkt Start- und Zielpunkt, gemessen wird von "auf dem Greifen" bis "wieder abgestiegen".
-- Geprüft wird im Takt der Streckenmessung, die auch die Yards des Flugs liefert. Ausloggen im Flug zählt nicht.
-- Abheben und Landen meldet das Modul als GLIMPSE_TRAVEL_RIDE_START/_END mit kind "flight" (Travel.lua).

local api = Travel.api

local CURRENT = Enum and Enum.FlightPathState and Enum.FlightPathState.Current or 0
local PLAN_TIMEOUT = 10 -- Sekunden; so lange darf es vom Klick bis zum Abflug dauern

local planned -- { from, to } nach TakeTaxiNode
local started -- { from, to, at, yards } sobald der Charakter fliegt

function Travel.RouteID(from, to)
    return from * 10000 + to
end

function Travel:PlanFlight(slotIndex)
    planned = nil
    local nodes = self:TaxiNodes()
    if not nodes then return end
    local from, to
    for _, node in ipairs(nodes) do
        if node.state == CURRENT then from = node.nodeID end
        if node.slotIndex == slotIndex then to = node.nodeID end
    end
    if from and to and from ~= to then planned = { from = from, to = to, at = api.GetTime() } end
end

function Travel:OnTaxiState()
    local onTaxi = Travel.Ask(api.UnitOnTaxi, "player")
    if onTaxi and planned and not started then
        started = { from = planned.from, to = planned.to, at = api.GetTime(), yards = 0 }
        planned = nil
        self.debug:Log("flight", "start %d -> %d", started.from, started.to)
        self:SendMessage("GLIMPSE_TRAVEL_RIDE_START", "flight", Travel.RouteID(started.from, started.to), started.at)
    elseif planned and api.GetTime() - planned.at > PLAN_TIMEOUT then
        planned = nil
    elseif not onTaxi and started then
        local seconds = math.floor(api.GetTime() - started.at + 0.5)
        local route = Travel.RouteID(started.from, started.to)
        self.debug:Log("flight", "%d -> %d in %d s", started.from, started.to, seconds)
        if seconds > 0 then
            self:Count("flight", route)
            self:Count("flighttime", route, seconds)
            local yards = math.floor(started.yards + 0.5)
            if yards > 0 then self:Count("flightdistance", route, yards) end
        end
        started = nil
        self:SendMessage("GLIMPSE_TRAVEL_RIDE_END", "flight", route)
    end
end

--- Strecke aus der Messung zum laufenden Flug addieren
function Travel:AddFlightYards(yards)
    if started then started.yards = started.yards + yards end
end

--- Flug verwerfen, ohne zu zählen
function Travel:CancelFlight()
    if started then self:SendMessage("GLIMPSE_TRAVEL_RIDE_END", "flight", Travel.RouteID(started.from, started.to)) end
    planned, started = nil, nil
end

function Travel:StartFlights()
    self:RegisterEvent("TAXIMAP_OPENED", "RecordFlightPoints")
    if api.hooksecurefunc then
        api.hooksecurefunc("TakeTaxiNode", function(slotIndex) self:PlanFlight(slotIndex) end)
    end
end
