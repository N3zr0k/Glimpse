local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")
local L = Glimpse.L

-- Rekorde: Höchst- und Tiefstwerte in der Database (SetMax/SetMin) und eine Meldung, wenn ein neuer Rekord fällt.
-- Gespeichert wird immer, die Schalter steuern nur die Meldung. Die Erkennung steht in den Dateien TravelRecords*.lua:
--   Speed   speedmax/speedmin   ID = Fortbewegungsart (walk, mount), Yards pro Sekunde
--   Fall    fallmax             ID 0, Yards (Schätzung aus der Fallzeit)
--   Water   breathmax           ID 0, Sekunden unter Wasser am Stück
--           swimmax             ID 0, Yards am Stück geschwommen
--   Jumps   jumpmilestone       ID 0, zuletzt gemeldeter Meilenstein (Sprünge selbst zählt Travel als jump)

local api = Travel.api

Travel.RECORD_DEFAULTS = {
    walk = true, mount = true, fall = true, jump = true, breath = true, swim = true,
    output = "both", -- both, screen, chat
}

local MIN_GAIN = 1.01 -- ein neuer Rekord muss mindestens 1 % besser sein
local PAUSE = 30      -- Sekunden zwischen zwei Meldungen derselben Art
local GOLD = "|cffffd100"

local lastShown = {}

function Travel:RecordOption(name)
    local profile = self.recordSettings and self.recordSettings.profile
    if profile and profile[name] ~= nil then return profile[name] end
    return Travel.RECORD_DEFAULTS[name]
end

local function MapID()
    return Glimpse.IDs and Glimpse.IDs:ZoneKey() or nil
end

--- Wert als Rekord eintragen (lowest = true: Tiefstwert). Gibt true zurück, wenn es ein neuer Rekord ist.
function Travel:NewRecord(kind, id, value, lowest)
    local ns = self.ns
    if not (ns and ns.SetMax and ns.SetMin) then return false end

    local old
    if lowest then old = ns:GetMin(kind, id) else old = ns:GetMax(kind, id) end
    if old then
        if lowest and value > old / MIN_GAIN then return false end
        if not lowest and value < old * MIN_GAIN then return false end
    end
    local ok, isRecord = pcall(lowest and ns.SetMin or ns.SetMax, ns, kind, id, value, MapID())
    if not ok then
        self.debug:Error("records", "%s", tostring(isRecord))
        return false
    end
    return isRecord == true
end

local function Fill(text, vars)
    return (text:gsub("{(%w+)}", function(key) return tostring(vars[key] or "") end))
end

--- Meldung zu einer Art. vars füllt die Platzhalter {name} des Textes; vars.pick wählt den Text, sonst einer zufällig.
function Travel:Announce(kind, vars)
    if not self:RecordOption(kind) then return end
    local now = api.GetTime()
    if kind ~= "jump" and lastShown[kind] and now - lastShown[kind] < PAUSE then return end

    local list = self:RecordTexts(kind)
    local text = list and (list[vars.pick] or (#list > 0 and list[math.random(#list)]))
    if not text then return end
    lastShown[kind] = now
    text = Fill(text, vars)

    local output = self:RecordOption("output")
    if output ~= "screen" then Glimpse:Print(GOLD .. text .. "|r") end
    if output ~= "chat" then api.ShowNotice(text) end
end

-- Tempo als "27 km/h (100 %)" bzw. mph; 100 % ist das normale Lauftempo (7 Yards pro Sekunde)
local RUN_SPEED = 7
function Travel:FormatSpeed(yardsPerSecond)
    local unit = Glimpse.GetDistanceUnit and Glimpse:GetDistanceUnit() or "meters"
    local text
    if unit == "yards" then
        text = format(L["%d mph"], math.floor(yardsPerSecond * 3600 / 1760 + 0.5))
    else
        text = format(L["%d km/h"], math.floor(yardsPerSecond * 0.9144 * 3.6 + 0.5))
    end
    return format("%s (%d %%)", text, math.floor(yardsPerSecond / RUN_SPEED * 100 + 0.5))
end

function Travel:FormatDistance(yards)
    if Glimpse.FormatDistance then return Glimpse:FormatDistance(yards) end
    return format("%d yd", math.floor(yards + 0.5))
end

function Travel:FormatDuration(seconds)
    return format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

--- Alles Laufende beenden (Ladebildschirm, Logout): offene Strecken und Tauchgänge werden gewertet
function Travel:ResetRecords()
    if not self.ns then return end
    self:ResetSpeed()
    self:ResetFall()
    self:ResetWater(api.GetTime())
end

function Travel:StartRecords()
    self:StartFalls()
end

--- Eine Messung der Rekord-Erkennung; mode, yards und der Messzustand (mit speed) kommen aus Measure
function Travel:RecordsTick(mode, yards, state)
    if not self.ns then return end
    local ok, err = pcall(function()
        self:RecordSpeedTick(mode, state and state.speed)
        self:RecordWaterTick(api.GetTime(), yards, mode)
    end)
    if not ok then self.debug:Error("records", "%s", tostring(err)) end
end
