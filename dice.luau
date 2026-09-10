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

local enabled = {}
local settings = {tower = "Infinity Tower", shopItem = ""}
local traitSettings = {unit = ""}
local gradeSettings = {unit = ""}
local sessionStart = tick()
local detectedCapacity = nil

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

local network = ReplicatedStorage:WaitForChild("Network", 15)

local RollDice = find(network, "RollService", "RF", "RollDice")
local EquipBest = find(network, "PlotService", "RE", "EquipBest")
local LevelUpSlot = find(network, "PlotService", "RE", "LevelUpSlot")
local CollectBalance = find(network, "PlotService", "RE", "CollectBalance")
local BuyUpgrade = find(network, "RE", "BuyUpgrade")
if not BuyUpgrade and network then
	--// UpgradeService registers its signal straight on Network (Network.Server.CreateSignal),
	--// so the RemoteEvent can live at Network.BuyUpgrade instead of Network.RE.BuyUpgrade
	BuyUpgrade = network:FindFirstChild("BuyUpgrade", true)
end
local BuyDice = find(network, "DiceShopService", "RE", "BuyDice")
local EquipDice = find(network, "DiceShopService", "RE", "EquipDice")
local EquipTowerTeam = find(network, "Towers", "RE", "EquipBestTowerTeam")
local PlayTower = find(network, "Towers", "RF", "PlayTower")
local CompleteTowerFloor = find(network, "Towers", "RF", "CompleteTowerFloor")
local UseBoost = find(network, "BoostService", "RE", "Use")
local SellInventory = find(network, "SellService", "RF", "SellInventory")
local ClaimQuest = find(network, "QuestService", "RE", "Claim")
local BuyQuestItem = find(network, "QuestService", "RE", "Buy")
local RollTrait = find(network, "TraitService", "RE", "Roll")
if not RollTrait and network then
	--// TraitService uses NetworkComm as well; search inside its folder as a fallback
	local traitFolder = network:FindFirstChild("TraitService")
	if traitFolder then
		RollTrait = traitFolder:FindFirstChild("Roll", true)
	end
end
local Rebirth = find(network, "RebirthService", "RE", "Rebirth")
local RollGrade = find(network, "GradeService", "RE", "Roll")
if not RollGrade and network then
	--// GradeService uses NetworkComm too; search inside its folder as a fallback
	local gradeFolder = network:FindFirstChild("GradeService")
	if gradeFolder then
		RollGrade = gradeFolder:FindFirstChild("Roll", true)
	end
end

local Data = loadModule("Framework", "Features", "Data", "DataController")
local EntryRegistry = loadModule("Framework", "Features", "Inventory", "EntryRegistry")
local DiceConfig = loadModule("Framework", "Features", "Rolling", "Dice")
local QuestConfig = loadModule("Framework", "Features", "Quests", "QuestConfig")
local UpgradeConfig = loadModule("Framework", "Features", "Upgrades", "Upgrades")
local TreeStructure = loadModule("Framework", "Features", "Upgrades", "TreeStructure")
local UnitConfig = loadModule("Framework", "Features", "Inventory", "Kinds", "Unit", "UnitConfig")
local DataSettings = loadModule("Framework", "Features", "Data", "DataSettings")

local KNOWN_RARITIES = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Exotic", "Celestial", "Secret"}

local function getEntryConfig(name)
	if type(EntryRegistry) == "table" and type(EntryRegistry.getEntryConfig) == "function" then
		local ok, config = pcall(EntryRegistry.getEntryConfig, name)
		if ok and type(config) == "table" then
			return config
		end
	end
	return nil
end

local function rarityOf(name)
	local config = getEntryConfig(name)
	if config and config.rarity then
		return tostring(config.rarity)
	end
	if type(UnitConfig) == "table" and type(UnitConfig.Get) == "function" then
		local ok, unit = pcall(UnitConfig.Get, name)
		if ok and type(unit) == "table" and unit.rarity then
			return tostring(unit.rarity)
		end
	end
	return nil
end

local function getInventory()
	return read(function()
		return Data.Inventory()
	end)
end

local function buildRarityList()
	local found = {}
	local entries = type(UnitConfig) == "table" and UnitConfig.entries
	if type(entries) == "table" then
		for _, config in pairs(entries) do
			if type(config) == "table" and config.rarity then
				found[tostring(config.rarity)] = true
			end
		end
	end
	local inventory = getInventory()
	if type(inventory) == "table" then
		for _, entry in pairs(inventory) do
			if type(entry) == "table" and entry.name then
				local rarity = rarityOf(entry.name)
				if rarity then
					found[rarity] = true
				end
			end
		end
	end
	local ordered, seen = {}, {}
	for _, rarity in ipairs(KNOWN_RARITIES) do
		if found[rarity] then
			table.insert(ordered, rarity)
			seen[rarity] = true
		end
	end
	local extras = {}
	for rarity in pairs(found) do
		if not seen[rarity] then
			table.insert(extras, rarity)
		end
	end
	table.sort(extras)
	for _, rarity in ipairs(extras) do
		table.insert(ordered, rarity)
	end
	if #ordered == 0 then
		return KNOWN_RARITIES
	end
	return ordered
end

local RARITIES = buildRarityList()

local function inventoryUnitCount()
	local inventory = getInventory()
	if type(inventory) ~= "table" then
		return 0
	end
	local count = 0
	for _, entry in pairs(inventory) do
		if type(entry) == "table" and entry.name then
			local config = getEntryConfig(entry.name)
			if config and config.kind == "Unit" then
				count += tonumber(entry.amount) or 1
			end
		end
	end
	return count
end

local function capacityKey(name)
	name = string.lower(name)
	local scale = string.find(name, "max", 1, true) or string.find(name, "limit", 1, true) or string.find(name, "capacity", 1, true) or string.find(name, "size", 1, true)
	local scope = string.find(name, "inv", 1, true) or string.find(name, "unit", 1, true) or string.find(name, "slot", 1, true) or string.find(name, "storage", 1, true)
	return scale ~= nil and scope ~= nil
end

local function scanCapacity(source)
	if type(source) ~= "table" then
		return nil
	end
	for key, value in pairs(source) do
		if type(key) == "string" and capacityKey(key) then
			local amount = numberFrom(value)
			if amount and amount > 0 then
				return math.floor(amount)
			end
		end
	end
	for key, value in pairs(source) do
		if type(key) == "string" and type(value) == "table" then
			local scope = string.find(string.lower(key), "inv", 1, true) or string.find(string.lower(key), "unit", 1, true) or string.find(string.lower(key), "slot", 1, true)
			if scope then
				for innerKey, innerValue in pairs(value) do
					if type(innerKey) == "string" and capacityKey(innerKey) then
						local amount = numberFrom(innerValue)
						if amount and amount > 0 then
							return math.floor(amount)
						end
					end
				end
			end
		end
	end
	return nil
end

local function findCapacity()
	return scanCapacity(Data) or scanCapacity(DataSettings)
end

local function equippedKey()
	if type(Data) ~= "table" then
		return nil
	end
	for _, field in ipairs({"Equipped", "EquippedUnit", "GetEquipped", "Holding"}) do
		local getter = Data[field]
		if type(getter) == "function" then
			local ok, value = pcall(getter, Data)
			if ok and type(value) == "string" then
				return value
			end
		end
	end
	return nil
end

--// SAFETY: only true Units may ever be sold — potions/boosts/other kinds are
--// skipped even when their rarity is selected. Unknown entries (config unreadable)
--// are also skipped rather than risked.
local function isUnitEntry(entry)
	if type(entry) ~= "table" or type(entry.name) ~= "string" then
		return false
	end
	local config = getEntryConfig(entry.name)
	if config then
		return config.kind == "Unit"
	end
	--// fallback: UnitConfig.Get(name) may expose the kind too
	if type(UnitConfig) == "table" and type(UnitConfig.Get) == "function" then
		local ok, unit = pcall(UnitConfig.Get, entry.name)
		if ok and type(unit) == "table" and unit.kind ~= nil then
			return unit.kind == "Unit"
		end
	end
	if entry.kind ~= nil then
		return entry.kind == "Unit"
	end
	return false --// can't confirm it's a Unit -> don't touch it
end

local function collectKeys(allowedRarities)
	local inventory = getInventory()
	if type(inventory) ~= "table" then
		return nil
	end
	local heldKey = equippedKey()
	local keys = {}
	for key, entry in pairs(inventory) do
		if type(entry) == "table" and entry.name and key ~= heldKey then
			local attributes = entry.attributes
			if not (type(attributes) == "table" and attributes.locked) then
				if not isUnitEntry(entry) then
					continue --// never sell potions/boosts/unknown kinds
				end
				if not allowedRarities then
					table.insert(keys, key)
				else
					local rarity = rarityOf(entry.name)
					if rarity and allowedRarities[rarity] then
						table.insert(keys, key)
					end
				end
			end
		end
	end
	return keys
end

local function sellRarities()
	if not SellInventory then
		return
	end
	local chosen = selectedValues(Options.SellRarities)
	if not next(chosen) then
		return
	end
	local keys = collectKeys(chosen)
	if keys and #keys > 0 then
		call(SellInventory, keys)
	end
end

local function autoRoll()
	if enabled.roll and RollDice then
		call(RollDice)
	end
end

local function autoEquipBest()
	if enabled.equipBest and EquipBest then
		fire(EquipBest)
	end
end

local function autoCollect()
	if not enabled.collect then
		return
	end
	for slot = 1, 10 do
		fire(CollectBalance, slot)
	end
end

local function autoSlots()
	if not enabled.slots then
		return
	end
	for slot = 1, 10 do
		fire(LevelUpSlot, slot)
	end
end

local function autoRebirth()
	if enabled.rebirth and Rebirth then
		fire(Rebirth)
	end
end

local diceCatalog = {}
if type(DiceConfig) == "table" and type(DiceConfig.GetAll) == "function" then
	local ok, all = pcall(DiceConfig.GetAll)
	if ok and type(all) == "table" then
		for name, config in pairs(all) do
			if type(config) == "table" and config.luck then
				table.insert(diceCatalog, {name = tostring(name), luck = config.luck, price = config.price})
			end
		end
		table.sort(diceCatalog, function(a, b)
			return a.luck < b.luck
		end)
	end
end

local function autoDice()
	if not enabled.dice then
		return
	end
	local owned = read(function()
		return Data.OwnedDice()
	end) or {}
	local bestOwned
	for _, dice in ipairs(diceCatalog) do
		if owned[dice.name] then
			bestOwned = dice.name
		end
	end
	local equipped = read(function()
		return Data.Dice()
	end)
	if bestOwned and equipped ~= bestOwned then
		fire(EquipDice, bestOwned)
	end
	local money = tonumber(read(function()
		return Data.Money()
	end)) or 0
	for index = #diceCatalog, 1, -1 do
		local dice = diceCatalog[index]
		if dice.price and not owned[dice.name] and money >= dice.price then
			fire(BuyDice, dice.name)
			break
		end
	end
end

local function autoPotion()
	if not enabled.potion or not UseBoost then
		return
	end
	local inventory = getInventory()
	if type(inventory) ~= "table" then
		return
	end
	local activeSet = {}
	local active = read(function()
		return Data.ActiveEntries()
	end)
	if type(active) == "table" then
		for key, value in pairs(active) do
			activeSet[tostring(key)] = true
			if type(value) == "table" and value.name then
				activeSet[tostring(value.name)] = true
			end
		end
	end
	for _, entry in pairs(inventory) do
		if type(entry) == "table" and entry.name then
			local config = getEntryConfig(entry.name)
			if config and config.kind == "Boost" and (tonumber(entry.amount) or 0) > 0 and not activeSet[entry.name] then
				fire(UseBoost, entry.name)
			end
		end
	end
end

--// UPGRADES: name -> {price}, ownership via Data.Upgrades[name](), tree via TreeStructure
local UPGRADE_NAMES = {}
local UPGRADE_PRICES = {}

local function collectUpgrades(result)
	if type(result) ~= "table" then
		return
	end
	for key, value in pairs(result) do
		if type(key) == "string" and key ~= "Start" and type(value) == "table" then
			for _, field in ipairs({"Price", "Cost", "price", "cost"}) do
				if type(value[field]) == "number" then
					UPGRADE_NAMES[key] = true
					UPGRADE_PRICES[key] = value[field]
					break
				end
			end
		end
	end
end

local function scanUpgrades()
	collectUpgrades(UpgradeConfig)
	if type(UpgradeConfig) == "table" and type(UpgradeConfig.GetAll) == "function" then
		local ok, all = pcall(UpgradeConfig.GetAll)
		if ok then
			collectUpgrades(all)
		end
	end
	return toList(UPGRADE_NAMES)
end

local UPGRADES = scanUpgrades()
local upgradeIndex = 0

--// NOTE: DataController's getters (Data.Upgrades[name]) are STATE objects called
--// with () through the __call metamethod — they are NOT type "function". The old
--// type-check made the owned-check always return false, which is why it kept
--// trying to buy upgrades you already own. callValue() calls anything callable.
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

local function isUpgradeOwned(name)
	local root = type(Data) == "table" and Data.Upgrades or nil
	if root == nil then
		return false
	end
	--// indexing works for plain tables AND state containers (__index)
	local getter
	pcall(function()
		getter = root[name]
	end)
	--// Data.Upgrades may itself be a function that returns the state table
	if getter == nil and type(root) == "function" then
		local state = callValue(root)
		if type(state) == "table" then
			getter = state[name]
		end
	end
	if getter == true then
		return true
	end
	if getter == nil then
		--// last resort: Data.Upgrades(name) call shape
		local ok, value = pcall(root, name)
		if ok and value == true then
			return true
		end
		return false
	end
	--// getter is a state object (callable) / function / boolean
	local value = callValue(getter)
	if value ~= nil then
		return value == true
	end
	return false
end

local function upgradeParentReady(name)
	if type(TreeStructure) == "table" and type(TreeStructure.GetParent) == "function" then
		local ok, parent = pcall(TreeStructure.GetParent, name)
		if ok and parent and parent ~= "Start" then
			return isUpgradeOwned(parent)
		end
	end
	return true
end

local recentBought = {}

local function autoUpgrade()
	if not enabled.upgrades or not BuyUpgrade then
		return
	end
	if #UPGRADES == 0 then
		UPGRADES = scanUpgrades()
		if #UPGRADES == 0 then
			return
		end
	end
	local money = tonumber(read(function()
		return Data.Money()
	end)) or 0
	if money <= 0 then
		return
	end
	for _ = 1, #UPGRADES do
		upgradeIndex = upgradeIndex % #UPGRADES + 1
		local name = UPGRADES[upgradeIndex]
		--// only buy upgrades that are: NOT owned + parent owned (unlocked) + affordable
		if name ~= "Start"
			and not (recentBought[name] and tick() - recentBought[name] < 3)
			and not isUpgradeOwned(name)
			and upgradeParentReady(name)
		then
			local price = UPGRADE_PRICES[name]
			if price and money >= price then
				recentBought[name] = tick()
				fire(BuyUpgrade, name)
				return
			end
		end
	end
end

--// QUEST SHOP: QuestConfig.Shop is an ARRAY of {name, amount, tickets, gamepass?}
local function questShopList()
	local found = {}
	if type(QuestConfig) ~= "table" then
		return found
	end
	local shop = QuestConfig.Shop
	if type(shop) == "table" then
		for _, item in ipairs(shop) do
			if type(item) == "table" and type(item.name) == "string" and not item.gamepass then
				table.insert(found, item.name)
			end
		end
	end
	if #found == 0 then
		for _, key in ipairs({"ShopItems", "Store", "Items"}) do
			local table_ = QuestConfig[key]
			if type(table_) == "table" then
				for name in pairs(table_) do
					if type(name) == "string" then
						table.insert(found, name)
					end
				end
				if next(found) then
					break
				end
			end
		end
	end
	table.sort(found)
	return found
end

local SHOP_ITEMS = questShopList()

local function autoQuestShop()
	if not enabled.questShop or settings.shopItem == "" or not BuyQuestItem then
		return
	end
	fire(BuyQuestItem, settings.shopItem)
end

--// TRAITS: Framework/Features/Traits/Traits = name -> {order, weight, protected, ...}
--// TraitService/Roll(key, ignoreProtected) burns 1 "Trait Reroll" and rerolls the
--// unit's trait. ignoreProtected = true skips the client confirm dialog for
--// protected traits (Samurai/Shogun/Monarch/Transcendent).
local TraitsConfig = loadModule("Framework", "Features", "Traits", "Traits")

local TRAIT_NAMES = {}
if type(TraitsConfig) == "table" then
	local ordered = {}
	for name, config in pairs(TraitsConfig) do
		table.insert(ordered, {name = name, order = (type(config) == "table" and config.order) or 999})
	end
	table.sort(ordered, function(a, b)
		return a.order < b.order
	end)
	for _, trait in ipairs(ordered) do
		table.insert(TRAIT_NAMES, trait.name)
	end
end

local function unitList()
	local inventory = getInventory()
	local found = {}
	if type(inventory) ~= "table" then
		return found
	end
	for _, entry in pairs(inventory) do
		if type(entry) == "table" and entry.name then
			local config = getEntryConfig(entry.name)
			if config and config.kind == "Unit" then
				table.insert(found, entry.name)
			end
		end
	end
	table.sort(found)
	return found
end

local function unitKeyFor(name)
	local inventory = getInventory()
	if type(inventory) ~= "table" then
		return nil
	end
	for key, entry in pairs(inventory) do
		if type(entry) == "table" and entry.name == name then
			local config = getEntryConfig(entry.name)
			if config and config.kind == "Unit" then
				return key --// the remote wants the inventory KEY, not the name
			end
		end
	end
	return nil
end

local function unitTrait(key)
	local inventory = getInventory()
	local entry = type(inventory) == "table" and inventory[key]
	if type(entry) == "table" and type(entry.attributes) == "table" and type(entry.attributes.trait) == "string" then
		return entry.attributes.trait
	end
	return nil
end

local function rerollCount()
	local inventory = getInventory()
	local entry = type(inventory) == "table" and inventory["Trait Reroll"]
	if type(entry) == "table" then
		return tonumber(entry.amount) or 0
	end
	return 0
end

local function autoTraits()
	if not enabled.traits or not RollTrait then
		return
	end
	if traitSettings.unit == "" then
		return
	end
	local chosen = selectedValues(Options.TraitSelect)
	if not next(chosen) then
		return --// select at least one wanted trait first
	end
	local key = unitKeyFor(traitSettings.unit)
	if not key then
		return --// unit left the inventory (sold/etc.)
	end
	if rerollCount() < 1 then
		return --// out of Trait Rerolls
	end
	local trait = unitTrait(key)
	if trait and chosen[trait] then
		return --// already has a wanted trait -> stop, don't waste rerolls
	end
	--// protected traits are ALWAYS bypassed in the background (no UI toggle):
	--// second arg true = skips the game's protected-trait confirm dialog
	fire(RollTrait, key, true)
end

--// GRADES: Framework/Features/Grades/Grades = name -> {order, weight, protected, ...}
--// GradeService/Roll(key, ignoreProtected) burns 1 Gem and rerolls the unit's grade.
--// ignoreProtected = true skips the confirm dialog for protected grades (S/S+/Z/Z+).
local GradesConfig = loadModule("Framework", "Features", "Grades", "Grades")

local GRADE_NAMES = {}
if type(GradesConfig) == "table" then
	local ordered = {}
	for name, config in pairs(GradesConfig) do
		table.insert(ordered, {name = name, order = (type(config) == "table" and config.order) or 999})
	end
	table.sort(ordered, function(a, b)
		return a.order < b.order
	end)
	for _, grade in ipairs(ordered) do
		table.insert(GRADE_NAMES, grade.name)
	end
end

local function unitGrade(key)
	local inventory = getInventory()
	local entry = type(inventory) == "table" and inventory[key]
	if type(entry) == "table" and type(entry.attributes) == "table" and type(entry.attributes.grade) == "string" then
		return entry.attributes.grade
	end
	return nil
end

local function gemCount()
	local inventory = getInventory()
	local entry = type(inventory) == "table" and inventory["Gems"]
	if type(entry) == "table" then
		return tonumber(entry.amount) or 0
	end
	return 0
end

local function autoGrade()
	if not enabled.grades or not RollGrade then
		return
	end
	if gradeSettings.unit == "" then
		return
	end
	local chosen = selectedValues(Options.GradeSelect)
	if not next(chosen) then
		return --// select at least one wanted grade first
	end
	local key = unitKeyFor(gradeSettings.unit)
	if not key then
		return --// unit left the inventory (sold/etc.)
	end
	if gemCount() < 1 then
		return --// out of Gems
	end
	local grade = unitGrade(key)
	if grade and chosen[grade] then
		return --// already has a wanted grade -> stop, don't waste gems
	end
	--// protected grades are ALWAYS bypassed in the background (no UI toggle):
	--// second arg true = skips the game's protected-grade confirm dialog
	fire(RollGrade, key, true)
end

local function towerList()
	local found = {}
	for _, path in ipairs({{"Framework", "Features", "Towers", "TowerConfig"}, {"Framework", "Features", "Towers", "Towers"}}) do
		local module = loadModule(table.unpack(path))
		local source
		if type(module) == "table" then
			if type(module.GetAll) == "function" then
				local ok, result = pcall(module.GetAll)
				if ok then
					source = result
				end
			end
			source = source or module.Towers or module.entries
		end
		if type(source) == "table" then
			for name in pairs(source) do
				if type(name) == "string" then
					found[name] = true
				end
			end
			if next(found) then
				break
			end
		end
	end
	found["Infinity Tower"] = true
	return toList(found)
end

local TOWERS = towerList()

local function autoTowerTeam()
	if enabled.towerTeam and EquipTowerTeam then
		fire(EquipTowerTeam)
	end
end

--// Instan Tower runs as TWO loops (see LOOPS section at the bottom):
--//   0.5s -> PlayTower with the selected tower name (ALWAYS first)
--//   0.1s -> CompleteTowerFloor (no arguments, only AFTER PlayTower)
--// ORDERING: towerArmed blocks CompleteTowerFloor until the first PlayTower has
--// gone through, so PlayTower is guaranteed to fire first every time the toggle
--// is turned on. Both loop speeds stay exactly the same (0.5s / 0.1s).
local towerArmed = false

local function autoTowerPlay()
	if not enabled.tower or settings.tower == "" then
		return
	end
	call(PlayTower, settings.tower)
	towerArmed = true --// PlayTower done -> CompleteTowerFloor may now run
end

local function autoTowerFloor()
	if not enabled.tower or not towerArmed then
		return --// never before the first PlayTower
	end
	call(CompleteTowerFloor)
end

--// QUESTS: QuestConfig.Periods = {Daily = {quests = {..}}, Weekly = ..}
local function questPeriods()
	local periods = {}
	if type(QuestConfig) == "table" and type(QuestConfig.Periods) == "table" then
		for _, key in ipairs({"Daily", "Weekly"}) do
			if QuestConfig.Periods[key] then
				table.insert(periods, key)
			end
		end
	end
	return periods
end

local PERIODS = questPeriods()

local function autoQuests()
	if not enabled.quests or not ClaimQuest or #PERIODS == 0 then
		return
	end
	if type(Data) ~= "table" or type(Data.Quests) ~= "table" then
		return
	end
	for _, period in ipairs(PERIODS) do
		local state = read(function()
			return Data.Quests[period]()
		end)
		if type(state) == "table" then
			local expiresAt = state.expiresAt or 0
			local claimed = state.claimed
			local progress = state.progress
			local periodData = QuestConfig.Periods[period]
			local quests = type(periodData) == "table" and periodData.quests
			if type(claimed) == "table" and type(progress) == "table" and type(quests) == "table" then
				for _, quest in ipairs(quests) do
					if type(quest) == "table" and type(quest.id) == "string" and not claimed[quest.id] then
						local target = tonumber(quest.target)
						local current = tonumber(progress[quest.id]) or 0
						if not target or current >= target then
							fire(ClaimQuest, period, quest.id, expiresAt)
						end
					end
				end
			end
		end
	end
end

local function autoSellRarity()
	if enabled.sellRarity then
		sellRarities()
	end
end

local function autoSellFull()
	if not enabled.sellFull then
		return
	end
	if not detectedCapacity or detectedCapacity <= 0 then
		return
	end
	if inventoryUnitCount() >= detectedCapacity then
		sellRarities()
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
		{ Text = "Anime Dice", Copyable = true },
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
local ShopTab = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" })
local TowerTab = Tabs.Main:AddSubTab({ Name = "Tower", Icon = "castle" })

local FarmingBox = box(FarmTab, "Farming", "star", "Left")
FarmingBox:AddToggle("RollDice", { Text = "Auto Roll", Default = false, Callback = function(value)
	enabled.roll = value
end })
FarmingBox:AddToggle("CollectBalance", { Text = "Collect Cash", Default = false, Callback = function(value)
	enabled.collect = value
end })
FarmingBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })
FarmingBox:AddToggle("AutoPotions", { Text = "Use Potion", Default = false, Callback = function(value)
	enabled.potion = value
end })
FarmingBox:AddToggle("EquipBest", { Text = "Equip Best Unit", Default = false, Callback = function(value)
	enabled.equipBest = value
end })
FarmingBox:AddToggle("LevelSlots", { Text = "Upgrade Unit", Default = false, Callback = function(value)
	enabled.slots = value
end })

local GradeBox = box(FarmTab, "Auto Grade", "gem", "Left")
gradeSettings.unit = unitList()[1] or ""
GradeBox:AddDropdown("GradeSelectUnit", {
	Text = "Unit",
	Values = unitList(),
	Default = gradeSettings.unit,
	Callback = function(value)
		gradeSettings.unit = value or ""
	end,
})
GradeBox:AddDropdown("GradeSelect", {
	Text = "Select Grade",
	Values = GRADE_NAMES,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
	Tooltip = "Rerolling stops as soon as the unit gets one of these grades",
})
GradeBox:AddDivider()
GradeBox:AddToggle("AutoGrade", { Text = "Auto Grade", Default = false, Callback = function(value)
	enabled.grades = value
end })

local UnitBox = box(FarmTab, "Unit", "users", "Right")
UnitBox:AddDropdown("SellRarities", {
	Text = "Rarity to Sell",
	Values = RARITIES,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
	Tooltip = "Used by Auto Sell by Rarity and Auto Sell Full Inventory",
})
UnitBox:AddToggle("AutoSellRarity", { Text = "Sell Selected Rarity", Default = false, Callback = function(value)
	enabled.sellRarity = value
end })
UnitBox:AddToggle("AutoSellFullInv", { Text = "Sell When Full", Default = false, Callback = function(value)
	enabled.sellFull = value
end })

local TraitBox = box(FarmTab, "Auto Trait", "sparkles", "Right")
traitSettings.unit = unitList()[1] or ""
TraitBox:AddDropdown("TraitSelectUnit", {
	Text = "Unit",
	Values = unitList(),
	Default = traitSettings.unit,
	Callback = function(value)
		traitSettings.unit = value or ""
	end,
})
TraitBox:AddDropdown("TraitSelect", {
	Text = "Select Trait",
	Values = TRAIT_NAMES,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
	Tooltip = "Rerolling stops as soon as the unit gets one of these traits",
})
TraitBox:AddDivider()
TraitBox:AddToggle("AutoTraits", { Text = "Auto Traits", Default = false, Callback = function(value)
	enabled.traits = value
end })

local UpgradeBox = box(ShopTab, "Upgrades", "rocket", "Left")
UpgradeBox:AddToggle("AutoUpgrade", { Text = "Buy Affordable Upgrades", Default = false, Callback = function(value)
	enabled.upgrades = value
end })
UpgradeBox:AddToggle("AutoDice", { Text = "Buy & Equip Best Dice", Default = false, Callback = function(value)
	enabled.dice = value
end })

local QuestBox = box(ShopTab, "Quest", "ticket", "Right")
settings.shopItem = SHOP_ITEMS[1] or ""
QuestBox:AddDropdown("QuestShopSelect", {
	Text = "Item",
	Values = SHOP_ITEMS,
	Default = SHOP_ITEMS[1],
	Callback = function(value)
		settings.shopItem = value or ""
	end,
})
QuestBox:AddDivider()
QuestBox:AddToggle("ClaimQuests", { Text = "Claim Quest", Default = false, Callback = function(value)
	enabled.quests = value
end })
QuestBox:AddToggle("AutoQuestShop", { Text = "Buy Selected Item", Default = false, Callback = function(value)
	enabled.questShop = value
end })

local TowerBox = box(TowerTab, "Tower", "castle", "Left")
TowerBox:AddDropdown("TowerSelect", {
	Text = "Tower",
	Values = TOWERS,
	Default = settings.tower,
	Callback = function(value)
		settings.tower = value
	end,
})
TowerBox:AddToggle("EquipTowerTeam", { Text = "Best Tower Team", Default = false, Callback = function(value)
	enabled.towerTeam = value
end })
TowerBox:AddToggle("AutoTower", { Text = "Instan Tower", Default = false, Callback = function(value)
	enabled.tower = value
	towerArmed = false --// re-arm: PlayTower always fires first when (re)enabled
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

local ServerTools = box(Tabs.Settings, "Server", "server", "Right")
ServerTools:AddButton({ Text = "Reconnect", Func = reconnectServer })
ServerTools:AddButton({ Text = "Rejoin Server", Func = rejoinServer })
ServerTools:AddButton({ Text = "Server Hop (Lowest Players)", Func = serverHop })

SaveManager:SetLibrary(Library)
ThemeManager:SetLibrary(Library)

--// "Dark Silver" monochrome theme
--// Panel #151515 -> BackgroundColor, Secondary panel #1A1A1A -> MainColor,
--// Border #2A2A2A -> OutlineColor, Primary text #F5F5F5 -> FontColor,
--// Bright silver #E5E5E5 -> AccentColor. Button hover/active, secondary/muted
--// text etc. are derived by the library from these 5.
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
		ContrastLabel:Destroy() --// removes the row + resizes the groupbox cleanly
	end
	ThemeManager.ContrastLabel = nil
end)

local function updateLabels()
	if ready("capacity", 5) then
		detectedCapacity = findCapacity()
	end
	if not ready("labels", 1) then
		return
	end
	setLabel("SessionTime", paint("Session -", formatDuration(tick() - sessionStart), COLORS.orange))
	setLabel("PlayersLabel", paint("Players -", string.format("%d/%d", #Players:GetPlayers(), Players.MaxPlayers), COLORS.user))
end

local function refreshLists()
	if ready("upgscan", 15) and #UPGRADES == 0 then
		UPGRADES = scanUpgrades()
	end
	if ready("unitlist", 10) then
		pcall(function()
			local units = unitList()
			Options.TraitSelectUnit:SetValues(units)
			Options.GradeSelectUnit:SetValues(units)
			if traitSettings.unit == "" and #units > 0 then
				traitSettings.unit = units[1]
				Options.TraitSelectUnit:SetValue(units[1])
			end
			if gradeSettings.unit == "" and #units > 0 then
				gradeSettings.unit = units[1]
				Options.GradeSelectUnit:SetValue(units[1])
			end
		end)
	end
	if ready("shopscan", 15) and #SHOP_ITEMS == 0 then
		SHOP_ITEMS = questShopList()
		if #SHOP_ITEMS > 0 then
			pcall(function()
				Options.QuestShopSelect:SetValues(SHOP_ITEMS)
			end)
			settings.shopItem = SHOP_ITEMS[1]
			pcall(function()
				Options.QuestShopSelect:SetValue(SHOP_ITEMS[1])
			end)
		end
	end
	if not ready("lists", 10) then
		return
	end
	pcall(function()
		Options.SellRarities:SetValues(buildRarityList())
	end)
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

--// Fast Roll — 1s (as fast as possible)
loop("roll", autoRoll, 1)
--// Instan Tower — PlayTower (starts/selects the tower) — 0.5s
loop("tower", autoTowerPlay, 0.5)
--// Instan Tower — CompleteTowerFloor — 0.1s
loop("tower", autoTowerFloor, 0.1)
--// Equip Best Unit — 0.4s
loop("equipBest", autoEquipBest, 0.4)
--// Collect Cash — 0.5s
loop("collect", autoCollect, 0.5)
--// Upgrade Unit (slots) — 0.2s
loop("slots", autoSlots, 0.2)
--// Auto Rebirth — 0.2s
loop("rebirth", autoRebirth, 0.2)
--// Claim Quest — 0.3s
loop("quests", autoQuests, 0.3)
--// Auto Buy Selected Item (quest shop) — 3s
loop("questShop", autoQuestShop, 3)
--// Auto Traits — 0.5s
loop("traits", autoTraits, 0.5)
--// Auto Grade — 0.5s
loop("grades", autoGrade, 0.5)
--// Auto Buy & Equip Best Dice — 0.2s
loop("dice", autoDice, 0.2)
--// Use Potion — 0.3s
loop("potion", autoPotion, 0.3)
--// Auto Buy Affordable Upgrades — 0.2s
loop("upgrades", autoUpgrade, 0.2)
--// Best Tower Team — 1.5s
loop("towerTeam", autoTowerTeam, 1.5)
--// Auto Sell by Rarity — 0.2s
loop("sellRarity", autoSellRarity, 0.2)
--// Auto Sell Full Inventory — 0.1s
loop("sellFull", autoSellFull, 0.1)

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
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()