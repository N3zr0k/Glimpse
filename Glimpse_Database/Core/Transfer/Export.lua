local _, P = ...
local DB = GlimpseDB

-- Ein Export hat zwei Teile:
--   world      Weltwissen (Orte, Arten mit world = true), Summe aller eigenen Charaktere. Darf jeder importieren.
--   personal   alle anderen Arten je eigenem Charakter (Schlüssel = Charakter-Schlüssel). Wird nur beim selben
--              Charakter angewendet (Import.lua).
-- Exportiert wird nur, was Glimpse selbst erfasst hat (own); Importe und Startwerte bleiben, wo sie sind, damit
-- nichts doppelt hin und her wandert.

-- world = { loot = true } gilt auch für "loot:299" (Art mit Unterteilung, z. B. Beute je NPC)
local function IsWorld(info, kind)
    local world = info.world
    if not world then return false end
    return world[kind] == true or (type(kind) == "string" and world[kind:match("^([^:]+):")] == true)
end

local function AddAll(target, source)
    for id, n in pairs(source) do target[id] = (target[id] or 0) + n end
end

-- Weltwissen eines Namespace: Zähler der world-Arten über alle Charaktere summiert, dazu die Orte
local function WorldPart(info, data)
    local part = {}
    local own = data.own
    for _, kinds in pairs(own and own.counts or {}) do
        for kind, ids in pairs(kinds) do
            if IsWorld(info, kind) then AddAll(P.Path(part, "counts", kind), ids) end
        end
        P.Yield()
    end
    if data.places and data.places.own then part.places = data.places.own end
    if next(part) then return part end
end

-- Persönliche Daten eines Charakters: alle Tabellen des own-Blocks ohne world-Arten
local function PersonalPart(info, block, char)
    local part = {}
    for field, byChar in pairs(block) do
        for kind, value in pairs(byChar[char] or {}) do
            if not IsWorld(info, kind) then P.Path(part, field)[kind] = value end
        end
    end
    if next(part) then return part end
end

local function BuildPayload(names)
    if not P.CurrentChar() then error("NO_CHARACTER", 0) end

    local payload = {
        format = P.FORMAT,
        api = DB.API_VERSION,
        install = P.meta.install,
        time = P.Now(),
        origin = { key = P.charKey, name = UnitName("player"), realm = GetRealmName() },
        namespaces = {},
        world = {},
        personal = {},
    }
    for _, name in ipairs(names) do
        local info = P.meta.namespaces[name]
        local area = info and DB:LoadArea(info.area)
        local data = area and area[name]
        if data then
            payload.namespaces[name] = { area = info.area, version = data.version or info.version }
            payload.world[name] = WorldPart(info, data)

            for index, entry in ipairs(P.meta.characters) do
                local part = not entry.foreign and data.own and PersonalPart(info, data.own, index)
                if part then
                    local personal = P.Path(payload.personal, entry.key)
                    personal.name, personal.realm, personal.class = entry.name, entry.realm, entry.class
                    P.Path(personal, "data")[name] = part
                end
            end
        end
        P.Yield()
    end
    return payload
end

--- Export als kopierbarer Text, asynchron. names = Liste von Namespaces oder nil für alle.
-- callback(text) oder callback(nil, Fehler)
function DB:Export(names, callback)
    P.RequireLoaded()
    names = names or self:GetNamespaces()
    P.RunAsync(function()
        return P.Encode(BuildPayload(names))
    end, function(ok, result)
        if ok then callback(result) else callback(nil, result) end
    end)
end
