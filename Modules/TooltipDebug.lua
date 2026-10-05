local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Debug-Modul für Tooltips. Zeigt nur etwas an, wenn der Debug-Modus an ist
-- (/gli debug on), und zwar hinter der Trennlinie am Ende des Tooltips:
--
--   [DEBUG] Glimpse(TooltipDebug)
--   Ziel: NPC (ID 1234)
--   Datentyp: Unit (2)
--   Tooltip-Frame: GameTooltip
--   Geschützte Felder: guid        <- nur wenn der Client Felder geschützt hat
--
-- Das sind die Infos, die man beim Schreiben eigener Zeilen braucht: welcher Typ ankommt
-- (für RegisterTooltipLine), in welchem Frame der Tooltip steckt (z. B. GameTooltip oder
-- ItemRefTooltip) und welche Felder man wegen Secret-Werten nicht lesen kann.
--
-- Wie man selbst Zeilen für einen Typ anhängt, steht als Beispiel ganz unten.
-- Das Modul kann gelöscht werden (dann auch aus Modules.xml nehmen).
local TooltipDebug = Glimpse:NewModule("TooltipDebug")

-- Enum.TooltipDataType geht von Name -> Wert, wir brauchen die Gegenrichtung.
-- Wird beim ersten Tooltip einmal aufgebaut.
local typeNames

local function TypeName(value)
    if not typeNames then
        typeNames = {}
        if Enum and Enum.TooltipDataType then
            for name, v in pairs(Enum.TooltipDataType) do typeNames[v] = name end
        end
    end
    return typeNames[value] or tostring(value)
end

-- Erstes Stück der GUID sagt, was für ein Ziel eine Unit ist
local GUID_KINDS = {
    Creature = "NPC",
    Vehicle = "NPC",
    Pet = "Pet",
    Player = "Player",
    GameObject = "Object",
}

-- Eigene Auswertung für Units: das Ziel steckt in der GUID, nicht in data.id.
-- Gibt target und id zurück, beides darf fehlen.
local function ResolveUnit(data)
    local guid = data.guid
    if not guid then return "Unit", nil end

    -- Creature-0-<Server>-<Instanz>-<Zone>-<NPC-ID>-<Spawn>
    local kind, _, _, _, _, npcID = strsplit("-", guid)
    -- Spieler-GUIDs haben an dieser Stelle keine ID
    if kind == "Player" then npcID = nil end

    return GUID_KINDS[kind] or "Unit", npcID
end

-- Baut die Debug-Zeilen. target ist der Text für "Ziel", die ID kommt aus data.id, außer ein
-- Typ bringt einen eigenen resolve(data) mit. Fehlt ein Wert, war er nicht vorhanden oder
-- geschützt (steht dann unter hidden).
local function BuildLines(module, data, tooltip, hidden, target, resolve)
    -- Der Schalter wird bei jedem Tooltip geprüft, damit man Debug live umschalten kann
    if not Glimpse:IsDebug() then return nil end

    local id = data.id
    if resolve then target, id = resolve(data) end

    local targetLine = L["Target"] .. ": " .. target
    if id then targetLine = targetLine .. " (ID " .. id .. ")" end

    local typeText = "?"
    if data.type ~= nil then
        typeText = format("%s (%s)", TypeName(data.type), tostring(data.type))
    end

    -- Tooltips ohne Namen (anonyme Frames) gibt es auch
    local frame = tooltip and tooltip:GetName()
    if not frame or Glimpse:IsSecret(frame) then frame = "?" end

    local lines = {
        { format("|cff9d9d9d[DEBUG]|r %s(%s)", Glimpse.name, module:GetName()), nil, 0.6, 0.6, 0.6 },
        { targetLine, nil, 0.6, 0.6, 0.6 },
        { L["Data type"] .. ": " .. typeText, nil, 0.6, 0.6, 0.6 },
        { L["Tooltip frame"] .. ": " .. frame, nil, 0.6, 0.6, 0.6 },
    }

    if hidden and #hidden > 0 then
        tinsert(lines, { L["Secret fields"] .. ": " .. table.concat(hidden, ", "), nil, 0.6, 0.6, 0.6 })
    end

    return lines
end

-- Typen, die das Modul abdeckt: { Name in Enum.TooltipDataType, optionaler Resolver }
-- Fehlt ein Typ im Client, wird er beim Registrieren übersprungen.
-- Weitere Typen: einfach eine Zeile ergänzen.
local TYPES = {
    { "Item" },
    { "Spell" },
    { "Unit", ResolveUnit },
    { "Object" },
    { "Currency" },
    { "Mount" },
    { "Toy" },
    { "Quest" },
    { "Achievement" },
    { "Macro" },
}

function TooltipDebug:OnEnable()
    for _, entry in ipairs(TYPES) do
        local name, resolve = entry[1], entry[2]
        local dataType = Enum.TooltipDataType and Enum.TooltipDataType[name]

        if dataType then
            -- Der Provider bekommt (module, data, tooltip, hidden) und gibt die Zeilen zurück
            self:RegisterTooltipLine(dataType, function(module, data, tooltip, hidden)
                return BuildLines(module, data, tooltip, hidden, name, resolve)
            end)
        else
            self:Debug("Tooltip-Typ nicht vorhanden:", name)
        end
    end
end

-- Beispiel: eigene Zeile für einen Tooltip-Typ anhängen (in einem eigenen Modul oder einer
-- Erweiterung). Der Typ kann als Name ("Item"), als Enum-Wert oder als "ALL" angegeben werden.
-- Der Provider gibt zurück, was angehängt werden soll, oder nil für nichts. Die Zeilen
-- erscheinen hinter der Trennlinie. data enthält nur Felder, die nicht secret sind, ein
-- fehlendes Feld muss also immer mit nil rechnen.
--
--   local Herbs = Glimpse:NewModule("Herbs")
--
--   function Herbs:OnEnable()
--       self:RegisterTooltipLine("Item", "OnItem")
--   end
--
--   function Herbs:OnItem(data)
--       if data.id == 12345 then
--           return "Wird für Alchemie gebraucht", 0.4, 1, 0.4      -- Text, r, g, b
--       end
--   end
--
-- Mehrere Zeilen als Tabelle, Doppelzeilen mit links/rechts:
--
--   return { "Erste Zeile", { "Links", "Rechts", 1, 1, 1 } }
