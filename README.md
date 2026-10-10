# Glimpse

<p align="center"><img src="docs/icon.png" alt="Glimpse icon" width="160"></p>

<p align="center">
  <a href="https://github.com/N3zr0k/Glimpse/releases"><img src="https://img.shields.io/github/v/release/N3zr0k/Glimpse?include_prereleases&sort=date&label=latest" alt="latest"></a>
  <a href="https://github.com/N3zr0k/Glimpse/releases"><img src="https://img.shields.io/badge/dynamic/regex?url=https%3A%2F%2Fgithub.com%2FN3zr0k%2FGlimpse%2Freleases.atom&search=%2F%28release%29s%2Ftag%2Fv%5B0-9.%5D%2B%22%7C%2Freleases%2Ftag%2Fv%5B0-9.%5D%2B-%28alpha%7Cbeta%7Clatest%29&replace=%241%242&label=status&color=blue" alt="status"></a>
  <a href="https://github.com/N3zr0k/Glimpse/commits/main"><img src="https://img.shields.io/github/last-commit/N3zr0k/Glimpse/main?label=last%20push" alt="last push"></a>
  <a href="https://github.com/N3zr0k/Glimpse/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/N3zr0k/Glimpse/ci.yml?branch=main&label=CI" alt="CI"></a>
</p>

Minimalistic tooltip framework and common base for the Glimpse addons. On its own it adds a settings page, an overview
of the installed extensions and an API for tooltips, and it records what every character does.

For WoW Forever (interface 16001).

| Addon | Role |
| --- | --- |
| **Glimpse** | Settings, overview of the extensions, tooltip API, and recording of combat and travel data. |
| **Glimpse: Database** | Stores the data of all Glimpse addons per character and for the account, with export and import. Large or optional parts live in four data areas (`Glimpse_Database_Gathering`, `_Professions`, `_Reputation`, `_Misc`) that load only when an addon needs them. Shows nothing by itself. |

## Contents

* [Features](#features)
* [Options](#options)
* [Commands](#commands)
* [Installation](#installation)
* [For developers](#for-developers)
* [Credits](#credits)
* [License](#license)

## Features

* One place for all extensions: each one is a separate addon with its own page under Glimpse in the game options.
* Overview of the installed extensions with icon and version, and a warning if an extension needs a newer Glimpse.
* Records kills, deaths, combat time, loot per creature, distance travelled (walking, riding, swimming, flight paths,
  as a ghost) and time per zone for every character. Extensions such as Statistics show the numbers.
* Knows where data comes from: recorded by Glimpse, imported, the game's own statistic before Glimpse, or read live
  from another addon such as GatherMate2 (never copied).
* Export and import as a text you can copy. Knowledge about the world (places, loot) can be shared with anyone;
  personal numbers only go back to the same character, also on a new computer or before that character logs in.
* Debug mode: diagnostic messages in the chat and a [DEBUG] block in tooltips (target, ID, data type, hidden fields).

| Extension | What it does |
| --- | --- |
| [Glimpse: KeybindsTooltip](https://github.com/N3zr0k/Glimpse_KeybindsTooltip) | Keyboard, mouse and click-cast bindings in spell, item and macro tooltips |
| [Glimpse: Gathering](https://github.com/N3zr0k/Glimpse_Gathering) | Records gathering and loot data and shows drop chances and the best places in tooltips |
| [Glimpse: Statistics](https://github.com/N3zr0k/Glimpse_Statistics) | Counts kills, deaths, fishing, gathering and skinning per character and account |
| [Glimpse: Professions](https://github.com/N3zr0k/Glimpse_Professions) | Profession spell tooltips with skill, bonus and statistics; fishing first |

## Options

Open them with `/gli config` or in the game options under Addons > Glimpse.

* **Overview:** installed extensions and, below a divider, the credits of the whole suite: author, contributors,
  image credits of all extensions and thanks.
* **General:** debug mode and the distance unit for all extensions (automatic by client language, yards or metres).
* **Combat:** kills and deaths in creature tooltips, with account values and position next to the name, the level or
  in an own line.
* **Data:** the data areas of Glimpse: Database with their size, export and import (to share or move to another computer),
  and resetting an area.
* **Profiles:** settings per profile, can be copied, reset and shared between characters.

Extensions can offer "Only while a key is held": their tooltip lines then appear only while Shift, Ctrl and/or Alt are held.

## Commands

| Command | Does |
| --- | --- |
| `/glimpse` or `/gli` | Shows all commands, including those of installed extensions |
| `/gli config` | Opens the settings |
| `/gli info` | Addon information from the TOC (version, author, links, license, game version) |
| `/gli debug on\|off` | Switches the debug mode |
| `/gli debug log` | Opens the last debug lines in a window to copy them |
| `/gli debug list` | Shows the debug categories; `/gli debug <name> <category> on\|off` switches one |
| `/gli probe` | Lists the test probes of all extensions; `/gli probe <group> <name>` runs one |

## Installation

Download the latest ZIP from [CurseForge](https://www.curseforge.com/wow/addons/glimpse) or the
[releases page](https://github.com/N3zr0k/Glimpse/releases) and unpack it into the AddOns folder of the Forever client,
during the beta for example `D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns`. The folder must be called
`Glimpse`. The ZIP also contains `Glimpse_Database` and its four data areas `Glimpse_Database_Gathering`,
`_Professions`, `_Reputation` and `_Misc`; keep all of them enabled. Extensions are installed the same way, next to it.

## For developers

Glimpse is built on Ace3. The API (tooltip lines and handlers, options pages, credits, modifier keys, slash commands,
debuggers and probes, ID helpers, the `Locations` module, the recorded data) is described in
[DEVELOPER.md](DEVELOPER.md) (German), together with the Database API (global `GlimpseDB`: namespaces, counters,
hourly history, places, export and import, callback `Glimpse_DB_Changed`).

The repository holds the folders `Glimpse/`, `Glimpse_Database/` and the four `Glimpse_Database_*` areas; link all of
them into the AddOns folder (junction) and `/reload` after each change. Checks:

```
lua tests/run.lua
lua tests/database/run.lua
luacheck .
python3 tools/check.py
```

## Credits

Author: N3zr0k. Special thanks to Flovy and sMash for testing.

## License

MIT, see [LICENSE](LICENSE). The embedded libraries have their own licenses, each in its folder: Ace3 and
HereBeDragons (by Nevcairiel, BSD) in `Glimpse/Libs/`, LibStub, CallbackHandler-1.0, LibSerialize (by Ross Nichols, MIT)
and LibDeflate (by Haoqian He, zlib) in `Glimpse_Database/Libs/`.
