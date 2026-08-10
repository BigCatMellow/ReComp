# Useful Dex

On the Pokédex species data page, press **A** to cycle between two info
pages:

1. **Data + Stats** — the sprite, kind, number, height/weight, types, base
   stats (HP/ATK/DEF/SPD/SPC), and **BST**, arranged like a compact dex card.
2. **Moves** — the full movelist: level-up learned moves first, then TM/HM
   moves by machine number.

**A** advances to the next page (back to Data + Stats after Moves), **B**
closes, and on the Moves page **UP/DOWN** pages when the list runs long. On
Data + Stats, **UP/DOWN** opens the previous/next species that has been seen.
The entry sprite is resolved as a battle sprite so installed sprite/animation
mods can provide their replacement.

Try it: START → POKéDEX → a species → data page → press A.

On the Pokédex list itself, press **SELECT** to cycle the list view:

1. **POKéDEX** — the standard numbered list (all 151 slots).
2. **POKéDEX A-Z** — only seen/owned species, sorted by name, dex numbers kept.
3. **POKéDEX CAUGHT** — only the species you own, in dex order.

The cursor stays on the same species where it survives the switch; the
SEEN/OWN footer counts are the full dex totals in every view. UP on the
first row and DOWN on the last wrap around to the other end, in every view.

## What it does

- Registers a replacement for the `DexEntryMenu` screen; its combined data
  and base-stat page follows the compact dex-card layout, and a broken mod
  screen degrades to the builtin automatically.
- Registers a replacement for the `PokedexMenu` screen that rebuilds the
  list in place on SELECT; the side menu (DATA/CRY/AREA/QUIT) is untouched.
- Learned moves come from the species' `learnset`, deduped, in ROM order.
- TM/HM moves come from the species' `tmhm` list, mapped to machine numbers
  through the items registry, sorted TM01..TM50 then HM01..HM05.
- Evolution labels come from the merged `evolution_methods` registry's
  `describe()`, so mod-added evolution methods display too.

## Notes

- The pages are species data, so they show even before you own the mon
  (the height/weight/text block still respects ownership like vanilla).
- A species with no evolution skips that section; a mon with no machines
  shows the learned section only.
- Moves paginate 10 rows per page with a `PAGE n/m` footer.
