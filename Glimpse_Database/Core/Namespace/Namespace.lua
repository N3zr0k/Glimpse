local _, P = ...
local DB = GlimpseDB

-- Namespace = logische Sicht (Name, API), Bereich = physische Tabelle. Jeder Namespace hat genau einen Schreiber
-- (DB:Register), lesen darf jeder (DB:Get). Wo ein Namespace liegt, steht in Meta.namespaces; zieht er in einen
-- anderen Bereich um, wandern die Daten beim nächsten Register mit.
--
-- Daten eines Namespace (Tabelle im Bereich, Schlüssel = Name):
--   version                      Schema-Version
--   own / imported / baseline    je ein Block nach Herkunft (Query.lua)
--     counts[char][kind][id]           Zähler
--     zones[char][kind][id][mapID]     Zähler pro Zone (nur mit zones = true)
--     seen[char][kind][id]             { erster, letzter } Zeitstempel
--     hours[char][kind][hour]          Stunden-Buckets je Art
--     idHours[char][kind][id][hour]    Stunden-Buckets je ID, dünn besetzt
--   places[source][mapID][xy] = id     Orte (Locations.lua), ohne Charakter
-- Bei imported ist char der Charakter, von dem die Daten stammen.

local Reader = {}
local Writer = setmetatable({}, { __index = Reader })
P.Reader, P.Writer = Reader, Writer

local ReaderMeta = { __index = Reader }
local WriterMeta = { __index = Writer }

P.writers = {}
P.readers = {}
P.writerAddons = {} -- Name -> Addon, das ihn angemeldet hat (nur für /gli probe db sources)

-- Addon-Ordner aus dem Aufrufstapel, nil wenn nicht erkennbar
local function CallerAddon()
    if not debugstack then return nil end
    for addon in debugstack(3, 5, 0):gmatch("AddOns[/\\]([^/\\]+)[/\\]") do
        if addon ~= DB.name then return addon end
    end
end

--- Datentabelle des Namespace. create = true legt sie an (nur Schreiber und Import).
function P.Data(ns, create)
    local area = P.areas[ns.area]
    local data = area and area[ns.name]
    if not data and create and area then
        data = { version = ns.version }
        area[ns.name] = data
    end
    return data
end

local function NewView(meta, name, info)
    return setmetatable({
        name = name,
        area = info.area,
        version = info.version,
        zones = info.zones == true,
        world = info.world or {},
    }, meta)
end

--- Namespace zum Schreiben anmelden. options:
--   area     Bereich (Standard "Misc"), siehe Areas.lua
--   version  Schema-Version (Standard 1); ist die gespeicherte älter, wird migrate(data, alt, neu) aufgerufen
--   zones    true = Zähler auch pro Zone
--   world    { kind = true }: Arten, die als Weltwissen exportiert werden (alle anderen sind persönlich).
--            Gilt auch für Unterarten "kind:...", z. B. world = { loot = true } für "loot:299".
--   addon    Name des schreibenden Addons für die Diagnose (sonst aus dem Aufrufstapel)
-- Gibt nil und Grund zurück, wenn der Bereich nicht geladen werden kann.
function DB:Register(name, options)
    P.RequireLoaded()
    if type(name) ~= "string" or name == "" then error("namespace name expected", 2) end
    if P.writers[name] then error(format("namespace %q already has a writer", name), 2) end

    options = options or {}
    local area = options.area or "Misc"
    local version = options.version or 1

    local areaData, reason = self:LoadArea(area)
    if not areaData then return nil, reason end

    -- Umzug aus einem anderen Bereich
    local info = P.meta.namespaces[name]
    if info and info.area ~= area and not areaData[name] then
        local old = self:LoadArea(info.area)
        if old and old[name] then
            areaData[name], old[name] = old[name], nil
        end
    end

    local data = areaData[name]
    if data and (data.version or 1) > version then
        return nil, "NEWER_DATA"
    end
    if data and (data.version or 1) < version and options.migrate then
        options.migrate(data, data.version or 1, version)
    end
    if data then data.version = version end

    info = { area = area, version = version, zones = options.zones == true, world = options.world }
    P.meta.namespaces[name] = info
    P.readers[name] = nil

    local ns = NewView(WriterMeta, name, info)
    P.writers[name] = ns
    P.writerAddons[name] = options.addon or CallerAddon()
    return ns
end

--- Namespace zum Lesen, lädt seinen Bereich bei Bedarf. nil, wenn der Namespace unbekannt ist oder der Bereich
-- nicht geladen werden kann.
function DB:Get(name)
    P.RequireLoaded()
    local reader = P.readers[name]
    if reader then return reader end

    local info = P.meta.namespaces[name]
    if not info or not self:LoadArea(info.area) then return nil end

    reader = NewView(ReaderMeta, name, info)
    P.readers[name] = reader
    return reader
end

--- Namen aller bekannten Namespaces, sortiert
function DB:GetNamespaces()
    P.RequireLoaded()
    local list = {}
    for name in pairs(P.meta.namespaces) do list[#list + 1] = name end
    table.sort(list)
    return list
end

function Reader:IsWriter()
    return getmetatable(self) == WriterMeta
end
