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
	GameName = "Kitten Farm",
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

local function remoteAt(path)
	if not RemotesFolder or type(path) ~= "string" then
		return nil
	end
	local node = RemotesFolder
	for part in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	return node
end

local function waitRemote(path)
	local node = remoteAt(path)
	if node then
		return node
	end
	if not RemotesFolder then
		return nil
	end
	local wanted = string.match(path, "([^%.]+)$")
	local ok, waited = pcall(function()
		return RemotesFolder:WaitForChild(wanted, 10)
	end)
	return ok and waited or nil
end

local YarnCollect = waitRemote("Yarn.Collect")
local Prestige = waitRemote("Prestige")

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

local KittensConfig = requireShared("Config.Kittens")
local UpgradesConfig = requireShared("Config.Upgrades")
local PrestigeConfig = requireShared("Config.Prestige")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(Prestige, "GetData")
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
		if value == nil then
			local direct = LocalPlayer:FindFirstChild(key)
			if direct then
				value = direct.Value or direct:GetAttribute("Value")
			end
		end
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function myPlot()
	local plots = Workspace:FindFirstChild("Plots")
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

local function getMoney()
	local data = getPlayerData()
	return tonumber(data and data.money) or tonumber(statValue("Money", "Cash", "Coins")) or 0
end

local function getYarn()
	local data = getPlayerData()
	return tonumber(data and data.yarn) or tonumber(statValue("Yarn")) or 0
end

local function getRebirthPrice()
	local data = getPlayerData()
	return tonumber(data and data.Price) or 0
end

local function getRebirthMaxed()
	local data = getPlayerData()
	return data and data.Maxed and true or false
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function plotPress(plot, name)
	local buttons = plot and plot:FindFirstChild("Buttons")
	local button = buttons and buttons:FindFirstChild(name)
	return button and button:FindFirstChild("Press")
end

local function pressButton(plot, name)
	local press = plotPress(plot, name)
	local root = getRoot()
	if not press or not root then
		return false
	end
	if type(firetouchinterest) == "function" then
		pcall(firetouchinterest, root, press, 0)
		task.wait(0.08)
		pcall(firetouchinterest, root, press, 1)
	end
	return true
end

local function yarnPieces()
	local folder = Workspace:FindFirstChild("Yarn")
	local list = {}
	if not folder then
		return list
	end
	for _, piece in ipairs(folder:GetChildren()) do
		table.insert(list, piece)
	end
	return list
end

local BUY_TIERS = {
	{Key = "buy1", Flag = "buy1", Button = "Buy1", Text = "Buy 1 Kitten"},
	{Key = "buy5", Flag = "buy5", Button = "Buy5", Text = "Buy 5 Kittens"},
	{Key = "buy25", Flag = "buy25", Button = "Buy25", Text = "Buy 25 Kittens"},
	{Key = "buy100", Flag = "buy100", Button = "Buy100", Text = "Buy 100 Kittens"},
}

local UPGRADE_BUTTONS = {
	{Key = "yarnRate", Flag = "upgradeYarnRate", Button = "UpgradeYarnRate", Text = "Upgrade Yarn Rate"},
	{Key = "buyTier", Flag = "upgradeBuyTier", Button = "UpgradeBuyTier", Text = "Upgrade Buy Tier"},
}

local function doAutoCollectYarn()
	if not enabled.collectYarn or not YarnCollect then
		return
	end
	if not ready("collectYarn", 1) then
		return
	end
	local pieces = yarnPieces()
	if #pieces == 0 then
		return
	end
	for index = 1, #pieces do
		if not enabled.collectYarn then
			break
		end
		setFarmStatus("collecting yarn")
		fire(YarnCollect, pieces[index].Name)
		playerDataAt = 0
		task.wait(0.1)
	end
end

local function doAutoCollectMoney()
	if not enabled.collectMoney then
		return
	end
	if not ready("collectMoney", 1) then
		return
	end
	local plot = myPlot()
	if not plot then
		return
	end
	if pressButton(plot, "CollectCash") then
		setFarmStatus("collecting cash")
		playerDataAt = 0
	end
end

local function doAutoDepositYarn()
	if not enabled.deposit then
		return
	end
	if not ready("deposit", 1) then
		return
	end
	local plot = myPlot()
	if not plot then
		return
	end
	if getYarn() <= 0 then
		return
	end
	if pressButton(plot, "DepositYarn") then
		setFarmStatus("depositing yarn")
		playerDataAt = 0
	end
end

local function doAutoBuyKittens()
	local plot = myPlot()
	if not plot then
		return
	end
	local bought = 0
	for index = 1, #BUY_TIERS do
		if not session.running then
			break
		end
		local entry = BUY_TIERS[index]
		if enabled[entry.Flag] then
			setFarmStatus("buying x" .. entry.Key:match("%d+"))
			if pressButton(plot, entry.Button) then
				playerDataAt = 0
				bought = bought + 1
			end
			task.wait(0.3)
		end
	end
	if bought == 0 then
		return
	end
end

local function doAutoUpgrades()
	local plot = myPlot()
	if not plot then
		return
	end
	local touched = 0
	for index = 1, #UPGRADE_BUTTONS do
		if not session.running then
			break
		end
		local entry = UPGRADE_BUTTONS[index]
		if enabled[entry.Flag] then
			setFarmStatus("upgrading " .. entry.Key)
			if pressButton(plot, entry.Button) then
				playerDataAt = 0
				touched = touched + 1
			end
			task.wait(0.3)
		end
	end
	if touched == 0 then
		return
	end
end

local function doAutoMerge()
	if not enabled.merge then
		return
	end
	if not ready("merge", 1) then
		return
	end
	local plot = myPlot()
	if not plot then
		return
	end
	if pressButton(plot, "Button") then
		setFarmStatus("merging kittens")
		playerDataAt = 0
	end
end

local function doAutoRebirth()
	if not enabled.rebirth or not Prestige then
		return
	end
	if not ready("rebirth", 3) then
		return
	end
	playerDataAt = 0
	if getRebirthMaxed() then
		return
	end
	local price = getRebirthPrice()
	if price <= 0 or getMoney() < price then
		return
	end
	setFarmStatus("rebirthing")
	call(Prestige, "Prestige")
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

local CollectTab = Tabs.Main:AddSubTab({ Name = "Collect", Icon = "hand" })
local BuyTab = Tabs.Main:AddSubTab({ Name = "Buy", Icon = "shopping-cart" })
local UpgradeTab = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "arrow-up" })
local RebirthTab = Tabs.Main:AddSubTab({ Name = "Rebirth", Icon = "refresh-cw" })

local CollectBox = box(CollectTab, "Resource", "hand", "Left")
CollectBox:AddToggle("AutoCollectYarn", { Text = "Collect Yarn", Default = false, Callback = function(value)
	enabled.collectYarn = value
end })
CollectBox:AddToggle("AutoCollectMoney", { Text = "Collect Cash", Default = false, Callback = function(value)
	enabled.collectMoney = value
end })
CollectBox:AddToggle("AutoDepositYarn", { Text = "Deposit Yarn", Default = false, Callback = function(value)
	enabled.deposit = value
end })
CollectBox:AddToggle("AutoMerge", { Text = "Auto Merge", Default = false, Callback = function(value)
	enabled.merge = value
end })

local CollectInfoBox = box(CollectTab, "Game Info", "activity", "Right")
CollectInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
CollectInfoBox:AddLabel("MoneyLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
CollectInfoBox:AddLabel("YarnLabel", { Text = paint("Yarn -", "0", COLORS.user), DoesWrap = true })

local BuyBox = box(BuyTab, "Kitten Purchasing", "shopping-cart", "Left")
for index = 1, #BUY_TIERS do
	local entry = BUY_TIERS[index]
	BuyBox:AddToggle(entry.Flag, { Text = entry.Text, Default = false, Callback = function(value)
		enabled[entry.Flag] = value
	end })
end

local UpgradeBox = box(UpgradeTab, "Upgrade", "arrow-up", "Left")
for index = 1, #UPGRADE_BUTTONS do
	local entry = UPGRADE_BUTTONS[index]
	UpgradeBox:AddToggle(entry.Flag, { Text = entry.Text, Default = false, Callback = function(value)
		enabled[entry.Flag] = value
	end })
end

local RebirthBox = box(RebirthTab, "Rebirth", "refresh-cw", "Left")
RebirthBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })

local RebirthInfoBox = box(RebirthTab, "Game Info", "activity", "Right")
RebirthInfoBox:AddLabel("RebirthStatusLabel", { Text = paint("Rebirth -", "idle", COLORS.accent), DoesWrap = true })
RebirthInfoBox:AddLabel("RebirthPriceLabel", { Text = paint("Price -", "0", COLORS.gold), DoesWrap = true })
RebirthInfoBox:AddLabel("RebirthMaxedLabel", { Text = paint("Maxed -", "false", COLORS.orange), DoesWrap = true })

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
	local money = getMoney()
	local yarn = getYarn()
	setLabel("MoneyLabel", paint("Cash -", abbreviateNumber(money), COLORS.gold))
	setLabel("YarnLabel", paint("Yarn -", abbreviateNumber(yarn), COLORS.user))
	setLabel("RebirthStatusLabel", paint("Rebirth -", farmStatus, COLORS.accent))
	setLabel("RebirthPriceLabel", paint("Price -", abbreviateNumber(getRebirthPrice()), COLORS.gold))
	setLabel("RebirthMaxedLabel", paint("Maxed -", tostring(getRebirthMaxed()), COLORS.orange))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	if not myPlot() then
		setFarmStatus("no plot")
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

chain({ doAutoCollectYarn }, 1)
chain({ doAutoCollectMoney }, 1)
chain({ doAutoDepositYarn }, 1)
chain({ doAutoBuyKittens }, 1)
chain({ doAutoUpgrades }, 1)
chain({ doAutoMerge }, 1)
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