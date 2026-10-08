local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Fenster mit dem Debug-Log zum Kopieren (/gli debug log). Ein Fenster, das bei jedem Öffnen neu befüllt wird.

local window

function Glimpse:ShowTextWindow(title, text, onAccept)
    local AceGUI = LibStub("AceGUI-3.0")
    if window then window:Release() end

    window = AceGUI:Create("Frame")
    window:SetTitle(title)
    window:SetLayout("Fill")
    window:SetWidth(700)
    window:SetHeight(450)
    window:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        window = nil
    end)

    local box = AceGUI:Create("MultiLineEditBox")
    box:SetLabel("")
    box:SetText(text or "")
    box:DisableButton(onAccept == nil)
    if onAccept then
        box:SetCallback("OnEnterPressed", function(_, _, value) onAccept(value) end)
    end
    window:AddChild(box)

    -- Fokus erst einen Frame später, sonst landet er nicht im Feld
    C_Timer.After(0, function()
        if not window then return end
        box:SetFocus()
        if text and text ~= "" then box:HighlightText() end
    end)
    return box
end

function Glimpse:ShowDebugLog()
    local lines = self:GetLogLines()
    local text = #lines > 0 and table.concat(lines, "\n") or L["The debug log is empty."]
    self:ShowTextWindow(L["Glimpse debug log"], text)
end
