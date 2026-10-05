local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local L = Glimpse.L

-- { Anzeigename (Locale-Key), TOC-Feld }
-- "GitHub" ist ein Eigenname und wird nicht übersetzt.
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
            -- L[f[1]] fällt bei "GitHub" auf den Key zurück, das passt so
            self:Printf("  |cffffd100%s:|r %s", L[f[1]], value)
        end
    end

    -- Hilft bei Support-Anfragen: welcher Client, welches Interface
    local version, build, _, toc = GetBuildInfo()
    self:Printf("  |cffffd100%s:|r %s (%s) / Interface %s", L["Game version"], version, build, toc)
end)
