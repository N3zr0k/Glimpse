# CurseForge-Projekt: Glimpse

Angaben und Texte zum Kopieren in den CurseForge Author Console (Projekt Glimpse, ID 1730173). Texte auf CurseForge
auf Englisch. Das Repository enthält Glimpse, Glimpse: Database und die vier Datenbereiche; alles gehört zu diesem
einen Projekt. Stand: Core 0.3.36-alpha.1. Alpha-Versionen gehen nicht auf CurseForge, die Texte sind für beta und
latest.

## Felder

| Feld | Eintrag |
| --- | --- |
| Project name | `Glimpse` |
| Slug (URL) | `glimpse` |
| Summary | `Minimalistic tooltip framework and base for the Glimpse addons. Records combat and travel data per character and account and shares it with other addons.` |
| Primary category | Miscellaneous |
| Additional categories | Tooltip, Plugins, Combat |
| License | MIT License |
| Logo / Avatar | `docs/icon.png` (512 x 512 PNG) |
| Source | `https://github.com/N3zr0k/Glimpse` |
| Issues | `https://github.com/N3zr0k/Glimpse/issues` |
| Game version | WoW Forever, Interface 16001 (setzt der Packager pro Datei aus der TOC) |
| Relations | Embedded: Ace3. Kommt automatisch aus `.pkgmeta`, nichts von Hand eintragen. |

## Description (Markdown)

```markdown
# Glimpse

[![latest](https://img.shields.io/github/v/release/N3zr0k/Glimpse?include_prereleases&amp;sort=date&amp;label=latest)](https://github.com/N3zr0k/Glimpse/releases) [![last push](https://img.shields.io/github/last-commit/N3zr0k/Glimpse/main?label=last%20push)](https://github.com/N3zr0k/Glimpse/commits/main) [![CI](https://img.shields.io/github/actions/workflow/status/N3zr0k/Glimpse/ci.yml?branch=main&amp;label=CI)](https://github.com/N3zr0k/Glimpse/actions/workflows/ci.yml)

Minimalistic tooltip framework and common base for the Glimpse addons. On its own it adds a settings page, an overview of the installed extensions and an API for tooltips, and it **records what every character does**. The numbers are stored by **Glimpse: Database** (included) and can be shown by extensions such as Glimpse: Statistics.

For WoW Forever (interface 16001).

## What you get

- **One place for all extensions:** each extension has its own page under Glimpse in the game options. The overview lists them with icon and version and warns if one needs a newer Glimpse.
- **Combat:** kills (also from looted corpses), deaths with the killer, combat time and loot per creature. Kills and deaths show up in the creature tooltip, with account values in brackets.
- **Travel:** distance and time while walking, riding, swimming, diving, on flight paths, as a ghost, on ships and zeppelins and on the Deeprun Tram, with values per day and for the last 7 days. Also zones entered and time in them, teleports, jumps, known flight points and every flight per route (count, time, distance).
- **Records:** remembers your best values: fastest and slowest speed on foot and mounted, deepest fall, longest time under water and longest swim. A new record shows a funny message on screen and in chat (switchable), and your mount gets praised. Jump milestones from 100 up to one million jumps have their own sayings.
- **Double click:** extensions can register a double-click action. Glimpse detects the double click, checks the situation (standing, swimming, mounted ...) and runs the right action. One central key or one key per action.
- **Per character and account-wide:** all numbers are kept per character and can be summed for the account.
- **Backup and sharing:** export and import as text you can copy. Knowledge about the world (places, loot) can be shared with anyone, personal numbers only go back to the same character.
- **Debug mode:** diagnostic messages with the addon name in the chat, a log window to copy and test probes for testers.
- German and English.

## Included addons

| Addon | What it does |
| --- | --- |
| **Glimpse** | Settings, overview, tooltip and double-click API, recording of combat and travel data. |
| **Glimpse: Database** | Stores the data of all Glimpse addons, with export and import. Large or optional parts live in four data areas that load only when needed. Shows nothing by itself. |

## Extensions

- [Glimpse: KeybindsTooltip](https://github.com/N3zr0k/Glimpse_KeybindsTooltip): keyboard, mouse and click-cast bindings in tooltips
- [Glimpse: Gathering](https://github.com/N3zr0k/Glimpse_Gathering): gathering and loot data, drop chances and best places in tooltips
- [Glimpse: Statistics](https://github.com/N3zr0k/Glimpse_Statistics): counts kills, deaths, fishing and gathering
- [Glimpse: Professions](https://github.com/N3zr0k/Glimpse_Professions): profession tooltips, fishing first

## Commands

`/gli` (or `/glimpse`) lists all commands. `/gli config` opens the settings, `/gli info` shows version and links, `/gli debug on|off` switches the debug mode, `/gli probe` lists the test probes.

## Installation

Unpack the ZIP into the AddOns folder of the Forever client. The ZIP contains `Glimpse`, `Glimpse_Database` and its four data areas `Glimpse_Database_Gathering`, `_Professions`, `_Reputation` and `_Misc`. Keep all of them enabled.

## Links

- Source, API documentation and issues: [GitHub](https://github.com/N3zr0k/Glimpse)
- MIT license
```

## Changelog-Text

Der Changelog kommt aus `CHANGELOG.md` (`manual-changelog` in `.pkgmeta`), nichts zu kopieren.
