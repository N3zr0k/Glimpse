local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- /gli probe db sources [Namespace]: woher die Daten aller Addons kommen.
--   ohne Namespace  je Namespace Bereich, Schreiber, Summen je Herkunft, Orte und externe Quellen,
--                   dazu alte SavedVariables und was Erweiterungen selbst angeben
--   mit Namespace   Summen je Art und Herkunft
-- Erweiterungen mit Daten außerhalb von Database melden sie an:
--   Glimpse:RegisterDataSource("Glimpse_GatheringDB", function() return { "Namen: GlimpseGatheringNames" } end)

Glimpse.dataSources = {}

function Glimpse:RegisterDataSource(addon, func)
    self.dataSources[addon] = func
end

-- SavedVariables der alten Addons, aus denen Database übernimmt
local LEGACY = { "GlimpseStatisticsDB", "GlimpseGatheringDB" }

local function Sorted(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

local function SourceText(info)
    local parts = {}
    for _, source in ipairs(GlimpseDB.SOURCES) do
        local entry = info.sources[source]
        if entry then parts[#parts + 1] = format(L["%s %d (%d chars)"], source, entry.total, entry.chars) end
    end
    for _, source in ipairs(Sorted(info.places)) do
        parts[#parts + 1] = format(L["places %s %d"], source, info.places[source])
    end
    for _, source in ipairs(Sorted(info.adapters)) do
        parts[#parts + 1] = format(L["external %s (%s)"], source, info.adapters[source] and L["active"] or L["missing"])
    end
    return #parts > 0 and table.concat(parts, ", ") or L["no data"]
end

local function WriterText(info)
    local text
    if info.writer == nil then
        text = L["no writer"]
    else
        text = info.writer == true and L["writer active"] or format(L["writer %s"], info.writer)
    end
    if info.owner then text = text .. ", " .. format(L["owner %s"], info.owner) end
    return text
end

local function Overview(DB)
    local lines = {}
    for _, name in ipairs(DB:GetNamespaces()) do
        local info = DB:GetNamespaceInfo(name)
        local area = info.loaded and info.area or format(L["%s (not loaded: %s)"], info.area, tostring(info.reason))
        lines[#lines + 1] = format("|cffffd100%s|r: %s, %s", name, area, WriterText(info))
        lines[#lines + 1] = "  " .. SourceText(info)
    end
    if #lines == 0 then lines[1] = L["Glimpse: Database holds no data yet."] end

    for _, global in ipairs(LEGACY) do
        lines[#lines + 1] = format(L["Old data %s: %s"], global,
            type(_G[global]) == "table" and L["loaded"] or L["not loaded (addon not active)"])
    end
    for _, addon in ipairs(Sorted(Glimpse.dataSources)) do
        local ok, result = pcall(Glimpse.dataSources[addon])
        if type(result) ~= "table" then result = { tostring(result) } end
        for _, line in ipairs(result) do
            lines[#lines + 1] = format("|cffffd100%s|r: %s", addon, ok and line or "|cffff4040" .. line .. "|r")
        end
    end
    return lines
end

local function Detail(DB, name)
    local info = DB:GetNamespaceInfo(name, true)
    if not info then return format(L["Unknown namespace: %s"], name) end

    local lines = { format("|cffffd100%s|r: %s, %s", name, info.area, WriterText(info)) }
    for _, kind in ipairs(Sorted(info.kinds or {})) do
        local parts = {}
        for _, source in ipairs(DB.SOURCES) do
            local n = info.kinds[kind][source]
            if n then parts[#parts + 1] = source .. " " .. n end
        end
        lines[#lines + 1] = format("  %s: %s", kind, table.concat(parts, ", "))
    end
    if #lines == 1 then lines[2] = "  " .. L["no data"] end
    return lines
end

Glimpse:RegisterProbe("db", "sources", function(args)
    local DB = _G.GlimpseDB
    if not DB then return L["Glimpse: Database is not installed. Without it, Glimpse records no combat or travel data."] end
    if not DB.GetNamespaceInfo then return L["This version of Glimpse: Database cannot show its sources."] end

    local name = strtrim(args or "")
    if name ~= "" then return Detail(DB, strlower(name)) end
    return Overview(DB)
end, L["Shows where the data of all addons comes from; with a namespace per kind"])
