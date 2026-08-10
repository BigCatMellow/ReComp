# Definitive Gen 1

**Definitive Gen 1** is a cohesive modernization of Pokémon Red/Blue/Yellow for Gen1Recomp.

The target is not “modern Pokémon in a Game Boy skin.” The target is:

> **Gen 1 as if its designers had 25+ years of hindsight.**

Keep Kanto, the original progression, the compact battle system, the sprite-era identity, and the game's directness. Remove friction, fix mechanics that aged poorly, and communicate information more clearly.

## Design rules

1. **Clarity before decoration.** UI should be sparse and immediately readable.
2. **Color is language.** Type colors should mean the same thing in battle, move lists, summaries, learning screens, and the Pokédex.
3. **No unnecessary boxes.** Use spacing, color, alignment, icons, and motion before adding another panel.
4. **Preserve Gen 1 identity.** Do not add later-generation systems merely because they exist.
5. **Existing mods are baselines.** Study what worked, then improve architecture, compatibility, and UX where possible.
6. **Prefer public Gen1Recomp APIs.** Private-engine access is isolated in `lib/engine_bridge.lua`.
7. **Merged-world safe.** Do not assume exactly 151 Pokémon or a fixed vanilla move/item set.
8. **Disabled means vanilla.** Features should delegate/fall back cleanly whenever possible.
9. **One coherent mod.** Shared options, colors, helpers, and UI conventions replace a stack of unrelated QoL mods.

## Current 0.1.0 features

### Modern Physical/Special Split

Uses Gen1Recomp's existing per-move `category` support. Only moves whose later category differs from their Gen 1 type category are patched. No damage-formula monkey-patch is required.

### Clean Type-Colored Damage Numbers

- no background box
- no border
- move damage uses the move's type color
- one-pixel shadow for readability
- status/recoil/healing use stable semantic colors
- supports classic and Gen1Recomp's built-in wide battle layout
- uses the public `battle.damage_dealt` event for move damage
- avoids the original Damage Numbers mod's process-wide `Status.residual` patch

## Planned feature groups

- richer but minimal battle move information
- effectiveness indicators
- reusable TMs
- field moves/HMs without moveslot punishment
- running and quick actions
- repel continuation
- cleaner bag/pockets/sorting
- modernized boxes
- better move-learning comparison
- move relearner
- trade-evolution alternatives
- catch EXP and optional party EXP
- selected modern/fixed battle rules
- improved trainer AI/rematches
- cleaner Pokémon summary and Pokédex information
- followers
- final UI/UX consistency and accessibility pass

## Target

- Gen1Recomp 0.1.75+
- Mod API 2

The project is developed against the exact 0.1.75 release behavior first; newer `dev` APIs are only used when feature-detected or when the minimum supported engine is intentionally raised.
