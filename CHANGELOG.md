# Changelog

## [0.2.2] - 2026-10-06

### Added
- "Credits" tab on every options page (author from the TOC, optional contributors, image credits, thanks)
- Module `Locations`: map names and sizes, player position, distances, coordinates and waypoints (TomTom or game marker)
- Distance unit option (automatic, yards or metres), `FormatDistance(yards)` and `GetDistanceUnit()`

### Changed
- Options pages with tabs show the version below the whole frame instead of above the tabs

## [0.1.0] - 2026-10-05

### Added
- Ace3 base with AceDB profiles, AceLocale (enUS, deDE) and a settings page in the Blizzard options
- Overview page with all installed extensions, versions and icons
- Debug mode (`/gli debug`) with tagged chat output
- Extensible slash commands: one Lua file per command
- Tooltip API: line providers, raw handlers, one divider per tooltip, icons in lines, secret-value safe
- Uniform options page for extensions (`RegisterAddonOptions`, optional tabs)
- Modifier key option for extensions (`ModifiersHeld`, `BuildModifierOptions`)
- Addon icon (`Media/Icon.tga`) shown in the addon list
- `X-Glimpse-MinVersion` check for extensions
