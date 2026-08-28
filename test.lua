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

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Config
local Config = {
	AutoFishSecret = false,
	AutoSell = false,
	AutoBuyRod = false,
	AutoUpgrade = false,
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

-- Read FishConfig: returns { fishName = { ... }, ... }
local function GetFishConfig()
	local fishData = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild("FishConfig")
		if mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				fishData = data
			end
		end
	end)
	return fishData
end

-- Read RodsConfig: returns array of rod names
local function GetRodNames()
	local rods = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild("RodsConfig")
		if mod:IsA("ModuleScript") then
			local ok, data = pcall(require, mod)
			if ok and type(data) == "table" then
				for _, rod in ipairs(data) do
					if type(rod) == "table" and type(rod.name) == "string" then
						table.insert(rods, rod.name)
					end
				end
				if #rods == 0 then
					for k, v in pairs(data) do
						if type(k) == "string" and type(v) == "table" then
							table.insert(rods, k)
						end
					end
					table.sort(rods)
				end
			end
		end
	end)
	return rods
end

-- Get all fish names from FishConfig
local function GetAllFishNames()
	local names = {}
	pcall(function()
		local mod = ReplicatedStorage:WaitForChild("FishConfig")
		local ok, data = pcall(require, mod)
		if ok and type(data) == "table" then
			for k, v in pairs(data) do
				if type(k) == "string" then
					table.insert(names, k)
				end
			end
		end
	end)
	return names
end

-- ===== CORE FUNCTIONS =====

-- 1. GET ALL INDEX
local function GetAllIndex()
	local fishNames = GetAllFishNames()
	if #fishNames == 0 then
		Notify("Get All Index", "Could not read FishConfig", "Error")
		return
	end

	local CatchEvent = Remotes:WaitForChild("CaughtFish")
	local totalSent = 0

	-- Pass 1: all fish with empty rarity
	for _, fishName in ipairs(fishNames) do
		pcall(function()
			CatchEvent:FireServer(fishName, 999999999, "", 999999999, 999999999)
		end)
		totalSent = totalSent + 1
		task.wait(0.1)
	end

	-- Pass 2: all fish with Night
	for _, fishName in ipairs(fishNames) do
		pcall(function()
			CatchEvent:FireServer(fishName, 999999999, "Night", 999999999, 999999999)
		end)
		totalSent = totalSent + 1
		task.wait(0.1)
	end

	-- Pass 3: all fish with Big
	for _, fishName in ipairs(fishNames) do
		pcall(function()
			CatchEvent:FireServer(fishName, 999999999, "Big", 999999999, 999999999)
		end)
		totalSent = totalSent + 1
		task.wait(0.1)
	end

	-- Pass 4: all fish with Huge
	for _, fishName in ipairs(fishNames) do
		pcall(function()
			CatchEvent:FireServer(fishName, 999999999, "Huge", 999999999, 999999999)
		end)
		totalSent = totalSent + 1
		task.wait(0.1)
	end

	Notify("Get All Index", "Done! Sent " .. totalSent .. " fish", "Success")
end

-- 2. AUTO FISH SECRET
local function AutoFishSecret()
	pcall(function()
		Remotes:WaitForChild("CaughtFish"):FireServer("Emberfin", 999999999, "Huge", 999999999, 999999999)
	end)
end

-- 3. AUTO SELL
local function AutoSell()
	pcall(function()
		Remotes:WaitForChild("SellInventory"):InvokeServer()
	end)
end

-- 4. AUTO BUY ROD
local function AutoBuyRod()
	local rodNames = GetRodNames()
	if #rodNames == 0 then return end
	local BuyRod = Remotes:WaitForChild("BuyRod")
	for _, rodName in ipairs(rodNames) do
		pcall(function()
			BuyRod:FireServer(rodName)
		end)
		task.wait(0.1)
	end
end

-- 5. AUTO UPGRADE
local function AutoUpgrade()
	local upgrades = {"Hole", "Sell", "Bag"}
	local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
	for _, upgradeName in ipairs(upgrades) do
		pcall(function()
			BuyUpgrade:FireServer(upgradeName)
		end)
		task.wait(0.1)
	end
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

local function Notify(title, desc, typ)
	pcall(function()
		if type(title) == "string" and #title > 60 then title = title:sub(1, 57) .. "..." end
		if not desc or desc == "" then desc = " "
		elseif type(desc) == "string" and #desc > 60 then desc = desc:sub(1, 57) .. "..." end
		typ = typ or "Info"
		Library:Notify({ Title = title, Description = desc, Time = 4, Type = typ, DescriptionColor = NotifyColors[typ] })
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
			local toggle = Library.Toggles.AutoFishSecret
			if toggle and not toggle.Value then toggle:SetValue(true) end
		end
	end)
end

-- ===== THEME =====

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

-- ===== CONFIG SAVE/LOAD =====

local ConfigsDir = "FishingHub/Configs"
local AutoloadPath = "FishingHub/Autoload.json"
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
		makefolder("FishingHub") makefolder(ConfigsDir)
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
		makefolder("FishingHub") makefolder(ConfigsDir)
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
	pcall(function() makefolder("FishingHub") writefile(AutoloadPath, HttpService:JSONEncode({ Name = name })) end)
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

-- ===== UI WINDOW =====

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

-- ===== INFO TAB =====

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
	"Get All Index", "Auto Fish Secret", "Auto Sell", "Auto Buy Rod", "Auto Upgrade",
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

-- ===== MAIN TAB - FARMING =====

local FarmBox = MainTabs.Farming:AddLeftGroupbox("Auto Farming", "star")

FarmBox:AddButton({ Text = "Get All Index", Func = function()
	task.spawn(function()
		Notify("Get All Index", "Starting...", "Info")
		GetAllIndex()
	end)
end, Tooltip = "Process all fish by rarity" })

AddFeatureToggle(FarmBox, "AutoFishSecret", { Text = "Auto Fish Secret", Tooltip = "Auto fish Emberfin Huge", Notify = true }, function(v)
	Config.AutoFishSecret = v
	if v then task.spawn(function() while Config.AutoFishSecret do AutoFishSecret() task.wait(0.0000000001) end end) end
end)

AddFeatureToggle(FarmBox, "AutoSell", { Text = "Auto Sell", Tooltip = "Sell inventory automatically", Notify = true }, function(v)
	Config.AutoSell = v
	if v then task.spawn(function() while Config.AutoSell do AutoSell() task.wait(0.0000001) end end) end
end)

-- ===== MAIN TAB - UPGRADE =====

local UpgradeBox = MainTabs.Upgrade:AddLeftGroupbox("Upgrade", "trending-up")

AddFeatureToggle(UpgradeBox, "AutoBuyRod", { Text = "Auto Buy Rod", Tooltip = "Buy all rods automatically", Notify = true }, function(v)
	Config.AutoBuyRod = v
	if v then task.spawn(function() while Config.AutoBuyRod do AutoBuyRod() task.wait(0.1) end end) end
end)

AddFeatureToggle(UpgradeBox, "AutoUpgrade", { Text = "Auto Upgrade", Tooltip = "Buy all upgrades automatically", Notify = true }, function(v)
	Config.AutoUpgrade = v
	if v then task.spawn(function() while Config.AutoUpgrade do AutoUpgrade() task.wait(0.001) end end) end
end)

-- ===== SETTINGS TAB =====

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
	Config.AutoFishSecret = false Config.AutoSell = false Config.AutoBuyRod = false Config.AutoUpgrade = false
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

-- ===== STARTUP =====

ApplyTheme(Themes[Config.ThemeName])
Library:SetFont(Enum.Font[Config.FontName])

task.delay(1, function()
	local an = GetAutoloadName()
	if an and ConfigExists(an) then CurrentConfig = an if LoadConfig(an, true) then Notify("Config", "Autoloaded '" .. an .. "'", "Success") end end
	RunAutoExecute() UpdateAutoloadLabel() RefreshConfigList()
end)

Notify("AntiGodHub", "Loaded", "Success")