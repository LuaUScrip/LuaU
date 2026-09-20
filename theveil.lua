local Repo = "https://raw.githubusercontent.com/LuaUScrip/HUB/refs/heads/main/"
local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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
	GameName = "The Veil",
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

local enabled = {autoNoclip = true}
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

local Remotes
do
	local ok, folder = pcall(function() return ReplicatedStorage:WaitForChild("Remotes", 10) end)
	Remotes = ok and folder or nil
end

local function remote(name) return Remotes and Remotes:FindFirstChild(name) or nil end

local InteractPromptEvent = remote("InteractPromptEvent")
local SellItemsEvent = remote("SellItemsEvent")

local INTERACT_RANGE = 5
local ARRIVE_EPSILON = 4

local ALLY_TEAMS = {
	PlayerTeam = true,
	TrainingDummyTeam = true,
}

local TRINKET_NAMES = {
	["Ring"] = true,
	["Old Ring"] = true,
	["Amulet"] = true,
	["Old Amulet"] = true,
	["Goblet"] = true,
}

local RARITIES = { "Common", "Uncommon", "Rare", "Elite", "Legendary" }

local PROTECTED_ITEMS = {
	["Bag"] = true,
	["Lantern"] = true,
}

local MERCHANT_NAME = "Clement, Merchant"

local ESP_COLORS = {
	player = Color3.fromRGB(255, 90, 90),
	mob = Color3.fromRGB(255, 170, 60),
	drop = Color3.fromRGB(120, 255, 160),
	chest = Color3.fromRGB(255, 235, 120),
}

local RARITY_COLORS = {
	Common = 10197915,
	Uncommon = 4910432,
	Rare = 3717626,
	Elite = 11033582,
	Legendary = 16497700,
}

local RARITY_RANK = { Common = 1, Uncommon = 2, Rare = 3, Elite = 4, Legendary = 5 }

local function getCharacter() return LocalPlayer.Character end
local function getHumanoid() local character = getCharacter() return character and character:FindFirstChildOfClass("Humanoid") end
local function getRoot() local character = getCharacter() return character and character:FindFirstChild("HumanoidRootPart") end

local function isAlive()
	local humanoid = getHumanoid()
	return humanoid ~= nil and humanoid.Health > 0
end

local function inMenu()
	return LocalPlayer:GetAttribute("InMainMenu") == true
end

local function canAct()
	return session.running and not inMenu() and isAlive() and getRoot() ~= nil
end

local function teamOf(model)
	local team = model and model:FindFirstChild("Team")
	return team and team.Value or nil
end

local function myTeam()
	return teamOf(getCharacter())
end

local function isHostileMob(model)
	local team = teamOf(model)
	if not team then return false end
	return not ALLY_TEAMS[team]
end

local function isFriendlyPlayer(player)
	if player == LocalPlayer then return true end
	local mine = myTeam()
	local theirs = teamOf(player.Character)
	return mine ~= nil and theirs ~= nil and mine == theirs
end

local function partOf(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance end
	if instance:IsA("Model") then
		return instance.PrimaryPart
			or instance:FindFirstChild("HumanoidRootPart")
			or instance:FindFirstChild("Handle")
			or instance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function positionOf(instance)
	local part = partOf(instance)
	return part and part.Position or nil
end

local function distanceTo(instance)
	local root = getRoot()
	local pos = positionOf(instance)
	if not root or not pos then return math.huge end
	return (root.Position - pos).Magnitude
end

local function isInteractable(model, argument)
	if not model or not model.Parent then return false end
	if not model:FindFirstChild("IsInteractable") then return false end
	local arg = model:FindFirstChild("Argument")
	if not arg or not arg:IsA("StringValue") then return false end
	if argument and arg.Value ~= argument then return false end
	return true
end

local function dropsFolder()
	return Workspace:FindFirstChild("Drops")
end

local function monstersFolder()
	return Workspace:FindFirstChild("Monsters")
end

local function rarityOfDrop(model)
	return model:GetAttribute("Rarity") or "Common"
end

local function rarityOfItem(tool)
	local r = tool:FindFirstChild("Rarity")
	return (r and r.Value) or "Common"
end

local collisionOriginals = {}
local noclipActive = false
local travelling = false
local travelUntil = 0

local function markTravelling(seconds)
	travelling = true
	travelUntil = tick() + (seconds or 0.4)
end

local function applyNoclip()
	local character = getCharacter()
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if collisionOriginals[part] == nil then
				collisionOriginals[part] = part.CanCollide
			end
			if part.CanCollide then
				part.CanCollide = false
			end
		end
	end
	noclipActive = true
end

local function clearNoclip()
	if not noclipActive then return end
	for part, original in pairs(collisionOriginals) do
		if part and part.Parent then
			pcall(function() part.CanCollide = original end)
		end
	end
	table.clear(collisionOriginals)
	noclipActive = false
end

trackConnection(RunService.Stepped:Connect(function()
	if not session.running then
		clearNoclip()
		return
	end
	if travelling and tick() > travelUntil then
		travelling = false
	end
	local manual = enabled.noclip == true
	local auto = enabled.autoNoclip and travelling
	if manual or auto then
		applyNoclip()
	else
		clearNoclip()
	end
end))

local function freezeFall(root)
	if root then
		pcall(function() root.AssemblyLinearVelocity = Vector3.zero end)
	end
end

local function moveTo(targetPos, timeout)
	local root = getRoot()
	if not root or not targetPos then return false end
	local dest = targetPos + Vector3.new(0, 3, 0)
	local mode = Options.MoveMode and Options.MoveMode.Value or "Teleport"
	if mode == "Teleport" then
		markTravelling(0.5)
		root.CFrame = CFrame.new(dest)
		freezeFall(root)
		task.wait(0.12)
		return true
	end
	local speed = tonumber(Options.TweenSpeed and Options.TweenSpeed.Value) or 220
	local deadline = tick() + (timeout or 8)
	while tick() < deadline do
		markTravelling(0.4)
		if not canAct() then return false end
		root = getRoot()
		if not root then return false end
		local delta = dest - root.Position
		local dist = delta.Magnitude
		if dist <= ARRIVE_EPSILON then
			freezeFall(root)
			return true
		end
		local step = math.min(dist, speed * RunService.Heartbeat:Wait())
		root.CFrame = CFrame.new(root.Position + delta.Unit * step)
		freezeFall(root)
	end
	return false
end

local function approach(instance, range)
	range = range or INTERACT_RANGE
	local pos = positionOf(instance)
	if not pos then return false end
	if distanceTo(instance) <= range then return true end
	moveTo(pos, 8)
	return distanceTo(instance) <= (range + 3)
end

local function fireInteract(argument, instance)
	if not InteractPromptEvent then return false end
	local ok = pcall(function()
		InteractPromptEvent:FireServer(argument, instance)
	end)
	return ok
end

local function collect(model, argument)
	if not isInteractable(model, argument) then return false end
	if not approach(model) then return false end
	if not isInteractable(model, argument) then return false end
	fireInteract(argument, model)
	task.wait(tonumber(Options.ActionDelay and Options.ActionDelay.Value) or 0.15)
	local consumed = (not model.Parent) or (not model:FindFirstChild("IsInteractable"))
	if consumed then
		scriptState.picked = (scriptState.picked or 0) + 1
		setFarmStatus("picked " .. tostring(model.Name))
	end
	return consumed
end

local function gatherDrops(trinketsOnly, maxDistance)
	local folder = dropsFolder()
	local out = {}
	if not folder then return out end
	local root = getRoot()
	if not root then return out end
	for _, model in ipairs(folder:GetChildren()) do
		if isInteractable(model, "PickupDrop") then
			if (not trinketsOnly) or TRINKET_NAMES[model.Name] then
				local pos = positionOf(model)
				if pos then
					local d = (root.Position - pos).Magnitude
					if not maxDistance or maxDistance <= 0 or d <= maxDistance then
						out[#out + 1] = { model = model, dist = d }
					end
				end
			end
		end
	end
	table.sort(out, function(a, b) return a.dist < b.dist end)
	return out
end

local function gatherChests()
	local systems = Workspace:FindFirstChild("Systems")
	local out = {}
	if not systems then return out end
	local root = getRoot()
	if not root then return out end
	for _, inst in ipairs(systems:GetDescendants()) do
		if isInteractable(inst, "OpenChest") then
			local pos = positionOf(inst)
			if pos then
				out[#out + 1] = { model = inst, dist = (root.Position - pos).Magnitude }
			end
		end
	end
	table.sort(out, function(a, b) return a.dist < b.dist end)
	return out
end

local function gatherHostiles(maxDistance)
	local folder = monstersFolder()
	local out = {}
	if not folder then return out end
	local root = getRoot()
	if not root then return out end
	for _, model in ipairs(folder:GetChildren()) do
		if isHostileMob(model) then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local part = model:FindFirstChild("HumanoidRootPart")
			if hum and part and hum.Health > 0 then
				local d = (root.Position - part.Position).Magnitude
				if not maxDistance or maxDistance <= 0 or d <= maxDistance then
					out[#out + 1] = { model = model, humanoid = hum, root = part, dist = d, hp = hum.Health }
				end
			end
		end
	end
	table.sort(out, function(a, b)
		if math.abs(a.dist - b.dist) > 60 then
			return a.dist < b.dist
		end
		return a.hp < b.hp
	end)
	return out
end

local function isWeapon(tool)
	local flag = tool:FindFirstChild("IsSword")
	return flag ~= nil and flag.Value == true
end

local function bestWeapon()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then return nil end
	local best, bestScore
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and isWeapon(tool) then
			local price = tool:FindFirstChild("SellPrice")
			local score = (price and price.Value) or 0
			if not bestScore or score > bestScore then
				best, bestScore = tool, score
			end
		end
	end
	return best
end

local warnedNoWeapon = false

local function ensureWeapon()
	local character = getCharacter()
	if not character then return nil end
	local held = character:FindFirstChildOfClass("Tool")
	if held and isWeapon(held) then return held end
	if not enabled.farmAutoEquip then return held end
	local pick = bestWeapon()
	if not pick then
		if not warnedNoWeapon then
			warnedNoWeapon = true
			pcall(function() Library:Notify("No weapon in your bag to equip", 5) end)
		end
		return held
	end
	warnedNoWeapon = false
	local humanoid = getHumanoid()
	if humanoid then
		pcall(function() humanoid:EquipTool(pick) end)
	end
	return getCharacter() and getCharacter():FindFirstChildOfClass("Tool") or nil
end

local orbitAngle = 0

local function farmDesiredPosition(targetPos)
	local mode = Options.FarmPosition and Options.FarmPosition.Value or "Orbit"
	local height = tonumber(Options.FarmHeight and Options.FarmHeight.Value) or 8
	local depth = tonumber(Options.FarmDepth and Options.FarmDepth.Value) or 8
	local radius = tonumber(Options.FarmOrbitRadius and Options.FarmOrbitRadius.Value) or 8
	if mode == "Hover" then
		return targetPos + Vector3.new(0, height, 0)
	elseif mode == "Under" then
		return targetPos - Vector3.new(0, depth, 0)
	elseif mode == "Orbit" then
		local speed = tonumber(Options.FarmOrbitSpeed and Options.FarmOrbitSpeed.Value) or 120
		orbitAngle = (orbitAngle + math.rad(speed) * 0.05) % (math.pi * 2)
		return targetPos + Vector3.new(
			math.cos(orbitAngle) * radius,
			height,
			math.sin(orbitAngle) * radius
		)
	end
	local root = getRoot()
	if not root then return targetPos end
	local away = (root.Position - targetPos)
	local flat = Vector3.new(away.X, 0, away.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(1, 0, 0)
	end
	local reach = tonumber(Options.FarmReach and Options.FarmReach.Value) or 6
	return targetPos + flat.Unit * reach
end

local farmTargetPart = nil

local function doAutoFarm()
	if not enabled.farm or not canAct() then
		farmTargetPart = nil
		return
	end
	if farmTargetPart and not farmTargetPart.Parent then
		scriptState.kills = (scriptState.kills or 0) + 1
		farmTargetPart = nil
	end
	local list = gatherHostiles(tonumber(Options.FarmRadius and Options.FarmRadius.Value) or 0)
	local target = list[1]
	if not target then
		setFarmStatus("no mobs in range")
		return
	end
	local tool = ensureWeapon()
	if not tool or not isWeapon(tool) then return end
	local root = getRoot()
	if not root then return end
	farmTargetPart = target.root
	setFarmStatus("farming " .. target.model.Name)
	local targetPos = target.root.Position
	local desired = farmDesiredPosition(targetPos)
	local gap = (root.Position - desired).Magnitude
	if gap > 0.5 then
		markTravelling(0.4)
		local rot = root.CFrame - root.CFrame.Position
		local nextPos
		if enabled.farmSmooth then
			local speed = tonumber(Options.FarmMoveSpeed and Options.FarmMoveSpeed.Value) or 120
			local step = math.min(gap, speed * 0.05)
			nextPos = root.Position + (desired - root.Position).Unit * step
		else
			nextPos = desired
		end
		root.CFrame = CFrame.new(nextPos) * rot
	end
	freezeFall(root)
	pcall(function() tool:Activate() end)
end

local autoRotateSaved = nil

local function setAutoRotate(value)
	local humanoid = getHumanoid()
	if not humanoid then return end
	if autoRotateSaved == nil then
		autoRotateSaved = humanoid.AutoRotate
	end
	humanoid.AutoRotate = value
end

local function restoreAutoRotate()
	local humanoid = getHumanoid()
	if humanoid and autoRotateSaved ~= nil then
		humanoid.AutoRotate = autoRotateSaved
	end
	autoRotateSaved = nil
end

trackConnection(RunService.RenderStepped:Connect(function()
	if not session.running then return end
	local targetPart = farmTargetPart
	if not enabled.farm or not targetPart or not targetPart.Parent or not canAct() then
		if autoRotateSaved ~= nil then
			restoreAutoRotate()
		end
		return
	end
	local root = getRoot()
	if not root then return end
	local targetPos = targetPart.Position
	if enabled.farmFaceTarget then
		setAutoRotate(false)
		local lookPos = targetPos
		if not enabled.farmTiltToTarget then
			lookPos = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
		end
		if (lookPos - root.Position).Magnitude > 0.05 then
			root.CFrame = CFrame.lookAt(root.Position, lookPos)
		end
	elseif autoRotateSaved ~= nil then
		restoreAutoRotate()
	end
	if enabled.farmCameraLock then
		local camera = Workspace.CurrentCamera
		if camera then
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
		end
	end
end))

local function doAutoTrinket()
	if not enabled.trinket or not canAct() then return end
	local radius = tonumber(Options.TrinketRadius and Options.TrinketRadius.Value) or 0
	local list = gatherDrops(true, radius)
	local target = list[1]
	if target then
		setFarmStatus("trinket " .. target.model.Name)
		collect(target.model, "PickupDrop")
	end
end

local function doAutoPickup()
	if not enabled.pickup or not canAct() then return end
	local radius = tonumber(Options.PickupRadius and Options.PickupRadius.Value) or 0
	local list = gatherDrops(false, radius)
	local target = list[1]
	if target then
		collect(target.model, "PickupDrop")
	end
end

local function doAutoChest()
	if not enabled.chest or not canAct() then return end
	local list = gatherChests()
	local target = list[1]
	if not target then return end
	if collect(target.model, "OpenChest") then
		if enabled.chestSweep then
			task.wait(0.35)
			for _, entry in ipairs(gatherDrops(false, 30)) do
				if not canAct() then return end
				collect(entry.model, "PickupDrop")
			end
		end
	end
end

local function itemCategory(tool)
	if tool:FindFirstChild("CannotBeDropped") then
		return "protected"
	end
	local isSword = tool:FindFirstChild("IsSword")
	if isSword and isSword.Value == true then
		return "weapon"
	end
	if tool:FindFirstChild("IsPotion") then
		return "potion"
	end
	if tool:FindFirstChild("IsOutfit") then
		return "outfit"
	end
	if tool:FindFirstChild("IsAccessory") then
		return "accessory"
	end
	return "trinket"
end

local function categoryAllowed(category)
	if category == "protected" then return false end
	if category == "weapon" then return enabled.sellWeapons == true end
	if category == "outfit" then return enabled.sellOutfits == true end
	if category == "accessory" then return enabled.sellAccessories == true end
	if category == "potion" then return enabled.sellPotions == true end
	return enabled.sellTrinkets ~= false
end

local function selectedRarities()
	local picked = Options.SellRarities and Options.SellRarities.Value or {}
	local any = false
	for _, v in pairs(picked) do
		if v then
			any = true
			break
		end
	end
	if not any then return nil end
	return picked
end

local function sellableItems()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then return {} end
	local wanted = selectedRarities()
	if not wanted then return {} end
	local character = getCharacter()
	local equipped = character and character:FindFirstChildOfClass("Tool")
	local out = {}
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool ~= equipped and not PROTECTED_ITEMS[tool.Name] then
			local price = tool:FindFirstChild("SellPrice")
			if price and price.Value and price.Value > 0 then
				if wanted[rarityOfItem(tool)] and categoryAllowed(itemCategory(tool)) then
					local enh = tool:GetAttribute("Enhancements")
					local isEnhanced = type(enh) == "string" and enh ~= ""
					if (not isEnhanced) or enabled.sellEnhanced then
						out[#out + 1] = tool
					end
				end
			end
		end
	end
	return out
end

local function findMerchant()
	local npcs = Workspace:FindFirstChild("NPCs")
	return npcs and npcs:FindFirstChild(MERCHANT_NAME) or nil
end

local function doSell()
	local items = sellableItems()
	if #items == 0 then
		return false, "Nothing matches your rarity filter"
	end
	local merchant = findMerchant()
	if not merchant then
		return false, "Cannot find the merchant here"
	end
	if not SellItemsEvent then
		return false, "Sell remote missing"
	end
	local root = getRoot()
	if not root then
		return false, "No character"
	end
	local returnTo = root.Position
	setFarmStatus("selling " .. #items .. " items")
	if not approach(merchant, INTERACT_RANGE) then
		return false, "Could not get to the merchant"
	end
	task.wait(0.25)
	local ok = pcall(function()
		SellItemsEvent:FireServer(items)
	end)
	task.wait(0.6)
	if ok then
		scriptState.sold = (scriptState.sold or 0) + #items
	end
	if enabled.sellReturn then
		moveTo(returnTo, 8)
	end
	if not ok then
		return false, "Sell failed"
	end
	return true, ("Sold %d items"):format(#items)
end

local function doAutoSell()
	if not enabled.sell or not canAct() then return end
	if not ready("autoSell", 3) then return end
	local threshold = tonumber(Options.SellThreshold and Options.SellThreshold.Value) or 10
	if #sellableItems() < threshold then return end
	local ok, msg = doSell()
	pcall(function() Library:Notify("Auto Sell: " .. tostring(msg), 3) end)
end

local lightingBackup = nil

local function applyFullbright(on)
	if on then
		if not lightingBackup then
			lightingBackup = {
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
				Brightness = Lighting.Brightness,
				FogEnd = Lighting.FogEnd,
				FogStart = Lighting.FogStart,
				ClockTime = Lighting.ClockTime,
				GlobalShadows = Lighting.GlobalShadows,
			}
		end
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1e6
		Lighting.FogStart = 1e6
	else
		if lightingBackup then
			for k, v in pairs(lightingBackup) do
				pcall(function() Lighting[k] = v end)
			end
			lightingBackup = nil
		end
	end
end

local function doFullbright()
	if not enabled.fullbright then return end
	applyFullbright(true)
end

local EspPool = {}

local function newEspEntry()
	local box = Drawing and Drawing.new("Square")
	if box then
		box.Thickness = 1
		box.Filled = false
		box.Visible = false
	end
	local name = Drawing and Drawing.new("Text")
	if name then
		name.Size = 13
		name.Center = true
		name.Outline = true
		name.Visible = false
	end
	local dist = Drawing and Drawing.new("Text")
	if dist then
		dist.Size = 12
		dist.Center = true
		dist.Outline = true
		dist.Visible = false
	end
	local tracer = Drawing and Drawing.new("Line")
	if tracer then
		tracer.Thickness = 1
		tracer.Visible = false
	end
	return { box = box, name = name, dist = dist, tracer = tracer }
end

local function getEspEntry(i)
	if not EspPool[i] then
		EspPool[i] = newEspEntry()
	end
	return EspPool[i]
end

local function hideEspFrom(i)
	for j = i, #EspPool do
		local e = EspPool[j]
		if e.box then e.box.Visible = false end
		if e.name then e.name.Visible = false end
		if e.dist then e.dist.Visible = false end
		if e.tracer then e.tracer.Visible = false end
	end
end

local function destroyEsp()
	for _, e in ipairs(EspPool) do
		pcall(function()
			if e.box then e.box:Remove() end
			if e.name then e.name:Remove() end
			if e.dist then e.dist:Remove() end
			if e.tracer then e.tracer:Remove() end
		end)
	end
	table.clear(EspPool)
end

local function screenBox(model)
	local ok, cf, size = pcall(function()
		return model:GetBoundingBox()
	end)
	if not ok or not cf then
		local part = partOf(model)
		if not part then return nil end
		cf, size = part.CFrame, part.Size
	end
	local half = size * 0.5
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local onScreen = false
	local camera = Workspace.CurrentCamera
	for x = -1, 1, 2 do
		for y = -1, 1, 2 do
			for z = -1, 1, 2 do
				local corner = cf * CFrame.new(half.X * x, half.Y * y, half.Z * z)
				local sp, vis = camera:WorldToViewportPoint(corner.Position)
				if vis then onScreen = true end
				if sp.Z > 0 then
					minX = math.min(minX, sp.X)
					minY = math.min(minY, sp.Y)
					maxX = math.max(maxX, sp.X)
					maxY = math.max(maxY, sp.Y)
				end
			end
		end
	end
	if not onScreen or minX == math.huge then return nil end
	return minX, minY, maxX, maxY
end

local function espCategoryTargets()
	local out = {}
	local root = getRoot()
	if not root then return out end
	local maxDist = tonumber(Options.EspDistance and Options.EspDistance.Value) or 1500
	if enabled.espPlayers then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local skip = enabled.espIgnoreTeam and isFriendlyPlayer(plr)
				local part = plr.Character:FindFirstChild("HumanoidRootPart")
				if not skip and part then
					local d = (root.Position - part.Position).Magnitude
					if d <= maxDist then
						out[#out + 1] = { model = plr.Character, label = plr.Name, dist = d, color = ESP_COLORS.player }
					end
				end
			end
		end
	end
	if enabled.espMobs then
		local folder = monstersFolder()
		if folder then
			for _, m in ipairs(folder:GetChildren()) do
				if isHostileMob(m) then
					local part = m:FindFirstChild("HumanoidRootPart")
					local hum = m:FindFirstChildOfClass("Humanoid")
					if part and hum and hum.Health > 0 then
						local d = (root.Position - part.Position).Magnitude
						if d <= maxDist then
							out[#out + 1] = {
								model = m,
								label = ("%s [%d]"):format(m.Name, math.floor(hum.Health)),
								dist = d,
								color = ESP_COLORS.mob,
							}
						end
					end
				end
			end
		end
	end
	if enabled.espDrops then
		local folder = dropsFolder()
		if folder then
			for _, m in ipairs(folder:GetChildren()) do
				if isInteractable(m, "PickupDrop") and ((not enabled.espTrinketsOnly) or TRINKET_NAMES[m.Name]) then
					local pos = positionOf(m)
					if pos then
						local d = (root.Position - pos).Magnitude
						if d <= maxDist then
							out[#out + 1] = {
								model = m,
								label = ("%s (%s)"):format(m.Name, tostring(rarityOfDrop(m))),
								dist = d,
								color = ESP_COLORS.drop,
							}
						end
					end
				end
			end
		end
	end
	if enabled.espChests then
		for _, entry in ipairs(gatherChests()) do
			if entry.dist <= maxDist then
				out[#out + 1] = { model = entry.model, label = "Chest", dist = entry.dist, color = ESP_COLORS.chest }
			end
		end
	end
	table.sort(out, function(a, b) return a.dist < b.dist end)
	local cap = tonumber(Options.EspMaxObjects and Options.EspMaxObjects.Value) or 120
	while #out > cap do
		table.remove(out)
	end
	return out
end

trackConnection(RunService.RenderStepped:Connect(function()
	if not session.running then
		hideEspFrom(1)
		return
	end
	if not enabled.esp or not canAct() then
		hideEspFrom(1)
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then return end
	local targets = espCategoryTargets()
	local i = 0
	for _, t in ipairs(targets) do
		local minX, minY, maxX, maxY = screenBox(t.model)
		if minX then
			i += 1
			local e = getEspEntry(i)
			local w, h = maxX - minX, maxY - minY
			if enabled.espBox and e.box then
				e.box.Position = Vector2.new(minX, minY)
				e.box.Size = Vector2.new(w, h)
				e.box.Color = t.color
				e.box.Visible = true
			elseif e.box then
				e.box.Visible = false
			end
			if enabled.espName and e.name then
				e.name.Text = t.label
				e.name.Position = Vector2.new(minX + w * 0.5, minY - 15)
				e.name.Color = t.color
				e.name.Visible = true
			elseif e.name then
				e.name.Visible = false
			end
			if enabled.espDistText and e.dist then
				e.dist.Text = ("%d studs"):format(math.floor(t.dist))
				e.dist.Position = Vector2.new(minX + w * 0.5, maxY + 2)
				e.dist.Color = t.color
				e.dist.Visible = true
			elseif e.dist then
				e.dist.Visible = false
			end
			if enabled.espTracer and e.tracer then
				e.tracer.From = Vector2.new(camera.ViewportSize.X * 0.5, camera.ViewportSize.Y)
				e.tracer.To = Vector2.new(minX + w * 0.5, maxY)
				e.tracer.Color = t.color
				e.tracer.Visible = true
			elseif e.tracer then
				e.tracer.Visible = false
			end
		end
	end
	hideEspFrom(i + 1)
end))

local webhookQueue = {}
local webhookSeen = {}

local function httpPost(url, body)
	if type(httpRequest) ~= "function" then
		return false, "This executor has no http request function"
	end
	local ok, res = pcall(httpRequest, {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = body,
	})
	if not ok then
		return false, tostring(res)
	end
	local code = res and (res.StatusCode or res.Status or res.status_code) or 0
	if code >= 200 and code < 300 then
		return true, tostring(code)
	end
	return false, tostring(code)
end

local function webhookUrl()
	local u = Options.WebhookUrl and Options.WebhookUrl.Value or ""
	if type(u) ~= "string" or not u:match("^https?://") then
		return nil
	end
	return u
end

local function sendWebhook(payload)
	local url = webhookUrl()
	if not url then
		return false, "No webhook url set"
	end
	local ok, body = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return false, "Could not encode payload"
	end
	return httpPost(url, body)
end

local function flushWebhookQueue()
	if #webhookQueue == 0 then return end
	local batch = webhookQueue
	webhookQueue = {}
	table.sort(batch, function(a, b)
		local ra, rb = RARITY_RANK[a.rarity] or 0, RARITY_RANK[b.rarity] or 0
		if ra ~= rb then return ra > rb end
		return a.dist < b.dist
	end)
	local lines, best, bestRank = {}, "Common", 0
	for i, e in ipairs(batch) do
		if i <= 20 then
			lines[#lines + 1] = ("`%s`  %s  %d studs"):format(e.rarity, e.name, math.floor(e.dist))
		end
		local rank = RARITY_RANK[e.rarity] or 0
		if rank > bestRank then
			bestRank, best = rank, e.rarity
		end
	end
	if #batch > 20 then
		lines[#lines + 1] = ("and %d more"):format(#batch - 20)
	end
	sendWebhook({
		username = "AntiGodHub",
		embeds = { {
			title = (#batch == 1) and "Drop spotted" or ("%d drops spotted"):format(#batch),
			description = table.concat(lines, "\n"),
			color = RARITY_COLORS[best] or RARITY_COLORS.Common,
			footer = { text = "AntiGodHub | " .. CONFIG.GameName },
		} },
	})
end

do
	local function watchDrops()
		local folder = dropsFolder()
		if not folder then return end
		trackConnection(folder.ChildAdded:Connect(function(model)
			if not enabled.dropWebhook then return end
			if webhookSeen[model] then return end
			webhookSeen[model] = true
			task.delay(0.35, function()
				if not model.Parent then return end
				local rarity = model:GetAttribute("Rarity") or "Common"
				local picked = Options.WebhookRarities and Options.WebhookRarities.Value or {}
				if picked[rarity] ~= true then return end
				local root = getRoot()
				local pos = positionOf(model)
				local dist = (root and pos) and (root.Position - pos).Magnitude or 0
				local limit = tonumber(Options.WebhookRadius and Options.WebhookRadius.Value) or 0
				if limit > 0 and dist > limit then return end
				webhookQueue[#webhookQueue + 1] = { name = model.Name, rarity = rarity, dist = dist }
			end)
		end))
	end
	task.spawn(watchDrops)
end

local function doWebhookFlush()
	if not enabled.dropWebhook then
		webhookQueue = {}
		return
	end
	if not ready("webhook", tonumber(Options.WebhookInterval and Options.WebhookInterval.Value) or 4) then return end
	pcall(flushWebhookQueue)
end local function rejoinServer()
	pcall(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, LocalPlayer)
end

local function reconnectServer()
	pcall(TeleportService.Teleport, TeleportService, game.PlaceId, LocalPlayer)
end

local function serverHop()
	if not httpRequest then return reconnectServer() end
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
	if disable == renderingDisabled then return end
	renderingDisabled = disable
	pcall(function() RunService:Set3dRenderingEnabled(not disable) end)
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
	Main = Window:AddTab({ Name = "Main", Icon = "swords" }),
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
	if copyText then pcall(copyText, tostring(LocalPlayer.UserId)) end
	pcall(function() Library:Notify("Copied User ID") end)
end })
UserBox:AddButton({ Text = "Copy Username", Func = function()
	if copyText then pcall(copyText, tostring(LocalPlayer.Name)) end
	pcall(function() Library:Notify("Copied Username") end)
end })

local GameBox = box(Tabs.Info, "Game Info", "gamepad", "Right")
GameBox:AddLabel("GameNameLabel", { Text = paint("Game -", CONFIG.GameName, COLORS.accent), DoesWrap = true })
GameBox:AddLabel("ServerPlayersLabel", { Text = paint("Players -", "0/0", COLORS.user), DoesWrap = true })
GameBox:AddLabel("ServerIdLabel", { Text = paint("Server -", string.sub(game.JobId ~= "" and game.JobId or "N/A", 1, 18), COLORS.orange), DoesWrap = true })
GameBox:AddButton({ Text = "Copy Join Script", Func = function()
	if copyText then
		pcall(copyText, string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s")', game.PlaceId, game.JobId))
	end
	pcall(function() Library:Notify("Copied join script") end)
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
		if not universeId then return end
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
	if copyText then pcall(copyText, CONFIG.Discord) end
	pcall(function() Library:Notify("Copied Discord invite") end)
end })
SocialsBox:AddButton({ Text = "Copy Website", Func = function()
	if copyText then pcall(copyText, CONFIG.Website) end
	pcall(function() Library:Notify("Copied website link") end)
end })

local FarmTab = Tabs.Main:AddSubTab({ Name = "Farm", Icon = "swords" })
local ItemsTab = Tabs.Main:AddSubTab({ Name = "Items", Icon = "package" })
local VisualsTab = Tabs.Main:AddSubTab({ Name = "Visuals", Icon = "eye" })
local MiscTab = Tabs.Main:AddSubTab({ Name = "Misc", Icon = "settings-2" })
local PlayerTab = Tabs.Main:AddSubTab({ Name = "Player", Icon = "user" })

local FarmBox = box(FarmTab, "Auto Farm", "swords", "Left")
FarmBox:AddToggle("AutoFarm", { Text = "Auto Farm NPCs", Default = false, Callback = function(value)
	enabled.farm = value
end })
FarmBox:AddToggle("FarmAutoEquip", { Text = "Auto Equip Weapon", Default = true, Callback = function(value)
	enabled.farmAutoEquip = value
end })
FarmBox:AddToggle("FarmFaceTarget", { Text = "Look At Target", Default = true, Callback = function(value)
	enabled.farmFaceTarget = value
end })
FarmBox:AddToggle("FarmTiltToTarget", { Text = "Tilt Body Vertically", Default = false, Callback = function(value)
	enabled.farmTiltToTarget = value
end })
FarmBox:AddToggle("FarmCameraLock", { Text = "Camera Follows Target", Default = false, Callback = function(value)
	enabled.farmCameraLock = value
end })
FarmBox:AddSlider("FarmRadius", {
	Text = "Search Radius",
	Default = 2000,
	Min = 100,
	Max = 5000,
	Rounding = 0,
})

local PosBox = box(FarmTab, "Farm Positioning", "move", "Right")
PosBox:AddDropdown("FarmPosition", {
	Text = "Position Mode",
	Values = { "Orbit", "Hover", "Under", "Direct" },
	Default = "Orbit",
})
PosBox:AddSlider("FarmOrbitRadius", { Text = "Orbit Radius", Default = 5, Min = 2, Max = 40, Rounding = 0 })
PosBox:AddSlider("FarmOrbitSpeed", { Text = "Orbit Speed", Default = 120, Min = 10, Max = 720, Rounding = 0 })
PosBox:AddSlider("FarmHeight", { Text = "Hover Height", Default = 4, Min = 0, Max = 60, Rounding = 0 })
PosBox:AddSlider("FarmDepth", { Text = "Under Depth", Default = 8, Min = 0, Max = 60, Rounding = 0 })
PosBox:AddSlider("FarmReach", { Text = "Direct Reach", Default = 6, Min = 2, Max = 30, Rounding = 0 })
PosBox:AddDivider()
PosBox:AddToggle("FarmSmooth", { Text = "Smooth Repositioning", Default = true, Callback = function(value)
	enabled.farmSmooth = value
end })
PosBox:AddSlider("FarmMoveSpeed", { Text = "Reposition Speed", Default = 120, Min = 20, Max = 800, Rounding = 0 })

local ChestBox = box(FarmTab, "Chests", "box", "Left")
ChestBox:AddToggle("AutoChest", { Text = "Auto Open Chests", Default = false, Callback = function(value)
	enabled.chest = value
end })
ChestBox:AddToggle("ChestLootSweep", { Text = "Grab Chest Loot", Default = true, Callback = function(value)
	enabled.chestSweep = value
end })

local StatusBox = box(FarmTab, "Game Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("KillsLabel", { Text = paint("Kills -", "0", COLORS.orange), DoesWrap = true })
StatusBox:AddLabel("PickedLabel", { Text = paint("Picked -", "0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("SoldLabel", { Text = paint("Sold -", "0", COLORS.gold), DoesWrap = true })

local PickupBox = box(ItemsTab, "Pickup", "hand", "Left")
PickupBox:AddToggle("AutoTrinket", { Text = "Auto Trinket Teleport", Default = false, Callback = function(value)
	enabled.trinket = value
end })
PickupBox:AddSlider("TrinketRadius", { Text = "Trinket Radius", Default = 3000, Min = 100, Max = 6000, Rounding = 0 })
PickupBox:AddDivider()
PickupBox:AddToggle("AutoPickup", { Text = "Auto Pickup All", Default = false, Callback = function(value)
	enabled.pickup = value
end })
PickupBox:AddSlider("PickupRadius", { Text = "Pickup Radius", Default = 3000, Min = 100, Max = 6000, Rounding = 0 })

local SellBox = box(ItemsTab, "Auto Sell", "coins", "Left")
SellBox:AddToggle("AutoSell", { Text = "Auto Sell", Default = false, Callback = function(value)
	enabled.sell = value
end })
SellBox:AddDropdown("SellRarities", {
	Text = "Rarities To Sell",
	Values = RARITIES,
	Default = { "Common" },
	Multi = true,
})
SellBox:AddDivider()
SellBox:AddToggle("SellTrinkets", { Text = "Trinkets And Junk", Default = true, Callback = function(value)
	enabled.sellTrinkets = value
end })
SellBox:AddToggle("SellWeapons", { Text = "Weapons", Default = false, Callback = function(value)
	enabled.sellWeapons = value
end })
SellBox:AddToggle("SellOutfits", { Text = "Outfits And Armor", Default = false, Callback = function(value)
	enabled.sellOutfits = value
end })
SellBox:AddToggle("SellAccessories", { Text = "Accessories", Default = false, Callback = function(value)
	enabled.sellAccessories = value
end })
SellBox:AddToggle("SellPotions", { Text = "Potions", Default = false, Callback = function(value)
	enabled.sellPotions = value
end })
SellBox:AddToggle("SellEnhanced", { Text = "Also Sell Enhanced", Default = false, Callback = function(value)
	enabled.sellEnhanced = value
end })
SellBox:AddDivider()
SellBox:AddSlider("SellThreshold", { Text = "Sell When N Items Match", Default = 10, Min = 1, Max = 60, Rounding = 0 })
SellBox:AddToggle("SellReturn", { Text = "Return After Selling", Default = true, Callback = function(value)
	enabled.sellReturn = value
end })
SellBox:AddButton({ Text = "Sell Now", Func = function()
	task.spawn(function()
		local ok, msg = doSell()
		pcall(function() Library:Notify("Sell: " .. tostring(msg), 4) end)
	end)
end })

local HookBox = box(ItemsTab, "Drop Webhook", "bell", "Right")
HookBox:AddToggle("DropWebhook", { Text = "Drop Webhook", Default = false, Callback = function(value)
	enabled.dropWebhook = value
end })
HookBox:AddInput("WebhookUrl", {
	Text = "Webhook URL",
	Default = "",
	Finished = true,
})
HookBox:AddDropdown("WebhookRarities", {
	Text = "Rarities To Post",
	Values = RARITIES,
	Default = { "Rare", "Elite", "Legendary" },
	Multi = true,
})
HookBox:AddSlider("WebhookRadius", { Text = "Only Within", Default = 0, Min = 0, Max = 5000, Rounding = 0 })
HookBox:AddSlider("WebhookInterval", { Text = "Batch Every", Default = 4, Min = 1, Max = 30, Rounding = 0 })
HookBox:AddButton({ Text = "Send Test Webhook", Func = function()
	task.spawn(function()
		local ok, info = sendWebhook({
			username = "AntiGodHub",
			embeds = { {
				title = "Test",
				description = "Webhook is working",
				color = RARITY_COLORS.Legendary,
				footer = { text = "AntiGodHub | " .. CONFIG.GameName },
			} },
		})
		pcall(function() Library:Notify(ok and "Webhook sent" or ("Webhook failed: " .. tostring(info)), 4) end)
	end)
end })

local EspBox = box(VisualsTab, "ESP", "eye", "Left")
EspBox:AddToggle("EspMaster", { Text = "Enable ESP", Default = false, Callback = function(value)
	enabled.esp = value
end })
EspBox:AddDivider()
EspBox:AddToggle("EspBox", { Text = "Boxes", Default = true, Callback = function(value)
	enabled.espBox = value
end })
EspBox:AddToggle("EspName", { Text = "Names", Default = true, Callback = function(value)
	enabled.espName = value
end })
EspBox:AddToggle("EspDistanceText", { Text = "Distance", Default = true, Callback = function(value)
	enabled.espDistText = value
end })
EspBox:AddToggle("EspTracer", { Text = "Tracers", Default = false, Callback = function(value)
	enabled.espTracer = value
end })
EspBox:AddDivider()
EspBox:AddSlider("EspDistance", { Text = "Max Distance", Default = 1500, Min = 100, Max = 6000, Rounding = 0 })
EspBox:AddSlider("EspMaxObjects", { Text = "Max Drawn", Default = 120, Min = 10, Max = 400, Rounding = 0 })

local EspCatBox = box(VisualsTab, "ESP Targets", "list", "Right")
EspCatBox:AddToggle("EspPlayers", { Text = "Players", Default = false, Callback = function(value)
	enabled.espPlayers = value
end })
EspCatBox:AddToggle("EspIgnoreTeam", { Text = "Hide Party Members", Default = true, Callback = function(value)
	enabled.espIgnoreTeam = value
end })
EspCatBox:AddToggle("EspMobs", { Text = "Mobs", Default = false, Callback = function(value)
	enabled.espMobs = value
end })
EspCatBox:AddToggle("EspDrops", { Text = "Items And Accessories", Default = false, Callback = function(value)
	enabled.espDrops = value
end })
EspCatBox:AddToggle("EspTrinketsOnly", { Text = "Only Trinkets", Default = false, Callback = function(value)
	enabled.espTrinketsOnly = value
end })
EspCatBox:AddToggle("EspChests", { Text = "Chests", Default = false, Callback = function(value)
	enabled.espChests = value
end })

local LightBox = box(VisualsTab, "World", "sun", "Left")
LightBox:AddToggle("Fullbright", { Text = "Fullbright", Default = true, Callback = function(value)
	enabled.fullbright = value
	applyFullbright(value)
end })

local MoveBox = box(MiscTab, "Movement", "move", "Left")
MoveBox:AddDropdown("MoveMode", {
	Text = "Travel Mode",
	Values = { "Teleport", "Tween" },
	Default = "Teleport",
})
MoveBox:AddSlider("TweenSpeed", { Text = "Tween Speed", Default = 220, Min = 40, Max = 800, Rounding = 0 })
MoveBox:AddSlider("ActionDelay", { Text = "Action Delay", Default = 0.15, Min = 0.05, Max = 1, Rounding = 2 })
MoveBox:AddToggle("AutoNoclip", { Text = "Auto Noclip", Default = true, Callback = function(value)
	enabled.autoNoclip = value
end })

local flyVelocity
local flyUp = false
local flyDown = false
local walkSpeedOriginals = {}
local instantPromptConnection = nil

local function restoreWalkSpeed()
	for hum, speed in pairs(walkSpeedOriginals) do
		if hum.Parent then
			hum.WalkSpeed = speed
		end
		walkSpeedOriginals[hum] = nil
	end
end

local function applyInstantPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	pcall(function()
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 50
		prompt.RequiresLineOfSight = false
	end)
end

local MovementBox = box(PlayerTab, "Movement", "footprints", "Left")
MovementBox:AddToggle("WalkSpeedEnabled", { Text = "Walk Speed", Default = false, Callback = function(value)
	enabled.walkSpeed = value
	if not value then restoreWalkSpeed() end
end })
MovementBox:AddSlider("WalkSpeed", { Text = "Walk speed", Default = 32, Min = 16, Max = 250, Rounding = 0 })
MovementBox:AddToggle("Fly", { Text = "Fly", Default = false, Callback = function(value)
	enabled.fly = value
	if not value and flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
end })
MovementBox:AddSlider("FlySpeed", { Text = "Fly speed", Default = 60, Min = 10, Max = 400, Rounding = 0 })
MovementBox:AddToggle("NoClip", { Text = "NoClip", Default = false, Callback = function(value)
	enabled.noclip = value
end })
MovementBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false, Callback = function(value)
	enabled.infJump = value
end })
MovementBox:AddToggle("InstantProximityPrompt", { Text = "Instant ProximityPrompt", Default = false, Callback = function(value)
	if value then
		for _, prompt in ipairs(Workspace:GetDescendants()) do
			pcall(applyInstantPrompt, prompt)
		end
		if instantPromptConnection then
			instantPromptConnection:Disconnect()
		end
		instantPromptConnection = Workspace.DescendantAdded:Connect(function(descendant)
			pcall(applyInstantPrompt, descendant)
		end)
	elseif instantPromptConnection then
		instantPromptConnection:Disconnect()
		instantPromptConnection = nil
	end
end })

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not enabled.fly then return end
	if input.KeyCode == Enum.KeyCode.Space then
		flyUp = true
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		flyDown = true
	end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		flyUp = false
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		flyDown = false
	end
end))

trackConnection(UserInputService.JumpRequest:Connect(function()
	if not enabled.infJump then return end
	local humanoid = getHumanoid()
	if humanoid then
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end))

trackConnection(RunService.RenderStepped:Connect(function(dt)
	if not session.running then return end
	local humanoid = getHumanoid()
	local root = getRoot()
	if enabled.walkSpeed and humanoid then
		if walkSpeedOriginals[humanoid] == nil then walkSpeedOriginals[humanoid] = humanoid.WalkSpeed end
		humanoid.WalkSpeed = tonumber(Options.WalkSpeed.Value) or 32
	end
	if enabled.fly and root and humanoid then
		local camera = Workspace.CurrentCamera
		if camera then
			humanoid.PlatformStand = true
			local direction = Vector3.zero
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.new(0, 1, 0) end
			root.AssemblyLinearVelocity = Vector3.zero
			if direction.Magnitude > 0 then
				root.CFrame += direction.Unit * (tonumber(Options.FlySpeed.Value) or 60) * dt
			end
		end
	elseif not enabled.fly and humanoid and humanoid.PlatformStand then
		humanoid.PlatformStand = false
	end
end))

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
		pcall(function() Library:SetNotifySide(value) end)
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
	setLabel("KillsLabel", paint("Kills -", tostring(scriptState.kills or 0), COLORS.orange))
	setLabel("PickedLabel", paint("Picked -", tostring(scriptState.picked or 0), COLORS.user))
	setLabel("SoldLabel", paint("Sold -", tostring(scriptState.sold or 0), COLORS.gold))
end

local function loop(func, interval)
	task.spawn(function()
		while session.running do
			local ok, err = pcall(func)
			if not ok then logError(err) end
			task.wait(interval)
		end
	end)
end

enabled.farmSmooth = true
enabled.farmFaceTarget = true
enabled.farmAutoEquip = true
enabled.sellTrinkets = true
enabled.sellReturn = true
enabled.chestSweep = true
enabled.espIgnoreTeam = true
enabled.fullbright = true

loop(doAutoFarm, 0.05)
loop(doAutoTrinket, 0.1)
loop(doAutoPickup, 0.1)
loop(doAutoChest, 0.25)
loop(doAutoSell, 0.5)
loop(doFullbright, 0.5)
loop(doWebhookFlush, 0.5)
loop(function()
	if enabled.dropWebhook then return end
	table.clear(webhookSeen)
end, 30)

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
		task.wait(1)
	end
end)

task.spawn(function()
	task.wait(4.5)
	print("[AntiGodHub] interact remote: " .. (InteractPromptEvent and InteractPromptEvent.Name or "NONE") .. " | sell remote: " .. (SellItemsEvent and SellItemsEvent.Name or "NONE"))
	print("[AntiGodHub] merchant: " .. (findMerchant() and "found" or "not spawned yet") .. " | drops folder: " .. (dropsFolder() and "ready" or "missing"))
end)

Library:OnUnload(function()
	session.running = false
	destroyEsp()
	applyFullbright(false)
	clearNoclip()
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	if instantPromptConnection then
		pcall(function() instantPromptConnection:Disconnect() end)
		instantPromptConnection = nil
	end
	restoreAutoRotate()
	restoreWalkSpeed()
	for _, connection in ipairs(scriptConnections) do
		pcall(connection.Disconnect, connection)
	end
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()