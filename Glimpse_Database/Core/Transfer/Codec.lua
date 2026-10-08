local _, P = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

-- Textform eines Exports: Kopfzeile mit Formatversion, dann LibSerialize -> LibDeflate -> EncodeForPrint.
-- Nur in einer Coroutine aufrufen (P.RunAsync).
local FORMAT = 1
local HEADER = "!GlimpseDB:" .. FORMAT .. "!"
P.FORMAT = FORMAT

function P.Encode(payload)
    local serialized = P.Drive(LibSerialize:SerializeAsync(payload))
    P.Yield()
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    P.Yield()
    return HEADER .. LibDeflate:EncodeForPrint(compressed)
end

--- Format eines Textes: Formatversion bei eigenem Export, sonst nil
function P.Detect(text)
    local version = text:match("^!GlimpseDB:(%d+)!")
    return tonumber(version)
end

--- payload oder nil, Fehlertext
function P.Decode(text)
    local version = P.Detect(text)
    if version ~= FORMAT then return nil, "UNKNOWN_FORMAT" end

    local compressed = LibDeflate:DecodeForPrint(text:sub(#HEADER + 1))
    if not compressed then return nil, "BROKEN" end
    P.Yield()
    local serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then return nil, "BROKEN" end
    P.Yield()

    local ok, payload = P.Drive(LibSerialize:DeserializeAsync(serialized))
    if not ok or type(payload) ~= "table" then return nil, "BROKEN" end
    return payload
end
