local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Tooltip-Infos für Entwickler, nur im Debug-Modus (/gli debug on):
--
--   [Glimpse] TooltipDebug          <- Addon-Kennung blau (Glimpse:DebugTag)
--   Ziel: NPC (ID 1234)
--   Datentyp: Unit (2)
--   Tooltip-Frame: GameTooltip
--   Geschützte Felder: guid        <- nur bei Secret-Feldern
--
-- Kann gelöscht werden (dann auch aus Modules.xml). Beispiel für eigene Zeilen ganz unten.
local TooltipDebug = Glimpse:NewModule("TooltipDebug")

-- Wert -> Name aus Enum.TooltipDataType, lazy aufgebaut
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

-- Erstes GUID-Segment -> Zielart
local GUID_KINDS = {
    Creature = "NPC",
    Vehicle = "NPC",
    Pet = "Pet",
    Player = "Player",
    GameObject = "Object",
}

-- Units: Ziel steckt in der GUID, nicht in data.id. Rückgabe target, id (id optional).
local function ResolveUnit(data)
    local guid = data.guid
    if not guid then return "Unit", nil end

    -- Creature-0-<Server>-<Instanz>-<Zone>-<NPC-ID>-<Spawn>
    local kind, _, _, _, _, npcID = strsplit("-", guid)
    -- Spieler-GUIDs haben dort keine NPC-ID
    if kind == "Player" then npcID = nil end

    return GUID_KINDS[kind] or "Unit", npcID
end

-- ID aus data.id, außer der Typ bringt resolve(data) mit
local function BuildLines(module, data, tooltip, hidden, target, resolve)
    -- pro Tooltip prüfen, damit Debug live umschaltbar ist
    if not Glimpse:IsDebug() then return nil end

    local id = data.id
    if resolve then target, id = resolve(data) end

    local targetLine = L["Target"] .. ": " .. target
    if id then targetLine = targetLine .. " (ID " .. id .. ")" end

    local typeText = "?"
    if data.type ~= nil then
        typeText = format("%s (%s)", TypeName(data.type), tostring(data.type))
    end

    -- anonyme Tooltip-Frames
    local frame = tooltip and tooltip:GetName()
    if not frame or Glimpse:IsSecret(frame) then frame = "?" end

    local lines = {
        { Glimpse:DebugTag(Glimpse.name) .. " " .. module:GetName(), nil, 0.6, 0.6, 0.6 },
        { targetLine, nil, 0.6, 0.6, 0.6 },
        { L["Data type"] .. ": " .. typeText, nil, 0.6, 0.6, 0.6 },
        { L["Tooltip frame"] .. ": " .. frame, nil, 0.6, 0.6, 0.6 },
    }

    if hidden and #hidden > 0 then
        tinsert(lines, { L["Secret fields"] .. ": " .. table.concat(hidden, ", "), nil, 0.6, 0.6, 0.6 })
    end

    return lines
end

-- { Name in Enum.TooltipDataType, optionaler Resolver }, fehlende Typen werden übersprungen
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
            self:RegisterTooltipLine(dataType, function(module, data, tooltip, hidden)
                return BuildLines(module, data, tooltip, hidden, name, resolve)
            end)
        else
            self:Debug("Tooltip-Typ nicht vorhanden:", name)
        end
    end
end

-- Beispiel für eigene Zeilen (Modul oder Erweiterung). Typ als Name, Enum-Wert oder "ALL".
-- data enthält keine Secret-Felder, jedes Feld kann also nil sein.
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
