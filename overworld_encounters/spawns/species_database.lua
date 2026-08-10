local Database = {}

-- Legendary Pokemon Excluded from Standard Wild Overworld Spawns
Database.EXCLUDED_LEGENDARIES = {
  ARTICUNO = true,
  ZAPDOS = true,
  MOLTRES = true,
  MEWTWO = true,
  MEW = true,
}

-- Town Exclusions (No Wild Spawns inside Towns or Cities)
Database.TOWNS = {
  PALLET_TOWN = true, VIRIDIAN_CITY = true, PEWTER_CITY = true,
  CERULEAN_CITY = true, VERMILION_CITY = true, CELADON_CITY = true,
  FUCHSIA_CITY = true, SAFFRON_CITY = true, CINNABAR_ISLAND = true,
  INDIGO_PLATEAU = true,
}

-- Biome Classification for Map IDs
Database.BIOMES = {
  SMALL_ROUTES = {
    ROUTE_1 = true, ROUTE_2 = true, ROUTE_3 = true, ROUTE_4 = true,
    ROUTE_5 = true, ROUTE_6 = true, ROUTE_7 = true, ROUTE_8 = true,
    ROUTE_11 = true, ROUTE_22 = true, ROUTE_24 = true, ROUTE_25 = true,
  },
  LARGE_ROUTES = {
    ROUTE_9 = true, ROUTE_10 = true, ROUTE_12 = true, ROUTE_13 = true,
    ROUTE_14 = true, ROUTE_15 = true, ROUTE_16 = true, ROUTE_17 = true,
    ROUTE_18 = true, ROUTE_21 = true, ROUTE_23 = true, SAFARI_ZONE_CENTER = true,
    SAFARI_ZONE_EAST = true, SAFARI_ZONE_NORTH = true, SAFARI_ZONE_WEST = true,
  },
  CAVES = {
    MT_MOON_1F = true, MT_MOON_B1F = true, MT_MOON_B2F = true,
    ROCK_TUNNEL_1F = true, ROCK_TUNNEL_B1F = true, DIGLETTS_CAVE = true,
    VICTORY_ROAD_1F = true, VICTORY_ROAD_2F = true, VICTORY_ROAD_3F = true,
    CERULEAN_CAVE_1F = true, CERULEAN_CAVE_2F = true, CERULEAN_CAVE_B1F = true,
    SEAFOAM_ISLANDS_1F = true, SEAFOAM_ISLANDS_B1F = true, SEAFOAM_ISLANDS_B2F = true,
    SEAFOAM_ISLANDS_B3F = true, SEAFOAM_ISLANDS_B4F = true,
    POKEMON_TOWER_3F = true, POKEMON_TOWER_4F = true, POKEMON_TOWER_5F = true,
    POKEMON_TOWER_6F = true, POKEMON_TOWER_7F = true,
    POKEMON_MANSION_1F = true, POKEMON_MANSION_2F = true,
    POKEMON_MANSION_3F = true, POKEMON_MANSION_B1F = true,
    POWER_PLANT = true,
  },
  WATER = {
    ROUTE_19 = true, ROUTE_20 = true,
  },
}

---------------------------------------------------------------------------
-- Expanded Per-Map Species Pools for Maximum Game Variety
---------------------------------------------------------------------------
Database.MAP_POOLS = {

  -- ---- EARLY ROUTES ---------------------------------------------------

  ROUTE_1 = {
    DAY  = { "PIDGEY", "RATTATA", "CATERPIE", "WEEDLE", "ODDISH", "BELLSPROUT", "PIDGEY", "RATTATA" },
    MORN = { "PIDGEY", "RATTATA", "CATERPIE", "WEEDLE", "NIDORAN_F", "NIDORAN_M", "SPEAROW" },
    NITE = { "RATTATA", "MEOWTH", "DROWZEE", "ZUBAT", "ODDISH", "HOOTHOOT", "RATTATA" },
  },
  ROUTE_2 = {
    DAY  = { "PIDGEY", "RATTATA", "WEEDLE", "CATERPIE", "NIDORAN_F", "NIDORAN_M", "PIKACHU", "METAPOD" },
    MORN = { "CATERPIE", "WEEDLE", "METAPOD", "KAKUNA", "PIDGEY", "NIDORAN_F", "NIDORAN_M" },
    NITE = { "RATTATA", "MEOWTH", "ZUBAT", "WEEDLE", "EKANS", "PARAS", "DROWZEE" },
  },
  VIRIDIAN_FOREST = {
    DAY  = { "CATERPIE", "METAPOD", "BUTTERFREE", "WEEDLE", "KAKUNA", "BEEDRILL", "PIKACHU", "PIDGEOTTO" },
    MORN = { "CATERPIE", "WEEDLE", "METAPOD", "KAKUNA", "PIKACHU", "BUTTERFREE", "BEEDRILL" },
    NITE = { "WEEDLE", "KAKUNA", "PIKACHU", "VENONAT", "ZUBAT", "PARAS", "GASTLY" },
  },
  ROUTE_22 = {
    DAY  = { "RATTATA", "NIDORAN_M", "NIDORAN_F", "SPEAROW", "MANKEY", "EKANS", "POLIWAG" },
    MORN = { "NIDORAN_M", "NIDORAN_F", "RATTATA", "PIDGEY", "SPEAROW", "MANKEY" },
    NITE = { "RATTATA", "NIDORAN_M", "NIDORAN_F", "MEOWTH", "ZUBAT", "POLIWAG", "EKANS" },
  },
  ROUTE_3 = {
    DAY  = { "PIDGEY", "SPEAROW", "JIGGLYPUFF", "MANKEY", "NIDORAN_F", "NIDORAN_M", "SANDSHREW" },
    MORN = { "PIDGEY", "JIGGLYPUFF", "SPEAROW", "NIDORAN_F", "NIDORAN_M", "CATERPIE" },
    NITE = { "JIGGLYPUFF", "MEOWTH", "ZUBAT", "SPEAROW", "DROWZEE", "CLEFAIRY" },
  },
  ROUTE_4 = {
    DAY  = { "RATTATA", "SPEAROW", "EKANS", "SANDSHREW", "JIGGLYPUFF", "MANKEY", "CHARMANDER" },
    MORN = { "RATTATA", "SPEAROW", "NIDORAN_M", "NIDORAN_F", "EKANS", "SANDSHREW" },
    NITE = { "RATTATA", "EKANS", "MEOWTH", "ZUBAT", "DROWZEE", "PARAS" },
  },

  -- ---- MT. MOON -------------------------------------------------------

  MT_MOON_1F = {
    DAY  = { "ZUBAT", "GEODUDE", "PARAS", "CLEFAIRY", "SANDSHREW", "ONIX", "MACHOP" },
    MORN = { "ZUBAT", "GEODUDE", "CLEFAIRY", "PARAS", "MACHOP", "GEODUDE" },
    NITE = { "ZUBAT", "GEODUDE", "CLEFAIRY", "PARAS", "GASTLY", "ONIX" },
  },
  MT_MOON_B1F = {
    DAY  = { "ZUBAT", "GEODUDE", "PARAS", "CLEFAIRY", "ONIX", "MACHOP" },
    MORN = { "ZUBAT", "GEODUDE", "CLEFAIRY", "PARAS", "GEODUDE", "SANDSHREW" },
    NITE = { "ZUBAT", "GEODUDE", "CLEFAIRY", "PARAS", "GASTLY", "ONIX" },
  },
  MT_MOON_B2F = {
    DAY  = { "ZUBAT", "GEODUDE", "PARAS", "CLEFAIRY", "PARASECT", "ONIX", "MACHOP" },
    MORN = { "GEODUDE", "CLEFAIRY", "PARAS", "ZUBAT", "ONIX", "GRAVELER" },
    NITE = { "ZUBAT", "GEODUDE", "CLEFAIRY", "PARAS", "GASTLY", "HAUNTER" },
  },

  -- ---- CERULEAN ROUTES ------------------------------------------------

  ROUTE_24 = {
    DAY  = { "WEEDLE", "KAKUNA", "PIDGEY", "ODDISH", "BELLSPROUT", "ABRA", "PIDGEOTTO", "SQUIRTLE" },
    MORN = { "WEEDLE", "CATERPIE", "PIDGEY", "ABRA", "NIDORAN_F", "ODDISH", "BELLSPROUT" },
    NITE = { "ODDISH", "BELLSPROUT", "VENONAT", "ABRA", "ZUBAT", "GASTLY", "DROWZEE", "PSYDUCK" },
  },
  ROUTE_25 = {
    DAY  = { "WEEDLE", "KAKUNA", "PIDGEY", "ODDISH", "BELLSPROUT", "ABRA", "CATERPIE", "METAPOD", "PSYDUCK" },
    MORN = { "CATERPIE", "METAPOD", "WEEDLE", "PIDGEY", "ABRA", "ODDISH", "BELLSPROUT" },
    NITE = { "ODDISH", "BELLSPROUT", "VENONAT", "ABRA", "ZUBAT", "GASTLY", "DROWZEE", "GOLDUCK" },
  },

  -- ---- ROCK TUNNEL ---------------------------------------------------

  ROCK_TUNNEL_1F = {
    DAY  = { "ZUBAT", "GEODUDE", "MACHOP", "ONIX", "GRAVELER", "CUBONE", "KADABRA" },
    MORN = { "GEODUDE", "MACHOP", "ONIX", "ZUBAT", "GRAVELER", "CUBONE" },
    NITE = { "ZUBAT", "GEODUDE", "ONIX", "GASTLY", "HAUNTER", "MACHOP", "CUBONE" },
  },
  ROCK_TUNNEL_B1F = {
    DAY  = { "ZUBAT", "GEODUDE", "MACHOP", "ONIX", "GRAVELER", "CUBONE", "KADABRA", "MAROWAK" },
    MORN = { "GEODUDE", "MACHOP", "ONIX", "ZUBAT", "GRAVELER", "CUBONE" },
    NITE = { "ZUBAT", "GEODUDE", "ONIX", "GASTLY", "HAUNTER", "MACHOP", "MAROWAK" },
  },

  -- ---- VERMILION / SAFFRON ROUTES ------------------------------------

  ROUTE_5 = {
    DAY  = { "PIDGEY", "ODDISH", "BELLSPROUT", "MANKEY", "MEOWTH", "ABRA", "JIGGLYPUFF", "VULPIX" },
    MORN = { "PIDGEY", "MANKEY", "NIDORAN_F", "NIDORAN_M", "ODDISH", "BELLSPROUT", "VULPIX" },
    NITE = { "ODDISH", "BELLSPROUT", "MEOWTH", "DROWZEE", "ZUBAT", "MANKEY", "GASTLY", "ABRA" },
  },
  ROUTE_6 = {
    DAY  = { "PIDGEY", "ODDISH", "BELLSPROUT", "MANKEY", "MEOWTH", "ABRA", "JIGGLYPUFF", "PSYDUCK" },
    MORN = { "PIDGEY", "MANKEY", "NIDORAN_F", "NIDORAN_M", "ODDISH", "BELLSPROUT", "PSYDUCK" },
    NITE = { "ODDISH", "BELLSPROUT", "MEOWTH", "DROWZEE", "ZUBAT", "MANKEY", "GASTLY", "GOLDUCK" },
  },
  ROUTE_11 = {
    DAY  = { "EKANS", "SPEAROW", "DROWZEE", "ARBOK", "FEAROW", "HYPNO", "VOLTORB", "MAGNEMITE", "SNORLAX" },
    MORN = { "SPEAROW", "EKANS", "DROWZEE", "NIDORAN_M", "PIDGEY", "VOLTORB", "MAGNEMITE" },
    NITE = { "DROWZEE", "HYPNO", "EKANS", "MEOWTH", "ZUBAT", "GASTLY", "SPEAROW", "MAGNEMITE" },
  },

  -- ---- CELADON / LAVENDER ROUTES -------------------------------------

  ROUTE_7 = {
    DAY  = { "PIDGEY", "ODDISH", "BELLSPROUT", "GROWLITHE", "VULPIX", "MANKEY", "MEOWTH", "ABRA" },
    MORN = { "PIDGEY", "GROWLITHE", "VULPIX", "MANKEY", "ODDISH", "NIDORAN_F", "NIDORAN_M" },
    NITE = { "ODDISH", "BELLSPROUT", "GROWLITHE", "VULPIX", "DROWZEE", "MEOWTH", "GASTLY", "PERSIAN" },
  },
  ROUTE_8 = {
    DAY  = { "PIDGEY", "EKANS", "GROWLITHE", "VULPIX", "MANKEY", "MEOWTH", "ABRA", "KADABRA" },
    MORN = { "PIDGEY", "GROWLITHE", "VULPIX", "MANKEY", "EKANS", "NIDORAN_M", "NIDORAN_F" },
    NITE = { "GROWLITHE", "VULPIX", "EKANS", "DROWZEE", "MEOWTH", "ZUBAT", "GASTLY", "HAUNTER" },
  },
  ROUTE_9 = {
    DAY  = { "RATTATA", "SPEAROW", "EKANS", "FEAROW", "NIDORINO", "NIDORINA", "VOLTORB", "MAGNEMITE" },
    MORN = { "RATTATA", "SPEAROW", "NIDORAN_M", "NIDORAN_F", "EKANS", "PIDGEY", "VOLTORB" },
    NITE = { "RATTATA", "EKANS", "MEOWTH", "DROWZEE", "ZUBAT", "GASTLY", "MAGNEMITE", "VOLTORB" },
  },
  ROUTE_10 = {
    DAY  = { "VOLTORB", "MAGNEMITE", "ELECTABUZZ", "SPEAROW", "FEAROW", "EKANS", "MACHOP" },
    MORN = { "SPEAROW", "VOLTORB", "MAGNEMITE", "EKANS", "PIDGEY", "NIDORAN_M" },
    NITE = { "VOLTORB", "ELECTRODE", "MAGNEMITE", "MAGNETON", "EKANS", "DROWZEE", "GASTLY" },
  },

  -- ---- POKEMON TOWER -------------------------------------------------

  POKEMON_TOWER_3F = {
    DAY  = { "GASTLY", "GASTLY", "CUBONE", "HAUNTER", "VULPIX", "DROWZEE" },
    MORN = { "GASTLY", "CUBONE", "GASTLY", "HAUNTER", "VULPIX" },
    NITE = { "GASTLY", "GASTLY", "HAUNTER", "HAUNTER", "CUBONE", "GENGAR" },
  },
  POKEMON_TOWER_4F = {
    DAY  = { "GASTLY", "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "DROWZEE" },
    MORN = { "GASTLY", "CUBONE", "GASTLY", "HAUNTER", "MAROWAK" },
    NITE = { "GASTLY", "GASTLY", "HAUNTER", "HAUNTER", "CUBONE", "GENGAR" },
  },
  POKEMON_TOWER_5F = {
    DAY  = { "GASTLY", "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "HYPNO" },
    MORN = { "GASTLY", "CUBONE", "GASTLY", "HAUNTER", "MAROWAK" },
    NITE = { "GASTLY", "GASTLY", "HAUNTER", "HAUNTER", "CUBONE", "GENGAR" },
  },
  POKEMON_TOWER_6F = {
    DAY  = { "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "GASTLY", "HAUNTER", "GENGAR" },
    MORN = { "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "GASTLY" },
    NITE = { "GASTLY", "HAUNTER", "HAUNTER", "CUBONE", "MAROWAK", "GENGAR" },
  },
  POKEMON_TOWER_7F = {
    DAY  = { "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "HAUNTER", "GENGAR" },
    MORN = { "GASTLY", "CUBONE", "HAUNTER", "MAROWAK", "GASTLY" },
    NITE = { "HAUNTER", "HAUNTER", "GASTLY", "CUBONE", "MAROWAK", "GENGAR" },
  },

  -- ---- FUCHSIA / CYCLING ROAD ROUTES ---------------------------------

  ROUTE_12 = {
    DAY  = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "BELLSPROUT", "WEEPINBELL", "VENONAT", "FARFETCHD" },
    MORN = { "PIDGEY", "PIDGEOTTO", "ODDISH", "BELLSPROUT", "NIDORAN_F", "NIDORAN_M", "FARFETCHD" },
    NITE = { "ODDISH", "GLOOM", "BELLSPROUT", "VENONAT", "VENOMOTH", "MEOWTH", "ZUBAT", "DROWZEE" },
  },
  ROUTE_13 = {
    DAY  = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "BELLSPROUT", "WEEPINBELL", "VENONAT", "DITTO", "FARFETCHD" },
    MORN = { "PIDGEY", "PIDGEOTTO", "ODDISH", "BELLSPROUT", "VENONAT", "NIDORAN_F", "FARFETCHD" },
    NITE = { "ODDISH", "GLOOM", "BELLSPROUT", "VENONAT", "VENOMOTH", "DITTO", "MEOWTH", "GASTLY" },
  },
  ROUTE_14 = {
    DAY  = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "BELLSPROUT", "WEEPINBELL", "VENONAT", "VENOMOTH", "DITTO", "SCYTHER", "PINSIR" },
    MORN = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "VENONAT", "PIDGEOTTO", "SCYTHER", "PINSIR" },
    NITE = { "ODDISH", "GLOOM", "VENONAT", "VENOMOTH", "DITTO", "MEOWTH", "ZUBAT", "DROWZEE", "PINSIR" },
  },
  ROUTE_15 = {
    DAY  = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "BELLSPROUT", "WEEPINBELL", "VENONAT", "VENOMOTH", "DITTO", "SCYTHER", "PINSIR" },
    MORN = { "PIDGEY", "PIDGEOTTO", "ODDISH", "GLOOM", "VENONAT", "PIDGEOTTO", "SCYTHER", "PINSIR" },
    NITE = { "ODDISH", "GLOOM", "VENONAT", "VENOMOTH", "DITTO", "MEOWTH", "ZUBAT", "DROWZEE", "SCYTHER" },
  },
  ROUTE_16 = {
    DAY  = { "SPEAROW", "FEAROW", "DODUO", "DODRIO", "RATTATA", "RATICATE", "SNORLAX", "LICKITUNG" },
    MORN = { "SPEAROW", "DODUO", "RATTATA", "PIDGEY", "NIDORAN_M", "LICKITUNG" },
    NITE = { "RATTATA", "RATICATE", "DODUO", "DODRIO", "MEOWTH", "ZUBAT", "DROWZEE" },
  },
  ROUTE_17 = {
    DAY  = { "SPEAROW", "FEAROW", "DODUO", "DODRIO", "RATICATE", "FEAROW", "PONYTA", "RAPIDASH" },
    MORN = { "SPEAROW", "DODUO", "RATTATA", "FEAROW", "PIDGEY", "PONYTA" },
    NITE = { "RATICATE", "DODUO", "DODRIO", "FEAROW", "MEOWTH", "ZUBAT", "DROWZEE" },
  },
  ROUTE_18 = {
    DAY  = { "SPEAROW", "FEAROW", "DODUO", "DODRIO", "RATICATE", "FEAROW", "LICKITUNG", "PONYTA" },
    MORN = { "SPEAROW", "DODUO", "RATTATA", "FEAROW", "PIDGEY", "LICKITUNG" },
    NITE = { "RATICATE", "DODUO", "DODRIO", "FEAROW", "MEOWTH", "ZUBAT", "DROWZEE" },
  },

  -- ---- SAFARI ZONE ---------------------------------------------------

  SAFARI_ZONE_CENTER = {
    DAY  = { "NIDORAN_M", "NIDORAN_F", "RHYHORN", "RHYDON", "VENONAT", "EXEGGCUTE", "NIDORINO", "NIDORINA", "SCYTHER", "PINSIR", "CHANSEY", "PARASECT", "KANGASKHAN", "TAUROS" },
    MORN = { "NIDORAN_M", "NIDORAN_F", "RHYHORN", "VENONAT", "EXEGGCUTE", "CHANSEY", "PARASECT", "SCYTHER" },
    NITE = { "VENONAT", "VENOMOTH", "NIDORINO", "NIDORINA", "CHANSEY", "RHYHORN", "SCYTHER", "PINSIR", "PARASECT" },
  },
  SAFARI_ZONE_EAST = {
    DAY  = { "NIDORAN_M", "NIDORAN_F", "DODUO", "DODRIO", "PARAS", "EXEGGCUTE", "EXEGGCUTE", "NIDORINO", "PARASECT", "KANGASKHAN", "SCYTHER", "PINSIR", "DRATINI" },
    MORN = { "NIDORAN_M", "NIDORAN_F", "PARAS", "EXEGGCUTE", "DODUO", "KANGASKHAN", "PARASECT", "DRATINI" },
    NITE = { "PARAS", "PARASECT", "VENONAT", "NIDORINO", "NIDORINA", "KANGASKHAN", "SCYTHER", "PINSIR" },
  },
  SAFARI_ZONE_NORTH = {
    DAY  = { "NIDORAN_M", "NIDORAN_F", "RHYHORN", "RHYDON", "PARAS", "EXEGGCUTE", "NIDORINO", "NIDORINA", "VENOMOTH", "CHANSEY", "TAUROS", "PINSIR" },
    MORN = { "NIDORAN_M", "NIDORAN_F", "RHYHORN", "PARAS", "EXEGGCUTE", "CHANSEY", "TAUROS", "PINSIR" },
    NITE = { "VENONAT", "VENOMOTH", "NIDORINO", "NIDORINA", "CHANSEY", "TAUROS", "RHYHORN", "PINSIR" },
  },
  SAFARI_ZONE_WEST = {
    DAY  = { "NIDORAN_M", "NIDORAN_F", "DODUO", "DODRIO", "VENONAT", "EXEGGCUTE", "NIDORINO", "NIDORINA", "VENOMOTH", "TAUROS", "KANGASKHAN", "DRATINI", "DRAGONAIR" },
    MORN = { "NIDORAN_M", "NIDORAN_F", "DODUO", "VENONAT", "EXEGGCUTE", "TAUROS", "KANGASKHAN", "DRATINI" },
    NITE = { "VENONAT", "VENOMOTH", "NIDORINO", "NIDORINA", "KANGASKHAN", "TAUROS", "DODUO", "DRAGONAIR" },
  },

  -- ---- SEAFOAM ISLANDS -----------------------------------------------

  SEAFOAM_ISLANDS_1F = {
    DAY  = { "SEEL", "DEWGONG", "SLOWPOKE", "SLOWBRO", "SHELLDER", "CLOYSTER", "HORSEA", "SEADRA", "PSYDUCK", "GOLDUCK", "ZUBAT", "GOLBAT" },
    MORN = { "SEEL", "SLOWPOKE", "HORSEA", "PSYDUCK", "SHELLDER", "ZUBAT", "STARYU" },
    NITE = { "ZUBAT", "GOLBAT", "SEEL", "SLOWPOKE", "PSYDUCK", "GASTLY", "SHELLDER", "CLOYSTER" },
  },
  SEAFOAM_ISLANDS_B1F = {
    DAY  = { "STARYU", "STARMIE", "HORSEA", "SEADRA", "SHELLDER", "CLOYSTER", "SLOWPOKE", "SLOWBRO", "SEEL", "DEWGONG" },
    MORN = { "STARYU", "HORSEA", "SHELLDER", "SEEL", "SLOWPOKE", "ZUBAT", "STARMIE" },
    NITE = { "ZUBAT", "GOLBAT", "STARYU", "SEEL", "DEWGONG", "GASTLY", "SLOWPOKE", "CLOYSTER" },
  },
  SEAFOAM_ISLANDS_B2F = {
    DAY  = { "SEEL", "DEWGONG", "SLOWPOKE", "SLOWBRO", "SHELLDER", "CLOYSTER", "HORSEA", "SEADRA", "STARYU", "STARMIE", "GOLBAT" },
    MORN = { "SEEL", "SLOWPOKE", "HORSEA", "STARYU", "SHELLDER", "ZUBAT", "SLOWBRO" },
    NITE = { "ZUBAT", "GOLBAT", "SEEL", "SLOWPOKE", "STARYU", "GASTLY", "SLOWBRO", "STARMIE" },
  },
  SEAFOAM_ISLANDS_B3F = {
    DAY  = { "SLOWPOKE", "SLOWBRO", "SEEL", "DEWGONG", "HORSEA", "SEADRA", "SHELLDER", "CLOYSTER", "STARYU", "STARMIE", "LAPRAS" },
    MORN = { "SLOWPOKE", "SEEL", "HORSEA", "SHELLDER", "STARYU", "ZUBAT", "LAPRAS" },
    NITE = { "ZUBAT", "GOLBAT", "SLOWPOKE", "SEEL", "DEWGONG", "GASTLY", "SEADRA", "LAPRAS" },
  },
  SEAFOAM_ISLANDS_B4F = {
    DAY  = { "HORSEA", "SEADRA", "SHELLDER", "CLOYSTER", "SLOWPOKE", "SLOWBRO", "SEEL", "DEWGONG", "STARYU", "STARMIE", "GOLBAT", "LAPRAS" },
    MORN = { "HORSEA", "SHELLDER", "SEEL", "SLOWPOKE", "STARYU", "ZUBAT", "LAPRAS" },
    NITE = { "ZUBAT", "GOLBAT", "HORSEA", "SEEL", "DEWGONG", "GASTLY", "SLOWBRO", "LAPRAS" },
  },

  -- ---- POKEMON MANSION -----------------------------------------------

  POKEMON_MANSION_1F = {
    DAY  = { "KOFFING", "WEEZING", "PONYTA", "RAPIDASH", "GROWLITHE", "ARCANINE", "VULPIX", "NINETALES", "GRIMER", "MUK", "DITTO" },
    MORN = { "PONYTA", "GROWLITHE", "VULPIX", "KOFFING", "GRIMER", "PONYTA", "ARCANINE" },
    NITE = { "KOFFING", "WEEZING", "GRIMER", "MUK", "GASTLY", "HAUNTER", "GROWLITHE", "VULPIX" },
  },
  POKEMON_MANSION_2F = {
    DAY  = { "GROWLITHE", "ARCANINE", "VULPIX", "NINETALES", "KOFFING", "WEEZING", "PONYTA", "RAPIDASH", "GRIMER", "MUK", "DITTO" },
    MORN = { "GROWLITHE", "PONYTA", "VULPIX", "KOFFING", "GRIMER", "PONYTA", "RAPIDASH" },
    NITE = { "KOFFING", "WEEZING", "GRIMER", "MUK", "GASTLY", "HAUNTER", "GROWLITHE", "MAGMAR" },
  },
  POKEMON_MANSION_3F = {
    DAY  = { "KOFFING", "WEEZING", "GROWLITHE", "ARCANINE", "VULPIX", "NINETALES", "PONYTA", "RAPIDASH", "GRIMER", "MUK", "MAGMAR", "DITTO" },
    MORN = { "GROWLITHE", "PONYTA", "VULPIX", "KOFFING", "GRIMER", "MAGMAR" },
    NITE = { "KOFFING", "WEEZING", "GRIMER", "MUK", "GASTLY", "HAUNTER", "MAGMAR", "DITTO" },
  },
  POKEMON_MANSION_B1F = {
    DAY  = { "KOFFING", "WEEZING", "GROWLITHE", "ARCANINE", "VULPIX", "NINETALES", "PONYTA", "RAPIDASH", "GRIMER", "MUK", "MAGMAR", "DITTO" },
    MORN = { "GROWLITHE", "PONYTA", "VULPIX", "KOFFING", "GRIMER", "MAGMAR" },
    NITE = { "KOFFING", "WEEZING", "GRIMER", "MUK", "GASTLY", "HAUNTER", "MAGMAR", "DITTO" },
  },

  -- ---- POWER PLANT ---------------------------------------------------

  POWER_PLANT = {
    DAY  = { "VOLTORB", "ELECTRODE", "MAGNEMITE", "MAGNETON", "PIKACHU", "RAICHU", "ELECTABUZZ" },
    MORN = { "VOLTORB", "MAGNEMITE", "PIKACHU", "VOLTORB", "MAGNETON", "ELECTABUZZ" },
    NITE = { "VOLTORB", "ELECTRODE", "MAGNETON", "ELECTABUZZ", "MAGNEMITE", "RAICHU" },
  },

  -- ---- DIGLETT'S CAVE ------------------------------------------------

  DIGLETTS_CAVE = {
    DAY  = { "DIGLETT", "DIGLETT", "DIGLETT", "DUGTRIO", "DIGLETT", "DUGTRIO" },
    MORN = { "DIGLETT", "DIGLETT", "DIGLETT", "DUGTRIO", "DIGLETT" },
    NITE = { "DIGLETT", "DIGLETT", "DUGTRIO", "DIGLETT", "DUGTRIO" },
  },

  -- ---- ROUTE 21 ------------------------------------------------------

  ROUTE_21 = {
    DAY  = { "RATTATA", "RATICATE", "PIDGEY", "PIDGEOTTO", "TANGELA", "TENTACOOL", "TENTACRUEL", "STARYU" },
    MORN = { "PIDGEY", "RATTATA", "PIDGEOTTO", "TANGELA", "NIDORAN_F", "NIDORAN_M" },
    NITE = { "RATTATA", "RATICATE", "TANGELA", "MEOWTH", "ZUBAT", "DROWZEE", "TENTACRUEL" },
  },

  -- ---- ROUTE 23 / VICTORY ROAD ---------------------------------------

  ROUTE_23 = {
    DAY  = { "EKANS", "ARBOK", "SPEAROW", "FEAROW", "DITTO", "SANDSHREW", "SANDSLASH", "NIDORINO", "NIDORINA" },
    MORN = { "SPEAROW", "EKANS", "FEAROW", "DITTO", "ARBOK", "SANDSLASH" },
    NITE = { "EKANS", "ARBOK", "FEAROW", "DITTO", "MEOWTH", "DROWZEE", "ZUBAT", "NIDORINO" },
  },
  VICTORY_ROAD_1F = {
    DAY  = { "MACHOP", "MACHOKE", "MACHAMP", "GEODUDE", "GRAVELER", "GOLEM", "ZUBAT", "GOLBAT", "ONIX", "MAROWAK", "RHYDON" },
    MORN = { "MACHOP", "GEODUDE", "ONIX", "ZUBAT", "GRAVELER", "MACHOKE", "RHYDON" },
    NITE = { "ZUBAT", "GOLBAT", "ONIX", "GRAVELER", "MAROWAK", "GASTLY", "HAUNTER", "MACHOKE" },
  },
  VICTORY_ROAD_2F = {
    DAY  = { "MACHOP", "MACHOKE", "MACHAMP", "GEODUDE", "GRAVELER", "GOLEM", "ZUBAT", "GOLBAT", "ONIX", "MAROWAK", "RHYDON", "VENOMOTH" },
    MORN = { "MACHOP", "GEODUDE", "ONIX", "ZUBAT", "GRAVELER", "MACHOKE", "VENOMOTH" },
    NITE = { "ZUBAT", "GOLBAT", "ONIX", "GRAVELER", "MAROWAK", "GASTLY", "HAUNTER", "MACHOKE" },
  },
  VICTORY_ROAD_3F = {
    DAY  = { "MACHOP", "MACHOKE", "MACHAMP", "GEODUDE", "GRAVELER", "GOLEM", "ZUBAT", "GOLBAT", "ONIX", "MAROWAK", "RHYDON", "VENOMOTH" },
    MORN = { "MACHOP", "GEODUDE", "ONIX", "ZUBAT", "GRAVELER", "MACHOKE", "VENOMOTH" },
    NITE = { "ZUBAT", "GOLBAT", "ONIX", "GRAVELER", "VENOMOTH", "GASTLY", "HAUNTER", "MACHOKE" },
  },

  -- ---- CERULEAN CAVE -------------------------------------------------

  CERULEAN_CAVE_1F = {
    DAY  = { "GOLBAT", "HYPNO", "MAGNETON", "DODRIO", "VENOMOTH", "ARBOK", "KADABRA", "ALAKAZAM", "PARASECT", "RAICHU", "DITTO" },
    MORN = { "GOLBAT", "HYPNO", "MAGNETON", "KADABRA", "PARASECT", "RAICHU", "DITTO" },
    NITE = { "GOLBAT", "HYPNO", "ARBOK", "KADABRA", "RAICHU", "DITTO", "GASTLY", "HAUNTER" },
  },
  CERULEAN_CAVE_2F = {
    DAY  = { "DODRIO", "VENOMOTH", "KADABRA", "ALAKAZAM", "RHYDON", "MAROWAK", "ELECTRODE", "CHANSEY", "WIGGLYTUFF", "DITTO", "SNORLAX" },
    MORN = { "KADABRA", "RHYDON", "MAROWAK", "CHANSEY", "WIGGLYTUFF", "DITTO", "VENOMOTH" },
    NITE = { "GOLBAT", "VENOMOTH", "ELECTRODE", "MAROWAK", "DITTO", "CHANSEY", "GASTLY", "HAUNTER" },
  },
  CERULEAN_CAVE_B1F = {
    DAY  = { "RHYDON", "MAROWAK", "ELECTRODE", "CHANSEY", "PARASECT", "RAICHU", "ARBOK", "DITTO", "DRAGONITE", "CHARIZARD", "BLASTOISE", "VENUSAUR" },
    MORN = { "RHYDON", "MAROWAK", "CHANSEY", "PARASECT", "RAICHU", "DITTO", "ARBOK", "DRAGONITE" },
    NITE = { "GOLBAT", "ELECTRODE", "MAROWAK", "ARBOK", "RAICHU", "DITTO", "GASTLY", "CHANSEY", "DRAGONITE" },
  },

  -- ---- WATER ROUTES --------------------------------------------------

  ROUTE_19 = {
    DAY  = { "TENTACOOL", "TENTACRUEL", "STARYU", "STARMIE", "SHELLDER", "HORSEA", "SEADRA" },
    MORN = { "TENTACOOL", "TENTACRUEL", "STARYU", "HORSEA", "SEEL" },
    NITE = { "TENTACOOL", "TENTACRUEL", "STARYU", "STARMIE", "SHELLDER", "CLOYSTER" },
  },
  ROUTE_20 = {
    DAY  = { "TENTACOOL", "TENTACRUEL", "STARYU", "STARMIE", "SHELLDER", "HORSEA", "SEADRA", "GYARADOS" },
    MORN = { "TENTACOOL", "TENTACRUEL", "STARYU", "HORSEA", "SEEL" },
    NITE = { "TENTACOOL", "TENTACRUEL", "STARYU", "STARMIE", "SHELLDER", "GYARADOS" },
  },
}

-- Check if map allows wild overworld Pokemon spawns
function Database.isWildMap(mapId)
  if not mapId or Database.TOWNS[mapId] then
    return false
  end
  if mapId:find("_GATE", 1, true) or mapId:find("_HOUSE", 1, true) or mapId:find("_CENTER", 1, true) or mapId:find("_MART", 1, true) then
    return false
  end
  if Database.MAP_POOLS[mapId] then return true end
  return Database.BIOMES.SMALL_ROUTES[mapId] or Database.BIOMES.LARGE_ROUTES[mapId]
      or Database.BIOMES.CAVES[mapId] or Database.BIOMES.WATER[mapId]
end

-- Return active pool for mapId & time of day, dynamically pulling native encounter tables as fallback
function Database.getPoolForMap(mapId, period, game)
  period = period or "DAY"
  if not Database.isWildMap(mapId) then return nil end

  -- Per-map pool takes priority
  local mapPool = Database.MAP_POOLS[mapId]
  if mapPool then
    return mapPool[period] or mapPool.DAY
  end

  -- Dynamic Fallback: if map is not in MAP_POOLS, inspect game.data.encounters[mapId]
  if game and game.data and game.data.encounters then
    local mapEnc = game.data.encounters[mapId]
    local grass = mapEnc and mapEnc.grass
    if grass and grass.slots then
      local dynamicPool = {}
      for _, slot in ipairs(grass.slots) do
        if slot.species and not Database.EXCLUDED_LEGENDARIES[slot.species] then
          table.insert(dynamicPool, slot.species)
        end
      end
      if #dynamicPool > 0 then return dynamicPool end
    end
  end

  -- Ultimate Fallback pool based on biome
  if Database.BIOMES.CAVES[mapId] then
    return { "ZUBAT", "GEODUDE", "MACHOP", "ONIX", "GRAVELER", "PARAS" }
  elseif Database.BIOMES.WATER[mapId] then
    return { "TENTACOOL", "TENTACRUEL", "STARYU", "HORSEA", "PSYDUCK" }
  end

  return { "PIDGEY", "RATTATA", "CATERPIE", "WEEDLE", "ODDISH", "BELLSPROUT", "NIDORAN_F", "NIDORAN_M" }
end

-- Return target count of active overworld Pokemon for mapId
function Database.getTargetCount(mapId)
  if not Database.isWildMap(mapId) then return 0 end

  if Database.BIOMES.SMALL_ROUTES[mapId] then
    return 5
  end
  if Database.BIOMES.LARGE_ROUTES[mapId] or Database.BIOMES.CAVES[mapId] then
    return 8
  end
  return 5
end

return Database
