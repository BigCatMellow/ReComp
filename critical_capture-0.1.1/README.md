# Critical Capture

Gen 5's critical capture for the Gen 1 recomp: a thrown ball can go critical -- a rising whistle, a mid-air pause and shudder, then a single decisive shake with far better odds than the vanilla three-wobble check. The chance scales with your Pokedex, rescaled from the modern 600+ species to Gen 1's 151.

## How to try it

1. Install the mod and enable it in the mod manager (MODS row in OPTIONS).
2. Throw balls at wild Pokemon. Early on, almost nothing goes critical; the more species you have registered as owned, the more often it happens.
3. A critical capture whistles, the ball pauses and shudders at the top of its arc, and it shakes exactly once before the Pokemon is caught -- or breaks free.
4. OPTIONS > CRIT CAPTURE cycles OFF / GEN 5 / GEN 6. GEN 5 uses the cube root of the catch chance for the decisive shake; GEN 6 uses the fourth root (critical captures are more effective, exactly as in the modern games). OFF restores vanilla catching exactly.

## How it works

- The chance is Bulbapedia's Gen 5 model: `c = floor(a * multiplier / 6)`, rolled as `rng(0,255) < c`, where `a` is the modified catch rate on a 0-255 scale. Since Gen 1's two-roll algorithm never computes an `a`, the mod uses the exact probability of the throw (the rate roll and the HP roll combined) scaled to 0-255 -- so the critical chance tracks the real odds of the ball.
- The multiplier ladder is Gen 5's, rescaled to the 151-species dex and split into quarter steps (each band is ~15 species):

  | Species caught | Multiplier |
  |---|---|
  | 151 (complete dex) | 2.5 |
  | 136-150 | 2.25 |
  | 121-135 | 2 |
  | 106-120 | 1.75 |
  | 91-105 | 1.5 |
  | 76-90 | 1.25 |
  | 61-75 | 1 |
  | 46-60 | 0.75 |
  | 31-45 | 0.5 |
  | 16-30 | 0.25 |
  | 0-15 | 0 |
- A critical capture replaces the vanilla outcome with one decisive shake: it succeeds with the normal catch chance raised to 1/root (cube root in Gen 5, fourth root in Gen 6) -- always more likely than the vanilla roll, never less.
- Master Balls never roll critical; Safari throws do. The old man's scripted catch tutorial is untouched.
- The whistle is an authored ChipAsm chip program (no asset files); the mid-air shudder is the ball's own toss arc with its apex frames replayed.

## Layout

- `manifest.json` -- identity, version range, load order
- `main.lua` -- the entry chunk; the OPTIONS row, the catch.rate wrap, the toss anim swap
- `sfx.lua` -- the whistle, authored in the ChipAsm DSL
- `tests/critical_capture_test.lua` -- headless coverage of the rolls, tiers and hook wiring

## Loop

1. `POKEPORT_DEV=1 love .` once, leave it running
2. edit, press F5 to hot-reload, backtick for the dev console
3. `python3 tools/modkit.py validate mods/critical_capture` before sharing
4. `python3 tools/modkit.py pack mods/critical_capture` to ship
