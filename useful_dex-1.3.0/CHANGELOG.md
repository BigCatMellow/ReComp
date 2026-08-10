# Changelog

## [1.3.0] - 2026-08-07

### Added

- Combined the Dex data and stats information into one compact page.
- Added animated Crystal battle sprites to Dex pages when the Crystal sprite
  mod is installed.
- Added UP/DOWN navigation between seen Pokémon, including cries.
- Added coloured STAB indicators beside moves that match the Pokémon's type.
- Kept the sprite visible on the learnset page with a horizontal split layout.

### Fixed

- Improved learnset spacing and pagination so move names no longer overlap.

## [1.2.3] - 2026-08-06

### Changed

- Internal refactor of the dex screens: pagination (`pageRows` /
  `stepPage`), the A-cycle ring table and the dex list's cursor-restore
  scan were extracted into dedicated helpers. No user-visible behavior
  changes.

## [1.2.2] - 2026-08-05

### Fixed

- The dex list footer no longer wraps onto the last row at three-digit
  counts: it's now a fixed-width `SEEN %3d  OWN %3d` (17 glyphs), matching
  the engine's own footer fix.
- SELECT can no longer strand the player by switching to an empty
  alphabetical/caught view (ListMenu skips selection callbacks on an empty
  list, so only A/B, which close the whole dex, used to escape).
- Switching views no longer flashes the list head for one frame: scroll is
  clamped to the restored cursor before the first draw.

## [1.2.1] - 2026-08-02

### Added

- The Pokédex list wraps around: UP on the first row and DOWN on the last
  row loop to the other end, in every view.

## [1.2.0] - 2026-08-02

### Added

- SELECT on the Pokédex list cycles the view: standard numbered list, then
  alphabetical (seen/owned only, dex numbers kept), then caught only.
  The cursor stays on the same species where it survives the switch.

## [1.1.0] - 2026-08-01

### Added

- New page between the data page and the movelist: base stats (HP/ATK/DEF/
  SPD/SPC), their BST sum, and the species' evolutions with level / item /
  trade method and target name. A now cycles data -> stats -> moves -> data.

## [1.0.0] - 2026-08-01

### Added

- Pokédex data page opens a movelist page on A: learned moves first, then
  TM/HM moves by machine number, paginated with UP/DOWN.
