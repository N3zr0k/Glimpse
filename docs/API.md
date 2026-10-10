# Glimpse: gespeicherte Daten und Abruf

Alle Werte, die die Glimpse-Suite in Glimpse: Database speichert, und wie ein Addon sie liest. Neue Werte werden hier
eingetragen, sobald sie gespeichert werden (Regel in `REGELN.md`). Die vollständige Database-API steht in
`DEVELOPER.md`, Kapitel „Glimpse: Database“.

Stand: Core 0.3.39-alpha.1.

## Grundlagen

```lua
local reader = GlimpseDB and GlimpseDB:Get("travel")   -- nil ohne Database oder bei unbekanntem Namespace
if reader then
    local yards = reader:GetCount("distance", 1)        -- gelaufen, eingeloggter Charakter, insgesamt
end
```

Jeder Wert ist ein Zähler: **Namespace → Art (kind) → ID → Zahl**, getrennt je Charakter. Schreiben darf nur der
Besitzer des Namespace, lesen jeder.

| Abruf | Ergebnis |
| --- | --- |
| `reader:GetCount(kind, id, scope)` | Summe; `id = nil` summiert alle IDs der Art |
| `reader:GetCounts(kind, scope)` | `{ [id] = Summe }` |
| `reader:GetZones(kind, id, scope)` | `{ [Zone] = Summe }`, nur bei Namespaces mit Zonen |
| `reader:GetSeen(kind, id, scope)` | erster und letzter Zeitpunkt (Unix-Zeit) |
| `reader:GetSeries(kind, id, scope)` | `{ [Stunde] = n }`, scope braucht `range` oder `from`/`to` |
| `reader:GetDays(kind, id, scope, count)` | `{ [JJJJMMTT] = n }` der letzten `count` Tage, nur bei Namespaces mit Tageswerten |
| `reader:GetDayCount(kind, id, scope, count)` | Summe daraus; `count = 1` heute, `7` letzte 7 Tage |
| `reader:GetLocations(mapID, id, scope)` | Liste `{ mapID, x, y, id, source }` |
| `reader:GetMax(kind, id, scope)` | Rekord: Höchstwert, Zeit (Unix) und Zone, bester Wert der Charaktere des scope; `nil` ohne Rekord |
| `reader:GetMin(kind, id, scope)` | Rekord: Tiefstwert, Zeit und Zone, sonst wie `GetMax` |

**scope:** `"char"` (Standard, eingeloggter Charakter), `"account"` (alle eigenen Charaktere), `"all"` (dazu fremde
aus Importen) oder ein Charakter-Index aus `GlimpseDB:GetCharacters()`. Als Tabelle zusätzlich
`range = "today" | "week" | "month"` oder `from`/`to` (Unix-Zeit) für Zeiträume aus Stundenwerten.

**Zone:** uiMapID; in Instanzen `-instanceID` (negativ).

**Weltwissen:** Arten, die als Weltwissen markiert sind, gehen beim Export als Summe aller Charaktere raus und dürfen
von jedem importiert werden. Alle anderen Arten sind persönlich.

**Rekorde:** Neben den Zählern gibt es Höchst- und Tiefstwerte. Der Schreiber meldet mit `writer:SetMax(kind, id, value, mapID)`
bzw. `writer:SetMin(...)`; gespeichert wird nur ein besserer Wert. Rückgabe: `true` und der alte Wert bei einem Rekord,
sonst `false` und der Rekord. Rekorde sind persönlich (nicht Weltwissen), zählen nicht in `GetCount`, lösen aber
`EVENT_CHANGED` aus. Ablage je Charakter: `{ Wert, Zeit, mapID }`. Der Import behält den besseren Wert.

**Änderungen:** `GlimpseDB.RegisterCallback(self, GlimpseDB.EVENT_CHANGED, function(_, nsName, kind, id) end)`;
`nsName = nil` heißt viele Änderungen auf einmal (Import, Zurücksetzen).

## Namespace `combat`

Besitzer: Glimpse (Core-Modul Kampf, `Modules/Combat/`). Bereich `Core`, mit Zonen, keine Tageswerte.

| Art | ID | Wert | Weltwissen |
| --- | --- | --- | --- |
| `kill` | NPC-ID | Kills, pro Zone | nein |
| `death` | NPC-ID des Verursachers, 0 = unbekannt | Tode, pro Zone | nein |
| `time` | 0 | Sekunden im Kampf | nein |
| `looted` | NPC-ID | Kontrolle für `kill`: geplünderte Leichen (Backup, keine Beute-Statistik) | ja |
| `loot:<NPC-ID>` | Item-ID | Kontrolldaten zu `looted`: Anzahl erbeutet (die Beute-Auswertung liefert `gathering`) | ja |

```lua
local combat = GlimpseDB:Get("combat")
combat:GetCount("kill", 299)                         -- Kills dieses NPC, eingeloggter Charakter
combat:GetCount("kill", nil, { range = "week" })     -- alle Kills der letzten 7 Tage
combat:GetCounts("loot:299", "all")                  -- { [itemID] = Anzahl } aller Charaktere
```

## Namespace `travel`

Besitzer: Glimpse (Core-Modul Reisen, `Modules/Travel/`). Bereich `Core`, keine Zonen, **mit Tageswerten**.

Fortbewegungsarten (ID bei `distance` und `traveltime`):

| ID | Art | Erkennung |
| --- | --- | --- |
| 1 | Laufen | Standard |
| 2 | Reiten | aufgesessen |
| 3 | Schwimmen | an der Oberfläche |
| 4 | Flugroute | auf dem Flugtier (`UnitOnTaxi`) |
| 5 | Geist | tot als Geist |
| 6 | Schiff/Zeppelin | Position ändert sich, eigene Geschwindigkeit in zwei Schritten hintereinander 0 |
| 7 | Unter Wasser | getaucht |
| 8 | Tiefenbahn | nur in der Instanz 369: der Charakter steht selbst (eigene Geschwindigkeit 0) und wird seit mindestens 2 Sekunden schneller als Laufen bewegt (über 10 Yards pro Sekunde) |

| Art | ID | Wert |
| --- | --- | --- |
| `distance` | Fortbewegungsart | Yards |
| `traveltime` | Fortbewegungsart | Sekunden in Bewegung; Art 8 (Tiefenbahn) fest 58 Sekunden je Fahrt |
| `zone` | Zone | Betreten |
| `zonetime` | Zone | Sekunden in der Zone |
| `teleport` | 0 | Teleport, Ruhestein, Portal (ohne Strecke) |
| `jump` | 0 | Sprünge mit der Leertaste, nur vom Boden |
| `speedmax` | Fortbewegungsart: 1 gehen, 2 Reittier | **Rekord** (`GetMax`): höchster Wert eines Messabschnitts von mindestens 5 Sekunden (Yards pro Sekunde); nicht beim Fallen, auf Flugroute, Schiff oder Tiefenbahn |
| `speedmin` | 1 gehen, 2 Reittier | **Rekord** (`GetMin`): niedrigster Durchschnitt eines Messabschnitts von 5 Sekunden (über 1 Yard pro Sekunde) |
| `fallmax` | 0 | **Rekord**: tiefster Sturz in Yards, geschätzt aus der Fallzeit (Aufprall ab 23 Yards pro Sekunde, etwa 14 Yards Fallhöhe; Endgeschwindigkeit 60; jeder Sprung vom Boden setzt die Messung neu an) |
| `breathmax` | 0 | **Rekord**: längste Zeit mit angehaltenem Atem am Stück in Sekunden, gemessen ab Start der Atemleiste (ab 5 Sekunden, nur wenn die Atemleiste läuft) |
| `swimmax` | 0 | **Rekord**: längste Strecke am Stück geschwommen in Yards (ab 20 Yards) |
| `divemax` | 0 | **Rekord**: längste Strecke, die mit einem Atemzug getaucht wurde (während die Atemleiste läuft), in Yards (ab 20 Yards) |
| `walkmax` | 0 | **Rekord**: längste Strecke am Stück zu Fuß in Yards (ab 200 Yards); sie endet nach 5 Sekunden Stehen oder bei anderer Fortbewegungsart, Sprünge unterbrechen sie nicht |
| `jumpmilestone` | 0 | **Rekord**: zuletzt gemeldeter Sprung-Meilenstein (100, 500, 1000, 2500, 5000, 10000, 100000, 1000000), je Charakter |
| `tram` | Ziel: 1 Sturmwind, 2 Eisenschmiede, 0 unbekannt | Fahrten mit der Tiefenbahn; eine Fahrt endet an der Haltestelle (Bahn 3 Sekunden nicht schneller als Laufen) oder beim Verlassen der Instanz, Laufen im Wagen beendet sie nicht; hin und zurück ohne Aussteigen sind 2; alle Fahrten: `GetCount("tram")` |
Die Fahrt der Tiefenbahn dauert immer gleich lang (58 Sekunden ab Start, `Glimpse.modules.Travel.TRAM_SECONDS`), deshalb wird ihre Zeit nicht gemessen
und es gibt kein `tramtime`. Je gezählter Fahrt trägt der Core dafür fest 58 Sekunden in `traveltime` (ID 8) ein, damit Auswertungen weiter mit der Reisezeit rechnen können; die Zeit wird nicht gemessen.

| `flightpoint` | nodeID | 1 = dem Charakter bekannt |
| `flight` | Route `von * 10000 + nach` (nodeIDs) | Flüge |
| `flighttime` | Route | Sekunden |
| `flightdistance` | Route | Yards |

Das Ziel der Tiefenbahn ergibt sich aus der Startstadt: Der Core merkt sich bei Zonenwechsel Sturmwind (Karte 1453) oder Eisenschmiede (1455), beim Betreten der Instanz wird sie zur Startstadt,
jede weitere Fahrt ohne Aussteigen läuft zur anderen Haltestelle. Ohne bekannte Stadt (z. B. in der Bahn eingeloggt) zählt die Fahrt mit Ziel 0. Das Ziel wird nur im Speicher gehalten, ein Start wird nicht gespeichert.

**Nachrichten** (AceEvent, `Glimpse:RegisterMessage`), z. B. für eine Ankunftsanzeige:

| Nachricht | Parameter | Wann |
| --- | --- | --- |
| `GLIMPSE_TRAVEL_RIDE_START` | `kind, id, startTime, seconds` (seconds = 58 bei der Tiefenbahn, nil beim Flug) | Abfahrt der Tiefenbahn (`"tram"`, id = Ziel, 0 = unbekannt) oder Abheben (`"flight"`, id = Route) |
| `GLIMPSE_TRAVEL_RIDE_END` | `kind, id` | Ankunft, Landung oder Abbruch |

Orte: alle Flugpunkte, `id` = nodeID auf ihrer Zonenkarte. Namen liefert der Client über `C_TaxiMap`.
Kein Weltwissen, alles ist persönlich.

```lua
local travel = GlimpseDB:Get("travel")
travel:GetCount("distance", 1)                        -- gelaufen, insgesamt (Yards)
travel:GetCount("distance")                           -- Gesamtstrecke, alle Arten
travel:GetDayCount("distance", 2, nil, 1)             -- heute geritten
travel:GetDayCount("traveltime", nil, nil, 7)         -- Reisezeit der letzten 7 Tage
travel:GetDays("distance", 1)                         -- { [20261009] = Yards, ... }, letzte 7 Tage

-- Durchschnittsgeschwindigkeit (Yards pro Sekunde) einer Art
local speed = travel:GetCount("distance", 1) / math.max(travel:GetCount("traveltime", 1), 1)

-- Flugroute von Knoten 23 nach 25
local route = 23 * 10000 + 25
local flights = travel:GetCount("flight", route, "account")
local avgSeconds = flights > 0 and travel:GetCount("flighttime", route, "account") / flights
local yardsPerSecond = travel:GetCount("flightdistance", route, "account")
    / math.max(travel:GetCount("flighttime", route, "account"), 1)

travel:GetLocations(1413, nil)                        -- Flugpunkte auf der Karte Brachland
```

Strecke in Metern für die Anzeige: `Glimpse:FormatDistance(yards)` nutzt die Einheit aus den Optionen.

## Namespace `fishing`

Besitzer: Glimpse_Professions (`Modules/Fishing/FishingRecord.lua`). Bereich `Professions`, mit Zonen.

| Art | ID | Wert | Weltwissen |
| --- | --- | --- | --- |
| `cast` | 0 | Würfe, die ausgehen (Beutefenster oder stehend ausgelaufen, ab Professions 0.3.15 nicht schon beim Auswerfen), pro Zone; Wurf ohne Fang = `cast` - `catch`, Fangquote = `catch` / `cast` | nein |
| `casttier` | maximale Angelfertigkeit beim Wurf | Würfe | nein |
| `castabort` | 0 | Würfe, die durch Bewegung, Fall oder Kampf abgebrochen wurden, pro Zone (ab Professions 0.3.15); sie stehen nicht in `cast` und werden nirgends verrechnet | nein |
| `aborttier` | maximale Angelfertigkeit beim Abbruch | abgebrochene Würfe | nein |
| `catch` | 0 | Fänge, pro Zone | nein |
| `catchtier` | maximale Angelfertigkeit beim Fang | Fänge | nein |
| `fish` | Item-ID | Anzahl gefangen, pro Zone | nein |
| `looted` | Zone | Beutefenster beim Angeln | ja |
| `loot:<Zone>` | Item-ID | Anzahl gefangen in der Zone | ja |
| `drop:<Zone>` | Item-ID | Beutefenster mit diesem Item | ja |

```lua
local fishing = GlimpseDB:Get("fishing")
fishing:GetCount("catch") / math.max(fishing:GetCount("cast"), 1)   -- Fangquote
fishing:GetCounts("loot:1429", "all")                              -- Fänge in Elwynn, alle Charaktere
```

## Namespace `gathering`

Besitzer: Glimpse_Gathering (früher Glimpse_GatheringDB; ein gespeicherter alter Besitzer zählt als der neue). Bereich `Gathering`, mit Zonen. Fundorte als Orte.

| Art | ID | Wert | Weltwissen |
| --- | --- | --- | --- |
| `herb`, `ore`, `other` | Objekt-ID des Vorkommens | gesammelt, pro Zone | nein |
| `skin` | NPC-ID | gekürschnert, pro Zone | nein |
| `node` | Objekt-ID | Beutefenster an Vorkommen | ja |
| `nodeloot:<Objekt-ID>` | Item-ID | Anzahl | ja |
| `nodedrop:<Objekt-ID>` | Item-ID | Beutefenster mit diesem Item | ja |
| `npc` | NPC-ID | geplünderte Leichen (Sammelgut) | ja |
| `npcloot:<NPC-ID>`, `npcdrop:<NPC-ID>` | Item-ID | wie bei node | ja |
| `skinned` | NPC-ID | Beutefenster beim Kürschnern | ja |
| `skinloot:<NPC-ID>`, `skindrop:<NPC-ID>` | Item-ID | wie bei node | ja |

Orte: Fundorte der Vorkommen, `id` = Objekt-ID; in der Database liegen nur eigene Orte. Fremde Fundorte (GatherMate2)
hängt Glimpse_Gathering selbst live an, nicht über einen Database-Adapter. Namen der Objekte und NPCs stehen in Glimpse_Gathering
(SavedVariables `GlimpseGatheringNames`), nicht in der Database.

```lua
local gathering = GlimpseDB:Get("gathering")
gathering:GetCounts("herb")                                        -- { [Objekt-ID] = gesammelt }
gathering:GetCounts("nodeloot:1617", "all")                        -- Beute an Silberblatt
gathering:GetLocations(1429, 1617)                                 -- eigene Fundorte in Elwynn
```

## Namespace `reputation`

Vorgesehen für das Addon Glimpse: Reputation, noch keine Daten.
