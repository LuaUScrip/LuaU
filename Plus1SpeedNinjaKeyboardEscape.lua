-- ============================================================
-- AntiGodHub - Fixed Working Script
-- ============================================================

local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()
if not Library then warn("ERROR: Failed to load library") return end

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
Player.CharacterAdded:Connect(function(c)
	Character = c
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

-- ============================================================
-- Game Data
-- ============================================================

-- Auto-fire proximity prompts
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
	pcall(function()
		fireproximityprompt(prompt)
	end)
end)

-- Win positions
local WinPositions = {
	W1 = CFrame.new(395, 17, -8593, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	W2 = CFrame.new(0, 61, -9013, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	W3 = CFrame.new(186, 475, -12453, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	W4 = CFrame.new(-184, -2670, -36932, 1, 0, 0, 0, 1, 0, 0, 0, 1),
}

-- Remotes
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local RebirthRemote = Net:WaitForChild("RE/Rebirth/Request")
local TrailRemote = Net:WaitForChild("RE/Trails/BuyViaWins")

-- Trail list
local TrailList = { "Green", "Orange", "Blue", "Purple", "Rainbow", "Admin" }

-- W1/W2/W3/W4 Touch parts (lazy load, retry on demand)
local TouchPart = nil
local LastWorld = nil
local function LoadTouchPart(World)
	World = World or "W4"
	if LastWorld ~= World then
		TouchPart = nil
		LastWorld = World
	end
	if TouchPart then return TouchPart end
	pcall(function()
		if World == "W1" then
			local Stage = Workspace:WaitForChild("Stage12", 5)
			if Stage then
				TouchPart = Stage:WaitForChild("EscapeBreach", 5)
			end
		elseif World == "W2" then
			TouchPart = Workspace:WaitForChild("World2", 5)
			if TouchPart then
				TouchPart = TouchPart:WaitForChild("Stage12", 5)
				if TouchPart then
					TouchPart = TouchPart:WaitForChild("EscapeBreach", 5)
				end
			end
		else
			local Stage = Workspace:WaitForChild("Stage12", 5)
			if Stage then
				local Folder = World == "W3" and "Breach" or "Finale"
				local FinalFolder = Stage:WaitForChild(Folder, 5)
				if FinalFolder then
					TouchPart = FinalFolder:WaitForChild("EscapeBreach", 5)
				end
			end
		end
	end)
	return TouchPart
end

-- ============================================================
-- Config
-- ============================================================

local Config = {
	AutoWinsActive = false,
	AutoWinsWorld = "W1",
	AutoRebirthActive = false,
	AutoBuyTrailActive = false,
	AutoSave = false,
	AutoExecute = false,
	AutoReconnect = false,
	AutoHideUi = false,
	AntiAfk = false,
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
-- Helpers
-- ============================================================

local function CopyToClipboard(Text)
	local ok = pcall(setclipboard, Text)
	if not ok then pcall(toclipboard, Text) end
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
		if not Description or Description == "" then
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

local function SafeTeleport(CFramePos)
	if not HumanoidRootPart or not HumanoidRootPart.Parent then
		return false
	end
	HumanoidRootPart.CFrame = CFramePos
	RunService.RenderStepped:Wait()
	return true
end

local function FreezeVelocity()
	if not HumanoidRootPart or not HumanoidRootPart.Parent then return end
	HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	HumanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

-- ============================================================
-- Game Functions
-- ============================================================

local function DoAutoWins()
	if not HumanoidRootPart or not HumanoidRootPart.Parent then return end

	local Pos = WinPositions[Config.AutoWinsWorld]
	if not Pos then return end

	pcall(function()
		FreezeVelocity()
		SafeTeleport(Pos)
		FreezeVelocity()

		-- W1/W2/W3/W4: fire touchinterest on respective parts
		if Config.AutoWinsWorld == "W1" or Config.AutoWinsWorld == "W2" or Config.AutoWinsWorld == "W3" or Config.AutoWinsWorld == "W4" then
			local Part = LoadTouchPart(Config.AutoWinsWorld)
			if Part and firetouchinterest then
				firetouchinterest(HumanoidRootPart, Part, 0)
				task.wait(0.05)
				firetouchinterest(HumanoidRootPart, Part, 1)
			end
		end
	end)
end

local function DoAutoRebirth()
	pcall(function()
		RebirthRemote:FireServer()
	end)
end

local TrailBought = {}
local function DoAutoBuyTrail()
	for _, name in TrailList do
		if not TrailBought[name] then
			TrailBought[name] = true
			pcall(function()
				TrailRemote:FireServer(name)
			end)
		end
		task.wait(0.3)
	end
end

-- ============================================================
-- Themes
-- ============================================================

local function MakeTheme(a, bg, m, o, f)
	return {
		AccentColor = a,
		BackgroundColor = bg,
		MainColor = m,
		OutlineColor = o,
		FontColor = f,
	}
end

local Themes = {
	["Obsidian (Default)"] = MakeTheme(
		Color3.fromRGB(125, 85, 255), Color3.fromRGB(15, 15, 15),
		Color3.fromRGB(25, 25, 25), Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 255)
	),
	["Midnight Blue"] = MakeTheme(
		Color3.fromRGB(96, 165, 255), Color3.fromRGB(8, 10, 16),
		Color3.fromRGB(18, 22, 32), Color3.fromRGB(38, 46, 64), Color3.fromRGB(255, 255, 255)
	),
	["Blood Red"] = MakeTheme(
		Color3.fromRGB(255, 76, 76), Color3.fromRGB(16, 8, 8),
		Color3.fromRGB(28, 14, 14), Color3.fromRGB(64, 30, 30), Color3.fromRGB(255, 255, 255)
	),
	["Emerald Green"] = MakeTheme(
		Color3.fromRGB(96, 216, 118), Color3.fromRGB(8, 16, 10),
		Color3.fromRGB(16, 28, 20), Color3.fromRGB(30, 58, 40), Color3.fromRGB(255, 255, 255)
	),
	["Sunset Orange"] = MakeTheme(
		Color3.fromRGB(255, 148, 60), Color3.fromRGB(18, 12, 8),
		Color3.fromRGB(32, 22, 12), Color3.fromRGB(64, 46, 26), Color3.fromRGB(255, 255, 255)
	),
}

local ThemeNames = {}
for k in Themes do
	table.insert(ThemeNames, k)
end

local function ApplyTheme(s)
	for k, v in s do
		if Library.Scheme[k] ~= nil then
			Library.Scheme[k] = v
		end
	end
	Library:UpdateColorsUsingRegistry()
end

local function ApplyColorOverride(k, c)
	if Library.Scheme[k] ~= nil then
		Library.Scheme[k] = c
		Library:UpdateColorsUsingRegistry()
	end
end

local function SyncColorPickers()
	local map = {
		AccentColor = "ThemeAccent",
		FontColor = "ThemeFontColor",
		BackgroundColor = "ThemeBackground",
		MainColor = "ThemeMain",
		OutlineColor = "ThemeOutline",
	}
	for k, id in map do
		local p = Library.Options[id]
		if p and p.SetValueRGB then
			p:SetValueRGB(Config.CustomColors[k])
		end
	end
end

-- Fonts
local FontNames = {
	"Code", "Gotham", "Roboto", "Cartoon", "Arial",
	"SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito",
}

-- ============================================================
-- Config Save / Load
-- ============================================================

local ConfigsDir = "AutoFarm/Configs"
local AutoloadPath = "AutoFarm/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(Name)
	if type(Name) ~= "string" then return nil end
	local c = Name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):match("^%s*(.-)%s*$")
	return (c == "" or c == "---") and nil or c
end

local function ConfigPath(Name)
	return ConfigsDir .. "/" .. Name .. ".json"
end

local function GetConfigList()
	local list = {}
	if not listfiles then return list end
	pcall(function()
		makefolder("AutoFarm")
		makefolder(ConfigsDir)
		for _, p in listfiles(ConfigsDir) do
			if p:sub(-5) == ".json" then
				local n = p:match("([^/\\]+)%.json$")
				if n and n ~= "---" then
					table.insert(list, n)
				end
			end
		end
	end)
	table.sort(list)
	return list
end

local function SaveConfigData(Name)
	if not writefile then return false end
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	pcall(function()
		makefolder("AutoFarm")
		makefolder(ConfigsDir)
		local Data = {
			Toggles = {},
			ThemeName = Config.ThemeName,
			FontName = Config.FontName,
			MenuBind = Config.MenuBind,
			Colors = {},
			AutoWinsWorld = Config.AutoWinsWorld,
		}
		for k, c in Config.CustomColors do
			Data.Colors[k] = {
				math.floor(c.R * 255),
				math.floor(c.G * 255),
				math.floor(c.B * 255),
			}
		end
		for id, t in Library.Toggles do
			Data.Toggles[id] = t.Value
		end
		writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
	end)
	return true
end

local function GetAutoloadName()
	if not isfile or not readfile then return nil end
	if not pcall(function() return isfile(AutoloadPath) end) then return nil end
	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(AutoloadPath))
	end)
	if ok and type(d) == "table" and type(d.Name) == "string" then
		return SanitizeConfigName(d.Name)
	end
	return nil
end

local function SetAutoload(Name)
	Name = SanitizeConfigName(Name)
	if not Name or not writefile then return false end
	pcall(function()
		makefolder("AutoFarm")
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

	local fileExists = false
	pcall(function() fileExists = isfile(ConfigPath(Name)) end)

	if not isfile or not readfile or not fileExists then
		if not Silent then Notify("Config", "Config not found", "Warning") end
		return false
	end

	local ok, d = pcall(function()
		return HttpService:JSONDecode(readfile(ConfigPath(Name)))
	end)
	if not ok or type(d) ~= "table" then
		if not Silent then Notify("Config", "Failed to read config", "Error") end
		return false
	end

	SuppressUI = true

	if type(d.ThemeName) == "string" and Themes[d.ThemeName] then
		Config.ThemeName = d.ThemeName
		ApplyTheme(Themes[d.ThemeName])
	end

	if type(d.Colors) == "table" then
		for k, rgb in d.Colors do
			if Config.CustomColors[k] and type(rgb) == "table" then
				if type(rgb[1]) == "number" and type(rgb[2]) == "number" and type(rgb[3]) == "number" then
					Config.CustomColors[k] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
				end
			end
		end
		for k, c in Config.CustomColors do
			ApplyColorOverride(k, c)
		end
	end

	if type(d.FontName) == "string" then
		pcall(function()
			if Enum.Font[d.FontName] then
				Config.FontName = d.FontName
				Library:SetFont(Enum.Font[d.FontName])
			end
		end)
	end

	if type(d.MenuBind) == "string" then
		Config.MenuBind = d.MenuBind
	end

	if type(d.AutoWinsWorld) == "string" and WinPositions[d.AutoWinsWorld] then
		Config.AutoWinsWorld = d.AutoWinsWorld
	end

	if type(d.Toggles) == "table" then
		for id, v in d.Toggles do
			local t = Library.Toggles[id]
			if t and type(v) == "boolean" then
				t:SetValue(v)
			end
		end
	end

	if SettingsRefs.ThemeDropdown then
		SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName)
	end
	if SettingsRefs.WorldDropdown then
		SettingsRefs.WorldDropdown:SetValue(Config.AutoWinsWorld)
	end
	if SettingsRefs.MenuBindPicker then
		SettingsRefs.MenuBindPicker:SetValue({ Config.MenuBind, "Press" })
	end
	SyncColorPickers()

	SuppressUI = false
	CurrentConfig = Name
	return true
end

-- ============================================================
-- Toggle Helper
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
-- Utility Loops
-- ============================================================

local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local t = Library.Toggles.AutoWins
			if t and not t.Value then
				t:SetValue(true)
			end
		end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do
			task.wait(0.5)
			pcall(function()
				local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				if gui and gui:FindFirstChild("DisconnectedFrame") and gui.DisconnectedFrame.Visible then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
				end
			end)
		end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local timer = 0
		while Config.AutoHideUi do
			task.wait(1)
			if Library.Toggled then
				timer = timer + 1
				if timer >= 30 then
					Library:Toggle(false)
					timer = 0
				end
			else
				timer = 0
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

Player.Idled:Connect(function()
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
ToggleButton.Button.Position = UDim2.fromOffset(6, 6)
LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)

-- ============================================================
-- UI: Tabs
-- ============================================================

local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "house" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}
local AutoFarmTab = Tabs.Main:AddSubTab({ Name = "Auto Farm", Icon = "star" })

-- ============================================================
-- UI: INFO TAB
-- ============================================================

local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")
StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

local ExecutorName, ExecutorVersion = "Unknown", "Unknown"
pcall(function()
	if identifyexecutor then
		local n, v = identifyexecutor()
		if type(n) == "table" then
			ExecutorName = tostring(n[1] or "Unknown")
			ExecutorVersion = tostring(n[2] or "Unknown")
		else
			ExecutorName = tostring(n)
			if v then ExecutorVersion = tostring(v) end
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
local ExecDisp = ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" and (ExecutorName .. " " .. ExecutorVersion) or ExecutorName
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecDisp .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/21/2026</font>' })

local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local Green = "#60d888"
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })
local JobId = tostring(game.JobId)
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. (#JobId > 18 and JobId:sub(1, 18) .. "..." or JobId) .. '</font>' })

task.spawn(function()
	local ok, Info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	if ok and Info and Info.Name then
		pcall(function()
			local CleanName = tostring(Info.Name):gsub("[^%z\1-\127]", "")
			GameNameLabel:SetText('GAME - <font color="#60d888">' .. CleanName .. '</font>')
		end)
	end
end)

local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local e = os.clock() - ScriptStartTime
		pcall(function()
			SessionLabel:SetText('SESSION - <font color="#60d888">' .. math.floor(e / 60) .. 'm ' .. math.floor(e % 60) .. 's</font>')
		end)
		task.wait(1)
	end
end)

InfoGameBox:AddButton({
	Text = "Copy Place ID",
	Func = function() CopyToClipboard(tostring(game.PlaceId)) end,
	Tooltip = "Copy Place ID",
})
InfoGameBox:AddButton({
	Text = "Copy Join Script",
	Func = function()
		CopyToClipboard(string.format(
			'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',
			game.PlaceId, JobId
		))
	end,
	Tooltip = "Copy Join Script",
})

local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")
SocialsBox:AddButton({ Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) end, Tooltip = "Discord" })
SocialsBox:AddButton({ Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) end, Tooltip = "YouTube" })
SocialsBox:AddButton({ Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) end, Tooltip = "TikTok" })

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
for _, f in {
	"Auto Wins", "Auto Rebirth",
	"Auto Buy Trail", "Theme Manager",
	"Config Autoload", "Auto Execute Script", "Auto Reconnect",
	"Auto Hide UI", "Anti AFK",
} do
	FeaturesBox:AddLabel({ Text = '<font color="#60d888">' .. f .. '</font>' })
end

-- ============================================================
-- UI: MAIN TAB — Auto Farm
-- ============================================================

local WinsBox = AutoFarmTab:AddLeftGroupbox("Farming", "zap")

SettingsRefs.WorldDropdown = WinsBox:AddDropdown("AutoWinsWorld", {
	Text = "Select World",
	Values = { "W1", "W2", "W3", "W4" },
	Default = Config.AutoWinsWorld,
	Callback = function(v)
		Config.AutoWinsWorld = v
		if not SuppressUI then ScheduleSave() end
	end,
})

AddFeatureToggle(WinsBox, "AutoWins", {
	Text = "Auto Wins",
	Tooltip = "Farm Wins",
	Notify = true,
}, function(v)
	Config.AutoWinsActive = v
	if v then
		task.spawn(function()
			while Config.AutoWinsActive do
				DoAutoWins()
				task.wait(1)
			end
		end)
	end
end)

AddFeatureToggle(WinsBox, "AutoRebirth", {
	Text = "Auto Rebirth",
	Tooltip = "Auto Rebirth",
	Notify = true,
}, function(v)
	Config.AutoRebirthActive = v
	if v then
		task.spawn(function()
			while Config.AutoRebirthActive do
				DoAutoRebirth()
				task.wait(1)
			end
		end)
	end
end)

AddFeatureToggle(WinsBox, "AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Tooltip = "Buy all trails",
	Notify = true,
}, function(v)
	Config.AutoBuyTrailActive = v
	if v then
		TrailBought = {}
		task.spawn(function()
			while Config.AutoBuyTrailActive do
				DoAutoBuyTrail()
				task.wait(1)
			end
		end)
	end
end)

-- ============================================================
-- UI: SETTINGS TAB
-- ============================================================

local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

SettingsRefs.ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme",
	Values = ThemeNames,
	Default = Config.ThemeName,
	Callback = function(v)
		Config.ThemeName = v
		ApplyTheme(Themes[v])
		if not SuppressUI then
			for k, c in Themes[v] do
				Config.CustomColors[k] = c
			end
			SyncColorPickers()
			Notify("Theme", "Theme set to " .. v, "Success")
			ScheduleSave()
		end
	end,
})

ThemeBox:AddDivider()

ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {
	Default = Config.CustomColors.AccentColor,
	Title = "Accent Color",
	Callback = function(c)
		Config.CustomColors.AccentColor = c
		ApplyColorOverride("AccentColor", c)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", {
	Default = Config.CustomColors.FontColor,
	Title = "Font Color",
	Callback = function(c)
		Config.CustomColors.FontColor = c
		ApplyColorOverride("FontColor", c)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", {
	Default = Config.CustomColors.BackgroundColor,
	Title = "Background Color",
	Callback = function(c)
		Config.CustomColors.BackgroundColor = c
		ApplyColorOverride("BackgroundColor", c)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", {
	Default = Config.CustomColors.MainColor,
	Title = "Main Color",
	Callback = function(c)
		Config.CustomColors.MainColor = c
		ApplyColorOverride("MainColor", c)
		ScheduleSave()
	end,
})

ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", {
	Default = Config.CustomColors.OutlineColor,
	Title = "Outline Color",
	Callback = function(c)
		Config.CustomColors.OutlineColor = c
		ApplyColorOverride("OutlineColor", c)
		ScheduleSave()
	end,
})

ThemeBox:AddDivider()

SettingsRefs.FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font",
	Values = FontNames,
	Default = Config.FontName,
	Callback = function(v)
		Config.FontName = v
		pcall(function() Library:SetFont(Enum.Font[v]) end)
		if not SuppressUI then ScheduleSave() end
	end,
})

ThemeBox:AddButton({
	Text = "Reset Theme",
	Func = function()
		Config.ThemeName = "Emerald Green"
		for k, c in Themes["Emerald Green"] do
			Config.CustomColors[k] = c
		end
		ApplyTheme(Themes["Emerald Green"])
		SettingsRefs.ThemeDropdown:SetValue("Emerald Green")
		SyncColorPickers()
		Notify("Theme", "Reset to Emerald Green", "Info")
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
	ChangedCallback = function(k)
		if typeof(k) == "EnumItem" then
			Config.MenuBind = k.Name
		end
		ScheduleSave()
	end,
})
SettingsRefs.MenuBindPicker = Library.Options.MenuBind

MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", {
	Text = "Auto Execute Script",
	Tooltip = "Auto execute on load",
}, function(v)
	Config.AutoExecute = v
	if v then RunAutoExecute() end
end)

AddFeatureToggle(MenuBox, "AutoReconnect", {
	Text = "Auto Reconnect",
	Tooltip = "Rejoin on disconnect",
}, function(v)
	Config.AutoReconnect = v
	if v then AutoReconnectLoop() end
end)

AddFeatureToggle(MenuBox, "AutoHideUi", {
	Text = "Auto Hide UI",
	Tooltip = "Hide UI after 30s",
}, function(v)
	Config.AutoHideUi = v
	if v then AutoHideUiLoop() end
end)

AddFeatureToggle(MenuBox, "AntiAfk", {
	Text = "Anti AFK",
	Tooltip = "Prevent AFK kick",
}, function(v)
	Config.AntiAfk = v
	if v then AntiAfkLoop() end
end)

MenuBox:AddDivider()

MenuBox:AddButton({
	Text = "Stop All Features",
	Risky = true,
	Func = function()
		Config.AutoWinsActive = false
		Config.AutoRebirthActive = false
		Config.AutoBuyTrailActive = false
		Config.AutoReconnect = false
		Config.AutoHideUi = false
		Config.AntiAfk = false
		for _, t in Library.Toggles do
			if t.Value then t:SetValue(false) end
		end
		Notify("Script", "All features stopped", "Warning")
	end,
})

-- Config Manager
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")
local RefreshConfigList

local ConfigNameInput = ConfigBox:AddInput("ConfigName", {
	Text = "Config name",
	Placeholder = "Type name...",
	ClearTextOnFocus = true,
})

ConfigBox:AddButton({
	Text = "Create config",
	Tooltip = "Save new config",
	Func = function()
		local n = SanitizeConfigName(ConfigNameInput.Value)
		if not n then Notify("Config", "Enter a valid name", "Warning"); return end
		if SaveConfigData(n) then
			CurrentConfig = n
			RefreshConfigList(n)
			Notify("Config", "'" .. n .. "' created", "Success")
		end
	end,
})

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {
	Text = "Config list",
	Values = { "---" },
	Default = "---",
	Callback = function(v)
		CurrentConfig = v == "---" and nil or v
	end,
})
SettingsRefs.ConfigListDropdown = ConfigListDropdown
local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Autoload: <font color="#60d888">none</font>' })

RefreshConfigList = function(sel)
	local vals = { "---" }
	for _, n in GetConfigList() do
		table.insert(vals, n)
	end
	ConfigListDropdown:SetValues(vals)
	local choice = sel or CurrentConfig or "---"
	if not table.find(vals, choice) then
		choice = "---"
	end
	ConfigListDropdown:SetValue(choice)
	CurrentConfig = choice == "---" and nil or choice
end

local function UpdateAutoloadLabel()
	local n = GetAutoloadName()
	AutoloadLabel:SetText(n and ('Autoload: <font color="#60d888">' .. n .. '</font>') or 'Autoload: <font color="#60d888">none</font>')
end

ConfigBox:AddButton({
	Text = "Load config",
	Tooltip = "Load selected config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning"); return end
		if LoadConfig(CurrentConfig, false) then
			Notify("Config", "'" .. CurrentConfig .. "' loaded", "Success")
		end
	end,
})

ConfigBox:AddButton({
	Text = "Overwrite config",
	Tooltip = "Save over selected config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning"); return end
		if SaveConfigData(CurrentConfig) then
			Notify("Config", "'" .. CurrentConfig .. "' saved", "Success")
		end
	end,
})

ConfigBox:AddButton({
	Text = "Delete config",
	Risky = true,
	Tooltip = "Delete selected config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning"); return end
		pcall(function() delfile(ConfigPath(CurrentConfig)) end)
		if GetAutoloadName() == CurrentConfig then ClearAutoload() end
		CurrentConfig = nil
		RefreshConfigList()
		UpdateAutoloadLabel()
		Notify("Config", "Deleted", "Warning")
	end,
})

ConfigBox:AddButton({
	Text = "Refresh list",
	Tooltip = "Refresh config list",
	Func = function()
		RefreshConfigList()
		Notify("Config", "Refreshed", "Info")
	end,
})

ConfigBox:AddButton({
	Text = "Set as autoload",
	Tooltip = "Auto-load this config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning"); return end
		if SetAutoload(CurrentConfig) then
			UpdateAutoloadLabel()
			Notify("Config", "Autoload set to '" .. CurrentConfig .. "'", "Success")
		end
	end,
})

ConfigBox:AddButton({
	Text = "Reset autoload",
	Tooltip = "Clear autoload",
	Func = function()
		ClearAutoload()
		UpdateAutoloadLabel()
		Notify("Config", "Autoload cleared", "Info")
	end,
})

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", {
	Text = "Auto Save Config",
	Tooltip = "Auto save changes",
}, function(v) Config.AutoSave = v end)

-- ============================================================
-- Startup
-- ============================================================

ApplyTheme(Themes[Config.ThemeName])

task.delay(1, function()
	local n = GetAutoloadName()
	if n and SanitizeConfigName(n) then
		CurrentConfig = n
		if LoadConfig(n, true) then
			Notify("Config", "Autoloaded '" .. n .. "'", "Success")
		end
	end
	RunAutoExecute()
end)

Notify("AntiGodHub", "Script loaded", "Success")
