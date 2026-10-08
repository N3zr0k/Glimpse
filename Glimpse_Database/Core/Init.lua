local ADDON_NAME, P = ...

-- Unterste Schicht der Glimpse-Addons: speichert, migriert, exportiert und meldet Änderungen. Keine Oberfläche,
-- kein Ace3. Öffentliche API über das Global GlimpseDB, Übersicht in DEVELOPER.md.
-- P ist die private Tabelle des Addons (zweites Argument jeder Datei) für alles, was nicht API ist.
local DB = {}
_G.GlimpseDB = DB -- luacheck: ignore 122

DB.name = ADDON_NAME
DB.API_VERSION = 1
DB.EVENT_CHANGED = "Glimpse_DB_Changed"

-- DB.RegisterCallback(owner, DB.EVENT_CHANGED, method) -> method(event, nsName, kind, id)
DB.callbacks = LibStub("CallbackHandler-1.0"):New(DB)

function P.Fire(nsName, kind, id)
    DB.callbacks:Fire(DB.EVENT_CHANGED, nsName, kind, id)
end

--- Verschachtelte Tabelle holen, fehlende Ebenen werden angelegt: P.Path(t, "a", 1) -> t.a[1]
function P.Path(t, ...)
    for i = 1, select("#", ...) do
        local key = select(i, ...)
        local child = t[key]
        if child == nil then
            child = {}
            t[key] = child
        end
        t = child
    end
    return t
end

--- Wie P.Path, legt aber nichts an. nil, sobald eine Ebene fehlt.
function P.Peek(t, ...)
    for i = 1, select("#", ...) do
        if type(t) ~= "table" then return nil end
        t = t[select(i, ...)]
    end
    return t
end

-- Meta und Bereich Core kommen beim ADDON_LOADED (Events.lua); davor gibt es keine Daten
function P.RequireLoaded()
    if not P.meta then error("Glimpse_Database is not loaded yet", 3) end
end
