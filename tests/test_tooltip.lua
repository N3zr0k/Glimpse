-- luacheck: ignore 111 113 122 143 432
local stub = require("wowstub")

-- Tooltip-Zeilen von Erweiterungen (Core/Tooltip/Tooltip.lua): Trennlinien
local SEPARATOR = "|TInterface\\Common\\UI-TooltipDivider-Transparent:8:"

local function setup()
    local Glimpse = stub.newGlimpse()
    Glimpse.ModuleProto = {}
    local dispatch
    _G.Enum.TooltipDataType = { Spell = 1, Item = 2 }
    _G.TooltipDataProcessor = { AddTooltipPostCall = function(_, func) dispatch = func end }
    _G.geterrorhandler = function() return function(err) error(err, 0) end end
    stub.load("Core/Tooltip/Tooltip.lua", "Glimpse")

    -- ein Tooltip, der seine Zeilen als TextLeft<n> festhält
    local tooltip = { lines = {} }
    local function sync()
        for index, text in ipairs(tooltip.lines) do
            _G["TestTipTextLeft" .. index] = { GetText = function() return text end }
        end
    end
    function tooltip:GetName() return "TestTip" end
    function tooltip:GetWidth() return 5000 end -- alter Inhalt des wiederverwendeten Tooltips
    function tooltip:NumLines() return #self.lines end
    function tooltip:AddLine(text) self.lines[#self.lines + 1] = text sync() end
    function tooltip:AddDoubleLine(left) self.lines[#self.lines + 1] = left sync() end
    return Glimpse, tooltip, function(data) dispatch(tooltip, data) end
end

local function isSeparator(text) return text:sub(1, #SEPARATOR) == SEPARATOR end

test("Tooltip: eine Trennlinie vor der ersten Zeile, AddTooltipSeparator trennt Gruppen", function()
    local Glimpse, tooltip, run = setup()
    Glimpse:RegisterTooltipLine("Test:Spell", Enum.TooltipDataType.Spell, function()
        return { "Erste", { separator = true }, "Zweite" }
    end)
    tooltip:AddLine("Original")
    run({ type = Enum.TooltipDataType.Spell })

    eq(#tooltip.lines, 5, "Original, Linie, Erste, Linie, Zweite")
    eq(tooltip.lines[1], "Original", "Original zuerst")
    eq(isSeparator(tooltip.lines[2]), true, "erste Trennlinie von selbst")
    eq(tooltip.lines[3], "Erste", "erste Gruppe")
    eq(isSeparator(tooltip.lines[4]), true, "Trennlinie zwischen den Gruppen")
    eq(tooltip.lines[5], "Zweite", "zweite Gruppe")
end)

test("Tooltip: Trennlinie hat feste Breite, unabhängig von der alten Tooltip-Breite", function()
    local Glimpse, tooltip, run = setup()
    Glimpse:RegisterTooltipLine("Test:Spell", Enum.TooltipDataType.Spell, function() return { "Zeile" } end)
    tooltip:AddLine(string.rep("x", 60))
    run({ type = Enum.TooltipDataType.Spell })
    eq(tooltip.lines[2]:match(":8:(%d+)|t"), "200", "feste Breite")
end)

test("Tooltip: eine Trennlinie am Ende fällt weg, erneutes Verarbeiten hängt nichts doppelt an", function()
    local Glimpse, tooltip, run = setup()
    Glimpse:RegisterTooltipLine("Test:Spell", Enum.TooltipDataType.Spell, function()
        return { "Nur", { separator = true } }
    end)
    tooltip:AddLine("Original")
    run({ type = Enum.TooltipDataType.Spell })
    eq(#tooltip.lines, 3, "Original, Linie, Nur")
    run({ type = Enum.TooltipDataType.Spell })
    eq(#tooltip.lines, 3, "nicht doppelt")
end)

test("Tooltip: AddTooltipSeparator als erstes in einem rohen Handler ist die erste Linie, nicht zwei", function()
    local Glimpse, tooltip, run = setup()
    Glimpse:RegisterTooltipHandler("Test:Raw", Enum.TooltipDataType.Spell, function(tip)
        Glimpse:AddTooltipSeparator(tip)
        Glimpse:AddTooltipLine(tip, "Text")
        Glimpse:AddTooltipSeparator(tip)
        Glimpse:AddTooltipLine(tip, "Mehr")
    end)
    tooltip:AddLine("Original")
    run({ type = Enum.TooltipDataType.Spell })
    eq(#tooltip.lines, 5, "Original, Linie, Text, Linie, Mehr")
    eq(isSeparator(tooltip.lines[2]), true, "Linie nach dem Original")
    eq(tooltip.lines[3], "Text", "Text direkt dahinter")
end)
