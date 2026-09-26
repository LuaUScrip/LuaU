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
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

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
	GameName = "Fishing Chef",
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

local enabled = {}
local settings = {}
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

local timers = {}
local function ready(key, interval)
	local now = tick()
	if now - (timers[key] or 0) < interval then
		return false
	end
	timers[key] = now
	return true
end

local function attributeOf(instance, ...)
	if not instance then
		return nil
	end
	for index = 1, select("#", ...) do
		local value = instance:GetAttribute((select(index, ...)))
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function statValue(...)
	for index = 1, select("#", ...) do
		local key = (select(index, ...))
		local value = LocalPlayer:GetAttribute(key)
		if value == nil then
			local stats = LocalPlayer:FindFirstChild("leaderstats")
			local stat = stats and stats:FindFirstChild(key)
			if stat then
				value = stat.Value or stat:GetAttribute("Value")
			end
		end
		if value ~= nil then
			return value
		end
	end
	return nil
end

local SUFFIX_LIST = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

local function formatCommas(value)
	local text = tostring(value)
	local replaced
	repeat
		text, replaced = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return text
end

local gameFormat

local function toNumber(value)
	if type(value) == "number" then
		return value
	end
	if type(value) ~= "string" then
		return nil
	end
	local text = value:gsub("[, %s]", "")
	for index = #SUFFIX_LIST, 2, -1 do
		local suffix = SUFFIX_LIST[index]
		if #suffix > 0 and text:sub(-#suffix) == suffix then
			local base = tonumber(text:sub(1, -#suffix - 1))
			if base then
				return base * (1000 ^ (index - 1))
			end
		end
	end
	return tonumber(text)
end

local function abbreviateNumber(value)
	value = toNumber(value) or 0
	if gameFormat then
		local ok, text = pcall(gameFormat, value)
		if ok and type(text) == "string" and text ~= "" then
			return text
		end
	end
	local sign = value < 0 and "-" or ""
	local scaled = math.abs(value)
	if scaled < 1000 then
		return sign .. formatCommas(scaled)
	end
	local index = 1
	while scaled >= 1000 and index < #SUFFIX_LIST do
		scaled = scaled / 1000
		index = index + 1
	end
	local text = string.format("%.2f", scaled)
	text = string.gsub(text, "%.00$", "")
	text = string.gsub(text, "(%.%d)0$", "%1")
	return sign .. text .. SUFFIX_LIST[index]
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

local KnitServices
do
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local knit = packages and packages:FindFirstChild("Knit")
	local services = knit and knit:FindFirstChild("Services")
	if not services and packages then
		local index = packages:FindFirstChild("_Index", true)
		if index then
			for _, entry in ipairs(index:GetChildren()) do
				local entryKnit = entry:FindFirstChild("knit")
				local entryServices = entryKnit and entryKnit:FindFirstChild("Services")
				if entryServices then
					services = entryServices
					break
				end
			end
		end
	end
	KnitServices = services
end

local function knitService(name)
	if not KnitServices then
		return nil
	end
	return KnitServices:FindFirstChild(name) or KnitServices:FindFirstChild(name, true)
end

local function waitRemote(service, method)
	local folder = knitService(service)
	if not folder then
		return nil
	end
	for _, kind in ipairs({"RF", "RE"}) do
		local remoteFolder = folder:FindFirstChild(kind)
		local remote = remoteFolder and remoteFolder:FindFirstChild(method)
		if remote then
			return remote
		end
	end
	local ok, waited = pcall(function()
		return folder:WaitForChild("RF", 10):WaitForChild(method, 10)
	end)
	return ok and waited or nil
end

local function findKnitRemote(service, method)
	local folder = knitService(service)
	if not folder then
		return nil
	end
	for _, kind in ipairs({"RF", "RE"}) do
		local remoteFolder = folder:FindFirstChild(kind)
		local remote = remoteFolder and remoteFolder:FindFirstChild(method)
		if remote then
			return remote
		end
	end
	return nil
end

local CastRequest = waitRemote("Fish", "CastRequest")
local MinigameResolved = waitRemote("Fish", "MinigameResolved")
local SellFish = waitRemote("Fish", "SellFish")
local RequestFishData = waitRemote("Fish", "RequestFishData")
local DepositAll = waitRemote("FishStorage", "DepositAll")
local BuyRod = waitRemote("PurchaseController", "BuyRod")
local BuyKnife = waitRemote("PurchaseController", "BuyKnife")
local GetHostKitchen = waitRemote("Coop", "GetHostKitchen")
local StartCutSession = waitRemote("Fish", "StartCutSession")
local ServerAnims = waitRemote("Fish", "ServerAnims")
local CutAction = waitRemote("Fish", "CutAction")
local CutFish = waitRemote("Fish", "CutFish")
local RequestRestaurauntData = waitRemote("Fish", "RequestRestaurauntData")
local Cook = waitRemote("Fish", "Cook")
local StoreFood = waitRemote("Fish", "StoreFood")

local PackagesFolder = find(ReplicatedStorage, "Packages")
local SharedFolder = find(ReplicatedStorage, "Shared") or find(PackagesFolder, "Shared")
local ModulesFolder = find(ReplicatedStorage, "Modules")

local function requireShared(root, name)
	if not root then
		return nil
	end
	local module = root:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local FormatNumber = requireShared(PackagesFolder, "FormatNumber")
local ConfigsFolder = find(PackagesFolder, "Config") or find(PackagesFolder, "Configs")
local RodConfig = requireShared(ConfigsFolder, "RodConfig")
local KnifeConfig = requireShared(ConfigsFolder, "KnifeConfig")
local CookingFormula = requireShared(SharedFolder, "CookingFormula")
local FishIndex = requireShared(SharedFolder, "FishIndex")
local DailyQuestsConfig = requireShared(SharedFolder, "DailyQuestsConfig")
local FishingTypes = requireShared(SharedFolder, "FishingTypes")
local ZoneIndex = requireShared(SharedFolder, "ZoneIndex")
local Overhead = requireShared(SharedFolder, "Overhead")
local SpinConfig = requireShared(SharedFolder, "SpinConfig")
local RodSkinData = requireShared(SharedFolder, "RodSkinData")
local KnifeSkinData = requireShared(SharedFolder, "KnifeSkinData")
local NumberFormat = requireShared(SharedFolder, "NumberFormat")
local GameConfig = requireShared(ModulesFolder, "GameConfig")
local CookingConfig = requireShared(ModulesFolder, "CookingConfig")

if type(NumberFormat) == "table" and type(NumberFormat.abbreviate) == "function" then
	gameFormat = NumberFormat.abbreviate
elseif type(FormatNumber) == "function" then
	gameFormat = FormatNumber
elseif type(FormatNumber) == "table" and type(FormatNumber.FormatNumber) == "function" then
	gameFormat = FormatNumber.FormatNumber
end

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = {
		Level = tonumber(statValue("Level", "Rank", "PlayerLevel")) or 1,
		Cash = tonumber(statValue("Cash", "Coins", "Money")) or 0,
		Fish = tonumber(statValue("Fish", "FishCaught", "Caught")) or 0,
	}
	playerDataAt = tick()
	return playerDataCache
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
	return character and character:FindFirstChild("HumanoidRootPart")
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

local function getLevel()
	local data = getPlayerData()
	return data.Level or 1
end

local function getCash()
	local data = getPlayerData()
	return data.Cash or 0
end

local function getFishCount()
	local data = getPlayerData()
	return data.Fish or 0
end

local function getFishStock()
	return tonumber(statValue("FishStock", "Stock", "Inventory")) or 0
end

local function option(name, default)
	local value = tonumber(Options[name])
	if value == nil then
		return default
	end
	return value
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local CAST_POWER = 99999999999
local SELL_WEIGHT = 9999999999
local MAX_FISH_ID = 1000

local function nameList(config, fallback)
	if type(config) ~= "table" then
		return fallback
	end
	local list = config
	if type(config.Rods) == "table" then
		list = config.Rods
	elseif type(config.Items) == "table" then
		list = config.Items
	elseif type(config.Fishes) == "table" then
		list = config.Fishes
	end
	if type(list) ~= "table" then
		return fallback
	end
	local out = {}
	if type(list[1]) == "table" then
		for _, entry in ipairs(list) do
			local name = type(entry) == "table" and (entry.Name or entry.name) or entry
			if type(name) == "string" then
				table.insert(out, name)
			end
		end
	else
		for _, entry in ipairs(list) do
			if type(entry) == "string" then
				table.insert(out, entry)
			end
		end
	end
	if #out > 0 then
		return out
	end
	return fallback
end

local function assetNames(folderName, fallback)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild(folderName, true)
	if not folder then
		return fallback
	end
	local values = {}
	for _, child in ipairs(folder:GetChildren()) do
		local label = child:GetAttribute("DisplayName") or child:GetAttribute("ItemName")
		table.insert(values, tostring(label or child.Name))
	end
	if #values == 0 then
		return fallback
	end
	return values
end

local ROD_NAMES = assetNames("Rods", nameList(RodConfig, {
	"Spirit Cat Rod",
	"Glacier Rod",
	"Kitsune Rod",
	"Sea Dragon Rod",
	"Admin Rod",
	"Leviathan Spine Rod",
	"Moontuna Rod",
	"Dragon Rod",
	"Godzilla Rod",
}))

local KNIFE_NAMES = assetNames("Knives", nameList(KnifeConfig, {
	"Kitsune Knife",
	"Tiger Cleaver",
	"Fire Dragon Knife",
	"Yin Yang Knife",
}))

local RAINBOW_COLORS = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 127, 0),
	Color3.fromRGB(255, 255, 0),
	Color3.fromRGB(0, 255, 0),
	Color3.fromRGB(0, 0, 255),
	Color3.fromRGB(75, 0, 130),
	Color3.fromRGB(148, 0, 211),
}

local FISHING_TAG = "FishingEnabled"
local FISHING_REACH = 16
local FISHING_DROP = 50
local SPIN_SERVICES = {"PurchaseController", "Spin", "Crate", "Crates", "SkinService", "Lucky"}
local SPIN_METHODS = {"OpenCrate", "Spin", "OpenSpin", "ClaimCrate", "Claim", "Open"}
local FISH_PREFERENCE = {
	"atomic_helicoprion",
	"atomic_dunkleosteus",
	"atomic_leviathan",
	"mutated_godzilla",
	"godzilla",
	"heavenly_koi",
	"king_sea_dragon",
	"megalodon",
	"baby_shark",
}

local function allowedToolNames()
	if FishingTypes and type(FishingTypes.AllowedToolNames) == "table" and #FishingTypes.AllowedToolNames > 0 then
		return FishingTypes.AllowedToolNames
	end
	return {"FishingRod"}
end

local function fishingParts()
	local parts = {}
	if CollectionService and type(CollectionService.GetTagged) == "function" then
		local ok, tagged = pcall(CollectionService.GetTagged, CollectionService, FISHING_TAG)
		if ok and type(tagged) == "table" then
			for _, part in ipairs(tagged) do
				if part:IsA("BasePart") then
					table.insert(parts, part)
				end
			end
		end
	end
	if #parts == 0 then
		for _, name in ipairs({"AdditionalFishingZones", "Map"}) do
			local folder = Workspace:FindFirstChild(name, true)
			if folder then
				for _, part in ipairs(folder:GetDescendants()) do
					if part:IsA("BasePart") then
						table.insert(parts, part)
					end
				end
			end
		end
	end
	return parts
end

local function canCastFromCharacter()
	local character = getCharacter()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, nil
	end
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude == 0 then
		return false, nil
	end
	local origin = root.Position + flat.Unit * FISHING_REACH + Vector3.new(0, 5, 0)
	local targets = {}
	local map = Workspace:FindFirstChild("Map")
	if map then
		table.insert(targets, map)
	end
	table.insert(targets, Workspace.Terrain)
	local extra = Workspace:FindFirstChild("AdditionalFishingZones")
	if extra then
		table.insert(targets, extra)
	end
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = targets
	params.FilterType = Enum.RaycastFilterType.Include
	params.IgnoreWater = false
	local result = Workspace:Raycast(origin, Vector3.new(0, -FISHING_DROP, 0), params)
	if not result then
		return false, nil
	end
	local valid = false
	if result.Instance == Workspace.Terrain then
		valid = result.Material == Enum.Material.Water
	else
		valid = CollectionService:HasTag(result.Instance, FISHING_TAG)
	end
	return valid, result.Position
end

local function nearestFishingSpot()
	local root = getRoot()
	if not root then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, part in ipairs(fishingParts()) do
		local distance = (part.Position - root.Position).Magnitude
		if distance < bestDistance then
			bestDistance = distance
			best = part
		end
	end
	return best
end

local function faceFishingSpot()
	local spot = nearestFishingSpot()
	local root = getRoot()
	if not spot or not root then
		return false
	end
	local flat = Vector3.new(spot.Position.X - root.Position.X, 0, spot.Position.Z - root.Position.Z)
	if flat.Magnitude < 0.5 then
		return false
	end
	root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	return true
end

local function teleportToFishingSpot()
	local spot = nearestFishingSpot()
	local root = getRoot()
	if not spot or not root then
		return false
	end
	local flat = Vector3.new(root.Position.X - spot.Position.X, 0, root.Position.Z - spot.Position.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local stand = spot.Position - flat.Unit * 12 + Vector3.new(0, 4, 0)
	root.CFrame = CFrame.lookAt(stand, spot.Position)
	return true
end

local function equippedRodName()
	local character = getCharacter()
	if not character then
		return nil
	end
	for _, name in ipairs(allowedToolNames()) do
		local tool = character:FindFirstChild(name)
		if tool and tool:IsA("Tool") then
			return tool.Name
		end
	end
	return nil
end

local function equipRod()
	local humanoid = getHumanoid()
	if not humanoid then
		return false
	end
	if equippedRodName() then
		return true
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		return false
	end
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("Tool") then
			for _, name in ipairs(allowedToolNames()) do
				if string.find(string.lower(child.Name), string.lower(name), 1, true) then
					humanoid:EquipTool(child)
					return true
				end
			end
		end
	end
	return false
end

local function zoneList()
	local values = {"My Island"}
	if type(ZoneIndex) ~= "table" then
		return values
	end
	if type(ZoneIndex._ORDER) == "table" then
		for _, key in ipairs(ZoneIndex._ORDER) do
			if type(key) == "string" and type(ZoneIndex[key]) == "table" then
				table.insert(values, key)
			end
		end
	end
	for key, entry in pairs(ZoneIndex) do
		if type(key) == "string" and key ~= "_ORDER" and type(entry) == "table" and not string.find(key, "_DISABLED", 1, true) then
			local known = false
			for _, existing in ipairs(values) do
				if existing == key then
					known = true
					break
				end
			end
			if not known then
				table.insert(values, key)
			end
		end
	end
	return values
end

local function zoneEntry(zone)
	if type(ZoneIndex) ~= "table" or type(zone) ~= "string" then
		return nil
	end
	local entry = ZoneIndex[zone]
	if type(entry) == "table" then
		return entry
	end
	return nil
end

local function zoneFish(zone)
	local entry = zoneEntry(zone)
	if not entry or type(entry.fish) ~= "table" then
		return nil
	end
	return entry.fish
end

local function zoneBestFish(zone)
	local fish = zoneFish(zone)
	if type(fish) ~= "table" or #fish == 0 then
		return nil
	end
	return fish[#fish]
end

local function currentZone()
	local value = Options.ZoneTarget
	if type(value) == "string" and value ~= "" then
		return value
	end
	return nil
end

local function zoneTarget(zone)
	if zone == nil or zone == "" or zone == "My Island" then
		return nil
	end
	local direct = Workspace:FindFirstChild(zone, true)
	if direct then
		return direct
	end
	local lowered = string.lower(zone)
	for _, part in ipairs(fishingParts()) do
		if string.find(string.lower(part.Name), lowered, 1, true) then
			return part
		end
	end
	return nil
end

local function chefLevel()
	return math.max(1, math.floor(tonumber(statValue("ChefLevel", "Chef", "Level")) or 1))
end

local function cookableDishes()
	local fallback = {
		"Nigiri",
		"Sashimi",
		"Sushi",
		"Grilled Snapper",
		"Shrimp Tempura",
		"Takoyaki",
		"Mooncake",
		"BBQ Angler Fish",
		"Grilled Shark",
		"Tuna Croquette",
		"Soy Glazed Eel",
		"Tempura Salmon",
	}
	if type(GameConfig) ~= "table" or type(GameConfig.CookableFood) ~= "table" then
		return fallback
	end
	local list = GameConfig.CookableFood[math.min(chefLevel(), #GameConfig.CookableFood)]
	if type(list) ~= "table" or #list == 0 then
		return fallback
	end
	return list
end

local function chefBonus(dish)
	if type(GameConfig) ~= "table" or type(GameConfig.Chefs) ~= "table" then
		return 1
	end
	local level = math.min(chefLevel(), #GameConfig.Chefs)
	local chef = GameConfig.Chefs[level]
	local bonuses = chef and chef.Stats and chef.Stats.DishBonuses
	local bonus = bonuses and bonuses[dish]
	if type(bonus) == "number" and bonus > 0 then
		return bonus
	end
	return 1
end

local function stallLevel()
	local xp = tonumber(statValue("XP", "Experience", "StallXP", "StallExp", "StallLevel"))
	if xp == nil then
		return 0
	end
	local levels = GameConfig and GameConfig.Levels and GameConfig.Levels.Stall
	if type(levels) ~= "table" then
		return 0
	end
	local level = 0
	for index, threshold in ipairs(levels) do
		if xp >= threshold then
			level = index
		end
	end
	return level
end

local function productCount()
	local count = 0
	for _, data in ipairs({RodSkinData, KnifeSkinData}) do
		if type(data) == "table" and type(data.Products) == "table" then
			count = count + #data.Products
		end
	end
	if count == 0 and type(SpinConfig) == "table" and type(SpinConfig.Items) == "table" then
		count = #SpinConfig.Items
	end
	return count
end

local function spinRemotes()
	local found
	for _, service in ipairs(SPIN_SERVICES) do
		for _, method in ipairs(SPIN_METHODS) do
			if not found then
				found = findKnitRemote(service, method)
			end
		end
	end
	return found
end

local function doAutoSpin()
	if not enabled.spin then
		return
	end
	if not ready("spin", 2) then
		return
	end
	local remote = spinRemotes()
	if not remote then
		return
	end
	setFarmStatus("spinning")
	call(remote)
	playerDataAt = 0
end

local function showOverhead(text)
	if type(Overhead) ~= "table" or type(Overhead.ShowText) ~= "function" then
		return false
	end
	return pcall(Overhead.ShowText, LocalPlayer, tostring(text), {
		RichText = true,
		HoldTime = 1.5,
		Drift = 0,
		YOffset = 2,
		MaxDistance = 120,
		TextSize = 18,
		MaxWidth = 220,
	})
end

local function clearOverhead()
	if type(Overhead) ~= "table" or type(Overhead.Clear) ~= "function" then
		return
	end
	pcall(Overhead.Clear, LocalPlayer)
end

local rainbowProgress = 0
local titleColorSaved = nil
local lastOverhead = nil

local function titleModule()
	local folder = Workspace:FindFirstChild(LocalPlayer.Name)
	local module = folder and (folder:FindFirstChild("Title") or folder:FindFirstChild("TitleGui"))
	if module then
		return module
	end
	local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	for _, child in ipairs(gui:GetChildren()) do
		local inner = child:FindFirstChild("Title") or child
		if inner:FindFirstChild("TitleName") or inner:FindFirstChild("PlayerLevel") then
			return inner
		end
	end
	return nil
end

local function titleLabel(module, name)
	local node = module and module:FindFirstChild(name)
	if not node then
		return nil
	end
	if node:IsA("TextLabel") or node:IsA("TextButton") then
		return node
	end
	return node:FindFirstChildWhichIsA("TextLabel", true)
end

local function equippedGear()
	local result = {}
	local sources = {LocalPlayer:FindFirstChildOfClass("Backpack"), getCharacter()}
	for _, source in ipairs(sources) do
		if source then
			for _, child in ipairs(source:GetChildren()) do
				if child:IsA("Tool") then
					local lowered = string.lower(child.Name)
					if not result.Rod and string.find(lowered, "rod", 1, true) then
						result.Rod = child.Name
					end
					if not result.Knife and string.find(lowered, "knife", 1, true) then
						result.Knife = child.Name
					end
				end
			end
		end
	end
	return result
end

local function applyTitle()
	local module = titleModule()
	if not module then
		return
	end
	if settings.titleLevel ~= nil then
		local label = titleLabel(module, "PlayerLevel")
		if label then
			label.Text = tostring(settings.titleLevel)
		end
	end
	if settings.titleName ~= nil then
		local label = titleLabel(module, "PlayerName")
		if label then
			label.Text = tostring(settings.titleName)
		end
	end
	if settings.titleText ~= nil then
		local label = titleLabel(module, "TitleName")
		if label then
			label.Text = tostring(settings.titleText)
		end
	end
	if settings.overhead ~= nil and settings.overhead ~= lastOverhead then
		lastOverhead = settings.overhead
		showOverhead(lastOverhead)
	end
	if not enabled.rainbow then
		return
	end
	local label = titleLabel(module, "TitleName")
	if not label then
		return
	end
	if titleColorSaved == nil then
		titleColorSaved = label.TextColor3
	end
	rainbowProgress = (rainbowProgress + (option("RainbowSpeed", 0.02) or 0.02)) % #RAINBOW_COLORS
	local index = math.floor(rainbowProgress) + 1
	local nextIndex = (index % #RAINBOW_COLORS) + 1
	local amount = rainbowProgress - math.floor(rainbowProgress)
	local from = RAINBOW_COLORS[index]
	local to = RAINBOW_COLORS[nextIndex]
	label.TextColor3 = Color3.new(
		from.R + (to.R - from.R) * amount,
		from.G + (to.G - from.G) * amount,
		from.B + (to.B - from.B) * amount
	)
end

local function resetTitleColor()
	local label = titleLabel(titleModule(), "TitleName")
	if label and titleColorSaved then
		label.TextColor3 = titleColorSaved
	end
	titleColorSaved = nil
end

local function doAutoFish()
	if not enabled.fish or not CastRequest then
		return
	end
	if enabled.equiprod then
		equipRod()
	end
	if enabled.facewater then
		faceFishingSpot()
		task.wait(0.05)
	end
	setFarmStatus("fishing")
	call(CastRequest, CAST_POWER)
	task.wait(3)
	if not session.running or not enabled.fish then
		return
	end
	if MinigameResolved then
		call(MinigameResolved, true)
	end
	playerDataAt = 0
	task.wait(0.1)
end

local function sellPass()
	if not SellFish then
		return false
	end
	setFarmStatus("selling")
	for id = 1, MAX_FISH_ID do
		if not session.running or not enabled.sell then
			return true
		end
		fire(SellFish, {{ID = id, Name = "fish", Weight = SELL_WEIGHT}})
		task.wait(0.002)
	end
	playerDataAt = 0
	return true
end

local function doAutoSell()
	if not enabled.sell then
		return
	end
	sellPass()
end

local function doAutoDeposit()
	if not enabled.deposit or not DepositAll then
		return
	end
	setFarmStatus("depositing")
	fire(DepositAll)
	playerDataAt = 0
end

local function buyAll(list, remote, label)
	if not remote then
		return
	end
	setFarmStatus(label)
	for _, name in ipairs(list) do
		if not session.running then
			return
		end
		call(remote, name)
		task.wait(0.1)
	end
	playerDataAt = 0
end

local function getAllRods()
	buyAll(ROD_NAMES, BuyRod, "buying rods")
end

local function getAllKnives()
	buyAll(KNIFE_NAMES, BuyKnife, "buying knives")
end

local function doAutoBuyRods()
	if not enabled.buyrods then
		return
	end
	buyAll(ROD_NAMES, BuyRod, "buying rods")
end

local function doAutoBuyKnives()
	if not enabled.buyknives then
		return
	end
	buyAll(KNIFE_NAMES, BuyKnife, "buying knives")
end

local function depositAll()
	if not DepositAll then
		return
	end
	setFarmStatus("depositing")
	fire(DepositAll)
	playerDataAt = 0
end

local CUT_QUALITY = 4
local DEFAULT_FISH_CF = "baby_shark"
local DEFAULT_FISH_WEIGHT = 4.1222655608094581

local QUEST_SERVICES = {"Quest", "Quests", "DailyQuests", "QuestService", "DailyQuestService"}
local QUEST_DATA_METHODS = {"GetQuests", "RequestQuests", "GetData", "RequestData"}
local QUEST_CLAIM_METHODS = {"ClaimQuest", "CompleteQuest", "ClaimReward", "ClaimDailyQuest", "ClaimStarterQuest", "Claim"}

local function plotContainer()
	local plots = find(Workspace, "Code", "Plots")
	if plots then
		return plots
	end
	local code = Workspace:FindFirstChild("Code")
	if code then
		plots = code:FindFirstChild("Plots")
		if plots then
			return plots
		end
	end
	return Workspace:FindFirstChild("Plots", true)
end

local function plotFor(player)
	local plots = plotContainer()
	if not plots then
		return nil
	end
	local byName = plots:FindFirstChild(player.Name)
	if byName then
		return byName
	end
	local byId = plots:FindFirstChild(tostring(player.UserId))
	if byId then
		return byId
	end
	for _, child in ipairs(plots:GetChildren()) do
		local owner = attributeOf(child, "Owner", "OwnerUserId", "UserId", "Player")
		if owner == player.UserId or owner == player.Name then
			return child
		end
	end
	return nil
end

local function myPlot()
	return plotFor(LocalPlayer)
end

local function cuttingBoard()
	local plot = myPlot()
	if not plot then
		return Workspace:FindFirstChild("CuttingBoard", true)
	end
	local stall = plot:FindFirstChild("STALL")
	local station = stall and stall:FindFirstChild("CookingStation")
	local board = station and station:FindFirstChild("CuttingBoard")
	if board then
		return board
	end
	station = plot:FindFirstChild("CookingStation", true)
	board = station and station:FindFirstChild("CuttingBoard")
	if board then
		return board
	end
	return plot:FindFirstChild("CuttingBoard", true)
end

local ORDER_KEYS = {"Order", "Dish", "Recipe", "Food", "Wanted", "Request", "Item", "DishName"}

local function isCustomerModel(model)
	if not model:IsA("Model") then
		return false
	end
	local head = model:FindFirstChild("Head")
	if not head then
		return false
	end
	return head:FindFirstChild("NPCName") ~= nil
end

local function customerList()
	local values = {}
	for _, child in ipairs(Workspace:GetChildren()) do
		if isCustomerModel(child) then
			table.insert(values, child)
		end
	end
	if #values == 0 then
		for _, child in ipairs(Workspace:GetDescendants()) do
			if isCustomerModel(child) then
				table.insert(values, child)
			end
		end
	end
	return values
end

local function customerPrompt(customer)
	if not customer then
		return nil
	end
	local part = customer:FindFirstChild("HumanoidRootPart")
	if not part then
		part = customer:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part then
		return nil
	end
	return part:FindFirstChild("ProximityPrompt")
end

local function pressPrompt(prompt)
	if not prompt then
		return false
	end
	if type(fireproximityprompt) == "function" then
		local ok = pcall(fireproximityprompt, prompt)
		return ok
	end
	if type(prompt.Invoke) == "function" then
		return pcall(prompt.Invoke, prompt)
	end
	return false
end

local function findCustomer()
	local root = getRoot()
	local best, bestDistance = nil, math.huge
	for _, model in ipairs(customerList()) do
		if not root then
			return model
		end
		local position = safePivot(model)
		if position then
			local distance = (position - root.Position).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				best = model
			end
		end
	end
	return best
end

local function orderedDishes(customer)
	local values = {}
	if not customer then
		return values
	end
	local seen = {}
	local function push(value)
		if type(value) ~= "string" or value == "" then
			return
		end
		local cleaned = string.gsub(value, "%s+", " ")
		local best
		if type(CookingConfig) == "table" then
			for dish in pairs(CookingConfig) do
				if type(dish) == "string" and string.find(cleaned, dish, 1, true) then
					if not best or #dish > #best then
						best = dish
					end
				end
			end
		else
			for _, entry in ipairs(cookableDishes()) do
				local dish = type(entry) == "table" and (entry.Name or entry.Key) or entry
				if type(dish) == "string" and string.find(cleaned, dish, 1, true) then
					if not best or #dish > #best then
						best = dish
					end
				end
			end
		end
		if best and not seen[best] then
			seen[best] = true
			table.insert(values, best)
		end
	end
	local function read(node)
		if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
			push(node.Text)
		elseif node:IsA("StringValue") then
			push(node.Value)
		elseif node:IsA("ObjectValue") then
			local target = node.Value
			if type(target) == "string" then
				push(target)
			elseif typeof(target) == "Instance" then
				push(target.Name)
				if target:IsA("StringValue") then
					push(target.Value)
				end
			end
		end
		for _, key in ipairs(ORDER_KEYS) do
			local attribute = node:GetAttribute(key)
			if type(attribute) == "string" then
				push(attribute)
			elseif type(attribute) == "table" then
				for _, entry in ipairs(attribute) do
					push(entry)
				end
			end
		end
	end
	read(customer)
	for _, node in ipairs(customer:GetDescendants()) do
		read(node)
	end
	if #values == 0 then
		local gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if gui then
			for _, node in ipairs(gui:GetDescendants()) do
				if node:IsA("BillboardGui") or node:IsA("SurfaceGui") or string.find(string.lower(node.Name), "order", 1, true) or string.find(string.lower(node.Name), "bubble", 1, true) or string.find(string.lower(node.Name), "speech", 1, true) then
					read(node)
					for _, inner in ipairs(node:GetDescendants()) do
						read(inner)
					end
				end
			end
		end
	end
	return values
end

local function readOrderDump(node)
	local text = ""
	if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
		text = node.Text
	elseif node:IsA("StringValue") then
		text = node.Value
	elseif node:IsA("ObjectValue") then
		local target = node.Value
		if type(target) == "string" then
			text = target
		elseif typeof(target) == "Instance" then
			text = target.Name .. " (" .. target.ClassName .. ")"
		end
	end
	local attributes = {}
	for key, value in pairs(node:GetAttributes()) do
		table.insert(attributes, key .. "=" .. tostring(value))
	end
	if (type(text) == "string" and text ~= "") or #attributes > 0 then
		warn("[AntiGodHub]   " .. node:GetFullName() .. " [" .. node.ClassName .. "] text=" .. tostring(text) .. " attrs={" .. table.concat(attributes, ", ") .. "}")
	end
	for _, child in ipairs(node:GetChildren()) do
		readOrderDump(child)
	end
end

local function debugOrders()
	local models = customerList()
	if #models == 0 then
		warn("[AntiGodHub] NO CUSTOMERS FOUND - looking for Model with Head.NPCName")
		for _, child in ipairs(Workspace:GetChildren()) do
			if child:IsA("Model") then
				warn("[AntiGodHub]   candidate Model: " .. child.Name)
			end
		end
		return
	end
	for _, model in ipairs(models) do
		warn("[AntiGodHub] CUSTOMER " .. model:GetFullName())
		readOrderDump(model)
	end
end

local function getFishWeight()
	return tonumber(statValue("FishWeight", "Weight", "BestFishWeight", "FishSize")) or DEFAULT_FISH_WEIGHT
end

local function getFishConfigKey()
	local best = zoneBestFish(currentZone())
	if type(best) == "string" then
		return best
	end
	if type(FishIndex) == "table" then
		for _, key in ipairs(FISH_PREFERENCE) do
			if FishIndex[key] ~= nil then
				return key
			end
		end
	end
	return DEFAULT_FISH_CF
end

local function buildCookedFish(fish, dish)
	local entry = type(fish) == "table" and fish or {}
	local value = 0
	if CookingFormula and type(CookingFormula.ComputeDishValue) == "function" then
		local ok, computed = pcall(CookingFormula.ComputeDishValue, dish, getFishWeight(), CUT_QUALITY, 1, 1, chefBonus(dish) - 1)
		if ok and type(computed) == "number" then
			value = math.floor(computed)
		end
	else
		value = math.floor(tonumber(entry.Value) or 0)
	end
	return {
		CF = entry.CF or getFishConfigKey(),
		Name = "Fish Filet",
		Amount = 1,
		Value = value,
		Mutations = type(entry.Mutations) == "table" and entry.Mutations or {},
		Data = CUT_QUALITY,
		ID = entry.ID or 2,
	}
end

local function cookPass(fish, dish)
	if not StartCutSession or not CutAction or not Cook then
		return false
	end
	local board = cuttingBoard()
	local selected = dish or "Sashimi"
	setFarmStatus("cooking " .. tostring(selected))
	if GetHostKitchen then
		call(GetHostKitchen)
	end
	if board then
		local boardPrompt = board:FindFirstChild("ProximityPrompt", true)
		if pressPrompt(boardPrompt) then
			task.wait(0.15)
		end
	end
	if not session.running then
		return false
	end
	call(StartCutSession)
	task.wait(0.15)
	fire(CutAction, 1)
	task.wait(0.15)
	fire(CutAction, 2)
	task.wait(0.15)
	if ServerAnims and board then
		fire(ServerAnims, "CuttingBoard", board, false)
	end
	task.wait(0.15)
	call(CutFish, 1, 1.85)
	task.wait(0.15)
	if RequestRestaurauntData then
		call(RequestRestaurauntData)
	end
	task.wait(0.15)
	call(Cook, selected, buildCookedFish(fish, selected))
	playerDataAt = 0
	return true
end

local function inventoryFish()
	local values = {}
	local data = call(RequestFishData)
	if type(data) == "table" then
		for _, entry in ipairs(data) do
			if type(entry) == "table" and entry.ID then
				table.insert(values, {
					ID = entry.ID,
					CF = entry.CF or entry.Name or DEFAULT_FISH_CF,
					Mutations = type(entry.Mutations) == "table" and entry.Mutations or {},
					Data = entry.Data or CUT_QUALITY,
					Value = tonumber(entry.Value) or 0,
				})
			end
		end
	end
	return values
end

local function questRemotes()
	local data, claim
	for _, service in ipairs(QUEST_SERVICES) do
		for _, method in ipairs(QUEST_DATA_METHODS) do
			if not data then
				data = findKnitRemote(service, method)
			end
		end
		for _, method in ipairs(QUEST_CLAIM_METHODS) do
			if not claim then
				claim = findKnitRemote(service, method)
			end
		end
	end
	return data, claim
end

local function activeQuest()
	if DailyQuestsConfig and type(DailyQuestsConfig.ActiveQuest) == "function" then
		local ok, quest = pcall(DailyQuestsConfig.ActiveQuest)
		if ok and type(quest) == "table" then
			return quest
		end
	end
	return nil
end

local function questDay()
	if DailyQuestsConfig and type(DailyQuestsConfig.DayIndex) == "function" then
		local ok, day = pcall(DailyQuestsConfig.DayIndex)
		if ok and type(day) == "number" then
			return day
		end
	end
	return 0
end

local function doAutoQuest()
	if not enabled.quest then
		return
	end
	if not ready("quest", 3) then
		return
	end
	local data, claim = questRemotes()
	setFarmStatus("questing")
	if data then
		call(data)
	end
	if claim then
		local questId = tonumber(statValue("Quest", "QuestID", "QuestId", "CurrentQuest"))
		if questId then
			call(claim, questId)
		else
			call(claim)
		end
		playerDataAt = 0
	end
end

local function claimDailyReward()
	local _, claim = questRemotes()
	if not claim then
		return
	end
	setFarmStatus("claiming")
	call(claim)
	playerDataAt = 0
end

local function collectIslands()
	local values = zoneList()
	local plots = plotContainer()
	if plots then
		for _, child in ipairs(plots:GetChildren()) do
			local island = attributeOf(child, "Island", "Zone", "Biome", "Area")
			if island ~= nil then
				local name = tostring(island)
				local known = false
				for _, existing in ipairs(values) do
					if existing == name then
						known = true
						break
					end
				end
				if not known then
					table.insert(values, name)
				end
			end
		end
	end
	return values
end

local function islandTarget(value)
	if value == nil or value == "" or value == "My Island" then
		return myPlot()
	end
	return zoneTarget(value)
end

local function teleportToIsland(value)
	local target = islandTarget(value)
	local position = safePivot(target)
	if not position then
		return false
	end
	setFarmStatus("teleporting")
	return teleportTo(position)
end

local function doAutoHome()
	if not enabled.home then
		return
	end
	if not ready("home", 2) then
		return
	end
	local plot = myPlot()
	local position = safePivot(plot)
	local root = getRoot()
	if not position or not root then
		return
	end
	if (position - root.Position).Magnitude > 200 then
		teleportTo(position)
	end
end

local function doAutoSpot()
	if not enabled.spot then
		return
	end
	if not ready("spot", 2) then
		return
	end
	local valid = canCastFromCharacter()
	if valid then
		return
	end
	if teleportToFishingSpot() then
		task.wait(0.1)
		faceFishingSpot()
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
				local camera = Workspace.CurrentCamera
				VirtualUser:Button2Down(Vector2.new(), camera.CFrame)
				task.wait(0.1)
				VirtualUser:Button2Up(Vector2.new(), camera.CFrame)
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
			_G.settings().Rendering.QualityLevel = 1
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
local FISH_SPOTS = {
	{ Name = "No TP (Stay Here)", Position = nil },
	{ Name = "Moon Tuna Hunt", Position = Vector3.new(60, 10, -858) },
	{ Name = "Moon Tuna Islands 2", Position = Vector3.new(-166, 9, -817) },
	{ Name = "Moon Tuna Islands 3", Position = Vector3.new(40, 8, -586) },
	{ Name = "Koi Pond", Position = Vector3.new(-88, 11, -1350) },
	{ Name = "Shark Hunt", Position = Vector3.new(-16, 4, 325) },
	{ Name = "Bamboo Islands", Position = Vector3.new(-2359, 4, -928) },
	{ Name = "Snow Islands", Position = Vector3.new(-3743, 6, 1484) },
	{ Name = "Location 1", Position = Vector3.new(-112.332, 2.689, -1336.005) },
	{ Name = "Location 2", Position = Vector3.new(-3875.299, 38.839, 1557.888) },
	{ Name = "Location 3", Position = Vector3.new(-1315.620, 37.832, 1635.639) },
	{ Name = "Location 4 (Ocean)", Position = Vector3.new(-2.137, 23.070, 175.539) },
}

local function teleportToSpot(value)
	local index = tonumber(value)
	if not index or index < 1 or index > #FISH_SPOTS then
		return false
	end
	local position = FISH_SPOTS[index].Position
	if not position then
		return false
	end
	setFarmStatus("teleporting")
	return teleportTo(position)
end

local lightOriginals

local function updateLighting()
	if not lightOriginals then
		return
	end
	if enabled.fullbright then
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.new(0.8, 0.8, 0.8)
		Lighting.OutdoorAmbient = Color3.new(0.8, 0.8, 0.8)
		Lighting.ExposureCompensation = 0.5
	else
		Lighting.Brightness = lightOriginals.Brightness
		Lighting.GlobalShadows = lightOriginals.GlobalShadows
		Lighting.Ambient = lightOriginals.Ambient
		Lighting.OutdoorAmbient = lightOriginals.OutdoorAmbient
		Lighting.ExposureCompensation = lightOriginals.ExposureCompensation
	end
	if enabled.nofog then
		Lighting.FogEnd = 1e8
		Lighting.FogStart = 1e8
		Lighting.FogColor = Color3.new(1, 1, 1)
	end
	if enabled.day then
		Lighting.ClockTime = 14
	elseif enabled.night then
		Lighting.ClockTime = 23
	end
	if enabled.ambient then
		local color = Color3.new(option("AmbientRed", 0.32) or 0.32, option("AmbientGreen", 0.32) or 0.32, option("AmbientBlue", 0.32) or 0.32)
		Lighting.Ambient = color
		Lighting.OutdoorAmbient = color
	end
end

local function setLighting(state)
	if state and not lightOriginals then
		lightOriginals = {
			Brightness = Lighting.Brightness,
			GlobalShadows = Lighting.GlobalShadows,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			ExposureCompensation = Lighting.ExposureCompensation,
		}
	elseif not state and lightOriginals then
		Lighting.Brightness = lightOriginals.Brightness
		Lighting.GlobalShadows = lightOriginals.GlobalShadows
		Lighting.Ambient = lightOriginals.Ambient
		Lighting.OutdoorAmbient = lightOriginals.OutdoorAmbient
		Lighting.ExposureCompensation = lightOriginals.ExposureCompensation
		lightOriginals = nil
	end
	updateLighting()
end

local function applyMovement()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	local speed = option("WalkSpeed", 0)
	if speed and speed > 0 then
		humanoid.WalkSpeed = speed
	end
	local jump = option("JumpPower", 0)
	if jump and jump > 0 then
		humanoid.JumpPower = jump
	end
end

local flyConnection

local function setFly(state)
	enabled.fly = state
	if state and not flyConnection then
		flyConnection = RunService.Heartbeat:Connect(function()
			if not enabled.fly then
				return
			end
			local root = getRoot()
			local humanoid = getHumanoid()
			local camera = Workspace.CurrentCamera
			if not root or not humanoid or not camera then
				return
			end
			humanoid.PlatformStand = true
			local direction = Vector3.new()
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then
				direction = direction + camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then
				direction = direction - camera.CFrame.LookVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then
				direction = direction - camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then
				direction = direction + camera.CFrame.RightVector
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				direction = direction + Vector3.new(0, 1, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
				direction = direction - Vector3.new(0, 1, 0)
			end
			if direction.Magnitude > 0 then
				direction = direction.Unit * (option("FlySpeed", 50) or 50)
			end
			root.AssemblyLinearVelocity = direction
		end)
	elseif not state and flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
		local humanoid = getHumanoid()
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local antiFlingConnection
local antiFlingLast

local function setAntiFling(state)
	enabled.antiFling = state
	if state and not antiFlingConnection then
		antiFlingConnection = RunService.Heartbeat:Connect(function()
			if not enabled.antiFling then
				return
			end
			local root = getRoot()
			if not root then
				return
			end
			local last = antiFlingLast or root.Position
			if root.AssemblyLinearVelocity.Magnitude > 250 or root.AssemblyAngularVelocity.Magnitude > 250 then
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				root.CFrame = CFrame.new(last)
			else
				antiFlingLast = root.Position
			end
		end)
	elseif not state and antiFlingConnection then
		antiFlingConnection:Disconnect()
		antiFlingConnection = nil
	end
end

local flingWalkConnection

local function setFlingWalk(state)
	enabled.flingWalk = state
	if state and not flingWalkConnection then
		flingWalkConnection = RunService.Heartbeat:Connect(function()
			if not enabled.flingWalk then
				return
			end
			local root = getRoot()
			if not root then
				return
			end
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			root.RotVelocity = Vector3.zero
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character then
					local target = player.Character:FindFirstChild("HumanoidRootPart")
					if target and (root.Position - target.Position).Magnitude < 10 then
						local direction = (target.Position - root.Position).Unit
						target.AssemblyLinearVelocity = direction * 600 + Vector3.new(0, 350, 0)
						target.RotVelocity = Vector3.new(math.random(-800, 800), math.random(-800, 800), math.random(-800, 800))
						pcall(function()
							target:SetNetworkOwner(LocalPlayer)
						end)
					end
				end
			end
		end)
	elseif not state and flingWalkConnection then
		flingWalkConnection:Disconnect()
		flingWalkConnection = nil
		local root = getRoot()
		if root then
			root.RotVelocity = Vector3.zero
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local cookIndex = 0
local cooked = {dish = nil, customer = nil, at = 0}

local function bestCustomer()
	local root = getRoot()
	local best, bestWant, bestDistance = nil, nil, math.huge
	for _, model in ipairs(customerList()) do
		local ordered = orderedDishes(model)
		if #ordered > 0 then
			local distance = math.huge
			if root then
				local position = safePivot(model)
				if position then
					distance = (position - root.Position).Magnitude
				end
			end
			if distance < bestDistance then
				bestDistance = distance
				best = model
				bestWant = ordered[1]
			end
		end
	end
	return best, bestWant
end

local function doAutoCook()
	if not enabled.cook then
		return
	end
	if not ready("cook", 1) then
		return
	end
	local customer, want = bestCustomer()
	if not want then
		return
	end
	local list = inventoryFish()
	if #list == 0 then
		if cookPass(nil, want) then
			cooked.dish = want
			cooked.customer = customer
			cooked.at = tick()
		end
		return
	end
	cookIndex = (cookIndex % #list) + 1
	if cookPass(list[cookIndex], want) then
		cooked.dish = want
		cooked.customer = customer
		cooked.at = tick()
	end
	task.wait(0.5)
end

local function doAutoServe()
	if not enabled.serve or not StoreFood then
		return
	end
	if not ready("serve", 1) then
		return
	end
	if not cooked.dish then
		return
	end
	local customer = cooked.customer
	if not customer or not customer.Parent then
		cooked.dish = nil
		return
	end
	local current = orderedDishes(customer)
	if #current == 0 or current[1] ~= cooked.dish then
		cooked.dish = nil
		return
	end
	setFarmStatus("serving " .. tostring(cooked.dish))
	if not pressPrompt(customerPrompt(customer)) then
		fire(StoreFood, customer)
	end
	cooked.dish = nil
	cooked.customer = nil
	playerDataAt = 0
	task.wait(0.1)
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

local FishingTab = Tabs.Main:AddSubTab({ Name = "Fishing", Icon = "star" })
local KitchenTab = Tabs.Main:AddSubTab({ Name = "Kitchen", Icon = "zap" })
local GearTab = Tabs.Main:AddSubTab({ Name = "Gear", Icon = "gauge" })
local TravelTab = Tabs.Main:AddSubTab({ Name = "Travel", Icon = "wind" })
local QuestTab = Tabs.Main:AddSubTab({ Name = "Quest", Icon = "book" })
local TitleTab = Tabs.Main:AddSubTab({ Name = "Title", Icon = "crown" })

local FishBox = box(FishingTab, "Auto Fishing", "star", "Left")
FishBox:AddToggle("AutoFish", { Text = "Auto Fish", Default = false, Callback = function(value)
	enabled.fish = value
end })
FishBox:AddToggle("AutoSell", { Text = "Auto Sell Fish", Default = false, Callback = function(value)
	enabled.sell = value
end })
FishBox:AddToggle("AutoDeposit", { Text = "Auto Deposit", Default = false, Callback = function(value)
	enabled.deposit = value
end })
FishBox:AddDivider()
FishBox:AddToggle("AutoSpot", { Text = "Auto Fishing Spot", Default = true, Callback = function(value)
	enabled.spot = value
end })
FishBox:AddToggle("AutoEquipRod", { Text = "Auto Equip Rod", Default = true, Callback = function(value)
	enabled.equiprod = value
end })
FishBox:AddToggle("AutoFaceWater", { Text = "Auto Face Water", Default = true, Callback = function(value)
	enabled.facewater = value
end })
FishBox:AddDivider()
FishBox:AddButton({ Text = "Sell All Fish", Func = function()
	task.spawn(function()
		local previousState = enabled.sell
		enabled.sell = true
		sellPass()
		enabled.sell = previousState
		setFarmStatus("sold all")
	end)
end })
FishBox:AddButton({ Text = "Deposit All", Func = depositAll })

local StatusBox = box(FishingTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("LevelLabel", { Text = paint("Level -", "1", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("CashLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("FishLabel", { Text = paint("Fish -", "0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("StockLabel", { Text = paint("Stock -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("StallLevelLabel", { Text = paint("Stall Level -", "0", COLORS.accent), DoesWrap = true })

local CookBox = box(KitchenTab, "Auto Kitchen", "zap", "Left")
CookBox:AddToggle("AutoCook", { Text = "Auto Cook", Default = false, Callback = function(value)
	enabled.cook = value
end })
CookBox:AddToggle("AutoServe", { Text = "Auto Serve Customer", Default = false, Callback = function(value)
	enabled.serve = value
end })
CookBox:AddDivider()
CookBox:AddButton({ Text = "Cook Once", Func = function()
	task.spawn(function()
		local customer, want = bestCustomer()
		if not want then
			return
		end
		local list = inventoryFish()
		if #list == 0 then
			if cookPass(nil, want) then
				cooked.dish = want
				cooked.customer = customer
				cooked.at = tick()
			end
			return
		end
		cookIndex = (cookIndex % #list) + 1
		if cookPass(list[cookIndex], want) then
			cooked.dish = want
			cooked.customer = customer
			cooked.at = tick()
		end
	end)
end })
CookBox:AddButton({ Text = "Serve Customer", Func = doAutoServe })
CookBox:AddButton({ Text = "Debug Customer Order", Func = debugOrders })

local KitchenInfoBox = box(KitchenTab, "Kitchen Info", "activity", "Right")
KitchenInfoBox:AddLabel("DishLabel", { Text = paint("Cooking -", "waiting", COLORS.accent), DoesWrap = true })
KitchenInfoBox:AddLabel("FishWeightLabel", { Text = paint("Fish Weight -", "0", COLORS.user), DoesWrap = true })
KitchenInfoBox:AddLabel("BoardLabel", { Text = paint("Cutting Board -", "missing", COLORS.orange), DoesWrap = true })
KitchenInfoBox:AddLabel("CustomerLabel", { Text = paint("Customer -", "none", COLORS.gold), DoesWrap = true })
KitchenInfoBox:AddLabel("CustomerWantLabel", { Text = paint("Customer Want -", "none", COLORS.gold), DoesWrap = true })
KitchenInfoBox:AddLabel("ReadyDishLabel", { Text = paint("Ready To Serve -", "none", COLORS.user), DoesWrap = true })
KitchenInfoBox:AddLabel("ChefLevelLabel", { Text = paint("Chef Level -", "1", COLORS.accent), DoesWrap = true })
KitchenInfoBox:AddLabel("RodReadyLabel", { Text = paint("Rod Equipped -", "no", COLORS.user), DoesWrap = true })

local RodBox = box(GearTab, "Rods", "gauge", "Left")
RodBox:AddToggle("AutoBuyRods", { Text = "Auto Unlock Rods", Default = false, Callback = function(value)
	enabled.buyrods = value
end })
RodBox:AddButton({ Text = "Get All Rods", Func = getAllRods })

local KnifeBox = box(GearTab, "Knives", "target", "Left")
KnifeBox:AddToggle("AutoBuyKnives", { Text = "Auto Unlock Knives", Default = false, Callback = function(value)
	enabled.buyknives = value
end })
KnifeBox:AddButton({ Text = "Get All Knives", Func = getAllKnives })

local CrateBox = box(GearTab, "Crates", "gift", "Left")
CrateBox:AddToggle("AutoSpin", { Text = "Auto Open Crates", Default = false, Callback = function(value)
	enabled.spin = value
end })
CrateBox:AddButton({ Text = "Open All Crates", Func = function()
	task.spawn(function()
		local previousState = enabled.spin
		enabled.spin = true
		doAutoSpin()
		enabled.spin = previousState
	end)
end })

local GearInfoBox = box(GearTab, "Gear Info", "activity", "Right")
GearInfoBox:AddLabel("RodLabel", { Text = paint("Rod -", "none", COLORS.user), DoesWrap = true })
GearInfoBox:AddLabel("KnifeLabel", { Text = paint("Knife -", "none", COLORS.accent), DoesWrap = true })
GearInfoBox:AddLabel("CrateLabel", { Text = paint("Crates -", "0", COLORS.gold), DoesWrap = true })

local TravelBox = box(TravelTab, "Zone Travel", "wind", "Left")
local spotNames = {}
for _, entry in ipairs(FISH_SPOTS) do
	table.insert(spotNames, entry.Name)
end
TravelBox:AddDropdown("FishSpot", { Text = "Fishing Spot", Values = spotNames, Default = spotNames[1] })
TravelBox:AddButton({ Text = "Teleport To Spot", Func = function()
	teleportToSpot(Options.FishSpot)
end })
TravelBox:AddDivider()
local zoneValues = collectIslands()
local ZoneDropdown = TravelBox:AddDropdown("ZoneTarget", { Text = "Zone", Values = zoneValues, Default = "My Island" })
TravelBox:AddButton({ Text = "Teleport To Zone", Func = function()
	teleportToIsland(Options.ZoneTarget)
end })
TravelBox:AddButton({ Text = "Teleport Home", Func = function()
	teleportToIsland("My Island")
end })
TravelBox:AddDivider()
TravelBox:AddToggle("AutoHome", { Text = "Auto Return Home", Default = false, Callback = function(value)
	enabled.home = value
end })

local TravelInfoBox = box(TravelTab, "Travel Info", "gamepad", "Right")
TravelInfoBox:AddLabel("ZoneLabel", { Text = paint("Zone -", "My Island", COLORS.accent), DoesWrap = true })
TravelInfoBox:AddLabel("ZoneFishLabel", { Text = paint("Best Fish -", "none", COLORS.user), DoesWrap = true })
TravelInfoBox:AddLabel("MyIslandLabel", { Text = paint("My Island -", "unknown", COLORS.user), DoesWrap = true })
TravelInfoBox:AddLabel("IslandCountLabel", { Text = paint("Zones -", "1", COLORS.accent), DoesWrap = true })
TravelInfoBox:AddLabel("HomeDistanceLabel", { Text = paint("Home Distance -", "0", COLORS.orange), DoesWrap = true })

local QuestBox = box(QuestTab, "Daily Quest", "book", "Left")
QuestBox:AddToggle("AutoQuest", { Text = "Auto Quest", Default = false, Callback = function(value)
	enabled.quest = value
end })
QuestBox:AddButton({ Text = "Claim Daily Reward", Func = claimDailyReward })

local QuestInfoBox = box(QuestTab, "Quest Info", "book", "Right")
QuestInfoBox:AddLabel("QuestLabel", { Text = paint("Quest -", "none", COLORS.accent), DoesWrap = true })
QuestInfoBox:AddLabel("QuestDayLabel", { Text = paint("Day -", "0", COLORS.orange), DoesWrap = true })
local TitleBox = box(TitleTab, "Custom Title", "crown", "Left")
TitleBox:AddInput("CustomLevel", {
	Text = "Custom Level",
	Placeholder = "Enter level...",
	Default = "",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Callback = function(value)
		settings.titleLevel = value ~= "" and value or nil
		applyTitle()
	end,
})
TitleBox:AddInput("CustomName", {
	Text = "Custom Name",
	Placeholder = "Enter name...",
	Default = "",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Callback = function(value)
		settings.titleName = value ~= "" and value or nil
		applyTitle()
	end,
})
TitleBox:AddInput("CustomTitle", {
	Text = "Custom Title",
	Placeholder = "Enter title...",
	Default = "",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Callback = function(value)
		settings.titleText = value ~= "" and value or nil
		applyTitle()
	end,
})
TitleBox:AddDivider()
TitleBox:AddToggle("RainbowTitle", { Text = "Rainbow Title", Default = false, Callback = function(value)
	enabled.rainbow = value
	if not value then
		rainbowProgress = 0
		resetTitleColor()
	end
end })
TitleBox:AddSlider("RainbowSpeed", { Text = "Rainbow Speed", Default = 0.02, Min = 0.005, Max = 0.2, Rounding = 0 })
TitleBox:AddDivider()
TitleBox:AddInput("OverheadText", {
	Text = "Overhead Text",
	Placeholder = "Enter overhead...",
	Default = "",
	Numeric = false,
	Finished = false,
	ClearTextOnFocus = true,
	Callback = function(value)
		settings.overhead = value ~= "" and value or nil
		applyTitle()
	end,
})
TitleBox:AddButton({ Text = "Clear Overhead", Func = function()
	settings.overhead = nil
	lastOverhead = nil
	clearOverhead()
end })

local TitleInfoBox = box(TitleTab, "Title Info", "info", "Right")
TitleInfoBox:AddLabel("TitleLevelLabel", { Text = paint("Level Text -", "default", COLORS.accent), DoesWrap = true })
TitleInfoBox:AddLabel("TitleNameLabel", { Text = paint("Name Text -", "default", COLORS.user), DoesWrap = true })
TitleInfoBox:AddLabel("TitleTextLabel", { Text = paint("Title Text -", "default", COLORS.gold), DoesWrap = true })

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

local VisualBox = box(Tabs.Settings, "Visual", "sun", "Left")
VisualBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false, Callback = function(value)
	enabled.fullbright = value
	setLighting(true)
end })
VisualBox:AddToggle("NoFog", { Text = "No Fog", Default = false, Callback = function(value)
	enabled.nofog = value
	setLighting(true)
end })
VisualBox:AddToggle("ForceDay", { Text = "Force Day Time", Default = false, Callback = function(value)
	enabled.day = value
	if value then
		enabled.night = false
	end
	setLighting(true)
end })
VisualBox:AddToggle("ForceNight", { Text = "Force Night Time", Default = false, Callback = function(value)
	enabled.night = value
	if value then
		enabled.day = false
	end
	setLighting(true)
end })
VisualBox:AddToggle("AmbientToggle", { Text = "Ambient Changer", Default = false, Callback = function(value)
	enabled.ambient = value
	setLighting(true)
end })
VisualBox:AddSlider("AmbientRed", { Text = "Ambient Red", Default = 0.32, Min = 0, Max = 1, Rounding = 2 })
VisualBox:AddSlider("AmbientGreen", { Text = "Ambient Green", Default = 0.32, Min = 0, Max = 1, Rounding = 2 })
VisualBox:AddSlider("AmbientBlue", { Text = "Ambient Blue", Default = 0.32, Min = 0, Max = 1, Rounding = 2 })

local MoveBox = box(Tabs.Settings, "Movement", "run", "Left")
MoveBox:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = applyMovement })
MoveBox:AddSlider("JumpPower", { Text = "Jump Power", Default = 50, Min = 50, Max = 300, Rounding = 0, Callback = applyMovement })
MoveBox:AddToggle("Fly", { Text = "Fly (WASD, Space, Ctrl)", Default = false, Callback = setFly })
MoveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 300, Rounding = 0 })
MoveBox:AddDivider()
MoveBox:AddToggle("AntiFling", { Text = "Anti Fling", Default = false, Callback = setAntiFling })
MoveBox:AddToggle("FlingWalk", { Text = "Fling Walk", Default = false, Callback = setFlingWalk })

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

local nearestCustomer = nil
local nearestWant = nil
local islandValues = 1

local function updateLabels()
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("LevelLabel", paint("Level -", getLevel(), COLORS.accent))
	setLabel("CashLabel", paint("Cash -", abbreviateNumber(getCash()), COLORS.gold))
	setLabel("FishLabel", paint("Fish -", abbreviateNumber(getFishCount()), COLORS.user))
	setLabel("StockLabel", paint("Stock -", abbreviateNumber(getFishStock()), COLORS.orange))
	local gear = equippedGear()
	setLabel("RodLabel", paint("Rod -", gear.Rod or "none", COLORS.user))
	setLabel("KnifeLabel", paint("Knife -", gear.Knife or "none", COLORS.accent))
	setLabel("DishLabel", paint("Cooking -", nearestWant or "waiting", COLORS.accent))
	setLabel("FishWeightLabel", paint("Fish Weight -", abbreviateNumber(getFishWeight()), COLORS.user))
	setLabel("BoardLabel", paint("Cutting Board -", cuttingBoard() and "ready" or "missing", COLORS.orange))
	if ready("customer", 2) then
		nearestCustomer, nearestWant = bestCustomer()
	end
	setLabel("CustomerLabel", paint("Customer -", nearestCustomer and nearestCustomer.Name or "none", COLORS.gold))
	setLabel("CustomerWantLabel", paint("Customer Want -", nearestWant or "none", COLORS.gold))
	setLabel("ReadyDishLabel", paint("Ready To Serve -", cooked.dish or "none", COLORS.user))
	local plot = myPlot()
	setLabel("MyIslandLabel", paint("My Island -", plot and plot.Name or "unknown", COLORS.user))
	if ready("islands", 15) then
		islandValues = #collectIslands()
	end
	setLabel("IslandCountLabel", paint("Islands -", islandValues, COLORS.accent))
	local homePosition = safePivot(plot)
	local root = getRoot()
	setLabel("HomeDistanceLabel", paint("Home Distance -", homePosition and root and math.floor((homePosition - root.Position).Magnitude) or "0", COLORS.orange))
	local quest = activeQuest()
	setLabel("QuestLabel", paint("Quest -", quest and (quest.Name or quest.Key or quest.Recipe or "active") or "none", COLORS.accent))
	setLabel("QuestDayLabel", paint("Day -", questDay(), COLORS.orange))
	setLabel("StallLevelLabel", paint("Stall Level -", stallLevel(), COLORS.accent))
	setLabel("ChefLevelLabel", paint("Chef Level -", chefLevel(), COLORS.accent))
	setLabel("RodReadyLabel", paint("Rod Equipped -", equippedRodName() or "no", COLORS.user))
	setLabel("CrateLabel", paint("Crates -", productCount(), COLORS.gold))
	local zone = currentZone() or "My Island"
	setLabel("ZoneLabel", paint("Zone -", zone, COLORS.accent))
	setLabel("ZoneFishLabel", paint("Best Fish -", zoneBestFish(zone) or "none", COLORS.user))
	setLabel("TitleLevelLabel", paint("Level Text -", settings.titleLevel or "default", COLORS.accent))
	setLabel("TitleNameLabel", paint("Name Text -", settings.titleName or "default", COLORS.user))
	setLabel("TitleTextLabel", paint("Title Text -", settings.titleText or "default", COLORS.gold))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	local values = collectIslands()
	if #values > 0 and ZoneDropdown and type(ZoneDropdown.SetValues) == "function" then
		pcall(function()
			ZoneDropdown:SetValues(values)
			if type(ZoneDropdown.SetValue) == "function" and Options.ZoneTarget == nil then
				ZoneDropdown:SetValue("My Island")
			end
		end)
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

chain({ doAutoFish }, 0.2)
chain({ doAutoSell }, 0.2)
chain({ doAutoDeposit }, 0.5)
chain({ doAutoCook }, 0.3)
chain({ doAutoServe }, 0.5)
loop(doAutoBuyRods, 3)
loop(doAutoBuyKnives, 3)
loop(doAutoQuest, 1)
loop(doAutoHome, 2)
loop(doAutoSpot, 2)
loop(doAutoSpin, 2)
loop(applyTitle, 0.05)

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
	while session.running do
		pcall(updateLighting)
		pcall(applyMovement)
		task.wait(0.25)
	end
end)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	pcall(applyMovement)
end)

session.cleanup = function()
	setFly(false)
	setAntiFling(false)
	setFlingWalk(false)
	setLighting(false)
end

end)()

Library:OnUnload(function()
	session.running = false
	if type(session.cleanup) == "function" then
		pcall(session.cleanup)
	end
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	resetTitleColor()
	clearOverhead()
	settings.titleLevel = nil
	settings.titleName = nil
	settings.titleText = nil
	settings.overhead = nil
	lastOverhead = nil
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()