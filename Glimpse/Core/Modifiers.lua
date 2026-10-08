local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Tooltip-Ergänzungen nur bei gehaltener Shift/Strg/Alt-Taste.
-- Einstellungen (z. B. Profil der Erweiterung) mit modShift, modCtrl, modAlt.
-- Benutzung:
--   defaults:   modShift = false, modCtrl = false, modAlt = false
--   Optionen:   args.modifiers = Glimpse:BuildModifierOptions(self.db.profile, onChange, order)
--   Tooltip:    if not Glimpse:ModifiersHeld(self.db.profile) then return nil end
--   Event:      MODIFIER_STATE_CHANGED -> bei Glimpse:ModifiersRequired(profile) den Tooltip neu aufbauen

-- { Feld, Anzeigename, Abfrage }
local KEYS = {
    { "modShift", "Shift", function() return IsShiftKeyDown() end },
    { "modCtrl", "Ctrl", function() return IsControlKeyDown() end },
    { "modAlt", "Alt", function() return IsAltKeyDown() end },
}

function Glimpse:ModifiersRequired(settings)
    for _, key in ipairs(KEYS) do
        if settings[key[1]] then return true end
    end
    return false
end

--- Ohne gewählte Taste immer true
function Glimpse:ModifiersHeld(settings)
    for _, key in ipairs(KEYS) do
        if settings[key[1]] and not key[3]() then return false end
    end
    return true
end

--- AceConfig-Gruppe für die Optionsseite einer Erweiterung. onChange nach jeder Änderung.
function Glimpse:BuildModifierOptions(settings, onChange, order)
    local args = {
        help = {
            type = "description", order = 0, fontSize = "medium",
            name = L["Show the tooltip additions only while the selected keys are held. If several are selected, all of them must be held. If none is selected, they are always shown."],
        },
    }

    for index, key in ipairs(KEYS) do
        local field = key[1]
        args[field] = {
            type = "toggle", order = index,
            name = L[key[2]],
            get = function() return settings[field] end,
            set = function(_, value)
                settings[field] = value and true or false
                if onChange then onChange() end
            end,
        }
    end

    return { type = "group", inline = true, order = order or 100, name = L["Only while a key is held"], args = args }
end
