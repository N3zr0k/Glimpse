local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Reisen: Strecke pro Fortbewegungsart und Zonen mit Aufenthaltsdauer, für jeden Charakter. Schreibt in den
-- Namespace "travel" von Glimpse: Database; ohne Database bleibt das Modul still. Keine Wegverläufe.
--
-- Arten (kind) und IDs:
--   distance    Fortbewegungsart (Travel.MODES)   Yards
--   zone        uiMapID, in Instanzen -instanceID  Betreten
--   zonetime    wie zone                           Sekunden
local Travel = Glimpse:NewModule("Travel")

Travel.NAMESPACE = "travel"
Travel.MODES = { walk = 1, mount = 2, swim = 3, taxi = 4, ghost = 5 }

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
Travel.api = {
    GetTime = GetTime,
    UnitOnTaxi = UnitOnTaxi,
    UnitIsGhost = UnitIsGhost,
    IsSwimming = IsSwimming,
    IsMounted = IsMounted,
    HBD = LibStub("HereBeDragons-2.0", true),
}

function Travel:OnInitialize()
    self.debug = Glimpse:NewDebugger("Travel", { "distance", "zone" })
end

function Travel:OnEnable()
    local DB = GlimpseDB
    if not DB then return end

    local ns, reason = DB:Register(self.NAMESPACE, { area = "Core" })
    if not ns then
        self.debug:Error("distance", "Database: %s", tostring(reason))
        return
    end
    self.ns = ns

    self:StartDistance()
    self:StartZones()
    self:RegisterEvent("PLAYER_LOGOUT", function()
        self:FlushDistance()
        self:LeaveZone()
    end)
end

function Travel:Count(kind, id, amount)
    if not self.ns then return end
    local ok, err = pcall(self.ns.Count, self.ns, kind, id, nil, amount)
    if not ok then self.debug:Error(kind, "%s", tostring(err)) end
end
