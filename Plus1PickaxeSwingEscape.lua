local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua",
    true
))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

local S = {
    wins = false,
    train = false,
    event = false,
    rebirth = false,
    trails = false,
    aa = false,
    equipBest = false,
    hatch = false,
}
local threads = {}

local function spawnThread(key, runner)
    if threads[key] then return end
    threads[key] = task.spawn(function()
        runner()
        threads[key] = nil
    end)
end

local function getHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local function teleport(pos)
    local hrp = getHRP()
    local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Sit = false end
    hrp.CFrame = CFrame.new(pos)
end

local function attr(name)
    return LocalPlayer:GetAttribute(name)
end

local function firePrompt(prompt)
    if type(fireproximityprompt) == "function" then
        return pcall(fireproximityprompt, prompt)
    end
    prompt:InputHoldBegin()
    task.wait(0.15)
    prompt:InputHoldEnd()
    return true
end

local WINS = {
    [1] = { pos = Vector3.new(1207, 5, 184), pad = function()
        return workspace.Worlds.World1.DefaultWinPads.DefaultWin11.Floor
    end },
    [2] = { pos = Vector3.new(1471, 5, 514), pad = function()
        return workspace.Worlds.World2.DefaultWinPads.DefaultWin.Floor
    end },
    [3] = { pos = Vector3.new(1769, 5, 871), pad = function()
        return workspace.Worlds.World3.DefaultWinPads:GetChildren()[7].Floor
    end },
    [4] = { pos = Vector3.new(1769, 5, 1244), pad = function()
        return workspace.Worlds.World4.DefaultWinPads:GetChildren()[4].Floor
    end },
    [5] = { pos = Vector3.new(1769, 5, 2842), pad = function()
        return workspace.Worlds.World5.DefaultWinPads:GetChildren()[4].Floor
    end },
    [6] = { pos = Vector3.new(1769, 5, 4946), pad = function()
        return workspace.Worlds.World6.DefaultWinPads:GetChildren()[9].Floor
    end },
}

local function winsLoop()
    while S.wins do
        local win = WINS[attr("CurrentWorld")]
        if win then
            teleport(win.pos)
            task.wait(0.2)
            local ok, pad = pcall(win.pad)
            if ok and pad then
                teleport(pad.Position)
            end
            task.wait(0.3)
        end
        task.wait(0.1)
    end
end

local TRAIN = {
    [1] = {
        { req = 0, pos = Vector3.new(-55, 6, 237),  hitbox = function() return workspace.Dummy.Starter.Hitbox end },
        { req = 1, pos = Vector3.new(-55, 6, 227),  hitbox = function() return workspace.Dummy.OneRebirth.Hitbox end },
        { req = 3, pos = Vector3.new(-55, 6, 213),  hitbox = function() return workspace.Dummy.ThreeRebirths.Hitbox end },
    },
    [2] = {
        { req = 0, pos = Vector3.new(-55, 6, 565),  hitbox = function() return workspace.Dummy2.Starter.Hitbox end },
        { req = 5, pos = Vector3.new(-55, 6, 555),  hitbox = function() return workspace.Dummy2.OneRebirth.Hitbox end },
        { req = 7, pos = Vector3.new(-55, 6, 540),  hitbox = function() return workspace.Dummy2.ThreeRebirths.Hitbox end },
    },
    [3] = {
        { req = 0,  pos = Vector3.new(-55, 6, 922),  hitbox = function() return workspace.Dummy3.Starter.Hitbox end },
        { req = 12, pos = Vector3.new(-55, 6, 910), hitbox = function() return workspace.Dummy3.OneRebirth.Hitbox end },
        { req = 18, pos = Vector3.new(-55, 6, 897), hitbox = function() return workspace.Dummy3.ThreeRebirths.Hitbox end },
    },
    [4] = {
        { req = 0,  pos = Vector3.new(-55, 6, 1295), hitbox = function() return workspace.Dummy4.Starter.Hitbox end },
        { req = 16, pos = Vector3.new(-55, 6, 1284), hitbox = function() return workspace.Dummy4.OneRebirth.Hitbox end },
        { req = 22, pos = Vector3.new(-55, 6, 1271), hitbox = function() return workspace.Dummy4.ThreeRebirths.Hitbox end },
    },
    [5] = {
        { req = 0,  pos = Vector3.new(-55, 6, 2893), hitbox = function() return workspace.Dummy5.Starter.Hitbox end },
        { req = 20, pos = Vector3.new(-55, 6, 2882), hitbox = function() return workspace.Dummy5.OneRebirth.Hitbox end },
        { req = 26, pos = Vector3.new(-55, 6, 2869), hitbox = function() return workspace.Dummy5.ThreeRebirths.Hitbox end },
    },
    [6] = {
        { req = 0,  pos = Vector3.new(-56, 5, 4997), hitbox = function() return workspace.Dummy6.Starter.Hitbox end },
        { req = 24, pos = Vector3.new(-56, 5, 4986), hitbox = function() return workspace.Dummy6.OneRebirth.Hitbox end },
        { req = 30, pos = Vector3.new(-56, 5, 4973), hitbox = function() return workspace.Dummy6.ThreeRebirths.Hitbox end },
    },
}

local function trainLoop()
    while S.train do
        local world = attr("CurrentWorld")
        local rebirths = attr("Rebirths") or 0
        local list = TRAIN[world]
        if not list then
            task.wait(0.5)
        else
            local target
            for _, t in ipairs(list) do
                if rebirths >= t.req then target = t end
            end
            if not target then
                task.wait(0.5)
            else
                local ok, hitbox = pcall(target.hitbox)
                if ok and hitbox then
                    local lastTeleport = 0
                    while S.train
                        and attr("CurrentWorld") == world
                        and (attr("Rebirths") or 0) == rebirths
                    do
                        local now = os.clock()
                        if now - lastTeleport >= 1 then
                            teleport(target.pos)
                            lastTeleport = now
                        end
                        pcall(function()
                            Remotes.DamageBlock:InvokeServer(hitbox)
                        end)
                        task.wait(0.01)
                    end
                else
                    task.wait(0.5)
                end
            end
        end
    end
end

local EVENT_POS = Vector3.new(15, 6, 2063)

local function eventLoop()
    pcall(function()
        Remotes.SetWorld:FireServer(0)
    end)
    teleport(EVENT_POS)
    task.wait(0.5)
    local lastTeleport = 0
    while S.event do
        local now = os.clock()
        if now - lastTeleport >= 1 then
            teleport(EVENT_POS)
            lastTeleport = now
        end
        pcall(function()
            Remotes.DamageBlock:InvokeServer(workspace.LuckyEventWorld.EventLuckyBlock, false)
        end)
        task.wait(0.001)
    end
end

local function rebirthLoop()
    while S.rebirth do
        pcall(function()
            Remotes.Rebirth:InvokeServer()
        end)
        task.wait(1)
    end
end

local TRAILS = { "Orange", "Green", "Blue", "Purple", "White", "Black", "Rainbow", "Lava", "Inferno" }

local function trailsLoop()
    while S.trails do
        for _, color in ipairs(TRAILS) do
            if not S.trails then return end
            pcall(function()
                Remotes.BuyTrail:FireServer(color)
            end)
            task.wait(0.05)
            pcall(function()
                Remotes.EquipTrail:FireServer(color)
            end)
            task.wait(0.05)
        end
        task.wait(1)
    end
end

local function aaLoop()
    while S.aa do
        local reroll = workspace:FindFirstChild("LuckyReroll")
        if reroll then
            local ok, cf = pcall(function()
                return reroll:GetBoundingBox()
            end)
            if ok then
                teleport(cf.Position + Vector3.new(0, 5, 0))
                task.wait(0.3)
            end
        end
        local nests = workspace.Game.Map.PlayZones.Cosmic.Nests:GetChildren()
        local nest = nests[6]
        local prompt = nest and nest:FindFirstChild("Root")
            and nest.Root:FindFirstChild("ProximityPrompt")
        if prompt then
            firePrompt(prompt)
        end
        task.wait(1)
    end
end

local function hatchLoop()
    while S.hatch do
        pcall(function()
            Remotes.Hatch:InvokeServer(Library.flags["Egg"], "One")
        end)
        task.wait(1)
    end
end

local hub = Library:CreateWindow("AntiGodHub")

local function addAuto(win, key, text, runner)
    win:AddToggle({
        text = text,
        callback = function(state)
            S[key] = state
            if state then
                spawnThread(key, runner)
            end
        end,
    })
end

addAuto(hub, "wins", "Auto Wins", winsLoop)
addAuto(hub, "train", "Auto Train", trainLoop)
addAuto(hub, "event", "Auto Event", eventLoop)
addAuto(hub, "rebirth", "Auto Rebirth", rebirthLoop)
addAuto(hub, "trails", "Auto Buy Trail", trailsLoop)
addAuto(hub, "aa", "Auto Collect AA", aaLoop)

local eggs = Library:CreateWindow("Eggs")

eggs:AddList({
    text = "Select Egg",
    values = { "Lucky Egg", "Void Egg", "Azure Egg", "Lucky Event Egg" },
    value = "Lucky Egg",
    flag = "Egg",
})

addAuto(eggs, "hatch", "Hatch Egg", hatchLoop)

eggs:AddToggle({
    text = "Equip Best Pets",
    callback = function(state)
        S.equipBest = state
        if state then
            pcall(function()
                Remotes.PetEquipBest:FireServer()
            end)
        end
    end,
})

task.spawn(function()
    while task.wait(1) do
        if S.equipBest then
            pcall(function()
                Remotes.PetEquipBest:FireServer()
            end)
        end
    end
end)

Library:Init()