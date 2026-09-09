local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")

local running = {}
local loops = {}

local function loop(name, fn, wait_time)
	if loops[name] then return end
	loops[name] = true
	task.spawn(function()
		while loops[name] and running[name] do
			pcall(fn)
			task.wait(wait_time or 0.01)
		end
	end)
end

local function stop(name)
	loops[name] = false
end

local function getHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local WinButtons = {
	["W1"] = "Button14",
	["W2"] = "Button13",
	["W3"] = "Button13",
}

local selectedWorld = "W1"

local function getTouchPart()
	local buttonName = WinButtons[selectedWorld]
	if not buttonName then return nil end
	local giveWins = Workspace:FindFirstChild("GiveWins")
	local button = giveWins and giveWins:FindFirstChild(buttonName)
	return button and button:FindFirstChild("Touch")
end

local function doFarmWins()
	local hrp = getHRP()
	if not hrp then return end
	local touch = getTouchPart()
	if not touch then return end
	hrp.CFrame = touch.CFrame + Vector3.new(0, 3, 0)
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

local function doRebirth()
	Events:WaitForChild("RequestRebirth"):InvokeServer()
end

local TrailList = {
	"GreenTrail", "BlueTrail", "PurpleTrail", "RedTrail", "RainbowTrail",
	"GalaxyTrail", "CosmicTrail", "VoidTrail", "SupernovaTrail", "GodlyTrail", "InfinityTrail",
	"Tidal", "Energy",
}

local function doBuyTrail()
	for _, trail in ipairs(TrailList) do
		pcall(function() Events:WaitForChild("TrailAction"):FireServer("BuyWins", trail) end)
		task.wait(0.3)
	end
end

local function doEquipBestPet()
	Events:WaitForChild("InventoryAction"):InvokeServer("EquipBest")
end

LocalPlayer.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

task.spawn(function()
	while true do
		pcall(function()
			if LocalPlayer.GameplayPaused then
				LocalPlayer.GameplayPaused = false
			end
		end)
		task.wait()
	end
end)

local ui = lib:CreateWindow("AntiGodHub")

ui:AddList({
	text = "Select World",
	values = { "W1", "W2", "W3" },
	value = "W1",
	callback = function(v)
		selectedWorld = v
	end,
})

ui:AddToggle({
	text = "Farm Wins",
	state = false,
	callback = function(s)
		running.farmWins = s
		if s then loop("farmWins", doFarmWins, 1) else stop("farmWins") end
	end,
})

ui:AddToggle({
	text = "Auto Rebirth",
	state = false,
	callback = function(s)
		running.rebirth = s
		if s then loop("rebirth", doRebirth, 0.5) else stop("rebirth") end
	end,
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.buyTrail = s
		if s then loop("buyTrail", doBuyTrail, 1) else stop("buyTrail") end
	end,
})

ui:AddToggle({
	text = "Equip Best Pet",
	state = false,
	callback = function(s)
		running.equipPet = s
		if s then loop("equipPet", doEquipBestPet, 1) else stop("equipPet") end
	end,
})

lib:Init()