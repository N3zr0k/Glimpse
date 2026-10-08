local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- { Locale-Key, TOC-Feld }. "GitHub" hat keinen Locale-Eintrag, L[] liefert den Key.
local FIELDS = {
    { "Version", "Version" },
    { "Author", "Author" },
    { "Notes", "Notes" },
    { "Website", "X-Website" },
    { "GitHub", "X-Repo" },
    { "License", "X-License" },
}

Glimpse:RegisterCommand("info", L["Shows addon information from the TOC"], function(self)
    self:Print(self:GetMeta("Title") or self.name)

    for _, f in ipairs(FIELDS) do
        local value = self:GetMeta(f[2])
        if value and value ~= "" then
            self:Printf("  |cffffd100%s:|r %s", L[f[1]], value)
        end
    end

    -- für Support-Anfragen
    local version, build, _, toc = GetBuildInfo()
    self:Printf("  |cffffd100%s:|r %s (%s) / Interface %s", L["Game version"], version, build, toc)
end)
