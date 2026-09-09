local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

local running = {
	AutoSpikeBall = false,
	AutoRebirth = false,
	InstantChallenge = false,
	AutoSpinWheel = false,
	AutoUpgrade = false,
	AutoUsePotion = false,
	FreeRainbowPack = false,
	AutoBuyBall = false,
	AutoBuyTrail = false,
}

local loops = {}

local function loop(name, fn, wait_time)
	if loops[name] then return end
	loops[name] = true
	task.spawn(function()
		while loops[name] and running[name] do
			pcall(fn)
			task.wait(wait_time or 0.1)
		end
	end)
end

local function stop(name)
	loops[name] = false
end

local EggEvents = ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("EggRemoteEvents")
local BuyBall = ReplicatedStorage:WaitForChild("BuyBallRemote")
local BuyTrail = ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("BuyTrailRemote")
local TreadmillReward = ReplicatedStorage:WaitForChild("TreadmillClaimReward")
local SpinRemote = ReplicatedStorage:WaitForChild("SpinRemote")
local UpgradeRemote = ReplicatedStorage:WaitForChild("UpgradeRemote")

local function ReadModuleKeys(path)
	local keys = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild(path)
		if mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				for k, v in pairs(data) do
					if type(k) == "string" and type(v) == "table" then
						table.insert(keys, k)
					end
				end
			end
		end
	end)
	table.sort(keys)
	return keys
end

local function AutoSpikeBallLogic()
	pcall(function()
		EggEvents:WaitForChild("KickBall"):FireServer(math.huge)
	end)
end

local function AutoRebirthLogic()
	pcall(function()
		EggEvents:WaitForChild("DoRebirth"):InvokeServer()
	end)
end

local function InstantChallengeLogic()
	pcall(function()
		EggEvents:WaitForChild("SpikeChallengeRemote"):FireServer("LeaveChallenge", true)
	end)
end

local function AutoSpinWheelLogic()
	pcall(function()
		SpinRemote:InvokeServer()
	end)
end

local function AutoUpgradeLogic()
	pcall(function() UpgradeRemote:FireServer("A") end)
	pcall(function() UpgradeRemote:FireServer("B") end)
	pcall(function() UpgradeRemote:FireServer("C") end)
end

local function AutoUsePotionLogic()
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("Power") end)
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("Money") end)
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("PetLuck") end)
end

local function FreeRainbowPackLogic()
	pcall(function() TreadmillReward:FireServer(11) end)
	pcall(function() TreadmillReward:FireServer(12) end)
	pcall(function() TreadmillReward:FireServer(10) end)
	pcall(function() TreadmillReward:FireServer(5) end)
end

local function AutoBuyBallLogic()
	local ballNames = ReadModuleKeys("BallData")
	for _, name in ipairs(ballNames) do
		pcall(function() BuyBall:FireServer(name) end)
		task.wait(0.1)
	end
end

local function AutoBuyTrailLogic()
	local trailNames = ReadModuleKeys("TrailData")
	for _, name in ipairs(trailNames) do
		pcall(function() BuyTrail:FireServer(name) end)
		task.wait(0.1)
	end
end

local function GetBestBallLogic()
	pcall(function()
		BuyBall:FireServer("Lightning")
	end)
end

local function AntiAFKLogic()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end

task.spawn(function()
	while true do
		pcall(AntiAFKLogic)
		task.wait(600)
	end
end)

Players.LocalPlayer.Idled:Connect(function()
	AntiAFKLogic()
end)

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
	text = "Auto Spike Ball",
	state = false,
	callback = function(s)
		running.AutoSpikeBall = s
		if s then loop("AutoSpikeBall", AutoSpikeBallLogic, 0.5) else stop("AutoSpikeBall") end
	end
})

ui:AddToggle({
	text = "Auto Rebirth",
	state = false,
	callback = function(s)
		running.AutoRebirth = s
		if s then loop("AutoRebirth", AutoRebirthLogic, 0.1) else stop("AutoRebirth") end
	end
})

ui:AddToggle({
	text = "Instant Challenge",
	state = false,
	callback = function(s)
		running.InstantChallenge = s
		if s then loop("InstantChallenge", InstantChallengeLogic, 1) else stop("InstantChallenge") end
	end
})

ui:AddToggle({
	text = "Auto Spin Wheel",
	state = false,
	callback = function(s)
		running.AutoSpinWheel = s
		if s then loop("AutoSpinWheel", AutoSpinWheelLogic, 0.001) else stop("AutoSpinWheel") end
	end
})

ui:AddToggle({
	text = "Auto Upgrade",
	state = false,
	callback = function(s)
		running.AutoUpgrade = s
		if s then loop("AutoUpgrade", AutoUpgradeLogic, 0.1) else stop("AutoUpgrade") end
	end
})

ui:AddToggle({
	text = "Auto Use Potion",
	state = false,
	callback = function(s)
		running.AutoUsePotion = s
		if s then loop("AutoUsePotion", AutoUsePotionLogic, 0.1) else stop("AutoUsePotion") end
	end
})

ui:AddToggle({
	text = "Free Rainbow Pack",
	state = false,
	callback = function(s)
		running.FreeRainbowPack = s
		if s then loop("FreeRainbowPack", FreeRainbowPackLogic, 0.0001) else stop("FreeRainbowPack") end
	end
})

ui:AddToggle({
	text = "Auto Buy Ball",
	state = false,
	callback = function(s)
		running.AutoBuyBall = s
		if s then loop("AutoBuyBall", AutoBuyBallLogic, 0.5) else stop("AutoBuyBall") end
	end
})

ui:AddToggle({
	text = "Auto Buy Trail",
	state = false,
	callback = function(s)
		running.AutoBuyTrail = s
		if s then loop("AutoBuyTrail", AutoBuyTrailLogic, 0.5) else stop("AutoBuyTrail") end
	end
})

ui:AddButton({
	text = "Get Best Ball",
	callback = function()
		GetBestBallLogic()
	end
})

lib:Init()