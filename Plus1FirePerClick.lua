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

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Upgrades List
local UpgradesList = {
	"SpeedUpgrade",
	"PetLuck",
	"PetSlot",
	"TitleLuck",
}

-- Configuration
local Config = {
	HomePosition = Vector3.new(198, 3, 280),
	WinPadPosition = Vector3.new(25, 5, 2511),
	FarmWinsActive = false,
	FarmLevelActive = false,
	RebirthActive = false,
	RollTitleActive = false,
	UpgradeActive = false,
	BuyEggActive = false,
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

-- Helpers
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
		if type(Title) == "string" and #Title > 60 then Title = Title:sub(1, 57) .. "..." end
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

local function GetWinPad()
	local success, result = pcall(function()
		return Workspace.WinPads.StageWinPad_25
	end)
	return success and result or nil
end

local function Teleport(Position)
	if not HumanoidRootPart or not HumanoidRootPart.Parent then return false end
	HumanoidRootPart.CFrame = CFrame.new(Position + Vector3.new(0, 0, 0))
	task.wait()
	return true
end

local function TouchPad(Pad)
	if not Pad or not HumanoidRootPart or not HumanoidRootPart.Parent then return false end
	pcall(function()
		firetouchinterest(HumanoidRootPart, Pad, 0)
		task.wait(0.1)
		firetouchinterest(HumanoidRootPart, Pad, 1)
	end)
	return true
end

-- Core Actions
local function FarmWins()
	if not HumanoidRootPart or not HumanoidRootPart.Parent then return end
	pcall(function()
		Teleport(Config.WinPadPosition)
		task.wait(0.3)
		local Pad = GetWinPad()
		if Pad then TouchPad(Pad) end
	end)
end

local function FarmLevel()
	pcall(function()
		local Event = ReplicatedStorage:WaitForChild("FireEvents"):WaitForChild("AddPower")
		Event:FireServer()
	end)
end

local function DoRebirth()
	pcall(function()
		local Event = ReplicatedStorage:WaitForChild("FireEvents"):WaitForChild("DoRebirth")
		Event:FireServer()
	end)
end

local function RollTitle()
	pcall(function()
		local Event = ReplicatedStorage:WaitForChild("TitleRemotes"):WaitForChild("RollTitle")
		Event:InvokeServer("Normal")
	end)
end

local function BuyUpgrade(UpgradeName)
	pcall(function()
		local Event = ReplicatedStorage:WaitForChild("ShopEvents"):WaitForChild("BuyUpgrade")
		Event:FireServer("list", UpgradeName, "wins")
	end)
end

local function BuyAllUpgrades()
	for _, UpgradeName in UpgradesList do
		BuyUpgrade(UpgradeName)
		task.wait(0.01)
	end
end

local function BuyBestEgg()
	pcall(function()
		local Event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Eggs"):WaitForChild("BuyEgg")
		local EggModule = ReplicatedStorage:WaitForChild("Resources"):WaitForChild("Eggs"):WaitForChild("Molten")
		Event:InvokeServer(EggModule)
	end)
end

-- Theme System
local function MakeTheme(Accent, Background, Main, Outline, Font)
	return { AccentColor = Accent, BackgroundColor = Background, MainColor = Main, OutlineColor = Outline, FontColor = Font }
end

local Themes = {
	["Obsidian (Default)"] = MakeTheme(Color3.fromRGB(125, 85, 255), Color3.fromRGB(15, 15, 15), Color3.fromRGB(25, 25, 25), Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 255)),
	["Midnight Blue"] = MakeTheme(Color3.fromRGB(96, 165, 255), Color3.fromRGB(8, 10, 16), Color3.fromRGB(18, 22, 32), Color3.fromRGB(38, 46, 64), Color3.fromRGB(255, 255, 255)),
	["Blood Red"] = MakeTheme(Color3.fromRGB(255, 76, 76), Color3.fromRGB(16, 8, 8), Color3.fromRGB(28, 14, 14), Color3.fromRGB(64, 30, 30), Color3.fromRGB(255, 255, 255)),
	["Emerald Green"] = MakeTheme(Color3.fromRGB(96, 216, 118), Color3.fromRGB(8, 16, 10), Color3.fromRGB(16, 28, 20), Color3.fromRGB(30, 58, 40), Color3.fromRGB(255, 255, 255)),
	["Sunset Orange"] = MakeTheme(Color3.fromRGB(255, 148, 60), Color3.fromRGB(18, 12, 8), Color3.fromRGB(32, 22, 12), Color3.fromRGB(64, 46, 26), Color3.fromRGB(255, 255, 255)),
}

local ThemeNames = {}
for Name in Themes do table.insert(ThemeNames, Name) end

local function CloneColors(Scheme)
	local Clone = {}
	for Key, Value in Scheme do Clone[Key] = Value end
	return Clone
end

local function ApplyTheme(Scheme)
	for Key, Value in Scheme do
		if Library.Scheme[Key] ~= nil then Library.Scheme[Key] = Value end
	end
	Library:UpdateColorsUsingRegistry()
end

local function ApplyColorOverride(Key, Color)
	if Library.Scheme[Key] ~= nil then Library.Scheme[Key] = Color Library:UpdateColorsUsingRegistry() end
end

local function ApplyCustomColors()
	for Key, Color in Config.CustomColors do ApplyColorOverride(Key, Color) end
end

local FontNames = { "Code", "Gotham", "Roboto", "Cartoon", "Arial", "SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito" }

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
for _, Preset in FontPresets do table.insert(FontPresetNames, Preset.Name) end

-- Config Save/Load
local ConfigsDir = "HubConfigs/Configs"
local AutoloadPath = "HubConfigs/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(Name)
	if type(Name) ~= "string" then return nil end
	local Clean = Name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if Clean == "" or Clean == "---" then return nil end
	return Clean
end

local function ConfigPath(Name) return ConfigsDir .. "/" .. Name .. ".json" end

local function GetConfigList()
	local List = {}
	if not listfiles then return List end
	pcall(function()
		makefolder("HubConfigs") makefolder(ConfigsDir)
		for _, Path in listfiles(ConfigsDir) do
			if Path:sub(-5) == ".json" then
				local Name = Path:match("([^/\\]+)%.json$")
				if Name and Name ~= "---" then table.insert(List, Name) end
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
		makefolder("HubConfigs") makefolder(ConfigsDir)
		local Data = { Toggles = {}, ThemeName = Config.ThemeName, FontName = Config.FontName, FontPreset = Config.FontPreset, MenuBind = Config.MenuBind, Colors = {} }
		for Key, Color in Config.CustomColors do
			Data.Colors[Key] = { math.floor(Color.R * 255), math.floor(Color.G * 255), math.floor(Color.B * 255) }
		end
		for Id, Toggle in Library.Toggles do Data.Toggles[Id] = Toggle.Value end
		writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
	end)
	return true
end

local function GetAutoloadName()
	if not isfile or not readfile then return nil end
	if not isfile(AutoloadPath) then return nil end
	local Success, Data = pcall(function() return HttpService:JSONDecode(readfile(AutoloadPath)) end)
	if Success and type(Data) == "table" and type(Data.Name) == "string" then return SanitizeConfigName(Data.Name) end
	return nil
end

local function SetAutoload(Name)
	if not writefile then return false end
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	pcall(function() makefolder("HubConfigs") writefile(AutoloadPath, HttpService:JSONEncode({ Name = Name })) end)
	return true
end

local function ClearAutoload()
	pcall(function() if isfile and isfile(AutoloadPath) then delfile(AutoloadPath) end end)
	return true
end

local LoadConfig
local SaveQueued = false
local function ScheduleSave()
	if not Config.AutoSave or not CurrentConfig or SaveQueued then return end
	SaveQueued = true
	task.delay(1, function() SaveQueued = false SaveConfigData(CurrentConfig) end)
end

local function SyncColorPickers()
	local PickerMap = { AccentColor = "ThemeAccent", FontColor = "ThemeFontColor", BackgroundColor = "ThemeBackground", MainColor = "ThemeMain", OutlineColor = "ThemeOutline" }
	for Key, Idx in PickerMap do
		local Picker = Library.Options[Idx]
		if Picker and Picker.SetValueRGB then Picker:SetValueRGB(Config.CustomColors[Key]) end
	end
end

LoadConfig = function(Name, Silent)
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	if not isfile or not readfile then if not Silent then Notify("Config", "Not supported", "Error") end return false end
	if not isfile(ConfigPath(Name)) then if not Silent then Notify("Config", "Config not found", "Warning") end return false end

	local Success, Data = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath(Name))) end)
	if not Success or type(Data) ~= "table" then if not Silent then Notify("Config", "Failed to read", "Error") end return false end

	SuppressUI = true

	if type(Data.ThemeName) == "string" and Themes[Data.ThemeName] then Config.ThemeName = Data.ThemeName ApplyTheme(Themes[Data.ThemeName]) end
	if type(Data.Colors) == "table" then
		for Key, RGB in Data.Colors do
			if Config.CustomColors[Key] ~= nil and type(RGB) == "table" then
				local R, G, B = RGB[1], RGB[2], RGB[3]
				if type(R) == "number" and type(G) == "number" and type(B) == "number" then Config.CustomColors[Key] = Color3.fromRGB(R, G, B) end
			end
		end
		ApplyCustomColors()
	end
	if type(Data.FontName) == "string" and Enum.Font[Data.FontName] then Config.FontName = Data.FontName Library:SetFont(Enum.Font[Data.FontName]) end
	if type(Data.FontPreset) == "string" then
		for _, Preset in FontPresets do if Preset.Name == Data.FontPreset then Config.FontPreset = Preset.Name break end end
	end
	if type(Data.MenuBind) == "string" and Data.MenuBind ~= "None" then Config.MenuBind = Data.MenuBind end
	if type(Data.Toggles) == "table" then
		for Id, Value in Data.Toggles do
			local Toggle = Library.Toggles[Id]
			if Toggle and type(Value) == "boolean" then Toggle:SetValue(Value) end
		end
	end

	if SettingsRefs.ThemeDropdown then SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName) end
	if SettingsRefs.FontDropdown then SettingsRefs.FontDropdown:SetValue(Config.FontName) end
	if SettingsRefs.FontPresetDropdown then SettingsRefs.FontPresetDropdown:SetValue(Config.FontPreset) end
	SyncColorPickers()
	if SettingsRefs.MenuBindPicker then SettingsRefs.MenuBindPicker:SetValue({ Config.MenuBind, "Press" }) end

	SuppressUI = false
	CurrentConfig = Name
	return true
end

local function AddFeatureToggle(Box, Id, Info, OnToggle)
	return Box:AddToggle(Id, {
		Text = Info.Text, Default = false, Tooltip = Info.Tooltip,
		Callback = function(Value)
			if OnToggle then OnToggle(Value) end
			if Info.Notify and not SuppressUI then
				Notify(Info.Text .. " " .. (Value and "On" or "Off"), "", Value and "Success" or "Warning")
			end
			ScheduleSave()
		end,
	})
end

-- Auto Features
local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local AF = Library.Toggles.AutoFarmWins
			if AF and not AF.Value then AF:SetValue(true) end
		end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do
			task.wait(0.5)
			pcall(function()
				local RG = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				local DF = RG and RG:FindFirstChild("DisconnectedFrame")
				if DF and DF.Visible then TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer) end
			end)
		end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local OpenFor = 0
		while Config.AutoHideUi do
			task.wait(1)
			if Library.Toggled then OpenFor = OpenFor + 1 if OpenFor >= 30 then Library:Toggle(false) OpenFor = 0 end
			else OpenFor = 0 end
		end
	end)
end

local function AntiAfkLoop()
	task.spawn(function()
		while Config.AntiAfk do
			task.wait(600)
			pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
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
				if HRP then HRP.AssemblyLinearVelocity = HRP.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0) end
			end)
		end
	end)
end

Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end
end)

-- Window
local Window = Library:CreateWindow({
	Title = "AntiGodHub", Icon = 125265885440515,
	Footer = {
		{ Text = "Discord", Copyable = true, OnClick = function() CopyToClipboard(Config.DiscordLink) end },
		{ Text = " | " },
		{ Text = "AntiGodHub", Copyable = true },
	},
	CornerRadius = 20, AutoShow = true, ShowMobileButtons = false, Minimizable = true, Resizable = true,
	Animations = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true },
})

Library.ToggleKeybind = nil

local ToggleButton = Library:AddDraggableButton("Toggle", function() Library:Toggle() end, true, true)
local LockButton = Library:AddDraggableButton("Lock", function(self) Library.CantDragForced = not Library.CantDragForced self:SetText(Library.CantDragForced and "Unlock" or "Lock") end, true, true)
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

local FarmingTab = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" })

-- Info Tab
local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")
StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

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
			if Version ~= nil and tostring(Version) ~= "" then ExecutorVersion = tostring(Version) end
		end
	elseif getexecutorname then ExecutorName = tostring(getexecutorname()) end
	if ExecutorVersion == "Unknown" then pcall(function() if getexecutorversion then ExecutorVersion = tostring(getexecutorversion()) end end) end
end)

local ExecutorDisplay = ExecutorName
if ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" then ExecutorDisplay = ExecutorName .. " " .. ExecutorVersion end
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/22/2026</font>' })

local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local Green = "#60d888"
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })
local JobId = tostring(game.JobId)
local ShortJobId = #JobId > 18 and JobId:sub(1, 18) .. "..." or JobId
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. ShortJobId .. '</font>' })

task.spawn(function()
	local Success, Info = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId) end)
	if Success and Info and Info.Name then
		pcall(function()
			local CleanName = tostring(Info.Name):gsub("[^%z\1-\127]", "")
			GameNameLabel:SetText('GAME - <font color="#60d888">' .. CleanName .. '</font>')
		end)
	else pcall(function() GameNameLabel:SetText('GAME - <font color="#60d888">Unknown</font>') end) end
end)

local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local Elapsed = os.clock() - ScriptStartTime
		pcall(function() SessionLabel:SetText('SESSION - <font color="#60d888">' .. math.floor(Elapsed / 60) .. 'm ' .. math.floor(Elapsed % 60) .. 's</font>') end)
		task.wait(1)
	end
end)

InfoGameBox:AddButton({ Text = "Copy Place ID", Func = function() CopyToClipboard(tostring(game.PlaceId)) end, Tooltip = "Copy Place ID" })
InfoGameBox:AddButton({ Text = "Copy Join Script", Func = function()
	CopyToClipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)', game.PlaceId, JobId))
end, Tooltip = "Copy Join Script" })

local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")
SocialsBox:AddButton({ Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) end, Tooltip = "Discord" })
SocialsBox:AddButton({ Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) end, Tooltip = "YouTube" })
SocialsBox:AddButton({ Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) end, Tooltip = "TikTok" })

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Farm Wins</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Farm Level</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Rebirth</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Roll Title</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy All Upgrades</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Theme Manager</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Config Autoload</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Execute Script</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Reconnect</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Hide UI</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Anti AFK</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">No Gameplay Paused</font>' })

-- Main > Farming
local FarmGroup = FarmingTab:AddLeftGroupbox("Farming", "star")

AddFeatureToggle(FarmGroup, "AutoFarmWins", {
	Text = "Auto Farm Wins",
	Tooltip = "Teleport to Win Pad and touch it",
	Notify = true,
}, function(Value)
	Config.FarmWinsActive = Value
	if Value then
		task.spawn(function()
			while Config.FarmWinsActive do
				FarmWins()
				task.wait(1.5)
			end
		end)
	end
end)

AddFeatureToggle(FarmGroup, "AutoFarmLevel", {
	Text = "Auto Farm Level",
	Tooltip = "Spam AddPower remote",
	Notify = true,
}, function(Value)
	Config.FarmLevelActive = Value
	if Value then
		task.spawn(function()
			while Config.FarmLevelActive do
				FarmLevel()
				task.wait(0.0000001)
			end
		end)
	end
end)

AddFeatureToggle(FarmGroup, "AutoRebirth", {
	Text = "Auto Rebirth",
	Tooltip = "Auto Rebirth",
	Notify = true,
}, function(Value)
	Config.RebirthActive = Value
	if Value then
		task.spawn(function()
			while Config.RebirthActive do
				DoRebirth()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(FarmGroup, "AutoRollTitle", {
	Text = "Auto Roll Title",
	Tooltip = "Spam Roll Title remote",
	Notify = true,
}, function(Value)
	Config.RollTitleActive = Value
	if Value then
		task.spawn(function()
			while Config.RollTitleActive do
				RollTitle()
				task.wait(0.0000001)
			end
		end)
	end
end)


AddFeatureToggle(FarmGroup, "AutoUpgrades", {
	Text = "Auto Buy All Upgrades",
	Tooltip = "Auto buy SpeedUpgrade, PetLuck, PetSlot, TitleLuck",
	Notify = true,
}, function(Value)
	Config.UpgradeActive = Value
	if Value then
		task.spawn(function()
			while Config.UpgradeActive do
				BuyAllUpgrades()
				task.wait(0.001)
			end
		end)
	end
end)


-- Settings > Theme Manager
local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme", Values = ThemeNames, Default = Config.ThemeName,
	Callback = function(Value)
		Config.ThemeName = Value ApplyTheme(Themes[Value])
		if not SuppressUI then Config.CustomColors = CloneColors(Themes[Value]) SyncColorPickers() Notify("Theme", "Theme set to " .. Value, "Success") ScheduleSave() end
	end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

ThemeBox:AddDivider()
ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", { Default = Config.CustomColors.AccentColor, Title = "Accent Color", Callback = function(Color) Config.CustomColors.AccentColor = Color ApplyColorOverride("AccentColor", Color) ScheduleSave() end })
ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", { Default = Config.CustomColors.FontColor, Title = "Font Color", Callback = function(Color) Config.CustomColors.FontColor = Color ApplyColorOverride("FontColor", Color) ScheduleSave() end })
ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", { Default = Config.CustomColors.BackgroundColor, Title = "Background Color", Callback = function(Color) Config.CustomColors.BackgroundColor = Color ApplyColorOverride("BackgroundColor", Color) ScheduleSave() end })
ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", { Default = Config.CustomColors.MainColor, Title = "Main Color", Callback = function(Color) Config.CustomColors.MainColor = Color ApplyColorOverride("MainColor", Color) ScheduleSave() end })
ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", { Default = Config.CustomColors.OutlineColor, Title = "Outline Color", Callback = function(Color) Config.CustomColors.OutlineColor = Color ApplyColorOverride("OutlineColor", Color) ScheduleSave() end })

ThemeBox:AddDivider()

local FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font", Values = FontNames, Default = Config.FontName,
	Callback = function(Value) Config.FontName = Value Library:SetFont(Enum.Font[Value]) if not SuppressUI then ScheduleSave() end end,
})
SettingsRefs.FontDropdown = FontDropdown

local FontPresetDropdown = ThemeBox:AddDropdown("FontPreset", {
	Text = "Font Color Preset", Values = FontPresetNames, Default = Config.FontPreset, Visible = false,
	Callback = function(Value)
		Config.FontPreset = Value
		for _, Preset in FontPresets do
			if Preset.Name == Value then Config.CustomColors.FontColor = Color3.fromRGB(255, 255, 255) Config.CustomColors.AccentColor = Preset.Accent ApplyColorOverride("FontColor", Color3.fromRGB(255, 255, 255)) ApplyColorOverride("AccentColor", Preset.Accent) SyncColorPickers() break end
		end
		if not SuppressUI then ScheduleSave() end
	end,
})
SettingsRefs.FontPresetDropdown = FontPresetDropdown

ThemeBox:AddButton({ Text = "Reset Theme", Func = function()
	Config.ThemeName = "Emerald Green" Config.FontPreset = "White + Emerald"
	Config.CustomColors = CloneColors(Themes["Emerald Green"]) ApplyTheme(Themes["Emerald Green"])
	ThemeDropdown:SetValue("Emerald Green") FontPresetDropdown:SetValue("White + Emerald") SyncColorPickers()
	Notify("Theme", "Theme reset to Emerald Green", "Info") ScheduleSave()
end })

-- Settings > Menu Group
local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Group", "menu")

MenuBox:AddLabel("Menu Bind"):AddKeyPicker("MenuBind", {
	Default = Config.MenuBind, Mode = "Press", Text = "Toggle UI",
	Callback = function() Library:Toggle() end,
	ChangedCallback = function(NewKey) if typeof(NewKey) == "EnumItem" then Config.MenuBind = NewKey.Name end ScheduleSave() end,
})
SettingsRefs.MenuBindPicker = Library.Options.MenuBind

MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", { Text = "Auto Execute Script", Tooltip = "Auto Execute Script" }, function(Value) Config.AutoExecute = Value if Value then RunAutoExecute() end end)
AddFeatureToggle(MenuBox, "AutoReconnect", { Text = "Auto Reconnect to Game", Tooltip = "Auto Reconnect to Game" }, function(Value) Config.AutoReconnect = Value if Value then AutoReconnectLoop() end end)
AddFeatureToggle(MenuBox, "AutoHideUi", { Text = "Auto Hide UI", Tooltip = "Auto Hide UI" }, function(Value) Config.AutoHideUi = Value if Value then AutoHideUiLoop() end end)
AddFeatureToggle(MenuBox, "AntiAfk", { Text = "Anti AFK", Tooltip = "Anti AFK" }, function(Value) Config.AntiAfk = Value if Value then AntiAfkLoop() end end)
AddFeatureToggle(MenuBox, "NoGameplayPaused", { Text = "No Gameplay Paused", Tooltip = "No Gameplay Paused" }, function(Value) Config.NoGameplayPaused = Value if Value then NoPauseLoop() end end)

MenuBox:AddDivider()

MenuBox:AddButton({ Text = "Stop All Features", Func = function()
	Config.FarmWinsActive = false Config.FarmLevelActive = false Config.RebirthActive = false Config.RollTitleActive = false Config.UpgradeActive = false Config.BuyEggActive = false
	Config.AutoReconnect = false Config.AutoHideUi = false Config.AntiAfk = false Config.NoGameplayPaused = false
	for Id, Toggle in Library.Toggles do if Toggle.Value then Toggle:SetValue(false) end end
	Notify("Script", "All features stopped", "Warning")
end, Risky = true })

-- Settings > Configuration
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")
local RefreshConfigList

local ConfigNameInput = ConfigBox:AddInput("ConfigName", { Text = "Config name", Placeholder = "Type a config name...", ClearTextOnFocus = true })

ConfigBox:AddButton({ Text = "Create config", Func = function()
	local Name = SanitizeConfigName(ConfigNameInput.Value)
	if not Name then Notify("Config", "Enter a valid name", "Warning") return end
	if ConfigExists(Name) then Notify("Config", "'" .. Name .. "' already exists", "Warning") return end
	if SaveConfigData(Name) then CurrentConfig = Name RefreshConfigList(Name) Notify("Config", "Config created", "Success")
	else Notify("Config", "Not supported", "Error") end
end, Tooltip = "Create config" })

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", { Text = "Config list", Values = { "---" }, Default = "---", Callback = function(Value) CurrentConfig = Value == "---" and nil or Value end })
SettingsRefs.ConfigListDropdown = ConfigListDropdown

local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Current autoload config: <font color="#60d888">none</font>' })

RefreshConfigList = function(SelectName)
	local Values = { "---" }
	for _, Name in GetConfigList() do table.insert(Values, Name) end
	ConfigListDropdown:SetValues(Values)
	local Choice = SelectName or CurrentConfig or "---"
	if not table.find(Values, Choice) then Choice = "---" end
	ConfigListDropdown:SetValue(Choice)
	CurrentConfig = Choice == "---" and nil or Choice
end

local function UpdateAutoloadLabel()
	local Name = GetAutoloadName()
	local Text = 'Current autoload config: <font color="#60d888">none</font>'
	if Name then Text = 'Current autoload config: <font color="#60d888">' .. Name .. '</font>' end
	AutoloadLabel:SetText(Text)
end

ConfigBox:AddButton({ Text = "Load config", Func = function()
	local Name = CurrentConfig if not Name then Notify("Config", "Select a config first", "Warning") return end
	if LoadConfig(Name, false) then Notify("Config", "Config loaded", "Success") end
end, Tooltip = "Load config" })

ConfigBox:AddButton({ Text = "Overwrite config", Func = function()
	local Name = CurrentConfig if not Name then Notify("Config", "Select a config first", "Warning") return end
	if SaveConfigData(Name) then Notify("Config", "Config overwritten", "Success") else Notify("Config", "Not supported", "Error") end
end, Tooltip = "Overwrite config" })

ConfigBox:AddButton({ Text = "Delete config", Func = function()
	local Name = CurrentConfig if not Name then Notify("Config", "Select a config first", "Warning") return end
	pcall(function() delfile(ConfigPath(Name)) end)
	if GetAutoloadName() == Name then ClearAutoload() end
	CurrentConfig = nil RefreshConfigList() UpdateAutoloadLabel()
	Notify("Config", "Config deleted", "Warning")
end, Tooltip = "Delete config", Risky = true })

ConfigBox:AddButton({ Text = "Refresh list", Func = function() RefreshConfigList() Notify("Config", "List refreshed", "Info") end, Tooltip = "Refresh list" })

ConfigBox:AddButton({ Text = "Set as autoload", Func = function()
	local Name = CurrentConfig if not Name then Notify("Config", "Select a config first", "Warning") return end
	if SetAutoload(Name) then UpdateAutoloadLabel() Notify("Config", "Autoload set", "Success") end
end, Tooltip = "Set as autoload" })

ConfigBox:AddButton({ Text = "Reset autoload", Func = function() ClearAutoload() UpdateAutoloadLabel() Notify("Config", "Autoload cleared", "Info") end, Tooltip = "Reset autoload" })

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", { Text = "Auto Save Config", Tooltip = "Auto Save Config" }, function(Value) Config.AutoSave = Value end)

-- Init
ApplyTheme(Themes[Config.ThemeName])

task.delay(1, function()
	local AutoloadName = GetAutoloadName()
	if AutoloadName and ConfigExists(AutoloadName) then
		CurrentConfig = AutoloadName
		if LoadConfig(AutoloadName, true) then Notify("Config", "Autoloaded '" .. AutoloadName .. "'", "Success") end
	end
	RunAutoExecute()
end)

Notify("AntiGodHub", "Script loaded", "Success")