# Changelog

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
