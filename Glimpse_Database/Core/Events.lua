local ADDON_NAME, P = ...
local DB = GlimpseDB

-- SavedVariables sind erst beim eigenen ADDON_LOADED da, der Charakter sicher erst bei PLAYER_LOGIN.
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

local function LoadMeta()
    local meta = GlimpseDB_Meta
    if type(meta) ~= "table" then meta = {} end
    meta.characters = meta.characters or {}
    meta.index = meta.index or {}
    meta.namespaces = meta.namespaces or {}
    meta.pending = meta.pending or {}
    -- Kennung dieser Installation, damit ein Export nicht auf demselben Rechner zurück importiert wird
    meta.install = meta.install or format("%08x", math.random(0, 0x7fffffff))
    GlimpseDB_Meta = meta -- luacheck: ignore 111
    P.meta = meta

    if type(GlimpseDB_Core) ~= "table" then GlimpseDB_Core = {} end -- luacheck: ignore 111
    P.areas.Core = GlimpseDB_Core
end

frame:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        -- Bis zum ersten Ausloggen nach dem Update kann die alte SavedVariables-Datei des Core das Global
        -- GlimpseDB mit dessen früherer Einstellungstabelle überschreiben
        if GlimpseDB ~= DB then GlimpseDB = DB end -- luacheck: ignore 111
        if name == ADDON_NAME then
            LoadMeta()
            P.CurrentChar()
        end
    elseif event == "PLAYER_LOGIN" then
        P.CurrentChar()
        P.ApplyPending()
        if P.RunAlphaMigration then P.RunAlphaMigration() end
    end
end)
