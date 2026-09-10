local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = Packages:WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

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

local Worlds = {
	[90740816183375] = { pos = CFrame.new(395, 17, -8593), touch = { "Stage12", "EscapeBreach" } },
	[107335165302681] = { pos = CFrame.new(0, 61, -9013), touch = { "World2", "Stage12", "EscapeBreach" } },
	[83261190895443] = { pos = CFrame.new(186, 475, -12453), touch = { "Stage12", "Breach", "EscapeBreach" } },
	[131722594546368] = { pos = CFrame.new(-184, -2670, -36932), touch = { "Stage12", "Finale", "EscapeBreach" } },
	[124014751199823] = { pos = CFrame.new(0, 243, -29042), touch = { "Stage12", "Play", "EscapeBreach" } },
}

local currentWorld = nil
local function detectWorld()
	currentWorld = Worlds[game.PlaceId] or nil
	return currentWorld
end

detectWorld()

local function getTouchPart(world)
	if not world then return nil end
	local ok, part = pcall(function()
		local obj = Workspace
		for _, name in ipairs(world.touch) do
			obj = obj:WaitForChild(name, 5)
			if not obj then return nil end
		end
		return obj
	end)
	return ok and part or nil
end

local function doFarmWins()
	if not currentWorld then currentWorld = detectWorld() end
	if not currentWorld then return end
	local hrp = getHRP()
	if not hrp then return end
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	hrp.CFrame = currentWorld.pos
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	local part = getTouchPart(currentWorld)
	if part then
		pcall(function()
			firetouchinterest(hrp, part, 0)
			task.wait(0.05)
			firetouchinterest(hrp, part, 1)
		end)
	end
end

local function doRebirth()
	Net:WaitForChild("RE/Rebirth/Request"):FireServer()
end

local boughtTrails = {}
local function doBuyTrail()
	for _, name in ipairs({ "Green", "Orange", "Blue", "Purple", "Rainbow", "Admin" }) do
		if not boughtTrails[name] then
			boughtTrails[name] = true
			pcall(function() Net:WaitForChild("RE/Trails/BuyViaWins"):FireServer(name) end)
		end
		task.wait(0.3)
	end
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	pcall(function() fireproximityprompt(prompt) end)
end)

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

task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
			local frame = gui and gui:FindFirstChild("DisconnectedFrame")
			if frame and frame.Visible then
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
	end
end)

local ui = lib:CreateWindow("AntiGodHub")

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
		if s then loop("rebirth", doRebirth, 1) else stop("rebirth") end
	end,
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.buyTrail = s
		if s then boughtTrails = {} end
		if s then loop("buyTrail", doBuyTrail, 0.1) else stop("buyTrail") end
	end,
})

lib:Init()