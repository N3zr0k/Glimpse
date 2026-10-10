local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local IDs = Glimpse.IDs

-- Namen zu NPC- und Objekt-IDs. Der Core lernt sie beim Spielen (Ziel, Angreifer) und legt sie in Database ab
-- (Namespace names, Sprache des Clients); Gathering meldet Objekte über LearnName.
--   Glimpse.IDs:NPCName(id)                 -> Name oder nil
--   Glimpse.IDs:ObjectName(id)              -> Name oder nil
--   Glimpse.IDs:LearnName(kind, id, name)   -> kind "npc" oder "object"
--   Glimpse.IDs:LearnUnit(unit)             -> merkt den Namen einer Kreatur anhand ihrer GUID

local NAMESPACE = "names"

IDs.api.UnitName = UnitName
IDs.api.UnitGUID = UnitGUID

local known = { npc = {}, object = {} } -- Sitzungs-Cache, spart Zugriffe auf Database
local writer

local function Names()
    if writer then return writer end
    local DB = _G.GlimpseDB
    if DB then writer = DB:Register(NAMESPACE, { area = "Misc" }) end
    return writer
end

local function Clean(value)
    if value ~= nil and Glimpse:IsSecret(value) then return nil end
    return value
end

function IDs:LearnName(kind, id, name)
    name = Clean(name)
    if not known[kind] or type(id) ~= "number" or type(name) ~= "string" or name == "" then return false end
    if known[kind][id] == name then return false end

    local ns = Names()
    if not ns then return false end
    known[kind][id] = name
    ns:SetLabel(kind, id, name)
    return true
end

local function Lookup(kind, id)
    local name = known[kind][id]
    if name then return name end

    local ns = Names()
    name = ns and ns:GetLabel(kind, id)
    if name then known[kind][id] = name end
    return name
end

function IDs:NPCName(id)
    return Lookup("npc", id)
end

function IDs:ObjectName(id)
    return Lookup("object", id)
end

function IDs:LearnUnit(unit)
    local api = self.api
    if not (api.UnitGUID and api.UnitName) then return false end

    local npc = self:NPCFromGUID(api.UnitGUID(unit))
    if npc then return self:LearnName("npc", npc, api.UnitName(unit)) end
    return false
end

--- Cache leeren (Tests)
function IDs:ForgetNames()
    known = { npc = {}, object = {} }
    writer = nil
end
