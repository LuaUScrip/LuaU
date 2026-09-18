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
local UserInputService = game:GetService("UserInputService")
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
	GameName = "Deagle Arena",
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

local enabled = {teamCheck = true, aimWallCheck = true, silentFov = true, fovCircle = true, wallbang = false, walkSpeed = false, jumpPower = false, infJump = false}
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

local lastWarn = 0

local function logError(err)
	if tick() - lastWarn > 5 then
		lastWarn = tick()
		warn("[AntiGodHub] " .. tostring(err))
	end
end

local DeagleShared
do
	local module = find(ReplicatedStorage, "Modules", "Shared", "DeagleShared")
	if module then
		local ok, result = pcall(require, module)
		DeagleShared = ok and result or nil
	end
end

local DeagleController
do
	local ok, result = pcall(function()
		local loader = find(LocalPlayer, "PlayerScripts", "ModuleLoader")
		if not loader then
			return nil
		end
		return require(loader:WaitForChild("DeagleController", 10))
	end)
	DeagleController = ok and result or nil
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

local function isAliveAndValid(model)
	if not model or typeof(model) ~= "Instance" or not model:IsA("Model") or model == LocalPlayer.Character then
		return false
	end
	if not model.Parent then
		return false
	end
	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end
	local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
	if not rootPart then
		return false
	end
	if model:FindFirstChild("Dead") or model:GetAttribute("IsDead") == true then
		return false
	end
	return true
end

local function teamBlocked(model)
	if not enabled.teamCheck then
		return false
	end
	local player = Players:GetPlayerFromCharacter(model)
	if player and player.Team ~= nil and player.Team == LocalPlayer.Team then
		return true
	end
	return false
end

local npcTargets = {}

local function scanNpcs()
	local found = {}
	local queue = {Workspace}
	while #queue > 0 do
		local current = table.remove(queue, 1)
		for _, child in ipairs(current:GetChildren()) do
			if child:IsA("Model") and isAliveAndValid(child) then
				if not Players:GetPlayerFromCharacter(child) then
					found[child] = true
				end
			elseif child:IsA("Folder") or child.Name:lower():find("bot") or child.Name:lower():find("npc") then
				table.insert(queue, child)
			end
		end
	end
	npcTargets = found
end

local function collectTargets()
	local targets = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and isAliveAndValid(player.Character) then
			if not teamBlocked(player.Character) then
				table.insert(targets, player.Character)
			end
		end
	end
	for model in pairs(npcTargets) do
		if isAliveAndValid(model) and not teamBlocked(model) then
			table.insert(targets, model)
		end
	end
	return targets
end

local function resolveTargetPart(model)
	return model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
end

local function getPredictedPosition(part)
	local character = part.Parent
	local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
	if rootPart and rootPart:IsA("BasePart") then
		local okVelocity, velocity = pcall(function()
			return rootPart.AssemblyLinearVelocity
		end)
		local okPing, ping = pcall(LocalPlayer.GetNetworkPing, LocalPlayer)
		if okVelocity and typeof(velocity) == "Vector3" and okPing and type(ping) == "number" and ping > 0 then
			return part.Position + velocity * (ping * 1.85)
		end
	end
	return part.Position
end

local function isVisibleFrom(camera, part)
	local ok, result = pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
		params.IgnoreWater = true
		local origin = camera.CFrame.Position
		local direction = part.Position - origin
		return Workspace:Raycast(origin, direction, params)
	end)
	return ok and result == nil
end

local hasDrawing = false
do
	local ok = pcall(function()
		local test = Drawing.new("Square")
		test:Remove()
	end)
	hasDrawing = ok
end

local function newDrawing(kind, props)
	if not hasDrawing then
		return nil
	end
	local ok, obj = pcall(function()
		local drawing = Drawing.new(kind)
		for key, value in pairs(props) do
			drawing[key] = value
		end
		return drawing
	end)
	return ok and obj or nil
end

local ESP_MAX_DISTANCE = 300

local espCache = {}
local liveTargets = {}
local liveSet = {}
local fovCircle

local function clearEspEntry(entry)
	if not entry then
		return
	end
	for _, key in ipairs({"box", "nameText", "healthText", "distanceText", "tracer"}) do
		local drawing = entry[key]
		if drawing then
			pcall(function()
				drawing:Remove()
			end)
		end
	end
	if entry.highlight then
		pcall(function()
			entry.highlight:Destroy()
		end)
	end
	if entry.billboard then
		pcall(function()
			entry.billboard:Destroy()
		end)
	end
end

local function clearAllEsp()
	for model, entry in pairs(espCache) do
		clearEspEntry(entry)
		espCache[model] = nil
	end
end

local function hideEspEntry(entry)
	if not entry then
		return
	end
	for _, key in ipairs({"box", "nameText", "healthText", "distanceText", "tracer"}) do
		local drawing = entry[key]
		if drawing then
			pcall(function()
				drawing.Visible = false
			end)
		end
	end
	if entry.highlight then
		pcall(function()
			entry.highlight.Enabled = false
		end)
	end
	if entry.billboard then
		pcall(function()
			entry.billboard.Enabled = false
		end)
	end
end

local function createEntry(model)
	for _, child in ipairs(model:GetChildren()) do
		if (child:IsA("BillboardGui") and child.Name == "AntiGodEsp") or (child:IsA("Highlight") and child.Name == "AntiGodGlow") then
			pcall(function()
				child:Destroy()
			end)
		end
	end
	local entry = {}
	entry.box = newDrawing("Square", {Thickness = 1, Color = Color3.fromRGB(255, 255, 255), Filled = false, Visible = false})
	entry.nameText = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false})
	entry.healthText = newDrawing("Text", {Size = 13, Center = true, Outline = true, Color = Color3.fromRGB(124, 252, 124), Visible = false})
	entry.distanceText = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 165, 79), Visible = false})
	entry.tracer = newDrawing("Line", {Thickness = 1, Color = Color3.fromRGB(74, 163, 255), Visible = false})
	local okGlow, highlight = pcall(function()
		local glow = Instance.new("Highlight")
		glow.Name = "AntiGodGlow"
		glow.FillColor = Color3.fromRGB(255, 64, 64)
		glow.OutlineColor = Color3.fromRGB(255, 255, 255)
		glow.FillTransparency = 0.55
		glow.OutlineTransparency = 0
		glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		glow.Enabled = false
		glow.Parent = model
		return glow
	end)
	entry.highlight = okGlow and highlight or nil
	if not hasDrawing then
		local okGui, billboard = pcall(function()
			local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart", true)
			local gui = Instance.new("BillboardGui")
			gui.Name = "AntiGodEsp"
			gui.Size = UDim2.fromOffset(180, 44)
			gui.StudsOffset = Vector3.new(0, 2.5, 0)
			gui.AlwaysOnTop = true
			gui.Adornee = head
			gui.Enabled = false
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeTransparency = 0.2
			label.Text = ""
			label.Parent = gui
			gui.Parent = model
			return gui
		end)
		entry.billboard = okGui and billboard or nil
	end
	espCache[model] = entry
	return entry
end

local function resolveAimPart(model)
	local wanted = (Options.AimPart and Options.AimPart.Value) or "Head"
	return model:FindFirstChild(wanted) or model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
end

local lockedPart = nil

local function targetStillValid(camera, center, part, radius)
	if not part or not part.Parent or not isAliveAndValid(part.Parent) then
		return false
	end
	local ok, point = pcall(function()
		return camera:WorldToViewportPoint(part.Position)
	end)
	if not (ok and typeof(point) == "Vector3") or point.Z <= 0 then
		return false
	end
	if (Vector2.new(point.X, point.Y) - center).Magnitude > radius then
		return false
	end
	if enabled.aimWallCheck and not isVisibleFrom(camera, part) then
		return false
	end
	return true
end

local function acquireAimTarget(camera, center)
	local radius = (tonumber(Options.FovRadius and Options.FovRadius.Value) or 150)
	local best, bestDist
	for _, model in ipairs(liveTargets) do
		if isAliveAndValid(model) and not teamBlocked(model) then
			local part = resolveAimPart(model)
			if part then
				local ok, point = pcall(function()
					return camera:WorldToViewportPoint(part.Position)
				end)
				if ok and typeof(point) == "Vector3" and point.Z > 0 then
					local dist = (Vector2.new(point.X, point.Y) - center).Magnitude
					if dist <= radius and (not bestDist or dist < bestDist) then
						if not enabled.aimWallCheck or isVisibleFrom(camera, part) then
							best, bestDist = part, dist
						end
					end
				end
			end
		end
	end
	return best
end

local function getSilentAimTarget()
	if not enabled.silent then
		return nil
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local radius = enabled.silentFov and (tonumber(Options.FovRadius and Options.FovRadius.Value) or 150) or math.huge
	local best, bestDist
	for _, model in ipairs(liveTargets) do
		if isAliveAndValid(model) and not teamBlocked(model) then
			local part = resolveTargetPart(model)
			if part then
				local ok, point = pcall(function()
					return camera:WorldToViewportPoint(part.Position)
				end)
				if ok and typeof(point) == "Vector3" and point.Z > 0 then
					local dist = (Vector2.new(point.X, point.Y) - center).Magnitude
					if dist <= radius and (not bestDist or dist < bestDist) then
						if enabled.wallbang or isVisibleFrom(camera, part) then
							best, bestDist = part, dist
						end
					end
				end
			end
		end
	end
	return best
end

local CurrentShotTargets = {}

local originalRaycast
do
	if DeagleShared and type(DeagleShared.Raycast) == "function" then
		originalRaycast = DeagleShared.Raycast
		DeagleShared.Raycast = function(...)
			local part = next(CurrentShotTargets)
			if part and part.Parent and isAliveAndValid(part.Parent) then
				return {
					Instance = part,
					Position = getPredictedPosition(part),
					Normal = Vector3.new(0, 1, 0),
					Material = Enum.Material.Plastic,
				}
			end
			part = getSilentAimTarget()
			if part then
				return {
					Instance = part,
					Position = getPredictedPosition(part),
					Normal = Vector3.new(0, 1, 0),
					Material = Enum.Material.Plastic,
				}
			end
			return originalRaycast(...)
		end
	end
end

local function shootAt(position)
	if typeof(DeagleController) ~= "table" then
		return
	end
	pcall(function()
		DeagleController.ShootCooldownUntil = 0
		DeagleController.CanShoot = true
		DeagleController.CurrentSpread = 0
		if DeagleController.WeaponStats then
			DeagleController.WeaponStats.Spread = 0
		end
	end)
	pcall(function()
		if typeof(DeagleController.Shoot) == "function" then
			DeagleController.Shoot(position)
		elseif typeof(DeagleController.Fire) == "function" then
			DeagleController.Fire(position)
		end
	end)
end

local function doKillAll()
	if not enabled.killAll then
		return
	end
	local myCharacter = getCharacter()
	local myRoot = getRoot()
	local myHumanoid = getHumanoid()
	if not myCharacter or not myRoot or not myHumanoid or typeof(DeagleController) ~= "table" then
		return
	end
	setFarmStatus("kill all")
	local pool = collectTargets()
	for _, model in ipairs(pool) do
		local part = resolveTargetPart(model)
		if part then
			for key in pairs(CurrentShotTargets) do
				CurrentShotTargets[key] = nil
			end
			CurrentShotTargets[part] = true
			shootAt(getPredictedPosition(part))
		end
	end
	for key in pairs(CurrentShotTargets) do
		CurrentShotTargets[key] = nil
	end
end

local function updateVisuals(delta)
	delta = tonumber(delta) or 1 / 60
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X / 2, viewport.Y / 2)

	if enabled.fovCircle and hasDrawing then
		if not fovCircle then
			fovCircle = newDrawing("Circle", {Thickness = 1.5, Color = Color3.fromRGB(255, 255, 255), Filled = false, NumSides = 64, Visible = false})
		end
		if fovCircle then
			fovCircle.Radius = tonumber(Options.FovRadius and Options.FovRadius.Value) or 150
			fovCircle.Position = center
			fovCircle.Visible = true
		end
	elseif fovCircle then
		fovCircle.Visible = false
	end

	local now = tick()
	if now - (timers.targets or 0) > 0.1 then
		timers.targets = now
		if now - (timers.npcs or 0) > 1 then
			timers.npcs = now
			pcall(scanNpcs)
		end
		liveTargets = collectTargets()
		liveSet = {}
		for _, model in ipairs(liveTargets) do
			liveSet[model] = true
		end
	end

	if not (enabled.esp or enabled.tracers or enabled.espGlow) then
		if next(espCache) then
			clearAllEsp()
		end
	else
		for model, entry in pairs(espCache) do
			if not liveSet[model] or not isAliveAndValid(model) then
				clearEspEntry(entry)
				espCache[model] = nil
			end
		end
		local myRoot = getRoot()
		local myPosition = myRoot and myRoot.Position
		for _, model in ipairs(liveTargets) do
			if not espCache[model] and myPosition then
				local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
				if root and (root.Position - myPosition).Magnitude <= ESP_MAX_DISTANCE then
					createEntry(model)
				end
			end
		end
		for model, entry in pairs(espCache) do
			local head = model:FindFirstChild("Head") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
			local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
			local distance = (head and root and myPosition) and (root.Position - myPosition).Magnitude
			if not distance or distance > ESP_MAX_DISTANCE then
				hideEspEntry(entry)
			else
				local okPoint, point = pcall(function()
					return camera:WorldToViewportPoint(root.Position)
				end)
				if not (okPoint and typeof(point) == "Vector3") then
					point = nil
				end
				local onScreen = point ~= nil and point.Z > 0 and point.X > -50 and point.Y > -50 and point.X < viewport.X + 50 and point.Y < viewport.Y + 50
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				local owner = Players:GetPlayerFromCharacter(model)
				local displayName = owner and owner.DisplayName or model.Name
				local healthRatio = humanoid and math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1) or 1
				if entry.highlight then
					entry.highlight.Enabled = enabled.espGlow
				end
				if entry.billboard then
					entry.billboard.Enabled = enabled.esp and onScreen == true
					if entry.billboard.Enabled then
						local label = entry.billboard:FindFirstChildOfClass("TextLabel")
						if label then
							label.Text = string.format("%s\n%d%% | %dm", displayName, math.floor(healthRatio * 100 + 0.5), math.floor(distance))
						end
					end
				end
				local boxVisible = false
				local topY, bottomY, boxW = (point and point.Y) or 0, (point and point.Y) or 0, 0
				if onScreen then
					local okTop, topPoint = pcall(function()
						return camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, 3, 0)).Position)
					end)
					local okBottom, bottomPoint = pcall(function()
						return camera:WorldToViewportPoint((root.CFrame * CFrame.new(0, -3.4, 0)).Position)
					end)
					if okTop and typeof(topPoint) == "Vector3" and topPoint.Z > 0 and okBottom and typeof(bottomPoint) == "Vector3" and bottomPoint.Z > 0 then
						topY = math.min(topPoint.Y, bottomPoint.Y)
						bottomY = math.max(topPoint.Y, bottomPoint.Y)
						boxW = math.max((bottomY - topY) / 2, 8)
						boxVisible = true
					end
				end
				if entry.box then
					entry.box.Visible = enabled.esp and boxVisible
					if entry.box.Visible then
						entry.box.Size = Vector2.new(boxW * 2, bottomY - topY)
						entry.box.Position = Vector2.new(point.X - boxW, topY)
					end
				end
				if entry.nameText then
					entry.nameText.Visible = enabled.esp and boxVisible
					if entry.nameText.Visible then
						entry.nameText.Text = displayName
						entry.nameText.Position = Vector2.new(point.X, topY - 18)
					end
				end
				if entry.healthText then
					entry.healthText.Visible = enabled.esp and boxVisible
					if entry.healthText.Visible then
						local percent = math.floor(healthRatio * 100 + 0.5)
						entry.healthText.Text = "HP " .. percent .. "%"
						entry.healthText.Color = percent > 50 and Color3.fromRGB(124, 252, 124) or (percent > 25 and Color3.fromRGB(255, 165, 79) or Color3.fromRGB(255, 80, 80))
						entry.healthText.Position = Vector2.new(point.X, bottomY + 4)
					end
				end
				if entry.distanceText then
					entry.distanceText.Visible = enabled.esp and boxVisible
					if entry.distanceText.Visible then
						entry.distanceText.Text = math.floor(distance) .. "m"
						entry.distanceText.Position = Vector2.new(point.X, bottomY + 20)
					end
				end
				if entry.tracer then
					local okHead, headPoint = pcall(function()
						return camera:WorldToViewportPoint(head.Position)
					end)
					entry.tracer.Visible = enabled.tracers and onScreen and okHead and typeof(headPoint) == "Vector3" and headPoint.Z > 0
					if entry.tracer.Visible then
						entry.tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
						entry.tracer.To = Vector2.new(headPoint.X, headPoint.Y)
					end
				end
			end
		end
	end

	if enabled.aimbot then
		local radius = (tonumber(Options.FovRadius and Options.FovRadius.Value) or 150)
		if not targetStillValid(camera, center, lockedPart, radius) then
			lockedPart = nil
		end
		if not lockedPart then
			lockedPart = acquireAimTarget(camera, center)
		end
		if lockedPart then
			setFarmStatus("aiming")
			camera.CFrame = CFrame.new(camera.CFrame.Position, getPredictedPosition(lockedPart))
		end
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

local godConnection
local function setGodMode(state)
	if state and not godConnection then
		godConnection = RunService.Heartbeat:Connect(function()
			local humanoid = getHumanoid()
			if humanoid then
				if humanoid.MaxHealth ~= math.huge then
					humanoid.MaxHealth = math.huge
				end
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	elseif not state and godConnection then
		godConnection:Disconnect()
		godConnection = nil
		local humanoid = getHumanoid()
		if humanoid and humanoid.MaxHealth == math.huge then
			humanoid.MaxHealth = 100
			humanoid.Health = 100
		end
	end
end

local function applyMovement()
	local humanoid = getHumanoid()
	if not humanoid then
		return
	end
	if enabled.walkSpeed then
		humanoid.WalkSpeed = tonumber(Options.WalkSpeed and Options.WalkSpeed.Value) or 16
	end
	if enabled.jumpPower then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = tonumber(Options.JumpPower and Options.JumpPower.Value) or 50
	end
end

local infJumpConnection
local function setInfJump(state)
	if state and not infJumpConnection then
		infJumpConnection = UserInputService.JumpRequest:Connect(function()
			if not enabled.infJump or not session.running then
				return
			end
			local humanoid = getHumanoid()
			if humanoid then
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end)
			end
		end)
	elseif not state and infJumpConnection then
		infJumpConnection:Disconnect()
		infJumpConnection = nil
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

local CombatTab = Tabs.Main:AddSubTab({ Name = "Combat", Icon = "zap" })
local AimingTab = Tabs.Main:AddSubTab({ Name = "Aiming", Icon = "gauge" })
local VisualsTab = Tabs.Main:AddSubTab({ Name = "Visuals", Icon = "star" })

local KillBox = box(CombatTab, "Kill All", "zap", "Left")
KillBox:AddToggle("KillAll", { Text = "Kill All", Default = false, Callback = function(value)
	enabled.killAll = value
	if not value then
		for key in pairs(CurrentShotTargets) do
			CurrentShotTargets[key] = nil
		end
	end
end })

local StatusBox = box(CombatTab, "Combat Info", "activity", "Right")
StatusBox:AddLabel("FarmStatusLabel", { Text = paint("Status -", "idle", COLORS.accent), DoesWrap = true })
StatusBox:AddLabel("HealthLabel", { Text = paint("Health -", "0/0", COLORS.user), DoesWrap = true })
StatusBox:AddLabel("PingLabel", { Text = paint("Ping -", "0ms", COLORS.orange), DoesWrap = true })

local AimBox = box(AimingTab, "Aimbot", "gauge", "Left")
AimBox:AddToggle("Aimbot", { Text = "Auto Aim", Default = false, Callback = function(value)
	enabled.aimbot = value
	if not value then
		lockedPart = nil
	end
end })
AimBox:AddDropdown("AimPart", { Text = "Target", Values = { "Head", "Torso", "UpperTorso", "HumanoidRootPart" }, Default = "Head", Callback = function()
	lockedPart = nil
end })
AimBox:AddSlider("FovRadius", { Text = "FOV Radius", Default = 150, Min = 30, Max = 600, Rounding = 0, Suffix = "px" })

local SilentBox = box(AimingTab, "Silent Aim", "sparkles", "Right")
SilentBox:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Callback = function(value)
	enabled.silent = value
end })

local WallbangBox = box(AimingTab, "Wallbang", "target", "Right")
WallbangBox:AddToggle("Wallbang", { Text = "Wallbang", Default = false, Callback = function(value)
	enabled.wallbang = value
end })

local EspBox = box(VisualsTab, "ESP", "user", "Left")
EspBox:AddToggle("EspEnabled", { Text = "ESP", Default = false, Callback = function(value)
	enabled.esp = value
end })

local TrackerBox = box(VisualsTab, "Tracker", "link", "Right")
TrackerBox:AddToggle("Tracers", { Text = "Tracers", Default = false, Callback = function(value)
	enabled.tracers = value
end })
TrackerBox:AddToggle("EspGlow", { Text = "Wall Glow", Default = false, Callback = function(value)
	enabled.espGlow = value
end })

local MovementTab = Tabs.Main:AddSubTab({ Name = "Movement", Icon = "wind" })

local SpeedBox = box(MovementTab, "Speed", "gauge", "Left")
SpeedBox:AddToggle("WalkSpeedEnabled", { Text = "Walk Speed", Default = false, Callback = function(value)
	enabled.walkSpeed = value
	applyMovement()
end })
SpeedBox:AddSlider("WalkSpeed", { Text = "", Default = 16, Min = 0, Max = 500, Rounding = 0 })
SpeedBox:AddToggle("JumpPowerEnabled", { Text = "Jump Power", Default = false, Callback = function(value)
	enabled.jumpPower = value
	applyMovement()
end })
SpeedBox:AddSlider("JumpPower", { Text = "", Default = 50, Min = 0, Max = 500, Rounding = 0 })

local AirBox = box(MovementTab, "Jump", "wind", "Right")
AirBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false, Callback = function(value)
	enabled.infJump = value
	setInfJump(value)
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
ClientBox:AddToggle("GodMode", { Text = "God Mode", Default = false, Callback = function(value)
	setGodMode(value)
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
	setLabel("HealthLabel", paint("Health -", string.format("%d/%d", getHealth(), getMaxHealth()), COLORS.user))
	setLabel("PingLabel", paint("Ping -", getPing() .. "ms", COLORS.orange))
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

loop(doKillAll, 0.02)
loop(applyMovement, 0.25)

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
local visualConnection = RunService.RenderStepped:Connect(function(delta)
	if not session.running then
		return
	end
	local ok, err = pcall(updateVisuals, delta)
	if not ok then
		logError(err)
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
	if visualConnection then
		pcall(function()
			visualConnection:Disconnect()
		end)
		visualConnection = nil
	end
	setAntiAfk(false)
	setRendering(false)
	setFpsBoost(false)
	setGodMode(false)
	setInfJump(false)
	lockedPart = nil
	for key in pairs(CurrentShotTargets) do
		CurrentShotTargets[key] = nil
	end
	if originalRaycast and DeagleShared then
		pcall(function()
			DeagleShared.Raycast = originalRaycast
		end)
	end
	clearAllEsp()
	if fovCircle then
		pcall(function()
			fovCircle:Remove()
		end)
		fovCircle = nil
	end
	session.lib = nil
end)

SaveManager:LoadAutoloadConfig()