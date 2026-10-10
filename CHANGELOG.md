# Changelog

## [0.3.40] - 2026-10-10

### Added
- Names: the Core learns NPC names (target, attackers) and stores them per client language; other addons read them with `Glimpse.IDs:NPCName` and `:ObjectName`
- Database: names next to counters and records (`SetLabel`, `GetLabel`), part of export and import

### Removed
- Taking over old data from Statistics and GatheringDB (the first beta starts with an empty database)

## [0.3.39] - 2026-10-10

### Added
- Records: longest distance dived on one breath and longest distance walked without a break, with messages and switches

## [0.3.38] - 2026-10-10

### Fixed
- Records: the time under water starts when the breath bar starts and is now measured correctly (the client reports the paused state of the breath bar as 0/1)

## [0.3.37] - 2026-10-10

### Changed
- Records: speed records for running and riding are measured over at least 5 seconds; the highest value of that stretch counts

## [0.3.36] - 2026-10-10

### Fixed
- Records: jumping several times in a row is no longer counted as a fall; a fall needs an impact speed of at least 23 yards per second

## [0.3.35] - 2026-10-10

### Added
- Records: best values for running and riding speed, deepest fall, longest time under water and longest swim, with funny messages on screen and in chat (tab Records)
- Jump milestones from 100 up to one million jumps, each with its own saying
- Database: records (highest and lowest values) next to the counters

## [0.3.34] - 2026-10-10

### Added
- Saving: asks to reload when entering a rest area once enough changes or time have passed, so collected data reaches the disk (sliders in the Data tab)

## [0.3.33] - 2026-10-10

### Changed
- The gathering data belongs to the merged addon Glimpse: Gathering (an owner saved for the old Glimpse: GatheringDB is taken over)

## [0.3.32] - 2026-10-10

### Changed
- Combat: the looted corpses counter is documented as a backup check for the kill counter

## [0.3.31] - 2026-10-10

### Changed
- New icons for Glimpse and Glimpse: Database
- Core options are laid out like the extension pages: icon and description above the tabs, version below

### Fixed
- Combat options: the example follows the switches for kills and deaths
- Secret values in combat no longer cause errors in the travel measurement and the double click

## [0.3.25] - 2026-10-10

### Changed
- All Glimpse addons are listed under the category Tooltip in the game

## [0.3.24] - 2026-10-10

### Fixed
- Tooltip separator line has a fixed width

## [0.3.23] - 2026-10-10

### Fixed
- Tooltips with Glimpse lines no longer grow very wide after looting and shrink on every hover

## [0.3.22] - 2026-10-10

### Fixed
- No more Lua error in Travel and double click when the game protects values during combat

## [0.3.21] - 2026-10-09

### Changed
- The Deeprun Tram ride time is a fixed 58 seconds per ride (also in travel time) instead of a measurement

## [0.3.20] - 2026-10-09

### Fixed
- Walking inside the Deeprun Tram no longer splits a ride in two

## [0.3.19] - 2026-10-09

### Fixed
- Deeprun Tram start city is remembered again when you walk into Stormwind or Ironforge

## [0.3.18] - 2026-10-09

### Fixed
- Deeprun Tram start city is also found when you log in inside Stormwind or Ironforge

## [0.3.17] - 2026-10-09

### Fixed
- Deeprun Tram rides are detected only inside the tram instance, start and destination come from the city you entered from; `/gli probe travel tram` shows the state and can log a speed profile

## [0.3.16] - 2026-10-09

### Fixed
- Travel no longer counts a short walk as a ship or tram ride

## [0.3.15] - 2026-10-09

### Added
- Travel counts Deeprun Tram rides with destination and duration; ride start and end messages for tram and flights

## [0.3.14] - 2026-10-09

### Added
- Debug messages in chat and tooltips show which addon they come from

## [0.3.13] - 2026-10-09

### Added
- Travel counts jumps and the Deeprun Tram separately; teleports have their own counter

## [0.3.12] - 2026-10-09

### Added
- Travel records the distance of each flight route

## [0.3.11] - 2026-10-09

### Added
- Travel counts distance and time on ships and zeppelins and under water separately
- Travel counts teleports, hearthstones and portals per character

## [0.3.9] - 2026-10-09

### Added
- Travel records flight points, flight times per route and time spent moving
- Database keeps daily values; travel distance and time per day and for the last 7 days

### Changed
- Credits of all addons shown once in the Glimpse overview instead of a tab on every page

## [0.3.6] - 2026-10-09

### Added
- Double click dispatcher: addons react to a double click in the world, key and priority set under General > Double click

## [0.3.5] - 2026-10-08

### Added
- Namespaces belong to the addon that creates them; other addons cannot write to them

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
