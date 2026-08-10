# Switch Advisor

When you open the party menu mid-battle, every living POKeMON gets a
one-letter grade (**A**, **B**, **D** or **E**) against the foe standing on
the field, and caught POKeMON skip the nickname prompt on their way into the
party.

**By allanrmartins.** Two seams that kept getting re-typed into a private
QoL pack until they were worth publishing on their own.

## Try it

```sh
python3 tools/modkit.py validate mods/SWITCH_ADVISOR --base fixture
python3 tools/modkit.py lint mods/SWITCH_ADVISOR
luajit mods/SWITCH_ADVISOR/tests/switch_advisor_test.lua
```

Then enable it (`SWITCH_ADVISOR = true` under `mods` in `options.lua`, or
the F10 manager), start a wild battle, and press **PKMN**: the grades are in
the empty column between each mon's icon and its HP bar. Throw a ball and
the caught mon lands in the party with no nickname prompt.

## What it does

### Party grades

The grade is a two-part type-chart score, computed against the foe's
**current** types (so it follows a Transform or a Conversion):

| half | reads | scores |
|---|---|---|
| offence | the best **damaging** move the mon carries | `+3` at 4x, `+2` at 2x, `0` neutral, `-2` resisted, `-3` immune |
| defence | the foe's **own types**, as STAB | `-3` at 4x, `-2` at 2x, `0` neutral, `+2` resisted, `+3` immune |

The two add up, and the total becomes a letter: `A` at `>=3`, `B` at `>=2`,
`D` at `<=-2`, `E` at `<=-4`. There is no `C` on purpose - an average
matchup prints **nothing**, so the screen is byte-for-byte vanilla until
there is something worth saying.

With `DANGER FLAG` on, a mon the foe's types hit for 2x or better also gets
a `!`, so `D!` and a bare `D` read differently at a glance.

Three things it deliberately does not do:

- **It never reads the foe's move list.** The game knows those moves, you do
  not, and a marker that leaks them is a cheat rather than a convenience.
  STAB off the foe's visible types is the same guess a human makes.
- **It never grades a fainted mon.** The row already says `FNT`, and
  `ChooseNextMon` would just re-prompt.
- **It never touches the party menu outside a battle.** The START menu, the
  bag's item and TM pickers and the link-battle copies all leave
  `opts.battle` nil, so there is no foe to compare against and the screen
  stays vanilla.

### Skip nickname

The capture sequence queues the prompt as a UI factory, and the queue pushes
whatever the factory returns - so returning nothing would strand the battle
waiting on a UI that never appeared. Instead the prompt is replaced by a
state that pops itself on its first update: no draw, not opaque, so the
battle underneath keeps painting and the single frame it exists is
invisible.

The PC's rename screen is untouched. Renaming later still works.

## Options

| option | default | what it does |
|---|---|---|
| `PARTY GRADES` | on | the letter grades on the battle party menu |
| `DANGER FLAG` | on | the extra `!` on mons the foe hits super effectively |
| `SKIP NICKNAME` | on | captures skip the nickname prompt |

All three are read per call, so flipping one in the manager's options pane
takes effect immediately - no restart, not even leaving the battle.

## Notes for the curious

- **Letters, not arrows.** The Gen 1 font has no `<` and no `>` glyph. Its
  only two triangles are already the party cursor and the swap arrow, so
  painting either one beside six rows would read as six cursors, and
  `Font.encode` turns anything else into a space plus a log line. A letter
  needs no colour, survives a monochrome palette, is one glyph wide, and
  ranks the six candidates - which is the decision the screen exists for.
- **Two glyphs, and never more.** `x=24..40` of a row's HP line is the only
  space `PartyMenu:draw` leaves empty. The marker is hard-capped there, so
  it cannot cover a nickname, a level, a status or a bar.
- **It wraps `PartyMenu.draw`, not the `battle.overlay` hook.** The overlay
  hook runs after the engine has torn the palette step down, and text drawn
  from there comes out in the wrong shades no matter what `setColor` says.
  Inside the screen's own draw pass the marker restates the exact colour
  `PartyMenu:draw` uses for its own glyphs, and restores the white the
  original left behind.
- **The wraps are flagged.** A hot reload re-runs the entry chunk; the
  guard flags mean it cannot stack a second wrapper on either seam.

## Compatibility

`api 2`, `engine_internals`. It wraps `src.ui.PartyMenu.draw` and
`src.battle.BattleState.askNicknameUI`; if either is missing the mod logs
what to do about it and leaves the game alone rather than failing the load.

Another mod that replaces the capture sequence wholesale should load
*before* this one, so the wrap lands on top of it.

## Credits

- pret/pokered - `party_menu.asm` `RedrawPartyMenu_`, the row layout the
  marker column was measured out of.
