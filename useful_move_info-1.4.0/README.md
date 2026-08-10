# Useful Move Info

In battle, press **Start** (controller) — or **Q** on a keyboard — while a
move is highlighted to open an info box with the move's **type**,
**power**, **accuracy** and **effect**. Damaging moves also get a
**type-effectiveness** line against the foe's current types (SUPER
EFFECTIVE / NOT VERY EFFECTIVE / NO EFFECT, with the multiplier). Each line
(name, type, power, accuracy, effect) waits for an **A/B** press before
the next scrolls in, like a normal Gen 1 ContText box. A/B closes it, and
the battle resumes.

The same shortcut works when a Pokémon learns a new move: on the "Which
move should be forgotten?" list, Start/Q inspects the highlighted current
move, and a dedicated **NEW MOVE** row (before CANCEL) shows what the move
being learned does before you decide what to drop.

Try it: start a battle, open FIGHT, highlight a move, press Start (or Q).

## What it does

- Watches `Input.gamepadpressed` for the raw `start` button and
  `Input.keypressed` for `q`. Start is a Game Boy button, but the battle's
  move-select phase never reads it, so the press is free to steal;
  auto-repeat while Q is held is latched, so the box never instantly
  reopens after closing.
- On a press edge, a wrapped `BattleState.update` checks whether the battle
  is on the move-select phase and opens a TextBox with the highlighted
  move's details. The box pauses the battle like any other text box.
- While the box is showing, further Q/Start presses are dropped, so a
  press made while reading the box can never reopen it after it closes.
- The type-effectiveness line is resolved through the engine's `TypeChart`
  (so mod-added type charts and matchups display correctly) and reads the
  foe's live `curTypes` (Transform-aware). Status and fixed-damage moves
  (power 0) never read the type chart, so they skip the line.
- On the learn-a-new-move screen the mod registers a `MoveLearnMenu`
  screen override: the forget list gains a NEW MOVE row (inspect-only,
  never forgettable), and Start/Q opens the same info box for any row.
- Effect descriptions are curated for all 87 vanilla effect ids (chances
  included, e.g. "10% burn chance"); unknown or mod-added effect ids fall
  back to a readable version of the id.

## Notes

- Start is controller-only; Q is the desktop keyboard default. There is
  no rebind for either (the bindings menu covers Game Boy buttons only).
- Works in the classic and widescreen move layouts alike (the highlighted
  slot is read from `moveIndex`, which both layouts update).
