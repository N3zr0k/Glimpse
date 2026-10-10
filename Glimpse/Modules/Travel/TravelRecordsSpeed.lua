local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Tempo-Rekorde zu Fuß und beim Reiten. Gemessen wird die Geschwindigkeit aus der Strecke (TravelDistance.lua).
-- Ein Wert zählt erst, wenn er zwei Sekunden gehalten wurde (4 Messungen); kurze Spitzen, Rückstoß oder ein Sturz
-- lösen nichts aus. Der Höchstwert ist das Minimum des Fensters, der Tiefstwert das Maximum (und muss über 1 Yard
-- pro Sekunde liegen). speedmin hat keine Meldung.

local api = Travel.api
local MODES = Travel.MODES

local SAMPLES = 4
local MOVING = 1 -- Yards pro Sekunde, darunter gilt der Charakter als stehend

local window, windowMode = {}, nil

function Travel:ResetSpeed()
    window, windowMode = {}, nil
end

-- Name des aktiven Reittiers: Mount-Journal, sonst der Segen mit einem Reittier-Symbol; nil, wenn nicht lesbar
function Travel:MountName()
    local journal = api.C_MountJournal
    if journal and journal.GetMountIDs and journal.GetMountInfoByID then
        local ok, name = pcall(function()
            for _, id in ipairs(journal.GetMountIDs()) do
                local mountName, _, _, active = journal.GetMountInfoByID(id)
                if active then return mountName end
            end
        end)
        if ok and name then return name end
    end
    if not api.UnitBuff then return nil end
    for index = 1, 40 do
        local ok, name, icon = pcall(api.UnitBuff, "player", index)
        if not ok or not name then return nil end
        if not Glimpse:IsSecret(icon) and type(icon) == "string" and icon:lower():find("ability_mount", 1, true) then
            return name
        end
    end
end

function Travel:RecordSpeed(mode, low, high)
    if not self.ns then return end
    self:NewRecord("speedmin", mode, high, true)
    if not self:NewRecord("speedmax", mode, low) then return end

    local kind = mode == MODES.mount and "mount" or "walk"
    local vars = { speed = self:FormatSpeed(low) }
    if kind == "mount" then vars.mount = self:MountName() or self:RecordTexts("mountFallback") end
    self:Announce(kind, vars)
end

--- Eine Messung der Tempo-Erkennung. mode = Fortbewegungsart der Messung (nil im Stehen), speed in Yards pro Sekunde
function Travel:RecordSpeedTick(mode, speed)
    if (mode ~= MODES.walk and mode ~= MODES.mount) or not speed or Travel.Ask(api.IsFalling) then
        if windowMode then self:ResetSpeed() end
        return
    end
    if windowMode ~= mode then window, windowMode = {}, mode end

    window[#window + 1] = speed
    if #window > SAMPLES then table.remove(window, 1) end
    if #window < SAMPLES then return end

    local low, high = math.huge, 0
    for _, value in ipairs(window) do
        low, high = math.min(low, value), math.max(high, value)
    end
    if low < MOVING then return end
    self:RecordSpeed(mode, low, high)
end
