-- Load Obsidian GUI Library
local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()

if not Library then
	warn("ERROR: Failed to load library")
	return
end

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Track character respawn
Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- ============================================================
-- GAME-SPECIFIC: World detection & teleport/hitbox paths
-- ============================================================

local WorldData = {
	[1] = {
		CFrame = CFrame.new(13139.7939, 253.489624, 702.684814),
		HitboxPath = function()
			local s, h = pcall(function() return Workspace.StageWinPaths.Normal["13"].Hitbox end)
			return s and h or nil
		end,
	},
	[2] = {
		CFrame = CFrame.new(16173.8682, 319.496918, -10047.9756),
		HitboxPath = function()
			local s, h = pcall(function() return Workspace.StageWinPaths_W2.Normal["13"].Hitbox end)
			return s and h or nil
		end,
	},
}

-- Detect which world the player is in
local function DetectWorld()
	local ok, val = pcall(function() return Player:GetAttribute("World") end)
	if ok and type(val) == "number" then return math.floor(val) end
	local obj = Player:FindFirstChild("World")
	if obj and obj:IsA("ValueBase") and type(obj.Value) == "number" then return math.floor(obj.Value) end
	local wsObj = Workspace:FindFirstChild("World")
	if wsObj and wsObj:IsA("ValueBase") and type(wsObj.Value) == "number" then return math.floor(wsObj.Value) end
	return 1
end

-- Trails list
local TrailsList = {
	"RedTrail", "BlueTrail", "GreenTrail", "PurpleTrail",
	"OrangeTrail", "YellowTrail", "VoidTrail", "RainbowTrail",
}

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local JumpXpEvent = Remotes:WaitForChild("JumpXpEvent")
local RebirthButtonEvent = Remotes:WaitForChild("RebirthButtonEvent")
local TrailEquipRequest = Remotes:WaitForChild("TrailEquipRequest")

-- ============================================================
-- Configuration
-- ============================================================

local Config = {
	AutoWinsActive = false,
	AutoTrainFastActive = false,
	AutoRebirthActive = false,
	AutoBuyTrailActive = false,
	FontPreset = "White + Emerald",
	AutoSave = false,
	AutoExecute = false,
	AutoReconnect = false,
	AutoHideUi = false,
	AntiAfk = false,
	NoGameplayPaused = false,
	ThemeName = "Emerald Green",
	FontName = "Cartoon",
	MenuBind = "G",
	CustomColors = {
		AccentColor = Color3.fromRGB(96, 216, 118),
		FontColor = Color3.fromRGB(255, 255, 255),
		BackgroundColor = Color3.fromRGB(8, 16, 10),
		MainColor = Color3.fromRGB(16, 28, 20),
		OutlineColor = Color3.fromRGB(30, 58, 40),
	},
	DiscordLink = "https://discord.gg/jdJvZm6VdK",
	YouTubeLink = "https://youtube.com/@antigodhub",
	TikTokLink = "https://tiktok.com/@antigodhub",
}

local SettingsRefs = {}
local SuppressUI = false

-- ============================================================
-- Helper Functions
-- ============================================================

local function CopyToClipboard(Text)
	local Success = pcall(setclipboard, Text)
	if not Success then Success = pcall(toclipboard, Text) end
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

-- Teleport with safety
local function Teleport(CFramePos)
	if not HumanoidRootPart or not HumanoidRootPart.Parent then
		return false
	end
	HumanoidRootPart.CFrame = CFramePos
	RunService.RenderStepped:Wait(0.1)
	return true
end

-- ============================================================
-- GAME FUNCTIONS
-- ============================================================

-- AUTO WINS: Detect world -> Freeze -> Teleport -> Touch hitbox
local function DoAutoWin()
	if not HumanoidRootPart or not HumanoidRootPart.Parent then
		return
	end

	pcall(function()
		local world = DetectWorld()
		local data = WorldData[world]
		if not data then
			warn("Unknown world: " .. tostring(world))
			return
		end

		-- Freeze velocity
		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		-- Teleport to win position
		Teleport(data.CFrame)
		RunService.RenderStepped:Wait(0.1)

		-- Freeze again after teleport
		HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		-- Get hitbox
		local hitbox = data.HitboxPath()
		if not hitbox then
			warn("Hitbox not found for World " .. tostring(world))
			return
		end

		-- Touch hitbox: all character parts
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					firetouchinterest(part, hitbox, 0)
					task.wait(0.01)
					firetouchinterest(part, hitbox, 1)
				end)
			end
		end

		-- Touch hitbox: reverse direction
		pcall(function()
			firetouchinterest(hitbox, HumanoidRootPart, 0)
			task.wait(0.01)
			firetouchinterest(hitbox, HumanoidRootPart, 1)
		end)

		RunService.RenderStepped:Wait(0.1)
	end)
end

-- AUTO TRAIN FAST
local function DoAutoTrainFast()
	pcall(function()
		JumpXpEvent:FireServer()
	end)
end

-- AUTO REBIRTH
local function DoAutoRebirth()
	pcall(function()
		RebirthButtonEvent:FireServer()
	end)
end

-- AUTO BUY TRAIL (all in list)
local TrailAttempted = {}
local function ResetTrailTracking()
	TrailAttempted = {}
end

local function BuyTrail(TrailName)
	if TrailAttempted[TrailName] then
		return
	end
	TrailAttempted[TrailName] = true
	pcall(function()
		TrailEquipRequest:FireServer(TrailName)
	end)
end

local function BuyAllTrails()
	for _, TrailName in TrailsList do
		BuyTrail(TrailName)
		RunService.RenderStepped:Wait(0.5)
	end
end

-- ============================================================
-- Theme Manager
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

-- Fonts
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
local FontPresetNames = {}
for _, Preset in FontPresets do
	table.insert(FontPresetNames, Preset.Name)
end

-- ============================================================
-- Config Save / Load
-- ============================================================

local ConfigsDir = "AutoWins/Configs"
local AutoloadPath = "AutoWins/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(Name)
	if type(Name) ~= "string" then return nil end
	local Clean = Name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if Clean == "" or Clean == "---" then return nil end
	return Clean
end

local function ConfigPath(Name)
	return ConfigsDir .. "/" .. Name .. ".json"
end

local function GetConfigList()
	local List = {}
	if not listfiles then return List end
	pcall(function()
		makefolder("AutoWins")
		makefolder(ConfigsDir)
		for _, Path in listfiles(ConfigsDir) do
			if Path:sub(-5) == ".json" then
				local Name = Path:match("([^/\\]+)%.json$")
				if Name and Name ~= "---" then
					table.insert(List, Name)
				end
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
		makefolder("AutoWins")
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
		makefolder("AutoWins")
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

local LoadConfig
LoadConfig = function(Name, Silent)
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	if not isfile or not readfile then
		if not Silent then Notify("Config", "Config loading not supported on this executor", "Error") end
		return false
	end
	if not isfile(ConfigPath(Name)) then
		if not Silent then Notify("Config", "Config '" .. Name .. "' not found", "Warning") end
		return false
	end

	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(ConfigPath(Name)))
	end)
	if not Success or type(Data) ~= "table" then
		if not Silent then Notify("Config", "Failed to read configuration", "Error") end
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
	if SettingsRefs.FontPresetDropdown then
		SettingsRefs.FontPresetDropdown:SetValue(Config.FontPreset)
	end
	SyncColorPickers()
	if SettingsRefs.MenuBindPicker then
		SettingsRefs.MenuBindPicker:SetValue({ Config.MenuBind, "Press" })
	end

	SuppressUI = false
	CurrentConfig = Name
	return true
end

-- ============================================================
-- Feature Toggle Helper
-- ============================================================

local function AddFeatureToggle(Box, Id, Info, OnToggle)
	return Box:AddToggle(Id, {
		Text = Info.Text,
		Default = false,
		Tooltip = Info.Tooltip,
		Callback = function(Value)
			if OnToggle then
				OnToggle(Value)
			end
			if Info.Notify and not SuppressUI then
				Notify(Info.Text .. " " .. (Value and "On" or "Off"), "", Value and "Success" or "Warning")
			end
			ScheduleSave()
		end,
	})
end

-- ============================================================
-- Auto Features (utility loops)
-- ============================================================

local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local Toggle = Library.Toggles.AutoWins
			if Toggle and not Toggle.Value then
				Toggle:SetValue(true)
			end
		end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do
			task.wait(0.5)
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

Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- ============================================================
-- UI: Window
-- ============================================================

local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Icon = 125265885440515,
	Footer = {
		{ Text = "Discord", Copyable = true, OnClick = function() CopyToClipboard(Config.DiscordLink) end },
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

Library.ToggleKeybind = nil

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

-- ============================================================
-- UI: Tabs
-- ============================================================

local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "house" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

local MainTabs = {
	AutoFarm = Tabs.Main:AddSubTab({ Name = "Auto Farm", Icon = "star" }),
}

-- ============================================================
-- UI: INFO TAB
-- ============================================================

local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")

StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

-- Executor name + version
local ExecutorName = "Unknown"
local ExecutorVersion = "Unknown"
pcall(function()
	if identifyexecutor then
		local Name, Version = identifyexecutor()
		if type(Name) == "table" then
			ExecutorName = tostring(Name[1] or Name.Name or Name["Name"] or "Unknown")
			ExecutorVersion = tostring(Name[2] or Name.Version or Name["Version"] or "Unknown")
		else
			ExecutorName = tostring(Name)
			if Version ~= nil and tostring(Version) ~= "" then
				ExecutorVersion = tostring(Version)
			end
		end
	elseif getexecutorname then
		ExecutorName = tostring(getexecutorname())
	end
	if ExecutorVersion == "Unknown" then
		pcall(function()
			if getexecutorversion then
				ExecutorVersion = tostring(getexecutorversion())
			end
		end)
	end
end)

local ExecutorDisplay = ExecutorName
if ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" then
	ExecutorDisplay = ExecutorName .. " " .. ExecutorVersion
end
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

-- Updates Box
local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/18/2026</font>' })

-- Game Info Box
local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local Green = "#60d888"
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })

local JobId = tostring(game.JobId)
local ShortJobId = #JobId > 18 and JobId:sub(1, 18) .. "..." or JobId
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. ShortJobId .. '</font>' })

task.spawn(function()
	local Success, Info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if Success and Info and Info.Name then
		pcall(function()
			local CleanName = tostring(Info.Name):gsub("[^%z\1-\127]", "")
			GameNameLabel:SetText('GAME - <font color="#60d888">' .. CleanName .. '</font>')
		end)
	else
		pcall(function()
			GameNameLabel:SetText('GAME - <font color="#60d888">Unknown</font>')
		end)
	end
end)

-- Session timer
local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local Elapsed = os.clock() - ScriptStartTime
		local Mins = math.floor(Elapsed / 60)
		local Secs = math.floor(Elapsed % 60)
		pcall(function()
			SessionLabel:SetText('SESSION - <font color="#60d888">' .. Mins .. 'm ' .. Secs .. 's</font>')
		end)
		task.wait(1)
	end
end)

InfoGameBox:AddButton({
	Text = "Copy Place ID",
	Func = function()
		CopyToClipboard(tostring(game.PlaceId))
	end,
	Tooltip = "Copy Place ID",
})

InfoGameBox:AddButton({
	Text = "Copy Join Script",
	Func = function()
		local JoinScript = string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',
			game.PlaceId, JobId
		)
		CopyToClipboard(JoinScript)
	end,
	Tooltip = "Copy Join Script",
})

-- Socials Box
local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")

SocialsBox:AddButton({
	Text = "Discord",
	Func = function() CopyToClipboard(Config.DiscordLink) end,
	Tooltip = "Discord",
})
SocialsBox:AddButton({
	Text = "YouTube",
	Func = function() CopyToClipboard(Config.YouTubeLink) end,
	Tooltip = "YouTube",
})
SocialsBox:AddButton({
	Text = "TikTok",
	Func = function() CopyToClipboard(Config.TikTokLink) end,
	Tooltip = "TikTok",
})

-- Features Box
local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Wins</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Train Fast</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Rebirth</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy All Trails</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Theme Manager</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Config Autoload</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Execute Script</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Reconnect</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Hide UI</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Anti AFK</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">No Gameplay Paused</font>' })

-- ============================================================
-- UI: MAIN TAB
-- ============================================================

local FarmBox = MainTabs.AutoFarm:AddLeftGroupbox("Farming", "zap")

AddFeatureToggle(FarmBox, "AutoWins", {
	Text = "Auto Wins",
	Tooltip = "Wins",
	Notify = true,
}, function(Value)
	Config.AutoWinsActive = Value
	if Value then
		task.spawn(function()
			while Config.AutoWinsActive do
				DoAutoWin()
				RunService.RenderStepped:Wait(2)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoTrainFast", {
	Text = "Auto Train Fast",
	Tooltip = "Train Fast",
	Notify = true,
}, function(Value)
	Config.AutoTrainFastActive = Value
	if Value then
		task.spawn(function()
			while Config.AutoTrainFastActive do
				DoAutoTrainFast()
				RunService.RenderStepped:Wait(0.000001)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoRebirth", {
	Text = "Auto Rebirth",
	Tooltip = "Rebirth",
	Notify = true,
}, function(Value)
	Config.AutoRebirthActive = Value
	if Value then
		task.spawn(function()
			while Config.AutoRebirthActive do
				DoAutoRebirth()
				RunService.RenderStepped:Wait(180)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoBuyTrail", {
	Text = "Auto Buy All Trails",
	Tooltip = "Buys all 8 trails",
	Notify = true,
}, function(Value)
	Config.AutoBuyTrailActive = Value
	if Value then
		ResetTrailTracking()
		task.spawn(function()
			while Config.AutoBuyTrailActive do
				BuyAllTrails()
				RunService.RenderStepped:Wait(180)
			end
		end)
	end
end)

-- ============================================================
-- UI: SETTINGS TAB
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
			Notify("Theme", "Theme set to " .. Value, "Success")
			ScheduleSave()
		end
	end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

ThemeBox:AddDivider()

ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {
	Default = Config.CustomColors.AccentColor,
	Title = "Accent Color",
	Callback = function(Color)
		Config.CustomColors.AccentColor = Color
		ApplyColorOverride("AccentColor", Color)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", {
	Default = Config.CustomColors.FontColor,
	Title = "Font Color",
	Callback = function(Color)
		Config.CustomColors.FontColor = Color
		ApplyColorOverride("FontColor", Color)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", {
	Default = Config.CustomColors.BackgroundColor,
	Title = "Background Color",
	Callback = function(Color)
		Config.CustomColors.BackgroundColor = Color
		ApplyColorOverride("BackgroundColor", Color)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", {
	Default = Config.CustomColors.MainColor,
	Title = "Main Color",
	Callback = function(Color)
		Config.CustomColors.MainColor = Color
		ApplyColorOverride("MainColor", Color)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", {
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
		if not SuppressUI then
			ScheduleSave()
		end
	end,
})
SettingsRefs.FontDropdown = FontDropdown

local FontPresetDropdown = ThemeBox:AddDropdown("FontPreset", {
	Text = "Font Color Preset",
	Values = FontPresetNames,
	Default = Config.FontPreset,
	Visible = false,
	Callback = function(Value)
		Config.FontPreset = Value
		for _, Preset in FontPresets do
			if Preset.Name == Value then
				Config.CustomColors.FontColor = Color3.fromRGB(255, 255, 255)
				Config.CustomColors.AccentColor = Preset.Accent
				ApplyColorOverride("FontColor", Color3.fromRGB(255, 255, 255))
				ApplyColorOverride("AccentColor", Preset.Accent)
				SyncColorPickers()
				break
			end
		end
		if not SuppressUI then
			ScheduleSave()
		end
	end,
})
SettingsRefs.FontPresetDropdown = FontPresetDropdown

ThemeBox:AddButton({
	Text = "Reset Theme",
	Func = function()
		Config.ThemeName = "Emerald Green"
		Config.FontPreset = "White + Emerald"
		Config.CustomColors = CloneColors(Themes["Emerald Green"])
		ApplyTheme(Themes["Emerald Green"])
		ThemeDropdown:SetValue("Emerald Green")
		FontPresetDropdown:SetValue("White + Emerald")
		SyncColorPickers()
		Notify("Theme", "Theme reset to Emerald Green", "Info")
		ScheduleSave()
	end,
})

-- Menu Group
local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Group", "menu")

MenuBox:AddLabel("Menu Bind"):AddKeyPicker("MenuBind", {
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
	Tooltip = "Auto Execute Script",
}, function(Value)
	Config.AutoExecute = Value
	if Value then
		RunAutoExecute()
	end
end)

AddFeatureToggle(MenuBox, "AutoReconnect", {
	Text = "Auto Reconnect to Game",
	Tooltip = "Auto Reconnect to Game",
}, function(Value)
	Config.AutoReconnect = Value
	if Value then
		AutoReconnectLoop()
	end
end)

AddFeatureToggle(MenuBox, "AutoHideUi", {
	Text = "Auto Hide UI",
	Tooltip = "Auto Hide UI",
}, function(Value)
	Config.AutoHideUi = Value
	if Value then
		AutoHideUiLoop()
	end
end)

AddFeatureToggle(MenuBox, "AntiAfk", {
	Text = "Anti AFK",
	Tooltip = "Anti AFK",
}, function(Value)
	Config.AntiAfk = Value
	if Value then
		AntiAfkLoop()
	end
end)

AddFeatureToggle(MenuBox, "NoGameplayPaused", {
	Text = "No Gameplay Paused",
	Tooltip = "No Gameplay Paused",
}, function(Value)
	Config.NoGameplayPaused = Value
	if Value then
		NoPauseLoop()
	end
end)

MenuBox:AddDivider()

MenuBox:AddButton({
	Text = "Stop All Features",
	Func = function()
		Config.AutoWinsActive = false
		Config.AutoTrainFastActive = false
		Config.AutoRebirthActive = false
		Config.AutoBuyTrailActive = false
		Config.AutoReconnect = false
		Config.AutoHideUi = false
		Config.AntiAfk = false
		Config.NoGameplayPaused = false
		for Id, Toggle in Library.Toggles do
			if Toggle.Value then
				Toggle:SetValue(false)
			end
		end
		Notify("Script", "All features stopped", "Warning")
	end,
	Risky = true,
})

-- Configuration
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")

local RefreshConfigList

local ConfigNameInput = ConfigBox:AddInput("ConfigName", {
	Text = "Config name",
	Placeholder = "Type a config name...",
	ClearTextOnFocus = true,
})

ConfigBox:AddButton({
	Text = "Create config",
	Func = function()
		local Name = SanitizeConfigName(ConfigNameInput.Value)
		if not Name then
			Notify("Config", "Enter a valid config name first", "Warning")
			return
		end
		if ConfigExists(Name) then
			Notify("Config", "'" .. Name .. "' already exists", "Warning")
			return
		end
		if SaveConfigData(Name) then
			CurrentConfig = Name
			RefreshConfigList(Name)
			Notify("Config", "Config '" .. Name .. "' created", "Success")
		else
			Notify("Config", "Config saving not supported on this executor", "Error")
		end
	end,
	Tooltip = "Create config",
})

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {
	Text = "Config list",
	Values = { "---" },
	Default = "---",
	Callback = function(Value)
		CurrentConfig = Value == "---" and nil or Value
	end,
})
SettingsRefs.ConfigListDropdown = ConfigListDropdown

local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Current autoload config: <font color="#60d888">none</font>' })

RefreshConfigList = function(SelectName)
	local Values = { "---" }
	for _, Name in GetConfigList() do
		table.insert(Values, Name)
	end
	ConfigListDropdown:SetValues(Values)
	local Choice = SelectName or CurrentConfig or "---"
	if not table.find(Values, Choice) then
		Choice = "---"
	end
	ConfigListDropdown:SetValue(Choice)
	CurrentConfig = Choice == "---" and nil or Choice
end

local function UpdateAutoloadLabel()
	local Name = GetAutoloadName()
	local Text = 'Current autoload config: <font color="#60d888">none</font>'
	if Name then
		Text = 'Current autoload config: <font color="#60d888">' .. Name .. '</font>'
	end
	AutoloadLabel:SetText(Text)
end

ConfigBox:AddButton({
	Text = "Load config",
	Func = function()
		local Name = CurrentConfig
		if not Name then
			Notify("Config", "Select a config from the list first", "Warning")
			return
		end
		if LoadConfig(Name, false) then
			Notify("Config", "Config '" .. Name .. "' loaded", "Success")
		end
	end,
	Tooltip = "Load config",
})

ConfigBox:AddButton({
	Text = "Overwrite config",
	Func = function()
		local Name = CurrentConfig
		if not Name then
			Notify("Config", "Select a config from the list first", "Warning")
			return
		end
		if SaveConfigData(Name) then
			Notify("Config", "Config '" .. Name .. "' overwritten", "Success")
		else
			Notify("Config", "Config saving not supported on this executor", "Error")
		end
	end,
	Tooltip = "Overwrite config",
})

ConfigBox:AddButton({
	Text = "Delete config",
	Func = function()
		local Name = CurrentConfig
		if not Name then
			Notify("Config", "Select a config from the list first", "Warning")
			return
		end
		pcall(function()
			delfile(ConfigPath(Name))
		end)
		if GetAutoloadName() == Name then
			ClearAutoload()
		end
		CurrentConfig = nil
		RefreshConfigList()
		UpdateAutoloadLabel()
		Notify("Config", "Config '" .. Name .. "' deleted", "Warning")
	end,
	Tooltip = "Delete config",
	Risky = true,
})

ConfigBox:AddButton({
	Text = "Refresh list",
	Func = function()
		RefreshConfigList()
		Notify("Config", "Config list refreshed", "Info")
	end,
	Tooltip = "Refresh list",
})

ConfigBox:AddButton({
	Text = "Set as autoload",
	Func = function()
		local Name = CurrentConfig
		if not Name then
			Notify("Config", "Select a config from the list first", "Warning")
			return
		end
		if SetAutoload(Name) then
			UpdateAutoloadLabel()
			Notify("Config", "Autoload set to '" .. Name .. "'", "Success")
		end
	end,
	Tooltip = "Set as autoload",
})

ConfigBox:AddButton({
	Text = "Reset autoload",
	Func = function()
		ClearAutoload()
		UpdateAutoloadLabel()
		Notify("Config", "Autoload cleared", "Info")
	end,
	Tooltip = "Reset autoload",
})

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", {
	Text = "Auto Save Config",
	Tooltip = "Auto Save Config",
}, function(Value)
	Config.AutoSave = Value
end)

-- ============================================================
-- Startup
-- ============================================================

ApplyTheme(Themes[Config.ThemeName])

task.delay(1, function()
	local AutoloadName = GetAutoloadName()
	if AutoloadName and ConfigExists(AutoloadName) then
		CurrentConfig = AutoloadName
		if LoadConfig(AutoloadName, true) then
			Notify("Config", "Autoloaded '" .. AutoloadName .. "'", "Success")
		end
	end
	RunAutoExecute()
end)

Notify("AntiGodHub", "Script loaded", "Success")
