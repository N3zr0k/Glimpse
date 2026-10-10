-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Modul Sichern (Modules/Save): zählt Änderungen der Database und fragt im Ruhebereich
local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.name = "Glimpse"
    Glimpse.db = { profile = {} }
    function Glimpse.db:RegisterNamespace() return { profile = { ask = true, changes = 100, minutes = 30 } } end
    for _, file in ipairs({ "Save", "SavePrompt", "SaveOptions" }) do
        stub.load("Modules/Save/" .. file .. ".lua", "Glimpse")
    end
    local callbacks = {}
    _G.GlimpseDB = { EVENT_CHANGED = "changed",
        RegisterCallback = function(owner, event, method) callbacks[event] = { owner = owner, method = method } end }
    local shown, reloads = {}, 0
    _G.StaticPopupDialogs = {}
    _G.StaticPopup_Show = function(name, count) shown[#shown + 1] = { name = name, count = count } end

    local Save = Glimpse.modules.Save
    local state = { resting = true, combat = false, dead = false }
    for key, value in pairs({
        GetTime = function() return stub.now end,
        IsResting = function() return state.resting end,
        InCombatLockdown = function() return state.combat end,
        UnitIsDeadOrGhost = function() return state.dead end,
        ReloadUI = function() reloads = reloads + 1 end,
    }) do Save.api[key] = value end
    Save:OnInitialize()
    Save:OnEnable()
    local function Change(count)
        for _ = 1, count do Save:OnDataChanged() end
    end
    return Save, state, shown, function() return reloads end, Change, callbacks
end

test("Sichern: zählt Änderungen der Database", function()
    local Save, _, _, _, _, callbacks = setup()
    eq(callbacks.changed.owner, Save, "Rückruf angemeldet")
    eq(Save.pending, 0, "Start")
    Save:OnDataChanged()
    Save:OnDataChanged()
    eq(Save.pending, 2, "gezählt")
    _G.GlimpseDB = nil
end)

test("Sichern: fragt im Ruhebereich ab der Menge", function()
    local Save, _, shown, _, Change = setup()
    Change(99)
    Save:OnResting()
    eq(#shown, 0, "noch zu wenig")
    Change(1)
    Save:OnResting()
    eq(#shown, 1, "gefragt")
    eq(shown[1].count, 100, "Anzahl im Text")
    _G.GlimpseDB = nil
end)

test("Sichern: fragt nach der Zeit, aber nur mit einer Änderung", function()
    local Save, _, shown, _, Change = setup()
    stub.now = stub.now + 31 * 60
    Save:OnResting()
    eq(#shown, 0, "ohne Änderung nichts")
    Change(1)
    Save:OnResting()
    eq(#shown, 1, "mit einer Änderung nach 31 Minuten")
    -- die Zeit zählt ab der Frage neu
    Change(1)
    Save:OnResting()
    eq(#shown, 1, "gleich danach nicht noch einmal")
    _G.GlimpseDB = nil
end)

test("Sichern: nicht im Kampf, nicht tot, nicht beim Verlassen, nicht ausgeschaltet", function()
    local Save, state, shown, _, Change = setup()
    Change(500)
    state.combat = true
    Save:OnResting()
    state.combat, state.dead = false, true
    Save:OnResting()
    state.dead, state.resting = false, false
    Save:OnResting()
    eq(#shown, 0, "keine Frage")
    state.resting = true
    Save.settings.profile.ask = false
    Save:OnResting()
    eq(#shown, 0, "ausgeschaltet")
    Save.settings.profile.ask = true
    Save.settings.profile.minutes = 0
    Save:OnResting()
    eq(#shown, 1, "Menge reicht auch ohne Zeit")
    _G.GlimpseDB = nil
end)

test("Sichern: Dialog lädt neu, Optionen im Tab Daten", function()
    local Save, _, _, reloads = setup()
    _G.StaticPopupDialogs.GLIMPSE_SAVE_DATA.OnAccept()
    eq(reloads(), 1, "ReloadUI")
    local Glimpse = LibStub("AceAddon-3.0"):GetAddon("Glimpse")
    local options = Glimpse:BuildSaveOptions(5)
    eq(options.args.changes.min, 10, "kleinster Wert")
    eq(options.args.minutes.min, 0, "0 = aus")
    eq(options.args.changes.disabled(), false, "aktiv")
    Save.settings.profile.ask = false
    eq(options.args.changes.disabled(), true, "ohne Fragen gesperrt")
    _G.GlimpseDB = nil
end)
