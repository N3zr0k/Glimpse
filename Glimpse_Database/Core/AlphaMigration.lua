local ADDON_NAME, P = ...
local DB = GlimpseDB

-- Übernahme der Daten aus Glimpse: Statistics (GlimpseStatisticsDB) und Glimpse: GatheringDB (GlimpseGatheringDB).
-- Deren SavedVariables gibt es nur, wenn das Addon installiert und aktiv ist; dann läuft die Übernahme beim Login.
-- Statistics speichert je "Name - Realm". Übernommen wird nur der eingeloggte Charakter, festgemacht an seiner GUID
-- (Charakter-Schlüssel), jeder Charakter bei seinem nächsten Login. GatheringDB ist Weltwissen und wird beim ersten
-- Login übernommen, ohne Charakter (P.WorldChar). Erledigtes steht in Meta.migrated, die alten Addons behalten ihre
-- Daten.
-- Nur in Alpha-Versionen. Vor der ersten Beta Datei und XML-Zeile löschen, tools/check.py erzwingt das.

local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local version = GetMeta and GetMeta(ADDON_NAME, "Version")
if type(version) ~= "string" or not version:find("%-alpha%.") then return end

-- Zielnamespaces mit den Angaben ihrer späteren Schreiber, damit Export und Abfragen schon vorher stimmen.
-- Arten der Übernahme stehen in DEVELOPER.md ("Übernahme alter Daten").
local TARGETS = {
    combat = { area = "Core", zones = true, world = { looted = true, loot = true } },
    fishing = { area = "Professions", zones = true, world = { looted = true, loot = true, drop = true } },
    gathering = { area = "Gathering", zones = true,
        world = { node = true, nodeloot = true, nodedrop = true, npc = true, npcloot = true, npcdrop = true,
            skinned = true, skinloot = true, skindrop = true } },
}

-- Datentabelle eines Zielnamespace, nil wenn sein Bereich nicht geladen werden kann
local function Target(name)
    local info = P.meta.namespaces[name]
    if not info then
        local target = TARGETS[name]
        info = { area = target.area, version = 1, zones = target.zones, world = target.world }
        P.meta.namespaces[name] = info
    end
    if not DB:LoadArea(info.area) then return nil end
    return P.Data({ name = name, area = info.area, version = info.version }, true)
end

-- Schreibhilfen für einen Block (own) und Charakter-Index

local function AddCount(block, char, kind, id, n)
    if not n or n <= 0 then return end
    local ids = P.Path(block, "counts", char, kind)
    ids[id] = (ids[id] or 0) + n
end

local function AddZone(block, char, kind, id, mapID, n)
    if not (mapID and n and n > 0) then return end
    local zones = P.Path(block, "zones", char, kind, id)
    zones[mapID] = (zones[mapID] or 0) + n
end

local function AddSeen(block, char, kind, id, first, last)
    if type(first) ~= "number" then return end
    last = type(last) == "number" and last or first
    local seen = P.Path(block, "seen", char, kind)
    local old = seen[id]
    if old then
        old[1], old[2] = math.min(old[1], first), math.max(old[2], last)
    else
        seen[id] = { first, last }
    end
end

-- ---------------------------------------------------------------------------
-- Statistics: totals[key], by[key][subKey] = { n, first, last }, first/last[key], days[key][JJJJMMTT], baseline[key]
--   kills, kills.zone ("NPC@Zone")     -> combat    kill [NPC], Rest ohne Aufschlüsselung auf 0
--   deaths                             -> combat    death [NPC], 0 = unbekannt
--   fishing.casts, fishing.catches     -> fishing   cast [0], catch [0], je Zone
--   fishing.items, fishing.items.zone  -> fishing   fish [Item], je Zone
--   gathering.herb/.ore/.other         -> gathering herb, ore, other [Objekt-ID]
--   skinning                           -> gathering skin [NPC]
-- Blizzard-Startwerte landen im Block baseline unter ID 0. Zonen: uiMapID oder "i<InstanzID>" -> -InstanzID.
-- kills.area und deaths.area entfallen: Kills stecken in kills.zone, Tode lassen sich keiner ID zuordnen.
-- ---------------------------------------------------------------------------

local function Zone(key)
    if type(key) == "number" then return key end
    local instance = type(key) == "string" and tonumber(key:match("^i(%d+)$"))
    return instance and -instance or nil
end

-- "123@1412" -> 123, 1412
local function IdAtZone(subKey)
    if type(subKey) ~= "string" then return nil end
    local id, zone = subKey:match("^(%d+)@(.+)$")
    return tonumber(id), Zone(tonumber(zone) or zone)
end

local function Baseline(data, key)
    return data.baseline and tonumber(data.baseline[key]) or 0
end

-- Tagessummen (Ortszeit) auf die Stunde um 12 Uhr legen
local function Days(block, char, data, key, kind)
    for day, n in pairs(data.days and data.days[key] or {}) do
        local ok, stamp = pcall(time, { year = math.floor(day / 10000), month = math.floor(day / 100) % 100,
            day = day % 100, hour = 12 })
        if ok and stamp and n > 0 then
            local hours = P.Path(block, "hours", char, kind)
            local hour = DB:HourOf(stamp)
            hours[hour] = (hours[hour] or 0) + n
        end
    end
end

-- Zähler mit Aufschlüsselung nach ID; was die Aufschlüsselung nicht erklärt (gekürzt, ohne ID), kommt auf 0
local function ById(block, char, data, key, kind)
    local total = math.max((data.totals[key] or 0) - Baseline(data, key), 0)
    local sum = 0
    for subKey, entry in pairs(data.by and data.by[key] or {}) do
        local id = tonumber(subKey)
        if id and type(entry) == "table" and (entry.n or 0) > 0 then
            AddCount(block, char, kind, id, entry.n)
            AddSeen(block, char, kind, id, entry.first, entry.last)
            sum = sum + entry.n
        end
    end
    if total > sum then
        AddCount(block, char, kind, 0, total - sum)
        AddSeen(block, char, kind, 0, data.first and data.first[key], data.last and data.last[key])
    end
    Days(block, char, data, key, kind)
end

-- Zähler ohne ID, aufgeschlüsselt nach Zone
local function ByZone(block, char, data, key, kind)
    local total = math.max((data.totals[key] or 0) - Baseline(data, key), 0)
    AddCount(block, char, kind, 0, total)
    if total > 0 then AddSeen(block, char, kind, 0, data.first and data.first[key], data.last and data.last[key]) end
    for subKey, entry in pairs(data.by and data.by[key] or {}) do
        if type(entry) == "table" then AddZone(block, char, kind, 0, Zone(subKey), entry.n) end
    end
    Days(block, char, data, key, kind)
end

-- "ID@Zone"-Zähler als Zonen der ID
local function Zones(block, char, data, key, kind)
    for subKey, entry in pairs(data.by and data.by[key] or {}) do
        local id, zone = IdAtZone(subKey)
        if id and type(entry) == "table" then AddZone(block, char, kind, id, zone, entry.n) end
    end
end

local function SetBaseline(ns, char, data, key, kind)
    local value = Baseline(data, key)
    if value <= 0 then return end
    local ids = P.Path(ns, "baseline", "counts", char, kind)
    if ids[0] == nil then ids[0] = value end
end

local function Statistics(sv, char)
    local data = type(sv.char) == "table" and sv.char[UnitName("player") .. " - " .. GetRealmName()]
    if type(data) ~= "table" or type(data.totals) ~= "table" then return end

    local combat = Target("combat")
    if combat then
        local own = P.Path(combat, "own")
        ById(own, char, data, "kills", "kill")
        Zones(own, char, data, "kills.zone", "kill")
        ById(own, char, data, "deaths", "death")
        SetBaseline(combat, char, data, "kills", "kill")
        SetBaseline(combat, char, data, "deaths", "death")
    end
    local fishing = Target("fishing")
    if fishing then
        local own = P.Path(fishing, "own")
        ByZone(own, char, data, "fishing.casts", "cast")
        ByZone(own, char, data, "fishing.catches", "catch")
        ById(own, char, data, "fishing.items", "fish")
        Zones(own, char, data, "fishing.items.zone", "fish")
        SetBaseline(fishing, char, data, "fishing.catches", "catch")
    end
    local gathering = Target("gathering")
    if gathering then
        local own = P.Path(gathering, "own")
        ById(own, char, data, "gathering.herb", "herb")
        ById(own, char, data, "gathering.ore", "ore")
        ById(own, char, data, "gathering.other", "other")
        ById(own, char, data, "skinning", "skin")
    end
end

-- ---------------------------------------------------------------------------
-- GatheringDB: Abschnitte { attempts, items = { [Item] = { hits, amount } } }, alles Weltwissen
--   nodes[Objekt]       -> gathering  node [Objekt], nodeloot:<Objekt> [Item] Menge, nodedrop:<Objekt> [Item] Funde
--   npcs[NPC].loot      -> gathering  npc, npcloot:<NPC>, npcdrop:<NPC> (Versuche = Kills, auch leere Leichen)
--   npcs[NPC].skinning  -> gathering  skinned, skinloot:<NPC>, skindrop:<NPC>
--   fishing[Zone]       -> fishing    looted [Zone], loot:<Zone> [Item], drop:<Zone> [Item]
-- Fundorte { map, x, y, n } (x, y in 1/10000) oder { inst, n }: als Zonen der Art, Knoten- und Angelorte
-- zusätzlich als Orte. Namen der Knoten und Instanzen bleiben in GatheringDB.
-- ---------------------------------------------------------------------------

local function Section(block, char, section, kind, lootKind, dropKind, id)
    if type(section) ~= "table" then return end
    AddCount(block, char, kind, id, tonumber(section.attempts))
    for itemID, record in pairs(type(section.items) == "table" and section.items or {}) do
        if type(itemID) == "number" and type(record) == "table" then
            AddCount(block, char, lootKind .. ":" .. id, itemID, tonumber(record.amount))
            AddCount(block, char, dropKind .. ":" .. id, itemID, tonumber(record.hits))
        end
    end
end

-- Fundorte als Zonen der ID; places (optional) bekommt die Orte mit Karte
local function Spots(block, char, entry, kind, id, places)
    for _, spot in ipairs(type(entry.spots) == "table" and entry.spots or {}) do
        if type(spot) == "table" then
            local zone = tonumber(spot.map) or (tonumber(spot.inst) and -spot.inst)
            AddZone(block, char, kind, id, zone, tonumber(spot.n))
            if places and tonumber(spot.map) and tonumber(spot.x) and tonumber(spot.y) then
                P.Path(places, spot.map)[DB:PackXY(spot.x / 10000, spot.y / 10000)] = id
            end
        end
    end
end

local function Gathering(sv, char)
    local data = type(sv.global) == "table" and sv.global or {}

    local gathering = Target("gathering")
    if gathering then
        local own, places = P.Path(gathering, "own"), P.Path(gathering, "places", "own")
        for id, node in pairs(type(data.nodes) == "table" and data.nodes or {}) do
            if type(id) == "number" and type(node) == "table" then
                Section(own, char, node, "node", "nodeloot", "nodedrop", id)
                Spots(own, char, node, "node", id, places)
            end
        end
        for id, npc in pairs(type(data.npcs) == "table" and data.npcs or {}) do
            if type(id) == "number" and type(npc) == "table" then
                Section(own, char, npc.loot, "npc", "npcloot", "npcdrop", id)
                Section(own, char, npc.skinning, "skinned", "skinloot", "skindrop", id)
                Spots(own, char, npc, "npc", id)
            end
        end
    end

    local fishing = Target("fishing")
    if fishing then
        local own, places = P.Path(fishing, "own"), P.Path(fishing, "places", "own")
        for map, zone in pairs(type(data.fishing) == "table" and data.fishing or {}) do
            if type(map) == "number" and type(zone) == "table" then
                Section(own, char, zone, "looted", "loot", "drop", map)
                Spots(own, char, zone, "looted", map, places)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Ablauf beim Login (Events.lua)
-- ---------------------------------------------------------------------------

-- Auch nach einem Fehler erledigt, ein zweiter Lauf würde schon Übernommenes doppelt zählen
local function Run(convert, sv, char)
    local ok, err = pcall(convert, sv, char)
    if not ok then geterrorhandler()(err) end
end

function P.RunAlphaMigration()
    local char, key = P.CurrentChar(), P.charKey
    if not char then return end
    local migrated = P.meta.migrated or {}
    P.meta.migrated = migrated
    -- Zahl statt Tabelle: Lauf einer früheren Alpha, die alle Charaktere auf einmal übernommen hat
    if migrated.statistics == nil then migrated.statistics = {} end
    local statistics = type(migrated.statistics) == "table" and migrated.statistics

    local changed = false
    if type(GlimpseStatisticsDB) == "table" and statistics and not statistics[key] then
        Run(Statistics, GlimpseStatisticsDB, char)
        statistics[key] = P.Now()
        changed = true
    end
    if type(GlimpseGatheringDB) == "table" and not migrated.gathering then
        Run(Gathering, GlimpseGatheringDB, P.WorldChar())
        migrated.gathering = P.Now()
        changed = true
    end
    if changed then P.Fire(nil) end
end

--- { statistics = Zeitpunkt für diesen Charakter, gathering = Zeitpunkt }, nil = noch nicht übernommen
function DB:GetMigrations()
    P.RequireLoaded()
    local migrated = P.meta.migrated or {}
    local statistics = migrated.statistics
    if type(statistics) == "table" then statistics = P.charKey and statistics[P.charKey] end
    return { statistics = statistics, gathering = migrated.gathering }
end
