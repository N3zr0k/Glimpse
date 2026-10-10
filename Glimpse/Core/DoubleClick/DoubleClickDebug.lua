local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local DC = Glimpse:GetModule("DoubleClick")
local L = Glimpse.L

-- Log der letzten Doppelklicks (nur im Speicher) und /gli probe click handlers

DC.debug = Glimpse:NewDebugger("DoubleClick", { "click" })

local LOG_MAX = 25
DC.log = {}

function DC:Log(text)
    local log = self.log
    log[#log + 1] = format("%.1f %s", self.api.GetTime and self.api.GetTime() or 0, text)
    if #log > LOG_MAX then table.remove(log, 1) end
    self.debug:Log("click", "%s", text)
end

function DC:HandlerLines()
    local lines = {}
    if self:Option("central") then
        lines[#lines + 1] = format(L["Central key: %s"], self:BindingKey(self:Option("modifier"), self:Option("button")))
    end
    for _, name in ipairs(self:Sorted()) do
        local mod, btn = self:KeyOf(name)
        lines[#lines + 1] = format("%s: %s, %s %d%s", name, tostring(self:BindingKey(mod, btn)), L["priority"],
            self:PriorityOf(name), self:IsOff(name) and (", " .. L["off"]) or "")
    end
    if #lines == 0 then lines[1] = L["No addon has registered a double click."] end
    if #self.log == 0 then
        lines[#lines + 1] = L["No double click seen yet."]
    else
        for _, line in ipairs(self.log) do lines[#lines + 1] = line end
    end
    return lines
end

Glimpse:RegisterProbe("click", "handlers", function() return DC:HandlerLines() end,
    L["Shows the double click handlers and the last double clicks"])
