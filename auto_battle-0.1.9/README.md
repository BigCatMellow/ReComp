# Auto Battle

An **Auto Battle** mod for the [Gen1Recomp](https://gen1recomp.com) (LÖVE-based
Pokémon Gen 1 recompilation). When enabled, your move is chosen for you each turn
instead of the FIGHT menu opening — with an on-screen badge so you always know
it's active.

## What it does

- **Auto-picks your move.** Each turn it scores every usable move by
  `power × type-effectiveness × STAB` against the current foe and uses the best
  one. When nothing lands effectively (only status moves, or the foe is immune),
  it falls back to the game's own NPC move picker.
- **Handles the awkward cases** the same way the engine does: forced multi-turn
  moves (recharge / thrash / trap / Bide), and Struggle when you're out of PP.
- **Skip dialogs (optional).** Fast-forwards the battle text ("… appeared!",
  "… fainted!", status messages) so turns fly by.
- **Never hijacks a real choice.** Skip only advances plain battle text — it will
  not auto-confirm YES/NO prompts, move-learning, evolution, or the party/bag
  menus, so you stay in control of switching, items, running, and catching.
- **On-screen badges.** Small `AUTO` / `SKIP` tags in the top-right corner show
  what's on, plus the name of the move it just used.

## Controls

While Auto Battle is on, the game briefly waits before committing your move (the
**Takeover Window**). Nudge the D-pad during that window to open the menu
yourself for that turn — switch a Pokémon, use an item, run, or throw a ball.

## Options

Configure in the launcher's mod options:

| Option | Values | Default | Notes |
|---|---|---|---|
| `AUTO BATTLE` | ON / OFF | OFF | Master toggle for auto move selection. |
| `TAKEOVER WINDOW` | INSTANT / FAST / RELAXED | FAST | How long it waits before auto-committing (0s / 0.35s / 0.9s). Longer = easier to grab manual control. |
| `SKIP DIALOGS` | ON / OFF | OFF | Auto-advance battle text boxes. |
| `HEAL ITEMS` | ON / OFF | OFF | Use a Potion when the active Pokémon drops below the threshold. Picks the smallest potion that covers the missing HP. |
| `HEAL BELOW` | 1/2 HP / 1/4 HP | 1/2 HP | HP threshold that triggers a heal. |
| `CURE STATUS` | ON / OFF | OFF | Use a status-cure item (Antidote, Full Heal, …) when the active Pokémon is statused. |
| `AUTO CATCH` | ON / OFF | OFF | In wild battles, try to catch Pokémon you haven't registered yet. |
| `SWITCH MATCHUP` | ON / OFF | OFF | Switch to a benched Pokémon with a clearly better type matchup. |
| `USE BUFF/DEBUFF` | ON / OFF | OFF | Set up a stat move (Swords Dance, Growl, …) when it's safe and worthwhile. |
| `BADGE SIZE` | 1X / 2X | 1X | On-screen size of the AUTO/SKIP badges. |

Healing and curing spend a turn (the foe gets a free move, exactly like using
an item from the bag) and consume the item from your bag. Both are OFF by
default so nothing is spent unless you opt in.

## Auto Catch

When `AUTO CATCH` is on, in **wild** battles against a Pokémon that isn't in your
Pokédex yet (and only if you have a Poké/Great/Ultra Ball), it will:

1. **Put it to sleep or paralyse it** first, if you have a move for it — the
   biggest boost to the catch rate.
2. **Weaken it toward half HP** using your *weakest* move — but only when a
   forced-crit damage estimate proves the hit can't KO it. If nothing is
   provably safe, it skips straight to throwing rather than risk the kill.
3. **Throw a ball** (cheapest first), repeating until it's caught or you run out.

It never throws a **Master Ball** or **Safari Ball**, and it won't touch trainer
battles or Pokémon you already own. Still OFF by default — it spends your balls.

## Switch Matchup

When `SWITCH MATCHUP` is on, before attacking it checks whether a benched
Pokémon has a clearly better type matchup against the current foe. It scores
both directions with the **real movesets** — how hard each candidate hits the
foe, and how hard the foe's own moves hit the candidate — and only switches when:

- a benched Pokémon beats the active one's matchup by a clear margin,
- that Pokémon **won't** take a super-effective hit on the way in (switching
  always gives the foe a free move), and
- it hasn't already switched against that same foe (no switch-loops).

If your active Pokémon is already super-effective and safe, it stays put.

## Buff / Debuff

When `USE BUFF/DEBUFF` is on, it will spend a turn on a stat move (raising your
own attack/defense/etc., or lowering the foe's) — but only when it's clearly
safe and worth it:

- you can damage the foe but **can't** already KO it in one hit,
- the foe is still healthy (above ~60% HP), and
- your Pokémon **survives the foe's worst hit** (a forced-crit estimate).

It prefers an offensive buff matching how it attacks (physical → Attack,
special → Special), and stops once the stat reaches +/- 2 so it never sets up
forever.

**Tip:** for the fastest battles, pair `AUTO BATTLE` + `SKIP DIALOGS` with battle
animations turned off in the game options — animations and the HP-bar drain are
timed, not text you can skip.

## Install

Launcher → **MODS** → **Import mod .zip** → pick `auto_battle-<version>.zip`, then
enable it. You supply your own ROM; nothing ROM-derived is included here.

## How it works

The mod hooks the per-frame `battle.overlay` draw event. On the menu phase it
picks a move and commits it straight through the engine's turn resolver (no fake
button presses). "Skip dialogs" taps the advance button through the scripted-input
API only while the battle itself owns the screen, which is what keeps pushed
menus and prompts safe.

## License

MIT — see [LICENSE](LICENSE).
