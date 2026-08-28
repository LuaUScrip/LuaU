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

-- Remotes
local EggEvents = ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("EggRemoteEvents")
local BuyBall = ReplicatedStorage:WaitForChild("BuyBallRemote")
local BuyTrail = ReplicatedStorage:WaitForChild("PetSystem"):WaitForChild("BuyTrailRemote")
local TreadmillReward = ReplicatedStorage:WaitForChild("TreadmillClaimReward")
local SpinRemote = ReplicatedStorage:WaitForChild("SpinRemote")
local UpgradeRemote = ReplicatedStorage:WaitForChild("UpgradeRemote")

-- Config
local Config = {
	AutoSpikeBall = false,
	AutoRebirth = false,
	InstantChallenge = false,
	FreeRainbowPack = false,
	AutoUsePotion = false,
	AutoSpinWheel = false,
	AutoUpgrade = false,
	AutoBuyBall = false,
	AutoBuyTrail = false,
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

-- ===== MODULE READERS =====

local function ReadModuleKeys(path)
	local keys = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild(path)
		if mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				for k, v in pairs(data) do
					if type(k) == "string" and type(v) == "table" then
						table.insert(keys, k)
					end
				end
			end
		end
	end)
	table.sort(keys)
	return keys
end

-- ===== UTILITY =====

local function CopyToClipboard(text)
	local s = pcall(setclipboard, text)
	if not s then pcall(toclipboard, text) end
end

local NotifyColors = {
	Success = Color3.fromRGB(96, 216, 118),
	Warning = Color3.fromRGB(255, 176, 80),
	Error = Color3.fromRGB(255, 96, 96),
}

local function Notify(title, desc, t)
	pcall(function()
		if type(title) == "string" and #title > 60 then title = title:sub(1, 57) .. "..." end
		if not desc or desc == "" then desc = " "
		elseif type(desc) == "string" and #desc > 60 then desc = desc:sub(1, 57) .. "..." end
		t = t or "Info"
		Library:Notify({ Title = title, Description = desc, Time = 4, Type = t, DescriptionColor = NotifyColors[t] })
	end)
end

-- ===== FEATURE FUNCTIONS =====

local function AutoSpikeBallFunc()
	pcall(function()
		EggEvents:WaitForChild("KickBall"):FireServer(math.huge)
	end)
end

local function AutoRebirthFunc()
	pcall(function()
		EggEvents:WaitForChild("DoRebirth"):InvokeServer()
	end)
end

local function InstantChallengeFunc()
	pcall(function()
		EggEvents:WaitForChild("SpikeChallengeRemote"):FireServer("LeaveChallenge", true)
	end)
end

local function GetBestBallFunc()
	pcall(function()
		BuyBall:FireServer("Lightning")
	end)
end

local function FreeRainbowPackFunc()
	pcall(function() TreadmillReward:FireServer(11) end)
	pcall(function() TreadmillReward:FireServer(12) end)
	pcall(function() TreadmillReward:FireServer(10) end)
	pcall(function() TreadmillReward:FireServer(5) end)
end

local function AutoUsePotionFunc()
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("Power") end)
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("Money") end)
	pcall(function() EggEvents:WaitForChild("UsePotion"):FireServer("PetLuck") end)
end

local function AutoSpinWheelFunc()
	pcall(function()
		SpinRemote:InvokeServer()
	end)
end

local function AutoUpgradeFunc()
	pcall(function() UpgradeRemote:FireServer("A") end)
	pcall(function() UpgradeRemote:FireServer("B") end)
	pcall(function() UpgradeRemote:FireServer("C") end)
end

local function AutoBuyBallFunc()
	local ballNames = ReadModuleKeys("BallData")
	for _, name in ipairs(ballNames) do
		pcall(function() BuyBall:FireServer(name) end)
		task.wait(0.1)
	end
end

local function AutoBuyTrailFunc()
	local trailNames = ReadModuleKeys("TrailData")
	for _, name in ipairs(trailNames) do
		pcall(function() BuyTrail:FireServer(name) end)
		task.wait(0.1)
	end
end

-- Anti-AFK
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

Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

local function NoPauseLoop()
	task.spawn(function()
		while Config.NoGameplayPaused do
			task.wait(20)
			pcall(function()
				local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
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
				local df = gui and gui:FindFirstChild("DisconnectedFrame")
				if df and df.Visible then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
				end
			end)
		end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local openFor = 0
		while Config.AutoHideUi do
			task.wait(1)
			if Library.Toggled then
				openFor = openFor + 1
				if openFor >= 30 then Library:Toggle(false) openFor = 0 end
			else
				openFor = 0
			end
		end
	end)
end

local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local t = Library.Toggles.AutoSpikeBall
			if t and not t.Value then t:SetValue(true) end
		end
	end)
end

-- ===== THEME SYSTEM =====

local function MakeTheme(a, b, m, o, f)
	return { AccentColor = a, BackgroundColor = b, MainColor = m, OutlineColor = o, FontColor = f }
end

local Themes = {
	["Obsidian (Default)"] = MakeTheme(Color3.fromRGB(125, 85, 255), Color3.fromRGB(15, 15, 15), Color3.fromRGB(25, 25, 25), Color3.fromRGB(40, 40, 40), Color3.fromRGB(255, 255, 255)),
	["Midnight Blue"] = MakeTheme(Color3.fromRGB(96, 165, 255), Color3.fromRGB(8, 10, 16), Color3.fromRGB(18, 22, 32), Color3.fromRGB(38, 46, 64), Color3.fromRGB(255, 255, 255)),
	["Blood Red"] = MakeTheme(Color3.fromRGB(255, 76, 76), Color3.fromRGB(16, 8, 8), Color3.fromRGB(28, 14, 14), Color3.fromRGB(64, 30, 30), Color3.fromRGB(255, 255, 255)),
	["Emerald Green"] = MakeTheme(Color3.fromRGB(96, 216, 118), Color3.fromRGB(8, 16, 10), Color3.fromRGB(16, 28, 20), Color3.fromRGB(30, 58, 40), Color3.fromRGB(255, 255, 255)),
	["Sunset Orange"] = MakeTheme(Color3.fromRGB(255, 148, 60), Color3.fromRGB(18, 12, 8), Color3.fromRGB(32, 22, 12), Color3.fromRGB(64, 46, 26), Color3.fromRGB(255, 255, 255)),
}

local ThemeNames = {}
for n in Themes do table.insert(ThemeNames, n) end

local function CloneColors(s)
	local c = {}
	for k, v in s do c[k] = v end
	return c
end

local function ApplyTheme(s)
	for k, v in s do
		if Library.Scheme[k] ~= nil then Library.Scheme[k] = v end
	end
	Library:UpdateColorsUsingRegistry()
end

local function ApplyColorOverride(k, c)
	if Library.Scheme[k] ~= nil then Library.Scheme[k] = c Library:UpdateColorsUsingRegistry() end
end

local function ApplyCustomColors()
	for k, c in Config.CustomColors do ApplyColorOverride(k, c) end
end

local function SyncColorPickers()
	local map = { AccentColor = "ThemeAccent", FontColor = "ThemeFontColor", BackgroundColor = "ThemeBackground", MainColor = "ThemeMain", OutlineColor = "ThemeOutline" }
	for k, idx in map do
		local p = Library.Options[idx]
		if p and p.SetValueRGB then p:SetValueRGB(Config.CustomColors[k]) end
	end
end

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
for _, p in FontPresets do table.insert(FontPresetNames, p.Name) end

local FontNames = { "Code", "Gotham", "Roboto", "Cartoon", "Arial", "SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito" }

-- ===== CONFIG SAVE / LOAD =====

local ConfigsDir = "PickaxeSwing/Configs"
local AutoloadPath = "PickaxeSwing/Autoload.json"
local CurrentConfig = nil

local function SanitizeConfigName(n)
	if type(n) ~= "string" then return nil end
	local c = n:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return (c == "" or c == "---") and nil or c
end

local function ConfigPath(n) return ConfigsDir .. "/" .. n .. ".json" end

local function GetConfigList()
	local list = {}
	if not listfiles then return list end
	pcall(function()
		makefolder("PickaxeSwing") makefolder(ConfigsDir)
		for _, p in listfiles(ConfigsDir) do
			if p:sub(-5) == ".json" then
				local n = p:match("([^/\\]+)%.json$")
				if n and n ~= "---" then table.insert(list, n) end
			end
		end
	end)
	table.sort(list)
	return list
end

local function ConfigExists(n)
	n = SanitizeConfigName(n)
	return (not n or not isfile) and false or isfile(ConfigPath(n))
end

local function SaveConfigData(n)
	if not writefile then return false end
	n = SanitizeConfigName(n)
	if not n then return false end
	pcall(function()
		makefolder("PickaxeSwing") makefolder(ConfigsDir)
		local d = { Toggles = {}, ThemeName = Config.ThemeName, FontName = Config.FontName, FontPreset = Config.FontPreset, MenuBind = Config.MenuBind, Colors = {} }
		for k, c in Config.CustomColors do d.Colors[k] = { math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255) } end
		for id, t in Library.Toggles do d.Toggles[id] = t.Value end
		writefile(ConfigPath(n), HttpService:JSONEncode(d))
	end)
	return true
end

local function GetAutoloadName()
	if not isfile or not readfile then return nil end
	if not isfile(AutoloadPath) then return nil end
	local ok, d = pcall(function() return HttpService:JSONDecode(readfile(AutoloadPath)) end)
	return (ok and type(d) == "table" and type(d.Name) == "string") and SanitizeConfigName(d.Name) or nil
end

local function SetAutoload(n)
	if not writefile then return false end
	n = SanitizeConfigName(n)
	if not n then return false end
	pcall(function() makefolder("PickaxeSwing") writefile(AutoloadPath, HttpService:JSONEncode({ Name = n })) end)
	return true
end

local function ClearAutoload()
	pcall(function() if isfile and isfile(AutoloadPath) then delfile(AutoloadPath) end end)
	return true
end

local SaveQueued = false
local function ScheduleSave()
	if not Config.AutoSave or not CurrentConfig or SaveQueued then return end
	SaveQueued = true
	task.delay(1, function() SaveQueued = false SaveConfigData(CurrentConfig) end)
end

local LoadConfig
LoadConfig = function(n, silent)
	n = SanitizeConfigName(n)
	if not n then return false end
	if not isfile or not readfile then
		if not silent then Notify("Config", "Config loading not supported", "Error") end
		return false
	end
	if not isfile(ConfigPath(n)) then
		if not silent then Notify("Config", "Config '" .. n .. "' not found", "Warning") end
		return false
	end
	local ok, d = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath(n))) end)
	if not ok or type(d) ~= "table" then
		if not silent then Notify("Config", "Failed to read config", "Error") end
		return false
	end

	SuppressUI = true

	if type(d.ThemeName) == "string" and Themes[d.ThemeName] then
		Config.ThemeName = d.ThemeName ApplyTheme(Themes[d.ThemeName])
	end
	if type(d.Colors) == "table" then
		for k, rgb in d.Colors do
			if Config.CustomColors[k] ~= nil and type(rgb) == "table" then
				local r, g, b = rgb[1], rgb[2], rgb[3]
				if type(r) == "number" and type(g) == "number" and type(b) == "number" then
					Config.CustomColors[k] = Color3.fromRGB(r, g, b)
				end
			end
		end
		ApplyCustomColors()
	end
	if type(d.FontName) == "string" and Enum.Font[d.FontName] then
		Config.FontName = d.FontName Library:SetFont(Enum.Font[d.FontName])
	end
	if type(d.FontPreset) == "string" then
		for _, pr in FontPresets do
			if pr.Name == d.FontPreset then Config.FontPreset = pr.Name break end
		end
	end
	if type(d.MenuBind) == "string" and d.MenuBind ~= "None" then Config.MenuBind = d.MenuBind end
	if type(d.Toggles) == "table" then
		for id, v in d.Toggles do
			local t = Library.Toggles[id]
			if t and type(v) == "boolean" then t:SetValue(v) end
		end
	end

	if SettingsRefs.ThemeDropdown then SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName) end
	if SettingsRefs.FontDropdown then SettingsRefs.FontDropdown:SetValue(Config.FontName) end
	if SettingsRefs.FontPresetDropdown then SettingsRefs.FontPresetDropdown:SetValue(Config.FontPreset) end
	SyncColorPickers()

	SuppressUI = false
	CurrentConfig = n
	return true
end

-- Toggle helper
local function AddFeatureToggle(box, id, info, onToggle)
	return box:AddToggle(id, {
		Text = info.Text,
		Default = false,
		Tooltip = info.Tooltip,
		Callback = function(v)
			if onToggle then onToggle(v) end
			if info.Notify and not SuppressUI then
				Notify(info.Text .. " " .. (v and "On" or "Off"), "", v and "Success" or "Warning")
			end
			ScheduleSave()
		end,
	})
end

-- ===== CREATE WINDOW =====

local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Icon = 125265885440515,
	Footer = {
		{ Text = Config.DiscordLink, Copyable = true },
		{ Text = " | " },
		{ Text = "AntiGodHub", Copyable = true },
	},
	CornerRadius = 20,
	AutoShow = true,
	ShowMobileButtons = false,
	Minimizable = true,
	Resizable = true,
	Animations = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true },
})

Library.ToggleKeybind = nil

local ToggleButton = Library:AddDraggableButton("Toggle", function() Library:Toggle() end, true, true)
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

-- ===== INFO TAB =====

local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")
StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

local ExecutorName = "Unknown"
local ExecutorVersion = "Unknown"
pcall(function()
	if identifyexecutor then
		local n, v = identifyexecutor()
		if type(n) == "table" then
			ExecutorName = tostring(n[1] or n.Name or "Unknown")
			ExecutorVersion = tostring(n[2] or n.Version or "Unknown")
		else
			ExecutorName = tostring(n)
			if v ~= nil then ExecutorVersion = tostring(v) end
		end
	elseif getexecutorname then
		ExecutorName = tostring(getexecutorname())
	end
	if ExecutorVersion == "Unknown" then pcall(function() if getexecutorversion then ExecutorVersion = tostring(getexecutorversion()) end end) end
end)

local ExecutorDisplay = ExecutorName
if ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" then ExecutorDisplay = ExecutorName .. " " .. ExecutorVersion end
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/28/2026</font>' })

local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")
local Green = "#60d888"
InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">' .. GetGameName() .. '</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })

local JobId = tostring(game.JobId)
local ShortJobId = #JobId > 18 and JobId:sub(1, 18) .. "..." or JobId
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. ShortJobId .. '</font>' })

InfoGameBox:AddButton({ Text = "Copy Place ID", Func = function() CopyToClipboard(tostring(game.PlaceId)) end, Tooltip = "Copy Place ID" })
InfoGameBox:AddButton({
	Text = "Copy Join Script",
	Func = function()
		CopyToClipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)', game.PlaceId, JobId))
	end,
	Tooltip = "Copy Join Script"
})

local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")
SocialsBox:AddButton({ Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) end, Tooltip = "Discord" })
SocialsBox:AddButton({ Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) end, Tooltip = "YouTube" })
SocialsBox:AddButton({ Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) end, Tooltip = "TikTok" })

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
local featureList = {
	"Auto Spike Ball", "Auto Rebirth", "Instant Challenge", "Get Best Ball",
	"Free Rainbow Pack", "Auto Use Potion", "Auto Spin Wheel", "Auto Upgrade",
	"Auto Buy Ball", "Auto Buy Trail",
	"Anti AFK", "No Gameplay Paused", "Auto Reconnect", "Auto Hide UI",
	"Theme Manager", "Config System",
}
for _, f in ipairs(featureList) do
	FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ ' .. f .. '</font>' })
end

-- Session timer
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

-- ===== MAIN TAB =====

local MainTabs = {
	Farming = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" }),
	Upgrade = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "trending-up" }),
	Shop = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" }),
}

-- Farming Group (left)
local FarmBox = MainTabs.Farming:AddLeftGroupbox("Auto Farming", "star")

AddFeatureToggle(FarmBox, "AutoSpikeBall", {
	Text = "Auto Spike Ball",
	Tooltip = "Kick ball automatically",
	Notify = true,
}, function(v)
	Config.AutoSpikeBall = v
	if v then
		task.spawn(function()
			while Config.AutoSpikeBall do
				AutoSpikeBallFunc()
				task.wait(0.5)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoRebirth", {
	Text = "Auto Rebirth",
	Tooltip = "Rebirth automatically",
	Notify = true,
}, function(v)
	Config.AutoRebirth = v
	if v then
		task.spawn(function()
			while Config.AutoRebirth do
				AutoRebirthFunc()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "InstantChallenge", {
	Text = "Instant Challenge [IN FIGHT]",
	Tooltip = "Instan Challenge",
	Notify = true,
}, function(v)
	Config.InstantChallenge = v
	if v then
		task.spawn(function()
			while Config.InstantChallenge do
				InstantChallengeFunc()
				task.wait(1)
			end
		end)
	end
end)

AddFeatureToggle(FarmBox, "AutoSpinWheel", {
	Text = "Auto Spin Wheel",
	Tooltip = "Spin Wheel automatically",
	Notify = true,
}, function(v)
	Config.AutoSpinWheel = v
	if v then
		task.spawn(function()
			while Config.AutoSpinWheel do
				AutoSpinWheelFunc()
				task.wait(0.001)
			end
		end)
	end
end)

FarmBox:AddButton({
	Text = "Get Best Ball",
	Func = function() GetBestBallFunc() end,
	Tooltip = "Free Best Ball",
})

-- Upgrade Group (left)
local UpgradeBox = MainTabs.Upgrade:AddLeftGroupbox("Auto Upgrade", "trending-up")

AddFeatureToggle(UpgradeBox, "AutoUpgrade", {
	Text = "Auto Upgrade",
	Tooltip = "Buy all upgrades",
	Notify = true,
}, function(v)
	Config.AutoUpgrade = v
	if v then
		task.spawn(function()
			while Config.AutoUpgrade do
				AutoUpgradeFunc()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(UpgradeBox, "AutoUsePotion", {
	Text = "Auto Use Potion",
	Tooltip = "Use Potions",
	Notify = true,
}, function(v)
	Config.AutoUsePotion = v
	if v then
		task.spawn(function()
			while Config.AutoUsePotion do
				AutoUsePotionFunc()
				task.wait(0.1)
			end
		end)
	end
end)

AddFeatureToggle(UpgradeBox, "FreeRainbowPack", {
	Text = "Free Rainbow Pack",
	Tooltip = "Free Rainbow Pack",
	Notify = true,
}, function(v)
	Config.FreeRainbowPack = v
	if v then
		task.spawn(function()
			while Config.FreeRainbowPack do
				FreeRainbowPackFunc()
				task.wait(0.0001)
			end
		end)
	end
end)

-- Shop Group (left)
local ShopBox = MainTabs.Shop:AddLeftGroupbox("Auto Shop", "shopping-cart")

AddFeatureToggle(ShopBox, "AutoBuyBall", {
	Text = "Auto Buy Ball",
	Tooltip = "Buy all ball",
	Notify = true,
}, function(v)
	Config.AutoBuyBall = v
	if v then
		task.spawn(function()
			while Config.AutoBuyBall do
				AutoBuyBallFunc()
				task.wait(0.5)
			end
		end)
	end
end)

AddFeatureToggle(ShopBox, "AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Tooltip = "Buy all trail",
	Notify = true,
}, function(v)
	Config.AutoBuyTrail = v
	if v then
		task.spawn(function()
			while Config.AutoBuyTrail do
				AutoBuyTrailFunc()
				task.wait(0.5)
			end
		end)
	end
end)

-- ===== SETTINGS TAB =====

-- Theme Manager
local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme",
	Values = ThemeNames,
	Default = Config.ThemeName,
	Callback = function(v)
		Config.ThemeName = v
		ApplyTheme(Themes[v])
		if not SuppressUI then
			Config.CustomColors = CloneColors(Themes[v])
			ApplyCustomColors()
			SyncColorPickers()
			ScheduleSave()
		end
	end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

local FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font",
	Values = FontNames,
	Default = Config.FontName,
	Callback = function(v)
		Config.FontName = v
		Library:SetFont(Enum.Font[v])
		if not SuppressUI then ScheduleSave() end
	end,
})
SettingsRefs.FontDropdown = FontDropdown

local FontPresetDropdown = ThemeBox:AddDropdown("FontPreset", {
	Text = "Font Color Preset",
	Values = FontPresetNames,
	Default = Config.FontPreset,
	Visible = false,
	Callback = function(v)
		Config.FontPreset = v
		for _, pr in FontPresets do
			if pr.Name == v then
				Config.CustomColors.FontColor = Color3.fromRGB(255, 255, 255)
				Config.CustomColors.AccentColor = pr.Accent
				ApplyColorOverride("FontColor", Color3.fromRGB(255, 255, 255))
				ApplyColorOverride("AccentColor", pr.Accent)
				SyncColorPickers()
				break
			end
		end
		if not SuppressUI then ScheduleSave() end
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
	Callback = function() Library:Toggle() end,
	ChangedCallback = function(nk)
		if typeof(nk) == "EnumItem" then Config.MenuBind = nk.Name end
		ScheduleSave()
	end,
})

MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", { Text = "Auto Execute Script", Tooltip = "Auto execute on start" }, function(v)
	Config.AutoExecute = v
	if v then RunAutoExecute() end
end)

AddFeatureToggle(MenuBox, "AutoReconnect", { Text = "Auto Reconnect", Tooltip = "Reconnect if disconnected" }, function(v)
	Config.AutoReconnect = v
	if v then AutoReconnectLoop() end
end)

AddFeatureToggle(MenuBox, "AutoHideUi", { Text = "Auto Hide UI", Tooltip = "Hide UI after 30 seconds" }, function(v)
	Config.AutoHideUi = v
	if v then AutoHideUiLoop() end
end)

AddFeatureToggle(MenuBox, "AntiAfk", { Text = "Anti AFK", Tooltip = "Prevent AFK kick" }, function(v)
	Config.AntiAfk = v
	if v then AntiAfkLoop() end
end)

AddFeatureToggle(MenuBox, "NoGameplayPaused", { Text = "No Gameplay Paused", Tooltip = "Prevent gameplay pause" }, function(v)
	Config.NoGameplayPaused = v
	if v then NoPauseLoop() end
end)

MenuBox:AddDivider()

MenuBox:AddButton({
	Text = "Stop All Features",
	Func = function()
		for _, k in ipairs({ "AutoSpikeBall", "AutoRebirth", "InstantChallenge", "FreeRainbowPack", "AutoUsePotion", "AutoSpinWheel", "AutoUpgrade", "AutoBuyBall", "AutoBuyTrail", "AutoReconnect", "AutoHideUi", "AntiAfk", "NoGameplayPaused" }) do
			Config[k] = false
		end
		for _, t in Library.Toggles do
			if t.Value then t:SetValue(false) end
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
		local n = SanitizeConfigName(ConfigNameInput.Value)
		if not n then Notify("Config", "Enter a valid config name", "Warning") return end
		if ConfigExists(n) then Notify("Config", "'" .. n .. "' already exists", "Warning") return end
		if SaveConfigData(n) then
			CurrentConfig = n RefreshConfigList(n)
			Notify("Config", "Config '" .. n .. "' created", "Success")
		else
			Notify("Config", "Config saving not supported", "Error")
		end
	end,
	Tooltip = "Create config",
})

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {
	Text = "Config list",
	Values = { "---" },
	Default = "---",
	Callback = function(v) CurrentConfig = v == "---" and nil or v end,
})

local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Autoload: <font color="#60d888">none</font>' })

RefreshConfigList = function(sel)
	local vals = { "---" }
	for _, n in ipairs(GetConfigList()) do table.insert(vals, n) end
	ConfigListDropdown:SetValues(vals)
	local choice = sel or CurrentConfig or "---"
	if not table.find(vals, choice) then choice = "---" end
	ConfigListDropdown:SetValue(choice)
	CurrentConfig = choice == "---" and nil or choice
end

local function UpdateAutoloadLabel()
	local n = GetAutoloadName()
	AutoloadLabel:SetText('Autoload: <font color="#60d888">' .. (n or "none") .. '</font>')
end

ConfigBox:AddButton({
	Text = "Load config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning") return end
		if LoadConfig(CurrentConfig, false) then Notify("Config", "Config loaded", "Success") end
	end,
	Tooltip = "Load config",
})

ConfigBox:AddButton({
	Text = "Overwrite config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning") return end
		if SaveConfigData(CurrentConfig) then Notify("Config", "Config overwritten", "Success") end
	end,
	Tooltip = "Overwrite config",
})

ConfigBox:AddButton({
	Text = "Delete config",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning") return end
		pcall(function() delfile(ConfigPath(CurrentConfig)) end)
		if GetAutoloadName() == CurrentConfig then ClearAutoload() end
		CurrentConfig = nil RefreshConfigList() UpdateAutoloadLabel()
		Notify("Config", "Config deleted", "Warning")
	end,
	Tooltip = "Delete config",
	Risky = true,
})

ConfigBox:AddButton({ Text = "Refresh list", Func = function() RefreshConfigList() Notify("Config", "List refreshed", "Info") end, Tooltip = "Refresh list" })

ConfigBox:AddButton({
	Text = "Set as autoload",
	Func = function()
		if not CurrentConfig then Notify("Config", "Select a config first", "Warning") return end
		if SetAutoload(CurrentConfig) then UpdateAutoloadLabel() Notify("Config", "Autoload set", "Success") end
	end,
	Tooltip = "Set as autoload",
})

ConfigBox:AddButton({ Text = "Reset autoload", Func = function() ClearAutoload() UpdateAutoloadLabel() Notify("Config", "Autoload cleared", "Info") end, Tooltip = "Reset autoload" })

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", { Text = "Auto Save Config", Tooltip = "Save config automatically" }, function(v) Config.AutoSave = v end)

-- ===== STARTUP =====

ApplyTheme(Themes[Config.ThemeName])
Library:SetFont(Enum.Font[Config.FontName])

task.delay(1, function()
	local an = GetAutoloadName()
	if an and ConfigExists(an) then
		CurrentConfig = an
		if LoadConfig(an, true) then Notify("Config", "Autoloaded '" .. an .. "'", "Success") end
	end
	RunAutoExecute() UpdateAutoloadLabel() RefreshConfigList()
end)

Notify("AntiGodHub", "Loaded", "Success")