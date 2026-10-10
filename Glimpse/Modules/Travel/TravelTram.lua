local Glimpse = LibStub("AceAddon-3.0"):GetAddon((...))
local Travel = Glimpse:GetModule("Travel")

-- Fahrten mit der Tiefenbahn. Erkannt wird nur innerhalb der Instanz: Art 8 (Tiefenbahn) gilt, wenn der Charakter
-- selbst steht (eigene Geschwindigkeit 0) und mindestens FAST_SECONDS lang schneller bewegt wird, als er laufen kann
-- (WALK_MAX). Die laufende Fahrt ist der Zustand "fährt": Sie startet nicht neu und endet erst an der Haltestelle,
-- beim Verlassen der Instanz oder beim Ladebildschirm. Laufen im Wagen ist kein Aussteigen; Haltestelle heißt, die
-- Bahn war STOP_SECONDS lang nicht mehr schneller als Laufen. Hin und zurück ohne Aussteigen sind also zwei Fahrten. Kurze Abschnitte unter MIN_YARDS zählen nicht.
--
-- Start und Ziel: Sobald der Charakter Sturmwind oder Eisenschmiede betritt (Zonenereignis, kein ständiges Prüfen), merkt sich `city` die Stadt. Betritt er
-- die Instanz, wandert sie nach `origin` (woher er startet). Das Ziel ist die andere Stadt; nach einer Fahrt ist das
-- Ziel die neue Startstadt. Ohne bekannte Startstadt (z. B. in der Bahn eingeloggt) zählt die Fahrt mit Ziel 0.

local api = Travel.api
local MODES = Travel.MODES

Travel.TRAM_SECONDS = 58 -- feste Fahrzeit ab Start; die Bahn braucht immer gleich lang, gemessen wird sie nicht
local STOP_SECONDS = 3
local MIN_YARDS = 100
local FAST_SECONDS = 2   -- so lange muss die Bahn schneller sein als Laufen
local WALK_MAX = 10      -- Yards pro Sekunde; schneller läuft kein Charakter
local PROFILE_FAST = 15  -- ab dieser Geschwindigkeit endet im Debug das Anfahren

-- Ziel-IDs und die Stadtkarten (uiMapID) der Eingänge
Travel.TRAM_STORMWIND, Travel.TRAM_IRONFORGE = 1, 2
local CITY_STATION = { [1453] = 1, [1455] = 2 } -- Sturmwind, Eisenschmiede

local STATION_NAMES = { "Stormwind", "Ironforge" }

-- "Stormwind (1)" für das Debug-Log, "unknown (0)" ohne Station
local function Describe(station)
    return format("%s (%d)", station and STATION_NAMES[station] or "unknown", station or 0)
end

local ride   -- laufende Fahrt (der Spieler "fährt"): { startAt, lastFast, yards, to }
local city   -- zuletzt besuchte Stadt (1, 2 oder nil), bis die Instanz betreten wird
local origin -- Startstadt dieser Instanz (1, 2 oder nil)
local inside = false
local cityChecked = false -- einmalige Prüfung bei der ersten Messung (Login in der Stadt)
local lastZone

--- Bei Zonenwechsel aufrufen: Sturmwind oder Eisenschmiede merken
function Travel:CheckCity()
    local zone = Glimpse.IDs and Glimpse.IDs:ZoneKey()
    if zone ~= lastZone then
        lastZone = zone
        self.debug:Log("distance", "tram zone check: map %s", tostring(zone))
    end
    local station = CITY_STATION[zone]
    if station and station ~= city then
        city = station
        self.debug:Log("distance", "tram city cached: %s, map %s", Describe(city), tostring(zone))
    end
end

--- Pro Messung mit der aktuellen Instanz aufrufen: beim Betreten der Tiefenbahn wird die Stadt zur Startstadt
function Travel:TramZone(instance)
    if not cityChecked then
        cityChecked = true
        self:CheckCity()
    end
    if instance ~= Travel.TRAM_INSTANCE then
        inside = false
    elseif not inside then
        inside = true
        origin, city = city, nil
        self.debug:Log("distance", "tram instance %d entered, origin = %s", instance, Describe(origin))
    end
end

--- Startstadt der Tiefenbahn (1 Sturmwind, 2 Eisenschmiede) oder nil (nur lesen)
function Travel:GetTramStation()
    return origin
end

--- Ist die Bewegung seit dem letzten Schritt Tiefenbahn? cur/previous sind Messungen; setzt cur.fastSince
function Travel:IsTramMotion(previous, cur, yards)
    if cur.instance ~= Travel.TRAM_INSTANCE then return false end
    local seconds = math.max(cur.at - previous.at, 0.01)
    -- Läuft die Fahrt, bleibt es Tiefenbahn, solange die Bahn schnell war; Laufen im Wagen ändert daran nichts
    if ride then return yards / seconds > WALK_MAX or cur.at - ride.lastFast < STOP_SECONDS end
    if not (previous.standing and cur.standing) then
        cur.fastSince = nil
        return false
    end
    if yards / seconds <= WALK_MAX then
        cur.fastSince = nil
        return false
    end
    cur.fastSince = previous.fastSince or previous.at
    return cur.at - cur.fastSince >= FAST_SECONDS
end

--- Laufende Fahrt oder nil (nur lesen)
function Travel:GetTramRide()
    return ride
end

--- Fahrt abschließen; gibt die fertige Fahrt zurück oder nil, wenn sie zu kurz war
function Travel:EndTramRide()
    local done = ride
    ride = nil
    if not done then return nil end
    self:SendMessage("GLIMPSE_TRAVEL_RIDE_END", "tram", done.to or 0)
    if done.yards < MIN_YARDS then return nil end

    self.debug:Log("distance", "tram ride to %s, %.0f yd", Describe(done.to), done.yards)
    self:Count("tram", done.to or 0)
    self:Count("traveltime", MODES.tram, Travel.TRAM_SECONDS) -- fest eingetragen, nicht gemessen
    origin = done.to
    return done
end

--- Nach jeder Messung: mode und yards der Messung, position = { x, y, at } oder nil
function Travel:TramTick(mode, yards, position)
    local now = position and position.at or api.GetTime()
    if mode == MODES.tram and yards > 0 then
        if not ride then
            local to = origin and (3 - origin) -- die andere Haltestelle
            ride = { startAt = now, lastFast = now, yards = 0, to = to }
            self.debug:Log("distance", "tram ride starts, from %s to %s", Describe(origin), Describe(to))
            self:SendMessage("GLIMPSE_TRAVEL_RIDE_START", "tram", to or 0, now, Travel.TRAM_SECONDS)
        end
        ride.yards = ride.yards + yards
        if (position.speed or 0) > WALK_MAX then ride.lastFast = now end
        return
    end
    if not ride then return end
    -- Die Fahrt endet erst an der Haltestelle (die Bahn war STOP_SECONDS nicht mehr schneller als Laufen) oder wenn
    -- die Instanz verlassen wird. Laufen im Wagen beendet sie nicht.
    if (position and position.instance ~= Travel.TRAM_INSTANCE) or now - ride.lastFast >= STOP_SECONDS then
        self:EndTramRide()
    end
end

-- Debug: Geschwindigkeitsprofil der Bahn, jede Sekunde beim Anfahren (bis PROFILE_FAST), dann das Maximum, beim Bremsen
-- wieder jede Sekunde bis zum Stillstand. Gibt ein genaues Muster, um die Bahn von Laufen zu unterscheiden.
local profile -- { phase, startAt, lastLog, max }
local profiling = false -- per Befehl einschalten: /gli probe travel tram profile

local function ProfileLine(self, text, speed, now)
    self.debug:Log("distance", "tram profile %s, %.0f s: %.1f yd/s", text, now - profile.startAt, speed)
    profile.lastLog = now
end

--- Nach jeder Messung: cur = Messung mit cur.speed (Yards pro Sekunde, 0 ohne Bewegung)
function Travel:TramProfile(cur)
    if not profiling or cur.instance ~= Travel.TRAM_INSTANCE or not cur.standing then
        profile = nil
        return
    end
    local speed, now = cur.speed or 0, cur.at
    if not profile then
        if speed <= 0 then return end
        profile = { phase = "accel", startAt = now, lastLog = -math.huge, max = 0 }
    end
    profile.max = math.max(profile.max, speed)

    if profile.phase == "accel" then
        if speed <= 0 then
            profile = nil              -- kein Anfahren, nur ein Ruckeln im Stand
        elseif speed >= PROFILE_FAST then
            ProfileLine(self, "reached", speed, now)
            profile.phase = "cruise"
        elseif now - profile.lastLog >= 1 then
            ProfileLine(self, "accelerating", speed, now)
        end
    elseif profile.phase == "cruise" then
        if speed < profile.max - 1 then
            ProfileLine(self, "max " .. format("%.1f", profile.max) .. ", slowing", speed, now)
            profile.phase = "brake"
        end
    elseif speed <= 0 then
        ProfileLine(self, "stopped", speed, now)
        profile = nil
    elseif now - profile.lastLog >= 1 then
        ProfileLine(self, "slowing", speed, now)
    end
end

--- Zustand für /gli probe travel tram: Zeilen zum Anzeigen; "profile" schaltet das Geschwindigkeitsprofil um
function Travel:TramProbe(args)
    if strlower(args or ""):find("profile", 1, true) then
        profiling, profile = not profiling, nil
        return { "tram profile " .. (profiling and "on" or "off") .. " (output in debug category distance)" }
    end
    return {
        format("city cache: %s", Describe(city)),
        format("origin: %s", Describe(origin)),
        format("inside tram instance: %s", tostring(inside)),
        format("ride: %s", ride and format("to %s, %.0f yd", Describe(ride.to), ride.yards) or "none"),
        format("profile: %s", profiling and "on" or "off"),
    }
end
