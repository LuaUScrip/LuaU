local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")

local FIXED_POSITION = Vector3.new(-1162.8552246094, 0.72600001096725, 73.239318847656)
local coinLandedCount = 0
local BASIC_COIN = "Basic Coin"

-- Wait for game to load
task.wait(0.1)

local Events = rs:WaitForChild("Assets"):WaitForChild("Events")
local CoinThrowEvent = Events:WaitForChild("CoinThrow")
local CoinLandedEvent = Events:WaitForChild("CoinLanded")
local BuyCoinEvent = Events:WaitForChild("BuyCoin")
local SellAllEvent = Events:WaitForChild("SellAll")
local RequestUpgradeEvent = Events:WaitForChild("RequestUpgrade")
local SyncCoinsEvent = Events:WaitForChild("SyncCoins")
local LuckChangedEvent = Events:WaitForChild("LuckChanged")

local ProgressionModule = require(rs:WaitForChild("Assets"):WaitForChild("Modules"):WaitForChild("ProgressionModule"))
local AllCoinsData = ProgressionModule.Coins or {}

local running = {
    autoThrow = false,
    autoBuy = false,
    autoUpgradeAll = false,
    autoSellAll = false,
    fastThrow = false,
    vip = false,
    boost = false,
}

local loops = {}
local ownedCoins = {}
local equippedCoin = nil
local equippedCoinData = nil
local firstThrowDone = false

-- Fix: Properly connect SyncCoins event
if SyncCoinsEvent then
    SyncCoinsEvent.OnClientEvent:Connect(function(coinsList)
        if coinsList and type(coinsList) == "table" then
            ownedCoins = {}
            for _, coinName in ipairs(coinsList) do
                ownedCoins[coinName] = true
            end
        end
    end)
end

-- Fix: Use .Event correctly for LuckChanged
LuckChangedEvent.Event:Connect(function(_, coinName)
    if coinName then
        equippedCoin = coinName
        equippedCoinData = AllCoinsData[coinName]
        firstThrowDone = true
    end
end)

local function loop(name, fn, wait_time)
    if loops[name] then return end
    loops[name] = true
    task.spawn(function()
        while loops[name] and running[name] do
            local success, err = pcall(fn)
            if not success then
                warn("Loop error in " .. name .. ": " .. tostring(err))
            end
            task.wait(wait_time or 0.15)
        end
    end)
end

local function stop(name)
    loops[name] = false
end

local function autoThrowCoin()
    if not firstThrowDone then
        local success = pcall(function()
            CoinThrowEvent:FireServer(BASIC_COIN, FIXED_POSITION, FIXED_POSITION)
            task.wait(0.2)
            coinLandedCount = coinLandedCount + 1
            CoinLandedEvent:FireServer(999, FIXED_POSITION, BASIC_COIN, FIXED_POSITION, BASIC_COIN, coinLandedCount)
        end)
        if success then
            firstThrowDone = true
        end
        task.wait(0.5)
        return
    end
    
    if not equippedCoin then 
        -- Try to get equipped coin from attributes
        local equippedAttr = LP:GetAttribute("EquippedCoin") or LP:GetAttribute("SelectedCoin")
        if equippedAttr then
            equippedCoin = equippedAttr
            equippedCoinData = AllCoinsData[equippedCoin]
        else
            return 
        end
    end
    
    pcall(function()
        CoinThrowEvent:FireServer(equippedCoin, FIXED_POSITION, FIXED_POSITION)
        task.wait(0.1)
        coinLandedCount = coinLandedCount + 1
        CoinLandedEvent:FireServer(999, FIXED_POSITION, equippedCoin, FIXED_POSITION, equippedCoin, coinLandedCount)
    end)
end

local function autoBuyCoin()
    if not AllCoinsData then return end
    
    pcall(function()
        for coinName, coinData in pairs(AllCoinsData) do
            if not running.autoBuy then break end
            if ownedCoins[coinName] then continue end
            
            local cost = coinData.Cost
            if not cost or type(cost) ~= "number" then 
                -- Try to convert if it's a string
                cost = tonumber(cost)
                if not cost then continue end
            end
            
            -- Skip if we don't have enough money (optional check)
            local playerMoney = LP:GetAttribute("Money") or LP:GetAttribute("Cash") or 0
            if playerMoney < cost then continue end
            
            BuyCoinEvent:FireServer(coinName)
            task.wait(0.2)
        end
    end)
end

local function autoUpgradeAll()
    local UpgradeList = {"Luck Multiplier", "Value Multiplier", "Throw Speed"}
    pcall(function()
        for _, upgrade in ipairs(UpgradeList) do
            if not running.autoUpgradeAll then break end
            RequestUpgradeEvent:FireServer(upgrade)
            task.wait(0.1)
        end
    end)
end

local function autoSellAll()
    pcall(function()
        SellAllEvent:FireServer()
    end)
end

local function setFastThrow(value)
    pcall(function()
        LP:SetAttribute("ThrowSpeedLevel", value and 1000 or 0)
    end)
end

local function setVIP(value)
    pcall(function()
        LP:SetAttribute("VIP", value)
    end)
end

local function setBoost(value)
    pcall(function()
        LP:SetAttribute("MoreLuck", value)
        LP:SetAttribute("IsMod", value)
        LP:SetAttribute("IsAdmin", value)
        LP:SetAttribute("InsaneLuck", value)
        LP:SetAttribute("DynamicCoinOwned", value)
        LP:SetAttribute("DragonBooth", value)
        LP:SetAttribute("BetterPlacement", value)
        LP:SetAttribute("CC", value)
        LP:SetAttribute("DoubleCash", value)
    end)
end

-- Anti-AFK
task.spawn(function()
    while task.wait(60) do
        pcall(function()
            VirtualUser:ClickButton2(Vector2.new())
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new())
        end)
    end
end)

-- Create UI
local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
    text = "Throw Coin",
    state = false,
    callback = function(s)
        running.autoThrow = s
        if s then
            firstThrowDone = false
            loop("autoThrow", autoThrowCoin, 0.15)
        else
            stop("autoThrow")
        end
    end
})

ui:AddToggle({
    text = "Sell All",
    state = false,
    callback = function(s)
        running.autoSellAll = s
        if s then
            loop("autoSellAll", autoSellAll, 0.5)
        else
            stop("autoSellAll")
        end
    end
})

ui:AddToggle({
    text = "Upgrade All",
    state = false,
    callback = function(s)
        running.autoUpgradeAll = s
        if s then
            loop("autoUpgradeAll", autoUpgradeAll, 0.1)
        else
            stop("autoUpgradeAll")
        end
    end
})

ui:AddToggle({
    text = "Auto Buy Coin",
    state = false,
    callback = function(s)
        running.autoBuy = s
        if s then
            loop("autoBuy", autoBuyCoin, 0.15)
        else
            stop("autoBuy")
        end
    end
})

ui:AddToggle({
    text = "Fast Throw",
    state = false,
    callback = function(s)
        running.fastThrow = s
        setFastThrow(s)
    end
})

ui:AddToggle({
    text = "VIP",
    state = false,
    callback = function(s)
        running.vip = s
        setVIP(s)
    end
})

ui:AddToggle({
    text = "Boost",
    state = false,
    callback = function(s)
        running.boost = s
        setBoost(s)
    end
})

-- Initialize the library
lib:Init()