-- The critical-capture whistle: a short rising chip-tone sweep, authored
-- in the ChipAsm note-event DSL (no asset file, no ROM bytes).  ChipAsm
-- is on the loader's supported-require list, so this needs no
-- permissions.  The assembler is the validator: a bad length or an
-- out-of-range frequency raises here, at load.
local ChipAsm = require("src.audio.ChipAsm")

return ChipAsm.sfx{
  channels = {
    { hw = 1, program = {
      { pitchSweep = { pace = 4, subtract = false, shift = 2 } },
      { squareNote = { len = 2, volume = 9, fade = 3, frequency = 0x740 } },
      { squareNote = { len = 3, volume = 10, fade = 3, frequency = 0x780 } },
      { squareNote = { len = 3, volume = 11, fade = 4, frequency = 0x7A0 } },
      { squareNote = { len = 6, volume = 12, fade = 5, frequency = 0x7C0 } },
    } },
  },
}
