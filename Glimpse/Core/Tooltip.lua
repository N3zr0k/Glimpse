local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Trennlinie vor den Glimpse-Zeilen. Grünes/schwarzes Quadrat im Spiel = Pfad falsch.
local SEPARATOR_TEXTURE = "Interface\\Common\\UI-TooltipDivider-Transparent"
local SEPARATOR_HEIGHT = 8
local SEPARATOR_WIDTH = 200

-- Einträge { key, type, func } in Registrierungsreihenfolge, type = Enum.TooltipDataType oder "ALL".
--   entries     = rohe Handler, func(tooltip, data), prüfen Secrets selbst
--   lineEntries = Zeilen-Provider, func(data) -> Zeilen, bekommen bereinigte Daten
-- Beim (Un)Registrieren wird neu gebaut statt verändert, damit sich ein Handler
-- während Dispatch() selbst abmelden kann.
local entries = {}
local lineEntries = {}

-- PostCalls lassen sich nicht entfernen: ein einziger Callback, erst beim ersten Handler installiert
local installed = false

-- Nur während Dispatch(): merkt sich, ob der Separator schon gesetzt ist
local pass

-- Secret-Werte dürfen nicht verglichen, verkettet oder als Key genutzt werden (Fehler + Taint).
-- Ohne issecretvalue() im Client gilt nichts als secret.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

--- true bei Secret-Werten. Nur für rohe Handler nötig, Provider bekommen bereinigte Daten.
function Glimpse:IsSecret(value)
    return IsSecret(value)
end

-- ---------------------------------------------------------------------------
-- Trennlinie und Zeilen
-- ---------------------------------------------------------------------------

-- Feste Breite: Aus dem Tooltip lässt sich die Breite im PostCall nicht verlässlich bestimmen (der Tooltip wird
-- wiederverwendet, GetWidth() ist noch die Breite des vorherigen Inhalts).
local function AddSeparator(tooltip)
    tooltip:AddLine(format("|T%s:%d:%d|t", SEPARATOR_TEXTURE, SEPARATOR_HEIGHT, SEPARATOR_WIDTH))
end

--- Trennlinie zwischen Zeilengruppen. Ist die automatische erste Linie noch nicht gesetzt,
-- ersetzt dieser Aufruf sie (keine doppelte Linie am Anfang).
function Glimpse:AddTooltipSeparator(tooltip)
    if pass and pass.tooltip == tooltip and not pass.separator then
        pass.separator = true
    end
    AddSeparator(tooltip)
end

-- Pixel
local ICON_SIZE = 16

-- icon = Texturpfad ohne Endung oder FileDataID, als Inline-Textur
local function WithIcon(text, icon, size)
    if icon == nil or IsSecret(icon) then return text end
    if type(size) ~= "number" then size = ICON_SIZE end
    return format("|T%s:%d:%d:0:0|t %s", tostring(icon), size, size, text)
end

--- Zeile anhängen, zweispaltig wenn right gesetzt. Standardfarbe Weiß, optional icon/iconSize.
-- Während Dispatch() setzt die erste Zeile automatisch die Trennlinie davor.
function Glimpse:AddTooltipLine(tooltip, left, right, r, g, b, icon, iconSize)
    if pass and pass.tooltip == tooltip and not pass.separator then
        pass.separator = true
        AddSeparator(tooltip)
    end

    left = WithIcon(left, icon, iconSize)
    r, g, b = r or 1, g or 1, b or 1
    if right then
        tooltip:AddDoubleLine(left, right, r, g, b, r, g, b)
    else
        tooltip:AddLine(left, r, g, b)
    end
end

-- true, wenn der Tooltip nur erneut verarbeitet wurde und unsere Zeilen schon dranstehen
local function LastLineIs(tooltip, text)
    local name = tooltip:GetName()
    if not name or not tooltip.NumLines then return false end

    local count = tooltip:NumLines()
    if IsSecret(count) then return false end

    local line = _G[name .. "TextLeft" .. count]
    if not line then return false end

    local current = line:GetText()
    if IsSecret(current) then return false end
    return current == text
end

-- Kopie von data nur mit nicht-secret Strings/Zahlen/Booleans. Tabellen (lines, args) fehlen
-- bewusst. hidden = sortierte Namen der Secret-Felder, bzw. { "data" } wenn data selbst secret ist.
local function Sanitize(data)
    local safe, hidden = {}, {}
    if IsSecret(data) or (issecrettable ~= nil and issecrettable(data)) then
        return safe, { "data" }
    end

    -- id/guid stehen je nach Client erst nach SurfaceArgs in data
    if TooltipUtil and TooltipUtil.SurfaceArgs then
        pcall(TooltipUtil.SurfaceArgs, data)
    end

    for key, value in pairs(data) do
        if not IsSecret(key) then
            local valueType = type(value)
            if IsSecret(value) then
                tinsert(hidden, tostring(key))
            elseif valueType == "string" or valueType == "number" or valueType == "boolean" then
                safe[key] = value
            end
        end
    end
    table.sort(hidden)
    return safe, hidden
end

-- Provider-Rückgabe -> Zeilen { left, right, r, g, b [, icon=, iconSize=] }.
-- Erlaubt: nil, "Text"[, r, g, b] oder Liste aus "Text", { "Links", "Rechts", r, g, b, icon = ... }
-- und { separator = true }.
local function Collect(out, a, b, c, d)
    if a == nil then return end

    if type(a) == "string" then
        if not IsSecret(a) then tinsert(out, { a, nil, b, c, d }) end
    elseif type(a) == "table" then
        for _, line in ipairs(a) do
            if type(line) == "string" then
                if not IsSecret(line) then tinsert(out, { line }) end
            elseif type(line) == "table" and line.separator == true then
                tinsert(out, { separator = true })
            elseif type(line) == "table" and type(line[1]) == "string" and not IsSecret(line[1]) then
                tinsert(out, line)
            end
        end
    end
end

-- Läuft nach den rohen Handlern, deren Zeilen stehen also davor
local function AppendLines(tooltip, data, dataType)
    local list = lineEntries
    if #list == 0 then return end

    local safe, hidden
    local collected = {}
    for i = 1, #list do
        local entry = list[i]
        if entry.type == "ALL" or (dataType ~= nil and entry.type == dataType) then
            if not safe then safe, hidden = Sanitize(data) end
            local ok, a, b, c, d = pcall(entry.func, safe, tooltip, hidden)
            if ok then
                Collect(collected, a, b, c, d)
            else
                geterrorhandler()(a)
            end
        end
    end
    -- Trennlinien am Ende weglassen
    while #collected > 0 and collected[#collected].separator do collected[#collected] = nil end
    if #collected == 0 then return end

    -- Schon vorhanden? Vergleichstext braucht das Symbol, weil es im Tooltip mit drinsteht.
    local last = collected[#collected]
    if LastLineIs(tooltip, WithIcon(last[1], last.icon, last.iconSize)) then return end

    for _, line in ipairs(collected) do
        if line.separator then
            Glimpse:AddTooltipSeparator(tooltip)
        else
            Glimpse:AddTooltipLine(tooltip, line[1], line[2], line[3], line[4], line[5], line.icon, line.iconSize)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Verteilung
-- ---------------------------------------------------------------------------

local function Dispatch(tooltip, data)
    if not data then return end

    -- Secret-Typ: nur "ALL"-Handler
    local dataType = data.type
    if IsSecret(dataType) then dataType = nil end

    pass = { tooltip = tooltip, separator = false }

    local list = entries
    for i = 1, #list do
        local entry = list[i]
        if entry.type == "ALL" or (dataType ~= nil and entry.type == dataType) then
            -- Kaputter Handler soll die anderen nicht blockieren, Fehler geht trotzdem an BugSack & Co.
            local ok, err = pcall(entry.func, tooltip, data)
            if not ok then geterrorhandler()(err) end
        end
    end

    local ok, err = pcall(AppendLines, tooltip, data, dataType)
    if not ok then geterrorhandler()(err) end

    pass = nil
end

local function Install()
    if installed then return true end

    if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
        -- Siehe DEVELOPER.md (Tooltips erweitern)
        Glimpse:Debug("TooltipDataProcessor nicht verfügbar, Tooltip-Handler sind inaktiv")
        return false
    end

    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes or "ALL", Dispatch)
    installed = true
    return true
end

-- ---------------------------------------------------------------------------
-- Registrierung
-- ---------------------------------------------------------------------------

-- Enum-Wert, Name ("Item") oder "ALL"/nil
local function ResolveType(dataType)
    if dataType == nil or dataType == "ALL" then return "ALL" end
    if type(dataType) == "string" then
        return Enum.TooltipDataType[dataType]
    end
    return dataType
end

local function MakeEntry(fname, key, dataType, func)
    assert(type(key) == "string", fname .. ": key muss ein String sein")
    assert(type(func) == "function", fname .. ": func muss eine Funktion sein")

    local resolved = ResolveType(dataType)
    if resolved == nil then
        error(fname .. ": unbekannter Tooltip-Typ " .. tostring(dataType), 3)
    end
    return { key = key, type = resolved, func = func }
end

-- Neue Liste ohne die Einträge, für die remove(entry) true ergibt
local function Filtered(list, remove)
    local out = {}
    for _, entry in ipairs(list) do
        if not remove(entry) then tinsert(out, entry) end
    end
    return out
end

--- Zeilen-Provider registrieren. Zeilen erscheinen am Tooltip-Ende hinter der Trennlinie.
-- key:      eindeutig, z. B. "MeinAddon:Items". Gleicher Key ersetzt den alten Provider.
-- dataType: Enum.TooltipDataType.Item, "Item" oder "ALL".
-- func:     func(data, tooltip, hidden) gibt die Zeilen zurück:
--             nil                      -> keine Zeile
--             "Text" [, r, g, b]       -> eine Zeile
--             { "Text", { "Links", "Rechts", r, g, b }, ... }  -> mehrere Zeilen
-- data enthält nur nicht-secret Strings/Zahlen/Booleans, hidden die Namen der entfernten Felder.
-- false, wenn die Tooltip-API im Client fehlt.
function Glimpse:RegisterTooltipLine(key, dataType, func)
    local entry = MakeEntry("RegisterTooltipLine", key, dataType, func)
    lineEntries = Filtered(lineEntries, function(e) return e.key == key end)
    tinsert(lineEntries, entry)
    return Install()
end

--- Roher Handler func(tooltip, data), läuft nachdem Blizzard den Tooltip gefüllt hat.
-- Secrets selbst prüfen (Glimpse:IsSecret). false, wenn die Tooltip-API fehlt.
function Glimpse:RegisterTooltipHandler(key, dataType, func)
    local entry = MakeEntry("RegisterTooltipHandler", key, dataType, func)
    entries = Filtered(entries, function(e) return e.key == key end)
    tinsert(entries, entry)
    return Install()
end

--- Provider und Handler mit genau diesem Key entfernen.
function Glimpse:UnregisterTooltipHandler(key)
    local function match(entry) return entry.key == key end
    entries = Filtered(entries, match)
    lineEntries = Filtered(lineEntries, match)
end

--- Alle Provider und Handler mit Key-Präfix prefix entfernen (z. B. "MeinAddon:").
function Glimpse:UnregisterTooltipHandlers(prefix)
    local function match(entry) return strsub(entry.key, 1, #prefix) == prefix end
    entries = Filtered(entries, match)
    lineEntries = Filtered(lineEntries, match)
end

-- ---------------------------------------------------------------------------
-- Modul-Helfer
-- ---------------------------------------------------------------------------

-- Prototyp aus Init.lua, wirkt per Metatable auch auf bereits angelegte Module
local ModuleProto = Glimpse.ModuleProto

--- Zeilen-Provider des Moduls. provider = Funktion oder Methodenname,
-- Aufruf provider(module, data, tooltip, hidden), Rückgabe wie bei Glimpse:RegisterTooltipLine.
function ModuleProto:RegisterTooltipLine(dataType, provider)
    local module = self
    local key = self:GetName() .. ":line:" .. tostring(dataType or "ALL")

    return Glimpse:RegisterTooltipLine(key, dataType, function(data, tooltip, hidden)
        if not module:IsEnabled() then return nil end

        local fn = provider
        if type(fn) == "string" then fn = module[fn] end
        if fn then return fn(module, data, tooltip, hidden) end
    end)
end

--- Roher Handler des Moduls, Aufruf handler(module, tooltip, data). Einer pro Modul und Typ.
function ModuleProto:RegisterTooltip(dataType, handler)
    local module = self
    local key = self:GetName() .. ":" .. tostring(dataType or "ALL")

    return Glimpse:RegisterTooltipHandler(key, dataType, function(tooltip, data)
        if not module:IsEnabled() then return end

        local fn = handler
        if type(fn) == "string" then fn = module[fn] end
        if fn then fn(module, tooltip, data) end
    end)
end

function ModuleProto:UnregisterAllTooltips()
    Glimpse:UnregisterTooltipHandlers(self:GetName() .. ":")
end
