# Changelog

## [0.3.3] - 2026-10-08

### Added
- `/gli probe db sources` shows where the data of all addons comes from

## [0.3.2] - 2026-10-08

### Added
- Kills are also counted when looting a corpse without a target (area damage, pet)

## [0.3.1] - 2026-10-08

### Changed
- Data of Glimpse: Statistics is taken over per character at its login (alpha only)

## [0.3.0] - 2026-10-08

### Added
- Glimpse: Database, shared storage for all Glimpse addons with export and import
- Data of Glimpse: Statistics and Glimpse: GatheringDB is taken over once
- Records kills, deaths, combat time, loot, distance and zones per character
- Kills and deaths in creature tooltips (moved from Glimpse: Statistics)
- Options tab "Data" with export, import and reset
- Settings are stored under a new name and start fresh once
- Debug categories, debug log window (`/gli debug log`) and test probes (`/gli probe`) for extensions

## [0.2.5] - 2026-10-08

### Changed
- WoW Forever only (interface 16001)

## [0.2.3] - 2026-10-07

### Added
- Separator lines between groups of tooltip lines (`AddTooltipSeparator`)

## [0.2.2] - 2026-10-06

### Added
- Credits tab on every options page
- `Locations` module: maps, position, distances, coordinates and waypoints (TomTom or game marker)
- Distance unit option (automatic, yards or metres)

## [0.1.0] - 2026-10-05

### Added
- First release: Ace3 base with profiles, options page and overview of installed extensions
- Tooltip API for extensions (line providers, icons, secret-value safe)
- Debug mode and extensible `/gli` commands
