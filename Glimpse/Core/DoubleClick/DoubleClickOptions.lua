local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local DC = Glimpse:GetModule("DoubleClick")
local L = Glimpse.L

-- Block "Doppelklick" im Tab "Allgemein": Taste zentral für alle, je Handler an/aus und Priorität. Die Handler-Liste wird neu gebaut,
-- sobald sich ein Handler an- oder abmeldet.

local MODIFIER_NAMES = {
    SHIFT = SHIFT_KEY_TEXT or "Shift", CTRL = CTRL_KEY_TEXT or "Ctrl", ALT = ALT_KEY_TEXT or "Alt",
}
local BUTTON_NAMES = {
    RightButton = "Double click right", LeftButton = "Double click left", MiddleButton = "Double click middle",
    Button4 = "Double click mouse button 4", Button5 = "Double click mouse button 5",
}

local function ModifierName(modifier)
    return MODIFIER_NAMES[modifier] or L["No key"]
end

local function KeyText(modifier, button)
    local click = L[BUTTON_NAMES[button] or BUTTON_NAMES.RightButton]
    if not modifier or modifier == "NONE" then return click end
    return format("%s + %s", ModifierName(modifier), click)
end

-- Mouseover im Block: eigene Taste des Addons, bei zentraler Taste mit Hinweis
local function HandlerTooltip(name)
    local own = format(L["Own key: %s"], KeyText(DC:OwnKeyOf(name)))
    if not DC:Option("central") then return own end
    return own .. "\n" .. format(L["Currently the central key applies: %s"], KeyText(DC:KeyOf(name)))
end

--- "Umschalt + Doppelklick rechts" für die Taste eines Handlers (zentral oder eigene)
function Glimpse:GetDoubleClickText(name)
    return KeyText(DC:KeyOf(name))
end

local function Get(name) return DC:Option(name) end
local function Set(name, value) DC.settings.profile[name] = value end

local function Values(list, names)
    local values = {}
    for _, key in ipairs(list) do values[key] = names(key) end
    return values
end

--- Zusatztaste und Maustaste als zwei Auswahlfelder, gleich in allen Addons. Trägt sie in args ein:
--   Glimpse:AddDoubleClickKeyOptions(args, self.db.profile, 22, {
--       modifier = "castKey", button = "castButton",  -- Felder in settings, Standard "modifier" und "button"
--       onChange = function() end,                    -- optional, nach jeder Änderung
--       disabled = function() return false end,       -- optional, zusätzlich ausgrauen
--       hidden   = function() return false end,       -- optional, z. B. wenn die Funktion im Addon aus ist
--   })
-- Ist die Taste zentral eingestellt, sind die Felder ausgegraut und zeigen die zentrale Taste.
-- opts.central = true nur für den Core-Block selbst: dort umgekehrt, aktiv nur bei zentraler Taste.
function Glimpse:AddDoubleClickKeyOptions(args, settings, order, opts)
    opts = opts or {}
    local fields = { modifier = opts.modifier or "modifier", button = opts.button or "button" }
    local defaults = { modifier = "SHIFT", button = "RightButton" }

    local function Locked()
        if opts.central then return not Get("central") end
        return Get("central") or (opts.disabled and opts.disabled()) or false
    end
    local function Option(kind, offset, name, list, names)
        return {
            type = "select", order = order + offset, name = name, style = "dropdown",
            values = function() return Values(list, names) end,
            sorting = list,
            get = function()
                if Get("central") and not opts.central then return Get(kind) end
                return settings[fields[kind]] or defaults[kind]
            end,
            set = function(_, value)
                settings[fields[kind]] = value
                if opts.onChange then opts.onChange() end
            end,
            disabled = Locked,
            hidden = opts.hidden,
        }
    end
    args.doubleClickModifier = Option("modifier", 0, L["Modifier key"], DC.MODIFIERS, ModifierName)
    args.doubleClickButton = Option("button", 0.1, L["Mouse button"], DC.BUTTONS,
        function(key) return L[BUTTON_NAMES[key]] end)
    return args
end

local group -- Tab-Tabelle, die Handler-Einträge werden darin ersetzt

local function HandlerArgs()
    local args = {}
    for index, name in ipairs(DC:Sorted()) do
        local handler = DC.handlers[name]
        local order = 20 + index * 2
        args["on_" .. name] = {
            type = "toggle", order = order, width = 1.4, name = handler.title or name,
            desc = function() return HandlerTooltip(name) end,
            get = function() return not DC:IsOff(name) end,
            set = function(_, value) DC.settings.profile.off[name] = (not value) or nil end,
        }
        args["prio_" .. name] = {
            type = "range", order = order + 1, width = 1.2, min = -100, max = 100, step = 1,
            name = L["Priority"],
            desc = format(L["Higher wins when several addons fit. Default of the addon: %d."], handler.priority or 0),
            get = function() return DC:PriorityOf(name) end,
            set = function(_, value)
                DC.settings.profile.priority[name] = value ~= (handler.priority or 0) and value or nil
                DC:OnHandlersChanged()
            end,
            disabled = function() return DC:IsOff(name) end,
        }
    end
    if #DC:Sorted() == 0 then
        args.none = { type = "description", order = 21, name = L["No addon has registered a double click."] }
    end
    return args
end

function Glimpse:BuildDoubleClickOptions(order)
    group = {
        type = "group", inline = true, order = order, name = L["Double click"],
        args = {
            intro = {
                type = "description", order = 1, fontSize = "medium", width = "full",
                name = L["Addons can react to a double click in the game world, e.g. casting the fishing rod. Here you set the key for all of them and which addon wins when several fit."],
            },
            central = {
                type = "toggle", order = 2, width = "full", name = L["Same key for all addons"],
                desc = L["When on, every addon uses the key set here and its own key setting is greyed out."],
                get = function() return Get("central") end,
                set = function(_, value) Set("central", value) end,
            },
            handlersHeader = { type = "header", order = 10, name = L["Addons"] },
            combatNote = {
                type = "description", order = 11, width = "full", fontSize = "small",
                name = "|cff999999" .. L["Locked in combat for all addons."] .. "|r",
            },
        },
    }
    -- Die Einstellungen gibt es erst nach DC:OnInitialize, daher über eine Weiterleitung
    local central = setmetatable({}, {
        __index = function(_, key) return Get(key) end,
        __newindex = function(_, key, value) Set(key, value) end,
    })
    Glimpse:AddDoubleClickKeyOptions(group.args, central, 3, { central = true })
    DC:OnHandlersChanged()
    return group
end

function DC:OnHandlersChanged()
    if not group then return end
    for key in pairs(group.args) do
        if key:match("^on_") or key:match("^prio_") or key == "none" then group.args[key] = nil end
    end
    for key, option in pairs(HandlerArgs()) do group.args[key] = option end
    if Glimpse.RefreshConfig and Glimpse.db then Glimpse:RefreshConfig() end
end
