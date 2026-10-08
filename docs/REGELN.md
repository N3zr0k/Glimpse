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
* Oberste Ebene eines Addon-Ordners nur: `Core/`, `Libs/`, `Commands/`, `Locales/`, `Modules/`, `Media/`.
* Im Repo hat jedes Addon einen eigenen Unterordner mit nur den Dateien, die WoW lädt. Tests, Tools, Doku und CI liegen
  daneben.
* TOC-Titel immer `Glimpse: Name`.
* `docs/Files.md` listet als Tabelle alle Dateien des Addons (nur was WoW lädt) mit kurzer Beschreibung, ob die Datei
  in die Datenbank schreibt oder daraus liest und in welchen Namespace bzw. Bereich, und weiteren wichtigen
  Abhängigkeiten. Bei jeder neuen, umbenannten oder gelöschten Datei mitpflegen.

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
