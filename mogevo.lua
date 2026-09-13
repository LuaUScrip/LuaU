local Repo = "https://raw.githubusercontent.com/LuaUScrip/HUB/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

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
	Version = "v1.5",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Mog Evolution",
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

print("[AntiGodHub] Loading - " .. CONFIG.GameName)

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

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local gameState = {
	mogActive = false,
}

local Remotes = {}
local announcedRemote = {}

local function resolveRemote(...)
	local node = ReplicatedStorage
	for index = 1, select("#", ...) do
		local name = (select(index, ...))
		local found = node and node:FindFirstChild(name)
		if not found then
			local ok, waited = pcall(function()
				return node and node:WaitForChild(name, 10)
			end)
			found = ok and waited or nil
		end
		if not found then
			return nil
		end
		node = found
	end
	return node
end

local function getRemote(...)
	local key = table.concat({...}, "/")
	local cached = Remotes[key]
	if cached and cached.Parent then
		return cached
	end
	local found = resolveRemote(...)
	if found then
		if not announcedRemote[key] then
			announcedRemote[key] = true
			print("[AntiGodHub] Remote ready - " .. key)
		end
		Remotes[key] = found
	end
	return found
end

local PacketIds = {
	Challenge = 0,
	Begin = 1,
	Duel = 2,
	Countdown = 3,
	Fill = 4,
	Click = 5,
	Result = 6,
	Finish = 7,
	Ascend = 8,
	Flash = 9,
}

local function mogPacket(packetId, ...)
	local bytes = {packetId}
	for _, value in ipairs({...}) do
		if type(value) == "string" then
			table.insert(bytes, #value)
			for index = 1, #value do
				table.insert(bytes, string.byte(value, index))
			end
		elseif type(value) == "number" then
			table.insert(bytes, value)
		elseif type(value) == "boolean" then
			table.insert(bytes, value and 1 or 0)
		end
	end
	local buf = buffer.create(#bytes)
	for index = 1, #bytes do
		buffer.writeu8(buf, index - 1, bytes[index])
	end
	return buf
end

local function watchPackets(event)
	if not event or gameState.packetWatch then
		return
	end
	gameState.packetWatch = event
	pcall(function()
		event.OnClientEvent:Connect(function(buf)
			if typeof(buf) ~= "buffer" or buffer.len(buf) < 1 then
				return
			end
			local ok, packetId = pcall(buffer.readu8, buf, 0)
			if ok and (packetId == PacketIds.Result or packetId == PacketIds.Finish) then
				gameState.mogActive = false
			end
		end)
	end)
end

local MOG_ZONES = {
	{"Zone0", 100},
	{"Zone1", 500},
	{"Zone2", 2400},
	{"Zone3", 8000},
	{"Zone4", 42000},
	{"Zone5", 230000},
	{"Zone6", 550000},
	{"Zone7", 1500000},
	{"Zone8", 2000000},
	{"Zone9", 2600000},
	{"Zone10", 12000000},
	{"Zone11", 23000000},
	{"Zone12", 42000000},
	{"Zone13", 54000000},
	{"Zone14", 120000000},
}
local MOG_ZONE_NAMES = {}
for _, zone in ipairs(MOG_ZONES) do
	table.insert(MOG_ZONE_NAMES, zone[1])
end

local MOG_ZONE_DEFAULT = "Zone4"

local HAMMER_TIERS = {
	{"1", "Wood", 1},
	{"2", "Stone", 10},
	{"3", "Iron", 50},
	{"4", "Gold", 200},
	{"5", "Diamond", 1000},
	{"6", "Flaming", 5000},
	{"7", "Darkness", 20000},
	{"8", "Void", 80000},
	{"9", "Galaxy", 350000},
	{"10", "Rainbow", 1500000},
	{"11", "Godly", 7500000},
}
local REBIRTH_BASE_LEVEL = 10
local REBIRTH_LEVEL_INCREMENT = 5

local function worldFromOption(optionKey, fallbackKey)
	local option = Options and Options[optionKey]
	local name = option and tostring(option.Value) or ""
	if name ~= "World1" and name ~= "World2" and fallbackKey then
		local fallback = Options and Options[fallbackKey]
		name = fallback and tostring(fallback.Value) or ""
	end
	if name ~= "World1" and name ~= "World2" then
		name = "World1"
	end
	return Workspace:FindFirstChild(name)
end

local function getWorld()
	return worldFromOption("WorldSelect")
end

local function getMogWorld()
	return worldFromOption("MogWorld", "WorldSelect")
end

local function getLaneName()
	return "Normal"
end

local function getWins()
	return tonumber(LocalPlayer:GetAttribute("Wins")) or 0
end

local function getTotalWins()
	return tonumber(LocalPlayer:GetAttribute("TotalWins")) or 0
end

local function getLevel()
	return tonumber(LocalPlayer:GetAttribute("Level")) or 0
end

local function getRebirths()
	return tonumber(LocalPlayer:GetAttribute("Rebirths")) or 0
end

local function getAppeal()
	return tonumber(LocalPlayer:GetAttribute("AppealTotal")) or 0
end

local function rebirthRequirement()
	return REBIRTH_BASE_LEVEL + REBIRTH_LEVEL_INCREMENT * getRebirths()
end

local function selectedPads()
	local option = Options and Options.WinPadSelect
	local value = option and option.Value
	local pads = {}
	if type(value) == "table" then
		for _, entry in ipairs(value) do
			local pad = tonumber(entry)
			if pad then
				table.insert(pads, pad)
			end
		end
	else
		local pad = tonumber(value)
		if pad then
			table.insert(pads, pad)
		end
	end
	table.sort(pads)
	if #pads == 0 then
		table.insert(pads, 8)
	end
	return pads
end

local function optionNumber(key, fallback)
	local option = Options and Options[key]
	local value = option and tonumber(option.Value)
	return value or fallback
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

local function firePrompt(prompt)
	if not prompt then
		return false
	end
	return pcall(function()
		if fireproximityprompt then
			fireproximityprompt(prompt)
		elseif fireprompt then
			fireprompt(prompt)
		elseif fire then
			fire(prompt)
		else
			prompt:InputHoldBegin()
			task.wait(math.clamp((prompt.HoldDuration or 0) + 0.05, 0.05, 3))
			prompt:InputHoldEnd()
		end
	end)
end

local function zeroVelocity(part)
	if not part then
		return
	end
	pcall(function()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function moggerPosition(world, zoneName)
	local moggers = world and world:FindFirstChild("Moggers")
	local zone = moggers and moggers:FindFirstChild(zoneName)
	local mogger = zone and (zone:FindFirstChild("Mogger") or zone)
	if not mogger then
		return nil
	end
	local humanoid = mogger:FindFirstChildOfClass("Humanoid")
	local root = humanoid and (mogger:FindFirstChild("HumanoidRootPart") or humanoid.RootPart)
	if root then
		return root.Position
	end
	return safePivot(mogger)
end

local function doAutoMog()
	if not enabled.autoMog then
		return
	end
	local event = getRemote("Packet", "RemoteEvent")
	watchPackets(event)
	if not event then
		return
	end
	if not ready("mog", 0.1) then
		return
	end
	local zone = Options and Options.MogZone and tostring(Options.MogZone.Value) or MOG_ZONE_DEFAULT
	if zone == "" then
		zone = MOG_ZONE_DEFAULT
	end
	local spot = moggerPosition(getMogWorld(), zone)
	if spot then
		setFarmStatus("teleport to " .. zone .. " mogger")
		teleportTo(spot)
		task.wait(0.25)
	end
	if not session.running or not enabled.autoMog then
		return
	end
	setFarmStatus("mogging " .. zone)
	fire(event, mogPacket(PacketIds.Challenge, zone))
	gameState.mogActive = true
	local deadline = tick() + 60
	while session.running and enabled.autoMog and gameState.mogActive and tick() < deadline do
		fire(event, mogPacket(PacketIds.Click))
		task.wait(0.1)
	end
	gameState.mogActive = false
end

local function doAutoAscend()
	if not enabled.autoAscend then
		return
	end
	if not ready("ascend", 0.1) then
		return
	end
	local event = getRemote("Packet", "RemoteEvent")
	if not event then
		return
	end
	setFarmStatus("ascending")
	fire(event, mogPacket(PacketIds.Ascend))
end

local function doAutoClickPower()
	if not enabled.autoClickPower then
		return
	end
	if not ready("clickPower", 0.01) then
		return
	end
	local event = getRemote("PowerRemotes", "ClickPower")
	if not event then
		return
	end
	setFarmStatus("farming power")
	fire(event)
end

local function doAutoWin()
	if not enabled.autoWinPads then
		return
	end
	local world = getWorld()
	if not world then
		return
	end
	local lane = find(world, "WinPads", getLaneName())
	local targetPad = selectedPads()[1]
	local finalZoneIndex = targetPad - 1
	if finalZoneIndex < 0 then
		return
	end
	local stand = lane and lane:FindFirstChild(tostring(targetPad))
	local padPart = stand and (stand:FindFirstChild("Win") or stand:FindFirstChildWhichIsA("BasePart", true))
	local padPos = padPart and safePivot(padPart)
	if not padPart or not padPos then
		return
	end
	local spawnPos = safePivot(world:FindFirstChild("SpawnLocation"))
	local hopDelay = math.clamp(optionNumber("WinSpeed", 0.1), 0.05, 2)
	for zoneIndex = 0, finalZoneIndex do
		if not (session.running and enabled.autoWinPads) then
			return
		end
		local zoneName = "Zone" .. zoneIndex
		local spot = moggerPosition(world, zoneName)
		if spot then
			setFarmStatus("teleport to " .. zoneName .. " mogger")
			teleportTo(spot)
			zeroVelocity(getRoot())
			task.wait(hopDelay)
		end
	end
	if not (session.running and enabled.autoWinPads) then
		return
	end
	teleportTo(padPos)
	zeroVelocity(getRoot())
	setFarmStatus("claiming win " .. targetPad)
	fireTouch(padPart)
	task.wait(0.25)
	if spawnPos then
		setFarmStatus("teleport to spawn")
		teleportTo(spawnPos)
		zeroVelocity(getRoot())
	end
end

local function currentHammerTier()
	return math.floor(tonumber(LocalPlayer:GetAttribute("HammerTier")) or 0)
end

local function bestOwnedTier()
	local equipped = currentHammerTier()
	local best = equipped
	local mask = tonumber(LocalPlayer:GetAttribute("HammerOwned")) or 0
	for tier = 1, #HAMMER_TIERS do
		local ok, owned = pcall(bit32.btest, mask, bit32.lshift(1, tier - 1))
		if ok and owned and tier > best then
			best = tier
		end
	end
	return best
end

local function targetBestEquipTier()
	local equipped = currentHammerTier()
	local best = bestOwnedTier()
	local wins = getWins()
	for tier = 1, #HAMMER_TIERS do
		local price = HAMMER_TIERS[tier][3]
		if wins >= price and tier > best then
			best = tier
		end
	end
	if best > equipped and best >= 1 and best <= #HAMMER_TIERS then
		return best
	end
	return nil
end

local function equipHammerNow(stands, tier)
	local entry = HAMMER_TIERS[tier]
	if not entry then
		return false
	end
	local stand = stands:FindFirstChild(entry[1])
	if not stand then
		return false
	end
	local frame = stand:FindFirstChild("Frame") or stand:FindFirstChildWhichIsA("BasePart", true)
	local position = safePivot(frame)
	if not frame or not position then
		return false
	end
	local before = currentHammerTier()
	teleportTo(position)
	zeroVelocity(getRoot())
	for attempt = 1, 3 do
		if currentHammerTier() == tier then
			break
		end
		for _, part in ipairs(touchParts(stand)) do
			fireTouch(part)
			task.wait(0.05)
			if currentHammerTier() == tier then
				break
			end
		end
		task.wait(0.2)
		attempt = attempt + 1
	end
	return currentHammerTier() ~= before and currentHammerTier() == tier
end

local function doAutoHammer()
	if not enabled.autoHammer then
		return
	end
	if not ready("hammer", 0.1) then
		return
	end
	local world = getWorld()
	local stands = world and world:FindFirstChild("HammerStand")
	if not stands then
		return
	end
	local tier = targetBestEquipTier()
	if not tier then
		setFarmStatus("best hammer already equipped - stopped")
		local toggle = Toggles and Toggles.AutoHammer
		if toggle and toggle.Value then
			pcall(function()
				toggle:SetValue(false)
			end)
		end
		enabled.autoHammer = false
		return
	end
	local tierName = HAMMER_TIERS[tier][2]
	setFarmStatus("equipping " .. tierName .. " hammer")
	if equipHammerNow(stands, tier) then
		setFarmStatus("equipped " .. tierName .. " - stopped")
		local toggle = Toggles and Toggles.AutoHammer
		if toggle and toggle.Value then
			pcall(function()
				toggle:SetValue(false)
			end)
		end
		enabled.autoHammer = false
	end
end

local function doAutoRebirth()
	if not enabled.autoRebirth then
		return
	end
	if not ready("rebirth", 3) then
		return
	end
	if getLevel() < rebirthRequirement() then
		return
	end
	local event = getRemote("RebirthRemotes", "DoRebirth")
	if not event then
		return
	end
	setFarmStatus("rebirth at level " .. getLevel())
	fire(event)
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
			if okDecode and type(decoded) == "table" then
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

local FarmTab = Tabs.Main:AddSubTab({ Name = "Power", Icon = "zap" })
local WinTab = Tabs.Main:AddSubTab({ Name = "Win", Icon = "trophy" })
local MogTab = Tabs.Main:AddSubTab({ Name = "Mog", Icon = "sparkles" })
local HammerTab = Tabs.Main:AddSubTab({ Name = "Hammers", Icon = "hammer" })

local PowerBox = box(FarmTab, "Power & Level", "zap", "Left")
PowerBox:AddToggle("AutoFarmPower", { Text = "Farm Power", Default = false, Callback = function(value)
	enabled.autoClickPower = value
end })
PowerBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.autoRebirth = value
end })

local FarmInfoBox = box(FarmTab, "Farming Info", "activity", "Right")
FarmInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("LevelLabel", { Text = paint("Level -", "0", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("AppealLabel", { Text = paint("Appeal -", "0", COLORS.gold), DoesWrap = true })
FarmInfoBox:AddLabel("RebirthsLabel", { Text = paint("Rebirth -", "0", COLORS.orange), DoesWrap = true })
FarmInfoBox:AddLabel("RebirthGateLabel", { Text = paint("Rebirth Req -", "...", COLORS.orange), DoesWrap = true })

local WinBox = box(WinTab, "Auto Win", "trophy", "Left")
WinBox:AddDropdown("WorldSelect", {
	Text = "Select World",
	Values = { "World1", "World2" },
	Default = "World1",
	Callback = function(value)
		settings.worldSelect = value
	end,
})
do
	local padValues = {}
	for index = 1, 15 do
		table.insert(padValues, tostring(index))
	end
	WinBox:AddDropdown("WinPadSelect", {
		Text = "Select Area",
		Values = padValues,
		Default = "1",
		Callback = function(value)
			settings.winPadSelect = value
		end,
	})
end
WinBox:AddSlider("WinSpeed", {
	Text = "Speed Farming",
	Default = 0.1,
	Min = 0.05,
	Max = 2,
	Rounding = 2,
	Callback = function(value)
		settings.winSpeed = value
	end,
})
WinBox:AddToggle("AutoWinPads", { Text = "Auto Win", Default = false, Callback = function(value)
	enabled.autoWinPads = value
end })
local WinInfoBox = box(WinTab, "Wins Info", "activity", "Right")
WinInfoBox:AddLabel("WinStatus", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
WinInfoBox:AddLabel("WinsLabel", { Text = paint("Wins -", "0", COLORS.gold), DoesWrap = true })
WinInfoBox:AddLabel("TotalWinsLabel", { Text = paint("Total Wins -", "0", COLORS.user), DoesWrap = true })

local MogBox = box(MogTab, "Auto Mog", "sparkles", "Left")
MogBox:AddDropdown("MogWorld", {
	Text = "Select World",
	Values = { "World1", "World2" },
	Default = "World1",
	Callback = function(value)
		settings.mogWorld = value
	end,
})
MogBox:AddDropdown("MogZone", {
	Text = "Select Zone",
	Values = MOG_ZONE_NAMES,
	Default = MOG_ZONE_DEFAULT,
	Callback = function(value)
		settings.mogZone = value
	end,
})
MogBox:AddToggle("AutoMog", { Text = "Auto Mog", Default = false, Callback = function(value)
	enabled.autoMog = value
end })
MogBox:AddToggle("AutoAscend", { Text = "Auto Ascend", Default = false, Callback = function(value)
	enabled.autoAscend = value
end })

local MogInfoBox = box(MogTab, "Mogging Info", "activity", "Right")
MogInfoBox:AddLabel("MogStatus", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
MogInfoBox:AddLabel("MogZoneLive", { Text = paint("Zone -", "...", COLORS.user), DoesWrap = true })
MogInfoBox:AddLabel("MogAppeal", { Text = paint("Appeal -", "0", COLORS.gold), DoesWrap = true })
MogInfoBox:AddLabel("MogZoneReq", { Text = paint("Zone Req -", "...", COLORS.orange), DoesWrap = true })

local HammerBox = box(HammerTab, "Auto Hammer", "hammer", "Left")
HammerBox:AddToggle("AutoHammer", { Text = "Buy + Equip Best Hammer", Default = false, Callback = function(value)
	enabled.autoHammer = value
end })

local HammerInfoBox = box(HammerTab, "Hammer Info", "activity", "Right")
HammerInfoBox:AddLabel("HammerStatus", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
HammerInfoBox:AddLabel("HammerEquipped", { Text = paint("Equipped -", "...", COLORS.accent), DoesWrap = true })
HammerInfoBox:AddLabel("HammerBest", { Text = paint("Best -", "...", COLORS.gold), DoesWrap = true })
HammerInfoBox:AddLabel("HammerNext", { Text = paint("Next -", "...", COLORS.user), DoesWrap = true })

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

local function hammerNames(tier)
	if tier and tier >= 1 and tier <= #HAMMER_TIERS then
		return HAMMER_TIERS[tier][2]
	end
	return "none"
end

local function liveActivity()
	if enabled.autoHammer then
		local tier = targetBestEquipTier()
		if not tier then
			return "Buy Hammer"
		end
		if tier > bestOwnedTier() then
			return "Buy " .. hammerNames(tier)
		end
		return "Equip " .. hammerNames(tier)
	end
	if enabled.autoMog then
		local zone = Options and Options.MogZone and tostring(Options.MogZone.Value) or MOG_ZONE_DEFAULT
		return "Mog " .. zone
	end
	if enabled.autoWinPads then
		return "Farming Wins"
	end
	if enabled.autoClickPower then
		return "Farming Power"
	end
	return "idle"
end

local function updateLabels()
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", liveActivity(), COLORS.accent))
	setLabel("LevelLabel", paint("Level -", tostring(getLevel()), COLORS.accent))
	setLabel("AppealLabel", paint("Appeal -", abbreviateNumber(getAppeal()), COLORS.gold))
	setLabel("RebirthsLabel", paint("Rebirth -", tostring(getRebirths()), COLORS.orange))
	setLabel("RebirthGateLabel", paint("Rebirth Req -", "Lv " .. rebirthRequirement() .. " (you: " .. getLevel() .. ")", COLORS.orange))
	setLabel("WinStatus", paint("Status -", liveActivity(), COLORS.accent))
	setLabel("WinsLabel", paint("Wins -", abbreviateNumber(getWins()), COLORS.gold))
	setLabel("TotalWinsLabel", paint("Total Wins -", abbreviateNumber(getTotalWins()), COLORS.user))
	setLabel("MogStatus", paint("Status -", liveActivity(), COLORS.accent))
	pcall(function()
		local zone = Options and Options.MogZone and tostring(Options.MogZone.Value) or MOG_ZONE_DEFAULT
		setLabel("MogZoneLive", paint("Zone -", zone, COLORS.user))
		local required
		for _, entry in ipairs(MOG_ZONES) do
			if entry[1] == zone then
				required = entry[2]
				break
			end
		end
		setLabel("MogZoneReq", paint("Zone Req -", required and (abbreviateNumber(required)) or "unknown", COLORS.orange))
	end)
	setLabel("MogAppeal", paint("Appeal -", abbreviateNumber(getAppeal()), COLORS.gold))
	setLabel("HammerStatus", paint("Status -", liveActivity(), COLORS.accent))
	pcall(function()
		setLabel("HammerEquipped", paint("Equipped -", hammerNames(currentHammerTier()), COLORS.accent))
		setLabel("HammerBest", paint("Best -", hammerNames(bestOwnedTier()), COLORS.gold))
		local wins = getWins()
		local nextTier
		for tier = 1, #HAMMER_TIERS do
			if wins >= HAMMER_TIERS[tier][3] then
				nextTier = tier
			end
		end
		local text = "none affordable"
		if nextTier then
			text = HAMMER_TIERS[nextTier][2] .. " (" .. abbreviateNumber(HAMMER_TIERS[nextTier][3]) .. " wins)"
		end
		setLabel("HammerNext", paint("Next -", text, COLORS.user))
	end)
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

chain({ doAutoClickPower, doAutoAscend }, 0.01)
loop(doAutoMog, 0.5)
loop(doAutoHammer, 0.5)
loop(doAutoRebirth, 0.5)
loop(doAutoWin, 1)

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