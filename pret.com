if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE = 'https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/'

local games = {
    [380415714] = 'ThrowACoin.lua',
    [34949992] = 'WebSwingForLuckyBlock.lua',
    [1008362692] = 'WebSwingEscape.lua',
    [380644426] = 'VolleyBall.lua',
    [35789662] = 'ThrowARock.lua',
    [6617290] = 'SpeedVsGiant.lua',
    [755009393] = 'Plus1WallhopeObbyEscape.lua',
    [912232112] = 'Plus1StandPowerEvolution.lua',
    [166307374] = 'Plus1SpeedSlimeEscape.lua',
    [32350554] = 'Plus1SpeedPerClick.lua',
    [900737444] = 'Plus1SpeedNinjaKeyboardEscape.lua',
    [34842200] = 'Plus1SlimeKeyboardEscape.lua',
    [73354146] = 'BeAFishBait.lua',
    [124937935] = 'CarsVsTape.lua',
    [34492682] = 'ChickenFarm.lua',
    [622013004] = 'CleanYourKeycaps.lua',
    [254824034] = 'ClimbTheUniverse.lua',
    [522804844] = 'ClimbWaterslideAndSlide.lua',
    [525269288] = 'DogRace.lua',
    [33893781] = 'DreamKeyboardEscape.lua',
    [835055045] = 'DriveCarAndSlide.lua',
    [592785028] = 'FishForJunk.lua',
    [1041268469] = 'FishingChef.lua',
    [612510500] = 'HoleFishing.lua',
    [854390513] = 'JumpToStealPlayer.lua',
    [854390513] = 'JumpToStealSlime.lua',
    [393047738] = 'LickAFish.lua',
    [32445464] = 'MurderVsSherif.lua',
    [1012646512] = 'Plus1AuraToBlastBosses.lua',
    [697469702] = 'Plus1BackflipKeyboardEscape.lua',
    [447185872] = 'Plus1BackflipObbyEscape.lua',
    [17052250] = 'Plus1BottleFlipObbyEscape.lua',
    [3434923] = 'Plus1DoubleJumpBikeEscape.lua',
    [959292201] = 'Plus1FirePerClick.lua',
    [760075281] = 'Plus1FollowersPerClick.lua',
    [554364117] = 'Plus1HeatPerClick.lua',
    [290230886] = 'Plus1HighJumpPowerEscape.lua',
    [750112327] = 'JumpCrunchy.lua',
    [136586527] = 'Plus1KaijuEvolution.lua',
    [719799116] = 'Plus1KaijuPowerPerClick.lua',
    [129736655] = 'Plus1KatanaEvolution.lua',
    [298851451] = 'Plus1KeyboardEscapeUnderwater.lua',
    [987531238] = 'Plus1LadderPerClick.lua',
    [232837303] = 'Plus1LavaEscape.lua',
    [306375276] = 'Plus1LootEvolution.lua',
    [35328876] = 'Plus1MonkeyBananaDestruction.lua',
    [999320972] = 'Plus1MuscleForPrisonEscape.lua',
    [33752759] = 'Plus1MuscleToPushBoulder.lua',
    [650599714] = 'Plus1MuscleToSlapFight.lua',
    [490911723] = 'Plus1PickaxeSwingEscape.lua',
    [772967743] = 'Plus1PullPerStep.lua',
    [150185229] = 'Plus1RollerForNeedoh.lua',
    [896205907] = 'PressAKeycaps.lua',
    [993102780] = 'StealABrainrotEgg.lua',
    [34304529] = 'StealAChicken.lua',
    [359321322] = 'StealBabyEgg.lua',
    [984941738] = 'StealFishEggs.lua',
    [35850353] = 'SurfForLuckyBlock.lua',
    [641497291] = 'skinperstep.luau',
    [525269288] = 'DogRace.lua',
}

if identifyexecutor then
    local execName = tostring(identifyexecutor()):lower()
    local UNSUPPORTED = { "Solara", "Xeno" }
    for _, name in ipairs(UNSUPPORTED) do
        if execName:find(name:lower(), 1, true) then
            local Players = game:GetService("Players")
            Players.LocalPlayer:Kick(table.concat({
                "EXECUTOR NOT SUPPORTED",
                "Executor: " .. execName,
                "This executor is not compatible with this script",
            }, "\n"))
            return
        end
    end
end

local file = games[game.CreatorId]
if file then
    task.wait(math.random())
    loadstring(game:HttpGet(BASE .. file))()
end
