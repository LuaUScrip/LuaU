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
	Version = "v1.5",
	Folder = "AntiGodHub",
	CornerRadius = 20,
	GameName = "+1 Speed Monkey Escape",
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
local scriptState = {}
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

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local function safeFire(remote, ...)
	if not remote then
		return false
	end
	local className = remote.ClassName
	if className == "RemoteFunction" then
		local ok, err = pcall(remote.InvokeServer, remote, ...)
		if not ok then
			logError(remote.Name .. ": " .. tostring(err))
		end
		return ok
	end
	local ok, err = pcall(remote.FireServer, remote, ...)
	if not ok then
		logError(remote.Name .. ": " .. tostring(err))
	end
	return ok
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

local Data
do
	local ok, folder = pcall(function()
		return LocalPlayer:WaitForChild("Data", 10)
	end)
	Data = ok and folder or nil
end

local function dataChild(...)
	return Data and find(Data, ...)
end

local Remotes
do
	local ok, folder = pcall(function()
		return ReplicatedStorage:WaitForChild("Remotes", 10)
	end)
	Remotes = ok and folder or nil
end

local function remote(name)
	return Remotes and Remotes:FindFirstChild(name) or nil
end

-- Real BigNum module if present, else a digit-based stub
local BigNum
do
	local module = find(ReplicatedStorage, "Util", "BigNum")
	if module then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" and type(result.GreaterEqual) == "function" then
			BigNum = result
		end
	end
	if not BigNum then
		BigNum = {
			GreaterEqual = function(winsValue, req)
				local numeric = 0
				if type(winsValue) == "number" then
					numeric = winsValue
				elseif winsValue and type(winsValue.FindFirstChild) == "function" then
					local digits = winsValue:FindFirstChild("Digits")
					numeric = digits and tonumber(digits.Value) or 0
				end
				return numeric >= (tonumber(req) or 0)
			end,
		}
	end
end

-- Formatter: prefers the game's real Util.Formatter, else an exact embedded copy
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
					if more then
						out = out .. char
					end
				else
					if count >= maxChars then
						break
					end
					out = out .. char
					count = count + 1
				end
			end
			if string.sub(out, -1) == "." then
				out = string.sub(out, 1, -2)
			end
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

local function getLevel()
	local level = dataChild("Level")
	return level and tonumber(level.Value) or 0
end

local function getRebirths()
	local rebirths = dataChild("Rebirths")
	return rebirths and tonumber(rebirths.Value) or 0
end

local function getSpeedMulti()
	local multi = dataChild("SpeedMulti")
	return multi and tonumber(multi.Value) or 0
end

local function getWinsDigits()
	local wins = dataChild("Wins")
	if not wins then
		return 0
	end
	if BigNum then
		local ok, result = pcall(BigNum.ToNumber, wins)
		if ok and type(result) == "number" then
			return result
		end
	end
	local digits = wins:FindFirstChild("Digits")
	if not digits then
		return 0
	end
	local raw = tostring(digits.Value)
	if raw == "" then
		return 0
	end
	if tonumber(raw) then
		return tonumber(raw)
	end
	-- BigNum digit groups are comma-joined, least-significant first
	local groups = {}
	for group in string.gmatch(raw, "[^,]+") do
		groups[#groups + 1] = tonumber(group) or 0
	end
	local value = 0
	for index = #groups, 1, -1 do
		value = value * 1000000 + groups[index]
	end
	return value
end

-- Embedded game configs (avoids require of Plugin modules)
local UpgradesCfg = {
	{WinsRequirement = 0, Multi = 1, Skin = "Cubic"},
	{WinsRequirement = 3, Multi = 2, Skin = "Portal"},
	{WinsRequirement = 15, Multi = 4, Skin = "Bolt"},
	{WinsRequirement = 100, Multi = 8, Skin = "Glitch"},
	{WinsRequirement = 500, Multi = 16, Skin = "Fairy"},
	{WinsRequirement = 2500, Multi = 32, Skin = "Forsaken"},
	{WinsRequirement = 15000, Multi = 64, Skin = "Crystal"},
	{WinsRequirement = 50000, Multi = 128, Skin = "Poison"},
	{WinsRequirement = 250000, Multi = 256, Skin = "Angel"},
	{WinsRequirement = 1000000, Multi = 512, Skin = "Haste"},
}
local MainCfg = {
	WorldRebirthsRequired = {World2 = 8, World3 = 16, World4 = 24, World5 = 32},
	StageWins = {
		World1 = {1, 5, 20, 100, 500, 3000, 15000, 50000, 200000},
		World2 = {1000000, 5000000, 25000000, 100000000, 600000000, 3000000000, 25000000000, 150000000000, 1000000000000},
		World3 = {5000000000000, 20000000000000, 75000000000000, 250000000000000, 1000000000000000, 5000000000000000, 25000000000000000, 100000000000000000, 400000000000000000},
		World4 = {2000000000000000000, 10000000000000000000, 75000000000000000000, 350000000000000000000, 2000000000000000000000, 10000000000000000000000, 50000000000000000000000, 250000000000000000000000, 1000000000000000000000000},
		World5 = {5000000000000000000000000, 25000000000000000000000000, 75000000000000000000000000, 250000000000000000000000000, 1000000000000000000000000000, 5000000000000000000000000000, 20000000000000000000000000000, 80000000000000000000000000000, 350000000000000000000000000000},
	},
	ChapterStageWins = {
		C1 = {
			W1 = {1, 5, 20, 100, 500, 3000, 15000, 50000, 200000},
			W2 = {1000000, 5000000, 25000000, 100000000, 600000000, 3000000000, 25000000000, 150000000000, 1000000000000},
			W3 = {5000000000000, 20000000000000, 75000000000000, 250000000000000, 1000000000000000, 5000000000000000, 25000000000000000, 100000000000000000, 400000000000000000},
			W4 = {2000000000000000000, 10000000000000000000, 75000000000000000000, 350000000000000000000, 2000000000000000000000, 10000000000000000000000, 50000000000000000000000, 250000000000000000000000, 1000000000000000000000000},
			W5 = {5000000000000000000000000, 25000000000000000000000000, 75000000000000000000000000, 250000000000000000000000000, 1000000000000000000000000000, 5000000000000000000000000000, 20000000000000000000000000000, 80000000000000000000000000000, 350000000000000000000000000000},
		},
		C2 = {
			W1 = {1, 5, 20, 100, 500, 3000},
		},
	},
}
local TreadmillCfg = {Multis = {Basic = 1, Reward = 1.5, Golden = 3, Diamond = 9, Galaxy = 25, Emerald = 100, Void = 100, Celestial = 1000, Quantum = 10}}

-- Real Balancing module if present, so tail requirements match the server scaling
local Balancing
do
	local module = find(ReplicatedStorage, "Util", "Balancing")
	if module then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" and type(result.GetWinMultiAtLevel) == "function" then
			Balancing = result
		end
	end
end

local function tailRequirement(idx)
	local base = UpgradesCfg[idx] and UpgradesCfg[idx].WinsRequirement or 0
	if Balancing then
		local ok, scaled = pcall(function()
			return base * Balancing.GetWinMultiAtLevel(Balancing.GetUpgradeLevel(idx - 1))
		end)
		if ok and type(scaled) == "number" then
			return scaled
		end
	end
	return base
end

local function winsGreaterEqual(req)
	local wins = dataChild("Wins")
	if wins then
		local ok, result = pcall(BigNum.GreaterEqual, wins, req)
		if ok then
			return result == true
		end
	end
	return getWinsDigits() >= (tonumber(req) or 0)
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

local function getHealth()
	local humanoid = getHumanoid()
	return humanoid and math.floor(humanoid.Health) or 0
end

local function getMaxHealth()
	local humanoid = getHumanoid()
	return humanoid and math.floor(humanoid.MaxHealth) or 0
end

local function getPing()
	local ok, ping = pcall(LocalPlayer.GetNetworkPing, LocalPlayer)
	if ok and type(ping) == "number" then
		return math.floor(ping * 1000 + 0.5)
	end
	return 0
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

local function teleportTo(position)
	local root = getRoot()
	if root and position then
		root.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		return true
	end
	return false
end

-- ============ GAME FEATURE LOGIC ============

local function isWorldUnlocked(world)
	local num = tonumber(string.match(world, "World(%d+)") or "0") or 0
	if num <= 1 then
		return true
	end
	local req = MainCfg.WorldRebirthsRequired[world]
	if not req then
		return true
	end
	return getRebirths() >= req
end

local function isTreadmillUnlocked(ttype)
	if ttype == "Sunken" then
		local shards = dataChild("CollectedShards")
		if not shards or #shards:GetChildren() < 9 then
			return false
		end
	end
	if ttype == "Quantum" then
		return false
	end
	local paidList = {Golden = true, Diamond = true, Galaxy = true, Void = true, Celestial = true, Emerald = true}
	if not paidList[ttype] then
		return true
	end
	local passes = dataChild("Passes")
	return passes and passes:FindFirstChild(ttype) ~= nil
end

local function getTreadmillPart(preferred)
	local best, bestMulti = nil, -1
	for _, part in ipairs(CollectionService:GetTagged("Treadmill")) do
		if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
			local ttype = part:GetAttribute("Type") or part.Name
			if isTreadmillUnlocked(ttype) then
				if preferred and string.lower(ttype) == string.lower(preferred) then
					return part
				end
				if not preferred then
					local multi = TreadmillCfg.Multis[ttype] or 0
					if multi > bestMulti then
						bestMulti = multi
						best = part
					end
				end
			end
		end
	end
	if best then
		return best
	end
	for _, part in ipairs(CollectionService:GetTagged("Treadmill")) do
		if part:IsA("BasePart") and part:IsDescendantOf(Workspace) then
			local ttype = part:GetAttribute("Type") or part.Name
			if isTreadmillUnlocked(ttype) then
				return part
			end
		end
	end
	return nil
end

local function treadmillSpot(part)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	-- land just above the belt surface so the character never floats above it
	return Vector3.new(part.Position.X, part.Position.Y + part.Size.Y / 2 + 1, part.Position.Z)
end

local function doAutoTrain()
	if not enabled.train then
		return
	end
	-- wins farming takes priority; never fight it over the character position
	if enabled.wins then
		return
	end
	local useBest = enabled.trainBest ~= false
	local preferred = useBest and nil or (Options.TrainTreadmill_Select and Options.TrainTreadmill_Select.Value)
	local part = getTreadmillPart(preferred)
	if not part then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	setFarmStatus("training")
	local spot = treadmillSpot(part)
	if spot and (root.Position - spot).Magnitude > 8 then
		-- teleport at most once every 3s so it never thrashes
		if not ready("treadmillTp", 3) then
			return
		end
		root.CFrame = CFrame.new(spot)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
		end)
		task.wait(0.25)
		return
	end
	-- while standing on it, gently re-register the touch every 3s
	if ready("treadmillTouch", 3) and firetouchinterest then
		pcall(firetouchinterest, part, root, 0)
		task.wait(0.05)
		pcall(firetouchinterest, part, root, 1)
	end
end

-- Streaming-safe fixed win pad positions (per chapter/world/stage)
local FixedWinPos = {
	C1 = {
		W1 = {
			[1] = Vector3.new(-682.16, 23.04, -255.05),
			[2] = Vector3.new(-935.66, 23.04, -255.05),
			[3] = Vector3.new(-1214.16, 23.04, -255.05),
			[4] = Vector3.new(-1569.16, 23.04, -255.05),
			[5] = Vector3.new(-2183.16, 118.04, -255.05),
			[6] = Vector3.new(-3046.41, 118.04, -255.05),
			[7] = Vector3.new(-4318.16, 277.04, -255.05),
			[8] = Vector3.new(-6158.66, 277.04, -254.66),
			[9] = Vector3.new(-9459, 399, -255),
		},
		W2 = {
			[1] = Vector3.new(-735.16, 23.04, -2565.05),
			[2] = Vector3.new(-1095.01, 38.04, -2565.05),
			[3] = Vector3.new(-1880.16, -51.96, -2565.05),
			[4] = Vector3.new(-2400.16, 55.34, -2565.05),
			[5] = Vector3.new(-3247.16, 55.34, -2565.05),
			[6] = Vector3.new(-3605.38, 55.34, -3697.49),
			[7] = Vector3.new(-3605.38, 55.34, -4607.49),
			[8] = Vector3.new(-3605.38, 55.34, -5827.49),
			[9] = Vector3.new(-3603, 164, -9379),
		},
		W3 = {
			[1] = Vector3.new(-684.16, 22.54, 2740.95),
			[2] = Vector3.new(-953.63, 22.54, 2740.95),
			[3] = Vector3.new(-1286.63, 22.54, 2740.95),
			[4] = Vector3.new(-1684.63, 22.54, 2740.95),
			[5] = Vector3.new(-2240.63, 22.54, 2740.95),
			[6] = Vector3.new(-2560.63, 278.54, 2740.95),
			[7] = Vector3.new(-4208.63, 278.54, 2740.95),
			[8] = Vector3.new(-5420.63, 278.54, 2740.95),
			[9] = Vector3.new(-8077.63, 278.54, 2740.95),
		},
		W4 = {
			[1] = Vector3.new(-684.16, 22.54, 5740.95),
			[2] = Vector3.new(-892.16, 22.54, 5740.95),
			[3] = Vector3.new(-1206.66, 22.54, 5740.95),
			[4] = Vector3.new(-1592.66, 22.54, 5740.95),
			[5] = Vector3.new(-1852.06, 172.54, 5740.95),
			[6] = Vector3.new(-2718.06, 172.54, 5740.95),
			[7] = Vector3.new(-3933.06, 172.54, 5740.95),
			[8] = Vector3.new(-5663.06, 17.5, 5740.95),
			[9] = Vector3.new(-7760.11, 17.5, 5740.95),
		},
		W5 = {
			[1] = Vector3.new(-684.16, 22.54, 7561.95),
			[2] = Vector3.new(-1005.16, 22.54, 7561.95),
			[3] = Vector3.new(-1333.16, 22.54, 7561.95),
			[4] = Vector3.new(-1778.15, 103.54, 7444.95),
			[5] = Vector3.new(-2369.24, 103.54, 7444.95),
			[6] = Vector3.new(-2828.45, 283.54, 7801.31),
		},
	},
	C2 = {
		W1 = {
			[1] = Vector3.new(-682.162, 23.04, -255.048),
			[2] = Vector3.new(-936.65, 23.04, -255.048),
			[3] = Vector3.new(-1367.412, 23.04, -255.048),
			[4] = Vector3.new(-1663.412, 108.04, -255.048),
			[5] = Vector3.new(-2513.412, 108.04, -255.048),
			[6] = Vector3.new(-3548.412, 108.04, -255.048),
		},
	},
}

local winOptions = {}
do
	for chapter, worlds in pairs(MainCfg.ChapterStageWins) do
		for world, stages in pairs(worlds) do
			for stage in ipairs(stages) do
				table.insert(winOptions, string.format("%s %s Stage%d", chapter, world, stage))
			end
		end
	end
	table.sort(winOptions, function(a, b)
		local ca, wa, sa = string.match(a, "([C%d]+) ([W%d]+) Stage(%d+)")
		local cb, wb, sb = string.match(b, "([C%d]+) ([W%d]+) Stage(%d+)")
		if ca ~= cb then
			local cana, canb = tonumber(ca:sub(2)), tonumber(cb:sub(2))
			if cana and canb and cana ~= canb then
				return cana < canb
			end
		end
		if wa ~= wb then
			local wana, wanb = tonumber(wa:sub(2)), tonumber(wb:sub(2))
			if wana and wanb and wana ~= wanb then
				return wana < wanb
			end
		end
		return tonumber(sa) < tonumber(sb)
	end)
end

local function scanYellowWinButtons()
	local buttons = {}
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "Button" and part.BrickColor.Name == "New Yeller" and part.Parent and part.Parent.Name == "NormalWin" then
			buttons[#buttons + 1] = part
		end
	end
	return buttons
end

local function nearestYellowButton(position)
	local best, bestDist = nil, 80
	for _, part in ipairs(scanYellowWinButtons()) do
		local dist = (part.Position - position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = part
		end
	end
	return best
end

local function touchWinButton(part)
	local root = getRoot()
	if not root or not part then
		return
	end
	if firetouchinterest then
		pcall(firetouchinterest, part, root, 0)
		task.wait(0.05)
		pcall(firetouchinterest, part, root, 1)
	else
		root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	end
end

local function parseWinSelection(selection)
	if type(selection) ~= "string" or selection == "" then
		return nil, nil, nil
	end
	local chapter = string.match(selection, "(C%d+)")
	local world = string.match(selection, "(W%d+)")
	if not chapter or not world then
		return nil, nil, nil
	end
	local stage = tonumber(string.match(selection, "Stage(%d+)")) or 1
	return chapter, world, stage
end

local function stageWinsRequirement(chapter, world, stage)
	if MainCfg.ChapterStageWins[chapter] and MainCfg.ChapterStageWins[chapter][world] then
		local stages = MainCfg.ChapterStageWins[chapter][world]
		return (stages and stages[stage]) or 0
	end
	return 0
end

local function getBestUnlockedStage()
	-- highest chapter/world+stage whose win requirement is met
	local bestChapter, bestWorld, bestStage = nil, nil, nil
	for _, entry in ipairs(winOptions) do
		local chapter, world, stage = parseWinSelection(entry)
		if chapter and world and winsGreaterEqual(stageWinsRequirement(chapter, world, stage)) then
			bestChapter, bestWorld, bestStage = chapter, world, stage
		end
	end
	if bestChapter then
		return bestChapter, bestWorld, bestStage
	end
	-- nothing affordable yet: fall back to first available stage
	for _, entry in ipairs(winOptions) do
		local chapter, world, stage = parseWinSelection(entry)
		if chapter and world then
			return chapter, world, stage
		end
	end
	return "C1", "W1", 1
end

local function doAutoWins()
	if not enabled.wins then
		return
	end
	local chapter, world, stage = parseWinSelection(Options.AutoWins_Manual and Options.AutoWins_Manual.Value)
	if not chapter then
		-- default: best unlocked + affordable stage
		chapter, world, stage = getBestUnlockedStage()
	end
	local winReq = stageWinsRequirement(chapter, world, stage or 1)
	if not winsGreaterEqual(winReq) then
		-- touching the pad without enough wins does nothing, so skip it
		setFarmStatus("needs " .. Formatter.Format(winReq) .. " wins")
		return
	end
	setFarmStatus("farming wins")
	local fixedPos = FixedWinPos[chapter] and FixedWinPos[chapter][world] and FixedWinPos[chapter][world][stage or 1]
	if fixedPos then
		teleportTo(fixedPos)
		task.wait(0.15)
		local button = nearestYellowButton(fixedPos)
		touchWinButton(button)
	else
		local button = nearestYellowButton(getRoot() and getRoot().Position or Vector3.zero)
		if button then
			teleportTo(button.Position)
			task.wait(0.15)
			touchWinButton(button)
		end
	end
end

local function doAutoCollectBananas()
	if not enabled.bananas then
		return
	end
	setFarmStatus("collecting bananas")
	local root = getRoot()
	if not root then
		return
	end
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and string.find(string.lower(part.Name), "banana", 1, true) then
			pcall(firetouchinterest, part, root, 0)
			pcall(firetouchinterest, part, root, 1)
		end
	end
	for _, prompt in ipairs(Workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and string.find(string.lower(prompt.ObjectText or ""), "banana", 1, true) then
			pcall(fireproximityprompt, prompt)
		end
	end
end

local function doAutoCollectShards()
	if not enabled.shards then
		return
	end
	setFarmStatus("collecting shards")
	local selected = Options.AutoCollectShards_Select and Options.AutoCollectShards_Select.Value or {}
	local names = {}
	if type(selected) == "table" then
		for key, value in pairs(selected) do
			if value then
				names[#names + 1] = key
			end
		end
	elseif type(selected) == "string" and selected ~= "" then
		names[#names + 1] = selected
	end
	if #names == 0 then
		names = {"Shard1", "Shard2", "Shard3", "Shard4", "Shard5", "Shard6", "Shard7", "Shard8", "Shard9"}
	end
	table.sort(names)
	for _, name in ipairs(names) do
		safeFire(remote("CollectShard"), name)
	end
end

local function doAutoRace()
	if not enabled.race then
		return
	end
	setFarmStatus("joining race")
	safeFire(remote("JoinRace"))
end

local function doAutoRewards()
	if not enabled.freeReward and not enabled.streakReward and not enabled.offlineEarnings then
		return
	end
	if enabled.freeReward and ready("freeReward", 5) then
		safeFire(remote("ClaimFreeReward"))
	end
	if enabled.streakReward and ready("streakReward", 5) then
		safeFire(remote("ClaimStreakReward"))
	end
	if enabled.offlineEarnings and ready("offlineEarnings", 5) then
		safeFire(remote("ClaimOfflineEarnings"))
	end
end

local CODE_LIST = {"STREAK", "100MVISITS", "250KCCU", "1MCCU", "300MVISITS", "PULSEISANOOB", "50MVISITS", "CODESYAY", "80MVISITS"}

local function doAutoRedeemCode()
	if not enabled.codes then
		return
	end
	if ready("codes", 3) then
		for _, code in ipairs(CODE_LIST) do
			safeFire(remote("RedeemCode"), code)
		end
	end
end

local function doAutoSpinWheel()
	if not enabled.spin then
		return
	end
	if ready("spin", 3) then
		safeFire(remote("SpawnWheel"))
		safeFire(remote("PlayLootBoxSpin"))
	end
end

local function doAutoChests()
	if not enabled.skullChest and not enabled.secretChest and not enabled.secretDoor then
		return
	end
	if enabled.skullChest and ready("skullChest", 1) then
		safeFire(remote("OpenSkullChest"), 1)
	end
	if enabled.secretChest and ready("secretChest", 1) then
		safeFire(remote("OpenSecretChest"), 1)
	end
	if enabled.secretDoor and ready("secretDoor", 2) then
		safeFire(remote("SecretDoorRequestEnter"))
	end
end

local function doAutoTails()
	if not enabled.tailsBuy and not enabled.tailsEquip then
		return
	end
	local unlocked = dataChild("UnlockedUpgrades")
	local selected = dataChild("SelectedUpgrade")
	local selectedIdx = selected and tonumber(selected.Value) or 1
	if enabled.tailsBuy and ready("tailsBuy", 1) then
		local bestIdx, bestReq = nil, -1
		for idx, cfg in ipairs(UpgradesCfg) do
			local owned = unlocked and unlocked:FindFirstChild(tostring(idx))
			local req = tailRequirement(idx)
			if not owned and cfg.WinsRequirement and winsGreaterEqual(req) then
				if req > bestReq then
					bestReq = req
					bestIdx = idx
				end
			end
		end
		if bestIdx and bestIdx ~= selectedIdx then
			setFarmStatus("buy tail " .. (UpgradesCfg[bestIdx].Skin or bestIdx))
			safeFire(remote("SelectUpgrade"), bestIdx)
		end
	end
	if enabled.tailsEquip and ready("tailsEquip", 1) then
		local bestOwned = 1
		if unlocked then
			for _, child in ipairs(unlocked:GetChildren()) do
				local num = tonumber(child.Name)
				if num and num > bestOwned then
					bestOwned = num
				end
			end
		end
		if bestOwned ~= selectedIdx then
			setFarmStatus("equip tail " .. (UpgradesCfg[bestOwned] and UpgradesCfg[bestOwned].Skin or bestOwned))
			safeFire(remote("SelectUpgrade"), bestOwned)
		end
	end
end

local TRAIL_LIST = {"Swamp", "TimeTraveler", "Golden", "Galactus", "FrostBorn", "Vaporwave", "Null"}

local function doAutoTrails()
	if not enabled.trailBuy and not enabled.trailEquip then
		return
	end
	local unlocked = dataChild("UnlockedTrails")
	if enabled.trailBuy and ready("trailBuy", 1) then
		for _, name in ipairs(TRAIL_LIST) do
			if not unlocked or not unlocked:FindFirstChild(name) then
				setFarmStatus("buy trail " .. name)
				safeFire(remote("BuyTrail"), name)
				break
			end
		end
	end
	if enabled.trailEquip and ready("trailEquip", 1) then
		local best
		for index = #TRAIL_LIST, 1, -1 do
			if not unlocked or unlocked:FindFirstChild(TRAIL_LIST[index]) then
				best = TRAIL_LIST[index]
				break
			end
		end
		if best then
			setFarmStatus("equip trail " .. best)
			safeFire(remote("EquipTrail"), best)
		end
	end
end

local AURA_LIST = {"Swamp", "TimeTraveler", "Golden", "Galactus", "FrostBorn", "Vaporwave", "Null"}

local function doAutoAuras()
	if not enabled.auraBuy and not enabled.auraEquip then
		return
	end
	local unlocked = dataChild("UnlockedAuras")
	if enabled.auraBuy and ready("auraBuy", 1) then
		for _, name in ipairs(AURA_LIST) do
			if not unlocked or not unlocked:FindFirstChild(name) then
				setFarmStatus("buy aura " .. name)
				safeFire(remote("BuyAura"), name)
				break
			end
		end
	end
	if enabled.auraEquip and ready("auraEquip", 1) then
		local best
		for index = #AURA_LIST, 1, -1 do
			if not unlocked or unlocked:FindFirstChild(AURA_LIST[index]) then
				best = AURA_LIST[index]
				break
			end
		end
		if best then
			setFarmStatus("equip aura " .. best)
			safeFire(remote("EquipAura"), best)
		end
	end
end

local CHARM_RARITY = {}
do
	local charms = find(ReplicatedStorage, "Config", "Charms")
	if charms then
		local ok, config = pcall(require, charms)
		if ok and type(config) == "table" and type(config.Items) == "table" then
			for _, worldItems in pairs(config.Items) do
				if type(worldItems) == "table" then
					for name, item in pairs(worldItems) do
						if type(item) == "table" and type(item.Rarity) == "string" then
							CHARM_RARITY[name] = item.Rarity
						end
					end
				end
			end
		end
	end
end

local RARITY_RANK = {Rare = 1, Epic = 2, Legendary = 3, Mythic = 4, Secret = 5}

local function doAutoCharms()
	if not enabled.charmBuy then
		return
	end
	if not ready("charmBuy", 1) then
		return
	end
	-- buy by rarity only: anything at or above the selected rarity
	local rarityFilter = (Options.CharmBuyRarity and Options.CharmBuyRarity.Value) or "Rare"
	local minRank = RARITY_RANK[rarityFilter] or 1
	local world = dataChild("World")
	local worldName = world and tostring(world.Value) or "1"
	local charmShop = dataChild("CharmShop")
	local shopFolder = charmShop and charmShop:FindFirstChild("World" .. worldName)
	if not shopFolder then
		return
	end
	for slot = 1, 3 do
		local slotValue = shopFolder:FindFirstChild("Slot" .. slot)
		local boughtValue = shopFolder:FindFirstChild("Bought" .. slot)
		if slotValue and slotValue:IsA("StringValue") and boughtValue and boughtValue.Value == false then
			local charmName = slotValue.Value
			local rarity = CHARM_RARITY[charmName]
			if rarity ~= nil and (RARITY_RANK[rarity] or 0) >= minRank then
				setFarmStatus("buy charm " .. charmName)
				safeFire(remote("BuyCharm"), slot)
				task.wait(0.6)
			end
		end
	end
end

local function doAutoEquipCharms()
	if not enabled.charmEquip then
		return
	end
	if not ready("charmEquip", 1) then
		return
	end
	local mode = (Options.AutoEquipBestCharms_Mode and Options.AutoEquipBestCharms_Mode.Value) or "Wins"
	safeFire(remote("EquipBestCharms"), mode)
end

local function doAutoDeleteCharms()
	if not enabled.charmDelete then
		return
	end
	if not ready("charmDelete", 1) then
		return
	end
	local stopOn = (Options.AutoDeleteCharms_StopOn and Options.AutoDeleteCharms_StopOn.Value) or "Rare"
	safeFire(remote("DeleteCharms"), stopOn)
end

local function doAutoFuseCharms()
	if not enabled.charmFuse then
		return
	end
	if not ready("charmFuse", 1) then
		return
	end
	local charmsFolder = dataChild("Charms")
	if not charmsFolder then
		return
	end
	local byKey = {}
	for _, charm in ipairs(charmsFolder:GetChildren()) do
		local charmName = charm:GetAttribute("CharmName") or charm:GetAttribute("Name") or ""
		if charmName ~= "" and not charm:GetAttribute("Locked") then
			local stars = tonumber(charm:GetAttribute("Stars")) or 0
			if stars < 3 then
				local key = charmName .. "_" .. stars
				byKey[key] = byKey[key] or {}
				table.insert(byKey[key], charm.Name)
			end
		end
	end
	for _, ids in pairs(byKey) do
		if #ids >= 3 then
			setFarmStatus("fuse charms")
			safeFire(remote("FuseCharms"), {ids[1], ids[2], ids[3]})
			return
		end
	end
end

local POTION_LIST = {"Speed Potion (10m)", "Speed Potion (30m)", "Speed Potion (1h)", "Wins Potion (10m)", "Wins Potion (30m)", "Wins Potion (1h)"}

local function doAutoPotions()
	if not enabled.potions then
		return
	end
	if not ready("potions", 2) then
		return
	end
	local selected = Options.SelectedPotions and Options.SelectedPotions.Value or {}
	local wanted = {}
	if type(selected) == "table" then
		for key, value in pairs(selected) do
			if value then
				wanted[key] = true
			end
		end
	elseif type(selected) == "string" and selected ~= "" then
		wanted[selected] = true
	end
	for _, potion in ipairs(POTION_LIST) do
		if wanted[potion] then
			safeFire(remote("UsePotion"), potion)
		end
	end
end

local function doAutoRebirth()
	if not enabled.rebirth then
		return
	end
	if not ready("rebirth", 1) then
		return
	end
	setFarmStatus("rebirth")
	safeFire(remote("Rebirth"))
end

-- ============ SERVER TOOLS ============

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

-- ============ UI ============

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

local TrainTab = Tabs.Main:AddSubTab({ Name = "Train", Icon = "activity" })
local WinsTab = Tabs.Main:AddSubTab({ Name = "Wins", Icon = "trophy" })
local CollectTab = Tabs.Main:AddSubTab({ Name = "Collecting", Icon = "package" })
local InventoryTab = Tabs.Main:AddSubTab({ Name = "Inventory", Icon = "backpack" })
local CharmsTab = Tabs.Main:AddSubTab({ Name = "Charms", Icon = "gem" })

local TrainBox = box(TrainTab, "Auto Train", "activity", "Left")
TrainBox:AddDropdown("TrainTreadmill_Select", {
	Text = "Treadmill",
	Values = {"Basic", "Reward", "Quantum", "Golden", "Diamond", "Galaxy", "Emerald", "Void", "Celestial"},
	Default = "Basic",
})
TrainBox:AddToggle("AutoTrain", { Text = "Auto Train on Treadmill", Default = false, Callback = function(value)
	enabled.train = value
end })
TrainBox:AddToggle("AutoTrainBest", { Text = "Use Best Unlocked (no Robux)", Default = true, Callback = function(value)
	enabled.trainBest = value
end })

local WinsBox = box(WinsTab, "Auto Farm Wins", "trophy", "Left")
WinsBox:AddDropdown("AutoWins_Manual", {
	Text = "Win Pad",
	Values = winOptions,
	Default = 1,
})
WinsBox:AddToggle("AutoWins", { Text = "Auto Farm Wins", Default = false, Callback = function(value)
	enabled.wins = value
end })

local StatusBox = box(WinsTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("LevelLabel", { Text = paint("Level -", "0", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("RebirthLabel", { Text = paint("Rebirths -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("WinsLabel", { Text = paint("Wins -", "0", COLORS.gold), DoesWrap = true })
StatusBox:AddLabel("MultiLabel", { Text = paint("Speed Multi -", "1", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("WinReqLabel", { Text = paint("Win Req -", "-", COLORS.gold), DoesWrap = true })

local CollectBox = box(CollectTab, "Collecting", "package", "Left")
CollectBox:AddToggle("AutoCollectBananas", { Text = "Auto Collect Bananas", Default = false, Callback = function(value)
	enabled.bananas = value
end })
CollectBox:AddDropdown("AutoCollectShards_Select", {
	Text = "Sunken Shards",
	Values = {"Shard1", "Shard2", "Shard3", "Shard4", "Shard5", "Shard6", "Shard7", "Shard8", "Shard9"},
	Default = 1,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
})
CollectBox:AddToggle("AutoCollectShards", { Text = "Auto Collect Sunken Shards", Default = false, Callback = function(value)
	enabled.shards = value
end })

local RewardBox = box(CollectTab, "Rewards & Codes", "gift", "Right")
RewardBox:AddToggle("AutoClaimFreeReward", { Text = "Auto Claim Free Reward", Default = false, Callback = function(value)
	enabled.freeReward = value
end })
RewardBox:AddToggle("AutoClaimStreakReward", { Text = "Auto Claim Streak Reward", Default = false, Callback = function(value)
	enabled.streakReward = value
end })
RewardBox:AddToggle("AutoClaimOfflineEarnings", { Text = "Auto Claim Offline Earnings", Default = false, Callback = function(value)
	enabled.offlineEarnings = value
end })
RewardBox:AddToggle("AutoRedeemCode", { Text = "Auto Redeem Code", Default = false, Callback = function(value)
	enabled.codes = value
end })
RewardBox:AddToggle("AutoSpinWheel", { Text = "Auto Spin Wheel", Default = false, Callback = function(value)
	enabled.spin = value
end })

local ChestBox = box(CollectTab, "Chests & Doors", "box", "Right")
ChestBox:AddToggle("AutoOpenSkullChest", { Text = "Auto Open Skull Chest", Default = false, Callback = function(value)
	enabled.skullChest = value
end })
ChestBox:AddToggle("AutoOpenSecretChest", { Text = "Auto Open Secret Chest", Default = false, Callback = function(value)
	enabled.secretChest = value
end })
ChestBox:AddToggle("AutoEnterSecretDoor", { Text = "Auto Enter Secret Door", Default = false, Callback = function(value)
	enabled.secretDoor = value
end })

local RaceBox = box(CollectTab, "Race", "flag", "Right")
RaceBox:AddToggle("AutoJoinRace", { Text = "Auto Join Race", Default = false, Callback = function(value)
	enabled.race = value
end })

local TailsBox = box(InventoryTab, "Monkey Tails", "shirt", "Left")
TailsBox:AddToggle("AutoBuyTails", { Text = "Auto Buy Best Tail", Default = false, Callback = function(value)
	enabled.tailsBuy = value
end })
TailsBox:AddToggle("AutoEquipBestTails", { Text = "Auto Equip Best Owned Tail", Default = false, Callback = function(value)
	enabled.tailsEquip = value
end })

local TrailsBox = box(InventoryTab, "Trails", "wind", "Right")
TrailsBox:AddToggle("AutoBuyTrail", { Text = "Auto Buy Next Trail", Default = false, Callback = function(value)
	enabled.trailBuy = value
end })
TrailsBox:AddToggle("AutoEquipBestTrail", { Text = "Auto Equip Best Trail", Default = false, Callback = function(value)
	enabled.trailEquip = value
end })

local AurasBox = box(InventoryTab, "Auras", "sparkles", "Left")
AurasBox:AddToggle("AutoBuyAura", { Text = "Auto Buy Next Aura", Default = false, Callback = function(value)
	enabled.auraBuy = value
end })
AurasBox:AddToggle("AutoEquipAura", { Text = "Auto Equip Best Aura", Default = false, Callback = function(value)
	enabled.auraEquip = value
end })

local PotionBox = box(InventoryTab, "Potions", "flask-conical", "Right")
PotionBox:AddDropdown("SelectedPotions", {
	Text = "Potions",
	Values = POTION_LIST,
	Default = 1,
	Multi = true,
	Searchable = true,
	SelectAllButtons = true,
})
PotionBox:AddToggle("AutoUsePotions", { Text = "Auto Use Selected Potions", Default = false, Callback = function(value)
	enabled.potions = value
end })

local CharmBuyBox = box(CharmsTab, "Charm Shop", "gem", "Left")
CharmBuyBox:AddDropdown("CharmBuyRarity", {
	Text = "Buy By Rarity",
	Values = {"Rare", "Epic", "Legendary", "Mythic", "Secret"},
	Default = "Rare",
})
CharmBuyBox:AddToggle("AutoBuyCharm", { Text = "Auto Buy Charms", Default = false, Callback = function(value)
	enabled.charmBuy = value
end })

local CharmManageBox = box(CharmsTab, "Charm Manage", "settings-2", "Right")
CharmManageBox:AddDropdown("AutoEquipBestCharms_Mode", {
	Text = "Equip Best Mode",
	Values = {"Wins", "Speed"},
	Default = "Wins",
})
CharmManageBox:AddToggle("AutoEquipBestCharms", { Text = "Auto Equip Best Charms", Default = false, Callback = function(value)
	enabled.charmEquip = value
end })
CharmManageBox:AddDropdown("AutoDeleteCharms_StopOn", {
	Text = "Delete Stops On",
	Values = {"Rare", "Epic", "Legendary", "Mythic"},
	Default = "Rare",
})
CharmManageBox:AddToggle("AutoDeleteCharms", { Text = "Auto Delete Charms", Default = false, Callback = function(value)
	enabled.charmDelete = value
end })
CharmManageBox:AddToggle("AutoFuseCharms", { Text = "Auto Fuse Charms", Default = false, Callback = function(value)
	enabled.charmFuse = value
end })

local RebirthBox = box(CharmsTab, "Rebirth", "refresh-cw", "Left")
RebirthBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(value)
	enabled.rebirth = value
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
ClientBox:AddToggle("NoGameplayPaused", { Text = "No Pause", Default = false, Callback = function(value)
	scriptState.noPause = value
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
	setLabel("LevelLabel", paint("Level -", getLevel(), COLORS.accent))
	setLabel("RebirthLabel", paint("Rebirths -", getRebirths(), COLORS.orange))
	setLabel("WinsLabel", paint("Wins -", Formatter.Format(getWinsDigits()), COLORS.gold))
	setLabel("MultiLabel", paint("Speed Multi -", getSpeedMulti(), COLORS.user))
	local padChapter, padWorld, padStage = parseWinSelection(Options.AutoWins_Manual and Options.AutoWins_Manual.Value)
	if not padChapter then
		padChapter, padWorld, padStage = getBestUnlockedStage()
	end
	local padReq = stageWinsRequirement(padChapter, padWorld, padStage)
	local padMet = winsGreaterEqual(padReq)
	setLabel("WinReqLabel", paint("Win Req -", string.format("%s %s Stage%d - %s wins (%s)", padChapter, padWorld, padStage or 1, Formatter.Format(padReq), padMet and "met" or "not met"), padMet and COLORS.user or COLORS.orange))
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

chain({ doAutoWins }, 1)
chain({ doAutoTrain }, 1)
loop(doAutoCollectBananas, 0.5)
loop(doAutoCollectShards, 1)
loop(doAutoRace, 2)
loop(doAutoRewards, 1)
loop(doAutoRedeemCode, 3)
loop(doAutoSpinWheel, 3)
loop(doAutoChests, 1)
loop(doAutoTails, 1)
loop(doAutoTrails, 1)
loop(doAutoAuras, 1)
loop(doAutoCharms, 1)
loop(doAutoEquipCharms, 1)
loop(doAutoDeleteCharms, 1)
loop(doAutoFuseCharms, 1)
loop(doAutoPotions, 2)
loop(doAutoRebirth, 1)

task.spawn(function()
	while session.running do
		if scriptState.noPause then
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
