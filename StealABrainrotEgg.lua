local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua",
    true
))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local RequestSell = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RequestSell")
local RequestPlotUpgrade = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RequestPlotUpgrade")
local RequestTreadmillUpgrade = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RequestTreadmillUpgrade")
local EquipBestPets = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("EquipBestPets")
local TrailAction = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("TrailAction")

-- Hardcoded trail list
local TRAILS = {"OrangeTrail", "BlueTrail", "GreenTrail", "PurpleTrail", "RainbowTrail"}

local win1 = Library:CreateWindow("AntiGodHub")

local sellAll = false
local plotUpgrade = false
local treadmillUpgrade = false
local equipBestPets = false
local autoBuyTrail = false

win1:AddToggle({text = "Sell All", callback = function(v) sellAll = v end})
win1:AddToggle({text = "Plot Upgrade", callback = function(v) plotUpgrade = v end})
win1:AddToggle({text = "Treadmill Upgrade", callback = function(v) treadmillUpgrade = v end})
win1:AddToggle({text = "Equip Best Pets", callback = function(v) equipBestPets = v end})
win1:AddToggle({text = "Auto Buy Trail", callback = function(v) autoBuyTrail = v end})
win1:AddButton({text = "Anti Guard", callback = function()
    pcall(function()
        local bosses = Workspace:FindFirstChild("Bosses")
        if bosses then
            for _, folder in ipairs(bosses:GetChildren()) do
                pcall(function() folder:Destroy() end)
            end
        end
    end)
end})

task.spawn(function()
    while true do
        task.wait(0.3)
        
        if sellAll and RequestSell then
            pcall(function() RequestSell:FireServer("Inventory") end)
        end
        
        if plotUpgrade and RequestPlotUpgrade then
            pcall(function() RequestPlotUpgrade:InvokeServer() end)
            task.wait(0.1)
        end
        
        if treadmillUpgrade and RequestTreadmillUpgrade then
            pcall(function() RequestTreadmillUpgrade:InvokeServer() end)
            task.wait(0.1)
        end
        
        if equipBestPets and EquipBestPets then
            pcall(function() EquipBestPets:FireServer() end)
            task.wait(0.1)
        end
    end
end)

-- Auto buy hardcoded trails
task.spawn(function()
    while true do
        if autoBuyTrail and TrailAction then
            for _, trailName in ipairs(TRAILS) do
                if autoBuyTrail then
                    pcall(function()
                        TrailAction:FireServer("BuyMoney", trailName)
                    end)
                    task.wait(0.3)
                end
            end
        end
        task.wait(1)
    end
end)

local win2 = Library:CreateWindow("Farming")

local ZONES = {"Zone1", "Zone2", "Zone3", "Zone4", "Zone5", "Zone6", "Zone7", "Zone8"}
local selectedZone = ZONES[1]
local farming = false
local HOME = Vector3.new(25, 3, 125)

win2:AddList({text = "Select Zone", values = ZONES, value = ZONES[1], callback = function(v) 
    selectedZone = v
end})
win2:AddToggle({text = "Collect Egg", callback = function(v) farming = v end})
win2:AddButton({text = "Go Home", callback = function()
    pcall(function()
        local player = Players.LocalPlayer
        if not player then return end
        
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(HOME)
        end
    end)
end})

-- Get all eggs in zone
local function getAllEggsInZone(zoneName)
    local eggs = {}
    
    local eggsFolder = Workspace:FindFirstChild("Eggs")
    if not eggsFolder then
        return eggs
    end
    
    local zoneFolder = eggsFolder:FindFirstChild(zoneName)
    if not zoneFolder then
        return eggs
    end
    
    -- Loop through ALL children in zone
    for _, zoneChild in pairs(zoneFolder:GetChildren()) do
        local spawnedEggFolder = zoneChild:FindFirstChild("SpawnedEgg")
        
        if spawnedEggFolder then
            -- Get all eggs in SpawnedEgg
            for _, eggItem in pairs(spawnedEggFolder:GetChildren()) do
                if eggItem:FindFirstChild("EggPromptAttachment") then
                    table.insert(eggs, eggItem)
                end
            end
        end
    end
    
    return eggs
end

-- Get egg position
local function getEggPosition(eggInstance)
    if eggInstance:IsA("BasePart") then
        return eggInstance.Position
    end
    
    if eggInstance:IsA("Model") and eggInstance.PrimaryPart then
        return eggInstance.PrimaryPart.Position
    end
    
    for _, child in pairs(eggInstance:GetChildren()) do
        if child:IsA("BasePart") then
            return child.Position
        end
    end
    
    return nil
end

-- Trigger proximity prompt
local function triggerPrompt(proximityPrompt)
    if fireproximityprompt then
        pcall(function() fireproximityprompt(proximityPrompt) end)
    elseif fireprompt then
        pcall(function() fireprompt(proximityPrompt) end)
    else
        pcall(function()
            proximityPrompt:InputHoldBegin()
            task.wait(0.3)
            proximityPrompt:InputHoldEnd()
        end)
    end
end

-- Main farming loop - FASTER
task.spawn(function()
    while true do
        if not farming then
            task.wait(0.5)
        else
            pcall(function()
                local player = Players.LocalPlayer
                if not player then return end
                
                local character = player.Character
                if not character then return end
                
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoidRootPart then return end
                
                -- Get all eggs in selected zone
                local allEggs = getAllEggsInZone(selectedZone)
                
                if #allEggs == 0 then
                    task.wait(0.3)
                    return
                end
                
                -- Collect each egg FAST
                for _, egg in ipairs(allEggs) do
                    if not farming then break end
                    
                    if not egg or not egg.Parent then
                        continue
                    end
                    
                    pcall(function()
                        local eggPos = getEggPosition(egg)
                        if not eggPos then return end
                        
                        -- Teleport to egg fast
                        local teleportPos = eggPos + Vector3.new(0, 3, 0)
                        humanoidRootPart.CFrame = CFrame.new(teleportPos)
                        task.wait(0.08)
                        
                        -- Verify egg exists
                        if not egg or not egg.Parent then 
                            humanoidRootPart.CFrame = CFrame.new(HOME)
                            return 
                        end
                        
                        -- Fire prompt
                        local promptAttachment = egg:FindFirstChild("EggPromptAttachment")
                        if promptAttachment then
                            local proximityPrompt = promptAttachment:FindFirstChild("ProximityPrompt")
                            if proximityPrompt then
                                task.wait(0.05)
                                triggerPrompt(proximityPrompt)
                                task.wait(0.3)
                            end
                        end
                        
                        -- Return home fast
                        humanoidRootPart.CFrame = CFrame.new(HOME)
                    end)
                    
                    -- 0.3s cooldown (faster than 0.5s)
                    task.wait(0.3)
                end
            end)
            
            task.wait(0.05)
        end
    end
end)

Library:Init()