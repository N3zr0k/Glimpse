local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Trennlinie zwischen Original-Tooltip und allem, was von Glimpse oder einer Erweiterung kommt.
-- Der Pfad ist die übliche Blizzard-Trennlinie aus dem Standard-UI. Wenn im Spiel statt einer
-- Linie ein grünes/schwarzes Quadrat erscheint, stimmt der Pfad im Client nicht und muss hier
-- angepasst werden.
local SEPARATOR_TEXTURE = "Interface\\Common\\UI-TooltipDivider-Transparent"
local SEPARATOR_HEIGHT = 8
local SEPARATOR_MIN_WIDTH = 100

-- Zwei Registries, jeweils in Registrierungsreihenfolge: { key, type, func }
--   entries     = rohe Handler, func(tooltip, data). Der Handler ist selbst für Secret-Prüfung zuständig.
--   lineEntries = Zeilen-Provider, func(data) -> Zeilen. Bekommen nur bereinigte Daten.
-- "type" ist ein Enum.TooltipDataType-Wert oder "ALL".
-- Die Tabellen werden beim (Un)Registrieren komplett neu gebaut und nie verändert.
-- So kann sich ein Handler während des Aufrufs selbst abmelden, ohne dass die
-- Schleife in Dispatch() durcheinanderkommt.
local entries = {}
local lineEntries = {}

-- Blizzard bietet keine Möglichkeit, einen PostCall wieder zu entfernen. Deshalb
-- hängen wir genau einen Callback an und verteilen selbst. Installiert wird er erst
-- beim ersten Handler, ohne Nutzer fassen wir die Tooltips gar nicht an.
local installed = false

-- Zustand des Tooltips, der gerade verarbeitet wird. Damit weiß AddTooltipLine, ob schon
-- ein Separator gesetzt wurde. Nur während Dispatch() gesetzt.
local pass

-- Ab Midnight (und damit wohl auch in Forever) kann der Client Werte als "secret" markieren,
-- z. B. in manchen Action-Bar-Tooltips. Mit so einem Wert darf Addon-Code nichts machen:
-- vergleichen, verketten oder als Tabellen-Key benutzen wirft einen Fehler und taintet die
-- Ausführung. issecretvalue() erlaubt die Prüfung vorher. Gibt es die Funktion im Client
-- nicht, gilt nichts als secret.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

--- true, wenn value ein geschützter Wert ist, den man nicht auswerten darf.
-- Nur für rohe Handler nötig. Zeilen-Provider bekommen schon bereinigte Daten.
function Glimpse:IsSecret(value)
    return IsSecret(value)
end

-- ---------------------------------------------------------------------------
-- Trennlinie und Zeilen
-- ---------------------------------------------------------------------------

local function AddSeparator(tooltip)
    -- Breite grob an den Tooltip anpassen, die Linie soll nicht überstehen
    local width = 200
    local tooltipWidth = tooltip:GetWidth()
    if type(tooltipWidth) == "number" and not IsSecret(tooltipWidth) then
        width = math.max(math.floor(tooltipWidth) - 20, SEPARATOR_MIN_WIDTH)
    end
    tooltip:AddLine(format("|T%s:%d:%d|t", SEPARATOR_TEXTURE, SEPARATOR_HEIGHT, width))
end

--- Hängt eine Trennlinie an, um Gruppen von Zeilen im Bereich von Glimpse zu trennen. Die erste Trennlinie vor der ersten
-- Zeile setzt AddTooltipLine von selbst; ist sie noch nicht gesetzt, ist dieser Aufruf genau diese erste Linie (es gibt nie
-- zwei Linien hintereinander am Anfang).
function Glimpse:AddTooltipSeparator(tooltip)
    if pass and pass.tooltip == tooltip and not pass.separator then
        pass.separator = true
    end
    AddSeparator(tooltip)
end

-- Standardgröße der Symbole vor einer Zeile (in Pixel)
local ICON_SIZE = 16

-- Setzt ein Symbol vor den Text. Wie bei der Trennlinie ist das eine Inline-Textur, es braucht
-- also keine eigenen Frames. icon ist ein Texturpfad (ohne Dateiendung) oder eine FileDataID.
local function WithIcon(text, icon, size)
    if icon == nil or IsSecret(icon) then return text end
    if type(size) ~= "number" then size = ICON_SIZE end
    return format("|T%s:%d:%d:0:0|t %s", tostring(icon), size, size, text)
end

--- Hängt eine Zeile (zweispaltig, wenn right gesetzt ist) an den Tooltip.
-- Farbe ist Weiß, wenn nichts angegeben wird. Mit icon (und optional iconSize) steht links vor
-- dem Text ein Symbol. Während ein Tooltip von Glimpse verarbeitet wird, setzt die erste Zeile
-- automatisch die Trennlinie davor (nur diese erste, weitere mit AddTooltipSeparator).
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

-- Prüft, ob die letzte Zeile des Tooltips schon unser Text ist (der Tooltip wurde dann
-- nur erneut verarbeitet, nicht neu aufgebaut).
local function LastLineIs(tooltip, text)
    local name = tooltip:GetName()
    if not name or not tooltip.NumLines then return false end

    local count = tooltip:NumLines()
    if IsSecret(count) then return false end

    local line = _G[name .. "TextLeft" .. count]
    if not line then return false end

    -- Zeilentexte können secret sein, die dürfen wir nicht vergleichen
    local current = line:GetText()
    if IsSecret(current) then return false end
    return current == text
end

-- Kopie von data, in der nur Strings, Zahlen und Booleans stehen, und zwar nur die, die
-- nicht secret sind. Tabellen (lines, args) fehlen bewusst, deren Inhalt kann geschützt sein.
-- Zusätzlich kommt eine sortierte Liste der Feldnamen zurück, die wegen Secret fehlen (hidden).
-- Ist data selbst geschützt, steht dort nur "data".
local function Sanitize(data)
    local safe, hidden = {}, {}
    if IsSecret(data) or (issecrettable ~= nil and issecrettable(data)) then
        return safe, { "data" }
    end

    -- Je nach Clientstand stehen Felder wie id/guid erst nach SurfaceArgs in data
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

-- Wandelt die Rückgabe eines Providers in eine Liste von Zeilen { left, right, r, g, b }.
-- Erlaubt sind: nil, "Text", "Text", r, g, b oder eine Tabelle mit Zeilen
-- ({ "Text", { "Links", "Rechts", r, g, b } }). Eine Zeilen-Tabelle darf zusätzlich die benannten
-- Felder icon (Texturpfad oder FileDataID) und iconSize haben: { "Links", "Rechts", r, g, b, icon = "..." }
-- { separator = true } ist eine Trennlinie zwischen zwei Gruppen von Zeilen (am Ende der Liste fällt sie weg).
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

-- Läuft nach allen rohen Handlern, damit auch deren Zeilen vor den Provider-Zeilen stehen
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
    -- Eine Trennlinie am Ende wäre eine Linie ohne Zeilen dahinter
    while #collected > 0 and collected[#collected].separator do collected[#collected] = nil end
    if #collected == 0 then return end

    -- Tooltip wurde nur erneut verarbeitet: unsere Zeilen stehen schon am Ende
    -- (die letzte Zeile steht mit Symbol im Tooltip, deshalb muss der Vergleichstext es auch haben)
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

    -- Ist der Typ selbst secret, laufen nur noch die "ALL"-Handler
    local dataType = data.type
    if IsSecret(dataType) then dataType = nil end

    pass = { tooltip = tooltip, separator = false }

    local list = entries
    for i = 1, #list do
        local entry = list[i]
        if entry.type == "ALL" or (dataType ~= nil and entry.type == dataType) then
            -- pcall, damit ein kaputter Handler nicht die anderen mitreißt.
            -- Der Fehler geht trotzdem an den normalen Error-Handler (BugSack etc.).
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
        -- Sollte es in Forever nicht geben, siehe DEVELOPER.md (Tooltips erweitern)
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

-- Erlaubt Enum-Wert (Enum.TooltipDataType.Item), Namen ("Item") und "ALL"/nil.
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

--- Registriert einen Zeilen-Provider: die einfache Variante, um Zeilen an Tooltips eines
-- Typs anzuhängen. Die Zeilen erscheinen am Ende des Tooltips hinter der Trennlinie.
-- key:      eindeutiger Name, z. B. "MeinAddon:Items". Gleicher Key ersetzt den alten Provider.
-- dataType: Enum.TooltipDataType.Item, "Item" oder "ALL".
-- func:     func(data) gibt die Zeilen zurück:
--             nil                      -> keine Zeile
--             "Text" [, r, g, b]       -> eine Zeile
--             { "Text", { "Links", "Rechts", r, g, b }, ... }  -> mehrere Zeilen
-- data enthält nur Felder, die nicht secret sind (Strings, Zahlen, Booleans). Fehlt ein Feld,
-- war es entweder nicht vorhanden oder geschützt.
-- func bekommt optional als 2. und 3. Argument den Tooltip und die Liste der Feldnamen, die wegen
-- Secret entfernt wurden (hidden). Das ist vor allem fürs Debuggen gedacht.
-- Gibt false zurück, wenn die Tooltip-API im Client fehlt.
function Glimpse:RegisterTooltipLine(key, dataType, func)
    local entry = MakeEntry("RegisterTooltipLine", key, dataType, func)
    lineEntries = Filtered(lineEntries, function(e) return e.key == key end)
    tinsert(lineEntries, entry)
    return Install()
end

--- Registriert einen rohen Handler, der bei jedem Tooltip des Typs aufgerufen wird.
-- Für Fälle, in denen man den Tooltip selbst anfassen muss. func(tooltip, data) läuft nachdem
-- Blizzard den Tooltip gefüllt hat. Secret-Werte muss der Handler selbst prüfen (Addon:IsSecret).
-- Gibt false zurück, wenn die Tooltip-API im Client fehlt.
function Glimpse:RegisterTooltipHandler(key, dataType, func)
    local entry = MakeEntry("RegisterTooltipHandler", key, dataType, func)
    entries = Filtered(entries, function(e) return e.key == key end)
    tinsert(entries, entry)
    return Install()
end

--- Entfernt Provider und Handler mit genau diesem Key.
function Glimpse:UnregisterTooltipHandler(key)
    local function match(entry) return entry.key == key end
    entries = Filtered(entries, match)
    lineEntries = Filtered(lineEntries, match)
end

--- Entfernt alle Provider und Handler, deren Key mit prefix beginnt (z. B. "MeinAddon:").
function Glimpse:UnregisterTooltipHandlers(prefix)
    local function match(entry) return strsub(entry.key, 1, #prefix) == prefix end
    entries = Filtered(entries, match)
    lineEntries = Filtered(lineEntries, match)
end

-- ---------------------------------------------------------------------------
-- Modul-Helfer
-- ---------------------------------------------------------------------------

-- Der Prototyp wird in Init.lua angelegt und gilt für alle Module, auch die aus Erweiterungen.
-- Die Funktionen hier landen über die Metatable direkt in jedem Modul, auch wenn es schon
-- existiert. Wichtig ist nur, dass diese Datei vor dem Laden der Module drankommt.
local ModuleProto = Glimpse.ModuleProto

--- Zeilen-Provider für dieses Modul: die einfache Variante. provider ist eine Funktion oder der
-- Name einer Modul-Methode und wird als provider(module, data, tooltip, hidden) aufgerufen.
-- Die Rückgabe sind die Zeilen, die am Ende des Tooltips hinter der Trennlinie erscheinen
-- (siehe DEVELOPER.md).
function ModuleProto:RegisterTooltipLine(dataType, provider)
    local module = self
    local key = self:GetName() .. ":line:" .. tostring(dataType or "ALL")

    return Glimpse:RegisterTooltipLine(key, dataType, function(data, tooltip, hidden)
        -- ein deaktiviertes Modul liefert keine Zeilen
        if not module:IsEnabled() then return nil end

        local fn = provider
        if type(fn) == "string" then fn = module[fn] end
        if fn then return fn(module, data, tooltip, hidden) end
    end)
end

--- Tooltip-Handler für dieses Modul. handler ist eine Funktion oder der Name einer
-- Modul-Methode und wird als handler(module, tooltip, data) aufgerufen.
-- Pro Modul und Typ gibt es einen Handler, ein zweiter Aufruf ersetzt den ersten.
function ModuleProto:RegisterTooltip(dataType, handler)
    local module = self
    local key = self:GetName() .. ":" .. tostring(dataType or "ALL")

    return Glimpse:RegisterTooltipHandler(key, dataType, function(tooltip, data)
        -- ein deaktiviertes Modul soll keine Tooltips mehr anfassen
        if not module:IsEnabled() then return end

        local fn = handler
        if type(fn) == "string" then fn = module[fn] end
        if fn then fn(module, tooltip, data) end
    end)
end

--- Entfernt alle Zeilen-Provider und Handler des Moduls.
function ModuleProto:UnregisterAllTooltips()
    Glimpse:UnregisterTooltipHandlers(self:GetName() .. ":")
end
