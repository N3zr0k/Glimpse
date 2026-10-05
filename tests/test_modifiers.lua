-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

local function setup()
    local Glimpse = stub.newGlimpse()
    stub.load("Core/Modifiers.lua", "Glimpse")
    return Glimpse
end

test("Modifiers: ohne Auswahl gilt immer", function()
    local G = setup()
    local settings = { modShift = false, modCtrl = false, modAlt = false }
    eq(G:ModifiersRequired(settings), false, "required")
    eq(G:ModifiersHeld(settings), true, "held")
end)

test("Modifiers: eine Taste", function()
    local G = setup()
    local settings = { modShift = true }
    eq(G:ModifiersRequired(settings), true, "required")
    eq(G:ModifiersHeld(settings), false, "ohne Taste")
    stub.keys.shift = true
    eq(G:ModifiersHeld(settings), true, "mit Taste")
    stub.keys.shift, stub.keys.ctrl = false, true
    eq(G:ModifiersHeld(settings), false, "falsche Taste")
end)

test("Modifiers: Kombination verlangt alle Tasten", function()
    local G = setup()
    local settings = { modShift = true, modAlt = true }
    stub.keys.shift = true
    eq(G:ModifiersHeld(settings), false, "nur Shift")
    stub.keys.alt = true
    eq(G:ModifiersHeld(settings), true, "Shift und Alt")
    stub.keys.ctrl = true
    eq(G:ModifiersHeld(settings), true, "zusätzliche Taste stört nicht")
end)

test("Modifiers: Optionsgruppe schreibt in die Einstellungen und meldet die Änderung", function()
    local G = setup()
    local settings = { modShift = false, modCtrl = false, modAlt = false }
    local changed = 0
    local group = G:BuildModifierOptions(settings, function() changed = changed + 1 end, 5)

    eq(group.inline, true, "inline")
    eq(group.order, 5, "order")
    eq(group.args.modCtrl.get(), false, "Startwert")
    group.args.modCtrl.set(nil, true)
    eq(settings.modCtrl, true, "gesetzt")
    eq(group.args.modCtrl.get(), true, "gelesen")
    eq(changed, 1, "onChange")
end)
