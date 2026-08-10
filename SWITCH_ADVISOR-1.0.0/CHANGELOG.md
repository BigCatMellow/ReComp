# Changelog

All notable changes to this mod are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this mod adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-03

### Added

- **Party grades.** The battle party menu prints a one-letter grade
  (A, B, D or E) beside every living party member, scored against the
  types of the foe that is on the field right now. An average matchup
  prints nothing, so the screen stays vanilla until there is something
  worth saying.
- **Danger flag.** A mon the foe's own types hit super effectively also
  gets a `!` next to its grade. Its own toggle, on by default.
- **Skip nickname.** A caught POKeMON goes straight into the party or the
  box, with no "Do you want to give a nickname?" prompt. The PC's rename
  screen is untouched, so renaming later still works.
- Three toggles in the mod's options pane - `PARTY GRADES`, `DANGER FLAG`
  and `SKIP NICKNAME` - all on by default, all read per call, so flipping
  one takes effect without leaving the battle.
- `tests/switch_advisor_test.lua`, a ROM-free suite that loads the mod
  through the real headless loader and asserts both stated effects: the
  grade for a hand-built party against a hand-built foe, and the
  self-popping stand-in that replaces the nickname prompt. Run it from a
  checkout of the engine with
  `luajit mods/SWITCH_ADVISOR/tests/switch_advisor_test.lua`. The suite is
  excluded from the packaged mod by `.modkitignore`.
