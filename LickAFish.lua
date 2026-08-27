-- Load Obsidian GUI Library
local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()

if not Library then
	warn("ERROR: Failed to load library")
	return
end

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local function GetGameName()
	local s, info = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId)
	end)
	return (s and info and info.Name) or "Unknown Game"
end

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
Player.CharacterAdded:Connect(function(c)
	Character = c
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

-- Remote cache
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Config
local Config = {
	AutoLickFish = false,
	AutoCollectCash = false,
	AutoSellAll = false,
	AutoRebirth = false,
	AutoEquipBestFish = false,
	AutoUpgradeAquarium = false,
	AutoBuyTongue = false,
	AutoBuyGym = false,
	AutoBuySpeed = false,
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

-- Module readers
local function ReadModuleKeys(path)
	local keys = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild(path)
		if mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				for k, _ in pairs(data) do
					if type(k) == "string" then
						table.insert(keys, k)
					end
				end
			end
		end
	end)
	table.sort(keys)
	return keys
end

local function CopyToClipboard(text)
	local s = pcall(setclipboard, text)
	if not s then pcall(toclipboard, text) end
end

local NotifyColors = {
	Success = Color3.fromRGB(96, 216, 118),
	Warning = Color3.fromRGB(255, 176, 80),
	Error = Color3.fromRGB(255, 96, 96),
}

local function Notify(title, desc, type)
	pcall(function()
		if type(title) == "string" and #title > 60 then title = title:sub(1, 57) .. "..." end
		if not desc or desc == "" then desc = " "
		elseif type(desc) == "string" and #desc > 60 then desc = desc:sub(1, 57) .. "..." end
		type = type or "Info"
		Library:Notify({ Title = title, Description = desc, Time = 4, Type = type, DescriptionColor = NotifyColors[type] })
	end)
end

-- Auto Lick Fish: OnCast -> wait 1s -> onSwimComplete
local function AutoLickFish()
	pcall(function()
		Remotes:WaitForChild("OnCast"):InvokeServer(9999)
	end)
	task.wait(1)
	pcall(function()
		Remotes:WaitForChild("onSwimComplete"):InvokeServer(false)
	end)
end

local function AutoCollectCash()
	pcall(function() Remotes:WaitForChild("ClaimMoney"):InvokeServer() end)
end

local function AutoSellAll()
	pcall(function() Remotes:WaitForChild("Sell"):InvokeServer("All") end)
end

local function AutoRebirth()
	pcall(function() Remotes:WaitForChild("Rebirth"):InvokeServer() end)
end

local function AutoEquipBestFish()
	pcall(function() Remotes:WaitForChild("EquipBest"):InvokeServer() end)
end

local function AutoUpgradeAquarium()
	pcall(function() Remotes:WaitForChild("UpgradeTank"):InvokeServer() end)
end

local function AutoBuyTongue()
	local names = ReadModuleKeys("TongueConfigs")
	for _, name in ipairs(names) do
		pcall(function() Remotes:WaitForChild("BuyTongue"):InvokeServer(name) end)
		task.wait(0.1)
	end
end

local function AutoBuyGym()
	local names = ReadModuleKeys("GymToolConfigs")
	for _, name in ipairs(names) do
		pcall(function() Remotes:WaitForChild("BuyGym"):InvokeServer(name) end)
		task.wait(0.1)
	end
end

local function AutoBuySpeed()
	pcall(function() Remotes:WaitForChild("BuySpeed"):InvokeServer(1) end)
end

-- Utility
local function AntiAfkLoop()
	task.spawn(function()
		while Config.AntiAfk do
			task.wait(600)
			pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
		end
	end)
end

Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then
		pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
	end
end)

local function NoPauseLoop()
	task.spawn(function()
		while Config.NoGameplayPaused do
			task.wait(20)
			pcall(function()
				local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				if hrp then hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0) end
			end)
		end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do
			task.wait(0.5)
			pcall(function()
				local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
				local frame = gui and gui:FindFirstChild("DisconnectedFrame")
				if frame and frame.Visible then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
				end
			end)
		end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local t = 0
		while Config.AutoHideUi do
			task.wait(1)
			if Library.Toggled then
				t = t + 1
				if t >= 30 then Library:Toggle() t = 0 end
			else
				t = 0
			end
		end
	end)
end

local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local toggle = Library.Toggles.AutoLickFish
			if toggle and not toggle.Value then toggle:SetValue(true) end
		end
	end)
end

-- Theme
local function MakeTheme(a, b, m, o, f)
	return { AccentColor = a, BackgroundColor = b, MainColor = m, OutlineColor = o, FontColor = f }
end

local Themes = {
	["Obsidian (Default)"] = MakeTheme(Color3.fromRGB(125,85,255), Color3.fromRGB(15,15,15), Color3.fromRGB(25,25,25), Color3.fromRGB(40,40,40), Color3.fromRGB(255,255,255)),
	["Midnight Blue"] = MakeTheme(Color3.fromRGB(96,165,255), Color3.fromRGB(8,10,16), Color3.fromRGB(18,22,32), Color3.fromRGB(38,46,64), Color3.fromRGB(255,255,255)),
	["Blood Red"] = MakeTheme(Color3.fromRGB(255,76,76), Color3.fromRGB(16,8,8), Color3.fromRGB(28,14,14), Color3.fromRGB(64,30,30), Color3.fromRGB(255,255,255)),
	["Emerald Green"] = MakeTheme(Color3.fromRGB(96,216,118), Color3.fromRGB(8,16,10), Color3.fromRGB(16,28,20), Color3.fromRGB(30,58,40), Color3.fromRGB(255,255,255)),
	["Sunset Orange"] = MakeTheme(Color3.fromRGB(255,148,60), Color3.fromRGB(18,12,8), Color3.fromRGB(32,22,12), Color3.fromRGB(64,46,26), Color3.fromRGB(255,255,255)),
}

local ThemeNames = {}
for Name in Themes do table.insert(ThemeNames, Name) end

local function CloneColors(s) local c = {} for k, v in s do c[k] = v end return c end
local function ApplyTheme(s) for k, v in s do if Library.Scheme[k] ~= nil then Library.Scheme[k] = v end end Library:UpdateColorsUsingRegistry() end
local function ApplyColorOverride(k, c) if Library.Scheme[k] ~= nil then Library.Scheme[k] = c Library:UpdateColorsUsingRegistry() end end
local function ApplyCustomColors() for k, c in Config.CustomColors do ApplyColorOverride(k, c) end end
local function SyncColorPickers()
	local map = { AccentColor = "ThemeAccent", FontColor = "ThemeFontColor", BackgroundColor = "ThemeBackground", MainColor = "ThemeMain", OutlineColor = "ThemeOutline" }
	for k, idx in map do local p = Library.Options[idx] if p and p.SetValueRGB then p:SetValueRGB(Config.CustomColors[k]) end end
end

local FontNames = { "Code", "Gotham", "Roboto", "Cartoon", "Arial", "SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito" }

local FontPresets = {
	{ Name = "White + Emerald", Accent = Color3.fromRGB(96,216,118) },
	{ Name = "White + Sky Blue", Accent = Color3.fromRGB(79,195,247) },
	{ Name = "White + Gold", Accent = Color3.fromRGB(255,213,79) },
	{ Name = "White + Rose", Accent = Color3.fromRGB(255,107,107) },
	{ Name = "White + Violet", Accent = Color3.fromRGB(179,136,255) },
	{ Name = "White + Teal", Accent = Color3.fromRGB(77,208,196) },
	{ Name = "White + Coral", Accent = Color3.fromRGB(255,138,101) },
	{ Name = "White + Lavender", Accent = Color3.fromRGB(206,147,216) },
	{ Name = "White + Cyan", Accent = Color3.fromRGB(77,208,225) },
	{ Name = "White + Lime", Accent = Color3.fromRGB(174,213,129) },
}
local FontPresetNames = {}
for _, p in FontPresets do table.insert(FontPresetNames, p.Name) end

-- Config save/load
local ConfigsDir = "LickFish/Configs"
local AutoloadPath = "LickFish/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(name)
	if type(name) ~= "string" then return nil end
	local clean = name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if clean == "" or clean == "---" then return nil end
	return clean
end

local function ConfigPath(name) return ConfigsDir .. "/" .. name .. ".json" end

local function GetConfigList()
	local list = {}
	if not listfiles then return list end
	pcall(function()
		makefolder("LickFish") makefolder(ConfigsDir)
		for _, path in listfiles(ConfigsDir) do
			if path:sub(-5) == ".json" then
				local n = path:match("([^/\\]+)%.json$")
				if n and n ~= "---" then table.insert(list, n) end
			end
		end
	end)
	table.sort(list) return list
end

local function ConfigExists(name)
	name = SanitizeConfigName(name)
	return name and isfile and isfile(ConfigPath(name)) or false
end

local function SaveConfigData(name)
	if not writefile then return false end
	name = SanitizeConfigName(name)
	if not name then return false end
	pcall(function()
		makefolder("LickFish") makefolder(ConfigsDir)
		local data = { Toggles = {}, ThemeName = Config.ThemeName, FontName = Config.FontName, MenuBind = Config.MenuBind, Colors = {} }
		for k, c in Config.CustomColors do data.Colors[k] = { math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255) } end
		for id, t in Library.Toggles do data.Toggles[id] = t.Value end
		writefile(ConfigPath(name), HttpService:JSONEncode(data))
	end)
	return true
end

local function GetAutoloadName()
	if not isfile or not readfile then return nil end
	if not isfile(AutoloadPath) then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(AutoloadPath)) end)
	return (ok and type(data) == "table" and type(data.Name) == "string") and SanitizeConfigName(data.Name) or nil
end

local function SetAutoload(name)
	if not writefile then return false end
	name = SanitizeConfigName(name)
	if not name then return false end
	pcall(function() makefolder("LickFish") writefile(AutoloadPath, HttpService:JSONEncode({ Name = name })) end)
	return true
end

local function ClearAutoload()
	pcall(function() if isfile and isfile(AutoloadPath) then delfile(AutoloadPath) end end)
end

local SaveQueued = false
local function ScheduleSave()
	if not Config.AutoSave or not CurrentConfig or SaveQueued then return end
	SaveQueued = true
	task.delay(1, function() SaveQueued = false SaveConfigData(CurrentConfig) end)
end

local LoadConfig
LoadConfig = function(name, silent)
	name = SanitizeConfigName(name)
	if not name then return false end
	if not isfile or not readfile then if not silent then Notify("Config", "Config loading not supported", "Error") end return false end
	if not isfile(ConfigPath(name)) then if not silent then Notify("Config", "Config '" .. name .. "' not found", "Warning") end return false end

	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath(name))) end)
	if not ok or type(data) ~= "table" then if not silent then Notify("Config", "Failed to read configuration", "Error") end return false end

	SuppressUI = true

	if type(data.ThemeName) == "string" and Themes[data.ThemeName] then
		Config.ThemeName = data.ThemeName
		ApplyTheme(Themes[data.ThemeName])
	end
	if type(data.Colors) == "table" then
		for k, rgb in data.Colors do
			if Config.CustomColors[k] ~= nil and type(rgb) == "table" then
				local r, g, b = rgb[1], rgb[2], rgb[3]
				if type(r) == "number" and type(g) == "number" and type(b) == "number" then
					Config.CustomColors[k] = Color3.fromRGB(r, g, b)
				end
			end
		end
		ApplyCustomColors()
	end
	if type(data.FontName) == "string" and Enum.Font[data.FontName] then
		Config.FontName = data.FontName
		Library:SetFont(Enum.Font[data.FontName])
	end
	if type(data.MenuBind) == "string" and data.MenuBind ~= "None" then Config.MenuBind = data.MenuBind end
	if type(data.Toggles) == "table" then
		for id, val in data.Toggles do
			local t = Library.Toggles[id]
			if t and type(val) == "boolean" then t:SetValue(val) end
		end
	end

	if SettingsRefs.ThemeDropdown then SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName) end
	if SettingsRefs.FontDropdown then SettingsRefs.FontDropdown:SetValue(Config.FontName) end
	SyncColorPickers()

	SuppressUI = false
	CurrentConfig = name
	return true
end

local function AddFeatureToggle(box, id, info, cb)
	return box:AddToggle(id, {
		Text = info.Text, Default = false, Tooltip = info.Tooltip,
		Callback = function(val)
			if cb then cb(val) end
			if info.Notify and not SuppressUI then Notify(info.Text .. " " .. (val and "On" or "Off"), "", val and "Success" or "Warning") end
			ScheduleSave()
		end,
	})
end

-- UI
local Window = Library:CreateWindow({
	Title = "AntiGodHub", Icon = 125265885440515,
	Footer = { { Text = Config.DiscordLink, Copyable = true }, { Text = " | " }, { Text = "AntiGodHub", Copyable = true } },
	CornerRadius = 20, AutoShow = true, ShowMobileButtons = false, Minimizable = true, Resizable = true,
	Animations = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true },
})
Library.ToggleKeybind = nil

local ToggleBtn = Library:AddDraggableButton("Toggle", function() Library:Toggle() end, true, true)
local LockBtn = Library:AddDraggableButton("Lock", function(self) Library.CantDragForced = not Library.CantDragForced self:SetText(Library.CantDragForced and "Unlock" or "Lock") end, true, true)
ToggleBtn.Button.AnchorPoint = Vector2.new(0, 0) ToggleBtn.Button.Position = UDim2.fromOffset(6, 6)
LockBtn.Button.AnchorPoint = Vector2.new(0, 0) LockBtn.Button.Position = UDim2.fromOffset(ToggleBtn.Button.Size.X.Offset + 12, 6)

local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "house" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}
local MainTabs = {
	Farming = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" }),
	Upgrade = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "trending-up" }),
}

-- Info Tab
local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")
StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

local ExecutorName, ExecutorVersion = "Unknown", "Unknown"
pcall(function()
	if identifyexecutor then
		local n, v = identifyexecutor()
		if type(n) == "table" then ExecutorName = tostring(n[1] or n.Name or "Unknown") ExecutorVersion = tostring(n[2] or n.Version or "Unknown")
		else ExecutorName = tostring(n) if v and tostring(v) ~= "" then ExecutorVersion = tostring(v) end end
	elseif getexecutorname then ExecutorName = tostring(getexecutorname()) end
	if ExecutorVersion == "Unknown" then pcall(function() if getexecutorversion then ExecutorVersion = tostring(getexecutorversion()) end end) end
end)
local ExecutorDisplay = ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" and (ExecutorName .. " " .. ExecutorVersion) or ExecutorName
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/27/2026</font>' })

local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local Green = "#60d888"
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })
local JobId = tostring(game.JobId)
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. (#JobId > 18 and JobId:sub(1,18) .. "..." or JobId) .. '</font>' })

task.spawn(function()
	local s, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	pcall(function() GameNameLabel:SetText('GAME - <font color="#60d888">' .. ((s and info and info.Name) or "Unknown") .. '</font>') end)
end)

InfoGameBox:AddButton({ Text = "Copy Place ID", Func = function() CopyToClipboard(tostring(game.PlaceId)) end })
InfoGameBox:AddButton({ Text = "Copy Join Script", Func = function()
	CopyToClipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)', game.PlaceId, JobId))
end })

local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")
SocialsBox:AddButton({ Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) end })
SocialsBox:AddButton({ Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) end })
SocialsBox:AddButton({ Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) end })

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
local featureList = {
	"Auto Lick Fish", "Auto Collect Cash", "Auto Sell All", "Auto Rebirth", "Auto Equip Best Fish",
	"Auto Upgrade Aquarium", "Auto Buy Tongue", "Auto Buy Gym", "Auto Buy Speed",
	"Anti AFK", "No Gameplay Paused", "Auto Reconnect", "Auto Hide UI", "Theme Manager", "Config System",
}
for _, f in ipairs(featureList) do
	FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ ' .. f .. '</font>' })
end

local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local e = os.clock() - ScriptStartTime
		pcall(function() SessionLabel:SetText('SESSION - <font color="#60d888">' .. math.floor(e/60) .. 'm ' .. math.floor(e%60) .. 's</font>') end)
		task.wait(1)
	end
end)

-- Farming
local FarmBox = MainTabs.Farming:AddLeftGroupbox("Auto Farming", "star")

AddFeatureToggle(FarmBox, "AutoLickFish", { Text = "Auto Lick Fish", Tooltip = "Lick fish automatically", Notify = true }, function(v)
	Config.AutoLickFish = v
	if v then task.spawn(function() while Config.AutoLickFish do AutoLickFish() task.wait(1) end end) end
end)

AddFeatureToggle(FarmBox, "AutoCollectCash", { Text = "Auto Collect Cash", Tooltip = "Collect cash automatically", Notify = true }, function(v)
	Config.AutoCollectCash = v
	if v then task.spawn(function() while Config.AutoCollectCash do AutoCollectCash() task.wait(0.5) end end) end
end)

AddFeatureToggle(FarmBox, "AutoSellAll", { Text = "Auto Sell All", Tooltip = "Sell all fish automatically", Notify = true }, function(v)
	Config.AutoSellAll = v
	if v then task.spawn(function() while Config.AutoSellAll do AutoSellAll() task.wait(1) end end) end
end)

AddFeatureToggle(FarmBox, "AutoRebirth", { Text = "Auto Rebirth", Tooltip = "Rebirth automatically", Notify = true }, function(v)
	Config.AutoRebirth = v
	if v then task.spawn(function() while Config.AutoRebirth do AutoRebirth() task.wait(0.5) end end) end
end)

AddFeatureToggle(FarmBox, "AutoEquipBestFish", { Text = "Auto Equip Best Fish", Tooltip = "Equip best fish automatically", Notify = true }, function(v)
	Config.AutoEquipBestFish = v
	if v then task.spawn(function() while Config.AutoEquipBestFish do AutoEquipBestFish() task.wait(0.5) end end) end
end)

-- Upgrade
local UpgradeBox = MainTabs.Upgrade:AddLeftGroupbox("Upgrade", "trending-up")

AddFeatureToggle(UpgradeBox, "AutoUpgradeAquarium", { Text = "Auto Upgrade Aquarium", Tooltip = "Upgrade aquarium automatically", Notify = true }, function(v)
	Config.AutoUpgradeAquarium = v
	if v then task.spawn(function() while Config.AutoUpgradeAquarium do AutoUpgradeAquarium() task.wait(0.1) end end) end
end)

AddFeatureToggle(UpgradeBox, "AutoBuyTongue", { Text = "Auto Buy Tongue", Tooltip = "Buy all tongues automatically", Notify = true }, function(v)
	Config.AutoBuyTongue = v
	if v then task.spawn(function() while Config.AutoBuyTongue do AutoBuyTongue() task.wait(0.3) end end) end
end)

AddFeatureToggle(UpgradeBox, "AutoBuyGym", { Text = "Auto Buy Gym", Tooltip = "Buy all gym tools automatically", Notify = true }, function(v)
	Config.AutoBuyGym = v
	if v then task.spawn(function() while Config.AutoBuyGym do AutoBuyGym() task.wait(0.3) end end) end
end)

AddFeatureToggle(UpgradeBox, "AutoBuySpeed", { Text = "Auto Buy Speed", Tooltip = "Buy speed upgrades automatically", Notify = true }, function(v)
	Config.AutoBuySpeed = v
	if v then task.spawn(function() while Config.AutoBuySpeed do AutoBuySpeed() task.wait(0.001) end end) end
end)

-- Settings
local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme", Values = ThemeNames, Default = Config.ThemeName,
	Callback = function(v) Config.ThemeName = v ApplyTheme(Themes[v]) if not SuppressUI then Config.CustomColors = CloneColors(Themes[v]) SyncColorPickers() ScheduleSave() end end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

ThemeBox:AddDivider()
ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", { Default = Config.CustomColors.AccentColor, Title = "Accent Color", Callback = function(c) Config.CustomColors.AccentColor = c ApplyColorOverride("AccentColor", c) ScheduleSave() end })
ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", { Default = Config.CustomColors.FontColor, Title = "Font Color", Callback = function(c) Config.CustomColors.FontColor = c ApplyColorOverride("FontColor", c) ScheduleSave() end })
ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", { Default = Config.CustomColors.BackgroundColor, Title = "Background Color", Callback = function(c) Config.CustomColors.BackgroundColor = c ApplyColorOverride("BackgroundColor", c) ScheduleSave() end })
ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", { Default = Config.CustomColors.MainColor, Title = "Main Color", Callback = function(c) Config.CustomColors.MainColor = c ApplyColorOverride("MainColor", c) ScheduleSave() end })
ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", { Default = Config.CustomColors.OutlineColor, Title = "Outline Color", Callback = function(c) Config.CustomColors.OutlineColor = c ApplyColorOverride("OutlineColor", c) ScheduleSave() end })
ThemeBox:AddDivider()

local FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font", Values = FontNames, Default = Config.FontName,
	Callback = function(v) Config.FontName = v Library:SetFont(Enum.Font[v]) if not SuppressUI then ScheduleSave() end end,
})
SettingsRefs.FontDropdown = FontDropdown

ThemeBox:AddButton({ Text = "Reset Theme", Func = function()
	Config.ThemeName = "Emerald Green" Config.CustomColors = CloneColors(Themes["Emerald Green"]) ApplyTheme(Themes["Emerald Green"])
	ThemeDropdown:SetValue("Emerald Green") SyncColorPickers() Notify("Theme", "Theme reset to Emerald Green", "Info") ScheduleSave()
end })

local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Group", "menu")

MenuBox:AddLabel("Menu Bind"):AddKeyPicker("MenuBind", {
	Default = Config.MenuBind, Mode = "Press", Text = "Toggle UI",
	Callback = function() Library:Toggle() end,
	ChangedCallback = function(k) if typeof(k) == "EnumItem" then Config.MenuBind = k.Name end ScheduleSave() end,
})
MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", { Text = "Auto Execute Script", Tooltip = "Execute script on load" }, function(v) Config.AutoExecute = v if v then RunAutoExecute() end end)
AddFeatureToggle(MenuBox, "AutoReconnect", { Text = "Auto Reconnect", Tooltip = "Reconnect on disconnect" }, function(v) Config.AutoReconnect = v if v then AutoReconnectLoop() end end)
AddFeatureToggle(MenuBox, "AutoHideUi", { Text = "Auto Hide UI", Tooltip = "Hide UI after idle" }, function(v) Config.AutoHideUi = v if v then AutoHideUiLoop() end end)
AddFeatureToggle(MenuBox, "AntiAfk", { Text = "Anti AFK", Tooltip = "Prevent AFK kick" }, function(v) Config.AntiAfk = v if v then AntiAfkLoop() end end)
AddFeatureToggle(MenuBox, "NoGameplayPaused", { Text = "No Gameplay Paused", Tooltip = "Keep character moving" }, function(v) Config.NoGameplayPaused = v if v then NoPauseLoop() end end)
MenuBox:AddDivider()

MenuBox:AddButton({ Text = "Stop All Features", Func = function()
	Config.AutoLickFish = false Config.AutoCollectCash = false Config.AutoSellAll = false Config.AutoRebirth = false Config.AutoEquipBestFish = false
	Config.AutoUpgradeAquarium = false Config.AutoBuyTongue = false Config.AutoBuyGym = false Config.AutoBuySpeed = false
	Config.AutoReconnect = false Config.AutoHideUi = false Config.AntiAfk = false Config.NoGameplayPaused = false
	for _, t in Library.Toggles do if t.Value then t:SetValue(false) end end
	Notify("Script", "All features stopped", "Warning")
end, Risky = true })

local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")
local RefreshConfigList

local ConfigNameInput = ConfigBox:AddInput("ConfigName", { Text = "Config name", Placeholder = "Type a config name...", ClearTextOnFocus = true })

ConfigBox:AddButton({ Text = "Create config", Func = function()
	local n = SanitizeConfigName(ConfigNameInput.Value)
	if not n then Notify("Config", "Enter a valid name first", "Warning") return end
	if ConfigExists(n) then Notify("Config", "'" .. n .. "' already exists", "Warning") return end
	if SaveConfigData(n) then CurrentConfig = n RefreshConfigList(n) Notify("Config", "Config '" .. n .. "' created", "Success")
	else Notify("Config", "Config saving not supported", "Error") end
end })

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", { Text = "Config list", Values = { "---" }, Default = "---", Callback = function(v) CurrentConfig = v == "---" and nil or v end })
local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Autoload: <font color="#60d888">none</font>' })

RefreshConfigList = function(sel)
	local vals = { "---" }
	for _, n in ipairs(GetConfigList()) do table.insert(vals, n) end
	ConfigListDropdown:SetValues(vals)
	local choice = sel or CurrentConfig or "---"
	if not table.find(vals, choice) then choice = "---" end
	ConfigListDropdown:SetValue(choice) CurrentConfig = choice == "---" and nil or choice
end

local function UpdateAutoloadLabel()
	local n = GetAutoloadName()
	AutoloadLabel:SetText(n and ('Autoload: <font color="#60d888">' .. n .. '</font>') or 'Autoload: <font color="#60d888">none</font>')
end

ConfigBox:AddButton({ Text = "Load config", Func = function()
	local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end
	if LoadConfig(n, false) then Notify("Config", "Config '" .. n .. "' loaded", "Success") end
end })
ConfigBox:AddButton({ Text = "Overwrite config", Func = function()
	local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end
	if SaveConfigData(n) then Notify("Config", "Config '" .. n .. "' overwritten", "Success") else Notify("Config", "Config saving not supported", "Error") end
end })
ConfigBox:AddButton({ Text = "Delete config", Func = function()
	local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end
	pcall(function() delfile(ConfigPath(n)) end)
	if GetAutoloadName() == n then ClearAutoload() end
	CurrentConfig = nil RefreshConfigList() UpdateAutoloadLabel() Notify("Config", "Config '" .. n .. "' deleted", "Warning")
end, Risky = true })
ConfigBox:AddButton({ Text = "Refresh list", Func = function() RefreshConfigList() Notify("Config", "Config list refreshed", "Info") end })
ConfigBox:AddButton({ Text = "Set as autoload", Func = function()
	local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end
	if SetAutoload(n) then UpdateAutoloadLabel() Notify("Config", "Autoload set to '" .. n .. "'", "Success") end
end })
ConfigBox:AddButton({ Text = "Reset autoload", Func = function() ClearAutoload() UpdateAutoloadLabel() Notify("Config", "Autoload cleared", "Info") end })
ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", { Text = "Auto Save Config", Tooltip = "Save config automatically" }, function(v) Config.AutoSave = v end)

-- Startup
ApplyTheme(Themes[Config.ThemeName])
Library:SetFont(Enum.Font[Config.FontName])

task.delay(1, function()
	local an = GetAutoloadName()
	if an and ConfigExists(an) then CurrentConfig = an if LoadConfig(an, true) then Notify("Config", "Autoloaded '" .. an .. "'", "Success") end end
	RunAutoExecute() UpdateAutoloadLabel() RefreshConfigList()
end)

Notify("AntiGodHub", "Loaded", "Success")