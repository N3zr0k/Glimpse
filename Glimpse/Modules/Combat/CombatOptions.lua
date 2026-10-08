local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Combat = Glimpse:GetModule("Combat")
local L = Glimpse.L

-- Tab "Kampf": Anzeige der Kills und Tode im Kreatur-Tooltip (CombatTooltip.lua)

local function Get(name) return Combat:TooltipOption(name) end
local function Set(name, value) Combat.settings.profile[name] = value end
local function Off() return not (Get("kills") or Get("deaths")) end

function Glimpse:BuildCombatOptions(order)
    return {
        type = "group", order = order, name = L["Combat"],
        args = {
            example = {
                type = "description", order = 1, fontSize = "medium", width = "full",
                name = function()
                    return format("%s  |cffffd100%s|r %s\n%s %s\n%s %s\n|cff999999%s|r", L["Example:"], L["Wild Boar"],
                        Combat:ExampleTooltipText(), Combat.KILL_ICON, L["How often you have killed it"],
                        Combat.DEATH_ICON, L["How often it has killed you"],
                        L["First the number of this character, in brackets the account (if switched on)."])
                end,
            },
            kills = {
                type = "toggle", order = 2, width = "full", name = L["Show kills in creature tooltips"],
                desc = L["Shows how often you have killed a creature, with a symbol, next to its name or in the tooltip."],
                get = function() return Get("kills") end,
                set = function(_, value) Set("kills", value) end,
            },
            deaths = {
                type = "toggle", order = 3, width = "full", name = L["Show deaths in creature tooltips"],
                desc = L["Shows how often a creature has killed you, in red with a graveyard symbol. Who killed you is an estimate: the enemy that attacked you last."],
                get = function() return Get("deaths") end,
                set = function(_, value) Set("deaths", value) end,
            },
            account = {
                type = "toggle", order = 4, width = "full", name = L["Also show account values"],
                desc = L["Adds the numbers of all your characters in brackets, e.g. 3(7) for 3 kills, 7 on the account, in a darker color."],
                get = function() return Get("account") end,
                set = function(_, value) Set("account", value) end,
                disabled = Off,
            },
            mode = {
                type = "select", order = 5, name = L["Position 1"], style = "dropdown",
                desc = L["Where the numbers stand: at the name (line 1), at the level (line 2) or in an own line. If that is not possible, the own line is used."],
                values = { name = L["Next to the name"], level = L["Next to the level"], line = L["Own line"] },
                sorting = { "name", "level", "line" },
                get = function() return Get("mode") end,
                set = function(_, value) Set("mode", value) end,
                disabled = Off,
            },
            position = {
                type = "select", order = 6, name = L["Position 2"], style = "dropdown",
                desc = L["Next to the name or level: left (behind the text of the line) or right (right-aligned, the text of the line stays unchanged). Own line: Blizzard frame (a line at the end of the tooltip) or Glimpse frame (at the start of the Glimpse area below the separator line, followed by an empty line)."],
                values = function()
                    if Get("mode") == "line" then return { blizzard = L["Blizzard frame"], glimpse = L["Glimpse frame"] } end
                    return { left = L["Left"], right = L["Right"] }
                end,
                get = function() return Get(Get("mode") == "line" and "frame" or "side") end,
                set = function(_, value) Set(Get("mode") == "line" and "frame" or "side", value) end,
                disabled = Off,
            },
        },
    }
end
