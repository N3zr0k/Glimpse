local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- ID-Helfer für Module, Erweiterungen, Database und Tooltips:
--   Glimpse.IDs:ParseGUID(guid)            -> Art, ID   ("Creature-0-1-2-3-299-0" -> "Creature", 299)
--   Glimpse.IDs:NPCFromGUID(guid)          -> NPC-ID oder nil (nur Kreaturen und Fahrzeuge)
--   Glimpse.IDs:DescribeItem(id, callback) -> callback("Name [id]", name); wartet auf den Item-Cache
--   Glimpse.IDs:DescribeSpell(id)          -> "Name [id]"
--   Glimpse.IDs:DescribeMap(mapID)         -> "Name [id]"
--   Glimpse.IDs:ZoneKey()                  -> uiMapID, in Instanzen -instanceID; nil, wenn unbekannt
--   Glimpse.IDs:Where()                    -> mapID, x, y, Zonenname (x, y nil in Instanzen)
local IDs = {}
Glimpse.IDs = IDs

-- Blizzard-API gebündelt, damit Tests sie ersetzen können
IDs.api = {
    GetItemNameByID = C_Item and C_Item.GetItemNameByID,
    GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo,
    CreateItem = Item and Item.CreateFromItemID and function(id) return Item:CreateFromItemID(id) end,
    GetSpellName = C_Spell and C_Spell.GetSpellName,
    GetSpellInfo = GetSpellInfo,
    GetMapInfo = C_Map and C_Map.GetMapInfo,
}

local function Clean(value)
    if value ~= nil and Glimpse:IsSecret(value) then return nil end
    return value
end

local function Describe(name, id)
    return format("%s [%s]", name or "?", tostring(id))
end

function IDs:ParseGUID(guid)
    guid = Clean(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    return kind, tonumber(id)
end

function IDs:NPCFromGUID(guid)
    local kind, id = self:ParseGUID(guid)
    if kind == "Creature" or kind == "Vehicle" then return id end
end

local function ItemName(id)
    local get = IDs.api.GetItemNameByID
    local name = get and get(id)
    if not name and IDs.api.GetItemInfo then name = IDs.api.GetItemInfo(id) end
    return Clean(name)
end

function IDs:DescribeItem(id, callback)
    local name = ItemName(id)
    if name or not self.api.CreateItem then
        callback(Describe(name, id), name)
        return
    end

    local item = self.api.CreateItem(id)
    if item:IsItemEmpty() then
        callback(Describe(nil, id), nil)
        return
    end
    item:ContinueOnItemLoad(function()
        name = ItemName(id)
        callback(Describe(name, id), name)
    end)
end

function IDs:DescribeSpell(id)
    local name
    if self.api.GetSpellName then
        name = self.api.GetSpellName(id)
    elseif self.api.GetSpellInfo then
        name = self.api.GetSpellInfo(id)
    end
    return Describe(Clean(name), id)
end

function IDs:DescribeMap(mapID)
    local info = self.api.GetMapInfo and self.api.GetMapInfo(mapID)
    return Describe(info and Clean(info.name), mapID)
end

function IDs:ZoneKey()
    local Locations = Glimpse:GetModule("Locations", true)
    local area = Locations and Locations:GetPlayerArea()
    if not area then return nil end
    if area.instance then return -area.instance, area.name end
    return area.map, Locations:GetMapName(area.map)
end

function IDs:Where()
    local Locations = Glimpse:GetModule("Locations", true)
    local area = Locations and Locations:GetPlayerArea()
    if not area then return nil end
    if area.instance then return -area.instance, nil, nil, area.name end
    return area.map, area.x, area.y, Locations:GetMapName(area.map)
end
