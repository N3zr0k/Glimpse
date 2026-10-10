local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")

-- Anzeige: Kills und Tode je Kreatur im Unit-Tooltip, "[Kill] 3(7) · [Friedhof] 1(3)", Klammer = Account (Option).
-- Liest nur, was CombatKills.lua und CombatDeaths.lua gespeichert haben. Position: an Name oder Stufe (rechtes Feld oder an
-- den Text gehängt) oder eigene Zeile (Ende des Blizzard-Tooltips oder Anfang des Glimpse-Bereichs). Geht die
-- Position nicht sicher (Secret, Feld belegt, Zeile fehlt), steht der Text in einer eigenen Zeile.

local KILL_ICON = "|TInterface\\CURSOR\\Attack:12|t"
local DEATH_ICON = "|A:poi-graveyard-neutral:14:14|a"
local COLOR = { kill = "|cffd0d0d0", killAccount = "|cff808080", death = "|cffff5555", deathAccount = "|cff994040" }
local SEPARATOR = "|cffffffff · |r"
Combat.KILL_ICON, Combat.DEATH_ICON = KILL_ICON, DEATH_ICON

Combat.tooltipDefaults = {
    kills = true,
    deaths = true,
    account = false,
    mode = "name",     -- name, level oder line
    side = "right",    -- bei name/level: right (rechtes Feld) oder left (an den Text)
    frame = "blizzard", -- bei line: blizzard (Tooltip-Ende) oder glimpse (Glimpse-Bereich)
}

function Combat:TooltipOption(name)
    local value = self.settings and self.settings.profile[name]
    if value == nil then value = self.tooltipDefaults[name] end
    return value
end

-- Zeilenfeld des Tooltips, nil wenn Name oder Zeilenzahl nicht lesbar sind
local function Field(tooltip, index, side)
    if type(tooltip) ~= "table" or not tooltip.GetName then return nil end
    local name, count = tooltip:GetName(), tooltip.NumLines and tooltip:NumLines()
    if not name or type(count) ~= "number" or Glimpse:IsSecret(count) or count < index then return nil end
    return _G[name .. "Text" .. side .. index]
end

local function Readable(text)
    return text == nil or (type(text) == "string" and not Glimpse:IsSecret(text))
end

-- An den lesbaren Text der Zeile hängen
local function Append(tooltip, index, text)
    local line = Field(tooltip, index, "Left")
    if not (line and line.GetText and line.SetText) then return false end
    local current = line:GetText()
    if not Readable(current) or not current or current == "" then return false end
    if not current:find(text, 1, true) then -- Tooltip wird teils mehrfach verarbeitet
        line:SetText(current .. " " .. text)
        tooltip:Show()
    end
    return true
end

-- Ins rechte Feld, nur wenn es leer ist; bleibt es unsichtbar, wieder leeren
local function Right(tooltip, index, text)
    local right = Field(tooltip, index, "Right")
    if not (right and right.GetText and right.SetText) then return false end
    local current = right:GetText()
    if not Readable(current) then return false end
    if current == text then return true end
    if current and current ~= "" then return false end

    right:SetText(text)
    right:Show()
    tooltip:Show()
    if right.IsShown and not right:IsShown() then
        right:SetText("")
        return false
    end
    return true
end

local function HasLine(tooltip, text)
    local count = tooltip.NumLines and tooltip:NumLines()
    if type(count) ~= "number" or Glimpse:IsSecret(count) then return false end
    for index = 1, count do
        local line = Field(tooltip, index, "Left")
        local current = line and line:GetText()
        if Readable(current) and current == text then return true end
    end
    return false
end

local function Part(icon, mine, all, showAccount, color, accountColor)
    local text = format("%s %s%d|r", icon, color, mine)
    if showAccount then text = text .. format("%s(%d)|r", accountColor, all) end
    return text
end

--- Beispiel mit festen Zahlen für die Optionen
function Combat:ExampleTooltipText()
    local showAccount = self:TooltipOption("account")
    local parts = {}
    if self:TooltipOption("kills") then
        parts[#parts + 1] = Part(KILL_ICON, 3, 7, showAccount, COLOR.kill, COLOR.killAccount)
    end
    if self:TooltipOption("deaths") then
        parts[#parts + 1] = Part(DEATH_ICON, 1, 3, showAccount, COLOR.death, COLOR.deathAccount)
    end
    return table.concat(parts, SEPARATOR)
end

--- Text für eine Kreatur, nil wenn nichts zu zeigen ist
function Combat:CreatureText(npc)
    if not self.ns then return nil end
    local showAccount = self:TooltipOption("account")
    local parts = {}

    local function Add(option, kind, icon, color, accountColor)
        if not self:TooltipOption(option) then return end
        local mine, all = self.ns:GetCount(kind, npc, "char"), self.ns:GetCount(kind, npc, "account")
        -- mit Account auch "0(5)", wenn nur andere Charaktere gezählt haben
        if mine > 0 or (showAccount and all > 0) then
            parts[#parts + 1] = Part(icon, mine, math.max(all, mine), showAccount, color, accountColor)
        end
    end
    Add("kills", "kill", KILL_ICON, COLOR.kill, COLOR.killAccount)
    Add("deaths", "death", DEATH_ICON, COLOR.death, COLOR.deathAccount)
    if #parts > 0 then return table.concat(parts, SEPARATOR) end
end

--- Läuft nach Blizzard und vor den Zeilen-Providern, damit die eigene Zeile oben im Glimpse-Bereich steht
function Combat:OnUnitTooltip(tooltip, data)
    if type(data) ~= "table" or Glimpse:IsSecret(data) then return end
    if not (self:TooltipOption("kills") or self:TooltipOption("deaths")) then return end
    if _G.TooltipUtil and _G.TooltipUtil.SurfaceArgs then pcall(_G.TooltipUtil.SurfaceArgs, data) end

    local guid = data.guid
    if type(guid) ~= "string" or Glimpse:IsSecret(guid) then return end
    local npc = Glimpse.IDs:NPCFromGUID(guid)
    local text = npc and self:CreatureText(npc)
    if not text then return end

    local mode = self:TooltipOption("mode")
    if mode == "name" or mode == "level" then
        local index = mode == "name" and 1 or 2
        local place = self:TooltipOption("side") == "left" and Append or Right
        local ok, placed = pcall(place, tooltip, index, text)
        if ok and placed then return end
    end

    local ok, present = pcall(HasLine, tooltip, text)
    if ok and present then return end
    if self:TooltipOption("frame") == "blizzard" and tooltip.AddLine then
        tooltip:AddLine(text, 0.6, 0.6, 0.6)
        tooltip:Show()
        return
    end
    Glimpse:AddTooltipLine(tooltip, text, nil, 0.6, 0.6, 0.6)
    Glimpse:AddTooltipLine(tooltip, " ")
end

function Combat:StartTooltip()
    if Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
        self:RegisterTooltip(Enum.TooltipDataType.Unit, "OnUnitTooltip")
    end
end
