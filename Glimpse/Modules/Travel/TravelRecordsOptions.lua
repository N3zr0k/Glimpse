local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")
local L = Glimpse.L

-- Tab "Rekorde": Schalter je Art für die Meldung und Ausgabeort. Die Werte werden immer gespeichert.

local function Get(name) return Travel:RecordOption(name) end
local function Set(name, value)
    if Travel.recordSettings then Travel.recordSettings.profile[name] = value end
end

local function Toggle(order, key, name, desc)
    return {
        type = "toggle", order = order, width = "full", name = name, desc = desc,
        get = function() return Get(key) end,
        set = function(_, value) Set(key, value) end,
    }
end

function Glimpse:BuildRecordOptions(order)
    return {
        type = "group", order = order, name = L["Records"],
        hidden = function() return not GlimpseDB end,
        args = {
            intro = {
                type = "description", order = 1, fontSize = "medium", width = "full",
                name = L["Glimpse remembers your best values and tells you when you beat one. The values are always saved; here you choose which messages you get."],
            },
            walk = Toggle(2, "walk", L["Running speed"], L["A message when you run faster than ever before on foot."]),
            mount = Toggle(3, "mount", L["Riding speed"], L["A message when you ride faster than ever before. Your mount gets praised."]),
            fall = Toggle(4, "fall", L["Falling"], L["A message for a new deepest fall. The depth is estimated from the time you fell."]),
            jump = Toggle(5, "jump", L["Jumps"], L["A message at 100, 500, 1000, 2500, 5000, 10000, 100000 and 1000000 jumps of this character."]),
            breath = Toggle(6, "breath", L["Holding your breath"], L["A message when you stayed under water longer than ever before. It comes when you surface."]),
            swim = Toggle(7, "swim", L["Swimming"], L["A message for a new longest swim without leaving the water."]),
            dive = Toggle(8, "dive", L["Diving"], L["A message for a new longest distance dived on one breath. It comes when you surface."]),
            walkdist = Toggle(9, "walkdist", L["Walking distance"], L["A message for a new longest distance walked without a break. It comes when you stop."]),
            output = {
                type = "select", order = 10, name = L["Show messages"], style = "dropdown", width = "double",
                values = { both = L["Screen and chat"], screen = L["Screen only"], chat = L["Chat only"] },
                sorting = { "both", "screen", "chat" },
                get = function() return Get("output") end,
                set = function(_, value) Set("output", value) end,
            },
            list = {
                type = "execute", order = 11, name = L["Show records"],
                desc = L["Lists your records in the chat."],
                func = function() Travel:PrintRecords() end,
            },
        },
    }
end
