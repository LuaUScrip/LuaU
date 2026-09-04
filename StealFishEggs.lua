local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua",
    true
))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function remote(path)
    local obj = ReplicatedStorage
    for _, name in ipairs(path) do
        obj = obj:FindFirstChild(name)
        if not obj then return nil end
    end
    return obj
end

local SellRequest = remote({"SellSystem", "SellRequest"})
local BuyTrailCash = remote({"TrailSystem", "BuyTrailCash"})
local EquipBestFish = remote({"FishSystem", "EquipBestFish"})
local UpgradeTank = remote({"TankLevels", "UpgradeTank"})
local UpgradeTreadPool = remote({"TreadPoolLevels", "UpgradeTreadPool"})
local ClaimFishIndex = remote({"FishIndexSystem", "ClaimFishIndex"})

local FishConfig
pcall(function()
    FishConfig = require(remote({"FishSystem", "FishConfig"}))
end)

local function teleportTo(pos)
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    if root then
        root.CFrame = CFrame.new(pos)
    end
end

local win1 = Library:CreateWindow("AntiGodHub")

local autoSell, autoBuyTrail, equipBest, upgradeTank, upgradeTread, claimIndex = false, false, false, false, false, false
local TRAILS = {"Basic", "Rare", "Epic", "Legendary", "Mythic", "Abyssal", "Astral"}

win1:AddToggle({text = "Auto Sell All", callback = function(v) autoSell = v end})
win1:AddToggle({text = "Auto Buy Trail", callback = function(v) autoBuyTrail = v end})
win1:AddToggle({text = "Equip Best Fish", callback = function(v) equipBest = v end})
win1:AddToggle({text = "Upgrade Tank", callback = function(v) upgradeTank = v end})
win1:AddToggle({text = "Upgrade Treadmill", callback = function(v) upgradeTread = v end})
win1:AddToggle({text = "Claim Index", callback = function(v) claimIndex = v end})

task.spawn(function()
    while true do
        task.wait(0.5)
        if autoSell and SellRequest then
            local ok, res = pcall(SellRequest.InvokeServer, SellRequest, "SellInventory")
            if ok and res then print("[Sell] Count:", res[1] and res[1].Count) end
        end
        if autoBuyTrail and BuyTrailCash then
            for _, trail in ipairs(TRAILS) do
                pcall(BuyTrailCash.InvokeServer, BuyTrailCash, trail)
            end
        end
        if equipBest and EquipBestFish then
            pcall(EquipBestFish.FireServer, EquipBestFish)
        end
        if upgradeTank and UpgradeTank then
            pcall(UpgradeTank.FireServer, UpgradeTank)
        end
        if upgradeTread and UpgradeTreadPool then
            pcall(UpgradeTreadPool.FireServer, UpgradeTreadPool, "Upgrade")
        end
        if claimIndex and ClaimFishIndex then
            pcall(ClaimFishIndex.FireServer, ClaimFishIndex, "ALL")
        end
    end
end)

local win2 = Library:CreateWindow("Farming")

local RARITIES = {"Basic", "Rare", "Epic", "Legendary", "Mythic", "Abyssal", "Astral"}
pcall(function()
    local cfg = require(remote({"EggSystem", "EggRarityConfig"}))
    if cfg and type(cfg.RarityOrder) == "table" and #cfg.RarityOrder > 0 then
        RARITIES = cfg.RarityOrder
    end
end)

local FishModels = remote({"FishModels"})
local rarity, farming = RARITIES[1], false
local HOME = Vector3.new(35, 119, -49)

win2:AddList({text = "Select Rarity", values = RARITIES, value = RARITIES[1], callback = function(v) rarity = v end})
win2:AddToggle({text = "Collect Eggs", callback = function(v) farming = v end})

local function getFishNames(rarityName)
    local folder = FishModels and FishModels:FindFirstChild(rarityName .. "Fish")
    if not folder then return {} end
    local names = {}
    for _, fish in ipairs(folder:GetChildren()) do
        names[#names + 1] = fish.Name
    end
    return names
end

local function getEggPrefixes(fishNames)
    local prefixes = {}
    for _, name in ipairs(fishNames) do
        local found
        for _, key in ipairs({name, name:gsub("^Fish", ""), "Fish" .. name}) do
            local cfg = FishConfig and FishConfig[key]
            if cfg and cfg.EggModelName then
                prefixes[cfg.EggModelName] = true
                found = true
                break
            end
        end
        if not found then
            prefixes[name] = true
            if name:sub(-5) ~= "Model" then prefixes[name .. "Model"] = true end
        end
    end
    return prefixes
end

local function findEgg(rarityName)
    local prefixes = getEggPrefixes(getFishNames(rarityName))
    local eggsFolder = Workspace:FindFirstChild("SpawnedEggs")
    if not eggsFolder then return nil end
    for _, egg in ipairs(eggsFolder:GetChildren()) do
        local base = egg.Name:match("^(.-)_%d+$") or egg.Name
        if prefixes[base] or prefixes[egg.Name] then
            return egg
        end
    end
    return nil
end

local function fireEggPrompt(egg)
    local part = egg.PrimaryPart or egg:FindFirstChild("PrimaryPart") or egg:FindFirstChildOfClass("Part")
    local prompt = part and part:FindFirstChild("EggPrompt")
    if not prompt then
        prompt = egg:FindFirstChild("EggPrompt")
    end
    if not prompt then return false end
    return pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        elseif fireprompt then
            fireprompt(prompt)
        elseif fire then
            fire(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(0.2)
            prompt:InputHoldEnd()
        end
    end)
end

task.spawn(function()
    while true do
        if not farming then
            task.wait(0.5)
        else
            local egg = findEgg(rarity)
            if egg then
                local part = egg.PrimaryPart or egg:FindFirstChild("PrimaryPart") or egg:FindFirstChildOfClass("Part")
                if part then
                    teleportTo(part.Position + Vector3.new(0, 4, 0))
                    task.wait(0.3)
                    fireEggPrompt(egg)
                    task.wait(0.3)
                    teleportTo(HOME)
                    task.wait(0.15)
                end
            else
                task.wait(0.1)
            end
        end
    end
end)

Library:Init()