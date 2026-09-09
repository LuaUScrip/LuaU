local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

local running = {
	AutoWins = false,
	AutoTrainFast = false,
	AutoRebirth = false,
	AutoBuyTrails = false,
	AutoBuyAura = false,
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

local WorldData = {
	[1] = {
		CFrame = CFrame.new(13139.7939, 253.489624, 702.684814),
		HitboxPath = function()
			return pcall(function() return Workspace.StageWinPaths.Normal["13"].Hitbox end) and Workspace.StageWinPaths.Normal["13"].Hitbox or nil
		end,
	},
	[2] = {
		CFrame = CFrame.new(16173.8682, 319.496918, -10047.9756),
		HitboxPath = function()
			return pcall(function() return Workspace.StageWinPaths_W2.Normal["13"].Hitbox end) and Workspace.StageWinPaths_W2.Normal["13"].Hitbox or nil
		end,
	},
	[3] = {
		CFrame = CFrame.new(20375.6406, 317.497925, -16982.5254, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		HitboxPath = function()
			return pcall(function() return Workspace.StageWinPaths_W3.Normal["13"].Hitbox end) and Workspace.StageWinPaths_W3.Normal["13"].Hitbox or nil
		end,
	},
	[4] = {
		CFrame = CFrame.new(24800.5, 315.0, -22500.0),
		HitboxPath = function()
			return pcall(function() return Workspace.StageWinPaths_W4.Normal["13"].Hitbox end) and Workspace.StageWinPaths_W4.Normal["13"].Hitbox or nil
		end,
	},
	[5] = {
		CFrame = CFrame.new(29500.0, 312.0, -28500.0),
		HitboxPath = function()
			return pcall(function() return Workspace.StageWinPaths_W5.Normal["13"].Hitbox end) and Workspace.StageWinPaths_W5.Normal["13"].Hitbox or nil
		end,
	},
}

local function DetectWorld()
	local ok, val = pcall(function() return Player:GetAttribute("World") end)
	if ok and type(val) == "number" then return math.floor(val) end
	local obj = Player:FindFirstChild("World")
	if obj and obj:IsA("ValueBase") and type(obj.Value) == "number" then return math.floor(obj.Value) end
	return 1
end

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local JumpXpEvent = Remotes:WaitForChild("JumpXpEvent")
local RebirthButtonEvent = Remotes:WaitForChild("RebirthButtonEvent")
local TrailEquipRequest = Remotes:WaitForChild("TrailEquipRequest")
local AuraEquipRequest = Remotes:WaitForChild("AuraEquipRequest")

local TrailsList = {}
local AurasList = {
	"RedAura", "GreenAura", "BlueAura", "RainbowAura",
	"GalaxyAura", "DivineAura", "FairyAura", "SpectralAura",
	"YinYangAura", "BloodmoonAura", "SakuraAura", "FlashAura"
}

local OwnedAuras = {}
local EquippedAura = "none"

local function LoadTrails()
	pcall(function()
		local TrailsController = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("TrailsController"))
		TrailsList = {}
	end)
	if #TrailsList == 0 then
		TrailsList = {
			"RedTrail", "BlueTrail", "GreenTrail", "PurpleTrail",
			"OrangeTrail", "YellowTrail", "VoidTrail", "RainbowTrail",
			"CandyTrail", "MintTrail", "GalaxyTrail", "DivineTrail",
			"FairyTrail", "SpectralTrail", "YinYangTrail", "BloodmoonTrail",
			"SakuraTrail", "FlashTrail"
		}
	end
end

local autoWinsLoopRunning = false

local function AutoWinsLogic()
	if not HumanoidRootPart or not HumanoidRootPart.Parent then return end

	pcall(function()
		local world = DetectWorld()
		local data = WorldData[world]
		if not data then return end

		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		HumanoidRootPart.CFrame = data.CFrame
		task.wait(0.03)

		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		local hitbox = data.HitboxPath()
		if not hitbox then return end

		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					firetouchinterest(part, hitbox, 0)
					task.wait(0.03)
					firetouchinterest(part, hitbox, 1)
				end)
			end
		end

		pcall(function()
			firetouchinterest(hitbox, HumanoidRootPart, 0)
			task.wait(0.03)
			firetouchinterest(hitbox, HumanoidRootPart, 1)
		end)
	end)
end

local function StartAutoWinsLoop()
	if autoWinsLoopRunning then return end
	autoWinsLoopRunning = true
	task.spawn(function()
		while autoWinsLoopRunning and running.AutoWins do
			AutoWinsLogic()
			task.wait(0.1)
		end
	end)
end

local function StopAutoWinsLoop()
	autoWinsLoopRunning = false
end

local function AutoTrainFastLogic()
	pcall(function()
		JumpXpEvent:FireServer()
	end)
end

local function AutoRebirthLogic()
	pcall(function()
		RebirthButtonEvent:FireServer()
	end)
end

local function AutoBuyTrailsLogic()
	pcall(function()
		for _, TrailName in ipairs(TrailsList) do
			TrailEquipRequest:FireServer(TrailName)
			task.wait(0.2)
		end
	end)
end

local function AutoBuyAuraLogic()
	pcall(function()
		local equippedIndex = 0
		for i, aura in ipairs(AurasList) do
			if aura == EquippedAura then
				equippedIndex = i
				break
			end
		end

		for i, aura in ipairs(AurasList) do
			if i >= equippedIndex and not table.find(OwnedAuras, aura) then
				AuraEquipRequest:FireServer(aura)
				task.wait(0.3)
			end
		end
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

pcall(function()
	local HiddenStats = Player:WaitForChild("HiddenStats", 10)
	if HiddenStats then
		local OwnedAurasValue = HiddenStats:FindFirstChild("OwnedAuras")
		if OwnedAurasValue then
			local function UpdateOwnedAuras(value)
				if value == "" then
					OwnedAuras = {}
				else
					local success, decoded = pcall(function()
						return HttpService:JSONDecode(value)
					end)
					OwnedAuras = (success and type(decoded) == "table") and decoded or {}
				end
			end
			UpdateOwnedAuras(OwnedAurasValue.Value)
			OwnedAurasValue.Changed:Connect(function(newValue)
				UpdateOwnedAuras(newValue)
			end)
		end

		local AuraIdValue = HiddenStats:FindFirstChild("AuraId")
		if AuraIdValue then
			EquippedAura = (AuraIdValue.Value == "" or not AuraIdValue.Value) and "none" or AuraIdValue.Value
			AuraIdValue.Changed:Connect(function(newValue)
				EquippedAura = (newValue == "" or not newValue) and "none" or newValue
			end)
		end
	end
end)

local ui = lib:CreateWindow("AntiGodHub")

LoadTrails()

ui:AddToggle({
	text = "Auto Wins",
	state = false,
	callback = function(s)
		running.AutoWins = s
		if s then StartAutoWinsLoop() else StopAutoWinsLoop() end
	end
})

ui:AddToggle({
	text = "Auto Train Fast",
	state = false,
	callback = function(s)
		running.AutoTrainFast = s
		if s then loop("AutoTrainFast", AutoTrainFastLogic, 0.01) else stop("AutoTrainFast") end
	end
})

ui:AddToggle({
	text = "Auto Rebirth",
	state = false,
	callback = function(s)
		running.AutoRebirth = s
		if s then loop("AutoRebirth", AutoRebirthLogic, 0.3) else stop("AutoRebirth") end
	end
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.AutoBuyTrails = s
		if s then loop("AutoBuyTrails", AutoBuyTrailsLogic, 0.2) else stop("AutoBuyTrails") end
	end
})

ui:AddToggle({
	text = "Buy Aura",
	state = false,
	callback = function(s)
		running.AutoBuyAura = s
		if s then loop("AutoBuyAura", AutoBuyAuraLogic, 0.2) else stop("AutoBuyAura") end
	end
})

lib:Init()