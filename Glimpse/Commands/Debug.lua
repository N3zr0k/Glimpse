local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- /glimpse debug                     umschalten
-- /glimpse debug on|off              an, aus
-- /glimpse debug log                 Fenster mit den letzten Debug-Zeilen zum Kopieren
-- /glimpse debug list                Debugger und ihre Kategorien
-- /glimpse debug <Name> <Kat> on|off eine Kategorie schalten (Name und Kategorie wie in der Liste)

local function FindDebugger(name)
    for key, debugger in pairs(Glimpse.debuggers) do
        if strlower(key) == strlower(name) then return debugger end
    end
end

local function List(self)
    local names = {}
    for name in pairs(self.debuggers) do names[#names + 1] = name end
    table.sort(names)
    if #names == 0 then
        self:Print(L["No debug categories registered."])
        return
    end
    for _, name in ipairs(names) do
        local debugger = self.debuggers[name]
        local parts = {}
        for _, category in ipairs(debugger.categories) do
            local off = self.db.profile.debugOff[name] and self.db.profile.debugOff[name][category]
            parts[#parts + 1] = (off and "|cff888888" or "|cff40ff40") .. category .. "|r"
        end
        self:Printf("  |cffffd100%s|r: %s", name, table.concat(parts, ", "))
    end
end

Glimpse:RegisterCommand("debug", L["Toggles debug mode (on/off), log, list, <name> <category> on/off"], function(self, args)
    local first, second, third = strsplit(" ", strtrim(args or ""))
    first = strlower(first or "")

    if first == "on" then
        self:SetDebug(true)
    elseif first == "off" then
        self:SetDebug(false)
    elseif first == "log" then
        self:ShowDebugLog()
    elseif first == "list" then
        List(self)
    elseif first ~= "" then
        local debugger = FindDebugger(first)
        third = strlower(third or "")
        if not debugger or not second or (third ~= "on" and third ~= "off") then
            self:Print(L["Usage: /glimpse debug <name> <category> on|off"])
            return
        end
        debugger:SetCategory(strlower(second), third == "on")
        self:Printf("%s/%s: %s", debugger.name, strlower(second), third)
    else
        self:SetDebug(not self:IsDebug())
    end
end)
