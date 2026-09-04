local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua",
    true
))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("SharedModules")
    :WaitForChild("Network"):WaitForChild("Remotes")

local HOME = CFrame.new(-134, 4, 255)
local PACE = 0.05 -- seconds between each numbered remote call

-- toggle states
local S = {
    collect = false,
    open = false,
    upgrade = false,
    rebirth = false,
    floors = false,
    board = false,
    brainrot = false
}
local threads = {}

local function spawnThread(key, runner)
    if threads[key] then return end
    threads[key] = task.spawn(function()
        runner()
        threads[key] = nil
    end)
end

-- ===== runners: fire one at a time, stop when toggled off =====
-- Collect Cash / Open Lucky Block / Upgrade Brainrots send "1", "2" ... (strings)
local function collectLoop()
    local i = 1
    while S.collect do
        Remotes["Collect Earnings"]:FireServer(tostring(i))
        i = i == 70 and 1 or i + 1
        task.wait(PACE)
    end
end

local function openLoop()
    local i = 1
    while S.open do
        Remotes["Open Lucky Block"]:FireServer(tostring(i))
        i = i == 70 and 1 or i + 1
        task.wait(PACE)
    end
end

local function brainrotLoop()
    local i = 1
    while S.brainrot do
        Remotes["Upgrade Friend"]:FireServer(tostring(i))
        i = i == 70 and 1 or i + 1
        task.wait(PACE)
    end
end

local function upgradeLoop()
    while S.upgrade do
        Remotes["Upgrade Speed 5"]:FireServer()
        task.wait(0.05)
        if not S.upgrade then return end
        Remotes["Upgrade Boost"]:FireServer()
        task.wait(0.05)
        if not S.upgrade then return end
        Remotes["Upgrade Carry Limit"]:FireServer()
        task.wait(1)
    end
end

local function rebirthLoop()
    while S.rebirth do
        Remotes.Rebirth:FireServer()
        task.wait(1)
    end
end

-- Upgrade Floors: plain numbers 1..70 via InvokeServer
local function floorsLoop()
    local i = 1
    while S.floors do
        pcall(function()
            Remotes["Purchase Floor"]:InvokeServer(i)
        end)
        i = i == 70 and 1 or i + 1
        task.wait(PACE)
    end
end

-- Buy Board: plain numbers 2..19
local function boardLoop()
    local i = 2
    while S.board do
        Remotes["Buy Board Upgrade"]:FireServer(i)
        i = i == 19 and 2 or i + 1
        task.wait(PACE)
    end
end

-- ===== Window 1: AntiGodHub (all toggles, run only while on) =====
local hub = Library:CreateWindow("AntiGodHub")

local function addAuto(key, text, runner)
    hub:AddToggle({
        text = text,
        callback = function(state)
            S[key] = state
            if state then
                spawnThread(key, runner) -- starts at 1 and counts up
            end
        end
    })
end

addAuto("collect", "Auto Collect Cash", collectLoop)
addAuto("open", "Auto Open Lucky Block", openLoop)
addAuto("upgrade", "Auto Upgrade All", upgradeLoop)
addAuto("rebirth", "Auto Rebirth", rebirthLoop)
addAuto("floors", "Auto Upgrade Floors", floorsLoop)
addAuto("board", "Auto Buy Board", boardLoop)
addAuto("brainrot", "Auto Upgrade Brainrots", brainrotLoop)

-- ===== Window 2: Farming =====
local function getHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local function teleportHome()
    local hrp = getHRP()
    local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Sit = false end
    hrp.CFrame = HOME
end

local function getLuckyBlock(name)
    local live = workspace:FindFirstChild("Live")
    local friends = live and live:FindFirstChild("Friends")
    return friends and friends:FindFirstChild(name)
end

local function stealBlock(name)
    local block = getLuckyBlock(name)
    if not block then
        warn("Lucky block not found: " .. tostring(name))
        return false
    end
    local root = block:FindFirstChild("RootPart") or block:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local prompt = root:FindFirstChild("StealPrompt")
    if not prompt then return false end

    local hrp = getHRP()
    local humanoid = hrp.Parent:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.Sit = false end
    local height = root.Size.Y > 0 and root.Size.Y or 8
    local standCF = CFrame.new(root.Position.X, root.Position.Y + height / 2 + 2, root.Position.Z)
    hrp.CFrame = standCF
    task.wait(0.4) -- settle on top of the block

    if type(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt) -- instant fire
    else
        hrp.CFrame = standCF -- keep in range while holding
        prompt:InputHoldBegin()
        task.wait(0.15)
        prompt:InputHoldEnd()
    end

    task.wait(0.5)
    teleportHome() -- back home (-134, 4, 255)
    return true
end

local autoSteal = false
local stealThread

local farming = Library:CreateWindow("Farming")

farming:AddList({
    text = "Lucky Block",
    values = {
        "Brainrot God Lucky Block",
        "OG Lucky Block",
        "Divine Lucky Block",
        "Transcendent Lucky Block"
    },
    value = "Brainrot God Lucky Block",
    flag = "LuckyBlock"
})

farming:AddButton({
    text = "Collect",
    callback = function()
        if not stealBlock(Library.flags["LuckyBlock"]) then
            teleportHome()
        end
    end
})

farming:AddToggle({
    text = "Collect Lucky Block",
    callback = function(state)
        autoSteal = state
        if state and not stealThread then
            stealThread = task.spawn(function()
                while autoSteal do
                    local ok = stealBlock(Library.flags["LuckyBlock"])
                    task.wait(1) -- stay home before going back to the block
                    if not ok then
                        task.wait(1) -- block gone: wait before retrying
                    end
                end
                stealThread = nil
            end)
        end
    end
})

Library:Init()