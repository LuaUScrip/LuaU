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
	Version = "v1.7",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Zombie Invasion",
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

local RemotesFolder
do
	local ok, folder = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes", 10)
	end)
	RemotesFolder = ok and folder or nil
end

local function waitRemote(name)
	if not RemotesFolder then
		return nil
	end
	local instance = RemotesFolder:FindFirstChild(name) or RemotesFolder:FindFirstChild(name, true)
	if instance then
		return instance
	end
	local ok, waited = pcall(function()
		return RemotesFolder:WaitForChild(name, 10)
	end)
	return ok and waited or nil
end

local RollResultAction = waitRemote("RollResultAction")
local Placement = waitRemote("Placement")
local UpgradeRemote = waitRemote("Upgrade")
local GetProfileRemote = waitRemote("GetProfile")
local WaveControl = waitRemote("WaveControl")
local AntiAfkRemote = waitRemote("AntiAfk")

local SharedFolder = find(ReplicatedStorage, "Shared")
local function requireShared(name)
	if not SharedFolder or type(name) ~= "string" then
		return nil
	end
	local node = SharedFolder
	for part in string.gmatch(name, "[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	if not node then
		return nil
	end
	local ok, result = pcall(require, node)
	return ok and result or nil
end

local ZombiesConfig = requireShared("Config.Zombies")
local StatsModule = requireShared("Game.Stats")
local PetsConfig = requireShared("Config.Pets")
local ProfileModule = requireShared("Game.Profile")
local GraveMapModule = requireShared("Game.GraveMap")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(GetProfileRemote)
	if type(playerDataCache) ~= "table" then
		playerDataCache = nil
	end
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

local function getMoney()
	local data = getPlayerData()
	return tonumber(data and data.money) or tonumber(statValue("Money", "Cash", "Coins")) or 0
end

local function getRolls()
	local data = getPlayerData()
	return tonumber(data and data.rolls) or tonumber(statValue("Rolls")) or 0
end

local function getZombieCount()
	local data = getPlayerData()
	if type(data and data.zombies) == "table" then
		local count = 0
		for _ in pairs(data.zombies) do
			count = count + 1
		end
		return count
	end
	return tonumber(statValue("Zombies")) or 0
end

local function getWave()
	return tonumber(statValue("Wave")) or 0
end

local function getWaveState()
	local value = statValue("WaveState")
	return type(value) == "string" and value or "Idle"
end

local function getGraveRows()
	return tonumber(statValue("GraveRows")) or 13
end

local function getGraveCols()
	return tonumber(statValue("GraveCols")) or 3
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

local function myPlot()
	local name = statValue("Plot")
	if type(name) ~= "string" then
		return nil
	end
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	return plots:FindFirstChild(name)
end

local function rollPart()
	local plot = myPlot()
	if not plot then
		return nil
	end
	local roll = plot:FindFirstChild("Roll")
	if not roll then
		return nil
	end
	return roll:FindFirstChild("Rool")
end

local function rollPrompt()
	local plot = myPlot()
	if not plot then
		return nil
	end
	local rool = rollPart()
	if rool then
		local anchor = rool:FindFirstChild("RollPromptAnchor")
		if anchor then
			local prompt = anchor:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				return prompt
			end
		end
		local direct = rool:FindFirstChildOfClass("ProximityPrompt")
		if direct then
			return direct
		end
	end
	local roll = plot:FindFirstChild("Roll")
	if roll then
		local onRoll = roll:FindFirstChildOfClass("ProximityPrompt")
		if onRoll then
			return onRoll
		end
	end
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and string.find(string.lower(descendant.Name), "roll", 1, true) then
			return descendant
		end
	end
	return nil
end

local function ensureNearRoll()
	local prompt = rollPrompt()
	if not prompt then
		return false
	end
	local part = prompt.Parent
	if not part or not part:IsA("BasePart") then
		return true
	end
	local root = getRoot()
	if not root then
		return false
	end
	local spot = topSurface(part) or part.Position
	for _ = 1, 2 do
		if (root.Position - spot).Magnitude <= 12 then
			return true
		end
		pcall(function()
			root.CFrame = CFrame.new(spot)
		end)
		pcall(function()
			local character = getCharacter()
			if character then
				character:PivotTo(CFrame.new(spot))
			end
		end)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
		end)
		task.wait(0.1)
	end
	return (root.Position - spot).Magnitude <= 14
end

local function rollSync()
	return call(RollResultAction, "Sync")
end

local rollingSince = 0

local function canRoll(sync)
	if type(sync) ~= "table" then
		return true
	end
	if sync.rolling == true or sync.Rolling == true then
		if rollingSince == 0 then
			rollingSince = tick()
		end
		return tick() - rollingSince < 1.5
	end
	rollingSince = 0
	return true
end

local function rollEvent()
	if not RollResultAction or not RollResultAction:IsA("RemoteEvent") then
		return false
	end
	fire(RollResultAction, ROLL_METHODS[1])
	return true
end

local function zombiePower(kind, level, upgrades, weight, profile)
	local ok, stats = pcall(function()
		local petTotals
		if ProfileModule and PetsConfig and type(ProfileModule.equippedPets) == "function" and type(PetsConfig.totals) == "function" then
			pcall(function()
				petTotals = PetsConfig.totals(ProfileModule.equippedPets(profile))
			end)
		end
		return StatsModule.zombie(kind, level or 1, upgrades or {}, weight or 100, petTotals)
	end)
	if ok and type(stats) == "table" then
		local health = tonumber(stats.health) or 0
		local dps = tonumber(stats.dps) or 0.1
		return health * math.max(dps, 0.1)
	end
	local found, zombie = pcall(function()
		return ZombiesConfig and ZombiesConfig.find(kind)
	end)
	if found and zombie then
		return (tonumber(zombie.damage) or 1) * (tonumber(zombie.health) or 1) * (1 + (tonumber(weight) or 100) / 1000)
	end
	return 0
end

local function treeSet()
	local set = {}
	local raw = statValue("GraveTrees")
	if type(raw) == "string" then
		for cell in string.gmatch(raw, "[^,]+") do
			set[cell] = true
		end
	end
	return set
end

local function emptyGraveCell(profile)
	local rows, cols = getGraveRows(), getGraveCols()
	local trees = treeSet()
	local occupied = {}
	if type(profile and profile.zombies) == "table" then
		for _, zombie in pairs(profile.zombies) do
			if type(zombie) == "table" and zombie.cell then
				occupied[tostring(zombie.cell[1]) .. ":" .. tostring(zombie.cell[2])] = true
			end
		end
	end
	for x = 0, cols - 1 do
		for y = 0, rows - 1 do
			local key = x .. ":" .. y
			if not trees[key] and not occupied[key] then
				return x, y
			end
		end
	end
	return nil
end

local function clearablePines()
	local cols, rows = getGraveCols(), getGraveRows()
	local ok, trees = pcall(function()
		return GraveMapModule and GraveMapModule.decodeTrees(statValue("GraveTrees"))
	end)
	if not ok or type(trees) ~= "table" then
		return {}
	end
	local function blocked(x, y)
		return trees[x .. ":" .. y] == true
	end
	local list = {}
	for key in pairs(trees) do
		local xs, ys = string.match(key, "^(%-?%d+):(%-?%d+)$")
		local x, y = tonumber(xs), tonumber(ys)
		if x and y then
			local okClear, can = pcall(function()
				return GraveMapModule.canClear(cols, rows, x, y, blocked)
			end)
			if okClear and can then
				table.insert(list, key)
			end
		end
	end
	table.sort(list)
	return list
end

local function totalPines()
	local count = 0
	pcall(function()
		local trees = GraveMapModule and GraveMapModule.decodeTrees(statValue("GraveTrees"))
		if type(trees) == "table" then
			for _ in pairs(trees) do
				count = count + 1
			end
		end
	end)
	return count
end

local function clearOnePine()
	local list = clearablePines()
	if #list == 0 then
		return false, "No clearable pines"
	end
	local key = list[1]
	local result = call(Placement, "ClearTree", key)
	if result == true then
		return true, key
	end
	return false, "Server refused " .. tostring(key)
end

local function bestLooseZombie(profile)
	if type(profile and profile.zombies) ~= "table" then
		return nil
	end
	local bestId, bestPower, bestKind = nil, -1, nil
	for _, zombie in pairs(profile.zombies) do
		if type(zombie) == "table" and zombie.cell == nil and zombie.kind and zombie.id then
			local power = zombiePower(zombie.kind, zombie.level, profile.upgrades, zombie.weight, profile)
			if power > bestPower then
				bestPower = power
				bestId = zombie.id
				bestKind = zombie.kind
			end
		end
	end
	return bestId, bestPower, bestKind
end

local function bestRarity(kind)
	local ok, zombie = pcall(function()
		return ZombiesConfig and ZombiesConfig.find(kind)
	end)
	if ok and zombie then
		return zombie.rarity or "Common"
	end
	return "Common"
end

local RARITIES = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"}

local ROLL_METHODS = {"Roll", "Start", "RollZombie", "StartRoll", "Begin", "Open"}
local ROLL_INTERVAL = 0.4
local lastRollAt = 0

local UPGRADE_LIST = {
	{Key = "life", Flag = "upLife", Max = 50, Text = "Upgrade Health"},
	{Key = "damage", Flag = "upDamage", Max = 50, Text = "Upgrade Damage"},
	{Key = "money", Flag = "upMoney", Max = 50, Text = "Upgrade Money"},
	{Key = "resurrection", Flag = "upRes", Max = 10, Text = "Upgrade Resurrect"},
	{Key = "graves", Flag = "upGraves", Max = 4, Text = "Upgrade Graves"},
	{Key = "luck", Flag = "upLuck", Max = 10, Text = "Upgrade Luck"},
}

local function doAutoRoll()
	if not enabled.roll then
		return
	end
	if tick() - lastRollAt < ROLL_INTERVAL then
		return
	end
	if not canRoll(rollSync()) then
		return
	end
	local prompt = rollPrompt()
	if prompt and ensureNearRoll() and type(fireproximityprompt) == "function" then
		if pcall(fireproximityprompt, prompt) then
			lastRollAt = tick()
			setFarmStatus("rolling")
			return
		end
	end
	if rollEvent() then
		lastRollAt = tick()
		setFarmStatus("rolling")
	end
end

local function doAutoBuy()
	if not enabled.buy or not RollResultAction then
		return
	end
	local sync = rollSync()
	if type(sync) ~= "table" or type(sync.results) ~= "table" then
		return
	end
	local allowed = nil
	if Options.RarityFilter and type(Options.RarityFilter.Value) == "table" then
		allowed = Options.RarityFilter.Value
	end
	for _, result in ipairs(sync.results) do
		if type(result) == "table" and result.slot and result.kind then
			local want = true
			if allowed then
				want = allowed[bestRarity(result.kind)] == true
			end
			if want then
				setFarmStatus("buying")
				call(RollResultAction, "Buy", result.slot, nil)
				playerDataAt = 0
				task.wait(0.4)
			end
		end
	end
end

local function doAutoPlace()
	if not enabled.place or not Placement then
		return
	end
	local data = getPlayerData()
	local bestId, bestPower = bestLooseZombie(data)
	if not bestId then
		return
	end
	local x, y = emptyGraveCell(data)
	if x == nil then
		return
	end
	setFarmStatus("placing")
	call(Placement, "Place", bestId, x, y)
	playerDataAt = 0
	setFarmStatus("placed " .. abbreviateNumber(bestPower))
end

local function doAutoTrees()
	if not enabled.trees or not Placement then
		return
	end
	if not ready("trees", 2) then
		return
	end
	local ok = clearOnePine()
	if not ok then
		return
	end
	setFarmStatus("clearing pine")
	playerDataAt = 0
end

local function doAutoWave()
	if not enabled.wave or not WaveControl then
		return
	end
	if getWaveState() ~= "Idle" then
		return
	end
	if not ready("wave", 3) then
		return
	end
	setFarmStatus("starting wave")
	fire(WaveControl, "Start")
end

local function doAutoUpgrades()
	if not UpgradeRemote or not ready("upgrades", 1) then
		return
	end
	local data = getPlayerData()
	if type(data and data.upgrades) ~= "table" then
		return
	end
	for _, entry in ipairs(UPGRADE_LIST) do
		if not session.running then
			break
		end
		if enabled[entry.Flag] then
			local level = tonumber(data.upgrades[entry.Key]) or 0
			if level < entry.Max then
				setFarmStatus("upgrading " .. entry.Key)
				local ok, result = pcall(UpgradeRemote.InvokeServer, UpgradeRemote, entry.Key)
				if not ok then
					logError(result)
				end
				playerDataAt = 0
				data = getPlayerData()
				if type(data and data.upgrades) == "table" then
					level = tonumber(data.upgrades[entry.Key]) or 0
				else
					break
				end
				if level < entry.Max then
					task.wait(0.25)
				end
			end
		end
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

local RollTab = Tabs.Main:AddSubTab({ Name = "Roll", Icon = "dices" })
local GraveTab = Tabs.Main:AddSubTab({ Name = "Grave", Icon = "skull" })
local UpgradeTab = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "arrow-up" })

local RollBox = box(RollTab, "Auto Roll", "dices", "Left")
RollBox:AddToggle("AutoRoll", { Text = "Auto Roll Zombie", Default = false, Callback = function(value)
	enabled.roll = value
end })
RollBox:AddToggle("AutoBuy", { Text = "Auto Buy Zombie", Default = false, Callback = function(value)
	enabled.buy = value
end })
RollBox:AddDropdown("RarityFilter", {
	Text = "Buy Rarity Filter",
	Values = RARITIES,
	Default = 1,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
})

local RollInfoBox = box(RollTab, "Game Info", "activity", "Right")
RollInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
RollInfoBox:AddLabel("MoneyLabel", { Text = paint("Money -", "0", COLORS.gold), DoesWrap = true })
RollInfoBox:AddLabel("RollsLabel", { Text = paint("Rolls -", "0", COLORS.gold), DoesWrap = true })
RollInfoBox:AddLabel("ZombiesLabel", { Text = paint("Zombies -", "0", COLORS.user), DoesWrap = true })
RollInfoBox:AddLabel("WaveLabel", { Text = paint("Wave -", "0", COLORS.accent), DoesWrap = true })
RollInfoBox:AddLabel("WaveStateLabel", { Text = paint("Wave State -", "Idle", COLORS.orange), DoesWrap = true })

local GraveBox = box(GraveTab, "Grave", "skull", "Left")
GraveBox:AddToggle("AutoPlace", { Text = "Auto Place Best Zombie", Default = false, Callback = function(value)
	enabled.place = value
end })
GraveBox:AddToggle("AutoTrees", { Text = "Auto Clear Pines", Default = false, Callback = function(value)
	enabled.trees = value
end })

local GraveInfoBox = box(GraveTab, "Grave Space", "activity", "Right")
GraveInfoBox:AddLabel("GraveUsedLabel", { Text = paint("Used -", "0", COLORS.user), DoesWrap = true })
GraveInfoBox:AddLabel("PinesLabel", { Text = paint("Pines -", "0", COLORS.orange), DoesWrap = true })
GraveInfoBox:AddLabel("ClearableLabel", { Text = paint("Clearable -", "0", COLORS.gold), DoesWrap = true })
GraveInfoBox:AddLabel("LooseLabel", { Text = paint("Loose Zombies -", "0", COLORS.user), DoesWrap = true })

local UpgradeBox = box(UpgradeTab, "Upgrade", "arrow-up", "Left")
for index = 1, #UPGRADE_LIST do
	local entry = UPGRADE_LIST[index]
	UpgradeBox:AddToggle(entry.Flag, { Text = entry.Text, Default = false, Callback = function(value)
		enabled[entry.Flag] = value
	end })
end

local WaveBox = box(UpgradeTab, "Wave", "swords", "Left")
WaveBox:AddToggle("AutoWave", { Text = "Auto Start Wave", Default = false, Callback = function(value)
	enabled.wave = value
end })

local UpgradeInfoBox = box(UpgradeTab, "Upgrade Info", "activity", "Right")
UpgradeInfoBox:AddLabel("UpgradeStatusLabel", { Text = paint("Upgrade -", "idle", COLORS.accent), DoesWrap = true })
UpgradeInfoBox:AddLabel("HealthLevelLabel", { Text = paint("Health -", "0/50", COLORS.user), DoesWrap = true })
UpgradeInfoBox:AddLabel("DamageLevelLabel", { Text = paint("Damage -", "0/50", COLORS.user), DoesWrap = true })
UpgradeInfoBox:AddLabel("MoneyLevelLabel", { Text = paint("Money -", "0/50", COLORS.user), DoesWrap = true })
UpgradeInfoBox:AddLabel("ResLevelLabel", { Text = paint("Resurrect -", "0/10", COLORS.accent), DoesWrap = true })
UpgradeInfoBox:AddLabel("GraveLevelLabel", { Text = paint("Graves -", "0/4", COLORS.accent), DoesWrap = true })
UpgradeInfoBox:AddLabel("LuckLevelLabel", { Text = paint("Luck -", "0/10", COLORS.gold), DoesWrap = true })

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
	setLabel("MoneyLabel", paint("Money -", abbreviateNumber(getMoney()), COLORS.gold))
	setLabel("RollsLabel", paint("Rolls -", abbreviateNumber(getRolls()), COLORS.gold))
	setLabel("ZombiesLabel", paint("Zombies -", abbreviateNumber(getZombieCount()), COLORS.user))
	setLabel("WaveLabel", paint("Wave -", getWave(), COLORS.accent))
	setLabel("WaveStateLabel", paint("Wave State -", getWaveState(), COLORS.orange))
	local rows, cols = getGraveRows(), getGraveCols()
	local used = getZombieCount()
	local loose = 0
	local data = getPlayerData()
	if type(data and data.zombies) == "table" then
		for _, zombie in pairs(data.zombies) do
			if type(zombie) == "table" and zombie.cell == nil then
				loose = loose + 1
			end
		end
	end
	setLabel("GraveUsedLabel", paint("Used -", string.format("%d/%d", used - loose, math.max(rows * cols - totalPines(), 0)), COLORS.user))
	setLabel("PinesLabel", paint("Pines -", totalPines(), COLORS.orange))
	setLabel("ClearableLabel", paint("Clearable -", #clearablePines(), COLORS.gold))
	setLabel("LooseLabel", paint("Loose Zombies -", loose, COLORS.user))
	local upgrades = type(data and data.upgrades) == "table" and data.upgrades or {}
	local function levelText(key, max)
		return string.format("%s/%s", tostring(tonumber(upgrades[key]) or 0), tostring(max))
	end
	setLabel("UpgradeStatusLabel", paint("Upgrade -", farmStatus, COLORS.accent))
	setLabel("HealthLevelLabel", paint("Health -", levelText("life", 50), COLORS.user))
	setLabel("DamageLevelLabel", paint("Damage -", levelText("damage", 50), COLORS.user))
	setLabel("MoneyLevelLabel", paint("Money -", levelText("money", 50), COLORS.user))
	setLabel("ResLevelLabel", paint("Resurrect -", levelText("resurrection", 10), COLORS.accent))
	setLabel("GraveLevelLabel", paint("Graves -", levelText("graves", 4), COLORS.accent))
	setLabel("LuckLevelLabel", paint("Luck -", levelText("luck", 10), COLORS.gold))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	pcall(function()
		if GraveMapModule and type(GraveMapModule.decodeTrees) == "function" then
			GraveMapModule.decodeTrees(statValue("GraveTrees"))
		end
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

chain({ doAutoRoll }, ROLL_INTERVAL)
chain({ doAutoPlace }, 1)
chain({ doAutoUpgrades }, 1)
loop(doAutoBuy, 1)
loop(doAutoTrees, 1)
loop(doAutoWave, 1)

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
			pcall(function()
				if AntiAfkRemote then
					AntiAfkRemote:InvokeServer("Reconnect")
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

end)()

Library:OnUnload(function()
	session.running = false
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()