local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local BridgeNet2 = require(ReplicatedStorage.Packages.BridgeNet2)
local KeycapConfig = require(ReplicatedStorage.Shared.Schematics.KeycapConfig)
local CleaningConfig = require(ReplicatedStorage.Shared.Schematics.CleaningConfig)
local CarryConfig = require(ReplicatedStorage.Shared.Schematics.CarryConfig)
local PlacementConfig = require(ReplicatedStorage.Shared.Schematics.PlacementConfig)
local IncomeConfig = require(ReplicatedStorage.Shared.Schematics.IncomeConfig)
local SoapConfig = require(ReplicatedStorage.Shared.Schematics.SoapConfig)
local SpongeConfig = require(ReplicatedStorage.Shared.Schematics.SpongeConfig)
local UpgradeConfig = require(ReplicatedStorage.Shared.Schematics.UpgradeConfig)
local RebirthConfig = require(ReplicatedStorage.Shared.Schematics.RebirthConfig)
local WorkerConfig = require(ReplicatedStorage.Shared.Schematics.WorkerConfig)

local Bridges = {
    CleanSession = BridgeNet2.ReferenceBridge("CleanSession"),
    SoapRoll = BridgeNet2.ReferenceBridge("SoapRoll"),
    SoapDunk = BridgeNet2.ReferenceBridge(SoapConfig.Dunk.Bridge),
    Upgrade = BridgeNet2.ReferenceBridge(UpgradeConfig.Bridge),
    Rebirth = BridgeNet2.ReferenceBridge(RebirthConfig.Bridge),
    Worker = BridgeNet2.ReferenceBridge(WorkerConfig.Bridge),
    Sponge = BridgeNet2.ReferenceBridge("SpongeShop"),
}

local CONFIG = {
    PlacedTag = KeycapConfig.PlacedTag,
    CleanableTag = KeycapConfig.CleanableTag,
    CleanerAttr = CleaningConfig.Scrub.ClaimAttr,
    CarryToolName = CarryConfig.ToolName,
    OccupiedAttr = PlacementConfig.OccupiedAttr,
    SoapBoothFolder = SoapConfig.Booth.FolderName,
    EquippedSpongeAttr = SpongeConfig.EquippedAttr,
}

local running = {
    autoWashPlace = false,
    autoRoll = false,
    autoDunk = false,
    autoCollect = false,
    autoWorkers = false,
    autoRebirth = false,
    autoUpgrades = false,
    autoSponges = false,
}

local loops = {}
local lastRolledSoapTier = nil
local lastSpongeBuy = {}
local antiAfkData = { lastInput = tick(), lastTap = tick() }

local collectTween = nil
local collectConnection = nil

local soapNames = {}
for _, soap in ipairs(SoapConfig.Soaps) do
    table.insert(soapNames, soap.DisplayName)
end

local spongeIndexById = {}
for i, v in ipairs(SpongeConfig.Sponges) do
    spongeIndexById[v.Id] = i
end

local soapRollConnection = Bridges.SoapRoll:Connect(function(data)
    local plot = getPlot()
    if plot and type(data) == "table" and typeof(data.Booth) == "Instance" 
        and data.Booth:IsDescendantOf(plot) and type(data.Tier) == "number" then
        lastRolledSoapTier = data.Tier
    end
end)

pcall(function()
    for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
        pcall(function() connection:Disable() end)
    end
end)

UserInputService.InputBegan:Connect(function()
    antiAfkData.lastInput = tick()
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Gamepad1 then
        antiAfkData.lastInput = tick()
    end
end)

local function getPlot()
    local plotName = LocalPlayer:GetAttribute("Plot")
    if plotName then
        local plot = workspace.Map.Plots:FindFirstChild(plotName)
        if plot then return plot end
    end
    for _, plot in ipairs(workspace.Map.Plots:GetChildren()) do
        if plot:GetAttribute("Owner") == LocalPlayer.UserId then
            return plot
        end
    end
    return nil
end

local function getMoney()
    return LocalPlayer:GetAttribute("Money") or 0
end

local function getPlacementSpot(plot)
    local placement = plot:FindFirstChild("Placement")
    local references = placement and placement:FindFirstChild("PositionReference")
    local target, targetOrder = nil, math.huge
    
    if references then
        for _, tier in ipairs(references:GetChildren()) do
            if tier:GetAttribute("Unlocked") then
                for _, spot in ipairs(tier:GetChildren()) do
                    local order = spot:GetAttribute("FillOrder") or math.huge
                    if spot:IsA("BasePart") and not spot:GetAttribute(CONFIG.OccupiedAttr) and order < targetOrder then
                        target = spot
                        targetOrder = order
                    end
                end
            end
        end
    end
    return target
end

local function antiAfkTap()
    local camera = workspace.CurrentCamera
    if not camera then return end
    VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
    task.wait(0.1)
    VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
    antiAfkData.lastTap = tick()
end

local function washKeycaps()
    local plot = getPlot()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local carried = character and character:FindFirstChild(CONFIG.CarryToolName)
        or LocalPlayer.Backpack:FindFirstChild(CONFIG.CarryToolName)
    
    if plot and root and not carried then
        for _, cap in ipairs(CollectionService:GetTagged(CONFIG.CleanableTag)) do
            if cap:IsA("BasePart") and cap:IsDescendantOf(plot) then
                if cap:GetAttribute(CONFIG.CleanerAttr) ~= LocalPlayer.UserId then
                    root.CFrame = cap.CFrame * CFrame.new(0, 0, 4)
                    task.wait(0.2)
                    pcall(function()
                        Bridges.CleanSession:Fire({ Action = "Begin", Cap = cap })
                    end)
                else
                    pcall(function()
                        Bridges.CleanSession:Fire({ Action = "Scrub" })
                    end)
                end
                break
            end
        end
    end
end

local function placeKeycaps()
    local plot = getPlot()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local tool = character and character:FindFirstChild(CONFIG.CarryToolName)
        or LocalPlayer.Backpack:FindFirstChild(CONFIG.CarryToolName)
    local spot = plot and getPlacementSpot(plot)
    
    if tool and humanoid and root and spot then
        if tool.Parent ~= character then
            humanoid:EquipTool(tool)
            task.wait(0.1)
        end
        root.CFrame = spot.CFrame * CFrame.new(0, 3, 3)
        task.wait(0.2)
        pcall(function()
            tool:Activate()
        end)
        task.wait(PlacementConfig.PlaceDebounce)
    end
end

local function washAndPlace()
    local plot = getPlot()
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local carried = character and character:FindFirstChild(CONFIG.CarryToolName)
        or LocalPlayer.Backpack:FindFirstChild(CONFIG.CarryToolName)
    
    if carried then
        placeKeycaps()
        return
    end
    
    washKeycaps()
end

local function rollSoap()
    local plot = getPlot()
    local booth = plot and plot:FindFirstChild("Booths") and plot.Booths:FindFirstChild(CONFIG.SoapBoothFolder)
    
    if booth then
        local button = booth:FindFirstChild(SoapConfig.Booth.ButtonName)
        local press = button and button:FindFirstChild(SoapConfig.Booth.PressName)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        
        if press and root and firetouchinterest then
            pcall(function()
                firetouchinterest(root, press, 0)
                task.wait(0.05)
                firetouchinterest(root, press, 1)
            end)
        end
    end
end

local function dunkSponge()
    local plot = getPlot()
    local booth = plot and plot:FindFirstChild("Booths") and plot.Booths:FindFirstChild(CONFIG.SoapBoothFolder)
    local charges = LocalPlayer:GetAttribute(SoapConfig.Dunk.ChargesAttr) or 0
    local loaded = LocalPlayer:GetAttribute(SoapConfig.Dunk.LoadedAttr) or 0
    local remaining = booth and booth:GetAttribute(SoapConfig.Dunk.RemainAttr)
    local available = booth and not booth:GetAttribute(SoapConfig.Dunk.EmptyAttr)
        and type(remaining) == "number" and remaining > 0
    
    if (charges <= 0 or loaded <= 0) and available then
        local reference = booth:FindFirstChild(SoapConfig.Booth.ReferenceName)
        local proximity = reference and reference:FindFirstChild(SoapConfig.Dunk.PromptPartName)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        
        if proximity and root then
            root.CFrame = proximity.CFrame * CFrame.new(0, 0, 4)
            task.wait(0.2)
        end
        pcall(function()
            Bridges.SoapDunk:Fire({ Booth = booth })
        end)
    end
end

local function stopCollectMovement()
    if collectTween then
        pcall(function()
            collectTween:Cancel()
        end)
        collectTween = nil
    end
    if collectConnection then
        pcall(function()
            collectConnection:Disconnect()
        end)
        collectConnection = nil
    end
end

local function collectMoney()
    local plot = getPlot()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    
    if plot and humanoid and root then
        local footOffset = humanoid.HipHeight + root.Size.Y * 0.5
        for _, cap in ipairs(CollectionService:GetTagged(CONFIG.PlacedTag)) do
            if not running.autoCollect then
                stopCollectMovement()
                return
            end
            if cap:IsA("BasePart") and cap:IsDescendantOf(plot) then
                stopCollectMovement()
                root.CFrame = CFrame.new(cap.Position + Vector3.new(0, footOffset, 0)) * root.CFrame.Rotation
                task.wait(0.1)
            end
        end
        if running.autoCollect then
            root.CFrame += Vector3.new(0, IncomeConfig.FootBoxSize.Y + 1, 0)
        end
    end
end

local function hireWorkers()
    local workers = LocalPlayer:GetAttribute(WorkerConfig.WorkersAttr) or 0
    local maxWorkers = LocalPlayer:GetAttribute(WorkerConfig.MaxWorkersAttr) or 0
    
    if maxWorkers > workers then
        local cost = WorkerConfig.Prices[workers + 1] or WorkerConfig.BaseCost * WorkerConfig.CostGrowth ^ workers
        if getMoney() >= cost then
            pcall(function()
                Bridges.Worker:Fire({ Action = "Buy" })
            end)
        end
    end
end

local function autoBirth()
    local rebirths = LocalPlayer:GetAttribute(RebirthConfig.RebirthsAttr) or 0
    
    if rebirths < RebirthConfig.MaxRebirths then
        local have = LocalPlayer:GetAttribute(RebirthConfig.MoneyAttr) or getMoney()
        local need = RebirthConfig.Requirements[rebirths + 1] or math.huge
        
        if have >= need then
            pcall(function()
                Bridges.Rebirth:Fire({})
            end)
        end
    end
end

local function buyUpgrades()
    for _, id in ipairs({"Speed", "Radius", "Soap", "Worker"}) do
        local cfg = UpgradeConfig.Upgrades[id]
        if cfg then
            local level = LocalPlayer:GetAttribute(cfg.Attr) or 0
            if level < cfg.MaxLevel then
                local cost = cfg.Prices and cfg.Prices[level + 1] or cfg.BaseCost * cfg.CostGrowth ^ level
                if getMoney() >= cost then
                    pcall(function()
                        Bridges.Upgrade:Fire({ Action = "Buy", Id = id })
                    end)
                end
            end
        end
    end
end

local function buySponges()
    local equipped = LocalPlayer:GetAttribute(CONFIG.EquippedSpongeAttr)
    local equippedIndex = spongeIndexById[equipped] or 1
    local rebirths = LocalPlayer:GetAttribute(RebirthConfig.RebirthsAttr) or 0
    local target = nil
    
    for i = #SpongeConfig.Sponges, equippedIndex + 1, -1 do
        local sponge = SpongeConfig.Sponges[i]
        local affordable = not sponge.RobuxOnly and (sponge.CashPrice or 0) > 0
            and getMoney() >= sponge.CashPrice and (sponge.MinRebirth or 0) <= rebirths
        
        if affordable then
            target = sponge
            break
        end
    end
    
    if target and (os.clock() - (lastSpongeBuy[target.Id] or 0)) > 3 then
        lastSpongeBuy[target.Id] = os.clock()
        pcall(function()
            Bridges.Sponge:Fire({ Action = "Buy", Id = target.Id })
        end)
        task.wait(0.3)
        pcall(function()
            Bridges.Sponge:Fire({ Action = "Equip", Id = target.Id })
        end)
    end
end

local function antiAFK()
    local idle = tick() - antiAfkData.lastInput
    local sinceTap = tick() - antiAfkData.lastTap
    
    if idle >= 60 and sinceTap >= 60 then
        pcall(antiAfkTap)
    end
end

local function loop(name, fn, wait_time)
    if loops[name] then return end
    loops[name] = true
    task.spawn(function()
        while loops[name] do
            pcall(fn)
            task.wait(wait_time or 0.1)
        end
        loops[name] = nil
    end)
end

local function stop(name)
    loops[name] = false
end

loop("antiAfk", antiAFK, 2)

local ui = lib:CreateWindow("AntiGodHub")

local function createToggle(text, key, fn, waitTime)
    ui:AddToggle({
        text = text,
        state = false,
        callback = function(s)
            running[key] = s
            if s then 
                loop(key, fn, waitTime) 
            else 
                stop(key)
                if key == "autoCollect" then
                    stopCollectMovement()
                end
            end
        end
    })
end

createToggle("Wash & Place Keycaps", "autoWashPlace", washAndPlace, 0.01)
createToggle("Auto Roll Soap", "autoRoll", rollSoap, 1)
createToggle("Buy Sponge", "autoSponges", buySponges, 1)
createToggle("Dunk Sponge", "autoDunk", dunkSponge, 1)
createToggle("Collect Cash", "autoCollect", collectMoney, 1)
createToggle("Buy Workers", "autoWorkers", hireWorkers, 1)
createToggle("Auto Upgrade", "autoUpgrades", buyUpgrades, 0.5)
createToggle("Auto Rebirth", "autoRebirth", autoBirth, 1)

lib:Init()