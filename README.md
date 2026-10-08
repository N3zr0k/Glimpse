# Glimpse

<p align="center"><img src="docs/icon.png" alt="Glimpse icon" width="160"></p>

Minimalistic tooltip framework and common base for the Glimpse addons. On its own it adds a settings page, an overview
of the installed extensions and an API for tooltips.

For WoW Forever (interface 16001).

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
* Debug mode: diagnostic messages in the chat and a [DEBUG] block in tooltips (target, ID, data type, hidden fields).

| Extension | What it does |
| --- | --- |
| [Glimpse: KeybindsTooltip](https://github.com/N3zr0k/Glimpse_KeybindsTooltip) | Keyboard, mouse and click-cast bindings in spell, item and macro tooltips |
| [Glimpse: Gathering](https://github.com/N3zr0k/Glimpse_Gathering) | Records gathering and loot data and shows drop chances and the best places in tooltips |
| [Glimpse: Statistics](https://github.com/N3zr0k/Glimpse_Statistics) | Counts kills, deaths, fishing, gathering and skinning per character and account |
| [Glimpse: Professions](https://github.com/N3zr0k/Glimpse_Professions) | Profession spell tooltips with skill, bonus and statistics; fishing first |

## Options

Open them with `/gli config` or in the game options under Addons > Glimpse.

* **Overview:** installed extensions.
* **General:** debug mode and the distance unit for all extensions (automatic by client language, yards or metres).
* **Profiles:** settings per profile, can be copied, reset and shared between characters.
* **Credits:** author, contributors, image credits and thanks. Every extension page has the same tab.

Extensions can offer "Only while a key is held": their tooltip lines then appear only while Shift, Ctrl and/or Alt are held.

## Commands

| Command | Does |
| --- | --- |
| `/glimpse` or `/gli` | Shows all commands, including those of installed extensions |
| `/gli config` | Opens the settings |
| `/gli info` | Addon information from the TOC (version, author, links, license, game version) |
| `/gli debug on\|off` | Switches the debug mode |

## Installation

Download the latest ZIP from [CurseForge](https://www.curseforge.com/wow/addons/glimpse) or the
[releases page](https://github.com/N3zr0k/Glimpse/releases) and unpack it into the AddOns folder of the Forever client,
during the beta for example `D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns`. The folder must be called
`Glimpse`. Extensions are installed the same way, next to it.

## For developers

Glimpse is built on Ace3. The API (tooltip lines and handlers, options pages, credits, modifier keys, slash commands,
the `Locations` module) is described in [DEVELOPER.md](DEVELOPER.md) (German).

The addon lives in the folder `Glimpse/` of the repository; link that folder into the AddOns folder (junction) and
`/reload` after each change. Checks:

```
lua tests/run.lua
luacheck .
python3 tools/check.py
```

## Credits

Author: N3zr0k. Special thanks to Flovy and sMash for testing.

## License

MIT, see [LICENSE](LICENSE). Ace3 in `Glimpse/Libs/` has its own license.
