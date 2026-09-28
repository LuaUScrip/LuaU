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
	GameName = "Shuffle an Egg",
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

local enabled = {levelUp = true}
local settings = {lastPick = 0}
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

local GameHandShake = waitRemote("GameHandShake")
local CollectMoney = waitRemote("CollectMoney")
local PetEgg = waitRemote("PetEgg")
local OpenEgg = waitRemote("OpenEgg")
local PlaceEgg = waitRemote("PlaceEgg")
local EquipBestAnimals = waitRemote("EquipBestAnimals")
local PlaceAnimal = waitRemote("PlaceAnimal")
local LevelUpAnimal = waitRemote("LevelUpAnimal")
local BuyCup = waitRemote("BuyCup")
local EquipCup = waitRemote("EquipCup")
local BuyDealer = waitRemote("BuyDealer")
local EquipDealer = waitRemote("EquipDealer")
local Upgrade = waitRemote("Upgrade")
local Rebirth = waitRemote("Rebirth")
local UsePotion = waitRemote("UsePotion")
local GetQuestData = waitRemote("GetQuestData")

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = call(GetQuestData)
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

local function myBase()
	local bases = Workspace:FindFirstChild("Base")
	if not bases then
		return nil
	end
	for _, entry in ipairs(bases:GetChildren()) do
		if entry:GetAttribute("Owner") == LocalPlayer.Name then
			return entry
		end
	end
	for _, entry in ipairs(bases:GetChildren()) do
		local owner = entry:GetAttribute("OwnerId") or entry:GetAttribute("UserId")
		if owner == LocalPlayer.UserId then
			return entry
		end
	end
	return nil
end

local function childList(base, name)
	if not base then
		return {}
	end
	local folder = base:FindFirstChild(name)
	if not folder then
		return {}
	end
	return folder:GetChildren()
end

local function getMoney()
	return tonumber(statValue("Money", "Cash", "Coins")) or 0
end

local function getGamesPlayed()
	return tonumber(statValue("GamesPlayed")) or 0
end

local function getSelected()
	return tostring(read(function()
		return statValue("Selected")
	end) or "")
end

local function getRebirths()
	return tonumber(statValue("Rebirths", "Rebirth")) or 0
end

local function getAnimals()
	return #childList(myBase(), "Animals")
end

local function getEggs()
	return #childList(myBase(), "Eggs")
end

local function getEggCapacity()
	local base = myBase()
	if not base then
		return tonumber(statValue("EggCapacity", "EggsCapacity", "Capacity")) or 10
	end
	local value = read(function()
		return base:GetAttribute("EggCapacity")
	end) or read(function()
		return base:GetAttribute("EggsCapacity")
	end) or read(function()
		return base:GetAttribute("Capacity")
	end) or read(function()
		return base:GetAttribute("MaxEggs")
	end)
	return tonumber(value) or tonumber(statValue("EggCapacity", "EggsCapacity", "Capacity")) or 10
end

local function getHatching()
	local total = 0
	for _, pod in ipairs(childList(myBase(), "Eggs")) do
		if tonumber(pod:GetAttribute("HatchAt")) then
			total = total + 1
		end
	end
	return total
end

local EGG_IDS = {
	"basic_egg", "frogs_egg", "bats_egg", "tigers_egg", "trex_egg", "snails_egg",
	"capybara_egg", "osctrich_egg", "snake_egg", "sphinx_egg", "mouse_egg",
	"polarbear_egg", "seal_egg", "gorilla_egg", "mamut_egg", "talon_egg",
	"flame_egg", "angelic_egg", "unicorn_egg", "dragon_egg",
}

local CUP_LADDER = {
	"Red", "Blue", "Green", "Orange", "Pink Studs", "Orange Studs", "Babushka",
	"Nuclear", "Radioactive", "Jester", "Weight", "Prestige Weight",
}

local DEALER_LADDER = {
	"Default", "Devil", "Angel", "Galaxy", "Golden", "Rainbow", "Candy",
	"Glitch", "Cybrpg", "Sea", "Cosmic",
}

local function ladderRank(ladder, name)
	for index = 1, #ladder do
		if ladder[index] == name then
			return index
		end
	end
	return 0
end

local UPGRADE_KEYS = {
	{Key = "Tourist", Flag = "upgradeTourist", Text = "Upgrade Tourist"},
	{Key = "Base", Flag = "upgradeBase", Text = "Upgrade Base"},
	{Key = "Dealer", Flag = "upgradeDealer", Text = "Upgrade Dealer"},
	{Key = "MovementSpeed", Flag = "upgradeSpeed", Text = "Upgrade Movement Speed"},
}

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local SHUFFLE_PERMS = {
	[1] = {1, 3, 2},
	[2] = {1, 3, 2},
	[3] = {2, 1, 3},
	[4] = {2, 1, 3},
	[5] = {3, 2, 1},
	[6] = {3, 2, 1},
}

local shuffleState = {sequence = "", pick = 0, won = false, busy = false, played = 0, started = 0, tries = 0, wins = 0, slots = {0, 0, 0}}

task.spawn(function()
	local ok, err = pcall(function()
		if not GameHandShake then
			return
		end
		GameHandShake.OnClientEvent:Connect(function(action, payload)
			if action == "ShuffleSequence" and type(payload) == "table" and type(payload.Sequence) == "table" then
				shuffleState.sequence = table.concat(payload.Sequence, "+")
			elseif action == "RevealResult" and type(payload) == "table" then
				shuffleState.pick = tonumber(payload.CorrectCup) or 0
				shuffleState.won = payload.Won == true
				shuffleState.sequence = ""
				shuffleState.tries = shuffleState.tries + 1
				if shuffleState.won then
					shuffleState.wins = shuffleState.wins + 1
				end
				if shuffleState.won and shuffleState.pick >= 1 and shuffleState.pick <= 3 then
					shuffleState.slots[shuffleState.pick] = shuffleState.slots[shuffleState.pick] + 1
				end
			end
		end)
	end)
	if not ok then
		logError(err)
	end
end)

local function bestSlot()
	if shuffleState.tries < 3 then
		return 2
	end
	local best, bestWins = 0, 0
	for index = 1, 3 do
		local wins = shuffleState.slots[index] or 0
		if wins > bestWins then
			bestWins = wins
			best = index
		end
	end
	if best <= 0 then
		return 2
	end
	return best
end

local function solvePick(sequence)
	local slots = {"Cup1", "Cup2", "Cup3"}
	if type(sequence) ~= "string" or sequence == "" then
		return 2
	end
	for token in string.gmatch(sequence, "Shuffle(%d)") do
		local perm = SHUFFLE_PERMS[tonumber(token)]
		if not perm then
			return 2
		end
		local moved = {}
		for index = 1, 3 do
			moved[index] = slots[perm[index]]
		end
		slots = moved
	end
	for index = 1, 3 do
		if slots[index] == "Cup2" then
			return index
		end
	end
	return 2
end

local POTION_FALLBACK = { "Luck", "Cash" }

local function potionKinds()
	local data = getPlayerData()
	if type(data) == "table" then
		for _, key in ipairs({ "Potions", "Potion", "PotionList", "Items" }) do
			local entry = data[key]
			if type(entry) == "table" then
				local list = {}
				for name in pairs(entry) do
					table.insert(list, tostring(name))
				end
				if #list > 0 then
					return list
				end
			end
		end
	end
	return POTION_FALLBACK
end

local function ownedNames(holder)
	local owned = {}
	local node = LocalPlayer:FindFirstChild(holder)
	if not node then
		return owned
	end
	for _, entry in ipairs(node:GetChildren()) do
		owned[entry.Name] = true
	end
	return owned
end

local function findTool(wanted)
	local containers = {LocalPlayer:FindFirstChildOfClass("Backpack"), getCharacter()}
	for index = 1, #containers do
		local container = containers[index]
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool:FindFirstChild("UID") then
					if wanted == nil or tool.Name == wanted then
						return tool
					end
				end
			end
		end
	end
	return nil
end

local function findEggTool()
	for index = #EGG_IDS, 1, -1 do
		local tool = findTool(EGG_IDS[index])
		if tool then
			return tool
		end
	end
	return findTool()
end

local function plotFloor(base)
	local plot = base and base:FindFirstChild("Plot")
	if not plot then
		return nil
	end
	local best, bestArea = nil, 0
	for _, part in ipairs(plot:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Floor" then
			local area = part.Size.X * part.Size.Z
			if area > bestArea then
				bestArea = area
				best = part
			end
		end
	end
	return best
end

local function doAutoShufflePlay()
	if not enabled.play or not GameHandShake then
		return
	end
	if not ready("shufflePlay", 2) then
		return
	end
	if shuffleState.busy then
		return
	end
	shuffleState.played = getGamesPlayed()
	shuffleState.started = tick()
	setFarmStatus("starting round")
	fire(GameHandShake, "Play")
	task.wait(0.4)
	fire(GameHandShake, "Select")
	task.wait(0.6)
	setFarmStatus("shuffling cups")
	fire(GameHandShake, "StartShuffle")
	shuffleState.busy = true
	shuffleState.sequence = ""
end

local function doAutoShufflePick()
	if not enabled.buyEgg or not GameHandShake then
		return
	end
	if not ready("shufflePick", 0.3) then
		return
	end
	local pick = 2
	if shuffleState.sequence ~= "" then
		pick = solvePick(shuffleState.sequence)
	else
		if not ready("pickBlind", 4) then
			setFarmStatus("watching shuffle")
			return
		end
		pick = bestSlot()
	end
	settings.lastPick = pick
	setFarmStatus("picking cup " .. pick)
	fire(GameHandShake, "PickCup", pick)
	shuffleState.busy = false
	shuffleState.sequence = ""
	task.wait(2)
end

local function doAutoShuffleWatch()
	if not (enabled.play or enabled.buyEgg) then
		return
	end
	if not ready("shuffleWatch", 0.5) then
		return
	end
	if not shuffleState.busy then
		return
	end
	if getGamesPlayed() > shuffleState.played then
		shuffleState.busy = false
		shuffleState.sequence = ""
		setFarmStatus("round finished")
		if not shuffleState.won then
			fire(GameHandShake, "ExitGame")
		end
	elseif shuffleState.started > 0 and tick() - shuffleState.started > 60 then
		shuffleState.busy = false
		shuffleState.sequence = ""
		setFarmStatus("round reset")
		fire(GameHandShake, "ExitGame")
	end
end

local function doAutoCollect()
	if not enabled.collect or not CollectMoney then
		return
	end
	if not ready("collect", 0.5) then
		return
	end
	local pods = childList(myBase(), "Animals")
	if #pods == 0 then
		return
	end
	local taken = 0
	for index = 1, #pods do
		if not enabled.collect then
			break
		end
		local pod = pods[index]
		local animal = pod:GetAttribute("Animal")
		if animal and animal ~= "" then
			taken = taken + 1
			fire(CollectMoney, pod)
			task.wait(0.08)
		end
	end
	if taken == 0 then
		return
	end
	setFarmStatus("collecting cash")
end

local function doAutoPet()
	if not PetEgg then
		return
	end
	if not ready("pet", 0.5) then
		return
	end
	local pods = childList(myBase(), "Eggs")
	if #pods == 0 then
		return
	end
	for index = 1, #pods do
		fire(PetEgg, pods[index].Name)
		task.wait(0.1)
	end
end

local function doAutoOpenEggs()
	if not enabled.openEggs or not OpenEgg then
		return
	end
	if not ready("openEggs", 0.5) then
		return
	end
	local pods = childList(myBase(), "Eggs")
	if #pods == 0 then
		return
	end
	local opened = 0
	for index = 1, #pods do
		if not enabled.openEggs then
			break
		end
		local pod = pods[index]
		local hatch = tonumber(pod:GetAttribute("HatchAt")) or 0
		if hatch > 0 and hatch - os.time() < 1 then
			opened = opened + 1
			fire(OpenEgg, pod.Name)
			task.wait(0.3)
		end
	end
	if opened == 0 then
		return
	end
	setFarmStatus("hatching eggs")
end

local eggSpots = {}

local function pruneEggSpots()
	local now = os.clock()
	local kept = {}
	for index = 1, #eggSpots do
		if now - eggSpots[index].time < 3 then
			kept[#kept + 1] = eggSpots[index]
		end
	end
	eggSpots = kept
end

local function eggSlotTaken(slot, step, placed)
	local limit = step * step
	for index = 1, #eggSpots do
		local reserved = eggSpots[index].position
		local dx, dz = slot.X - reserved.X, slot.Z - reserved.Z
		if dx * dx + dz * dz < limit then
			return true
		end
	end
	for index = 1, #placed do
		local position = placed[index].Position
		local dx, dz = slot.X - position.X, slot.Z - position.Z
		if dx * dx + dz * dz < limit then
			return true
		end
	end
	return false
end

local function doAutoPlaceEgg()
	if not enabled.placeEgg or not PlaceEgg then
		return
	end
	if not ready("placeEgg", 0.5) then
		return
	end
	local base = myBase()
	if not base then
		return
	end
	pruneEggSpots()
	local capacity = getEggCapacity()
	local placed = childList(base, "Eggs")
	if #placed + #eggSpots >= capacity then
		return
	end
	local floor = plotFloor(base)
	if not floor then
		return
	end
	local tool = findEggTool()
	if not tool then
		return
	end
	local step = math.floor(math.min(floor.Size.X, floor.Size.Z) / 12)
	if step < 6 then
		step = 6
	end
	local columns = math.floor((floor.Size.X - step) / step)
	local rows = math.floor((floor.Size.Z - step) / step)
	if columns < 1 or rows < 1 then
		columns, rows = 1, 1
	end
	local y = floor.Position.Y + floor.Size.Y / 2
	local x0 = floor.Position.X - floor.Size.X / 2 + step / 2
	local z0 = floor.Position.Z - floor.Size.Z / 2 + step / 2
	setFarmStatus("placing egg")
	local sent = 0
	for iz = 0, rows - 1 do
		for ix = 0, columns - 1 do
			if #placed + #eggSpots >= capacity or sent >= 8 then
				return
			end
			local slot = Vector3.new(x0 + ix * step, y, z0 + iz * step)
			if not eggSlotTaken(slot, step, placed) then
				fire(PlaceEgg, tool.Name, slot, tool.UID.Value)
				table.insert(eggSpots, {position = slot, time = os.clock()})
				placed[#placed + 1] = {Position = slot}
				sent = sent + 1
				task.wait(0.12)
			end
		end
	end
end

local function doAutoEquipBest()
	if not enabled.equipBest or not EquipBestAnimals then
		return
	end
	if not ready("equipBest", 0.5) then
		return
	end
	setFarmStatus("equipping best")
	fire(EquipBestAnimals)
end

local function doAutoPlaceAnimal()
	if not enabled.placeAnimal or not PlaceAnimal then
		return
	end
	if not ready("placeAnimal", 0.5) then
		return
	end
	local pods = childList(myBase(), "Animals")
	local empty = nil
	for index = 1, #pods do
		local animal = pods[index]:GetAttribute("Animal")
		if not animal or animal == "" then
			empty = pods[index]
			break
		end
	end
	if not empty then
		return
	end
	local tool = findTool()
	if not tool then
		return
	end
	setFarmStatus("placing animal")
	fire(PlaceAnimal, "Request", empty, {Name = tool.Name, UID = tool.UID.Value})
end

local function doAutoLevelUp()
	if not LevelUpAnimal then
		return
	end
	if not ready("levelUp", 0.5) then
		return
	end
	local pods = childList(myBase(), "Animals")
	if #pods == 0 then
		return
	end
	for index = 1, #pods do
		local animal = pods[index]:GetAttribute("Animal")
		if animal and animal ~= "" then
			fire(LevelUpAnimal, pods[index])
			task.wait(0.2)
		end
	end
end

local function bestOwnedRank(ladder, holder)
	local best = 0
	for name in pairs(ownedNames(holder)) do
		local rank = ladderRank(ladder, name)
		if rank > best then
			best = rank
		end
	end
	return best
end

local function bestCupName()
	local best, rank = "", 0
	for name in pairs(ownedNames("Cups")) do
		local current = ladderRank(CUP_LADDER, name)
		if current > rank then
			rank = current
			best = name
		end
	end
	return best, rank
end

local function getEquippedCup()
	return tostring(statValue("EquippedCup", "CurrentCup", "CupEquipped") or "")
end

local function buyNextRarity(ladder, holder, remote)
	local owned = ownedNames(holder)
	local best = bestOwnedRank(ladder, holder)
	for index = best + 1, #ladder do
		if not owned[ladder[index]] then
			setFarmStatus("buying " .. ladder[index])
			fire(remote, ladder[index])
			return true
		end
	end
	return false
end

local function equipBestRarity(ladder, holder, remote)
	local best = 0
	for name in pairs(ownedNames(holder)) do
		local rank = ladderRank(ladder, name)
		if rank > best then
			best = rank
			setFarmStatus("equipping " .. name)
		end
	end
	if best <= 0 then
		return false
	end
	fire(remote, ladder[best])
	return true
end

local function doAutoBuyCup()
	if not enabled.buyCup or not BuyCup then
		return
	end
	if not ready("buyCup", 0.5) then
		return
	end
	buyNextRarity(CUP_LADDER, "Cups", BuyCup)
end

local function doAutoEquipCup()
	if not enabled.equipCup or not EquipCup then
		return
	end
	if not ready("equipCup", 0.5) then
		return
	end
	equipBestRarity(CUP_LADDER, "Cups", EquipCup)
end

local function doAutoBuyDealer()
	if not enabled.buyDealer or not BuyDealer then
		return
	end
	if not ready("buyDealer", 0.5) then
		return
	end
	buyNextRarity(DEALER_LADDER, "OwnedDealers", BuyDealer)
end

local function doAutoEquipDealer()
	if not enabled.equipDealer or not EquipDealer then
		return
	end
	if not ready("equipDealer", 0.5) then
		return
	end
	equipBestRarity(DEALER_LADDER, "OwnedDealers", EquipDealer)
end

local function doAutoUpgrade()
	if not Upgrade then
		return
	end
	local fired = 0
	for index = 1, #UPGRADE_KEYS do
		local entry = UPGRADE_KEYS[index]
		if enabled[entry.Flag] and ready("upg" .. entry.Key, 0.5) then
			fired = fired + 1
			setFarmStatus("upgrading " .. entry.Key)
			fire(Upgrade, entry.Key)
			task.wait(0.3)
		end
	end
	if fired == 0 then
		return
	end
end

local function doAutoRebirth()
	if not enabled.rebirth or not Rebirth then
		return
	end
	if not ready("rebirth", 0.5) then
		return
	end
	setFarmStatus("rebirthing")
	fire(Rebirth, "Rebirth")
end

local function doAutoPotion()
	if not enabled.potion or not UsePotion then
		return
	end
	if not ready("potion", 0.5) then
		return
	end
	local kinds = potionKinds()
	setFarmStatus("using potions")
	for index = 1, #kinds do
		if not enabled.potion then
			break
		end
		fire(UsePotion, kinds[index])
		task.wait(0.3)
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
			if okDecode and type(decoded.data) == "table" and decoded.data[1] then
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

local ShuffleTab = Tabs.Main:AddSubTab({ Name = "Shuffle", Icon = "dices" })
local FarmTab = Tabs.Main:AddSubTab({ Name = "Farm", Icon = "coins" })
local GearTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" })
local ExtrasTab = Tabs.Main:AddSubTab({ Name = "Extras", Icon = "gift" })

local ShuffleBox = box(ShuffleTab, "Auto Shuffle", "dices", "Left")
ShuffleBox:AddToggle("AutoPlay", { Text = "Auto Play", Default = false, Callback = function(value)
	enabled.play = value
end })
ShuffleBox:AddToggle("AutoBuyEgg", { Text = "Auto Buy Egg", Default = false, Callback = function(value)
	enabled.buyEgg = value
end })

local ShuffleInfoBox = box(ShuffleTab, "Game Info", "activity", "Right")
ShuffleInfoBox:AddLabel("ShuffleStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
ShuffleInfoBox:AddLabel("GamesPlayedLabel", { Text = paint("Played -", "0", COLORS.gold), DoesWrap = true })
ShuffleInfoBox:AddLabel("SelectedLabel", { Text = paint("Egg -", "none", COLORS.user), DoesWrap = true })
ShuffleInfoBox:AddLabel("PickLabel", { Text = paint("Pick -", "0", COLORS.orange), DoesWrap = true })
ShuffleInfoBox:AddLabel("BestSlotLabel", { Text = paint("Slot -", "2", COLORS.orange), DoesWrap = true })
ShuffleInfoBox:AddLabel("BestCupLabel", { Text = paint("Best -", "none", COLORS.gold), DoesWrap = true })
ShuffleInfoBox:AddLabel("CupRarityLabel", { Text = paint("Cup -", "0/12", COLORS.user), DoesWrap = true })
ShuffleInfoBox:AddLabel("EquippedCupLabel", { Text = paint("Equipped -", "none", COLORS.accent), DoesWrap = true })
ShuffleInfoBox:AddLabel("TargetLabel", { Text = paint("Wins -", "0", COLORS.user), DoesWrap = true })

local CashBox = box(FarmTab, "Cash & Eggs", "coins", "Left")
CashBox:AddToggle("AutoCollect", { Text = "Collect Animal Cash", Default = false, Callback = function(value)
	enabled.collect = value
end })
CashBox:AddToggle("AutoOpenEggs", { Text = "Open Hatched Eggs", Default = false, Callback = function(value)
	enabled.openEggs = value
end })
CashBox:AddToggle("AutoPlaceEgg", { Text = "Place Egg", Default = false, Callback = function(value)
	enabled.placeEgg = value
end })

local FarmInfoBox = box(FarmTab, "Game Info", "activity", "Right")
FarmInfoBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("MoneyLabel", { Text = paint("Cash -", "0", COLORS.gold), DoesWrap = true })
FarmInfoBox:AddLabel("AnimalsLabel", { Text = paint("Pets -", "0", COLORS.user), DoesWrap = true })
FarmInfoBox:AddLabel("EggsLabel", { Text = paint("Eggs -", "0", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("HatchingLabel", { Text = paint("Hatch -", "0", COLORS.accent), DoesWrap = true })
FarmInfoBox:AddLabel("CapacityLabel", { Text = paint("Cap -", "0/10", COLORS.user), DoesWrap = true })

local AnimalsBox = box(FarmTab, "Animals", "paw-print", "Left")
AnimalsBox:AddToggle("AutoEquipBest", { Text = "Equip Best Animals", Default = false, Callback = function(value)
	enabled.equipBest = value
end })
AnimalsBox:AddToggle("AutoPlaceAnimal", { Text = "Place Animal", Default = false, Callback = function(value)
	enabled.placeAnimal = value
end })

local CupBox = box(GearTab, "Cups", "cup-soda", "Left")
CupBox:AddToggle("AutoBuyCup", { Text = "Buy Next Rarity Cup", Default = false, Callback = function(value)
	enabled.buyCup = value
end })
CupBox:AddToggle("AutoEquipCup", { Text = "Equip Best Rarity Cup", Default = false, Callback = function(value)
	enabled.equipCup = value
end })

local DealerBox = box(GearTab, "Dealers", "users", "Left")
DealerBox:AddToggle("AutoBuyDealer", { Text = "Buy Next Rarity Dealer", Default = false, Callback = function(value)
	enabled.buyDealer = value
end })
DealerBox:AddToggle("AutoEquipDealer", { Text = "Equip Best Rarity Dealer", Default = false, Callback = function(value)
	enabled.equipDealer = value
end })

local UpgradeBox = box(GearTab, "Upgrades", "arrow-up", "Right")
for index = 1, #UPGRADE_KEYS do
	local entry = UPGRADE_KEYS[index]
	UpgradeBox:AddToggle(entry.Flag, { Text = entry.Text, Default = false, Callback = function(value)
		enabled[entry.Flag] = value
	end })
end

local RebirthBox = box(ExtrasTab, "Rebirth", "refresh-cw", "Left")
RebirthBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })

local PotionBox = box(ExtrasTab, "Potions", "flask-conical", "Left")
PotionBox:AddToggle("AutoPotion", { Text = "Use Potions", Default = false, Callback = function(value)
	enabled.potion = value
end })

local ExtrasInfoBox = box(ExtrasTab, "Game Info", "activity", "Right")
ExtrasInfoBox:AddLabel("RebirthStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
ExtrasInfoBox:AddLabel("RebirthsLabel", { Text = paint("Rebirths -", "0", COLORS.orange), DoesWrap = true })

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
	setLabel("SessionTime", paint("Time -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("ServerPlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
	setLabel("ShuffleStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("GamesPlayedLabel", paint("Played -", abbreviateNumber(getGamesPlayed()), COLORS.gold))
	local selected = getSelected()
	setLabel("SelectedLabel", paint("Egg -", selected ~= "" and selected or "none", COLORS.user))
	setLabel("PickLabel", paint("Pick -", tostring(settings.lastPick or 0), COLORS.orange))
	setLabel("BestSlotLabel", paint("Slot -", tostring(bestSlot()), COLORS.orange))
	local bestCup, cupRank = bestCupName()
	setLabel("BestCupLabel", paint("Best -", bestCup ~= "" and bestCup or "none", COLORS.gold))
	setLabel("CupRarityLabel", paint("Cup -", string.format("%d/%d", cupRank, #CUP_LADDER), COLORS.user))
	local equipped = getEquippedCup()
	setLabel("EquippedCupLabel", paint("Equipped -", equipped ~= "" and equipped or "none", COLORS.accent))
	setLabel("TargetLabel", paint("Wins -", tostring(shuffleState.wins or 0), COLORS.user))
	setLabel("FarmStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("MoneyLabel", paint("Cash -", abbreviateNumber(getMoney()), COLORS.gold))
	setLabel("AnimalsLabel", paint("Pets -", getAnimals(), COLORS.user))
	setLabel("EggsLabel", paint("Eggs -", getEggs(), COLORS.accent))
	setLabel("HatchingLabel", paint("Hatch -", getHatching(), COLORS.accent))
	setLabel("CapacityLabel", paint("Cap -", string.format("%d/%d", getEggs(), getEggCapacity()), COLORS.user))
	setLabel("RebirthStatusLabel", paint("Status -", farmStatus, COLORS.accent))
	setLabel("RebirthsLabel", paint("Rebirths -", abbreviateNumber(getRebirths()), COLORS.orange))
end

local function refreshLists()
	if not ready("lists", 15) then
		return
	end
	if not myBase() then
		setFarmStatus("no base")
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

chain({ doAutoShufflePlay }, 0.3)
chain({ doAutoShufflePick }, 0.3)
loop(doAutoShuffleWatch, 0.5)
chain({ doAutoCollect }, 0.5)
chain({ doAutoPet }, 0.5)
loop(doAutoOpenEggs, 0.5)
loop(doAutoPlaceEgg, 0.5)
loop(doAutoEquipBest, 0.5)
loop(doAutoPlaceAnimal, 0.5)
loop(doAutoLevelUp, 0.5)
loop(doAutoBuyCup, 0.5)
loop(doAutoEquipCup, 0.5)
loop(doAutoBuyDealer, 0.5)
loop(doAutoEquipDealer, 0.5)
loop(doAutoUpgrade, 0.5)
loop(doAutoRebirth, 0.5)
loop(doAutoPotion, 0.5)

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
		task.wait(0.5)
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