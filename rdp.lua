local Repo = "https://raw.githubusercontent.com/LuaUScrip/HUB/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local copyText = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request)

local CONFIG = {
	Title = "AntiGodHub",
	Icon = 80985370671515,
	Discord = "https://discord.gg/jdJvZm6VdK",
	Website = "https://rscripts.net/@AntiGodHub",
	Version = "v1.0",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Ride A Pet",
}

local previous = getgenv().UnitGrinder
if previous then
	previous.running = false
	if type(previous.lib) == "table" and type(previous.lib.Unload) == "function" then
		pcall(function()
			previous.lib:Unload()
		end)
	end
end

local session = {running = true, lib = Library}
getgenv().UnitGrinder = session

local enabled = {
	collect = false,
	plant = false,
	hatch = false,
	place = false,
	feed = false,
	foodBuy = false,
	gearBuy = false,
	rebirth = false,
	index = false,
	upgrade = false,
	esp = false,
	antiafk = false,
	noPause = false,
}

local config = {
	minRarity = 0,
	targetEgg = nil,
	priority = "Highest Rarity",
	flySpeed = 1500,
	plantRarity = 0,
	food = nil,
	foodBuy = nil,
	gearBuy = nil,
	espRarity = 0,
}

local state = {
	manual = {},
	cooldowns = {},
	lastPickup = 0,
	espEntries = {},
}

local sessionStart = tick()
local farmStatus = "idle"

local function find(root, ...)
	local node = root
	for index = 1, select("#", ...) do
		node = node and node:FindFirstChild((select(index, ...)))
	end
	return node
end

local remotesFolder = nil

local function getRemotesFolder()
	if remotesFolder and remotesFolder.Parent then
		return remotesFolder
	end
	local folder = find(ReplicatedStorage, "Remotes", "Game")
	if not folder then
		local ok, waited = pcall(function()
			return ReplicatedStorage:WaitForChild("Remotes", 5)
		end)
		if ok and waited then
			folder = waited:FindFirstChild("Game") or waited:WaitForChild("Game", 5)
		end
	end
	remotesFolder = folder
	return folder
end

local function fireRemote(name, ...)
	local folder = getRemotesFolder()
	if not folder then
		return false
	end
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		pcall(remote.FireServer, remote, ...)
		return true
	end
	return false
end

local function read(value)
	if value ~= nil then
		local ok, result = pcall(value)
		if ok then
			return result
		end
	end
end

local timers = {}
local function ready(key, interval)
	local now = tick()
	if now - (timers[key] or 0) < interval then
		return false
	end
	timers[key] = now
	return true
end

local SUFFIX_LIST = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"}
do
	local groups = {"Dc", "Vg", "Tg", "Qg", "Qq", "Sg", "Su", "Og", "Ng"}
	local prefixes = {"", "Un", "Du", "Tr", "Qd", "Qn", "Se", "St", "Ot", "Nn"}
	for _, group in ipairs(groups) do
		for _, prefix in ipairs(prefixes) do
			table.insert(SUFFIX_LIST, prefix .. group)
		end
	end
	table.insert(SUFFIX_LIST, "Ce")
end

local SUFFIX_EXPONENTS = {}
for index, suffix in ipairs(SUFFIX_LIST) do
	SUFFIX_EXPONENTS[string.lower(suffix)] = (index - 1) * 3
end

local function abbreviateNumber(value)
	value = tonumber(value) or 0
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local index = math.floor(math.log10(value) / 3)
	index = math.min(index, #SUFFIX_LIST - 1)
	local scaled = value / (1000 ^ index)
	local text = string.format("%.2f", scaled):gsub("%.?0+$", "")
	return text .. SUFFIX_LIST[index + 1]
end

local function formatDuration(seconds)
	seconds = math.floor(seconds)
	if seconds < 60 then
		return string.format("%ds", seconds)
	end
	return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
end

local StatusHoldUntil = 0

local function setFarmStatus(text)
	text = tostring(text or "idle")
	if text == "idle" then
		if tick() < StatusHoldUntil then
			return
		end
	else
		StatusHoldUntil = tick() + 2
	end
	farmStatus = text
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local RARITY_LIST = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}
local RARITY_RANK = {}
for index, name in ipairs(RARITY_LIST) do
	RARITY_RANK[name] = index
end

local RARITY_CHOICES = {"Any"}
for _, name in ipairs(RARITY_LIST) do
	table.insert(RARITY_CHOICES, name)
end

local RARITY_COLORS = {
	Common = Color3.fromRGB(214, 218, 228),
	Rare = Color3.fromRGB(96, 170, 255),
	Epic = Color3.fromRGB(190, 110, 255),
	Legendary = Color3.fromRGB(255, 196, 66),
	Mythic = Color3.fromRGB(255, 82, 90),
	Divine = Color3.fromRGB(255, 240, 150),
	Ethereal = Color3.fromRGB(125, 225, 255),
}

local SORT_MODES = {"Highest Luck", "Highest Rarity", "Nearest", "Farthest"}

local GameData = {}
do
	local names = {"Eggs", "Pets", "Foods", "Shop", "Rebirths", "EggBaskets", "Mutations"}
	for _, name in ipairs(names) do
		local ok, result = pcall(function()
			return require(find(ReplicatedStorage, "GameData", name))
		end)
		GameData[name] = ok and type(result) == "table" and result or nil
	end
end

local gameDataAt = {}

local function gameData(name)
	if GameData[name] then
		return GameData[name]
	end
	if tick() - (gameDataAt[name] or 0) < 5 then
		return nil
	end
	gameDataAt[name] = tick()
	local ok, result = pcall(function()
		return require(find(ReplicatedStorage, "GameData", name))
	end)
	if ok and type(result) == "table" then
		GameData[name] = result
	end
	return GameData[name]
end

local eggsFolder = nil

local function getActiveEggs()
	if eggsFolder and eggsFolder.Parent then
		return eggsFolder
	end
	local folder = find(ReplicatedStorage, "ServerData", "ActiveEggs")
	if not folder then
		local ok, waited = pcall(function()
			return ReplicatedStorage:WaitForChild("ServerData", 5)
		end)
		if ok and waited then
			folder = waited:FindFirstChild("ActiveEggs") or waited:WaitForChild("ActiveEggs", 5)
		end
	end
	eggsFolder = folder
	return folder
end

local EGG_CHOICES = {"Any"}
do
	local sorted = {}
	local eggsTable = gameData("Eggs")
	if type(eggsTable) == "table" then
		for name, entry in pairs(eggsTable) do
			if type(entry) == "table" then
				table.insert(sorted, {
					Name = name,
					Rank = RARITY_RANK[tostring(entry.Rarity)] or 0,
					Luck = tonumber(entry.Luck) or 0,
				})
			end
		end
	end
	table.sort(sorted, function(a, b)
		if a.Rank ~= b.Rank then
			return a.Rank > b.Rank
		end
		return a.Luck > b.Luck
	end)
	for _, entry in ipairs(sorted) do
		table.insert(EGG_CHOICES, entry.Name)
	end
end

local FOOD_CHOICES = {"Any"}
do
	local sorted = {}
	local foodsTable = gameData("Foods")
	if type(foodsTable) == "table" then
		for name, entry in pairs(foodsTable) do
			if type(entry) == "table" then
				table.insert(sorted, {Name = name, Cost = tonumber(entry.Cost) or 0})
			end
		end
	end
	table.sort(sorted, function(a, b)
		return a.Cost < b.Cost
	end)
	for _, entry in ipairs(sorted) do
		table.insert(FOOD_CHOICES, entry.Name)
	end
end

local GEAR_CHOICES = {"Any"}
do
	local shopData = gameData("Shop")
	local shopTable = type(shopData) == "table" and shopData.Gears or nil
	if type(shopTable) == "table" then
		local sorted = {}
		for name, entry in pairs(shopTable) do
			if type(entry) == "table" then
				table.insert(sorted, {Name = name, Price = tonumber(entry.Price) or 0})
			end
		end
		table.sort(sorted, function(a, b)
			return a.Price < b.Price
		end)
		for _, entry in ipairs(sorted) do
			table.insert(GEAR_CHOICES, entry.Name)
		end
	end
end

local function eggData(name)
	local table_ = gameData("Eggs")
	if type(table_) == "table" then
		local entry = table_[tostring(name)]
		if type(entry) == "table" then
			return entry
		end
	end
	return nil
end

local function eggRank(name)
	local entry = eggData(name)
	return entry and RARITY_RANK[tostring(entry.Rarity)] or 0
end

local function eggRarity(name)
	local entry = eggData(name)
	return entry and tostring(entry.Rarity) or "Common"
end

local function eggLuck(name)
	local entry = eggData(name)
	return entry and tonumber(entry.Luck) or 0
end

local function petData(name)
	local table_ = gameData("Pets")
	if type(table_) == "table" then
		local entry = table_[tostring(name)]
		if type(entry) == "table" then
			return entry
		end
	end
	return nil
end

local function mutationBonus(mutation)
	local table_ = gameData("Mutations")
	if type(table_) == "table" and mutation then
		local entry = table_[tostring(mutation)]
		if type(entry) == "table" then
			return 1 + (tonumber(entry.StatMultiplier) or 0) / 100
		end
	end
	return 1
end

local function petScore(name, weight, mutation)
	local entry = petData(name)
	return (entry and tonumber(entry.Income) or 1) * math.max(tonumber(weight) or 1, 0.1) * mutationBonus(mutation)
end

local function petNameOf(instance)
	local attribute = instance:GetAttribute("PetName")
	if type(attribute) == "string" and attribute ~= "" then
		return attribute
	end
	return string.gsub(instance.Name, "%s*%[.*$", "")
end

local function getSaved(name)
	local saved = find(LocalPlayer, "SavedData", name)
	return saved and saved.Value or nil
end

local function getCash()
	return tonumber(getSaved("Cash")) or 0
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function getRoot()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsDescendantOf(Workspace) then
		return root
	end
	return nil
end

local plotCache = nil

local function getPlot()
	if plotCache and plotCache.Parent then
		local owner = find(plotCache, "Data", "Owner")
		if owner and owner.Value == LocalPlayer then
			return plotCache
		end
	end
	plotCache = nil
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, child in ipairs(plots:GetChildren()) do
		local owner = find(child, "Data", "Owner")
		if owner and owner.Value == LocalPlayer then
			plotCache = child
			return child
		end
	end
	return nil
end

local function getBaseplate()
	local plot = getPlot()
	local base = plot and plot:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		return base
	end
	return nil
end

local function getPlotTop()
	local base = getBaseplate()
	if not base then
		return nil
	end
	return base.Position + Vector3.new(0, base.Size.Y / 2, 0)
end

local plotRandom = Random.new()

local function randomPlotPoint(margin, avoid, radius)
	local base = getBaseplate()
	if not base then
		return nil
	end
	local halfX = math.max(1, base.Size.X / 2 - margin)
	local halfZ = math.max(1, base.Size.Z / 2 - margin)
	local topY = base.Position.Y + base.Size.Y / 2
	local fallback = nil
	for _ = 1, 24 do
		local offset = Vector3.new(plotRandom:NextNumber(-halfX, halfX), 0, plotRandom:NextNumber(-halfZ, halfZ))
		local world = base.CFrame:PointToWorldSpace(offset)
		local point = Vector3.new(world.X, topY, world.Z)
		local clear = true
		if avoid then
			for _, other in ipairs(avoid) do
				if Vector3.new(other.X - point.X, 0, other.Z - point.Z).Magnitude < radius then
					clear = false
					break
				end
			end
		end
		if clear then
			return point
		end
		fallback = fallback or point
	end
	return fallback
end

local noclipSaved = {}

local function setNoclip(active)
	local character = LocalPlayer.Character
	if not character then
		return
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if active then
				if noclipSaved[descendant] == nil then
					noclipSaved[descendant] = descendant.CanCollide
				end
				descendant.CanCollide = false
			elseif noclipSaved[descendant] ~= nil then
				descendant.CanCollide = noclipSaved[descendant]
				noclipSaved[descendant] = nil
			end
		end
	end
end

local function clearNoclip()
	for part, value in pairs(noclipSaved) do
		if part and part.Parent then
			pcall(function()
				part.CanCollide = value
			end)
		end
		noclipSaved[part] = nil
	end
end

local CRUISE_HEIGHT = 250

local function flightPath(from, to)
	if Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude < 80 and math.abs(to.Y - from.Y) < 30 then
		return {to}
	end
	local height = math.max(from.Y, to.Y) + CRUISE_HEIGHT
	return {
		Vector3.new(from.X, height, from.Z),
		Vector3.new(to.X, height, to.Z),
		to,
	}
end

local function travelTime(from, to)
	local total = 0
	for _, point in ipairs(flightPath(from, to)) do
		total = total + (point - from).Magnitude
		from = point
	end
	return total / math.max(config.flySpeed, 20)
end

local flying = false

local function flyTo(position, abortCheck, tolerance)
	local root = getRoot()
	if not root or typeof(position) ~= "Vector3" then
		return false
	end
	tolerance = tolerance or 3
	if (root.Position - position).Magnitude <= tolerance then
		return true
	end
	local path = flightPath(root.Position, position)
	local deadline = tick() + travelTime(root.Position, position) + 6
	setNoclip(true)
	flying = true
	local connection = RunService.Stepped:Connect(function()
		local character = LocalPlayer.Character
		if not character then
			return
		end
		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.CanCollide then
				descendant.CanCollide = false
			end
		end
	end)
	local reached = false
	local index = 1
	while tick() < deadline do
		if abortCheck and abortCheck() then
			break
		end
		local heartbeat = RunService.Heartbeat:Wait()
		root = getRoot()
		if not root then
			break
		end
		local final = index == #path
		local delta = path[index] - root.Position
		local distance = delta.Magnitude
		if distance <= (final and tolerance or 2) then
			if final then
				reached = true
				break
			end
			index = index + 1
		else
			local step = math.min(distance, math.max(config.flySpeed, 20) * heartbeat)
			local flat = Vector3.new(delta.X, 0, delta.Z)
			local rotation = flat.Magnitude > 0.1 and CFrame.lookAt(Vector3.zero, flat.Unit) or root.CFrame.Rotation
			pcall(function()
				root.CFrame = CFrame.new(root.Position + delta.Unit * step) * rotation
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end
	end
	connection:Disconnect()
	flying = false
	setNoclip(false)
	clearNoclip()
	local endRoot = getRoot()
	if endRoot then
		pcall(function()
			endRoot.AssemblyLinearVelocity = Vector3.zero
		end)
		if (endRoot.Position - position).Magnitude <= tolerance + 1 then
			return true
		end
	end
	return reached
end

local function firePrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end
	local fired = false
	if typeof(fireproximityprompt) == "function" then
		for _ = 1, 3 do
			if pcall(fireproximityprompt, prompt) then
				fired = true
				break
			end
			task.wait(0.1)
		end
	end
	if fired then
		return true
	end
	return pcall(function()
		prompt:InputHoldBegin()
		task.wait(math.max(prompt.HoldDuration, 0.1) + 0.1)
		prompt:InputHoldEnd()
	end)
end

local function basketCount()
	local basket = LocalPlayer:FindFirstChild("Basket")
	return basket and #basket:GetChildren() or 0
end

local function basketCapacity()
	local equipped = getSaved("EquippedEggBasket")
	local table_ = gameData("EggBaskets")
	local entry = type(table_) == "table" and equipped and table_[tostring(equipped)] or nil
	local capacity = type(entry) == "table" and tonumber(entry.Capacity) or 1
	if capacity == math.huge or capacity > 50 then
		return 50
	end
	return math.max(1, capacity)
end

local function isCollected(name)
	local attribute = LocalPlayer:GetAttribute("CollectedEggs")
	return type(attribute) == "string" and attribute ~= "" and string.find(attribute, tostring(name) .. ",", 1, true) ~= nil
end

local function eggVisible(instance)
	local egg = instance:GetAttribute("Egg")
	local position = instance:GetAttribute("Position")
	local privateTo = instance:GetAttribute("PrivateTo")
	return type(egg) == "string" and typeof(position) == "Vector3" and (privateTo == nil or privateTo == LocalPlayer.UserId)
end

local function eggOptions(from)
	local options = {}
	local plotTop = getPlotTop()
	local now = tick()
	local eggs = getActiveEggs()
	if not eggs then
		return options
	end
	for _, child in ipairs(eggs:GetChildren()) do
		if eggVisible(child) then
			local name = child:GetAttribute("Egg")
			local cooldown = state.cooldowns[child.Name]
			local blocked = cooldown and cooldown > now
			if not blocked and not isCollected(name) and (config.targetEgg == nil or config.targetEgg == name) then
				local rank = eggRank(name)
				if rank >= config.minRarity then
					local position = child:GetAttribute("Position")
					local travel = plotTop and travelTime(position, plotTop) or 0
					if travel < 15 then
						table.insert(options, {
							Config = child,
							Name = name,
							Position = position,
							Rank = rank,
							Luck = eggLuck(name) * (tonumber(child:GetAttribute("Weight")) or 1),
							Distance = (position - from).Magnitude,
						})
					end
				end
			end
		end
	end
	table.sort(options, function(a, b)
		if config.priority == "Nearest" then
			return a.Distance < b.Distance
		end
		if config.priority == "Farthest" then
			return a.Distance > b.Distance
		end
		if config.priority == "Highest Rarity" then
			if a.Rank ~= b.Rank then
				return a.Rank > b.Rank
			end
			if a.Luck ~= b.Luck then
				return a.Luck > b.Luck
			end
			return a.Distance < b.Distance
		end
		if a.Luck ~= b.Luck then
			return a.Luck > b.Luck
		end
		return a.Distance < b.Distance
	end)
	return options
end

local function nextManual()
	local eggs = getActiveEggs()
	if not eggs then
		return nil
	end
	while #state.manual > 0 do
		local instance = eggs:FindFirstChild(state.manual[1])
		if instance and eggVisible(instance) then
			return {
				Config = instance,
				Name = instance:GetAttribute("Egg"),
				Position = instance:GetAttribute("Position"),
			}
		end
		table.remove(state.manual, 1)
	end
	return nil
end

local function removeFromManual(name)
	local index = table.find(state.manual, name)
	if index then
		table.remove(state.manual, index)
	end
end

local function deliverEggs(abortCheck)
	if basketCount() <= 0 then
		return true
	end
	setFarmStatus("bringing eggs home")
	local plotTop = getPlotTop()
	if not plotTop then
		return false
	end
	local root = getRoot()
	if not root then
		return false
	end
	pcall(function()
		root.CFrame = CFrame.new(plotTop + Vector3.new(0, 4, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	local deadline = tick() + 6
	while basketCount() > 0 and tick() < deadline do
		if abortCheck() then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if basketCount() > 0 then
		local retry = getRoot()
		if retry then
			pcall(function()
				retry.CFrame = CFrame.new(plotTop + Vector3.new(0, 4, 0))
				retry.AssemblyLinearVelocity = Vector3.zero
			end)
		end
		deadline = tick() + 4
		while basketCount() > 0 and tick() < deadline do
			RunService.Heartbeat:Wait()
		end
	end
	if basketCount() == 0 then
		state.lastPickup = 0
	end
	return basketCount() == 0
end

local function pickTarget(from)
	local target = nextManual()
	if not target then
		for _, option in ipairs(eggOptions(from)) do
			if not table.find(state.manual, option.Config.Name) then
				target = option
				break
			end
		end
	end
	return target
end

local function collectStep(abortCheck)
	local capacity = basketCapacity()
	local collected = false
	while basketCount() < capacity do
		if abortCheck() then
			break
		end
		local root = getRoot()
		if not root then
			break
		end
		local target = pickTarget(root.Position)
		if not target then
			break
		end
		local uid = target.Config.Name
		local name = target.Name
		local instance = target.Config
		setFarmStatus("collecting " .. tostring(name))
		local reached = flyTo(target.Position + Vector3.new(0, 3, 0), function()
			return abortCheck() or instance.Parent == nil
		end, 6)
		if instance.Parent == nil and not reached then
			removeFromManual(uid)
		else
			local before = basketCount()
			state.lastPickup = tick()
			fireRemote("EggPickup", uid)
			local deadline = tick() + 1.5
			while basketCount() == before and tick() < deadline do
				RunService.Heartbeat:Wait()
			end
			removeFromManual(uid)
			if basketCount() > before then
				collected = true
			else
				state.cooldowns[uid] = tick() + 20
				break
			end
		end
	end
	if basketCount() > 0 then
		deliverEggs(abortCheck)
	end
	return collected
end

local function plotEggFolder()
	local plot = getPlot()
	local folder = plot and plot:FindFirstChild("Eggs")
	return folder and folder:GetChildren() or {}
end

local function plotPetFolder()
	local plot = getPlot()
	local folder = plot and plot:FindFirstChild("Pets")
	return folder and folder:GetChildren() or {}
end

local function occupiedPoints()
	local points = {}
	for _, instance in ipairs(plotEggFolder()) do
		local ok, position = pcall(function()
			return instance:GetPivot().Position
		end)
		if ok then
			table.insert(points, position)
		end
	end
	for _, instance in ipairs(plotPetFolder()) do
		local ok, position = pcall(function()
			return instance:GetPivot().Position
		end)
		if ok then
			table.insert(points, position)
		end
	end
	return points
end

local function equippedTools(tag)
	local tools = {}
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") and CollectionService:HasTag(child, tag) then
				table.insert(tools, child)
			end
		end
	end
	local character = getCharacter()
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") and CollectionService:HasTag(child, tag) then
				table.insert(tools, child)
			end
		end
	end
	return tools
end

local function equipTool(tool)
	local humanoid = getHumanoid()
	local character = getCharacter()
	if not humanoid or not tool or not character then
		return false
	end
	if tool.Parent == character then
		return true
	end
	pcall(function()
		humanoid:EquipTool(tool)
	end)
	local deadline = tick() + 1
	while tool.Parent ~= character and tick() < deadline do
		RunService.Heartbeat:Wait()
	end
	return tool.Parent == character
end

local function unequipTools()
	local humanoid = getHumanoid()
	if humanoid then
		pcall(function()
			humanoid:UnequipTools()
		end)
	end
end

local function toolAmount(tool)
	local amount = tool:FindFirstChild("Amount", true)
	return amount and tonumber(amount.Value) or 1
end

local function bestFoodTool()
	local best, bestCost = nil, math.huge
	for _, tool in ipairs(equippedTools("Food")) do
		if toolAmount(tool) > 0 and (config.food == nil or tool.Name == config.food) then
			local foodsTable = gameData("Foods")
			local entry = type(foodsTable) == "table" and foodsTable[tool.Name] or nil
			local cost = type(entry) == "table" and tonumber(entry.Cost) or 0
			if cost < bestCost then
				best = tool
				bestCost = cost
			end
		end
	end
	return best
end

local feedCooldowns = {}
local hatchCooldowns = {}

local function plantStep(abortCheck)
	local tools = {}
	for _, tool in ipairs(equippedTools("Egg")) do
		if config.plantRarity <= eggRank(tool.Name) then
			table.insert(tools, tool)
		end
	end
	if #tools == 0 then
		return false
	end
	table.sort(tools, function(a, b)
		return eggLuck(a.Name) > eggLuck(b.Name)
	end)
	local points = occupiedPoints()
	local planted = 0
	for _, tool in ipairs(tools) do
		if abortCheck() then
			break
		end
		if tool.Parent then
			local point = randomPlotPoint(8, points, 5)
			if point then
				setFarmStatus("planting " .. tostring(tool.Name))
				if equipTool(tool) then
					fireRemote("EggPlaced", {PlantPosition = point})
					table.insert(points, point)
					planted = planted + 1
					task.wait(0.2)
				end
			end
		end
	end
	unequipTools()
	return planted > 0
end

local function hatchReadyEggs()
	local entries = {}
	for _, instance in ipairs(plotEggFolder()) do
		local timer = instance:FindFirstChild("Timer", true)
		local prompt = instance:FindFirstChild("Hatch", true)
		if prompt and prompt:IsA("ProximityPrompt") then
			local text = timer and timer:IsA("TextLabel") and string.lower(timer.Text) or nil
			if text == nil or string.find(text, "ready", 1, true) ~= nil then
				table.insert(entries, {
					Egg = instance,
					Prompt = prompt,
				})
			end
		end
	end
	table.sort(entries, function(a, b)
		return a.Egg.Name < b.Egg.Name
	end)
	return entries
end

local function hatchStep(abortCheck)
	if abortCheck() then
		return false
	end
	local entries = hatchReadyEggs()
	for _, entry in ipairs(entries) do
		if abortCheck() then
			break
		end
		local uid = tostring(entry.Egg.Name)
		local ok, position = pcall(function()
			return entry.Egg:GetPivot().Position
		end)
		if not ok then
			hatchCooldowns[uid] = tick() + 10
		elseif (hatchCooldowns[uid] or 0) <= tick() then
			setFarmStatus("hatching eggs")
			flyTo(position + Vector3.new(0, 2, 2), abortCheck, 3)
			local prompt = entry.Egg:FindFirstChild("Hatch", true)
			if prompt and prompt:IsA("ProximityPrompt") then
				pcall(function()
					prompt.Enabled = true
					prompt.MaxActivationDistance = 20
					prompt.RequiresLineOfSight = false
					prompt.HoldDuration = 0
				end)
				firePrompt(prompt)
				local deadline = tick() + 3
				while tick() < deadline and entry.Egg.Parent do
					RunService.Heartbeat:Wait()
				end
				if entry.Egg.Parent then
					firePrompt(prompt)
					deadline = tick() + 3
					while tick() < deadline and entry.Egg.Parent do
						RunService.Heartbeat:Wait()
					end
				end
			end
			if entry.Egg.Parent then
				hatchCooldowns[uid] = tick() + 10
			else
				hatchCooldowns[uid] = nil
				task.wait(0.5)
				unequipTools()
				return true
			end
		end
	end
	return false
end

local function maxPets()
	return math.max(1, tonumber(LocalPlayer:GetAttribute("MaxPets")) or tonumber(getSaved("MaxPets")) or 5)
end

local function petScoreOf(instance)
	return petScore(petNameOf(instance), instance:GetAttribute("Weight"), instance:GetAttribute("Mutation"))
end

local function bestPetTool()
	local best, bestScore = nil, -1
	for _, tool in ipairs(equippedTools("Pet")) do
		local score = petScore(petNameOf(tool), tool:GetAttribute("Weight"), tool:GetAttribute("Mutation"))
		if score > bestScore then
			best = tool
			bestScore = score
		end
	end
	return best, bestScore
end

local function weakestPet()
	local worst, worstScore = nil, math.huge
	for _, instance in ipairs(plotPetFolder()) do
		local score = petScoreOf(instance)
		if score < worstScore then
			worst = instance
			worstScore = score
		end
	end
	return worst, worstScore
end

local function placePet(tool, abortCheck)
	local key = tool:GetAttribute("PetKey")
	if not key then
		return false
	end
	local plotTop = getPlotTop()
	if plotTop then
		flyTo(plotTop + Vector3.new(0, 4, 0), abortCheck, 20)
	end
	if not equipTool(tool) then
		return false
	end
	local point = randomPlotPoint(10, nil, 0)
	local before = #plotPetFolder()
	fireRemote("PlacePet", key, point + Vector3.new(0, 2, 0))
	task.wait(0.35)
	unequipTools()
	local deadline = tick() + 1.5
	while tick() < deadline and #plotPetFolder() == before do
		RunService.Heartbeat:Wait()
	end
	return #plotPetFolder() > before
end

local function placeStep(abortCheck)
	local placed = 0
	for _ = 1, maxPets() do
		if abortCheck() then
			break
		end
		local tool, toolScore = bestPetTool()
		if not tool then
			break
		end
		if #plotPetFolder() < maxPets() then
			setFarmStatus("placing " .. tostring(petNameOf(tool)))
			if placePet(tool, abortCheck) then
				placed = placed + 1
			end
		else
			local worst, worstScore = weakestPet()
			local key = worst and worst:GetAttribute("PetKey")
			if key and toolScore > worstScore * 1.05 then
				setFarmStatus("placing " .. tostring(petNameOf(tool)))
				local plotTop = getPlotTop()
				if plotTop then
					flyTo(plotTop + Vector3.new(0, 4, 0), abortCheck, 20)
				end
				fireRemote("PickupPet", key)
				local deadline = tick() + 1.5
				while tick() < deadline and worst.Parent do
					RunService.Heartbeat:Wait()
				end
				if not worst.Parent then
					setFarmStatus("placing " .. tostring(petNameOf(tool)))
					if placePet(tool, abortCheck) then
						placed = placed + 1
					end
				end
			else
				break
			end
		end
	end
	return placed > 0
end

local function feedStep(abortCheck)
	local pets = plotPetFolder()
	table.sort(pets, function(a, b)
		return petScoreOf(a) > petScoreOf(b)
	end)
	local fed = 0
	for _, instance in ipairs(pets) do
		if abortCheck() then
			break
		end
		local key = instance:GetAttribute("PetKey")
		if key and (feedCooldowns[key] or 0) <= tick() then
			local tool = bestFoodTool()
			if not tool then
				break
			end
			local ok, position = pcall(function()
				return instance:GetPivot().Position
			end)
			if ok then
				setFarmStatus("feeding " .. tostring(instance:GetAttribute("PetName") or instance.Name))
				flyTo(position + Vector3.new(0, 4, 4), abortCheck, 8)
				if equipTool(tool) then
					local age = instance:GetAttribute("Age")
					fireRemote("FeedPet", key, tool.Name)
					local deadline = tick() + 1.2
					while tick() < deadline and instance:GetAttribute("Age") == age do
						RunService.Heartbeat:Wait()
					end
					feedCooldowns[key] = tick() + 2
					fed = fed + 1
				end
			end
		end
	end
	unequipTools()
	return fed > 0
end

local function feedWanted()
	if not enabled.feed or not bestFoodTool() then
		return false
	end
	for _, instance in ipairs(plotPetFolder()) do
		local key = instance:GetAttribute("PetKey")
		if key and (feedCooldowns[key] or 0) <= tick() then
			return true
		end
	end
	return false
end

local function placeWanted()
	if not enabled.place then
		return false
	end
	local tool, toolScore = bestPetTool()
	if not tool then
		return false
	end
	if #plotPetFolder() < maxPets() then
		return true
	end
	local worst, worstScore = weakestPet()
	return worst ~= nil and toolScore > worstScore * 1.05
end

local function shopChoices(category)
	local names = {}
	local shopData = gameData("Shop")
	local shopTable = type(shopData) == "table" and shopData[category] or nil
	if type(shopTable) == "table" then
		local sorted = {}
		for name, entry in pairs(shopTable) do
			if type(entry) == "table" then
				table.insert(sorted, {Name = name, Price = tonumber(entry.Price) or 0})
			end
		end
		table.sort(sorted, function(a, b)
			return a.Price < b.Price
		end)
		for _, item in ipairs(sorted) do
			table.insert(names, item.Name)
		end
	end
	return names
end

local function shopPrice(category, name)
	local shopData = gameData("Shop")
	local shopTable = type(shopData) == "table" and shopData[category] or nil
	local entry = type(shopTable) == "table" and shopTable[name] or nil
	return type(entry) == "table" and tonumber(entry.Price) or math.huge
end

local shopStock = {Food = {}, Gears = {}}

local function toolCountByName(name)
	local total = 0
	local containers = {LocalPlayer:FindFirstChildOfClass("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and string.gsub(child.Name, "%s*%[.*$", "") == name then
					total = total + toolAmount(child)
				end
			end
		end
	end
	return total
end

local function buyCategory(category, selected)
	local names = shopChoices(category)
	local opened = false
	for _, name in ipairs(names) do
		if selected == nil or name == selected then
			local price = shopPrice(category, name)
			local stock = shopStock[category][name]
			local wanted = stock == nil or stock > 0
			local attempts = 0
			while wanted and attempts < 20 and getCash() >= price do
				if not opened then
					fireRemote("SetOpenShop", category)
					task.wait(0.15)
					opened = true
				end
				local before = toolCountByName(name)
				fireRemote("BuyWithCash", category, name)
				attempts = attempts + 1
				local deadline = tick() + 0.8
				while tick() < deadline and toolCountByName(name) <= before do
					RunService.Heartbeat:Wait()
				end
				if toolCountByName(name) > before then
					if shopStock[category][name] then
						shopStock[category][name] = math.max(0, shopStock[category][name] - 1)
						wanted = shopStock[category][name] > 0
					end
				else
					shopStock[category][name] = 0
					wanted = false
				end
			end
		end
	end
end

local stockConnections = {}

do
	for _, name in ipairs({"Restock", "ShopStock"}) do
		local remotes = getRemotesFolder()
		local remote = remotes and remotes:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			table.insert(stockConnections, remote.OnClientEvent:Connect(function(payload)
				if type(payload) == "table" then
					for category, items in pairs(payload) do
						if (category == "Food" or category == "Gears") and type(items) == "table" then
							local parsed = {}
							for itemName, entry in pairs(items) do
								if type(entry) == "table" then
									parsed[itemName] = tonumber(entry.Amount) or 0
								end
							end
							shopStock[category] = parsed
						end
					end
				end
			end))
		end
	end
	fireRemote("ShopStock")
end

local function rebirthCost()
	local table_ = gameData("Rebirths")
	if type(table_) ~= "table" then
		return nil
	end
	local count = tonumber(getSaved("Rebirths")) or 0
	local cap = tonumber(table_.Cap)
	if cap and count >= cap then
		return nil
	end
	if type(table_.GetCost) == "function" then
		local ok, result = pcall(table_.GetCost, count)
		if ok and tonumber(result) then
			return tonumber(result)
		end
	end
	return nil
end

local function carryActive()
	if basketCount() <= 0 then
		return false
	end
	return state.lastPickup > 0 and tick() - state.lastPickup < 30
end

local function farmActive()
	return enabled.collect or carryActive() or enabled.plant or enabled.hatch or enabled.place or enabled.feed
end

local function stopRequested()
	return not farmActive()
end

local function doAutoFarm()
	if not farmActive() or not getRoot() or not getPlot() then
		return
	end
	if basketCount() > 0 and not stopRequested() then
		deliverEggs(stopRequested)
	end
	if enabled.plant and not stopRequested() then
		plantStep(stopRequested)
	end
	if enabled.hatch and not stopRequested() then
		hatchStep(stopRequested)
	end
	if placeWanted() and not stopRequested() then
		placeStep(stopRequested)
	end
	if feedWanted() and not stopRequested() then
		feedStep(stopRequested)
	end
	if enabled.collect and not stopRequested() then
		collectStep(stopRequested)
	end
end

local function rejoinServer()
	pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
end

local function reconnectServer()
	pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
end

local function serverHop()
	if not httpRequest then
		return reconnectServer()
	end
	task.spawn(function()
		local best, bestCount = nil, math.huge
		local ok, response = pcall(httpRequest, {
			Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId),
			Method = "GET",
		})
		if ok and response.Body then
			local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, response.Body)
			if okDecode and type(decoded.data) == "table" then
				for _, server in ipairs(decoded.data) do
					if server.id ~= game.JobId and type(server.playing) == "number" and server.playing < bestCount then
						best = server.id
						bestCount = server.playing
					end
				end
			end
		end
		if best then
			pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, best, LocalPlayer)
		else
			pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
		end
	end)
end

local afkConnection
local function setAntiAfk(active)
	if active and not afkConnection then
		afkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	elseif not active and afkConnection then
		afkConnection:Disconnect()
		afkConnection = nil
	end
end

local renderingDisabled = false
local function setRendering(disable)
	if disable == renderingDisabled then
		return
	end
	renderingDisabled = disable
	pcall(function()
		RunService:Set3dRenderingEnabled(not disable)
	end)
end

local fpsOriginals
local function setFpsBoost(active)
	if active and not fpsOriginals then
		fpsOriginals = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			Brightness = Lighting.Brightness,
		}
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.Brightness = 1
		end)
	elseif not active and fpsOriginals then
		pcall(function()
			Lighting.GlobalShadows = fpsOriginals.GlobalShadows
			Lighting.FogEnd = fpsOriginals.FogEnd
			Lighting.Brightness = fpsOriginals.Brightness
		end)
		fpsOriginals = nil
	end
end

local espFontOk, espFont = pcall(function()
	return Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold, Enum.FontStyle.Normal)
end)
if not espFontOk then
	espFont = nil
end
local espFolder = nil
local espUpdateAt = 0

local function clearEspEntry(entry)
	if entry and entry.Gui then
		pcall(function()
			entry.Gui:Destroy()
		end)
	end
end

local function clearAllEsp()
	for instance, entry in pairs(state.espEntries) do
		clearEspEntry(entry)
		state.espEntries[instance] = nil
	end
	if espFolder then
		pcall(function()
			espFolder:Destroy()
		end)
		espFolder = nil
	end
end

local function styleEspLabel(label, height)
	label.BackgroundTransparency = 1
	if espFont then
		label.FontFace = espFont
	else
		label.Font = Enum.Font.GothamBold
	end
	label.TextScaled = true
	label.TextStrokeTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Size = UDim2.new(1, 0, 0, height)
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.8
	stroke.Transparency = 0.05
	stroke.Parent = label
end

local function espHost()
	local candidates = {read(function()
		return gethui()
	end), read(function()
		return game:GetService("CoreGui")
	end), LocalPlayer:FindFirstChildOfClass("PlayerGui")}
	for _, candidate in ipairs(candidates) do
		if typeof(candidate) == "Instance" then
			return candidate
		end
	end
	return nil
end

local function createEspEntry(instance)
	if state.espEntries[instance] or not espFolder then
		return
	end
	local name = instance:GetAttribute("Egg")
	local position = instance:GetAttribute("Position")
	if type(name) ~= "string" or typeof(position) ~= "Vector3" then
		return
	end
	local privateTo = instance:GetAttribute("PrivateTo")
	if privateTo ~= nil and privateTo ~= LocalPlayer.UserId then
		return
	end
	if eggRank(name) < config.espRarity then
		return
	end
	local rarity = eggRarity(name)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Size = UDim2.fromOffset(170, 46)
	billboard.Adornee = Workspace.Terrain
	billboard.StudsOffsetWorldSpace = position + Vector3.new(0, 4, 0)
	billboard.MaxDistance = 100000
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = frame
	local nameLabel = Instance.new("TextLabel")
	nameLabel.LayoutOrder = 1
	styleEspLabel(nameLabel, 24)
	nameLabel.Text = name
	nameLabel.TextColor3 = RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
	nameLabel.Parent = frame
	local infoLabel = Instance.new("TextLabel")
	infoLabel.LayoutOrder = 2
	styleEspLabel(infoLabel, 18)
	infoLabel.TextColor3 = Color3.fromRGB(230, 232, 240)
	infoLabel.Parent = frame
	billboard.Parent = espFolder
	state.espEntries[instance] = {
		Gui = billboard,
		Info = infoLabel,
		Rarity = rarity,
		Position = position,
		Weight = tonumber(instance:GetAttribute("Weight")) or 1,
	}
end

local function setEsp(active)
	clearAllEsp()
	if active then
		espFolder = Instance.new("Folder")
		espFolder.Name = "AntiGodEsp"
		local host = espHost()
		if host then
			espFolder.Parent = host
		end
		local eggs = getActiveEggs()
		if eggs then
			for _, instance in ipairs(eggs:GetChildren()) do
				createEspEntry(instance)
			end
		end
	end
end

local function updateEsp()
	if not enabled.esp then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	for instance, entry in pairs(state.espEntries) do
		if instance.Parent == nil then
			clearEspEntry(entry)
			state.espEntries[instance] = nil
		elseif entry.Info then
			entry.Info.Text = string.format("%s  %.2fkg  %dm", entry.Rarity, entry.Weight, math.floor((entry.Position - root.Position).Magnitude))
		end
	end
end

local espConnection = nil

local ui = (function()
local execName, execVersion
if identifyexecutor then
	local ok, name, version = pcall(identifyexecutor)
	if ok and type(name) == "string" and name ~= "" then
		execName = name
		if type(version) == "string" and version ~= "" then
			execVersion = version
		end
	end
end
execName = execName or "Unknown"
local executorText = execVersion and (execName .. " " .. execVersion) or execName

local Window = Library:CreateWindow({
	Title = CONFIG.Title,
	Icon = CONFIG.Icon,
	CornerRadius = CONFIG.CornerRadius,
	Footer = {
		{ Text = CONFIG.Discord, Copyable = true },
		"|",
		{ Text = CONFIG.GameName, Copyable = true },
		"|",
		CONFIG.Version,
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	SearchKeybind = Enum.KeyCode.F,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	NotifySide = "Right",
	SidebarCompacted = true,
	SidebarCompactWidth = 48,
	EnableSidebarResize = false,
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
		KeyPicker = true,
		SubTabUnderline = true,
	},
})

local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "zap" }),
	Settings = Window:AddTab({ Name = "UI Settings", Icon = "settings" }),
}

local COLORS = {
	label = "#ffffff",
	user = "#7CFC7C",
	accent = "#4AA3FF",
	orange = "#FFA54F",
	gold = "#FFD24A",
}

local function paint(prefix, value, color)
	return string.format('<font color="%s">%s</font> <font color="%s">%s</font>', COLORS.label, prefix, color or COLORS.accent, tostring(value))
end

local function box(parent, name, icon, side)
	return parent:AddGroupbox({ Name = name, IconName = icon, Side = side, PopOut = false })
end

local function setLabel(idx, text)
	pcall(function()
		local label = Library.Labels and Library.Labels[idx]
		if label and type(label.SetText) == "function" then
			label:SetText(text)
		end
	end)
end

local UserBox = box(Tabs.Info, "Account", "user", "Left")
UserBox:AddPlayerInfo("InfoAvatar", { ThumbnailType = "Bust", Height = 190 })
UserBox:AddDivider()
UserBox:AddLabel("UserLabel", { Text = paint("User -", LocalPlayer.DisplayName, COLORS.user), DoesWrap = true })
UserBox:AddLabel("UserIdLabel", { Text = paint("UserId -", LocalPlayer.UserId, COLORS.accent), DoesWrap = true })
UserBox:AddLabel("ExecutorLabel", { Text = paint("Executor -", executorText, COLORS.orange), DoesWrap = true })
UserBox:AddDivider()
UserBox:AddLabel("SessionTime", { Text = paint("Session -", "0s", COLORS.orange), DoesWrap = true })
UserBox:AddButton({ Text = "Copy User ID", Func = function()
	if copyText then
		pcall(copyText, tostring(LocalPlayer.UserId))
	end
	pcall(function()
		Library:Notify("Copied User ID")
	end)
end })
UserBox:AddButton({ Text = "Copy Username", Func = function()
	if copyText then
		pcall(copyText, tostring(LocalPlayer.Name))
	end
	pcall(function()
		Library:Notify("Copied Username")
	end)
end })

local GameBox = box(Tabs.Info, "Game Info", "gamepad", "Right")
GameBox:AddLabel("GameNameLabel", { Text = paint("Game -", CONFIG.GameName, COLORS.accent), DoesWrap = true })
GameBox:AddLabel("ServerPlayersLabel", { Text = paint("Players -", "0/0", COLORS.user), DoesWrap = true })
GameBox:AddLabel("ServerIdLabel", { Text = paint("Server -", string.sub(game.JobId ~= "" and game.JobId or "N/A", 1, 18), COLORS.orange), DoesWrap = true })
GameBox:AddButton({ Text = "Copy Join Script", Func = function()
	if copyText then
		pcall(copyText, string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")', game.PlaceId, game.JobId))
	end
	pcall(function()
		Library:Notify("Copied join script")
	end)
end })

local SocialsBox = box(Tabs.Info, "Socials", "link", "Right")
SocialsBox:AddButton({ Text = "Copy Discord Invite", Func = function()
	if copyText then
		pcall(copyText, CONFIG.Discord)
	end
	pcall(function()
		Library:Notify("Copied Discord invite")
	end)
end })
SocialsBox:AddButton({ Text = "Copy Website", Func = function()
	if copyText then
		pcall(copyText, CONFIG.Website)
	end
	pcall(function()
		Library:Notify("Copied website link")
	end)
end })

local FarmTab = Tabs.Main:AddSubTab({ Name = "Farm", Icon = "star" })
local PetsTab = Tabs.Main:AddSubTab({ Name = "Pets", Icon = "heart" })
local ShopTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-bag" })

local FarmBox = box(FarmTab, "Collect Egg", "egg", "Left")
FarmBox:AddToggle("Collect", { Text = "Auto Collect Eggs", Default = false, Callback = function(value)
	enabled.collect = value
end })
FarmBox:AddDropdown("MinEggRarity", { Text = "Min Egg Rarity", Values = RARITY_CHOICES, Default = "Any", Callback = function(value)
	config.minRarity = RARITY_RANK[tostring(value)] or 0
end })
FarmBox:AddDropdown("TargetEgg", { Text = "Target Egg", Values = EGG_CHOICES, Default = "Any", Callback = function(value)
	config.targetEgg = value == "Any" and nil or tostring(value)
end })
FarmBox:AddDropdown("CollectPriority", { Text = "Collect Priority", Values = SORT_MODES, Default = "Highest Rarity", Callback = function(value)
	config.priority = tostring(value)
end })
local StatusBox = box(FarmTab, "Farm Status", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("CashLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("RebirthsLabel", { Text = paint("Rebirths -", "0", COLORS.accent), DoesWrap = true })

local UpgradeBox = box(FarmTab, "Upgrade", "trending-up", "Right")
UpgradeBox:AddToggle("UpgradeHatchLuck", { Text = "Upgrade Hatch Luck", Default = false, Callback = function(value)
	enabled.upgrade = value
end })

local PlantBox = box(PetsTab, "Place & Hatch", "egg", "Left")
PlantBox:AddToggle("Plant", { Text = "Auto Place Egg", Default = false, Callback = function(value)
	enabled.plant = value
end })
PlantBox:AddDropdown("PlantRarity", { Text = "Plant Min Rarity", Values = RARITY_CHOICES, Default = "Any", Callback = function(value)
	config.plantRarity = RARITY_RANK[tostring(value)] or 0
end })
PlantBox:AddToggle("Hatch", { Text = "Auto Hatch Eggs", Default = false, Callback = function(value)
	enabled.hatch = value
	if value then
		hatchCooldowns = {}
	end
end })

local PetsBox = box(PetsTab, "Pets", "heart", "Right")
PetsBox:AddToggle("Place", { Text = "Auto Place Best Pets", Default = false, Callback = function(value)
	enabled.place = value
end })
PetsBox:AddToggle("Feed", { Text = "Auto Feed Pets", Default = false, Callback = function(value)
	enabled.feed = value
	if not value then
		feedCooldowns = {}
	end
end })
PetsBox:AddDropdown("FoodToUse", { Text = "Food To Use", Values = FOOD_CHOICES, Default = "Any", Callback = function(value)
	config.food = value == "Any" and nil or tostring(value)
end })

local ShopBox = box(ShopTab, "Gears", "shopping-bag", "Left")
ShopBox:AddToggle("FoodBuy", { Text = "Auto Buy Food", Default = false, Callback = function(value)
	enabled.foodBuy = value
end })
ShopBox:AddDropdown("FoodBuyItem", { Text = "Food To Buy", Values = FOOD_CHOICES, Default = "Any", Callback = function(value)
	config.foodBuy = value == "Any" and nil or tostring(value)
end })
ShopBox:AddToggle("GearBuy", { Text = "Auto Buy Radars", Default = false, Callback = function(value)
	enabled.gearBuy = value
end })
ShopBox:AddDropdown("GearBuyItem", { Text = "Radar To Buy", Values = GEAR_CHOICES, Default = "Any", Callback = function(value)
	config.gearBuy = value == "Any" and nil or tostring(value)
end })

local ProgressBox = box(ShopTab, "Rebirth & Index", "trending-up", "Right")
ProgressBox:AddToggle("Rebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })
ProgressBox:AddToggle("Index", { Text = "Auto Claim Index Reward", Default = false, Callback = function(value)
	enabled.index = value
end })

local VisualsBox = box(FarmTab, "ESP", "eye", "Left")
VisualsBox:AddToggle("Esp", { Text = "ESP Eggs", Default = false, Callback = function(value)
	enabled.esp = value
	setEsp(value)
end })
VisualsBox:AddDropdown("EspRarity", { Text = "ESP Min Rarity", Values = RARITY_CHOICES, Default = "Any", Callback = function(value)
	config.espRarity = RARITY_RANK[tostring(value)] or 0
	if enabled.esp then
		setEsp(true)
	end
end })

local MenuBox = box(Tabs.Settings, "Menu", "wrench", "Left")
MenuBox:AddToggle("KeybindMenuOpen", {
	Text = "Open Keybind Menu",
	Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
	Callback = function(value)
		if Library.KeybindFrame then
			Library.KeybindFrame.Visible = value
		end
	end,
})
MenuBox:AddDropdown("NotificationSide", {
	Text = "Notification Side",
	Values = { "Left", "Right" },
	Default = "Right",
	Callback = function(value)
		pcall(function()
			Library:SetNotifySide(value)
		end)
	end,
})
MenuBox:AddDropdown("DPIScale", {
	Text = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Callback = function(value)
		pcall(function()
			Library:SetDPIScale(tonumber((value:gsub("%%", ""))))
		end)
	end,
})
MenuBox:AddDivider()
MenuBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
MenuBox:AddButton({ Text = "Unload", Func = function()
	Library:Unload()
end })
Library.ToggleKeybind = Options.MenuKeybind

local ClientBox = box(Tabs.Settings, "Client", "cpu", "Left")
ClientBox:AddToggle("AntiAfk", { Text = "Anti AFK", Default = false, Callback = function(value)
	enabled.antiafk = value
	setAntiAfk(value)
end })
ClientBox:AddToggle("NoGameplayPaused", { Text = "No Gameplay Paused", Default = false, Callback = function(value)
	enabled.noPause = value
end })
ClientBox:AddToggle("FpsBoost", { Text = "FPS Boost", Default = false, Callback = function(value)
	setFpsBoost(value)
end })
ClientBox:AddToggle("DisableRendering", { Text = "Disable 3D Rendering", Default = false, Callback = function(value)
	setRendering(value)
end })

local ServerTools = box(Tabs.Settings, "Server", "server", "Right")
ServerTools:AddButton({ Text = "Reconnect", Func = reconnectServer })
ServerTools:AddButton({ Text = "Rejoin Server", Func = rejoinServer })
ServerTools:AddButton({ Text = "Server Hop (Lowest Players)", Func = serverHop })

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

ThemeManager.BuiltInThemes["Dark Silver"] = {
	999,
	{
		FontColor = "f5f5f5",
		MainColor = "1a1a1a",
		AccentColor = "e5e5e5",
		BackgroundColor = "151515",
		OutlineColor = "2a2a2a",
		BackgroundImage = "",
	},
}

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder(CONFIG.Folder)
SaveManager:SetFolder(CONFIG.Folder)
SaveManager:SetSubFolder(tostring(game.PlaceId))

local SettingsAddGroupbox = Tabs.Settings.AddGroupbox
Tabs.Settings.AddGroupbox = function(self, info)
	info = type(info) == "table" and info or {}
	info.PopOut = false
	return SettingsAddGroupbox(self, info)
end
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyTheme("Dark Silver")
ThemeManager:ApplyToTab(Tabs.Settings)
Tabs.Settings.AddGroupbox = SettingsAddGroupbox

pcall(function()
	ThemeManager.UpdateContrastWarning = function() end
	local ContrastLabel = ThemeManager.ContrastLabel
	if ContrastLabel and not ContrastLabel.Destroyed and type(ContrastLabel.Destroy) == "function" then
		ContrastLabel:Destroy()
	end
	ThemeManager.ContrastLabel = nil
end)

local function updateLabels()
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("CashLabel", paint("Cash -", abbreviateNumber(getCash()), COLORS.gold))
	setLabel("RebirthsLabel", paint("Rebirths -", tostring(tonumber(getSaved("Rebirths")) or 0), COLORS.accent))
end

local function chain(steps, interval)
	task.spawn(function()
		while session.running do
			setFarmStatus("idle")
			for _, step in ipairs(steps) do
				if not session.running then
					break
				end
				local ok, err = pcall(step)
				if not ok then
					logError(err)
				end
			end
			task.wait(interval)
		end
	end)
end

local function loop(func, interval)
	task.spawn(function()
		while session.running do
			local ok, err = pcall(func)
			if not ok then
				logError(err)
			end
			task.wait(interval)
		end
	end)
end

local function autoBuyStep()
	if enabled.foodBuy then
		buyCategory("Food", config.foodBuy)
	end
	if enabled.gearBuy then
		buyCategory("Gears", config.gearBuy)
	end
end

local function progressStep()
	if enabled.rebirth and ready("rebirth", 1) then
		local cost = rebirthCost()
		if cost and getCash() >= cost then
			fireRemote("Rebirth")
			timers.rebirth = tick() + 15
		end
	end
	if enabled.index and ready("index", 60) then
		fireRemote("ClaimIndexReward")
	end
end

espConnection = RunService.Heartbeat:Connect(function(deltaTime)
	espUpdateAt = espUpdateAt + deltaTime
	if espUpdateAt < 0.25 then
		return
	end
	espUpdateAt = 0
	if not enabled.esp then
		return
	end
	local eggs = getActiveEggs()
	if eggs then
		for _, instance in ipairs(eggs:GetChildren()) do
			if not state.espEntries[instance] then
				createEspEntry(instance)
			end
		end
	end
	updateEsp()
end)

chain({doAutoFarm}, 0.2)
loop(autoBuyStep, 3)
loop(progressStep, 1)
loop(function()
	if not enabled.upgrade then
		return
	end
	pcall(function()
		local remote = find(ReplicatedStorage, "Remotes", "Game", "Plot", "Upgrades")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer("Max")
		end
	end)
end, 0.3)

task.spawn(function()
	while session.running do
		if enabled.noPause then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
		task.wait(60)
	end
end)
task.spawn(function()
	while session.running do
		task.wait(300)
		if session.running and enabled.antiafk then
			pcall(function()
				local humanoid = getHumanoid()
				if humanoid then
					humanoid.Jump = true
				end
			end)
		end
	end
end)
task.spawn(function()
	while session.running do
		pcall(updateLabels)
		task.wait(1)
	end
end)

end)()

Library:OnUnload(function()
	session.running = false
	if espConnection then
		espConnection:Disconnect()
	end
	for _, connection in ipairs(stockConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	clearAllEsp()
	setNoclip(false)
	clearNoclip()
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()