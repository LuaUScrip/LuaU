--[[
	AntiGodHub — Farm Script (FIXED)
	Logic: Auto Farm Wins (W1/W2) / Auto Rebirth / Auto Spin Wheels / Trails / Auras / Equipment.
	Same structure as the original. Remotes live under ReplicatedStorage.Remote.
--]]

-- ===== Load Obsidian GUI Library =====
local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library

pcall(function()
	Library = loadstring(game:HttpGet(LibraryURL))()
end)

if not Library then
	warn("ERROR: Failed to load library")
	return
end

-- ===== Services =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Track character respawns
Player.CharacterAdded:Connect(function(NewCharacter)
	Character = NewCharacter
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Session timer
local SessionStart = tick()

-- ===== Configuration =====
local Config = {
	AutoFarmWins = false,
	FarmWorld = "W1",
	AutoRebirth = false,
	AutoSpinWheels = false,
	AutoBuyEquipTrail = false,
	AutoBuyEquipAura = false,
	AutoBuyEquipment = false,
	AutoEquipBestEquipment = false,
	AutoSave = false,
	AutoExecute = false,
	AutoReconnect = false,
	AutoHideUi = false,
	AntiAfk = false,
	NoGameplayPaused = false,
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
	DiscordLink = "https://discord.gg/jdJvZm6VdK",
	YouTubeLink = "https://youtube.com/@antigodhub",
	TikTokLink = "https://tiktok.com/@antigodhub",
}

local SettingsRefs = {}
local SuppressUI = false

-- ===== Executor Detection =====
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

-- ===== Utility Functions =====
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

local function Teleport(Position)
	if not HumanoidRootPart or not HumanoidRootPart.Parent then
		return false
	end
	HumanoidRootPart.CFrame = CFrame.new(Position + Vector3.new(0, 3, 0))
	RunService.RenderStepped:Wait()
	return true
end

-- ===== Remotes =====
-- Remote layout: ReplicatedStorage.Remote.<Group>.<Name>
local function GetRemote(Group, Name)
	local RemoteFolder = ReplicatedStorage:FindFirstChild("Remote")
	if not RemoteFolder then return nil end
	local GroupFolder = RemoteFolder:FindFirstChild(Group)
	if not GroupFolder then return nil end
	return GroupFolder:FindFirstChild(Name)
end

-- ===== World Configuration =====
local WorldConfig = {
	W1 = {
		RewardPath = "Reward",
		RewardIndex = "14",
		Display = "World 1",
	},
	W2 = {
		RewardPath = "Reward_World2",
		RewardIndex = "11",
		Display = "World 2",
	},
}

-- Farm wins: touch the reward part based on selected world
local function FarmWins()
	pcall(function()
		local World = WorldConfig[Config.FarmWorld]
		if not World then return end

		local Rewards = Workspace:FindFirstChild(World.RewardPath)
		local Normal = Rewards and Rewards:FindFirstChild("Normal")
		local RewardIndex = Normal and Normal:FindFirstChild(World.RewardIndex)
		local Part = RewardIndex and RewardIndex:FindFirstChild("Part")
		if not Part then return end

		Teleport(Part.Position)
		task.wait(0.4)

		local Char = Player.Character
		if Char then
			touchinterest(Part, Char, 0)
			task.wait(0.3)
			touchinterest(Part, Char, 1)
		end
	end)
end

local function Rebirth()
	pcall(function()
		local Event = GetRemote("Rebirth", "RequestRebirth")
		if Event then
			Event:InvokeServer()
		end
	end)
end

local function SpinWheels()
	pcall(function()
		local Event = GetRemote("Spin", "RequestSpin")
		if Event then
			Event:InvokeServer()
		end
	end)
end

-- Unlock + equip every trail (list 1-10)
local function BuyEquipTrail()
	pcall(function()
		local Unlock = GetRemote("Trail", "RequestWinUnlock")
		local Equip = GetRemote("Trail", "RequestToggleEquip")
		if not Unlock or not Equip then return end
		for i = 1, 10 do
			Unlock:InvokeServer(tostring(i))
			task.wait(0.1)
			Equip:InvokeServer(tostring(i))
			task.wait(0.1)
		end
	end)
end

-- Unlock + equip every aura (list 1-10)
local function BuyEquipAura()
	pcall(function()
		local Unlock = GetRemote("Aura", "RequestWinUnlock")
		local Equip = GetRemote("Aura", "RequestToggleEquip")
		if not Unlock or not Equip then return end
		for i = 1, 10 do
			Unlock:InvokeServer(tostring(i))
			task.wait(0.1)
			Equip:InvokeServer(tostring(i))
			task.wait(0.1)
		end
	end)
end

-- Buy every equipment (list 1-3)
local function BuyEquipment()
	pcall(function()
		local Purchase = GetRemote("Equipment", "PurchaseWithWin")
		if not Purchase then return end
		for i = 1, 3 do
			Purchase:InvokeServer(i)
			task.wait(0.1)
		end
	end)
end

local function EquipBestEquipment()
	pcall(function()
		local Event = GetRemote("Equipment", "EquipBest")
		if Event then
			Event:InvokeServer()
		end
	end)
end

-- ===== Theme Manager =====
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

-- ===== Config Save / Load =====
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
			FarmWorld = Config.FarmWorld,
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

	if type(Data.FarmWorld) == "string" and WorldConfig[Data.FarmWorld] then
		Config.FarmWorld = Data.FarmWorld
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
	if SettingsRefs.FarmWorldDropdown then
		SettingsRefs.FarmWorldDropdown:SetValue(Config.FarmWorld)
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

-- ===== Auto Feature Loops =====
local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local AutoFarm = Library.Toggles.AutoFarmWins
			if AutoFarm and not AutoFarm.Value then
				AutoFarm:SetValue(true)
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

-- Anti-AFK idle response
Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

-- ===== Create Window =====
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

-- Draggable buttons
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
	Farming = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" }),
	Upgrades = Tabs.Main:AddSubTab({ Name = "Upgrades", Icon = "trending-up" }),
	Shop = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" }),
}

-- ===== Info Tab =====
local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "activity")

StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()

local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0h 0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "refresh-cw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a">Last Updated 8/23/2026</font>' })

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
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Farm Wins</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Rebirth</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Spin Wheels</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Buy & Equip Trails</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Buy & Equip Auras</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Buy Equipment</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Equip Best Equipment</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Theme Manager</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Config System</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ Auto Features</font>' })

-- ===== Main Tab > Farming =====
local FarmBox = MainTabs.Farming:AddLeftGroupbox("Farming", "star")

-- World selector dropdown
local FarmWorldDropdown = FarmBox:AddDropdown("FarmWorld", {
	Text = "Select Farm World",
	Values = { "W1", "W2" },
	Default = Config.FarmWorld,
	Callback = function(Value)
		Config.FarmWorld = Value
		if not SuppressUI then
			Notify("Farm World", "Switched to " .. WorldConfig[Value].Display, "Success")
			ScheduleSave()
		end
	end,
})
SettingsRefs.FarmWorldDropdown = FarmWorldDropdown

FarmBox:AddDivider()

AddFeatureToggle(FarmBox, "AutoFarmWins", {
	Text = "Auto Farm Wins",
	Tooltip = "farm",
	Notify = true,
}, function(Value)
	Config.AutoFarmWins = Value
	if Value then
		task.spawn(function()
			while Config.AutoFarmWins do
				FarmWins()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoRebirth", {
	Text = "Auto Rebirth",
	Tooltip = "Request rebirth",
	Notify = true,
}, function(Value)
	Config.AutoRebirth = Value
	if Value then
		task.spawn(function()
			while Config.AutoRebirth do
				Rebirth()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoSpinWheels", {
	Text = "Auto Spin Wheels",
	Tooltip = "Request wheel spin",
	Notify = true,
}, function(Value)
	Config.AutoSpinWheels = Value
	if Value then
		task.spawn(function()
			while Config.AutoSpinWheels do
				SpinWheels()
				task.wait(0.1)
			end
		end)
	end
end)

-- Quick actions
local QuickBox = MainTabs.Farming:AddRightGroupbox("Quick Actions", "zap")

QuickBox:AddButton({
	Text = "Farm Wins",
	Func = function()
		FarmWins()
		Notify("Action", "Farming wins on " .. WorldConfig[Config.FarmWorld].Display, "Info")
	end,
})

QuickBox:AddButton({
	Text = "Rebirth",
	Func = function()
		Rebirth()
		Notify("Action", "Rebirth initiated", "Info")
	end,
})

QuickBox:AddButton({
	Text = "Spin Wheel",
	Func = function()
		SpinWheels()
		Notify("Action", "Spinning wheel", "Info")
	end,
})

-- ===== Main Tab > Upgrades =====
local TrailBox = MainTabs.Upgrades:AddLeftGroupbox("Trails", "sparkles")

AddFeatureToggle(TrailBox, "AutoBuyEquipTrail", {
	Text = "Auto Buy & Equip Trail",
	Tooltip = "Unlock + equip all trails (1-10)",
	Notify = true,
}, function(Value)
	Config.AutoBuyEquipTrail = Value
	if Value then
		task.spawn(function()
			while Config.AutoBuyEquipTrail do
				BuyEquipTrail()
				task.wait(0.1)
			end
		end)
	end
end)

local AuraBox = MainTabs.Upgrades:AddRightGroupbox("Auras", "arrow-up")

AddFeatureToggle(AuraBox, "AutoBuyEquipAura", {
	Text = "Auto Buy & Equip Aura",
	Tooltip = "Unlock + equip all auras (1-10)",
	Notify = true,
}, function(Value)
	Config.AutoBuyEquipAura = Value
	if Value then
		task.spawn(function()
			while Config.AutoBuyEquipAura do
				BuyEquipAura()
				task.wait(0.1)
			end
		end)
	end
end)

-- ===== Main Tab > Shop =====
local EquipmentBox = MainTabs.Shop:AddLeftGroupbox("Equipment", "shopping-bag")

AddFeatureToggle(EquipmentBox, "AutoBuyEquipment", {
	Text = "Auto Buy Equipment",
	Tooltip = "Buy all equipment (1-3)",
	Notify = true,
}, function(Value)
	Config.AutoBuyEquipment = Value
	if Value then
		task.spawn(function()
			while Config.AutoBuyEquipment do
				BuyEquipment()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(EquipmentBox, "AutoEquipBestEquipment", {
	Text = "Auto Equip Best Equipment",
	Tooltip = "Equip best equipment",
	Notify = true,
}, function(Value)
	Config.AutoEquipBestEquipment = Value
	if Value then
		task.spawn(function()
			while Config.AutoEquipBestEquipment do
				EquipBestEquipment()
				task.wait(0.1)
			end
		end)
	end
end)

-- Shop quick actions
local ShopQuickBox = MainTabs.Shop:AddRightGroupbox("Quick Actions", "zap")

ShopQuickBox:AddButton({
	Text = "Buy All Equipment",
	Func = function()
		BuyEquipment()
		Notify("Action", "Buying equipment", "Info")
	end,
})

ShopQuickBox:AddButton({
	Text = "Equip Best Equipment",
	Func = function()
		EquipBestEquipment()
		Notify("Action", "Equipping best", "Info")
	end,
})

-- ===== Settings Tab =====
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

-- Menu settings
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
		Config.AutoFarmWins = false
		Config.AutoRebirth = false
		Config.AutoSpinWheels = false
		Config.AutoBuyEquipTrail = false
		Config.AutoBuyEquipAura = false
		Config.AutoBuyEquipment = false
		Config.AutoEquipBestEquipment = false
		for Id, Toggle in Library.Toggles do
			if Toggle.Value then
				Toggle:SetValue(false)
			end
		end
		Notify("Stop", "All features stopped", "Warning")
	end,
	Risky = true
})

-- ===== Config System =====
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

-- ===== Startup =====
-- Apply theme on startup
ApplyTheme(Themes[Config.ThemeName])

-- Autoload on startup
task.delay(1, function()
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

Notify("AntiGodHub", "Script loaded!", "Success")