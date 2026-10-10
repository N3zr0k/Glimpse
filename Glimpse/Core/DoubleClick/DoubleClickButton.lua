local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local DC = Glimpse:GetModule("DoubleClick")

-- Erkennung über GLOBAL_MOUSE_DOWN. Der erste Klick bleibt beim Spiel (Kamera, Auswahl). Beim zweiten Klick innerhalb
-- WINDOW wird die Taste für diesen einen Klick per Override-Bindung auf den Secure-Button gelegt (nur so darf ein
-- Addon zaubern) und Mouselook beendet. Im PreClick sagt der Handler mit Prepare(ctx), was gewirkt wird.

local WINDOW = 0.4      -- Sekunden für den zweiten Klick
local DOUBLE_MIN = 0.03 -- schneller = Prellen
local BUTTON_NAME = "GlimpseDoubleClickButton"
local BINDING = { LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3", Button4 = "BUTTON4",
    Button5 = "BUTTON5" }

local api = DC.api
api.CreateFrame = CreateFrame
api.SetOverrideBindingClick = SetOverrideBindingClick
api.ClearOverrideBindings = ClearOverrideBindings
api.IsMouselooking = IsMouselooking
api.MouselookStop = MouselookStop
api.IsMouseButtonDown = IsMouseButtonDown
api.After = C_Timer and C_Timer.After

--- "SHIFT-BUTTON2", "BUTTON2" ...
function DC:BindingKey(modifier, button)
    local key = BINDING[button]
    if not key then return nil end
    return (modifier == "NONE" or not modifier) and key or (modifier .. "-" .. key)
end

-- Hängendes Mouselook beenden, außer eine Maustaste ist noch gedrückt (force ignoriert das)
local function StopMouselook(force)
    if force ~= true and api.IsMouseButtonDown
        and (api.IsMouseButtonDown("LeftButton") or api.IsMouseButtonDown("RightButton")) then return end
    if api.IsMouselooking and api.IsMouselooking() and api.MouselookStop then api.MouselookStop() end
end

local button
local pending -- { name, handler, ctx, armed, action, prepared } für den gebundenen Klick
local armed = 0 -- damit ein alter Timer keine neuere Bindung löscht
local lastPress = {} -- [Taste] = Zeit des ersten Klicks

local function Clear()
    if button and api.ClearOverrideBindings and not DC:InCombat() then api.ClearOverrideBindings(button) end
end

local function SetAction(action)
    button:SetAttribute("type", action and action.type or nil)
    button:SetAttribute("spell", action and action.spell or nil)
    button:SetAttribute("item", action and action.item or nil)
    button:SetAttribute("macrotext", action and action.macrotext or nil)
end

function DC:OnPreClick(mouseButton, down)
    if self:InCombat() or not pending then
        self:Log("click on the button without a pending handler or in combat")
        SetAction(nil)
        return
    end
    -- Down und Up kommen beide an (je nach CVar zaubert der Client bei einem davon): Prepare nur einmal
    if not pending.prepared then
        pending.prepared = true
        local ok, action = pcall(pending.handler.Prepare, pending.ctx)
        if not ok then
            self.debug:Error("click", "%s: %s", pending.name, tostring(action))
            action = nil
        end
        pending.action = type(action) == "table" and action or nil
        self:Log(format("%s prepared (%s, down=%s): %s", pending.name, tostring(mouseButton), tostring(down),
            pending.action and tostring(pending.action.type) or "nothing"))
    end
    SetAction(pending.action)
end

function DC:OnPostClick(down)
    if down then return end
    StopMouselook()
    if api.After then api.After(0.1, StopMouselook) end
    Clear()
    local done = pending
    pending = nil
    if done and done.handler.Done then pcall(done.handler.Done, done.ctx, done.action) end
end

function DC:EnsureButton()
    if button or not api.CreateFrame then return button end
    button = api.CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyDown", "AnyUp")
    button:SetScript("PreClick", function(_, mouseButton, down) DC:OnPreClick(mouseButton, down) end)
    button:SetScript("PostClick", function(_, _, down) DC:OnPostClick(down) end)
    return button
end

function DC:OnMouseDown(_, mouseButton)
    if not BINDING[mouseButton] then return end
    local modifier = self:HeldModifier()
    if not modifier or not self:HasKey(modifier, mouseButton) then return end

    local key = self:BindingKey(modifier, mouseButton)
    local now = api.GetTime and api.GetTime() or 0
    local gap = lastPress[key] and (now - lastPress[key])
    if not gap or gap <= DOUBLE_MIN or gap >= WINDOW then
        lastPress[key] = now
        return
    end
    lastPress[key] = nil

    if self:InCombat() then self:Log("double click " .. key .. " ignored: in combat") return end
    local ctx = self:Situation(modifier, mouseButton)
    local name, handler = self:Choose(modifier, mouseButton, ctx)
    if not name then self:Log("double click " .. key .. " ignored: " .. handler) return end

    local frame = self:EnsureButton()
    if not frame then return end
    armed = armed + 1
    pending = { name = name, handler = handler, ctx = ctx, armed = armed }
    api.SetOverrideBindingClick(frame, true, key, BUTTON_NAME)
    self:Log(format("double click %s: %s", key, name))
    -- Up gehört jetzt dem Button, Mouselook muss hier enden
    StopMouselook(true)

    local mine = armed
    if api.After then
        api.After(WINDOW, function()
            if armed == mine and pending and pending.armed == mine and not pending.prepared then
                pending = nil
                Clear()
            end
        end)
    end
end

-- Im Kampf nicht löschbare Bindung nachholen
function DC:OnCombatEnd()
    pending = nil
    Clear()
end

function DC:OnEnable()
    self:RegisterEvent("GLOBAL_MOUSE_DOWN", "OnMouseDown")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnd")
end

-- für Tests
function DC:Pending() return pending end
