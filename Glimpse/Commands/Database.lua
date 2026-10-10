local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- /glimpse db owner <Namespace>          Besitzer anzeigen
-- /glimpse db owner <Namespace> reset    Besitzer freigeben (nach dem Umbenennen eines Addon-Ordners)
Glimpse:RegisterCommand("db", L["Database: owner <namespace> [reset] shows or releases the owner of a namespace"], function(self, args)
    local DB = _G.GlimpseDB
    if not (DB and DB.GetOwner) then
        self:Print(L["This version of Glimpse: Database has no namespace owners."])
        return
    end

    local action, name, reset = strmatch(strtrim(args or ""), "^(%S*)%s*(%S*)%s*(%S*)$")
    name = strlower(name or "")
    if action ~= "owner" or name == "" then
        self:Print(L["Usage: /gli db owner <namespace> [reset]"])
        return
    end

    if reset == "reset" then
        local ok, reason = DB:ResetOwner(name)
        if ok then
            self:Printf(L["%s: owner released, the next addon that registers it becomes the owner."], name)
        else
            self:Printf(L["%s: owner not released (%s)."], name, tostring(reason))
        end
        return
    end
    self:Printf(L["%s: owner %s"], name, DB:GetOwner(name) or L["none"])
end)
