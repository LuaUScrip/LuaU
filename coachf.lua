local Repo = "https://raw.githubusercontent.com/LuaUScrip/HUB/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Toggles = Library.Toggles
local Options = Library.Options
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")
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
	GameName = "Coach a Fighter!",
}

local previous = getgenv().UnitGrinder
if previous then
	previous.running = false
	if type(previous.lib) == "table" and type(previous.lib.Unload) == "function" then
		pcall(function() previous.lib:Unload() end)
	end
end

local session = {running = true, lib = Library}
getgenv().UnitGrinder = session

local enabled = {}
local scriptState = {}
local sessionStart = tick()
local farmStatus = "idle"

local scriptConnections = {}
local function trackConnection(connection)
	table.insert(scriptConnections, connection)
	return connection
end

local function find(root, ...)
	local node = root
	for index = 1, select("#", ...) do
		node = node and node:FindFirstChild((select(index, ...)))
	end
	return node
end

local function fire(remote, ...)
	if remote then pcall(remote.FireServer, remote, ...) end
end

local function call(remote, ...)
	if remote then
		local ok, result = pcall(remote.InvokeServer, remote, ...)
		if ok then return result end
	end
end

local lastWarn = 0
local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function safeFire(remote, ...)
	if not remote then return false end
	local className = remote.ClassName
	if className == "RemoteFunction" then
		local ok, err = pcall(remote.InvokeServer, remote, ...)
		if not ok then logError(remote.Name .. ": " .. tostring(err)) end
		return ok
	end
	local ok, err = pcall(remote.FireServer, remote, ...)
	if not ok then logError(remote.Name .. ": " .. tostring(err)) end
	return ok
end

local timers = {}
local function ready(key, interval)
	local now = tick()
	if now - (timers[key] or 0) < interval then return false end
	timers[key] = now
	return true
end

local function formatDuration(seconds)
	seconds = math.floor(seconds)
	if seconds < 60 then return string.format("%ds", seconds) end
	return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
end

local StatusHoldUntil = 0
local function setFarmStatus(text)
	text = tostring(text or "idle")
	if text == "idle" then
		if tick() < StatusHoldUntil then return end
	else
		StatusHoldUntil = tick() + 2
	end
	farmStatus = text
end

local Formatter
do
	local module = find(ReplicatedStorage, "Util", "Formatter")
	if module then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" and type(result.Format) == "function" then
			Formatter = result
		end
	end
	if not Formatter then
		local suffixes = {
			"", "K", "M", "B", "T", "Qa", "Qui", "Sx", "Sp", "Oc", "No",
			"Dc", "Udc", "Ddc", "Tdc", "Qdc", "Qid", "Sxd", "Spd", "Ocd", "Nmd",
			"Vg", "Uvg", "Dvg", "Tvg", "Qvg", "Qivg", "Sxvg", "Spvg", "Ocvg", "Nmvg", "Tg",
		}
		local function limitStringIgnoreDots(text, maxChars)
			local count = 0
			local out = ""
			for index = 1, #text do
				local char = string.sub(text, index, index)
				if char == "." then
					local more = false
					for inner = index + 1, #text do
						if string.sub(text, inner, inner) ~= "." then
							more = true
							break
						end
					end
					if more then out = out .. char end
				else
					if count >= maxChars then break end
					out = out .. char
					count = count + 1
				end
			end
			if string.sub(out, -1) == "." then out = string.sub(out, 1, -2) end
			return out
		end
		Formatter = { Suffixes = suffixes }
		function Formatter.Format(value)
			local suffixIndex = 1
			local rounded = math.round(value * 10) / 10
			if rounded >= 999.999999 then
				while rounded >= 999.999999 and suffixIndex < #suffixes do
					suffixIndex = suffixIndex + 1
					rounded = rounded / 1000
				end
			end
			local suffix = suffixes[suffixIndex]
			if suffixIndex == #suffixes and rounded >= 999.999999 then
				return tostring(math.floor(rounded)) .. suffix
			end
			local scaled = math.round(rounded * 100) / 100
			return limitStringIgnoreDots(tostring(scaled), 3) .. suffix
		end
		function Formatter.FormatPrecise(value)
			local suffixIndex = 1
			local rounded = math.round(value * 10) / 10
			if rounded >= 999.999999 then
				while rounded >= 999.999999 and suffixIndex < #suffixes do
					suffixIndex = suffixIndex + 1
					rounded = rounded / 1000
				end
			end
			local suffix = suffixes[suffixIndex]
			if suffixIndex == #suffixes and rounded >= 999.999999 then
				return tostring(math.floor(rounded)) .. suffix
			end
			local precision = suffixIndex >= 12 and 5 or (suffixIndex >= 6 and 4 or 3)
			local factor = 10 ^ (precision - 1)
			local scaled = math.round(rounded * factor) / factor
			return limitStringIgnoreDots(tostring(scaled), precision) .. suffix
		end
	end
end

local Comms
do
	local ok, folder = pcall(function() return ReplicatedStorage:WaitForChild("comms", 10) end)
	Comms = ok and folder or nil
end

local function commsRemote(name) return Comms and Comms:FindFirstChild(name) or nil end

local RequestReroll = commsRemote("RequestReroll")
local PickFighterOffer = commsRemote("PickFighterOffer")
local ShowRerollCards = commsRemote("ShowRerollCards")
local ClearRerollCards = commsRemote("ClearRerollCards")
local ToggleInstantReveal = commsRemote("ToggleInstantReveal")
local OpenTrainingMenu = commsRemote("OpenTrainingMenu")
local OpenSparringMenu = commsRemote("OpenSparringMenu")
local RequestOfficialNPCMatch = commsRemote("RequestOfficialNPCMatch")
local RequestCurrentFighters = commsRemote("RequestCurrentFighters")
local RequestPantsShop = commsRemote("RequestPantsShop")
local PurchasePantsShopItem = commsRemote("PurchasePantsShopItem")
local NotifyRemote = commsRemote("Notify")

local LeagueConfig
do
	local ok, modules = pcall(function() return ReplicatedStorage:WaitForChild("sharedModules", 10) end)
	local module = modules and modules:FindFirstChild("LeagueConfig")
	if module then
		local okRequire, result = pcall(require, module)
		if okRequire and type(result) == "table" then LeagueConfig = result end
	end
end

local RARITY_VALUES = { "Random", "Random [Shiny]", "Real", "Real [Shiny]", "Legend", "Legend [Shiny]" }
local STATION_STAT_BY_NAME = {
	["Punching Bag"] = "Power",
	["Bench Press"] = "Power",
	["Pull Ups"] = "Dexterity",
	["Treadmill [AGL]"] = "Agility",
	["Treadmill [STM]"] = "Stamina",
}
local LEAGUE_VALUES = { "Bronze", "Silver", "Gold", "World" }
local NONE_FIGHTER = "None"
local MAX_TRAINING_REPS = 9
local REQUIRED_SPARS = 3

local function getCharacter() return LocalPlayer.Character end
local function getHumanoid() local character = getCharacter() return character and character:FindFirstChildOfClass("Humanoid") end
local function getRoot() local character = getCharacter() return character and character:FindFirstChild("HumanoidRootPart") end

local function optionText(name, fallback)
	local option = Options[name]
	if option == nil then return fallback end
	return tostring(option.Value or fallback)
end

local function optionNumber(name, fallback)
	local option = Options[name]
	local value = option and tonumber(option.Value)
	return value or fallback
end

local function selectionSet(values)
	local set = {}
	if type(values) == "table" then
		for key, value in pairs(values) do
			local entry = type(value) == "string" and value or (type(key) == "string" and key or nil)
			local selected = type(value) == "string" or value == true
			if entry and selected then set[entry] = true end
		end
	elseif type(values) == "string" and values ~= "" then
		set[values] = true
	end
	return set
end

local function teleportTo(cf)
	local root = getRoot()
	if not root or not cf then
		return false
	end
	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	root.CFrame = cf
	return true
end

local function getHud()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	return playerGui and playerGui:FindFirstChild("HUD")
end

local function getPlot()
	local plots = Workspace:FindFirstChild("Plots")
	local used = plots and plots:FindFirstChild("Used")
	return used and used:FindFirstChild(LocalPlayer.Name)
end

local function getStatsFolder()
	return LocalPlayer:FindFirstChild("Stats")
end

local function getMoney()
	local stats = getStatsFolder()
	local money = stats and stats:FindFirstChild("Money")
	return money and money.Value or 0
end

local function getStatValue(name)
	local stats = getStatsFolder()
	local value = stats and stats:FindFirstChild(name)
	return value and value.Value or 0
end

local function fighterCount()
	local folder = LocalPlayer:FindFirstChild("Fighters")
	return folder and #folder:GetChildren() or 0
end

local function fireGuiButton(button)
	if not button then
		return false
	end
	local fired = false
	if firesignal then
		fired = pcall(firesignal, button.MouseButton1Click)
		if not fired then
			fired = pcall(firesignal, button.Activated)
		end
	end
	if fired then
		return true
	end
	for _, signalName in ipairs({ "MouseButton1Click", "Activated" }) do
		local ok, list = pcall(function()
			return getconnections(button[signalName])
		end)
		if ok then
			for _, connection in ipairs(list) do
				local ran = pcall(function()
					if connection.Fire then
						connection:Fire()
					elseif connection.Function then
						connection.Function()
					end
				end)
				fired = fired or ran
			end
		end
	end
	return fired
end

local function parseNumber(text)
	if typeof(text) == "number" then
		return text
	end
	if typeof(text) ~= "string" then
		return nil
	end
	local value = string.match(text, "(%-?%d+%.?%d*)")
	return value and tonumber(value) or nil
end

local function waitFor(predicate, timeout)
	local deadline = os.clock() + (timeout or 5)
	while os.clock() < deadline do
		local ok, result = pcall(predicate)
		if ok and result then
			return result
		end
		task.wait(0.05)
	end
	return nil
end

local latestRerollToken = nil
local latestOffers = {}
local rerollBusy = false

local function offerRarityLabel(data)
	local category = tostring(data.Category or "Custom")
	local label = "Random"
	if category == "Real" then
		label = "Real"
	elseif category == "Legend" then
		label = "Legend"
	end
	if data.IsShiny == true then
		label = label .. " [Shiny]"
	end
	return label
end

local function readOffer(data, index)
	return {
		index = index,
		name = data.RealName or data.PresetName or "",
		rarity = offerRarityLabel(data),
		shiny = data.IsShiny == true,
		overall = tonumber(data.Overall) or 0,
		power = tonumber(data.Power) or 0,
		agility = tonumber(data.Agility) or 0,
		dexterity = tonumber(data.Dexterity) or 0,
		endurance = tonumber(data.Endurance) or 0,
		reach = tonumber(data.Reach) or 0,
		stamina = tonumber(data.Stamina) or 0,
		trainingCap = tonumber(data.TrainingCap) or 0,
	}
end

trackConnection(ShowRerollCards.OnClientEvent:Connect(function(offers, token)
	latestRerollToken = token
	latestOffers = {}
	if typeof(offers) ~= "table" then
		return
	end
	for index = 1, 3 do
		local data = offers[index]
		if typeof(data) == "table" then
			table.insert(latestOffers, readOffer(data, index))
		end
	end
end))

trackConnection(ClearRerollCards.OnClientEvent:Connect(function()
	latestRerollToken = nil
	latestOffers = {}
end))

local function getRerollMenu()
	local hud = getHud()
	return hud and hud:FindFirstChild("RerollMenu")
end

local function getOfferCards()
	return latestOffers
end

local function freeRerollReady()
	local menu = getRerollMenu()
	local button = menu and menu:FindFirstChild("Reroll")
	local label = button and button:FindFirstChild("TextLabel")
	if not button or not label then
		return false
	end
	local text = string.lower(label.Text)
	if string.find(text, "free", 1, true) then
		return button.Active ~= false and button.Visible ~= false
	end
	return false
end

local function setInstantReveal(value)
	local current = LocalPlayer:GetAttribute("InstantReveal") == true
	if current == value then
		return
	end
	pcall(function()
		ToggleInstantReveal:FireServer(value)
	end)
	pcall(function()
		ToggleInstantReveal:FireServer()
	end)
end

local function offerMeetsStop(offer)
	if not offer then
		return false
	end
	local rarities = selectionSet(Options.StopRarities and Options.StopRarities.Value)
	if next(rarities) ~= nil and not rarities[offer.rarity] then
		return false
	end
	if offer.overall < (optionNumber("StopMinOverall", 0) or 0) then
		return false
	end
	if offer.trainingCap < (optionNumber("StopMinTrainingCap", 0) or 0) then
		return false
	end
	local checks = {
		Power = offer.power,
		Agility = offer.agility,
		Dexterity = offer.dexterity,
		Endurance = offer.endurance,
		Reach = offer.reach,
		Stamina = offer.stamina,
	}
	for stat, value in pairs(checks) do
		local minimum = optionNumber("StopMin" .. stat, 0) or 0
		if minimum > 0 and value < minimum then
			return false
		end
	end
	return true
end

local function chooseOffer(offers)
	local matches = {}
	for _, offer in ipairs(offers) do
		if offerMeetsStop(offer) then
			table.insert(matches, offer)
		end
	end
	if #matches == 0 then
		return nil
	end
	local mode = optionText("StopPickMode", "Lowest Overall")
	if mode == "First Match" then
		return matches[1]
	end
	table.sort(matches, function(a, b)
		if a.overall == b.overall then
			return a.trainingCap > b.trainingCap
		end
		if mode == "Lowest Overall" then
			return a.overall < b.overall
		end
		return a.overall > b.overall
	end)
	return matches[1]
end

local function pickOffer(offer)
	if not offer then
		return false
	end
	if latestRerollToken == nil then
		return false
	end
	safeFire(PickFighterOffer, offer.index, latestRerollToken)
	latestRerollToken = nil
	latestOffers = {}
	return true
end

local function onOfferPicked(offer)
	pcall(function()
		Library:Notify(string.format("Stopped on %s [%d OVR] %s", offer.rarity, offer.overall, offer.name))
	end)
	if enabled.stopAfterPick then
		enabled.freeReroll = false
		enabled.realReroll = false
		enabled.legendReroll = false
		pcall(function()
			if Toggles.AutoFreeReroll then Toggles.AutoFreeReroll:SetValue(false) end
			if Toggles.AutoRealReroll then Toggles.AutoRealReroll:SetValue(false) end
			if Toggles.AutoLegendReroll then Toggles.AutoLegendReroll:SetValue(false) end
		end)
	end
end

local function requestReroll(kind)
	if LocalPlayer:GetAttribute("RerollRequestPending") == true then
		return false
	end
	if kind == "Casual" then
		if not freeRerollReady() then
			return false
		end
	elseif kind == "Real" then
		if getStatValue("RealRerolls") < 1 then
			return false
		end
	elseif kind == "Legend" then
		if getStatValue("LegendRerolls") < 1 then
			return false
		end
	else
		return false
	end
	safeFire(RequestReroll, kind)
	return true
end

local function getOwnedFighters()
	local result = call(RequestCurrentFighters)
	if typeof(result) == "table" then
		return result
	end
	local folder = LocalPlayer:FindFirstChild("Fighters")
	local fighters = {}
	if not folder then
		return fighters
	end
	for _, child in ipairs(folder:GetChildren()) do
		local entry = { FighterId = child.Name }
		for _, value in ipairs(child:GetChildren()) do
			if value:IsA("ValueBase") then
				entry[value.Name] = value.Value
			end
		end
		table.insert(fighters, entry)
	end
	return fighters
end

local function fighterStat(fighter, key)
	local value = fighter and fighter[key]
	return typeof(value) == "number" and value or 0
end

local function fighterCompletedSpars(fighter)
	return fighterStat(fighter, "CompletedSpars")
end

local function fighterDropdownLabel(fighter)
	local name = fighter.RealName or fighter.PresetName or "Fighter"
	local overall = fighterStat(fighter, "Overall")
	return string.format("%s [%d] %s", name, overall, fighter.FighterId)
end

local function parseFighterIdFromLabel(label)
	if typeof(label) ~= "string" or label == "" or label == NONE_FIGHTER then
		return nil
	end
	return string.match(label, "({[%w%-]+})$")
end

local function getFighterDropdownValues()
	local values = { NONE_FIGHTER }
	for _, fighter in ipairs(getOwnedFighters()) do
		if fighter.FighterId then
			table.insert(values, fighterDropdownLabel(fighter))
		end
	end
	return values
end

local function chooseNamedFighter(optionName)
	local fighterId = parseFighterIdFromLabel(optionText(optionName, NONE_FIGHTER))
	if not fighterId then
		return nil
	end
	for _, fighter in ipairs(getOwnedFighters()) do
		if fighter.FighterId == fighterId then
			return fighter
		end
	end
	return { FighterId = fighterId }
end

local function getTrainingStations()
	local plot = getPlot()
	local folder = plot and plot:FindFirstChild("TrainingStations")
	if not folder then
		return {}
	end
	local nameCounts = {}
	local stations = {}
	for index, station in ipairs(folder:GetChildren()) do
		local tp = station:FindFirstChild("TP")
		local prompt = tp and tp:FindFirstChildWhichIsA("ProximityPrompt", true)
		if tp and prompt then
			nameCounts[station.Name] = (nameCounts[station.Name] or 0) + 1
			local count = nameCounts[station.Name]
			local label = station.Name
			local totalSame = 0
			for _, other in ipairs(folder:GetChildren()) do
				if other.Name == station.Name then
					totalSame += 1
				end
			end
			if totalSame > 1 then
				label = string.format("%s #%d", station.Name, count)
			end
			table.insert(stations, {
				index = index,
				key = "Station" .. index,
				model = station,
				name = station.Name,
				label = label,
				tp = tp,
				prompt = prompt,
				stat = STATION_STAT_BY_NAME[station.Name] or "Overall",
				fighterOption = "StationFighter_" .. index,
				repsOption = "StationReps_" .. index,
			})
		end
	end
	return stations
end

local function getFighterSelector()
	local hud = getHud()
	return hud and hud:FindFirstChild("FighterSelector")
end

local function closeFighterSelector()
	local selector = getFighterSelector()
	if not selector then
		return
	end
	local closeButton = selector:FindFirstChild("Close")
	if closeButton then
		fireGuiButton(closeButton)
	end
	selector.Visible = false
end

local function selectFighterCard(card)
	if not card then
		return false
	end
	local fired = false
	for _, descendant in ipairs(card:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			fired = fireGuiButton(descendant) or fired
		end
	end
	return fired
end

local function clickFighterCard(card)
	if not card then
		return false
	end
	local button = card:FindFirstChild("Button")
	if button and getconnections then
		local ok, list = pcall(getconnections, button.MouseButton1Click)
		if ok then
			for _, connection in ipairs(list) do
				if connection.Function then
					local info = debug.getinfo(connection.Function)
					if info and info.nups and info.nups >= 20 then
						if pcall(connection.Function) then
							return true
						end
					end
				end
			end
			for _, connection in ipairs(list) do
				local ran = pcall(function()
					if connection.Fire then
						connection:Fire()
					elseif connection.Function then
						connection.Function()
					end
				end)
				if ran then
					return true
				end
			end
		end
	end
	return selectFighterCard(card)
end

local function findSelectorCard(selector, fighterId)
	local list = selector and selector:FindFirstChild("List")
	if not list then
		return nil
	end
	for _, card in ipairs(list:GetChildren()) do
		if card.Name == "FighterCard" and card:GetAttribute("FighterId") == fighterId then
			return card
		end
	end
	return nil
end

local function openStationMenu(station)
	closeFighterSelector()
	teleportTo(station.tp.CFrame * CFrame.new(0, 3, 0))
	task.wait(0.15)
	local token
	local connection = OpenTrainingMenu.OnClientEvent:Connect(function(_, sessionToken)
		token = sessionToken
	end)
	pcall(fireproximityprompt, station.prompt)
	local selector = waitFor(function()
		local fs = getFighterSelector()
		if fs and fs.Visible and fs:FindFirstChild("List") and fs.List:FindFirstChild("FighterCard") then
			return fs
		end
	end, 5)
	connection:Disconnect()
	return selector, token
end

local function setTrainingReps(repSelector, desired)
	desired = math.clamp(math.floor(desired), 1, MAX_TRAINING_REPS)
	local amountLabel = repSelector:FindFirstChild("AmountSelected")
	local addButton = repSelector:FindFirstChild("Add")
	local subButton = repSelector:FindFirstChild("Subtract")
	local current = parseNumber(amountLabel and amountLabel.Text) or 1
	local guard = 0
	while current < desired and addButton and guard < MAX_TRAINING_REPS do
		fireGuiButton(addButton)
		task.wait(0.05)
		current = parseNumber(amountLabel.Text) or current
		guard += 1
	end
	guard = 0
	while current > desired and subButton and guard < MAX_TRAINING_REPS do
		fireGuiButton(subButton)
		task.wait(0.05)
		current = parseNumber(amountLabel.Text) or current
		guard += 1
	end
	local startButton = repSelector:FindFirstChild("Start")
	if startButton and getconnections then
		local ok, list = pcall(getconnections, startButton.MouseButton1Click)
		if ok and list[1] and list[1].Function and setupvalue then
			pcall(setupvalue, list[1].Function, 5, desired)
		end
	end
	return current
end

local function startTrainingFromUi(selector, reps)
	local repSelector = waitFor(function()
		local rep = selector:FindFirstChild("RepSelector")
		if rep and rep.Visible then
			return rep
		end
	end, 4)
	if not repSelector then
		return false
	end
	setTrainingReps(repSelector, reps)
	task.wait(0.05)
	local startButton = repSelector:FindFirstChild("Start")
	return fireGuiButton(startButton)
end

local function assignFighterToStation(station, fighterId, reps)
	if typeof(fighterId) ~= "string" or fighterId == "" then
		return false
	end
	local selector = openStationMenu(station)
	if not selector then
		return false
	end
	local card = findSelectorCard(selector, fighterId)
	if not card then
		closeFighterSelector()
		return false
	end
	selectFighterCard(card)
	local started = startTrainingFromUi(selector, reps or 1)
	if not started then
		closeFighterSelector()
		return false
	end
	task.wait(0.35 + ((reps or 1) * 0.35))
	return true
end

local function getSparringPrompt()
	local plot = getPlot()
	local rings = plot and plot:FindFirstChild("BoxingRings")
	local ring = rings and rings:FindFirstChild("BoxingRing")
	local podium = ring and ring:FindFirstChild("Podium")
	local place = podium and podium:FindFirstChild("PlacePart")
	return place and place:FindFirstChildWhichIsA("ProximityPrompt", true), place
end

local function openSparringMenu()
	closeFighterSelector()
	local prompt, place = getSparringPrompt()
	if not prompt or not place then
		return nil
	end
	teleportTo(place.CFrame * CFrame.new(0, 3, 0))
	task.wait(0.15)
	local connection = OpenSparringMenu.OnClientEvent:Connect(function() end)
	pcall(fireproximityprompt, prompt)
	local selector = waitFor(function()
		local fs = getFighterSelector()
		if fs and fs.Visible and fs:FindFirstChild("List") and fs.List:FindFirstChild("FighterCard") then
			return fs
		end
	end, 5)
	connection:Disconnect()
	return selector
end

local function getFighterSpars(fighterId)
	if typeof(fighterId) ~= "string" or fighterId == "" then
		return 0
	end
	local result = call(RequestCurrentFighters)
	if typeof(result) == "table" then
		for _, fighter in ipairs(result) do
			if fighter.FighterId == fighterId then
				return fighterCompletedSpars(fighter)
			end
		end
		return 0
	end
	for _, fighter in ipairs(getOwnedFighters()) do
		if fighter.FighterId == fighterId then
			return fighterCompletedSpars(fighter)
		end
	end
	return 0
end

local function startSparForFighter(fighterId)
	if typeof(fighterId) ~= "string" or fighterId == "" then
		return false
	end
	local before = getFighterSpars(fighterId)
	local selector = openSparringMenu()
	if not selector then
		return false
	end
	local card = findSelectorCard(selector, fighterId)
	if not card then
		closeFighterSelector()
		return false
	end
	if not clickFighterCard(card) then
		closeFighterSelector()
		return false
	end
	local deadline = os.clock() + 60
	while os.clock() < deadline do
		if not session.running then
			return false
		end
		task.wait(1)
		if getFighterSpars(fighterId) > before then
			return true
		end
	end
	return false
end

local function buyBoxerForFighter(fighterId)
	if typeof(fighterId) ~= "string" or fighterId == "" then
		return false
	end
	local ok, shop = pcall(function()
		return RequestPantsShop:InvokeServer()
	end)
	if not ok or typeof(shop) ~= "table" or typeof(shop.Offers) ~= "table" then
		return false
	end
	local refreshId = shop.RefreshId
	if typeof(refreshId) ~= "string" then
		return false
	end
	local money = getMoney()
	local offers = {}
	for _, offer in pairs(shop.Offers) do
		if typeof(offer) == "table" and typeof(offer.PantsName) == "string" then
			table.insert(offers, offer)
		end
	end
	table.sort(offers, function(a, b)
		return (tonumber(a.Price) or 0) < (tonumber(b.Price) or 0)
	end)
	for _, offer in ipairs(offers) do
		local price = tonumber(offer.Price) or 0
		if money >= price then
			local purchased, result = pcall(function()
				return PurchasePantsShopItem:InvokeServer(fighterId, offer.PantsName, refreshId)
			end)
			if purchased and typeof(result) == "table" and result.Success == true then
				setFarmStatus("bought boxer")
				return true
			end
			if purchased and typeof(result) == "table" and typeof(result.Message) == "string" then
				if string.find(string.lower(result.Message), "enough money", 1, true) then
					return false
				end
			end
		end
	end
	return false
end

local function getMatchSignup()
	local hud = getHud()
	return hud and hud:FindFirstChild("MatchSignup")
end

local function openMatchSignup()
	local existing = getMatchSignup()
	if existing and existing.Visible then
		return existing
	end
	local hud = getHud()
	local fightButton = hud and (hud:FindFirstChild("FightButton", true) or (hud:FindFirstChild("Right") and hud.Right:FindFirstChild("FightButton")))
	if fightButton then
		fireGuiButton(fightButton)
	end
	return waitFor(function()
		local menu = getMatchSignup()
		if menu and menu.Visible then
			return menu
		end
	end, 5)
end

local function startPveFight()
	if not RequestOfficialNPCMatch then
		return false
	end
	local league = optionText("PveLeague", "Bronze")
	local leagueData = LeagueConfig and LeagueConfig.Leagues and LeagueConfig.Leagues[league]
	if leagueData and getMoney() < (leagueData.MatchPrice or 0) then
		return false
	end
	local fighter = chooseNamedFighter("PveFighter")
	if not fighter or not fighter.FighterId then
		return false
	end
	if getFighterSpars(fighter.FighterId) < REQUIRED_SPARS then
		return false
	end
	local beforeMoney = getMoney()
	local errMessage
	local notifyConn
	if NotifyRemote then
		notifyConn = NotifyRemote.OnClientEvent:Connect(function(message, _, kind)
			if kind == "Error" or (typeof(message) == "string" and string.find(string.lower(message), "available", 1, true)) then
				errMessage = tostring(message)
			end
		end)
	end
	safeFire(RequestOfficialNPCMatch, fighter.FighterId, league)
	task.wait(0.6)
	if notifyConn then
		notifyConn:Disconnect()
	end
	if errMessage then
		closeFighterSelector()
		local menu = openMatchSignup()
		if not menu then
			return false
		end
		local leagueButton = menu:FindFirstChild(league)
		if not leagueButton then
			return false
		end
		local clickTarget = leagueButton:IsA("GuiButton") and leagueButton or leagueButton:FindFirstChildWhichIsA("GuiButton", true) or leagueButton
		fireGuiButton(clickTarget)
		local selector = waitFor(function()
			local fs = getFighterSelector()
			if fs and fs.Visible and fs:FindFirstChild("List") and fs.List:FindFirstChild("FighterCard") then
				return fs
			end
		end, 5)
		if not selector then
			return false
		end
		local card = findSelectorCard(selector, fighter.FighterId)
		if not card then
			closeFighterSelector()
			return false
		end
		if not clickFighterCard(card) then
			closeFighterSelector()
			return false
		end
	end
	local deadline = os.clock() + 20
	while os.clock() < deadline do
		if not session.running then
			return false
		end
		task.wait(0.5)
		if getMoney() < beforeMoney then
			setFarmStatus("pve fight started")
			return true
		end
		local matchViewer = LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("MatchViewer")
		if matchViewer then
			local frame = matchViewer:FindFirstChild("Frame")
			local arena = matchViewer:FindFirstChild("ArenaInformation")
			local winner = matchViewer:FindFirstChild("WinnerFrame")
			if (frame and frame.Visible) or (arena and arena.Visible) or (winner and winner.Visible) then
				setFarmStatus("pve fight started")
				return true
			end
		end
	end
	return true
end

local function doAutoReroll()
	if not enabled.freeReroll and not enabled.realReroll and not enabled.legendReroll and not enabled.stopRoll then return end
	if rerollBusy then return end
	if not ready("reroll", tonumber(Options.RerollDelay and Options.RerollDelay.Value) or 0.35) then return end
	rerollBusy = true
	if enabled.instantReveal then
		setInstantReveal(true)
	end
	if enabled.stopRoll then
		local choice = chooseOffer(getOfferCards())
		if choice and pickOffer(choice) then
			onOfferPicked(choice)
			rerollBusy = false
			return
		end
	end
	local rolled = false
	if enabled.freeReroll then
		rolled = requestReroll("Casual")
	end
	if not rolled and enabled.realReroll then
		rolled = requestReroll("Real")
	end
	if not rolled and enabled.legendReroll then
		rolled = requestReroll("Legend")
	end
	if rolled then
		setFarmStatus("rerolling")
		task.wait(0.25)
		if enabled.stopRoll then
			local choice = chooseOffer(getOfferCards())
			if choice and pickOffer(choice) then
				onOfferPicked(choice)
			end
		end
	end
	rerollBusy = false
end

local trainBusy = false

local function doAutoTrain()
	if not enabled.assign or trainBusy then return end
	if not ready("train", tonumber(Options.TrainingDelay and Options.TrainingDelay.Value) or 0.75) then return end
	trainBusy = true
	for _, station in ipairs(TrainingStations) do
		if not session.running or not enabled.assign then break end
		if not station.model or not station.model.Parent then
			local refreshed = getTrainingStations()
			for _, fresh in ipairs(refreshed) do
				if fresh.index == station.index then
					station.model = fresh.model
					station.tp = fresh.tp
					station.prompt = fresh.prompt
					break
				end
			end
		end
		local fighterId = parseFighterIdFromLabel(optionText(station.fighterOption, NONE_FIGHTER))
		if fighterId then
			setFarmStatus("assign " .. station.name)
			local reps = optionNumber(station.repsOption, 1) or 1
			assignFighterToStation(station, fighterId, reps)
			task.wait(tonumber(Options.TrainingDelay and Options.TrainingDelay.Value) or 0.75)
		end
	end
	trainBusy = false
end

local sparBusy = false

local function doAutoSpar()
	if not enabled.spar or sparBusy then return end
	if not ready("spar", tonumber(Options.SparDelay and Options.SparDelay.Value) or 2) then return end
	local fighter = chooseNamedFighter("SparFighter")
	if not fighter or not fighter.FighterId then return end
	local spars = getFighterSpars(fighter.FighterId)
	if enabled.sparStopAtThree and spars >= REQUIRED_SPARS then return end
	sparBusy = true
	setFarmStatus("sparring")
	startSparForFighter(fighter.FighterId)
	sparBusy = false
end

local pveBusy = false

local function doAutoPve()
	if not enabled.pve or pveBusy then return end
	if not ready("pve", tonumber(Options.PveDelay and Options.PveDelay.Value) or 3) then return end
	pveBusy = true
	startPveFight()
	pveBusy = false
end

local boxerBusy = false

local function doAutoBoxers()
	if not enabled.buyBoxers or boxerBusy then return end
	if not ready("boxers", tonumber(Options.BoxerDelay and Options.BoxerDelay.Value) or 2) then return end
	local fighter = chooseNamedFighter("BoxerFighter")
	if not fighter or not fighter.FighterId then return end
	boxerBusy = true
	buyBoxerForFighter(fighter.FighterId)
	boxerBusy = false
end

local TrainingStations = getTrainingStations()
do
	local deadline = tick() + 8
	while #TrainingStations == 0 and tick() < deadline do
		task.wait(0.25)
		TrainingStations = getTrainingStations()
	end
end

local REROLL_RARITIES = { "Random", "Random [Shiny]", "Real", "Real [Shiny]", "Legend", "Legend [Shiny]" }
local LEAGUES = { "Bronze", "Silver", "Gold", "World" }
local MAX_REPS = 9
local SPARS_REQUIRED = 3

local function rejoinServer()
	pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
end

local function reconnectServer()
	pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
end

local function serverHop()
	if not httpRequest then
		reconnectServer()
		return
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
			reconnectServer()
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
		{ Text = CONFIG.Website, Copyable = true },
		"|",
		CONFIG.Version,
	},
	NotifySide = "Right",
	ShowCustomCursor = false,
	FuzzySearch = true,
	FuzzySearchToggle = true,
	SearchKeybind = Enum.KeyCode.F,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	Size = UDim2.fromOffset(880, 640),
	MinSize = Vector2.new(560, 380),
	Resizable = true,
	AutoJump = true,
	PopOut = false,
})
pcall(function()
	Window.PopOut = false
end)

local Tabs = {
	Info = Window:AddTab("Info", "info"),
	Main = Window:AddTab("Main", "swords"),
	Settings = Window:AddTab("Settings", "settings"),
}

local RerollTab = Tabs.Main:AddSubTab("Reroll", "dices")
local TrainingTab = Tabs.Main:AddSubTab("Training", "activity")
local FightsTab = Tabs.Main:AddSubTab("Fights", "swords")

local AccountBox = Tabs.Info:AddLeftGroupbox("Account", "circle-user")
AccountBox:AddLabel("User: " .. LocalPlayer.Name)
AccountBox:AddLabel("User ID: " .. tostring(LocalPlayer.UserId))
AccountBox:AddLabel("Executor: " .. executorText)
AccountBox:AddButton({
	Text = "Copy Username",
	Func = function()
		if copyText then pcall(copyText, LocalPlayer.Name) end
		Library:Notify("Copied username to clipboard")
	end,
})
AccountBox:AddButton({
	Text = "Copy User ID",
	Func = function()
		if copyText then pcall(copyText, tostring(LocalPlayer.UserId)) end
		Library:Notify("Copied user ID to clipboard")
	end,
})

local SessionLabel = AccountBox:AddLabel("Session: 0s")

local GameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local resolvedGameName = CONFIG.GameName
pcall(function()
	local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	if info and info.Name then
		resolvedGameName = info.Name
	end
end)
GameBox:AddLabel("Game: " .. resolvedGameName)
GameBox:AddLabel("Place ID: " .. tostring(game.PlaceId))
local PlayersLabel = GameBox:AddLabel("Players: 0")
GameBox:AddLabel("Server: " .. tostring(game.JobId))
GameBox:AddButton({
	Text = "Copy Join Script",
	Func = function()
		local joinScript = string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game:GetService("Players").LocalPlayer)',
			game.PlaceId,
			game.JobId
		)
		if copyText then pcall(copyText, joinScript) end
		Library:Notify("Copied join script to clipboard")
	end,
})

local SocialsBox = Tabs.Info:AddLeftGroupbox("Socials", "link")
SocialsBox:AddButton({
	Text = "Discord",
	Func = function()
		if copyText then pcall(copyText, CONFIG.Discord) end
		Library:Notify("Copied Discord invite to clipboard")
	end,
})
SocialsBox:AddButton({
	Text = "Website",
	Func = function()
		if copyText then pcall(copyText, CONFIG.Website) end
		Library:Notify("Copied website link to clipboard")
	end,
})

local StatusBox = Tabs.Main:AddLeftGroupbox("Status", "activity")
local StatusLabel = StatusBox:AddLabel("Status: idle")
local MoneyLabel = StatusBox:AddLabel("Money: 0")
local FightersLabel = StatusBox:AddLabel("Fighters: 0")

local RerollBox = RerollTab:AddLeftGroupbox("Auto Reroll", "refresh-cw")
RerollBox:AddToggle("AutoFreeReroll", {
	Text = "Auto Free Reroll",
	Default = false,
	Callback = function(value)
		enabled.freeReroll = value
	end,
})
RerollBox:AddToggle("AutoRealReroll", {
	Text = "Auto Real Reroll",
	Default = false,
	Callback = function(value)
		enabled.realReroll = value
	end,
})
RerollBox:AddToggle("AutoLegendReroll", {
	Text = "Auto Legend Reroll",
	Default = false,
	Callback = function(value)
		enabled.legendReroll = value
	end,
})
RerollBox:AddToggle("AutoStopRoll", {
	Text = "Auto Stop Roll",
	Default = false,
	Callback = function(value)
		enabled.stopRoll = value
	end,
})
RerollBox:AddToggle("UseInstantReveal", {
	Text = "Instant Reveal",
	Default = false,
	Callback = function(value)
		enabled.instantReveal = value
		pcall(setInstantReveal, value)
	end,
})
RerollBox:AddSlider("RerollDelay", {
	Text = "Reroll delay",
	Default = 0.35,
	Min = 0.1,
	Max = 3,
	Rounding = 2,
	Suffix = "s",
})
RerollBox:AddDropdown("StopPickMode", {
	Text = "Stop roll pick mode",
	Values = { "First Match", "Lowest Overall", "Highest Overall" },
	Default = "Lowest Overall",
})

local StopBox = RerollTab:AddRightGroupbox("Stop Roll Criteria", "flag")
StopBox:AddDropdown("StopRarities", {
	Text = "Rarities to stop on (none = any)",
	Values = REROLL_RARITIES,
	Default = {},
	Multi = true,
	Searchable = true,
	AllowNull = true,
})
StopBox:AddInput("StopMinOverall", { Text = "Min overall (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinTrainingCap", { Text = "Min training cap (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddDivider()
StopBox:AddInput("StopMinPower", { Text = "Min power (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinAgility", { Text = "Min agility (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinDexterity", { Text = "Min dexterity (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinEndurance", { Text = "Min endurance (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinReach", { Text = "Min reach (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddInput("StopMinStamina", { Text = "Min stamina (0 = off)", Default = "0", Numeric = true, Finished = true })
StopBox:AddDivider()
StopBox:AddToggle("StopUnloadAfterPick", {
	Text = "Stop All Rerolls After Pick",
	Default = false,
	Callback = function(value)
		enabled.stopAfterPick = value
	end,
})

local StationBox = TrainingTab:AddLeftGroupbox("Auto Assign", "users")
StationBox:AddToggle("AutoAssignFighters", {
	Text = "Auto Assign Fighters",
	Default = false,
	Callback = function(value)
		enabled.autoAssign = value
	end,
})
StationBox:AddSlider("TrainingDelay", {
	Text = "Assign delay",
	Default = 0.75,
	Min = 0.25,
	Max = 5,
	Rounding = 2,
	Suffix = "s",
})
StationBox:AddDivider()

local fighterDropdowns = {}
local function refreshFighterDropdowns()
	local values = getFighterDropdownValues()
	for _, dropdown in pairs(fighterDropdowns) do
		pcall(function()
			dropdown:SetValues(values)
		end)
	end
end

for _, station in ipairs(TrainingStations) do
	local dropdown = StationBox:AddDropdown("StationFighter_" .. tostring(station.index), {
		Text = station.label .. " (" .. tostring(station.stat) .. ")",
		Values = getFighterDropdownValues(),
		Default = "None",
		AllowNull = false,
		Searchable = true,
	})
	table.insert(fighterDropdowns, dropdown)
	StationBox:AddSlider("StationReps_" .. tostring(station.index), {
		Text = station.label .. " reps",
		Default = 1,
		Min = 1,
		Max = MAX_REPS,
		Rounding = 0,
	})
end

StationBox:AddButton({
	Text = "Refresh Fighters",
	Func = function()
		refreshFighterDropdowns()
		Library:Notify("Fighter lists refreshed")
	end,
})

local SparBox = FightsTab:AddLeftGroupbox("Auto Spar", "swords")
SparBox:AddToggle("AutoSpar", {
	Text = "Auto Spar",
	Default = false,
	Callback = function(value)
		enabled.autoSpar = value
	end,
})
SparBox:AddToggle("SparStopAtThree", {
	Text = "Stop at 3 Spars",
	Default = true,
	Callback = function(value)
		enabled.sparStop = value
	end,
})
local SparFighterDropdown = SparBox:AddDropdown("SparFighter", {
	Text = "Fighter",
	Values = getFighterDropdownValues(),
	Default = "None",
	AllowNull = false,
	Searchable = true,
})
table.insert(fighterDropdowns, SparFighterDropdown)
SparBox:AddSlider("SparDelay", {
	Text = "Spar delay",
	Default = 2,
	Min = 0.5,
	Max = 15,
	Rounding = 1,
	Suffix = "s",
})

local SparStatusBox = FightsTab:AddRightGroupbox("Spar Status", "activity")
local SparStatusLabel = SparStatusBox:AddLabel("Spar status: select a fighter")

local PveBox = FightsTab:AddLeftGroupbox("Auto PVE", "trophy")
PveBox:AddToggle("AutoPve", {
	Text = "Auto Start PVE",
	Default = false,
	Callback = function(value)
		enabled.autoPve = value
	end,
})
PveBox:AddDropdown("PveLeague", {
	Text = "League",
	Values = LEAGUES,
	Default = "Bronze",
})
local PveFighterDropdown = PveBox:AddDropdown("PveFighter", {
	Text = "Fighter",
	Values = getFighterDropdownValues(),
	Default = "None",
	AllowNull = false,
	Searchable = true,
})
table.insert(fighterDropdowns, PveFighterDropdown)
PveBox:AddSlider("PveDelay", {
	Text = "Fight delay",
	Default = 3,
	Min = 1,
	Max = 20,
	Rounding = 1,
	Suffix = "s",
})
PveBox:AddButton({
	Text = "Refresh Fighters",
	Func = function()
		refreshFighterDropdowns()
		Library:Notify("Fighter lists refreshed")
	end,
})

local BoxerBox = FightsTab:AddRightGroupbox("Money Shop", "shopping-bag")
BoxerBox:AddToggle("AutoBuyBoxers", {
	Text = "Auto Buy Boxers",
	Default = false,
	Callback = function(value)
		enabled.buyBoxers = value
	end,
})
local BoxerFighterDropdown = BoxerBox:AddDropdown("BoxerFighter", {
	Text = "Fighter",
	Values = getFighterDropdownValues(),
	Default = "None",
	AllowNull = false,
	Searchable = true,
})
table.insert(fighterDropdowns, BoxerFighterDropdown)
BoxerBox:AddSlider("BoxerDelay", {
	Text = "Buy delay",
	Default = 2,
	Min = 0.5,
	Max = 15,
	Rounding = 1,
	Suffix = "s",
})

local MenuBox = Tabs.Settings:AddLeftGroupbox("Menu", "menu")
MenuBox:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind
MenuBox:AddDropdown("NotifySide", {
	Text = "Notification side",
	Values = { "Left", "Right" },
	Default = "Right",
	Callback = function(value)
		pcall(function()
			if Window.SetNotifySide then
				Window:SetNotifySide(value)
			end
		end)
	end,
})
MenuBox:AddSlider("UiScale", {
	Text = "UI scale",
	Default = 100,
	Min = 70,
	Max = 130,
	Rounding = 0,
	Suffix = "%",
	Callback = function(value)
		pcall(function()
			if Window.SetDpiScale then
				Window:SetDpiScale(value / 100)
			end
		end)
	end,
})
MenuBox:AddButton({
	Text = "Unload",
	Func = function()
		Library:Unload()
	end,
})

local ClientBox = Tabs.Settings:AddLeftGroupbox("Client", "monitor")
ClientBox:AddToggle("AntiAfk", {
	Text = "Anti AFK",
	Default = true,
	Callback = function(value)
		setAntiAfk(value)
	end,
})
ClientBox:AddToggle("FpsBoost", {
	Text = "FPS Boost",
	Default = false,
	Callback = function(value)
		setFpsBoost(value)
	end,
})
ClientBox:AddToggle("DisableRendering", {
	Text = "Disable 3D Rendering",
	Default = false,
	Callback = function(value)
		setRendering(value)
	end,
})

local ServerBox = Tabs.Settings:AddRightGroupbox("Server", "server")
ServerBox:AddButton({
	Text = "Reconnect",
	Func = reconnectServer,
})
ServerBox:AddButton({
	Text = "Rejoin Server",
	Func = rejoinServer,
})
ServerBox:AddButton({
	Text = "Server Hop",
	Func = serverHop,
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder(CONFIG.Folder)
SaveManager:SetFolder(CONFIG.Folder .. "/CoachAFighter")

ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SaveDefault("Dark Silver")

local function chain(func)
	task.spawn(function()
		while session.running do
			local ok, err = pcall(func)
			if not ok then
				logError(err)
			end
			task.wait(0.05)
		end
	end)
end

local function loop(interval, func)
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

local function updateLabels()
	pcall(function()
		StatusLabel:SetText("Status: " .. tostring(farmStatus))
	end)
	pcall(function()
		MoneyLabel:SetText("Money: " .. tostring(getMoney()))
	end)
	pcall(function()
		FightersLabel:SetText("Fighters: " .. tostring(#getOwnedFighters()))
	end)
	pcall(function()
		PlayersLabel:SetText("Players: " .. tostring(#Players:GetPlayers()))
	end)
end

local function updateSparStatus()
	local fighter = chooseNamedFighter("SparFighter")
	if not fighter or not fighter.FighterId then
		SparStatusLabel:SetText("Spar status: select a fighter")
		return
	end
	local spars = getFighterSpars(fighter.FighterId)
	SparStatusLabel:SetText(string.format("Spar status: %d / %d spars", spars, SPARS_REQUIRED))
end

loop(1, function()
	pcall(function()
		SessionLabel:SetText("Session: " .. formatDuration(tick() - sessionStart))
	end)
end)
loop(2, updateLabels)
loop(3, function()
	pcall(updateSparStatus)
end)

chain(doAutoReroll)
chain(doAutoTraining)
chain(doAutoSpar)
chain(doAutoPve)
chain(doAutoBoxers)

Library:OnUnload(function()
	session.running = false
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	pcall(function()
		setInstantReveal(false)
	end)
	pcall(closeFighterSelector)
	for _, connection in ipairs(scriptConnections) do
		pcall(connection.Disconnect, connection)
	end
	session.lib = nil
end)

Library:Notify(CONFIG.Title .. " loaded", 5)

SaveManager:LoadAutoloadConfig()