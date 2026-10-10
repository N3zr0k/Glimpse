local _, P = ...
local Reader, Writer = P.Reader, P.Writer

local MAX_NAME = 120

-- Namen zu IDs (NPCs, Objekte ...), je Client-Sprache: labels[Sprache][Art][ID] = Name.
-- Namen sind Weltwissen, hängen an keinem Charakter und gehen mit dem Export raus.

local function Locale(locale)
    return locale or (GetLocale and GetLocale()) or "enUS"
end

--- Namen merken. Leere oder zu lange Namen werden verworfen; false, wenn nichts zu ändern war.
function Writer:SetLabel(kind, id, name, locale)
    if type(kind) ~= "string" or id == nil or type(name) ~= "string" or name == "" or #name > MAX_NAME then
        return false
    end

    local names = P.Path(P.Data(self, true), "labels", Locale(locale), kind)
    if names[id] == name then return false end
    names[id] = name
    return true
end

--- Name in der Sprache des Clients (oder locale). Fehlt er, zählt ein Name aus einer anderen Sprache;
-- die zweite Rückgabe ist dann deren Sprache.
function Reader:GetLabel(kind, id, locale)
    local labels = P.Peek(P.Data(self), "labels")
    if not labels then return nil end

    locale = Locale(locale)
    local name = P.Peek(labels, locale, kind, id)
    if name then return name, locale end
    for other, kinds in pairs(labels) do
        name = other ~= locale and kinds[kind] and kinds[kind][id]
        if name then return name, other end
    end
end
