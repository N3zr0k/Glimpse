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

-- Version unter dem Rahmen einer Seite mit Tabs (Core/Options.lua)
local function footerSetup()
    local Glimpse = stub.newGlimpse()
    Glimpse.GetMeta = function(_, key) return key == "Version" and "1.2.3" or nil end
    Glimpse.L = Glimpse.L or {}
    stub.load("Core/Options.lua", "Glimpse")
    return Glimpse
end

test("Optionen: die Version steht unter dem Rahmen der Tabs", function()
    local G = footerSetup()
    local points, text, heightArg = {}, nil, nil
    local fontString = {
        SetPoint = function(_, ...) points.text = { ... } end,
        SetJustifyH = function() end,
        SetText = function(_, value) text = value end,
    }
    local widget = {
        frame = { CreateFontString = function() return fontString end, GetHeight = function() return 400 end },
        content = { SetPoint = function(_, ...) points.content = { ... } end },
        OnHeightSet = function(_, height) heightArg = height end,
        SetTitle = function() points.content = { "BOTTOMRIGHT", -10, 10 } end, -- setzt die Anker zurück wie AceGUI
    }
    local realCreateFrame, level = _G.CreateFrame, nil
    _G.CreateFrame = function()
        return {
            SetPoint = function() end, SetSize = function() end,
            SetFrameLevel = function(_, value) level = value end,
            CreateFontString = function() return fontString end,
        }
    end
    widget.frame.GetFrameLevel = function() return 3 end
    eq(G:AddVersionFooter(widget, "Glimpse_X"), true, "gelingt")
    _G.CreateFrame = realCreateFrame
    eq(level, 53, "Text liegt weit über dem Tab-Rahmen")
    eq(points.content[1], "BOTTOMRIGHT", "Inhalt endet früher")
    eq(points.content[3], 24, "eine Zeile Platz")
    eq(text:find("1.2.3", 1, true) ~= nil, true, "Versionstext")
    eq(heightArg, 386, "Höhe des Inhalts gekürzt")
    widget:OnHeightSet(500)
    eq(heightArg, 486, "auch bei späteren Größenänderungen")
    widget:SetTitle("Titel")
    eq(points.content[3], 24, "nach SetTitle wieder Platz")
    eq(G:AddVersionFooter(nil, "Glimpse_X"), false, "ohne Panel")
end)
