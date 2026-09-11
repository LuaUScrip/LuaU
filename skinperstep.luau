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
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local copyText = setclipboard or toclipboard or (syn and syn.write_clipboard)
local httpRequest = request or http_request or (syn and syn.request)

local CONFIG = {
	Title = "AntiGodHub",
	Icon = 80985370671515,
	Discord = "https://discord.gg/jdJvZm6VdK",
	Website = "https://rscripts.net/@AntiGodHub",
	Version = "v1.6",
	Folder = "AntiGodHub",
	CornerRadius = 20,
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

local enabled = { equipBestPets = true, noPause = true }
local settings = {
	egg = "",
}
local sessionStart = tick()

local function find(root, ...)
	local node = root
	for index = 1, select("#", ...) do
		node = node and node:FindFirstChild((select(index, ...)))
	end
	return node
end

local function loadModule(...)
	local module = find(ReplicatedStorage, ...)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
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

local function selectedValues(option)
	local chosen = {}
	local value = option and option.Value
	if type(value) == "table" then
		for key, isOn in pairs(value) do
			if isOn then
				chosen[tostring(key)] = true
			end
		end
	end
	return chosen
end

local function toList(set)
	local list = {}
	for value in pairs(set) do
		table.insert(list, value)
	end
	table.sort(list)
	return list
end

local function numberFrom(value)
	if type(value) == "function" then
		return read(value)
	end
	if type(value) == "number" then
		return value
	end
	return nil
end

--// callValue() calls anything callable (function / callable state table / userdata)
local function callValue(value)
	local valueType = type(value)
	if valueType ~= "function" and valueType ~= "userdata" and valueType ~= "table" then
		return nil
	end
	local ok, result = pcall(value)
	if ok then
		return result
	end
	return nil
end

--// ═══════════════════════════════════════════════════════════
--// GAME LOGIC — "+1 Skinny Per Step"
--// ═══════════════════════════════════════════════════════════

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local Resources = ReplicatedStorage:WaitForChild("Resources", 15)
local AutoWinsRoute = ReplicatedStorage:FindFirstChild("AutoWinsRoute")

local BuyEgg = find(Remotes, "Eggs", "BuyEgg")
local EquipBestPets = find(Remotes, "Pets", "EquipBest")
local EggsFolder = find(Resources, "Eggs")
local RebirthRequest = ReplicatedStorage:WaitForChild("RebirthRequest", 15)
local TrailEquipRequest = ReplicatedStorage:WaitForChild("TrailEquipRequest", 15)
local TeleportRequest = ReplicatedStorage:WaitForChild("TeleportRequest", 15)

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

local function attr(name, default)
	local value = LocalPlayer:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function getLevel()
	return tonumber(attr("Level", 1)) or 1
end

local function getWins()
	return tonumber(attr("Wins", 0)) or 0
end

local function getRebirths()
	return tonumber(attr("Rebirths", 0)) or 0
end

local function getCurrentWorld()
	return tonumber(attr("CurrentWorld", 1)) or 1
end

--// Rebirth requirement (real curve from the game):
--// rebirths <= 30 -> (rebirths + 1) * 25; after 30 -> 775 + 9 * (rebirths - 30)
local function requiredRebirthLevel(rebirths)
	if rebirths <= 30 then
		return (rebirths + 1) * 25
	end
	return 775 + (rebirths - 30) * 9
end

--// Ownership attributes are stored as CSV strings ("RedTrail,BlueTrail,...")
local function csvOwns(csv, name)
	return ("," .. tostring(csv or "") .. ","):find("," .. name .. ",", 1, true) ~= nil
end

local function ownsTrail(name)
	return csvOwns(attr("OwnedTrails", ""), name)
end

--// The game has 7 worlds
local MAX_WORLDS = 7

--// World unlock requirements (rebirths needed to teleport there)
local WORLD_REBIRTHS = {
	[1] = 0,
	[2] = 14,
	[3] = 29,
	[4] = 49,
	[5] = 69,
	[6] = 89,
	[7] = 169,
}

--// Trails ordered by cost; Speed = the walkspeed each trail grants
local TRAIL_ORDER = {
	{ Name = "WhiteTrail", Cost = 5, Speed = 17 },
	{ Name = "RedTrail", Cost = 100, Speed = 22 },
	{ Name = "BlueTrail", Cost = 1000, Speed = 25 },
	{ Name = "YellowTrail", Cost = 50000, Speed = 28 },
	{ Name = "GreenTrail", Cost = 500000, Speed = 31 },
	{ Name = "PurpleTrail", Cost = 1000000, Speed = 35 },
	{ Name = "RainbowTrail", Cost = 10000000, Speed = 40 },
	{ Name = "AuroraTrail", Cost = 50000000, Speed = 45 },
	{ Name = "LavaTrail", Cost = 100000000, Speed = 50 },
	{ Name = "BeachTrail", Cost = 1000000000, Speed = 54 },
	{ Name = "ObsidianTrail", Cost = 1e12, Speed = 59 },
	{ Name = "DiamondTrail", Cost = 1e15, Speed = 65 },
}

--// WIN PADS (two sources, route first):
--//   1. AutoWinsRoute/W1..W7 — Vector3Value children named by level
--//   2. Fallback — Workspace WinZoneLevel* models: level requirement is in the
--//      name ("WinZoneLevel300Model" = W1, "WinZoneLevel300ModelW4" = W4) and
--//      TouchWin sits inside the WinModel child
local function bestPadFromRoute(world, level)
	local folder = AutoWinsRoute and AutoWinsRoute:FindFirstChild("W" .. tostring(world))
	if not folder then
		return nil
	end
	local bestLevel, bestPos = -1, nil
	for _, child in ipairs(folder:GetChildren()) do
		local padLevel = tonumber(child.Name)
		if padLevel and child:IsA("Vector3Value") and padLevel <= level and padLevel > bestLevel then
			bestLevel = padLevel
			bestPos = child.Value
		end
	end
	if not bestPos then
		return nil
	end
	return bestLevel, bestPos
end

local function bestPadFromWorkspace(world, level)
	local bestLevel, bestPos = -1, nil
	for _, model in ipairs(Workspace:GetChildren()) do
		local name = model.Name
		local padLevel = tonumber(name:match("^WinZoneLevel(%d+)Model"))
		if padLevel and padLevel <= level and padLevel > bestLevel then
			local zoneWorld = tonumber(name:match("ModelW(%d+)$")) or 1
			if zoneWorld == world then
				local touch = model:FindFirstChild("TouchWin", true)
				if touch and touch:IsA("BasePart") then
					bestLevel = padLevel
					bestPos = touch.Position
				else
					bestLevel = padLevel
					bestPos = model:GetPivot().Position
				end
			end
		end
	end
	if not bestPos then
		return nil
	end
	return bestLevel, bestPos
end

--// Best (highest) pad inside ONE world that the player's level can reach
local function bestPadInWorld(world)
	local level = getLevel()
	local routeLevel, routePos = bestPadFromRoute(world, level)
	if routeLevel then
		return routeLevel, routePos
	end
	return bestPadFromWorkspace(world, level)
end

--// ALWAYS "Best" — scans ALL 7 worlds but ONLY counts pads in worlds you can
--// legally reach (your current world + worlds unlocked by rebirths), so Auto Win
--// never stalls waiting on a locked world. Ties prefer staying in the current
--// world (no pointless teleports between worlds with equal pads).
local function resolveWinTarget()
	local currentWorld = getCurrentWorld()
	local rebirths = getRebirths()
	local bestWorld, bestLevel, bestPos = nil, -1, nil
	for world = 1, MAX_WORLDS do
		if world == currentWorld or rebirths >= (WORLD_REBIRTHS[world] or 0) then
			local padLevel, padPos = bestPadInWorld(world)
			if padLevel and (padLevel > bestLevel or (padLevel == bestLevel and world == currentWorld)) then
				bestWorld, bestLevel, bestPos = world, padLevel, padPos
			end
		end
	end
	if not bestWorld then
		return nil
	end
	return bestWorld, bestLevel, bestPos
end

local worldTeleportAt = 0

--// SAFETY: fires the world teleport only when the rebirth requirement is met
--// and at most once every 2s (the loop would otherwise spam the remote)
local function ensureWorld(world)
	if getCurrentWorld() == world then
		return true
	end
	local need = WORLD_REBIRTHS[world] or 0
	if getRebirths() < need then
		return false
	end
	if os.clock() - worldTeleportAt < 2 then
		return false
	end
	worldTeleportAt = os.clock()
	fire(TeleportRequest, world)
	return false
end

local function findWinTouch(world, level)
	local name
	if world == 1 then
		name = "WinZoneLevel" .. level .. "Model"
	else
		name = "WinZoneLevel" .. level .. "ModelW" .. world
	end
	local zone = Workspace:FindFirstChild(name)
	if not zone then
		return nil
	end
	return zone:FindFirstChild("TouchWin", true)
end

local lastPadTouchAt = 0

local function retriggerWinTouch(touch)
	local root = getRoot()
	if not root or not touch or not touch:IsA("BasePart") then
		return
	end
	if not firetouchinterest then
		return
	end
	if os.clock() - lastPadTouchAt < 0.2 then
		return
	end
	lastPadTouchAt = os.clock()
	pcall(firetouchinterest, root, touch, 0)
	pcall(firetouchinterest, root, touch, 1)
end

--// Auto Win — TELEPORT mode: snaps straight onto the best pad's TouchWin part
--// (no walking, no control takeover), then retriggers the touch so the server
--// registers the win. If the best reachable pad lives in another unlocked world,
--// ensureWorld teleports there first (gated by rebirths + 2s throttle).
local function autoWinStep()
	local world, level, position = resolveWinTarget()
	if not world or not position then
		return
	end
	if getCurrentWorld() ~= world then
		ensureWorld(world)
		return
	end

	local root = getRoot()
	if not root then
		return
	end

	local touch = findWinTouch(world, level)
	local target = touch and touch.Position or position
	root.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	retriggerWinTouch(touch)
end

--// TREADMILLS: Workspace models named "*Treadmill" with Multiplier /
--// RequiredRebirths attributes; stand on the Conveyor part to train
local function isTreadmillModel(inst)
	return inst:IsA("Model") and inst.Name:find("Treadmill") and inst.Name ~= "TreadmillsGUI"
end

local function treadmillLabel(model)
	local name = model.Name
	if string.sub(name, -9) == "Treadmill" then
		name = string.sub(name, 1, -10)
	end
	return (string.gsub(name, "GoldenCrown", " Golden Crown"))
end

local function isRobuxTreadmill(model)
	if model.Name == "WoodenTreadmill" then
		return false
	end
	if (tonumber(model:GetAttribute("RequiredRebirths")) or 0) == 0 then
		return true
	end
	if string.find(model.Name, "GoldenCrown", 1, true) then
		return true
	end
	return model:FindFirstChild("RobuxAmountNeedToUnlockGUI", true) ~= nil
end

local function treadmillStand(model)
	local conveyor = model:FindFirstChild("Conveyor", true)
	if conveyor and conveyor:IsA("BasePart") then
		return conveyor
	end
	if model.PrimaryPart then
		return model.PrimaryPart
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function getTreadmills()
	local list = {}
	for _, model in ipairs(Workspace:GetChildren()) do
		if isTreadmillModel(model) then
			local stand = treadmillStand(model)
			if stand then
				list[#list + 1] = {
					Model = model,
					Label = treadmillLabel(model),
					Required = tonumber(model:GetAttribute("RequiredRebirths")) or 0,
					Multiplier = tonumber(model:GetAttribute("Multiplier")) or 0,
					Conveyor = stand,
				}
			end
		end
	end
	table.sort(list, function(a, b)
		if a.Multiplier ~= b.Multiplier then
			return a.Multiplier > b.Multiplier
		end
		return a.Label < b.Label
	end)
	return list
end

--// SAFETY: gamepass treadmills only count as unlocked when the flag attribute
--// is actually set; rebirth treadmills compare against RequiredRebirths
local function treadmillUnlocked(entry)
	local name = entry.Model.Name
	if name == "HackerTreadmill" then
		return attr("HasHacker", false) == true
	end
	if name == "GalaxyTreadmill" then
		return attr("HasGalaxy", false) == true
	end
	if name == "LavaTreadmill" then
		return attr("HasLava", false) == true
	end
	if name == "UFOTreadmill" then
		return attr("HasUFO", false) == true
	end
	if name == "AngelTreadmill" then
		return attr("HasAngel", false) == true
	end
	if string.find(name, "GoldenCrown", 1, true) then
		return attr("HasVIP", false) == true
	end
	return getRebirths() >= entry.Required
end

--// ALWAYS "Best": highest-multiplier treadmill that is unlocked and not Robux-gated
local function resolveTreadmill()
	for _, entry in ipairs(getTreadmills()) do
		if not isRobuxTreadmill(entry.Model) and treadmillUnlocked(entry) then
			return entry
		end
	end
	return nil
end

local function teleportToPart(part)
	local root = getRoot()
	if not root or not part then
		return
	end
	root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
end

local function getBuyPrompt(model)
	local prompt = model:FindFirstChild("BuyPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		return prompt
	end
	return nil
end

local function fireBuyPrompt(model)
	local prompt = getBuyPrompt(model)
	if not prompt then
		return false
	end
	local part = prompt.Parent
	if part and part:IsA("BasePart") then
		teleportToPart(part)
		task.wait(0.1)
	end
	if fireproximityprompt then
		pcall(fireproximityprompt, prompt)
		return true
	end
	pcall(function()
		prompt:InputHoldBegin()
		task.wait(0.05)
		prompt:InputHoldEnd()
	end)
	return true
end

--// FOODS: food models (Apple1Thin, Carrot10Thin, RainbowApple, ...) are NESTED
--// in the Workspace, so we scan GetDescendants (cached, refreshed every 5s) for
--// Models with a RequiredWins attribute + a BuyPrompt.
--// Ownership / equipped state is name-format agnostic: model names may appear in
--// OwnedFruits / EquippedItem as "Apple1Thin", "Apple1" or "Apple", so every
--// variant is checked.
local FoodCache = {}

local function foodNameVariants(name)
	local variants = { name }
	local base = name:gsub("Thin$", "")
	if base ~= name then
		table.insert(variants, base)
	end
	local noDigits = name:gsub("%d+$", "")
	if noDigits ~= name then
		table.insert(variants, noDigits)
	end
	local noDigitsThin = base:gsub("%d+$", "")
	if noDigitsThin ~= base then
		table.insert(variants, noDigitsThin)
	end
	return variants
end

local function ownsFoodName(name)
	local csv = attr("OwnedFruits", "")
	for _, variant in ipairs(foodNameVariants(name)) do
		if csvOwns(csv, variant) then
			return true
		end
	end
	return false
end

local function equippedFoodName(name, equipped)
	for _, variant in ipairs(foodNameVariants(name)) do
		if equipped == variant then
			return true
		end
	end
	return false
end

local function buildFoodCache()
	local list = {}
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("Model") and inst:GetAttribute("RequiredWins") ~= nil then
			local req = tonumber(inst:GetAttribute("RequiredWins"))
			if req and req == req and req ~= math.huge and inst:FindFirstChild("BuyPrompt", true) then
				list[#list + 1] = {
					Model = inst,
					Name = inst.Name,
					Required = req,
				}
			end
		end
	end
	table.sort(list, function(a, b)
		if a.Required ~= b.Required then
			return a.Required < b.Required
		end
		return a.Name < b.Name
	end)
	FoodCache = list
end

local lastFoodActionAt = 0
local lastEquipAttempt = ""
local lastEquipAttemptAt = 0

--// Auto Buy & Equip Best Food:
--//   1. Buys the best affordable food you DON'T own — but ONLY if it's an
--//      upgrade (better than the best food you already own)
--//   2. Equips the best owned food when EquippedItem doesn't match it
--//   3. SAFETY: if the best owned food is ALREADY equipped and there's nothing
--//      better to buy -> does NOTHING: no teleport, no prompt fire, no repeat buy
--//   4. Equip attempts are remembered for 10s so a mismatched EquippedItem name
--//      can never cause an infinite teleport/prompt loop
local function autoBuyFoodsOnce()
	if #FoodCache == 0 or ready("foodscan", 5) then
		buildFoodCache()
	end
	if os.clock() - lastFoodActionAt < 1.5 then
		return
	end
	local wins = getWins()
	local equipped = tostring(attr("EquippedItem", "") or "")
	local buyTarget = nil
	local bestOwned = nil
	for _, food in ipairs(FoodCache) do
		if ownsFoodName(food.Name) then
			if not bestOwned or food.Required > bestOwned.Required then
				bestOwned = food
			end
		elseif wins >= food.Required then
			if not buyTarget or food.Required > buyTarget.Required then
				buyTarget = food
			end
		end
	end
	--// only an UPGRADE is worth buying (better than the best food we already own)
	if buyTarget and bestOwned and buyTarget.Required <= bestOwned.Required then
		buyTarget = nil
	end
	--// SAFETY: best owned already equipped AND nothing better to buy -> idle
	if not buyTarget and bestOwned and equippedFoodName(bestOwned.Name, equipped) then
		return
	end
	if buyTarget then
		lastFoodActionAt = os.clock()
		fireBuyPrompt(buyTarget.Model)
		return
	end
	if bestOwned
		and not equippedFoodName(bestOwned.Name, equipped)
		and not (lastEquipAttempt == bestOwned.Name and os.clock() - lastEquipAttemptAt < 10)
	then
		lastFoodActionAt = os.clock()
		lastEquipAttempt = bestOwned.Name
		lastEquipAttemptAt = os.clock()
		fireBuyPrompt(bestOwned.Model)
	end
end

--// EGGS: Resources/Eggs children each hold a Cost value; BuyEgg is a RemoteFunction
local function buildEggValues()
	local values = {}
	if not EggsFolder then
		return values
	end
	local entries = {}
	for _, egg in ipairs(EggsFolder:GetChildren()) do
		local cost = egg:FindFirstChild("Cost")
		local amount = cost and tonumber(cost.Value) or 0
		if amount > 0 then
			entries[#entries + 1] = { Name = egg.Name, Cost = amount }
		end
	end
	table.sort(entries, function(a, b)
		return a.Cost < b.Cost
	end)
	for _, entry in ipairs(entries) do
		values[#values + 1] = entry.Name
	end
	return values
end

local function eggCost(name)
	local egg = EggsFolder and EggsFolder:FindFirstChild(name)
	local cost = egg and egg:FindFirstChild("Cost")
	return cost and tonumber(cost.Value) or 0
end

--// Auto Train — ALWAYS the best unlocked treadmill; once OnTreadmill is true it
--// only corrects position when it drifts off the conveyor
local function autoTrainOnce()
	local entry = resolveTreadmill()
	if not entry then
		return
	end
	if attr("OnTreadmill", false) == true then
		local root = getRoot()
		if root and (root.Position - entry.Conveyor.Position).Magnitude > 14 then
			teleportToPart(entry.Conveyor)
		end
		return
	end
	teleportToPart(entry.Conveyor)
end

local function autoRebirthOnce()
	local rebirths = getRebirths()
	local need = requiredRebirthLevel(rebirths)
	if getLevel() < need then
		return
	end
	fire(RebirthRequest)
end

--// Trails: buys the most expensive affordable trail, then equips the fastest owned
local function autoBuyTrailsOnce()
	local wins = getWins()
	local bestOwned = nil
	local bestSpeed = -1
	for _, trail in ipairs(TRAIL_ORDER) do
		if ownsTrail(trail.Name) then
			if trail.Speed > bestSpeed then
				bestSpeed = trail.Speed
				bestOwned = trail.Name
			end
		elseif wins >= trail.Cost then
			fire(TrailEquipRequest, trail.Name)
			task.wait(0.15)
			if ownsTrail(trail.Name) and trail.Speed > bestSpeed then
				bestSpeed = trail.Speed
				bestOwned = trail.Name
			end
		end
	end
	local equipped = tostring(attr("EquippedTrail", "") or "")
	if bestOwned and equipped ~= bestOwned then
		fire(TrailEquipRequest, bestOwned)
	end
end

--// Auto Hatch — fixed 0.2s pacing (loop interval), hatches the selected egg from
--// the dropdown when you can afford it, optionally re-equips best pets
local function autoHatchOnce()
	local eggName = settings.egg
	if type(eggName) ~= "string" or eggName == "" then
		return
	end
	local egg = EggsFolder and EggsFolder:FindFirstChild(eggName)
	if not egg then
		return
	end
	if getWins() < eggCost(eggName) then
		return
	end
	local result = call(BuyEgg, egg)
	if result and enabled.equipBestPets then
		fire(EquipBestPets)
	end
end

local function applyAntiGameplayPause(enabledState)
	pcall(function()
		GuiService:SetGameplayPausedNotificationEnabled(not enabledState)
	end)
	pcall(function()
		local notification = CoreGui:FindFirstChild("RobloxNetworkPauseNotification")
		if notification then
			notification.Enabled = not enabledState
		end
	end)
	if not enabledState then
		return
	end
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(LocalPlayer, "GameplayPaused", false)
		else
			LocalPlayer.GameplayPaused = false
		end
	end)
end

local function autoNoGameplayPause()
	applyAntiGameplayPause(true)
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

local function setAutoReconnect(state)
	if state then
		task.spawn(function()
			while session.running and enabled.autoReconnect do
				if not LocalPlayer.Parent then
					pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
					break
				end
				task.wait(1)
			end
		end)
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

local function formatDuration(seconds)
	seconds = math.floor(seconds)
	if seconds < 60 then
		return string.format("%ds", seconds)
	end
	return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
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
		{ Text = "+1 Skinny Per Step", Copyable = true },
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

local gameName = "Unknown"
pcall(function()
	gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)
local job = game.JobId ~= "" and game.JobId or "N/A"
local jobShort = string.sub(job, 1, 18) .. (string.len(job) > 18 and "..." or "")

local UserBox = box(Tabs.Info, "", "user", "Left")
UserBox:AddPlayerInfo("InfoAvatar", { ThumbnailType = "Bust", Height = 190 })
UserBox:AddDivider()
UserBox:AddLabel("UserLabel", { Text = paint("User -", LocalPlayer.DisplayName, COLORS.user) })
UserBox:AddLabel("UserIdLabel", { Text = paint("UserId -", LocalPlayer.UserId, COLORS.accent) })
UserBox:AddLabel("ExecutorLabel", { Text = paint("Executor -", executorText, COLORS.orange) })
UserBox:AddDivider()
UserBox:AddLabel("SessionTime", { Text = paint("Session -", "0s", COLORS.orange) })
UserBox:AddButton({ Text = "Copy ID", Func = function()
	if copyText then
		copyText(tostring(LocalPlayer.UserId))
	end
end })

local ServerBox = box(Tabs.Info, "Session", "activity", "Right")
ServerBox:AddLabel("GameLabel", { Text = paint("Game -", gameName, COLORS.accent) })
ServerBox:AddLabel("PlayersLabel", { Text = paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user) })
ServerBox:AddLabel("JobLabel", { Text = paint("Job -", jobShort, COLORS.gold) })
ServerBox:AddDivider()
ServerBox:AddButton({ Text = "Rejoin Server", Func = rejoinServer })
ServerBox:AddButton({ Text = "Server Hop (Lowest Players)", Func = serverHop })
ServerBox:AddButton({ Text = "Copy Job ID", Func = function()
	if copyText then
		copyText(game.JobId)
	end
end })

local SocialsBox = box(Tabs.Info, "Socials", "link", "Right")
SocialsBox:AddButton({ Text = "Copy Discord Invite", Func = function()
	if copyText then
		copyText(CONFIG.Discord)
	end
end })
SocialsBox:AddButton({ Text = "Copy Website", Func = function()
	if copyText then
		copyText(CONFIG.Website)
	end
end })

pcall(function()
	Tabs.Main:SetSubTabAlignment("Center")
end)

local FarmTab = Tabs.Main:AddSubTab({ Name = "Farm", Icon = "star" })

local FarmingBox = box(FarmTab, "Farming", "star", "Left")
FarmingBox:AddToggle("AutoWin", { Text = "Auto Win (Teleport)", Default = false, Callback = function(value)
	enabled.win = value
end })
FarmingBox:AddToggle("AutoTrain", { Text = "Auto Train", Default = false, Callback = function(value)
	enabled.train = value
end })
FarmingBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })

local EggsValues = buildEggValues()
if #EggsValues == 0 then
	EggsValues = { "Common" }
end
settings.egg = EggsValues[1] or ""

--// Pets group sits BELOW the Farming group (left column)
local PetsBox = box(FarmTab, "Pets", "paw-print", "Left")
--// EGG DROPDOWN first
PetsBox:AddDropdown("HatchEgg", {
	Text = "Egg",
	Values = EggsValues,
	Default = settings.egg,
	Tooltip = "Auto Hatch buys this egg when you have enough wins",
	Callback = function(value)
		settings.egg = value or ""
	end,
})
--// Auto Hatch below the dropdown
PetsBox:AddToggle("AutoHatch", { Text = "Auto Hatch Pets", Default = false, Callback = function(value)
	enabled.hatch = value
end })
PetsBox:AddToggle("AutoEquipBestPets", { Text = "Auto Equip Best Pets", Default = true, Callback = function(value)
	enabled.equipBestPets = value
end })

local ShopBox = box(FarmTab, "Shop", "shopping-cart", "Right")
ShopBox:AddToggle("AutoBuyTrail", { Text = "Auto Buy Best Trail", Default = false, Callback = function(value)
	enabled.trails = value
end })
ShopBox:AddToggle("AutoBuyFoods", { Text = "Auto Buy & Equip Best Food", Default = false, Callback = function(value)
	enabled.foods = value
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
		Library:SetNotifySide(value)
	end,
})
MenuBox:AddDropdown("DPIScale", {
	Text = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Callback = function(value)
		Library:SetDPIScale(tonumber((value:gsub("%%", ""))))
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
	setAntiAfk(value)
end })
ClientBox:AddToggle("AutoReconnectToggle", { Text = "Auto Reconnect", Default = false, Callback = function(value)
	enabled.autoReconnect = value
	setAutoReconnect(value)
end })
ClientBox:AddToggle("DisableRendering", { Text = "Disable 3D Rendering", Default = false, Callback = function(value)
	setRendering(value)
end })
ClientBox:AddToggle("FpsBoost", { Text = "FPS Boost", Default = false, Callback = function(value)
	setFpsBoost(value)
end })
ClientBox:AddToggle("AntiGameplayPause", { Text = "No Gameplay Paused", Default = true, Callback = function(value)
	enabled.noPause = value
	applyAntiGameplayPause(value)
end })

local ServerTools = box(Tabs.Settings, "Server", "server", "Right")
ServerTools:AddButton({ Text = "Reconnect", Func = reconnectServer })
ServerTools:AddButton({ Text = "Rejoin Server", Func = rejoinServer })
ServerTools:AddButton({ Text = "Server Hop (Lowest Players)", Func = serverHop })

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

--// "Dark Silver" monochrome theme
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
ThemeManager:ApplyTheme("Dark Silver") --// default look; user can still switch themes in the dropdown
ThemeManager:ApplyToTab(Tabs.Settings)
Tabs.Settings.AddGroupbox = SettingsAddGroupbox

--// Remove the "Contrast check" label that ThemeManager adds
pcall(function()
	ThemeManager.UpdateContrastWarning = function() end --// nothing re-renders it
	local ContrastLabel = ThemeManager.ContrastLabel
	if ContrastLabel and not ContrastLabel.Destroyed and type(ContrastLabel.Destroy) == "function" then
		ContrastLabel:Destroy()
	end
	ThemeManager.ContrastLabel = nil
end)

local function updateLabels()
	if not ready("labels", 1) then
		return
	end
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("PlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
end

local function refreshLists()
	if ready("eggs", 15) then
		pcall(function()
			local eggs = buildEggValues()
			if #eggs > 0 then
				Options.HatchEgg:SetValues(eggs)
				if settings.egg == "" then
					settings.egg = eggs[1]
					Options.HatchEgg:SetValue(eggs[1])
				end
			end
		end)
	end
end

--// ═══════════════════════════════════════════════════════════
--// LOOPS — every toggle runs in its OWN loop with its OWN speed.
--// To change a feature's speed, edit the task.wait(<seconds>) at
--// the bottom of its loop below. That's it — no other changes needed.
--// ═══════════════════════════════════════════════════════════

local function loop(name, func, interval)
	task.spawn(function()
		while session.running do
			if enabled[name] then
				func()
			end
			task.wait(interval)
		end
	end)
end

--// Auto Win (Teleport) — 0.1s (touch retrigger throttled to 0.2s inside)
loop("win", autoWinStep, 0.1)
--// Auto Train — 0.35s
loop("train", autoTrainOnce, 0.35)
--// Auto Rebirth — 1s
loop("rebirth", autoRebirthOnce, 1)
--// Auto Buy Best Trail — 1s
loop("trails", autoBuyTrailsOnce, 1)
--// Auto Buy & Equip Best Food — 1.25s (cache rescans every 5s, action throttle 1.5s,
--// idle when the best owned food is already equipped)
loop("foods", autoBuyFoodsOnce, 1.25)
--// Auto Hatch — fixed 0.2s
loop("hatch", autoHatchOnce, 0.2)
--// No Gameplay Paused — 1s
loop("noPause", autoNoGameplayPause, 1)

--// UI refresh (labels + dropdown lists) — 1s, always runs, not tied to a toggle
task.spawn(function()
	while session.running do
		updateLabels()
		refreshLists()
		task.wait(1)
	end
end)

Library:OnUnload(function()
	session.running = false
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	applyAntiGameplayPause(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()