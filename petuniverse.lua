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
	GameName = "Pets Universe",
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

local SafeGet
do
	local ok, module = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules", 10):WaitForChild("SafeGetService", 10))
	end)
	SafeGet = ok and module or nil
end

local serviceCache = {}

local function GetSvc(name)
	local cached = serviceCache[name]
	if cached ~= nil then
		return cached
	end
	if not SafeGet or not SafeGet.Get then
		return nil
	end
	local ok, svc = pcall(SafeGet.Get, name)
	local result = ok and svc or nil
	serviceCache[name] = result
	return result
end

local SharedFolder = find(ReplicatedStorage, "Modules")
local function requireShared(name)
	local module = SharedFolder and SharedFolder:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local PlayerData = requireShared("PlayerData")
local PetDisplay = requireShared("PetDisplay")
local PartyEggModule = requireShared("PartyEggModule")
local UpgradeTreeModule
do
	local ok, mod = pcall(function()
		return require(find(ReplicatedStorage, "UpgradeTree", "UpgradeTreeData"))
	end)
	UpgradeTreeModule = ok and mod or nil
end

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	local ok, folder = pcall(function()
		return PlayerData and PlayerData.Folder and PlayerData.Folder(LocalPlayer, "Stats")
	end)
	playerDataCache = ok and folder or nil
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

local function statValue(name)
	local stats = getPlayerData()
	local value = stats and stats:FindFirstChild(name)
	return value and tonumber(value.Value) or 0
end

local function getCoins()
	return statValue("Coins")
end

local function getRubies()
	return statValue("Rubies")
end

local function getGems()
	return statValue("Gems")
end

local EGG_LIST = {"Basic Egg", "Sprout Egg", "Grassy Egg", "Dried Egg", "Frost Egg", "Zombie Egg", "Castle Egg", "Universe Egg"}
local MODE_LIST = {"Single", "Half", "Max"}
local WORLD_LIST = {"Spawn", "BirchForest", "TreasureDunes", "FrozenAlley", "HauntedHouse", "PetKingdom", "TheMoon"}
local UPGRADE_LIST = {"CoinsUpgrades", "RubiesUpgrades", "LuckUpgrades", "HatchSpeedUpgrades", "CriticalUpgrades", "PetSpeedUpgrades"}
local MOON_INC_LIST = {"Damage", "MoreGems", "TapPower", "PetAttackSpeed", "CritDmg", "ChestTier", "AstralBeeChance", "AstralBeeVariant"}
local MOON_PERM_LIST = {"CoinMultiplier", "RubiesMultiplier", "GemsMultiplier", "LuckMultiplier", "HatchSpeedMultiplier", "CritChance", "EggHatch", "PetEquip"}
local ITEM_LIST = {
	"Apple", "Banana", "Blueberry", "Kiwi", "Mango", "Taco",
	"CoinsPotion", "CoinsPotion2", "RubiesPotion", "RubiesPotion2", "LuckPotion", "LuckPotion2",
	"HatchSpeedPotion", "HatchSpeedPotion2", "CriticalPotion", "CriticalPotion2",
	"Ball", "Bone", "Cookie", "Squeaky",
}
local ITEM_FOLDERS = {"FruitsData", "PotionsData", "ToysData", "MiscData"}

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

local function itemOwned(name)
	for _, folderName in ipairs(ITEM_FOLDERS) do
		local folder = PlayerData and PlayerData.Folder and PlayerData.Folder(LocalPlayer, folderName)
		local value = folder and folder:FindFirstChild(name)
		if value then
			local ok, amount = pcall(function()
				return tonumber(value.Value)
			end)
			if ok and amount then
				return amount
			end
			return 1
		end
	end
	return 1
end

local function selectedItemNames()
	local selected = Options.SelectedItems and Options.SelectedItems.Value
	local names = {}
	if type(selected) == "string" then
		names[1] = selected
	elseif type(selected) == "table" then
		for key, active in pairs(selected) do
			if type(key) == "string" and active then
				table.insert(names, key)
			elseif type(key) == "number" and type(active) == "string" then
				table.insert(names, active)
			end
		end
	end
	return names
end

local function setBuiltInAuto(state)
	local service = GetSvc("BreakableAreaService")
	if service and service.SetAutoBreaking then
		pcall(function()
			service.SetAutoBreaking:Fire(state)
		end)
	end
end

local breakablesFolder, breakablesWaited = nil, false

local function getBreakablesFolder()
	local folder = Workspace:FindFirstChild("Breakables")
	if folder then
		breakablesFolder = folder
		return folder
	end
	if not breakablesWaited then
		breakablesWaited = true
		local ok, waited = pcall(function()
			return Workspace:WaitForChild("Breakables", 10)
		end)
		breakablesFolder = ok and waited or nil
	end
	return breakablesFolder
end

local function tierNameFor(detector, folder)
	local node = detector.Parent
	local depth = 0
	while node and node ~= folder and depth < 6 do
		local name = node.Name
		if string.match(name, "^RTier") or string.match(name, "^Tier") then
			return name
		end
		node = node.Parent
		depth += 1
	end
	return nil
end

local function selectionAccepts(selection, tierName)
	if not selection or selection == "Nearest" then
		return true
	end
	if selection == "Gems" then
		return string.match(tierName or "", "^RTier") ~= nil
	end
	if selection == "Coins" then
		return string.match(tierName or "", "^Tier") ~= nil
	end
	return true
end

local function nearestBreakable(selection)
	local folder = getBreakablesFolder()
	local root = getRoot()
	if not folder or not root then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, instance in ipairs(folder:GetDescendants()) do
		if instance:IsA("ClickDetector") and instance.Parent and instance.Parent:IsA("Model") then
			if selection == "Nearest" or selectionAccepts(selection, tierNameFor(instance, folder)) then
				local part = instance.Parent.PrimaryPart or instance.Parent:FindFirstChildWhichIsA("BasePart", true)
				if part then
					local distance = (part.Position - root.Position).Magnitude
					if distance < bestDistance then
						best, bestDistance = instance, distance
					end
				end
			end
		end
	end
	return best
end

local function doAutoBreak()
	if not enabled.breaking then
		return
	end
	local selection = Options.BreakTarget and Options.BreakTarget.Value or "Nearest"
	setFarmStatus("breaking " .. string.lower(tostring(selection)))
	if ready("builtin", 1) then
		setBuiltInAuto(true)
	end
	local detector = nearestBreakable(selection)
	if detector then
		pcall(fireclickdetector, detector)
	end
end

local function doAutoPlaytime()
	if not enabled.playtime then
		return
	end
	local service = GetSvc("PlaytimeGiftsService")
	if not service or not service.ClaimGift then
		return
	end
	setFarmStatus("claiming gifts")
	for index = 1, 9 do
		pcall(function()
			service.ClaimGift:Fire("Gift" .. index)
		end)
	end
end

local function doAutoPartyEgg()
	if not enabled.partyEgg then
		return
	end
	local isReady = true
	if PartyEggModule and PartyEggModule.IsReady then
		local ok, result = pcall(PartyEggModule.IsReady, LocalPlayer)
		isReady = ok and result == true
	end
	if not isReady then
		return
	end
	local service = GetSvc("PartyEggService")
	if service and service.Claim then
		setFarmStatus("claiming playtime egg")
		pcall(function()
			service.Claim:Fire()
		end)
	end
end

local function doAutoHatch()
	if not enabled.hatch then
		return
	end
	local service = GetSvc("EggHatchService")
	if not service or not service.Hatch then
		return
	end
	local egg = Options.SelectedEgg and Options.SelectedEgg.Value or "Basic Egg"
	local mode = Options.HatchMode and Options.HatchMode.Value or "Max"
	setFarmStatus("hatching " .. tostring(egg))
	pcall(function()
		service.Hatch:Fire(egg, mode)
	end)
end

local function equipBestNow()
	local service = GetSvc("PetsService")
	if service and service.Action then
		setFarmStatus("equipping best pets")
		pcall(function()
			service.Action:Fire("EquipBest")
		end)
	end
end

local function doAutoEquipBest()
	if not enabled.equip then
		return
	end
	if not ready("equip", 10) then
		return
	end
	equipBestNow()
end

local function craftPets(dataFolder, need, machineName, bulkKey, singleKey)
	local service = GetSvc("CraftMachinesService")
	if not service then
		return
	end
	local folder = PlayerData and PlayerData.Folder and PlayerData.Folder(LocalPlayer, "PetsData")
	local sub = folder and folder:FindFirstChild(dataFolder)
	if not sub then
		return
	end
	local readyList = {}
	for _, pet in ipairs(sub:GetChildren()) do
		if PetDisplay and PetDisplay.GetAvailable and PetDisplay.GetAvailable(LocalPlayer, pet.Name) >= need then
			table.insert(readyList, pet.Name)
		end
	end
	if #readyList == 0 then
		return
	end
	local root = getRoot()
	local machine = find(Workspace, "Map", "Machines", machineName)
	local part = machine and (machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart", true))
	if not root or not part then
		return
	end
	setFarmStatus("crafting")
	local back = root.CFrame
	local moved = (part.Position - root.Position).Magnitude > 20
	if moved then
		root.CFrame = part.CFrame + Vector3.new(0, 3, 6)
		pcall(function()
			root.Velocity = Vector3.zero
			root.RotVelocity = Vector3.zero
		end)
		task.wait(1)
	end
	readyList = {}
	for _, pet in ipairs(sub:GetChildren()) do
		if PetDisplay and PetDisplay.GetAvailable and PetDisplay.GetAvailable(LocalPlayer, pet.Name) >= need then
			table.insert(readyList, pet.Name)
		end
	end
	if #readyList > 0 then
		table.sort(readyList)
		if service[bulkKey] then
			pcall(function()
				service[bulkKey]:Fire(readyList)
			end)
		elseif service[singleKey] then
			for _, name in ipairs(readyList) do
				pcall(function()
					service[singleKey]:Fire(name)
				end)
			end
		end
		task.wait(1.5)
	end
	if moved then
		local character = getCharacter()
		local current = character and character:FindFirstChild("HumanoidRootPart")
		if current then
			current.CFrame = back
		end
	end
end

local function craftGoldensOnce()
	craftPets("NormalPetsData", 8, "GoldenMachine", "CraftBulkGolden", "CraftGolden")
end

local function craftDiamondsOnce()
	craftPets("GoldenPetsData", 6, "DiamondMachine", "CraftBulkDiamond", "CraftDiamond")
end

local function doAutoGolden()
	if not enabled.golden then
		return
	end
	craftGoldensOnce()
end

local function doAutoDiamond()
	if not enabled.diamond then
		return
	end
	craftDiamondsOnce()
end

local function doAutoUpgrades()
	if not enabled.upgrades then
		return
	end
	local service = GetSvc("UpgradesService")
	if not service or not service.BuyUpgrade then
		return
	end
	setFarmStatus("buying upgrades")
	for _, name in ipairs(UPGRADE_LIST) do
		pcall(function()
			service.BuyUpgrade:Fire(name)
		end)
	end
end

local function doAutoWorlds()
	if not enabled.worlds then
		return
	end
	local service = GetSvc("TeleportService")
	if not service or not service.Purchase then
		return
	end
	setFarmStatus("buying worlds")
	pcall(function()
		service.Purchase:Fire("Bought")
		service.Purchase:Fire("BoughtMoon")
	end)
end

local function teleportToWorld()
	local service = GetSvc("TeleportService")
	if not service or not service.GoTo then
		return
	end
	local world = Options.TeleportWorld and Options.TeleportWorld.Value or "Spawn"
	setFarmStatus("teleporting to " .. tostring(world))
	pcall(function()
		service.GoTo:Fire(world)
	end)
end

local function useItemsNow()
	local names = selectedItemNames()
	local service = GetSvc("ConsumablesService")
	if not service or not service.UseItem or #names == 0 then
		return
	end
	for _, name in ipairs(names) do
		if itemOwned(name) > 0 then
			setFarmStatus("using " .. tostring(name))
			pcall(function()
				service.UseItem:Fire(name, 1)
			end)
		end
	end
end

local function doAutoItems()
	if not enabled.items then
		return
	end
	if not ready("items", 60) then
		return
	end
	useItemsNow()
end

local function moonPass(serviceName, keyList)
	local service = GetSvc(serviceName)
	if not service or not service.BuyUpgrade then
		return
	end
	for _, key in ipairs(keyList) do
		pcall(function()
			service.BuyUpgrade:Fire(key)
		end)
	end
end

local function doAutoMoonInc()
	if not enabled.moonInc then
		return
	end
	setFarmStatus("buying moon upgrades")
	moonPass("MoonUpgradesService", MOON_INC_LIST)
end

local function doAutoMoonPerm()
	if not enabled.moonPerm then
		return
	end
	setFarmStatus("buying permanent moon upgrades")
	moonPass("MoonPermUpgradesService", MOON_PERM_LIST)
end

local function buyTreePass()
	local service = GetSvc("UpgradeTreeService")
	if not service or not service.BuyNode or type(UpgradeTreeModule) ~= "table" then
		return
	end
	local nums = {}
	for key in pairs(UpgradeTreeModule) do
		if type(key) == "number" then
			table.insert(nums, key)
		end
	end
	table.sort(nums)
	local tree = PlayerData and PlayerData.Folder and PlayerData.Folder(LocalPlayer, "TreeData")
	local balance = getRubies()
	local bought = 0
	for _, key in ipairs(nums) do
		if bought >= 5 then
			break
		end
		local entry = UpgradeTreeModule[key]
		if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "start" then
			local owned = tree and tree:FindFirstChild(entry.id)
			if not (owned and owned.Value) then
				local parentOk = not entry.parent or (tree and tree:FindFirstChild(entry.parent) and tree:FindFirstChild(entry.parent).Value)
				local cost = tonumber(entry.cost) or 0
				if parentOk and cost <= balance then
					pcall(function()
						service.BuyNode:Fire(entry.id)
					end)
					bought += 1
					balance -= cost
				end
			end
		end
	end
	if bought > 0 then
		setFarmStatus("skill tree +" .. bought)
	end
end

local function doAutoSkillTree()
	if not enabled.skilltree then
		return
	end
	buyTreePass()
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
			settings().Rendering.QualityLevel = 1
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

local FarmingTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" })
local PetsTab = Tabs.Main:AddSubTab({ Name = "Pets", Icon = "sparkles" })
local ShopTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" })

local FarmBox = box(FarmingTab, "Farming", "star", "Left")
FarmBox:AddDropdown("BreakTarget", { Text = "Select Target", Values = { "Gems", "Coins", "Nearest" }, Default = 3 })
FarmBox:AddToggle("AutoBreak", { Text = "Auto Break Selected", Default = false, Callback = function(value)
	enabled.breaking = value
	if not value then
		setBuiltInAuto(false)
	end
end })
FarmBox:AddToggle("AutoPlaytime", { Text = "Auto Claim Playtime Rewards", Default = false, Callback = function(value)
	enabled.playtime = value
end })
FarmBox:AddToggle("AutoPartyEgg", { Text = "Auto Claim Playtime Egg", Default = false, Callback = function(value)
	enabled.partyEgg = value
end })

local StatusBox = box(FarmingTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("CoinsLabel", { Text = paint("Coins -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("RubiesLabel", { Text = paint("Rubies -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("GemsLabel", { Text = paint("Gems -", "0", COLORS.user), DoesWrap = true })

local HatchBox = box(PetsTab, "Hatching", "egg", "Left")
HatchBox:AddDropdown("SelectedEgg", { Text = "Egg", Values = EGG_LIST, Default = 1 })
HatchBox:AddDropdown("HatchMode", { Text = "Mode", Values = MODE_LIST, Default = 3 })
HatchBox:AddToggle("AutoHatch", { Text = "Auto Hatch Eggs", Default = false, Callback = function(value)
	enabled.hatch = value
end })

local PetsBox = box(PetsTab, "Pets", "paw-print", "Right")
PetsBox:AddToggle("AutoEquipBest", { Text = "Auto Equip Best Pets", Default = false, Callback = function(value)
	enabled.equip = value
end })
PetsBox:AddToggle("AutoGolden", { Text = "Auto Golden Pets", Default = false, Callback = function(value)
	enabled.golden = value
end })
PetsBox:AddToggle("AutoDiamond", { Text = "Auto Diamond Pets", Default = false, Callback = function(value)
	enabled.diamond = value
end })
PetsBox:AddDivider()
PetsBox:AddButton({ Text = "Equip Best Now", Func = equipBestNow })
PetsBox:AddButton({ Text = "Craft Goldens Now", Func = craftGoldensOnce })
PetsBox:AddButton({ Text = "Craft Diamonds Now", Func = craftDiamondsOnce })

local UpgradeBox = box(ShopTab, "Auto Upgrade", "gauge", "Left")
UpgradeBox:AddToggle("AutoUpgrades", { Text = "Auto Buy Upgrades", Default = false, Callback = function(value)
	enabled.upgrades = value
end })

local WorldsBox = box(ShopTab, "Worlds", "globe", "Left")
WorldsBox:AddToggle("AutoBuyWorlds", { Text = "Auto Buy Worlds", Default = false, Callback = function(value)
	enabled.worlds = value
end })
WorldsBox:AddDropdown("TeleportWorld", { Text = "Teleport To", Values = WORLD_LIST, Default = 1 })
WorldsBox:AddButton({ Text = "Teleport", Func = teleportToWorld })

local ItemsBox = box(ShopTab, "Auto Use Items", "shopping-bag", "Right")
ItemsBox:AddDropdown("SelectedItems", { Text = "Items", Values = ITEM_LIST, Default = 1, Multi = true, Searchable = true, SelectAllButtons = true })
ItemsBox:AddToggle("AutoUseItems", { Text = "Auto Use Selected Items", Default = false, Callback = function(value)
	enabled.items = value
	if value then
		timers.items = 0
		task.spawn(useItemsNow)
	end
end })
ItemsBox:AddDivider()
ItemsBox:AddButton({ Text = "Use Now", Func = useItemsNow })

local MoonBox = box(ShopTab, "Moon & Tree", "moon", "Right")
MoonBox:AddToggle("AutoMoonInc", { Text = "Auto Moon Upgrades", Default = false, Callback = function(value)
	enabled.moonInc = value
end })
MoonBox:AddToggle("AutoMoonPerm", { Text = "Auto Permanent Moon Upgrades", Default = false, Callback = function(value)
	enabled.moonPerm = value
end })
MoonBox:AddToggle("AutoSkillTree", { Text = "Auto Upgrade Skill Tree", Default = false, Callback = function(value)
	enabled.skilltree = value
end })
MoonBox:AddDivider()
MoonBox:AddButton({ Text = "Buy Affordable Nodes", Func = buyTreePass })

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
	setLabel("CoinsLabel", paint("Coins -", abbreviateNumber(getCoins()), COLORS.gold))
	setLabel("RubiesLabel", paint("Rubies -", abbreviateNumber(getRubies()), COLORS.orange))
	setLabel("GemsLabel", paint("Gems -", abbreviateNumber(getGems()), COLORS.user))
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

chain({ doAutoBreak }, 0.1)
chain({ doAutoHatch }, 0.2)
chain({ doAutoPlaytime, doAutoPartyEgg }, 1)
loop(doAutoEquipBest, 5)
loop(doAutoUpgrades, 0.2)
loop(doAutoWorlds, 1)
loop(doAutoGolden, 1)
loop(doAutoDiamond, 1)
loop(doAutoItems, 0.2)
loop(doAutoMoonInc, 1)
loop(doAutoMoonPerm, 1)
loop(doAutoSkillTree, 1)

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
		if enabled.antiafk then
			local service = GetSvc("AutoRejoinService")
			if service and service.ReportActivity then
				pcall(function()
					service.ReportActivity:Fire()
				end)
			end
		end
		task.wait(20)
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
	setBuiltInAuto(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()