return function(mod)
    ------------------------------------------------------------
    -- COMBINED: MUSIC + SFX
    -- assets/music/<pack>/   assets/sfx/<pack>/
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- MUSIC
    ------------------------------------------------------------
    local MUSIC_CHOICES = {
        { "ORIGINAL", "original" },
        { "GBA / FIRE RED", "firered" },
        { "LET'S GO", "letsgo" },
    }
    local MUSIC_PACKS = { "firered", "letsgo" }

    local SONG_FILES = {
        Music_PalletTown        = "pallettownnew.ogg",
        Music_Pokecenter        = "pokecenternew.ogg",
        Music_Gym               = "gymnew.ogg",
        Music_Cities1           = "cities1new.ogg",
        Music_Cities2           = "cities2new.ogg",
        Music_Cerulean          = "ceruleannew.ogg",
        Music_Celadon           = "celadonnew.ogg",
        Music_Cinnabar          = "cinnabarnew.ogg",
        Music_Vermilion         = "vermilionnew.ogg",
        Music_Lavender          = "lavendernew.ogg",
        Music_SSAnne            = "ssannenew.ogg",
        Music_SafariZone        = "safarizonenew.ogg",
        Music_Routes1           = "routes1new.ogg",
        Music_Routes2           = "routes2new.ogg",
        Music_Routes3           = "routes3new.ogg",
        Music_Routes4           = "routes4new.ogg",
        Music_IndigoPlateau     = "indigoplateaunew.ogg",
        Music_BikeRiding        = "bikeridingnew.ogg",
        Music_Surfing           = "surfingnew.ogg",
        Music_TitleScreen       = "titlescreennew.ogg",
        Music_Credits           = "creditsnew.ogg",
        Music_HallOfFame        = "halloffamenew.ogg",
        Music_OaksLab           = "oakslabnew.ogg",
        Music_GameCorner        = "gamecornernew.ogg",
        Music_IntroBattle       = "introbattlenew.ogg",
        Music_Dungeon1          = "dungeon1new.ogg",
        Music_Dungeon2          = "dungeon2new.ogg",
        Music_Dungeon3          = "dungeon3new.ogg",
        Music_CinnabarMansion   = "cinnabarmansionnew.ogg",
        Music_PokemonTower      = "pokemontowernew.ogg",
        Music_SilphCo           = "silphconew.ogg",
        Music_PkmnHealed        = "pkmnhealednew.ogg",
        Music_WildBattle        = "wildbattlenew.ogg",
        Music_TrainerBattle     = "trainerbattlenew.ogg",
        Music_GymLeaderBattle   = "gymleaderbattlenew.ogg",
        Music_FinalBattle       = "finalbattlenew.ogg",
        Music_DefeatedWildMon   = "defeatedwildmonnew.ogg",
        Music_DefeatedTrainer   = "defeatedtrainernew.ogg",
        Music_DefeatedGymLeader = "defeatedgymleadernew.ogg",
        Music_MeetProfOak       = "meetprofoaknew.ogg",
        Music_MeetRival         = "meetrivalnew.ogg",
        Music_MuseumGuy         = "museumguynew.ogg",
        Music_MeetEvilTrainer   = "meeteviltrainernew.ogg",
        Music_MeetFemaleTrainer = "meetfemaletrainernew.ogg",
        Music_MeetMaleTrainer   = "meetmaletrainernew.ogg",
    }

    local MUSIC_SFX_FILES = {
        Level_Up   = "levelupnew.ogg",
        Caught_Mon = "caughtpokemonnew.ogg",
    }

    ------------------------------------------------------------
    -- SFX
    ------------------------------------------------------------
    local SFX_CHOICES = {
        { "ORIGINAL", "original" },
        { "FIRE RED", "firered" },
        { "MODERN", "modern" },
        { "GEN 5", "gen5" },
    }

    local SFX_FILES = {
        Press_AB           = "Press_AB.ogg",
        Start_Menu         = "Start_Menu.ogg",
        Tink               = "Tink.ogg",
        Arrow_Tiles        = "Arrow_Tiles.ogg",
        Denied             = "Denied.ogg",
        Purchase           = "Purchase.ogg",
        Save               = "Save.ogg",
        Turn_On_PC         = "Turn_On_PC.ogg",
        Turn_Off_PC        = "Turn_Off_PC.ogg",
        Enter_PC           = "Enter_PC.ogg",
        Withdraw_Deposit   = "Withdraw_Deposit.ogg",
        Switch             = "Switch.ogg",
        Swap               = "Swap.ogg",
        Collision          = "Collision.ogg",
        Go_Inside          = "Go_Inside.ogg",
        Go_Outside         = "Go_Outside.ogg",
        Ledge              = "Ledge.ogg",
        Shrink             = "Shrink.ogg",
        Cut                = "Cut.ogg",
        Fly                = "Fly.ogg",
        Jump               = "Jump.ogg",
        Teleport_Enter_1   = "Teleport_Enter_1.ogg",
        Teleport_Enter_2   = "Teleport_Enter_2.ogg",
        Teleport_Exit_1    = "Teleport_Exit_1.ogg",
        Teleport_Exit_2    = "Teleport_Exit_2.ogg",
        Escape_Rope        = "Escape_Rope.ogg",
        Open_Door          = "Open_Door.ogg",
        Get_Item1          = "Get_Item1.ogg",
        Get_Item2          = "Get_Item2.ogg",
        Get_Key_Item       = "Get_Key_Item.ogg",
        Pokedex_Rating     = "Pokedex_Rating.ogg",
        Dex_Page_Added     = "Dex_Page_Added.ogg",
        Pokeflute          = "Pokeflute.ogg",
        Heal_HP            = "Heal_HP.ogg",
        Heal_Ailment       = "Heal_Ailment.ogg",
        Healing_Machine    = "Healing_Machine.ogg",
        Poisoned           = "Poisoned.ogg",
        Trade_Machine      = "Trade_Machine.ogg",
        Ball_Toss          = "Ball_Toss.ogg",
        Ball_Poof          = "Ball_Poof.ogg",
        Faint_Thud         = "Faint_Thud.ogg",
        Faint_Fall         = "Faint_Fall.ogg",
        Run                = "Run.ogg",
        Peck               = "Peck.ogg",
        Damage             = "Damage.ogg",
        Not_Very_Effective = "Not_Very_Effective.ogg",
    }

    local SFX_PREVIEW = {
        "Press_AB",
        "Start_Menu",
        "Tink",
        "Denied",
        "Save",
    }

    ------------------------------------------------------------
    -- OPTIONS
    ------------------------------------------------------------
    mod.options:define({
        {
            key = "soundtrack",
            type = "choice",
            label = "SOUNDTRACK",
            choices = MUSIC_CHOICES,
            default = "firered",
        },
        {
            key = "sfx_pack",
            type = "choice",
            label = "SOUND EFFECTS",
            choices = SFX_CHOICES,
            default = "firered",
        },
        {
            key = "stereo",
            type = "choice",
            label = "STEREO SOUND",
            choices = {
                { "ON", "on" },
                { "OFF", "off" },
            },
            default = "on",
        },
    })

    local function labelFor(choices, value)
        for _, c in ipairs(choices) do
            if c[2] == value then return c[1] end
        end
        return choices[1][1]
    end

    local function nextChoice(choices, value, dir)
        local i = 1
        for idx, c in ipairs(choices) do
            if c[2] == value then
                i = idx
                break
            end
        end
        i = ((i - 1 + (dir or 1)) % #choices) + 1
        return choices[i][2]
    end

    local function stereoEnabled()
        return (mod.options:get("stereo") or "on") == "on"
    end

    local function getGame()
        local ok, Game = pcall(require, "src.core.Game")
        if ok and Game then return Game end
        return nil
    end

    local function fileExists(path)
        if love and love.filesystem and love.filesystem.getInfo then
            local info = love.filesystem.getInfo(path)
            if info and (info.type == "file" or not info.type) then
                return true
            end
        end
        local f = io.open(path, "rb")
        if f then
            f:close()
            return true
        end
        return false
    end

    local function shallowCopy(t)
        local out = {}
        if type(t) ~= "table" then return out end
        for k, v in pairs(t) do
            out[k] = v
        end
        return out
    end

    local function setOption(game, key, value)
        if game and game.save and game.save.options then
            game.save.options.modOptions = game.save.options.modOptions or {}
            local t = game.save.options.modOptions
            t[mod.id] = t[mod.id] or {}
            t[mod.id][key] = value
        end
        local loader = game and game.mods
        if loader then
            loader.modOptions = loader.modOptions or {}
            loader.modOptions[mod.id] = loader.modOptions[mod.id] or {}
            loader.modOptions[mod.id][key] = value
        end
    end

    ------------------------------------------------------------
    -- Stereo tracking — apply ON/OFF to sources that are playing NOW
    ------------------------------------------------------------
    -- Weak keys so finished sources can be GC'd
    local trackedSources = setmetatable({}, { __mode = "k" })

    local function configureSource(src)
        if not src then return src end
        pcall(function()
            if stereoEnabled() then
                if src.setRelative then src:setRelative(false) end
            else
                -- Mono-style: pinned to listener center
                if src.setRelative then src:setRelative(true) end
                if src.setPosition then src:setPosition(0, 0, 0) end
                if src.setAttenuationDistances then
                    src:setAttenuationDistances(0, 0)
                end
            end
        end)
        trackedSources[src] = true
        return src
    end

    -- Immediate: every tracked source still playing
    local function applyStereoLive()
        for src, _ in pairs(trackedSources) do
            local alive = true
            pcall(function()
                if src.isPlaying and not src:isPlaying() then
                    -- keep config for next play of same instance
                end
                configureSource(src)
            end)
            if not alive then
                trackedSources[src] = nil
            end
        end
    end

    do
        local Sound = require("src.core.Sound")

        local origPlay = Sound.play
        function Sound.play(data, name, ...)
            return configureSource(origPlay(data, name, ...))
        end

        if Sound.playCry then
            local origCry = Sound.playCry
            function Sound.playCry(data, species, ...)
                return configureSource(origCry(data, species, ...))
            end
        end

        if Sound.playPikaCry then
            local origPika = Sound.playPikaCry
            function Sound.playPikaCry(data, n, ...)
                return configureSource(origPika(data, n, ...))
            end
        end
    end

    ------------------------------------------------------------
    -- REGISTER MUSIC (load-time only)
    ------------------------------------------------------------
    for _, pack in ipairs(MUSIC_PACKS) do
        for vanilla, filename in pairs(SONG_FILES) do
            mod.content.music:register(vanilla .. "_" .. pack, {
                file = mod.assets:path(
                    ("assets/music/%s/%s"):format(pack, filename)
                ),
            })
        end
        mod.content.music:register("Music_Evolution_" .. pack, {
            file = mod.assets:path(
                ("assets/music/%s/evolutionnew.ogg"):format(pack)
            ),
        })
        for name, filename in pairs(MUSIC_SFX_FILES) do
            mod.content.sfx:register(name .. "_" .. pack, {
                file = mod.assets:path(
                    ("assets/music/%s/%s"):format(pack, filename)
                ),
            })
        end
    end

    local bootMusic = mod.options:get("soundtrack") or "firered"
    if bootMusic ~= "original" then
        for name, filename in pairs(MUSIC_SFX_FILES) do
            local path = mod.assets:path(
                ("assets/music/%s/%s"):format(bootMusic, filename)
            )
            mod.content.sfx:override(name, { file = path })
        end
        mod.content.audio:patch("special", {
            evolution = "Music_Evolution_" .. bootMusic,
        })
    end

    ------------------------------------------------------------
    -- APPLY MUSIC
    ------------------------------------------------------------
    local function applySoundtrack(pack)
        local Game = getGame()
        local data = Game and Game.data
        if data and data.audio then
            data.audio.special = data.audio.special or {}
            if pack == "original" then
                data.audio.special.evolution = "Music_SafariZone"
            else
                data.audio.special.evolution = "Music_Evolution_" .. pack
            end
            if data.audio.sfx then
                for name, _ in pairs(MUSIC_SFX_FILES) do
                    if pack ~= "original" then
                        local alt = data.audio.sfx[name .. "_" .. pack]
                        if alt then
                            data.audio.sfx[name] = alt
                        end
                    end
                end
            end
        end

        local Music = require("src.core.Music")
        Music.reload()

        if not data then return end

        local stack = Game and Game.stack
        if stack and stack.states then
            for i = #stack.states, 1, -1 do
                local s = stack.states[i]
                if s and type(s.startMusic) == "function" then
                    s:startMusic()
                    return
                end
            end
        end

        Music.restoreMap(data)
    end

    ------------------------------------------------------------
    -- APPLY SFX
    ------------------------------------------------------------
    local vanillaSfx = nil

    local function ensureVanillaSfx(data)
        if vanillaSfx or not data or not data.audio or not data.audio.sfx then
            return
        end
        vanillaSfx = shallowCopy(data.audio.sfx)
    end

    local function applySfxPack(pack)
        local Game = getGame()
        local data = Game and Game.data
        if not data or not data.audio or not data.audio.sfx then
            return
        end

        ensureVanillaSfx(data)

        if vanillaSfx then
            for name, def in pairs(vanillaSfx) do
                data.audio.sfx[name] = def
            end
        end

        local musicPack = mod.options:get("soundtrack") or "firered"
        if musicPack ~= "original" and data.audio.sfx then
            for name, _ in pairs(MUSIC_SFX_FILES) do
                local alt = data.audio.sfx[name .. "_" .. musicPack]
                if alt then
                    data.audio.sfx[name] = alt
                end
            end
        end

        if pack ~= "original" then
            for name, filename in pairs(SFX_FILES) do
                local path = mod.assets:path(
                    ("assets/sfx/%s/%s"):format(pack, filename)
                )
                if fileExists(path) then
                    data.audio.sfx[name] = { file = path }
                end
            end
        end

        local Sound = require("src.core.Sound")
        if Sound.invalidate then
            Sound.invalidate()
        end
    end

    ------------------------------------------------------------
    -- SFX option preview
    ------------------------------------------------------------
    local function playRandomSfxPreview(pack)
        local name = SFX_PREVIEW[love.math.random(#SFX_PREVIEW)]
        local Game = getGame()
        local data = Game and Game.data
        local Sound = require("src.core.Sound")

        if pack and pack ~= "original" then
            local filename = SFX_FILES[name]
            if filename then
                local path = mod.assets:path(
                    ("assets/sfx/%s/%s"):format(pack, filename)
                )
                if fileExists(path) and love.audio then
                    local ok, src = pcall(love.audio.newSource, path, "static")
                    if ok and src then
                        configureSource(src)
                        src:stop()
                        src:play()
                        return
                    end
                end
            end
        end

        if data and Sound.play then
            Sound.play(data, name)
        end
    end

    ------------------------------------------------------------
    -- music.select
    ------------------------------------------------------------
    mod.hooks:wrap("music.select", function(next, song, ctx)
        local pack = mod.options:get("soundtrack")
        if pack == "original" or not song then
            return next(song, ctx)
        end
        if SONG_FILES[song] then
            return song .. "_" .. pack
        end
        return next(song, ctx)
    end)

    ------------------------------------------------------------
    -- Heal jingle → restore map music
    ------------------------------------------------------------
    local healRestoreAt = nil
    local HEAL_SECONDS = 3.5

    local function isHealSong(song)
        if type(song) ~= "string" then return false end
        return song == "Music_PkmnHealed"
            or song:find("PkmnHealed", 1, true) ~= nil
    end

    mod.events:on("music.started", function(ev)
        if ev and isHealSong(ev.song) then
            healRestoreAt = love.timer.getTime() + HEAL_SECONDS
        end
    end)

    mod.hooks:wrap("music.volume", function(next, vol, ctx)
        if healRestoreAt and love.timer.getTime() >= healRestoreAt then
            healRestoreAt = nil
            local Game = getGame()
            if Game and Game.data then
                require("src.core.Music").restoreMap(Game.data)
            end
        end
        return next(vol, ctx)
    end)

    ------------------------------------------------------------
    -- Boot
    ------------------------------------------------------------
    mod.events:on("game.ready", function()
        local Game = getGame()
        if Game and Game.data then
            ensureVanillaSfx(Game.data)
        end
        applySoundtrack(mod.options:get("soundtrack") or "firered")
        applySfxPack(mod.options:get("sfx_pack") or "firered")
        applyStereoLive()
    end)

    ------------------------------------------------------------
    -- MAIN OPTIONS MENU
    ------------------------------------------------------------
    mod.hooks:wrap("ui.options.rows", function(next, game, rows)
        rows = next(game, rows) or rows

        local function already(id)
            for _, r in ipairs(rows) do
                if r.id == id then return true end
            end
            return false
        end

        local function tryInsert(row, anchors)
            if already(row.id) then return end
            local inserted = false
            if mod.ui and mod.ui.insertAfter then
                for _, anchor in ipairs(anchors) do
                    local n = #rows
                    mod.ui.insertAfter(rows, anchor, row)
                    if #rows > n then
                        inserted = true
                        break
                    end
                end
            end
            if not inserted then
                rows[#rows + 1] = row
            end
        end

        tryInsert({
            id = "mod_soundtrack",
            label = "SOUNDTRACK",
            value = function()
                return labelFor(MUSIC_CHOICES, mod.options:get("soundtrack"))
            end,
            step = function(g, dir)
                local cur = mod.options:get("soundtrack") or "firered"
                local new = nextChoice(MUSIC_CHOICES, cur, dir or 1)
                setOption(g, "soundtrack", new)
                applySoundtrack(new)
                applySfxPack(mod.options:get("sfx_pack") or "firered")
                return true
            end,
        }, { "MUSIC VOL", "SFX VOL" })

        tryInsert({
            id = "mod_sfx_pack",
            label = "SOUND EFFECTS",
            value = function()
                return labelFor(SFX_CHOICES, mod.options:get("sfx_pack"))
            end,
            step = function(g, dir)
                local cur = mod.options:get("sfx_pack") or "firered"
                local new = nextChoice(SFX_CHOICES, cur, dir or 1)
                setOption(g, "sfx_pack", new)
                applySfxPack(new)
                playRandomSfxPreview(new)
                return true
            end,
        }, { "SFX VOL", "MUSIC VOL", "SOUNDTRACK" })

        tryInsert({
            id = "mod_stereo",
            label = "STEREO SOUND",
            value = function()
                local v = mod.options:get("stereo") or "on"
                return v == "on" and "ON" or "OFF"
            end,
            step = function(g, dir)
                local cur = mod.options:get("stereo") or "on"
                local new = nextChoice(
                    { { "ON", "on" }, { "OFF", "off" } },
                    cur,
                    dir or 1
                )
                setOption(g, "stereo", new)
                -- Instant: retarget every source already playing
                applyStereoLive()
                return true
            end,
        }, { "SOUND EFFECTS", "SFX VOL", "MUSIC VOL" })

        return rows
    end)

    ------------------------------------------------------------
    -- Mod manager
    ------------------------------------------------------------
    mod.events:on("mod.options_changed", function(ev)
        if ev.key == "soundtrack" then
            applySoundtrack(ev.value)
            applySfxPack(mod.options:get("sfx_pack") or "firered")
        elseif ev.key == "sfx_pack" then
            applySfxPack(ev.value)
            playRandomSfxPreview(ev.value)
        elseif ev.key == "stereo" then
            applyStereoLive()
        end
    end)
end