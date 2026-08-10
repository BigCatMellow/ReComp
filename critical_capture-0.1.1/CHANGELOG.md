# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-08-05

### Changed

- The ball-tier tables (anim registration, index map, toss-anim map, sub-id
  derivation) were deduplicated into one `BALL_TIERS` source of truth.
- The catch-rate wrap now resolves the thrown ball through the engine's
  `battle:ballDef`, so critical-capture odds are scored against the same
  record the vanilla roll uses (a ball present only in the engine's
  `Catching.BALLS` used to be scored as a plain POKE BALL).

## [0.1.0] - 2026-08-03

### Added

- Critical captures: a thrown ball can go critical, whistle, pause and shudder mid-air, then shake once with far better odds.
- Gen 5's critical-capture model (`c = floor(a * multiplier / 6)`), with `a` as the exact Gen 1 two-roll catch probability scaled to 0-255.
- Gen 5's multiplier table rescaled to the 151-species dex and split into a quarter-step ladder (each band ~15 species): 0-15 caught = 0x, 16-30 = 0.25x, 31-45 = 0.5x, 46-60 = 0.75x, 61-75 = 1x, 76-90 = 1.25x, 91-105 = 1.5x, 106-120 = 1.75x, 121-135 = 2x, 136-150 = 2.25x, 151 (complete dex) = 2.5x.
- The decisive single shake succeeds with the normal catch chance raised to 1/root -- cube root in GEN 5 mode, fourth root in GEN 6 mode.
- OPTIONS > CRIT CAPTURE row cycling OFF / GEN 5 / GEN 6; GEN 5 is the default.
- An authored ChipAsm whistle sfx (no asset files) and a crit toss arc per ball tier (the vanilla arc with its apex frames replayed for the mid-air shudder).
- Master Balls never roll critical; the old man's catch tutorial is untouched.
