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
	Version = "v1.4",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Jump To Steal Soccer Player",
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

local LUCKY_BLOCKS = {
	"Champions Lucky Block",
	"Spain Lucky Block",
	"Icons Lucky Block",
	"Japan Lucky Block",
	"Alternate Lucky Block",
	"Next Generation Lucky Block",
	"Backline Legends Lucky Block",
	"Coaches Lucky Block",
}

local HOME_POSITION = Vector3.new(198, 3, 280)

local GEAR_LIST = {
	{"1", "Starter Coil", 1520},
	{"2", "Speed Coil", 25400},
	{"3", "Elastic Coil", 513000},
	{"4", "Swift Coil", 7760000},
	{"5", "Storm Coil", 26100000},
	{"6", "Rainbow Coil", 190000000},
	{"20", "Dual Crimson Coil", 799000000},
	{"21", "Dual Rainbow Coil", 109000000000},
	{"23", "Dual Shadow Coil", 27500000000000},
	{"29", "Dual Fallen Coil", 33900000000000000},
	{"33", "Dual Ghost Coil", 21400000000000000000},
}

local GEAR_SORTED = {}
for _, gear in ipairs(GEAR_LIST) do
	table.insert(GEAR_SORTED, gear)
end
table.sort(GEAR_SORTED, function(a, b)
	return a[3] < b[3]
end)

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

local function selectedSet(optionKey)
	local option = Options and Options[optionKey]
	local selection = option and option.Value
	if type(selection) == "string" then
		return {[selection] = true}
	end
	if type(selection) == "table" then
		for key, value in pairs(selection) do
			if type(key) == "string" and value == true then
				return selection
			end
			break
		end
		local out = {}
		for _, value in ipairs(selection) do
			out[value] = true
		end
		return out
	end
	return {}
end

local function selectedList(optionKey)
	local set = selectedSet(optionKey)
	local list = {}
	for value in pairs(set) do
		table.insert(list, value)
	end
	table.sort(list)
	return list
end

local function optionNumber(key, fallback)
	local option = Options and Options[key]
	local value = option and tonumber(option.Value)
	return value or fallback
end

local function getMoney()
	local ok, value = pcall(function()
		return game:GetService("Players").LocalPlayer.leaderstats.Cash.Value
	end)
	return ok and tonumber(value) or 0
end

local function getRebirths()
	local ok, value = pcall(function()
		return game:GetService("Players").LocalPlayer.leaderstats.Rebirth.Value
	end)
	return ok and tonumber(value) or 0
end

local JUMP_BASE_PRICE = 260
local JUMP_GROWTH = 1.073
local JUMP_PRICE_SCALE = 5 * 1.38 / (1 + 1.073 + 1.073 ^ 2 + 1.073 ^ 3 + 1.073 ^ 4)

local function getJumpLevel()
	local ok, data = pcall(function()
		return _G._Lib and _G._Lib.Data and _G._Lib.Data:Get(LocalPlayer)
	end)
	if ok and type(data) == "table" then
		local jump = tonumber(data.Jump)
		if jump then
			return jump
		end
	end
	local attr = LocalPlayer:GetAttribute("Jump")
	if attr ~= nil then
		return math.floor(tonumber(attr) or 0)
	end
	return nil
end

local function jumpSinglePrice(level)
	return math.floor(JUMP_BASE_PRICE * JUMP_GROWTH ^ level * JUMP_PRICE_SCALE + 0.5)
end

local function fireSpeedUpgradeSmart()
	local money = getMoney()
	local level = getJumpLevel()
	if level then
		local bulk = 0
		local cost = 0
		for i = 0, 9 do
			local price = jumpSinglePrice(level + i)
			if money < cost + price then
				break
			end
			cost = cost + price
			bulk = bulk + 1
		end
		if bulk >= 1 then
			fire(getRemote("SharedModules", "Network", "Remotes", "Buy Speed Upgrade"), bulk)
			return
		end
	end
	fire(getRemote("SharedModules", "Network", "Remotes", "Buy Speed Upgrade"), 3)
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

local function zeroVelocity(part)
	if not part then
		return
	end
	pcall(function()
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function teleportTo(position)
	local root = getRoot()
	if root and position then
		zeroVelocity(root)
		root.CFrame = CFrame.new(position)
		zeroVelocity(root)
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

pcall(function()
	game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(prompt)
		pcall(fireproximityprompt, prompt)
	end)
end)

local function luckyBlockPart(blockName)
	local ok, part = pcall(function()
		local model = find(Workspace, "Live", "Slimes", blockName)
		if not model then
			return nil
		end
		return model:FindFirstChild("RootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	end)
	if ok then
		return part
	end
	return nil
end

local function fireStealPrompt(part)
	if not part then
		return
	end
	local prompt = part:FindFirstChild("StealPrompt")
	if not prompt and part.Parent then
		prompt = part.Parent:FindFirstChild("StealPrompt")
	end
	if not prompt then
		prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
	end
	if not prompt and part.Parent then
		prompt = part.Parent:FindFirstChildWhichIsA("ProximityPrompt")
	end
	if prompt then
		firePrompt(prompt)
	end
end

local function isOwnPlotBlock(part)
	local node = part
	while node and node ~= Workspace do
		local ok, owner = pcall(node.GetAttribute, node, "Owner")
		if ok and owner ~= nil and (owner == LocalPlayer or tonumber(owner) == LocalPlayer.UserId) then
			return true
		end
		node = node.Parent
	end
	return false
end

local function doAutoFarm()
	if not enabled.autoFarm then
		return
	end
	local blocks = selectedList("LuckyBlockSelect")
	if #blocks == 0 then
		return
	end
	local promptWait = math.clamp(optionNumber("FarmSpeed", 0.25), 0.05, 2)
	for _, blockName in ipairs(blocks) do
		if not (session.running and enabled.autoFarm) then
			return
		end
		local part = luckyBlockPart(blockName)
		if part and not isOwnPlotBlock(part) then
			local spot = safePivot(part)
			if spot then
				setFarmStatus("stealing " .. blockName)
				teleportTo(spot)
				task.wait(0.05)
				fireStealPrompt(part)
				task.wait(promptWait)
				teleportTo(HOME_POSITION)
				task.wait(0.1)
			end
		end
	end
end

local function doAutoCollect()
	if not enabled.autoCollect then
		return
	end
	setFarmStatus("collecting cash")
	for slot = 1, 70 do
		if not (session.running and enabled.autoCollect) then
			return
		end
		local event = getRemote("SharedModules", "Network", "Remotes", "Collect Earnings")
		fire(event, tostring(slot))
		task.wait(0.01)
	end
end

local function doAutoOpen()
	if not enabled.autoOpen then
		return
	end
	if not ready("open", 0.1) then
		return
	end
	local event = getRemote("SharedModules", "Network", "Remotes", "Open Lucky Block")
	if not event then
		return
	end
	setFarmStatus("opening lucky blocks")
	fire(event)
end

local function doAutoSellAll()
	if not enabled.autoSellAll then
		return
	end
	if not ready("sell", 0.5) then
		return
	end
	local event = getRemote("SharedModules", "Network", "Remotes", "Sell All Slimes")
	if not event then
		return
	end
	setFarmStatus("selling soccer players")
	fire(event)
end

local REBIRTH_JUMP_REQ = {50, 75, 100, 125, 150, 200, 250}

local function rebirthJumpRequirement()
	local nextRebirth = getRebirths() + 1
	if nextRebirth <= #REBIRTH_JUMP_REQ then
		return REBIRTH_JUMP_REQ[nextRebirth]
	end
	return REBIRTH_JUMP_REQ[#REBIRTH_JUMP_REQ] + (nextRebirth - #REBIRTH_JUMP_REQ) * 40
end

local function doAutoRebirth()
	if not enabled.autoRebirth then
		return
	end
	if not ready("rebirth", 1) then
		return
	end
	local jump = getJumpLevel()
	if jump and jump < rebirthJumpRequirement() then
		return
	end
	local event = getRemote("SharedModules", "Network", "Remotes", "Rebirth")
	if not event then
		return
	end
	setFarmStatus("rebirth")
	fire(event)
end

local function doAutoBuyAllUpgrades()
	if not enabled.autoBuyUpgrades then
		return
	end
	if not ready("buyUpgrades", 0.5) then
		return
	end
	setFarmStatus("buying upgrades")
	fire(getRemote("SharedModules", "Network", "Remotes", "Upgrade Carry Limit"))
	fireSpeedUpgradeSmart()
end

local function doAutoBuySelectedUpgrades()
	if not enabled.autoBuySelectedUpgrades then
		return
	end
	if not ready("buySelUpgrades", 0.5) then
		return
	end
	local upgrades = selectedList("UpgradeList")
	if #upgrades == 0 then
		return
	end
	for _, upgrade in ipairs(upgrades) do
		if not (session.running and enabled.autoBuySelectedUpgrades) then
			return
		end
		if upgrade == "Jump" then
			setFarmStatus("buying jump upgrade")
			fireSpeedUpgradeSmart()
		elseif upgrade == "Carry" then
			setFarmStatus("buying carry upgrade")
			fire(getRemote("SharedModules", "Network", "Remotes", "Upgrade Carry Limit"))
		end
		task.wait(0.05)
	end
end

local function doAutoUpgradeFloors()
	if not enabled.autoUpgradeFloors then
		return
	end
	if not ready("floors", 1) then
		return
	end
	setFarmStatus("upgrading floors")
	for floorId = 10, 70 do
		if not (session.running and enabled.autoUpgradeFloors) then
			return
		end
		local event = getRemote("SharedModules", "Network", "Remotes", "Purchase Floor")
		call(event, floorId)
	end
end

local function doAutoUpgradeSoccer()
	if not enabled.autoUpgradeSoccer then
		return
	end
	if not ready("soccer", 0.5) then
		return
	end
	local slots = selectedList("SoccerSlot")
	if #slots == 0 then
		return
	end
	for _, slot in ipairs(slots) do
		if not (session.running and enabled.autoUpgradeSoccer) then
			return
		end
		local slotId = tonumber(string.match(slot, "%d+"))
		if slotId then
			setFarmStatus("upgrading soccer " .. slotId)
			fire(getRemote("SharedModules", "Network", "Remotes", "Upgrade Slime"), tostring(slotId))
			task.wait(0.01)
		end
	end
end

local function gearIdFromOption(value)
	return tostring(string.match(tostring(value), "^(%d+)") or "")
end

local function doAutoBuyGear()
	if not enabled.autoBuyGear then
		return
	end
	if not ready("buyGear", 0.5) then
		return
	end
	local gears = selectedList("GearList")
	if #gears == 0 then
		return
	end
	for _, gear in ipairs(gears) do
		if not (session.running and enabled.autoBuyGear) then
			return
		end
		local gearId = gearIdFromOption(gear)
		if gearId ~= "" then
			setFarmStatus("buying gear " .. gearId)
			fire(getRemote("SharedModules", "Network", "Remotes", "Buy Gear"), gearId, "Buy")
			task.wait(0.01)
		end
	end
end

local function doAutoBuyAllGear()
	if not enabled.autoBuyAllGear then
		return
	end
	if not ready("buyAllGear", 0.5) then
		return
	end
	setFarmStatus("buying all gear")
	for _, entry in ipairs(GEAR_SORTED) do
		if not (session.running and enabled.autoBuyAllGear) then
			return
		end
		local money = getMoney()
		if money >= entry[3] then
			setFarmStatus("buying " .. entry[2])
			fire(getRemote("SharedModules", "Network", "Remotes", "Buy Gear"), entry[1], "Buy")
			task.wait(0.05)
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

local FarmTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" })
local UpgradeTab = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "trending-up" })
local ShopTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" })

local FarmInfoBox = box(FarmTab, "Farming Info", "activity", "Right")
FarmInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("FarmRebirthLabel", { Text = paint("Rebirth -", "0", COLORS.orange), DoesWrap = true })
FarmInfoBox:AddLabel("FarmBlocksLabel", { Text = paint("Blocks -", "none", COLORS.user), DoesWrap = true })

local FarmBox = box(FarmTab, "Auto Farm", "star", "Left")
FarmBox:AddDropdown("LuckyBlockSelect", {
	Text = "Select LuckyBlock",
	Values = LUCKY_BLOCKS,
	Multi = true,
	Default = {},
	Callback = function() end,
})
FarmBox:AddDivider()
FarmBox:AddSlider("FarmSpeed", {
	Text = "Steal Speed (s)",
	Min = 0.05,
	Max = 2,
	Default = 0.25,
	Rounding = 2,
	Callback = function() end,
})
FarmBox:AddDivider()
FarmBox:AddToggle("AutoFarm", { Text = "Auto Farm Lucky Blocks", Default = false, Callback = function(value)
	enabled.autoFarm = value
	if not value then
		pcall(function()
			teleportTo(HOME_POSITION)
		end)
	end
end })
FarmBox:AddToggle("AutoCollectCash", { Text = "Auto Collect Cash", Default = false, Callback = function(value)
	enabled.autoCollect = value
end })
FarmBox:AddToggle("AutoOpenBlocks", { Text = "Auto Open Lucky Blocks", Default = false, Callback = function(value)
	enabled.autoOpen = value
end })
FarmBox:AddToggle("AutoSellAll", { Text = "Auto Sell Soccer Players", Default = false, Callback = function(value)
	enabled.autoSellAll = value
end })
FarmBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.autoRebirth = value
end })

local UpgradeInfoBox = box(UpgradeTab, "Upgrade Info", "activity", "Right")
UpgradeInfoBox:AddLabel("UpgradeStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
UpgradeInfoBox:AddLabel("UpgradeSelectedLabel", { Text = paint("Upgrades -", "none", COLORS.user), DoesWrap = true })

local UpgradeBox = box(UpgradeTab, "Upgrades", "zap", "Left")
UpgradeBox:AddDropdown("UpgradeList", {
	Text = "Select Upgrade",
	Values = { "Jump", "Carry" },
	Multi = true,
	Default = {},
	Callback = function() end,
})
UpgradeBox:AddDivider()
UpgradeBox:AddToggle("AutoBuyUpgrades", { Text = "Auto Buy All Upgrades", Default = false, Callback = function(value)
	enabled.autoBuyUpgrades = value
end })
UpgradeBox:AddToggle("AutoBuySelectedUpgrades", { Text = "Auto Buy Selected Upgrades", Default = false, Callback = function(value)
	enabled.autoBuySelectedUpgrades = value
end })

local FloorsSoccerBox = box(UpgradeTab, "Floors & Soccer", "zap", "Right")
FloorsSoccerBox:AddDropdown("SoccerSlot", {
	Text = "Select Soccer",
	Values = (function()
		local options = {}
		for i = 1, 70 do
			table.insert(options, "Soccer " .. i)
		end
		return options
	end)(),
	Multi = true,
	Default = {},
	Callback = function() end,
})
FloorsSoccerBox:AddDivider()
FloorsSoccerBox:AddToggle("AutoUpgradeFloors", { Text = "Auto Upgrade Floors", Default = false, Callback = function(value)
	enabled.autoUpgradeFloors = value
end })
FloorsSoccerBox:AddToggle("AutoUpgradeSoccer", { Text = "Auto Upgrade Soccer", Default = false, Callback = function(value)
	enabled.autoUpgradeSoccer = value
end })

local ShopInfoBox = box(ShopTab, "Shop Info", "activity", "Right")
ShopInfoBox:AddLabel("ShopStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
ShopInfoBox:AddLabel("ShopGearLabel", { Text = paint("Gears -", "none", COLORS.user), DoesWrap = true })

local GearBox = box(ShopTab, "Gear", "shopping-bag", "Left")
GearBox:AddDropdown("GearList", {
	Text = "Select Gear",
	Values = (function()
		local options = {}
		for _, gear in ipairs(GEAR_LIST) do
			table.insert(options, gear[1] .. " - " .. gear[2])
		end
		return options
	end)(),
	Multi = true,
	Default = {},
	Callback = function() end,
})
GearBox:AddDivider()
GearBox:AddToggle("AutoBuyGear", { Text = "Auto Buy Selected Gear", Default = false, Callback = function(value)
	enabled.autoBuyGear = value
end })
GearBox:AddToggle("AutoBuyAllGear", { Text = "Auto Buy All Gear", Default = false, Callback = function(value)
	enabled.autoBuyAllGear = value
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

local function liveActivity()
	if enabled.autoFarm then
		return "Farming Lucky Blocks"
	end
	if enabled.autoCollect then
		return "Collecting Cash"
	end
	if enabled.autoOpen then
		return "Opening Lucky Blocks"
	end
	if enabled.autoSellAll then
		return "Selling Soccer Players"
	end
	if enabled.autoRebirth then
		return "Rebirthing"
	end
	if enabled.autoBuyUpgrades or enabled.autoBuySelectedUpgrades then
		return "Buying Upgrades"
	end
	if enabled.autoUpgradeFloors then
		return "Upgrading Floors"
	end
	if enabled.autoUpgradeSoccer then
		return "Upgrading Soccer"
	end
	if enabled.autoBuyGear or enabled.autoBuyAllGear then
		return "Buying Gear"
	end
	return "idle"
end

local function updateLabels()
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", liveActivity(), COLORS.accent))
	setLabel("FarmRebirthLabel", paint("Rebirth -", tostring(getRebirths()), COLORS.orange))
	local blocks = selectedList("LuckyBlockSelect")
	setLabel("FarmBlocksLabel", paint("Blocks -", #blocks > 0 and tostring(#blocks) .. " selected" or "none", COLORS.user))
	setLabel("UpgradeStatusLabel", paint("Status -", liveActivity(), COLORS.accent))
	local upgrades = selectedList("UpgradeList")
	setLabel("UpgradeSelectedLabel", paint("Upgrades -", #upgrades > 0 and table.concat(upgrades, ", ") or "none", COLORS.user))
	setLabel("ShopStatusLabel", paint("Status -", liveActivity(), COLORS.accent))
	local gears = selectedList("GearList")
	setLabel("ShopGearLabel", paint("Gears -", #gears > 0 and tostring(#gears) .. " selected" or "none", COLORS.user))
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

task.spawn(function()
	while session.running do
		local ok, err = pcall(doAutoFarm)
		if not ok then
			logError(err)
		end
		task.wait(0.05)
	end
end)

chain({ doAutoCollect, doAutoOpen, doAutoSellAll, doAutoRebirth, doAutoBuyAllUpgrades, doAutoBuySelectedUpgrades }, 0.01)
loop(doAutoUpgradeFloors, 0.5)
loop(doAutoUpgradeSoccer, 0.5)
loop(doAutoBuyGear, 0.5)
loop(doAutoBuyAllGear, 0.5)

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
