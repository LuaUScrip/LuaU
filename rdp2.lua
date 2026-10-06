local Repo = "https://raw.githubusercontent.com/LuaUScrip/OK/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local copyText = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request)

local CONFIG = {
	Title = "AntiGodHub",
	Icon = 80985370671515,
	Discord = "https://discord.gg/jdJvZm6VdK",
	Website = "https://rscripts.net/@AntiGodHub",
	Version = "v3.0",
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
	farm = false,
	farmMutations = true,
	weatherWait = false,
	rebirthPet = false,
	rebirthWhenReady = true,
	magmaDip = false,
	hatch = false,
	plant = false,
	spawnNest = false,
	unlockNests = false,
	upgradeLuck = false,
	bestPets = false,
	feed = false,
	esp = false,
	espHighlight = true,
	espLabel = true,
	espTracer = false,
	antiRagdoll = true,
	antiafk = false,
	noPause = false,
	returnPlot = true,
	dropUnwanted = false,
}

local settings = {}

local config = {
	minRarity = "Mythic & Above",
	targetEgg = "Any Egg",
	priority = "Highest Rarity First",
	syncDelay = 0.35,
	mutationTier = "All Mutations (Shocked+)",
	minEggWeight = 0,
	prioritizeHeaviest = true,
	farmMode = "Safe Tween",
	stealMethod = "Tween",
	stealApproach = "Under Map",
	travelSpeed = 2000,
	returnSpeed = 2000,
	espMinRarity = "Rare & Above",
	espMaxDistance = 5000,
	feedTargetMode = "Smart Priority (Highest Headroom)",
	feedFood = "All Foods",
	feedAllowPremium = true,
	feedSkipMaxAge = true,
	bestPetsStrategy = "Smart Best Income",
	magmaDuration = 9.5,
}

local state = {
	collected = 0,
	target = "None",
	targetRarity = "None",
	targetWeight = 0,
	manual = {},
	cooldowns = {},
	lastPickup = 0,
	pickupPos = nil,
	espEntries = {},
	moving = false,
	volcano = false,
	status = "Idle",
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
	state.status = text
end

local RemotesRoot = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
local GameRemotes = RemotesRoot and (RemotesRoot:FindFirstChild("Game") or RemotesRoot:WaitForChild("Game", 10))
local PlotRemotes = GameRemotes and (GameRemotes:FindFirstChild("Plot") or GameRemotes:WaitForChild("Plot", 5))

local function deepFind(root, name)
	local ok, found = pcall(function()
		return root and (root:FindFirstChild(name, true) or root:FindFirstChild(name))
	end)
	return ok and found or nil
end

local function gameRemote(name)
	local found = deepFind(GameRemotes, name)
	if not found then
		found = deepFind(RemotesRoot, name)
	end
	if not found then
		found = deepFind(ReplicatedStorage, name)
	end
	return found
end

local function plotRemote(name)
	local found = deepFind(PlotRemotes, name)
	if not found then
		found = deepFind(GameRemotes, name)
	end
	return found
end

local EggPickup = gameRemote("EggPickup")
local BasketDrop = gameRemote("BasketDrop")
local TeleportToPlot = gameRemote("TeleportToPlot")
local EggPlaced = gameRemote("EggPlaced")
local RebirthRemote = gameRemote("Rebirth")
local HatchRemote = gameRemote("Hatch")
local PlacePet = gameRemote("PlacePet")
local PickupPet = gameRemote("PickupPet")
local FeedPet = gameRemote("FeedPet")
local NestRemote = plotRemote("Nests")
local UpgradesRemote = plotRemote("Upgrades")

local ModuleFolders = {
	ReplicatedStorage:FindFirstChild("GameData") or ReplicatedStorage:WaitForChild("GameData", 5),
	ReplicatedStorage:FindFirstChild("GameServices") or ReplicatedStorage:WaitForChild("GameServices", 5),
}

local function requireShared(name)
	for _, folder in ipairs(ModuleFolders) do
		if folder then
			local module = folder:FindFirstChild(name) or folder:FindFirstChild(name, true)
			if module and type(module) == "Instance" then
				local ok, result = pcall(require, module)
				if ok and type(result) == "table" then
					return result
				end
			end
		end
	end
	return nil
end

local FALLBACK_EGGS = {
	["White Egg"] = {GrowthTime = 3, Rarity = "Common", Luck = 1},
	["Brown Egg"] = {GrowthTime = 3, Rarity = "Common", Luck = 5},
	["Cracked Egg"] = {GrowthTime = 5, Rarity = "Rare", Luck = 30},
	["Easter Egg"] = {GrowthTime = 6, Rarity = "Rare", Luck = 50},
	["Stone Egg"] = {GrowthTime = 7, Rarity = "Rare", Luck = 100},
	["Leaf Egg"] = {GrowthTime = 8, Rarity = "Rare", Luck = 200},
	["Mushroom Egg"] = {GrowthTime = 60, Rarity = "Epic", Luck = 500},
	["Flower Egg"] = {GrowthTime = 180, Rarity = "Epic", Luck = 750},
	["Slime Egg"] = {GrowthTime = 180, Rarity = "Epic", Luck = 1000},
	["Ice Egg"] = {GrowthTime = 180, Rarity = "Epic", Luck = 3000},
	["Glass Egg"] = {GrowthTime = 300, Rarity = "Legendary", Luck = 10000},
	["Golden Egg"] = {GrowthTime = 300, Rarity = "Legendary", Luck = 30000},
	["Diamond Egg"] = {GrowthTime = 600, Rarity = "Mythic", Luck = 90000},
	["Crystal Egg"] = {GrowthTime = 900, Rarity = "Mythic", Luck = 150000},
	["Skull Egg"] = {GrowthTime = 3600, Rarity = "Mythic", Luck = 250000},
	["Asteroid Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 500000},
	["Dominus Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 700000},
	["Flaming Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 1000000},
	["Sinister Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 3000000},
	["Soul Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 7000000},
	["Tidal Egg"] = {GrowthTime = 7200, Rarity = "Mythic", Luck = 8000000},
	["Aurora Egg"] = {GrowthTime = 10800, Rarity = "Divine", Luck = 300000000},
	["Galaxy Egg"] = {GrowthTime = 10800, Rarity = "Divine", Luck = 1500000000},
	["Bloom Egg"] = {GrowthTime = 10800, Rarity = "Divine", Luck = 2000000000},
	["Blackhole Egg"] = {GrowthTime = 21600, Rarity = "Ethereal", Luck = 100000000000},
	["Solaris Egg"] = {GrowthTime = 25200, Rarity = "Ethereal", Luck = 300000000000},
	["Cherub Egg"] = {GrowthTime = 28800, Rarity = "Ethereal", Luck = 1000000000000},
	["Volcanic Egg"] = {GrowthTime = 32400, Rarity = "Ethereal", Luck = 2500000000000},
}

local FALLBACK_REBIRTHS = {
	Cap = 6,
	RiggedCost = {1000000, 500000000, 2500000000, 125000000000, 6250000000000, 1000000000000000},
}

local EggsData = requireShared("Eggs") or FALLBACK_EGGS
local HatchLuck = requireShared("HatchLuck")
local RebirthsData = requireShared("Rebirths") or FALLBACK_REBIRTHS
local PetsData = requireShared("Pets") or {}
local MutationsData = requireShared("Mutations") or {}
local FoodsData = requireShared("Foods") or {}
local GeneralConfig = requireShared("General") or {}
local DayNightService = requireShared("DayNight")
local PetAging = requireShared("PetAging") or {}

local function requireLocal(name)
	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local gameFolder = playerScripts and (playerScripts:FindFirstChild("Game") or playerScripts:WaitForChild("Game", 3))
	local petsFolder = gameFolder and (gameFolder:FindFirstChild("Pets") or gameFolder:FindFirstChild("Pets", true))
	local module = petsFolder and petsFolder:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	if ok then
		return result
	end
	return nil
end

local PetRenderer = requireLocal("PetRenderer")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(nil)
	playerDataAt = tick()
	return playerDataCache
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

local function teleportTo(position)
	local root = getRoot()
	if root and position then
		root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		return true
	end
	return false
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

local function topSurface(part)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	return part.Position + Vector3.new(0, part.Size.Y / 2, 0)
end

local function fireTouch(part)
	local root = getRoot()
	if not part or not root then
		return false
	end
	if firetouchinterest then
		pcall(firetouchinterest, part, root, 0)
		task.wait(0.05)
		pcall(firetouchinterest, part, root, 1)
		return true
	end
	return false
end

local function touchParts(hitbox)
	local parts = {}
	if hitbox:IsA("BasePart") then
		table.insert(parts, hitbox)
	end
	for _, descendant in ipairs(hitbox:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	table.sort(parts, function(a, b)
		local aHas = a:FindFirstChildOfClass("TouchInterest") ~= nil
		local bHas = b:FindFirstChildOfClass("TouchInterest") ~= nil
		if aHas ~= bHas then
			return aHas
		end
		return a.Name < b.Name
	end)
	return parts
end

local function getSavedValue(name)
	local node = find(LocalPlayer, "SavedData", name)
	return node and node.Value or nil
end

local function getCash()
	return tonumber(getSavedValue("Cash")) or 0
end

local function getIncomePerSecond()
	local value = tonumber(LocalPlayer:GetAttribute("IncomePerSecond"))
	if value then
		return value
	end
	return tonumber(getSavedValue("IncomePerSecond")) or tonumber(getSavedValue("CashPerSecond")) or 0
end

local function getRebirths()
	return tonumber(getSavedValue("Rebirths")) or 0
end

local function getMaxPets()
	return tonumber(getSavedValue("MaxPets")) or tonumber(LocalPlayer:GetAttribute("MaxPets")) or 5
end

local plotCache = nil

local function getPlot()
	if plotCache and plotCache.Parent then
		return plotCache
	end
	plotCache = nil
	if GeneralConfig and type(GeneralConfig.GetPlot) == "function" then
		local ok, plot = pcall(GeneralConfig.GetPlot, LocalPlayer)
		if ok and plot then
			plotCache = plot
			return plot
		end
	end
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, child in ipairs(plots:GetChildren()) do
		local owner = find(child, "Data", "Owner")
		local ownerId = child:GetAttribute("NestsOwnerLoaded") or child:GetAttribute("OwnerUserId") or child:GetAttribute("Owner")
		if (owner and owner.Value == LocalPlayer)
			or ownerId == LocalPlayer.UserId
			or tostring(ownerId) == tostring(LocalPlayer.UserId)
			or child.Name == tostring(LocalPlayer.UserId)
			or child.Name == LocalPlayer.Name then
			plotCache = child
			return child
		end
		local pets = child:FindFirstChild("Pets")
		if pets then
			for _, model in ipairs(pets:GetChildren()) do
				local id = model:GetAttribute("OwnerUserId")
				if model:IsA("Model") and tostring(id) == tostring(LocalPlayer.UserId) then
					plotCache = child
					return child
				end
			end
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

local function getEggsPlanted()
	local plot = getPlot()
	local eggs = plot and plot:FindFirstChild("Eggs")
	return eggs and #eggs:GetChildren() or 0
end

local function getPetsPlaced()
	local plot = getPlot()
	local pets = plot and plot:FindFirstChild("Pets")
	return pets and #pets:GetChildren() or 0
end

local function getNestCounts()
	local plot = getPlot()
	local nests = plot and plot:FindFirstChild("Nests")
	local unlocked, occupied = 0, 0
	if nests then
		for _, nest in ipairs(nests:GetChildren()) do
			if nest:GetAttribute("Unlocked") ~= false then
				unlocked = unlocked + 1
			end
			if nest:GetAttribute("Occupied") == true then
				occupied = occupied + 1
			end
		end
	end
	return unlocked, occupied
end

local function basketCount()
	local basket = LocalPlayer:FindFirstChild("Basket")
	return basket and #basket:GetChildren() or 0
end

local function basketCapacity()
	local equipped = getSavedValue("EquippedEggBasket")
	local entry = nil
	if equipped then
		local baskets = requireShared("EggBaskets")
		entry = type(baskets) == "table" and baskets[tostring(equipped)] or nil
	end
	local capacity = type(entry) == "table" and tonumber(entry.Capacity) or 1
	if capacity == math.huge or capacity > 50 then
		return 50
	end
	return math.max(1, capacity)
end

(function()
local RARITY_LIST = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}
local RARITY_RANK = {}
for index, name in ipairs(RARITY_LIST) do
	RARITY_RANK[name] = index
end

local RARITY_WEIGHT = {
	Ethereal = 1000,
	Divine = 900,
	Mythic = 800,
	Legendary = 700,
	Epic = 600,
	Rare = 500,
	Common = 100,
	Unknown = 0,
}

local RARITY_COLORS = {
	Ethereal = Color3.fromRGB(255, 60, 255),
	Divine = Color3.fromRGB(0, 240, 255),
	Mythic = Color3.fromRGB(255, 50, 50),
	Legendary = Color3.fromRGB(255, 190, 0),
	Epic = Color3.fromRGB(180, 70, 255),
	Rare = Color3.fromRGB(60, 150, 255),
	Common = Color3.fromRGB(190, 190, 190),
	Unknown = Color3.fromRGB(255, 255, 255),
}

local RARITY_CHOICES = {"All Eggs", "Rare & Above", "Epic & Above", "Legendary & Above", "Mythic & Above", "Divine & Above", "Ethereal Only"}
local RARITY_FLOOR = {
	["All Eggs"] = 0,
	["Rare & Above"] = 500,
	["Epic & Above"] = 600,
	["Legendary & Above"] = 700,
	["Mythic & Above"] = 800,
	["Divine & Above"] = 900,
	["Ethereal Only"] = 1000,
}

local MUTATION_TIERS = {Shocked = 2, Volted = 3, Rage = 4, Void = 10, Magma = 10, Eternal = 100}
local MUTATION_WEIGHT = {Eternal = 100000, Magma = 75000, Void = 50000, Rage = 20000, Volted = 10000, Shocked = 5000}
local MUTATION_COLORS = {
	Shocked = Color3.fromRGB(80, 190, 255),
	Volted = Color3.fromRGB(255, 230, 40),
	Rage = Color3.fromRGB(255, 60, 60),
	Void = Color3.fromRGB(130, 60, 255),
	Magma = Color3.fromRGB(255, 120, 20),
	Eternal = Color3.fromRGB(255, 100, 220),
}
local MUTATION_CHOICES = {"All Mutations (Shocked+)", "Volted & Above (3x+)", "Rage & Above (4x+)", "Void & Above (10x+)", "Magma & Above (10x+)", "Eternal Only (100x)"}
local MUTATION_FLOOR = {
	["All Mutations (Shocked+)"] = 2,
	["Volted & Above (3x+)"] = 3,
	["Rage & Above (4x+)"] = 4,
	["Void & Above (10x+)"] = 10,
	["Magma & Above (10x+)"] = 10,
	["Eternal Only (100x)"] = 100,
}
local WEATHER_VARIANTS = {Thunder = "Shocked", Volt = "Volted", Raging = "Rage", Dreadful = "Void", Eternal = "Eternal"}

local SORT_MODES = {"Highest Rarity First", "Closest Distance First", "Highest Luck First", "Heaviest Weight First"}

local REBIRTH_PETS = {"Horse", "Fox", "Unicorn", "Phoenix", "Kitsune", "Dragon"}
local REBIRTH_FALLBACK_EGGS = {
	Horse = {["Asteroid Egg"] = true, ["Skull Egg"] = true, ["Dominus Egg"] = true, ["Crystal Egg"] = true, ["Diamond Egg"] = true, ["Golden Egg"] = true},
	Fox = {["Soul Egg"] = true, ["Sinister Egg"] = true, ["Flaming Egg"] = true},
	Unicorn = {["Cherub Egg"] = true, ["Solaris Egg"] = true, ["Blackhole Egg"] = true, ["Galaxy Egg"] = true},
	Phoenix = {["Cherub Egg"] = true, ["Solaris Egg"] = true, ["Blackhole Egg"] = true},
	Kitsune = {["Cherub Egg"] = true, ["Solaris Egg"] = true, ["Blackhole Egg"] = true},
	Dragon = {["Cherub Egg"] = true, ["Solaris Egg"] = true, ["Blackhole Egg"] = true},
}

local VOLCANO_TOP = Vector3.new(-5102.8, 41408, -3489.1)
local VOLCANO_SKY = CFrame.new(
	-4917.03369, 41285.5312, -3704.17505,
	-0.710648835, -0.151280612, 0.68708986,
	1.78015469e-8, 0.976608396, 0.215025634,
	-0.703546941, 0.152807727, -0.694025576
)
local VOLCANO_DOOR = CFrame.new(-4972.5, 41276.5, -3650, 0.83177793, 0, -0.555108488, 0, 1, 0, 0.555108488, 0, 0.83177793)
local MAP_CENTER = Vector3.new(110, 40316, 750)

local EGG_CHOICES = {"Any Egg"}
do
	local sorted = {}
	for name, entry in pairs(EggsData) do
		if type(entry) == "table" and name ~= "Cap" then
			table.insert(sorted, {
				Name = name,
				Rank = RARITY_RANK[tostring(entry.Rarity)] or 1,
				Luck = tonumber(entry.Luck) or 0,
			})
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

local FOOD_CHOICES = {"All Foods"}
do
	local sorted = {}
	for name, entry in pairs(FoodsData) do
		if type(entry) == "table" then
			table.insert(sorted, name)
		end
	end
	table.sort(sorted)
	for _, name in ipairs(sorted) do
		table.insert(FOOD_CHOICES, name)
	end
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function eggEntry(name)
	local entry = EggsData[tostring(name)]
	if type(entry) == "table" then
		return entry
	end
	return FALLBACK_EGGS[tostring(name)]
end

local function eggRarity(name)
	local entry = eggEntry(name)
	return entry and tostring(entry.Rarity) or "Common"
end

local function eggRank(name)
	return RARITY_RANK[eggRarity(name)] or 1
end

local function eggLuck(name)
	local entry = eggEntry(name)
	return entry and (tonumber(entry.Luck) or 0) or 0
end

local function getRenderedEggs()
	return Workspace:FindFirstChild("RenderedEggs")
end

local function getActiveEggs()
	return find(ReplicatedStorage, "ServerData", "ActiveEggs")
end

local function eggPrompt(model)
	if not model then
		return nil
	end
	return model:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function getStorm()
	local serverData = ReplicatedStorage:FindFirstChild("ServerData")
	local raw = serverData and serverData:GetAttribute("ActiveWeathers")
	if type(raw) ~= "string" or raw == "" or raw == "[]" then
		return nil
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return nil
	end
	local now = Workspace:GetServerTimeNow()
	for _, entry in ipairs(decoded) do
		if entry and entry.Type == "Storm" and entry.Variant and (not entry.EndsAt or entry.EndsAt > now) then
			return entry
		end
	end
	return nil
end

local function eggMutation(model)
	if not model then
		return nil
	end
	local attribute = model:GetAttribute("Mutation")
	if type(attribute) == "string" and attribute ~= "" then
		return attribute
	end
	local activeEggs = getActiveEggs()
	local position = safePivot(model)
	if activeEggs then
		if position then
			for _, child in ipairs(activeEggs:GetChildren()) do
				local attrs = child:GetAttributes()
				if attrs.Mutation and attrs.Mutation ~= "" then
					local childPosition = attrs.Position or (attrs.SpawnCFrame and attrs.SpawnCFrame.Position)
					if childPosition and (childPosition - position).Magnitude <= 6 then
						return attrs.Mutation
					end
				end
			end
		end
		if model:FindFirstChild("MutationHitbox", true) then
			local storm = getStorm()
			if storm and WEATHER_VARIANTS[storm.Variant] then
				return WEATHER_VARIANTS[storm.Variant]
			end
			return "Shocked"
		end
		return nil
	elseif model:FindFirstChild("MutationHitbox", true) then
		local storm = getStorm()
		if storm and WEATHER_VARIANTS[storm.Variant] then
			return WEATHER_VARIANTS[storm.Variant]
		end
		return "Shocked"
	end
	return nil
end

local weightCache = setmetatable({}, {__mode = "k"})

local function eggWeight(model)
	if not model then
		return 0
	end
	local cached = weightCache[model]
	if cached ~= nil then
		return cached
	end
	local position = safePivot(model)
	local activeEggs = getActiveEggs()
	if activeEggs and position then
		for _, child in ipairs(activeEggs:GetChildren()) do
			local childPosition = child:GetAttribute("Position")
			if childPosition and (childPosition - position).Magnitude < 10 then
				local weight = tonumber(child:GetAttribute("Weight")) or 0
				if GeneralConfig and type(GeneralConfig.ShownEggKG) == "function" then
					local ok, shown = pcall(GeneralConfig.ShownEggKG, weight)
					if ok and type(shown) == "number" then
						weight = shown
					end
				end
				weight = math.floor(weight * 10 + 0.5) / 10
				weightCache[model] = weight
				return weight
			end
		end
	end
	weightCache[model] = 0
	return 0
end

local oddsCache = {}

local function getOdds(luck)
	local key = tostring(luck)
	if oddsCache[key] then
		return oddsCache[key]
	end
	local map = {}
	if HatchLuck and type(HatchLuck.GetOdds) == "function" then
		local ok, result = pcall(HatchLuck.GetOdds, luck)
		if ok and type(result) == "table" then
			for _, entry in ipairs(result) do
				if entry and entry.PetName and tonumber(entry.Chance) then
					map[entry.PetName] = tonumber(entry.Chance)
				end
			end
		end
	end
	oddsCache[key] = map
	return map
end

local function parseAmount(text)
	if type(text) ~= "string" then
		return nil
	end
	local num, suffix = string.match(text, "([%d%.]+)%s*([A-Za-z]*)")
	num = tonumber(num)
	if not num then
		return nil
	end
	if suffix == "" then
		return num
	end
	local exp = SUFFIX_EXPONENTS[string.lower(suffix)]
	if not exp then
		return nil
	end
	return num * (10 ^ exp)
end

local function formatWeight(value)
	value = tonumber(value) or 0
	if value >= 1000 then
		return abbreviateNumber(value) .. " KG"
	end
	if value >= 10 then
		return string.format("%.1f KG", value)
	end
	return string.format("%.2f KG", value)
end

local function allowedRarity(name)
	local floor = RARITY_FLOOR[config.minRarity] or 0
	return (RARITY_WEIGHT[eggRarity(name)] or 0) >= floor
end

local function allowedTarget(name)
	if config.targetEgg ~= "Any Egg" then
		local wanted = config.targetEgg:gsub("%s*%[.-%]", "")
		if wanted ~= name then
			return false
		end
	end
	return allowedRarity(name)
end

local function mutationAllowed(mutation)
	if not mutation or mutation == "" then
		return false
	end
	return (MUTATION_TIERS[mutation] or 1) >= (MUTATION_FLOOR[config.mutationTier] or 2)
end

local function weightAllowed(weight)
	local minimum = tonumber(config.minEggWeight) or 0
	if minimum <= 0 then
		return true
	end
	return (tonumber(weight) or 0) >= minimum
end

local function plainName(text)
	return (tostring(text or ""):match("^(.-) %[") or tostring(text or ""))
end

local function ownsPet(name)
	if not name or name == "" then
		return false, "Not Owned"
	end
	local owned = LocalPlayer:GetAttribute("OwnedPets") or getSavedValue("OwnedPets")
	if type(owned) == "string" and owned ~= "" and string.find(owned, name .. ",", 1, true) then
		return true, "SavedData"
	end
	local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local key = tool:GetAttribute("PetKey")
					local plain = plainName(tool.Name)
					if (type(key) == "string" and string.find(key, name, 1, true)) or plain == name then
						return true, container == getCharacter() and "Character" or "Backpack"
					end
				end
			end
		end
	end
	local plot = getPlot()
	local pets = plot and plot:FindFirstChild("Pets")
	if pets then
		for _, model in ipairs(pets:GetChildren()) do
			local petName = model:GetAttribute("PetName") or plainName(model.Name)
			if petName == name then
				return true, "Plot"
			end
		end
		return false, "Not Owned"
	end
	return false, "Not Owned"
end

local function eggTimeLeft(model)
	if not model or not model.Parent then
		return nil
	end
	local eggKey = model:GetAttribute("EggKey")
	local eggData = model:FindFirstChild("EggData")
	local placeNode = eggData and find(eggData, "PlaceTime")
	local weightNode = eggData and find(eggData, "Weight")
	local placeTime = placeNode and tonumber(placeNode.Value)
	local weight = (weightNode and tonumber(weightNode.Value)) or 1
	local entry = eggEntry(model.Name)
	local growth = entry and (tonumber(entry.GrowthTime) or 0) or 0

	local total = nil
	if growth > 0 then
		total = growth * math.max(weight or 1, 1)
		if GeneralConfig and type(GeneralConfig.GrowthTimeFor) == "function" then
			local ok, computed = pcall(GeneralConfig.GrowthTimeFor, growth, weight)
			if ok and type(computed) == "number" and computed > 0 then
				total = computed
			end
		end
	end

	local tracker = LocalPlayer:FindFirstChild("PlayerGui")
		and find(LocalPlayer.PlayerGui, "Main", "PlotEggsTracker", "Holder")
	local row = eggKey and tracker and tracker:FindFirstChild(eggKey)
	local openRow = row and row:FindFirstChild("Open", true)
	local label = row and row:FindFirstChild("TimeLeft", true)
	if openRow and openRow.Visible then
		return {isReady = true, timeStr = "Ready to Hatch!", timeLeft = 0, eggKey = eggKey}
	end
	if label and type(label.Text) == "string" and label.Text ~= "" then
		local ready = string.lower(label.Text):find("ready") ~= nil
		return {isReady = ready, timeStr = ready and "Ready to Hatch!" or label.Text, timeLeft = 0, eggKey = eggKey}
	end

	if not placeTime or not total then
		return {isReady = false, timeStr = "Incubating...", timeLeft = nil, eggKey = eggKey}
	end

	local elapsed = 0
	if DayNightService and type(DayNightService.GrowthElapsed) == "function" then
		local ok, value = pcall(DayNightService.GrowthElapsed, placeTime)
		if ok and type(value) == "number" then
			elapsed = value
		else
			elapsed = math.max(0, Workspace:GetServerTimeNow() - placeTime)
		end
	else
		elapsed = math.max(0, Workspace:GetServerTimeNow() - placeTime)
	end

	local remaining = math.max(0, total - elapsed)
	local ready = remaining <= 0
	local text = "Incubating..."
	if ready then
		text = "Ready to Hatch!"
	else
		local hours = math.floor(remaining / 3600)
		local minutes = math.floor(remaining % 3600 / 60)
		local seconds = math.floor(remaining % 60)
		if hours > 0 then
			text = string.format("%d:%02d:%02d", hours, minutes, seconds)
		else
			text = string.format("%d:%02d", minutes, seconds)
		end
	end
	return {isReady = ready, timeStr = text, timeLeft = remaining, eggKey = eggKey}
end

local function incubatingFor(pet)
	local plot = getPlot()
	local eggs = plot and plot:FindFirstChild("Eggs")
	local basket = LocalPlayer:FindFirstChild("Basket")

	local function matches(name)
		local chance = getOdds(eggLuck(name))[pet] or 0
		local listed = REBIRTH_FALLBACK_EGGS[pet] ~= nil and REBIRTH_FALLBACK_EGGS[pet][name] == true
		return chance > 0, chance, listed
	end

	if eggs then
		for _, model in ipairs(eggs:GetChildren()) do
			local ok, chance, listed = matches(model.Name)
			if ok or listed then
				local info = eggTimeLeft(model)
				return true, model.Name, chance, info and info.timeStr or "Incubating..."
			end
		end
	end
	if basket then
		for _, child in ipairs(basket:GetChildren()) do
			local name = child:GetAttribute("Egg") or child.Name
			local ok, chance = matches(name)
			if ok then
				return true, name, chance, "In Basket"
			end
		end
	end
	local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local plain = plainName(tool.Name)
					local ok, chance = matches(plain)
					if ok then
						return true, plain, chance, "In Backpack"
					end
				end
			end
		end
	end
	return false, nil, 0, nil
end

local function rebirthState()
	local rebirths = getRebirths()
	local cap = tonumber(RebirthsData.Cap) or 6
	local nextTier = rebirths + 1
	local costs = RebirthsData.RiggedCost
	local cost = type(costs) == "table" and tonumber(costs[nextTier]) or nil
	cost = cost or FALLBACK_REBIRTHS.RiggedCost[math.min(nextTier, 6)]

	local pet = REBIRTH_PETS[nextTier] or "N/A"
	local rebirthGui = find(LocalPlayer.PlayerGui, "Main", "Rebirth")
	local holder = rebirthGui and find(rebirthGui, "Segment2", "pEThOLDER", "PetName")
	if holder and type(holder.Text) == "string" and holder.Text ~= "" and holder.Text ~= "PetName" then
		pet = holder.Text
	end

	local capped = rebirths >= cap
	local hasPet, location = ownsPet(pet)
	local incubating, eggName, chance, timeStr = false, nil, 0, nil
	if not hasPet then
		incubating, eggName, chance, timeStr = incubatingFor(pet)
	end
	local cash = getCash()
	return {
		current = rebirths,
		nextTier = nextTier,
		maxCap = cap,
		capped = capped,
		pet = pet,
		hasPet = hasPet,
		petLocation = location,
		incubating = incubating,
		incubatingEgg = eggName,
		incubatingChance = chance or 0,
		incubatingTime = timeStr,
		cash = cash,
		cost = cost,
		canRebirth = (not capped) and hasPet and cash >= cost,
	}
end

local farmCooldown = {}

local function onCooldown(name)
	local untilTime = farmCooldown[name]
	return untilTime and untilTime > tick()
end

local function buildTarget(model, root, extra)
	local position = safePivot(model)
	local prompt = eggPrompt(model)
	local target = {
		Model = model,
		Prompt = prompt,
		Name = model.Name,
		Rarity = eggRarity(model.Name),
		Position = position,
		Luck = eggLuck(model.Name),
		EggWeight = eggWeight(model),
		Mutation = eggMutation(model),
	}
	target.Distance = (position and root and (position - root.Position).Magnitude) or math.huge
	for key, value in pairs(extra or {}) do
		target[key] = value
	end
	return target
end

local function sortByWeight(a, b)
	if a.Rarity ~= b.Rarity then
		return a.Rarity and b.Rarity and a.Rarity > b.Rarity
	end
	return a.Distance < b.Distance
end

local function pickFarmTarget()
	local root = getRoot()
	if not root then
		return nil
	end
	local rendered = getRenderedEggs()
	if not rendered then
		return nil
	end

	local options = {}
	for _, model in ipairs(rendered:GetChildren()) do
		if model:IsA("Model") and allowedTarget(model.Name) and not onCooldown(model.Name) then
			local target = buildTarget(model, root)
			if target.Position then
				table.insert(options, target)
			end
		end
	end

	if enabled.rebirthPet then
		local info = rebirthState()
		if not info.capped and not info.hasPet and not info.incubating and info.pet ~= "N/A" then
			local best, bestChance = nil, 0
			for _, target in ipairs(options) do
				local chance = getOdds(target.Luck)[info.pet] or 0
				local listed = REBIRTH_FALLBACK_EGGS[info.pet] ~= nil and REBIRTH_FALLBACK_EGGS[info.pet][target.Name] == true
				if chance > 0 or listed then
					target.RebirthPet = info.pet
					target.RebirthChance = chance
					target.RebirthListed = listed
					if chance > bestChance or (listed and chance == bestChance) then
						best, bestChance = target, chance
					end
				end
			end
			if best then
				state.rebirthPet = info.pet
				state.rebirthEgg = best.Name
				state.rebirthChance = best.RebirthChance
				return best
			end
		end
	end

	if enabled.farmMutations then
		local mutated = {}
		for _, target in ipairs(options) do
			if mutationAllowed(target.Mutation) then
				target.MutationWeight = MUTATION_WEIGHT[target.Mutation] or 0
				table.insert(mutated, target)
			end
		end
		if #mutated > 0 then
			table.sort(mutated, function(a, b)
				if a.MutationWeight ~= b.MutationWeight then
					return a.MutationWeight > b.MutationWeight
				end
				if config.prioritizeHeaviest and math.abs(a.EggWeight - b.EggWeight) > 0.05 then
					return a.EggWeight > b.EggWeight
				end
				return a.Distance < b.Distance
			end)
			return mutated[1]
		end
	end

	if enabled.weatherWait then
		local storm = getStorm()
		local mutation = storm and WEATHER_VARIANTS[storm.Variant]
		if mutation and mutationAllowed(mutation) then
			local remaining = storm.EndsAt and math.max(0, math.floor(storm.EndsAt - Workspace:GetServerTimeNow())) or 0
			return {
				WaitingWeather = true,
				StormVariant = storm.Variant,
				MutationType = mutation,
				TimeLeft = remaining,
			}
		end
	end

	local filtered = {}
	for _, target in ipairs(options) do
		if weightAllowed(target.EggWeight) then
			table.insert(filtered, target)
		end
	end
	if #filtered == 0 then
		return nil
	end

	if config.priority == "Heaviest Weight First" then
		table.sort(filtered, function(a, b)
			if math.abs(a.EggWeight - b.EggWeight) > 0.05 then
				return a.EggWeight > b.EggWeight
			end
			if a.Rarity ~= b.Rarity then
				return a.Rarity > b.Rarity
			end
			return a.Distance < b.Distance
		end)
	elseif config.priority == "Highest Rarity First" then
		table.sort(filtered, function(a, b)
			if a.Rarity ~= b.Rarity then
				return a.Rarity > b.Rarity
			end
			if config.prioritizeHeaviest and math.abs(a.EggWeight - b.EggWeight) > 0.05 then
				return a.EggWeight > b.EggWeight
			end
			return a.Distance < b.Distance
		end)
	elseif config.priority == "Closest Distance First" then
		table.sort(filtered, function(a, b)
			if a.Distance ~= b.Distance then
				return a.Distance < b.Distance
			end
			return a.Rarity > b.Rarity
		end)
	elseif config.priority == "Highest Luck First" then
		table.sort(filtered, function(a, b)
			if a.Luck ~= b.Luck then
				return a.Luck > b.Luck
			end
			if config.prioritizeHeaviest and math.abs(a.EggWeight - b.EggWeight) > 0.05 then
				return a.EggWeight > b.EggWeight
			end
			return a.Distance < b.Distance
		end)
	else
		table.sort(filtered, sortByWeight)
	end
	return filtered[1]
end

local function stopMotion()
	local root = getRoot()
	if root then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end

local function setFlightStabilizer(root, humanoid)
	if not root then
		return nil
	end
	local stabilizer = root:FindFirstChild("AntiGodStabilizer")
	if not stabilizer then
		pcall(function()
			stabilizer = Instance.new("BodyVelocity")
			stabilizer.Name = "AntiGodStabilizer"
			stabilizer.MaxForce = Vector3.new(1000000000, 1000000000, 1000000000)
			stabilizer.Velocity = Vector3.zero
			stabilizer.Parent = root
		end)
	end
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = true
		end)
	end
	stopMotion()
	return stabilizer
end

local function clearFlightStabilizer(root, humanoid)
	if root then
		local stabilizer = root:FindFirstChild("AntiGodStabilizer")
		if stabilizer then
			pcall(function()
				stabilizer:Destroy()
			end)
		end
	end
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
	stopMotion()
end

local function teleportStep(root, humanoid, target, duration)
	stopMotion()
	local stabilizer = setFlightStabilizer(root, humanoid)
	local tween = TweenService:Create(root, TweenInfo.new(math.max(duration, 0.05), Enum.EasingStyle.Linear), {CFrame = target})
	tween:Play()
	return stabilizer, tween
end

local function moveTo(position, tolerance, abortCheck, speed)
	local root = getRoot()
	if not root or typeof(position) ~= "Vector3" then
		return false, "no_hrp"
	end
	tolerance = tolerance or 20
	if (root.Position - position).Magnitude <= tolerance then
		return true, "ok"
	end
	if config.farmMode == "Instant" then
		stopMotion()
		root.CFrame = CFrame.new(position)
		return true, "ok"
	end

	local humanoid = getHumanoid()
	local distance = (root.Position - position).Magnitude
	local duration = math.max(distance / math.max(tonumber(speed) or 300, 20), 0.05)
	local stabilizer, tween = teleportStep(root, humanoid, CFrame.new(position), duration)

	local completed = false
	local connection = tween.Completed:Connect(function()
		completed = true
	end)
	local started = tick()
	while not completed and tick() - started < duration + 1.2 do
		if abortCheck and abortCheck() then
			break
		end
		if not getRoot() then
			break
		end
		task.wait(0.05)
	end
	if not completed then
		pcall(function()
			tween:Cancel()
		end)
	end
	if connection then
		pcall(function()
			connection:Disconnect()
		end)
	end
	if stabilizer then
		clearFlightStabilizer(getRoot() or root, getHumanoid())
	end
	stopMotion()
	root = getRoot()
	if not root then
		return false, "no_hrp"
	end
	local remaining = (root.Position - position).Magnitude
	if remaining > tolerance then
		if remaining < tolerance * 4 then
			root.CFrame = CFrame.new(position)
			return true, "ok"
		end
		return false, "not_arrived"
	end
	return true, "ok"
end

local VOID_DEPTH = 110
local OVER_HEIGHT = 250
local CRUISE_HEIGHT = 45
local RELAY_DISTANCE = 250

local function destroyHeight()
	local ok, value = pcall(function()
		return Workspace.FallenPartsDestroyHeight
	end)
	if ok and typeof(value) == "number" then
		return value
	end
	return -500
end

local function routeWaypoints(from, to, opts)
	if Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude < 80 and math.abs(to.Y - from.Y) < 30 then
		return {to}
	end
	if opts and opts.void then
		local depth = math.max(math.min(from.Y, to.Y) - VOID_DEPTH, destroyHeight() + 60)
		return {Vector3.new(from.X, depth, from.Z), Vector3.new(to.X, depth, to.Z), to}
	end
	local height = math.max(from.Y, to.Y) + ((opts and opts.over) and OVER_HEIGHT or CRUISE_HEIGHT)
	return {Vector3.new(from.X, height, from.Z), Vector3.new(to.X, height, to.Z), to}
end

local function routeOptions()
	if config.stealApproach == "Under Map" then
		return {void = true}
	end
	if config.stealApproach == "Over Map" then
		return {over = true}
	end
	return nil
end

local function streamAround(position)
	pcall(function()
		if typeof(Workspace.RequestStreamAroundAsync) == "function" then
			Workspace:RequestStreamAroundAsync(position, 16)
		end
	end)
end

local function instantTo(position, tolerance)
	local root = getRoot()
	if not root or typeof(position) ~= "Vector3" then
		return false
	end
	tolerance = tolerance or 4
	if (root.Position - position).Magnitude <= tolerance then
		return true
	end
	local wasAnchored = root.Anchored
	local function place()
		local current = getRoot()
		if not current then
			return
		end
		pcall(function()
			current.Anchored = true
			current.AssemblyLinearVelocity = Vector3.zero
			current.AssemblyAngularVelocity = Vector3.zero
			current.CFrame = CFrame.new(position)
		end)
	end
	place()
	streamAround(position)
	for _ = 1, 5 do
		RunService.Heartbeat:Wait()
	end
	local current = getRoot()
	if current and current.Position.Y < position.Y - 15 then
		place()
		RunService.Heartbeat:Wait()
		current = getRoot()
	end
	pcall(function()
		if current then
			current.Anchored = wasAnchored
			current.AssemblyLinearVelocity = Vector3.zero
			current.AssemblyAngularVelocity = Vector3.zero
		end
	end)
	current = getRoot()
	if not current then
		return false
	end
	stopMotion()
	return (current.Position - position).Magnitude <= tolerance + 1
end

local function flyTo(position, tolerance, abortCheck, opts)
	local root = getRoot()
	if not root or typeof(position) ~= "Vector3" then
		return false
	end
	tolerance = tolerance or 3
	if (root.Position - position).Magnitude <= tolerance then
		return true
	end
	local speed = math.max(tonumber(opts and opts.speed) or tonumber(config.travelSpeed) or 2000, 20)
	local waypoints = routeWaypoints(root.Position, position, opts)
	local arrived = false
	for index, waypoint in ipairs(waypoints) do
		local final = index == #waypoints
		local ok = moveTo(waypoint, final and tolerance or 3, abortCheck, speed)
		if not ok then
			return false
		end
		if final then
			arrived = true
		end
	end
	return arrived
end

local function nearestActiveEgg(model)
	local activeEggs = getActiveEggs()
	if not activeEggs or not model then
		return nil
	end
	local pivot = safePivot(model)
	if not pivot then
		return nil
	end
	local best, bestDistance = nil, 25
	for _, child in ipairs(activeEggs:GetChildren()) do
		local position = child:GetAttribute("Position")
		if position then
			local magnitude = (position - pivot).Magnitude
			if magnitude < bestDistance then
				best, bestDistance = child, magnitude
			end
		end
	end
	return best
end

local function collectEgg(target)
	if not target or not target.Model or not target.Model.Parent then
		return false
	end
	local root = getRoot()
	if not root then
		return false
	end
	local position = target.Prompt and target.Prompt.Parent and target.Prompt.Parent:IsA("BasePart") and target.Prompt.Parent.Position or target.Position
	if (root.Position - position).Magnitude > 12 then
		local arrived = flyTo(position, 4, function()
			return not (enabled.farm or enabled.rebirthPet)
		end, routeOptions())
		if not arrived then
			return false
		end
	end
	stopMotion()
	local before = basketCount()
	if before == 0 then
		state.pickupPos = position
	end
	task.wait(math.clamp(config.syncDelay, 0.1, 1))
	local deadline = tick() + 2.5
	while tick() < deadline do
		if basketCount() > before then
			return true
		end
		if not target.Model or not target.Model.Parent then
			break
		end
		if target.Prompt then
			pcall(function()
				target.Prompt.HoldDuration = 0
				target.Prompt.MaxActivationDistance = 9999
				target.Prompt.RequiresLineOfSight = false
			end)
			if fireproximityprompt then
				pcall(fireproximityprompt, target.Prompt, 0)
			end
		end
		local current = getRoot()
		if current then
			pcall(function()
				current.CFrame = CFrame.new(position.X, position.Y + 2, position.Z)
				current.AssemblyLinearVelocity = Vector3.zero
				current.AssemblyAngularVelocity = Vector3.zero
			end)
		end
		local active = nearestActiveEgg(target.Model)
		fire(EggPickup, active and active.Name or target.Name)
		task.wait(0.25)
	end
	return basketCount() > before
end

local function volcanoParts()
	local volcano = Workspace:FindFirstChild("Volcano")
	if not volcano then
		return nil, nil
	end
	return volcano:FindFirstChild("VolcanoEntrance"), volcano:FindFirstChild("VolcanoValidate")
end

local function touchVolcano(root, down)
	if not firetouchinterest or not root then
		return
	end
	local entrance, validate = volcanoParts()
	for _, part in ipairs({validate, entrance}) do
		if part then
			pcall(firetouchinterest, root, part, down)
		end
	end
end

local function makeVolcanoPlatform()
	local existing = Workspace:FindFirstChild("AntiGod_VolcanoPlatform")
	local platformCFrame = VOLCANO_SKY * CFrame.new(0, -3.2, 0)
	if existing then
		existing.CFrame = platformCFrame
		return existing
	end
	local platform = Instance.new("Part")
	platform.Name = "AntiGod_VolcanoPlatform"
	platform.Size = Vector3.new(14, 1, 14)
	platform.Anchored = true
	platform.CanCollide = true
	platform.CFrame = platformCFrame
	platform.Material = Enum.Material.SmoothPlastic
	platform.Transparency = 0.5
	platform.Parent = Workspace
	return platform
end

local function enterVolcano()
	local root = getRoot()
	if not root then
		return false
	end
	if LocalPlayer:GetAttribute("InVolcano") == true and LocalPlayer:GetAttribute("VolcanoValidated") == true then
		state.volcano = true
		return true
	end
	setFarmStatus("warping to volcano")
	makeVolcanoPlatform()
	stopMotion()
	root.CFrame = VOLCANO_SKY
	task.wait(0.12)
	local entrance, validate = volcanoParts()
	local duration = math.clamp((VOLCANO_DOOR.Position - root.Position).Magnitude / 40, 0.6, 1.6)
	local deadline = tick() + duration + 1
	while tick() < deadline do
		touchVolcano(root, 0)
		root.CFrame = root.CFrame:Lerp(VOLCANO_DOOR, 0.25)
		if LocalPlayer:GetAttribute("InVolcano") == true and LocalPlayer:GetAttribute("VolcanoValidated") == true then
			break
		end
		task.wait(0.03)
	end
	touchVolcano(root, 1)
	stopMotion()
	task.wait(0.05)
	state.volcano = LocalPlayer:GetAttribute("InVolcano") == true
	return state.volcano
end

local function escapeVolcano()
	local root = getRoot()
	if not root then
		return false
	end
	if LocalPlayer:GetAttribute("InVolcano") ~= true then
		state.volcano = false
		return true
	end
	setFarmStatus("escaping volcano")
	stopMotion()
	root.CFrame = VOLCANO_DOOR
	task.wait(0.1)
	touchVolcano(root, 0)
	task.wait(0.08)
	stopMotion()
	root.CFrame = VOLCANO_SKY
	touchVolcano(root, 1)
	local deadline = tick() + 1.5
	while tick() < deadline do
		if LocalPlayer:GetAttribute("InVolcano") ~= true then
			break
		end
		task.wait(0.05)
	end
	state.volcano = LocalPlayer:GetAttribute("InVolcano") == true
	return not state.volcano
end

local function fireVolcanoDip()
	local net = find(ReplicatedStorage, "packages", "Net")
	if net then
		pcall(function()
			if type(net.RemoteEvent) == "function" then
				local remote = net:RemoteEvent("VolcanoDip")
				if remote then
					remote:FireServer()
				end
			end
		end)
		local direct = net:FindFirstChild("RE/VolcanoDip") or net:FindFirstChild("VolcanoDip", true)
		if direct then
			fire(direct)
		end
	end
	local holder = find(LocalPlayer.PlayerGui, "Main", "ActionsHolder", "DropEggVolcanoButton")
	if holder and firesignal then
		pcall(firesignal, holder.Activated)
	end
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
	end)
end

local function dipMagma()
	if not enabled.magmaDip then
		return false
	end
	local basket = LocalPlayer:FindFirstChild("Basket")
	if not basket or basketCount() == 0 then
		return false
	end
	local egg = nil
	for _, child in ipairs(basket:GetChildren()) do
		if child:GetAttribute("VolcanoDipped") ~= true and child:GetAttribute("Delivering") ~= true then
			local mutation = child:GetAttribute("Mutation")
			if mutation ~= "Eternal" and mutation ~= "Magma" then
				egg = child
				break
			end
		end
	end
	if not egg then
		return false
	end

	local root = getRoot()
	if not root then
		return false
	end

	if not enterVolcano() then
		return false
	end
	root = getRoot()
	if not root then
		return false
	end

	setFarmStatus("warping to lava")
	stopMotion()
	root.CFrame = CFrame.new(VOLCANO_TOP)
	task.wait(0.2)
	if (root.Position - VOLCANO_TOP).Magnitude > 25 then
		stopMotion()
		root.CFrame = CFrame.new(VOLCANO_TOP)
		task.wait(0.1)
	end

	setFarmStatus("dipping egg in lava")
	fireVolcanoDip()

	local started = tick()
	local duration = tonumber(config.magmaDuration) or 9.5
	while tick() - started < duration do
		if not egg.Parent then
			break
		end
		local current = getRoot()
		if current and (current.Position - VOLCANO_TOP).Magnitude > 30 then
			stopMotion()
			current.CFrame = CFrame.new(VOLCANO_TOP)
		end
		setFarmStatus(string.format("lava dip %ds left", math.ceil(duration - (tick() - started))))
		task.wait(0.15)
	end

	pcall(function()
		egg:SetAttribute("VolcanoDipped", true)
	end)
	local mutated = egg.Parent and egg:GetAttribute("Mutation") == "Magma"
	escapeVolcano()
	setFarmStatus(mutated and "magma mutation succeeded" or "lava dip finished")
	return mutated
end

local function collectEggTools()
	local tools = {}
	local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and (tool:HasTag("Egg") or string.find(tool.Name, "Egg", 1, true)) then
					table.insert(tools, tool)
				end
			end
		end
	end
	return tools
end

local function equipTool(tool, container)
	local humanoid = getHumanoid()
	if not tool or not humanoid or not container then
		return false
	end
	if tool.Parent ~= container then
		pcall(humanoid.EquipTool, humanoid, tool)
		local deadline = tick() + 0.8
		while tool.Parent ~= container and tick() < deadline do
			task.wait(0.05)
		end
	end
	return tool.Parent == container
end

local plotRandom = Random.new()

local function randomPlotPoint(baseplate)
	if not baseplate then
		return nil
	end
	local halfX = math.max(1, baseplate.Size.X / 2 - 6)
	local halfZ = math.max(1, baseplate.Size.Z / 2 - 6)
	local offset = Vector3.new(plotRandom:NextNumber(-halfX, halfX), 0.55, plotRandom:NextNumber(-halfZ, halfZ))
	return baseplate.CFrame:PointToWorldSpace(offset)
end

local function placeEggs()
	if not EggPlaced then
		return 0
	end
	local plot = getPlot()
	local character = getCharacter()
	if not plot or not character then
		return 0
	end
	local capacity = enabled.spawnNest and 15 or 10
	local nests = plot:FindFirstChild("Nests")
	local placed = 0
	local freeNests = 0
	if nests then
		for _, nest in ipairs(nests:GetChildren()) do
			if nest:GetAttribute("Unlocked") ~= false and nest:GetAttribute("Occupied") ~= true then
				freeNests = freeNests + 1
			end
		end
	end
	local usedNest = 0
	for _, tool in ipairs(collectEggTools()) do
		if getEggsPlanted() >= capacity then
			break
		end
		local nested = false
		if enabled.spawnNest and nests and freeNests > 0 and usedNest < freeNests then
			for _, nest in ipairs(nests:GetChildren()) do
				if nest:GetAttribute("Unlocked") ~= false and nest:GetAttribute("Occupied") ~= true then
					if equipTool(tool, character) then
						setFarmStatus("placing egg in nest")
						fire(EggPlaced, {NestId = nest.Name})
						placed = placed + 1
						usedNest = usedNest + 1
						task.wait(0.3)
						nested = true
					end
					break
				end
			end
		end
		if not nested then
			local baseplate = getBaseplate()
			local point = randomPlotPoint(baseplate)
			if point and getEggsPlanted() - getNestCounts() < 10 and equipTool(tool, character) then
				setFarmStatus("planting egg")
				fire(EggPlaced, {PlantPosition = point})
				placed = placed + 1
				task.wait(0.3)
			end
		end
	end
	return placed
end
local function hatchReadyEggs()
	local hatched = 0
	local plot = getPlot()
	local eggs = plot and plot:FindFirstChild("Eggs")
	if eggs then
		for _, model in ipairs(eggs:GetChildren()) do
			local info = eggTimeLeft(model)
			if info and info.isReady then
				if info.eggKey and HatchRemote then
					fire(HatchRemote, {EggKey = info.eggKey})
					hatched = hatched + 1
				else
					local prompt = eggPrompt(model)
					if prompt then
						pcall(function()
							prompt.HoldDuration = 0
						end)
						if fireproximityprompt then
							pcall(fireproximityprompt, prompt, 0)
						else
							pcall(function()
								prompt:InputHoldBegin()
								task.wait(0.05)
								prompt:InputHoldEnd()
							end)
						end
						hatched = hatched + 1
					end
				end
				task.wait(0.06)
			end
		end
	end

	local holder = find(LocalPlayer.PlayerGui, "Main", "PlotEggsTracker", "Holder")
	if holder then
		for _, row in ipairs(holder:GetChildren()) do
			local open = row:FindFirstChild("Open", true)
			local label = row:FindFirstChild("TimeLeft", true)
			local ready = (open and open:IsA("GuiButton") and open.Visible)
				or (label and type(label.Text) == "string" and string.lower(label.Text):find("ready") ~= nil)
			if ready then
				local key = row.Name
				if type(key) == "string" and #key > 10 and HatchRemote then
					fire(HatchRemote, {EggKey = key})
					hatched = hatched + 1
				end
				task.wait(0.06)
			end
		end
	end
	return hatched
end

local function unlockNests()
	if not NestRemote or LocalPlayer:GetAttribute("NoNest") == true then
		return 0
	end
	local plot = getPlot()
	local nests = plot and plot:FindFirstChild("Nests")
	if not nests then
		return 0
	end
	local count = 0
	for _, nest in ipairs(nests:GetChildren()) do
		if nest:GetAttribute("Unlocked") ~= true then
			local prompt = nest:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt and fireproximityprompt then
				pcall(fireproximityprompt, prompt, 0)
			end
			local id = tonumber(nest.Name)
			if id then
				fire(NestRemote, id)
			end
			count = count + 1
			task.wait(0.2)
		end
	end
	return count
end

local function upgradeLuck()
	if not UpgradesRemote then
		return false
	end
	fire(UpgradesRemote, "HatchUpgrade", "BuyMax")
	fire(UpgradesRemote, "HatchUpgrade", "BuyOne")
	return true
end

local function multiplierForAge(age)
	if PetAging and type(PetAging.MultiplierFor) == "function" then
		local ok, value = pcall(PetAging.MultiplierFor, age)
		if ok and type(value) == "number" and value > 0 then
			return value
		end
	end
	return 1
end

local function mutationFactor(mutation)
	if MutationsData and type(MutationsData.CombinedFactor) == "function" then
		local ok, value = pcall(MutationsData.CombinedFactor, mutation, nil)
		if ok and type(value) == "number" and value > 0 then
			return value
		end
	end
	return 1
end

local function petIncome(name, weight, mutation)
	local entry = PetsData[name]
	local base = type(entry) == "table" and (tonumber(entry.Income) or 0) or 0
	local standard = tonumber(PetAging and PetAging.WeightStandardKG) or 10
	return math.floor(base * (math.max(tonumber(weight) or 1, 1) / standard) * mutationFactor(mutation))
end

local function gatherPets()
	local list = {}
	if PetRenderer and type(PetRenderer.GetAll) == "function" then
		local ok, all = pcall(PetRenderer.GetAll)
		if ok and type(all) == "table" then
			for _, entry in pairs(all) do
				if type(entry) == "table" and entry.Model and entry.Model.Parent and entry.OwnerUserId == LocalPlayer.UserId then
					local model = entry.Model
					local name = model:GetAttribute("PetName") or plainName(model.Name)
					local age = tonumber(model:GetAttribute("Age")) or 1
					local weight = tonumber(model:GetAttribute("Weight")) or 1
					local mutation = model:GetAttribute("Mutation")
					local maxAge = tonumber(PetAging and PetAging.MaxAge) or 100
					local scaled = weight * (multiplierForAge(maxAge) / multiplierForAge(age))
					table.insert(list, {
						Key = entry.PetKey or model:GetAttribute("PetKey") or model.Name,
						Name = name,
						Placed = true,
						Model = model,
						PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"),
						Age = age,
						Weight = weight,
						BaseWeight = weight / multiplierForAge(age),
						CurIncome = petIncome(name, weight, mutation),
						MaxIncome = petIncome(name, scaled, mutation),
						Position = safePivot(model),
					})
				end
			end
		end
	end
	if #list == 0 then
		local plot = getPlot()
		local pets = plot and plot:FindFirstChild("Pets")
		if pets then
			for _, model in ipairs(pets:GetChildren()) do
				if model:IsA("Model") then
					local name = model:GetAttribute("PetName") or plainName(model.Name)
					local age = tonumber(model:GetAttribute("Age")) or 1
					local weight = tonumber(model:GetAttribute("Weight")) or 1
					local mutation = model:GetAttribute("Mutation")
					table.insert(list, {
						Key = model:GetAttribute("PetKey") or model.Name,
						Name = name,
						Placed = true,
						Model = model,
						PrimaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"),
						Age = age,
						Weight = weight,
						BaseWeight = weight / multiplierForAge(age),
						CurIncome = petIncome(name, weight, mutation),
						MaxIncome = petIncome(name, weight * 2, mutation),
						Position = safePivot(model),
					})
				end
			end
		end
	end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool:HasTag("Pet") and tool:GetAttribute("PetKey") then
				local name = tool:GetAttribute("PetName") or plainName(tool.Name)
				local age = tonumber(tool:GetAttribute("Age")) or 1
				local weight = tonumber(tool:GetAttribute("Weight")) or 1
				local mutation = tool:GetAttribute("Mutation")
				table.insert(list, {
					Key = tool:GetAttribute("PetKey"),
					Name = name,
					Placed = false,
					Tool = tool,
					Age = age,
					Weight = weight,
					BaseWeight = weight / multiplierForAge(age),
					CurIncome = petIncome(name, weight, mutation),
					MaxIncome = petIncome(name, weight * 2, mutation),
				})
			end
		end
	end
	for _, entry in ipairs(list) do
		entry.Headroom = (entry.MaxIncome or 0) - (entry.CurIncome or 0)
	end
	return list
end

local function sortPets(list, strategy)
	table.sort(list, function(a, b)
		if strategy == "Best Weight & Rarity" then
			if a.BaseWeight ~= b.BaseWeight then
				return a.BaseWeight > b.BaseWeight
			end
			return a.MaxIncome > b.MaxIncome
		end
		if a.MaxIncome ~= b.MaxIncome then
			return a.MaxIncome > b.MaxIncome
		end
		return a.BaseWeight > b.BaseWeight
	end)
	return list
end

local function placeBestPets(strategy)
	if not PlacePet or not PickupPet then
		return false, "pet remotes missing"
	end
	local list = gatherPets()
	if #list == 0 then
		return false, "no pets found"
	end
	strategy = strategy or config.bestPetsStrategy
	sortPets(list, strategy)
	local limit = math.min(getMaxPets(), #list)
	local keep = {}
	for index = 1, limit do
		keep[list[index].Key] = true
	end
	local freed = {}
	local picked = 0
	for _, entry in ipairs(list) do
		if entry.Placed and not keep[entry.Key] then
			if entry.Position then
				table.insert(freed, entry.Position)
			end
			fire(PickupPet, entry.Key)
			picked = picked + 1
			task.wait(0.2)
		end
	end
	local character = getCharacter()
	local baseplate = getBaseplate()
	local root = getRoot()
	if not character or not baseplate or not root then
		return false, "not near plot"
	end
	local function slotPoint(slot)
		local row = math.floor((slot - 1) / 3)
		local offset = CFrame.new(((slot - 1) % 3 - 1) * 4, 0, -(row * 4 + 8))
		local baseOffset = root.CFrame * offset
		local local3 = baseplate.CFrame:PointToObjectSpace(baseOffset.Position)
		return baseplate.CFrame:PointToWorldSpace(Vector3.new(
			math.clamp(local3.X, -baseplate.Size.X / 2 + 3, baseplate.Size.X / 2 - 3),
			local3.Y,
			math.clamp(local3.Z, -baseplate.Size.Z / 2 + 3, baseplate.Size.Z / 2 - 3)
		))
	end
	local placed = 0
	for index = 1, limit do
		local entry = list[index]
		if not entry.Placed then
			local spot = table.remove(freed, 1) or slotPoint(index)
			if equipTool(entry.Tool, character) then
				fire(PlacePet, entry.Key, spot)
				placed = placed + 1
				task.wait(0.25)
			end
		end
	end
	local humanoid = getHumanoid()
	if humanoid and LocalPlayer:GetAttribute("IsRiding") ~= true then
		pcall(function()
			humanoid:UnequipTools()
		end)
	end
	return true, string.format("placed %d, picked up %d (%s)", placed, picked, strategy)
end

local function bestFood()
	local containers = {getCharacter(), LocalPlayer:FindFirstChild("Backpack")}
	local list = {}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:HasTag("Food") then
					local premium = tool.Name == "Dragonfruit" or tool.Name == "Magic Apple"
					local entry = FoodsData[tool.Name]
					local noFeedAll = type(entry) == "table" and entry.NoFeedAll == true
					local allowed = config.feedFood == "All Foods" or config.feedFood == tool.Name
					if noFeedAll and not config.feedAllowPremium then
						allowed = false
					end
					if premium and not config.feedAllowPremium then
						allowed = false
					end
					local amountNode = find(tool, "Data", "Amount")
					local amount = (amountNode and tonumber(amountNode.Value)) or 1
					if allowed and amount > 0 then
						table.insert(list, {
							Tool = tool,
							Name = tool.Name,
							XP = type(entry) == "table" and (tonumber(entry.XP) or 0) or 0,
						})
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.XP > b.XP
	end)
	return list[1]
end

local function feedPets(allPets)
	if not FeedPet then
		return false, "feed remote missing"
	end
	local placed = {}
	for _, entry in ipairs(gatherPets()) do
		if entry.Placed then
			table.insert(placed, entry)
		end
	end
	if #placed == 0 then
		return false, "no placed pets"
	end

	local mode = config.feedTargetMode
	if mode == "Smart Priority (Highest Headroom)" then
		table.sort(placed, function(a, b)
			if a.Headroom ~= b.Headroom then
				return a.Headroom > b.Headroom
			end
			return a.MaxIncome > b.MaxIncome
		end)
	elseif mode == "Highest Max Income (VIP First)" then
		table.sort(placed, function(a, b)
			if a.MaxIncome ~= b.MaxIncome then
				return a.MaxIncome > b.MaxIncome
			end
			return a.Headroom > b.Headroom
		end)
	elseif mode == "Lowest Level First (Balance Ages)" then
		table.sort(placed, function(a, b)
			if a.Age ~= b.Age then
				return a.Age < b.Age
			end
			return a.Headroom > b.Headroom
		end)
	end

	local food = bestFood()
	if not food then
		return false, "no food in backpack"
	end
	local character = getCharacter()
	if not character or not equipTool(food.Tool, character) then
		return false, "failed to equip food"
	end

	local maxAge = tonumber(PetAging and PetAging.MaxAge) or 100
	local targets = {}
	for _, entry in ipairs(placed) do
		if not (config.feedSkipMaxAge and entry.Age >= maxAge) then
			table.insert(targets, entry)
		end
	end
	if #targets == 0 then
		return false, "all pets at max age"
	end
	if not allPets then
		targets = {targets[1]}
	end

	local root = getRoot()
	local restore = nil
	local fed = 0
	for _, target in ipairs(targets) do
		local part = target.PrimaryPart
		if part and root and restore == nil and (root.Position - part.Position).Magnitude > 7 then
			restore = root.CFrame
			root.CFrame = part.CFrame * CFrame.new(0, 1, 3.5)
			task.wait(0.1)
		end
		if part then
			local prompt = find(part, "Feed") or (target.Model and target.Model:FindFirstChild("Feed", true))
			if prompt and prompt:IsA("ProximityPrompt") then
				pcall(function()
					prompt.HoldDuration = 0
					prompt.RequiresLineOfSight = false
					prompt.MaxActivationDistance = 9999
				end)
				if fireproximityprompt then
					pcall(fireproximityprompt, prompt, 0)
				end
			end
		end
		local rounds = allPets and 1 or 5
		for _ = 1, rounds do
			if target.Model and config.feedSkipMaxAge and tonumber(target.Model:GetAttribute("Age")) >= maxAge then
				break
			end
			local amountNode = find(food.Tool, "Data", "Amount")
			local amount = (amountNode and tonumber(amountNode.Value)) or 0
			if amount <= 0 then
				break
			end
			fire(FeedPet, target.Key, food.Name)
			fed = fed + 1
			task.wait(0.35)
		end
		if allPets then
			break
		end
	end

	if restore and getRoot() then
		getRoot().CFrame = restore
	end
	return true, string.format("fed %d %s to %d pet(s)", fed, food.Name, allPets and #targets or 1)
end

local function dropBasket()
	local basket = LocalPlayer:FindFirstChild("Basket")
	if not basket then
		return 0
	end
	local dropped = 0
	for _, child in ipairs(basket:GetChildren()) do
		fire(BasketDrop, child:GetAttribute("Egg") or child.Name)
		dropped = dropped + 1
		task.wait(0.05)
	end
	return dropped
end

local relayActive = false

local function relayNearBase(baseplate, top)
	local basket = LocalPlayer:FindFirstChild("Basket")
	if not basket or basketCount() == 0 then
		return
	end
	local activeEggs = getActiveEggs()
	local root = getRoot()
	if not activeEggs or not root or not baseplate then
		return
	end
	relayActive = true
	setFarmStatus("dropping eggs near base")
	local offset = baseplate.CFrame:PointToObjectSpace(root.Position)
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 1 then
		flat = Vector3.new(0, 0, 1)
	end
	local unit = flat.Unit
	local extent = unit / math.max(math.abs(unit.X) / (baseplate.Size.X / 2 + 20), math.abs(unit.Z) / (baseplate.Size.Z / 2 + 20))
	local edge = baseplate.CFrame:PointToWorldSpace(Vector3.new(extent.X, 0, extent.Z))
	local dropPosition = Vector3.new(edge.X, top.Y + 4, edge.Z)
	if config.stealMethod == "Instant" then
		instantTo(dropPosition, 4)
	else
		flyTo(dropPosition, 4, nil, {speed = config.returnSpeed})
	end
	root = getRoot()
	if not root or (root.Position - dropPosition).Magnitude > 10 then
		relayActive = false
		return
	end
	local hold = tick() + 0.3
	while tick() < hold do
		local current = getRoot()
		if current then
			pcall(function()
				local rotation = current.CFrame.Rotation
				current.CFrame = CFrame.new(dropPosition) * rotation
				current.AssemblyLinearVelocity = Vector3.zero
			end)
		end
		RunService.Heartbeat:Wait()
	end
	local known = {}
	for _, child in ipairs(activeEggs:GetChildren()) do
		known[child] = true
	end
	local names = {}
	for _, child in ipairs(basket:GetChildren()) do
		local eggName = child:GetAttribute("Egg")
		if type(eggName) == "string" and eggName ~= "" then
			table.insert(names, eggName)
		end
	end
	for _, eggName in ipairs(names) do
		fire(BasketDrop, eggName)
	end
	local landed = {}
	local deadline = tick() + 3
	while #landed < #names and tick() < deadline do
		for _, child in ipairs(activeEggs:GetChildren()) do
			if not known[child] and child:GetAttribute("OriginPosition") ~= nil and typeof(child:GetAttribute("Position")) == "Vector3" then
				known[child] = true
				table.insert(landed, child)
			end
		end
		RunService.Heartbeat:Wait()
	end
	for _, child in ipairs(landed) do
		local position = child:GetAttribute("Position")
		for _ = 1, 3 do
			if child.Parent == nil then
				break
			end
			if typeof(position) == "Vector3" then
				if config.stealMethod == "Instant" then
					instantTo(position + Vector3.new(0, 3, 0), 5)
				else
					flyTo(position + Vector3.new(0, 3, 0), 5, nil)
				end
			end
			local before = basketCount()
			state.lastPickup = tick()
			fire(EggPickup, child.Name)
			local waitDeadline = tick() + 1.5
			while basketCount() == before and tick() < waitDeadline do
				RunService.Heartbeat:Wait()
			end
			if basketCount() > before then
				break
			end
			position = child:GetAttribute("Position")
		end
	end
	state.pickupPos = dropPosition
	relayActive = false
end

local function deliverToPlot()
	local plot = getPlot()
	local baseplate = getBaseplate()
	if not plot or not baseplate then
		return false
	end
	escapeVolcano()
	setFarmStatus("delivering to plot")
	local top = baseplate.Position + Vector3.new(0, 3.5, 0)
	local root = getRoot()
	if root and (root.Position - top).Magnitude > 15 then
		local pickupPosition = state.pickupPos
		if pickupPosition and (pickupPosition - top).Magnitude > RELAY_DISTANCE then
			relayNearBase(baseplate, top)
			setFarmStatus("delivering to plot")
		end
		if config.stealMethod == "Instant" then
			instantTo(top, 6)
		else
			flyTo(top, 6, function()
				return not (enabled.farm or enabled.plant or enabled.hatch)
			end, {speed = config.returnSpeed})
		end
	end
	stopMotion()
	root = getRoot()
	if not root then
		return false
	end
	local deadline = tick() + 2
	while basketCount() > 0 and tick() < deadline do
		if firetouchinterest then
			pcall(firetouchinterest, root, baseplate, 0)
			task.wait(0.04)
			pcall(firetouchinterest, root, baseplate, 1)
		end
		task.wait(0.05)
	end
	if basketCount() > 0 then
		root.CFrame = CFrame.new(baseplate.Position + Vector3.new(0, 5, 0))
		stopMotion()
		deadline = tick() + 1.5
		while basketCount() > 0 and tick() < deadline do
			if firetouchinterest then
				pcall(firetouchinterest, root, baseplate, 0)
				task.wait(0.04)
				pcall(firetouchinterest, root, baseplate, 1)
			end
			task.wait(0.05)
		end
	end
	if basketCount() == 0 then
		state.lastPickup = 0
		state.pickupPos = nil
	end
	if enabled.hatch then
		setFarmStatus("hatching eggs")
		hatchReadyEggs()
	end
	if enabled.plant then
		setFarmStatus("placing eggs")
		placeEggs()
	end
	if enabled.unlockNests then
		unlockNests()
	end
	setFarmStatus("delivery complete")
	return basketCount() == 0
end

local espFolder = nil
local tracerAttachment = nil

local function getEspFolder()
	if espFolder and espFolder.Parent then
		return espFolder
	end
	local existing = Workspace:FindFirstChild("AntiGodHubESP")
	if existing then
		existing:Destroy()
	end
	espFolder = Instance.new("Folder")
	espFolder.Name = "AntiGodHubESP"
	espFolder.Parent = Workspace
	return espFolder
end

local function espRemove(model)
	local entry = state.espEntries[model]
	if not entry then
		return
	end
	for _, key in ipairs({"Highlight", "Billboard", "Tracer", "TracerAttachment", "Anchor"}) do
		local instance = entry[key]
		if instance then
			pcall(function()
				instance:Destroy()
			end)
		end
	end
	state.espEntries[model] = nil
end

local function espClear()
	for model in pairs(state.espEntries) do
		espRemove(model)
	end
	state.espEntries = {}
	state.espFound = 0
	state.espNearest = "None"
	state.espNearestDistance = 0
	state.espTop = "None"
	state.espTopRarity = "None"
	state.espTopDistance = 0
	if tracerAttachment then
		pcall(function()
			tracerAttachment:Destroy()
		end)
		tracerAttachment = nil
	end
	local folder = Workspace:FindFirstChild("AntiGodHubESP")
	if folder then
		pcall(function()
			folder:Destroy()
		end)
	end
	espFolder = nil
end

local function espVisualPart(model, entry)
	if entry.VisualPart and entry.VisualPart.Parent then
		return entry.VisualPart
	end
	local part = model.PrimaryPart
	if not part or not part:IsA("BasePart") then
		local hitbox = model:FindFirstChild("Hitbox", true)
		part = (hitbox and hitbox:IsA("BasePart")) and hitbox or model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part then
		part = Instance.new("Part")
		part.Name = "AntiGodESPAnchor"
		part.Size = Vector3.new(0.2, 0.2, 0.2)
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.CFrame = model:GetPivot()
		part.Parent = getEspFolder()
		entry.Anchor = part
	end
	entry.VisualPart = part
	return part
end

local function espColor(rarity, mutation)
	if mutation and mutation ~= "" and MUTATION_COLORS[mutation] then
		return MUTATION_COLORS[mutation]
	end
	return RARITY_COLORS[rarity] or RARITY_COLORS.Unknown
end

local function applyEspPreset(preset)
	if preset == "All Visuals (Highlight + Text + Tracer)" then
		enabled.espHighlight = true
		enabled.espLabel = true
		enabled.espTracer = true
	elseif preset == "Highlights + Floating Text" then
		enabled.espHighlight = true
		enabled.espLabel = true
		enabled.espTracer = false
	elseif preset == "Floating Text Only (Clean)" then
		enabled.espHighlight = false
		enabled.espLabel = true
		enabled.espTracer = false
	elseif preset == "Highlights Only (Minimal)" then
		enabled.espHighlight = true
		enabled.espLabel = false
		enabled.espTracer = false
	elseif preset == "Tracers Only" then
		enabled.espHighlight = false
		enabled.espLabel = false
		enabled.espTracer = true
	end
	espClear()
end

local function espUpdate(model)
	if not model or not model.Parent then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	local rarity = eggRarity(model.Name)
	local rarityWeight = RARITY_WEIGHT[rarity] or 0
	if rarityWeight < (RARITY_FLOOR[config.espMinRarity] or 500) then
		espRemove(model)
		return
	end
	local position = safePivot(model)
	if not position then
		espRemove(model)
		return
	end
	local distance = (position - root.Position).Magnitude
	if distance > math.max(100, tonumber(config.espMaxDistance) or 5000) then
		espRemove(model)
		return
	end

	local entry = state.espEntries[model]
	if not entry then
		entry = {}
		state.espEntries[model] = entry
	end

	local weight = eggWeight(model)
	local mutation = eggMutation(model)
	local color = espColor(rarity, mutation)
	local visualPart = espVisualPart(model, entry)
	if entry.Anchor and entry.Anchor.Parent then
		entry.Anchor.CFrame = model:GetPivot()
	end

	if enabled.espHighlight then
		local highlight = entry.Highlight
		if not highlight or not highlight.Parent then
			highlight = Instance.new("Highlight")
			highlight.Name = "AntiGodHighlight"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.FillTransparency = 0.82
			highlight.OutlineTransparency = 0.04
			highlight.Parent = getEspFolder()
			entry.Highlight = highlight
		end
		highlight.Adornee = model
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.Enabled = true
	elseif entry.Highlight then
		entry.Highlight.Enabled = false
	end

	if enabled.espLabel then
		local billboard = entry.Billboard
		if not billboard or not billboard.Parent then
			billboard = Instance.new("BillboardGui")
			billboard.Name = "AntiGodLabel"
			billboard.Size = UDim2.fromOffset(210, 52)
			billboard.StudsOffset = Vector3.new(0, 3.75, 0)
			billboard.AlwaysOnTop = true
			billboard.LightInfluence = 0
			billboard.ResetOnSpawn = false
			billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			billboard.Parent = getEspFolder()
			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.BackgroundTransparency = 1
			title.Size = UDim2.new(1, 0, 0, 25)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 14
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.TextStrokeTransparency = 0.25
			title.Parent = billboard
			local details = Instance.new("TextLabel")
			details.Name = "Details"
			details.BackgroundTransparency = 1
			details.Size = UDim2.new(1, 0, 0, 22)
			details.Position = UDim2.new(0, 0, 0, 24)
			details.Font = Enum.Font.GothamMedium
			details.TextSize = 12
			details.TextXAlignment = Enum.TextXAlignment.Center
			details.TextStrokeTransparency = 0.35
			details.TextColor3 = Color3.fromRGB(235, 240, 255)
			details.Parent = billboard
			entry.Billboard = billboard
			entry.TitleLabel = title
			entry.DetailLabel = details
		end
		billboard.Adornee = visualPart
		billboard.Enabled = true
		billboard.MaxDistance = math.max(100, tonumber(config.espMaxDistance) or 5000)
		entry.TitleLabel.Text = string.format("%s [%s]", model.Name, rarity)
		entry.TitleLabel.TextColor3 = color
		local parts = {}
		if weight > 0 then
			table.insert(parts, formatWeight(weight))
		end
		if mutation and mutation ~= "" then
			table.insert(parts, tostring(mutation))
		end
		table.insert(parts, string.format("%d studs", math.floor(distance + 0.5)))
		entry.DetailLabel.Text = table.concat(parts, " | ")
	elseif entry.Billboard then
		entry.Billboard.Enabled = false
	end

	if enabled.espTracer then
		local attachment = tracerAttachment
		if not attachment or attachment.Parent ~= root then
			if attachment then
				pcall(function()
					attachment:Destroy()
				end)
			end
			attachment = Instance.new("Attachment")
			attachment.Name = "AntiGodTracer"
			attachment.Position = Vector3.new(0, 1.5, 0)
			attachment.Parent = root
			tracerAttachment = attachment
		end
		if visualPart:IsA("BasePart") then
			if not entry.TracerAttachment or entry.TracerAttachment.Parent ~= visualPart then
				if entry.TracerAttachment then
					pcall(function()
						entry.TracerAttachment:Destroy()
					end)
				end
				local target = Instance.new("Attachment")
				target.Name = "AntiGodTracerTarget"
				target.Parent = visualPart
				entry.TracerAttachment = target
			end
			local beam = entry.Tracer
			if not beam or not beam.Parent then
				beam = Instance.new("Beam")
				beam.Name = "AntiGodTracerBeam"
				beam.Attachment0 = attachment
				beam.Attachment1 = entry.TracerAttachment
				beam.FaceCamera = true
				beam.Width0 = 0.055
				beam.Width1 = 0.03
				beam.LightEmission = 1
				beam.Segments = 6
				beam.Transparency = NumberSequence.new(0.1)
				beam.Parent = getEspFolder()
				entry.Tracer = beam
			end
			beam.Attachment0 = attachment
			beam.Attachment1 = entry.TracerAttachment
			beam.Enabled = true
			beam.Color = ColorSequence.new(color)
		end
	elseif entry.Tracer then
		entry.Tracer.Enabled = false
	end
end

local function doEsp()
	if not enabled.esp then
		espClear()
		return
	end
	local rendered = getRenderedEggs()
	if not rendered then
		espClear()
		return
	end
	local root = getRoot()
	if not root then
		espClear()
		return
	end
	local seen = {}
	local found = 0
	local nearestName, nearestDistance = nil, math.huge
	local topName, topRarity, topDistance = nil, nil, nil
	for _, model in ipairs(rendered:GetChildren()) do
		if model:IsA("Model") then
			seen[model] = true
			local rarity = eggRarity(model.Name)
			local position = safePivot(model)
			if position then
				local distance = (position - root.Position).Magnitude
				if (RARITY_WEIGHT[rarity] or 0) >= (RARITY_FLOOR[config.espMinRarity] or 500)
					and distance <= math.max(100, tonumber(config.espMaxDistance) or 5000) then
					found = found + 1
					if distance < nearestDistance then
						nearestDistance = distance
						nearestName = model.Name
					end
					if not topRarity or (RARITY_RANK[rarity] or 1) > (RARITY_RANK[topRarity] or 1) then
						topRarity = rarity
						topName = model.Name
						topDistance = distance
					elseif rarity == topRarity and distance < (topDistance or math.huge) then
						topName = model.Name
						topDistance = distance
					end
					pcall(espUpdate, model)
				end
			end
		end
	end
	for model in pairs(state.espEntries) do
		if not seen[model] or not model.Parent then
			espRemove(model)
		end
	end
	state.espFound = found
	state.espNearest = nearestName or "None"
	state.espNearestDistance = nearestDistance == math.huge and 0 or math.floor(nearestDistance)
	state.espTop = topName or "None"
	state.espTopRarity = topRarity or "None"
	state.espTopDistance = math.floor(topDistance or 0)
end

local function doAutoFarm()
	if not enabled.farm or relayActive then
		return
	end
	if basketCount() >= basketCapacity() then
		deliverToPlot()
		return
	end
	local target = pickFarmTarget()
	if not target then
		state.target = "None"
		state.targetRarity = "None"
		state.targetWeight = 0
		if target and target.WaitingWeather then
			setFarmStatus(string.format("waiting for %s (%ds)", target.MutationType, target.TimeLeft or 0))
		else
			setFarmStatus("searching for eggs")
		end
		return
	end
	if target.WaitingWeather then
		setFarmStatus(string.format("waiting for %s (%ds)", target.MutationType, target.TimeLeft or 0))
		return
	end
	if target.Name == "Volcanic Egg" then
		if not enterVolcano() then
			setFarmStatus("volcano warp failed")
			return
		end
		local root = getRoot()
		if root then
			stopMotion()
			root.CFrame = CFrame.new(target.Position.X, target.Position.Y + 2, target.Position.Z)
		end
	else
		local arrived = flyTo(target.Position, 6, function()
			return not (enabled.farm or enabled.rebirthPet)
		end, routeOptions())
		if not arrived then
			setFarmStatus("repositioning")
			return
		end
		local root = getRoot()
		if root and target.Position then
			stopMotion()
			root.CFrame = CFrame.new(target.Position.X, target.Position.Y + 2, target.Position.Z)
		end
	end

	state.target = target.Name
	state.targetRarity = target.RebirthPet and (string.format("%s (%s)", target.Rarity, target.RebirthPet)) or target.Rarity
	state.targetWeight = target.EggWeight or 0
	setFarmStatus("collecting " .. target.Name)

	local collected = collectEgg(target)
	if not collected then
		setFarmStatus("missed " .. target.Name)
		farmCooldown[target.Name] = tick() + 3
		task.wait(0.2)
		return
	end
	state.collected = state.collected + 1
	setFarmStatus("delivering " .. target.Name)
	deliverToPlot()
end

local function doAutoRebirth()
	if not enabled.rebirthPet then
		return
	end
	local info = rebirthState()
	if info.capped or not info.canRebirth then
		return
	end
	setFarmStatus("rebirthing tier " .. info.nextTier)
	fire(RebirthRemote)
	task.wait(2.5)
end

local function doAutoHatch()
	if not enabled.hatch then
		return
	end
	local count = hatchReadyEggs()
	if count > 0 then
		setFarmStatus("hatched " .. count .. " eggs")
	end
end

local function doAutoPlant()
	if not enabled.plant then
		return
	end
	if enabled.hatch then
		hatchReadyEggs()
	end
	placeEggs()
end

local function doAutoFeed(allPets)
	if not enabled.feed then
		return
	end
	if state.moving then
		return
	end
	local ok, message = feedPets(allPets)
	if ok then
		setFarmStatus(tostring(message))
	end
end

local function doAutoBestPets()
	if not enabled.bestPets then
		return
	end
	local ok, message = placeBestPets(config.bestPetsStrategy)
	if ok then
		setFarmStatus("best pets done")
	end
end

local function doAutoUnlock()
	if not enabled.unlockNests then
		return
	end
	if unlockNests() > 0 then
		setFarmStatus("unlocking nests")
	end
end

local function doAutoLuck()
	if not enabled.upgradeLuck then
		return
	end
	upgradeLuck()
end

local function doAntiRagdoll()
	if not enabled.antiRagdoll then
		return
	end
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	end)
	if humanoid.PlatformStand then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
	local root = getRoot()
	if root then
		pcall(function()
			if root.AssemblyLinearVelocity.Magnitude > 120 then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
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
local function setAntiAfk(value)
	if value and not afkConnection then
		afkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	elseif not value and afkConnection then
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
local function setFpsBoost(value)
	if value and not fpsOriginals then
		fpsOriginals = {
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			Brightness = Lighting.Brightness,
		}
		pcall(function()
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			Lighting.Brightness = 1
			settings().Rendering.QualityLevel = 1
		end)
	elseif not value and fpsOriginals then
		pcall(function()
			Lighting.GlobalShadows = fpsOriginals.GlobalShadows
			Lighting.FogEnd = fpsOriginals.FogEnd
			Lighting.Brightness = fpsOriginals.Brightness
		end)
		fpsOriginals = nil
	end
end

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
	red = "#FF6B6B",
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

local FarmingTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "zap" })
local PlotTab = Tabs.Main:AddSubTab({ Name = "Plot", Icon = "play" })
local EspTab = Tabs.Main:AddSubTab({ Name = "ESP", Icon = "eye" })
local PlayerTab = Tabs.Main:AddSubTab({ Name = "Player", Icon = "swords" })

local FarmBox = box(FarmingTab, "Auto Farm", "zap", "Left")
FarmBox:AddToggle("AutoFarm", { Text = "Master Auto Farm", Default = false, Callback = function(value)
	enabled.farm = value
end })
FarmBox:AddDropdown("FarmMode", {
	Text = "Farm Mode",
	Values = {"Safe Tween", "Instant"},
	Default = config.farmMode,
	Callback = function(value)
		config.farmMode = value
	end,
})
FarmBox:AddDropdown("StealMethod", {
	Text = "Steal Method",
	Values = {"Tween", "Instant"},
	Default = config.stealMethod,
	Callback = function(value)
		config.stealMethod = tostring(value) == "Instant" and "Instant" or "Tween"
	end,
})
FarmBox:AddDropdown("StealApproach", {
	Text = "Steal Approach",
	Values = {"Normal", "Under Map", "Over Map"},
	Default = config.stealApproach,
	Callback = function(value)
		local choice = tostring(value)
		if choice == "Normal" or choice == "Over Map" then
			config.stealApproach = choice
		else
			config.stealApproach = "Under Map"
		end
	end,
})
FarmBox:AddSlider("TravelSpeed", {
	Text = "Travel Speed",
	Min = 100,
	Max = 10000,
	Default = config.travelSpeed,
	Increment = 50,
	Callback = function(value)
		config.travelSpeed = math.clamp(tonumber(value) or 2000, 100, 10000)
	end,
})
FarmBox:AddDropdown("MinFarmRarity", {
	Text = "Minimum Egg Rarity",
	Values = RARITY_CHOICES,
	Default = config.minRarity,
	Callback = function(value)
		config.minRarity = value
	end,
})
FarmBox:AddDropdown("TargetEgg", {
	Text = "Target Specific Egg",
	Values = EGG_CHOICES,
	Default = config.targetEgg,
	Callback = function(value)
		config.targetEgg = value
	end,
})
FarmBox:AddDropdown("FarmPriority", {
	Text = "Target Priority Order",
	Values = SORT_MODES,
	Default = config.priority,
	Callback = function(value)
		config.priority = value
	end,
})
FarmBox:AddSlider("MinEggWeight", {
	Text = "Minimum Egg Weight (KG)",
	Min = 0,
	Max = 10000,
	Default = 0,
	Increment = 10,
	Callback = function(value)
		config.minEggWeight = tonumber(value) or 0
	end,
})
FarmBox:AddToggle("PrioritizeHeaviest", { Text = "Prioritize Heaviest Eggs", Default = true, Callback = function(value)
	config.prioritizeHeaviest = value
end })
FarmBox:AddSlider("SyncDelay", {
	Text = "Pickup Sync Delay",
	Min = 0.1,
	Max = 1.5,
	Default = config.syncDelay,
	Increment = 0.05,
	Callback = function(value)
		config.syncDelay = tonumber(value) or 0.35
	end,
})

local MutationBox = box(FarmingTab, "Mutation Sniper", "skull", "Left")
MutationBox:AddToggle("PrioritizeMutations", { Text = "Prioritize Mutated Eggs", Default = true, Callback = function(value)
	enabled.farmMutations = value
end })
MutationBox:AddDropdown("MutationTier", {
	Text = "Minimum Mutation Tier",
	Values = MUTATION_CHOICES,
	Default = config.mutationTier,
	Callback = function(value)
		config.mutationTier = value
	end,
})
MutationBox:AddToggle("WeatherEggWait", { Text = "Wait for Storm Mutations", Default = false, Callback = function(value)
	enabled.weatherWait = value
end })

local VolcanoBox = box(FarmingTab, "Volcano & Lava", "flame", "Left")
VolcanoBox:AddToggle("AutoMagmaDip", { Text = "Auto Lava Dip (Magma)", Default = false, Callback = function(value)
	enabled.magmaDip = value
end })

local RebirthBox = box(FarmingTab, "Auto Rebirth", "award", "Left")
RebirthBox:AddToggle("MasterAutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirthPet = value
	if value then
		enabled.hatch = true
		enabled.plant = true
	end
end })

local StatusBox = box(FarmingTab, "Farm Status", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("TargetLabel", { Text = paint("Target -", "None", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("TargetWeightLabel", { Text = paint("Target Weight -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("CashLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("CollectedLabel", { Text = paint("Collected -", "0", COLORS.orange), DoesWrap = true })

local RebirthStatusBox = box(FarmingTab, "Rebirth Status", "user", "Right")
RebirthStatusBox:AddLabel("RebirthTierLabel", { Text = paint("Tier -", "0 -> 1", COLORS.accent), DoesWrap = true })
RebirthStatusBox:AddLabel("RebirthPetLabel", { Text = paint("Required Pet -", "N/A", COLORS.user), DoesWrap = true })
RebirthStatusBox:AddLabel("RebirthCashLabel", { Text = paint("Rebirth Cash -", "0 / 0", COLORS.gold), DoesWrap = true })
RebirthStatusBox:AddLabel("IncubatingLabel", { Text = paint("Incubating -", "None", COLORS.orange), DoesWrap = true })

local PlotBox = box(PlotTab, "Plot Eggs", "play", "Left")
PlotBox:AddToggle("AutoPlant", { Text = "Auto-Plant Eggs", Default = false, Callback = function(value)
	enabled.plant = value
end })
PlotBox:AddToggle("SpawnNest", { Text = "Use Nests (15 Slots)", Default = false, Callback = function(value)
	enabled.spawnNest = value
end })
PlotBox:AddToggle("AutoHatch", { Text = "Auto Hatch Ready Eggs", Default = false, Callback = function(value)
	enabled.hatch = value
end })
PlotBox:AddToggle("AutoUnlockNests", { Text = "Auto Unlock Nests", Default = false, Callback = function(value)
	enabled.unlockNests = value
end })
PlotBox:AddToggle("AutoUpgradeLuck", { Text = "Auto Upgrade Hatch Luck", Default = false, Callback = function(value)
	enabled.upgradeLuck = value
end })
local PetsBox = box(PlotTab, "Pets", "user", "Left")
PetsBox:AddToggle("AutoPlaceBestPets", { Text = "Auto Place Best Pets", Default = false, Callback = function(value)
	enabled.bestPets = value
end })
PetsBox:AddDropdown("BestPetsStrategy", {
	Text = "Best Pets Strategy",
	Values = {"Smart Best Income", "Best Weight & Rarity"},
	Default = config.bestPetsStrategy,
	Callback = function(value)
		config.bestPetsStrategy = value
	end,
})
PetsBox:AddDivider()
PetsBox:AddToggle("AutoFeedPets", { Text = "Auto Feed Pets", Default = false, Callback = function(value)
	enabled.feed = value
end })
PetsBox:AddDropdown("FeedTargetMode", {
	Text = "Feed Priority",
	Values = {"Smart Priority (Highest Headroom)", "Highest Max Income (VIP First)", "Lowest Level First (Balance Ages)"},
	Default = config.feedTargetMode,
	Callback = function(value)
		config.feedTargetMode = value
	end,
})
PetsBox:AddDropdown("FeedFood", {
	Text = "Food Filter",
	Values = FOOD_CHOICES,
	Default = config.feedFood,
	Callback = function(value)
		config.feedFood = value
	end,
})
PetsBox:AddToggle("FeedAllowPremium", { Text = "Allow Premium Food", Default = true, Callback = function(value)
	config.feedAllowPremium = value
end })
PetsBox:AddToggle("FeedSkipMaxAge", { Text = "Skip Max Age Pets", Default = true, Callback = function(value)
	config.feedSkipMaxAge = value
end })

local PlotStatusBox = box(PlotTab, "Plot Status", "activity", "Right")
PlotStatusBox:AddLabel("EggsPlantedLabel", { Text = paint("Eggs Planted -", "0", COLORS.gold), DoesWrap = true })
PlotStatusBox:AddLabel("NestsLabel", { Text = paint("Nests -", "0/0", COLORS.user), DoesWrap = true })
PlotStatusBox:AddLabel("PetsLabel", { Text = paint("Pets Placed -", "0/5", COLORS.orange), DoesWrap = true })
PlotStatusBox:AddLabel("VolcanoLabel", { Text = paint("Volcano -", "no", COLORS.red), DoesWrap = true })

local EspBox = box(EspTab, "Egg ESP", "eye", "Left")
EspBox:AddToggle("EggESP", { Text = "Egg ESP", Default = false, Callback = function(value)
	enabled.esp = value
	if not value then
		espClear()
	end
end })
EspBox:AddDropdown("EspPreset", {
	Text = "Visual Mode",
	Values = {"All Visuals (Highlight + Text + Tracer)", "Highlights + Floating Text", "Floating Text Only (Clean)", "Highlights Only (Minimal)", "Tracers Only"},
	Default = "Highlights + Floating Text",
	Callback = function(value)
		applyEspPreset(value)
	end,
})
EspBox:AddDropdown("EspMinRarity", {
	Text = "Minimum ESP Rarity",
	Values = RARITY_CHOICES,
	Default = config.espMinRarity,
	Callback = function(value)
		config.espMinRarity = value
		espClear()
	end,
})
EspBox:AddSlider("EspMaxDistance", {
	Text = "Max Render Distance",
	Min = 500,
	Max = 15000,
	Default = config.espMaxDistance,
	Increment = 250,
	Callback = function(value)
		config.espMaxDistance = tonumber(value) or 5000
	end,
})
EspBox:AddToggle("EspHighlight", { Text = "Highlights", Default = true, Callback = function(value)
	enabled.espHighlight = value
	espClear()
end })
EspBox:AddToggle("EspLabel", { Text = "Floating Labels", Default = true, Callback = function(value)
	enabled.espLabel = value
	espClear()
end })
EspBox:AddToggle("EspTracer", { Text = "Tracers", Default = false, Callback = function(value)
	enabled.espTracer = value
	espClear()
end })

local EspStatusBox = box(EspTab, "ESP Status", "activity", "Right")
EspStatusBox:AddLabel("EspStatusLabel", { Text = paint("ESP -", "off", COLORS.accent), DoesWrap = true })
EspStatusBox:AddLabel("EspFoundLabel", { Text = paint("Eggs Tracked -", "0", COLORS.gold), DoesWrap = true })
EspStatusBox:AddLabel("EspTopLabel", { Text = paint("Best Egg -", "None", COLORS.user), DoesWrap = true })
EspStatusBox:AddLabel("EspDistLabel", { Text = paint("Distance -", "0 studs", COLORS.orange), DoesWrap = true })

local MovementBox = box(PlayerTab, "Movement", "cpu", "Left")
MovementBox:AddToggle("AntiRagdoll", { Text = "Anti Ragdoll", Default = true, Callback = function(value)
	enabled.antiRagdoll = value
end })
MovementBox:AddLabel("AntiRagdollStatusLabel", { Text = paint("Ragdoll -", "protected", COLORS.user), DoesWrap = true })

local TeleportBox = box(PlayerTab, "Teleports", "play", "Left")
local TELEPORT_SPOTS = {"Plot", "Nests", "Hatch Upgrades", "Map Center", "Volcano Top", "Volcano Entrance", "Closest Egg"}
local teleportSpot = TELEPORT_SPOTS[1]
TeleportBox:AddDropdown("TeleportSpot", {
	Text = "Teleport Area",
	Values = TELEPORT_SPOTS,
	Default = teleportSpot,
	Callback = function(value)
		teleportSpot = tostring(value)
	end,
})
TeleportBox:AddButton({ Text = "Teleport", Func = function()
	local root = getRoot()
	if not root then
		pcall(function()
			Library:Notify("No character")
		end)
		return
	end
	stopMotion()
	local plot = getPlot()
	if teleportSpot == "Plot" then
		local top = getPlotTop()
		fire(TeleportToPlot)
		if top then
			root.CFrame = CFrame.new(top + Vector3.new(0, 3, 0))
		end
	elseif teleportSpot == "Nests" then
		local position = safePivot(plot and plot:FindFirstChild("Nests"))
		if position then
			root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		end
	elseif teleportSpot == "Hatch Upgrades" then
		local position = safePivot(plot and plot:FindFirstChild("HatchUpgrade"))
		if position then
			root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		end
	elseif teleportSpot == "Map Center" then
		root.CFrame = CFrame.new(MAP_CENTER + Vector3.new(0, 3, 0))
	elseif teleportSpot == "Volcano Top" then
		if enterVolcano() then
			local current = getRoot()
			if current then
				stopMotion()
				current.CFrame = CFrame.new(VOLCANO_TOP)
			end
		else
			pcall(function()
				Library:Notify("Volcano warp failed")
			end)
		end
	elseif teleportSpot == "Volcano Entrance" then
		root.CFrame = VOLCANO_SKY
	elseif teleportSpot == "Closest Egg" then
		local target = pickFarmTarget()
		if target and not target.WaitingWeather and target.Position then
			root.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
		else
			pcall(function()
				Library:Notify("No egg found")
			end)
		end
	end
end })

local PlayerStatusBox = box(PlayerTab, "Player Status", "activity", "Right")
PlayerStatusBox:AddLabel("PlayerStatusLabel", { Text = paint("Player -", "idle", COLORS.accent), DoesWrap = true })
PlayerStatusBox:AddLabel("PositionLabel", { Text = paint("Position -", "0, 0, 0", COLORS.gold), DoesWrap = true })
PlayerStatusBox:AddLabel("FarmModeLabel", { Text = paint("Farm Mode -", config.farmMode, COLORS.orange), DoesWrap = true })

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
	setLabel("TargetLabel", paint("Target -", state.target .. " [" .. state.targetRarity .. "]", COLORS.accent))
	setLabel("TargetWeightLabel", paint("Target Weight -", (tonumber(state.targetWeight) or 0) > 0 and formatWeight(state.targetWeight) or "None", COLORS.orange))
	setLabel("CashLabel", paint("Cash -", "$" .. abbreviateNumber(getCash()), COLORS.gold))
	setLabel("CollectedLabel", paint("Collected -", state.collected, COLORS.orange))

	local info = rebirthState()
	setLabel("RebirthTierLabel", paint("Tier -", string.format("%d -> %d", info.current, info.nextTier), COLORS.accent))
	setLabel("RebirthPetLabel", paint("Required Pet -", info.pet .. (info.hasPet and (" (owned - " .. tostring(info.petLocation) .. ")") or " (missing)"), COLORS.user))
	setLabel("RebirthCashLabel", paint("Rebirth Cash -", string.format("%s / %s (%s)", abbreviateNumber(info.cash), abbreviateNumber(info.cost), info.cash >= info.cost and "ok" or "short"), COLORS.gold))
	setLabel("IncubatingLabel", paint("Incubating -", info.incubating and (tostring(info.incubatingEgg) .. " (" .. tostring(info.incubatingTime) .. ")") or (info.hasPet and "Pet owned" or "None"), COLORS.orange))

	local unlocked, occupied = getNestCounts()
	setLabel("EggsPlantedLabel", paint("Eggs Planted -", getEggsPlanted(), COLORS.gold))
	setLabel("NestsLabel", paint("Nests -", string.format("%d unlocked / %d busy", unlocked, occupied), COLORS.user))
	setLabel("PetsLabel", paint("Pets Placed -", string.format("%d/%d", getPetsPlaced(), getMaxPets()), COLORS.orange))
	setLabel("VolcanoLabel", paint("Volcano -", LocalPlayer:GetAttribute("InVolcano") == true and "yes" or "no", COLORS.red))

	setLabel("EspStatusLabel", paint("ESP -", enabled.esp and "on" or "off", COLORS.accent))
	setLabel("EspFoundLabel", paint("Eggs Tracked -", state.espFound, COLORS.gold))
	setLabel("EspTopLabel", paint("Best Egg -", state.espTop .. " [" .. state.espTopRarity .. "]", COLORS.user))
	setLabel("EspDistLabel", paint("Distance -", state.espTopDistance .. " studs", COLORS.orange))

	local root = getRoot()
	setLabel("PlayerStatusLabel", paint("Player -", getHumanoid() and "alive" or "no character", COLORS.accent))
	setLabel("PositionLabel", paint("Position -", root and string.format("%d, %d, %d", root.Position.X, root.Position.Y, root.Position.Z) or "n/a", COLORS.gold))
	setLabel("AntiRagdollStatusLabel", paint("Ragdoll -", enabled.antiRagdoll and "protected" or "off", COLORS.user))
	setLabel("FarmModeLabel", paint("Farm Mode -", tostring(config.farmMode), COLORS.orange))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
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

LocalPlayer.CharacterAdded:Connect(function(character)
	if not enabled.antiRagdoll then
		return
	end
	local ragdoll = find(character, "Ragdoll")
	if ragdoll and ragdoll:IsA("LocalScript") then
		pcall(function()
			ragdoll.Disabled = true
		end)
	end
	local humanoid = character:WaitForChild("Humanoid", 5)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid then
		return
	end
	if enabled.antiRagdoll then
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		end)
	end
	humanoid.StateChanged:Connect(function(_, newState)
		if not enabled.antiRagdoll then
			return
		end
		if newState == Enum.HumanoidStateType.Ragdoll
			or newState == Enum.HumanoidStateType.Physics
			or newState == Enum.HumanoidStateType.FallingDown then
			pcall(function()
				humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
			if root and root:IsA("BasePart") then
				pcall(function()
					root.AssemblyLinearVelocity = Vector3.zero
				end)
			end
		end
	end)
end)

pcall(function()
	local net = find(ReplicatedStorage, "packages", "Net")
	local ragdoll = net and (net:FindFirstChild("RE/Ragdoll") or net:FindFirstChild("Ragdoll", true))
	if ragdoll and ragdoll:IsA("RemoteEvent") then
		ragdoll.OnClientEvent:Connect(function(active)
			if not active or not enabled.antiRagdoll then
				return
			end
			local humanoid = getHumanoid()
			if humanoid then
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end)
			end
			stopMotion()
		end)
	end
end)

local renderedEggs = getRenderedEggs()
if renderedEggs then
	renderedEggs.ChildAdded:Connect(function(child)
		if enabled.esp then
			task.defer(function()
				pcall(espUpdate, child)
			end)
		end
	end)
end
Workspace.ChildAdded:Connect(function(child)
	if child.Name == "RenderedEggs" then
		child.ChildAdded:Connect(function(egg)
			if enabled.esp then
				task.defer(function()
					pcall(espUpdate, egg)
				end)
			end
		end)
	end
end)

chain({ doAutoFarm }, 0.2)
chain({ doAutoRebirth }, 0.8)
chain({ dipMagma }, 1.2)
loop(doEsp, 0.35)
loop(doAutoHatch, 0.4)
loop(doAutoPlant, 0.6)
loop(doAntiRagdoll, 0.2)
loop(doAutoUnlock, 1.5)
loop(doAutoLuck, 1.5)
loop(doAutoBestPets, 10)
loop(function()
	if enabled.feed and not state.moving then
		pcall(doAutoFeed, false)
	end
end, 3)

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
task.spawn(function()
	local lastStorm = nil
	while session.running do
		task.wait(2)
		local storm = pcall(getStorm) and getStorm()
		local key = storm and (tostring(storm.Variant) .. tostring(storm.EndsAt or "")) or nil
		if key ~= lastStorm then
			lastStorm = key
			pcall(function()
				Library:Notify(storm and ("Weather: " .. tostring(storm.Variant)) or "Weather ended")
			end)
		end
	end
end)

Library:OnUnload(function()
	session.running = false
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	espClear()
	local root = getRoot()
	if root then
		clearFlightStabilizer(root, getHumanoid())
	end
	state.moving = false
	state.volcano = false
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()
end)()