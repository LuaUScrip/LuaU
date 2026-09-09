local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local WallhopRemotes = ReplicatedStorage:WaitForChild("WallhopRemotes")

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

local function getWorld()
	local world = LocalPlayer:GetAttribute("World")
	if world then return world end
	local ok, val = pcall(function()
		local w = LocalPlayer:FindFirstChild("World")
		return w and w:IsA("ValueBase") and w.Value or nil
	end)
	return ok and val or nil
end

local function getWorldPad(worldNum)
	if worldNum == 1 then
		local ok, result = pcall(function()
			return Workspace.World1.Map.Obby.Stage15.StageCheckpoint.NormalPad.Part
		end)
		return ok and result or nil
	elseif worldNum == 2 then
		local ok, result = pcall(function()
			return Workspace.World2.Map.Obby.Stage15.StageCheckpoint.NormalPad.Part
		end)
		return ok and result or nil
	end
	return nil
end

local function touchPad(pad)
	local hrp = getHRP()
	if not pad or not hrp then return end
	pcall(function()
		firetouchinterest(hrp, pad, 0)
		RunService.RenderStepped:Wait(0.1)
		firetouchinterest(hrp, pad, 1)
	end)
end

local function doFarmWins()
	local world = getWorld()
	if world then
		local pad = getWorldPad(world)
		if pad then touchPad(pad) end
	end
end

local function doRebirth()
	WallhopRemotes:WaitForChild("RebirthRequest"):FireServer()
end

local function csvContains(csv, name)
	for word in string.gmatch(csv or "", "[^,]+") do
		if word == name then return true end
	end
	return false
end

local function getAvailableNames(folder)
	local names = {}
	if not folder then return names end
	for _, child in ipairs(folder:GetChildren()) do
		names[#names + 1] = child.Name
	end
	return names
end

local function doBuyAndEquipBestAura()
	local folder = Workspace:FindFirstChild("World1") and Workspace.World1:FindFirstChild("AuraImages")
	local names = getAvailableNames(folder)
	local owned = LocalPlayer:GetAttribute("OwnedAuras") or ""
	local equipped = LocalPlayer:GetAttribute("EquippedAura") or ""

	local firstUnowned = nil
	local bestOwned = nil
	for i = #names, 1, -1 do
		if csvContains(owned, names[i]) then
			if not bestOwned then bestOwned = names[i] end
		else
			firstUnowned = names[i]
		end
	end

	if firstUnowned then
		pcall(function() WallhopRemotes:WaitForChild("AuraBuy"):FireServer(firstUnowned) end)
		task.wait(1)
		owned = LocalPlayer:GetAttribute("OwnedAuras") or ""
		for i = #names, 1, -1 do
			if csvContains(owned, names[i]) then
				bestOwned = names[i]
				break
			end
		end
	end

	if bestOwned and bestOwned ~= equipped then
		pcall(function() WallhopRemotes:WaitForChild("AuraEquip"):FireServer(bestOwned) end)
	end
end

local function doBuyAndEquipBestTrail()
	local folder = Workspace:FindFirstChild("World1") and Workspace.World1:FindFirstChild("Trails")
	local names = getAvailableNames(folder)
	local owned = LocalPlayer:GetAttribute("OwnedTrails") or ""
	local equipped = LocalPlayer:GetAttribute("EquippedTrail") or ""

	local firstUnowned = nil
	local bestOwned = nil
	for i = #names, 1, -1 do
		if csvContains(owned, names[i]) then
			if not bestOwned then bestOwned = names[i] end
		else
			firstUnowned = names[i]
		end
	end

	if firstUnowned then
		pcall(function() WallhopRemotes:WaitForChild("TrailBuy"):FireServer(firstUnowned) end)
		task.wait(1)
		owned = LocalPlayer:GetAttribute("OwnedTrails") or ""
		for i = #names, 1, -1 do
			if csvContains(owned, names[i]) then
				bestOwned = names[i]
				break
			end
		end
	end

	if bestOwned and bestOwned ~= equipped then
		pcall(function() WallhopRemotes:WaitForChild("TrailEquip"):FireServer(bestOwned) end)
	end
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

task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
			local frame = gui and gui:FindFirstChild("DisconnectedFrame")
			if frame and frame.Visible then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
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
		if s then loop("farmWins", doFarmWins, 0.1) else stop("farmWins") end
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
	text = "Buy Aura",
	state = false,
	callback = function(s)
		running.buyEquipAura = s
		if s then loop("buyEquipAura", doBuyAndEquipBestAura, 0.1) else stop("buyEquipAura") end
	end,
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.buyEquipTrail = s
		if s then loop("buyEquipTrail", doBuyAndEquipBestTrail, 0.1) else stop("buyEquipTrail") end
	end,
})

lib:Init()