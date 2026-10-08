-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Modul Kampf (Modules/Combat) mit einem Namespace, der nur mitschreibt
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = { debug = false, debugOff = {} } }
    function Glimpse.db:RegisterNamespace() return { profile = {} } end
    _G.tContains = function(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Data.lua", "Glimpse")
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Core/IDs.lua", "Glimpse")
    for _, file in ipairs({ "Combat", "CombatKills", "CombatDeaths", "CombatLoot", "CombatTime", "CombatTooltip" }) do
        stub.load("Modules/Combat/" .. file .. ".lua", "Glimpse")
    end
    Glimpse.modules.Locations = { GetPlayerArea = function() return { map = 1429 } end, GetMapName = function() end }

    local counts = {}
    local ns = { Count = function(_, kind, id, zone, amount)
        counts[#counts + 1] = { kind = kind, id = id, zone = zone, amount = amount or 1 }
    end }
    -- Lesen für den Tooltip: counts.read[kind][id] = { char, account }
    counts.read = {}
    function ns:GetCount(kind, id, scope)
        local entry = counts.read[kind] and counts.read[kind][id]
        if not entry then return 0 end
        return scope == "account" and entry[2] or entry[1]
    end
    _G.GlimpseDB = { Register = function(_, name, options)
        counts.name, counts.options = name, options
        return ns
    end }

    local Combat = Glimpse.modules.Combat
    -- Die Dateien halten die Tabelle als Upvalue, daher füllen statt ersetzen
    for key, value in pairs({
        GetTime = function() return stub.now end,
        UnitGUID = function(unit) return stub.units[unit] and stub.units[unit].guid end,
        UnitIsDead = function(unit) return stub.units[unit] and stub.units[unit].dead end,
        UnitHealth = function() return 1 end,
        UnitIsTapDenied = function() return false end,
        UnitExists = function(unit) return stub.units[unit] ~= nil end,
        UnitCanAttack = function() return true end,
        UnitIsUnit = function(a, b) return stub.units[a] ~= nil and stub.units[a].guid == stub.units[b].guid end,
        IsFishingLoot = function() return false end,
    }) do Combat.api[key] = value end
    Combat:OnInitialize()
    Combat:OnEnable()
    _G.GlimpseDB = nil
    return Combat, counts
end

local NPC = "Creature-0-1-2-3-299-0001"

test("Kampf: Namespace combat im Bereich Core, Beute ist Weltwissen", function()
    local _, counts = setup()
    eq(counts.name, "combat", "Name")
    eq(counts.options.area, "Core", "Bereich")
    eq(counts.options.world.loot, true, "loot")
end)

test("Kampf: PARTY_KILL des Spielers zählt einmal je Leiche", function()
    local Combat, counts = setup()
    stub.units.player = { guid = "Player-1-1" }
    Combat:OnPartyKill("PARTY_KILL", "Player-1-1", NPC)
    Combat:OnPartyKill("PARTY_KILL", "Player-1-1", NPC)
    Combat:OnPartyKill("PARTY_KILL", "Player-1-2", "Creature-0-1-2-3-6-0002")
    eq(#counts, 1, "einmal")
    eq(counts[1].kind, "kill", "Art")
    eq(counts[1].id, 299, "NPC")
    eq(counts[1].zone, 1429, "Zone")
end)

test("Kampf: Tod des Ziels als Ersatz ohne PARTY_KILL", function()
    local Combat, counts = setup()
    Combat.partyKill = false
    stub.units.target = { guid = NPC, dead = true }
    Combat:OnTargetEvent("UNIT_HEALTH")
    eq(#counts, 1, "gezählt")
    Combat.partyKill = true
    stub.units.target = { guid = "Creature-0-1-2-3-6-0002", dead = true }
    Combat:OnTargetEvent("UNIT_HEALTH")
    eq(#counts, 1, "mit PARTY_KILL nicht")
end)

test("Kampf: Tod mit geschätztem Verursacher", function()
    local Combat, counts = setup()
    stub.units.player = { guid = "Player-1-1" }
    stub.units.target = { guid = NPC }
    stub.units.targettarget = { guid = "Player-1-1" }
    Combat:OnPlayerDamaged()
    stub.now = 5
    Combat:OnPlayerDead()
    eq(counts[1].kind, "death", "Art")
    eq(counts[1].id, 299, "Verursacher")

    stub.units.target = nil
    stub.now = 100
    Combat:OnPlayerDead()
    eq(counts[2].id, 0, "unbekannt")
end)

test("Kampf: Beute je NPC, zweites Fenster derselben Leiche zählt nicht", function()
    local Combat, counts = setup()
    local api = Combat.api
    api.GetNumLootItems = function() return 2 end
    api.GetLootSlotType = function() return 1 end
    api.GetLootSlotLink = function(slot) return slot == 1 and "|Hitem:2589::|h" or "|Hitem:2592::|h" end
    api.GetLootSourceInfo = function(slot) return NPC, slot == 1 and 2 or 1 end
    Combat:OnLootOpened()
    Combat:OnLootOpened()

    local found = {}
    for _, entry in ipairs(counts) do found[entry.kind .. ":" .. entry.id] = entry.amount end
    eq(found["looted:299"], 1, "Leiche")
    eq(found["loot:299:2589"], 2, "Leinenstoff")
    eq(found["loot:299:2592"], 1, "Wollstoff")
    eq(found["kill:299"], 1, "Kill über die Leiche")
    eq(#counts, 4, "kein zweites Mal")
end)

test("Kampf: geplünderte Leichen zählen als Kill, aber nicht doppelt", function()
    local Combat, counts = setup()
    local api = Combat.api
    local OTHER = "Creature-0-1-2-3-299-0002"
    stub.units.player = { guid = "Player-1-1" }
    Combat:OnPartyKill("PARTY_KILL", "Player-1-1", NPC)

    -- Flächenbeute: NPC schon über PARTY_KILL gezählt, OTHER ohne Ziel getötet (Pet, Fläche)
    api.GetNumLootItems = function() return 1 end
    api.GetLootSlotType = function() return 1 end
    api.GetLootSlotLink = function() return "|Hitem:2589::|h" end
    api.GetLootSourceInfo = function() return NPC, 1, OTHER, 1 end
    Combat:OnLootOpened()

    local kills = 0
    for _, entry in ipairs(counts) do
        if entry.kind == "kill" then kills = kills + 1 end
    end
    eq(kills, 2, "jede GUID einmal")
end)

test("Kampf: Beutefenster direkt nach eigenem Zauber zählt nicht (Kürschnern)", function()
    local Combat, counts = setup()
    local api = Combat.api
    api.GetNumLootItems = function() return 1 end
    api.GetLootSlotType = function() return 1 end
    api.GetLootSlotLink = function() return "|Hitem:2318::|h" end
    api.GetLootSourceInfo = function() return NPC, 1 end
    stub.now = 50
    Combat:OnSpellSucceeded("UNIT_SPELLCAST_SUCCEEDED", "player")
    stub.now = 50.2
    Combat:OnLootOpened()
    eq(#counts, 0, "nicht gezählt")
end)

test("Kampf: Kampfzeit in Sekunden", function()
    local Combat, counts = setup()
    stub.now = 10
    Combat:OnRegenDisabled()
    stub.now = 22.5
    Combat:OnRegenEnabled("PLAYER_REGEN_ENABLED")
    eq(counts[1].kind, "time", "Art")
    eq(counts[1].amount, 12.5, "Sekunden")
end)

test("Kampf: ohne Database still", function()
    local Glimpse = stub.newGlimpse()
    Glimpse.db = { profile = { debugOff = {} } }
    function Glimpse.db:RegisterNamespace() return { profile = {} } end
    _G.tContains = function() return false end
    stub.load("Core/Debug/Probes.lua", "Glimpse")
    stub.load("Core/Data.lua", "Glimpse")
    stub.load("Core/Debug/Debug.lua", "Glimpse")
    stub.load("Core/Debug/Debugger.lua", "Glimpse")
    stub.load("Modules/Combat/Combat.lua", "Glimpse")
    local Combat = Glimpse.modules.Combat
    Combat:OnInitialize()
    Combat:OnEnable()
    eq(Combat.ns, nil, "kein Namespace")
    Combat:Count("kill", 1)
end)

-- Tooltip mit Zeilen wie im Client: <Name>TextLeft<n> / TextRight<n>
local function FakeTooltip(lines)
    local tooltip = { added = {}, name = "FakeTip" }
    local function Field(text)
        local field = { text = text, shown = text ~= nil }
        function field:GetText() return self.text end
        function field:SetText(value) self.text = value end
        function field:Show() self.shown = true end
        function field:IsShown() return self.shown end
        return field
    end
    for index, text in ipairs(lines) do
        _G["FakeTipTextLeft" .. index] = Field(text)
        _G["FakeTipTextRight" .. index] = Field(nil)
    end
    function tooltip:GetName() return self.name end
    function tooltip:NumLines() return #lines end
    function tooltip:Show() end
    function tooltip:AddLine(text) self.added[#self.added + 1] = text end
    return tooltip
end

test("Kampf-Tooltip: Kills und Tode rechts neben dem Namen, Account in Klammern", function()
    local Combat, counts = setup()
    counts.read = { kill = { [299] = { 3, 7 } }, death = { [299] = { 1, 3 } } }
    local tooltip = FakeTooltip({ "Wolf", "Stufe 5" })
    Combat:OnUnitTooltip(tooltip, { guid = NPC })
    local right = _G.FakeTipTextRight1:GetText()
    eq(right:find("|cffd0d0d03|r", 1, true) ~= nil, true, "Kills")
    eq(right:find("|cffff55551|r", 1, true) ~= nil, true, "Tode")
    eq(right:find("(7)", 1, true), nil, "Account aus")

    Combat.settings.profile.account = true
    _G.FakeTipTextRight1:SetText(nil)
    Combat:OnUnitTooltip(tooltip, { guid = NPC })
    eq(_G.FakeTipTextRight1:GetText():find("(7)", 1, true) ~= nil, true, "Account an")
end)

test("Kampf-Tooltip: belegtes Feld führt zur eigenen Zeile, nichts ohne Zahlen", function()
    local Combat, counts = setup()
    counts.read = { kill = { [299] = { 2, 2 } } }
    local tooltip = FakeTooltip({ "Wolf" })
    _G.FakeTipTextRight1:SetText("anderes Addon")
    Combat:OnUnitTooltip(tooltip, { guid = NPC })
    eq(#tooltip.added, 1, "eigene Zeile am Ende")
    eq(_G.FakeTipTextRight1:GetText(), "anderes Addon", "Feld unverändert")

    local empty = FakeTooltip({ "Hirsch" })
    Combat:OnUnitTooltip(empty, { guid = "Creature-0-1-2-3-883-0001" })
    eq(#empty.added + #(_G.FakeTipTextRight1:GetText() or ""), 0, "nichts gezählt")

    Combat.settings.profile.kills, Combat.settings.profile.deaths = false, false
    local off = FakeTooltip({ "Wolf" })
    Combat:OnUnitTooltip(off, { guid = NPC })
    eq(#off.added, 0, "ausgeschaltet")
    eq(_G.FakeTipTextRight1:GetText(), nil, "ausgeschaltet, Feld leer")
end)

test("Kampf-Tooltip: links an die Stufe gehängt", function()
    local Combat, counts = setup()
    counts.read = { kill = { [299] = { 4, 4 } } }
    Combat.settings.profile.mode, Combat.settings.profile.side = "level", "left"
    local tooltip = FakeTooltip({ "Wolf", "Stufe 5" })
    Combat:OnUnitTooltip(tooltip, { guid = NPC })
    eq(_G.FakeTipTextLeft2:GetText():find("^Stufe 5 ") ~= nil, true, "angehängt")
    Combat:OnUnitTooltip(tooltip, { guid = NPC })
    local _, n = _G.FakeTipTextLeft2:GetText():gsub("Attack", "")
    eq(n, 1, "nicht doppelt")
end)
