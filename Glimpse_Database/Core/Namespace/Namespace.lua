local _, P = ...
local DB = GlimpseDB

-- Namespace = logische Sicht (Name, API), Bereich = physische Tabelle. Jeder Namespace hat genau einen Schreiber
-- (DB:Register), lesen darf jeder (DB:Get). Wo ein Namespace liegt, steht in Meta.namespaces; zieht er in einen
-- anderen Bereich um, wandern die Daten beim nächsten Register mit.
--
-- Besitzer: Der Addon-Ordner, der einen Namespace zuerst anmeldet, besitzt ihn (Meta.namespaces[name].owner).
-- Andere Ordner bekommen beim Anmelden "NOT_OWNER". Der Ordner kommt aus dem Aufrufstapel, nicht vom Aufrufer.
-- Schützt die API vor Versehen, nicht vor Absicht: SavedVariables sind für jedes Addon offen.
--
-- Daten eines Namespace (Tabelle im Bereich, Schlüssel = Name):
--   version                      Schema-Version
--   own / imported / baseline    je ein Block nach Herkunft (Query.lua)
--     counts[char][kind][id]           Zähler
--     zones[char][kind][id][mapID]     Zähler pro Zone (nur mit zones = true)
--     seen[char][kind][id]             { erster, letzter } Zeitstempel
--     hours[char][kind][hour]          Stunden-Buckets je Art
--     idHours[char][kind][id][hour]    Stunden-Buckets je ID, dünn besetzt
--     days[char][kind][id][day]        Tageswerte je ID (nur mit days = true), day = lokales Datum JJJJMMTT
--   places[source][mapID][xy] = id     Orte (Locations.lua), ohne Charakter
-- Bei imported ist char der Charakter, von dem die Daten stammen.

local Reader = {}
local Writer = setmetatable({}, { __index = Reader })
P.Reader, P.Writer = Reader, Writer

local ReaderMeta = { __index = Reader }
local WriterMeta = { __index = Writer }

P.writers = {}
P.readers = {}
P.writerAddons = {} -- Name -> Addon, das ihn angemeldet hat (für /gli probe db sources)

-- Besitzer der Namespaces, die es schon vor dem Besitzer-Schutz gab
P.OWNERS = {
    combat = "Glimpse",
    travel = "Glimpse",
    fishing = "Glimpse_Professions",
    gathering = "Glimpse_GatheringDB",
}

--- Addon-Ordner des Aufrufers einer DB-Funktion. nil, wenn nicht erkennbar (z. B. loadstring);
-- false ohne debugstack (nur Tests außerhalb des Clients, dann gibt es keinen Schutz).
function P.CallerAddon()
    if not debugstack then return false end
    -- 1 = diese Funktion, 2 = die DB-Funktion, 3 = ihr Aufrufer
    for addon in debugstack(3, 5, 0):gmatch("AddOns[/\\]([^/\\]+)[/\\]") do
        if addon ~= DB.name then return addon end
    end
    return nil
end

--- Besitzer eines Namespace oder nil. owner = false heißt freigegeben.
function P.Owner(name)
    local info = P.meta.namespaces[name]
    if info and info.owner ~= nil then return info.owner or nil end
    return P.OWNERS[name]
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
        days = info.days == true,
        world = info.world or {},
    }, meta)
end

--- Namespace zum Schreiben anmelden. options:
--   area     Bereich (Standard "Misc"), siehe Areas.lua
--   version  Schema-Version (Standard 1); ist die gespeicherte älter, wird migrate(data, alt, neu) aufgerufen
--   zones    true = Zähler auch pro Zone
--   days     true = Zähler auch als ein Wert je Tag (Days.lua)
--   world    { kind = true }: Arten, die als Weltwissen exportiert werden (alle anderen sind persönlich).
--            Gilt auch für Unterarten "kind:...", z. B. world = { loot = true } für "loot:299".
-- Gibt nil und Grund zurück: "NO_ADDON" (Aufrufer ohne Addon-Ordner), "NOT_OWNER" (Namespace gehört einem anderen
-- Addon), "NEWER_DATA" oder der Grund, warum der Bereich nicht geladen werden kann.
function DB:Register(name, options)
    P.RequireLoaded()
    if type(name) ~= "string" or name == "" then error("namespace name expected", 2) end

    local caller = P.CallerAddon()
    if caller == nil then return nil, "NO_ADDON" end
    local owner = P.Owner(name)
    if caller and owner and caller ~= owner then return nil, "NOT_OWNER" end

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

    info = { area = area, version = version, zones = options.zones == true, days = options.days == true, world = options.world,
        owner = owner or caller or nil }
    P.meta.namespaces[name] = info
    P.readers[name] = nil

    local ns = NewView(WriterMeta, name, info)
    P.writers[name] = ns
    P.writerAddons[name] = caller or nil
    return ns
end

--- Besitzer freigeben, z. B. nach dem Umbenennen eines Addon-Ordners. Der nächste Register setzt ihn neu.
-- Nur aus Glimpse (/gli db owner). Gibt true oder false und Grund ("NOT_ALLOWED", "UNKNOWN") zurück.
function DB:ResetOwner(name)
    P.RequireLoaded()
    local caller = P.CallerAddon()
    if caller ~= false and caller ~= "Glimpse" then return false, "NOT_ALLOWED" end

    local info = P.meta.namespaces[name]
    if not info then return false, "UNKNOWN" end
    info.owner = false
    return true
end

--- Besitzer (Addon-Ordner) eines Namespace, nil wenn keiner
function DB:GetOwner(name)
    P.RequireLoaded()
    return P.Owner(name)
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
