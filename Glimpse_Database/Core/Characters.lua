local _, P = ...
local DB = GlimpseDB

-- Charaktere stehen einmal in Meta.characters und werden überall als kleine Zahl (Index) gespeichert.
-- Schlüssel = kurzer Hash der Spieler-GUID; damit lassen sich Exporte demselben Charakter zuordnen, ohne Namen.
-- foreign = true: Charakter kennt Glimpse nur aus einem Import (z. B. Weltwissen eines anderen Spielers).
-- world = true: kein Charakter, sondern Weltwissen ohne Zuordnung (Schlüssel "world"), zählt zum Account.

-- djb2 auf 32 Bit, reicht gegen Verwechslung; kein Schutz gegen Absicht
function P.Hash(text)
    local hash = 5381
    for i = 1, #text do
        hash = (hash * 33 + text:byte(i)) % 4294967296
    end
    return format("%08x", hash)
end

--- Index zum Schlüssel, wird bei Bedarf angelegt. info (optional) ergänzt name, realm, class.
function P.CharIndex(key, info)
    local meta = P.meta
    local index = meta.index[key]
    if not index then
        index = #meta.characters + 1
        meta.characters[index] = { key = key, foreign = true }
        meta.index[key] = index
    end

    local entry = meta.characters[index]
    if info then
        entry.name = info.name or entry.name
        entry.realm = info.realm or entry.realm
        entry.class = info.class or entry.class
    end
    return index
end

--- Index des eingeloggten Charakters, nil solange die GUID noch nicht bekannt ist
function P.CurrentChar()
    if P.char then return P.char end

    local guid = UnitGUID("player")
    if not guid then return nil end

    local key = P.Hash(guid)
    local name, realm = UnitName("player"), GetRealmName()
    local _, class = UnitClass("player")
    local index = P.CharIndex(key, { name = name, realm = realm, class = class })
    P.meta.characters[index].foreign = nil
    P.char, P.charKey = index, key
    return index
end

function DB:GetCharacter()
    return P.CurrentChar()
end

--- name, realm, class, key, foreign eines Charakter-Index
function DB:GetCharacterInfo(index)
    local entry = P.meta and P.meta.characters[index]
    if not entry then return nil end
    return entry.name, entry.realm, entry.class, entry.key, entry.foreign == true
end

--- Indizes der eigenen Charaktere (ohne fremde aus Importen), aktueller zuerst
function DB:GetCharacters()
    P.RequireLoaded()
    local current = P.CurrentChar()
    local list = { current }  -- leer, solange der Charakter unbekannt ist
    for index, entry in ipairs(P.meta.characters) do
        if not entry.foreign and not entry.world and index ~= current then list[#list + 1] = index end
    end
    return list
end
