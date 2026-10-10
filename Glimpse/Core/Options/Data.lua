local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Tab "Daten": Bereiche von Glimpse: Database mit Größe, Export, Import und Zurücksetzen. Ohne Database nur ein
-- Hinweis.

-- Fehlercodes aus Database -> Locale-Key
local ERRORS = {
    UNKNOWN_FORMAT = "This is not a Glimpse export.",
    BROKEN = "The text is incomplete or damaged.",
    SAME_INSTALL = "This export comes from this computer and is already included.",
    NO_CHARACTER = "Not possible before the character is loaded.",
}

local function Database()
    return _G.GlimpseDB
end

local function AreaLines()
    local DB = Database()
    local lines = {}
    for _, area in ipairs(DB.AREAS) do
        local size = DB:GetAreaSize(area)
        local state = size and format(L["%d values"], size) or ("|cff888888" .. L["not loaded"] .. "|r")
        lines[#lines + 1] = format("|cffffd100%s:|r %s", area, state)
    end
    return table.concat(lines, "\n")
end

function Glimpse:ExportData()
    local DB = Database()
    self:Print(L["Export is being prepared ..."])
    DB:Export(nil, function(text, err)
        if not text then
            self:Print(L[ERRORS[err] or "Export failed: %s"]:format(tostring(err)))
            return
        end
        self:ShowTextWindow(L["Glimpse export (copy with Ctrl+C)"], text)
    end)
end

function Glimpse:ImportData()
    local DB = Database()
    self:ShowTextWindow(L["Glimpse import (paste with Ctrl+V, then Accept)"], "", function(text)
        DB:Import(text, function(result, err)
            if not result then
                self:Print(L[ERRORS[err] or "Import failed: %s"]:format(tostring(err)))
                return
            end
            self:Print(format(L["Import done: %d areas of world knowledge, %d characters, %d waiting for login."],
                result.namespaces, result.characters, result.pending))
            for name, reason in pairs(result.skipped) do
                self:Print(format(L["Skipped: %s (%s)"], name, tostring(reason)))
            end
        end)
    end)
end

function Glimpse:BuildDataOptions(order)
    local selected = "Misc"

    return {
        type = "group", order = order, name = L["Data"],
        args = {
            missing = {
                type = "description", order = 1, fontSize = "medium",
                name = L["Glimpse: Database is not installed. Without it, Glimpse records no combat or travel data."],
                hidden = function() return Database() ~= nil end,
            },
            -- ohne Database gibt es nichts zu sichern
            save = Glimpse.BuildSaveOptions and Glimpse:BuildSaveOptions(5) or nil,
            areasHeader = {
                type = "header", order = 10, name = L["Data areas"],
                hidden = function() return Database() == nil end,
            },
            areas = {
                type = "description", order = 11, fontSize = "medium",
                name = function() return Database() and AreaLines() or "" end,
                hidden = function() return Database() == nil end,
            },
            transferHeader = {
                type = "header", order = 20, name = L["Export and import"],
                hidden = function() return Database() == nil end,
            },
            transferNote = {
                type = "description", order = 21, fontSize = "small",
                name = "|cff999999" .. L["World knowledge (places, loot) can be shared with anyone. Your own numbers only go to the same character, also on another computer."] .. "|r",
                hidden = function() return Database() == nil end,
            },
            export = {
                type = "execute", order = 22, name = L["Export"],
                func = function() self:ExportData() end,
                hidden = function() return Database() == nil end,
            },
            import = {
                type = "execute", order = 23, name = L["Import"],
                func = function() self:ImportData() end,
                hidden = function() return Database() == nil end,
            },
            resetHeader = {
                type = "header", order = 30, name = L["Reset"],
                hidden = function() return Database() == nil end,
            },
            resetArea = {
                type = "select", order = 31, name = L["Data area"],
                values = function()
                    local values = {}
                    for _, area in ipairs(Database().AREAS) do values[area] = area end
                    return values
                end,
                get = function() return selected end,
                set = function(_, value) selected = value end,
                hidden = function() return Database() == nil end,
            },
            reset = {
                type = "execute", order = 32, name = L["Reset area"],
                confirm = true,
                confirmText = L["Delete all data of this area for all characters? This cannot be undone."],
                func = function()
                    Database():ResetArea(selected)
                    self:Print(format(L["Data area %s reset."], selected))
                end,
                hidden = function() return Database() == nil end,
            },
        },
    }
end

