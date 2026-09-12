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
	GameName = "Fill Water Escape",
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

local GainPower = waitRemote("GainPower")
local RebirthEvent = waitRemote("RebirthEvent")
local SpeedUpgrade = waitRemote("SpeedUpgrade")
local BuyAura = waitRemote("BuyAura")
local EquipAura = waitRemote("EquipAura")
local BucketShop = waitRemote("BucketShop")
local GetPlayerData = waitRemote("GetPlayerData")

local SharedFolder = find(ReplicatedStorage, "Shared")
local function requireShared(name)
	local module = SharedFolder and SharedFolder:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local Stages = requireShared("Stages")
local TrainingZones = requireShared("TrainingZones")
local Buckets = requireShared("Buckets")
local Auras = requireShared("Auras")
local SpeedCost = requireShared("SpeedCost")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(GetPlayerData)
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

local function getWins()
	return tonumber(LocalPlayer:GetAttribute("Wins")) or 0
end

local function getLevel()
	return tonumber(LocalPlayer:GetAttribute("Level")) or 1
end

local function getRebirth()
	return tonumber(LocalPlayer:GetAttribute("Rebirth")) or 0
end

local function getSpeed()
	local base = SpeedCost and SpeedCost.BaseSpeed or 18
	return tonumber(LocalPlayer:GetAttribute("Speed")) or base
end

local function getWaterPower()
	local value = tonumber(LocalPlayer:GetAttribute("WaterPower"))
	if value and value > 0 then
		return value
	end
	local data = getPlayerData()
	local fromData = data and tonumber(data.WaterPower)
	if fromData and fromData > 0 then
		return fromData
	end
	return 0
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

local function stageReward(winsHitbox, stageName, index)
	local title = winsHitbox:FindFirstChild("Title")
	local gui = title and title:FindFirstChild("BillboardGui")
	local amount = gui and gui:FindFirstChild("Amount")
	local text = amount and amount.Text
	if type(text) == "string" then
		text = text:gsub("<.->", ""):gsub(",", "")
		local parsed = parseAmount(text)
		if parsed then
			return parsed
		end
	end
	local config = Stages and Stages[stageName]
	if config and tonumber(config.Wins) then
		return tonumber(config.Wins)
	end
	return index
end

local function estimateFillTime(capacity, power)
	if not capacity or capacity <= 0 then
		return math.huge
	end
	return math.ceil(capacity / math.max(power or 1, 1)) * (1 / 30)
end

local function scanStages()
	local list = {}
	local gameRoot = find(Workspace, "Game")
	if not gameRoot then
		return list
	end
	for _, stage in ipairs(gameRoot:GetChildren()) do
		local index = string.match(stage.Name, "^Stage(%d+)$")
		index = index and tonumber(index)
		local hitboxes = stage and stage:FindFirstChild("Hitboxes")
		local fillPart = hitboxes and hitboxes:FindFirstChild("Hitbox")
		local winsHitbox = hitboxes and hitboxes:FindFirstChild("WinsHitbox")
		if index and winsHitbox then
			local config = Stages and Stages[stage.Name]
			local capacity = tonumber(fillPart and fillPart:GetAttribute("Capacity")) or (config and config.FillLimit) or 100
			list[#list + 1] = {
				name = stage.Name,
				fillPart = fillPart,
				winsHitbox = winsHitbox,
				capacity = capacity,
				reward = stageReward(winsHitbox, stage.Name, index),
			}
		end
	end
	return list
end

local ZoneClass
do
	local zoneModule = find(ReplicatedStorage, "Modules", "Zone")
	if zoneModule then
		local ok, result = pcall(require, zoneModule)
		if ok and type(result) == "table" and type(result.new) == "function" then
			ZoneClass = result
		end
	end
end

local zoneCache = {}

local function zoneFor(container)
	local cached = zoneCache[container]
	if cached ~= nil then
		return cached or nil
	end
	local built = false
	if ZoneClass then
		local ok, result = pcall(ZoneClass.new, container)
		if ok and result then
			built = result
		end
	end
	zoneCache[container] = built
	return built or nil
end

local function trainingZones()
	local CollectionService = game:GetService("CollectionService")
	local ok, tagged = pcall(CollectionService.GetTagged, CollectionService, "TrainingZone")
	if ok and #tagged > 0 then
		return tagged
	end
	local folder = find(Workspace, "TrainingZones")
	return folder and folder:GetChildren() or {}
end

local function zoneUnlocked(config)
	if not config then
		return true
	end
	if config.Pass then
		return LocalPlayer:GetAttribute("Pass_" .. config.Pass:gsub("%s", "")) == true
	end
	if config.Rebirth then
		return config.Rebirth <= getRebirth()
	end
	return config.Robux == nil
end

local function bestTrainingZone()
	local best, bestMultiplier
	for _, container in ipairs(trainingZones()) do
		local config = TrainingZones and TrainingZones[container.Name]
		if zoneUnlocked(config) then
			local multiplier = (config and config.Multiplier) or 1
			if not bestMultiplier or multiplier > bestMultiplier then
				best, bestMultiplier = container, multiplier
			end
		end
	end
	return best
end

local function isInsideZone(container)
	local zone = zoneFor(container)
	if zone and type(zone.findLocalPlayer) == "function" then
		local ok, inside = pcall(zone.findLocalPlayer, zone)
		if ok then
			return inside == true
		end
	end
	local root = getRoot()
	local pivot = safePivot(container)
	if root and pivot then
		return (root.Position - pivot).Magnitude < 25
	end
	return false
end

local function zoneEntryPosition(container)
	local zone = zoneFor(container)
	local pivot = safePivot(container)
	if zone and type(zone.findPoint) == "function" then
		if pivot then
			local ok, inside = pcall(zone.findPoint, zone, pivot)
			if ok and inside then
				return pivot
			end
		end
		local checked = 0
		for _, part in ipairs(container:GetDescendants()) do
			if part:IsA("BasePart") then
				checked += 1
				if checked > 10 then
					break
				end
				local ok, inside = pcall(zone.findPoint, zone, part.Position)
				if ok and inside then
					return part.Position
				end
			end
		end
	end
	return pivot
end

local rebirthState
if RebirthEvent then
	pcall(function()
		RebirthEvent.OnClientEvent:Connect(function(action, state)
			if action == "State" then
				rebirthState = state
			end
		end)
	end)
end

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local winsStageName = nil
local winsCooldown = {}

local function pickWinsStage(stages, power)
	table.sort(stages, function(a, b)
		local ia = tonumber(string.match(a.name, "%d+")) or 0
		local ib = tonumber(string.match(b.name, "%d+")) or 0
		return ia < ib
	end)
	local now = tick()
	local function open(stage)
		local cooldown = winsCooldown[stage.name]
		return cooldown == nil or cooldown <= now
	end
	local function fillTime(stage)
		return estimateFillTime(stage.capacity, power)
	end
	if winsStageName then
		for position, stage in ipairs(stages) do
			if stage.name == winsStageName then
				if open(stage) and fillTime(stage) < 15 then
					local current = stage
					for index = position + 1, #stages do
						local higher = stages[index]
						if open(higher) and fillTime(higher) < 7 then
							current = higher
						end
					end
					winsStageName = current.name
					return current
				end
				break
			end
		end
		winsStageName = nil
	end
	local best
	for _, stage in ipairs(stages) do
		if open(stage) and fillTime(stage) < 10 then
			best = stage
		end
	end
	if best then
		winsStageName = best.name
		return best
	end
	for _, stage in ipairs(stages) do
		if open(stage) then
			winsStageName = stage.name
			return stage
		end
	end
	return nil
end

local function touchWinsHitbox(hitbox)
	for _, part in ipairs(touchParts(hitbox)) do
		fireTouch(part)
	end
end

local function doAutoWins()
	if not enabled.autoWins then
		return
	end
	local stages = scanStages()
	if #stages == 0 then
		return
	end
	local power = getWaterPower()
	local best = pickWinsStage(stages, power)
	if not best then
		return
	end
	setFarmStatus("farming")
	local fillSpot = topSurface(best.fillPart) or safePivot(best.fillPart)
	if fillSpot then
		teleportTo(fillSpot)
	end
	task.wait(math.clamp(estimateFillTime(best.capacity, power) * 1.5 + 1, 1, 20))
	if not enabled.autoWins or not session.running then
		return
	end
	local winsBefore = getWins()
	touchWinsHitbox(best.winsHitbox)
	task.wait(0.35)
	if getWins() <= winsBefore then
		local spot = safePivot(best.winsHitbox)
		if spot then
			teleportTo(spot)
			task.wait(0.15)
			touchWinsHitbox(best.winsHitbox)
			task.wait(0.35)
		end
	end
	if getWins() <= winsBefore then
		winsCooldown[best.name] = tick() + 90
		winsStageName = nil
	end
end

local function doAutoTrain()
	if not enabled.train or enabled.autoWins then
		return
	end
	local container = bestTrainingZone()
	if not container then
		return
	end
	if not isInsideZone(container) then
		local point = zoneEntryPosition(container)
		if point then
			teleportTo(point)
			task.wait(0.25)
		end
	end
	if isInsideZone(container) then
		setFarmStatus("training")
		fire(GainPower)
	end
end

local function doAutoRebirth()
	if not enabled.rebirth or not RebirthEvent then
		return
	end
	fire(RebirthEvent, "Request")
	if rebirthState and rebirthState.CanRebirth == true then
		setFarmStatus("rebirth")
		fire(RebirthEvent, "Rebirth")
		task.wait(1)
	end
end

local function doAutoBucket()
	if not enabled.bucket or not BucketShop or not Buckets then
		return
	end
	local data = getPlayerData()
	if not data or type(data.Inventory) ~= "table" then
		return
	end
	local owned = data.Inventory.Buckets or {}
	local wins = getWins()
	local ownedFill, ownedName = 0, nil
	for name in pairs(owned) do
		local config = Buckets[name]
		if config and (config.FillPower or 0) > ownedFill then
			ownedFill, ownedName = config.FillPower or 0, name
		end
	end
	local buyName, buyFill
	for name, config in pairs(Buckets) do
		if not config.Gamepass and not owned[name] and (config.RequiredWins or 0) <= wins then
			local fill = config.FillPower or 0
			if fill > 0 and (not buyFill or fill < buyFill) then
				buyName, buyFill = name, fill
			end
		end
	end
	if buyName then
		setFarmStatus("buy bucket " .. buyName)
		fire(BucketShop, buyName)
		playerDataAt = 0
		task.wait(0.5)
		return
	end
	local equippedFill = (data.CurrentBucket and Buckets[data.CurrentBucket] and Buckets[data.CurrentBucket].FillPower) or 0
	if ownedName and ownedFill > equippedFill then
		setFarmStatus("equip bucket " .. ownedName)
		fire(BucketShop, ownedName)
		playerDataAt = 0
		task.wait(0.5)
	end
end

local function doAutoAura()
	if not enabled.aura or not Auras then
		return
	end
	local data = getPlayerData()
	if not data or type(data.Inventory) ~= "table" then
		return
	end
	local owned = data.Inventory.Auras or {}
	local wins = getWins()
	local ownedMult, ownedName = 0, nil
	for name in pairs(owned) do
		local config = Auras[name]
		if config and (config.Multiplier or 0) > ownedMult then
			ownedMult, ownedName = config.Multiplier or 0, config.Name or name
		end
	end
	local buyName, buyMult
	for name, config in pairs(Auras) do
		local mult = config.Multiplier or 0
		if config.Cost and not owned[name] and config.Cost <= wins and mult > ownedMult then
			if not buyMult or mult > buyMult then
				buyName, buyMult = config.Name or name, mult
			end
		end
	end
	if buyName and BuyAura then
		setFarmStatus("buy aura " .. buyName)
		fire(BuyAura, buyName)
		playerDataAt = 0
		task.wait(0.5)
		return
	end
	if ownedName and data.CurrentAura ~= ownedName and ownedMult > 0 and EquipAura then
		setFarmStatus("equip aura " .. ownedName)
		fire(EquipAura, ownedName)
		playerDataAt = 0
		task.wait(0.5)
	end
end

local function doAutoSpeed()
	if not enabled.speed or not SpeedUpgrade then
		return
	end
	local speed = getSpeed()
	if SpeedCost and SpeedCost.IsMaxed and SpeedCost:IsMaxed(speed) then
		return
	end
	local cost = SpeedCost and SpeedCost.GetCost and SpeedCost:GetCost(speed)
	if cost and getWins() < cost then
		return
	end
	setFarmStatus("speed upgrade")
	fire(SpeedUpgrade, "Upgrade")
end

local function buyBestBucket()
	if not BucketShop then
		return
	end
	setFarmStatus("buy bucket Hacker Bucket")
	fire(BucketShop, "Hacker Bucket")
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
local ShopTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" })

local FarmBox = box(FarmingTab, "Farming", "star", "Left")
FarmBox:AddToggle("AutoWins", { Text = "Farm Wins", Default = false, Callback = function(value)
	enabled.autoWins = value
end })
FarmBox:AddToggle("AutoTrain", { Text = "Auto Train", Default = false, Callback = function(value)
	enabled.train = value
end })
FarmBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })
FarmBox:AddDivider()
FarmBox:AddButton({ Text = "Best Bucket", Func = buyBestBucket })

local StatusBox = box(FarmingTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("WinsLabel", { Text = paint("Wins -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("PowerLabel", { Text = paint("Water Power -", "0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("LevelLabel", { Text = paint("Level -", "1", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("RebirthLabel", { Text = paint("Rebirth -", "0", COLORS.orange), DoesWrap = true })

local BucketBox = box(ShopTab, "Auto Buy Bucket", "shopping-bag", "Left")
BucketBox:AddToggle("AutoBucket", { Text = "Auto Buy Best Bucket", Default = false, Callback = function(value)
	enabled.bucket = value
end })

local AuraBox = box(ShopTab, "Auto Buy Aura", "sparkles", "Right")
AuraBox:AddToggle("AutoAura", { Text = "Auto Buy Best Aura", Default = false, Callback = function(value)
	enabled.aura = value
end })

local SpeedBox = box(ShopTab, "Auto Upgrade Speed", "gauge", "Left")
SpeedBox:AddToggle("AutoSpeed", { Text = "Auto Speed Upgrade", Default = false, Callback = function(value)
	enabled.speed = value
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
	setLabel("WinsLabel", paint("Wins -", abbreviateNumber(getWins()), COLORS.gold))
	setLabel("PowerLabel", paint("Water Power -", abbreviateNumber(getWaterPower()), COLORS.user))
	setLabel("LevelLabel", paint("Level -", getLevel(), COLORS.accent))
	setLabel("RebirthLabel", paint("Rebirth -", getRebirth(), COLORS.orange))
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

chain({ doAutoWins }, 0.2)
chain({ doAutoTrain, doAutoRebirth }, 0.3)
loop(doAutoBucket, 0.3)
loop(doAutoAura, 0.3)
loop(doAutoSpeed, 0.3)

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
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()