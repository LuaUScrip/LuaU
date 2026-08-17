--[[
	AntiGodHub | Gun + Hitbox Script
	================================
	Remote logic only. Final clean version:
	- Auto Shoot (prediction) / Auto Equip
	- Hitbox Expander (FFA only)
	- Hidden aim config: Max Distance 1000 / Prediction 0

	FEATURES
	• Main > Combat: Auto Shoot, Hitbox
	• Info tab: session timer, game info, socials
	• Settings: themes, config save/load, auto features
	• Toggle + Lock buttons (mobile friendly)

	USAGE
	1. Open your executor.
	2. Paste the whole script and execute.
	3. Toggle features in the "AntiGodHub" window.
--]]

-- ============================================================
-- 1. LIBRARY
-- ============================================================
local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library

pcall(function()
	Library = loadstring(game:HttpGet(LibraryURL))()
end)

if not Library then
	warn("ERROR: Failed to load library")
	return
end

-- ============================================================
-- 2. SERVICES
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer

-- Session timer
local SessionStart = tick()

-- ============================================================
-- 3. CONFIG
--    Feature state lives on getgenv() (same as the source
--    scripts) so other scripts can read/toggle it.
-- ============================================================
-- Gun
getgenv().autoShoot = false
getgenv().autoEquip = false
getgenv().aimConfig = {
	MAX_DISTANCE = 1000,
	PREDRATE = 0,
}

-- Hitbox (FFA only)
getgenv().HitboxEnabled = false
getgenv().NoCollisionEnabled = false
getgenv().HitboxSize = 23
getgenv().HitboxTransparency = 0.8

-- UI config
local Config = {
	-- Auto features
	AutoSave = false,
	AutoExecute = false,
	AutoReconnect = false,
	AutoHideUi = false,
	AntiAfk = false,
	NoGameplayPaused = false,

	-- UI
	ThemeName = "Emerald Green",
	FontName = "Cartoon",
	FontPreset = "White + Emerald",
	MenuBind = "G",
	CustomColors = {
		AccentColor = Color3.fromRGB(96, 216, 118),
		FontColor = Color3.fromRGB(255, 255, 255),
		BackgroundColor = Color3.fromRGB(8, 16, 10),
		MainColor = Color3.fromRGB(16, 28, 20),
		OutlineColor = Color3.fromRGB(30, 58, 40),
	},

	-- Links
	DiscordLink = "https://discord.gg/jdJvZm6VdK",
	YouTubeLink = "https://youtube.com/@antigodhub",
	TikTokLink = "https://tiktok.com/@antigodhub",
}

local SettingsRefs = {}
local SuppressUI = false

-- ============================================================
-- 4. EXECUTOR DETECTION
-- ============================================================
local ExecutorName = "Unknown"
local ExecutorVersion = "Unknown"

pcall(function()
	if identifyexecutor then
		local Name, Version = identifyexecutor()
		if type(Name) == "table" then
			ExecutorName = tostring(Name[1] or Name.Name or "Unknown")
			ExecutorVersion = tostring(Name[2] or Name.Version or "Unknown")
		else
			ExecutorName = tostring(Name)
			if Version ~= nil then
				ExecutorVersion = tostring(Version)
			end
		end
	elseif getexecutorname then
		ExecutorName = tostring(getexecutorname())
		if getexecutorversion then
			ExecutorVersion = tostring(getexecutorversion())
		end
	end
end)

local ExecutorDisplay = ExecutorName
if ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" then
	ExecutorDisplay = ExecutorName .. " " .. ExecutorVersion
end

-- ============================================================
-- 5. UTILITIES
-- ============================================================
local function CopyToClipboard(Text)
	local Success = pcall(setclipboard, Text)
	if not Success then
		Success = pcall(toclipboard, Text)
	end
	return Success
end

local NotifyColors = {
	Success = Color3.fromRGB(96, 216, 118),
	Warning = Color3.fromRGB(255, 176, 80),
	Error = Color3.fromRGB(255, 96, 96),
}

local function Notify(Title, Description, Type)
	pcall(function()
		if type(Title) == "string" and #Title > 60 then
			Title = Title:sub(1, 57) .. "..."
		end
		if Description == nil or Description == "" then
			Description = " "
		elseif type(Description) == "string" and #Description > 60 then
			Description = Description:sub(1, 57) .. "..."
		end
		Type = Type or "Info"
		Library:Notify({
			Title = Title,
			Description = Description,
			Time = 4,
			Type = Type,
			DescriptionColor = NotifyColors[Type],
		})
	end)
end

-- ============================================================
-- 6. COMBAT (Auto Shoot / Auto Equip)
-- ============================================================
local FIRE_RATE_COOLDOWN = 0.11
local EQUIP_COOLDOWN = 0.5

local function GetShootRemote()
	local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	return RemotesFolder and RemotesFolder:FindFirstChild("ShootGun")
end

-- Nearest enemy with velocity prediction (FFA, skips same team)
local function GetNearestTarget()
	local MyChar = Player.Character
	local MyRoot = MyChar and MyChar:FindFirstChild("HumanoidRootPart")
	if not MyRoot then return nil, nil end

	local NearestPlayer, MinDist = nil, math.huge
	local TargetVelocity = Vector3.new(0, 0, 0)

	for _, OtherPlayer in pairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player and OtherPlayer.Character and OtherPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local Hum = OtherPlayer.Character:FindFirstChildOfClass("Humanoid")
			if Hum and Hum.Health > 0 and Hum:GetState() ~= Enum.HumanoidStateType.Dead and OtherPlayer.Character.Parent == Workspace then
				if not OtherPlayer.Team or not Player.Team or OtherPlayer.Team ~= Player.Team then
					local EnemyRoot = OtherPlayer.Character.HumanoidRootPart
					local Dist = (EnemyRoot.Position - MyRoot.Position).Magnitude

					local Velocity = EnemyRoot.AssemblyLinearVelocity
					if Dist < MinDist and Dist <= getgenv().aimConfig.MAX_DISTANCE and Velocity.Y > -100 then
						MinDist = Dist
						NearestPlayer = EnemyRoot
						TargetVelocity = Velocity
					end
				end
			end
		end
	end

	if NearestPlayer then
		local PredictedPos = NearestPlayer.Position + (TargetVelocity * getgenv().aimConfig.PREDRATE)
		return NearestPlayer, PredictedPos
	end
	return nil, nil
end

-- One persistent loop (no double firing when Auto Shoot + Auto Equip are both on)
local function ShootLoop()
	task.spawn(function()
		local LastFireTime = 0
		local LastEquipTime = 0

		while true do
			RunService.Heartbeat:Wait()
			if Library.Unloaded then break end

			pcall(function()
				local Char = Player.Character
				if not Char then return end

				-- Auto Equip (key 2)
				if getgenv().autoEquip and not Char:FindFirstChildOfClass("Tool") then
					local CurrentTime = os.clock()
					if (CurrentTime - LastEquipTime) >= EQUIP_COOLDOWN then
						LastEquipTime = CurrentTime
						task.spawn(function()
							pcall(function()
								VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
							end)
							task.wait(0.05)
							pcall(function()
								VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
							end)
						end)
					end
				end

				if not getgenv().autoShoot then return end

				local CurrentTime = os.clock()
				if (CurrentTime - LastFireTime) < FIRE_RATE_COOLDOWN then return end

				local ShootRemote = GetShootRemote()
				if not ShootRemote then return end

				local GunModel = Char:FindFirstChild("Gun_Equip") or Char:FindFirstChildOfClass("Tool")
				local Muzzle = GunModel and GunModel:FindFirstChild("Muzzle", true)
				if not Muzzle then return end

				local TargetInstance, PredictedPosition = GetNearestTarget()
				if TargetInstance and PredictedPosition then
					LastFireTime = CurrentTime
					ShootRemote:FireServer(Muzzle.WorldPosition, PredictedPosition, TargetInstance, PredictedPosition)
				end
			end)
		end
	end)
end

-- ============================================================
-- 7. HITBOX EXPANDER (FFA only)
-- ============================================================
local HitboxOriginals = {}
local DefaultBodyParts = {
	"UpperTorso",
	"Head",
	"HumanoidRootPart",
}

local function SavePart(OtherPlayer, Part)
	if not HitboxOriginals[OtherPlayer] then
		HitboxOriginals[OtherPlayer] = {}
	end
	if not HitboxOriginals[OtherPlayer][Part.Name] then
		HitboxOriginals[OtherPlayer][Part.Name] = {
			CanCollide = Part.CanCollide,
			Transparency = Part.Transparency,
			Size = Part.Size,
		}
	end
end

local function RestorePlayer(OtherPlayer)
	local Saved = HitboxOriginals[OtherPlayer]
	if not Saved then return end
	for PartName, Properties in Saved do
		local Part = OtherPlayer.Character and OtherPlayer.Character:FindFirstChild(PartName)
		if Part and Part:IsA("BasePart") then
			Part.CanCollide = Properties.CanCollide
			Part.Transparency = Properties.Transparency
			Part.Size = Properties.Size
		end
	end
end

local function FindClosestPart(Character, PartName)
	for _, Part in ipairs(Character:GetChildren()) do
		if Part:IsA("BasePart") and Part.Name:lower():match(PartName:lower()) then
			return Part
		end
	end
	return nil
end

local function ExtendHitbox(OtherPlayer)
	for _, PartName in ipairs(DefaultBodyParts) do
		local Part = OtherPlayer.Character and (OtherPlayer.Character:FindFirstChild(PartName) or FindClosestPart(OtherPlayer.Character, PartName))
		if Part and Part:IsA("BasePart") then
			SavePart(OtherPlayer, Part)
			Part.CanCollide = not getgenv().NoCollisionEnabled
			Part.Transparency = getgenv().HitboxTransparency
			Part.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
		end
	end
end

-- FFA: every other player is a target
local function IsEnemy()
	return true
end

local function UpdateHitboxes()
	for _, OtherPlayer in pairs(Players:GetPlayers()) do
		if OtherPlayer ~= Player and OtherPlayer.Character and OtherPlayer.Character:FindFirstChild("HumanoidRootPart") then
			if IsEnemy() then
				ExtendHitbox(OtherPlayer)
			else
				RestorePlayer(OtherPlayer)
			end
		end
	end
end

local function CheckForDeadPlayers()
	for OtherPlayer in HitboxOriginals do
		if not OtherPlayer.Parent or not OtherPlayer.Character or not OtherPlayer.Character:IsDescendantOf(game) then
			RestorePlayer(OtherPlayer)
			HitboxOriginals[OtherPlayer] = nil
		end
	end
end

-- Track players (re-apply hitbox on respawn, restore on removal)
local function OnPlayerAdded(OtherPlayer)
	OtherPlayer.CharacterAdded:Connect(function(Character)
		task.wait(0.1)
		HitboxOriginals[OtherPlayer] = nil
		if getgenv().HitboxEnabled and IsEnemy() then
			pcall(ExtendHitbox, OtherPlayer)
		end
	end)
	OtherPlayer.CharacterRemoving:Connect(function()
		RestorePlayer(OtherPlayer)
		HitboxOriginals[OtherPlayer] = nil
	end)
end

Players.PlayerAdded:Connect(OnPlayerAdded)

for _, Existing in pairs(Players:GetPlayers()) do
	if Existing ~= Player then
		OnPlayerAdded(Existing)
	end
end

-- Hitbox loop
RunService.Stepped:Connect(function()
	if Library.Unloaded then return end

	if getgenv().HitboxEnabled then
		UpdateHitboxes()
		CheckForDeadPlayers()
	else
		for _, OtherPlayer in pairs(Players:GetPlayers()) do
			if OtherPlayer ~= Player then
				RestorePlayer(OtherPlayer)
			end
		end
	end
end)

-- ============================================================
-- 8. THEME MANAGER
-- ============================================================
local function MakeTheme(Accent, Background, Main, Outline, Font)
	return {
		AccentColor = Accent,
		BackgroundColor = Background,
		MainColor = Main,
		OutlineColor = Outline,
		FontColor = Font,
	}
end

local Themes = {
	["Obsidian (Default)"] = MakeTheme(
		Color3.fromRGB(125, 85, 255),
		Color3.fromRGB(15, 15, 15),
		Color3.fromRGB(25, 25, 25),
		Color3.fromRGB(40, 40, 40),
		Color3.fromRGB(255, 255, 255)
	),
	["Midnight Blue"] = MakeTheme(
		Color3.fromRGB(96, 165, 255),
		Color3.fromRGB(8, 10, 16),
		Color3.fromRGB(18, 22, 32),
		Color3.fromRGB(38, 46, 64),
		Color3.fromRGB(255, 255, 255)
	),
	["Blood Red"] = MakeTheme(
		Color3.fromRGB(255, 76, 76),
		Color3.fromRGB(16, 8, 8),
		Color3.fromRGB(28, 14, 14),
		Color3.fromRGB(64, 30, 30),
		Color3.fromRGB(255, 255, 255)
	),
	["Emerald Green"] = MakeTheme(
		Color3.fromRGB(96, 216, 118),
		Color3.fromRGB(8, 16, 10),
		Color3.fromRGB(16, 28, 20),
		Color3.fromRGB(30, 58, 40),
		Color3.fromRGB(255, 255, 255)
	),
	["Sunset Orange"] = MakeTheme(
		Color3.fromRGB(255, 148, 60),
		Color3.fromRGB(18, 12, 8),
		Color3.fromRGB(32, 22, 12),
		Color3.fromRGB(64, 46, 26),
		Color3.fromRGB(255, 255, 255)
	),
}

local ThemeNames = {}
for Name in Themes do
	table.insert(ThemeNames, Name)
end

local function CloneColors(Scheme)
	local Clone = {}
	for Key, Value in Scheme do
		Clone[Key] = Value
	end
	return Clone
end

local function ApplyTheme(Scheme)
	for Key, Value in Scheme do
		if Library.Scheme[Key] ~= nil then
			Library.Scheme[Key] = Value
		end
	end
	Library:UpdateColorsUsingRegistry()
end

local function ApplyColorOverride(Key, Color)
	if Library.Scheme[Key] ~= nil then
		Library.Scheme[Key] = Color
		Library:UpdateColorsUsingRegistry()
	end
end

local function ApplyCustomColors()
	for Key, Color in Config.CustomColors do
		ApplyColorOverride(Key, Color)
	end
end

local function SyncColorPickers()
	local PickerMap = {
		AccentColor = "ThemeAccent",
		FontColor = "ThemeFontColor",
		BackgroundColor = "ThemeBackground",
		MainColor = "ThemeMain",
		OutlineColor = "ThemeOutline",
	}
	for Key, Idx in PickerMap do
		local Picker = Library.Options[Idx]
		if Picker and Picker.SetValueRGB then
			Picker:SetValueRGB(Config.CustomColors[Key])
		end
	end
end

-- ===== Fonts =====
local FontNames = {
	"Code", "Gotham", "Roboto", "Cartoon", "Arial",
	"SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito",
}

local FontPresets = {
	{ Name = "White + Emerald", Accent = Color3.fromRGB(96, 216, 118) },
	{ Name = "White + Sky Blue", Accent = Color3.fromRGB(79, 195, 247) },
	{ Name = "White + Gold", Accent = Color3.fromRGB(255, 213, 79) },
	{ Name = "White + Rose", Accent = Color3.fromRGB(255, 107, 107) },
	{ Name = "White + Violet", Accent = Color3.fromRGB(179, 136, 255) },
	{ Name = "White + Teal", Accent = Color3.fromRGB(77, 208, 196) },
	{ Name = "White + Coral", Accent = Color3.fromRGB(255, 138, 101) },
	{ Name = "White + Lavender", Accent = Color3.fromRGB(206, 147, 216) },
	{ Name = "White + Cyan", Accent = Color3.fromRGB(77, 208, 225) },
	{ Name = "White + Lime", Accent = Color3.fromRGB(174, 213, 129) },
}

-- ============================================================
-- 9. CONFIG SAVE / LOAD
-- ============================================================
local ConfigsDir = "FarmScript/Configs"
local AutoloadPath = "FarmScript/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(Name)
	if type(Name) ~= "string" then return nil end
	local Clean = Name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if Clean == "" then return nil end
	return Clean
end

local function ConfigPath(Name)
	return ConfigsDir .. "/" .. Name .. ".json"
end

local function GetConfigList()
	local List = {}
	if not listfiles then return List end
	pcall(function()
		makefolder("FarmScript")
		makefolder(ConfigsDir)
		for _, Path in listfiles(ConfigsDir) do
			if Path:sub(-5) == ".json" then
				local Name = Path:match("([^/\\]+)%.json$")
				if Name then table.insert(List, Name) end
			end
		end
	end)
	table.sort(List)
	return List
end

local function ConfigExists(Name)
	Name = SanitizeConfigName(Name)
	if not Name or not isfile then return false end
	return isfile(ConfigPath(Name))
end

local function SaveConfigData(Name)
	if not writefile then return false end
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	pcall(function()
		makefolder("FarmScript")
		makefolder(ConfigsDir)
		local Data = {
			Toggles = {},
			ThemeName = Config.ThemeName,
			FontName = Config.FontName,
			FontPreset = Config.FontPreset,
			MenuBind = Config.MenuBind,
			Colors = {},
		}
		for Key, Color in Config.CustomColors do
			Data.Colors[Key] = {
				math.floor(Color.R * 255),
				math.floor(Color.G * 255),
				math.floor(Color.B * 255),
			}
		end
		for Id, Toggle in Library.Toggles do
			Data.Toggles[Id] = Toggle.Value
		end
		writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
	end)
	return true
end

local function GetAutoloadName()
	if not isfile or not readfile then return nil end
	if not isfile(AutoloadPath) then return nil end
	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(AutoloadPath))
	end)
	if Success and type(Data) == "table" and type(Data.Name) == "string" then
		return SanitizeConfigName(Data.Name)
	end
	return nil
end

local function SetAutoload(Name)
	if not writefile then return false end
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	pcall(function()
		makefolder("FarmScript")
		writefile(AutoloadPath, HttpService:JSONEncode({ Name = Name }))
	end)
	return true
end

local function ClearAutoload()
	pcall(function()
		if isfile and isfile(AutoloadPath) then
			delfile(AutoloadPath)
		end
	end)
	return true
end

local SaveQueued = false
local function ScheduleSave()
	if not Config.AutoSave then return end
	if not CurrentConfig then return end
	if SaveQueued then return end
	SaveQueued = true
	task.delay(1, function()
		SaveQueued = false
		SaveConfigData(CurrentConfig)
	end)
end

local LoadConfig
LoadConfig = function(Name, Silent)
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	if not isfile or not readfile then
		if not Silent then Notify("Config", "Config loading not supported", "Error") end
		return false
	end
	if not isfile(ConfigPath(Name)) then
		if not Silent then Notify("Config", "Config not found", "Warning") end
		return false
	end

	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(ConfigPath(Name)))
	end)
	if not Success or type(Data) ~= "table" then
		if not Silent then Notify("Config", "Failed to read config", "Error") end
		return false
	end

	SuppressUI = true

	if type(Data.ThemeName) == "string" and Themes[Data.ThemeName] then
		Config.ThemeName = Data.ThemeName
		ApplyTheme(Themes[Data.ThemeName])
	end

	if type(Data.Colors) == "table" then
		for Key, RGB in Data.Colors do
			if Config.CustomColors[Key] ~= nil and type(RGB) == "table" then
				local R, G, B = RGB[1], RGB[2], RGB[3]
				if type(R) == "number" and type(G) == "number" and type(B) == "number" then
					Config.CustomColors[Key] = Color3.fromRGB(R, G, B)
				end
			end
		end
		ApplyCustomColors()
	end

	if type(Data.FontName) == "string" and Enum.Font[Data.FontName] then
		Config.FontName = Data.FontName
		Library:SetFont(Enum.Font[Data.FontName])
	end

	if type(Data.FontPreset) == "string" then
		for _, Preset in FontPresets do
			if Preset.Name == Data.FontPreset then
				Config.FontPreset = Preset.Name
				break
			end
		end
	end

	if type(Data.MenuBind) == "string" and Data.MenuBind ~= "None" then
		Config.MenuBind = Data.MenuBind
	end

	if type(Data.Toggles) == "table" then
		for Id, Value in Data.Toggles do
			local Toggle = Library.Toggles[Id]
			if Toggle and type(Value) == "boolean" then
				Toggle:SetValue(Value)
			end
		end
	end

	if SettingsRefs.ThemeDropdown then
		SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName)
	end
	if SettingsRefs.FontDropdown then
		SettingsRefs.FontDropdown:SetValue(Config.FontName)
	end
	SyncColorPickers()

	SuppressUI = false
	CurrentConfig = Name
	return true
end

-- Add a feature toggle
local function AddFeatureToggle(Box, Id, Info, OnToggle)
	return Box:AddToggle(Id, {
		Text = Info.Text,
		Default = false,
		Tooltip = Info.Tooltip,
		Callback = function(Value)
			if OnToggle then OnToggle(Value) end
			if Info.Notify and not SuppressUI then
				Notify(Info.Text .. (Value and " On" or " Off"), "", Value and "Success" or "Warning")
			end
			ScheduleSave()
		end,
	})
end

-- ============================================================
-- 10. AUTO FEATURE LOOPS
-- ============================================================
local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute and not Library.Unloaded then
			local AutoShoot = Library.Toggles.AutoShoot
			if AutoShoot and not AutoShoot.Value then
				AutoShoot:SetValue(true)
			end
		end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do
			task.wait(0.5)
			if Library.Unloaded then break end
			pcall(function()
				local RobloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				local DFrame = RobloxGui and RobloxGui:FindFirstChild("DisconnectedFrame")
				if DFrame and DFrame.Visible then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
				end
			end)
		end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local OpenFor = 0
		while Config.AutoHideUi do
			task.wait(1)
			if Library.Unloaded then break end
			if Library.Toggled then
				OpenFor = OpenFor + 1
				if OpenFor >= 30 then
					Library:Toggle(false)
					OpenFor = 0
				end
			else
				OpenFor = 0
			end
		end
	end)
end

local function AntiAfkLoop()
	task.spawn(function()
		while Config.AntiAfk do
			task.wait(600)
			if Library.Unloaded then break end
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
	end)
end

local function NoPauseLoop()
	task.spawn(function()
		while Config.NoGameplayPaused do
			task.wait(20)
			if Library.Unloaded then break end
			pcall(function()
				local Char = Player.Character
				local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
				if HRP then
					HRP.AssemblyLinearVelocity = HRP.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0)
				end
			end)
		end
	end)
end

-- Anti-AFK idle response
Player.Idled:Connect(function()
	if Config.AntiAfk and not Library.Unloaded then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- ============================================================
-- 11. WINDOW
-- ============================================================
local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Icon = 125265885440515,
	Footer = {
		{ Text = "Discord", Copyable = true, CopyText = Config.DiscordLink },
		{ Text = " | " },
		{ Text = "AntiGodHub", Copyable = true },
	},
	CornerRadius = 20,
	AutoShow = true,
	ShowMobileButtons = false,
	Minimizable = true,
	Resizable = true,
	Animations = {
		ToggleWindow = true,
		TabSwitch = true,
		Groupbox = true,
		Dropdown = true,
	},
})

-- Draggable Toggle / Lock buttons (mobile friendly)
local ToggleButton = Library:AddDraggableButton("Toggle", function()
	Library:Toggle()
end, true, true)

local LockButton = Library:AddDraggableButton("Lock", function(self)
	Library.CantDragForced = not Library.CantDragForced
	self:SetText(Library.CantDragForced and "Unlock" or "Lock")
end, true, true)

ToggleButton.Button.AnchorPoint = Vector2.new(0, 0)
ToggleButton.Button.Position = UDim2.fromOffset(6, 6)
LockButton.Button.AnchorPoint = Vector2.new(0, 0)
LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)

-- Tabs
local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "house" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

-- Main sub-tabs
local MainTabs = {
	Combat = Tabs.Main:AddSubTab({ Name = "Combat", Icon = "crosshair" }),
}

-- ============================================================
-- 12. INFO TAB
-- ============================================================
local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "activity")

StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()

local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0h 0m 0s</font>' })

-- Live session timer
task.spawn(function()
	while true do
		local Elapsed = tick() - SessionStart
		local Hours = math.floor(Elapsed / 3600)
		local Mins = math.floor((Elapsed % 3600) / 60)
		local Secs = math.floor(Elapsed % 60)
		pcall(function()
			SessionLabel:SetText('SESSION - <font color="#60d888">' .. Hours .. 'h ' .. Mins .. 'm ' .. Secs .. 's</font>')
		end)
		task.wait(1)
		if Library.Unloaded then break end
	end
end)

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "refresh-cw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a">Last Updated 8/17/2026</font>' })

-- Game info
local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="#60d888">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="#60d888">' .. tostring(game.PlaceId) .. '</font>' })

local JobId = tostring(game.JobId)
local ShortJobId = #JobId > 18 and JobId:sub(1, 18) .. "..." or JobId
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="#60d888">' .. ShortJobId .. '</font>' })

-- Fetch game name
task.spawn(function()
	local Success, Info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	if Success and Info and Info.Name then
		pcall(function()
			local CleanName = tostring(Info.Name):gsub("[^%z\1-\127]", "")
			GameNameLabel:SetText('GAME - <font color="#60d888">' .. CleanName .. '</font>')
		end)
	end
end)

-- Copy buttons
InfoGameBox:AddButton({
	Text = "Copy Place ID",
	Func = function()
		CopyToClipboard(tostring(game.PlaceId))
		Notify("Copied", "Place ID copied", "Success")
	end,
})

InfoGameBox:AddButton({
	Text = "Copy Join Script",
	Func = function()
		local JoinScript = string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',
			game.PlaceId, JobId
		)
		CopyToClipboard(JoinScript)
		Notify("Copied", "Join script copied", "Success")
	end,
})

-- Socials
local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "share-2")

SocialsBox:AddButton({
	Text = "Discord",
	Func = function()
		CopyToClipboard(Config.DiscordLink)
		Notify("Discord", "Link copied", "Success")
	end,
})
SocialsBox:AddButton({
	Text = "YouTube",
	Func = function()
		CopyToClipboard(Config.YouTubeLink)
		Notify("YouTube", "Link copied", "Success")
	end,
})
SocialsBox:AddButton({
	Text = "TikTok",
	Func = function()
		CopyToClipboard(Config.TikTokLink)
		Notify("TikTok", "Link copied", "Success")
	end,
})

-- Features
local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "sparkles")
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Shoot</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Hitbox Expander</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Theme Manager</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Config System</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Features</font>' })

-- ============================================================
-- 13. MAIN TAB > COMBAT (Auto Shoot / Hitbox)
-- ============================================================
local CombatBox = MainTabs.Combat:AddLeftGroupbox("Combat", "crosshair")

AddFeatureToggle(CombatBox, "AutoShoot", {
	Text = "Auto Shoot [INSTAN WIN]",
	Tooltip = "Auto shoot nearest enemy with prediction",
	Notify = true,
}, function(Value)
	getgenv().autoShoot = Value
end)

local HitboxBox = MainTabs.Combat:AddLeftGroupbox("Hitbox", "target")

AddFeatureToggle(HitboxBox, "Hitbox", {
	Text = "Hitbox",
	Tooltip = "Expand enemy hitboxes (FFA)",
	Notify = true,
}, function(Value)
	getgenv().HitboxEnabled = Value
end)

-- ============================================================
-- 14. SETTINGS TAB
-- ============================================================
-- Theme Manager
local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme",
	Values = ThemeNames,
	Default = Config.ThemeName,
	Callback = function(Value)
		Config.ThemeName = Value
		ApplyTheme(Themes[Value])
		if not SuppressUI then
			Config.CustomColors = CloneColors(Themes[Value])
			SyncColorPickers()
			Notify("Theme", "Changed to " .. Value, "Success")
			ScheduleSave()
		end
	end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

ThemeBox:AddDivider()

ThemeBox:AddLabel({ Text = "Accent" }):AddColorPicker("ThemeAccent", {
	Default = Config.CustomColors.AccentColor,
	Title = "Accent Color",
	Callback = function(Color)
		Config.CustomColors.AccentColor = Color
		ApplyColorOverride("AccentColor", Color)
		ScheduleSave()
	end,
})
ThemeBox:AddLabel({ Text = "Font" }):AddColorPicker("ThemeFontColor", {
	Default = Config.CustomColors.FontColor,
	Title = "Font Color",
	Callback = function(Color)
		Config.CustomColors.FontColor = Color
		ApplyColorOverride("FontColor", Color)
		ScheduleSave()
	end,
})
ThemeBox:AddLabel({ Text = "Background" }):AddColorPicker("ThemeBackground", {
	Default = Config.CustomColors.BackgroundColor,
	Title = "Background Color",
	Callback = function(Color)
		Config.CustomColors.BackgroundColor = Color
		ApplyColorOverride("BackgroundColor", Color)
		ScheduleSave()
	end,
})
ThemeBox:AddLabel({ Text = "Main" }):AddColorPicker("ThemeMain", {
	Default = Config.CustomColors.MainColor,
	Title = "Main Color",
	Callback = function(Color)
		Config.CustomColors.MainColor = Color
		ApplyColorOverride("MainColor", Color)
		ScheduleSave()
	end,
})
ThemeBox:AddLabel({ Text = "Outline" }):AddColorPicker("ThemeOutline", {
	Default = Config.CustomColors.OutlineColor,
	Title = "Outline Color",
	Callback = function(Color)
		Config.CustomColors.OutlineColor = Color
		ApplyColorOverride("OutlineColor", Color)
		ScheduleSave()
	end,
})

ThemeBox:AddDivider()

local FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font",
	Values = FontNames,
	Default = Config.FontName,
	Callback = function(Value)
		Config.FontName = Value
		Library:SetFont(Enum.Font[Value])
		if not SuppressUI then ScheduleSave() end
	end,
})
SettingsRefs.FontDropdown = FontDropdown

ThemeBox:AddButton({
	Text = "Reset Theme",
	Func = function()
		Config.ThemeName = "Emerald Green"
		Config.FontPreset = "White + Emerald"
		Config.CustomColors = CloneColors(Themes["Emerald Green"])
		ApplyTheme(Themes["Emerald Green"])
		ThemeDropdown:SetValue("Emerald Green")
		SyncColorPickers()
		Notify("Theme", "Reset to default", "Info")
		ScheduleSave()
	end,
})

-- Menu Settings / Auto features
local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Settings", "menu")

MenuBox:AddLabel({ Text = "Menu Bind" }):AddKeyPicker("MenuBind", {
	Default = Config.MenuBind,
	Mode = "Press",
	Text = "Toggle UI",
	Callback = function()
		Library:Toggle()
	end,
	ChangedCallback = function(NewKey)
		if typeof(NewKey) == "EnumItem" then
			Config.MenuBind = NewKey.Name
		end
		ScheduleSave()
	end,
})
SettingsRefs.MenuBindPicker = Library.Options.MenuBind

MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", {
	Text = "Auto Execute Script",
	Tooltip = "Auto run on startup",
}, function(Value)
	Config.AutoExecute = Value
	if Value then RunAutoExecute() end
end)

AddFeatureToggle(MenuBox, "AutoReconnect", {
	Text = "Auto Reconnect",
	Tooltip = "Auto reconnect on disconnect",
}, function(Value)
	Config.AutoReconnect = Value
	if Value then AutoReconnectLoop() end
end)

AddFeatureToggle(MenuBox, "AutoHideUi", {
	Text = "Auto Hide UI",
	Tooltip = "Auto hide after 30s",
}, function(Value)
	Config.AutoHideUi = Value
	if Value then AutoHideUiLoop() end
end)

AddFeatureToggle(MenuBox, "AntiAfk", {
	Text = "Anti AFK",
	Tooltip = "Prevent idle kick",
}, function(Value)
	Config.AntiAfk = Value
	if Value then AntiAfkLoop() end
end)

AddFeatureToggle(MenuBox, "NoGameplayPaused", {
	Text = "No Gameplay Paused",
	Tooltip = "Keep running when paused",
}, function(Value)
	Config.NoGameplayPaused = Value
	if Value then NoPauseLoop() end
end)

MenuBox:AddDivider()

MenuBox:AddButton({
	Text = "Stop All Features",
	Func = function()
		for Id, Toggle in Library.Toggles do
			if Toggle.Value then
				Toggle:SetValue(false)
			end
		end
		Notify("Stop", "All features stopped", "Warning")
	end,
	Risky = true
})

-- Config System
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "database")

local ConfigNameInput = ConfigBox:AddInput("ConfigName", {
	Text = "Config name",
	Placeholder = "Type config name...",
	ClearTextOnFocus = true,
})

ConfigBox:AddButton({
	Text = "Create Config",
	Func = function()
		local Name = SanitizeConfigName(ConfigNameInput.Value)
		if not Name then
			Notify("Config", "Invalid name", "Warning")
			return
		end
		if ConfigExists(Name) then
			Notify("Config", "Already exists", "Warning")
			return
		end
		if SaveConfigData(Name) then
			CurrentConfig = Name
			Notify("Config", "Created: " .. Name, "Success")
		else
			Notify("Config", "Save not supported", "Error")
		end
	end,
})

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {
	Text = "Select config",
	Values = { "---" },
	Default = "---",
	Callback = function(Value)
		CurrentConfig = Value == "---" and nil or Value
	end,
})
SettingsRefs.ConfigListDropdown = ConfigListDropdown

local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Autoload: <font color="#60d888">None</font>' })

local function RefreshConfigList(SelectName)
	local Values = { "---" }
	for _, Name in GetConfigList() do
		table.insert(Values, Name)
	end
	ConfigListDropdown:SetValues(Values)
	local Choice = SelectName or CurrentConfig or "---"
	if not table.find(Values, Choice) then Choice = "---" end
	ConfigListDropdown:SetValue(Choice)
	CurrentConfig = Choice == "---" and nil or Choice
end

local function UpdateAutoloadLabel()
	local Name = GetAutoloadName()
	local Text = 'Autoload: <font color="#60d888">None</font>'
	if Name then
		Text = 'Autoload: <font color="#60d888">' .. Name .. '</font>'
	end
	AutoloadLabel:SetText(Text)
end

ConfigBox:AddButton({
	Text = "Load Config",
	Func = function()
		if not CurrentConfig then
			Notify("Config", "Select config first", "Warning")
			return
		end
		if LoadConfig(CurrentConfig, false) then
			Notify("Config", "Loaded: " .. CurrentConfig, "Success")
		end
	end,
})
ConfigBox:AddButton({
	Text = "Overwrite Config",
	Func = function()
		if not CurrentConfig then
			Notify("Config", "Select config first", "Warning")
			return
		end
		if SaveConfigData(CurrentConfig) then
			Notify("Config", "Overwritten", "Success")
		end
	end,
})
ConfigBox:AddButton({
	Text = "Delete Config",
	Func = function()
		if not CurrentConfig then
			Notify("Config", "Select config first", "Warning")
			return
		end
		pcall(function() delfile(ConfigPath(CurrentConfig)) end)
		if GetAutoloadName() == CurrentConfig then ClearAutoload() end
		CurrentConfig = nil
		RefreshConfigList()
		UpdateAutoloadLabel()
		Notify("Config", "Deleted", "Warning")
	end,
	Risky = true
})
ConfigBox:AddButton({
	Text = "Set Autoload",
	Func = function()
		if not CurrentConfig then
			Notify("Config", "Select config first", "Warning")
			return
		end
		if SetAutoload(CurrentConfig) then
			UpdateAutoloadLabel()
			Notify("Config", "Autoload set: " .. CurrentConfig, "Success")
		end
	end,
})
ConfigBox:AddButton({
	Text = "Clear Autoload",
	Func = function()
		ClearAutoload()
		UpdateAutoloadLabel()
		Notify("Config", "Autoload cleared", "Info")
	end,
})

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", {
	Text = "Auto Save Config",
	Tooltip = "Auto save on changes",
}, function(Value)
	Config.AutoSave = Value
end)

-- ============================================================
-- 15. STARTUP
-- ============================================================
-- Apply theme on startup
ApplyTheme(Themes[Config.ThemeName])

-- Autoload on startup
task.delay(1, function()
	if Library.Unloaded then return end
	local AutoloadName = GetAutoloadName()
	if AutoloadName and ConfigExists(AutoloadName) then
		CurrentConfig = AutoloadName
		if LoadConfig(AutoloadName, true) then
			Notify("Autoload", "Loaded: " .. AutoloadName, "Success")
		end
	end
	RunAutoExecute()
	UpdateAutoloadLabel()
	RefreshConfigList()
end)

-- Start loops
ShootLoop()

-- ============================================================
-- 16. UNLOAD
-- ============================================================
Library:OnUnload(function()
	-- Restore hitboxes
	for OtherPlayer in pairs(HitboxOriginals) do
		RestorePlayer(OtherPlayer)
	end
	HitboxOriginals = {}

	-- Reset feature flags
	getgenv().autoShoot = false
	getgenv().autoEquip = false
	getgenv().HitboxEnabled = false
	getgenv().NoCollisionEnabled = false

	Config.AutoReconnect = false
	Config.AutoHideUi = false
	Config.AntiAfk = false
	Config.NoGameplayPaused = false
end)

Notify("AntiGodHub", "Script loaded!", "Success")