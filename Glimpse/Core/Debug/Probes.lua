local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- Probes: kleine Prüfungen für Tester, z. B. /gli probe prof lure. Erweiterungen melden sie hier an, Hilfe und
-- Ausgabe kommen vom Core:
--   Glimpse:RegisterProbe("prof", "lure", function(args) return { "Zeile 1", "Zeile 2" } end, "Zeigt den Köder")
-- func bekommt den Rest der Eingabe und gibt eine Liste von Zeilen oder einen Text zurück.

Glimpse.probes = {}

function Glimpse:RegisterProbe(group, name, func, help)
    group, name = strlower(group), strlower(name)
    self.probes[group] = self.probes[group] or {}
    self.probes[group][name] = { func = func, help = help, addon = self:FindCallerAddon(2) }
end

local function Sorted(t)
    local keys = {}
    for key in pairs(t) do keys[#keys + 1] = key end
    table.sort(keys)
    return keys
end

function Glimpse:ListProbes()
    if not next(self.probes) then
        self:Print(L["No probes registered."])
        return
    end
    self:Print(L["Available probes:"])
    for _, group in ipairs(Sorted(self.probes)) do
        for _, name in ipairs(Sorted(self.probes[group])) do
            self:Printf("  |cffffd100/glimpse probe %s %s|r - %s", group, name, self.probes[group][name].help or "")
        end
    end
end

function Glimpse:RunProbe(group, name, args)
    group, name = strlower(group or ""), strlower(name or "")
    local probe = self.probes[group] and self.probes[group][name]
    if not probe then
        self:Print(format(L["Unknown probe: %s %s"], group, name))
        return self:ListProbes()
    end

    local ok, result = pcall(probe.func, args or "")
    if not ok then
        result = { "|cffff4040" .. tostring(result) .. "|r" }
    elseif type(result) ~= "table" then
        result = { tostring(result or "") }
    end

    local prefix = format("%s/%s:", group, name)
    for _, line in ipairs(result) do
        self:AddLogLine(self:DebugTag(probe.addon, true) .. " " .. prefix .. " " .. line)
        self:Print(self:DebugTag(probe.addon) .. " " .. prefix .. " " .. line)
    end
end
