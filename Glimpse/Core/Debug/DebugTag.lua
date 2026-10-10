local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))

-- Addon-Kennung vor jeder Debug-Ausgabe in Chat und Tooltip, z. B. [Glimpse: Professions]; nur der Name hinter
-- "Glimpse: " ist dezent blau, beim Core "Glimpse" selbst. Das Addon kommt aus dem Aufrufstapel (Ordner unter AddOns),
-- der Name aus der TOC.
--   Glimpse:DebugTag()                  Kennung des Aufrufers, farbig
--   Glimpse:DebugTag("Glimpse_Travel")  Kennung eines bestimmten Addons
--   Glimpse:DebugTag(nil, true)         ohne Farbe (Log zum Kopieren)

local TAG_COLOR = "|cff6a9fd4"

--- Addon-Ordner des Aufrufers. level wie bei error(): 1 = Funktion, die FindCallerAddon aufruft, 2 = deren Aufrufer.
-- nil ohne debugstack (Tests) oder wenn kein Addon-Pfad im Stapel steht.
function Glimpse:FindCallerAddon(level)
    if not debugstack then return nil end
    -- direkt aufrufen, ein pcall dazwischen verschiebt die Stapeltiefe
    local stack = debugstack((level or 2) + 1, 1, 0)
    return type(stack) == "string" and stack:match("AddOns[/\\]([^/\\]+)[/\\]") or nil
end

function Glimpse:DebugTag(addon, plain)
    addon = addon or self:FindCallerAddon(2) or self.name
    local title = self:GetMeta("Title", addon) or addon
    if plain then return "[" .. title .. "]" end
    local prefix, name = title:match("^(.-:%s*)(.+)$")
    if not prefix then prefix, name = "", title end
    return "[" .. prefix .. TAG_COLOR .. name .. "|r]"
end
