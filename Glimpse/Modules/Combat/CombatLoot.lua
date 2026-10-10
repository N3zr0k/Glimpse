local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")

-- Backup und Kontrolle für den Killzähler, keine Beute-Statistik (die kommt von Gathering).
-- Beute pro NPC aus dem Beutefenster: looted [NPC] einmal je Leiche, loot:<NPC> [Item] mit Menge.
-- Jede geplünderte Leiche ist auch ein Kill (CombatKills.lua), sonst fehlen Kills ohne Ziel.
-- Angelbeute und Knoten (GameObject) gehören nicht hierher. Ein Beutefenster direkt nach einem eigenen Zauber
-- (Kürschnern, Taschendiebstahl) zählt nicht, ebenso eine zweite Plünderung derselben Leiche.

local api, Clean = Combat.api, Combat.Clean

local LOOT_ITEM = Enum and Enum.LootSlotType and Enum.LootSlotType.Item or 1
local CORPSE_REPEAT = 600
local CAST_WINDOW = 0.5 -- Sekunden zwischen Zauber und Beutefenster
local Seen = Combat.NewSeen(CORPSE_REPEAT, 2000)
local lastCast = -1e9

local function ItemID(link)
    link = Clean(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

--- { [guid] = { [itemID] = Menge } } aller Kreaturen im Beutefenster; Kreaturen ohne Items mit leerer Tabelle
function Combat:ReadLoot()
    local bySource = {}
    for slot = 1, api.GetNumLootItems() do
        local itemID = api.GetLootSlotType(slot) == LOOT_ITEM and ItemID(api.GetLootSlotLink(slot)) or nil
        -- guid1, menge1, guid2, menge2 ... (Flächenbeute)
        local info = { api.GetLootSourceInfo(slot) }
        for i = 1, #info, 2 do
            local guid, amount = Clean(info[i]), tonumber(Clean(info[i + 1])) or 1
            if Glimpse.IDs:NPCFromGUID(guid) then
                local items = bySource[guid] or {}
                bySource[guid] = items
                if itemID then items[itemID] = (items[itemID] or 0) + amount end
            end
        end
    end
    return bySource
end

function Combat:OnLootOpened()
    local ok, fishing = pcall(api.IsFishingLoot)
    if ok and Clean(fishing) == true then return end
    if api.GetTime() - lastCast <= CAST_WINDOW then return end

    local read, sources = pcall(self.ReadLoot, self)
    if not read then
        self.debug:Error("loot", "%s", tostring(sources))
        return
    end

    local now = api.GetTime()
    for guid, items in pairs(sources) do
        -- schon über PARTY_KILL oder den Tod des Ziels gezählt: CountKill erkennt die GUID
        self:CountKill(guid, "loot")
        -- zweites Fenster derselben Leiche = Kürschnern oder erneut geöffnet
        if not Seen(guid, now) then
            local npc = Glimpse.IDs:NPCFromGUID(guid)
            self:Count("looted", npc)
            for itemID, amount in pairs(items) do
                self:Count("loot:" .. npc, itemID, amount)
            end
            self.debug:Log("loot", "%s", tostring(npc))
        end
    end
end

function Combat:OnSpellSucceeded(_, unit)
    if unit == "player" then lastCast = api.GetTime() end
end

function Combat:StartLoot()
    self:RegisterEvent("LOOT_OPENED", "OnLootOpened")
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellSucceeded")
end
