local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClientState = require(ReplicatedStorage:WaitForChild("ClientState"))

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

local function getWinCFrame()
	local id = game.PlaceId
	if id == 135039703249004 then
		return CFrame.new(-499.937134, 582.330933, 7579.62256, 0, 0, -1, 0, 1, 0, 1, 0, 0)
	elseif id == 102674673429018 then
		return CFrame.new(-509.266724, 172.690475, 464.342407, -1, 0, 0, 0, 1, 0, 0, 0, -1)
	end
end

local function loadAuraConfig()
	local ok, data = pcall(function()
		return require(ReplicatedStorage:WaitForChild("FeatureConfigs"):WaitForChild("AuraConfig"))
	end)
	if ok and data and data.AURAS then
		local items = {}
		for key, aura in pairs(data.AURAS) do
			if aura.available ~= false and aura.price and aura.price > 0 then
				items[#items + 1] = { key = key, name = aura.name or key, multiplier = aura.multiplier or 1, price = aura.price }
			end
		end
		table.sort(items, function(a, b) return a.multiplier < b.multiplier end)
		return items
	end
	return {}
end

local function loadTrailConfig()
	local ok, data = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Config"))
	end)
	if ok and data and data.TRAILS then
		local items = {}
		for name, trail in pairs(data.TRAILS) do
			if trail.Wins and trail.Wins > 0 then
				items[#items + 1] = { name = name, multiplier = trail.Multiplier or 1, wins = trail.Wins }
			end
		end
		table.sort(items, function(a, b) return a.multiplier < b.multiplier end)
		return items
	end
	return {}
end

local function loadItemsConfig()
	local ok, data = pcall(function()
		return require(ReplicatedStorage:WaitForChild("FeatureConfigs"):WaitForChild("Items"))
	end)
	if ok and data and data.ITEMS then
		local rarityOrder = { Exotic = 0, Secret = 1, Mythic = 2, Legendary = 3, Epic = 4, Rare = 5, Uncommon = 6, Common = 7 }
		local items = {}
		for key, item in pairs(data.ITEMS) do
			if item.shopExcluded ~= true then
				items[#items + 1] = { key = key, name = item.name or key, multiplier = item.multiplier or 0, rarity = item.rarity or "Common" }
			end
		end
		table.sort(items, function(a, b)
			if a.multiplier ~= b.multiplier then return a.multiplier > b.multiplier end
			return (rarityOrder[a.rarity] or 7) < (rarityOrder[b.rarity] or 7)
		end)
		return items
	end
	return {}
end

local function doFarmWins()
	local hrp = getHRP()
	if not hrp then return end
	hrp.CFrame = getWinCFrame()
	hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

local function doTrain()
	pcall(function()
		Remotes:WaitForChild("UpdateSpeed"):FireServer("Walking")
		task.wait(0.01)
		Remotes:WaitForChild("UpdateSpeed"):FireServer("Treadmill")
	end)
end

local function doRebirth()
	pcall(function() Remotes:WaitForChild("Rebirth"):FireServer() end)
end

local function doBuyAndEquipBestAura()
	local data = loadAuraConfig()
	if #data == 0 then return end
	local state = ClientState:Get()
	local owned = state.OwnedAuras or {}
	local equipped = state.EquippedAura or "None"
	local ownedSet = {}
	for _, name in ipairs(owned) do ownedSet[name] = true end
	local firstUnowned = nil
	local bestOwned = nil
	local bestMult = 0
	for i = #data, 1, -1 do
		local item = data[i]
		if ownedSet[item.key] then
			if item.multiplier > bestMult then
				bestMult = item.multiplier
				bestOwned = item.key
			end
		else
			if not firstUnowned then firstUnowned = item.key end
		end
	end
	if firstUnowned then
		pcall(function() Remotes:WaitForChild("BuyAura"):InvokeServer(firstUnowned, "Wins") end)
		task.wait(1)
		state = ClientState:Get()
		owned = state.OwnedAuras or {}
		ownedSet = {}
		for _, name in ipairs(owned) do ownedSet[name] = true end
		for i = #data, 1, -1 do
			if ownedSet[data[i].key] then
				if data[i].multiplier > bestMult then
					bestMult = data[i].multiplier
					bestOwned = data[i].key
				end
			end
		end
	end
	if bestOwned and bestOwned ~= equipped then
		pcall(function() Remotes:WaitForChild("EquipAura"):FireServer(bestOwned) end)
	end
end

local function doBuyAndEquipBestTrail()
	local data = loadTrailConfig()
	if #data == 0 then return end
	local state = ClientState:Get()
	local owned = state.OwnedTrails or {}
	local equipped = state.EquippedTrail or "None"
	local ownedSet = {}
	for _, name in ipairs(owned) do ownedSet[name] = true end
	local firstUnowned = nil
	local bestOwned = nil
	local bestMult = 0
	for i = #data, 1, -1 do
		local item = data[i]
		if ownedSet[item.name] then
			if item.multiplier > bestMult then
				bestMult = item.multiplier
				bestOwned = item.name
			end
		else
			if not firstUnowned then firstUnowned = item.name end
		end
	end
	if firstUnowned then
		pcall(function() Remotes:WaitForChild("BuyTrail"):InvokeServer(firstUnowned, "Wins") end)
		task.wait(1)
		state = ClientState:Get()
		owned = state.OwnedTrails or {}
		ownedSet = {}
		for _, name in ipairs(owned) do ownedSet[name] = true end
		for i = #data, 1, -1 do
			if ownedSet[data[i].name] then
				if data[i].multiplier > bestMult then
					bestMult = data[i].multiplier
					bestOwned = data[i].name
				end
			end
		end
	end
	if bestOwned and bestOwned ~= equipped then
		pcall(function() Remotes:WaitForChild("EquipTrail"):FireServer(bestOwned) end)
	end
end

local function doBuyBestItems()
	for _, rarity in ipairs({"Rare", "Mysterious"}) do
		pcall(function() Remotes:WaitForChild("ItemsShopAction"):FireServer("BuyWins", rarity) end)
		task.wait(0.3)
	end
end

local function doEquipBestItems()
	pcall(function() Remotes:WaitForChild("ItemAction"):FireServer("EquipBest") end)
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

ui:AddToggle({
	text = "Farm Wins",
	state = false,
	callback = function(s)
		running.farmWins = s
		if s then loop("farmWins", doFarmWins, 1) else stop("farmWins") end
	end,
})

ui:AddToggle({
	text = "Fast Train",
	state = false,
	callback = function(s)
		running.train = s
		if s then loop("train", doTrain, 0.00001) else stop("train") end
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
		running.buyAura = s
		if s then loop("buyAura", doBuyAndEquipBestAura, 0.1) else stop("buyAura") end
	end,
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.buyTrail = s
		if s then loop("buyTrail", doBuyAndEquipBestTrail, 0.1) else stop("buyTrail") end
	end,
})

ui:AddToggle({
	text = "Buy Best Items",
	state = false,
	callback = function(s)
		running.buyItems = s
		if s then loop("buyItems", doBuyBestItems, 0.1) else stop("buyItems") end
	end,
})

ui:AddToggle({
	text = "Equip Best Items",
	state = false,
	callback = function(s)
		running.equipItems = s
		if s then loop("equipItems", doEquipBestItems, 0.5) else stop("equipItems") end
	end,
})

lib:Init()