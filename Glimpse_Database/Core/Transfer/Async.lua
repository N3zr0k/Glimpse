local _, P = ...

-- Lange Arbeit (Export, Import) über mehrere Frames verteilen: func läuft in einer Coroutine und ruft P.Yield(),
-- wenn sie eine Pause machen darf. Danach geht es im nächsten Frame weiter. done(ok, ...) am Ende, ok = false mit
-- Fehlermeldung, wenn func einen Fehler wirft.

local MAX_FRAME_TIME = 0.008 -- Sekunden Arbeit pro Frame

function P.RunAsync(func, done)
    local thread = coroutine.create(func)

    local function Step()
        local started = debugprofilestop()
        repeat
            local result = { coroutine.resume(thread) }
            if not result[1] then
                done(false, result[2])
                return
            end
            if coroutine.status(thread) == "dead" then
                done(true, unpack(result, 2))
                return
            end
        until debugprofilestop() - started > MAX_FRAME_TIME * 1000
        C_Timer.After(0, Step)
    end

    C_Timer.After(0, Step)
end

function P.Yield()
    if coroutine.running() then coroutine.yield() end
end

--- Ruft einen LibSerialize-Handler bis zum Ende auf und gibt dessen Ergebnis zurück (ohne completed)
function P.Drive(handler)
    while true do
        local result = { handler() }
        if result[1] then return unpack(result, 2) end
        P.Yield()
    end
end
