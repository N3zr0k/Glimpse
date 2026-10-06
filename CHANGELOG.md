# Changelog

## [Unreleased]

### Added
- "Credits" section on every options page, like TomTom: divider, author from the TOC and optional contributors, image credits and thanks (`RegisterAddonOptions(..., credits)`); every options page now has tabs and "Credits" is always the last one (pages without tabs get an "Options" tab); author no longer repeated in the overview
- Module `Locations` for all extensions: map names and sizes, continents, player position and instance, distances in yards, coordinates as text and waypoints (TomTom if installed, otherwise the game marker)
- Distance unit for all extensions: option in the General tab (automatic by client language, yards or metres), `FormatDistance(yards)` and `GetDistanceUnit()`; from one mile (1760 yd) or one kilometre on the larger unit

### Changed
- Options pages with tabs show the version in small grey text below the whole frame, like pages without tabs, instead of above the tabs (falls back to the bottom of each tab if the panel cannot be adjusted)

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
