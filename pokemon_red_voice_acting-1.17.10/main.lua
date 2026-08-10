return function(mod)
  ---------------------------------------------------------------------------
  -- POKÉMON RED VOICE ACTING v1.17.10
  --
  -- Voices the complete opening Professor Oak sequence while preserving:
  --   * Oak, Pokémon, player and rival portraits
  --   * the Nidorino reveal and cry
  --   * the original player naming screen
  --   * the original rival naming screen
  --   * the original shrink-away animation
  ---------------------------------------------------------------------------

  local Sound = require("src.core.Sound")

  ---------------------------------------------------------------------------
  -- PERSISTENT VOICE VOLUME
  --
  -- Added directly to the game's main Options menu through
  -- ui.options.rows. 0 = mute, 10 = full normalized volume.
  ---------------------------------------------------------------------------

  local function clampVoiceLevel(value)
    value = tonumber(value) or 10
    return math.max(0, math.min(10, value))
  end

  local voiceLevel = 10

  -- Read the value stored by v1.11.1 and earlier. The option schema is no
  -- longer defined, so it does not render in the mod manager, but the loader
  -- still exposes an already-saved value through mod.options:get().
  local legacyVoiceLevel = clampVoiceLevel(
    mod.options:get("voice_volume")
  )

  local function gameOptions(game)
    local save = game and game.save
    if not save then
      return nil
    end

    save.options = save.options or {}
    return save.options
  end

  local function readVoiceLevel(game)
    local options = gameOptions(game)
    local stored = options and options.voiceVolume

    if stored == nil then
      stored = legacyVoiceLevel
      if options then
        options.voiceVolume = stored
      end
    end

    voiceLevel = clampVoiceLevel(stored)
    return voiceLevel
  end

  local function applyVoiceVolume(source)
    if source then
      pcall(source.setVolume, source, voiceLevel / 10)
    end
  end

  local VOICES = {
    HELLO = "VOICE_OAK_INTRO_001",
    WELCOME = "VOICE_OAK_INTRO_002",
    MY_NAME = "VOICE_OAK_INTRO_003",
    PROFESSOR = "VOICE_OAK_INTRO_004",
    WORLD = "VOICE_OAK_INTRO_005",
    PETS = "VOICE_OAK_INTRO_006",
    FIGHTS = "VOICE_OAK_INTRO_007",
    PROFESSION = "VOICE_OAK_INTRO_008",
    ASK_PLAYER_NAME = "VOICE_OAK_INTRO_009",
    INTRODUCE_RIVAL = "VOICE_OAK_INTRO_010",
    ASK_RIVAL_NAME = "VOICE_OAK_INTRO_011",
    LEGEND = "VOICE_OAK_INTRO_012",
    ADVENTURES = "VOICE_OAK_INTRO_013",

    MOM_LEAVE_HOME = "VOICE_MOM_REDS_HOUSE_001",
    MOM_TV = "VOICE_MOM_REDS_HOUSE_002",
    MOM_OAK_LOOKING = "VOICE_MOM_REDS_HOUSE_003",

    PALLET_GIRL_RAISING = "VOICE_PALLET_GIRL_001",
    PALLET_GIRL_PROTECTION = "VOICE_PALLET_GIRL_002",
    PALLET_MAN_TECHNOLOGY = "VOICE_PALLET_MAN_001",
    PALLET_MAN_PC_STORAGE = "VOICE_PALLET_MAN_002",

    OAKS_LAB_AIDE = "VOICE_OAKS_LAB_AIDE_001",
    OAKS_LAB_GIRL_AUTHORITY = "VOICE_OAKS_LAB_GIRL_001",
    OAKS_LAB_GIRL_REGARD = "VOICE_OAKS_LAB_GIRL_002",
    OAKS_LAB_RIVAL_GRAMPS_ABSENT = "VOICE_OAKS_LAB_RIVAL_001",

    DAISY_BROTHER_AT_LAB = "VOICE_DAISY_RIVALS_HOUSE_001",

    PALLET_OAK_HEY_WAIT = "VOICE_PALLET_OAK_001",
    PALLET_OAK_UNSAFE = "VOICE_PALLET_OAK_002",
    PALLET_OAK_PROTECTION = "VOICE_PALLET_OAK_003",
    PALLET_OAK_COME_WITH_ME = "VOICE_PALLET_OAK_004",

    LAB_RIVAL_FED_UP = "VOICE_OAKS_LAB_PRESTARTER_001",
    LAB_OAK_LET_ME_THINK = "VOICE_OAKS_LAB_PRESTARTER_002",
    LAB_OAK_TOLD_TO_COME = "VOICE_OAKS_LAB_PRESTARTER_003",
    LAB_OAK_HAHA = "VOICE_OAKS_LAB_PRESTARTER_004",
    LAB_OAK_INSIDE_BALLS = "VOICE_OAKS_LAB_PRESTARTER_005",
    LAB_OAK_SERIOUS_TRAINER = "VOICE_OAKS_LAB_PRESTARTER_006",
    LAB_OAK_ONLY_THREE = "VOICE_OAKS_LAB_PRESTARTER_007",
    LAB_OAK_BE_PATIENT = "VOICE_OAKS_LAB_PRESTARTER_008",
    LAB_OAK_THREE_POKEMON = "VOICE_OAKS_LAB_PRESTARTER_009",
    LAB_RIVAL_WHAT_ABOUT_ME = "VOICE_OAKS_LAB_PRESTARTER_010",

    LAB_OAK_CONFIRM_CHARMANDER = "VOICE_OAKS_LAB_STARTER_001",
    LAB_OAK_CONFIRM_SQUIRTLE = "VOICE_OAKS_LAB_STARTER_002",
    LAB_OAK_CONFIRM_BULBASAUR = "VOICE_OAKS_LAB_STARTER_003",

    LAB_OAK_WHICH_POKEMON = "VOICE_OAKS_LAB_PRESTARTER_011",
    LAB_OAK_DONT_GO_AWAY = "VOICE_OAKS_LAB_PRESTARTER_012",
    LAB_RIVAL_GO_AHEAD = "VOICE_OAKS_LAB_PRESTARTER_013",

    LAB_RIVAL_TAKE_THIS_ONE = "VOICE_OAKS_LAB_POSTCHOICE_001",
    LAB_RIVAL_LOOKS_STRONGER = "VOICE_OAKS_LAB_POSTCHOICE_002",
    LAB_OAK_CAN_FIGHT_WILD = "VOICE_OAKS_LAB_POSTCHOICE_003",

    LAB_RIVAL_BATTLE_WAIT = "VOICE_OAKS_LAB_BATTLE_001",
    LAB_RIVAL_BATTLE_CHECK = "VOICE_OAKS_LAB_BATTLE_002",
    LAB_RIVAL_BATTLE_CHALLENGE = "VOICE_OAKS_LAB_BATTLE_003",

    LAB_RIVAL_WIN_UNBELIEVABLE = "VOICE_OAKS_LAB_OUTCOME_001",
    LAB_RIVAL_WIN_WRONG_POKEMON = "VOICE_OAKS_LAB_OUTCOME_002",
    LAB_RIVAL_LOSS_GREAT = "VOICE_OAKS_LAB_OUTCOME_003",
    LAB_RIVAL_SHARED_TOUGHEN = "VOICE_OAKS_LAB_OUTCOME_004",
    LAB_RIVAL_SMELL_YA_LATER = "VOICE_OAKS_LAB_OUTCOME_005",

    LAB_OAK_RAISE_YOUNG = "VOICE_OAKS_LAB_POSTCHOICE_004",

    DAISY_GRANDPA_ERRAND = "VOICE_DAISY_RIVALS_HOUSE_002",
    DAISY_MAP_WILL_HELP = "VOICE_DAISY_RIVALS_HOUSE_003",
    DAISY_USE_TOWN_MAP = "VOICE_DAISY_RIVALS_HOUSE_004",

    MOM_QUICK_REST = "VOICE_MOM_REDS_HOUSE_004",
    MOM_LOOKING_GREAT = "VOICE_MOM_REDS_HOUSE_005",
    MOM_TAKE_CARE = "VOICE_MOM_REDS_HOUSE_006",

    DAISY_POKEMON_NEED_REST = "VOICE_DAISY_RIVALS_HOUSE_005",

    ROUTE1_MART_WORKER_INTRO = "VOICE_ROUTE1_MART_WORKER_001",
    ROUTE1_MART_WORKER_VISIT = "VOICE_ROUTE1_MART_WORKER_002",
    ROUTE1_MART_WORKER_SAMPLE = "VOICE_ROUTE1_MART_WORKER_003",
    ROUTE1_MART_WORKER_POKEBALLS = "VOICE_ROUTE1_MART_WORKER_004",

    ROUTE1_LEDGE_SEE = "VOICE_ROUTE1_LEDGE_YOUNGSTER_001",
    ROUTE1_LEDGE_JUMP = "VOICE_ROUTE1_LEDGE_YOUNGSTER_002",
    ROUTE1_LEDGE_QUICKER = "VOICE_ROUTE1_LEDGE_YOUNGSTER_003",

    ROUTE22_RIVAL1_HEY =
      "VOICE_ROUTE22_RIVAL1_001",
    ROUTE22_RIVAL1_POKEMON_LEAGUE =
      "VOICE_ROUTE22_RIVAL1_002",
    ROUTE22_RIVAL1_NO_BADGES =
      "VOICE_ROUTE22_RIVAL1_003",
    ROUTE22_RIVAL1_GUARD =
      "VOICE_ROUTE22_RIVAL1_004",
    ROUTE22_RIVAL1_STRONGER =
      "VOICE_ROUTE22_RIVAL1_005",

    VIRIDIAN_FOREST_SOUTH_GATE_GIRL_FOREST =
      "VOICE_VIRIDIAN_FOREST_SOUTH_GATE_GIRL_001",
    VIRIDIAN_FOREST_SOUTH_GATE_GIRL_MAZE =
      "VOICE_VIRIDIAN_FOREST_SOUTH_GATE_GIRL_002",
    VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_RATTATA =
      "VOICE_VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_001",
    VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_GOT_ONE =
      "VOICE_VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_002",

    VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_FORESTS_CAVES =
      "VOICE_VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_001",
    VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_LOOK_EVERYWHERE =
      "VOICE_VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_002",
    VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_ROADSIDE_BUSHES =
      "VOICE_VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_001",
    VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_SPECIAL_MOVE =
      "VOICE_VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_002",

    VIRIDIAN_FOREST_YOUNGSTER1_FRIENDS =
      "VOICE_VIRIDIAN_FOREST_YOUNGSTER1_001",
    VIRIDIAN_FOREST_YOUNGSTER1_POKEMON_FIGHTS =
      "VOICE_VIRIDIAN_FOREST_YOUNGSTER1_002",
    VIRIDIAN_FOREST_YOUNGSTER5_RAN_OUT_BALLS =
      "VOICE_VIRIDIAN_FOREST_YOUNGSTER5_001",
    VIRIDIAN_FOREST_YOUNGSTER5_CARRY_EXTRAS =
      "VOICE_VIRIDIAN_FOREST_YOUNGSTER5_002",

    VIRIDIAN_FOREST_BUG_CATCHER1_BATTLE =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER1_001",
    VIRIDIAN_FOREST_BUG_CATCHER1_DEFEAT =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER1_002",
    VIRIDIAN_FOREST_BUG_CATCHER1_AFTER =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER1_003",
    VIRIDIAN_FOREST_BUG_CATCHER2_BATTLE =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER2_001",
    VIRIDIAN_FOREST_BUG_CATCHER2_DEFEAT =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER2_002",
    VIRIDIAN_FOREST_BUG_CATCHER2_AFTER =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER2_003",
    VIRIDIAN_FOREST_BUG_CATCHER3_BATTLE =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER3_001",
    VIRIDIAN_FOREST_BUG_CATCHER3_DEFEAT =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER3_002",
    VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_GROUND =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER3_003",
    VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_DROPPED =
      "VOICE_VIRIDIAN_FOREST_BUG_CATCHER3_004",

    VIRIDIAN_MART_CAME_FROM_PALLET =
      "VOICE_VIRIDIAN_MART_CLERK_001",
    VIRIDIAN_MART_KNOW_OAK =
      "VOICE_VIRIDIAN_MART_CLERK_002",
    VIRIDIAN_MART_TAKE_ORDER =
      "VOICE_VIRIDIAN_MART_CLERK_003",
    VIRIDIAN_MART_SAY_HI =
      "VOICE_VIRIDIAN_MART_CLERK_004",
    VIRIDIAN_MART_BOUGHT_ITEM =
      "VOICE_VIRIDIAN_MART_CLERK_005",
    VIRIDIAN_MART_SOLD_ITEM =
      "VOICE_VIRIDIAN_MART_CLERK_006",
    VIRIDIAN_MART_GREETING =
      "VOICE_VIRIDIAN_MART_CLERK_007",
    VIRIDIAN_MART_TAKE_YOUR_TIME =
      "VOICE_VIRIDIAN_MART_CLERK_008",
    VIRIDIAN_MART_NOT_ENOUGH_MONEY =
      "VOICE_VIRIDIAN_MART_CLERK_009",
    VIRIDIAN_MART_BAG_FULL =
      "VOICE_VIRIDIAN_MART_CLERK_010",
    VIRIDIAN_MART_WHAT_TO_SELL =
      "VOICE_VIRIDIAN_MART_CLERK_011",
    VIRIDIAN_MART_NOTHING_TO_SELL =
      "VOICE_VIRIDIAN_MART_CLERK_012",
    VIRIDIAN_MART_CANT_PRICE =
      "VOICE_VIRIDIAN_MART_CLERK_013",
    VIRIDIAN_MART_ANYTHING_ELSE =
      "VOICE_VIRIDIAN_MART_CLERK_014",
    VIRIDIAN_MART_MANY_ANTIDOTES =
      "VOICE_VIRIDIAN_MART_YOUNGSTER_001",
    VIRIDIAN_MART_POTIONS_SOLD_OUT =
      "VOICE_VIRIDIAN_MART_COOLTRAINER_001",

    VIRIDIAN_CITY_POKEBALLS_AT_WAIST =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER1_001",
    VIRIDIAN_CITY_YOU_HAVE_POKEMON =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER1_002",
    VIRIDIAN_CITY_CARRY_USE_ANYWHERE =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER1_003",

    VIRIDIAN_CITY_CATERPILLAR_QUESTION =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER2_001",
    VIRIDIAN_CITY_CATERPIE_WEEDLE =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER2_002",
    VIRIDIAN_CITY_POISON_STING =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER2_003",
    VIRIDIAN_CITY_OK_THEN =
      "VOICE_VIRIDIAN_CITY_YOUNGSTER2_004",

    VIRIDIAN_CITY_GIRL_GRANDPA_MEAN =
      "VOICE_VIRIDIAN_CITY_GIRL_001",
    VIRIDIAN_CITY_GIRL_WINDING_TRAIL =
      "VOICE_VIRIDIAN_CITY_GIRL_002",
    VIRIDIAN_CITY_OLD_MAN_CANT_GO_THROUGH =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_SLEEPY_001",
    VIRIDIAN_CITY_OLD_MAN_PRIVATE_PROPERTY =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_SLEEPY_002",

    VIRIDIAN_CITY_OLD_MAN_HAD_COFFEE =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_001",
    VIRIDIAN_CITY_OLD_MAN_GO_THROUGH =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_002",
    VIRIDIAN_CITY_OLD_MAN_IN_HURRY =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_003",
    VIRIDIAN_CITY_OLD_MAN_TIME_IS_MONEY =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_004",
    VIRIDIAN_CITY_OLD_MAN_USING_POKEDEX =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_005",
    VIRIDIAN_CITY_OLD_MAN_POKEDEX_UPDATED =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_006",
    VIRIDIAN_CITY_OLD_MAN_DONT_KNOW_CATCH =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_007",
    VIRIDIAN_CITY_OLD_MAN_SHOW_HOW =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_008",
    VIRIDIAN_CITY_OLD_MAN_WEAKEN_TARGET =
      "VOICE_VIRIDIAN_CITY_OLD_MAN_009",

    VIRIDIAN_CITY_GYM_WATCHER_CLOSED =
      "VOICE_VIRIDIAN_CITY_GYM_WATCHER_001",
    VIRIDIAN_CITY_GYM_WATCHER_WONDER_LEADER =
      "VOICE_VIRIDIAN_CITY_GYM_WATCHER_002",
    VIRIDIAN_CITY_GYM_WATCHER_LEADER_RETURNED =
      "VOICE_VIRIDIAN_CITY_GYM_WATCHER_003",

    VIRIDIAN_CITY_FISHER_DOZED_OFF =
      "VOICE_VIRIDIAN_CITY_FISHER_001",
    VIRIDIAN_CITY_FISHER_DROWZEE_DREAM =
      "VOICE_VIRIDIAN_CITY_FISHER_002",
    VIRIDIAN_CITY_FISHER_HAVE_TM =
      "VOICE_VIRIDIAN_CITY_FISHER_003",
    VIRIDIAN_CITY_FISHER_DREAM_EATER =
      "VOICE_VIRIDIAN_CITY_FISHER_004",
    VIRIDIAN_CITY_FISHER_BAG_FULL =
      "VOICE_VIRIDIAN_CITY_FISHER_005",

    PEWTER_CITY_COOLTRAINER_M_SERIOUS =
      "VOICE_PEWTER_CITY_COOLTRAINER_M_001",
    PEWTER_CITY_COOLTRAINER_M_BROCK =
      "VOICE_PEWTER_CITY_COOLTRAINER_M_002",
    PEWTER_CITY_COOLTRAINER_F_CLEFAIRY =
      "VOICE_PEWTER_CITY_COOLTRAINER_F_001",
    PEWTER_CITY_COOLTRAINER_F_MOON_STONE =
      "VOICE_PEWTER_CITY_COOLTRAINER_F_002",

    PEWTER_CITY_SUPER_NERD1_MUSEUM =
      "VOICE_PEWTER_CITY_SUPER_NERD1_001",
    PEWTER_CITY_SUPER_NERD1_FOSSILS =
      "VOICE_PEWTER_CITY_SUPER_NERD1_002",
    PEWTER_CITY_SUPER_NERD1_HAVE_TO_GO =
      "VOICE_PEWTER_CITY_SUPER_NERD1_003",

    PEWTER_CITY_SUPER_NERD2_WHAT_DOING =
      "VOICE_PEWTER_CITY_SUPER_NERD2_001",
    PEWTER_CITY_SUPER_NERD2_HARD_WORK =
      "VOICE_PEWTER_CITY_SUPER_NERD2_002",
    PEWTER_CITY_SUPER_NERD2_REPEL =
      "VOICE_PEWTER_CITY_SUPER_NERD2_003",

    PEWTER_CITY_YOUNGSTER_CHALLENGERS =
      "VOICE_PEWTER_CITY_YOUNGSTER_001",
    PEWTER_CITY_YOUNGSTER_FOLLOW_ME =
      "VOICE_PEWTER_CITY_YOUNGSTER_002",
    PEWTER_CITY_YOUNGSTER_TAKE_ON_BROCK =
      "VOICE_PEWTER_CITY_YOUNGSTER_003",

    OAK_PARCEL_OLD_POKEMON = "VOICE_OAKS_LAB_PARCEL_001",
    OAK_PARCEL_LIKES_YOU = "VOICE_OAKS_LAB_PARCEL_002",
    OAK_PARCEL_TALENTED = "VOICE_OAKS_LAB_PARCEL_003",
    OAK_PARCEL_SOMETHING = "VOICE_OAKS_LAB_PARCEL_004",
    OAK_PARCEL_CUSTOM_BALL = "VOICE_OAKS_LAB_PARCEL_005",

    RIVAL_POKEDEX_GRAMPS = "VOICE_OAKS_LAB_POKEDEX_RIVAL_001",
    RIVAL_POKEDEX_CALLED = "VOICE_OAKS_LAB_POKEDEX_RIVAL_002",

    OAK_POKEDEX_REQUEST = "VOICE_OAKS_LAB_POKEDEX_OAK_001",
    OAK_POKEDEX_INVENTION = "VOICE_OAKS_LAB_POKEDEX_OAK_002",
    OAK_POKEDEX_RECORDS = "VOICE_OAKS_LAB_POKEDEX_OAK_003",
    OAK_POKEDEX_ENCYCLOPEDIA = "VOICE_OAKS_LAB_POKEDEX_OAK_004",
    OAK_POKEDEX_TAKE_THESE = "VOICE_OAKS_LAB_POKEDEX_OAK_005",

    OAK_DREAM_COMPLETE_GUIDE = "VOICE_OAKS_LAB_DREAM_001",
    OAK_DREAM_THAT_WAS = "VOICE_OAKS_LAB_DREAM_002",
    OAK_DREAM_TOO_OLD = "VOICE_OAKS_LAB_DREAM_003",
    OAK_DREAM_FULFILL = "VOICE_OAKS_LAB_DREAM_004",
    OAK_DREAM_GET_MOVING = "VOICE_OAKS_LAB_DREAM_005",
    OAK_DREAM_UNDERTAKING = "VOICE_OAKS_LAB_DREAM_006",

    RIVAL_POKEDEX_LEAVE_TO_ME =
      "VOICE_OAKS_LAB_POKEDEX_RIVAL_003",
    RIVAL_POKEDEX_DONT_NEED =
      "VOICE_OAKS_LAB_POKEDEX_RIVAL_004",
    RIVAL_POKEDEX_BORROW_MAP =
      "VOICE_OAKS_LAB_POKEDEX_RIVAL_005",
    RIVAL_POKEDEX_DONT_LEND =
      "VOICE_OAKS_LAB_POKEDEX_RIVAL_006",

    OAK_POKEDEX_AROUND_WORLD =
      "VOICE_OAKS_LAB_POKEDEX_OAK_006",

    POKECENTER_NURSE_WELCOME =
      "VOICE_POKECENTER_NURSE_001",
    POKECENTER_NURSE_PERFECT_HEALTH =
      "VOICE_POKECENTER_NURSE_002",
    POKECENTER_NURSE_NEED_POKEMON =
      "VOICE_POKECENTER_NURSE_003",
    POKECENTER_NURSE_FIGHTING_FIT =
      "VOICE_POKECENTER_NURSE_004",
    POKECENTER_NURSE_FAREWELL =
      "VOICE_POKECENTER_NURSE_005",
    POKECENTER_NURSE_SHALL_HEAL =
      "VOICE_POKECENTER_NURSE_006",

    VIRIDIAN_POKECENTER_CENTER_EVERY_TOWN =
      "VOICE_VIRIDIAN_POKECENTER_COOLTRAINER_001",
    VIRIDIAN_POKECENTER_NO_CHARGE =
      "VOICE_VIRIDIAN_POKECENTER_COOLTRAINER_002",
    VIRIDIAN_POKECENTER_USE_PC =
      "VOICE_VIRIDIAN_POKECENTER_GENTLEMAN_001",
    VIRIDIAN_POKECENTER_RECEPTIONIST_KIND =
      "VOICE_VIRIDIAN_POKECENTER_GENTLEMAN_002",
    VIRIDIAN_POKECENTER_HEAL_VISITOR =
      "VOICE_VIRIDIAN_POKECENTER_VISITOR_001",
    VIRIDIAN_POKECENTER_CABLE_WELCOME =
      "VOICE_VIRIDIAN_POKECENTER_RECEPTIONIST_001",
    VIRIDIAN_POKECENTER_CABLE_APPLY =
      "VOICE_VIRIDIAN_POKECENTER_RECEPTIONIST_002",
    VIRIDIAN_POKECENTER_CABLE_SAVE =
      "VOICE_VIRIDIAN_POKECENTER_RECEPTIONIST_003",
    VIRIDIAN_POKECENTER_CABLE_FAREWELL =
      "VOICE_VIRIDIAN_POKECENTER_RECEPTIONIST_004",

    VIRIDIAN_SCHOOL_MEMORIZE_NOTES =
      "VOICE_VIRIDIAN_SCHOOL_BRUNETTE_001",
    VIRIDIAN_SCHOOL_READ_BLACKBOARD =
      "VOICE_VIRIDIAN_SCHOOL_COOLTRAINER_001",

    VIRIDIAN_NICKNAME_DADDY_LOVES_POKEMON =
      "VOICE_VIRIDIAN_NICKNAME_LITTLE_GIRL_001",
    VIRIDIAN_NICKNAME_NICKNAMES_FUN_HARD =
      "VOICE_VIRIDIAN_NICKNAME_BALDING_GUY_001",
    VIRIDIAN_NICKNAME_SIMPLE_NAMES =
      "VOICE_VIRIDIAN_NICKNAME_BALDING_GUY_002",
  }

  local FILES = {
    [VOICES.HELLO] =
      "assets/voices/oak_intro/oak_intro_001_hello_there.ogg",
    [VOICES.WELCOME] =
      "assets/voices/oak_intro/oak_intro_002_welcome.ogg",
    [VOICES.MY_NAME] =
      "assets/voices/oak_intro/oak_intro_003_my_name_is_oak.ogg",
    [VOICES.PROFESSOR] =
      "assets/voices/oak_intro/oak_intro_004_pokemon_professor.ogg",
    [VOICES.WORLD] =
      "assets/voices/oak_intro/oak_intro_005_world_inhabited.ogg",
    [VOICES.PETS] =
      "assets/voices/oak_intro/oak_intro_006_pokemon_are_pets.ogg",
    [VOICES.FIGHTS] =
      "assets/voices/oak_intro/oak_intro_007_others_use_for_fights.ogg",
    [VOICES.PROFESSION] =
      "assets/voices/oak_intro/oak_intro_008_study_as_profession.ogg",
    [VOICES.ASK_PLAYER_NAME] =
      "assets/voices/oak_intro/oak_intro_009_ask_player_name.ogg",
    [VOICES.INTRODUCE_RIVAL] =
      "assets/voices/oak_intro/oak_intro_010_introduce_rival.ogg",
    [VOICES.ASK_RIVAL_NAME] =
      "assets/voices/oak_intro/oak_intro_011_ask_rival_name.ogg",
    [VOICES.LEGEND] =
      "assets/voices/oak_intro/oak_intro_012_legend_unfolds.ogg",
    [VOICES.ADVENTURES] =
      "assets/voices/oak_intro/oak_intro_013_adventures_await.ogg",

    [VOICES.MOM_LEAVE_HOME] =
      "assets/voices/reds_house/mom/mom_reds_house_001_leave_home.ogg",
    [VOICES.MOM_TV] =
      "assets/voices/reds_house/mom/mom_reds_house_002_saw_on_tv.ogg",
    [VOICES.MOM_OAK_LOOKING] =
      "assets/voices/reds_house/mom/mom_reds_house_003_oak_looking_for_you.ogg",

    [VOICES.PALLET_GIRL_RAISING] =
      "assets/voices/pallet_town/girl_pallet_001_raising_pokemon.ogg",
    [VOICES.PALLET_GIRL_PROTECTION] =
      "assets/voices/pallet_town/girl_pallet_002_protection.ogg",
    [VOICES.PALLET_MAN_TECHNOLOGY] =
      "assets/voices/pallet_town/man_pallet_001_technology.ogg",
    [VOICES.PALLET_MAN_PC_STORAGE] =
      "assets/voices/pallet_town/man_pallet_002_pc_storage.ogg",

    [VOICES.OAKS_LAB_AIDE] =
      "assets/voices/oaks_lab/aide_oaks_lab_001_oak_assistant.ogg",
    [VOICES.OAKS_LAB_GIRL_AUTHORITY] =
      "assets/voices/oaks_lab/girl_oaks_lab_001_oak_authority.ogg",
    [VOICES.OAKS_LAB_GIRL_REGARD] =
      "assets/voices/oaks_lab/girl_oaks_lab_002_high_regard.ogg",
    [VOICES.OAKS_LAB_RIVAL_GRAMPS_ABSENT] =
      "assets/voices/oaks_lab/rival_oaks_lab_001_gramps_absent.ogg",

    [VOICES.DAISY_BROTHER_AT_LAB] =
      "assets/voices/rivals_house/daisy/daisy_rivals_house_001_brother_at_lab.ogg",

    [VOICES.PALLET_OAK_HEY_WAIT] =
      "assets/voices/pallet_town/oak/oak_pallet_001_hey_wait.ogg",
    [VOICES.PALLET_OAK_UNSAFE] =
      "assets/voices/pallet_town/oak/oak_pallet_002_unsafe_tall_grass.ogg",
    [VOICES.PALLET_OAK_PROTECTION] =
      "assets/voices/pallet_town/oak/oak_pallet_003_need_protection.ogg",
    [VOICES.PALLET_OAK_COME_WITH_ME] =
      "assets/voices/pallet_town/oak/oak_pallet_004_come_with_me.ogg",

    [VOICES.LAB_RIVAL_FED_UP] =
      "assets/voices/oaks_lab/pre_starter/rival_oaks_lab_002_fed_up_waiting.ogg",
    [VOICES.LAB_OAK_LET_ME_THINK] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_001_let_me_think.ogg",
    [VOICES.LAB_OAK_TOLD_TO_COME] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_002_told_you_to_come.ogg",
    [VOICES.LAB_OAK_HAHA] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_003_haha.ogg",
    [VOICES.LAB_OAK_INSIDE_BALLS] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_004_inside_pokeballs.ogg",
    [VOICES.LAB_OAK_SERIOUS_TRAINER] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_005_serious_trainer.ogg",
    [VOICES.LAB_OAK_ONLY_THREE] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_006_only_three_left.ogg",
    [VOICES.LAB_OAK_BE_PATIENT] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_007_be_patient.ogg",
    [VOICES.LAB_OAK_THREE_POKEMON] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_007_three_pokemon_here.ogg",
    [VOICES.LAB_RIVAL_WHAT_ABOUT_ME] =
      "assets/voices/oaks_lab/pre_starter/rival_oaks_lab_003_what_about_me.ogg",

    [VOICES.LAB_OAK_CONFIRM_CHARMANDER] =
      "assets/voices/oaks_lab/starter_choice/oak_oaks_lab_008_confirm_charmander.ogg",
    [VOICES.LAB_OAK_CONFIRM_SQUIRTLE] =
      "assets/voices/oaks_lab/starter_choice/oak_oaks_lab_009_confirm_squirtle.ogg",
    [VOICES.LAB_OAK_CONFIRM_BULBASAUR] =
      "assets/voices/oaks_lab/starter_choice/oak_oaks_lab_010_confirm_bulbasaur.ogg",

    [VOICES.LAB_OAK_WHICH_POKEMON] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_011_which_pokemon.ogg",
    [VOICES.LAB_OAK_DONT_GO_AWAY] =
      "assets/voices/oaks_lab/pre_starter/oak_oaks_lab_012_dont_go_away.ogg",
    [VOICES.LAB_RIVAL_GO_AHEAD] =
      "assets/voices/oaks_lab/pre_starter/rival_oaks_lab_004_go_ahead_choose.ogg",

    [VOICES.LAB_RIVAL_TAKE_THIS_ONE] =
      "assets/voices/oaks_lab/post_choice/rival_oaks_lab_005_take_this_one.ogg",
    [VOICES.LAB_RIVAL_LOOKS_STRONGER] =
      "assets/voices/oaks_lab/post_choice/rival_oaks_lab_006_looks_stronger.ogg",
    [VOICES.LAB_OAK_CAN_FIGHT_WILD] =
      "assets/voices/oaks_lab/post_choice/oak_oaks_lab_013_can_fight_wild_pokemon.ogg",

    [VOICES.LAB_RIVAL_BATTLE_WAIT] =
      "assets/voices/oaks_lab/rival_battle/rival_oaks_lab_007_wait.ogg",
    [VOICES.LAB_RIVAL_BATTLE_CHECK] =
      "assets/voices/oaks_lab/rival_battle/rival_oaks_lab_008_check_pokemon.ogg",
    [VOICES.LAB_RIVAL_BATTLE_CHALLENGE] =
      "assets/voices/oaks_lab/rival_battle/rival_oaks_lab_009_take_you_on.ogg",

    [VOICES.LAB_RIVAL_WIN_UNBELIEVABLE] =
      "assets/voices/oaks_lab/battle_outcome/rival_oaks_lab_010_what_unbelievable.ogg",
    [VOICES.LAB_RIVAL_WIN_WRONG_POKEMON] =
      "assets/voices/oaks_lab/battle_outcome/rival_oaks_lab_011_wrong_pokemon.ogg",
    [VOICES.LAB_RIVAL_LOSS_GREAT] =
      "assets/voices/oaks_lab/battle_outcome/rival_oaks_lab_012_am_i_great.ogg",
    [VOICES.LAB_RIVAL_SHARED_TOUGHEN] =
      "assets/voices/oaks_lab/battle_outcome/rival_oaks_lab_013_toughen_it_up.ogg",
    [VOICES.LAB_RIVAL_SMELL_YA_LATER] =
      "assets/voices/oaks_lab/battle_outcome/rival_oaks_lab_014_smell_ya_later.ogg",

    [VOICES.LAB_OAK_RAISE_YOUNG] =
      "assets/voices/oaks_lab/post_choice/oak_oaks_lab_014_raise_young_pokemon.ogg",

    [VOICES.DAISY_GRANDPA_ERRAND] =
      "assets/voices/rivals_house/daisy/daisy_rivals_house_002_grandpa_errand.ogg",
    [VOICES.DAISY_MAP_WILL_HELP] =
      "assets/voices/rivals_house/daisy/daisy_rivals_house_003_map_will_help.ogg",
    [VOICES.DAISY_USE_TOWN_MAP] =
      "assets/voices/rivals_house/daisy/daisy_rivals_house_004_use_town_map.ogg",

    [VOICES.MOM_QUICK_REST] =
      "assets/voices/reds_house/mom/mom_reds_house_004_quick_rest.ogg",
    [VOICES.MOM_LOOKING_GREAT] =
      "assets/voices/reds_house/mom/mom_reds_house_005_looking_great.ogg",
    [VOICES.MOM_TAKE_CARE] =
      "assets/voices/reds_house/mom/mom_reds_house_006_take_care_now.ogg",

    [VOICES.DAISY_POKEMON_NEED_REST] =
      "assets/voices/rivals_house/daisy/daisy_rivals_house_005_pokemon_need_rest.ogg",

    [VOICES.ROUTE1_MART_WORKER_INTRO] =
      "assets/voices/route_1/route1_mart_worker_001_work_at_mart.ogg",
    [VOICES.ROUTE1_MART_WORKER_VISIT] =
      "assets/voices/route_1/route1_mart_worker_002_visit_viridian.ogg",
    [VOICES.ROUTE1_MART_WORKER_SAMPLE] =
      "assets/voices/route_1/route1_mart_worker_003_free_sample.ogg",
    [VOICES.ROUTE1_MART_WORKER_POKEBALLS] =
      "assets/voices/route_1/route1_mart_worker_004_carry_pokeballs.ogg",

    [VOICES.ROUTE1_LEDGE_SEE] =
      "assets/voices/route_1/route1_ledge_youngster_001_see_ledges.ogg",
    [VOICES.ROUTE1_LEDGE_JUMP] =
      "assets/voices/route_1/route1_ledge_youngster_002_jump_from_them.ogg",
    [VOICES.ROUTE1_LEDGE_QUICKER] =
      "assets/voices/route_1/route1_ledge_youngster_003_quicker_to_pallet.ogg",

    [VOICES.ROUTE22_RIVAL1_HEY] =
      "assets/voices/route_22/rival_first_encounter/route22_rival1_001_hey.ogg",
    [VOICES.ROUTE22_RIVAL1_POKEMON_LEAGUE] =
      "assets/voices/route_22/rival_first_encounter/route22_rival1_002_pokemon_league.ogg",
    [VOICES.ROUTE22_RIVAL1_NO_BADGES] =
      "assets/voices/route_22/rival_first_encounter/route22_rival1_003_no_badges.ogg",
    [VOICES.ROUTE22_RIVAL1_GUARD] =
      "assets/voices/route_22/rival_first_encounter/route22_rival1_004_guard_wont_let_through.ogg",
    [VOICES.ROUTE22_RIVAL1_STRONGER] =
      "assets/voices/route_22/rival_first_encounter/route22_rival1_005_pokemon_stronger.ogg",

    [VOICES.VIRIDIAN_FOREST_SOUTH_GATE_GIRL_FOREST] =
      "assets/voices/viridian_forest/south_gate/viridian_forest_south_gate_girl_001_going_to_forest.ogg",
    [VOICES.VIRIDIAN_FOREST_SOUTH_GATE_GIRL_MAZE] =
      "assets/voices/viridian_forest/south_gate/viridian_forest_south_gate_girl_002_natural_maze.ogg",
    [VOICES.VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_RATTATA] =
      "assets/voices/viridian_forest/south_gate/viridian_forest_south_gate_little_girl_001_rattata_bite.ogg",
    [VOICES.VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_GOT_ONE] =
      "assets/voices/viridian_forest/south_gate/viridian_forest_south_gate_little_girl_002_did_you_get_one.ogg",

    [VOICES.VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_FORESTS_CAVES] =
      "assets/voices/viridian_forest/north_gate/viridian_forest_north_gate_super_nerd_001_forests_caves.ogg",
    [VOICES.VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_LOOK_EVERYWHERE] =
      "assets/voices/viridian_forest/north_gate/viridian_forest_north_gate_super_nerd_002_look_everywhere.ogg",
    [VOICES.VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_ROADSIDE_BUSHES] =
      "assets/voices/viridian_forest/north_gate/viridian_forest_north_gate_gramps_001_roadside_bushes.ogg",
    [VOICES.VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_SPECIAL_MOVE] =
      "assets/voices/viridian_forest/north_gate/viridian_forest_north_gate_gramps_002_special_move.ogg",

    [VOICES.VIRIDIAN_FOREST_YOUNGSTER1_FRIENDS] =
      "assets/voices/viridian_forest/main/viridian_forest_youngster1_001_friends.ogg",
    [VOICES.VIRIDIAN_FOREST_YOUNGSTER1_POKEMON_FIGHTS] =
      "assets/voices/viridian_forest/main/viridian_forest_youngster1_002_pokemon_fights.ogg",
    [VOICES.VIRIDIAN_FOREST_YOUNGSTER5_RAN_OUT_BALLS] =
      "assets/voices/viridian_forest/main/viridian_forest_youngster5_001_ran_out_pokeballs.ogg",
    [VOICES.VIRIDIAN_FOREST_YOUNGSTER5_CARRY_EXTRAS] =
      "assets/voices/viridian_forest/main/viridian_forest_youngster5_002_carry_extras.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_BATTLE] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher1_001_battle.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_DEFEAT] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher1_002_defeat.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_AFTER] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher1_003_after.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_BATTLE] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher2_001_battle.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_DEFEAT] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher2_002_defeat.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_AFTER] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher2_003_after.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_BATTLE] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher3_001_battle.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_DEFEAT] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher3_002_defeat.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_GROUND] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher3_003_after_ground.ogg",
    [VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_DROPPED] =
      "assets/voices/viridian_forest/main/viridian_forest_bug_catcher3_004_after_dropped.ogg",

    [VOICES.VIRIDIAN_MART_CAME_FROM_PALLET] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_001_came_from_pallet.ogg",
    [VOICES.VIRIDIAN_MART_KNOW_OAK] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_002_know_professor_oak.ogg",
    [VOICES.VIRIDIAN_MART_TAKE_ORDER] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_003_take_order_to_oak.ogg",
    [VOICES.VIRIDIAN_MART_SAY_HI] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_004_say_hi_to_oak.ogg",
    [VOICES.VIRIDIAN_MART_BOUGHT_ITEM] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_005_here_you_are_thank_you.ogg",
    [VOICES.VIRIDIAN_MART_SOLD_ITEM] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_006_thank_you.ogg",
    [VOICES.VIRIDIAN_MART_GREETING] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_007_greeting.ogg",
    [VOICES.VIRIDIAN_MART_TAKE_YOUR_TIME] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_008_take_your_time.ogg",
    [VOICES.VIRIDIAN_MART_NOT_ENOUGH_MONEY] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_009_not_enough_money.ogg",
    [VOICES.VIRIDIAN_MART_BAG_FULL] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_010_bag_full.ogg",
    [VOICES.VIRIDIAN_MART_WHAT_TO_SELL] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_011_what_to_sell.ogg",
    [VOICES.VIRIDIAN_MART_NOTHING_TO_SELL] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_012_nothing_to_sell.ogg",
    [VOICES.VIRIDIAN_MART_CANT_PRICE] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_013_cant_price_that.ogg",
    [VOICES.VIRIDIAN_MART_ANYTHING_ELSE] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_clerk_014_anything_else.ogg",
    [VOICES.VIRIDIAN_MART_MANY_ANTIDOTES] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_youngster_001_many_antidotes.ogg",
    [VOICES.VIRIDIAN_MART_POTIONS_SOLD_OUT] =
      "assets/voices/viridian_city/pokemon_mart/viridian_mart_cooltrainer_001_potions_sold_out.ogg",

    [VOICES.VIRIDIAN_CITY_POKEBALLS_AT_WAIST] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster1_001_pokeballs_at_waist.ogg",
    [VOICES.VIRIDIAN_CITY_YOU_HAVE_POKEMON] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster1_002_you_have_pokemon.ogg",
    [VOICES.VIRIDIAN_CITY_CARRY_USE_ANYWHERE] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster1_003_carry_use_anywhere.ogg",

    [VOICES.VIRIDIAN_CITY_CATERPILLAR_QUESTION] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster2_001_caterpillar_question.ogg",
    [VOICES.VIRIDIAN_CITY_CATERPIE_WEEDLE] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster2_002_caterpie_no_poison_weedle_does.ogg",
    [VOICES.VIRIDIAN_CITY_POISON_STING] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster2_003_watch_poison_sting.ogg",
    [VOICES.VIRIDIAN_CITY_OK_THEN] =
      "assets/voices/viridian_city/outdoors/viridian_city_youngster2_004_ok_then.ogg",

    [VOICES.VIRIDIAN_CITY_GIRL_GRANDPA_MEAN] =
      "assets/voices/viridian_city/outdoors/viridian_city_girl_001_grandpa_mean.ogg",
    [VOICES.VIRIDIAN_CITY_GIRL_WINDING_TRAIL] =
      "assets/voices/viridian_city/outdoors/viridian_city_girl_002_winding_trail.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_CANT_GO_THROUGH] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_sleepy_001_cant_go_through.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_PRIVATE_PROPERTY] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_sleepy_002_private_property.ogg",

    [VOICES.VIRIDIAN_CITY_OLD_MAN_HAD_COFFEE] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_001_had_coffee.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_GO_THROUGH] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_002_go_through.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_IN_HURRY] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_003_in_hurry.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_TIME_IS_MONEY] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_004_time_is_money.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_USING_POKEDEX] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_005_using_pokedex.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_POKEDEX_UPDATED] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_006_pokedex_updated.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_DONT_KNOW_CATCH] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_007_dont_know_catch.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_SHOW_HOW] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_008_show_how.ogg",
    [VOICES.VIRIDIAN_CITY_OLD_MAN_WEAKEN_TARGET] =
      "assets/voices/viridian_city/outdoors/viridian_city_old_man_009_weaken_target.ogg",

    [VOICES.VIRIDIAN_CITY_GYM_WATCHER_CLOSED] =
      "assets/voices/viridian_city/outdoors/viridian_city_gym_watcher_001_gym_always_closed.ogg",
    [VOICES.VIRIDIAN_CITY_GYM_WATCHER_WONDER_LEADER] =
      "assets/voices/viridian_city/outdoors/viridian_city_gym_watcher_002_wonder_leader.ogg",
    [VOICES.VIRIDIAN_CITY_GYM_WATCHER_LEADER_RETURNED] =
      "assets/voices/viridian_city/outdoors/viridian_city_gym_watcher_003_leader_returned.ogg",

    [VOICES.VIRIDIAN_CITY_FISHER_DOZED_OFF] =
      "assets/voices/viridian_city/outdoors/viridian_city_fisher_001_doze_in_sun.ogg",
    [VOICES.VIRIDIAN_CITY_FISHER_DROWZEE_DREAM] =
      "assets/voices/viridian_city/outdoors/viridian_city_fisher_002_drowzee_dream.ogg",
    [VOICES.VIRIDIAN_CITY_FISHER_HAVE_TM] =
      "assets/voices/viridian_city/outdoors/viridian_city_fisher_003_have_this_tm.ogg",
    [VOICES.VIRIDIAN_CITY_FISHER_DREAM_EATER] =
      "assets/voices/viridian_city/outdoors/viridian_city_fisher_004_dream_eater.ogg",
    [VOICES.VIRIDIAN_CITY_FISHER_BAG_FULL] =
      "assets/voices/viridian_city/outdoors/viridian_city_fisher_005_too_much_stuff.ogg",

    [VOICES.PEWTER_CITY_COOLTRAINER_M_SERIOUS] =
      "assets/voices/pewter_city/outdoors/pewter_city_cooltrainer_m_001_serious_trainers.ogg",
    [VOICES.PEWTER_CITY_COOLTRAINER_M_BROCK] =
      "assets/voices/pewter_city/outdoors/pewter_city_cooltrainer_m_002_brock_into_it.ogg",
    [VOICES.PEWTER_CITY_COOLTRAINER_F_CLEFAIRY] =
      "assets/voices/pewter_city/outdoors/pewter_city_cooltrainer_f_001_clefairy_moon.ogg",
    [VOICES.PEWTER_CITY_COOLTRAINER_F_MOON_STONE] =
      "assets/voices/pewter_city/outdoors/pewter_city_cooltrainer_f_002_moon_stone.ogg",

    [VOICES.PEWTER_CITY_SUPER_NERD1_MUSEUM] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd1_001_museum_question.ogg",
    [VOICES.PEWTER_CITY_SUPER_NERD1_FOSSILS] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd1_002_fossils_amazing.ogg",
    [VOICES.PEWTER_CITY_SUPER_NERD1_HAVE_TO_GO] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd1_003_have_to_go.ogg",

    [VOICES.PEWTER_CITY_SUPER_NERD2_WHAT_DOING] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd2_001_what_doing.ogg",
    [VOICES.PEWTER_CITY_SUPER_NERD2_HARD_WORK] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd2_002_hard_work.ogg",
    [VOICES.PEWTER_CITY_SUPER_NERD2_REPEL] =
      "assets/voices/pewter_city/outdoors/pewter_city_super_nerd2_003_spraying_repel.ogg",

    [VOICES.PEWTER_CITY_YOUNGSTER_CHALLENGERS] =
      "assets/voices/pewter_city/outdoors/pewter_city_youngster_001_brock_challengers.ogg",
    [VOICES.PEWTER_CITY_YOUNGSTER_FOLLOW_ME] =
      "assets/voices/pewter_city/outdoors/pewter_city_youngster_002_follow_me.ogg",
    [VOICES.PEWTER_CITY_YOUNGSTER_TAKE_ON_BROCK] =
      "assets/voices/pewter_city/outdoors/pewter_city_youngster_003_take_on_brock.ogg",

    [VOICES.OAK_PARCEL_OLD_POKEMON] =
      "assets/voices/oaks_lab/parcel/oak_parcel_001_old_pokemon.ogg",
    [VOICES.OAK_PARCEL_LIKES_YOU] =
      "assets/voices/oaks_lab/parcel/oak_parcel_002_seems_to_like_you.ogg",
    [VOICES.OAK_PARCEL_TALENTED] =
      "assets/voices/oaks_lab/parcel/oak_parcel_003_talented_trainer.ogg",
    [VOICES.OAK_PARCEL_SOMETHING] =
      "assets/voices/oaks_lab/parcel/oak_parcel_004_something_for_me.ogg",
    [VOICES.OAK_PARCEL_CUSTOM_BALL] =
      "assets/voices/oaks_lab/parcel/oak_parcel_005_custom_pokeball.ogg",

    [VOICES.RIVAL_POKEDEX_GRAMPS] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_001_gramps.ogg",
    [VOICES.RIVAL_POKEDEX_CALLED] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_002_what_called_for.ogg",

    [VOICES.OAK_POKEDEX_REQUEST] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_001_request_of_you_two.ogg",
    [VOICES.OAK_POKEDEX_INVENTION] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_002_invention_pokedex.ogg",
    [VOICES.OAK_POKEDEX_RECORDS] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_003_records_data.ogg",
    [VOICES.OAK_POKEDEX_ENCYCLOPEDIA] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_004_high_tech_encyclopedia.ogg",
    [VOICES.OAK_POKEDEX_TAKE_THESE] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_005_take_these.ogg",

    [VOICES.OAK_DREAM_COMPLETE_GUIDE] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_002_complete_guide.ogg",
    [VOICES.OAK_DREAM_THAT_WAS] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_001_that_was_my_dream.ogg",
    [VOICES.OAK_DREAM_TOO_OLD] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_003_too_old.ogg",
    [VOICES.OAK_DREAM_FULFILL] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_004_fulfill_my_dream.ogg",
    [VOICES.OAK_DREAM_GET_MOVING] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_005_get_moving.ogg",
    [VOICES.OAK_DREAM_UNDERTAKING] =
      "assets/voices/oaks_lab/pokedex/oak/oak_dream_006_great_undertaking.ogg",

    [VOICES.RIVAL_POKEDEX_LEAVE_TO_ME] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_003_leave_it_to_me.ogg",
    [VOICES.RIVAL_POKEDEX_DONT_NEED] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_004_dont_need_you.ogg",
    [VOICES.RIVAL_POKEDEX_BORROW_MAP] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_005_borrow_town_map.ogg",
    [VOICES.RIVAL_POKEDEX_DONT_LEND] =
      "assets/voices/oaks_lab/pokedex/rival/rival_pokedex_006_dont_lend_one.ogg",

    [VOICES.OAK_POKEDEX_AROUND_WORLD] =
      "assets/voices/oaks_lab/pokedex/oak/oak_pokedex_006_pokemon_around_world.ogg",

    [VOICES.POKECENTER_NURSE_WELCOME] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_001_welcome.ogg",
    [VOICES.POKECENTER_NURSE_PERFECT_HEALTH] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_002_perfect_health.ogg",
    [VOICES.POKECENTER_NURSE_NEED_POKEMON] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_003_need_pokemon.ogg",
    [VOICES.POKECENTER_NURSE_FIGHTING_FIT] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_004_fighting_fit.ogg",
    [VOICES.POKECENTER_NURSE_FAREWELL] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_005_see_you_again.ogg",
    [VOICES.POKECENTER_NURSE_SHALL_HEAL] =
      "assets/voices/pokemon_center/nurse/pokemon_center_nurse_006_shall_we_heal.ogg",


    [VOICES.VIRIDIAN_POKECENTER_CENTER_EVERY_TOWN] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_cooltrainer_001_center_every_town.ogg",
    [VOICES.VIRIDIAN_POKECENTER_NO_CHARGE] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_cooltrainer_002_no_charge.ogg",
    [VOICES.VIRIDIAN_POKECENTER_USE_PC] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_gentleman_001_use_pc.ogg",
    [VOICES.VIRIDIAN_POKECENTER_RECEPTIONIST_KIND] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_gentleman_002_receptionist_kind.ogg",
    [VOICES.VIRIDIAN_POKECENTER_HEAL_VISITOR] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_visitor_001_heal_tired_hurt_fainted.ogg",
    [VOICES.VIRIDIAN_POKECENTER_CABLE_WELCOME] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_receptionist_001_welcome_cable_club.ogg",
    [VOICES.VIRIDIAN_POKECENTER_CABLE_APPLY] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_receptionist_002_apply_here.ogg",
    [VOICES.VIRIDIAN_POKECENTER_CABLE_SAVE] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_receptionist_003_save_game.ogg",
    [VOICES.VIRIDIAN_POKECENTER_CABLE_FAREWELL] =
      "assets/voices/viridian_city/pokemon_center/viridian_pokecenter_receptionist_004_come_again.ogg",

    [VOICES.VIRIDIAN_SCHOOL_MEMORIZE_NOTES] =
      "assets/voices/viridian_city/school_house/viridian_school_brunette_001_memorize_notes.ogg",
    [VOICES.VIRIDIAN_SCHOOL_READ_BLACKBOARD] =
      "assets/voices/viridian_city/school_house/viridian_school_cooltrainer_001_read_blackboard.ogg",

    [VOICES.VIRIDIAN_NICKNAME_DADDY_LOVES_POKEMON] =
      "assets/voices/viridian_city/nickname_house/viridian_nickname_little_girl_001_daddy_loves_pokemon.ogg",
    [VOICES.VIRIDIAN_NICKNAME_NICKNAMES_FUN_HARD] =
      "assets/voices/viridian_city/nickname_house/viridian_nickname_balding_guy_001_nicknames_fun_hard.ogg",
    [VOICES.VIRIDIAN_NICKNAME_SIMPLE_NAMES] =
      "assets/voices/viridian_city/nickname_house/viridian_nickname_balding_guy_002_simple_names.ogg",
  }

  for id, relativePath in pairs(FILES) do
    mod.content.sfx:register(id, {
      file = mod.assets:path(relativePath),
    })
  end

  local activeVoice = nil

  local function stopActiveVoice()
    if activeVoice then
      pcall(activeVoice.stop, activeVoice)
      activeVoice = nil
    end
  end

  local function setVoiceLevel(game, value)
    local options = gameOptions(game)
    voiceLevel = clampVoiceLevel(value)

    if options then
      options.voiceVolume = voiceLevel
    end

    applyVoiceVolume(activeVoice)
    return voiceLevel
  end

  local function startVoiceForGame(game, voiceId)
    stopActiveVoice()
    readVoiceLevel(game)
    activeVoice = Sound.play(game.data, voiceId)
    applyVoiceVolume(activeVoice)
    return activeVoice
  end

  local function startVoice(speech, voiceId)
    return startVoiceForGame(speech.game, voiceId)
  end

  ---------------------------------------------------------------------------
  -- SHARED POKé MART ATTENDANT
  --
  -- The opening and return-to-menu lines belong to the main ShopMenu. BUY
  -- and SELL responses are rendered directly as ListMenu footers rather than
  -- ordinary TextBoxes. Voice only the fixed canonical strings supplied by
  -- the user; the item-name and price prompts remain deliberately unvoiced.
  ---------------------------------------------------------------------------

  local ListMenu = require("src.ui.ListMenu")
  local ShopMenu = require("src.ui.ShopMenu")

  local function normalizedMartText(value)
    return tostring(value or "")
      :upper()
      :gsub("[%c]", " ")
      :gsub("%s+", " ")
      :match("^%s*(.-)%s*$")
  end

  local function martDataText(game, key, fallback)
    local dataText = game
      and game.data
      and game.data.text
      or nil

    return dataText and dataText[key] or fallback
  end

  -- Some engine revisions expose the clerk greeting as a normal text resource
  -- before constructing ShopMenu; others enter ShopMenu directly. The text
  -- wrapper below primes this flag so the constructor fallback cannot replay
  -- the same greeting twice.
  if ShopMenu._pokemonRedVoiceMartWrappedVersion ~= "1.16.8" then
    ShopMenu._pokemonRedVoiceMartWrappedVersion = "1.16.8"

    local previousShopMenuNew = ShopMenu.new

    function ShopMenu.new(game, stock, onQuit)
      local menu = previousShopMenuNew(game, stock, onQuit)

      if game and game._pokemonRedVoiceMartGreetingPrimed then
        game._pokemonRedVoiceMartGreetingPrimed = nil
      else
        startVoiceForGame(game, VOICES.VIRIDIAN_MART_GREETING)
      end

      return menu
    end
  end

  if ListMenu._pokemonRedVoiceMartWrappedVersion ~= "1.16.8" then
    ListMenu._pokemonRedVoiceMartWrappedVersion = "1.16.8"

    local previousListMenuNew = ListMenu.new
    local previousListMenuUpdate = ListMenu.update

    local function stopOwnedMartVoice(menu)
      local source = menu._pokemonRedVoiceMartSource

      if source and activeVoice == source then
        stopActiveVoice()
      end

      menu._pokemonRedVoiceMartSource = nil
    end

    local function menuIsTop(menu)
      local stack = menu.game and menu.game.stack

      if not stack or not stack.top then
        return true
      end

      return stack:top() == menu
    end

    local function footerMatches(menu, key, fallback)
      return normalizedMartText(menu.footer)
        == normalizedMartText(martDataText(menu.game, key, fallback))
    end

    local function syncMartFooterVoice(menu)
      if not menu._pokemonRedVoiceMartKind or not menuIsTop(menu) then
        return
      end

      local footer = normalizedMartText(menu.footer)

      if footer == menu._pokemonRedVoiceMartLastFooter then
        return
      end

      menu._pokemonRedVoiceMartLastFooter = footer
      stopOwnedMartVoice(menu)

      local voiceId = nil

      if menu._pokemonRedVoiceMartKind == "BUY" then
        if footerMatches(
          menu,
          "_PokemartBuyingGreetingText",
          "Take your time."
        ) then
          voiceId = VOICES.VIRIDIAN_MART_TAKE_YOUR_TIME
        elseif footerMatches(
          menu,
          "_PokemartNotEnoughMoneyText",
          "You don't have\nenough money."
        ) then
          voiceId = VOICES.VIRIDIAN_MART_NOT_ENOUGH_MONEY
        elseif footerMatches(
          menu,
          "_PokemartItemBagFullText",
          "You can't carry\nany more items."
        ) then
          voiceId = VOICES.VIRIDIAN_MART_BAG_FULL
        elseif footerMatches(
          menu,
          "_PokemartBoughtItemText",
          "Here you are!\nThank you!"
        ) then
          voiceId = VOICES.VIRIDIAN_MART_BOUGHT_ITEM
        end
      elseif menu._pokemonRedVoiceMartKind == "SELL" then
        if footerMatches(
          menu,
          "_PokemartSellingGreetingText",
          "What would you like\nto sell?"
        ) then
          voiceId = VOICES.VIRIDIAN_MART_WHAT_TO_SELL
        elseif footerMatches(
          menu,
          "_PokemartNoItemsToSellText",
          "You don't have\nanything to sell."
        ) then
          voiceId = VOICES.VIRIDIAN_MART_NOTHING_TO_SELL
        elseif footerMatches(
          menu,
          "_PokemartUnsellableItemText",
          "I can't put a\nprice on that."
        ) then
          voiceId = VOICES.VIRIDIAN_MART_CANT_PRICE
        elseif footerMatches(
          menu,
          "_PokemartThankYouText",
          "Thank you!"
        ) then
          voiceId = VOICES.VIRIDIAN_MART_SOLD_ITEM
        end
      end

      if voiceId then
        menu._pokemonRedVoiceMartSource = startVoiceForGame(
          menu.game,
          voiceId
        )
      end
    end

    function ListMenu.new(game, title, items, opts)
      local menu = previousListMenuNew(game, title, items, opts)
      local kind = normalizedMartText(title)

      if opts and opts.dialogue and (kind == "BUY" or kind == "SELL") then
        menu._pokemonRedVoiceMartKind = kind

        -- The canonical Gen I SELL entry has its own greeting and a dedicated
        -- empty-bag response. Some Gen1Recomp revisions reused the BUY footer
        -- or displayed only "Nothing here"; restore the original fixed text so
        -- the visible line and supplied voice remain synchronized.
        if kind == "SELL" then
          if not items or #items == 0 then
            menu.footer = martDataText(
              game,
              "_PokemartNoItemsToSellText",
              "You don't have\nanything to sell."
            )
          else
            menu.footer = martDataText(
              game,
              "_PokemartSellingGreetingText",
              "What would you like\nto sell?"
            )
          end
        end

        -- Nil forces the opening fixed footer to play when this list becomes
        -- the top state. Dynamic item/price prompts are ignored by the matcher.
        menu._pokemonRedVoiceMartLastFooter = nil

        local originalOnChoose = menu.onChoose

        if originalOnChoose then
          menu.onChoose = function(...)
            -- A new transaction may resolve to the same fixed string as the
            -- previous one. Clear the remembered footer while the quantity or
            -- confirmation overlay is above the list.
            stopOwnedMartVoice(menu)
            menu._pokemonRedVoiceMartLastFooter = nil
            return originalOnChoose(...)
          end
        end

        local originalOnCancel = menu.onCancel

        menu.onCancel = function(...)
          stopOwnedMartVoice(menu)

          local results = nil
          if originalOnCancel then
            results = { originalOnCancel(...) }
          end

          -- The list has already been popped by ListMenu:update, so this line
          -- accompanies the returned BUY/SELL/QUIT menu.
          startVoiceForGame(menu.game, VOICES.VIRIDIAN_MART_ANYTHING_ELSE)

          if results then
            return table.unpack(results)
          end
        end
      end

      return menu
    end

    function ListMenu:update(dt)
      -- ChoiceBox and QuantityBox callbacks alter the footer while layered
      -- above this list. Check both sides of the original update so the fixed
      -- response plays on the first frame the mart list is visible again.
      syncMartFooterVoice(self)
      local result = previousListMenuUpdate(self, dt)
      syncMartFooterVoice(self)
      return result
    end
  end

  ---------------------------------------------------------------------------
  -- MAIN OPTIONS MENU ROW
  --
  -- The engine persists game.save.options whenever a row's step callback
  -- returns true. Put this immediately below the built-in SFX VOL row.
  ---------------------------------------------------------------------------

  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    rows = next(game, rows) or rows

    -- Defensive de-duplication if the hook chain rebuilds the list.
    for i = #rows, 1, -1 do
      if rows[i].id == "voiceVolume" then
        table.remove(rows, i)
      end
    end

    local voiceRow = {
      id = "voiceVolume",
      label = "VOICE VOLUME",

      value = function(g)
        local level = readVoiceLevel(g)
        return level == 0 and "OFF" or tostring(level)
      end,

      step = function(g, dir)
        local before = readVoiceLevel(g)
        local after = clampVoiceLevel(before + dir)

        if after == before then
          return false
        end

        setVoiceLevel(g, after)
        return true
      end,
    }

    local insertAt = #rows + 1
    for i, row in ipairs(rows) do
      if row.id == "sfxVol" then
        insertAt = i + 1
        break
      end
    end

    table.insert(rows, insertAt, voiceRow)
    return rows
  end)

  ---------------------------------------------------------------------------
  -- A voiced dialogue beat.
  --
  -- The voice begins when its matching text appears. Advancing the text stops
  -- the current clip so spoken lines cannot overlap.
  ---------------------------------------------------------------------------

  local function voicedStep(id, text, voiceId, options)
    options = options or {}

    return {
      id = id,
      kind = "fn",

      run = function(speech, done)
        if options.pic ~= nil then
          speech:applyPic({
            pic = options.pic,
          })
        end

        local function showText()
          startVoice(speech, voiceId)

          speech:sayText(text, function()
            stopActiveVoice()
            done()
          end)
        end

        if options.reveal then
          speech:revealPic(options.reveal, showText)
        else
          showText()
        end
      end,
    }
  end

  ---------------------------------------------------------------------------
  -- Keep the vanilla Nidorino reveal and wait for its cry before continuing.
  ---------------------------------------------------------------------------

  local function waitForSource(game, source, done)
    if not source then
      done()
      return
    end

    local state = {
      isOpaque = false,
      finished = false,
    }

    function state:update(_)
      if self.finished then
        return
      end

      local ok, playing = pcall(source.isPlaying, source)

      if not ok or not playing then
        self.finished = true
        game.stack:pop()
        done()
      end
    end

    function state:draw()
      -- Transparent state: OakSpeech remains visible underneath.
    end

    game.stack:push(state)
  end

  local function nidorinoRevealStep()
    return {
      id = "voice_oak_demo_mon",
      kind = "fn",

      run = function(speech, done)
        speech.pic = speech.demoPic
        speech.picFlip = true
        speech.picTrueColor = speech.demoTrueColor

        speech:revealPic("wipe", function()
          local cry = Sound.playCry(
            speech.game.data,
            speech.demoSpecies
          )

          waitForSource(speech.game, cry, done)
        end)
      end,
    }
  end

  ---------------------------------------------------------------------------
  -- Reshape the vanilla intro around the two original naming-screen anchors.
  ---------------------------------------------------------------------------

  mod.hooks:wrap(
    "intro.oak_speech.build",
    function(next, steps, speech)
      steps = next(steps, speech)

      mod.ui.removeStep(steps, "oak_welcome")
      mod.ui.removeStep(steps, "demo_mon")
      mod.ui.removeStep(steps, "world_spiel")
      mod.ui.removeStep(steps, "ask_player_name")
      mod.ui.removeStep(steps, "ask_rival_name")
      mod.ui.removeStep(steps, "legend")

      local beforePlayerName = {
        voicedStep(
          "voice_oak_001_hello",
          "Hello there!",
          VOICES.HELLO,
          {
            pic = "oak",
            reveal = "fade",
          }
        ),

        voicedStep(
          "voice_oak_002_welcome",
          "Welcome to the\nworld of POKéMON!",
          VOICES.WELCOME
        ),

        voicedStep(
          "voice_oak_003_name",
          "My name is OAK!",
          VOICES.MY_NAME
        ),

        voicedStep(
          "voice_oak_004_professor",
          "People call me the\nPOKéMON PROFESSOR.",
          VOICES.PROFESSOR
        ),

        nidorinoRevealStep(),

        voicedStep(
          "voice_oak_005_world",
          "This world is\ninhabited by\ncreatures called\nPOKéMON!",
          VOICES.WORLD
        ),

        voicedStep(
          "voice_oak_006_pets",
          "For some people,\nPOKéMON are pets.",
          VOICES.PETS
        ),

        voicedStep(
          "voice_oak_007_fights",
          "Others use them\nfor fights.",
          VOICES.FIGHTS
        ),

        voicedStep(
          "voice_oak_008_profession",
          "Myself, I study\nPOKéMON as a\nprofession.",
          VOICES.PROFESSION
        ),

        voicedStep(
          "voice_oak_009_ask_player",
          "First, what is\nyour name?",
          VOICES.ASK_PLAYER_NAME,
          {
            pic = "player",
          }
        ),
      }

      for _, step in ipairs(beforePlayerName) do
        mod.ui.insertStepBefore(steps, "name_player", step)
      end

      local beforeRivalName = {
        voicedStep(
          "voice_oak_010_introduce_rival",
          "This is my grand-\nson. He's been\nyour rival since\nyou were a baby.",
          VOICES.INTRODUCE_RIVAL,
          {
            pic = "rival",
          }
        ),

        voicedStep(
          "voice_oak_011_ask_rival",
          "...Erm, what is\nhis name again?",
          VOICES.ASK_RIVAL_NAME
        ),
      }

      for _, step in ipairs(beforeRivalName) do
        mod.ui.insertStepBefore(steps, "name_rival", step)
      end

      local beforeShrink = {
        voicedStep(
          "voice_oak_012_legend",
          "Your very own\nPOKéMON adventure is\nabout to unfold!",
          VOICES.LEGEND,
          {
            pic = "player",
          }
        ),

        voicedStep(
          "voice_oak_013_adventures",
          "A world of dreams\nand adventures with\nPOKéMON awaits!\nLet's go!",
          VOICES.ADVENTURES
        ),
      }

      for _, step in ipairs(beforeShrink) do
        mod.ui.insertStepBefore(steps, "shrink", step)
      end

      return steps
    end
  )

  ---------------------------------------------------------------------------
  -- VOICED OVERWORLD DIALOGUE
  --
  -- Each mapped vanilla text ID is replaced by individually voiced pages.
  -- Unmapped dialogue continues through the original show_text command.
  ---------------------------------------------------------------------------

  local Commands = require("src.script.Commands")
  local TextBox = require("src.render.TextBox")

  local VOICED_SCRIPT_PAGES = {
    _RedsHouse1FMomWakeUpText = {
      {
        text = "Right! All boys\nleave home some day.",
        voice = VOICES.MOM_LEAVE_HOME,
      },
      {
        text = "It said so on TV.",
        voice = VOICES.MOM_TV,
      },
      {
        text = "PROF. OAK, next\ndoor, is looking\nfor you.",
        voice = VOICES.MOM_OAK_LOOKING,
      },
    },

    _BluesHouseDaisyRivalAtLabText = {
      {
        -- The recording deliberately avoids dynamic character names.
        text = "Hi! My brother is\nout at Grandpa's\nlab.",
        voice = VOICES.DAISY_BROTHER_AT_LAB,
      },
    },


    _OaksLabYouWantCharmanderText = {
      {
        text = "So! You want the\nfire POKéMON,\nCHARMANDER?",
        voice = VOICES.LAB_OAK_CONFIRM_CHARMANDER,
      },
    },

    _OaksLabYouWantSquirtleText = {
      {
        text = "So! You want the\nwater POKéMON,\nSQUIRTLE?",
        voice = VOICES.LAB_OAK_CONFIRM_SQUIRTLE,
      },
    },

    _OaksLabYouWantBulbasaurText = {
      {
        text = "So! You want the\nplant POKéMON,\nBULBASAUR?",
        voice = VOICES.LAB_OAK_CONFIRM_BULBASAUR,
      },
    },


    _OaksLabOak1WhichPokemonDoYouWantText = {
      {
        text = "Now, which POKéMON\ndo you want?",
        voice = VOICES.LAB_OAK_WHICH_POKEMON,
      },
    },

    _OaksLabOakDontGoAwayYetText = {
      {
        text = "Hey! Don't go away\nyet!",
        voice = VOICES.LAB_OAK_DONT_GO_AWAY,
      },
    },

    _OaksLabRivalGoAheadAndChooseText = {
      {
        -- The supplied recording avoids dynamic character names.
        text = "Heh! I don't need\nto be greedy like\nyou! Go ahead and\nchoose!",
        voice = VOICES.LAB_RIVAL_GO_AHEAD,
      },
    },


    _OaksLabRivalIllTakeThisOneText = {
      {
        text = "I'll take this one,\nthen!",
        voice = VOICES.LAB_RIVAL_TAKE_THIS_ONE,
      },
    },

    _OaksLabRivalMyPokemonLooksStrongerText = {
      {
        text = "My POKéMON looks a\nlot stronger.",
        voice = VOICES.LAB_RIVAL_LOOKS_STRONGER,
      },
    },

    _OaksLabOak1YourPokemonCanFightText = {
      {
        text = "If a wild POKéMON\nappears, your\nPOKéMON can fight\nagainst it!",
        voice = VOICES.LAB_OAK_CAN_FIGHT_WILD,
      },
    },


    _OaksLabRivalIllTakeYouOnText = {
      {
        text = "Wait!",
        voice = VOICES.LAB_RIVAL_BATTLE_WAIT,
      },
      {
        text = "Let's check out our\nPOKéMON!",
        voice = VOICES.LAB_RIVAL_BATTLE_CHECK,
      },
      {
        text = "Come on! I'll take\nyou on!",
        voice = VOICES.LAB_RIVAL_BATTLE_CHALLENGE,
      },
    },


    _OaksLabRivalIPickedTheWrongPokemonText = {
      {
        text = "WHAT?\nUnbelievable!",
        voice = VOICES.LAB_RIVAL_WIN_UNBELIEVABLE,
      },
      {
        text = "I picked the wrong\nPOKéMON!",
        voice = VOICES.LAB_RIVAL_WIN_WRONG_POKEMON,
      },
    },

    _OaksLabRivalSmellYouLaterText = {
      {
        text = function(game)
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return rival .. ": Okay!\nI'll make my\nPOKéMON fight to\ntoughen it up!"
        end,
        voice = VOICES.LAB_RIVAL_SHARED_TOUGHEN,
      },
      {
        -- The supplied recording deliberately omits the dynamic player name.
        text = "Gramps!\nSmell ya later!",
        voice = VOICES.LAB_RIVAL_SMELL_YA_LATER,
      },
    },


    _OaksLabOak1RaiseYourYoungPokemonText = {
      {
        -- The supplied recording deliberately omits the dynamic player name.
        text = "Raise your young\nPOKéMON by making\nit fight!",
        voice = VOICES.LAB_OAK_RAISE_YOUNG,
      },
    },

    _BluesHouseDaisyOfferMapText = {
      {
        text = "Grandpa asked you\nto run an errand?",
        voice = VOICES.DAISY_GRANDPA_ERRAND,
      },
      {
        text = "Here, this will\nhelp you!",
        voice = VOICES.DAISY_MAP_WILL_HELP,
      },
    },

    _BluesHouseDaisyUseMapText = {
      {
        text = "Use the TOWN MAP\nto find out where\nyou are.",
        voice = VOICES.DAISY_USE_TOWN_MAP,
      },
    },


    _RedsHouse1FMomYouShouldRestText = {
      {
        text = "You should take a\nquick rest.",
        voice = VOICES.MOM_QUICK_REST,
      },
    },

    _RedsHouse1FMomLookingGreatText = {
      {
        text = "Oh, good! You and\nyour POKéMON are\nlooking great!",
        voice = VOICES.MOM_LOOKING_GREAT,
      },
      {
        text = "Take care now!",
        voice = VOICES.MOM_TAKE_CARE,
      },
    },


    _BluesHouseDaisyWalkingText = {
      {
        text = "POKéMON are living\nthings! If they get\ntired, give them a\nrest!",
        voice = VOICES.DAISY_POKEMON_NEED_REST,
      },
    },


    -------------------------------------------------------------------------
    -- ROUTE 1
    --
    -- The free Potion and its receipt notification remain controlled by the
    -- original Route1 script. Only the spoken text resources are replaced.
    -- The rare Bag-full branch is deliberately left unvoiced.
    -------------------------------------------------------------------------

    _Route1Youngster1MartSampleText = {
      {
        text = "Hi! I work at a\nPOKéMON MART.",
        voice = VOICES.ROUTE1_MART_WORKER_INTRO,
      },
      {
        text = "It's a convenient\nshop, so please\nvisit us in\nVIRIDIAN CITY.",
        voice = VOICES.ROUTE1_MART_WORKER_VISIT,
      },
      {
        text = "I know, I'll give\nyou a sample!\nHere you go!",
        voice = VOICES.ROUTE1_MART_WORKER_SAMPLE,
      },
    },

    _Route1Youngster1AlsoGotPokeballsText = {
      {
        text = "We also carry\nPOKé BALLs for\ncatching POKéMON!",
        voice = VOICES.ROUTE1_MART_WORKER_POKEBALLS,
      },
    },

    _Route1Youngster2Text = {
      {
        text = "See those ledges\nalong the road?",
        voice = VOICES.ROUTE1_LEDGE_SEE,
      },
      {
        text = "It's a bit scary,\nbut you can jump\nfrom them.",
        voice = VOICES.ROUTE1_LEDGE_JUMP,
      },
      {
        text = "You can get back\nto PALLET TOWN\nquicker that way.",
        voice = VOICES.ROUTE1_LEDGE_QUICKER,
      },
    },


    -------------------------------------------------------------------------
    -- ROUTE 22 — FIRST RIVAL ENCOUNTER
    --
    -- story5.lua drives the ambush and battle using the original text label.
    -- These five pages replace only the pre-battle speech. The first supplied
    -- recording says only “Hey!”, so the dynamic rival/player names remain
    -- visible while the fixed spoken portion is voiced.
    -------------------------------------------------------------------------

    _Route22RivalBeforeBattleText1 = {
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return rival .. ": Hey!\n" .. player .. "!"
        end,
        voice = VOICES.ROUTE22_RIVAL1_HEY,
      },
      {
        text = "You're going to\nPOKéMON LEAGUE?",
        voice = VOICES.ROUTE22_RIVAL1_POKEMON_LEAGUE,
      },
      {
        text = "Forget it! You\nprobably don't\nhave any BADGEs!",
        voice = VOICES.ROUTE22_RIVAL1_NO_BADGES,
      },
      {
        text = "The guard won't\nlet you through!",
        voice = VOICES.ROUTE22_RIVAL1_GUARD,
      },
      {
        text = "By the way, did\nyour POKéMON\nget any stronger?",
        voice = VOICES.ROUTE22_RIVAL1_STRONGER,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN FOREST SOUTH GATE
    --
    -- The vanilla dialogue for each girl is stored as one text page. The user
    -- supplied two recordings per NPC, so each sentence is given its own
    -- advance point while the original interaction remains side-effect free.
    -------------------------------------------------------------------------

    _ViridianForestSouthGateGirlText = {
      {
        text = "Are you going to\nVIRIDIAN FOREST?",
        voice = VOICES.VIRIDIAN_FOREST_SOUTH_GATE_GIRL_FOREST,
      },
      {
        text = "Be careful, it's\na natural maze!",
        voice = VOICES.VIRIDIAN_FOREST_SOUTH_GATE_GIRL_MAZE,
      },
    },

    _ViridianForestSouthGateLittleGirlText = {
      {
        text = "RATTATA may be\nsmall, but its\nbite is wicked!",
        voice = VOICES.VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_RATTATA,
      },
      {
        text = "Did you get one?",
        voice = VOICES.VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_GOT_ONE,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN FOREST NORTH GATE
    -------------------------------------------------------------------------

    _ViridianForestNorthGateSuperNerdText = {
      {
        text = "Many POKéMON live\nonly in forests\nand caves.",
        voice = VOICES.VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_FORESTS_CAVES,
      },
      {
        text = "You need to look\neverywhere to get\ndifferent kinds!",
        voice = VOICES.VIRIDIAN_FOREST_NORTH_GATE_SUPER_NERD_LOOK_EVERYWHERE,
      },
    },

    _ViridianForestNorthGateGrampsText = {
      {
        text = "Have you noticed\nthe bushes on the\nroadside?",
        voice = VOICES.VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_ROADSIDE_BUSHES,
      },
      {
        text = "They can be cut\ndown by a special\nPOKéMON move.",
        voice = VOICES.VIRIDIAN_FOREST_NORTH_GATE_GRAMPS_SPECIAL_MOVE,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN FOREST — NPCs AND BUG CATCHERS
    --
    -- The three trainer defeat lines are also spoken on the battle screen;
    -- a BattleState message hook below attaches those voices there. Exact
    -- labels here cover pre-battle and post-battle overworld conversations.
    -------------------------------------------------------------------------

    _ViridianForestYoungster1Text = {
      {
        text = "I came here with\nsome friends!",
        voice = VOICES.VIRIDIAN_FOREST_YOUNGSTER1_FRIENDS,
      },
      {
        text = "They're out for\nPOKéMON fights!",
        voice = VOICES.VIRIDIAN_FOREST_YOUNGSTER1_POKEMON_FIGHTS,
      },
    },

    _ViridianForestYoungster2BattleText = {
      {
        text = "Hey! You have\nPOKéMON! Come on!\nLet's battle'em!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_BATTLE,
      },
    },
    _ViridianForestYoungster2EndBattleText = {
      {
        text = "No!\nCATERPIE can't\ncut it!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_DEFEAT,
      },
    },
    _ViridianForestYoungster2AfterBattleText = {
      {
        text = "Ssh! You'll scare\nthe bugs away!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_AFTER,
      },
    },

    _ViridianForestYoungster3BattleText = {
      {
        text = "Yo! You can't jam\nout if you're a\nPOKéMON trainer!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_BATTLE,
      },
    },
    _ViridianForestYoungster3EndBattleText = {
      {
        text = "Huh?\nI ran out of\nPOKéMON!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_DEFEAT,
      },
    },
    _ViridianForestYoungster3AfterBattleText = {
      {
        text = "Darn! I'm going\nto catch some\nstronger ones!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_AFTER,
      },
    },

    _ViridianForestYoungster4BattleText = {
      {
        text = "Hey, wait up!\nWhat's the hurry?",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_BATTLE,
      },
    },
    _ViridianForestYoungster4EndBattleText = {
      {
        text = "I give! You're good\nat this!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_DEFEAT,
      },
    },
    _ViridianForestYoungster4AfterBattleText = {
      {
        text = "Sometimes, you\ncan find stuff on\nthe ground!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_GROUND,
      },
      {
        text = "I'm looking for\nthe stuff I\ndropped!",
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_DROPPED,
      },
    },

    _ViridianForestYoungster5Text = {
      {
        text = "I ran out of POKé\nBALLs to catch\nPOKéMON with!",
        voice = VOICES.VIRIDIAN_FOREST_YOUNGSTER5_RAN_OUT_BALLS,
      },
      {
        text = "You should carry\nextras!",
        voice = VOICES.VIRIDIAN_FOREST_YOUNGSTER5_CARRY_EXTRAS,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN CITY — POKé BALL YOUNGSTER
    --
    -- The original first page contains the first two supplied sentences,
    -- followed by a paragraph break before the longer final thought. They
    -- are separated here so each recording begins on its own advance point.
    -------------------------------------------------------------------------

    _ViridianCityYoungster1Text = {
      {
        text = [[Those POKé BALLs
at your waist!]],
        voice = VOICES.VIRIDIAN_CITY_POKEBALLS_AT_WAIST,
      },
      {
        text = "You have POKéMON!",
        voice = VOICES.VIRIDIAN_CITY_YOU_HAVE_POKEMON,
      },
      {
        text = [[It's great that
you can carry and
use POKéMON any
time, anywhere!]],
        voice = VOICES.VIRIDIAN_CITY_CARRY_USE_ANYWHERE,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN CITY — AWAKE OLD MAN CATCHING TUTORIAL
    --
    -- The opening question is an `ask` command. Only its final page receives
    -- the original Yes/No options. The NO branch continues through four
    -- voiced explanation pages, runs the original Weedle-catching demo, then
    -- resumes on the final weakening-advice page. YES takes the short
    -- Time-is-money branch. No battle or script state is replaced here.
    -------------------------------------------------------------------------

    _ViridianCityOldManHadMyCoffeeNowText = {
      {
        text = [[Ahh, I've had my
coffee now and I
feel great!]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_HAD_COFFEE,
      },
      {
        text = [[Sure you can go
through!]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_GO_THROUGH,
      },
      {
        text = [[Are you in a
hurry?]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_IN_HURRY,
      },
    },

    _ViridianCityOldManKnowHowToCatchPokemonText = {
      {
        text = [[I see you're using
a POKéDEX.]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_USING_POKEDEX,
      },
      {
        text = [[When you catch a
POKéMON, POKéDEX
is automatically
updated.]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_POKEDEX_UPDATED,
      },
      {
        text = [[What? Don't you
know how to catch
POKéMON?]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_DONT_KNOW_CATCH,
      },
      {
        text = [[I'll show you
how to then.]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_SHOW_HOW,
      },
    },

    _ViridianCityOldManTimeIsMoneyText = {
      {
        text = [[Time is money...
Go along then.]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_TIME_IS_MONEY,
      },
    },

    _ViridianCityOldManYouNeedToWeakenTheTargetText = {
      {
        text = [[First, you need
to weaken the
target POKéMON.]],
        voice = VOICES.VIRIDIAN_CITY_OLD_MAN_WEAKEN_TARGET,
      },
    },


    -------------------------------------------------------------------------
    -- SHARED POKé MART FIXED DIALOGUE
    --
    -- These labels cover engine revisions that still expose the lines through
    -- Commands.show_text. The ListMenu/ShopMenu hooks above cover revisions
    -- that render them directly inside the shopping interface.
    -------------------------------------------------------------------------

    _PokemartGreetingText = {
      {
        text = "Hi there!\nMay I help you?",
        voice = VOICES.VIRIDIAN_MART_GREETING,
      },
    },

    _PokemartBuyingGreetingText = {
      {
        text = "Take your time.",
        voice = VOICES.VIRIDIAN_MART_TAKE_YOUR_TIME,
      },
    },

    _PokemartNotEnoughMoneyText = {
      {
        text = "You don't have\nenough money.",
        voice = VOICES.VIRIDIAN_MART_NOT_ENOUGH_MONEY,
      },
    },

    _PokemartItemBagFullText = {
      {
        text = "You can't carry\nany more items.",
        voice = VOICES.VIRIDIAN_MART_BAG_FULL,
      },
    },

    _PokemartSellingGreetingText = {
      {
        text = "What would you like\nto sell?",
        voice = VOICES.VIRIDIAN_MART_WHAT_TO_SELL,
      },
    },

    _PokemartNoItemsToSellText = {
      {
        text = "You don't have\nanything to sell.",
        voice = VOICES.VIRIDIAN_MART_NOTHING_TO_SELL,
      },
    },

    _PokemartUnsellableItemText = {
      {
        text = "I can't put a\nprice on that.",
        voice = VOICES.VIRIDIAN_MART_CANT_PRICE,
      },
    },

    _PokemartAnythingElseText = {
      {
        text = "Is there anything\nelse I can do?",
        voice = VOICES.VIRIDIAN_MART_ANYTHING_ELSE,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN POKé MART — OAK'S PARCEL
    --
    -- The first line runs on map entry. The clerk then moves the player to
    -- the counter. give_item adds OAKS_PARCEL before displaying the quest
    -- resource and arms its final page with the original key-item jingle.
    -------------------------------------------------------------------------

    _ViridianMartClerkYouCameFromPalletTownText = {
      {
        text = "Hey! You came from\nPALLET TOWN?",
        voice = VOICES.VIRIDIAN_MART_CAME_FROM_PALLET,
      },
    },

    _ViridianMartClerkParcelQuestText = {
      {
        text = "You know PROF.OAK,\nright?",
        voice = VOICES.VIRIDIAN_MART_KNOW_OAK,
      },
      {
        text = "His order came in.\nWill you take it\nto him?",
        voice = VOICES.VIRIDIAN_MART_TAKE_ORDER,
      },
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return player .. " got\nOAK's PARCEL!"
        end,

        -- Commands.give_item places the key-item jingle options in
        -- ctx.textOpts immediately before calling Commands.show_text.
        -- Apply those options only to this final system page.
        use_text_opts = true,
      },
    },

    _ViridianMartClerkSayHiToOakText = {
      {
        text = "Okay! Say hi to\nPROF.OAK for me!",
        voice = VOICES.VIRIDIAN_MART_SAY_HI,
      },
    },


    -------------------------------------------------------------------------
    -- OAK'S PARCEL AND POKéDEX EXCHANGE
    --
    -- The hand-ported Oak's Lab script retains all movement, inventory,
    -- flags, music changes, object visibility and item sounds. These entries
    -- replace only the spoken text pages.
    -------------------------------------------------------------------------

    _OaksLabOak1DeliverParcelText = {
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return "OAK: Oh, " .. player .. "!\nHow is my old\nPOKéMON?"
        end,
        voice = VOICES.OAK_PARCEL_OLD_POKEMON,
      },
      {
        text = "Well, it seems to\nlike you a lot.",
        voice = VOICES.OAK_PARCEL_LIKES_YOU,
      },
      {
        text = "You must be\ntalented as a\nPOKéMON trainer!",
        voice = VOICES.OAK_PARCEL_TALENTED,
      },
      {
        text = "What? You have\nsomething for me?",
        voice = VOICES.OAK_PARCEL_SOMETHING,
      },
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return player .. " delivered\nOAK's PARCEL."
        end,
      },
    },

    _OaksLabOak1ParcelThanksText = {
      {
        text = "Ah! This is the\ncustom POKé BALL\nI ordered!\nThank you!",
        voice = VOICES.OAK_PARCEL_CUSTOM_BALL,
      },
    },

    _OaksLabRivalGrampsText = {
      {
        text = function(game)
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return rival .. ": Gramps!"
        end,
        voice = VOICES.RIVAL_POKEDEX_GRAMPS,
      },
    },

    _OaksLabRivalWhatDidYouCallMeForText = {
      {
        text = function(game)
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return rival .. ": What did\nyou call me for?"
        end,
        voice = VOICES.RIVAL_POKEDEX_CALLED,
      },
    },

    _OaksLabOakIHaveARequestText = {
      {
        text = "OAK: Oh right! I\nhave a request of\nyou two.",
        voice = VOICES.OAK_POKEDEX_REQUEST,
      },
    },

    _OaksLabOakMyInventionPokedexText = {
      {
        text = "On the desk there\nis my invention,\nPOKéDEX!",
        voice = VOICES.OAK_POKEDEX_INVENTION,
      },
      {
        text = "It automatically\nrecords data on\nPOKéMON you've\nseen or caught!",
        voice = VOICES.OAK_POKEDEX_RECORDS,
      },
      {
        text = "It's a hi-tech\nencyclopedia!",
        voice = VOICES.OAK_POKEDEX_ENCYCLOPEDIA,
      },
    },

    _OaksLabOakGotPokedexText = {
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return "OAK: " .. player .. " and\n" .. rival
            .. "! Take\nthese with you!"
        end,
        voice = VOICES.OAK_POKEDEX_TAKE_THESE,
      },
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return player .. " got\nPOKéDEX from OAK!"
        end,
      },
    },

    _OaksLabOakThatWasMyDreamText = {
      {
        text = "To make a complete\nguide on all the\nPOKéMON in the\nworld...",
        voice = VOICES.OAK_DREAM_COMPLETE_GUIDE,
      },
      {
        text = "That was my dream!",
        voice = VOICES.OAK_DREAM_THAT_WAS,
      },
      {
        text = "But, I'm too old!\nI can't do it!",
        voice = VOICES.OAK_DREAM_TOO_OLD,
      },
      {
        text = "So, I want you two\nto fulfill my\ndream for me!",
        voice = VOICES.OAK_DREAM_FULFILL,
      },
      {
        text = "Get moving, you\ntwo!",
        voice = VOICES.OAK_DREAM_GET_MOVING,
      },
      {
        text = "This is a great\nundertaking in\nPOKéMON history!",
        voice = VOICES.OAK_DREAM_UNDERTAKING,
      },
    },

    _OaksLabRivalLeaveItAllToMeText = {
      {
        text = function(game)
          local rival = game
            and game.save
            and game.save.player
            and game.save.player.rival
            or "RIVAL"

          return rival .. ": Alright\nGramps! Leave it\nall to me!"
        end,
        voice = VOICES.RIVAL_POKEDEX_LEAVE_TO_ME,
      },
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return player .. ", I hate to\nsay it, but I\ndon't need you!"
        end,
        voice = VOICES.RIVAL_POKEDEX_DONT_NEED,
      },
      {
        text = "I know! I'll\nborrow a TOWN MAP\nfrom my sis!",
        voice = VOICES.RIVAL_POKEDEX_BORROW_MAP,
      },
      {
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return "I'll tell her not\nto lend you one,\n"
            .. player .. "! Hahaha!"
        end,
        voice = VOICES.RIVAL_POKEDEX_DONT_LEND,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN SCHOOL HOUSE
    --
    -- The instructor's vanilla text uses a paragraph break after "Okay!".
    -- The supplied recording reads the complete response continuously, so it
    -- is presented as one four-line box while keeping the same full wording.
    -------------------------------------------------------------------------

    _ViridianSchoolHouseBrunetteGirlText = {
      {
        text = "Whew! I'm trying\nto memorize all\nmy notes.",
        voice = VOICES.VIRIDIAN_SCHOOL_MEMORIZE_NOTES,
      },
    },

    _ViridianSchoolHouseCooltrainerFText = {
      {
        text = "Okay!\nBe sure to read\nthe blackboard\ncarefully!",
        voice = VOICES.VIRIDIAN_SCHOOL_READ_BLACKBOARD,
      },
    },


    -------------------------------------------------------------------------
    -- VIRIDIAN NICKNAME HOUSE
    --
    -- The balding man's original dialogue has two paragraphs. Each supplied
    -- recording is attached to its original page, preserving the vanilla
    -- advance point and complete wording.
    -------------------------------------------------------------------------

    _ViridianNicknameHouseBaldingGuyText = {
      {
        text = "Coming up with\nnicknames is fun,\nbut hard.",
        voice = VOICES.VIRIDIAN_NICKNAME_NICKNAMES_FUN_HARD,
      },
      {
        text = "Simple names are\nthe easiest to\nremember.",
        voice = VOICES.VIRIDIAN_NICKNAME_SIMPLE_NAMES,
      },
    },

    _ViridianNicknameHouseLittleGirlText = {
      {
        text = "My Daddy loves\nPOKéMON too.",
        voice = VOICES.VIRIDIAN_NICKNAME_DADDY_LOVES_POKEMON,
      },
    },


    _OaksLabOak1PokemonAroundTheWorldText = {
      {
        -- The supplied recording omits the dynamic player name.
        text = function(game)
          local player = game
            and game.save
            and game.save.player
            and game.save.player.name
            or "PLAYER"

          return "POKéMON around the\nworld wait for\nyou, "
            .. player .. "!"
        end,
        voice = VOICES.OAK_POKEDEX_AROUND_WORLD,
      },
    },

  }

  -- Publish the current table outside this module closure. This means a
  -- replacement version can update the active dialogue mappings even when
  -- the application hot-reloads the mod without recreating Commands.
  Commands._pokemonRedVoiceDialoguePages = VOICED_SCRIPT_PAGES

  local function resolvedVoiceText(ctx, textId, subs)
    local game = ctx and ctx.game
    local text = game
      and game.data
      and game.data.text
      and game.data.text[textId]
      or nil

    if not text
      and game
      and game.data
      and ctx.overworld
      and ctx.overworld.map
    then
      text = game.data:resolveText(
        ctx.overworld.map.def.label,
        textId
      )
    end

    if not text then
      text = textId
    end

    text = tostring(text or "")

    if subs then
      for token, value in pairs(subs) do
        text = text:gsub(
          "{" .. token .. ":?[%w_]*}",
          tostring(value)
        )
      end
    end

    return text
  end

  local function pagesForScriptText(ctx, textId, subs)
    local currentPages = Commands._pokemonRedVoiceDialoguePages
      or VOICED_SCRIPT_PAGES
    local pages = currentPages[textId]

    if pages then
      return pages
    end

    local mapId = ctx
      and ctx.overworld
      and ctx.overworld.map
      and ctx.overworld.map.id
      or nil

    if mapId ~= "ROUTE_1" then
      return nil
    end

    -- Route 1's Potion worker is a hand-ported text_asm interaction. Match
    -- the actual resolved text as a fallback instead of relying exclusively
    -- on a generated label spelling. The script itself still continues after
    -- this box, so it retains the event flag, Potion award and item jingle.
    local normalized = resolvedVoiceText(ctx, textId, subs)
      :upper()
      :gsub("[%c]", " ")
      :gsub("%s+", " ")

    if normalized:find("WORK AT A", 1, true)
      and normalized:find("VIRIDIAN CITY", 1, true)
    then
      return currentPages._Route1Youngster1MartSampleText
    end

    if normalized:find("WE ALSO CARRY", 1, true)
      and normalized:find("CATCHING", 1, true)
    then
      return currentPages._Route1Youngster1AlsoGotPokeballsText
    end

    if normalized:find("SEE THOSE LEDGES", 1, true)
      and normalized:find("PALLET TOWN", 1, true)
    then
      return currentPages._Route1Youngster2Text
    end

    return nil
  end

  -- Fresh loads capture vanilla/other-mod Commands.show_text. A hot upgrade
  -- from an older voice-mod build captures that older wrapper underneath us;
  -- unmatched text still delegates correctly, while this version's current
  -- table takes precedence.
  local previousShowText =
    Commands._pokemonRedVoiceBaseShowText or Commands.show_text
  Commands._pokemonRedVoiceBaseShowText = previousShowText
  Commands._pokemonRedVoiceDialogueWrappedVersion = "1.17.0"

  function Commands.show_text(ctx, textId, subs, extraOpts)
    local pages = pagesForScriptText(ctx, textId, subs)

    if textId == "_PokemartGreetingText" and ctx and ctx.game then
      ctx.game._pokemonRedVoiceMartGreetingPrimed = true
    end

    if not pages then
      return previousShowText(ctx, textId, subs, extraOpts)
    end

    local runner = ctx.runner

    -- Most voiced dialogue has no armed text options. Gift commands are an
    -- exception: Commands.give_item stores the item jingle on ctx.textOpts
    -- immediately before calling show_text. Capture it only when a page
    -- explicitly requests it, and remove it from the context just as the
    -- original Commands.show_text would.
    local armedTextOpts = nil

    for _, page in ipairs(pages) do
      if page.use_text_opts then
        armedTextOpts = ctx.textOpts
        ctx.textOpts = nil
        break
      end
    end

    local function showPage(index)
      local page = pages[index]

      if not page then
        stopActiveVoice()
        runner:resume()
        return
      end

      local pageText = type(page.text) == "function"
        and page.text(ctx.game)
        or page.text

      if page.voice then
        startVoiceForGame(ctx.game, page.voice)
      else
        stopActiveVoice()
      end

      local pageOpts = nil

      if page.use_text_opts and armedTextOpts then
        pageOpts = {}
        for key, value in pairs(armedTextOpts) do
          pageOpts[key] = value
        end
      end

      if index == #pages and extraOpts then
        pageOpts = pageOpts or {}
        for key, value in pairs(extraOpts) do
          pageOpts[key] = value
        end
      end

      -- Choice callbacks replace TextBox.onDone. Stop the current line before
      -- resuming the script branch, just as normal page completion does.
      if pageOpts and pageOpts.choice then
        local originalChoice = pageOpts.choice
        pageOpts.choice = function(yes)
          stopActiveVoice()
          originalChoice(yes)
        end
      end

      ctx.game.stack:push(TextBox.new(
        ctx.game,
        pageText,
        function()
          stopActiveVoice()
          showPage(index + 1)
        end,
        pageOpts
      ))
    end

    showPage(1)
    runner:yield()
  end


  ---------------------------------------------------------------------------
  -- OAK'S LAB LOSS TAUNT INSIDE BATTLE
  --
  -- The player's-loss line is queued directly by BattleState:sayNext as
  -- _Rival1WinText, so it never reaches Commands.show_text. Start its voice
  -- when the battle message itself begins, and stop it when that queue item
  -- is dismissed.
  ---------------------------------------------------------------------------

  local BattleState = require("src.battle.BattleState")

  if not BattleState._pokemonRedVoiceOutcomeWrapped then
    BattleState._pokemonRedVoiceOutcomeWrapped = true

    local previousStartMessage = BattleState.startMessage
    local previousUpdateQueue = BattleState.updateQueue

    function BattleState:startMessage(item)
      local text = item and item.text or ""
      local isLabRival = BattleState.isOaksLabStarterRival
        and BattleState.isOaksLabStarterRival(self)

      if isLabRival
        and text:find("Yeah! Am", 1, true)
        and text:find("great or what?", 1, true)
      then
        item._pokemonRedVoiceOutcome = true
        startVoiceForGame(self.game, VOICES.LAB_RIVAL_LOSS_GREAT)
      end

      return previousStartMessage(self, item)
    end

    function BattleState:updateQueue(...)
      local voicedItem = self.current
        and self.current._pokemonRedVoiceOutcome
        and self.current
        or nil

      local result = previousUpdateQueue(self, ...)

      if voicedItem and self.current ~= voicedItem then
        stopActiveVoice()
      end

      return result
    end
  end

  ---------------------------------------------------------------------------
  -- VIRIDIAN FOREST TRAINER DEFEAT VOICES INSIDE BATTLE
  --
  -- Generic trainers bypass Commands.show_text. Their EndBattleText is queued
  -- directly in BattleState after the defeated trainer slides back onscreen.
  -- Match the three exact Viridian Forest loss messages at that queue boundary.
  -- The trainer-class check is retained as a fallback because some builds
  -- release the overworld map reference during the battle return sequence.
  ---------------------------------------------------------------------------

  local previousForestTrainerStartMessage =
    BattleState._pokemonRedVoiceForestTrainerBaseStartMessage
      or BattleState.startMessage
  BattleState._pokemonRedVoiceForestTrainerBaseStartMessage =
    previousForestTrainerStartMessage
  BattleState._pokemonRedVoiceForestTrainerWrappedVersion = "1.17.8"

  function BattleState:startMessage(item)
    local text = tostring(item and item.text or "")
    local normalized = text:upper():gsub("[%c]", " "):gsub("%s+", " ")
    local mapId = BattleState.currentMapId
      and BattleState.currentMapId(self)
      or nil
    local trainerName = self.trainer and tostring(self.trainer.name or "") or ""
    local isBugCatcher = trainerName:upper():find("BUG CATCHER", 1, true) ~= nil
    local voice = nil

    if mapId == "VIRIDIAN_FOREST" or isBugCatcher then
      if normalized:find("CATERPIE", 1, true)
        and normalized:find("CUT IT", 1, true)
      then
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_DEFEAT
      elseif normalized:find("RAN OUT OF", 1, true)
        and normalized:find("POK", 1, true)
      then
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_DEFEAT
      elseif normalized:find("I GIVE!", 1, true)
        and normalized:find("YOU'RE GOOD", 1, true)
      then
        voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_DEFEAT
      end
    end

    if voice then
      item._pokemonRedVoiceOutcome = true
      startVoiceForGame(self.game, voice)
    end

    return previousForestTrainerStartMessage(self, item)
  end


  ---------------------------------------------------------------------------
  -- MAP NPC VOICE ROUTING
  --
  -- Stable object indices avoid differences in imported text constants.
  --
  -- PALLET TOWN: 2 = girl, 3 = technology enthusiast
  -- ROUTE 1: 2 = ledge youngster fallback only
  -- VIRIDIAN MART: 2 = Antidote youngster, 3 = sold-out visitor
  -- OAK'S LAB: 1 = rival, 9 = girl, 10/11 = scientist aides
  ---------------------------------------------------------------------------

  local OverworldState = require("src.world.OverworldController")

  local PALLET_GIRL_PAGES = {
    {
      text = "I'm raising\nPOKéMON too!",
      voice = VOICES.PALLET_GIRL_RAISING,
    },
    {
      text = "When they get\nstrong, they can\nprotect me!",
      voice = VOICES.PALLET_GIRL_PROTECTION,
    },
  }

  local PALLET_MAN_PAGES = {
    {
      text = "Technology is\namazing!",
      voice = VOICES.PALLET_MAN_TECHNOLOGY,
    },
    {
      text = "You can now store\nand recall items\nand POKéMON as data\nvia PC!",
      voice = VOICES.PALLET_MAN_PC_STORAGE,
    },
  }

  local VIRIDIAN_MART_YOUNGSTER_PAGES = {
    {
      text = "This shop sells\nmany ANTIDOTEs.",
      voice = VOICES.VIRIDIAN_MART_MANY_ANTIDOTES,
    },
  }

  local VIRIDIAN_MART_COOLTRAINER_PAGES = {
    {
      text = "No! POTIONs are\nall sold out.",
      voice = VOICES.VIRIDIAN_MART_POTIONS_SOLD_OUT,
    },
  }

  local VIRIDIAN_SCHOOL_BRUNETTE_PAGES = {
    {
      text = "Whew! I'm trying\nto memorize all\nmy notes.",
      voice = VOICES.VIRIDIAN_SCHOOL_MEMORIZE_NOTES,
    },
  }

  local VIRIDIAN_SCHOOL_COOLTRAINER_PAGES = {
    {
      text = "Okay!\nBe sure to read\nthe blackboard\ncarefully!",
      voice = VOICES.VIRIDIAN_SCHOOL_READ_BLACKBOARD,
    },
  }

  local VIRIDIAN_NICKNAME_BALDING_GUY_PAGES = {
    {
      text = "Coming up with\nnicknames is fun,\nbut hard.",
      voice = VOICES.VIRIDIAN_NICKNAME_NICKNAMES_FUN_HARD,
    },
    {
      text = "Simple names are\nthe easiest to\nremember.",
      voice = VOICES.VIRIDIAN_NICKNAME_SIMPLE_NAMES,
    },
  }

  local VIRIDIAN_NICKNAME_LITTLE_GIRL_PAGES = {
    {
      text = "My Daddy loves\nPOKéMON too.",
      voice = VOICES.VIRIDIAN_NICKNAME_DADDY_LOVES_POKEMON,
    },
  }

  local VIRIDIAN_FOREST_SOUTH_GATE_GIRL_PAGES =
    VOICED_SCRIPT_PAGES._ViridianForestSouthGateGirlText

  local VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_PAGES =
    VOICED_SCRIPT_PAGES._ViridianForestSouthGateLittleGirlText

  local OAKS_LAB_AIDE_PAGES = {
    {
      text = "I study POKéMON as\nPROF. OAK's AIDE.",
      voice = VOICES.OAKS_LAB_AIDE,
    },
  }

  local OAKS_LAB_GIRL_PAGES = {
    {
      text = "PROF. OAK is the\nauthority on\nPOKéMON!",
      voice = VOICES.OAKS_LAB_GIRL_AUTHORITY,
    },
    {
      text = "Many POKéMON\ntrainers hold him\nin high regard!",
      voice = VOICES.OAKS_LAB_GIRL_REGARD,
    },
  }

  local OAKS_LAB_RIVAL_ABSENT_PAGES = {
    {
      text = function(game)
        local rival = game
          and game.save
          and game.save.player
          and game.save.player.rival
          or "RIVAL"

        return rival .. ": Yo!\nGramps isn't\naround!"
      end,
      voice = VOICES.OAKS_LAB_RIVAL_GRAMPS_ABSENT,
    },
  }

  local function pagesForNpc(game, overworld, npc)
    if not overworld or not overworld.map or not npc or not npc.def then
      return nil
    end

    local mapId = overworld.map.id
    local index = npc.def.index

    if mapId == "PALLET_TOWN" then
      if index == 2 then
        return PALLET_GIRL_PAGES
      elseif index == 3 then
        return PALLET_MAN_PAGES
      end
      return nil
    end

    -- Route 1 object 2 is the ledge youngster. This side-effect-free fallback
    -- covers builds that display his extracted text directly instead of
    -- passing through Commands.show_text. Object 1 is intentionally excluded
    -- because its original script awards the Potion sample.
    if mapId == "ROUTE_1" then
      if index == 2 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._Route1Youngster2Text
          or VOICED_SCRIPT_PAGES._Route1Youngster2Text
      end
      return nil
    end

    if mapId == "VIRIDIAN_FOREST" then
      if index == 1 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._ViridianForestYoungster1Text
          or VOICED_SCRIPT_PAGES._ViridianForestYoungster1Text
      elseif index == 8 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._ViridianForestYoungster5Text
          or VOICED_SCRIPT_PAGES._ViridianForestYoungster5Text
      end
      return nil
    end

    if mapId == "VIRIDIAN_FOREST_NORTH_GATE" then
      if index == 1 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._ViridianForestNorthGateSuperNerdText
          or VOICED_SCRIPT_PAGES._ViridianForestNorthGateSuperNerdText
      elseif index == 2 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._ViridianForestNorthGateGrampsText
          or VOICED_SCRIPT_PAGES._ViridianForestNorthGateGrampsText
      end
      return nil
    end

    if mapId == "VIRIDIAN_FOREST_SOUTH_GATE" then
      if index == 1 then
        return VIRIDIAN_FOREST_SOUTH_GATE_GIRL_PAGES
      elseif index == 2 then
        return VIRIDIAN_FOREST_SOUTH_GATE_LITTLE_GIRL_PAGES
      end
      return nil
    end

    if mapId == "VIRIDIAN_CITY" then
      if index == 1 then
        return Commands._pokemonRedVoiceDialoguePages
          and Commands._pokemonRedVoiceDialoguePages._ViridianCityYoungster1Text
          or VOICED_SCRIPT_PAGES._ViridianCityYoungster1Text
      end
      return nil
    end

    if mapId == "VIRIDIAN_MART" then
      if index == 2 then
        return VIRIDIAN_MART_YOUNGSTER_PAGES
      elseif index == 3 then
        return VIRIDIAN_MART_COOLTRAINER_PAGES
      end
      return nil
    end

    if mapId == "VIRIDIAN_SCHOOL_HOUSE" then
      if index == 1 then
        return VIRIDIAN_SCHOOL_BRUNETTE_PAGES
      elseif index == 2 then
        return VIRIDIAN_SCHOOL_COOLTRAINER_PAGES
      end
      return nil
    end

    if mapId == "VIRIDIAN_NICKNAME_HOUSE" then
      if index == 1 then
        return VIRIDIAN_NICKNAME_BALDING_GUY_PAGES
      elseif index == 2 then
        return VIRIDIAN_NICKNAME_LITTLE_GIRL_PAGES
      end
      return nil
    end

    if mapId ~= "OAKS_LAB" then
      return nil
    end

    if index == 9 then
      return OAKS_LAB_GIRL_PAGES
    elseif index == 10 or index == 11 then
      return OAKS_LAB_AIDE_PAGES
    elseif index == 1 then
      local flags = game and game.save and game.save.flags or {}
      if not flags.EVENT_FOLLOWED_OAK_INTO_LAB
        and not flags.EVENT_GOT_STARTER
      then
        return OAKS_LAB_RIVAL_ABSENT_PAGES
      end
    end

    return nil
  end

  if OverworldState._pokemonRedVoiceNpcIndexWrappedVersion ~= "1.17.5" then
    OverworldState._pokemonRedVoiceNpcIndexWrappedVersion = "1.17.5"
    OverworldState._pokemonRedVoiceNpcIndexWrapped = true

    local previousShowMapText = OverworldState.showMapText

    function OverworldState:showMapText(textConst, npc, onDone)
      local game = self.runner and self.runner.game
        or require("src.core.Game")

      -----------------------------------------------------------------------
      -- VIRIDIAN CITY FISHER — TM42 DREAM EATER
      --
      -- Gen1Recomp's generic gift entry currently omits the original Fisher's
      -- three-page pre-gift speech. Handle this one interaction here so the
      -- voiced pages, bag-full retry, item award, event flag and repeat-visit
      -- explanation follow the Pokémon Red script exactly.
      -----------------------------------------------------------------------

      local viridianFisher =
        self.map
        and self.map.id == "VIRIDIAN_CITY"
        and (
          textConst == "TEXT_VIRIDIANCITY_FISHER"
          or (npc and npc.def and npc.def.index == 6)
        )

      if viridianFisher then
        if npc then npc:facePlayer(self.player) end

        local function finish()
          stopActiveVoice()
          if onDone then onDone() end
        end

        local function voiced(text, voice, done)
          startVoiceForGame(game, voice)
          game.stack:push(TextBox.new(game, text, function()
            stopActiveVoice()
            if done then done() end
          end))
        end

        local function showExplanation()
          voiced(
            "TM42 contains\nDREAM EATER...\v...Snore...",
            VOICES.VIRIDIAN_CITY_FISHER_DREAM_EATER,
            finish
          )
        end

        if game.save.flags.EVENT_GOT_TM42 then
          showExplanation()
          return
        end

        local function tryGiveTM()
          local added = require("src.inventory.Bag").add(
            game.save,
            "TM_DREAM_EATER",
            1
          )

          if not added then
            voiced(
              "You have too much\nstuff already.",
              VOICES.VIRIDIAN_CITY_FISHER_BAG_FULL,
              finish
            )
            return
          end

          require("src.core.Sound").play(game.data, "Get_Item1")

          local player = game.save.player and game.save.player.name
            or "PLAYER"
          local received = game.data.text
            and game.data.text._ViridianCityFisherReceivedTM42Text
            or "{PLAYER} received\nTM42!"
          received = tostring(received):gsub("{PLAYER}", player)

          game.stack:push(TextBox.new(game, received, function()
            game.save.flags.EVENT_GOT_TM42 = true
            finish()
          end))
        end

        voiced(
          "Yawn!\nI must have dozed\voff in the sun.",
          VOICES.VIRIDIAN_CITY_FISHER_DOZED_OFF,
          function()
            voiced(
              "I had this dream\nabout a DROWZEE\veating my dream.\vWhat's this?\vWhere did this TM\vcome from?",
              VOICES.VIRIDIAN_CITY_FISHER_DROWZEE_DREAM,
              function()
                voiced(
                  "This is spooky!\nHere, you can\vhave this TM.",
                  VOICES.VIRIDIAN_CITY_FISHER_HAVE_TM,
                  tryGiveTM
                )
              end
            )
          end
        )
        return
      end

      local pages = pagesForNpc(game, self, npc)

      if not pages then
        return previousShowMapText(self, textConst, npc, onDone)
      end

      npc:facePlayer(self.player)

      local function showPage(index)
        local page = pages[index]

        if not page then
          stopActiveVoice()
          if onDone then onDone() end
          return
        end

        local text = type(page.text) == "function"
          and page.text(game)
          or page.text

        startVoiceForGame(game, page.voice)

        game.stack:push(TextBox.new(
          game,
          text,
          function()
            stopActiveVoice()
            showPage(index + 1)
          end
        ))
      end

      showPage(1)
    end
  end

  ---------------------------------------------------------------------------
  -- OAK'S FIRST PALLET TOWN ESCORT
  --
  -- data/scripts/story2.lua constructs these TextBoxes directly inside
  -- PALLET_TOWN.onStep, bypassing Commands.show_text and showMapText.
  -- Match the two cutscene text resources at TextBox.new, while leaving
  -- Oak's movement, exclamation bubble, music and lab-warp callbacks intact.
  ---------------------------------------------------------------------------

  if TextBox._pokemonRedVoiceTextBoxWrappedVersion ~= "1.17.10" then
    TextBox._pokemonRedVoiceTextBoxWrappedVersion = "1.17.10"

    local previousTextBoxNew = TextBox.new

    local function matchesGameText(game, text, key, fallback)
      local dataText = game
        and game.data
        and game.data.text
        or nil
      local expected = dataText and dataText[key] or nil

      return (expected ~= nil and text == expected)
        or text == fallback
    end


    -- Set only while a Cable Club No response is being resolved. Weak keys
    -- prevent a finished game instance from being retained by the mod.
    local cableClubFarewellPending = setmetatable({}, { __mode = "k" })

    function TextBox.new(game, text, onDone, opts)
      local flags = game and game.save and game.save.flags or {}

      -----------------------------------------------------------------------
      -- ROUTE 1 POKÉ MART WORKER
      --
      -- This NPC is a text_asm script. Its first and repeat speeches are
      -- created by nested PrintText calls after showMapText has already
      -- entered the script, so ordinary text-ID and object-index replacement
      -- cannot safely intercept them.
      --
      -- Match the final resolved TextBox content instead. The original onDone
      -- callback is invoked only after the final voiced page, allowing the
      -- vanilla script to continue with the Potion award, event flag, Bag-full
      -- handling and item jingle.
      -----------------------------------------------------------------------

      local normalizedBoxText = tostring(text or "")
        :upper()
        :gsub("[%c]", " ")
        :gsub("%s+", " ")

      -----------------------------------------------------------------------
      -- SHARED POKéMON CENTER NURSE
      --
      -- The original routine presents the welcome text, an optional first-use
      -- question, a Yes/No menu, the healing sequence and a shared farewell.
      -- Final TextBox matching preserves all original callbacks and effects.
      -----------------------------------------------------------------------

      -----------------------------------------------------------------------
      -- SHARED POKéMON CENTER NURSE — CORRECT PAGE AND MENU FLOW
      --
      -- First visit:
      --   Welcome -> perfect health -> shall we heal -> Yes/No
      --
      -- Later visits:
      --   Welcome -> perfect health -> Yes/No
      --
      -- A TextBox with opts.choice calls that choice callback instead of its
      -- onDone callback. Therefore, choice options belong only on the final
      -- opening page.
      -----------------------------------------------------------------------

      local function wrappedChoiceOptions(original, beforeChoice)
        if not original then
          return nil
        end

        local copy = {}

        for key, value in pairs(original) do
          copy[key] = value
        end

        if original.choice then
          copy.choice = function(yes)
            stopActiveVoice()
            if beforeChoice then
              beforeChoice(yes)
            end
            original.choice(yes)
          end
        end

        return copy
      end

      -- Build a sequence without recursively entering this wrapper. Only the
      -- final page receives the original options, so a Yes/No callback cannot
      -- fire early from one of the newly separated voiced pages.
      local function voicedBoxSequence(pages, finalOnDone, finalOpts)
        local function showPage(index)
          local page = pages[index]

          if not page then
            stopActiveVoice()
            if finalOnDone then
              finalOnDone()
            end
            return nil
          end

          if page.voice then
            startVoiceForGame(game, page.voice)
          else
            stopActiveVoice()
          end

          local isFinal = index == #pages
          local box = previousTextBoxNew(
            game,
            page.text,
            function()
              stopActiveVoice()
              showPage(index + 1)
            end,
            isFinal and finalOpts or nil
          )

          if index == 1 then
            return box
          end

          game.stack:push(box)
          return nil
        end

        return showPage(1)
      end

      -----------------------------------------------------------------------
      -- VIRIDIAN FOREST BUG CATCHERS — DIRECT TRAINER TEXTBOXES
      --
      -- OverworldController:engageTrainer creates the challenge TextBox
      -- directly, and defeated-trainer interactions create the after-battle
      -- TextBox directly as well. Neither path calls Commands.show_text, so
      -- label-based voiced pages cannot run. Match these fixed texts at the
      -- TextBox constructor while leaving the original battle callback intact.
      -----------------------------------------------------------------------

      local currentMapId = game
        and game.overworld
        and game.overworld.map
        and game.overworld.map.id
        or (game and game.save and game.save.player and game.save.player.map)

      if currentMapId == "VIRIDIAN_FOREST" then
        local forestTrainerVoice = nil

        if normalizedBoxText:find("HEY! YOU HAVE", 1, true)
          and normalizedBoxText:find("COME ON!", 1, true)
          and normalizedBoxText:find("BATTLE", 1, true)
        then
          forestTrainerVoice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_BATTLE
        elseif normalizedBoxText:find("SCARE", 1, true)
          and normalizedBoxText:find("BUGS AWAY", 1, true)
        then
          forestTrainerVoice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER1_AFTER
        elseif normalizedBoxText:find("JAM OUT", 1, true)
          and normalizedBoxText:find("TRAINER", 1, true)
        then
          forestTrainerVoice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_BATTLE
        elseif normalizedBoxText:find("DARN!", 1, true)
          and normalizedBoxText:find("STRONGER ONES", 1, true)
        then
          forestTrainerVoice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER2_AFTER
        elseif normalizedBoxText:find("WAIT UP", 1, true)
          and normalizedBoxText:find("WHAT'S THE HURRY", 1, true)
        then
          forestTrainerVoice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_BATTLE
        end

        if forestTrainerVoice then
          startVoiceForGame(game, forestTrainerVoice)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        local forestTrainer3After =
          normalizedBoxText:find("FIND STUFF", 1, true)
          and normalizedBoxText:find("GROUND", 1, true)
          and normalizedBoxText:find("LOOKING FOR", 1, true)
          and normalizedBoxText:find("DROPPED", 1, true)

        if forestTrainer3After then
          return voicedBoxSequence({
            {
              text = [[Sometimes, you
can find stuff on
the ground!]],
              voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_GROUND,
            },
            {
              text = [[I'm looking for
the stuff I
dropped!]],
              voice = VOICES.VIRIDIAN_FOREST_BUG_CATCHER3_AFTER_DROPPED,
            },
          }, onDone, opts)
        end
      end

      -----------------------------------------------------------------------
      -- PEWTER CITY — OUTDOOR NPCs
      --
      -- The two Super Nerd interactions and Brock escort youngster are
      -- hand-ported direct TextBoxes, so source-label hooks do not reliably
      -- reach them. Match all five outdoor NPCs here. The youngster's first
      -- vanilla page is split only to accommodate the separately recorded
      -- "Follow me!" clip; the original escort callback runs after page two.
      -----------------------------------------------------------------------

      if currentMapId == "PEWTER_CITY" then
        local pewterCooltrainerM =
          normalizedBoxText:find("AREN'T MANY SERIOUS", 1, true)
          and normalizedBoxText:find("BUG CATCHER", 1, true)
          and normalizedBoxText:find("BROCK", 1, true)

        if pewterCooltrainerM then
          return voicedBoxSequence({
            {
              text = [[There aren't many
serious POKéMON
trainers here!]],
              voice = VOICES.PEWTER_CITY_COOLTRAINER_M_SERIOUS,
            },
            {
              text = [[They're all like
BUG CATCHERs,
but PEWTER GYM's
BROCK is totally
into it!]],
              voice = VOICES.PEWTER_CITY_COOLTRAINER_M_BROCK,
            },
          }, onDone, opts)
        end

        local pewterCooltrainerF =
          normalizedBoxText:find("CLEFAIRY", 1, true)
          and normalizedBoxText:find("FROM THE MOON", 1, true)
          and normalizedBoxText:find("MOON STONE", 1, true)

        if pewterCooltrainerF then
          return voicedBoxSequence({
            {
              text = [[It's rumored that
CLEFAIRYs came
from the moon!]],
              voice = VOICES.PEWTER_CITY_COOLTRAINER_F_CLEFAIRY,
            },
            {
              text = [[They appeared
after MOON STONE
fell on MT.MOON.]],
              voice = VOICES.PEWTER_CITY_COOLTRAINER_F_MOON_STONE,
            },
          }, onDone, opts)
        end

        if normalizedBoxText:find("DID YOU CHECK OUT", 1, true)
          and normalizedBoxText:find("MUSEUM", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD1_MUSEUM)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        if normalizedBoxText:find("WEREN'T THOSE", 1, true)
          and normalizedBoxText:find("FOSSILS", 1, true)
          and normalizedBoxText:find("AMAZING", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD1_FOSSILS)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        if normalizedBoxText:find("REALLY?", 1, true)
          and normalizedBoxText:find("ABSOLUTELY", 1, true)
          and normalizedBoxText:find("HAVE TO GO", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD1_HAVE_TO_GO)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        if normalizedBoxText:find("PSSSST", 1, true)
          and normalizedBoxText:find("KNOW WHAT", 1, true)
          and normalizedBoxText:find("I'M DOING", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD2_WHAT_DOING)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        if normalizedBoxText:find("THAT'S RIGHT", 1, true)
          and normalizedBoxText:find("HARD WORK", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD2_HARD_WORK)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        if normalizedBoxText:find("SPRAYING REPEL", 1, true)
          and normalizedBoxText:find("OUT OF MY GARDEN", 1, true)
        then
          startVoiceForGame(game, VOICES.PEWTER_CITY_SUPER_NERD2_REPEL)
          return previousTextBoxNew(game, text, function()
            stopActiveVoice()
            if onDone then onDone() end
          end, opts)
        end

        local pewterYoungsterFollow =
          normalizedBoxText:find("YOU'RE A TRAINER", 1, true)
          and normalizedBoxText:find("BROCK", 1, true)
          and normalizedBoxText:find("CHALLENGERS", 1, true)
          and normalizedBoxText:find("FOLLOW ME", 1, true)

        if pewterYoungsterFollow then
          return voicedBoxSequence({
            {
              text = [[You're a trainer
right? BROCK's
looking for new
challengers!]],
              voice = VOICES.PEWTER_CITY_YOUNGSTER_CHALLENGERS,
            },
            {
              text = "Follow me!",
              voice = VOICES.PEWTER_CITY_YOUNGSTER_FOLLOW_ME,
            },
          }, onDone, opts)
        end

        local pewterYoungsterGym =
          normalizedBoxText:find("TAKE ON BROCK", 1, true)
          and (
            normalizedBoxText:find("RIGHT STUFF", 1, true)
            or normalizedBoxText:find("GYM FIRST", 1, true)
          )

        if pewterYoungsterGym then
          startVoiceForGame(game, VOICES.PEWTER_CITY_YOUNGSTER_TAKE_ON_BROCK)
          return previousTextBoxNew(
            game,
            [[If you have the
right stuff, go
take on BROCK!]],
            function()
              stopActiveVoice()
              if onDone then onDone() end
            end,
            opts
          )
        end
      end

      -----------------------------------------------------------------------
      -- VIRIDIAN CITY YOUNGSTER — CATERPIE / WEEDLE TUTORIAL
      --
      -- The engine's flavor script shows the question, then pushes its own
      -- ChoiceBox from the original TextBox onDone callback. YES creates one
      -- two-page TextBox; NO creates the short refusal TextBox. We therefore
      -- voice the question without replacing its callback, split only the
      -- two-page YES response, and leave the ChoiceBox and branch selection
      -- entirely under the original script's control.
      -----------------------------------------------------------------------

      local viridianCaterpillarQuestion =
        normalizedBoxText:find("YOU WANT TO KNOW", 1, true)
        and normalizedBoxText:find("2 KINDS", 1, true)
        and normalizedBoxText:find("CATERPILLAR", 1, true)
        and normalizedBoxText:find("POK", 1, true)

      if viridianCaterpillarQuestion then
        startVoiceForGame(game, VOICES.VIRIDIAN_CITY_CATERPILLAR_QUESTION)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      local viridianCaterpieWeedle =
        normalizedBoxText:find("CATERPIE HAS NO", 1, true)
        and normalizedBoxText:find("WEEDLE DOES", 1, true)
        and normalizedBoxText:find("POISON STING", 1, true)

      if viridianCaterpieWeedle then
        return voicedBoxSequence({
          {
            text = [[CATERPIE has no
poison, but
WEEDLE does.]],
            voice = VOICES.VIRIDIAN_CITY_CATERPIE_WEEDLE,
          },
          {
            text = [[Watch out for its
POISON STING!]],
            voice = VOICES.VIRIDIAN_CITY_POISON_STING,
          },
        }, onDone, opts)
      end

      if normalizedBoxText == "OH, OK THEN!" then
        startVoiceForGame(game, VOICES.VIRIDIAN_CITY_OK_THEN)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      -----------------------------------------------------------------------
      -- VIRIDIAN CITY GYM WATCHER — CLOSED GYM STATE
      --
      -- Before Giovanni returns, the watcher beside the Gym delivers one
      -- two-paragraph TextBox. Split it at the original paragraph boundary so
      -- each supplied recording has its own advance point. The later
      -- The later "Leader returned" state is a separate one-page interaction.
      -----------------------------------------------------------------------

      local viridianGymWatcherClosed =
        normalizedBoxText:find("THIS POK", 1, true)
        and normalizedBoxText:find("GYM IS ALWAYS", 1, true)
        and normalizedBoxText:find("CLOSED", 1, true)
        and normalizedBoxText:find("WONDER WHO", 1, true)
        and normalizedBoxText:find("LEADER IS", 1, true)

      if viridianGymWatcherClosed then
        return voicedBoxSequence({
          {
            text = [[This POKéMON GYM
is always closed.]],
            voice = VOICES.VIRIDIAN_CITY_GYM_WATCHER_CLOSED,
          },
          {
            text = [[I wonder who the
LEADER is?]],
            voice = VOICES.VIRIDIAN_CITY_GYM_WATCHER_WONDER_LEADER,
          },
        }, onDone, opts)
      end

      local viridianGymWatcherReturned =
        normalizedBoxText:find("VIRIDIAN GYM'S", 1, true)
        and normalizedBoxText:find("LEADER RETURNED", 1, true)

      if viridianGymWatcherReturned then
        startVoiceForGame(game, VOICES.VIRIDIAN_CITY_GYM_WATCHER_LEADER_RETURNED)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      -----------------------------------------------------------------------
      -- VIRIDIAN CITY GIRL / SLEEPING GRANDFATHER
      --
      -- The girl changes dialogue after EVENT_GOT_POKEDEX. The sleeping old
      -- man's two original pages also drive the blocking callback that moves
      -- the player back one tile, so that callback is retained only after the
      -- final voiced page. Matching here covers both direct flavor TextBoxes
      -- and the story.lua onStep gate, which bypass Commands.show_text.
      -----------------------------------------------------------------------

      local viridianGirlBeforePokedex =
        normalizedBoxText:find("OH GRANDPA", 1, true)
        and normalizedBoxText:find("HASN'T HAD HIS", 1, true)
        and normalizedBoxText:find("COFFEE YET", 1, true)

      if viridianGirlBeforePokedex then
        startVoiceForGame(game, VOICES.VIRIDIAN_CITY_GIRL_GRANDPA_MEAN)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      local viridianGirlAfterPokedex =
        normalizedBoxText:find("WHEN I GO SHOP", 1, true)
        and normalizedBoxText:find("PEWTER CITY", 1, true)
        and normalizedBoxText:find("WINDING TRAIL", 1, true)
        and normalizedBoxText:find("VIRIDIAN FOREST", 1, true)

      if viridianGirlAfterPokedex then
        startVoiceForGame(game, VOICES.VIRIDIAN_CITY_GIRL_WINDING_TRAIL)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      local viridianSleepyOldMan =
        normalizedBoxText:find("YOU CAN'T GO", 1, true)
        and normalizedBoxText:find("THROUGH HERE", 1, true)
        and normalizedBoxText:find("PRIVATE PROPERTY", 1, true)

      if viridianSleepyOldMan then
        return voicedBoxSequence({
          {
            text = [[You can't go
through here!]],
            voice = VOICES.VIRIDIAN_CITY_OLD_MAN_CANT_GO_THROUGH,
          },
          {
            text = [[This is private
property!]],
            voice = VOICES.VIRIDIAN_CITY_OLD_MAN_PRIVATE_PROPERTY,
          },
        }, onDone, opts)
      end

      -----------------------------------------------------------------------
      -- VIRIDIAN CITY POKÉMON CENTER VISITORS
      --
      -- These map texts arrive as multi-paragraph TextBoxes. Splitting each
      -- paragraph gives every supplied recording its own advance point while
      -- preserving the original completion callback after the final page.
      -----------------------------------------------------------------------

      local viridianCenterEveryTown =
        normalizedBoxText:find("THERE'S A POK", 1, true)
        and normalizedBoxText:find("CENTER IN EVERY", 1, true)
        and normalizedBoxText:find("THEY DON'T CHARGE", 1, true)

      if viridianCenterEveryTown then
        return voicedBoxSequence({
          {
            text = [[There's a POKéMON
CENTER in every
town ahead.]],
            voice = VOICES.VIRIDIAN_POKECENTER_CENTER_EVERY_TOWN,
          },
          {
            text = [[They don't charge
any money either!]],
            voice = VOICES.VIRIDIAN_POKECENTER_NO_CHARGE,
          },
        }, onDone, opts)
      end

      local viridianCenterUsePc =
        normalizedBoxText:find("YOU CAN USE THAT", 1, true)
        and normalizedBoxText:find("PC IN THE CORNER", 1, true)
        and normalizedBoxText:find("THE RECEPTIONIST", 1, true)
        and normalizedBoxText:find("SO KIND", 1, true)

      if viridianCenterUsePc then
        return voicedBoxSequence({
          {
            text = [[You can use that
PC in the corner.]],
            voice = VOICES.VIRIDIAN_POKECENTER_USE_PC,
          },
          {
            text = [[The receptionist
told me. So kind!]],
            voice = VOICES.VIRIDIAN_POKECENTER_RECEPTIONIST_KIND,
          },
        }, onDone, opts)
      end

      local viridianCenterHealVisitor =
        normalizedBoxText:find("CENTER", 1, true)
        and normalizedBoxText:find("HEAL YOUR TIRED", 1, true)
        and normalizedBoxText:find("HURT OR FAINTED", 1, true)
        and normalizedBoxText:find("POK", 1, true)

      if viridianCenterHealVisitor then
        startVoiceForGame(game, VOICES.VIRIDIAN_POKECENTER_HEAL_VISITOR)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      -----------------------------------------------------------------------
      -- SHARED CABLE CLUB RECEPTIONIST
      --
      -- Connected flow:
      --   Welcome -> apply here -> save warning -> original Yes/No
      --
      -- Disconnected flow:
      --   Welcome -> original unvoiced reserved-area explanation
      --
      -- The No response is tracked only long enough to voice the receptionist's
      -- subsequent "Please come again" box without affecting identically-worded
      -- dialogue elsewhere in the game.
      -----------------------------------------------------------------------

      local cableWelcome =
        normalizedBoxText:find("WELCOME TO THE CABLE CLUB", 1, true)
      local cableApply =
        normalizedBoxText:find("PLEASE APPLY HERE", 1, true)
      local cableSave =
        normalizedBoxText:find("BEFORE OPENING THE LINK", 1, true)
        and normalizedBoxText:find("SAVE THE GAME", 1, true)
      local cableReserved =
        normalizedBoxText:find("RESERVED FOR 2 FRIENDS", 1, true)
        or normalizedBoxText:find("RESERVED FOR TWO FRIENDS", 1, true)

      if cableWelcome and cableApply and cableSave then
        local choiceOpts = wrappedChoiceOptions(opts, function(yes)
          cableClubFarewellPending[game] = yes == false or nil
        end)

        return voicedBoxSequence({
          {
            text = [[Welcome to the
CABLE CLUB!]],
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_WELCOME,
          },
          {
            text = "Please apply here.",
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_APPLY,
          },
          {
            text = [[Before opening the
link, we have to
save the game.]],
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_SAVE,
          },
        }, onDone, choiceOpts)
      end

      if cableApply and cableSave then
        local choiceOpts = wrappedChoiceOptions(opts, function(yes)
          cableClubFarewellPending[game] = yes == false or nil
        end)

        return voicedBoxSequence({
          {
            text = "Please apply here.",
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_APPLY,
          },
          {
            text = [[Before opening the
link, we have to
save the game.]],
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_SAVE,
          },
        }, onDone, choiceOpts)
      end

      if cableWelcome and cableReserved then
        cableClubFarewellPending[game] = nil
        return voicedBoxSequence({
          {
            text = [[Welcome to the
CABLE CLUB!]],
            voice = VOICES.VIRIDIAN_POKECENTER_CABLE_WELCOME,
          },
          {
            text = [[This area is
reserved for 2
friends who are
linked by cable.]],
          },
        }, onDone, opts)
      end

      if cableWelcome then
        cableClubFarewellPending[game] = nil
        startVoiceForGame(game, VOICES.VIRIDIAN_POKECENTER_CABLE_WELCOME)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      if cableApply then
        startVoiceForGame(game, VOICES.VIRIDIAN_POKECENTER_CABLE_APPLY)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      if cableSave then
        local choiceOpts = wrappedChoiceOptions(opts, function(yes)
          cableClubFarewellPending[game] = yes == false or nil
        end)
        startVoiceForGame(game, VOICES.VIRIDIAN_POKECENTER_CABLE_SAVE)
        return previousTextBoxNew(game, text, onDone, choiceOpts)
      end

      if cableClubFarewellPending[game]
        and normalizedBoxText:find("PLEASE COME AGAIN!", 1, true)
      then
        cableClubFarewellPending[game] = nil
        startVoiceForGame(game, VOICES.VIRIDIAN_POKECENTER_CABLE_FAREWELL)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      local pokecenterWelcome =
        normalizedBoxText:find("WELCOME TO OUR", 1, true)
        and normalizedBoxText:find("BACK TO PERFECT HEALTH", 1, true)

      if pokecenterWelcome then
        local firstVisit =
          normalizedBoxText:find("SHALL WE HEAL YOUR", 1, true)
          and normalizedBoxText:find("POK", 1, true)

        local choiceOpts = wrappedChoiceOptions(opts)

        local function showFirstVisitPrompt()
          startVoiceForGame(
            game,
            VOICES.POKECENTER_NURSE_SHALL_HEAL
          )

          game.stack:push(previousTextBoxNew(
            game,
            "Shall we heal your\nPOKéMON?",
            nil,
            choiceOpts
          ))
        end

        local function showPerfectHealth()
          startVoiceForGame(
            game,
            VOICES.POKECENTER_NURSE_PERFECT_HEALTH
          )

          if firstVisit then
            game.stack:push(previousTextBoxNew(
              game,
              "We heal your POKéMON\nback to perfect\nhealth!",
              function()
                stopActiveVoice()
                showFirstVisitPrompt()
              end
            ))
          else
            game.stack:push(previousTextBoxNew(
              game,
              "We heal your POKéMON\nback to perfect\nhealth!",
              nil,
              choiceOpts
            ))
          end
        end

        startVoiceForGame(game, VOICES.POKECENTER_NURSE_WELCOME)

        return previousTextBoxNew(
          game,
          "Welcome to our\nPOKéMON CENTER!",
          function()
            stopActiveVoice()
            showPerfectHealth()
          end
        )
      end

      -- Defensive fallback if another engine build emits this separately.
      local pokecenterShallHeal =
        normalizedBoxText:find("SHALL WE HEAL YOUR", 1, true)
        and normalizedBoxText:find("POK", 1, true)

      if pokecenterShallHeal then
        startVoiceForGame(game, VOICES.POKECENTER_NURSE_SHALL_HEAL)

        return previousTextBoxNew(
          game,
          text,
          onDone,
          wrappedChoiceOptions(opts)
        )
      end

      -- Yes-only handover line. Match the nurse's actual wording rather
      -- than the generic phrase "need your ... POKéMON". The broad matcher
      -- also caught Oak's Pallet Town warning: "You need your own POKéMON
      -- for your protection."
      local pokecenterNeedPokemon =
        (
          normalizedBoxText:find("WE'LL NEED YOUR", 1, true)
          or normalizedBoxText:find("WE WILL NEED YOUR", 1, true)
        )
        and normalizedBoxText:find("POK", 1, true)

      if pokecenterNeedPokemon then
        startVoiceForGame(game, VOICES.POKECENTER_NURSE_NEED_POKEMON)

        return previousTextBoxNew(
          game,
          text,
          function()
            stopActiveVoice()
            if onDone then
              onDone()
            end
          end,
          opts
        )
      end

      -----------------------------------------------------------------------
      -- Successful healing combines the fighting-fit page and farewell in one
      -- TextBox. Split it into two voiced boxes and call original onDone only
      -- after the farewell closes.
      -----------------------------------------------------------------------

      local pokecenterPostHeal =
        normalizedBoxText:find("FIGHTING FIT", 1, true)
        and normalizedBoxText:find(
          "WE HOPE TO SEE YOU AGAIN",
          1,
          true
        )

      if pokecenterPostHeal then
        local function showPostHealFarewell()
          startVoiceForGame(
            game,
            VOICES.POKECENTER_NURSE_FAREWELL
          )

          game.stack:push(previousTextBoxNew(
            game,
            "We hope to see you\nagain!",
            function()
              stopActiveVoice()
              if onDone then
                onDone()
              end
            end
          ))
        end

        startVoiceForGame(
          game,
          VOICES.POKECENTER_NURSE_FIGHTING_FIT
        )

        return previousTextBoxNew(
          game,
          "Thank you! Your\nPOKéMON are\nfighting fit!",
          function()
            stopActiveVoice()
            showPostHealFarewell()
          end
        )
      end

      -- Defensive fallback if fighting-fit is emitted alone.
      local pokecenterFightingFit =
        normalizedBoxText:find("FIGHTING FIT", 1, true)

      if pokecenterFightingFit then
        startVoiceForGame(game, VOICES.POKECENTER_NURSE_FIGHTING_FIT)

        return previousTextBoxNew(
          game,
          text,
          function()
            stopActiveVoice()
            if onDone then
              onDone()
            end
          end,
          opts
        )
      end

      -- Shared farewell; the No branch reaches this directly.
      local pokecenterFarewell =
        normalizedBoxText:find("WE HOPE TO SEE YOU AGAIN", 1, true)

      if pokecenterFarewell then
        startVoiceForGame(game, VOICES.POKECENTER_NURSE_FAREWELL)

        return previousTextBoxNew(
          game,
          text,
          function()
            stopActiveVoice()
            if onDone then
              onDone()
            end
          end,
          opts
        )
      end

      local route1MartFirstSpeech =
        normalizedBoxText:find("HI! I WORK AT A", 1, true)
        and normalizedBoxText:find("VIRIDIAN CITY", 1, true)
        and normalizedBoxText:find("HERE YOU GO", 1, true)

      if route1MartFirstSpeech then
        local function finishMartSpeech()
          stopActiveVoice()
          if onDone then
            onDone()
          end
        end

        local function showSamplePage()
          startVoiceForGame(game, VOICES.ROUTE1_MART_WORKER_SAMPLE)

          game.stack:push(previousTextBoxNew(
            game,
            "I know, I'll give\nyou a sample!\nHere you go!",
            finishMartSpeech,
            opts
          ))
        end

        local function showVisitPage()
          startVoiceForGame(game, VOICES.ROUTE1_MART_WORKER_VISIT)

          game.stack:push(previousTextBoxNew(
            game,
            "It's a convenient\nshop, so please\nvisit us in\nVIRIDIAN CITY.",
            showSamplePage,
            opts
          ))
        end

        startVoiceForGame(game, VOICES.ROUTE1_MART_WORKER_INTRO)

        return previousTextBoxNew(
          game,
          "Hi! I work at a\nPOKéMON MART.",
          showVisitPage,
          opts
        )
      end

      local route1MartRepeatSpeech =
        normalizedBoxText:find("WE ALSO CARRY", 1, true)
        and normalizedBoxText:find("CATCHING", 1, true)

      if route1MartRepeatSpeech then
        startVoiceForGame(game, VOICES.ROUTE1_MART_WORKER_POKEBALLS)

        return previousTextBoxNew(
          game,
          "We also carry\nPOKé BALLs for\ncatching POKéMON!",
          function()
            stopActiveVoice()
            if onDone then
              onDone()
            end
          end,
          opts
        )
      end

      local beforeStarter = not flags.EVENT_FOLLOWED_OAK_INTO_LAB
        and not flags.EVENT_GOT_STARTER

      if beforeStarter and matchesGameText(
        game,
        text,
        "_PalletTownOakHeyWaitDontGoOutText",
        "OAK: Hey! Wait!\nDon't go out!"
      ) then
        -- This vanilla box is automatic. The voice may continue while Oak
        -- approaches; the next Oak line stops it if it is still playing.
        startVoiceForGame(game, VOICES.PALLET_OAK_HEY_WAIT)
        return previousTextBoxNew(game, text, onDone, opts)
      end

      if beforeStarter and matchesGameText(
        game,
        text,
        "_PalletTownOakItsUnsafeText",
        "OAK: It's unsafe!\nWild POKéMON\nlive in tall grass!"
      ) then
        local function finishEscortSpeech()
          stopActiveVoice()
          if onDone then
            onDone()
          end
        end

        local function showComeWithMe()
          startVoiceForGame(game, VOICES.PALLET_OAK_COME_WITH_ME)

          game.stack:push(previousTextBoxNew(
            game,
            "I know!\nHere, come with\nme!",
            finishEscortSpeech
          ))
        end

        local function showProtection()
          startVoiceForGame(game, VOICES.PALLET_OAK_PROTECTION)

          game.stack:push(previousTextBoxNew(
            game,
            "You need your own\nPOKéMON for your\nprotection.",
            showComeWithMe
          ))
        end

        startVoiceForGame(game, VOICES.PALLET_OAK_UNSAFE)

        return previousTextBoxNew(
          game,
          "OAK: It's unsafe!\nWild POKéMON live\nin tall grass!",
          showProtection
        )
      end

      -----------------------------------------------------------------------
      -- OAK'S LAB: PRE-STARTER SPEECH
      --
      -- story2.lua creates four direct TextBoxes:
      -- rival fed-up line, Oak's multi-page speech, rival's reply, and
      -- Oak's be-patient line. Split Oak's long resource into individually
      -- voiced boxes while preserving the original onDone callback that sets
      -- EVENT_OAK_ASKED_TO_CHOOSE_MON.
      -----------------------------------------------------------------------

      local choosingStarter = flags.EVENT_FOLLOWED_OAK_INTO_LAB
        and not flags.EVENT_OAK_ASKED_TO_CHOOSE_MON
        and not flags.EVENT_GOT_STARTER

      if choosingStarter and matchesGameText(
        game,
        text,
        "_OaksLabRivalFedUpWithWaitingText",
        "{RIVAL}: Gramps!\nI'm fed up with\nwaiting!"
      ) then
        startVoiceForGame(game, VOICES.LAB_RIVAL_FED_UP)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      if choosingStarter and matchesGameText(
        game,
        text,
        "_OaksLabOakChooseMonText",
        "OAK: Here, {PLAYER}!\fThere are 3\nPOKéMON here!\fYou can have one!\nChoose!"
      ) then
        local sequence = {
          {
            text = "OAK: {RIVAL}?\nLet me think...",
            voice = VOICES.LAB_OAK_LET_ME_THINK,
          },
          {
            text = "Oh, that's right,\nI told you to\ncome! Just wait!",
            voice = VOICES.LAB_OAK_TOLD_TO_COME,
          },
          {
            -- The recording deliberately avoids the dynamic player name.
            text = "Here!\fThere are 3\nPOKéMON here!",
            voice = VOICES.LAB_OAK_THREE_POKEMON,
          },
          {
            text = "Haha!",
            voice = VOICES.LAB_OAK_HAHA,
          },
          {
            text = "They are inside\nthe POKé BALLS.",
            voice = VOICES.LAB_OAK_INSIDE_BALLS,
          },
          {
            text = "When I was young,\nI was a serious\nPOKéMON trainer!",
            voice = VOICES.LAB_OAK_SERIOUS_TRAINER,
          },
          {
            text = "In my old age, I\nhave only 3 left,\nbut you can have\none! Choose!",
            voice = VOICES.LAB_OAK_ONLY_THREE,
          },
        }

        local function showLabPage(index)
          local page = sequence[index]

          if not page then
            stopActiveVoice()
            if onDone then onDone() end
            return
          end

          if page.voice then
            startVoiceForGame(game, page.voice)
          else
            stopActiveVoice()
          end

          game.stack:push(previousTextBoxNew(
            game,
            page.text,
            function()
              stopActiveVoice()
              showLabPage(index + 1)
            end
          ))
        end

        local first = sequence[1]
        startVoiceForGame(game, first.voice)

        return previousTextBoxNew(
          game,
          first.text,
          function()
            stopActiveVoice()
            showLabPage(2)
          end,
          opts
        )
      end

      if choosingStarter and matchesGameText(
        game,
        text,
        "_OaksLabRivalWhatAboutMeText",
        "{RIVAL}: Hey!\nGramps! What about\nme?"
      ) then
        startVoiceForGame(game, VOICES.LAB_RIVAL_WHAT_ABOUT_ME)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      if choosingStarter and matchesGameText(
        game,
        text,
        "_OaksLabOakBePatientText",
        "OAK: Be patient!\n{RIVAL}, you can\nhave one too!"
      ) then
        startVoiceForGame(game, VOICES.LAB_OAK_BE_PATIENT)
        return previousTextBoxNew(game, text, function()
          stopActiveVoice()
          if onDone then onDone() end
        end, opts)
      end

      return previousTextBoxNew(game, text, onDone, opts)
    end
  end

  -- Defensive cleanup if the intro is exited through another mod.
  mod.events:on("intro.oak_speech.finished", function(_)
    stopActiveVoice()
  end)
end
