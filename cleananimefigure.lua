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
	GameName = "Clean the Anime Figures: Map 2",
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

local AnimeShelfFolder
do
	local ok, folder = pcall(function()
		return ReplicatedStorage:WaitForChild("AnimeShelfRemotes", 10)
	end)
	AnimeShelfFolder = ok and folder or nil
end

local function waitRemoteIn(root, name)
	if not root then
		return nil
	end
	local instance = root:FindFirstChild(name) or root:FindFirstChild(name, true)
	if instance then
		return instance
	end
	local ok, waited = pcall(function()
		return root:WaitForChild(name, 10)
	end)
	return ok and waited or nil
end

local CrystalFolder = find(ReplicatedStorage, "CrystalTree", "Remotes")
local FigurePetFolder = ReplicatedStorage:FindFirstChild("FigurePetRemotes")
local FreeRewardFolder = ReplicatedStorage:FindFirstChild("FreeRewardRemotes")

local ActionRequest = waitRemoteIn(AnimeShelfFolder, "ActionRequest")
local AbilityActivate = waitRemoteIn(AnimeShelfFolder, "AbilityActivate")
local PurchaseNode = waitRemoteIn(CrystalFolder, "PurchaseNode")
local SelectAbility = waitRemoteIn(CrystalFolder, "SelectAbility")
local PurchaseAbilityUpgrade = waitRemoteIn(CrystalFolder, "PurchaseAbilityUpgrade")
local PurchaseAbilitySlot = waitRemoteIn(CrystalFolder, "PurchaseAbilitySlot")
local SetAbilityLoadout = waitRemoteIn(CrystalFolder, "SetAbilityLoadout")
local PetSpin = waitRemoteIn(FigurePetFolder, "Spin")
local PetSetEquipped = waitRemoteIn(FigurePetFolder, "SetEquipped")
local PetGetState = waitRemoteIn(FigurePetFolder, "GetState")
local PetClaimPity = waitRemoteIn(FigurePetFolder, "ClaimPity")
local PetPurchaseThirdSlot = waitRemoteIn(FigurePetFolder, "PurchaseThirdSlot")
local FreeClaim = waitRemoteIn(FreeRewardFolder, "Claim")

local function requireModule(module)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local CrystalDefinition = requireModule(find(ReplicatedStorage, "CrystalTree", "Definition"))
local PetDefinitions = requireModule(ReplicatedStorage:FindFirstChild("FigurePetDefinitions"))

local function getMoney()
	return tonumber(LocalPlayer:GetAttribute("Money")) or 0
end

local function getCrystals()
	return tonumber(LocalPlayer:GetAttribute("Crystals")) or 0
end

local function getCarry()
	return tonumber(LocalPlayer:GetAttribute("CarryCount")) or 0
end

local function getMaxFigures()
	return tonumber(LocalPlayer:GetAttribute("MaxFigures")) or tonumber(LocalPlayer:GetAttribute("BaseMaxFigures")) or 1
end

local function getPickupRange()
	if LocalPlayer:GetAttribute("InfiniteRange") == true then
		return 1e5
	end
	return tonumber(LocalPlayer:GetAttribute("PickupRange")) or 12
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

local ABILITY_LIST = {"Observation Haki", "Blood Manipulation", "Thunder Breathing", "Jackpot", "Unseen Hand", "Spatial Awareness", "Arise"}
local ABILITY_IDS = {
	["Observation Haki"] = "ObservationHaki",
	["Blood Manipulation"] = "Blood",
	["Thunder Breathing"] = "ThunderBreathing",
	["Jackpot"] = "Jackpot",
	["Unseen Hand"] = "UnseenHand",
	["Spatial Awareness"] = "SpatialAwareness",
	["Arise"] = "Arise",
}
local ABILITY_UPGRADE_TYPES = {"Duration", "Cooldown", "Special 1", "Special 2"}
local ACTIVATE_SLOTS = {"Slot 1", "Slot 2", "Slot 3"}
local CRYSTAL_UPGRADES = {
	"Yen Boost", "Row Auto-Place", "Assistant Speed", "Inventory Discount", "Speed Discount",
	"Reach Discount", "Final Row Crystal", "Final Row Yen Multiplier", "First Row Instant Fill",
	"Improved Row Scaling", "Assistant Duration", "Speed Max Level", "Reach Max Level",
}
local SPIN_MODES = {"Free", "Lucky"}

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

local function multiValues(optionName)
	local selected = Options[optionName] and Options[optionName].Value
	local list = {}
	if type(selected) == "string" then
		table.insert(list, selected)
	elseif type(selected) == "table" then
		for key, active in pairs(selected) do
			if type(key) == "string" and active then
				table.insert(list, key)
			elseif type(key) == "number" and type(active) == "string" then
				table.insert(list, active)
			end
		end
	end
	return list
end

local slotsByType = {}
local allSlots = {}
local displayToTypeCache = {}

local function buildCaches()
	slotsByType = {}
	allSlots = {}
	displayToTypeCache = {}
	local shelves = find(Workspace, "Shelves")
	if shelves then
		for _, shelf in ipairs(shelves:GetChildren()) do
			for _, descendant in ipairs(shelf:GetDescendants()) do
				if descendant:IsA("BasePart") and string.find(string.lower(descendant.Name), "slot", 1, true) then
					local figureType = descendant:GetAttribute("FigureType")
					if figureType then
						slotsByType[figureType] = slotsByType[figureType] or {}
						table.insert(slotsByType[figureType], descendant)
						table.insert(allSlots, descendant)
					end
				end
			end
		end
	end
	local templates = ReplicatedStorage:FindFirstChild("AnimeShelfTemplates")
	if templates then
		for _, template in ipairs(templates:GetChildren()) do
			local displayName = template:GetAttribute("DisplayName")
			if displayName then
				displayToTypeCache[string.lower(displayName)] = template.Name
			end
			displayToTypeCache[string.lower(template.Name)] = template.Name
		end
	end
end

buildCaches()

do
	local shelves = find(Workspace, "Shelves")
	if shelves then
		pcall(function()
			shelves.ChildAdded:Connect(function()
				task.defer(buildCaches)
			end)
		end)
	end
end

local function groundFiguresFolder()
	return find(Workspace, "GroundFigures")
end

local function scanFigures()
	local root = getRoot()
	local folder = groundFiguresFolder()
	if not root or not folder then
		return nil, math.huge
	end
	local range = getPickupRange()
	local target, targetDistance, nearest, nearestDistance
	for _, model in ipairs(folder:GetChildren()) do
		if model:GetAttribute("FigureState") == "Ground" and model:FindFirstChild("PickupAimHitbox", true) then
			local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
			if part then
				local distance = (part.Position - root.Position).Magnitude
				if not target and distance <= range then
					target, targetDistance = model, distance
				end
				if not nearestDistance or distance < nearestDistance then
					nearestDistance, nearest = distance, model
				end
			end
		end
	end
	if target then
		return target, targetDistance
	end
	return nearest, nearestDistance or math.huge
end

local function getHeldFigureType()
	local label
	pcall(function()
		local gui = find(LocalPlayer, "PlayerGui", "AnimeStoreUI", "CurrentFigure", "Name")
		label = gui and gui.Text
	end)
	if type(label) ~= "string" or label == "" then
		return nil
	end
	local cached = displayToTypeCache[string.lower(label)]
	if cached then
		return cached
	end
	local templates = ReplicatedStorage:FindFirstChild("AnimeShelfTemplates")
	if templates then
		for _, template in ipairs(templates:GetChildren()) do
			local displayName = template:GetAttribute("DisplayName")
			if displayName and string.lower(displayName) == string.lower(label) then
				displayToTypeCache[string.lower(label)] = template.Name
				return template.Name
			end
		end
	end
	return label
end

local function findSlotForHeldType(heldType)
	local list = heldType and slotsByType[heldType]
	if not list then
		return nil
	end
	local root = getRoot()
	local best, bestDistance = nil, math.huge
	for _, slot in ipairs(list) do
		if slot:GetAttribute("Occupied") == false then
			local distance = root and (slot.Position - root.Position).Magnitude or 0
			if distance < bestDistance then
				best, bestDistance = slot, distance
			end
		end
	end
	return best
end

local function findEmptyShelfSlot()
	for _, slot in ipairs(allSlots) do
		if slot:GetAttribute("Occupied") == false then
			return slot
		end
	end
	return nil
end

local function nearestPlacementTarget()
	local root = getRoot()
	local folder = find(Workspace, "LocalPlacementRowTargets")
	if not root or not folder then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, part in ipairs(folder:GetChildren()) do
		if part:IsA("BasePart") then
			local distance = (part.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = part, distance
			end
		end
	end
	return best
end

local placeIdCounter = 0

local function tryPickup()
	if not ActionRequest then
		return false
	end
	local figure, distance = scanFigures()
	if not figure then
		return false
	end
	if distance > getPickupRange() then
		local part = figure.PrimaryPart or figure:FindFirstChildWhichIsA("BasePart", true)
		local root = getRoot()
		if part and root then
			root.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
		end
	end
	fire(ActionRequest, "PickupFigure", figure)
	return true
end

local function tryPlace()
	if not ActionRequest or getCarry() <= 0 then
		return false
	end
	local heldType = getHeldFigureType()
	local slot = findSlotForHeldType(heldType) or findEmptyShelfSlot() or nearestPlacementTarget()
	if not slot then
		return false
	end
	local root = getRoot()
	if root and (slot.Position - root.Position).Magnitude > 12 then
		root.CFrame = CFrame.new(slot.Position + Vector3.new(0, 5, 2))
	end
	placeIdCounter += 1
	fire(ActionRequest, "PlaceFigure", slot, placeIdCounter)
	return true
end

local function doAutoClean()
	if not enabled.clean then
		return
	end
	setFarmStatus("cleaning figures")
	if getCarry() < getMaxFigures() then
		tryPickup()
	else
		tryPlace()
	end
end

local function doAutoStats()
	if not enabled.stats then
		return
	end
	if not ready("stats", 1) then
		return
	end
	local did = false
	if enabled.upHold then
		fire(ActionRequest, "UpgradeCarry")
		did = true
	end
	if enabled.upSpeed then
		fire(ActionRequest, "UpgradeMovement")
		did = true
	end
	if enabled.upReach then
		fire(ActionRequest, "UpgradeReach")
		did = true
	end
	if did then
		setFarmStatus("buying stat upgrades")
	end
end

local function doAutoCrystal()
	if not enabled.crystal or not PurchaseNode or type(CrystalDefinition) ~= "table" then
		return
	end
	if not ready("crystal", 1) then
		return
	end
	local keywords = multiValues("CrystalUpgrades")
	if #keywords == 0 then
		return
	end
	local nodes = CrystalDefinition.Nodes
	if type(nodes) ~= "table" then
		return
	end
	setFarmStatus("buying crystal nodes")
	for id, node in pairs(nodes) do
		if type(node) == "table" and node.DisplayName then
			for _, keyword in ipairs(keywords) do
				if string.find(string.lower(node.DisplayName), string.lower(keyword), 1, true) then
					call(PurchaseNode, id)
					task.wait(0.15)
					break
				end
			end
		end
	end
end

local function selectedAbilityId()
	local selected = Options.SelectedAbility and Options.SelectedAbility.Value or ABILITY_LIST[1]
	return ABILITY_IDS[selected] or selected
end

local function doAutoAbilitySelect()
	if not enabled.abilitySelect or not SelectAbility then
		return
	end
	if not ready("abilitySelect", 2) then
		return
	end
	setFarmStatus("selecting ability")
	call(SelectAbility, selectedAbilityId())
end

local function doAutoAbilityActivate()
	if not enabled.abilityActivate or not AbilityActivate then
		return
	end
	if not ready("abilityActivate", 1) then
		return
	end
	local slotText = Options.ActivateSlot and Options.ActivateSlot.Value or ACTIVATE_SLOTS[1]
	local slot = tonumber(string.match(slotText, "%d+")) or 1
	setFarmStatus("activating ability")
	call(AbilityActivate, slot)
end

local function doAutoAbilityUpgrade()
	if not enabled.abilityUpgrade or not PurchaseAbilityUpgrade then
		return
	end
	if not ready("abilityUpgrade", 1) then
		return
	end
	local id = selectedAbilityId()
	local types = multiValues("AbilityUpgradeTypes")
	setFarmStatus("upgrading ability")
	for _, upgradeType in ipairs(types) do
		call(PurchaseAbilityUpgrade, id, upgradeType)
		call(PurchaseAbilityUpgrade, upgradeType, id)
		call(PurchaseAbilityUpgrade, id .. "_" .. upgradeType)
	end
end

local function doAutoAbilitySlot()
	if not enabled.abilitySlot or not PurchaseAbilitySlot then
		return
	end
	if not ready("abilitySlot", 2) then
		return
	end
	setFarmStatus("buying ability slot")
	call(PurchaseAbilitySlot)
end

local function doAutoSpinPets()
	if not enabled.spinPets or not PetSpin then
		return
	end
	if not ready("spinPets", 1) then
		return
	end
	local mode = Options.SpinMode and Options.SpinMode.Value or SPIN_MODES[1]
	if type(mode) == "table" then
		mode = SPIN_MODES[1]
	end
	setFarmStatus("spinning pets")
	call(PetSpin, {Mode = mode, Count = 1})
end

local function doAutoEquipPets()
	if not enabled.equipPets or not PetSetEquipped or type(PetDefinitions) ~= "table" then
		return
	end
	if not ready("equipPets", 2) then
		return
	end
	local order = PetDefinitions.Order
	if type(order) ~= "table" then
		return
	end
	local best = {}
	for index = #order, 1, -1 do
		table.insert(best, order[index])
	end
	local state = call(PetGetState)
	if type(state) == "table" and type(state.Inventory) == "table" then
		local filtered = {}
		for _, id in ipairs(best) do
			local count = state.Inventory[id]
			if type(count) == "number" and count > 0 then
				table.insert(filtered, id)
			end
		end
		if #filtered > 0 then
			best = filtered
		end
	end
	local toEquip = {}
	for index = 1, math.min(2, #best) do
		table.insert(toEquip, best[index])
	end
	if #toEquip > 0 then
		setFarmStatus("equipping best pets")
		call(PetSetEquipped, toEquip)
	end
end

local function doAutoClaimPity()
	if not enabled.pity or not PetClaimPity then
		return
	end
	if not ready("pity", 2) then
		return
	end
	setFarmStatus("claiming pet pity")
	call(PetClaimPity, {Track = "Free"})
	call(PetClaimPity, {Track = "Lucky"})
end

local function doAutoPetSlot()
	if not enabled.petSlot or not PetPurchaseThirdSlot then
		return
	end
	if not ready("petSlot", 3) then
		return
	end
	setFarmStatus("buying pet slot")
	call(PetPurchaseThirdSlot)
end

local function doAutoFreeReward()
	if not enabled.freeReward or not FreeClaim then
		return
	end
	if LocalPlayer:GetAttribute("FreeCrystalRewardAvailable") ~= true then
		return
	end
	setFarmStatus("claiming free reward")
	call(FreeClaim)
end

local function doAutoHire()
	if not enabled.hire then
		return
	end
	if not ready("hire", 5) then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "HirePrompt" and descendant.Enabled then
			local part = descendant.Parent
			if part and (part.Position - root.Position).Magnitude > (descendant.MaxActivationDistance or 10) then
				teleportTo(part.Position)
				task.wait(0.2)
			end
			if fireproximityprompt then
				pcall(fireproximityprompt, descendant)
			end
			setFarmStatus("hiring assistant")
			return
		end
	end
end

local function resetNow()
	if not ActionRequest then
		return
	end
	setFarmStatus("resetting run")
	fire(ActionRequest, "ResetRun")
end

local function doAutoResetRun()
	if not enabled.resetRun then
		return
	end
	if not ready("resetRun", 5) then
		return
	end
	resetNow()
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
	Main = Window:AddTab({ Name = "Main", Icon = "star" }),
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
local UpgradesTab = Tabs.Main:AddSubTab({ Name = "Upgrades", Icon = "trending-up" })
local AbilitiesTab = Tabs.Main:AddSubTab({ Name = "Abilities", Icon = "zap" })
local PetsTab = Tabs.Main:AddSubTab({ Name = "Pets", Icon = "paw-print" })
local RebirthTab = Tabs.Main:AddSubTab({ Name = "Rebirth", Icon = "refresh-cw" })

local FarmBox = box(FarmingTab, "Farming", "star", "Left")
FarmBox:AddToggle("AutoCleanFigures", { Text = "Auto Clean", Default = false, Callback = function(value)
	enabled.clean = value
end })
FarmBox:AddToggle("AutoClaimFreeReward", { Text = "Claim Free Crystal", Default = false, Callback = function(value)
	enabled.freeReward = value
end })

local StatusBox = box(FarmingTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("MoneyLabel", { Text = paint("Money -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("CrystalsLabel", { Text = paint("Crystals -", "0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("FiguresLabel", { Text = paint("Figures -", "0/0", COLORS.orange), DoesWrap = true })

local StatsBox = box(UpgradesTab, "Stat Upgrades", "arrow-up", "Left")
StatsBox:AddToggle("AutoUpgradeHold", { Text = "Auto Upgrade Hold Capacity", Default = false, Callback = function(value)
	enabled.upHold = value
	enabled.stats = enabled.upHold or enabled.upSpeed or enabled.upReach
end })
StatsBox:AddToggle("AutoUpgradeSpeed", { Text = "Auto Upgrade Walk Speed", Default = false, Callback = function(value)
	enabled.upSpeed = value
	enabled.stats = enabled.upHold or enabled.upSpeed or enabled.upReach
end })
StatsBox:AddToggle("AutoUpgradeReach", { Text = "Auto Upgrade Pickup Reach", Default = false, Callback = function(value)
	enabled.upReach = value
	enabled.stats = enabled.upHold or enabled.upSpeed or enabled.upReach
end })

local CrystalBox = box(UpgradesTab, "Crystal Tree", "hexagon", "Right")
CrystalBox:AddDropdown("CrystalUpgrades", { Text = "Auto Purchase Crystal Upgrades", Values = CRYSTAL_UPGRADES, Default = 1, Multi = true })
CrystalBox:AddToggle("AutoPurchaseCrystal", { Text = "Auto Purchase Crystal Nodes", Default = false, Callback = function(value)
	enabled.crystal = value
end })

local AbilityBox = box(AbilitiesTab, "Ability Control", "sparkles", "Left")
AbilityBox:AddDropdown("SelectedAbility", { Text = "Select Ability", Values = ABILITY_LIST, Default = 1 })
AbilityBox:AddToggle("AutoSelectAbility", { Text = "Auto Select Ability", Default = false, Callback = function(value)
	enabled.abilitySelect = value
end })
AbilityBox:AddDropdown("ActivateSlot", { Text = "Activate Slot", Values = ACTIVATE_SLOTS, Default = 1 })
AbilityBox:AddToggle("AutoActivateAbility", { Text = "Auto Activate Ability", Default = false, Callback = function(value)
	enabled.abilityActivate = value
end })

local AbilityUpgradeBox = box(AbilitiesTab, "Ability Upgrades", "arrow-up-circle", "Right")
AbilityUpgradeBox:AddDropdown("AbilityUpgradeTypes", { Text = "Upgrade Types", Values = ABILITY_UPGRADE_TYPES, Default = 1, Multi = true })
AbilityUpgradeBox:AddToggle("AutoUpgradeAbility", { Text = "Auto Upgrade Ability", Default = false, Callback = function(value)
	enabled.abilityUpgrade = value
end })
AbilityUpgradeBox:AddToggle("AutoPurchaseSlot", { Text = "Auto Purchase Ability Slot", Default = false, Callback = function(value)
	enabled.abilitySlot = value
end })

local SpinBox = box(PetsTab, "Figure Pets", "dices", "Left")
SpinBox:AddDropdown("SpinMode", { Text = "Spin Mode", Values = SPIN_MODES, Default = 1 })
SpinBox:AddToggle("AutoSpinPets", { Text = "Auto Spin Figure Pets", Default = false, Callback = function(value)
	enabled.spinPets = value
end })

local PetShopBox = box(PetsTab, "Shop & Hiring", "store", "Right")
PetShopBox:AddToggle("AutoEquipBestPets", { Text = "Auto Equip Best Figure Pets", Default = false, Callback = function(value)
	enabled.equipPets = value
end })
PetShopBox:AddToggle("AutoClaimPity", { Text = "Auto Claim Lucky Pity Reward", Default = false, Callback = function(value)
	enabled.pity = value
end })
PetShopBox:AddToggle("AutoPurchaseThirdSlot", { Text = "Auto Purchase Third Pet Slot", Default = false, Callback = function(value)
	enabled.petSlot = value
end })
PetShopBox:AddDivider()
PetShopBox:AddToggle("AutoHire", { Text = "Auto Hire Assistant", Default = false, Callback = function(value)
	enabled.hire = value
end })

local ResetBox = box(RebirthTab, "Run Control", "rotate-ccw", "Left")
ResetBox:AddToggle("AutoResetRun", { Text = "Auto Reset Run", Default = false, Callback = function(value)
	enabled.resetRun = value
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
	setLabel("MoneyLabel", paint("Money -", abbreviateNumber(getMoney()), COLORS.gold))
	setLabel("CrystalsLabel", paint("Crystals -", abbreviateNumber(getCrystals()), COLORS.user))
	setLabel("FiguresLabel", paint("Figures -", getCarry() .. "/" .. getMaxFigures(), COLORS.orange))
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

chain({ doAutoClean }, 0.1)
chain({ doAutoFreeReward }, 1)
chain({ doAutoResetRun }, 5)
loop(doAutoStats, 1)
loop(doAutoCrystal, 1)
loop(doAutoAbilitySelect, 1)
loop(doAutoAbilityActivate, 1)
loop(doAutoAbilityUpgrade, 1)
loop(doAutoAbilitySlot, 2)
loop(doAutoSpinPets, 1)
loop(doAutoEquipPets, 2)
loop(doAutoClaimPity, 2)
loop(doAutoPetSlot, 3)
loop(doAutoHire, 5)

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