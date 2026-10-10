# Funktionen

Alle Funktionen, die in diesem Repository (Glimpse und Glimpse: Database) eingebaut sind, mit kurzer Beschreibung. Die
Tabelle am Ende zeigt, welche Funktion Daten in der Datenbank liest, schreibt oder beides. Die Dateien dazu stehen in
[Files.md](Files.md), alle gespeicherten Werte in [API.md](API.md).

Stand: Core 0.3.40-beta.1.

## Glimpse (Core)

| Funktion | Beschreibung |
| --- | --- |
| Übersicht und Optionen | Optionsfenster unter Addons > Glimpse (`/gli config`): Liste der Erweiterungen mit Symbol, Version und Warnung bei zu alter Core-Version, Profile. |
| Credits | Autor, Bildnachweise aller Addons und Dank einmal in der Übersicht unter einem Trenner. |
| Tooltip-API | Erweiterungen hängen Zeilen und Handler an Tooltips (ein gemeinsamer PostCall), mit Trennlinie fester Breite und Schutz vor geheimen Werten (Secrets). |
| Modifier-Tasten | Tooltip-Zeilen nur bei gehaltener Umschalt-, Strg- und/oder Alt-Taste. |
| Doppelklick-Verteiler | Erweiterungen melden Doppelklick-Aktionen an (Taste, Priorität, Bedingungen); der Core erkennt den Doppelklick, bestimmt die Lage (stehen, schwimmen, Mount ...) und führt die passende Aktion aus. Zentrale Taste, Priorität und An/Aus je Aktion in den Optionen. |
| Debug | Debug-Modus mit Kategorien je Modul, Log-Fenster zum Kopieren, Addon-Kennung `[Glimpse: Name]` in Chat und Tooltip, Probes für Tester (`/gli probe`), Tooltip-Infos für Entwickler. |
| Slash-Befehle | `/gli` (auch `/glimpse`): `config`, `info`, `help`, `debug`, `probe`, `db owner`; Erweiterungen melden eigene Befehle an. |
| Locations | Kartennamen, Spielerposition, Entfernungen in Yards oder Metern, Koordinaten als Text, Wegpunkt über TomTom oder Spielmarkierung. |
| ID-Helfer | GUID zerlegen, NPC-ID, Namen von Item, Zauber und Karte, Zonen-Schlüssel. |
| Kampf | Zählt Kills (auch aus geplünderten Leichen, je GUID einmal), eigene Tode mit Verursacher, Kampfzeit. Geplünderte Leichen (`looted`) sind nur Backup und Kontrolle für den Killzähler, keine Beute-Statistik (die kommt von Gathering). Kills und Tode stehen im Kreatur-Tooltip, mit Account-Wert und wählbarer Position. |
| Reisen | Misst Strecke und Zeit je Fortbewegungsart (laufen, reiten, schwimmen, Flugroute, Geist, Schiff/Zeppelin, tauchen, Tiefenbahn), mit Tageswerten. Zählt betretene Zonen samt Aufenthaltsdauer, Teleports (Ruhestein, Portale), Sprünge mit der Leertaste, bekannte Flugpunkte sowie Flüge je Route (Anzahl, Zeit, Strecke). |
| Tiefenbahn | Erkennt Fahrten nur in der Instanz (selbst stehen, schneller bewegt als Laufen). Startstadt und Ziel (Sturmwind, Eisenschmiede) ergeben sich aus der zuletzt besuchten Stadt, die Fahrzeit ist fest 58 Sekunden. Meldet Start und Ende als Nachrichten `GLIMPSE_TRAVEL_RIDE_START` und `_END` (auch für Flüge). |
| Daten | Tab „Daten“: Bereiche mit Größe, Export und Import als Text, Zurücksetzen. |
| Rekorde | Merkt sich Bestwerte: höchstes und niedrigstes Tempo zu Fuß und beim Reiten, tiefsten Sturz, längste Zeit mit angehaltenem Atem, längste Tauchstrecke, längste Schwimmstrecke und längste Laufstrecke am Stück. Bei einem neuen Rekord kommt eine Meldung mit lustigem Text (auf dem Bildschirm, im Chat oder beides, Standard beides); beim Reiten wird das Reittier gelobt. Dazu Sprung-Meilensteine bei 100, 500, 1000, 2500, 5000, 10000, 100000 und 1000000 Sprüngen mit je einem eigenen Spruch. Tab „Rekorde“: Schalter je Art, Ausgabe und die Liste „Rekorde anzeigen“. |
| Sichern | Zählt die Änderungen seit dem Start und fragt beim Betreten eines Ruhebereichs, ob neu geladen werden soll, damit die Daten auf die Platte kommen. Grenzen als Regler im Tab „Daten“: Änderungen (10 bis 1000, Standard 100) und Minuten (0 bis 120, Standard 30, 0 = aus). Mit Anzeige der ungesicherten Änderungen und „Jetzt sichern“. |
| Beispielmodul | Vorlage für eigene Module. |

## Glimpse: Database

| Funktion | Beschreibung |
| --- | --- |
| Namespaces | Jedes Addon meldet einen Namespace an (ein Schreiber, der Besitzer ist der Addon-Ordner, der ihn zuerst anmeldet); gelesen werden darf von allen. |
| Rekorde | Höchst- und Tiefstwerte je Charakter, Art und ID (`SetMax`, `SetMin`, `GetMax`, `GetMin`) mit Zeit und Zone; Import und Export behalten den besseren Wert. |
| Zähler | Werte je Charakter, Art, ID und optional Zone, mit Summen für den Charakter, den Account oder alle. |
| Zeiträume | Stundenwerte (heute, Woche, Monat, frei wählbar) und Tageswerte (ein Wert je Tag, letzte 7 Tage). |
| Namen | Texte zu IDs je Clientsprache (`SetLabel`, `GetLabel`), Weltwissen: im Export, ein Import behält vorhandene Namen. |
| Orte | Karte, X und Y, kompakt gespeichert; fremde Fundorte (z. B. GatherMate2) werden live gelesen und nie kopiert. |
| Herkunft | Eigene, importierte, Blizzard-Startwerte und externe Daten bleiben getrennt. |
| Datenbereiche | Große Teile liegen in vier Bereichen (Gathering, Professions, Reputation, Misc), die erst bei Bedarf laden. |
| Export und Import | Text zum Kopieren; Weltwissen (Orte, Beute) teilbar, persönliche Zahlen nur zurück an denselben Charakter. Import führt per Maximum zusammen. |
| Änderungsmeldung | Callback bei geänderten Daten für Addons, die Anzeigen aktuell halten. |

## Datenbank-Zugriff je Funktion

Spalten **Liest**, **Schreibt** und **Beides**: ein Haken zeigt, wie die Funktion den Namespace nutzt. „–“ heißt kein Zugriff.

| Funktion | Namespace | Liest | Schreibt | Beides |
| --- | --- | :-: | :-: | :-: |
| Kampf: Kills, Tode, Zeit, Kontrolle (`looted`) | `combat` | | ✔ | |
| Kampf: Kreatur-Tooltip | `combat` | ✔ | | |
| Reisen: Strecke, Zeit, Zonen, Teleports, Sprünge, Flugpunkte, Flüge, Tiefenbahn | `travel` | | ✔ | |
| Rekorde: Tempo, Sturz, Atem, Schwimmstrecke, Sprung-Meilensteine | `travel` | ✔ | ✔ | ✔ |
| Namensdienst: NPC- und Objektnamen zu IDs (`Glimpse.IDs:NPCName`, `:ObjectName`) | `names` | ✔ | ✔ | ✔ |
| Rekorde: Liste „Rekorde anzeigen“ | `travel` | ✔ | | |
| Daten-Tab: Größe, Export, Import, Zurücksetzen | alle | | | ✔ |
| Sichern: zählt Änderungsmeldungen | alle (nur die Meldung, keine Daten) | ✔ | | |
| Probe `db sources` | alle | ✔ | | |
| Befehl `/gli db owner` | Besitzer der Namespaces (`GlimpseDB_Meta`) | | | ✔ |
| Glimpse: Database | alle (`GlimpseDB_Core` und die Bereiche) | | | ✔ |
| Übrige Funktionen (Optionen, Tooltip-API, Doppelklick, Debug, Locations, ID-Helfer) | – | | | |
