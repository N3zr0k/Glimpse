local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Doppelklick-Verteiler: Erweiterungen melden Handler an, der Core erkennt den Doppelklick, bestimmt die Lage und
-- lässt den passenden Handler über einen gemeinsamen Secure-Button wirken.
--   DoubleClick.lua           Anmeldung, Einstellungen, Auswahl des Handlers
--   DoubleClickSituation.lua  Lage beim Klick (ctx)
--   DoubleClickButton.lua     Erkennung, Secure-Button, Override-Bindung
--   DoubleClickOptions.lua    Block "Doppelklick" im Tab "Allgemein"
--   DoubleClickDebug.lua      Log und Probe
--
--   Glimpse:RegisterDoubleClick("fishing", {
--       modifier = "SHIFT",                -- oder function() return ... end; SHIFT, CTRL, ALT, NONE
--       button   = "RightButton",          -- oder function; Standard RightButton
--       priority = 10,                     -- höher gewinnt, Standard 0; in den Optionen überschreibbar
--       when     = { standing = true, mounted = false },  -- Felder aus ctx, die genau so sein müssen
--       Match    = function(ctx) return true end,         -- optional
--       Prepare  = function(ctx) return { type = "spell", spell = name } end,  -- nil = nichts wirken
--       Done     = function(ctx, action) end,             -- optional
--   })
-- Im Kampf sperrt der Client Bindungen und Secure-Attribute für alle Addons, dann passiert nichts.
local DC = Glimpse:NewModule("DoubleClick")

DC.handlers = {} -- Name -> Handler

DC.MODIFIERS = { "SHIFT", "CTRL", "ALT", "NONE" }
DC.BUTTONS = { "RightButton", "LeftButton", "MiddleButton", "Button4", "Button5" }

DC.defaults = {
    central = false,        -- Taste zentral für alle Handler
    modifier = "SHIFT",
    button = "RightButton",
    priority = {},          -- [Name] = Zahl, überschreibt die Vorgabe des Addons
    off = {},               -- [Name] = true, Handler abgeschaltet
}

function DC:OnInitialize()
    self.settings = Glimpse.db:RegisterNamespace("DoubleClick", { profile = self.defaults })
end

function DC:Option(name)
    local value = self.settings and self.settings.profile[name]
    if value == nil then value = self.defaults[name] end
    return value
end

local function Value(field, default)
    if type(field) == "function" then field = field() end
    return field or default
end

--- Eigene Taste eines Handlers (ohne zentrale Einstellung): modifier, button
function DC:OwnKeyOf(name)
    local handler = self.handlers[name]
    if not handler then return nil end
    return Value(handler.modifier, "NONE"), Value(handler.button, "RightButton")
end

--- Wirksame Taste eines Handlers: modifier, button
function DC:KeyOf(name)
    if self:Option("central") then return self:Option("modifier"), self:Option("button") end
    return self:OwnKeyOf(name)
end

function DC:PriorityOf(name)
    local own = self:Option("priority")[name]
    if own then return own end
    local handler = self.handlers[name]
    return handler and handler.priority or 0
end

function DC:IsOff(name)
    return self:Option("off")[name] == true
end

--- Namen nach Priorität, bei Gleichstand nach Name
function DC:Sorted()
    local names = {}
    for name in pairs(self.handlers) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        local pa, pb = self:PriorityOf(a), self:PriorityOf(b)
        if pa ~= pb then return pa > pb end
        return a < b
    end)
    return names
end

--- Gibt es einen eingeschalteten Handler auf dieser Taste?
function DC:HasKey(modifier, button)
    for name in pairs(self.handlers) do
        local mod, btn = self:KeyOf(name)
        if mod == modifier and btn == button and not self:IsOff(name) then return true end
    end
    return false
end

local function Fits(when, ctx)
    for field, wanted in pairs(when or {}) do
        if ctx[field] ~= wanted then return false end
    end
    return true
end

--- Handler für Taste und Lage: name, handler oder nil und Grund fürs Log
function DC:Choose(modifier, button, ctx)
    local reason = "no handler on this key"
    for _, name in ipairs(self:Sorted()) do
        local handler = self.handlers[name]
        local mod, btn = self:KeyOf(name)
        if mod == modifier and btn == button then
            if self:IsOff(name) then
                reason = name .. " is switched off"
            elseif not Fits(handler.when, ctx) then
                reason = name .. ": conditions not met"
            else
                local ok, match = true, true
                if handler.Match then ok, match = pcall(handler.Match, ctx) end
                if ok and match then return name, handler end
                reason = name .. (ok and ": Match false" or ": Match error " .. tostring(match))
            end
        end
    end
    return nil, reason
end

function Glimpse:RegisterDoubleClick(name, handler)
    if type(name) ~= "string" or type(handler) ~= "table" or type(handler.Prepare) ~= "function" then
        error("RegisterDoubleClick(name, { Prepare = function }) expected", 2)
    end
    DC.handlers[name] = handler
    if DC.OnHandlersChanged then DC:OnHandlersChanged() end
end

function Glimpse:UnregisterDoubleClick(name)
    DC.handlers[name] = nil
    if DC.OnHandlersChanged then DC:OnHandlersChanged() end
end

--- true, wenn die Taste zentral eingestellt ist; Erweiterungen grauen dann ihre eigene Einstellung aus
function Glimpse:IsDoubleClickCentral()
    return DC:Option("central") == true
end

--- Wirksame Taste eines angemeldeten Handlers: modifier, button
function Glimpse:GetDoubleClickKey(name)
    return DC:KeyOf(name)
end
