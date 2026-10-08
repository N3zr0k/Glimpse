local _, P = ...
local DB = GlimpseDB

-- Ein Bereich ist eine SavedVariables-Tabelle GlimpseDB_<Bereich>. "Core" gehört zum Hauptaddon und ist immer
-- geladen, alle anderen sind LoadOnDemand-Addons Glimpse_Database_<Bereich>. Nicht geladene Bereiche bleiben auf
-- der Platte unverändert.
DB.MAIN_AREA = "Core"
DB.AREAS = { "Core", "Gathering", "Professions", "Reputation", "Misc" }

local known = {}
for _, area in ipairs(DB.AREAS) do known[area] = true end

P.areas = {} -- Bereich -> Tabelle, sobald geladen

local function AddonName(area)
    return DB.name .. "_" .. area
end

function DB:IsArea(area)
    return known[area] == true
end

function DB:IsAreaLoaded(area)
    return P.areas[area] ~= nil
end

--- Tabelle des Bereichs, lädt das Addon bei Bedarf. Bei Fehler nil und Grund (z. B. "DISABLED", "MISSING").
function DB:LoadArea(area)
    P.RequireLoaded()
    if not known[area] then error("unknown area " .. tostring(area), 2) end
    if P.areas[area] then return P.areas[area] end

    if area ~= DB.MAIN_AREA and not C_AddOns.IsAddOnLoaded(AddonName(area)) then
        local loaded, reason = C_AddOns.LoadAddOn(AddonName(area))
        if not loaded then return nil, reason or "MISSING" end
    end

    -- Beim ersten Mal gibt es die SavedVariables noch nicht
    local global = "GlimpseDB_" .. area
    local data = _G[global]
    if type(data) ~= "table" then
        data = {}
        _G[global] = data -- luacheck: ignore 122
    end
    P.areas[area] = data
    return data
end

--- Ungefähre Größe eines geladenen Bereichs: Anzahl gespeicherter Werte (für den Tab "Daten")
function DB:GetAreaSize(area)
    local function Count(t, depth)
        local n = 0
        for _, value in pairs(t) do
            if type(value) == "table" and depth < 12 then
                n = n + Count(value, depth + 1)
            else
                n = n + 1
            end
        end
        return n
    end

    local data = P.areas[area]
    return data and Count(data, 0) or nil
end

--- Bereich leeren. Namespaces bleiben angemeldet und legen ihre Tabellen beim nächsten Schreiben neu an.
function DB:ResetArea(area)
    local data = self:LoadArea(area)
    if not data then return false end
    for key in pairs(data) do data[key] = nil end
    P.Fire(nil)
    return true
end
