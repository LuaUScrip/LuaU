local Repo = "https://raw.githubusercontent.com/LuaUScrip/OK/refs/heads/main/"
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
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local copyText = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request)
local RenderSettings = settings

local CONFIG = {
	Title = "AntiGodHub",
	Icon = 80985370671515,
	Discord = "https://discord.gg/jdJvZm6VdK",
	Website = "https://rscripts.net/@AntiGodHub",
	Version = "v1.4",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Swing For Eggs",
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
do
	local legacy = getgenv().AstraHubSwingForEggs
	if legacy ~= nil then
		if type(legacy) == "table" and type(legacy.Unload) == "function" then
			pcall(legacy.Unload)
		end
		pcall(function()
			getgenv().AstraHubSwingForEggs = nil
		end)
	end
end

local session = {running = true, lib = Library}
getgenv().UnitGrinder = session

local enabled = {
	autoSteal = false,
	autoPlace = false,
	autoHatch = false,
	autoEquipBest = false,
	autoIndex = false,
	autoSell = false,
	autoSuits = false,
	autoTreadmill = false,
	autoSlots = false,
	walkSpeed = false,
	infJump = false,
	noClip = false,
	instantPrompt = false,
	fly = false,
	antiafk = true,
	noPause = true,
	autoReconnect = false,
	fpsBoost = false,
	disable3D = false,
}

local settings = {}

local config = {
	stealMode = "Instant",
	tweenSpeed = 500,
	stealZones = {},
	stealRarities = {},
	placeRarities = {},
	placeDelay = 0.2,
	hatchDelay = 0.2,
	equipBestDelay = 0.2,
	sellMode = "Inventory",
	sellMinimum = 1,
	sellDelay = 0.2,
	travelToSeller = true,
	walkSpeed = 32,
	flySpeed = 60,
}

local state = {
	status = "Idle",
	notifications = {},
	plotCapacity = 0,
	capacityStamp = 0,
	moveBusy = false,
	moveStamp = 0,
	stealMiss = {},
}

local features = {
	steal = {on = false, interval = 0.1},
	place = {on = false, interval = 0.2},
	hatch = {on = false, interval = 0.2},
	equipBest = {on = false, interval = 0.2},
	index = {on = false, interval = 15},
	suits = {on = false, interval = 10},
	sell = {on = false, interval = 0.2},
	treadmill = {on = false, interval = 10},
	slots = {on = false, interval = 10},
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

local function fire(remote, ...)
	if remote then
		pcall(remote.FireServer, remote, ...)
	end
end

local function call(remote, ...)
	if remote then
		local ok, result = pcall(remote.InvokeServer, remote, ...)
		if ok then
			return result
		end
	end
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

local EventsFolder
do
	local ok, folder = pcall(function()
		return ReplicatedStorage:WaitForChild("Events", 10)
	end)
	EventsFolder = ok and folder or nil
end

local function waitRemote(name)
	if not EventsFolder then
		return nil
	end
	local instance = EventsFolder:FindFirstChild(name) or EventsFolder:FindFirstChild(name, true)
	if instance then
		return instance
	end
	local ok, waited = pcall(function()
		return EventsFolder:WaitForChild(name, 10)
	end)
	return ok and waited or nil
end

local function remoteAvailable(name, className)
	if not EventsFolder then
		return false
	end
	local remote = EventsFolder:FindFirstChild(name)
	return remote ~= nil and remote:IsA(className)
end

local function findRemote(name, className)
	if not EventsFolder then
		return nil
	end
	local remote = EventsFolder:FindFirstChild(name)
	if remote and remote:IsA(className) then
		return remote
	end
	return nil
end

local function fireRemote(name, ...)
	local remote = findRemote(name, "RemoteEvent")
	if not remote then
		return false
	end
	local args = table.pack(...)
	return (pcall(function()
		remote:FireServer(table.unpack(args, 1, args.n))
	end))
end

local function callRemote(name, ...)
	local remote = findRemote(name, "RemoteFunction")
	if not remote then
		return false, "remote unavailable"
	end
	local args = table.pack(...)
	local results = table.pack(pcall(function()
		return remote:InvokeServer(table.unpack(args, 1, args.n))
	end))
	if not results[1] then
		return false, "remote rejected"
	end
	return true, table.unpack(results, 2, results.n)
end

local ModulesFolder = find(ReplicatedStorage, "Modules")
local moduleCache = {}

local function requireGameModule(name)
	if moduleCache[name] ~= nil then
		local cached = moduleCache[name]
		return cached or nil
	end
	local module = ModulesFolder and ModulesFolder:FindFirstChild(name)
	if not module or not module:IsA("ModuleScript") then
		moduleCache[name] = false
		return nil
	end
	local ok, result = pcall(require, module)
	if not ok or type(result) ~= "table" then
		moduleCache[name] = false
		return nil
	end
	moduleCache[name] = result
	return result
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsDescendantOf(Workspace) then
		return root
	end
	return nil
end

local function safePivot(instance)
	if not instance then
		return nil
	end
	local ok, pivot = pcall(instance.GetPivot, instance)
	if ok and pivot then
		return pivot.Position
	end
	return nil
end

local function positionOf(instance)
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance.Position
	end
	local ok, pivot = pcall(function()
		return instance:GetPivot()
	end)
	if ok and typeof(pivot) == "CFrame" then
		return pivot.Position
	end
	return nil
end

local function isRunning()
	return session.running
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function queueNotify(text, duration)
	if not isRunning() then
		return
	end
	table.insert(state.notifications, {text = tostring(text), time = duration or 5})
	if #state.notifications > 12 then
		table.remove(state.notifications, 1)
	end
end

local function getCash()
	local stats = LocalPlayer:FindFirstChild("stats")
	local money = stats and stats:FindFirstChild("Money")
	return money and tonumber(money.Value) or 0
end

local function getMaxEggs()
	local plotConfig = requireGameModule("PlotConfigurations")
	local value = plotConfig and plotConfig.MaxEggsOnPlot
	return tonumber(value) or 30
end

local function getPlotCapacity(force)
	local stamp = tonumber(state.capacityStamp) or 0
	if not force then
		local cached = tonumber(state.plotCapacity) or 0
		if cached > 0 and os.clock() - stamp < 20 then
			return state.plotCapacity
		end
	end
	local ok, value = callRemote("GetPlotCapacity")
	if ok and tonumber(value) then
		state.plotCapacity = tonumber(value)
		state.capacityStamp = os.clock()
	end
	return state.plotCapacity or 0
end

local function isCarryingEgg()
	local character = getCharacter()
	return character ~= nil and character:GetAttribute("CarryingEgg") == true
end

local function getPlot()
	return Workspace:FindFirstChild("Plot_" .. LocalPlayer.Name)
end

local function getPlotPart()
	local plot = getPlot()
	local part = plot and plot:FindFirstChild("EggHatch")
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function listPlotItems()
	local plotPart = getPlotPart()
	local eggs, pets = {}, {}
	if not plotPart then
		return eggs, pets
	end
	for _, child in ipairs(plotPart:GetChildren()) do
		if child:IsA("Model") then
			if child:GetAttribute("IsEgg") == true then
				table.insert(eggs, child)
			elseif child:GetAttribute("ItemUUID") then
				table.insert(pets, child)
			end
		end
	end
	return eggs, pets
end

local RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Secret", "Divine", "Eternal", "Cosmic", "Hacker"}
local RARITY_RANK = {}
for index, rarity in ipairs(RARITY_LIST) do
	RARITY_RANK[rarity] = index
end

local function toSet(value)
	local set = {}
	if type(value) == "table" then
		for key, entry in pairs(value) do
			if entry == true and type(key) == "string" then
				set[key] = true
			elseif type(entry) == "string" then
				set[entry] = true
			end
		end
	end
	return set
end

local function isEggDrop(name)
	if type(name) ~= "string" then
		return false
	end
	local eggConfig = requireGameModule("EggConfigurations")
	if not eggConfig or type(eggConfig.EggDrops) ~= "table" then
		return false
	end
	return eggConfig.EggDrops[name] ~= nil
end

local function rarityOf(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local animalModule = requireGameModule("AnimalConfigurations")
	local animals = animalModule and type(animalModule.Animals) == "table" and animalModule.Animals or nil
	if not animals then
		return nil
	end
	local entry = animals[name]
	if type(entry) == "table" and type(entry.Rarity) == "string" then
		return entry.Rarity
	end
	local eggModule = requireGameModule("EggConfigurations")
	local drops = eggModule and type(eggModule.EggDrops) == "table" and eggModule.EggDrops or nil
	if type(drops) ~= "table" then
		return nil
	end
	local drop = drops[name]
	if type(drop) ~= "table" then
		return nil
	end
	local best
	for key in pairs(drop) do
		local animal = animals[key]
		local rarity = type(animal) == "table" and animal.Rarity or nil
		if type(rarity) == "string" and (not best or (RARITY_RANK[rarity] or 0) > (RARITY_RANK[best] or 0)) then
			best = rarity
		end
	end
	return best
end

local function listInventoryTools()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local character = getCharacter()
	local tools = {}
	local function collect(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") then
				local name = child:GetAttribute("OriginalName")
				if type(name) == "string" then
					table.insert(tools, {Tool = child, Name = name, IsEgg = isEggDrop(name), Rarity = rarityOf(name)})
				end
			end
		end
	end
	collect(backpack)
	collect(character)
	return tools
end

local function zoneDisplayName(zone)
	local zoneConfig = requireGameModule("ZoneConfigurations")
	local entry = zoneConfig and zoneConfig[zone]
	if type(entry) == "table" and type(entry.DisplayName) == "string" then
		return entry.DisplayName
	end
	return zone
end

local function getZoneChoices()
	local labels, map = {}, {}
	local zones = {}
	local eggsFolder = Workspace:FindFirstChild("Eggs")
	if eggsFolder then
		for _, child in ipairs(eggsFolder:GetChildren()) do
			if child:IsA("Folder") and child.Name:match("^Zone%d+$") then
				table.insert(zones, child.Name)
			end
		end
	end
	if #zones == 0 then
		local zoneConfig = requireGameModule("ZoneConfigurations")
		if type(zoneConfig) == "table" then
			for key in pairs(zoneConfig) do
				if type(key) == "string" and key:match("^Zone%d+$") then
					table.insert(zones, key)
				end
			end
		end
	end
	table.sort(zones, function(a, b)
		return (tonumber(a:match("%d+")) or 0) < (tonumber(b:match("%d+")) or 0)
	end)
	for _, zone in ipairs(zones) do
		local label = zone:gsub("Zone", "Zone ") .. " - " .. zoneDisplayName(zone)
		table.insert(labels, label)
		map[label] = zone
	end
	return labels, map
end

local function suitList()
	local suitModule = requireGameModule("SuitConfigurations")
	if not suitModule or type(suitModule.Suits) ~= "table" then
		return {}
	end
	local suits = {}
	for _, suit in ipairs(suitModule.Suits) do
		if type(suit) == "table" and type(suit.Name) == "string" then
			table.insert(suits, {Name = suit.Name, Price = tonumber(suit.Price) or 0})
		end
	end
	table.sort(suits, function(a, b)
		return a.Price < b.Price
	end)
	return suits
end

local function ownedSuits()
	local ok, result = callRemote("SuitShopAction", "GetData")
	if ok and type(result) == "table" and type(result.Owned) == "table" then
		return result.Owned
	end
	return nil
end

local function treadmillList()
	local treadmillModule = requireGameModule("TreadmillConfigurations")
	if not treadmillModule or type(treadmillModule.Treadmills) ~= "table" then
		return {}
	end
	local treadmills = {}
	for name, entry in pairs(treadmillModule.Treadmills) do
		if type(entry) == "table" and tonumber(entry.Price) then
			table.insert(treadmills, {Name = name, Price = tonumber(entry.Price)})
		end
	end
	table.sort(treadmills, function(a, b)
		return a.Price < b.Price
	end)
	return treadmills
end

local function nextTreadmill()
	local equipped = LocalPlayer:GetAttribute("EquippedTreadmill")
	if type(equipped) ~= "string" then
		local ok, value = callRemote("GetEquippedTreadmill")
		local valid = ok and type(value) == "string"
		equipped = valid and value or nil
	end
	local after = equipped == nil
	for _, treadmill in ipairs(treadmillList()) do
		if after then
			return treadmill
		end
		if treadmill.Name == equipped then
			after = true
		end
	end
	return nil
end

local function getEquippedTreadmillName()
	local equipped = LocalPlayer:GetAttribute("EquippedTreadmill")
	if type(equipped) == "string" then
		return equipped
	end
	return nil
end

local function hatchTimeFor(egg)
	local override = tonumber(egg:GetAttribute("HatchTimeOverride"))
	if override then
		return override
	end
	local eggConfig = requireGameModule("EggConfigurations")
	local sizeSystem = requireGameModule("EggSizeSystem")
	if not eggConfig or not sizeSystem or type(sizeSystem.GetHatchTime) ~= "function" then
		return nil
	end
	local settingsEntry = type(eggConfig.EggSettings) == "table" and eggConfig.EggSettings[egg:GetAttribute("OriginalName")]
	local entry = settingsEntry or nil
	local base = entry and tonumber(entry.HatchTime) or 5
	local size = egg:GetAttribute("EggSize") or "Normal"
	local ok, value = pcall(sizeSystem.GetHatchTime, base, size)
	if not ok or not tonumber(value) then
		return nil
	end
	local multiplier = 1
	local events = requireGameModule("GlobalEvents")
	if type(events) == "table" and type(events.GetHatchMultiplier) == "function" then
		local okMultiplier, result = pcall(events.GetHatchMultiplier)
		if okMultiplier and tonumber(result) and tonumber(result) > 0 then
			multiplier = tonumber(result)
		end
	end
	return tonumber(value) / multiplier
end

local function isEggReady(egg)
	local shell = egg:FindFirstChild("Shell")
	local prompt = shell and shell:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt and prompt.Enabled and prompt.ActionText == "Hatch" then
		return true
	end
	local hatchTime = hatchTimeFor(egg)
	if not hatchTime then
		return false
	end
	local started = tonumber(egg:GetAttribute("HatchStartTime")) or 0
	return Workspace:GetServerTimeNow() - started >= hatchTime
end

local function eggPrompt(model)
	local anchor = model:FindFirstChild("PromptAnchor", true)
	local prompt = anchor and anchor:FindFirstChildWhichIsA("ProximityPrompt")
	return prompt or nil
end

local function wildEggCandidates(zones, rarities)
	local list = {}
	local eggsFolder = Workspace:FindFirstChild("Eggs")
	if not eggsFolder then
		return list
	end
	local zoneFilter = zones and next(zones) ~= nil
	local rarityFilter = rarities and next(rarities) ~= nil
	for _, folder in ipairs(eggsFolder:GetChildren()) do
		local inZone = folder:IsA("Folder")
		if inZone then
			inZone = not zoneFilter or zones[folder.Name]
		end
		if inZone then
			for _, child in ipairs(folder:GetChildren()) do
				local egg = child:FindFirstChild("SpawnedEgg")
				local prompt = egg and eggPrompt(egg)
				local usable = prompt
				if usable then
					usable = prompt.Enabled
				end
				if usable then
					local eggName = egg:GetAttribute("EggName")
					local rarity = rarityOf(eggName)
					local matches = not rarityFilter
					if not matches then
						matches = rarity and rarities[rarity]
					end
					if matches then
						local position = positionOf(egg)
						if position then
							table.insert(list, {Model = egg, Prompt = prompt, Position = position, Name = tostring(eggName or "Egg"), Rarity = rarity})
						end
					end
				end
			end
		end
	end
	return list
end

local function closestCandidate(list)
	local root = getRoot()
	local origin = root and root.Position or Vector3.zero
	local best, bestDistance
	for _, entry in ipairs(list) do
		local distance = (entry.Position - origin).Magnitude
		if not bestDistance or distance < bestDistance then
			best, bestDistance = entry, distance
		end
	end
	return best, bestDistance or 0
end

local function randomPlotPoint()
	local plotPart = getPlotPart()
	if not plotPart then
		return nil
	end
	local half = plotPart.Size * 0.5
	local rangeX = math.max(half.X - 6, 1)
	local rangeZ = math.max(half.Z - 6, 1)
	local offset = Vector3.new((math.random() * 2 - 1) * rangeX, half.Y, (math.random() * 2 - 1) * rangeZ)
	return plotPart.Position + offset
end

local function sellNpcPart()
	local sellNpc = Workspace:FindFirstChild("SellNPC")
	local part = sellNpc and sellNpc:FindFirstChild("ProxPart")
	if part and part:IsA("BasePart") then
		return part
	end
	return nil
end

local function firePromptSafe(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
		return false
	elseif type(fireproximityprompt) ~= "function" then
		return false
	else
		return (pcall(fireproximityprompt, prompt))
	end
end

local function equipTool(tool)
	local humanoid = getHumanoid()
	if not humanoid or not tool then
		return false
	elseif tool.Parent == getCharacter() then
		return true
	else
		return (pcall(function()
			humanoid:EquipTool(tool)
		end))
	end
end

local function warpTo(position, yOffset)
	if typeof(position) ~= "Vector3" then
		return false
	end
	local root = getRoot()
	if not root then
		return false
	end
	local target = position + Vector3.new(0, yOffset or 4, 0)
	return (pcall(function()
		root.CFrame = CFrame.new(target)
		root.AssemblyLinearVelocity = Vector3.zero
	end))
end

local function moveLock(body)
	local deadline = os.clock() + 8
	while state.moveBusy and isRunning() and os.clock() < deadline do
		task.wait(0.1)
	end
	if not isRunning() then
		return false
	end
	if state.moveBusy then
		if os.clock() - (state.moveStamp or 0) < 60 then
			return false
		end
		state.moveBusy = false
	end
	state.moveBusy = true
	state.moveStamp = os.clock()
	local ok, result = pcall(body)
	state.moveBusy = false
	if not ok then
		warn("[AntiGodHub] movement error: " .. tostring(result))
		return false
	end
	return result
end

local DELIVERY_POINT = Vector3.new(31, 3, 134)

local function deliverInstant()
	if not isCarryingEgg() then
		return false
	end
	setFarmStatus("Delivering")
	if not warpTo(DELIVERY_POINT, 0) then
		return false
	end
	local deadline = os.clock() + 4
	while isRunning() and isCarryingEgg() and os.clock() < deadline do
		warpTo(DELIVERY_POINT, 0)
		task.wait(0.2)
	end
	return not isCarryingEgg()
end

local stealSystem = {
	mode = "Instant",
	tweenSpeed = 500,
	zones = {},
	rarities = {},
	float = {active = false},
}

stealSystem.BeginFloat = function()
	local f = stealSystem.float
	if f.active then
		return true
	end
	local character = getCharacter()
	local root = getRoot()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local _, yaw = root.CFrame:ToOrientation()
	f.active = true
	f.root = root
	f.humanoid = humanoid
	f.character = character
	f.yaw = yaw
	f.rot = CFrame.Angles(0, yaw, 0)
	f.pos = root.Position
	f.goal = root.Position
	f.arrived = true
	f.speedNow = 0
	f.prevPlatformStand = humanoid.PlatformStand
	f.collide = {}
	humanoid.PlatformStand = true
	f.conn = RunService.Stepped:Connect(function(_, dt)
		if not f.active then
			return
		end
		if not isRunning() or not root.Parent or humanoid.Health <= 0 or LocalPlayer.Character ~= character then
			stealSystem.EndFloat()
			return
		end
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if f.collide[part] == nil then
					f.collide[part] = part.CanCollide
				end
				part.CanCollide = false
			end
		end
		humanoid.PlatformStand = true
		local speed = math.max(stealSystem.tweenSpeed, 5)
		local delta = f.goal - f.pos
		local dist = delta.Magnitude
		if dist > 0.05 then
			f.speedNow = math.min(speed, f.speedNow + speed * dt * 4)
			local cap = math.max(dist * 6, 10)
			local step = math.min(f.speedNow, cap) * dt
			if step >= dist then
				f.pos = f.goal
				f.arrived = true
			else
				f.pos = f.pos + delta.Unit * step
				f.arrived = false
			end
			if math.sqrt(delta.X * delta.X + delta.Z * delta.Z) > 1 then
				f.yaw = math.atan2(-delta.X, -delta.Z)
			end
		else
			f.pos = f.goal
			f.arrived = true
			f.speedNow = 0
		end
		f.rot = CFrame.Angles(0, f.yaw, 0)
		root.CFrame = CFrame.new(f.pos) * f.rot
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	return true
end

stealSystem.EndFloat = function()
	local f = stealSystem.float
	if not f.active then
		return
	end
	f.active = false
	if f.conn then
		f.conn:Disconnect()
		f.conn = nil
	end
	for part, value in pairs(f.collide or {}) do
		if part.Parent then
			part.CanCollide = value
		end
	end
	local root, humanoid = f.root, f.humanoid
	if root and root.Parent then
		root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, f.yaw or 0, 0)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = f.prevPlatformStand == true
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
end

stealSystem.MoveTo = function(target, tween, cancel)
	if not tween then
		warpTo(target, 0)
		RunService.Heartbeat:Wait()
		return true
	end
	local f = stealSystem.float
	if not f.active then
		return false
	end
	f.goal = target
	f.arrived = false
	local deadline = os.clock() + 120
	while isRunning() and features.steal.on and f.active and not f.arrived and os.clock() < deadline do
		if cancel and cancel() then
			f.goal = f.pos
			return false
		end
		RunService.Heartbeat:Wait()
	end
	return f.arrived
end

stealSystem.FirePrompt = function(prompt, attempt)
	pcall(function()
		prompt:InputHoldBegin()
		task.wait(0.08)
		prompt:InputHoldEnd()
	end)
	firePromptSafe(prompt)
end

stealSystem.Grab = function(egg, tween)
	local prompt = egg.Prompt
	local saved
	pcall(function()
		saved = {
			HoldDuration = prompt.HoldDuration,
			MaxActivationDistance = prompt.MaxActivationDistance,
			RequiresLineOfSight = prompt.RequiresLineOfSight,
		}
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 20)
		prompt.RequiresLineOfSight = false
	end)

	local deadline = os.clock() + 10
	local attempt = 0
	local gone = false
	while isRunning() and features.steal.on and os.clock() < deadline do
		if isCarryingEgg() then
			break
		end
		if not egg.Model.Parent or not prompt.Parent or not prompt.Enabled then
			gone = true
			break
		end
		attempt += 1
		local pos = positionOf(egg.Model) or egg.Position
		local target = pos + Vector3.new(0, 1.5, 0)
		if tween then
			stealSystem.MoveTo(target, true, function()
				return isCarryingEgg() or not egg.Model.Parent
			end)
		else
			local root = getRoot()
			if not root or (root.Position - target).Magnitude > 2.5 then
				warpTo(target, 0)
				task.wait(0.2)
			end
		end
		if isCarryingEgg() then
			break
		end
		if egg.Model.Parent and prompt.Parent and prompt.Enabled then
			stealSystem.FirePrompt(prompt, attempt)
		end
		local untilTime = os.clock() + 0.15
		while isRunning() and features.steal.on and os.clock() < untilTime and not isCarryingEgg() do
			task.wait(0.03)
		end
	end

	if saved then
		pcall(function()
			if prompt.Parent then
				prompt.HoldDuration = saved.HoldDuration
				prompt.MaxActivationDistance = saved.MaxActivationDistance
				prompt.RequiresLineOfSight = saved.RequiresLineOfSight
			end
		end)
	end
	return isCarryingEgg(), gone
end

stealSystem.Deliver = function(tween)
	if not isCarryingEgg() then
		return false
	end
	if not tween then
		return deliverInstant()
	end
	if not stealSystem.BeginFloat() then
		return false
	end
	setFarmStatus("Delivering")
	stealSystem.MoveTo(DELIVERY_POINT, true, function()
		return not isCarryingEgg()
	end)
	stealSystem.EndFloat()
	local untilTime = os.clock() + 5
	local round = 0
	while isRunning() and features.steal.on and isCarryingEgg() and os.clock() < untilTime do
		round += 1
		local nudge = (round % 3 == 0) and Vector3.new(1.5, 0, 0) or (round % 3 == 2) and Vector3.new(-1.5, 0, 0) or Vector3.zero
		warpTo(DELIVERY_POINT + nudge, 0)
		task.wait(0.25)
	end
	return not isCarryingEgg()
end

stealSystem.Steal = function(egg, tween)
	if not egg.Model.Parent then
		return false
	end
	if tween and not stealSystem.BeginFloat() then
		return false
	end
	setFarmStatus("Stealing egg [" .. tostring(egg.Rarity or "?") .. "]")
	local pos = positionOf(egg.Model) or egg.Position
	stealSystem.MoveTo(pos + Vector3.new(0, 3, 0), tween, function()
		return isCarryingEgg() or not egg.Model.Parent or not egg.Prompt.Enabled
	end)
	local carrying, gone = stealSystem.Grab(egg, tween)
	if not carrying then
		setFarmStatus(gone and "Egg taken" or "Retrying")
		return false
	end
	return stealSystem.Deliver(tween)
end

local function doAutoSteal()
	local tween = config.stealMode == "Tween"
	if isCarryingEgg() then
		moveLock(function()
			local ok, result = pcall(stealSystem.Deliver, tween)
			stealSystem.EndFloat()
			if not ok then
				warn("[AntiGodHub] steal error: " .. tostring(result))
				state.stealMiss = {}
				return false
			end
			return result
		end)
		return
	end
	local candidates = wildEggCandidates(stealSystem.zones, stealSystem.rarities)
	local now = tick()
	for model, missUntil in pairs(state.stealMiss) do
		if now >= missUntil then
			state.stealMiss[model] = nil
		end
	end
	local pool = {}
	for _, entry in ipairs(candidates) do
		if not state.stealMiss[entry.Model] then
			table.insert(pool, entry)
		end
	end
	if #pool == 0 then
		if #candidates == 0 then
			setFarmStatus("idle")
			task.wait(0.4)
		end
		return
	end
	local target = closestCandidate(pool)
	if not target then
		return
	end
	moveLock(function()
		local ok, result = pcall(stealSystem.Steal, target, tween)
		stealSystem.EndFloat()
		if not ok then
			warn("[AntiGodHub] steal error: " .. tostring(result))
			state.stealMiss[target.Model] = tick() + 5
			return false
		end
		if result == true then
			state.stealMiss[target.Model] = nil
		else
			state.stealMiss[target.Model] = tick() + 4
		end
		return result
	end)
end

local function doAutoPlace()
	local plotPart = getPlotPart()
	if not plotPart then
		setFarmStatus("Plot not loaded")
		return
	end
	local tools = listInventoryTools()
	if #tools == 0 then
		return
	end
	local filterRarities = next(config.placeRarities) ~= nil
	local eggs = listPlotItems()
	local remaining = getMaxEggs() - #eggs
	local stuck = false
	local placed = 0
	moveLock(function()
		local pos = positionOf(plotPart)
		if pos then
			if not warpTo(pos, 8) then
				return false
			end
		end
		task.wait(0.3)
		for _, tool in ipairs(tools) do
			if not isRunning() or not features.place.on or stuck then
				break
			end
			if tool.Tool.Parent then
				local allowed = true
				if filterRarities then
					allowed = tool.Rarity and config.placeRarities[tool.Rarity] or false
				end
				if allowed and not (tool.IsEgg and remaining <= 0) then
					local dropPos = randomPlotPoint()
					if dropPos and equipTool(tool.Tool) then
						task.wait(0.15)
						if fireRemote("PlaceItemAtCursor", dropPos) then
							task.wait(0.45)
							if tool.Tool.Parent then
								stuck = true
							else
								placed += 1
								if tool.IsEgg then
									remaining -= 1
								end
							end
						end
					end
				end
			end
		end
		return true
	end)
	if placed > 0 then
		getPlotCapacity(true)
		setFarmStatus("Placed " .. placed)
	elseif stuck or remaining <= 0 then
		setFarmStatus("Plot full")
	end
end

local function doAutoHatch()
	local eggs = listPlotItems()
	local hatched = 0
	for _, egg in ipairs(eggs) do
		if not isRunning() or not features.hatch.on then
			break
		end
		if egg.Parent and isEggReady(egg) then
			if fireRemote("RequestHatch", egg) then
				hatched += 1
				task.wait(0.35)
			end
		end
	end
	if hatched > 0 then
		setFarmStatus("Hatched " .. hatched)
	end
end

local function doAutoEquipBest()
	if fireRemote("EquipBestPets") then
		setFarmStatus("Equipped best")
	end
end

local function doAutoIndexClaims()
	local okData, discovered = callRemote("GetIndexData")
	if not okData or type(discovered) ~= "table" then
		return
	end
	local okClaims, claims = callRemote("IndexRewardAction", "GetClaims")
	if not okClaims or type(claims) ~= "table" then
		claims = {}
	end
	local animalModule = requireGameModule("AnimalConfigurations")
	local animals = animalModule and type(animalModule.Animals) == "table" and animalModule.Animals or nil
	if not animals then
		return
	end
	local claimed = 0
	for key, value in pairs(discovered) do
		if not isRunning() or not features.index.on then
			break
		end
		if value == true and claims[key] ~= true and animals[key] then
			local okClaim, result = callRemote("IndexRewardAction", "Claim", key)
			if okClaim and type(result) == "table" and result.Success then
				claimed += 1
				task.wait(0.2)
			end
		end
	end
	if claimed > 0 then
		local text = "Claimed " .. claimed
		queueNotify(text)
		setFarmStatus(text)
	end
end

local function doAutoBuySuits()
	local owned = ownedSuits()
	if not owned then
		return
	end
	local cash = getCash()
	for _, suit in ipairs(suitList()) do
		if not isRunning() or not features.suits.on then
			break
		end
		if owned[suit.Name] ~= true and suit.Price > 0 then
			if cash >= suit.Price then
				local ok, result = callRemote("SuitShopAction", "Buy", suit.Name)
				if ok and result then
					queueNotify("Bought " .. suit.Name)
					setFarmStatus("Bought " .. suit.Name)
					cash = getCash()
					task.wait(0.4)
				end
			end
		end
	end
end

local function doAutoSell()
	local mode = config.sellMode == "Equipped" and "Equipped" or "Inventory"
	if mode == "Inventory" then
		if #listInventoryTools() < config.sellMinimum then
			return
		end
	else
		local _, pets = listPlotItems()
		if #pets < config.sellMinimum then
			return
		end
	end
	local ok = moveLock(function()
		if config.travelToSeller then
			local npc = sellNpcPart()
			local pos = npc and npc.Position or nil
			if pos then
				if not warpTo(pos, 4) then
					return false
				end
			end
			task.wait(0.3)
			return fireRemote("RequestSell", mode)
		end
		return fireRemote("RequestSell", mode)
	end)
	if ok then
		setFarmStatus("Sold")
	end
end

local function doAutoTreadmill()
	local treadmill = nextTreadmill()
	if not treadmill then
		setFarmStatus("Treadmill maxed")
		return
	end
	if getCash() < treadmill.Price then
		return
	end
	local ok, result = callRemote("RequestTreadmillUpgrade")
	if ok and type(result) == "table" and result.Success then
		queueNotify("Upgraded to " .. treadmill.Name)
		setFarmStatus("Upgraded")
	end
end

local function doAutoPetSlots()
	local plotConfig = requireGameModule("PlotConfigurations")
	local count = getPlotCapacity(true)
	if count <= 0 then
		return
	end
	local maxSlots = plotConfig and plotConfig.MaxSlots
	local max = tonumber(maxSlots) or 0
	if max > 0 and count >= max then
		setFarmStatus("Slots maxed")
		return
	end
	local price
	if plotConfig and type(plotConfig.Upgrades) == "table" then
		price = tonumber(plotConfig.Upgrades[count + 1])
	end
	if price and getCash() < price then
		return
	end
	local ok, result = callRemote("RequestPlotUpgrade")
	if ok and type(result) == "table" and result.Success then
		getPlotCapacity(true)
		queueNotify("Unlocked pet slot " .. tostring(count + 1))
		setFarmStatus("Slot " .. tostring(count + 1))
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
local function setAntiAfk(state)
	if state and not afkConnection then
		afkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	elseif not state and afkConnection then
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
local function setFpsBoost(state)
	if state and not fpsOriginals then
		fpsOriginals = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			Brightness = Lighting.Brightness,
		}
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
		Lighting.Brightness = 1
		RenderSettings.Rendering.QualityLevel = 1
		end)
	elseif not state and fpsOriginals then
		pcall(function()
			Lighting.GlobalShadows = fpsOriginals.GlobalShadows
			Lighting.FogEnd = fpsOriginals.FogEnd
			Lighting.Brightness = fpsOriginals.Brightness
		end)
		fpsOriginals = nil
	end
end

local function setGameplayPause(blocked)
	pcall(function()
		GuiService:SetGameplayPausedNotificationEnabled(not blocked)
	end)
	pcall(function()
		local gui = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
		if gui then
			gui.Enabled = not blocked
		end
	end)
	if not blocked then
		return
	end
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(LocalPlayer, "GameplayPaused", false)
		else
			LocalPlayer.GameplayPaused = false
		end
	end)
end

local savedCollide, savedSpeed, savedPlatform, savedPrompts = {}, {}, {}, {}

local function restoreCollide()
	for part, value in savedCollide do
		if part.Parent then
			part.CanCollide = value
		end
	end
	table.clear(savedCollide)
end

local function restoreSpeed()
	for humanoid, value in savedSpeed do
		if humanoid.Parent then
			humanoid.WalkSpeed = value
		end
	end
	table.clear(savedSpeed)
end

local function restorePlatform()
	for humanoid, value in savedPlatform do
		if humanoid.Parent then
			humanoid.PlatformStand = value
		end
	end
	table.clear(savedPlatform)
end

local function patchPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then
		return
	end
	if savedPrompts[prompt] == nil then
		savedPrompts[prompt] = {
			HoldDuration = prompt.HoldDuration,
			MaxActivationDistance = prompt.MaxActivationDistance,
			RequiresLineOfSight = prompt.RequiresLineOfSight,
		}
	end
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 50
	prompt.RequiresLineOfSight = false
end

local function restorePrompts()
	for prompt, value in savedPrompts do
		if prompt.Parent then
			prompt.HoldDuration = value.HoldDuration
			prompt.MaxActivationDistance = value.MaxActivationDistance
			prompt.RequiresLineOfSight = value.RequiresLineOfSight
		end
	end
	table.clear(savedPrompts)
end

local reconnecting = false

local function tryReconnect(forceNewServer)
	if reconnecting or not isRunning() or not enabled.autoReconnect then
		return
	end
	reconnecting = true
	local ok = pcall(function()
		if forceNewServer then
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end
	end)
	if not ok then
		reconnecting = false
		if not forceNewServer then
			task.delay(1.5, function()
				if isRunning() and enabled.autoReconnect then
					tryReconnect(true)
				end
			end)
		end
	end
end

local playerConnections = {}
local settingsConnections = {}

local function selectedMulti(flag, value)
	local option = Options[flag]
	if option and type(option.Value) == "table" then
		return option.Value
	end
	if type(value) == "table" then
		return value
	end
	return {}
end

local function withAny(list)
	local values = { "Any" }
	for _, value in ipairs(list) do
		table.insert(values, value)
	end
	return values
end

local zoneLabels, zoneMap = getZoneChoices()

local execName, execVersion
if identifyexecutor then
	local ok, name, version = pcall(identifyexecutor)
	if ok and type(name) == "string" and name ~= "" then
		execName = name
		execVersion = type(version) == "string" and version ~= "" and (name .. " " .. version) or name
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

do
	local function universeIdForPlace(placeId)
		local ok, body = pcall(function()
			return game:HttpGet("https://apis.roblox.com/universes/v1/places/" .. tostring(placeId) .. "/universe")
		end)
		if ok and type(body) == "string" then
			local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, body)
			if okDecode and type(decoded) == "table" then
				return tonumber(decoded.universeId)
			end
		end
		return nil
	end
	local function gameNameForUniverse(universeId)
		local ok, body = pcall(function()
			return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(universeId))
		end)
		if ok and type(body) == "string" then
			local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, body)
			if okDecode and type(decoded) == "table" and type(decoded.data) == "table" and decoded.data[1] then
				local name = decoded.data[1].name
				if type(name) == "string" and name ~= "" then
					return name
				end
			end
		end
		return nil
	end
	task.spawn(function()
		local universeId = universeIdForPlace(game.PlaceId)
		if not universeId then
			return
		end
		local name = gameNameForUniverse(universeId)
		if name then
			pcall(function()
				setLabel("GameNameLabel", paint("Game -", name, COLORS.accent))
			end)
		end
	end)
end

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

local EggsTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "egg" })
local MoneyTab = Tabs.Main:AddSubTab({ Name = "Cash", Icon = "dollar-sign" })
local UpgradesTab = Tabs.Main:AddSubTab({ Name = "Upgrades", Icon = "trending-up" })

local StealBox = box(EggsTab, "Egg", "egg", "Left")
StealBox:AddToggle("AutoSteal", { Text = "Auto Steal Egg", Default = false, Callback = function(value)
	enabled.autoSteal = value
	features.steal.on = value
end })
StealBox:AddDropdown("StealZones", {
	Text = "Zones",
	Values = withAny(zoneLabels),
	Default = { "Any" },
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
	Callback = function()
		local picked = toSet(selectedMulti("StealZones"))
		config.stealZones = picked
		if picked.Any then
			stealSystem.zones = {}
			return
		end
		local zones = {}
		for label in pairs(picked) do
			zones[zoneMap[label] or label] = true
		end
		stealSystem.zones = zones
	end,
})
StealBox:AddDropdown("StealRarities", {
	Text = "Rarities",
	Values = withAny(RARITY_LIST),
	Default = { "Any" },
	Multi = true,
	SelectAllButtons = true,
	Callback = function()
		local picked = toSet(selectedMulti("StealRarities"))
		if picked.Any then
			picked = {}
		end
		config.stealRarities = picked
		stealSystem.rarities = picked
	end,
})
StealBox:AddDropdown("StealMode", {
	Text = "Steal Mode",
	Values = { "Instant", "Tween" },
	Default = "Instant",
	Callback = function(value)
		config.stealMode = tostring(value) == "Tween" and "Tween" or "Instant"
		stealSystem.mode = config.stealMode
	end,
})
StealBox:AddSlider("TweenSpeed", {
	Text = "Tween Speed (studs/s)",
	Min = 10,
	Max = 2000,
	Default = 500,
	Increment = 10,
	Callback = function(value)
		config.tweenSpeed = tonumber(value) or 500
		stealSystem.tweenSpeed = math.clamp(config.tweenSpeed, 5, 2000)
	end,
})

local StatusBox = box(EggsTab, "Status", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("EggsLabel", { Text = paint("Eggs -", "0/30", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("PetsLabel", { Text = paint("Pets -", "0/0", COLORS.user), DoesWrap = true })

local PetsBox = box(EggsTab, "Pets", "paw-print", "Right")
PetsBox:AddToggle("AutoPlace", { Text = "Auto Place Best Egg", Default = false, Callback = function(value)
	enabled.autoPlace = value
	features.place.on = value
end })
PetsBox:AddDropdown("PlaceRarities", {
	Text = "Place Rarities",
	Values = withAny(RARITY_LIST),
	Default = { "Any" },
	Multi = true,
	SelectAllButtons = true,
	Callback = function()
		local picked = toSet(selectedMulti("PlaceRarities"))
		if picked.Any then
			picked = {}
		end
		config.placeRarities = picked
	end,
})
PetsBox:AddToggle("AutoEquipBest", { Text = "Auto Equip Best Pets", Default = false, Callback = function(value)
	enabled.autoEquipBest = value
	features.equipBest.on = value
end })
PetsBox:AddToggle("AutoHatch", { Text = "Auto Hatch Egg", Default = false, Callback = function(value)
	enabled.autoHatch = value
	features.hatch.on = value
end })

local SellBox = box(MoneyTab, "Auto Sell", "coins", "Left")
SellBox:AddToggle("AutoSell", { Text = "Auto Sell", Default = false, Callback = function(value)
	enabled.autoSell = value
	features.sell.on = value
end })
SellBox:AddDropdown("SellMode", {
	Text = "Sell Mode",
	Values = { "Any", "Inventory", "Equipped" },
	Default = "Any",
	Callback = function(value)
		config.sellMode = tostring(value) == "Equipped" and "Equipped" or "Inventory"
	end,
})

local MoneyStatus = box(MoneyTab, "Money", "banknote", "Right")
MoneyStatus:AddLabel("CashLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })

local ProgressBox = box(UpgradesTab, "Progression", "gauge", "Left")
ProgressBox:AddToggle("AutoIndex", { Text = "Auto Claim Index", Default = false, Callback = function(value)
	enabled.autoIndex = value
	features.index.on = value
end })
ProgressBox:AddToggle("AutoTreadmill", { Text = "Auto Upgrade Treadmill", Default = false, Callback = function(value)
	enabled.autoTreadmill = value
	features.treadmill.on = value
end })
ProgressBox:AddToggle("AutoSlots", { Text = "Auto Upgrade Pet Slots", Default = false, Callback = function(value)
	enabled.autoSlots = value
	features.slots.on = value
end })

local SuitsBox = box(UpgradesTab, "Suits", "award", "Right")
SuitsBox:AddToggle("AutoSuits", { Text = "Auto Buy Suits", Default = false, Callback = function(value)
	enabled.autoSuits = value
	features.suits.on = value
end })

local UpgradeStatus = box(UpgradesTab, "Progress Status", "activity", "Right")
UpgradeStatus:AddLabel("TreadmillLabel", { Text = paint("Treadmill -", "None", COLORS.accent), DoesWrap = true })

table.insert(playerConnections, Workspace.DescendantAdded:Connect(function(instance)
	if not session.running then
		return
	end
	if enabled.instantPrompt then
		pcall(patchPrompt, instance)
	end
end))
table.insert(playerConnections, RunService.Stepped:Connect(function()
	if not session.running then
		return
	end
	local character = getCharacter()
	if enabled.noClip and character then
		for _, part in character:QueryDescendants("BasePart") do
			if savedCollide[part] == nil then
				savedCollide[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end
end))
table.insert(playerConnections, UserInputService.JumpRequest:Connect(function()
	if not session.running then
		return
	end
	local humanoid = getHumanoid()
	if enabled.infJump and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))
table.insert(playerConnections, RunService.RenderStepped:Connect(function(dt)
	if not session.running then
		return
	end
	local character = getCharacter()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera

	if enabled.walkSpeed and humanoid then
		if savedSpeed[humanoid] == nil then
			savedSpeed[humanoid] = humanoid.WalkSpeed
		end
		humanoid.WalkSpeed = config.walkSpeed
	end

	if enabled.fly and root and humanoid and camera then
		if savedPlatform[humanoid] == nil then
			savedPlatform[humanoid] = humanoid.PlatformStand
		end
		humanoid.PlatformStand = true
		local direction = Vector3.zero
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				direction += camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				direction -= camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				direction -= camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				direction += camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				direction += Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				direction -= Vector3.new(0, 1, 0)
			end
		end
		root.AssemblyLinearVelocity = Vector3.zero
		if direction.Magnitude > 0 then
			root.CFrame = root.CFrame + direction.Unit * config.flySpeed * dt
		end
	end
end))

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
ClientBox:AddToggle("AntiAfk", { Text = "Anti AFK", Default = true, Callback = function(value)
	enabled.antiafk = value
	setAntiAfk(value)
end })
ClientBox:AddToggle("NoGameplayPaused", { Text = "No Gameplay Paused", Default = true, Callback = function(value)
	enabled.noPause = value
	setGameplayPause(value)
end })
ClientBox:AddToggle("FpsBoost", { Text = "FPS Boost", Default = false, Callback = function(value)
	enabled.fpsBoost = value
	setFpsBoost(value)
end })
ClientBox:AddToggle("DisableRendering", { Text = "Disable 3D Rendering", Default = false, Callback = function(value)
	enabled.disable3D = value
	setRendering(value)
end })
setAntiAfk(enabled.antiafk)
setGameplayPause(true)

local ServerTools = box(Tabs.Settings, "Server", "server", "Right")
ServerTools:AddButton({ Text = "Reconnect", Func = reconnectServer })
ServerTools:AddButton({ Text = "Rejoin Server", Func = rejoinServer })
ServerTools:AddButton({ Text = "Server Hop (Lowest Players)", Func = serverHop })

local RecoveryBox = box(Tabs.Settings, "Recovery", "refresh-cw", "Right")
RecoveryBox:AddToggle("AutoReconnect", { Text = "Auto Reconnect on Kick", Default = false, Callback = function(value)
	enabled.autoReconnect = value
end })

table.insert(settingsConnections, TeleportService.TeleportInitFailed:Connect(function(player)
	if player == LocalPlayer and enabled.autoReconnect then
		reconnecting = false
		task.delay(3, function()
			if isRunning() and enabled.autoReconnect then
				tryReconnect(true)
			end
		end)
	end
end))
task.spawn(function()
	local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 30)
	local overlay = promptGui and promptGui:WaitForChild("promptOverlay", 30)
	if not session.running or not overlay then
		return
	end
	table.insert(settingsConnections, overlay.ChildAdded:Connect(function(child)
		if child.Name == "ErrorPrompt" then
			tryReconnect(false)
		end
	end))
end)

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
	local eggs, pets = listPlotItems()
	setLabel("EggsLabel", paint("Eggs -", string.format("%d/%d", #eggs, getMaxEggs()), COLORS.gold))
	setLabel("PetsLabel", paint("Pets -", string.format("%d/%d", #pets, tonumber(state.plotCapacity) or 0), COLORS.user))
	setLabel("CashLabel", paint("Cash -", abbreviateNumber(getCash()), COLORS.gold))
	setLabel("TreadmillLabel", paint("Treadmill -", getEquippedTreadmillName() or "None", COLORS.accent))
	while #state.notifications > 0 do
		local item = table.remove(state.notifications, 1)
		pcall(function()
			Library:Notify(item.text)
		end)
	end
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	pcall(function()
		state.plotCapacity = getPlotCapacity(true)
	end)
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

local function featureLoop(feature, func)
	task.spawn(function()
		while session.running do
			if feature.on then
				local ok, err = pcall(func)
				if not ok then
					logError(err)
				end
				task.wait(tonumber(feature.interval) or 1)
			else
				task.wait(0.2)
			end
		end
	end)
end

featureLoop(features.steal, doAutoSteal)
featureLoop(features.place, doAutoPlace)
featureLoop(features.hatch, doAutoHatch)
featureLoop(features.equipBest, doAutoEquipBest)
featureLoop(features.index, doAutoIndexClaims)
featureLoop(features.suits, doAutoBuySuits)
featureLoop(features.sell, doAutoSell)
featureLoop(features.treadmill, doAutoTreadmill)
featureLoop(features.slots, doAutoPetSlots)

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
		pcall(refreshLists)
		task.wait(1)
	end
end)

Library:OnUnload(function()
	session.running = false
	for _, feature in pairs(features) do
		feature.on = false
	end
	pcall(stealSystem.EndFloat)
	pcall(setGameplayPause, false)
	pcall(restoreCollide)
	pcall(restoreSpeed)
	pcall(restorePlatform)
	pcall(restorePrompts)
	for _, connection in ipairs(playerConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	for _, connection in ipairs(settingsConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	pcall(setAntiAfk, false)
	pcall(setRendering, false)
	pcall(setFpsBoost, false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()