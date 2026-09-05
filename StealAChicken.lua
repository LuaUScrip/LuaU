local library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua",
    true
))()

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/stealaeggspeedbypass.lua"))()
end)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local HOME_CFRAME = CFrame.new(-34, 33, -298)
local ZONES = {"Forest", "Lake", "Jungle", "Desert", "Snow", "Volcano", "Beach", "Abyss", "Cosmic", "Crystal"}

local selectedZone = "Forest"
local farming = false
local stopped = false
local loopRunning = false

local ARRIVE_WAIT = 0.4
local PROMPT_FIRE_WAIT = 0.5
local HOME_ARRIVE_WAIT = 0.2
local HOME_STAY_WAIT = 1.5
local EGG_LOOP_WAIT = 1.0

local PRIORITY_RARITIES = {"InsaneEgg"}

local upgradeState = {
    upgradePen = false,
    collectHatch = false,
    upgradeTreadmill = false,
    sellEgg = false,
    sellChicken = false,
    autoBuyTrail = false,
    equipBestPets = false,
}

local trailList = {"blue", "purple", "red", "galaxy", "aquatic", "divine", "rainbow"}

local function getRemoteEvent(path)
    return ReplicatedStorage.packages._Index["littensy_remo@1.5.3"].remo.container[path]
end

local function upgradePen()
    pcall(function()
        local Event = getRemoteEvent("data.base.upgradeBase")
        Event:FireServer()
    end)
end

local function collectHatch()
    pcall(function()
        local Event = getRemoteEvent("data.base.claimAllEggs")
        Event:FireServer()
    end)
end

local function upgradeTreadmill()
    pcall(function()
        local Event = getRemoteEvent("data.upgrades.upgrade")
        Event:FireServer("treadmill", 1)
    end)
end

local function sellAllEggs()
    pcall(function()
        local Event = getRemoteEvent("data.backpack.sellAllItems")
        Event:FireServer("egg")
    end)
end

local function sellAllChickens()
    pcall(function()
        local Event = getRemoteEvent("data.backpack.sellAllItems")
        Event:FireServer("chicken")
    end)
end

local function buyTrail(trailName)
    pcall(function()
        local Event = getRemoteEvent("data.trailShop.buyTrail")
        Event:FireServer(trailName)
    end)
end

local function buyAllTrails()
    for _, trail in ipairs(trailList) do
        buyTrail(trail)
        task.wait(1)
    end
end

local function equipBestPets()
    pcall(function()
        local Event = getRemoteEvent("data.base.equipBestChickens")
        Event:FireServer()
    end)
end

local function getHRP()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        task.wait(0.5)
        return getHRP()
    end
    return hrp
end

local function getHumanoid()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function zeroVelocity(part)
    if not part then return end
    part.AssemblyLinearVelocity = Vector3.zero
    part.AssemblyAngularVelocity = Vector3.zero
end

local function burstPivot(cf, fires)
    local r = getHRP()
    if not r or not cf then return end
    fires = fires or 2
    for _ = 1, fires do
        r.CFrame = cf
        zeroVelocity(r)
        task.wait(0.014)
    end
end

local function smoothPath(goal, steps, firesPerStep)
    local r = getHRP()
    if not r or not goal then return false end
    steps = steps or 16
    firesPerStep = firesPerStep or 2
    local from = r.Position
    for i = 1, steps do
        if stopped then return false end
        r = getHRP()
        if not r then return false end
        local p = from:Lerp(goal, i / steps)
        burstPivot(CFrame.new(p.X, math.max(p.Y, r.Position.Y), p.Z), firesPerStep)
    end
    return true
end

local function fastTp(cf)
    burstPivot(cf, 3)
    return true
end

local function travelTo(goal)
    local r = getHRP()
    if not r then return false end
    if (r.Position - goal).Magnitude > 8 then
        smoothPath(goal, 18, 2)
    end
    burstPivot(CFrame.new(goal), 2)
    return true
end

local function walkRunTo(goal, speed, timeout)
    local h = getHumanoid()
    if not h or not goal then return false end
    speed = math.min(speed or 16, 16)
    timeout = timeout or 45
    local saved = h.WalkSpeed
    h.WalkSpeed = speed
    h:MoveTo(goal)
    local t0 = os.clock()
    while os.clock() - t0 < timeout and not stopped do
        local r = getHRP()
        if not r then break end
        local dist = (goal - r.Position).Magnitude
        if dist <= 4.5 then
            h.WalkSpeed = saved
            h:Move(Vector3.zero, false)
            return true
        end
        local flat = Vector3.new(goal.X - r.Position.X, 0, goal.Z - r.Position.Z)
        if flat.Magnitude > 0.3 then
            h:Move(flat.Unit, false)
        end
        task.wait(0.15)
    end
    h.WalkSpeed = saved
    h:Move(Vector3.zero, false)
    local r = getHRP()
    return r and (r.Position - goal).Magnitude <= 10
end

local function firePromptInstant(prompt)
    if not prompt then return false end
    return pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
            return true
        elseif fireprompt then
            fireprompt(prompt)
            return true
        elseif fire then
            fire(prompt)
            return true
        else
            prompt:InputHoldBegin()
            task.wait(0.2)
            prompt:InputHoldEnd()
            return true
        end
    end)
end

local function getZone(name)
    local game_ = Workspace:FindFirstChild("Game")
    if not game_ then return nil end
    local map = game_:FindFirstChild("Map")
    if not map then return nil end
    local playZones = map:FindFirstChild("PlayZones")
    if not playZones then return nil end
    return playZones:FindFirstChild(name)
end

local function getNests(zone)
    if not zone then return {} end
    local nests = zone:FindFirstChild("Nests")
    if not nests then return {} end
    local list = {}
    for _, child in ipairs(nests:GetChildren()) do
        table.insert(list, child)
    end
    return list
end

local function getPrompt(nest)
    if not nest then return nil end
    return nest:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function hasChicken(nest)
    if not nest then return false end
    return nest:FindFirstChild("Chicken") ~= nil
end

local function isPriorityRarity(nestName)
    if not nestName then return false end
    for _, priority in ipairs(PRIORITY_RARITIES) do
        if string.find(nestName:lower(), priority:lower()) then
            return true
        end
    end
    return false
end

local function getEggs(nest)
    if not nest then return {} end
    local prompt = getPrompt(nest)
    local rootPart = prompt and prompt.Parent

    local function blocked(inst)
        if prompt and (inst == prompt or inst:IsAncestorOf(prompt)) then
            return true
        end
        if rootPart and (inst == rootPart or inst:IsDescendantOf(rootPart)) then
            return true
        end
        return false
    end

    local models = {}
    for _, inst in ipairs(nest:GetDescendants()) do
        if not blocked(inst) and inst:IsA("Model") and inst:FindFirstChildWhichIsA("BasePart", true) then
            table.insert(models, inst)
        end
    end

    local eggs = {}
    for _, m in ipairs(models) do
        local container = false
        for _, other in ipairs(models) do
            if other ~= m and other:IsDescendantOf(m) then
                container = true
                break
            end
        end
        if not container then
            table.insert(eggs, m)
        end
    end

    for _, inst in ipairs(nest:GetDescendants()) do
        if not blocked(inst) and inst:IsA("BasePart") then
            local am = inst:FindFirstAncestorOfClass("Model")
            if not am or not table.find(eggs, am) then
                if not table.find(eggs, inst) then
                    table.insert(eggs, inst)
                end
            end
        end
    end

    return eggs
end

local function goHome()
    travelTo(HOME_CFRAME.Position)
    task.wait(HOME_ARRIVE_WAIT)
end

local function getEggPosition(egg)
    if not egg then return nil end
    if egg:IsA("BasePart") then
        return egg.CFrame.Position
    else
        local part = egg:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame.Position
        end
    end
    return nil
end

local function collectEgg(egg, nestOrFolder)
    if stopped or not egg or not nestOrFolder then return false end
    if not egg.Parent then return false end
    local eggPos = getEggPosition(egg)
    if not eggPos then return false end
    
    if not travelTo(eggPos + Vector3.new(0, 1, 0)) then
        return false
    end
    
    if stopped then return false end
    task.wait(ARRIVE_WAIT)
    if stopped then return false end
    
    local prompt = getPrompt(nestOrFolder)
    if prompt then
        firePromptInstant(prompt)
        task.wait(PROMPT_FIRE_WAIT)
    end
    
    if stopped then return false end
    goHome()
    if stopped then return false end
    task.wait(HOME_STAY_WAIT)
    
    return true
end

local function farmCycle()
    if stopped then return end
    local zone = getZone(selectedZone)
    if not zone then return end
    
    local nests = getNests(zone)
    if #nests == 0 then return end
    
    local priorityFolders = {}
    local regularNests = {}
    
    for _, nest in ipairs(nests) do
        if stopped then return end
        if isPriorityRarity(nest.Name) then
            table.insert(priorityFolders, nest)
        else
            table.insert(regularNests, nest)
        end
    end
    
    for _, folder in ipairs(priorityFolders) do
        if stopped then return end
        if hasChicken(folder) then
            local eggs = getEggs(folder)
            if #eggs > 0 then
                for _, egg in ipairs(eggs) do
                    if stopped then return end
                    if egg and egg.Parent then
                        collectEgg(egg, folder)
                        if stopped then return end
                        task.wait(EGG_LOOP_WAIT)
                    end
                end
            end
        end
    end
    
    for _, nest in ipairs(regularNests) do
        if stopped then return end
        if not hasChicken(nest) then continue end
        local prompt = getPrompt(nest)
        if not prompt then continue end
        local eggs = getEggs(nest)
        if #eggs == 0 then continue end
        
        for _, egg in ipairs(eggs) do
            if stopped then return end
            if egg and egg.Parent then
                collectEgg(egg, nest)
                if stopped then return end
                task.wait(EGG_LOOP_WAIT)
            end
        end
    end
end

local function farmLoop()
    loopRunning = true
    while farming and not stopped do
        pcall(farmCycle)
        task.wait(0.5)
    end
    loopRunning = false
end

local function upgradeLoop()
    while upgradeState.upgradePen do
        upgradePen()
        task.wait(0.5)
    end
    while upgradeState.collectHatch do
        collectHatch()
        task.wait(0.5)
    end
    while upgradeState.upgradeTreadmill do
        upgradeTreadmill()
        task.wait(0.5)
    end
    while upgradeState.sellEgg do
        sellAllEggs()
        task.wait(0.5)
    end
    while upgradeState.sellChicken do
        sellAllChickens()
        task.wait(0.5)
    end
    while upgradeState.autoBuyTrail do
        buyAllTrails()
        task.wait(1)
    end
    while upgradeState.equipBestPets do
        equipBestPets()
        task.wait(0.5)
    end
end

local win1 = library:CreateWindow("AntiGodHub")

win1:AddToggle({
    text = "Upgrade Pen",
    state = false,
    callback = function(state)
        upgradeState.upgradePen = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Collect Hatch",
    state = false,
    callback = function(state)
        upgradeState.collectHatch = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Upgrade Treadmill",
    state = false,
    callback = function(state)
        upgradeState.upgradeTreadmill = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Sell Egg",
    state = false,
    callback = function(state)
        upgradeState.sellEgg = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Sell Chicken",
    state = false,
    callback = function(state)
        upgradeState.sellChicken = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Auto Buy Trail",
    state = false,
    callback = function(state)
        upgradeState.autoBuyTrail = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

win1:AddToggle({
    text = "Equip Best Pets",
    state = false,
    callback = function(state)
        upgradeState.equipBestPets = state
        if state then
            task.spawn(upgradeLoop)
        end
    end
})

local win2 = library:CreateWindow("Farming")

win2:AddList({
    text = "Select Zone",
    values = ZONES,
    value = "Forest",
    callback = function(v)
        selectedZone = v
    end
})

win2:AddToggle({
    text = "Collect Egg",
    state = false,
    callback = function(state)
        farming = state
        if state then
            stopped = false
            task.spawn(farmLoop)
        else
            stopped = true
            task.spawn(function()
                while loopRunning do
                    task.wait(0.1)
                end
                goHome()
            end)
        end
    end
})

win2:AddButton({
    text = "Collect Once",
    callback = function()
        stopped = false
        task.spawn(function()
            pcall(farmCycle)
        end)
    end
})

win2:AddButton({
    text = "Go Home",
    callback = function()
        stopped = false
        goHome()
    end
})

library:Init()