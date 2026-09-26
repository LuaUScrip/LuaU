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
	GameName = "Merge a Dino",
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

local function attributeOf(instance, ...)
	if not instance then
		return nil
	end
	for index = 1, select("#", ...) do
		local value = instance:GetAttribute((select(index, ...)))
		if value ~= nil then
			return value
		end
	end
	return nil
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
		if value ~= nil then
			return value
		end
	end
	return nil
end

local SUFFIX_LIST = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}

local function formatCommas(value)
	local text = tostring(value)
	local replaced
	repeat
		text, replaced = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return text
end

local gameFormat

local function toNumber(value)
	if type(value) == "number" then
		return value
	end
	if type(value) ~= "string" then
		return nil
	end
	local text = value:gsub("[, %s]", "")
	for index = #SUFFIX_LIST, 2, -1 do
		local suffix = SUFFIX_LIST[index]
		if #suffix > 0 and text:sub(-#suffix) == suffix then
			local base = tonumber(text:sub(1, -#suffix - 1))
			if base then
				return base * (1000 ^ (index - 1))
			end
		end
	end
	return tonumber(text)
end

local function abbreviateNumber(value)
	value = toNumber(value) or 0
	if gameFormat then
		local ok, text = pcall(gameFormat, value)
		if ok and type(text) == "string" and text ~= "" then
			return text
		end
	end
	local sign = value < 0 and "-" or ""
	local scaled = math.abs(value)
	if scaled < 1000 then
		return sign .. formatCommas(scaled)
	end
	local index = 1
	while scaled >= 1000 and index < #SUFFIX_LIST do
		scaled = scaled / 1000
		index = index + 1
	end
	local text = string.format("%.2f", scaled)
	text = string.gsub(text, "%.00$", "")
	text = string.gsub(text, "(%.%d)0$", "%1")
	return sign .. text .. SUFFIX_LIST[index]
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

local RemotesFolder = find(ReplicatedStorage, "Remotes")
local FunctionsFolder = RemotesFolder and RemotesFolder:FindFirstChild("Functions")
local EventsFolder = RemotesFolder and RemotesFolder:FindFirstChild("Events")

local function waitRemote(folder, name)
	if not folder then
		return nil
	end
	local remote = folder:FindFirstChild(name) or folder:FindFirstChild(name, true)
	if remote then
		return remote
	end
	local ok, waited = pcall(function()
		return folder:WaitForChild(name, 10)
	end)
	return ok and waited or nil
end

local UpgradeRequest = waitRemote(FunctionsFolder, "UpgradeRequest")
local LockBaseRequest = waitRemote(FunctionsFolder, "LockBaseRequest")
local RebirthRequest = waitRemote(FunctionsFolder, "RebirthRequest")
local DeathAction = waitRemote(FunctionsFolder, "DeathAction")
local DropDino = waitRemote(EventsFolder, "DropDino")
local AttackDino = waitRemote(EventsFolder, "AttackDino")
local NotificationEvent = waitRemote(EventsFolder, "NotificationEvent")

local function requireModule(root, name)
	if not root then
		return nil
	end
	local module = root:FindFirstChild(name)
	if not module then
		return nil
	end
	local ok, result = pcall(require, module)
	return ok and result or nil
end

local ModulesFolder = find(ReplicatedStorage, "Modules")
local ConstantsFolder = ModulesFolder and ModulesFolder:FindFirstChild("Constants")

local DinoStats = requireModule(ConstantsFolder, "DinoStats")

local DataModule = requireModule(ModulesFolder, "Data")

do
	local PackagesFolder = find(ReplicatedStorage, "Packages")
	local FormatNumberModule = requireModule(PackagesFolder, "FormatNumber")
	if type(FormatNumberModule) == "function" then
		gameFormat = FormatNumberModule
	elseif type(FormatNumberModule) == "table" then
		gameFormat = FormatNumberModule.FormatNumber or FormatNumberModule.Format or FormatNumberModule.Number
	end
end

local function dataValue(path)
	if not DataModule then
		return nil
	end
	local node = DataModule.client
	if type(node) ~= "table" then
		return nil
	end
	for index = 1, #path - 1 do
		node = node[path[index]]
		if type(node) ~= "table" then
			return nil
		end
	end
	local getter = node[path[#path]]
	if type(getter) ~= "function" then
		return nil
	end
	local ok, value = pcall(getter, node)
	if ok then
		return value
	end
end

local playerDataCache, playerDataAt = nil, 0

local function getPlayerData()
	if tick() - playerDataAt < 2 then
		return playerDataCache
	end
	playerDataCache = {
		Cash = tonumber(dataValue({"Cash"})) or 0,
		Rebirths = tonumber(statValue("Rebirths", "Rebirth")) or 0,
	}
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

local function getRebirths()
	return tonumber(statValue("Rebirths", "Rebirth")) or tonumber(getPlayerData().Rebirths) or 0
end

local function plotFor(player)
	if not player then
		return nil
	end
	local candidates = {}
	local map = Workspace:FindFirstChild("Map")
	local plots = map and map:FindFirstChild("Plots")
	if plots then
		table.insert(candidates, plots)
	end
	local direct = Workspace:FindFirstChild("Plots")
	if direct then
		table.insert(candidates, direct)
	end
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "Plots" then
			table.insert(candidates, descendant)
		end
	end
	for _, folder in ipairs(candidates) do
		for _, plot in ipairs(folder:GetChildren()) do
			if plot:IsA("Model") and attributeOf(plot, "Owner", "OwnerUserId", "UserId") == player.UserId then
				return plot
			end
		end
		local named = folder:FindFirstChild(tostring(player.UserId)) or folder:FindFirstChild(player.Name)
		if named and named:IsA("Model") then
			return named
		end
	end
	return nil
end

local function getPlot()
	return plotFor(LocalPlayer)
end

local function tierOf(dino)
	if not dino then
		return nil
	end
	local stats = DinoStats and DinoStats[dino.Name]
	if stats and tonumber(stats.Tier) then
		return tonumber(stats.Tier)
	end
	return attributeOf(dino, "Tier", "DinoTier") or dino.Name
end

local function getHeldDino()
	local character = getCharacter()
	if not character then
		return nil
	end
	for _, name in ipairs({"PickupWeld", "Weld", "HoldWeld", "DinoWeld", "CarryWeld"}) do
		local weld = character:FindFirstChild(name, true)
		if weld and (weld:IsA("WeldConstraint") or weld:IsA("Motor6D")) then
			local part = weld.Part1 or weld.Part0
			if part then
				local model = part:FindFirstAncestorOfClass("Model")
				if model and not model:IsDescendantOf(character) then
					return model
				end
			end
		end
	end
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("WeldConstraint") or descendant:IsA("Motor6D") then
			local part = descendant.Part1 or descendant.Part0
			if part and not part:IsDescendantOf(character) then
				local model = part:FindFirstAncestorOfClass("Model")
				if model and model:IsDescendantOf(Workspace) then
					return model
				end
			end
		end
	end
	return nil
end

local function tryPrompt(dino)
	if not dino or not dino:IsDescendantOf(Workspace) then
		return nil
	end
	local prompt
	for _, descendant in ipairs(dino:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			prompt = descendant
			break
		end
	end
	if not prompt or not prompt.Enabled or not prompt.Parent then
		return nil
	end
	pcall(function()
		prompt:InputHoldBegin()
	end)
	for _ = 1, 6 do
		task.wait(0.05)
		local held = getHeldDino()
		if held then
			pcall(function()
				prompt:InputHoldEnd()
			end)
			return held
		end
	end
	pcall(function()
		prompt:InputHoldEnd()
	end)
	return getHeldDino()
end

local function freeOwnDinos()
	local plot = getPlot()
	if not plot then
		return {}
	end
	local out = {}
	for _, descendant in ipairs(plot:GetDescendants()) do
		if descendant:IsA("Model") and attributeOf(descendant, "OwnerUserId", "Owner", "UserId") == LocalPlayer.UserId then
			local merging = attributeOf(descendant, "Merging")
			local dying = attributeOf(descendant, "Dying")
			if not merging and not dying and attributeOf(descendant, "Held") ~= true then
				table.insert(out, descendant)
			end
		end
	end
	if #out == 0 then
		for _, descendant in ipairs(plot:GetChildren()) do
			if descendant:IsA("Model") then
				local merging = attributeOf(descendant, "Merging")
				local dying = attributeOf(descendant, "Dying")
				if not merging and not dying and attributeOf(descendant, "Held") ~= true then
					table.insert(out, descendant)
				end
			end
		end
	end
	return out
end

local RECOVERY_TIME = 60
local recovering = {}

local function isRecovering(dino)
	local untilTime = recovering[dino]
	if not untilTime then
		return false
	end
	if tick() >= untilTime or not dino:IsDescendantOf(Workspace) then
		recovering[dino] = nil
		return false
	end
	return true
end

local mergeBusy = false
local lastPickupAt = 0
local PICKUP_COOLDOWN = 0.2

local function dinoPosition(dino)
	if not dino then
		return nil
	end
	local ok, pivot = pcall(dino.GetPivot, dino)
	if ok and pivot then
		return pivot.Position
	end
	local part = dino.PrimaryPart or dino:FindFirstChildWhichIsA("BasePart", true)
	if part then
		return part.Position
	end
	return nil
end

local function teleportToDino(root, dino, offset)
	if not dino then
		return false
	end
	local ok = pcall(function()
		root.CFrame = dino:GetPivot() + Vector3.new(0, offset or 0, 0)
	end)
	return ok
end

local function pickUp(dino)
	local root = getRoot()
	if not root or not dino or not dino:IsDescendantOf(Workspace) then
		return nil
	end
	if tick() - lastPickupAt < PICKUP_COOLDOWN then
		return nil
	end
	lastPickupAt = tick()
	for _, offset in ipairs({0, 2, -1.5}) do
		if not teleportToDino(root, dino, offset) then
			return nil
		end
		for _ = 1, 3 do
			task.wait(0.04)
			local held = getHeldDino()
			if held then
				return held
			end
		end
		if not dino:IsDescendantOf(Workspace) then
			return nil
		end
	end
	if tryPrompt(dino) then
		return getHeldDino()
	end
	local position = dinoPosition(dino)
	if position then
		pcall(function()
			local start = root.CFrame
			for step = 1, 10 do
				root.CFrame = start:Lerp(CFrame.new(position), step / 10)
				task.wait(0.04)
			end
		end)
		if getHeldDino() then
			return getHeldDino()
		end
	end
	return tryPrompt(dino)
end

local function mergeKey(dino)
	local tier = tierOf(dino)
	if type(tier) == "number" then
		return tostring(tier), tier
	end
	return tostring(dino and dino.Name or "?"), 1
end

local function bestPair(free)
	local root = getRoot()
	local origin = root and root.Position or Vector3.new()
	local counts, order = {}, {}
	for _, dino in ipairs(free) do
		if not isRecovering(dino) then
			local key, tier = mergeKey(dino)
			if not counts[key] then
				counts[key] = {}
				order[#order + 1] = {key = key, tier = tier}
			end
			table.insert(counts[key], dino)
		end
	end
	local bestKey, bestFirst, bestSecond, bestScore
	for _, group in ipairs(order) do
		local list = counts[group.key]
		if #list >= 2 then
			for firstIndex = 1, #list - 1 do
				local firstPosition = dinoPosition(list[firstIndex])
				if firstPosition then
					for secondIndex = firstIndex + 1, #list do
						local secondPosition = dinoPosition(list[secondIndex])
						if secondPosition then
							local travel = (firstPosition - origin).Magnitude + (secondPosition - origin).Magnitude
							local score = travel - group.tier * 1.5
							if not bestScore or score < bestScore then
								bestKey, bestFirst, bestSecond, bestScore = group.key, list[firstIndex], list[secondIndex], score
							end
						end
					end
				end
			end
		end
	end
	if bestFirst then
		return bestKey, bestFirst, bestSecond
	end
	return nil
end

local function dropHeld()
	if not getHeldDino() then
		return true
	end
	fire(DropDino)
	for _ = 1, 6 do
		task.wait(0.04)
		if not getHeldDino() then
			return true
		end
	end
	return not getHeldDino()
end

local function mergePass()
	local root = getRoot()
	if not root then
		return false
	end
	local origin = root.CFrame
	local free = freeOwnDinos()
	if #free < 2 then
		return false
	end
	local key, first, partner = bestPair(free)
	if not first or not partner then
		return false
	end
	local held = getHeldDino()
	if held and mergeKey(held) == key then
		first = held
		for _, dino in ipairs(free) do
			if dino ~= held and mergeKey(dino) == key then
				partner = dino
				break
			end
		end
		if not partner then
			return false
		end
	elseif held and not dropHeld() then
		return false
	end
	if not getHeldDino() then
		for attempt = 1, 3 do
			if attempt > 1 then
				if not dropHeld() then
					return false
				end
				local retryKey, retryFirst, retryPartner = bestPair(freeOwnDinos())
				if not retryFirst or not retryPartner then
					return false
				end
				key, first, partner = retryKey, retryFirst, retryPartner
			end
			local picked = pickUp(first)
			if not picked then
				return false
			end
			if mergeKey(picked) == key then
				break
			end
			recovering[picked] = tick() + 3
			if attempt == 3 then
				dropHeld()
				return false
			end
		end
		if not getHeldDino() or mergeKey(getHeldDino()) ~= key then
			dropHeld()
			return false
		end
	end
	if not partner:IsDescendantOf(Workspace) then
		dropHeld()
		task.wait(0.1)
		return false
	end
	setFarmStatus("merge " .. tostring(partner.Name))
	local started = tick()
	while tick() - started < 4 do
		if not session.running then
			break
		end
		if not getHeldDino() then
			break
		end
		if not partner:IsDescendantOf(Workspace) then
			break
		end
		if not teleportToDino(root, partner, 0) then
			break
		end
		task.wait(0.03)
	end
	pcall(function()
		root.CFrame = origin + Vector3.new(0, 3, 0)
	end)
	return not getHeldDino()
end

local function doAutoMerge()
	if not enabled.merge or mergeBusy then
		return
	end
	if enabled.attack then
		setFarmStatus("merge off (attack on)")
		return
	end
	if not ready("merge", 0.3) then
		return
	end
	mergeBusy = true
	local ok, merged = pcall(mergePass)
	mergeBusy = false
	if ok and merged then
		playerDataAt = 0
	end
end

local function bestOwnDino()
	local best, bestTier
	for _, dino in ipairs(freeOwnDinos()) do
		if not isRecovering(dino) then
			local tier = tierOf(dino)
			if type(tier) == "number" then
				if not bestTier or tier > bestTier then
					best, bestTier = dino, tier
				end
			elseif not best then
				best, bestTier = dino, 0
			end
		end
	end
	return best, bestTier
end

local function playerList()
	local list = {}
	for _, player in ipairs(Players:GetChildren()) do
		if player:IsA("Player") and player ~= LocalPlayer then
			table.insert(list, player)
		end
	end
	return list
end

local function targetPlayer()
	local list = playerList()
	local wanted = Options.AttackTarget and Options.AttackTarget.Value
	if wanted and wanted ~= "Auto" then
		for _, player in ipairs(list) do
			if player.DisplayName == wanted or player.Name == wanted then
				return player
			end
		end
		return nil
	end
	local root = getRoot()
	local best, bestDistance
	for _, player in ipairs(list) do
		local character = player.Character
		local otherRoot = character and character:FindFirstChild("HumanoidRootPart")
		if otherRoot and root then
			local distance = (otherRoot.Position - root.Position).Magnitude
			if not bestDistance or distance < bestDistance then
				best, bestDistance = player, distance
			end
		end
	end
	return best
end

local attackDino

local function ensureHeldDino()
	if getHeldDino() then
		return true
	end
	if attackDino and attackDino:IsDescendantOf(Workspace) then
		return true
	end
	if attackDino and not attackDino:IsDescendantOf(Workspace) then
		recovering[attackDino] = tick() + RECOVERY_TIME
		attackDino = nil
	end
	local best = bestOwnDino()
	if not best then
		return false
	end
	attackDino = pickUp(best)
	return attackDino ~= nil
end

local attackBlocked = false
local blockedDino
local attackBlockedAt = 0
local ATTACK_BLOCK_TIME = 90

local function clearAttackBlock()
	attackBlocked = false
	blockedDino = nil
	attackBlockedAt = 0
end

local function blockAttack()
	if not attackBlocked then
		attackBlockedAt = tick()
		blockedDino = getHeldDino()
	end
	attackBlocked = true
	if not blockedDino then
		blockedDino = getHeldDino()
	end
	setFarmStatus("dino busy")
end

if NotificationEvent then
	pcall(function()
		NotificationEvent.OnClientEvent:Connect(function(message, kind)
			if type(message) ~= "string" then
				return
			end
			local lowered = message:lower()
			if lowered:find("already attacking") or (kind == "error" and lowered:find("attacking")) then
				blockAttack()
			end
		end)
	end)
end

local function doAutoAttack()
	if not enabled.attack or not AttackDino then
		return
	end
	if not ready("attack", 1) then
		return
	end
	if attackBlocked then
		local gone = blockedDino ~= nil and not blockedDino:IsDescendantOf(Workspace)
		if gone then
			recovering[blockedDino] = tick() + RECOVERY_TIME
		end
		if gone or tick() - attackBlockedAt >= ATTACK_BLOCK_TIME then
			clearAttackBlock()
		else
			return
		end
	end
	local humanoid = getHumanoid()
	if humanoid and humanoid.Health <= 0 then
		return
	end
	local target = targetPlayer()
	if not target then
		return
	end
	local character = target.Character
	local otherRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not otherRoot then
		return
	end
	if not ensureHeldDino() then
		return
	end
	setFarmStatus("attack " .. target.DisplayName)
	fire(AttackDino, "Request", otherRoot.Position)
end

local function declineDeath()
	if not DeathAction then
		return false
	end
	return call(DeathAction, "Decline") == true
end

local function doAutoDeathAction()
	if not enabled.deathAction then
		return
	end
	if not ready("deathAction", 0.5) then
		return
	end
	local humanoid = getHumanoid()
	if humanoid and humanoid.Health <= 0 then
		setFarmStatus("death decline")
		declineDeath()
		clearAttackBlock()
	end
end

local lastTargets = ""

local function refreshTargets()
	local values = {"Auto"}
	for _, player in ipairs(playerList()) do
		values[#values + 1] = player.DisplayName
	end
	local key = table.concat(values, ",")
	if key == lastTargets then
		return
	end
	lastTargets = key
	pcall(function()
		local current = Options.AttackTarget and Options.AttackTarget.Value
		Options.AttackTarget:SetValues(values)
		if not table.find(values, current) then
			Options.AttackTarget:SetValue("Auto")
		end
	end)
end

local function requestUpgrade(key)
	if not UpgradeRequest then
		return false
	end
	local result = call(UpgradeRequest, key)
	return result == true
end

local function doAutoSpawnTier()
	if not enabled.spawnTier then
		return
	end
	if not ready("spawnTier", 1) then
		return
	end
	setFarmStatus("spawn tier")
	if requestUpgrade("SpawnTier") then
		playerDataAt = 0
	end
end

local function doAutoMaxSpawn()
	if not enabled.maxSpawn then
		return
	end
	if not ready("maxSpawn", 1) then
		return
	end
	setFarmStatus("max spawn")
	if requestUpgrade("MaxSpawn") then
		playerDataAt = 0
	end
end

local function doAutoLockTime()
	if not enabled.lockTime then
		return
	end
	if not ready("lockTime", 1) then
		return
	end
	setFarmStatus("lock time")
	if requestUpgrade("LockBase") then
		playerDataAt = 0
	end
end

local function lockState()
	local now = Workspace:GetServerTimeNow()
	local ends = tonumber(statValue("LockEndsAt")) or 0
	local cooldown = tonumber(statValue("LockCooldownEndsAt")) or 0
	local plot = getPlot()
	return now, ends, cooldown, plot and attributeOf(plot, "UnderAttack") == true
end

local function isBaseLocked()
	local now, ends = lockState()
	return now < ends
end

local function canLockBase()
	local now, ends, cooldown, underAttack = lockState()
	return not underAttack and now >= ends and now >= cooldown
end

local function lockBase()
	if not LockBaseRequest then
		return false
	end
	return call(LockBaseRequest) == true
end

local function doAutoLockBase()
	if not enabled.lockBase then
		return
	end
	if not ready("lockBase", 1) then
		return
	end
	if not canLockBase() then
		return
	end
	setFarmStatus("lock base")
	lockBase()
end

local function doAutoRebirth()
	if not enabled.rebirth or not RebirthRequest then
		return
	end
	if not ready("rebirth", 1) then
		return
	end
	setFarmStatus("rebirth")
	if call(RebirthRequest) == true then
		playerDataAt = 0
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

local teleportHooked = false
local function setAntiRejoin(state)
	if state == teleportHooked then
		return
	end
	teleportHooked = state
	if not state then
		return
	end
	pcall(function()
		if not hookmetamethod then
			return
		end
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if not checkcaller() and self == TeleportService then
				if method == "Teleport" or method == "TeleportToPlaceInstance" or method == "TeleportToPrivateServer" then
					return nil
				end
			end
			return old(self, ...)
		end)
	end)
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

local DinosTab = Tabs.Main:AddSubTab({ Name = "Dinos", Icon = "star" })
local UpgradeTab = Tabs.Main:AddSubTab({ Name = "All Upgrade", Icon = "zap" })
local AttackTab = Tabs.Main:AddSubTab({ Name = "Attack", Icon = "rocket" })

local DinosBox = box(DinosTab, "Merging", "star", "Left")
DinosBox:AddToggle("AutoMerge", { Text = "Auto Merge", Default = false, Callback = function(value)
	enabled.merge = value
end })
DinosBox:AddToggle("AutoLockBase", { Text = "Auto Lock Base", Default = false, Callback = function(value)
	enabled.lockBase = value
end })
local StatusBox = box(DinosTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("RebirthLabel", { Text = paint("Rebirths -", "0", COLORS.orange), DoesWrap = true })

local UpgradeBox = box(UpgradeTab, "Auto Upgrades", "zap", "Left")
UpgradeBox:AddToggle("AutoSpawnTier", { Text = "Upgrade Spawn Tier", Default = false, Callback = function(value)
	enabled.spawnTier = value
end })
UpgradeBox:AddToggle("AutoMaxSpawn", { Text = "Upgrade Max Spawn", Default = false, Callback = function(value)
	enabled.maxSpawn = value
end })
UpgradeBox:AddToggle("AutoLockTime", { Text = "Upgrade Lock Time", Default = false, Callback = function(value)
	enabled.lockTime = value
end })
UpgradeBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
end })

local AttackBox = box(AttackTab, "Attack", "rocket", "Left")
AttackBox:AddToggle("AutoAttack", { Text = "Auto Attack", Default = false, Callback = function(value)
	enabled.attack = value
end })
AttackBox:AddToggle("AutoDeathAction", { Text = "Auto Decline", Default = true, Callback = function(value)
	enabled.deathAction = value
end })
AttackBox:AddDropdown("AttackTarget", { Text = "Target", Values = { "Auto" }, Default = "Auto", Callback = function()
	ready("attack", 0)
end })

local AttackInfo = box(AttackTab, "Attack Info", "gauge", "Right")
AttackInfo:AddLabel("TargetLabel", { Text = paint("Target -", "none", COLORS.user), DoesWrap = true })
AttackInfo:AddLabel("AttackHeldLabel", { Text = paint("Holding -", "none", COLORS.accent), DoesWrap = true })
AttackInfo:AddLabel("BestDinoLabel", { Text = paint("Best -", "none", COLORS.orange), DoesWrap = true })

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
ClientBox:AddToggle("AntiAfk", { Text = "Anti AFK", Default = true, Callback = function(value)
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

enabled.antiafk = true
setAntiAfk(true)

enabled.deathAction = true

local ServerTools = box(Tabs.Settings, "Server", "server", "Right")
ServerTools:AddToggle("AntiRejoin", { Text = "Anti Rejoin", Default = false, Callback = function(value)
	enabled.antiRejoin = value
	setAntiRejoin(value)
end })
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
	setLabel("RebirthLabel", paint("Rebirths -", abbreviateNumber(getRebirths()), COLORS.orange))
	local target = targetPlayer()
	setLabel("TargetLabel", paint("Target -", target and target.DisplayName or "none", COLORS.user))
	setLabel("AttackHeldLabel", paint("Holding -", getHeldDino() and getHeldDino().Name or "none", COLORS.accent))
	local best = bestOwnDino()
	setLabel("BestDinoLabel", paint("Best -", best and best.Name or "none", COLORS.orange))
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
					warn("[AntiGodHub] " .. tostring(err))
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
				warn("[AntiGodHub] " .. tostring(err))
			end
			task.wait(interval)
		end
	end)
end

chain({ doAutoMerge }, 0.3)
chain({ doAutoAttack }, 1)
chain({ doAutoLockBase, doAutoSpawnTier, doAutoMaxSpawn, doAutoLockTime }, 1)
loop(doAutoRebirth, 1)
loop(doAutoDeathAction, 0.5)
loop(refreshTargets, 2)

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