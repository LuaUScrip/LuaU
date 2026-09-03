--// ═══════════════════════════════════════════════════════════
--// 🥚 AntiGodHub — Egg Hunt Script
--// Obsidian GUI Library
--// ═══════════════════════════════════════════════════════════

local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()
if not Library then warn("ERROR: Failed to load library") return end

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

-- Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
Player.CharacterAdded:Connect(function(c)
	Character = c
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

-- Remotes
local Events = ReplicatedStorage:WaitForChild("Events")
local EquipBestPetsEvent = Events:WaitForChild("EquipBestPets")
local RequestSellEvent = Events:WaitForChild("RequestSell")
local RequestRebirthEvent = Events:WaitForChild("RequestRebirth")
local TrailActionEvent = Events:WaitForChild("TrailAction")
local RequestPlotUpgradeEvent = Events:WaitForChild("RequestPlotUpgrade")
local TrailConfigurations = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TrailConfigurations")

-- Config
local Config = {
	AutoCollectEgg = false,
	AntiCaught = false,
	EquipBestPet = false,
	SellInventory = false,
	Rebirth = false,
	AutoBuyTrail = false,
	PlotUpgrade = false,
	AntiAfk = false,
	NoGameplayPaused = false,
	AutoReconnect = false,
	AutoHideUi = false,
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

-- ═══════════════════════════════════════════════════════════
-- TRAIL MODULE READER
-- ═══════════════════════════════════════════════════════════

local function GetTrailNames()
	local trails = {}
	pcall(function()
		if typeof(TrailConfigurations) == "ModuleScript" then
			local ok, data = pcall(require, TrailConfigurations)
			if ok and type(data) == "table" then
				local trailTable = data["Trails"] or data["trails"]
				if type(trailTable) == "table" then
					for _, trail in ipairs(trailTable) do
						if type(trail) == "table" and type(trail["ID"]) == "string" then
							table.insert(trails, trail["ID"])
						end
					end
				end
			end
		end
	end)
	return trails
end

-- ═══════════════════════════════════════════════════════════
-- CORE FUNCTIONS
-- ═══════════════════════════════════════════════════════════

local function FirePrompt(prompt, retries)
	retries = retries or 3
	if not prompt then return false end
	pcall(function()
		prompt.MaxActivationDistance = 20
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
	end)
	for i = 1, retries do
		local ok = pcall(function() fireproximityprompt(prompt) end)
		if ok then return true end
		task.wait(0.05)
	end
	return false
end

local function GetZone5Prompts()
	local prompts = {}
	pcall(function()
		local eggs = Workspace:FindFirstChild("Eggs")
		if not eggs then return end
		local zone5 = eggs:FindFirstChild("Zone5")
		if not zone5 then return end
		for _, eggSpawn in ipairs(zone5:GetChildren()) do
			if eggSpawn.Name == "EggSpawn" then
				local spawnedEgg = eggSpawn:FindFirstChild("SpawnedEgg")
				if spawnedEgg then
					for _, desc in ipairs(spawnedEgg:GetDescendants()) do
						if desc:IsA("ProximityPrompt") then
							table.insert(prompts, { prompt = desc, part = desc.Parent })
						end
					end
				end
			end
		end
	end)
	return prompts
end

local function AutoCollectEgg()
	pcall(function()
		local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local homeCFrame = hrp.CFrame
		local eggData = GetZone5Prompts()
		if #eggData == 0 then return end
		for _, data in ipairs(eggData) do
			if not Config.AutoCollectEgg then break end
			local prompt = data.prompt
			local part = data.part
			if part and part.Parent then
				hrp.CFrame = part.CFrame + Vector3.new(0, 2, 0)
				task.wait(0.2)
				FirePrompt(prompt, 3)
				task.wait(0.03)
				hrp.CFrame = homeCFrame
				task.wait(0.01)
			end
		end
	end)
end

local function AntiCaught()
	pcall(function()
		local bosses = Workspace:FindFirstChild("Bosses")
		if bosses then
			for _, child in ipairs(bosses:GetChildren()) do
				if child:IsA("Folder") or child:IsA("Model") then child:Destroy() end
			end
		end
	end)
end

local function EquipBestPet() pcall(function() EquipBestPetsEvent:FireServer() end) end
local function SellInventoryFunc() pcall(function() RequestSellEvent:FireServer("Inventory") end) end
local function Rebirth() pcall(function() RequestRebirthEvent:FireServer() end) end

local function AutoBuyTrail()
	pcall(function()
		local trailIDs = GetTrailNames()
		if #trailIDs > 0 then
			for _, trailID in ipairs(trailIDs) do
				TrailActionEvent:FireServer("BuyMoney", trailID)
				task.wait(0.1)
			end
		else
			TrailActionEvent:FireServer("BuyMoney", "list")
		end
	end)
end

local function PlotUpgrade() pcall(function() RequestPlotUpgradeEvent:InvokeServer() end) end

-- ═══════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════

local function CopyToClipboard(text)
	local s = pcall(setclipboard, text)
	if not s then pcall(toclipboard, text) end
end

local NotifyColors = { Success = Color3.fromRGB(96,216,118), Warning = Color3.fromRGB(255,176,80), Error = Color3.fromRGB(255,96,96) }

local function Notify(title, desc, typ)
	pcall(function()
		if type(title) == "string" and #title > 60 then title = title:sub(1,57) .. "..." end
		if not desc or desc == "" then desc = " " elseif type(desc) == "string" and #desc > 60 then desc = desc:sub(1,57) .. "..." end
		typ = typ or "Info"
		Library:Notify({ Title = title, Description = desc, Time = 4, Type = typ, DescriptionColor = NotifyColors[typ] })
	end)
end

local function AntiAfkLoop()
	task.spawn(function()
		while Config.AntiAfk do task.wait(600) pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end
	end)
end

Players.LocalPlayer.Idled:Connect(function()
	if Config.AntiAfk then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end
end)

local function NoPauseLoop()
	task.spawn(function()
		while Config.NoGameplayPaused do task.wait(20) pcall(function()
			local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0) end
		end) end
	end)
end

local function AutoReconnectLoop()
	task.spawn(function()
		while Config.AutoReconnect do task.wait(0.5) pcall(function()
			local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
			local frame = gui and gui:FindFirstChild("DisconnectedFrame")
			if frame and frame.Visible then TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end
		end) end
	end)
end

local function AutoHideUiLoop()
	task.spawn(function()
		local t = 0
		while Config.AutoHideUi do task.wait(1)
			if Library.Toggled then t = t + 1 if t >= 30 then Library:Toggle() t = 0 end else t = 0 end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- THEME
-- ═══════════════════════════════════════════════════════════

local function MakeTheme(a, b, m, o, f) return { AccentColor = a, BackgroundColor = b, MainColor = m, OutlineColor = o, FontColor = f } end

local Themes = {
	["Emerald Green"] = MakeTheme(Color3.fromRGB(96,216,118), Color3.fromRGB(8,16,10), Color3.fromRGB(16,28,20), Color3.fromRGB(30,58,40), Color3.fromRGB(255,255,255)),
	["Obsidian (Default)"] = MakeTheme(Color3.fromRGB(125,85,255), Color3.fromRGB(15,15,15), Color3.fromRGB(25,25,25), Color3.fromRGB(40,40,40), Color3.fromRGB(255,255,255)),
	["Midnight Blue"] = MakeTheme(Color3.fromRGB(96,165,255), Color3.fromRGB(8,10,16), Color3.fromRGB(18,22,32), Color3.fromRGB(38,46,64), Color3.fromRGB(255,255,255)),
	["Blood Red"] = MakeTheme(Color3.fromRGB(255,76,76), Color3.fromRGB(16,8,8), Color3.fromRGB(28,14,14), Color3.fromRGB(64,30,30), Color3.fromRGB(255,255,255)),
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

-- ═══════════════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════════════

local ConfigsDir = "AntiGodHub/Configs"
local AutoloadPath = "AntiGodHub/Autoload.json"
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
		makefolder("AntiGodHub") makefolder(ConfigsDir)
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
		makefolder("AntiGodHub") makefolder(ConfigsDir)
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
	pcall(function() makefolder("AntiGodHub") writefile(AutoloadPath, HttpService:JSONEncode({ Name = name })) end)
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
	if type(data.ThemeName) == "string" and Themes[data.ThemeName] then Config.ThemeName = data.ThemeName ApplyTheme(Themes[data.ThemeName]) end
	if type(data.Colors) == "table" then
		for k, rgb in data.Colors do
			if Config.CustomColors[k] ~= nil and type(rgb) == "table" then
				local r, g, b = rgb[1], rgb[2], rgb[3]
				if type(r) == "number" and type(g) == "number" and type(b) == "number" then Config.CustomColors[k] = Color3.fromRGB(r, g, b) end
			end
		end
		ApplyCustomColors()
	end
	if type(data.FontName) == "string" and Enum.Font[data.FontName] then Config.FontName = data.FontName Library:SetFont(Enum.Font[data.FontName]) end
	if type(data.MenuBind) == "string" and data.MenuBind ~= "None" then Config.MenuBind = data.MenuBind end
	if type(data.Toggles) == "table" then for id, val in data.Toggles do local t = Library.Toggles[id] if t and type(val) == "boolean" then t:SetValue(val) end end end
	if SettingsRefs.ThemeDropdown then SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName) end
	if SettingsRefs.FontDropdown then SettingsRefs.FontDropdown:SetValue(Config.FontName) end
	SyncColorPickers()
	SuppressUI = false
	CurrentConfig = name
	return true
end

local function AddFeatureToggle(box, id, info, cb)
	return box:AddToggle(id, {
		Text = info.Text, Default = false,
		Callback = function(val)
			if cb then cb(val) end
			if info.Notify and not SuppressUI then Notify(info.Text .. " " .. (val and "On" or "Off"), "", val and "Success" or "Warning") end
			ScheduleSave()
		end,
	})
end

-- ═══════════════════════════════════════════════════════════
-- UI WINDOW
-- ═══════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════
-- INFO TAB
-- ═══════════════════════════════════════════════════════════

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
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated ' .. os.date("%m/%d/%Y") .. '</font>' })

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
SocialsBox:AddButton({ Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) Notify("Socials", "Discord link copied!", "Success") end })
SocialsBox:AddButton({ Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) Notify("Socials", "YouTube link copied!", "Success") end })
SocialsBox:AddButton({ Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) Notify("Socials", "TikTok link copied!", "Success") end })

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
for _, f in ipairs({
	"Auto Collect Egg", "Anti Caught", "Equip Best Pet", "Sell Inventory",
	"Rebirth", "Auto Buy Trail", "Plot Upgrade",
	"Anti AFK", "No Gameplay Paused", "Auto Reconnect", "Auto Hide UI",
	"Theme Manager", "Config System",
}) do FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ ' .. f .. '</font>' }) end

local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local e = os.clock() - ScriptStartTime
		pcall(function() SessionLabel:SetText('SESSION - <font color="#60d888">' .. math.floor(e/60) .. 'm ' .. math.floor(e%60) .. 's</font>') end)
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- MAIN TAB — FARMING
-- ═══════════════════════════════════════════════════════════

local FarmBox = Tabs.Main:AddLeftGroupbox("Farming", "star")

AddFeatureToggle(FarmBox, "AutoCollectEgg", { Text = "Auto Collect Egg", Notify = true }, function(v)
	Config.AutoCollectEgg = v
	if v then task.spawn(function() while Config.AutoCollectEgg do AutoCollectEgg() task.wait(0.5) end end) end
end)

AddFeatureToggle(FarmBox, "AntiCaught", { Text = "Anti Caught", Notify = true }, function(v)
	Config.AntiCaught = v
	if v then task.spawn(function() while Config.AntiCaught do AntiCaught() task.wait(0.5) end end) end
end)

AddFeatureToggle(FarmBox, "EquipBestPet", { Text = "Equip Best Pet", Notify = true }, function(v)
	Config.EquipBestPet = v
	if v then EquipBestPet() end
end)

AddFeatureToggle(FarmBox, "SellInventory", { Text = "Sell Inventory", Notify = true }, function(v)
	Config.SellInventory = v
	if v then SellInventoryFunc() end
end)

AddFeatureToggle(FarmBox, "Rebirth", { Text = "Rebirth", Notify = true }, function(v)
	Config.Rebirth = v
	if v then Rebirth() end
end)

AddFeatureToggle(FarmBox, "AutoBuyTrail", { Text = "Auto Buy Trail", Notify = true }, function(v)
	Config.AutoBuyTrail = v
	if v then task.spawn(function() while Config.AutoBuyTrail do AutoBuyTrail() task.wait(0.5) end end) end
end)

AddFeatureToggle(FarmBox, "PlotUpgrade", { Text = "Plot Upgrade", Notify = true }, function(v)
	Config.PlotUpgrade = v
	if v then PlotUpgrade() end
end)

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

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

AddFeatureToggle(MenuBox, "AutoReconnect", { Text = "Auto Reconnect" }, function(v) Config.AutoReconnect = v if v then AutoReconnectLoop() end end)
AddFeatureToggle(MenuBox, "AutoHideUi", { Text = "Auto Hide UI" }, function(v) Config.AutoHideUi = v if v then AutoHideUiLoop() end end)
AddFeatureToggle(MenuBox, "AntiAfk", { Text = "Anti AFK" }, function(v) Config.AntiAfk = v if v then AntiAfkLoop() end end)
AddFeatureToggle(MenuBox, "NoGameplayPaused", { Text = "No Gameplay Paused" }, function(v) Config.NoGameplayPaused = v if v then NoPauseLoop() end end)
MenuBox:AddDivider()

MenuBox:AddButton({ Text = "Stop All Features", Func = function()
	Config.AutoCollectEgg = false Config.AntiCaught = false Config.EquipBestPet = false
	Config.SellInventory = false Config.Rebirth = false Config.AutoBuyTrail = false Config.PlotUpgrade = false
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

AddFeatureToggle(ConfigBox, "AutoSave", { Text = "Auto Save Config" }, function(v) Config.AutoSave = v end)

-- ═══════════════════════════════════════════════════════════
-- STARTUP
-- ═══════════════════════════════════════════════════════════

ApplyTheme(Themes[Config.ThemeName])
Library:SetFont(Enum.Font[Config.FontName])

task.delay(1, function()
	local an = GetAutoloadName()
	if an and ConfigExists(an) then CurrentConfig = an if LoadConfig(an, true) then Notify("Config", "Autoloaded '" .. an .. "'", "Success") end end
	UpdateAutoloadLabel() RefreshConfigList()
end)

Notify("AntiGodHub", "Loaded", "Success")