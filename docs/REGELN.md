# Glimpse: Regeln

Verbindliche Regeln für alle Glimpse-Addons, festgelegt von Sven. Sie gelten für neuen Code und für jede
Überarbeitung. Details zu Schnittstellen stehen in [DEVELOPER.md](../DEVELOPER.md).

## Ziel

* Nur WoW Forever. Alle TOCs tragen `## Interface: 16001`, andere Clients werden nicht unterstützt.

## Code

* Sauber, einfach, gut lesbar.
* Nie Code 1:1 aus anderen Addons übernehmen, nur Ansatz und Idee.
* Vor eigenem Code prüfen, ob es eine passende Library gibt. Sie muss im Client laufen und eine zu MIT passende Lizenz
  haben.
* Kommentare kurz und informativ für Entwickler, auf Deutsch, und sie dürfen nicht nach KI klingen.
* Secret-Werte nie vergleichen, verketten oder als Schlüssel benutzen.
* Blizzard-Funktionen, die zwischen Client-Ständen wandern, über einen Alias mit Fallback ansprechen.
* Blizzard-Funktionen, die ein Modul braucht, in einer `api`-Tabelle bündeln, damit Tests sie ersetzen können.

## Dateien und Ordner

* Die TOC nennt nur eine XML; alle Lua-Dateien werden über XML geladen (`Glimpse.xml` als Vorbild).
* Lieber viele kleine Lua-Dateien nach Thema als eine große. Die Übersicht hat Vorrang.
* Dateien beginnen mit dem Namen ihres Moduls, danach das Thema (`CombatKills.lua`, `CombatDeaths.lua`).
  Braucht eine Datei Helfer, wird ihr Name verlängert (`CombatDeathsHelper.lua`; `Fishing.lua`, `FishingLure.lua`).
* Erfassen und Anzeigen sind getrennt: Erfassung in `<Modul><Thema>.lua` (`CombatKills.lua`), die Anzeige in
  `<Modul>Tooltip.lua` (`CombatTooltip.lua`).
* Hat eine Funktion mehrere Dateien, bekommt sie einen eigenen Ordner mit eigener XML (z. B. `Modules/Travel/Records/`).
  Gemeinsam genutzte Dinge liegen im Core oder in `Modules/Helper/`, nicht in einem Fachmodul.
* Oberste Ebene eines Addon-Ordners nur: `Core/`, `Libs/`, `Commands/`, `Locales/`, `Modules/`, `Media/`.
* Im Repo hat jedes Addon einen eigenen Unterordner mit nur den Dateien, die WoW lädt. Tests, Tools, Doku und CI liegen
  daneben.
* TOC-Titel immer `Glimpse: Name`.
* Alle Glimpse-Addons (Core, Database, Erweiterungen) tragen `## Category: Tooltip` (Sven, 2026-10-10).
* `tools/check.py` prüft, dass jede Lua- und XML-Datei von einer TOC oder XML geladen wird und in `docs/Files.md` steht.
* `docs/Files.md` listet als Tabelle alle Dateien des Addons (nur was WoW lädt) mit kurzer Beschreibung, ob die Datei
  in die Datenbank schreibt oder daraus liest und in welchen Namespace bzw. Bereich, und weiteren wichtigen
  Abhängigkeiten. Bei jeder neuen, umbenannten oder gelöschten Datei mitpflegen.
* `docs/API.md` im Glimpse-Repo listet alle gespeicherten Daten der Suite (Namespace, Art, ID, Wert) und wie man sie
  abruft. Jeder neue oder geänderte gespeicherte Wert, auch aus Erweiterungen, wird dort eingetragen.
* `docs/Features.md` im Repo listet die aktuell eingebauten Funktionen mit kurzer Beschreibung. Eine Tabelle zeigt, ob
  und was ein Addon in welchem Namespace der Datenbank liest, schreibt oder beides; Lesen, Schreiben und Beides haben
  je eine eigene Spalte.
* `docs/CURSEFORGE.md` im Repo sammelt alle Texte für das CurseForge-Projekt (Felder, Summary, Description), damit
  Sven sie von dort kopieren kann.
* Die Badges werden unverändert übernommen, sie funktionieren: README wie bisher, CurseForge-Zeile ohne `status`
  wie in `curseforge-badges.txt`.

## Daten

* Daten liegen in Glimpse: Database, nicht in eigenen SavedVariables. Jeder Namespace hat genau einen Schreiber, lesen
  darf jeder.
* Einstellungen eines Moduls oder einer Erweiterung liegen in einem eigenen Namespace von `Glimpse.db`, nie direkt in
  `GlimpseSettings`.
* IDs statt Namen speichern. Namen kommen lokalisiert aus dem Client.
* Etablierte Addons respektieren: Ist ein solches Addon geladen, nur den Tooltip erweitern und Komfort-Aktionen
  abschalten (Beispiel Fishing Buddy).

## Sprache

* Alle Texte über `Locales/`, mindestens `enUS` (Standard) und `deDE`.

## Prüfen

* Logik-Tests für jede neue Funktion. Die Tests laufen ohne WoW (`lua tests/run.lua`).
* luacheck ohne eine einzige Warnung.
* `python3 tools/check.py` muss durchlaufen.
* Vor dem Bauen zusätzlich `python3 tools/check.py --tag v<Version>`: Das prüft wie die CI, ob der CHANGELOG einen Abschnitt für die Version hat.

## Versionen und Releases

* Schema `vX.Y.Z-PHASE.N`: `X` Major-Release, `Y` Minor-Release, `Z` Bugfix/Features, `PHASE` = `alpha`, `beta`
  oder `latest`, `N` Repository-Version.
* `X`, `Y` und `PHASE` werden nur von Sven angesagt und freigegeben.
* Bevor ein Repository gebaut wird, werden die Änderungen aufgelistet und von Sven manuell freigegeben.
* `Z` steigt automatisch bei Änderungen in einem Addon-Ordner (z. B. `Glimpse_Database`).
* `N` steigt bei Änderungen im Repository außerhalb der Addon-Ordner. Ein neues `Z` setzt `N` auf 1 zurück. Ändert
  sich nur `N`, wird kein Release gebaut.
* alpha: nur ein Prerelease auf GitHub, auf CurseForge und anderen Plattformen wird nichts veröffentlicht.
* beta und latest: Release auf GitHub und CurseForge. Wago und WoWInterface bleiben aus, bis Sven sie freigibt.
* `CHANGELOG.md` nennt nur neue Funktionen und größere Fehlerbehebungen, je ein sehr kurzer Einzeiler. Kosmetisches
  steht nicht drin.
* Alle READMEs folgen demselben Aufbau.

## Übergabe

* Commits laufen unter Svens Identität, nie mit Claude als Co-Autor.
* Repo-ZIPs tragen die Version im Namen (`Glimpse_Repo_0.3.4-alpha.3.zip`) und enthalten keinen `.git`-Ordner.

## Repo-Bauweise (Pflicht, AddonHelper)

Der AddonHelper und `TesterZip` setzen diese Bauweise voraus. Weicht ein Repo ab, schlägt das Update fehl. Quelle:
`/mnt/project-files/dev-helper/Repo-Bauweise.md`.

* ZIP-Name: `<Repo>_Repo_<X.Y.Z-PHASE.N>.zip`, `<Repo>` heißt wie der Git-Clone (`Glimpse`, `Glimpse_Gathering`, ...).
* Genau ein Wurzelordner in der ZIP, exakt wie das Repo benannt (`Glimpse/`, nicht `Glimpse_Repo_0.3.25-alpha.1/`).
* Kein `.git` in der ZIP, Pfadtrenner `/`.
* Jeder Addon-Ordner liegt direkt unter dem Wurzelordner und hat eine gleichnamige TOC (`<Addon>/<Addon>.toc`).
* Dev-Dateien (`.github/`, `docs/`, `tests/`, `tools/`, README, CHANGELOG, LICENSE, `.pkgmeta`, `.luacheckrc`,
  `.gitattributes`, `.gitignore`) liegen neben den Addon-Ordnern, nie darin.
* Das Script löscht beim Update alles außer `.git`: was nicht in der ZIP steht, ist danach weg.
* `## Version:` in allen TOCs ist gleich und entspricht der Version im ZIP-Namen.
* Build-Ablauf: Repo in einen Ordner mit dem Repo-Namen kopieren und von dort zippen, nie in einen Ordner mit
  Versionsnummer.

## Wer Daten erfasst (Sven, 2026-10-10)

* Erweiterungen dürfen eigene Datenbank-Sammler haben, wenn es zur Erweiterung passt:
  * Professions sammelt Daten zu den Berufen.
  * Gathering sammelt Daten zu den Sammelberufen und die Beute von NPCs.
* Allgemeine Daten, die dauerhaft erfasst werden müssen, sammelt Glimpse: Core: Kills, Tode, Reputation pro NPC,
  alles was Travel betrifft (auch Flugpunkte, Flüge, Schiffe, Zeppeline, Tiefenbahn), Sprünge, gelaufene und
  geschwommene Strecke, Teleports usw. Travel hat keinen eigenen Sammler und liest nur.
* Diese Regel ersetzt die frühere Strategie, dass alle Sammler im Core liegen.
