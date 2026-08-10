# Changelog

## [1.4.0] - 2026-08-05

### Changed

- Renamed the mod from "Battle Move Info" to "Useful Move Info" (mod id
  `battle_move_info` -> `useful_move_info`); the repo is now
  `ShaneMcGovernIE/useful-move-info` (the old link redirects).

## [1.3.0] - 2026-08-05

### Added

- Type-effectiveness readout: for damaging moves the info box now appends a
  line against the foe's current types (SUPER EFFECTIVE / NOT VERY
  EFFECTIVE / NO EFFECT / NEUTRAL with the x multiplier), resolved through
  the engine's TypeChart. Status and fixed-damage moves (power 0) skip it.
- The same Start/Q shortcut works on the "Which move should be forgotten?"
  list when a Pokémon learns a new move: it inspects the highlighted
  current move, and a dedicated NEW MOVE row (before CANCEL) lets you read
  the move being learned before deciding what to forget.

## [1.2.1] - 2026-08-05

### Fixed

- The Q shortcut no longer dies for the whole session after focus loss,
  minimize/resume or a soft reset while the key was held or the info box
  was open: the held latch and open box now clear whenever the engine
  resets input state (`Input:reset`).
- The info box can no longer strand its open flag if the box push itself
  throws (pcall guard).

### Changed

- The boot closure was split into named `installInputWrappers` /
  `installBattleWrapper` functions; tests lock in the reset behaviour.

## [1.2.0] - 2026-08-03

### Changed

- The controller shortcut moved from the L shoulder button to Start.
  Start is a Game Boy button, but the battle's move-select phase never
  reads it, so the press is free to steal. The keyboard shortcut stays Q.

## [1.1.2] - 2026-08-01

### Fixed

- Pressing Q or L while the info box is showing no longer queues a second
  loop: presses while the box is open are dropped (the battle is frozen, so
  a queued edge would have reopened the box the moment it closed).

## [1.1.1] - 2026-08-01

### Fixed

- The info box no longer flows through every line on its own. Lines are
  ContText now, so each one waits for an A/B press (name, type, power,
  accuracy, effect) before the next scrolls in.

## [1.1.0] - 2026-08-01

### Added

- Q is the keyboard default for opening the info box on desktop, alongside
  the L shoulder button. Auto-repeat while held is latched so the box does
  not instantly reopen after closing.

## [1.0.0] - 2026-08-01

### Added

- L (left shoulder) on a highlighted battle move opens an info box with the
  move's type, power, accuracy and effect description.
