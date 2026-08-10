# Pokémon Red Voice Acting

An unofficial voice-acting mod for **gen1recomp** that adds recorded dialogue while preserving Pokémon Red's original text, choices, battles, movement sequences, healing routines, shop logic, and story progression.

## Version

**1.17.10** — 198 registered voice clips.

## Current coverage

- Professor Oak's introduction, naming sequence, and opening transition
- Pallet Town, Oak's Laboratory, Route 1, and the Pokédex handover
- Viridian City outdoor NPCs and accessible interiors
- Viridian Poké Mart and Pokémon Center interactions
- First Route 22 rival encounter pre-battle dialogue
- Viridian Forest, including trainers and both gatehouses
- Pewter City outdoor NPCs

Coverage is still expanding. Unrecorded areas continue to use the original text normally.

## Features

- Original dialogue flow and callbacks are retained
- Yes/No choices remain functional
- Trainer approach, battle, defeat, and post-battle states are preserved
- Original healing, shop, item-gift, and escort sequences are retained
- Persistent in-game voice volume control from 0 to 10
- Voice audio is supplied as mono 44.1 kHz OGG files

## Installation

1. Install a compatible build of gen1recomp.
2. Open the game's Mods screen or mod directory.
3. Add `pokemon_red_voice_acting-1.17.10.zip` without extracting it, unless your installation method specifically requires an extracted mod folder.
4. Enable **Pokémon Red Voice Acting** and restart the game.

## Upgrading from prototype builds

Earlier test versions used the temporary manifest ID `oak_intro_voice_part1`. This public package uses the permanent ID `pokemon_red_voice_acting`.

Remove or disable the old prototype before installing this package. Keeping both enabled can load duplicate dialogue hooks and play clips more than once.

## Known limitations

- Dialogue containing dynamic player or rival names may show the variable text while voicing only the fixed wording.
- Dynamic Poké Mart item names and prices remain unvoiced.
- The project does not yet cover the entire game.
- This mod uses the `engine_internals` permission because several original dialogue paths are created directly by internal UI and battle systems.

## Automatic updates

This package identifies its release repository as:

```text
1-Camp0-1/Gen1recomp-VoiceActingMod
```

Future release assets should use the filename pattern `pokemon_red_voice_acting-<version>.zip`.

## Disclaimer

This is an unofficial fan-made mod for gen1recomp. It is not affiliated with or endorsed by Nintendo, Game Freak, The Pokémon Company, or the gen1recomp maintainers. No Pokémon ROM is included.
