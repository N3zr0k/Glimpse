local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Debugger mit Kategorien für Core-Module und Erweiterungen:
--   local debug = Glimpse:NewDebugger("Professions", { "fishing", "lure" })
--   debug:Log("lure", "Köder %s erkannt", name)    nur im Debug-Modus und wenn die Kategorie an ist
--   debug:Warn("lure", ...)                          wie Log, gelb
--   debug:Error("lure", ...)                         immer sichtbar, rot
--   if debug:IsOn("lure") then ... end               vor teurer Arbeit für eine Debug-Zeile
-- Ausgabe einheitlich als [Glimpse:Professions/lure]. Kategorien sind standardmäßig an und werden einzeln mit
-- /gli debug Professions lure off abgeschaltet. Gleiche Meldungen kurz hintereinander werden zusammengefasst.

local LOG_SIZE = 500    -- Zeilen im Speicher für /gli debug log
local REPEAT_WINDOW = 2 -- Sekunden, in denen dieselbe Zeile nur gezählt wird

local COLORS = { log = "|cff9d9d9d", warn = "|cffffd100", error = "|cffff4040" }

Glimpse.debuggers = {}

-- Ringpuffer, nur im Speicher
local log, logStart = {}, 1

function Glimpse:AddLogLine(text)
    local stamp = date("%H:%M:%S")
    if #log < LOG_SIZE then
        log[#log + 1] = stamp .. " " .. text
    else
        log[logStart] = stamp .. " " .. text
        logStart = logStart % LOG_SIZE + 1
    end
end

--- Alle Log-Zeilen, älteste zuerst
function Glimpse:GetLogLines()
    local lines = {}
    for i = 0, #log - 1 do
        lines[#lines + 1] = log[(logStart - 1 + i) % #log + 1]
    end
    return lines
end

local Debugger = {}
local DebuggerMeta = { __index = Debugger }

local function Settings()
    local profile = Glimpse.db and Glimpse.db.profile
    return profile and profile.debugOff
end

function Debugger:IsOn(category)
    if not Glimpse:IsDebug() then return false end
    local off = Settings()
    return not (off and off[self.name] and off[self.name][category])
end

function Debugger:SetCategory(category, enabled)
    local off = Settings()
    if not off then return end
    off[self.name] = off[self.name] or {}
    off[self.name][category] = (not enabled) or nil
end

local function Output(self, level, category, text, ...)
    if select("#", ...) > 0 then text = format(text, ...) end
    local line = format("[%s:%s/%s] %s", Glimpse.name, self.name, category, text)

    -- gleiche Zeile in kurzer Folge nur zählen, beim nächsten anderen Text nachreichen
    local now = GetTime()
    if line == self.lastLine and now - self.lastTime < REPEAT_WINDOW then
        self.repeats = self.repeats + 1
        self.lastTime = now
        return
    end
    if self.repeats > 0 then
        local note = format("[%s:%s] (%dx) %s", Glimpse.name, self.name, self.repeats, self.lastLine)
        Glimpse:AddLogLine(note)
        Glimpse:Print(COLORS.log .. note .. "|r")
    end
    self.lastLine, self.lastTime, self.repeats = line, now, 0

    Glimpse:AddLogLine(line)
    Glimpse:Print(COLORS[level] .. line:gsub("|", "||") .. "|r")
end

function Debugger:Log(category, text, ...)
    if self:IsOn(category) then Output(self, "log", category, text, ...) end
end

function Debugger:Warn(category, text, ...)
    if self:IsOn(category) then Output(self, "warn", category, text, ...) end
end

function Debugger:Error(category, text, ...)
    Output(self, "error", category, text, ...)
end

--- Debugger zu einem Namen, gleicher Name gibt denselben zurück. categories = Liste der Kategorien (für die Hilfe).
function Glimpse:NewDebugger(name, categories)
    local debugger = self.debuggers[name]
    if not debugger then
        debugger = setmetatable({ name = name, categories = {}, repeats = 0, lastTime = 0 }, DebuggerMeta)
        self.debuggers[name] = debugger
    end
    for _, category in ipairs(categories or {}) do
        if not tContains(debugger.categories, category) then tinsert(debugger.categories, category) end
    end
    return debugger
end
