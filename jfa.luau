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
	Version = "v2.1",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "Jump For Animal",
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
local settings = {
	mutationMode = "Chosen Animal",
	mutationAnimal = "",
	trainBetweenSteals = 5,
}
local sessionStart = tick()
local farmStatus = "idle"

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

--// multi dropdowns can report {"Meadow","Winter"} (array) or {Meadow=true}
--// (keyed) depending on the library build — both shapes normalize here
local function selectedValues(option)
	local chosen = {}
	local value = option and option.Value
	if type(value) == "table" then
		for key, isOn in pairs(value) do
			if isOn == true and type(key) == "string" then
				chosen[key] = true
			elseif type(isOn) == "string" then
				chosen[isOn] = true
			end
		end
	elseif type(value) == "string" and value ~= "" then
		chosen[value] = true
	end
	return chosen
end

local function allows(set, value)
	if next(set) == nil then
		return true --// nothing selected -> everything allowed
	end
	return set[value] == true
end

local function toList(set)
	local list = {}
	for value in pairs(set) do
		table.insert(list, value)
	end
	table.sort(list)
	return list
end

--// non-idle statuses hold for ~2s so the egg chain's per-pass "idle"
--// reset can't clobber them (keeps "training"/fossil text steady on screen)
local StatusHoldUntil = 0

local function setFarmStatus(text)
	text = tostring(text or "idle")
	if text == "idle" then
		if tick() < StatusHoldUntil then
			return --// a real action still owns the status
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

local PlaceEggRequest = waitRemote("PlaceEggRequest")
local DropEggRequest = waitRemote("DropEggRequest")
local SellRemote = waitRemote("Sell")
local CoilsRemote = waitRemote("Coils")
local TrailsRemote = waitRemote("Trails")
local SquatTrainingRequest = waitRemote("SquatTrainingRequest")
local StopSquattingRequest = waitRemote("StopSquattingRequest")
local SquatBonusRequest = waitRemote("SquatBonusRequest")
local OfflineRewardsRemote = waitRemote("OfflineRewards")
local IndexRewardRemote = waitRemote("ClaimAnimalIndexReward")
local PetInventoryRemote = waitRemote("PetInventory")
local FossilRemote = waitRemote("Fossil")

local SettingsFolder = find(ReplicatedStorage, "Settings")
local function requireSetting(name)
	local module = SettingsFolder and SettingsFolder:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local Rarities = requireSetting("Rarities")
local SpeedUpgrades = requireSetting("SpeedUpgrades")
local TrailSettings = requireSetting("Trails")
local BarbellUpgrades = requireSetting("BarbellUpgrades")
local RecommendedJumps = requireSetting("RecommendedJumps")
local Animals = requireSetting("Animals")
local JumpLevels = requireSetting("JumpLevels")
local FossilEvent = requireSetting("FossilEvent")

local ZoneJumpRequirements = {Meadow = 25}
if type(RecommendedJumps) == "table" and type(RecommendedJumps.List) == "table" then
	for key, value in pairs(RecommendedJumps.List) do
		local zone = string.gsub(tostring(key), "%d+$", "")
		local jump = tonumber(value)
		if jump and (ZoneJumpRequirements[zone] == nil or jump < ZoneJumpRequirements[zone]) then
			ZoneJumpRequirements[zone] = jump
		end
	end
end

local FALLBACK_RARITY_ORDER = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Mythical", "Divine", "Celestial", "Eternal", "Exclusive"}

local function buildRarityNames()
	local found = {}
	if type(Rarities) == "table" then
		local list = Rarities.List or Rarities.Order
		if type(list) == "table" then
			for _, name in ipairs(list) do
				if type(name) == "string" then
					found[name] = true
				end
			end
		end
		if type(Rarities.GetAll) == "function" then
			local ok, all = pcall(Rarities.GetAll)
			if ok and type(all) == "table" then
				for name in pairs(all) do
					if type(name) == "string" then
						found[name] = true
					end
				end
			end
		end
	end
	for _, name in ipairs(FALLBACK_RARITY_ORDER) do
		found[name] = true
	end
	return toList(found)
end

local RARITY_NAMES = buildRarityNames()

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

local function holderPosition(holder)
	if not holder then
		return nil
	end
	if holder:IsA("BasePart") then
		return holder.Position
	end
	if holder:IsA("Attachment") then
		return holder.WorldPosition
	end
	return nil
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

local function getPlot()
	local plotValue = LocalPlayer:FindFirstChild("Plot")
	return plotValue and plotValue.Value or nil
end

local function getSquatDetector()
	local plot = getPlot()
	local floor = find(plot, "SquatZone", "Floor")
	return floor and floor:FindFirstChild("Detector") or nil
end

--// placement spot, same as the verified working source: the FIRST "Detector"
--// anywhere under your plot — the real egg spot on the plot floor
local function getPlacementDetector()
	local plot = getPlot()
	return plot and plot:FindFirstChild("Detector", true) or nil
end

local function getCash()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	local value = cash and cash:FindFirstChild("V")
	return value and tonumber(value.Value) or 0
end

local function getLevel()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local value = level and level:FindFirstChild("V")
	return value and tonumber(value.Value) or 0
end

local function currentJumpPower()
	local value = tonumber(LocalPlayer:GetAttribute("JumpPower"))
	if value and value > 0 then
		return value
	end
	if type(JumpLevels) == "table" and type(JumpLevels.GetJumpPower) == "function" then
		local ok, power = pcall(JumpLevels.GetJumpPower, getLevel())
		if ok and tonumber(power) and tonumber(power) > 0 then
			return tonumber(power)
		end
	end
	return nil --// unknown -> reach checks never block
end

--// last zone the character actually stood in (auto-detected, not a dropdown)
local lastDetectedZone = "-"

--// the zone the player is currently standing in: nearest SpawnedEggs stage
local function currentZone()
	local root = getRoot()
	local stages = find(Workspace, "Map", "Stages")
	if not root or not stages then
		return "-"
	end
	local best, bestDistance = nil, math.huge
	for _, stage in ipairs(stages:GetChildren()) do
		if stage:FindFirstChild("SpawnedEggs") then
			local position = safePivot(stage) or safePivot(stage:FindFirstChild("SpawnedEggs"))
			if position then
				local distance = (position - root.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = stage.Name, distance
				end
			end
		end
	end
	if best and bestDistance <= 400 then
		lastDetectedZone = best
		return best
	end
	return lastDetectedZone --// hold the last zone we were really in
end

local function isPetTool(tool)
	return tool:IsA("Tool") and tool:GetAttribute("IsPetInventoryTool") == true
end

local function isEggTool(tool)
	return tool:IsA("Tool") and tool:GetAttribute("IsEggTool") == true
end

local function forEachContainer(fn)
	local character = getCharacter()
	if LocalPlayer.Backpack then
		pcall(fn, LocalPlayer.Backpack)
	end
	if character then
		pcall(fn, character)
	end
end

local function findTool(predicate)
	local found
	forEachContainer(function(container)
		if found then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Tool") and predicate(child) then
				found = child
				return
			end
		end
	end)
	return found
end

local function countEggTools()
	local count = 0
	forEachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isEggTool(child) then
				count += 1
			end
		end
	end)
	return count
end

local function countPlacedEggs()
	local plot = getPlot()
	local placed = plot and plot:FindFirstChild("PlacedEggs")
	return placed and #placed:GetChildren() or 0
end

local function countReadyEggs()
	local plot = getPlot()
	local placed = plot and plot:FindFirstChild("PlacedEggs")
	if not placed then
		return 0
	end
	local ready_ = 0
	for _, egg in ipairs(placed:GetChildren()) do
		if egg:GetAttribute("HatchReady") == true then
			ready_ += 1
		end
	end
	return ready_
end

local function uniqueAnimalNames()
	local names = {}
	local seen = {}
	forEachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isPetTool(child) then
				local name = child:GetAttribute("AnimalName") or child.Name
				if not seen[name] then
					seen[name] = true
					table.insert(names, name)
				end
			end
		end
	end)
	table.sort(names)
	return names
end

local function abbreviate(value)
	value = tonumber(value) or 0
	local units = {"", "K", "M", "B", "T", "Qa", "Qi"}
	local index = 1
	while value >= 1000 and index < #units do
		value /= 1000
		index += 1
	end
	if index == 1 then
		return tostring(math.floor(value))
	end
	return string.format("%.2f%s", value, units[index])
end

local function formatDuration(seconds)
	seconds = math.floor(seconds)
	if seconds < 60 then
		return string.format("%ds", seconds)
	end
	return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
end

local function animalNameNormal(name)
	if type(Animals) == "table" and type(Animals.NormalizeName) == "function" then
		local ok, result = pcall(Animals.NormalizeName, name)
		if ok and type(result) == "string" and result ~= "" then
			return result
		end
	end
	return name
end

local function findAnimalConfig(name)
	if type(Animals) ~= "table" or type(name) ~= "string" or name == "" then
		return nil
	end
	local direct
	pcall(function()
		direct = Animals[name]
	end)
	if type(direct) == "table" then
		return direct
	end
	local normalized = string.lower(tostring(animalNameNormal(name)))
	local found
	local function scan(source)
		if found or type(source) ~= "table" then
			return
		end
		for key, value in pairs(source) do
			if found then
				return
			end
			if type(key) == "string" and type(value) == "table"
				and string.lower(tostring(animalNameNormal(key))) == normalized then
				found = value
				return
			end
			if type(value) == "table" then
				scan(value)
			end
		end
	end
	pcall(scan, Animals)
	return found
end

local function rarityFromAnimal(name)
	local config = findAnimalConfig(name)
	if type(config) ~= "table" then
		return nil
	end
	for _, field in ipairs({"Rarity", "rarity"}) do
		local value = config[field]
		if type(value) == "string" and value ~= "" then
			return value
		end
		if value ~= nil then
			local result = callValue(value)
			if type(result) == "string" and result ~= "" then
				return result
			end
		end
	end
	return nil
end

--// rarity of an inventory tool: pet name or egg name ("Owl Egg" -> "Owl")
local function toolRarity(tool)
	local value = tool:GetAttribute("Rarity")
	if type(value) == "string" and value ~= "" then
		return value
	end
	local name = tool:GetAttribute("AnimalName") or tool:GetAttribute("EggName") or tool.Name
	local rarity = rarityFromAnimal(name)
	if rarity then
		return rarity
	end
	return rarityFromAnimal(string.gsub(tostring(name), "%s*Egg$", ""))
end

local function eggDisplayName(egg)
	local name = egg:GetAttribute("AnimalName") or egg:GetAttribute("EggName") or egg.Name
	return tostring(name)
end

local function eggRarity(egg)
	if not egg then
		return nil
	end
	local value = egg:GetAttribute("Rarity")
	if type(value) == "string" and value ~= "" then
		return value
	end
	local root = egg:FindFirstChild("EggRoot") or egg
	value = root:GetAttribute("Rarity")
	if type(value) == "string" and value ~= "" then
		return value
	end
	return rarityFromAnimal(eggDisplayName(egg))
end

local function rarityIndexOf(rarity)
	if type(rarity) ~= "string" then
		return 0
	end
	if type(Rarities) == "table" and type(Rarities.GetIndex) == "function" then
		local ok, index = pcall(Rarities.GetIndex, rarity)
		if ok and tonumber(index) then
			return tonumber(index)
		end
	end
	for index, name in ipairs(FALLBACK_RARITY_ORDER) do
		if string.lower(name) == string.lower(rarity) then
			return index
		end
	end
	return 0
end

--// zone/spawned eggs only: must sit in a SpawnedEggs folder out in the map,
--// never under PlacedEggs or any player's plot (yours or theirs)
local function isValidZoneEgg(egg)
	local folder = egg.Parent
	if not folder or folder.Name ~= "SpawnedEggs" then
		return false
	end
	local container = folder.Parent
	if not container or not container:IsDescendantOf(Workspace) then
		return false
	end
	if container.Name == "PlacedEggs" then
		return false
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local plotValue = player:FindFirstChild("Plot")
		local plot = plotValue and plotValue.Value
		if plot and container:IsDescendantOf(plot) then
			return false
		end
	end
	return true
end

local function zoneReachable(zone)
	local required = ZoneJumpRequirements[zone]
	if not required then
		return true
	end
	local jump = currentJumpPower()
	if not jump then
		return true
	end
	return jump >= required
end

local function eggReachable(egg)
	local required
	for _, field in ipairs({"RequiredJumps", "JumpRequirement", "RequiredJumpPower"}) do
		local value = tonumber(egg:GetAttribute(field))
		if value then
			required = value
			break
		end
	end
	if not required then
		return true
	end
	local jump = currentJumpPower()
	if not jump then
		return true
	end
	return jump >= required
end

local function rarityAllowed(set, rarity)
	if next(set) == nil then
		return true
	end
	if type(rarity) ~= "string" then
		return true --// unknown rarity never stalls the bot; known ones are strict
	end
	for chosen in pairs(set) do
		if string.lower(chosen) == string.lower(rarity) then
			return true
		end
	end
	return false
end

local ZoneNames = {}
do
	local stages = find(Workspace, "Map", "Stages")
	if stages then
		for _, stage in ipairs(stages:GetChildren()) do
			if stage:FindFirstChild("SpawnedEggs") then
				table.insert(ZoneNames, stage.Name)
			end
		end
	end
	if #ZoneNames == 0 then
		ZoneNames = {"Meadow", "Coral Reef", "Winter", "Desert", "Crystal Mines", "Jungle", "Mystic Isles", "Prehistoric", "Celestial Heights", "Savannah"}
	end
end

local AnimalNames = uniqueAnimalNames()
if #AnimalNames == 0 then
	AnimalNames = {"None"}
end

local NextStealAt = 0
local NextPlaceAttempt = 0
local PlaceRotation = 0
local CarryWatchSince = nil
local LastBonusClaim = 0
local LastBarbellAction = 0
local SellWatch = 0
local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function scanEggs()
	local stages = find(Workspace, "Map", "Stages")
	return stages and stages:GetChildren() or {}
end

--// NO target dropdown anymore — always the best egg you can actually get:
--// must pass zone + rarity filters AND be reachable with your jump power;
--// highest rarity wins, closer eggs win ties
local function findEggTarget()
	local root = getRoot()
	local origin = root and root.Position or Vector3.zero
	local zoneSet = selectedValues(Options.StealZones)
	local raritySet = selectedValues(Options.StealRarities)
	local best
	for _, stage in ipairs(scanEggs()) do
		local spawned = stage:FindFirstChild("SpawnedEggs")
		if spawned then
			for _, egg in ipairs(spawned:GetChildren()) do
				if isValidZoneEgg(egg) then
					if allows(zoneSet, stage.Name) then
						local rarity = eggRarity(egg)
						if rarityAllowed(raritySet, rarity) then
							local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
							local position = prompt and (holderPosition(prompt.Parent) or safePivot(egg)) or nil
							if position then
								local reachable = zoneReachable(stage.Name) and eggReachable(egg)
								if reachable then
									local distance = (position - origin).Magnitude
									local score = rarityIndexOf(rarity) * 1000000 - distance * 0.001
									if not best or score > best.score then
										best = {
											prompt = prompt,
											position = position,
											egg = egg,
											name = eggDisplayName(egg),
											rarity = rarity,
											zone = stage.Name,
											score = score,
										}
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if best and best.prompt then
		return best.prompt, best.position, best.egg, best.name, best.rarity, best.zone
	end
	return nil --// nothing eligible right now; stay silent, no status spam
end


local FossilFinishAt = nil
local FossilClaimUntil = 0 --// while active, the egg chain stands still

local function fossilStation()
	return find(Workspace, "Map", "FossilEvent", "Station", "ResearchTable")
end

local function fossilTableDetector()
	local stationTable = fossilStation()
	return stationTable and stationTable:FindFirstChild("Detector") or nil
end

local function fossilPlacePrompt()
	local stationTable = fossilStation()
	local prompt = stationTable and stationTable:FindFirstChild("PlacePrompt", true)
	if prompt then
		return prompt
	end
	local tablePart = stationTable and stationTable:FindFirstChild("Table")
	return tablePart and tablePart:FindFirstChild("PlacePrompt", true) or nil
end

local function fossilBuyPrompt()
	local stand = find(Workspace, "Map", "FossilEvent", "EggStand")
	return stand and stand:FindFirstChild("BuyPrompt", true) or nil
end

local FOSSIL_EGG_PRICE = (type(FossilEvent) == "table" and type(FossilEvent.Stand) == "table"
	and tonumber(FossilEvent.Stand.PriceFragments)) or 500
local FOSSIL_MIN_CLEAN = (type(FossilEvent) == "table" and type(FossilEvent.Station) == "table"
	and tonumber(FossilEvent.Station.MinimumCleanSeconds)) or 8

local function getFragments()
	local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
	local fragments = leaderstats and leaderstats:FindFirstChild("Fragments")
	if not fragments then
		return nil --// unknown -> let the server decide
	end
	local value
	pcall(function()
		value = fragments.Value
	end)
	if value == nil then
		local inner = fragments:FindFirstChild("V")
		if inner then
			pcall(function()
				value = inner.Value
			end)
		end
	end
	return tonumber(value)
end

local LastFossilModel = nil --// the fossil we last dug, used to detect carrying

local function findFossilTarget()
	local root = getRoot()
	local origin = root and root.Position or Vector3.zero
	local stages = find(Workspace, "Map", "Stages")
	if not stages then
		return nil, nil
	end
	local best, bestPosition, bestDistance, bestModel
	for _, stage in ipairs(stages:GetChildren()) do
		local spawned = stage:FindFirstChild("SpawnedFossils")
		if spawned then
			for _, fossil in ipairs(spawned:GetChildren()) do
				if (tonumber(fossil:GetAttribute("CarriedByUserId")) or 0) == 0 then
					local prompt = fossil:FindFirstChild("DigPrompt", true)
						or fossil:FindFirstChildWhichIsA("ProximityPrompt", true)
					if prompt and prompt.Enabled then
						--// stand at the fossil itself, not up at the prompt attachment
						local position = safePivot(fossil) or holderPosition(prompt.Parent)
					if position then
						local distance = (position - origin).Magnitude
						if not best or distance < bestDistance then
							best, bestPosition, bestDistance, bestModel = prompt, position, distance, fossil
						end
					end
				end
			end
			end
		end
	end
	if best then
		LastFossilModel = bestModel
	end
	return best, bestPosition
end

--// ANY of these being true means a fossil is in our hands right now
local function carryingFossil()
	if (tonumber(LocalPlayer:GetAttribute("CarriedFossilCount")) or 0) > 0 then
		return true
	end
	if LocalPlayer:GetAttribute("FossilGuideStep") == "ReturnFossil" then
		return true
	end
	local model = LastFossilModel
	if model and model.Parent and model:IsDescendantOf(Workspace)
		and (tonumber(model:GetAttribute("CarriedByUserId")) or 0) == LocalPlayer.UserId then
		return true
	end
	return false
end

--// true while a fossil is carried or sitting on the research table:
--// the egg chain pauses so it can't drag the player away mid-clean
local function fossilBusy()
	if not enabled.fossil then
		return false
	end
	if tick() < FossilClaimUntil then
		return true
	end
	local pendingName = LocalPlayer:GetAttribute("PendingFossilName")
	if type(pendingName) == "string" and pendingName ~= "" then
		return true
	end
	if LocalPlayer:GetAttribute("FossilCleaningOpen") == true then
		return true
	end
	if carryingFossil() then
		--// keep the egg chain parked while the fossil is in our hands
		FossilClaimUntil = math.max(FossilClaimUntil, tick() + 1)
		return true
	end
	return false
end

local function doAutoBuyFossilEgg()
	if not enabled.buyFossilEgg then
		return
	end
	if fossilBusy() then
		return --// never fight the dig -> table -> clean cycle
	end
	if not ready("fossilEggBuy", 4) then
		return
	end
	local fragments = getFragments()
	if fragments and fragments < FOSSIL_EGG_PRICE then
		return --// not enough Fragments yet
	end
	local prompt = fossilBuyPrompt()
	if not prompt then
		return
	end
	--// stand at the EggStand base, not up at the prompt attachment
	local stand = find(Workspace, "Map", "FossilEvent", "EggStand")
	local position = safePivot(stand) or safePivot(prompt.Parent) or holderPosition(prompt.Parent)
	FossilClaimUntil = tick() + 3
	if position then
		teleportTo(position)
		task.wait(0.25)
	end
	pcall(function()
		prompt.Enabled = true
	end)
	pcall(function()
		fireproximityprompt(prompt)
	end)
	setFarmStatus("buying fossiled egg")
	task.wait(0.4)
end

local function doAutoFossil()
	if not enabled.fossil and not enabled.buyFossilEgg then
		FossilFinishAt = nil
		return
	end
	doAutoBuyFossilEgg()
	if not enabled.fossil then
		return
	end
	local pendingName = LocalPlayer:GetAttribute("PendingFossilName")
	local pending = type(pendingName) == "string" and pendingName ~= ""
	local placePrompt = fossilPlacePrompt()
	local detector = fossilTableDetector()
	--// anchor on the table's Detector part, not the prompt attachment
	local anchor = (detector and detector.Position)
		or (placePrompt and holderPosition(placePrompt.Parent))
	if pending then
		--// fossil is on the table: stand close and fire Finish the instant the
		--// server's minimum clean time is up, then retry until it logs
		LastFossilModel = nil
		if anchor then
			local root = getRoot()
			if root and (root.Position - anchor).Magnitude > 6 then
				teleportTo(anchor)
			end
		end
		setFarmStatus("cleaning fossil")
		if not FossilFinishAt then
			FossilFinishAt = tick() + FOSSIL_MIN_CLEAN + 0.3
		elseif tick() >= FossilFinishAt then
			fire(FossilRemote, "Finish")
			FossilFinishAt = tick() + 1.2 --// retry until the server accepts
		end
		return
	end
	FossilFinishAt = nil
	if carryingFossil() then
		if not anchor then
			return
		end
		setFarmStatus("fossil to table")
		local root = getRoot()
		if not root or (root.Position - anchor).Magnitude > 4 then
			teleportTo(anchor)
			task.wait(0.25)
		end
		if placePrompt then
			setFarmStatus("placing fossil")
			pcall(function()
				placePrompt.Enabled = true
			end)
			pcall(function()
				fireproximityprompt(placePrompt)
			end)
			task.wait(0.5)
		end
		return
	end
	local prompt, position = findFossilTarget()
	if not prompt or not position then
		return --// no fossil up right now; stay silent
	end
	if LocalPlayer:GetAttribute("IsSquatting") == true then
		fire(StopSquattingRequest)
		task.wait(0.2)
	end
	setFarmStatus("digging fossil")
	FossilClaimUntil = tick() + 6 --// just enough to cover dig + carry detection
	teleportTo(position)
	task.wait(0.3)
	pcall(function()
		prompt.RequiresLineOfSight = false
	end)
	pcall(function()
		prompt.Enabled = true
	end)
	pcall(function()
		fireproximityprompt(prompt) --// DigPrompt holds ~1.5s, then we carry it
	end)
	--// the moment the fossil is in our hands, teleport straight back to the table
	local deadline = tick() + 2.5
	while session.running and tick() < deadline and not carryingFossil() do
		task.wait(0.1)
	end
	if carryingFossil() and anchor then
		setFarmStatus("fossil to table")
		teleportTo(anchor)
	end
end

local function doCarryRecovery()
	if not enabled.steal and not enabled.place then
		CarryWatchSince = nil
		return
	end
	if fossilBusy() then
		return
	end
	local carried = (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0
	local tool = findTool(isEggTool)
	if carried and not tool then
		local base = getPlacementDetector()
		local root = getRoot()
		if base and root and (root.Position - base.Position).Magnitude > 40 then
			teleportTo(base.Position)
			task.wait(0.4)
		end
		if not CarryWatchSince then
			CarryWatchSince = tick()
		elseif tick() - CarryWatchSince > 30 then
			fire(DropEggRequest)
			CarryWatchSince = tick()
			task.wait(0.5)
		end
	else
		CarryWatchSince = nil
	end
end

local function doAutoPlace()
	if not enabled.place or not PlaceEggRequest then
		return
	end
	if fossilBusy() then
		return
	end
	if tick() < NextPlaceAttempt then
		return
	end
	local list = {}
	forEachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isEggTool(child) then
				table.insert(list, child)
			end
		end
	end)
	if #list == 0 then
		return
	end
	local humanoid = getHumanoid()
	local detector = getPlacementDetector()
	if not humanoid or not detector then
		setFarmStatus("no plot detector yet")
		return
	end
	NextPlaceAttempt = tick() + 2
	--// highest rarity egg goes on the plot first
	local bestTool, bestRarity = nil, -1
	for _, tool in ipairs(list) do
		local index = rarityIndexOf(toolRarity(tool))
		if index > bestRarity then
			bestTool, bestRarity = tool, index
		end
	end
	local carrying = bestTool or list[1]
	setFarmStatus("placing " .. tostring(carrying.Name))
	pcall(function()
		humanoid:EquipTool(carrying)
	end)
	task.wait(0.2)
	fire(PlaceEggRequest, carrying:GetAttribute("EggId"), detector.Position + Vector3.new(0, 2, 0))
	task.wait(0.35)
	if not carrying.Parent then
		setFarmStatus("placed " .. tostring(carrying.Name))
		NextStealAt = tick() + math.max(tonumber(settings.trainBetweenSteals) or 5, 0)
	else
		setFarmStatus("place retrying " .. tostring(carrying.Name))
	end
end

local function doAutoSteal()
	if not enabled.steal then
		return
	end
	if fossilBusy() then
		return
	end
	if tick() < NextStealAt then
		return
	end
	if (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0 then
		return
	end
	--// no backpack-full gate: keep stealing, Auto Place drains the eggs
	local prompt, position, egg, name, rarity = findEggTarget()
	if not prompt or not position or not egg then
		return --// nothing eligible; status stays quiet
	end
	if LocalPlayer:GetAttribute("IsSquatting") == true then
		fire(StopSquattingRequest)
		local deadline = tick() + 1.5
		while session.running and LocalPlayer:GetAttribute("IsSquatting") == true and tick() < deadline do
			task.wait(0.15)
		end
	end
	local toolsBefore = countEggTools()
	for attempt = 1, 3 do
		teleportTo(position)
		task.wait(0.3)
		pcall(function()
			prompt.RequiresLineOfSight = false
		end)
		pcall(function()
			prompt.Enabled = true
		end)
		pcall(function()
			fireproximityprompt(prompt) --// instant, the only grab method
		end)
		task.wait(0.45)
		if countEggTools() > toolsBefore
			or (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0
			or not egg.Parent then
			--// status only shows on a real pickup: egg name + rarity
			setFarmStatus("grabbed " .. tostring(name) .. (rarity and (" [" .. rarity .. "]") or ""))
			local base = getPlacementDetector()
			if base then
				teleportTo(base.Position)
				task.wait(0.4)
			end
			return
		end
	end
end

local function doAutoTrain()
	if not enabled.train then
		return
	end
	if fossilBusy() then
		return
	end
	if enabled.hatch and countReadyEggs() > 0 then
		if LocalPlayer:GetAttribute("IsSquatting") == true then
			fire(StopSquattingRequest)
		end
		return
	end
	if enabled.steal and (tonumber(LocalPlayer:GetAttribute("CarriedEggCount")) or 0) > 0 then
		return
	end
	local detector = getSquatDetector()
	local root = getRoot()
	if not detector or not root then
		return
	end
	if (root.Position - detector.Position).Magnitude > 10 then
		teleportTo(detector.Position)
		task.wait(0.3)
	end
	setFarmStatus("training") --// stays on the status label while Auto Train holds
	if LocalPlayer:GetAttribute("IsSquatting") ~= true then
		fire(SquatTrainingRequest, detector)
		task.wait(0.25)
	end
end

--// bonus is claimed SILENTLY under Auto Train — status stays "training"
local function doAutoSquatBonus()
	if not enabled.train or not SquatBonusRequest then
		return
	end
	if LocalPlayer:GetAttribute("SquatBonusAvailable") ~= true then
		return
	end
	if tick() - LastBonusClaim < 0.4 then
		return
	end
	LastBonusClaim = tick()
	fire(SquatBonusRequest, math.floor(tonumber(LocalPlayer:GetAttribute("SquatBonusVersion")) or 0))
end

local function findSellTarget()
	local raritySet = selectedValues(Options.SellRarities)
	if next(raritySet) == nil then
		return nil --// select at least one rarity before selling
	end
	local best, bestCps
	forEachContainer(function(container)
		for _, tool in ipairs(container:GetChildren()) do
			if isPetTool(tool) then
				local rarity = rarityFromAnimal(tool:GetAttribute("AnimalName") or tool.Name)
				if rarity then
					for chosen in pairs(raritySet) do
						if string.lower(chosen) == string.lower(rarity) then
							local cps = tonumber(tool:GetAttribute("CashPerSecond")) or math.huge
							if not bestCps or cps < bestCps then
								best, bestCps = tool, cps
							end
						end
					end
				end
			end
		end
	end)
	return best
end

local function doAutoSell()
	if not enabled.sell then
		return
	end
	if fossilBusy() then
		return
	end
	if findTool(isEggTool) then
		return --// eggs first, sell later
	end
	if tick() < SellWatch then
		return
	end
	SellWatch = tick() + 1
	local tool = findSellTarget()
	if not tool then
		return
	end
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	setFarmStatus("sell " .. tostring(tool:GetAttribute("AnimalName") or tool.Name))
	pcall(function()
		humanoid:EquipTool(tool)
	end)
	local sellRoot = find(Workspace, "Map", "Sell")
	local detector = sellRoot and sellRoot:FindFirstChild("Detector", true)
	if detector and detector:IsA("BasePart") then
		teleportTo(detector.Position)
		task.wait(0.3)
	end
	local prompt = detector and detector:FindFirstChild("SellAnimalPrompt", true)
	if prompt then
		pcall(function()
			prompt.Enabled = true
		end)
		pcall(function()
			fireproximityprompt(prompt)
		end)
	else
		fire(SellRemote)
	end
	task.wait(0.4)
end

local function doAutoHatch()
	if not enabled.hatch then
		return
	end
	if fossilBusy() then
		return
	end
	local plot = getPlot()
	local placed = plot and plot:FindFirstChild("PlacedEggs")
	if not placed then
		return
	end
	for _, egg in ipairs(placed:GetChildren()) do
		if egg:GetAttribute("HatchReady") == true then
			local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				local position = holderPosition(prompt.Parent) or safePivot(egg)
				setFarmStatus("hatch " .. tostring(egg.Name))
				if position then
					teleportTo(position)
					task.wait(0.25)
				end
				pcall(function()
					prompt.Enabled = true
				end)
				pcall(function()
					fireproximityprompt(prompt)
				end)
				task.wait(0.35)
				return
			end
		end
	end
end

local function ownedValue(folder, name)
	local entry = folder and folder:FindFirstChild(name)
	return entry and entry.Value == true
end

--// shop catalogs for the single "Auto Buy & Equip Best" toggles (no dropdowns)
local COIL_NAMES = { "Red Coil", "Candy Coil", "Yellow Coil", "Chocolate Coil" }
local TRAIL_NAMES = { "Blue Trail", "Red Trail", "Green Trail", "Yellow Trail", "Purple Trail", "White Trail", "Black Trail", "Galaxy Trail", "Crimson Star Trail", "Rainbow Trail" }

local function doAutoCoils()
	local coilData = LocalPlayer:FindFirstChild("CoilData")
	if not coilData or not CoilsRemote then
		return
	end
	local owned = coilData:FindFirstChild("Owned")
	local equipped = coilData:FindFirstChild("Equipped")
	if enabled.buyCoils and SpeedUpgrades then
		--// single-toggle mode: buy the best affordable coil we don't own yet
		local candidates = {}
		for _, name in ipairs(COIL_NAMES) do
			local ok, config = pcall(function()
				return SpeedUpgrades.Get(name)
			end)
			if ok and type(config) == "table" and not ownedValue(owned, name) then
				table.insert(candidates, {
					name = name,
					order = tonumber(config.Order) or 0,
					cost = tonumber(config.Cost) or math.huge,
				})
			end
		end
		table.sort(candidates, function(a, b)
			return a.order > b.order
		end)
		local cash = getCash()
		for _, candidate in ipairs(candidates) do
			if cash >= candidate.cost then
				fire(CoilsRemote, "Select", candidate.name)
				task.wait(0.25)
				break
			end
		end
	end
	if enabled.equipCoil and SpeedUpgrades and owned then
		local bestName, bestOrder = nil, -1
		for _, entry in ipairs(owned:GetChildren()) do
			if entry.Value == true then
				local ok, config = pcall(function()
					return SpeedUpgrades.Get(entry.Name)
				end)
				local order = ok and type(config) == "table" and tonumber(config.Order) or 0
				if order > bestOrder then
					bestName, bestOrder = entry.Name, order
				end
			end
		end
		if bestName and equipped and equipped.Value ~= bestName then
			fire(CoilsRemote, "Select", bestName)
			task.wait(0.2)
		end
	end
end

local function doAutoTrails()
	local trailData = LocalPlayer:FindFirstChild("TrailData")
	if not trailData or not TrailsRemote then
		return
	end
	local owned = trailData:FindFirstChild("Owned")
	local equipped = trailData:FindFirstChild("Equipped")
	if enabled.buyTrails and TrailSettings then
		--// single-toggle mode: buy the best affordable trail we don't own yet
		local candidates = {}
		for _, name in ipairs(TRAIL_NAMES) do
			local ok, config = pcall(function()
				return TrailSettings.Get(name)
			end)
			if ok and type(config) == "table" and not ownedValue(owned, name) then
				table.insert(candidates, {
					name = name,
					order = tonumber(config.Order) or 0,
					cost = tonumber(config.Cost) or math.huge,
				})
			end
		end
		table.sort(candidates, function(a, b)
			return a.order > b.order
		end)
		local cash = getCash()
		for _, candidate in ipairs(candidates) do
			if cash >= candidate.cost then
				fire(TrailsRemote, "Select", candidate.name)
				task.wait(0.25)
				break
			end
		end
	end
	if enabled.equipTrail and TrailSettings and owned then
		local bestName, bestOrder = nil, -1
		for _, entry in ipairs(owned:GetChildren()) do
			if entry.Value == true then
				local ok, config = pcall(function()
					return TrailSettings.Get(entry.Name)
				end)
				local order = ok and type(config) == "table" and tonumber(config.Order) or 0
				if order > bestOrder then
					bestName, bestOrder = entry.Name, order
				end
			end
		end
		if bestName and equipped and equipped.Value ~= bestName then
			fire(TrailsRemote, "Select", bestName)
			task.wait(0.2)
		end
	end
end

local function doAutoBarbell()
	if not enabled.barbell or type(BarbellUpgrades) ~= "table" or type(BarbellUpgrades.GetNext) ~= "function" then
		return
	end
	if fossilBusy() then
		return
	end
	if tick() - LastBarbellAction < 3 then
		return
	end
	LastBarbellAction = tick()
	local levelAttr = LocalPlayer:FindFirstChild("BarbellLevel")
	local level = levelAttr and tonumber(levelAttr.Value) or 1
	local nextUpgrade = read(function()
		return BarbellUpgrades.GetNext(math.max(math.floor(level), 1))
	end)
	if type(nextUpgrade) ~= "table" then
		return
	end
	local price = tonumber(nextUpgrade.CashPrice) or 0
	if getCash() < price then
		return
	end
	local upgradeB = find(getPlot(), "SquatZone", "UpgradeB")
	local prompt = upgradeB and upgradeB:FindFirstChild("BarbellUpgradePrompt", true)
	if not prompt then
		return
	end
	local position = holderPosition(prompt.Parent)
	if position then
		teleportTo(position)
		task.wait(0.25)
	end
	pcall(function()
		prompt.Enabled = true
	end)
	pcall(function()
		fireproximityprompt(prompt)
	end)
	task.wait(0.4)
end

local function findMutationPet(targetName)
	local candidate, candidateCps
	forEachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isPetTool(child) then
				local name = child:GetAttribute("AnimalName") or child.Name
				local cps = tonumber(child:GetAttribute("CashPerSecond")) or math.huge
				if name == targetName and (not candidateCps or cps < candidateCps) then
					candidate, candidateCps = child, cps
				end
			end
		end
	end)
	return candidate
end

local function findDuplicateAnimal()
	local counts, lowest = {}, {}
	forEachContainer(function(container)
		for _, child in ipairs(container:GetChildren()) do
			if isPetTool(child) then
				local name = child:GetAttribute("AnimalName") or child.Name
				local cps = tonumber(child:GetAttribute("CashPerSecond")) or math.huge
				counts[name] = (counts[name] or 0) + 1
				if not lowest[name] or cps < lowest[name] then
					lowest[name] = cps
				end
			end
		end
	end)
	local bestName, bestCps
	for name, count in pairs(counts) do
		if count >= 2 and (not bestCps or lowest[name] < bestCps) then
			bestName, bestCps = name, lowest[name]
		end
	end
	return bestName
end

local function mutationDetector()
	local mutations = find(Workspace, "Map", "Mutations")
	return mutations and mutations:FindFirstChild("Detector")
end

local function fireMutation(name, detector)
	local prompt = detector and detector:FindFirstChild(name, true)
	if not prompt then
		return false
	end
	local position = holderPosition(prompt.Parent)
	if position then
		teleportTo(position)
		task.wait(0.2)
	end
	pcall(function()
		prompt.Enabled = true
	end)
	pcall(function()
		fireproximityprompt(prompt)
	end)
	task.wait(0.35)
	return true
end

local function doAutoMutation()
	local active = LocalPlayer:GetAttribute("MutationCraftActive") == true
	local craftReady = LocalPlayer:GetAttribute("MutationCraftReady") == true
	local canRemove = LocalPlayer:GetAttribute("MutationCanRemove") == true
	local detector = mutationDetector()
	if enabled.claimMutation and active and craftReady then
		fireMutation("MutationPrompt", detector)
		return
	end
	if enabled.returnMutation and active and canRemove then
		fireMutation("MutationRemovePrompt", detector)
		return
	end
	if not enabled.addMutation or active then
		return
	end
	local target = LocalPlayer:GetAttribute("MutationCraftAnimalName")
	if type(target) ~= "string" or target == "" then
		target = settings.mutationAnimal --// Pet Choice: Chosen Animal (fixed, no dropdown)
	end
	if not target or target == "" or target == "None" then
		target = findDuplicateAnimal() --// nothing chosen -> auto-pick a duplicate
	end
	if not target or target == "" or target == "None" then
		return
	end
	local tool = findMutationPet(target)
	if not tool then
		return
	end
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	pcall(function()
		humanoid:EquipTool(tool)
	end)
	task.wait(0.2)
	fireMutation("MutationPrompt", detector)
end

local function doAutoOffline()
	if not enabled.offline or not OfflineRewardsRemote then
		return
	end
	if (tonumber(LocalPlayer:GetAttribute("OfflineCashPending")) or 0) > 0 then
		fire(OfflineRewardsRemote, "Claim")
		task.wait(0.25)
	end
end

local function doAutoIndex()
	if not enabled.index or not IndexRewardRemote then
		return
	end
	if not ready("indexClaim", 15) then
		return
	end
	fire(IndexRewardRemote, "__ALL__")
end

--// Equip Best Pets — asks the server to equip the strongest pets
local function doEquipBestPets()
	if not enabled.equipBest or not PetInventoryRemote then
		return
	end
	if not ready("equipBest", 15) then
		return
	end
	fire(PetInventoryRemote, "EquipBest")
end

local function deleteClientGuards()
	local guards = find(Workspace, "Map", "ClientGuards")
	if not guards then
		return
	end
	for _, child in ipairs(guards:GetChildren()) do
		pcall(function()
			child:Destroy()
		end)
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

--// auto-detect the real game name from the current place id;
--// the window footer keeps using CONFIG.GameName
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
			return --// keep CONFIG.GameName as the fallback
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
local SellingTab = Tabs.Main:AddSubTab({ Name = "Selling", Icon = "coins" })
local ShopsTab = Tabs.Main:AddSubTab({ Name = "Shops", Icon = "shopping-cart" })
local UpgradesTab = Tabs.Main:AddSubTab({ Name = "Upgrades", Icon = "trending-up" })
local RewardsTab = Tabs.Main:AddSubTab({ Name = "Rewards", Icon = "gift" })

local FarmBox = box(FarmingTab, "Farming", "star", "Left")
FarmBox:AddToggle("AutoPlace", { Text = "Place Best Egg", Default = false, Callback = function(value)
	enabled.place = value
	NextPlaceAttempt = 0
end })
FarmBox:AddToggle("AutoHatch", { Text = "Hatch Ready Egg", Default = false, Callback = function(value)
	enabled.hatch = value
end })
FarmBox:AddToggle("AutoTrain", { Text = "Fast Train X2", Default = false, Callback = function(value)
	enabled.train = value
	if not value and LocalPlayer:GetAttribute("IsSquatting") == true then
		fire(StopSquattingRequest)
	end
end })
FarmBox:AddToggle("EquipBestPets", { Text = "Equip Best Pets", Default = false, Callback = function(value)
	enabled.equipBest = value
	if value and PetInventoryRemote then
		task.spawn(function()
			fire(PetInventoryRemote, "EquipBest")
		end)
	end
end })
FarmBox:AddButton({ Text = "Anti Guard", Func = function()
	pcall(deleteClientGuards)
	task.spawn(function()
		for _ = 1, 10 do
			if not session.running then
				break
			end
			task.wait(2)
			pcall(deleteClientGuards)
		end
	end)
	pcall(function()
		Library:Notify("Anti Guard: client guards deleted (20s sweep)")
	end)
end })

--// steal eggs: own group right below Farming, Auto Steal sits under the dropdowns
local FarmEggBox = box(FarmingTab, "Farm Egg", "egg", "Left")
FarmEggBox:AddDropdown("StealZones", {
	Text = "Zones",
	Values = ZoneNames,
	Default = 1,
	Multi = true,
	Searchable = true,
})
FarmEggBox:AddDropdown("StealRarities", {
	Text = "Select Rarity",
	Values = RARITY_NAMES,
	Default = 1,
	Multi = true,
	Searchable = true,
})
FarmEggBox:AddToggle("AutoSteal", { Text = "Steal Egg", Default = false, Callback = function(value)
	enabled.steal = value
end })

--// no Target dropdown anywhere: stealing is always "best egg I can reach"
local GameStatusBox = box(FarmingTab, "Game Info", "info", "Right")
GameStatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
GameStatusBox:AddLabel("ZoneLabel", { Text = paint("Zone -", "-", COLORS.user), DoesWrap = true })
GameStatusBox:AddLabel("EggsLabel", { Text = paint("Eggs -", "placed 0 | ready 0", COLORS.user), DoesWrap = true })

--// Farm Fossil group sits directly below Game Info (same Right column)
local FossilBox = box(FarmingTab, "Farm Fossil", "hammer", "Right")
FossilBox:AddToggle("AutoFarmFossil", { Text = "Collect & Clean Fossil", Default = false, Callback = function(value)
	enabled.fossil = value
end })
FossilBox:AddToggle("AutoBuyFossilEgg", { Text = string.format("Buy Fossiled Egg (%d Fragments)", FOSSIL_EGG_PRICE), Default = false, Callback = function(value)
	enabled.buyFossilEgg = value
end })

local SellBox = box(SellingTab, "Selling", "coins", "Left")
SellBox:AddToggle("AutoSell", { Text = "Sell Pets By Rarity", Default = false, Callback = function(value)
	enabled.sell = value
end })
SellBox:AddDropdown("SellRarities", {
	Text = "Sell Rarity",
	Values = RARITY_NAMES,
	Default = 1,
	Multi = true,
	Searchable = true,
})
local ShopCoilBox = box(ShopsTab, "Coils", "gauge", "Left")
ShopCoilBox:AddToggle("AutoBuyCoils", { Text = "Buy & Equip Best Coil", Default = false, Callback = function(value)
	enabled.buyCoils = value
	enabled.equipCoil = value
end })
local ShopTrailBox = box(ShopsTab, "Trails", "wind", "Right")
ShopTrailBox:AddToggle("AutoBuyTrails", { Text = "Buy & Equip Best Trail", Default = false, Callback = function(value)
	enabled.buyTrails = value
	enabled.equipTrail = value
end })

local BarbellBox = box(UpgradesTab, "Barbell", "dumbbell", "Left")
BarbellBox:AddToggle("AutoBarbell", { Text = "Upgrade Barbell", Default = false, Callback = function(value)
	enabled.barbell = value
end })
local MutationBox = box(UpgradesTab, "Mutation Machine", "flask-conical", "Right")
MutationBox:AddToggle("AutoAddMutation", { Text = "Auto Add Pets To Machine", Default = false, Callback = function(value)
	enabled.addMutation = value
end })
MutationBox:AddDropdown("MutationAnimal", {
	Text = "Select Animal",
	Values = AnimalNames,
	Default = 1,
	Searchable = true,
	Callback = function(value)
		settings.mutationAnimal = value
	end,
})
MutationBox:AddToggle("AutoClaimMutation", { Text = "Claim Gold Mutation", Default = false, Callback = function(value)
	enabled.claimMutation = value
end })
MutationBox:AddToggle("AutoReturnMutation", { Text = "Return Mutation Pets", Default = false, Callback = function(value)
	enabled.returnMutation = value
end })

local RewardBox = box(RewardsTab, "Claims", "gift", "Left")
RewardBox:AddToggle("AutoOffline", { Text = "Claim Offline Cash", Default = false, Callback = function(value)
	enabled.offline = value
end })
RewardBox:AddToggle("AutoIndex", { Text = "Claim Index Rewards", Default = false, Callback = function(value)
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

--// default selections: steal every zone + every rarity, sell only junk tiers
pcall(function()
	local allZones, allRarities = {}, {}
	for _, zone in ipairs(ZoneNames) do
		allZones[zone] = true
	end
	for _, rarity in ipairs(RARITY_NAMES) do
		allRarities[rarity] = true
	end
	Options.StealZones:SetValue(allZones)
	Options.StealRarities:SetValue(allRarities)
	Options.SellRarities:SetValue({ Common = true, Uncommon = true })
end)

local function updateLabels()
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("ZoneLabel", paint("Zone -", currentZone(), COLORS.user))
	setLabel("EggsLabel", paint("Eggs -", string.format("placed %d | ready %d", countPlacedEggs(), countReadyEggs()), COLORS.user))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	pcall(function()
		local zones = {}
		local stages = find(Workspace, "Map", "Stages")
		if stages then
			for _, stage in ipairs(stages:GetChildren()) do
				if stage:FindFirstChild("SpawnedEggs") then
					table.insert(zones, stage.Name)
				end
			end
		end
		if #zones > 0 then
			Options.StealZones:SetValues(zones)
		end
		local animals = uniqueAnimalNames()
		if #animals > 0 then
			Options.MutationAnimal:SetValues(animals)
		end
	end)
end


local function chain(steps, interval)
	task.spawn(function()
		while session.running do
			setFarmStatus("idle") --// nothing happened yet this pass
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

--// farm chain — 0.5s per full pass (place runs before steal, like the source)
chain({ doCarryRecovery, doAutoPlace, doAutoSteal, doAutoSell, doAutoTrain, doAutoSquatBonus, doAutoHatch, doAutoBarbell }, 0.5)
--// shops + rewards + equip best pets — 0.5s
chain({ doAutoOffline, doAutoIndex, doEquipBestPets, doAutoCoils, doAutoTrails }, 0.5)
--// fossil cycle: dig -> table -> clean — 0.75s
loop(doAutoFossil, 0.4)
--// mutation machine — 0.5s
loop(doAutoMutation, 0.5)
--// no gameplay paused — 60s
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
--// anti-afk jump — 300s
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
--// UI refresh — 1s
task.spawn(function()
	while session.running do
		pcall(updateLabels)
		pcall(refreshLists)
		task.wait(1)
	end
end)

Library:OnUnload(function()
	session.running = false
	if LocalPlayer:GetAttribute("IsSquatting") == true then
		fire(StopSquattingRequest)
	end
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()