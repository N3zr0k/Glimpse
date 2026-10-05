# Glimpse

<p align="center"><img src="docs/icon.png" alt="Glimpse icon" width="160"></p>

Minimalistic and powerful tooltip enhancement framework for World of Warcraft (Forever client, interface 16001).

Glimpse is the common base for a family of small tooltip addons. It does nothing visible on its own
except provide a settings page, an overview of the installed extensions and a clean API for tooltips.

## Extensions

| Addon | What it does |
| --- | --- |
| [Glimpse: KeybindsTooltip](https://github.com/N3zr0k/Glimpse_KeybindsTooltip) | Shows keyboard, mouse and click-cast bindings in spell, item and macro tooltips |
| [Glimpse: GatheringDB / GatheringTooltip](https://github.com/N3zr0k/Glimpse_Gathering) | Records gathering and loot data while you play and shows drop chances in tooltips |

## Installation

Download the latest ZIP from the [releases page](https://github.com/N3zr0k/Glimpse/releases) and unpack it into
`World of Warcraft/_retail_/Interface/AddOns` (use the folder of your client). The folder must be called `Glimpse`.

## Usage

* `/glimpse` or `/gli` shows all commands.
* `/gli config` opens the settings, `/gli info` shows the addon information from the TOC.
* `/gli debug on|off` switches the debug mode (chat output of all modules, extra tooltip data).

Settings are stored per profile (Settings > Addons > Glimpse > Profiles).

## For developers

Glimpse is built on Ace3. Extensions are separate addons that depend on Glimpse. The API (tooltip lines,
options pages, slash commands, modifier keys) is described in [DEVELOPER.md](DEVELOPER.md) (German).

## License

MIT, see [LICENSE](LICENSE). Ace3 in `Libs/` has its own license.
