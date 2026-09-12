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
local VirtualInputManager = game:GetService("VirtualInputManager")
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
	GameName = "Steal Lucky Egg",
}

local HOME_POSITION = Vector3.new(157, 4, -31)
local CHECK_POSITION = Vector3.new(-3038, 4, -36)
local PROMPT_RANGE = 7

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

local timers = {}
local function ready(key, interval)
	local now = tick()
	if now - (timers[key] or 0) < interval then
		return false
	end
	timers[key] = now
	return true
end

local SUFFIX_LIST = {"", "K", "M", "B", "T", "qd", "Qn", "sx", "Sp", "O", "N", "de", "Ud", "DD", "tdD", "qdD", "QnD", "sxD", "SpD", "OcD", "NvD", "Vgn", "UVg", "DVg", "TVg", "qtV", "QnV", "SeV", "SPG", "OVG", "NVG", "TGN", "UTG", "DTG", "tsTG", "qtTG", "QnTG", "ssTG", "SpTG", "OcTG", "NoAG", "UnAG", "DuAG", "TeAG", "QdAG", "QnAG", "SxAG", "SpAG", "OcAG", "NvAG", "CT"}

local SUFFIX_EXPONENTS = {}
for index, suffix in ipairs(SUFFIX_LIST) do
	SUFFIX_EXPONENTS[string.lower(suffix)] = (index - 1) * 3
end

local function abbreviateNumber(value)
	value = tonumber(value) or 0
	local negative = value < 0
	if negative then
		value = -value
	end
	if value < 1000 then
		return (negative and "-" or "") .. string.format("%.0f", value)
	end
	local exponent = math.floor(math.log(value, 1000))
	exponent = math.min(exponent, 11)
	local scaled = value / (1000 ^ exponent)
	if scaled >= 999.95 and exponent < 11 then
		exponent = exponent + 1
		scaled = value / (1000 ^ exponent)
	end
	local text
	if scaled >= 100 then
		text = string.format("%.0f", scaled)
	else
		text = string.format("%.1f", scaled)
		if string.sub(text, -2) == ".0" then
			text = string.sub(text, 1, -3)
		end
	end
	return (negative and "-" or "") .. text .. SUFFIX_LIST[exponent + 1]
end

local function parseAmount(text)
	if type(text) ~= "string" then
		return nil
	end
	text = text:gsub("<.->", ""):gsub(",", ""):gsub("%$", "")
	local num, suffix = string.match(text, "([%d%.]+)%s*([%a]*)")
	num = tonumber(num)
	if not num then
		return nil
	end
	if suffix == "" then
		return num
	end
	local exponent = SUFFIX_EXPONENTS[string.lower(suffix)]
	if not exponent then
		return nil
	end
	return num * (10 ^ exponent)
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

local TreadmillToggle = waitRemote("TreadmillToggle")
local Rebirth = waitRemote("Rebirth")
local UpgradeBase = waitRemote("UpgradeBase")
local UpgradeCharacter = waitRemote("UpgradeCharacter")
local Sell = waitRemote("Sell")
local BuyTrail = waitRemote("BuyTrail")
local ClaimIndexRewards = waitRemote("ClaimIndexRewards")

local ClientModules = find(ReplicatedStorage, "ClientModules")
local function requireClientModule(name)
	local module = ClientModules and ClientModules:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local BaseUpgradeCosts = requireClientModule("BaseUpgradeModule")
local RebirthModule = requireClientModule("RebirthModule")
local CharactersModule = requireClientModule("CharactersModule")
local RaritiesModule = requireClientModule("RaritiesModule")
local TrailsModule = requireClientModule("TrailsModule")

local EGG_RARITY_BY_NAME = {}
local NORMALIZED_EGG_RARITY = {}
do
	if CharactersModule then
		for key, config in pairs(CharactersModule) do
			local rarity = type(config) == "table" and config.Rarity or nil
			if type(rarity) == "string" and rarity ~= "" then
				EGG_RARITY_BY_NAME[key] = rarity
				if config.IsEgg ~= true then
					EGG_RARITY_BY_NAME[key .. " Egg"] = rarity
				end
				local normalized = string.lower((string.gsub(key, "[^%w]", "")))
				if normalized ~= "" and NORMALIZED_EGG_RARITY[normalized] == nil then
					NORMALIZED_EGG_RARITY[normalized] = rarity
				end
				local eggNormalized = string.lower((string.gsub(key .. " Egg", "[^%w]", "")))
				if eggNormalized ~= "" and NORMALIZED_EGG_RARITY[eggNormalized] == nil then
					NORMALIZED_EGG_RARITY[eggNormalized] = rarity
				end
			end
		end
	end
end

local function getSpeedXP()
	return tonumber(LocalPlayer:GetAttribute("Speed")) or 0
end

local function getRebirthCount()
	return tonumber(LocalPlayer:GetAttribute("Rebirths")) or 0
end

-- ===== Live cash resolver: attribute -> leaderstats -> HUD $ label (best effort) =====
local cashValue, cashSource, cashAt = 0, "none", 0

local function attributeCash()
	local names = LocalPlayer:GetAttributes()
	for _, name in ipairs(names) do
		if name == "Cash" then
			local value = tonumber(LocalPlayer:GetAttribute(name))
			if value then
				return value, "attribute " .. name
			end
		end
	end
	for _, name in ipairs(names) do
		local lower = string.lower(name)
		if string.find(lower, "cash", 1, true) and not string.find(lower, "pending", 1, true) then
			local value = tonumber(LocalPlayer:GetAttribute(name))
			if value then
				return value, "attribute " .. name
			end
		end
	end
	return nil
end

local function leaderstatCash()
	local stats = LocalPlayer:FindFirstChild("leaderstats")
	if not stats then
		return nil
	end
	local child = stats:FindFirstChild("Cash") or stats:FindFirstChild("Cash/s")
	if child then
		local ok, value = pcall(function()
			return tonumber(child.Value)
		end)
		if ok and value then
			return value, "leaderstats " .. child.Name
		end
	end
	return nil
end

local function labelCash()
	local gui = LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then
		return nil
	end
	local named, namedValue
	local best, bestValue
	for _, item in ipairs(gui:GetDescendants()) do
		if (item:IsA("TextLabel") or item:IsA("TextButton")) and item.Visible then
			local text = item.Text
			if type(text) == "string" and string.find(text, "$", 1, true) then
				local value = parseAmount(text)
				if value then
					local path = string.lower(item.Name) .. " " .. (item.Parent and string.lower(item.Parent.Name) or "")
					if string.find(path, "cash", 1, true) or string.find(path, "money", 1, true) then
						if not namedValue or value > namedValue then
							named, namedValue = item, value
						end
					elseif not bestValue or value > bestValue then
						best, bestValue = item, value
					end
				end
			end
		end
	end
	local source = named or best
	if source then
		return (named and namedValue or bestValue), "gui " .. source.Name
	end
	return nil
end

local function rescanCash(force)
	if not force and tick() - cashAt < 0.5 then
		return cashValue
	end
	cashAt = tick()
	local value, source = attributeCash()
	if not value then
		value, source = leaderstatCash()
	end
	if not value then
		value, source = labelCash()
	end
	if value then
		cashValue, cashSource = value, source or "unknown"
	end
	return cashValue
end

local function getCash()
	return rescanCash(false)
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

local function playerSpawned()
	local character = getCharacter()
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
end

local function teleportTo(position)
	local root = getRoot()
	if root and position then
		root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		return true
	end
	return false
end

local function teleportHome()
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(HOME_POSITION)
		return true
	end
	return false
end

local function teleportCheck()
	local root = getRoot()
	if root then
		root.CFrame = CFrame.new(CHECK_POSITION)
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

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local RARITY_LIST = {}
local RARITY_ORDER = {}
do
	local entries = {}
	for name, config in pairs(RaritiesModule or {}) do
		entries[#entries + 1] = {name = name, order = tonumber(config.Order) or 0}
	end
	table.sort(entries, function(a, b)
		return a.order < b.order
	end)
	for index, entry in ipairs(entries) do
		RARITY_LIST[#RARITY_LIST + 1] = entry.name
		RARITY_ORDER[entry.name] = index
	end
	if #RARITY_LIST == 0 then
		RARITY_LIST = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Celestial", "Divine", "Exclusive", "OG"}
		for index, name in ipairs(RARITY_LIST) do
			RARITY_ORDER[name] = index
		end
	end
end

local RARITY_VALUES = {}
for _, name in ipairs(RARITY_LIST) do
	RARITY_VALUES[#RARITY_VALUES + 1] = name
end

local DEFAULT_RARITIES = {}
do
	local minOrder = RARITY_ORDER["Secret"] or 1
	for _, name in ipairs(RARITY_LIST) do
		if RARITY_ORDER[name] >= minOrder then
			DEFAULT_RARITIES[#DEFAULT_RARITIES + 1] = name
		end
	end
	if #DEFAULT_RARITIES == 0 then
		for _, name in ipairs(RARITY_LIST) do
			DEFAULT_RARITIES[#DEFAULT_RARITIES + 1] = name
		end
	end
end

local selectedRarities = {}

local function syncRarities(list)
	selectedRarities = {}
	if type(list) == "table" then
		for key, value in pairs(list) do
			if type(key) == "number" and type(value) == "string" then
				selectedRarities[value] = true
			elseif type(key) == "string" and value == true then
				selectedRarities[key] = true
			end
		end
	end
	if next(selectedRarities) == nil then
		for _, name in ipairs(RARITY_LIST) do
			selectedRarities[name] = true
		end
	end
end

local eggCooldown = {}

local eggsContainerCache

local function eggsContainer()
	if eggsContainerCache and eggsContainerCache.Parent then
		return eggsContainerCache
	end
	eggsContainerCache = nil
	local direct = Workspace:FindFirstChild("Eggs")
	if direct then
		eggsContainerCache = direct
		return direct
	end
	local ok, found = pcall(function()
		return Workspace:FindFirstChild("Eggs", true)
	end)
	if ok and found then
		eggsContainerCache = found
	end
	return eggsContainerCache
end

local function eggRarity(holder)
	if not holder then
		return nil
	end
	local attr = holder:GetAttribute("Rarity")
	if type(attr) == "string" and attr ~= "" then
		return attr
	end
	local mapped = EGG_RARITY_BY_NAME[holder.Name]
	if mapped then
		return mapped
	end
	local base = string.match(holder.Name, "^(.-)%s*Egg$") or holder.Name
	mapped = EGG_RARITY_BY_NAME[base]
	if mapped then
		return mapped
	end
	return NORMALIZED_EGG_RARITY[string.lower((string.gsub(holder.Name, "[^%w]", "")))]
		or NORMALIZED_EGG_RARITY[string.lower((string.gsub(base, "[^%w]", "")))]
end

local function holderFor(prompt)
	local node = prompt.Parent
	for _ = 1, 6 do
		if not node or node == Workspace then
			break
		end
		if EGG_RARITY_BY_NAME[node.Name] or node:GetAttribute("Rarity") or string.match(node.Name, "Egg$") then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function promptAnchorPosition(prompt, holder)
	local anchor = prompt.Parent
	if anchor and anchor:IsA("BasePart") then
		return anchor.Position
	end
	for _, descendant in ipairs(holder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant.Position
		end
	end
	return safePivot(holder)
end

local function pickEgg()
	local eggsRoot = eggsContainer()
	if not eggsRoot then
		setFarmStatus("no eggs folder")
		return nil
	end
	local now = tick()
	local best, bestOrder, bestDistance
	for _, prompt in ipairs(eggsRoot:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") then
			local holder = holderFor(prompt)
			if holder then
				local cooldown = eggCooldown[holder]
				if not cooldown or cooldown <= now then
					local rarity = eggRarity(holder)
					if rarity and selectedRarities[rarity] then
						local position = promptAnchorPosition(prompt, holder)
						if position then
							local order = RARITY_ORDER[rarity] or 0
							local distance = (position - CHECK_POSITION).Magnitude
							if not best
								or order > bestOrder
								or (order == bestOrder and distance < bestDistance) then
								best = {egg = holder, name = holder.Name, rarity = rarity, prompt = prompt, position = position}
								bestOrder = order
								bestDistance = distance
							end
						end
					end
				end
			end
		end
	end
	return best
end

local function promptPosition(prompt)
	local part = prompt and prompt.Parent
	if not part then
		return nil
	end
	if part:IsA("BasePart") then
		return part.Position
	end
	return safePivot(part)
end

local function pinAtPrompt(entry)
	local prompt = entry.prompt
	if not prompt or not prompt.Parent then
		return nil
	end
	local position = promptPosition(prompt) or entry.position
	if not position then
		return nil
	end
	local root = getRoot()
	if not root then
		return nil
	end
	root.Anchored = false
	local standPoint = position + Vector3.new(0, 2.5, 0)
	local target = CFrame.lookAt(standPoint, position)
	root.CFrame = target
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	local connection = RunService.Heartbeat:Connect(function()
		if root.Parent then
			root.CFrame = target
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
	local deadline = tick() + 0.4
	while tick() < deadline do
		task.wait(0.05)
	end
	entry.standDistance = (root.Position - position).Magnitude
	local maxDistance = tonumber(prompt.MaxActivationDistance) or PROMPT_RANGE
	return {
		ok = entry.standDistance <= maxDistance,
		release = function()
			if connection then
				connection:Disconnect()
				connection = nil
			end
			pcall(function()
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
		end,
	}
end

local function firePrompt(prompt)
	if not prompt then
		return false
	end
	pcall(function()
		prompt.RequiresLineOfSight = false
	end)
	local holdDuration = tonumber(prompt.HoldDuration) or 0
	pcall(function()
		prompt.HoldDuration = 0
	end)
	local keyCode = Enum.KeyCode.E
	pcall(function()
		if prompt.KeyboardKeyCode then
			keyCode = prompt.KeyboardKeyCode
		end
	end)
	local fired = false
	if fireproximityprompt then
		fired = pcall(fireproximityprompt, prompt)
	end
	if not fired then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		end)
		task.wait(math.clamp(holdDuration + 0.05, 0.05, 1))
		pcall(function()
			VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
		end)
	end
	pcall(prompt.InputHoldBegin, prompt)
	if holdDuration > 0 then
		task.wait(math.clamp(holdDuration, 0, 1))
	end
	pcall(prompt.InputHoldEnd, prompt)
	pcall(function()
		prompt.HoldDuration = holdDuration
	end)
	return true
end

local function isHoldingEgg()
	return (tonumber(LocalPlayer:GetAttribute("Holding")) or 0) > 0
end

local function doStealEgg()
	if not enabled.steal then
		return
	end
	if isHoldingEgg() then
		setFarmStatus("returning egg")
		teleportHome()
		task.wait(0.2)
		if not isHoldingEgg() then
			eggCooldown = {}
			setFarmStatus("delivered")
		end
		return
	end
	if not playerSpawned() then
		return
	end
	teleportCheck()
	task.wait(0.15)
	if not enabled.steal or not session.running or not playerSpawned() then
		return
	end
	local entry = pickEgg()
	if not entry then
		setFarmStatus("no egg")
		return
	end
	setFarmStatus("steal " .. entry.rarity)
	teleportTo(entry.position)
	if not enabled.steal or not session.running or not playerSpawned() then
		return
	end
	local grabbed = false
	for _ = 1, 6 do
		if isHoldingEgg() then
			grabbed = true
			break
		end
		if not entry.prompt.Parent or not enabled.steal then
			break
		end
		local pin = pinAtPrompt(entry)
		if pin then
			if pin.ok then
				firePrompt(entry.prompt)
			end
			pin.release()
		else
			task.wait(0.1)
		end
		local deadline = tick() + 0.4
		while tick() < deadline do
			if isHoldingEgg() then
				grabbed = true
				break
			end
			task.wait(0.03)
		end
		if grabbed then
			break
		end
	end
	if grabbed then
		eggCooldown[entry.egg] = nil
		setFarmStatus("got " .. entry.rarity)
	else
		local maxDistance = (entry.prompt and tonumber(entry.prompt.MaxActivationDistance)) or PROMPT_RANGE
		local inRange = (entry.standDistance or math.huge) <= maxDistance
		setFarmStatus(string.format("steal %s (%.1fu %s)", entry.rarity, entry.standDistance or -1, inRange and "in range" or "too far"))
		eggCooldown[entry.egg] = tick() + 2
	end
	teleportHome()
	task.wait(0.1)
end

local function treadmillRunning()
	return LocalPlayer:GetAttribute("TreadmillEquipped") == true
end

local myBase, myBaseAt = nil, 0

local function baseOwnedByMe(base)
	local ownerPart = base and base:FindFirstChild("OwnerPart")
	local gui = ownerPart and ownerPart:FindFirstChildOfClass("BillboardGui")
	local label = gui and gui:FindFirstChild("PlayerName")
	if label and label:IsA("TextLabel") then
		local text = label.Text
		return text == LocalPlayer.Name or text == LocalPlayer.DisplayName
	end
	return false
end

local function findMyBase()
	if myBase and myBase.Parent and tick() - myBaseAt < 10 then
		return myBase
	end
	myBaseAt = tick()
	myBase = nil
	local bases = find(Workspace, "Bases")
	if not bases then
		return nil
	end
	for _, base in ipairs(bases:GetChildren()) do
		if baseOwnedByMe(base) then
			myBase = base
			break
		end
	end
	return myBase
end

local function findTreadmill()
	local treadmills = find(Workspace, "Treadmills")
	if not treadmills then
		return nil
	end
	local base = findMyBase()
	if not base then
		return nil
	end
	local mine = treadmills:FindFirstChild(base.Name)
	local active = mine and mine:FindFirstChild("ActiveTreadmill")
	if active and active:FindFirstChild("HRP") then
		return active
	end
	return nil
end

local function doAutoTrain()
	if not enabled.train or enabled.steal or not TreadmillToggle then
		return
	end
	local treadmill = findTreadmill()
	local hrp = treadmill and treadmill:FindFirstChild("HRP")
	if not hrp then
		return
	end
	local spot = topSurface(hrp) or safePivot(hrp)
	local root = getRoot()
	if not spot or not root then
		return
	end
	if (root.Position - spot).Magnitude > 6 then
		teleportTo(spot)
		task.wait(0.15)
		return
	end
	setFarmStatus(treadmillRunning() and "training" or "waiting treadmill")
end

local function doAutoRebirth()
	if not enabled.rebirth or not Rebirth then
		return
	end
	if not ready("rebirth", 2) then
		return
	end
	local nextRequirement = RebirthModule and RebirthModule[getRebirthCount() + 1]
	local required = nextRequirement and tonumber(nextRequirement.SpeedXP)
	if required and getSpeedXP() < required then
		return
	end
	setFarmStatus("rebirth")
	fire(Rebirth)
end

local function doUpgradeBase()
	if not enabled.base or not UpgradeBase then
		return
	end
	local base = findMyBase()
	if not base then
		return
	end
	if not ready("baseup", 2) then
		return
	end
	local level = tonumber(base:GetAttribute("Level") or base:GetAttribute("BaseLevel"))
	local cost
	if BaseUpgradeCosts then
		if level then
			cost = tonumber(BaseUpgradeCosts[level + 1])
		else
			cost = tonumber(BaseUpgradeCosts[1])
		end
	end
	local cash = getCash()
	if cost and cash > 0 and cash < cost then
		return
	end
	setFarmStatus("upgrade base")
	fire(UpgradeBase, base)
end

local function doUpgradePets()
	if not enabled.pets or not UpgradeCharacter then
		return
	end
	local base = findMyBase()
	local slots = base and base:FindFirstChild("Slots")
	if not slots then
		return
	end
	if not ready("petsup", 2) then
		return
	end
	for _, slot in ipairs(slots:GetChildren()) do
		if slot:GetAttribute("SlotState") == "Character" then
			setFarmStatus("upgrade pets")
			fire(UpgradeCharacter, base, slot)
			task.wait(0.1)
		end
	end
end

local function doAutoSell()
	if not enabled.sell or not Sell then
		return
	end
	if not ready("sell", 3) then
		return
	end
	setFarmStatus("selling pets")
	fire(Sell, 1)
end

local boughtTrails = {}

local function doAutoTrail()
	if not enabled.trail or not BuyTrail or not TrailsModule then
		return
	end
	if not ready("trail", 2) then
		return
	end
	local cash = getCash()
	local currentMultiplier = tonumber(LocalPlayer:GetAttribute("TrailMultiplier")) or 1
	local bestIndex, bestMultiplier
	for index, config in ipairs(TrailsModule) do
		local cost = tonumber(config.Cost) or math.huge
		local multiplier = tonumber(config.Multiplier) or 0
		if cost <= cash and multiplier > currentMultiplier and not boughtTrails[config.Name] then
			if not bestMultiplier or multiplier > bestMultiplier then
				bestIndex, bestMultiplier = index, multiplier
			end
		end
	end
	if bestIndex then
		local config = TrailsModule[bestIndex]
		setFarmStatus("buy trail " .. tostring(config.Name))
		fire(BuyTrail, bestIndex, "Cash")
		boughtTrails[config.Name] = true
		task.wait(0.5)
	end
end

local function doClaimIndex()
	if not enabled.index or not ClaimIndexRewards then
		return
	end
	if not ready("claimindex", 30) then
		return
	end
	setFarmStatus("claim index")
	fire(ClaimIndexRewards)
end

local function clearTraps()
	local traps = find(Workspace, "PlacedBearTraps")
	if not traps then
		return
	end
	for _, trap in ipairs(traps:GetChildren()) do
		pcall(trap.Destroy, trap)
	end
end

local function doAntiTrap()
	if not enabled.antitrap then
		return
	end
	clearTraps()
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

local LiveLabels = {}

local function addLabel(parentBox, key, text)
	local label = parentBox:AddLabel(key, { Text = text, DoesWrap = true })
	LiveLabels[key] = label
	return label
end

local function setLabel(key, text)
	local label = LiveLabels[key]
	if label and type(label.SetText) == "function" then
		pcall(label.SetText, label, text)
		return
	end
	pcall(function()
		local fallback = Library.Labels and Library.Labels[key]
		if fallback and type(fallback.SetText) == "function" then
			fallback:SetText(text)
		end
	end)
end

local UserBox = box(Tabs.Info, "Account", "user", "Left")
UserBox:AddPlayerInfo("InfoAvatar", { ThumbnailType = "Bust", Height = 190 })
UserBox:AddDivider()
addLabel(UserBox, "UserLabel", paint("User -", LocalPlayer.DisplayName, COLORS.user))
addLabel(UserBox, "UserIdLabel", paint("UserId -", LocalPlayer.UserId, COLORS.accent))
addLabel(UserBox, "ExecutorLabel", paint("Executor -", executorText, COLORS.orange))
UserBox:AddDivider()
addLabel(UserBox, "SessionTime", paint("Session -", "0s", COLORS.orange))
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
addLabel(GameBox, "GameNameLabel", paint("Game -", CONFIG.GameName, COLORS.accent))
addLabel(GameBox, "ServerPlayersLabel", paint("Players -", "0/0", COLORS.user))
addLabel(GameBox, "ServerIdLabel", paint("Server -", string.sub(game.JobId ~= "" and game.JobId or "N/A", 1, 18), COLORS.orange))
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
FarmBox:AddToggle("AutoSteal", { Text = "Steal Egg", Default = false, Callback = function(value)
	enabled.steal = value
	eggCooldown = {}
	if value then
		enabled.train = false
		pcall(function()
			Options.AutoTrain:Set(false)
		end)
	end
end })
FarmBox:AddDropdown("StealRarity", {
	Text = "Select Rarity",
	Values = RARITY_VALUES,
	Default = DEFAULT_RARITIES,
	Multi = true,
	Callback = function(list)
		syncRarities(list)
	end,
})
FarmBox:AddDivider()
FarmBox:AddToggle("AutoTrain", { Text = "Auto Train", Default = false, Callback = function(value)
	enabled.train = value
	if value then
		enabled.steal = false
		eggCooldown = {}
		pcall(function()
			Options.AutoSteal:Set(false)
		end)
	else
		fire(TreadmillToggle, false)
	end
end })
FarmBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })
FarmBox:AddToggle("AntiTrap", { Text = "Anti Trap", Default = false, Callback = function(value)
	enabled.antitrap = value
	if value then
		clearTraps()
	end
end })
syncRarities(Options.StealRarity and Options.StealRarity.Value)

local StatusBox = box(FarmingTab, "Game Info", "activity", "Right")
addLabel(StatusBox, "FarmStatusLabel", paint("Status -", "idle", COLORS.accent))
addLabel(StatusBox, "CashLabel", paint("Cash -", "0", COLORS.gold))
addLabel(StatusBox, "SpeedXPLabel", paint("Speed -", "0", COLORS.user))
addLabel(StatusBox, "RebirthLabel", paint("Rebirths -", "0", COLORS.orange))

local UpgradeBox = box(ShopTab, "Upgrades", "hammer", "Left")
UpgradeBox:AddToggle("AutoBase", { Text = "Upgrade Base", Default = false, Callback = function(value)
	enabled.base = value
end })
UpgradeBox:AddToggle("AutoPets", { Text = "Upgrade Pets", Default = false, Callback = function(value)
	enabled.pets = value
end })
UpgradeBox:AddToggle("AutoTrail", { Text = "Buy Best Trail", Default = false, Callback = function(value)
	enabled.trail = value
end })

local SellBox = box(ShopTab, "Selling", "coins", "Right")
SellBox:AddToggle("AutoSell", { Text = "Sell All", Default = false, Callback = function(value)
	enabled.sell = value
end })

local IndexBox = box(ShopTab, "Index", "book-open", "Right")
IndexBox:AddToggle("AutoIndex", { Text = "Claim Index", Default = false, Callback = function(value)
	enabled.index = value
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
	setLabel("CashLabel", paint("Cash -", abbreviateNumber(rescanCash(true)), COLORS.gold))
	setLabel("SpeedXPLabel", paint("Speed -", abbreviateNumber(getSpeedXP()), COLORS.user))
	setLabel("RebirthLabel", paint("Rebirths -", getRebirthCount(), COLORS.orange))
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

chain({ doStealEgg }, 0.05)
chain({ doAutoTrain, doAutoRebirth }, 0.3)
loop(doUpgradeBase, 0.3)
loop(doUpgradePets, 0.3)
loop(doAutoSell, 0.3)
loop(doAutoTrail, 0.3)
loop(doClaimIndex, 0.3)
loop(doAntiTrap, 0.2)

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
syncRarities(Options.StealRarity and Options.StealRarity.Value)
rescanCash(true)