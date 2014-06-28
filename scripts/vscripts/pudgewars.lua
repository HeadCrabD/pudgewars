print("![PudgeWars] Hello World")

developmentmode = true
TIMER_USE_GAME_TIME =  true

STARTING_GOLD = 500
DOTA2XGAMEMODE_PLACEHOLDER = nil
GameMode = nil

if PudgeWarsGameMode == nil then
    print ( '[pudgewars] create pudgewars game mode' )
    PudgeWarsGameMode = {}
    PudgeWarsGameMode.szEntityClassName = "pudgewars"
    PudgeWarsGameMode.szNativeClassName = "dota_base_game_mode"
    PudgeWarsGameMode.__index = PudgeWarsGameMode
end

function PudgeWarsGameMode:new( o )
    print ( '[pudgewars] new' )
    o = o or {}
    setmetatable( o, self )
    return o
end

function PudgeWarsGameMode:InitGameMode()
    print('[PudgeWars] Starting to load PudgeWars gamemode...')

    GameRules:SetHeroRespawnEnabled( false )
    GameRules:SetUseUniversalShopMode( false )
    GameRules:SetSameHeroSelectionEnabled( true )
    GameRules:SetPreGameTime( 30.0)
    GameRules:SetPostGameTime( 60.0 )
    GameRules:SetTreeRegrowTime( 60.0 )
    GameRules:SetUseCustomHeroXPValues ( false )
    GameRules:SetGoldPerTick(0)
    print('[PudgeWars] Rules set')

    ListenToGameEvent('entity_killed', Dynamic_Wrap(PudgeWarsGameMode, 'OnEntityKilled'), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(PudgeWarsGameMode, 'AutoAssignPlayer'), self)
    --ListenToGameEvent('player_disconnect', Dynamic_Wrap(PudgeWarsGameMode, 'CleanupPlayer'), self)
    --ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(PudgeWarsGameMode, 'ShopReplacement'), self)
    --ListenToGameEvent('player_say', Dynamic_Wrap(PudgeWarsGameMode, 'PlayerSay'), self)
    --ListenToGameEvent('player_connect', Dynamic_Wrap(PudgeWarsGameMode, 'PlayerConnect'), self)
    --ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(PudgeWarsGameMode, 'AbilityUsed'), self)
    
    Convars:RegisterCommand('fake', function()
            self:CreateTimer('assign_fakes', {
                endTime = Time(),
                callback = function(PudgeWars, args)
                    for i=0, 9 do
                        if PlayerResource:IsFakeClient(i) then
                            local ply = PlayerResource:GetPlayer(i)
                            if ply then
                                CreateHeroForPlayer('npc_dota2x_pudgewars_pudge', ply)
                            end
                        end
                    end
                end})
    end, 'Connects and assigns fake Players.', 0)

    local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
    math.randomseed(tonumber(timeTxt))

    --Init Timers
    self.timers = {}

    --Init UserMap
    self.vUserNames = {}
    self.vUserIds = {}
    self.vSteamIds = {}
    self.vBots = {}
    self.vBroadcasters = {}
    self.vPlayers = {}
    self.vRadiant = {}
    self.vDire = {}
    self.vPlayerHeroData = {}

    --Find the gold and chest spawner
    self.tuGold = {}
    self.tuChest = {}
    self.eGoldSpawner  = Entities:FindByName(nil,"dota_pudgewar_gold_spawner" )
    self.eChestSpawner = Entities:FindByName(nil,"dota_pudgewar_chest_spawner")

    initHookData()
    self.t0 = 0
    PrecacheUnitByName('npc_precache_everything')
    print('[PudgeWars] Done loading PudgeWars gamemode!\n\n')

end

function PudgeWarsGameMode:CaptureGameMode()
    if GameMode == nil then
        GameMode = GameRules:GetGameModeEntity()        
        GameMode:SetRecommendedItemsDisabled( true )
        GameMode:SetCameraDistanceOverride( 900.0 )
        GameMode:SetCustomBuybackCostEnabled( true )
        GameMode:SetCustomBuybackCooldownEnabled( true )
        GameMode:SetBuybackEnabled( false )
        GameMode:SetTopBarTeamValuesOverride ( true )
        GameMode:SetUseCustomHeroLevels ( false )
        GameRules:SetHeroMinimapIconSize( 300 )

        GameMode:SetContextThink("PudgewarsThink", Dynamic_Wrap( PudgeWarsGameMode, 'Think' ), 0.1 )
        print("[PudgeWars] Pudgewars game mode begin to think")

        self:InitGoldAndChestTimer()
        --create gold and chest spawn timer
        

    end 
end
function PudgeWarsGameMode:InitGoldAndChestTimer( ... )
    if self.timers["gold_spawn_timer"] == nil then
        self:CreateTimer("gold_spawn_timer",{
            endTime = GameRules:GetGameTime() + math.random( 10 , 20 ),
            useGameTime = true,
            continousTimer = true,
            callback = function(pudgewars, args)
                print("[PudgeWars] Spawning Gold")
                if self.eGoldSpawner and self.eChestSpawner then
                    local vGoldSpawnPos = self.eGoldSpawner:GetOrigin()
                    local vGoldMoveTarget = self.eChestSpawner:GetOrigin()
                    local unit = CreateUnitByName("npc_dota2x_pudgewars_gold",vGoldSpawnPos,true,nil,DOTA_TEAM_NEUTRALS)
                    table.insert( self.tuGold , #self.tuGold +1 , unit )
                    local uIndex = unit.entindex()
                    local moveOrder = {
                        UnitIndex = uIndex,
                        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        Position = vGoldMoveTarget,
                        Queue = false
                    }
                    ExecuteOrderFromTable(moveOrder)
                else
                    print('err gold spawner or chest spawner not found on the map')
                end
            end
        })
    end
    if self.timers["chest_spawn_timer"] == nil then
        self:CreateTimer("chest_spawn_timer",{
            endTime = GameRules:GetGameTime() + math.random( 30 , 60 ),
            useGameTime = true,
            continousTimer = true,
            callback = function(pudgewars, args)
                print("[PudgeWars] Spawning Chest")
                if self.eGoldSpawner and self.eChestSpawner then
                    local vChestSpawnPos = self.eChestSpawner:GetOrigin()
                    local vChestMoveTarget = self.eGoldSpawner:GetOrigin()
                    local unit = CreateUnitByName("npc_dota2x_pudgewars_chest",vChestSpawnPos,true,nil,DOTA_TEAM_NEUTRALS)
                    table.insert( self.tuChest , #self.tuChest +1 , unit )
                    local uIndex = unit.entindex()
                    local moveOrder = {
                        UnitIndex = uIndex,
                        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        Position = vChestMoveTarget,
                        Queue = false
                    }
                    ExecuteOrderFromTable(moveOrder)
                else
                    print('err gold spawner or chest spawner not found on the map')
                end
            end
        })
    end
end

function PudgeWarsGameMode:Think()
    if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
        return
    end

    local now = GameRules:GetGameTime()
    if PudgeWarsGameMode.t0 == nil or PudgeWarsGameMode == 0 then
        PudgeWarsGameMode.t0 = now
    end
    local dt = now - PudgeWarsGameMode.t0
    PudgeWarsGameMode.t0 = now

    for k,v in pairs(PudgeWarsGameMode.timers) do
        local bUseGameTime = TIMER_USE_GAME_TIME
        if v.useGameTime and v.useGameTime == true then
            bUseGameTime = true;
        end
        if (bUseGameTime and GameRules:GetGameTime() > v.endTime) or (not bUseGameTime and Time() > v.endTime) then
            PudgeWarsGameMode.timers[k] = nil
            local status, continousTimer = pcall(v.callback, PudgeWarsGameMode, v)

            -- Make sure it worked
            if status then
                -- Check if it needs to loop
                if continousTimer then
                    -- Change it's end time
                    v.endTime = continousTimer
                    PudgeWarsGameMode.timers[k] = v
                end

            else
                -- Nope, handle the error
                PudgeWarsGameMode:HandleEventError('Timer', k, continousTimer)
            end
        end
    end

    return dt
end
function PudgeWarsGameMode:AutoAssignPlayer(keys)
    -- if any player connected, then start theh game mode
    PudgeWarsGameMode:CaptureGameMode()

    print ('[pudgewars] AutoAssignPlayer Fired')
    PrintTable (keys)
    
    local entIndex = keys.index + 1
    local ply = EntIndexToHScript(entIndex)
    local playerID = ply:GetPlayerID()
    
    -- If we're not on D2MODD.in, assign players round robin to teams
    if playerID == -1 then
        if #self.vRadiant > #self.vDire then
            ply:SetTeam(DOTA_TEAM_BADGUYS)
            ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_BADGUYS)
            table.insert (self.vDire, ply)
        else
            ply:SetTeam(DOTA_TEAM_GOODGUYS)
            ply:__KeyValueFromInt('teamnumber', DOTA_TEAM_GOODGUYS)
            table.insert (self.vRadiant, ply)
        end
        playerID = ply:GetPlayerID()
    end

    --Autoassign player
    self:CreateTimer('assign_player_'..entIndex, {
        endTime = Time(),
        callback = function(pudgewars, args)
            local heroEntity = ply:GetAssignedHero()
            if heroEntity == nil then
                print("ply hero entity = nil reassign it ")
                CreateHeroForPlayer('npc_dota_hero_pudge', ply)
                heroEntity = ply:GetAssignedHero()
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_hook")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_hook not found") end
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_toggle_hook")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_toggle_hook not found") end
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_upgrage_hook_damage")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_upgrage_hook_damage not found") end
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_upgrade_hook_radius")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_upgrade_hook_radius not found") end
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_upgrade_hook_length")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_upgrade_hook_length not found") end
                ABILITY = heroEntity:FindAbilityByName("dota2x_pudgewars_upgrade_hook_speed")
                if ABILITY then ABILITY:SetLevel(1) else print("dota2x_pudgewars_upgrade_hook_speed not found") end
                heroEntity:SetAbilityPoints(0)
            end
        end
    })
end

function PudgeWarsGameMode:HandleEventError(name, event, err)
    print(err)
    name = tostring(name or 'unknown')
    event = tostring(event or 'unknown')
    err = tostring(err or 'unknown')
    Say(nil, name .. ' threw an error on event '..event, false)
    Say(nil, err, false)
    if not self.errorHandled then
        self.errorHandled = true
    end
end

function PudgeWarsGameMode:CreateTimer(name, args)
    if not args.endTime or not args.callback then
        print("Invalid timer created: "..name)
        return
    end
    self.timers[name] = args
end

function PudgeWarsGameMode:RemoveTimer(name)
    self.timers[name] = nil
end

function PudgeWarsGameMode:RemoveTimers(killAll)
    local timers = {}
    if not killAll then
        for k,v in pairs(self.timers) do
            if v.continousTimer then
                timers[k] = v
            end
        end
    end
    self.timers = timers
end

function PudgeWarsGameMode:OnEntityKilled(keys)
    PrintTable(keys)
end
