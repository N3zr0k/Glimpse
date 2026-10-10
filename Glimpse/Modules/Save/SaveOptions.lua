local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Save = Glimpse:GetModule("Save")
local L = Glimpse.L

-- Block "Sichern" im Tab "Daten" (Core/Data.lua hängt ihn ein)

local function Get(name) return Save.settings.profile[name] end
local function Set(name, value) Save.settings.profile[name] = value end

function Glimpse:BuildSaveOptions(order)
    return {
        type = "group", order = order, inline = true, name = L["Saving"],
        hidden = function() return _G.GlimpseDB == nil end,
        args = {
            note = {
                type = "description", order = 1, fontSize = "small",
                name = "|cff999999" .. L["The game writes the collected data to disk only on logout or reload. After a crash everything since then is lost."] .. "|r",
            },
            status = {
                type = "description", order = 2, fontSize = "medium",
                name = function()
                    return format("|cffffd100%s:|r %d\n|cffffd100%s:|r %d %s", L["Unsaved changes"], Save.pending,
                        L["Time since last save or question"], math.floor(Save:SecondsSinceMark() / 60), L["min"])
                end,
            },
            ask = {
                type = "toggle", order = 3, width = "full", name = L["Ask when entering a rest area"],
                desc = L["Asks in an inn or a city whether to reload now, once one of the limits below is reached."],
                get = function() return Get("ask") end,
                set = function(_, value) Set("ask", value) end,
            },
            changes = {
                type = "range", order = 4, width = "full", name = L["Ask from this many changes"],
                desc = L["Every counted value is one change, e.g. a kill, a loot or a travel interval."],
                min = 10, max = 1000, step = 10,
                get = function() return Get("changes") end,
                set = function(_, value) Set("changes", value) end,
                disabled = function() return not Get("ask") end,
            },
            minutes = {
                type = "range", order = 5, width = "full", name = L["Or after this many minutes (0 = off)"],
                desc = L["Counts from the start or the last question, and needs at least one change."],
                min = 0, max = 120, step = 5,
                get = function() return Get("minutes") end,
                set = function(_, value) Set("minutes", value) end,
                disabled = function() return not Get("ask") end,
            },
            now = {
                type = "execute", order = 6, name = L["Save now (reload)"],
                confirm = true, confirmText = L["Reload the interface now to save the data?"],
                func = function() Save:ReloadNow() end,
            },
        },
    }
end
