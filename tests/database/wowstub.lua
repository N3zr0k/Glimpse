-- luacheck: ignore 111 113 122 143 432
-- Minimale Nachbildung der WoW-Umgebung für Glimpse_Database. Lädt die echten Libraries und alle Dateien in der
-- Reihenfolge der XML-Dateien, wie der Client.
local stub = {}

local ROOT = ((arg and arg[0] or ""):match("^(.*)/[^/]*$") or ".") .. "/../.."
stub.root = ROOT

-- Dateien einer XML in Ladereihenfolge (Script und Include, rekursiv)
local function XmlFiles(path, list)
    local base = path:match("^(.*)/[^/]*$")
    local handle = assert(io.open(path))
    local text = handle:read("*a"):gsub("<!%-%-.-%-%->", "")
    handle:close()
    for tag, file in text:gmatch("<(%a+)%s+file=\"([^\"]+)\"") do
        file = base .. "/" .. file:gsub("\\", "/")
        if tag == "Include" then XmlFiles(file, list) else list[#list + 1] = file end
    end
    return list
end

function stub.reset()
    -- Lua-5.1-Ausdrücke, die der Client mitbringt
    _G.unpack = table.unpack or unpack
    _G.format = string.format
    _G.strmatch = string.match
    _G.gsub = string.gsub
    _G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
    _G.date = os.date
    _G.time = os.time
    _G.debugprofilestop = function() return os.clock() * 1000 end
    _G.securecallfunction = function(func, ...) return func(...) end
    _G.geterrorhandler = function() return function(err) error(err, 0) end end
    _G.LibStub = nil

    stub.serverTime = 1767225600 + 86400 * 10 -- 2026-01-11 00:00 UTC
    _G.GetServerTime = function() return stub.serverTime end

    -- Zeitgeber, vom Test über stub.flush() abgearbeitet
    stub.timers = {}
    _G.C_Timer = { After = function(_, func) stub.timers[#stub.timers + 1] = func end }

    -- Spieler; stub.login(guid, name) wechselt ihn
    stub.player = { guid = "Player-1-00000001", name = "Flovy", realm = "Forever", class = "MAGE" }
    _G.UnitGUID = function(unit) return unit == "player" and stub.player.guid or nil end
    _G.UnitName = function(unit) return unit == "player" and stub.player.name or nil end
    _G.UnitClass = function() return stub.player.class, stub.player.class end
    _G.GetRealmName = function() return stub.player.realm end

    -- LoadOnDemand-Bereiche: stub.disabled[name] = true lässt das Laden scheitern
    stub.loaded, stub.disabled = {}, {}
    _G.C_AddOns = {
        IsAddOnLoaded = function(name) return stub.loaded[name] == true end,
        GetAddOnMetadata = function(_, field) if field == "Version" then return stub.version end end,
        LoadAddOn = function(name)
            if stub.disabled[name] then return false, "DISABLED" end
            stub.loaded[name] = true
            return true
        end,
    }

    -- Version wie in der TOC
    local toc = io.open(ROOT .. "/Glimpse_Database/Glimpse_Database.toc"):read("*a")
    stub.version = toc:match("## Version: (%S+)")

    -- Aufrufstapel: ohne stub.useStack kein debugstack (wie außerhalb des Clients, kein Besitzer-Schutz).
    -- stub.caller = Addon-Ordner des Aufrufers, nil = Code ohne Ordner (loadstring)
    _G.debugstack = nil
    stub.caller = "Glimpse"

    stub.frames = {}
    _G.CreateFrame = function()
        local frame = { events = {} }
        function frame:SetScript(_, func) self.onEvent = func end
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        stub.frames[#stub.frames + 1] = frame
        return frame
    end

    for _, name in ipairs({ "GlimpseDB", "GlimpseDB_Meta", "GlimpseDB_Core", "GlimpseDB_Gathering",
        "GlimpseDB_Professions", "GlimpseDB_Reputation", "GlimpseDB_Misc" }) do
        _G[name] = nil
    end
end

--- Aufrufstapel einschalten, caller wie stub.caller
function stub.useStack(caller)
    stub.caller = caller
    _G.debugstack = function()
        local file = stub.caller and ("Interface/AddOns/" .. stub.caller .. "/Core/File.lua") or '[string "code"]'
        return "Interface/AddOns/Glimpse_Database/Core/Namespace/Namespace.lua:1: in function <...>\n"
            .. file .. ":1: in main chunk\n"
    end
end

function stub.flush()
    for _ = 1, 10000 do
        local list = stub.timers
        if #list == 0 then return end
        stub.timers = {}
        for _, func in ipairs(list) do func() end
    end
    error("timers did not finish")
end

function stub.fire(event, ...)
    for _, frame in ipairs(stub.frames) do
        if frame.events[event] and frame.onEvent then frame.onEvent(frame, event, ...) end
    end
end

--- Lädt das Addon wie der Client (Dateien, dann SavedVariables, dann ADDON_LOADED und PLAYER_LOGIN).
-- saved = Tabelle mit SavedVariables aus einem früheren Lauf (optional). Gibt GlimpseDB und P zurück.
function stub.load(saved)
    local private = {}
    for _, file in ipairs(XmlFiles(ROOT .. "/Glimpse_Database/Glimpse_Database.xml", {})) do
        local chunk = assert(loadfile(file))
        chunk("Glimpse_Database", private)
    end
    for name, value in pairs(saved or {}) do _G[name] = value end
    stub.fire("ADDON_LOADED", "Glimpse_Database")
    stub.fire("PLAYER_LOGIN")
    return _G.GlimpseDB, private
end

--- SavedVariables, wie sie beim Ausloggen geschrieben würden (gleiche Tabellen, kein Kopieren nötig)
function stub.saved()
    local saved = {}
    for _, name in ipairs({ "GlimpseDB_Meta", "GlimpseDB_Core", "GlimpseDB_Gathering", "GlimpseDB_Professions",
        "GlimpseDB_Reputation", "GlimpseDB_Misc" }) do
        saved[name] = _G[name]
    end
    return saved
end

--- Zweiter Rechner bzw. anderer Charakter: Addon neu laden, ohne die alten Frames
function stub.restart(saved, player)
    stub.frames = {}
    if player then
        for key, value in pairs(player) do stub.player[key] = value end
    end
    return stub.load(saved)
end

return stub
