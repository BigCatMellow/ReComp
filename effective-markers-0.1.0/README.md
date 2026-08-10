# Effective Markers

Draws a small icon in the FIGHT menu's TYPE/PP info panel for the currently
selected move: green for super effective, red for not very effective, gray
for no effect, nothing for neutral (matching how the games themselves only
ever announce a matchup that isn't neutral).

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/72d8f353-a179-4a10-99a3-046b70a94431" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/41a7c22c-6afd-4a2b-9a63-3c1bf598f26e" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/b0ced7ab-c2a5-4725-a142-a5922e7a0b1d" />
<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/65fbae8d-9637-4582-b1cb-e1526c26ac55" />

The icon is the engine's own font art, not a hand-drawn shape.

## Known incompatibility

Not currently compatible with **dramatic-shape** or
**BATTLE_ART_VOXEL_FORK**: both monkey-patch `Renderer:endFrame` (battle-exit
veil, day/night tint) and discard its return value on some code paths,
so `render.hud` hooks -- this mod included -- receive a `nil` viewport and
the marker silently never draws. 

Fixed in BATTLE_ART_VOXEL_FORK's
`lib/BattleExit.lua` and `lib/DayTint.lua` locally; dramatic-shape has the
same bug unpatched. Disable either mod, or apply the same fix (capture and
return `inner(...)`'s result instead of discarding it), before expecting
markers to appear.

See https://github.com/absol89/DramaticShapeVoxelMod/pull/3 for the fix upstream.

It sits in blank space inside the TYPE/PP panel rather than next to the move
name, so it never has to compete with long move names:

- classic layout: right end of the "TYPE/" row (`x=72,y=72`) -- five
  characters of label in a 72px-wide row leaves room to spare
- widescreen layout: the unused row between PP and TYPE in the details
  panel (`x=288,y=120`)
