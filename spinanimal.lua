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
	GameName = "Spin Animals",
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

local GetSnapshot = waitRemote("GetSnapshot")
local RequestRoll = waitRemote("RequestRoll")
local RequestBuyEgg = waitRemote("RequestBuyEgg")
local RequestBuyUpgrade = waitRemote("RequestBuyUpgrade")
local RequestRebirth = waitRemote("RequestRebirth")
local RequestEquipBest = waitRemote("RequestEquipBest")

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

local EggsConfig = requireShared("Config.Eggs")
local UpgradesConfig = requireShared("Config.Upgrades")
local EconomyConfig = requireShared("Config.Economy")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(GetSnapshot)
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

local EGG_NAMES = {
	"Wooden",
	"Stone",
	"Copper",
	"Silver",
	"Gold",
	"Amber",
	"Emerald",
	"Amethyst",
	"Sapphire",
	"Ruby",
	"Obsidian",
	"Frost",
	"Rainbow",
	"Toxic",
	"Celestial",
	"Dragon",
}

local EGG_INDEX = {}
for index = 1, #EGG_NAMES do
	EGG_INDEX[EGG_NAMES[index]] = index
end

local function getMoney()
	local data = getPlayerData()
	return tonumber(data and data.money) or tonumber(statValue("Money", "Cash", "Coins")) or 0
end

local function getIncome()
	local data = getPlayerData()
	return tonumber(data and data.incomePerSecond) or tonumber(statValue("Income", "IncomePerSecond")) or 0
end

local function getRolls()
	local data = getPlayerData()
	return tonumber(data and data.rolls) or tonumber(statValue("Rolls")) or 0
end

local function getEggsOwned()
	local data = getPlayerData()
	return tonumber(data and data.eggsOwned) or tonumber(statValue("EggsOwned", "Eggs")) or 0
end

local function getRebirths()
	local data = getPlayerData()
	return tonumber(data and data.rebirths) or tonumber(statValue("Rebirths")) or 0
end

local function getPet()
	local data = getPlayerData()
	local pet = data and (data.equipped or data.equippedPet or data.pet)
	if type(pet) == "table" then
		return tostring(pet.name or pet.kind or pet.id or "none")
	end
	if pet ~= nil then
		return tostring(pet)
	end
	return "none"
end

local function upgradeFields(key)
	local fields = {key}
	local upper = string.upper(key)
	if upper ~= key then
		table.insert(fields, upper)
	end
	table.insert(fields, key .. "Level")
	table.insert(fields, upper .. "Level")
	return fields
end

local function getUpgradeLevel(key)
	local data = getPlayerData()
	local fields = upgradeFields(key)
	local containers = {}
	if type(data) == "table" then
		table.insert(containers, data.upgrades)
		table.insert(containers, data.upgradeLevels)
		table.insert(containers, data.upgradesLevels)
		table.insert(containers, data.stats)
		table.insert(containers, data)
	end
	for _, container in ipairs(containers) do
		if type(container) == "table" then
			for _, field in ipairs(fields) do
				local value = tonumber(container[field])
				if value then
					return value
				end
			end
		end
	end
	for _, field in ipairs(fields) do
		local value = tonumber(statValue(field))
		if value then
			return value
		end
	end
	return 0
end

local function eggName(index)
	return EGG_NAMES[math.clamp(math.floor(tonumber(index) or 1), 1, #EGG_NAMES)]
end

local function nextEggIndex()
	return math.min(getEggsOwned() + 1, #EGG_NAMES)
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function myPlot()
	local plots = Workspace:FindFirstChild("Map")
	if plots then
		plots = plots:FindFirstChild("Plots")
	end
	if not plots then
		return nil
	end
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:GetAttribute("Owner") == LocalPlayer.UserId then
			return plot
		end
	end
	for _, plot in ipairs(plots:GetChildren()) do
		if plot:GetAttribute("UserId") == LocalPlayer.UserId or plot:GetAttribute("OwnerId") == LocalPlayer.UserId then
			return plot
		end
	end
	return nil
end

local function placementRoots(plot)
	local roots = {}
	if not plot then
		return roots
	end
	for _, child in ipairs(plot:GetChildren()) do
		if string.sub(string.lower(child.Name), 1, 8) == "placement" then
			table.insert(roots, child)
		end
	end
	if #roots == 0 then
		table.insert(roots, plot)
	end
	return roots
end

local function collectPads(plot)
	local pads = {}
	for _, root in ipairs(placementRoots(plot)) do
		for _, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant.Name == "CollectMoney" then
				table.insert(pads, descendant)
			end
		end
	end
	table.sort(pads, function(a, b)
		if a.Position.X ~= b.Position.X then
			return a.Position.X < b.Position.X
		end
		return a.Position.Z < b.Position.Z
	end)
	return pads
end

local function pedestalParts(plot)
	local parts = {}
	if not plot then
		return parts
	end
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "_PedPrompt" and descendant.Enabled then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function pedestalClickers(plot)
	local parts = {}
	if not plot then
		return parts
	end
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("ClickDetector") and descendant.Name == "_PedClick" then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function selectedEggs()
	local list = {}
	local selected = Options.EggSelect and Options.EggSelect.Value
	if type(selected) == "table" then
		for name, on in pairs(selected) do
			if on and EGG_INDEX[name] then
				table.insert(list, EGG_INDEX[name])
			end
		end
	end
	if #list == 0 then
		table.insert(list, nextEggIndex())
	end
	table.sort(list)
	return list
end

local UPGRADE_LIST = {
	{Key = "luck", Flag = "upLuck", Text = "Upgrade Luck"},
	{Key = "cash", Flag = "upCash", Text = "Upgrade Cash"},
	{Key = "rollSpeed", Flag = "upRollSpeed", Text = "Upgrade Roll Speed"},
	{Key = "walkSpeed", Flag = "upWalkSpeed", Text = "Upgrade Walk Speed"},
}

local function doAutoCollect()
	if not enabled.collect then
		return
	end
	local root = getRoot()
	local plot = myPlot()
	if not root or not plot then
		return
	end
	if not ready("collect", 1) then
		return
	end
	local pads = collectPads(plot)
	if #pads == 0 then
		return
	end
	local origin = root.CFrame
	for _, pad in ipairs(pads) do
		if not enabled.collect or not root.Parent then
			break
		end
		local spot = topSurface(pad) or pad.Position
		if (root.Position - spot).Magnitude > 6 then
			teleportTo(spot)
			task.wait(0.15)
		end
		if type(firetouchinterest) == "function" then
			pcall(firetouchinterest, pad, root, 0)
			task.wait(0.05)
			pcall(firetouchinterest, pad, root, 1)
		end
		task.wait(0.35)
	end
	pcall(function()
		root.CFrame = origin
	end)
	setFarmStatus("collecting")
	playerDataAt = 0
end

local function doAutoPedestal()
	if not enabled.pedestal then
		return
	end
	local plot = myPlot()
	if not plot then
		return
	end
	if not ready("pedestal", 1) then
		return
	end
	local fired = 0
	if type(fireproximityprompt) == "function" then
		for _, prompt in ipairs(pedestalParts(plot)) do
			if pcall(fireproximityprompt, prompt) then
				fired = fired + 1
			end
		end
	end
	if type(fireclickdetector) == "function" then
		for _, detector in ipairs(pedestalClickers(plot)) do
			if pcall(fireclickdetector, detector) then
				fired = fired + 1
			end
		end
	end
	if fired > 0 then
		setFarmStatus("leveling pedestal")
		playerDataAt = 0
	end
end

local function doAutoRoll()
	if not enabled.roll or not RequestRoll then
		return
	end
	if not ready("roll", 1) then
		return
	end
	setFarmStatus("rolling")
	call(RequestRoll)
	playerDataAt = 0
end

local function doAutoBuyEggs()
	if not enabled.eggs or not RequestBuyEgg then
		return
	end
	for _, index in ipairs(selectedEggs()) do
		if not enabled.eggs then
			break
		end
		setFarmStatus("buying " .. eggName(index))
		fire(RequestBuyEgg, index)
		playerDataAt = 0
		task.wait(0.25)
	end
end

local function doAutoUpgrades()
	if not RequestBuyUpgrade or not ready("upgrades", 1) then
		return
	end
	local bought = 0
	for _, entry in ipairs(UPGRADE_LIST) do
		if not session.running then
			break
		end
		if enabled[entry.Flag] then
			local level = getUpgradeLevel(entry.Key)
			setFarmStatus("upgrading " .. entry.Key)
			fire(RequestBuyUpgrade, entry.Key)
			playerDataAt = 0
			bought = bought + 1
			if getUpgradeLevel(entry.Key) <= level then
				task.wait(0.25)
			end
		end
	end
	if bought == 0 then
		return
	end
end

local function doAutoEquipBest()
	if not enabled.equip or not RequestEquipBest then
		return
	end
	if not ready("equip", 30) then
		return
	end
	setFarmStatus("equipping best")
	fire(RequestEquipBest)
	playerDataAt = 0
end

local function doAutoRebirth()
	if not enabled.rebirth or not RequestRebirth then
		return
	end
	if not ready("rebirth", 3) then
		return
	end
	setFarmStatus("rebirthing")
	fire(RequestRebirth)
	playerDataAt = 0
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

local CollectTab = Tabs.Main:AddSubTab({ Name = "Collect", Icon = "coins" })
local EggsTab = Tabs.Main:AddSubTab({ Name = "Eggs", Icon = "egg" })
local UpgradeTab = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "arrow-up" })

local CollectBox = box(CollectTab, "Income", "coins", "Left")
CollectBox:AddToggle("AutoCollect", { Text = "Auto Collect Cash", Default = false, Callback = function(value)
	enabled.collect = value
end })
CollectBox:AddToggle("AutoPedestal", { Text = "Upgrade Animals", Default = false, Callback = function(value)
	enabled.pedestal = value
end })
CollectBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })

local CollectInfoBox = box(CollectTab, "Game Info", "activity", "Right")
CollectInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
CollectInfoBox:AddLabel("MoneyLabel", { Text = paint("Money -", "0", COLORS.gold), DoesWrap = true })
CollectInfoBox:AddLabel("IncomeLabel", { Text = paint("Income -", "0/s", COLORS.gold), DoesWrap = true })
CollectInfoBox:AddLabel("RollsLabel", { Text = paint("Rolls -", "0", COLORS.accent), DoesWrap = true })
CollectInfoBox:AddLabel("EggsLabel", { Text = paint("Eggs -", "0", COLORS.user), DoesWrap = true })
CollectInfoBox:AddLabel("RebirthsLabel", { Text = paint("Rebirths -", "0", COLORS.gold), DoesWrap = true })

local EggsBox = box(EggsTab, "Eggs & Rolls", "egg", "Left")
EggsBox:AddDropdown("EggSelect", {
	Text = "Buy Eggs",
	Values = EGG_NAMES,
	Default = {},
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
})
EggsBox:AddToggle("AutoBuyEggs", { Text = "Auto Buy Eggs", Default = false, Callback = function(value)
	enabled.eggs = value
end })
EggsBox:AddToggle("AutoRoll", { Text = "Auto Roll", Default = false, Callback = function(value)
	enabled.roll = value
end })
EggsBox:AddToggle("AutoEquipBest", { Text = "Auto Equip Best Pet", Default = false, Callback = function(value)
	enabled.equip = value
end })

local EggsInfoBox = box(EggsTab, "Game Info", "activity", "Right")
EggsInfoBox:AddLabel("EggStatusLabel", { Text = paint("Eggs -", "idle", COLORS.accent), DoesWrap = true })
EggsInfoBox:AddLabel("EggTargetLabel", { Text = paint("Next Egg -", eggName(1), COLORS.user), DoesWrap = true })
EggsInfoBox:AddLabel("EggProgressLabel", { Text = paint("Unlocked -", "0/16", COLORS.gold), DoesWrap = true })
EggsInfoBox:AddLabel("PetLabel", { Text = paint("Pet -", "none", COLORS.user), DoesWrap = true })

local UpgradeBox = box(UpgradeTab, "Upgrade", "arrow-up", "Left")
for index = 1, #UPGRADE_LIST do
	local entry = UPGRADE_LIST[index]
	UpgradeBox:AddToggle(entry.Flag, { Text = entry.Text, Default = false, Callback = function(value)
		enabled[entry.Flag] = value
	end })
end

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
	setLabel("IncomeLabel", paint("Income -", abbreviateNumber(getIncome()) .. "/s", COLORS.gold))
	setLabel("RollsLabel", paint("Rolls -", abbreviateNumber(getRolls()), COLORS.accent))
	local owned = getEggsOwned()
	setLabel("EggsLabel", paint("Eggs -", abbreviateNumber(owned), COLORS.user))
	setLabel("EggStatusLabel", paint("Eggs -", farmStatus, COLORS.accent))
	setLabel("EggTargetLabel", paint("Next Egg -", eggName(nextEggIndex()), COLORS.user))
	setLabel("EggProgressLabel", paint("Unlocked -", string.format("%d/%d", math.min(owned, #EGG_NAMES), #EGG_NAMES), COLORS.gold))
	setLabel("PetLabel", paint("Pet -", getPet(), COLORS.user))
	setLabel("RebirthsLabel", paint("Rebirths -", abbreviateNumber(getRebirths()), COLORS.gold))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	local plot = myPlot()
	if not plot then
		return
	end
	if #collectPads(plot) == 0 then
		setFarmStatus("no collect pads")
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

chain({ doAutoCollect }, 1)
chain({ doAutoPedestal }, 1)
chain({ doAutoUpgrades }, 1)
loop(doAutoRoll, 1)
loop(doAutoBuyEggs, 1)
loop(doAutoEquipBest, 30)
loop(doAutoRebirth, 3)

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

end)()

Library:OnUnload(function()
	session.running = false
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()