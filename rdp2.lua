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
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local copyText = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request)

local CONFIG = {
	Title = "AntiGodHub",
	Icon = 80985370671515,
	Discord = "https://discord.gg/jdJvZm6VdK",
	Website = "https://rscripts.net/@AntiGodHub",
	Version = "v2.0",
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
	rebirth = false,
	magmaDip = false,
	prioritizeRebirth = true,
	rebirthWhenReady = true,
	hatch = false,
	plant = false,
	spawnNest = false,
	unlockNests = false,
	upgradeLuck = false,
	feed = false,
	placeBestPets = false,
	esp = false,
	espHighlight = true,
	espLabel = true,
	espTracer = false,
	noclip = false,
	speed = false,
	infiniteJump = true,
	antiRagdoll = true,
	antiafk = false,
	noPause = false,
}

local settings = {}

local config = {
	minRarity = 5,
	targetEgg = "Any Egg",
	priority = "Highest Rarity",
	syncDelay = 0.35,
	mutationTier = "All Mutations (Shocked+)",
	prioritizeMutations = true,
	espMinRarity = 3,
	espMaxDistance = 5000,
	feedPriority = "Smart Priority (Highest Headroom)",
	feedFood = "All Foods",
	bestPetsStrategy = "Smart Potential (Max Income)",
	speed = 1,
}

local state = {
	collected = 0,
	target = "None",
	targetRarity = "None",
	targetMutation = "None",
	manual = {},
	cooldowns = {},
	lastPickup = 0,
	espEntries = {},
	baseSpeed = nil,
	incubatingEgg = "None",
	incubatingTime = "N/A",
	espFound = 0,
	espNearest = "None",
	espNearestDistance = 0,
	espTop = "None",
	espTopRarity = "None",
	espTopDistance = 0,
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

local RemotesRoot = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
local GameRemotes = RemotesRoot and (RemotesRoot:FindFirstChild("Game") or RemotesRoot:WaitForChild("Game", 10))
local PlotRemotes = GameRemotes and (GameRemotes:FindFirstChild("Plot") or GameRemotes:WaitForChild("Plot", 5))

local function gameRemote(name)
	if not GameRemotes then
		return nil
	end
	return GameRemotes:FindFirstChild(name) or GameRemotes:FindFirstChild(name, true)
end

local function plotRemote(name)
	if not PlotRemotes then
		return nil
	end
	return PlotRemotes:FindFirstChild(name) or PlotRemotes:FindFirstChild(name, true)
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
			local module = folder:FindFirstChild(name)
			if module then
				local ok, result = pcall(require, module)
				if ok then
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

local RARITY_LIST = {"Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal"}
local RARITY_RANK = {}
for index, name in ipairs(RARITY_LIST) do
	RARITY_RANK[name] = index
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

local RARITY_CHOICES = {"All Eggs", "Rare & Above", "Epic & Above", "Legendary & Above", "Mythic & Above", "Divine & Above", "Ethereal Only"}
local RARITY_FLOOR = {
	["All Eggs"] = 1,
	["Rare & Above"] = 2,
	["Epic & Above"] = 3,
	["Legendary & Above"] = 4,
	["Mythic & Above"] = 5,
	["Divine & Above"] = 6,
	["Ethereal Only"] = 7,
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
local MUTATION_CHOICES = {"All Mutations (Shocked+)", "Volted & Above (3x+)", "Rage & Above (4x+)", "Void & Above (10x+)", "Eternal Only (100x)"}
local MUTATION_FLOOR = {
	["All Mutations (Shocked+)"] = 2,
	["Volted & Above (3x+)"] = 3,
	["Rage & Above (4x+)"] = 4,
	["Void & Above (10x+)"] = 10,
	["Eternal Only (100x)"] = 100,
}
local WEATHER_VARIANTS = {Thunder = "Shocked", Volt = "Volted", Raging = "Rage", Dreadful = "Void", Eternal = "Eternal"}

local SORT_MODES = {"Highest Rarity", "Highest Luck", "Nearest", "Heaviest Weight"}

local REBIRTH_PETS = {"Horse", "Fox", "Unicorn", "Phoenix", "Kitsune", "Dragon"}
local REBIRTH_FALLBACK_EGGS = {
	Horse = {"Asteroid Egg", "Skull Egg", "Dominus Egg", "Crystal Egg", "Diamond Egg", "Golden Egg"},
	Fox = {"Soul Egg", "Sinister Egg", "Flaming Egg"},
	Unicorn = {"Cherub Egg", "Solaris Egg", "Blackhole Egg", "Galaxy Egg"},
	Phoenix = {"Cherub Egg", "Solaris Egg", "Blackhole Egg"},
	Kitsune = {"Cherub Egg", "Solaris Egg", "Blackhole Egg"},
	Dragon = {"Cherub Egg", "Solaris Egg", "Blackhole Egg"},
}

local VOLCANO_TOP = Vector3.new(-5102.8, 41408, -3489.1)
local VOLCANO_SKY = CFrame.new(
	-4917.03369, 41285.5312, -3704.17505,
	-0.710648835, -0.151280612, 0.68708986,
	1.78015469e-8, 0.976608396, 0.215025634,
	-0.703546941, 0.152807727, -0.694025576
)
local VOLCANO_DOOR = CFrame.new(-4972.5, 41276.5, -3650, 0.83177793, 0, -0.555108488, 0, 1, 0, 0.555108488, 0, 0.83177793)
local MAGMA_DIP_DURATION = 9.5

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
	if activeEggs and position then
		for _, child in ipairs(activeEggs:GetChildren()) do
			local childMutation = child:GetAttribute("Mutation")
			local childPosition = child:GetAttribute("Position")
			if type(childMutation) == "string" and childMutation ~= "" and typeof(childPosition) == "Vector3" then
				if (childPosition - position).Magnitude <= 6 then
					return childMutation
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
end

local function eggWeight(model)
	if not model then
		return 0
	end
	local position = safePivot(model)
	local activeEggs = getActiveEggs()
	if activeEggs and position then
		for _, child in ipairs(activeEggs:GetChildren()) do
			local childPosition = child:GetAttribute("Position")
			if typeof(childPosition) == "Vector3" and (childPosition - position).Magnitude < 10 then
				local weight = tonumber(child:GetAttribute("Weight")) or 0
				if GeneralConfig and type(GeneralConfig.ShownEggKG) == "function" then
					local ok, shown = pcall(GeneralConfig.ShownEggKG, weight)
					if ok and type(shown) == "number" then
						weight = shown
					end
				end
				return math.floor(weight * 10 + 0.5) / 10
			end
		end
	end
	return 0
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

local function isCollected(name)
	local attribute = LocalPlayer:GetAttribute("CollectedEggs")
	return type(attribute) == "string" and attribute ~= "" and string.find(attribute, tostring(name) .. ",", 1, true) ~= nil
end

local noclipSaved = {}

local function setNoclip(active)
	local character = getCharacter()
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
	return total / 300
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

local function moveTo(position, tolerance, abortCheck)
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
	local connection
	connection = RunService.Stepped:Connect(function()
		local character = getCharacter()
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
			local step = math.min(distance, 300 * heartbeat)
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
	setNoclip(false)
	clearNoclip()
	stopMotion()
	local endRoot = getRoot()
	if endRoot and (endRoot.Position - position).Magnitude <= tolerance + 1 then
		return true
	end
	return reached
end

local function firePrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end
	if typeof(fireproximityprompt) == "function" then
		for _ = 1, 3 do
			if pcall(fireproximityprompt, prompt) then
				return true
			end
			task.wait(0.1)
		end
	end
	return pcall(function()
		prompt:InputHoldBegin()
		task.wait(math.max(prompt.HoldDuration, 0.1) + 0.1)
		prompt:InputHoldEnd()
	end)
end

local function ownsPet(name)
	if not name or name == "" then
		return false
	end
	local owned = LocalPlayer:GetAttribute("OwnedPets") or getSavedValue("OwnedPets")
	if type(owned) == "string" and owned ~= "" and string.find(owned, name, 1, true) then
		return true
	end
	local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local key = tool:GetAttribute("PetKey")
					local plain = string.gsub(tool.Name, "%s*%[.*$", "")
					if (type(key) == "string" and string.find(key, name, 1, true)) or plain == name then
						return true
					end
				end
			end
		end
	end
	local plot = getPlot()
	local pets = plot and plot:FindFirstChild("Pets")
	if pets then
		for _, model in ipairs(pets:GetChildren()) do
			local petName = model:GetAttribute("PetName") or string.gsub(model.Name, "%s*%[.*$", "")
			if petName == name then
				return true
			end
		end
	end
	return false
end

local function eggTimeLeft(model)
	local entry = eggEntry(model.Name)
	local growth = entry and (tonumber(entry.GrowthTime) or 0) or 0
	if growth <= 0 then
		return nil
	end
	local eggData = model:FindFirstChild("EggData")
	local placeTime = eggData and find(eggData, "PlaceTime") and tonumber(eggData.PlaceTime.Value)
	local weight = eggData and find(eggData, "Weight") and tonumber(eggData.Weight.Value) or 1
	local total = growth * math.max(weight or 1, 1)
	if not placeTime then
		return total, total, true
	end
	local elapsed = math.max(0, Workspace:GetServerTimeNow() - placeTime)
	local remaining = math.max(0, total - elapsed)
	return remaining, total, remaining <= 0
end

local function incubatingFor(pet)
	local plot = getPlot()
	local eggs = plot and plot:FindFirstChild("Eggs")
	local basket = LocalPlayer:FindFirstChild("Basket")
	local fallback = REBIRTH_FALLBACK_EGGS[pet] or {}
	local function matches(name)
		local chance = getOdds(eggLuck(name))[pet] or 0
		local listed = false
		for _, eggName in ipairs(fallback) do
			if eggName == name then
				listed = true
				break
			end
		end
		return chance > 0, chance, listed
	end
	if eggs then
		for _, model in ipairs(eggs:GetChildren()) do
			local ok, chance, listed = matches(model.Name)
			if ok or listed then
				local remaining, total, ready = eggTimeLeft(model)
				if ready then
					return true, model.Name, "ready", chance
				end
				if remaining then
					return true, model.Name, formatDuration(remaining), chance
				end
				return true, model.Name, "incubating", chance
			end
		end
	end
	if basket then
		for _, egg in ipairs(basket:GetChildren()) do
			local name = egg:GetAttribute("Egg") or egg.Name
			local ok, chance = matches(name)
			if ok then
				return true, name, "in basket", chance
			end
		end
	end
	local containers = {LocalPlayer:FindFirstChild("Backpack"), getCharacter()}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local plain = string.gsub(tool.Name, "%s*%[.*$", "")
					local ok, chance = matches(plain)
					if ok then
						return true, plain, "in backpack", chance
					end
				end
			end
		end
	end
	return false, nil, nil, 0
end

local function rebirthState()
	local rebirths = getRebirths()
	local cap = tonumber(RebirthsData.Cap) or 6
	local nextTier = rebirths + 1
	local costs = RebirthsData.RiggedCost
	local cost = type(costs) == "table" and tonumber(costs[nextTier]) or nil
	cost = cost or FALLBACK_REBIRTHS.RiggedCost[math.min(nextTier, 6)]
	local pet = REBIRTH_PETS[nextTier] or "N/A"
	local capped = rebirths >= cap
	local hasPet = ownsPet(pet)
	local incubating, eggName, timeStr, chance = false, nil, nil, 0
	if not hasPet then
		incubating, eggName, timeStr, chance = incubatingFor(pet)
	end
	local cash = getCash()
	return {
		current = rebirths,
		nextTier = nextTier,
		maxCap = cap,
		capped = capped,
		pet = pet,
		hasPet = hasPet,
		incubating = incubating,
		incubatingEgg = eggName,
		incubatingTime = timeStr,
		incubatingChance = chance or 0,
		cash = cash,
		cost = cost,
		canRebirth = (not capped) and hasPet and cash >= cost,
	}
end

local function allowedEgg(name)
	if config.targetEgg ~= "Any Egg" and config.targetEgg ~= name then
		return false
	end
	return eggRank(name) >= (RARITY_FLOOR[config.minRarity] or 1)
end

local function mutationAllowed(mutation)
	if not mutation then
		return false
	end
	return (MUTATION_TIERS[mutation] or 1) >= (MUTATION_FLOOR[config.mutationTier] or 2)
end

local farmTargetName = nil
local farmCooldown = {}

local function onCooldown(name)
	local until_time = farmCooldown[name]
	return until_time and until_time > tick()
end

local function pickFarmTarget()
	local root = getRoot()
	if not root then
		return nil
	end
	local rendered = getRenderedEggs()
	local activeEggs = getActiveEggs()
	if not rendered or not activeEggs then
		return nil
	end
	local rebirth = enabled.rebirth and enabled.prioritizeRebirth and rebirthState() or nil
	local options = {}
	for _, model in ipairs(rendered:GetChildren()) do
		if model:IsA("Model") then
			local name = model.Name
			local rank = eggRank(name)
			local mutation = eggMutation(model)
			if mutation and enabled.prioritizeMutations and not mutationAllowed(mutation) then
				mutation = nil
			end
			local distance
			local ok = false
			for _, active in ipairs(activeEggs:GetChildren()) do
				local activeName = active:GetAttribute("Egg")
				if activeName == name then
					local position = active:GetAttribute("Position")
					if typeof(position) == "Vector3" then
						distance = (position - root.Position).Magnitude
						if not isCollected(name) and not onCooldown(name) and travelTime(root.Position, position) < 15 then
							ok = true
						end
					end
					break
				end
			end
			if ok and allowedEgg(name) then
				local weight = eggWeight(model)
				table.insert(options, {
					Model = model,
					Active = activeEggs:FindFirstChild(model.Name),
					Name = name,
					Rarity = eggRarity(name),
					Rank = rank,
					Luck = eggLuck(name),
					Weight = weight,
					Mutation = mutation,
					MutationWeight = MUTATION_WEIGHT[mutation] or 0,
					Distance = distance,
					Prompt = eggPrompt(model),
					RebirthPet = rebirth and rebirth.pet or nil,
					RebirthChance = rebirth and (getOdds(eggLuck(name))[rebirth.pet] or 0) or 0,
				})
			end
		end
	end
	if #options == 0 then
		return nil
	end
	local mutateOnly = enabled.farm and enabled.prioritizeMutations and #options > 1
	table.sort(options, function(a, b)
		if mutateOnly then
			local aHas = a.Mutation ~= nil
			local bHas = b.Mutation ~= nil
			if aHas ~= bHas then
				return aHas
			end
			if aHas and bHas then
				if a.MutationWeight ~= b.MutationWeight then
					return a.MutationWeight > b.MutationWeight
				end
			end
		end
		if rebirth and not rebirth.hasPet and not rebirth.incubating then
			local aListed = REBIRTH_FALLBACK_EGGS[rebirth.pet] or {}
			local aBonus, bBonus = 0, 0
			for _, eggName in ipairs(aListed) do
				if eggName == a.Name then
					aBonus = 1
				end
				if eggName == b.Name then
					bBonus = 1
				end
			end
			if aBonus ~= bBonus then
				return aBonus > bBonus
			end
			if a.RebirthChance ~= b.RebirthChance then
				return a.RebirthChance > b.RebirthChance
			end
		end
		if config.priority == "Nearest" then
			if a.Distance ~= b.Distance then
				return a.Distance < b.Distance
			end
		elseif config.priority == "Highest Luck" then
			if a.Luck ~= b.Luck then
				return a.Luck > b.Luck
			end
		elseif config.priority == "Heaviest Weight" then
			if math.abs(a.Weight - b.Weight) > 0.05 then
				return a.Weight > b.Weight
			end
		else
			if a.Rank ~= b.Rank then
				return a.Rank > b.Rank
			end
			if a.Luck ~= b.Luck then
				return a.Luck > b.Luck
			end
		end
		return a.Distance < b.Distance
	end)
	return options[1]
end

local function collectEgg(target)
	if not target or not target.Model or not target.Model.Parent then
		return false
	end
	local root = getRoot()
	if not root then
		return false
	end
	local position = target.Model:GetPivot().Position
	if (root.Position - position).Magnitude > 12 then
		if not moveTo(position, 4, function()
			return not enabled.farm
		end) then
			return false
		end
	end
	stopMotion()
	local before = basketCount()
	for _ = 1, 6 do
		if not target.Model.Parent then
			break
		end
		fire(EggPickup, target.Active and target.Active.Name or target.Name)
		local deadline = tick() + 0.6
		while tick() < deadline and basketCount() <= before do
			RunService.Heartbeat:Wait()
		end
		if basketCount() > before then
			state.lastPickup = tick()
			return true
		end
	end
	return basketCount() > before
end

local function deliverToPlot()
	local base = getBaseplate()
	if not base then
		return false
	end
	local top = topSurface(base) or base.Position
	local drop = top + Vector3.new(0, 3.5, 0)
	local root = getRoot()
	if root and (root.Position - drop).Magnitude > 12 then
		setFarmStatus("returning to plot")
		moveTo(drop, 4, function()
			return not (enabled.farm or enabled.plant or enabled.hatch)
		end)
	end
	setFarmStatus("delivering eggs")
	stopMotion()
	local deadline = tick() + 6
	while basketCount() > 0 and tick() < deadline do
		fireTouch(base)
		if basketCount() == 0 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	if basketCount() > 0 then
		teleportTo(top)
		stopMotion()
		deadline = tick() + 4
		while basketCount() > 0 and tick() < deadline do
			fireTouch(base)
			RunService.Heartbeat:Wait()
		end
	end
	if basketCount() == 0 then
		state.lastPickup = 0
	end
	return basketCount() == 0
end

local function hatchReadyEggs()
	if not HatchRemote then
		return 0
	end
	local plot = getPlot()
	local eggs = plot and plot:FindFirstChild("Eggs")
	if not eggs then
		return 0
	end
	local hatched = 0
	for _, model in ipairs(eggs:GetChildren()) do
		local _, _, ready = eggTimeLeft(model)
		if ready then
			local key = model:GetAttribute("EggKey")
			if type(key) == "string" and key ~= "" then
				fire(HatchRemote, {EggKey = key})
				hatched = hatched + 1
			else
				firePrompt(eggPrompt(model))
				hatched = hatched + 1
			end
			task.wait(0.15)
		end
	end
	return hatched
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
	if not tool or not humanoid then
		return false
	end
	if tool.Parent ~= container then
		humanoid:EquipTool(tool)
		local deadline = tick() + 1
		while tool.Parent ~= container and tick() < deadline do
			task.wait(0.05)
		end
	end
	return tool.Parent == container
end

local plotRandom = Random.new()

local function randomPlotPoint(margin)
	local base = getBaseplate()
	if not base then
		return nil
	end
	local halfX = math.max(1, base.Size.X / 2 - margin)
	local halfZ = math.max(1, base.Size.Z / 2 - margin)
	local offset = Vector3.new(plotRandom:NextNumber(-halfX, halfX), 0, plotRandom:NextNumber(-halfZ, halfZ))
	return base.CFrame:PointToWorldSpace(offset)
end

local function placeEggs()
	if not EggPlaced then
		return 0
	end
	local plot = getPlot()
	if not plot then
		return 0
	end
	local character = getCharacter()
	if not character then
		return 0
	end
	local placed = 0
	local capacity = enabled.spawnNest and 15 or 10
	local nests = plot:FindFirstChild("Nests")
	for _, tool in ipairs(collectEggTools()) do
		if getEggsPlanted() >= capacity then
			break
		end
		local skipPlot = false
		if enabled.spawnNest and nests then
			local done = false
			for _, nest in ipairs(nests:GetChildren()) do
				if nest:GetAttribute("Unlocked") ~= false and nest:GetAttribute("Occupied") ~= true then
					if equipTool(tool, character) then
						setFarmStatus("placing egg in nest")
						fire(EggPlaced, {NestId = nest.Name})
						placed = placed + 1
						task.wait(0.3)
						done = true
					end
					break
				end
			end
			if done then
				skipPlot = true
			end
		end
		if not skipPlot then
			if getEggsPlanted() - getNestCounts() < 10 then
				local point = randomPlotPoint(6)
				if point and equipTool(tool, character) then
					setFarmStatus("planting egg")
					fire(EggPlaced, {PlantPosition = point})
					placed = placed + 1
					task.wait(0.3)
				end
			else
				break
			end
		end
	end
	return placed
end

local function unlockNests()
	if not NestRemote then
		return 0
	end
	if LocalPlayer:GetAttribute("NoNest") == true then
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
			local id = tonumber(nest.Name)
			if id then
				fire(NestRemote, id)
				count = count + 1
			end
			firePrompt(nest:FindFirstChildWhichIsA("ProximityPrompt", true))
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

local function petIncome(name, weight, mutation)
	local entry = PetsData[name]
	local base = type(entry) == "table" and (tonumber(entry.Income) or 0) : 0
	local factor = 1
	if MutationsData and type(MutationsData.CombinedFactor) == "function" then
		local ok, value = pcall(MutationsData.CombinedFactor, mutation, nil)
		if ok and type(value) == "number" and value > 0 then
			factor = value
		end
	end
	local standard = tonumber(PetAging and PetAging.WeightStandardKG) or 10
	return math.floor(base * (math.max(tonumber(weight) or 1, 1) / standard) * factor)
end

local function gatherPets()
	local list = {}
	if PetRenderer and type(PetRenderer.GetAll) == "function" then
		local ok, all = pcall(PetRenderer.GetAll)
		if ok and type(all) == "table" then
			for _, entry in pairs(all) do
				if type(entry) == "table" and entry.Model and entry.Model.Parent and entry.OwnerUserId == LocalPlayer.UserId then
					local model = entry.Model
					local name = model:GetAttribute("PetName") or string.gsub(model.Name, "%s*%[.*$", "")
					local age = tonumber(model:GetAttribute("Age")) or 1
					local weight = tonumber(model:GetAttribute("Weight")) or 1
					local mutation = model:GetAttribute("Mutation")
					table.insert(list, {
						Key = entry.PetKey or model:GetAttribute("PetKey") or model.Name,
						Name = name,
						Placed = true,
						Model = model,
						PrimaryPart = model.PrimaryPart,
						Age = age,
						Weight = weight,
						Mutation = mutation,
						CurIncome = petIncome(name, weight, mutation),
						MaxIncome = petIncome(name, weight * (multiplierForAge(tonumber(PetAging and PetAging.MaxAge) or 100) / multiplierForAge(age)), mutation),
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
					local name = model:GetAttribute("PetName") or string.gsub(model.Name, "%s*%[.*$", "")
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
						Mutation = mutation,
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
				local name = tool:GetAttribute("PetName") or string.gsub(tool.Name, "%s*%[.*$", "")
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
					Mutation = mutation,
					CurIncome = petIncome(name, weight, mutation),
					MaxIncome = petIncome(name, weight * 2, mutation),
				})
			end
		end
	end
	return list
end

local function sortPets(list)
	local strategy = config.bestPetsStrategy
	table.sort(list, function(a, b)
		if strategy == "Current Cash/s (Game Default)" then
			if a.CurIncome ~= b.CurIncome then
				return a.CurIncome > b.CurIncome
			end
		end
		if a.MaxIncome ~= b.MaxIncome then
			return a.MaxIncome > b.MaxIncome
		end
		if a.Weight ~= b.Weight then
			return a.Weight > b.Weight
		end
		return a.Name < b.Name
	end)
	return list
end

local function placeBestPets()
	if not PlacePet or not PickupPet then
		return false, "pet remotes missing"
	end
	local list = gatherPets()
	if #list == 0 then
		return false, "no pets found"
	end
	sortPets(list)
	local maxPets = math.min(getMaxPets(), #list)
	local keep = {}
	for index = 1, maxPets do
		keep[list[index].Key] = true
	end
	local freed = {}
	for _, entry in ipairs(list) do
		if entry.Placed and not keep[entry.Key] and entry.Position then
			table.insert(freed, entry.Position)
			fire(PickupPet, entry.Key)
			task.wait(0.2)
		end
	end
	local character = getCharacter()
	if not character then
		return false, "no character"
	end
	local placed = 0
	for index = 1, maxPets do
		local entry = list[index]
		if not entry.Placed then
			local spot = table.remove(freed, 1)
			if not spot then
				local row = math.floor((index - 1) / 3)
				local offset = CFrame.new(((index - 1) % 3 - 1) * 4, 0, -(row * 4 + 8))
				local base = getBaseplate()
				local root = getRoot()
				if base and root then
					local local3 = base.CFrame:PointToObjectSpace((root.CFrame * offset).Position)
					spot = base.CFrame:PointToWorldSpace(Vector3.new(
						math.clamp(local3.X, -base.Size.X / 2 + 3, base.Size.X / 2 - 3),
						local3.Y,
						math.clamp(local3.Z, -base.Size.Z / 2 + 3, base.Size.Z / 2 - 3)
					))
				end
			end
			if spot and equipTool(entry.Tool, character) then
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
	return true, string.format("placed %d, picked up %d", placed, #freed)
end

local function bestFood()
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	local character = getCharacter()
	local containers = {character, backpack}
	local list = {}
	for _, container in ipairs(containers) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:HasTag("Food") then
					local data = find(tool, "Data", "Amount")
					local amount = data and tonumber(data.Value) or 1
					if amount and amount > 0 and (config.feedFood == "All Foods" or tool.Name == config.feedFood) then
						local entry = FoodsData[tool.Name]
						table.insert(list, {Tool = tool, Name = tool.Name, XP = type(entry) == "table" and (tonumber(entry.XP) or 0) or 0})
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

local function feedPets()
	if not FeedPet then
		return false, "feed remote missing"
	end
	local list = gatherPets()
	local placed = {}
	for _, entry in ipairs(list) do
		if entry.Placed then
			table.insert(placed, entry)
		end
	end
	if #placed == 0 then
		return false, "no placed pets"
	end
	sortPets(placed)
	if config.feedPriority == "Lowest Level First" then
		table.sort(placed, function(a, b)
			return a.Age < b.Age
		end)
	elseif config.feedPriority == "Highest Max Income" then
		table.sort(placed, function(a, b)
			return a.MaxIncome > b.MaxIncome
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
	local target = placed[1]
	local part = target.PrimaryPart or (target.Model and target.Model:FindFirstChildWhichIsA("BasePart"))
	local root = getRoot()
	local restore = nil
	if part and root and (root.Position - part.Position).Magnitude > 7 then
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
			firePrompt(prompt)
		end
	end
	local maxAge = tonumber(PetAging.MaxAge) or 100
	local count = 0
	while count < 5 do
		if target.Model and tonumber(target.Model:GetAttribute("Age")) >= maxAge then
			break
		end
		local data = find(food.Tool, "Data", "Amount")
		if data and (tonumber(data.Value) or 0) <= 0 then
			break
		end
		fire(FeedPet, target.Key, food.Name)
		count = count + 1
		task.wait(0.35)
	end
	if restore and getRoot() then
		teleportTo(restore.Position)
	end
	return true, string.format("fed %d %s to %s", count, food.Name, target.Name)
end

local function volcanoParts()
	local volcano = Workspace:FindFirstChild("Volcano")
	if not volcano then
		return nil, nil
	end
	return volcano:FindFirstChild("VolcanoEntrance"), volcano:FindFirstChild("VolcanoValidate")
end

local function touchVolcano(root, down)
	local entrance, validate = volcanoParts()
	if not firetouchinterest or not root then
		return
	end
	for _, part in ipairs({entrance, validate}) do
		if part then
			pcall(firetouchinterest, root, part, down)
		end
	end
end

local function makeVolcanoPlatform()
	local existing = Workspace:FindFirstChild("AntiGodHub_VolcanoPlatform")
	if existing then
		existing.CFrame = VOLCANO_SKY * CFrame.new(0, -3.2, 0)
		return existing
	end
	local platform = Instance.new("Part")
	platform.Name = "AntiGodHub_VolcanoPlatform"
	platform.Size = Vector3.new(14, 1, 14)
	platform.Anchored = true
	platform.CanCollide = true
	platform.CFrame = VOLCANO_SKY * CFrame.new(0, -3.2, 0)
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
		return true
	end
	setFarmStatus("warping to volcano")
	makeVolcanoPlatform()
	stopMotion()
	root.CFrame = VOLCANO_SKY
	task.wait(0.12)
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
	return LocalPlayer:GetAttribute("InVolcano") == true
end

local function escapeVolcano()
	local root = getRoot()
	if not root then
		return false
	end
	if LocalPlayer:GetAttribute("InVolcano") ~= true then
		return false
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
	return LocalPlayer:GetAttribute("InVolcano") ~= true
end

local function dipMagma()
	if not enabled.magmaDip then
		return false
	end
	local basket = LocalPlayer:FindFirstChild("Basket")
	if not basket then
		return false
	end
	local egg = nil
	for _, child in ipairs(basket:GetChildren()) do
		local mutation = child:GetAttribute("Mutation")
		if mutation ~= "Eternal" and mutation ~= "Magma" then
			egg = child
			break
		end
	end
	if not egg then
		return false
	end
	if not enterVolcano() then
		return false
	end
	setFarmStatus("dipping egg in lava")
	local root = getRoot()
	stopMotion()
	if root then
		root.CFrame = CFrame.new(VOLCANO_TOP)
	end
	task.wait(0.2)
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
	local deadline = tick() + MAGMA_DIP_DURATION
	while tick() < deadline do
		if not egg.Parent then
			break
		end
		local current = getRoot()
		if current and (current.Position - VOLCANO_TOP).Magnitude > 30 then
			stopMotion()
			current.CFrame = CFrame.new(VOLCANO_TOP)
		end
		setFarmStatus(string.format("magma dip %ds left", math.ceil(deadline - tick())))
		task.wait(0.15)
	end
	local mutated = egg.Parent and egg:GetAttribute("Mutation") == "Magma"
	escapeVolcano()
	setFarmStatus(mutated and "magma mutation succeeded" or "magma dip finished")
	return mutated
end

local espFolder = nil

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
	for _, key in ipairs({"Highlight", "Billboard", "Tracer"}) do
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
end

local function espApply(model, rarity, mutation)
	if state.espEntries[model] or not model.Parent then
		return
	end
	local folder = getEspFolder()
	local color = RARITY_COLORS[rarity] or RARITY_COLORS.Common
	if mutation and MUTATION_COLORS[mutation] then
		color = MUTATION_COLORS[mutation]
	end
	local entry = {}
	if enabled.espHighlight then
		pcall(function()
			local highlight = Instance.new("Highlight")
			highlight.Name = "AntiGodHighlight"
			highlight.Adornee = model
			highlight.FillColor = color
			highlight.OutlineColor = color
			highlight.FillTransparency = 0.7
			highlight.OutlineTransparency = 0.1
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = folder
			entry.Highlight = highlight
		end)
	end
	if enabled.espLabel then
		pcall(function()
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "AntiGodLabel"
			billboard.Size = UDim2.new(0, 170, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 2.2, 0)
			billboard.AlwaysOnTop = true
			billboard.MaxDistance = config.espMaxDistance
			billboard.Adornee = model.PrimaryPart or model
			billboard.Parent = folder
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
			frame.BackgroundTransparency = 0.25
			frame.BorderSizePixel = 0
			frame.Parent = billboard
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = frame
			local stroke = Instance.new("UIStroke")
			stroke.Color = color
			stroke.Thickness = 1.5
			stroke.Parent = frame
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextSize = 13
			label.TextColor3 = color
			label.TextWrapped = true
			label.Text = model.Name .. "\n" .. rarity .. (mutation and (" [" .. mutation .. "]") or "")
			label.Parent = frame
			entry.Billboard = billboard
		end)
	end
	if enabled.espTracer then
		local root = getRoot()
		if root then
			pcall(function()
				local start = Instance.new("Attachment")
				start.Position = Vector3.zero
				start.Parent = root
				local beam = Instance.new("Beam")
				beam.Name = "AntiGodTracer"
				beam.Attachment0 = start
				local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
				if part then
					local finish = Instance.new("Attachment")
					finish.Parent = part
					beam.Attachment1 = finish
				end
				beam.FaceColor = color
				beam.Width = 0.12
				beam.MaxDistance = config.espMaxDistance
				beam.Parent = folder
				entry.Tracer = beam
			end)
		end
	end
	state.espEntries[model] = entry
end

local function applyEspPreset(preset)
	if preset == "All Visuals" then
		enabled.espHighlight = true
		enabled.espLabel = true
		enabled.espTracer = true
	elseif preset == "Highlight + Label" then
		enabled.espHighlight = true
		enabled.espLabel = true
		enabled.espTracer = false
	elseif preset == "Label Only" then
		enabled.espHighlight = false
		enabled.espLabel = true
		enabled.espTracer = false
	elseif preset == "Highlight Only" then
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

local function doEsp()
	if not enabled.esp then
		espClear()
		return
	end
	local rendered = getRenderedEggs()
	local root = getRoot()
	if not rendered or not root then
		espClear()
		return
	end
	local seen = {}
	local floor = config.espMinRarity
	local found = 0
	local nearestName, nearestDistance = nil, math.huge
	local topName, topRarity, topDistance = nil, nil, nil
	for _, model in ipairs(rendered:GetChildren()) do
		if model:IsA("Model") then
			local rarity = eggRarity(model.Name)
			if (RARITY_RANK[rarity] or 1) >= floor then
				local position = safePivot(model)
				if position then
					local distance = (position - root.Position).Magnitude
					if distance <= config.espMaxDistance then
						found = found + 1
						seen[model] = true
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
						espApply(model, rarity, eggMutation(model))
					end
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
	if not enabled.farm then
		return
	end
	if basketCount() >= basketCapacity() then
		deliverToPlot()
		if enabled.hatch then
			setFarmStatus("hatching eggs")
			hatchReadyEggs()
		end
		if enabled.plant then
			setFarmStatus("placing eggs")
			placeEggs()
		end
		return
	end
	local target = pickFarmTarget()
	if not target then
		setFarmStatus("searching for eggs")
		state.target = "None"
		state.targetRarity = "None"
		state.targetMutation = "None"
		return
	end
	state.target = target.Name
	state.targetRarity = target.Rarity
	state.targetMutation = target.Mutation or "None"
	setFarmStatus("collecting " .. target.Name)
	local collected = collectEgg(target)
	if not collected then
		setFarmStatus("missed " .. target.Name)
		farmCooldown[target.Name] = tick() + 3
		farmTargetName = target.Name
		task.wait(0.3)
		return
	end
	farmTargetName = nil
	state.collected = state.collected + 1
	setFarmStatus("delivering " .. target.Name)
	task.wait(math.clamp(config.syncDelay, 0.1, 1))
	deliverToPlot()
end

local function doAutoRebirth()
	if not enabled.rebirth then
		return
	end
	local info = rebirthState()
	state.incubatingEgg = info.incubatingEgg or "None"
	state.incubatingTime = info.incubatingTime or "N/A"
	if not info.canRebirth or not enabled.rebirthWhenReady then
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
	if not enabled.plant or basketCount() == 0 then
		return
	end
	if enabled.hatch then
		hatchReadyEggs()
	end
	placeEggs()
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

local function doNoClip()
	local character = getCharacter()
	if not character then
		return
	end
	if enabled.noclip then
		setNoclip(true)
	else
		setNoclip(false)
		clearNoclip()
	end
end

local function doSpeedMod()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	if enabled.speed then
		if not state.baseSpeed then
			state.baseSpeed = humanoid.WalkSpeed
		end
		pcall(function()
			humanoid.WalkSpeed = 92 * math.max(config.speed, 1)
		end)
	elseif state.baseSpeed then
		pcall(function()
			humanoid.WalkSpeed = state.baseSpeed
		end)
		state.baseSpeed = nil
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
local function setAntiAfk(state_)
	if state_ and not afkConnection then
		afkConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	elseif not state_ and afkConnection then
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
local function setFpsBoost(state_)
	if state_ and not fpsOriginals then
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
	elseif not state_ and fpsOriginals then
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

local FarmingTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "zap" })
local PlotTab = Tabs.Main:AddSubTab({ Name = "Plot", Icon = "play" })
local EspTab = Tabs.Main:AddSubTab({ Name = "ESP", Icon = "eye" })
local PlayerTab = Tabs.Main:AddSubTab({ Name = "Player", Icon = "swords" })

local FarmBox = box(FarmingTab, "Auto Farm", "zap", "Left")
FarmBox:AddToggle("AutoFarm", { Text = "Auto Farm", Default = false, Callback = function(value)
	enabled.farm = value
end })
FarmBox:AddDropdown("MinFarmRarity", {
	Text = "Minimum Egg Rarity",
	Values = RARITY_CHOICES,
	Default = "Mythic & Above",
	Callback = function(value)
		config.minRarity = RARITY_FLOOR[value] or 1
	end,
})
FarmBox:AddDropdown("TargetEgg", {
	Text = "Target Specific Egg",
	Values = EGG_CHOICES,
	Default = "Any Egg",
	Callback = function(value)
		config.targetEgg = value
	end,
})
FarmBox:AddDropdown("FarmPriority", {
	Text = "Target Priority Order",
	Values = SORT_MODES,
	Default = "Highest Rarity",
	Callback = function(value)
		config.priority = value
	end,
})
FarmBox:AddSlider("SyncDelay", {
	Text = "Pickup Sync Delay",
	Min = 0.1,
	Max = 1.5,
	Default = 0.35,
	Increment = 0.05,
	Callback = function(value)
		config.syncDelay = value
	end,
})
FarmBox:AddToggle("PrioritizeMutations", { Text = "Prioritize Mutated Eggs", Default = true, Callback = function(value)
	enabled.prioritizeMutations = value
end })
FarmBox:AddDropdown("MutationTier", {
	Text = "Minimum Mutation Tier",
	Values = MUTATION_CHOICES,
	Default = "All Mutations (Shocked+)",
	Callback = function(value)
		config.mutationTier = value
	end,
})

local RebirthBox = box(FarmingTab, "Auto Rebirth", "skull", "Left")
RebirthBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })
RebirthBox:AddToggle("PrioritizeRebirthPet", { Text = "Prioritize Rebirth Pet", Default = true, Callback = function(value)
	enabled.prioritizeRebirth = value
end })
RebirthBox:AddToggle("RebirthWhenReady", { Text = "Rebirth When Ready", Default = true, Callback = function(value)
	enabled.rebirthWhenReady = value
end })
RebirthBox:AddDivider()
RebirthBox:AddButton({ Text = "Rebirth Now", Func = function()
	local info = rebirthState()
	if info.canRebirth then
		setFarmStatus("rebirthing tier " .. info.nextTier)
		fire(RebirthRemote)
		pcall(function()
			Library:Notify("Rebirth tier " .. info.nextTier .. " requested")
		end)
	else
		pcall(function()
			Library:Notify("Rebirth not ready yet")
		end)
	end
end })

local VolcanoBox = box(FarmingTab, "Volcano & Magma", "play", "Left")
VolcanoBox:AddToggle("AutoMagmaDip", { Text = "Auto Magma Lava Dip", Default = false, Callback = function(value)
	enabled.magmaDip = value
end })
VolcanoBox:AddButton({ Text = "Enter Volcano", Func = function()
	local ok = enterVolcano()
	pcall(function()
		Library:Notify(ok and "Entered the volcano" or "Volcano warp failed")
	end)
end })
VolcanoBox:AddButton({ Text = "Escape Volcano", Func = function()
	local ok = escapeVolcano()
	pcall(function()
		Library:Notify(ok and "Escaped the volcano" or "Nothing to escape")
	end)
end })
VolcanoBox:AddButton({ Text = "Dip Egg In Lava Now", Func = function()
	local before = basketCount()
	local ok = dipMagma()
	pcall(function()
		Library:Notify(ok and "Magma mutation succeeded" or ("Magma dip finished (" .. tostring(before) .. " egg)"))
	end)
end })

local StatusBox = box(FarmingTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("CashLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("IncomeLabel", { Text = paint("Income/s -", "0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("TargetLabel", { Text = paint("Target -", "None", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("CollectedLabel", { Text = paint("Collected -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("RebirthLabel", { Text = paint("Rebirth -", "0", COLORS.orange), DoesWrap = true })

local RebirthStatusBox = box(FarmingTab, "Rebirth Status", "user", "Right")
RebirthStatusBox:AddLabel("RebirthTierLabel", { Text = paint("Tier -", "0 -> 1", COLORS.accent), DoesWrap = true })
RebirthStatusBox:AddLabel("RebirthPetLabel", { Text = paint("Required Pet -", "N/A", COLORS.user), DoesWrap = true })
RebirthStatusBox:AddLabel("RebirthCashLabel", { Text = paint("Rebirth Cash -", "0 / 0", COLORS.gold), DoesWrap = true })
RebirthStatusBox:AddLabel("IncubatingLabel", { Text = paint("Incubating -", "None", COLORS.orange), DoesWrap = true })

local PlotBox = box(PlotTab, "Plot Eggs", "play", "Left")
PlotBox:AddToggle("AutoPlant", { Text = "Auto Plant Eggs", Default = false, Callback = function(value)
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
PlotBox:AddDivider()
PlotBox:AddButton({ Text = "Place Eggs Now", Func = function()
	local count = placeEggs()
	pcall(function()
		Library:Notify("Placed " .. tostring(count) .. " eggs")
	end)
end })
PlotBox:AddButton({ Text = "Teleport To Plot", Func = function()
	local top = getPlotTop()
	if top then
		fire(TeleportToPlot)
		teleportTo(top)
		stopMotion()
		pcall(function()
			Library:Notify("Teleported to your plot")
		end)
	else
		pcall(function()
			Library:Notify("Plot not found")
		end)
	end
end })

local PetsBox = box(PlotTab, "Pets", "user", "Left")
PetsBox:AddToggle("AutoPlaceBestPets", { Text = "Auto Place Best Pets", Default = false, Callback = function(value)
	enabled.placeBestPets = value
end })
PetsBox:AddDropdown("BestPetsStrategy", {
	Text = "Best Pets Strategy",
	Values = {"Smart Potential (Max Income)", "Current Cash/s (Game Default)"},
	Default = "Smart Potential (Max Income)",
	Callback = function(value)
		config.bestPetsStrategy = value
	end,
})
PetsBox:AddButton({ Text = "Place Best Pets Now", Func = function()
	local _, message = placeBestPets()
	pcall(function()
		Library:Notify(tostring(message or "done"))
	end)
end })
PetsBox:AddDivider()
PetsBox:AddToggle("AutoFeedPets", { Text = "Auto Feed Pets", Default = false, Callback = function(value)
	enabled.feed = value
end })
PetsBox:AddDropdown("FeedPriority", {
	Text = "Feed Priority",
	Values = {"Smart Priority (Highest Headroom)", "Highest Max Income", "Lowest Level First"},
	Default = "Smart Priority (Highest Headroom)",
	Callback = function(value)
		config.feedPriority = value
	end,
})
PetsBox:AddDropdown("FeedFood", {
	Text = "Food Filter",
	Values = FOOD_CHOICES,
	Default = "All Foods",
	Callback = function(value)
		config.feedFood = value
	end,
})
PetsBox:AddButton({ Text = "Feed Now", Func = function()
	local _, message = feedPets()
	pcall(function()
		Library:Notify(tostring(message or "done"))
	end)
end })

local PlotStatusBox = box(PlotTab, "Plot Status", "activity", "Right")
PlotStatusBox:AddLabel("PlotStatusLabel", { Text = paint("Plot -", "idle", COLORS.accent), DoesWrap = true })
PlotStatusBox:AddLabel("EggsPlantedLabel", { Text = paint("Eggs Planted -", "0", COLORS.gold), DoesWrap = true })
PlotStatusBox:AddLabel("NestsLabel", { Text = paint("Nests -", "0/0", COLORS.user), DoesWrap = true })
PlotStatusBox:AddLabel("PetsLabel", { Text = paint("Pets Placed -", "0/5", COLORS.orange), DoesWrap = true })
PlotStatusBox:AddLabel("BasketLabel", { Text = paint("Basket -", "0/1", COLORS.accent), DoesWrap = true })

local EspBox = box(EspTab, "Egg ESP", "eye", "Left")
EspBox:AddToggle("EggESP", { Text = "Egg ESP", Default = false, Callback = function(value)
	enabled.esp = value
	if not value then
		espClear()
	end
end })
EspBox:AddDropdown("EspPreset", {
	Text = "Visual Mode",
	Values = {"All Visuals", "Highlight + Label", "Label Only", "Highlight Only", "Tracers Only"},
	Default = "Highlight + Label",
	Callback = function(value)
		applyEspPreset(value)
	end,
})
EspBox:AddDropdown("EspMinRarity", {
	Text = "Minimum ESP Rarity",
	Values = RARITY_CHOICES,
	Default = "Epic & Above",
	Callback = function(value)
		config.espMinRarity = RARITY_FLOOR[value] or 1
		espClear()
	end,
})
EspBox:AddSlider("EspMaxDistance", {
	Text = "Max Render Distance",
	Min = 500,
	Max = 15000,
	Default = 5000,
	Increment = 250,
	Callback = function(value)
		config.espMaxDistance = value
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
MovementBox:AddToggle("NoClip", { Text = "NoClip", Default = false, Callback = function(value)
	enabled.noclip = value
end })
MovementBox:AddToggle("SpeedMod", { Text = "Speed Multiplier", Default = false, Callback = function(value)
	enabled.speed = value
end })
MovementBox:AddSlider("SpeedMultiplier", {
	Text = "Speed Multiplier",
	Min = 1,
	Max = 4,
	Default = 1,
	Increment = 0.25,
	Callback = function(value)
		config.speed = value
	end,
})
MovementBox:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = true, Callback = function(value)
	enabled.infiniteJump = value
end })
MovementBox:AddToggle("AntiRagdoll", { Text = "Anti Ragdoll", Default = true, Callback = function(value)
	enabled.antiRagdoll = value
end })

local TeleportBox = box(PlayerTab, "Teleports", "play", "Left")
TeleportBox:AddButton({ Text = "Teleport To Plot", Func = function()
	local top = getPlotTop()
	if top then
		fire(TeleportToPlot)
		teleportTo(top)
		stopMotion()
	end
end })
TeleportBox:AddButton({ Text = "Teleport To Nests", Func = function()
	local plot = getPlot()
	local nests = plot and plot:FindFirstChild("Nests")
	local position = safePivot(nests)
	if position then
		teleportTo(position)
		stopMotion()
	end
end })
TeleportBox:AddButton({ Text = "Teleport To Hatch Upgrades", Func = function()
	local plot = getPlot()
	local upgrades = plot and plot:FindFirstChild("HatchUpgrade")
	local position = safePivot(upgrades)
	if position then
		teleportTo(position)
		stopMotion()
	end
end })
TeleportBox:AddButton({ Text = "Teleport To Map Center", Func = function()
	teleportTo(Vector3.new(110, 40316, 750))
	stopMotion()
end })
TeleportBox:AddButton({ Text = "Teleport To Volcano Top", Func = function()
	if enterVolcano() then
		local root = getRoot()
		if root then
			stopMotion()
			root.CFrame = CFrame.new(VOLCANO_TOP)
		end
	end
end })
TeleportBox:AddButton({ Text = "Teleport To Closest Egg", Func = function()
	local target = pickFarmTarget()
	if target then
		moveTo(target.Model:GetPivot().Position, 4)
		stopMotion()
	else
		pcall(function()
			Library:Notify("No egg found")
		end)
	end
end })

local PlayerStatusBox = box(PlayerTab, "Player Status", "activity", "Right")
PlayerStatusBox:AddLabel("PlayerStatusLabel", { Text = paint("Player -", "idle", COLORS.accent), DoesWrap = true })
PlayerStatusBox:AddLabel("PositionLabel", { Text = paint("Position -", "0, 0, 0", COLORS.gold), DoesWrap = true })
PlayerStatusBox:AddLabel("SpeedLabel", { Text = paint("Walk Speed -", "0", COLORS.user), DoesWrap = true })
PlayerStatusBox:AddLabel("VolcanoLabel", { Text = paint("Volcano -", "no", COLORS.orange), DoesWrap = true })

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
	setLabel("CashLabel", paint("Cash -", "$" .. abbreviateNumber(getCash()), COLORS.gold))
	setLabel("IncomeLabel", paint("Income/s -", "$" .. abbreviateNumber(getIncomePerSecond()), COLORS.user))
	setLabel("RebirthLabel", paint("Rebirth -", getRebirths(), COLORS.orange))
	setLabel("TargetLabel", paint("Target -", state.target .. " [" .. state.targetRarity .. "]", COLORS.accent))
	setLabel("CollectedLabel", paint("Collected -", state.collected, COLORS.orange))
	local info = rebirthState()
	setLabel("RebirthTierLabel", paint("Tier -", string.format("%d -> %d", info.current, info.nextTier), COLORS.accent))
	setLabel("RebirthPetLabel", paint("Required Pet -", info.pet .. (info.hasPet and " (owned)" or " (missing)"), COLORS.user))
	setLabel("RebirthCashLabel", paint("Rebirth Cash -", string.format("%s / %s (%s)", abbreviateNumber(info.cash), abbreviateNumber(info.cost), info.cash >= info.cost and "ok" or "short"), COLORS.gold))
	setLabel("IncubatingLabel", paint("Incubating -", state.incubatingEgg .. " (" .. tostring(state.incubatingTime) .. ")", COLORS.orange))
	local unlocked, occupied = getNestCounts()
	setLabel("PlotStatusLabel", paint("Plot -", getPlot() and "found" or "not found", COLORS.accent))
	setLabel("EggsPlantedLabel", paint("Eggs Planted -", getEggsPlanted(), COLORS.gold))
	setLabel("NestsLabel", paint("Nests -", string.format("%d unlocked / %d busy", unlocked, occupied), COLORS.user))
	setLabel("PetsLabel", paint("Pets Placed -", string.format("%d/%d", getPetsPlaced(), getMaxPets()), COLORS.orange))
	setLabel("BasketLabel", paint("Basket -", string.format("%d/%d", basketCount(), basketCapacity()), COLORS.accent))
	setLabel("EspStatusLabel", paint("ESP -", enabled.esp and "on" or "off", COLORS.accent))
	setLabel("EspFoundLabel", paint("Eggs Tracked -", state.espFound, COLORS.gold))
	setLabel("EspTopLabel", paint("Best Egg -", state.espTop .. " [" .. state.espTopRarity .. "]", COLORS.user))
	setLabel("EspDistLabel", paint("Distance -", state.espTopDistance .. " studs", COLORS.orange))
	local root = getRoot()
	setLabel("PlayerStatusLabel", paint("Player -", getHumanoid() and "alive" or "no character", COLORS.accent))
	setLabel("PositionLabel", paint("Position -", root and string.format("%d, %d, %d", root.Position.X, root.Position.Y, root.Position.Z) or "n/a", COLORS.gold))
	local humanoid = getHumanoid()
	setLabel("SpeedLabel", paint("Walk Speed -", humanoid and math.floor(humanoid.WalkSpeed) or 0, COLORS.user))
	setLabel("VolcanoLabel", paint("Volcano -", LocalPlayer:GetAttribute("InVolcano") == true and "yes" or "no", COLORS.orange))
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

local function doAutoFeed()
	if not enabled.feed then
		return
	end
	local ok, message = feedPets()
	if ok then
		setFarmStatus(tostring(message))
	end
end

local function doAutoPlaceBestPets()
	if not enabled.placeBestPets then
		return
	end
	local ok, message = placeBestPets()
	if ok then
		setFarmStatus(tostring(message))
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

UserInputService.JumpRequest:Connect(function()
	if not enabled.infiniteJump then
		return
	end
	local humanoid = getHumanoid()
	if humanoid then
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end)
	end
end)

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

chain({ doAutoFarm }, 0.2)
chain({ doAutoRebirth, dipMagma }, 0.6)
loop(doEsp, 0.3)
loop(doAutoHatch, 0.4)
loop(doAutoPlant, 0.6)
loop(doAntiRagdoll, 0.2)
loop(doNoClip, 0.1)
loop(doSpeedMod, 0.15)
loop(doAutoFeed, 1.5)
loop(doAutoPlaceBestPets, 10)
loop(doAutoUnlock, 1.5)
loop(doAutoLuck, 1.5)

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
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	espClear()
	clearNoclip()
	setNoclip(false)
	state.baseSpeed = nil
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()