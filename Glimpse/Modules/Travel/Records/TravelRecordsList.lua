local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")
local L = Glimpse.L

-- Liste der Rekorde im Chat (Knopf in den Optionen). Erst der Wert dieses Charakters, in Klammern der beste des
-- Accounts, wenn er davon abweicht.

local MODES = Travel.MODES

local function Both(ns, getter, kind, id, format_)
    local own = ns[getter](ns, kind, id)
    if not own then return nil end
    local text = format_(own)
    local best = ns[getter](ns, kind, id, "account")
    if best and best ~= own then text = text .. " (" .. format_(best) .. ")" end
    return text
end

function Travel:PrintRecords()
    local ns = self.ns
    if not (ns and ns.GetMax) then
        Glimpse:Print(L["Records need Glimpse: Database."])
        return
    end

    local function Speed(value) return self:FormatSpeed(value) end
    local function Distance(value) return self:FormatDistance(value) end
    local function Duration(value) return self:FormatDuration(value) end
    local function Whole(value) return format("%d", value) end

    local rows = {
        { L["Running, fastest"], Both(ns, "GetMax", "speedmax", MODES.walk, Speed) },
        { L["Running, slowest"], Both(ns, "GetMin", "speedmin", MODES.walk, Speed) },
        { L["Riding, fastest"], Both(ns, "GetMax", "speedmax", MODES.mount, Speed) },
        { L["Riding, slowest"], Both(ns, "GetMin", "speedmin", MODES.mount, Speed) },
        { L["Deepest fall"], Both(ns, "GetMax", "fallmax", 0, Distance) },
        { L["Longest time under water"], Both(ns, "GetMax", "breathmax", 0, Duration) },
        { L["Longest swim"], Both(ns, "GetMax", "swimmax", 0, Distance) },
        { L["Longest dive"], Both(ns, "GetMax", "divemax", 0, Distance) },
        { L["Longest walk"], Both(ns, "GetMax", "walkmax", 0, Distance) },
        { L["Jump milestone"], Both(ns, "GetMax", "jumpmilestone", 0, Whole) },
    }
    Glimpse:Print(L["Records (this character, best of the account in brackets):"])
    for _, row in ipairs(rows) do
        Glimpse:Print(format("%s: %s", row[1], row[2] or L["none yet"]))
    end
end
