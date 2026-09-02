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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- ===== FIREPROXIMITYPROMPT - ONLY IN FARMING FUNCTION =====
-- Removed global scanner to prevent freezing - only fires StealPrompt during farming

-- Bypass Teleport System
local function get_hrp()
	local char = Player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function bypass_teleport(target)
	local hrp = get_hrp()
	if not hrp then return end
	local target_pos
	if typeof(target) == "Vector3" then
		target_pos = target
	elseif typeof(target) == "CFrame" then
		target_pos = target.Position
	elseif typeof(target) == "Instance" and target:IsA("BasePart") then
		target_pos = target.Position
	elseif typeof(target) == "string" then
		local part = Workspace:FindFirstChild(target)
		if part then target_pos = part.Position end
	end
	if target_pos then
		pcall(function()
			hrp.CFrame = CFrame.new(target_pos)
			hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		end)
	end
end

getgenv().bypass_teleport = bypass_teleport

-- Lucky Blocks List
local LuckyBlocksList = {
	"Secret Lucky Block",
	"Exclusive Lucky Block",
	"Cosmic Lucky Block",
	"Spain Lucky Block",
	"Icons Lucky Block",
	"Japan Lucky Block",
	"Limited Lucky Block",
	"Champions Lucky Block",
	"Nightmare Lucky Block",
	"Meltdown Lucky Block",
	"Slime God Lucky Block",
	"OG Lucky Block",
}

-- Configuration
local Config = {
	HomePosition = Vector3.new(198, 3, 280),
	SelectedLuckyBlocks = {},
	FarmActive = false,
	CollectActive = false,
	OpenActive = false,
	UpgradeSlimeActive = false,
	UpgradeJumpActive = false,
	RebirthActive = false,
	PurchaseFloorActive = false,
	SellAllActive = false,
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

-- ===== UTILITY =====

local function CopyToClipboard(Text)
	local Success = pcall(setclipboard, Text)
	if not Success then pcall(toclipboard, Text) end
end

local NotifyColors = {
	Success = Color3.fromRGB(96, 216, 118),
	Warning = Color3.fromRGB(255, 176, 80),
	Error = Color3.fromRGB(255, 96, 96),
}

local function Notify(Title, Description, Type)
	pcall(function()
		if type(Title) == "string" and #Title > 60 then Title = Title:sub(1, 57) .. "..." end
		if Description == nil or Description == "" then Description = " "
		elseif type(Description) == "string" and #Description > 60 then Description = Description:sub(1, 57) .. "..." end
		Type = Type or "Info"
		Library:Notify({ Title = Title, Description = Description, Time = 4, Type = Type, DescriptionColor = NotifyColors[Type] })
	end)
end

-- ===== CORE REMOTE FUNCTIONS =====

local Network = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes")

-- Helper: fire ALL proximity prompts on an instance and its descendants
local function fireAllPrompts(instance)
	pcall(function()
		for _, obj in pairs(instance:GetDescendants()) do
			if obj:IsA("ProximityPrompt") then
				pcall(fireproximityprompt, obj, 0)
				task.wait(0.1)
			end
		end
		-- Also check the instance itself
		if instance:IsA("ProximityPrompt") then
			pcall(fireproximityprompt, instance, 0)
		end
	end)
end

-- 1. AUTO FARM LUCKY BLOCKS (uses SelectedLuckyBlocks, only StealPrompt)
local function FarmLuckyBlock()
	local hrp = get_hrp()
	if not hrp or not hrp.Parent then return end
	if type(Config.SelectedLuckyBlocks) ~= "table" or #Config.SelectedLuckyBlocks == 0 then return end

	local slimesFolder = Workspace:FindFirstChild("Live") and Workspace.Live:FindFirstChild("Slimes")
	if not slimesFolder then return end

	-- Farm each selected block
	for _, blockName in ipairs(Config.SelectedLuckyBlocks) do
		local slime = slimesFolder:FindFirstChild(blockName)
		if slime then
			local rootPart = slime:FindFirstChild("RootPart")
			if rootPart then
				-- Teleport to slime
				pcall(function()
					hrp.CFrame = rootPart.CFrame
					hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end)
				task.wait(0.3)

				-- Fire ONLY StealPrompt on this slime
				pcall(function()
					-- Try StealPrompt directly
					local prompt = slime:FindFirstChild("StealPrompt")
					if prompt and prompt:IsA("ProximityPrompt") then
						fireproximityprompt(prompt)
					else
						-- Fallback: find any ProximityPrompt named StealPrompt in descendants
						for _, child in pairs(slime:GetDescendants()) do
							if child:IsA("ProximityPrompt") and child.Name == "StealPrompt" then
								fireproximityprompt(child)
								break
							end
						end
					end
				end)
				task.wait(0.2)
			end
		end
	end

	-- Return home
	pcall(function()
		hrp.CFrame = CFrame.new(Config.HomePosition)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end)
	task.wait(0.3)
end

-- 2. AUTO COLLECT CASH
local function CollectEarnings(Slot)
	pcall(function()
		Network:WaitForChild("Collect Earnings"):FireServer(tostring(Slot))
	end)
end

-- 3. AUTO UPGRADE SLIME
local function UpgradeSoccerSlot(SlotId)
	pcall(function()
		Network:WaitForChild("Upgrade Slime"):FireServer(tostring(SlotId))
	end)
end

-- 4. AUTO UPGRADE JUMP
local function BuyJumpUpgrade()
	pcall(function()
		Network:WaitForChild("Buy Speed Upgrade"):FireServer(3)
	end)
end

-- 5. AUTO REBIRTH
local function DoRebirth()
	pcall(function()
		Network:WaitForChild("Rebirth"):FireServer()
	end)
end

-- 6. AUTO SELL ALL
local function SellAllSlimes()
	pcall(function()
		Network:WaitForChild("Sell All Slimes"):FireServer()
	end)
end

-- ===== LOOP FUNCTIONS =====

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
				if OpenFor >= 30 then Library:Toggle(false) OpenFor = 0 end
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
				local HRP = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
				if HRP then HRP.AssemblyLinearVelocity = HRP.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0) end
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

-- ===== THEME =====

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

local FontNames = {"Code", "Gotham", "Roboto", "Cartoon", "Arial", "SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito"}

local function SyncColorPickers()
	local PickerMap = {
		AccentColor = "ThemeAccent", FontColor = "ThemeFontColor",
		BackgroundColor = "ThemeBackground", MainColor = "ThemeMain", OutlineColor = "ThemeOutline",
	}
	for Key, Idx in PickerMap do
		local Picker = Library.Options[Idx]
		if Picker and Picker.SetValueRGB then Picker:SetValueRGB(Config.CustomColors[Key]) end
	end
end

-- ===== CONFIG SAVE/LOAD =====

local ConfigsDir = "LuckyBlocksHub/Configs"
local AutoloadPath = "LuckyBlocksHub/Autoload.json"
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
		makefolder("LuckyBlocksHub") makefolder(ConfigsDir)
		for _, Path in listfiles(ConfigsDir) do
			if Path:sub(-5) == ".json" then
				local Name = Path:match("([^/\\]+)%.json$")
				if Name and Name ~= "---" then table.insert(List, Name) end
			end
		end
	end)
	table.sort(List) return List
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
		makefolder("LuckyBlocksHub") makefolder(ConfigsDir)
		local Data = { Toggles = {}, ThemeName = Config.ThemeName, FontName = Config.FontName, MenuBind = Config.MenuBind, SelectedLuckyBlocks = Config.SelectedLuckyBlocks, Colors = {} }
		for Key, Color in Config.CustomColors do Data.Colors[Key] = { math.floor(Color.R * 255), math.floor(Color.G * 255), math.floor(Color.B * 255) } end
		for Id, Toggle in Library.Toggles do Data.Toggles[Id] = Toggle.Value end
		writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
	end) return true
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
	pcall(function() makefolder("LuckyBlocksHub") writefile(AutoloadPath, HttpService:JSONEncode({ Name = Name })) end)
	return true
end

local function ClearAutoload()
	pcall(function() if isfile and isfile(AutoloadPath) then delfile(AutoloadPath) end end)
end

local SaveQueued = false
local function ScheduleSave()
	if not Config.AutoSave or not CurrentConfig or SaveQueued then return end
	SaveQueued = true task.delay(1, function() SaveQueued = false SaveConfigData(CurrentConfig) end)
end

local LoadConfig
LoadConfig = function(Name, Silent)
	Name = SanitizeConfigName(Name)
	if not Name then return false end
	if not isfile or not readfile then if not Silent then Notify("Config", "Config loading not supported", "Error") end return false end
	if not isfile(ConfigPath(Name)) then if not Silent then Notify("Config", "Config '" .. Name .. "' not found", "Warning") end return false end
	local Success, Data = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath(Name))) end)
	if not Success or type(Data) ~= "table" then if not Silent then Notify("Config", "Failed to read configuration", "Error") end return false end
	SuppressUI = true
	if type(Data.ThemeName) == "string" and Themes[Data.ThemeName] then Config.ThemeName = Data.ThemeName ApplyTheme(Themes[Data.ThemeName]) end
	if type(Data.Colors) == "table" then
		for Key, RGB in Data.Colors do
			if Config.CustomColors[Key] ~= nil and type(RGB) == "table" then
				local R, G, B = RGB[1], RGB[2], RGB[3]
				if type(R) == "number" and type(G) == "number" and type(B) == "number" then Config.CustomColors[Key] = Color3.fromRGB(R, G, B) end
			end
		end ApplyCustomColors()
	end
	if type(Data.FontName) == "string" and Enum.Font[Data.FontName] then Config.FontName = Data.FontName Library:SetFont(Enum.Font[Data.FontName]) end
	if type(Data.MenuBind) == "string" and Data.MenuBind ~= "None" then Config.MenuBind = Data.MenuBind end
	if type(Data.SelectedLuckyBlocks) == "table" then Config.SelectedLuckyBlocks = Data.SelectedLuckyBlocks end
	if type(Data.Toggles) == "table" then for Id, Value in Data.Toggles do local Toggle = Library.Toggles[Id] if Toggle and type(Value) == "boolean" then Toggle:SetValue(Value) end end end
	if SettingsRefs.ThemeDropdown then SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName) end
	if SettingsRefs.FontDropdown then SettingsRefs.FontDropdown:SetValue(Config.FontName) end
	if SettingsRefs.LuckyBlockDropdown then SettingsRefs.LuckyBlockDropdown:SetValue(Config.SelectedLuckyBlocks) end
	SyncColorPickers() SuppressUI = false CurrentConfig = Name return true
end

local function AddFeatureToggle(Box, Id, Info, OnToggle)
	return Box:AddToggle(Id, {
		Text = Info.Text, Default = false,
		Callback = function(Value)
			if OnToggle then OnToggle(Value) end
			if Info.Notify and not SuppressUI then Notify(Info.Text .. " " .. (Value and "On" or "Off"), "", Value and "Success" or "Warning") end
			ScheduleSave()
		end,
	})
end

local function RunAutoExecute()
	task.delay(3, function()
		if Config.AutoExecute then
			local AutoFarm = Library.Toggles.AutoFarmLuckyBlocks
			if AutoFarm and not AutoFarm.Value then AutoFarm:SetValue(true) end
		end
	end)
end

-- ===== UI WINDOW =====

local Window = Library:CreateWindow({
	Title = "AntiGodHub", Icon = 125265885440515,
	Footer = { { Text = Config.DiscordLink, Copyable = true }, { Text = " | " }, { Text = "AntiGodHub", Copyable = true } },
	CornerRadius = 20, AutoShow = true, ShowMobileButtons = false, Minimizable = true, Resizable = true,
	Animations = { ToggleWindow = true, TabSwitch = true, Groupbox = true, Dropdown = true },
})
Library.ToggleKeybind = nil

local ToggleButton = Library:AddDraggableButton("Toggle", function() Library:Toggle() end, true, true)
local LockButton = Library:AddDraggableButton("Lock", function(self) Library.CantDragForced = not Library.CantDragForced self:SetText(Library.CantDragForced and "Unlock" or "Lock") end, true, true)
ToggleButton.Button.AnchorPoint = Vector2.new(0, 0) ToggleButton.Button.Position = UDim2.fromOffset(6, 6)
LockButton.Button.AnchorPoint = Vector2.new(0, 0) LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)

local Tabs = {
	Info = Window:AddTab({ Name = "Info", Icon = "info" }),
	Main = Window:AddTab({ Name = "Main", Icon = "house" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}
local MainTabs = {
	Farming = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" }),
	Income = Tabs.Main:AddSubTab({ Name = "Income", Icon = "trending-up" }),
}

-- ===== INFO TAB =====

local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")
StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

local ExecutorName, ExecutorVersion = "Unknown", "Unknown"
pcall(function()
	if identifyexecutor then
		local Name, Version = identifyexecutor()
		if type(Name) == "table" then ExecutorName = tostring(Name[1] or "Unknown") ExecutorVersion = tostring(Name[2] or "Unknown")
		else ExecutorName = tostring(Name) if Version then ExecutorVersion = tostring(Version) end end
	elseif getexecutorname then ExecutorName = tostring(getexecutorname()) end
	if ExecutorVersion == "Unknown" then pcall(function() if getexecutorversion then ExecutorVersion = tostring(getexecutorversion()) end end) end
end)
local ExecutorDisplay = ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" and (ExecutorName .. " " .. ExecutorVersion) or ExecutorName
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")
UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 9/2/2026</font>' })

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
	else
		pcall(function() GameNameLabel:SetText('GAME - <font color="#60d888">Unknown</font>') end)
	end
end)

local ScriptStartTime = os.clock()
task.spawn(function()
	while true do
		local e = os.clock() - ScriptStartTime
		pcall(function() SessionLabel:SetText('SESSION - <font color="#60d888">' .. math.floor(e/60) .. 'm ' .. math.floor(e%60) .. 's</font>') end)
		task.wait(1)
	end
end)

InfoGameBox:AddButton({Text = "Copy Place ID", Func = function() CopyToClipboard(tostring(game.PlaceId)) end})
InfoGameBox:AddButton({Text = "Copy Join Script", Func = function()
	CopyToClipboard(string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)', game.PlaceId, JobId))
end})

local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")
SocialsBox:AddButton({Text = "Discord", Func = function() CopyToClipboard(Config.DiscordLink) end})
SocialsBox:AddButton({Text = "YouTube", Func = function() CopyToClipboard(Config.YouTubeLink) end})
SocialsBox:AddButton({Text = "TikTok", Func = function() CopyToClipboard(Config.TikTokLink) end})

local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")
local featureList = {
	"Auto Farm Lucky Blocks", "Auto Collect Cash", "Auto Open Lucky Block", "Auto Upgrade Slime",
	"Auto Upgrade Jump", "Auto Rebirth", "Auto Purchase Floor", "Anti AFK", "No Gameplay Paused",
	"Auto Reconnect", "Auto Hide UI", "Theme Manager", "Config System",
}
for _, f in ipairs(featureList) do FeaturesBox:AddLabel({ Text = '<font color="#60d888">✓ ' .. f .. '</font>' }) end

-- ===== MAIN TAB - FARMING =====

local FarmBox = MainTabs.Farming:AddLeftGroupbox("Lucky Block Farming", "star")

local LuckyBlockDropdown = FarmBox:AddDropdown("LuckyBlockSelect", {
	Text = "Select Block Type", Values = LuckyBlocksList, Default = "Secret Lucky Block", MaxVisibleDropdownItems = 8,
	Callback = function(v) Config.SelectedLuckyBlocks = {v} if not SuppressUI then ScheduleSave() end end,
})
SettingsRefs.LuckyBlockDropdown = LuckyBlockDropdown
FarmBox:AddDivider()

AddFeatureToggle(FarmBox, "AutoFarmLuckyBlocks", {Text = "Auto Farm Lucky Blocks", Tooltip = "Teleport and fire StealPrompt on all selected blocks", Notify = true}, function(Value)
	Config.FarmActive = Value
	if Value then
		task.spawn(function()
			while Config.FarmActive do pcall(FarmLuckyBlock) task.wait(0.5) end
		end)
	else
		pcall(function()
			local hrp = get_hrp()
			if hrp then hrp.CFrame = CFrame.new(Config.HomePosition) end
		end)
	end
end)

-- ===== MAIN TAB - INCOME =====

local IncomeBox = MainTabs.Income:AddLeftGroupbox("Income", "trending-up")

AddFeatureToggle(IncomeBox, "AutoCollectCash", {Text = "Auto Collect Cash", Tooltip = "Collect earnings 1-60", Notify = true}, function(Value)
	Config.CollectActive = Value
	if Value then task.spawn(function()
		while Config.CollectActive do for i = 1, 60 do pcall(function() Network:WaitForChild("Collect Earnings"):FireServer(tostring(i)) end) task.wait(0.5) end end
	end) end
end)

AddFeatureToggle(IncomeBox, "AutoOpenLuckyBlock", {Text = "Auto Open Lucky Blocks", Tooltip = "Open blocks 1-60", Notify = true}, function(Value)
	Config.OpenActive = Value
	if Value then task.spawn(function()
		while Config.OpenActive do for i = 1, 60 do pcall(function() Network:WaitForChild("Open Lucky Block"):FireServer(tostring(i)) end) task.wait(0.5) end end
	end) end
end)

IncomeBox:AddDivider()

AddFeatureToggle(IncomeBox, "AutoUpgradeSlime", {Text = "Auto Upgrade Slime", Tooltip = "Upgrade slime slots 1-60", Notify = true}, function(Value)
	Config.UpgradeSlimeActive = Value
	if Value then task.spawn(function()
		while Config.UpgradeSlimeActive do for i = 1, 60 do pcall(function() Network:WaitForChild("Upgrade Slime"):FireServer(tostring(i)) end) task.wait(0.5) end end
	end) end
end)

AddFeatureToggle(IncomeBox, "AutoUpgradeJump", {Text = "Auto Upgrade Jump", Tooltip = "Buy speed upgrade", Notify = true}, function(Value)
	Config.UpgradeJumpActive = Value
	if Value then task.spawn(function()
		while Config.UpgradeJumpActive do pcall(BuyJumpUpgrade) task.wait(0.5) end
	end) end
end)

IncomeBox:AddDivider()

AddFeatureToggle(IncomeBox, "AutoRebirth", {Text = "Auto Rebirth", Tooltip = "Perform rebirth", Notify = true}, function(Value)
	Config.RebirthActive = Value
	if Value then task.spawn(function()
		while Config.RebirthActive do pcall(DoRebirth) task.wait(5) end
	end) end
end)

AddFeatureToggle(IncomeBox, "AutoPurchaseFloor", {Text = "Auto Purchase Floor", Tooltip = "Purchase floor 2-60", Notify = true}, function(Value)
	Config.PurchaseFloorActive = Value
	if Value then task.spawn(function()
		while Config.PurchaseFloorActive do for i = 2, 60 do pcall(function() Network:WaitForChild("Purchase Floor"):InvokeServer(i) end) task.wait(0.5) end end
	end) end
end)

IncomeBox:AddDivider()

AddFeatureToggle(IncomeBox, "AutoSellAll", {Text = "Auto Sell All", Tooltip = "Sell all slimes", Notify = true}, function(Value)
	Config.SellAllActive = Value
	if Value then task.spawn(function()
		while Config.SellAllActive do pcall(SellAllSlimes) task.wait(0.5) end
	end) end
end)

-- ===== SETTINGS TAB =====

local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
	Text = "Theme", Values = ThemeNames, Default = Config.ThemeName,
	Callback = function(v) Config.ThemeName = v ApplyTheme(Themes[v]) if not SuppressUI then Config.CustomColors = CloneColors(Themes[v]) SyncColorPickers() ScheduleSave() end end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown
ThemeBox:AddDivider()
ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {Default = Config.CustomColors.AccentColor, Title = "Accent Color", Callback = function(c) Config.CustomColors.AccentColor = c ApplyColorOverride("AccentColor", c) ScheduleSave() end})
ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", {Default = Config.CustomColors.FontColor, Title = "Font Color", Callback = function(c) Config.CustomColors.FontColor = c ApplyColorOverride("FontColor", c) ScheduleSave() end})
ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", {Default = Config.CustomColors.BackgroundColor, Title = "Background Color", Callback = function(c) Config.CustomColors.BackgroundColor = c ApplyColorOverride("BackgroundColor", c) ScheduleSave() end})
ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", {Default = Config.CustomColors.MainColor, Title = "Main Color", Callback = function(c) Config.CustomColors.MainColor = c ApplyColorOverride("MainColor", c) ScheduleSave() end})
ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", {Default = Config.CustomColors.OutlineColor, Title = "Outline Color", Callback = function(c) Config.CustomColors.OutlineColor = c ApplyColorOverride("OutlineColor", c) ScheduleSave() end})
ThemeBox:AddDivider()
local FontDropdown = ThemeBox:AddDropdown("Font", {
	Text = "Font", Values = FontNames, Default = Config.FontName,
	Callback = function(v) Config.FontName = v Library:SetFont(Enum.Font[v]) if not SuppressUI then ScheduleSave() end end,
})
SettingsRefs.FontDropdown = FontDropdown
ThemeBox:AddButton({Text = "Reset Theme", Func = function()
	Config.ThemeName = "Emerald Green" Config.CustomColors = CloneColors(Themes["Emerald Green"]) ApplyTheme(Themes["Emerald Green"])
	ThemeDropdown:SetValue("Emerald Green") SyncColorPickers() Notify("Theme", "Theme reset to Emerald Green", "Info") ScheduleSave()
end})

local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Group", "menu")
MenuBox:AddLabel("Menu Bind"):AddKeyPicker("MenuBind", {
	Default = Config.MenuBind, Mode = "Press", Text = "Toggle UI",
	Callback = function() Library:Toggle() end,
	ChangedCallback = function(k) if typeof(k) == "EnumItem" then Config.MenuBind = k.Name end ScheduleSave() end,
})
MenuBox:AddDivider()
AddFeatureToggle(MenuBox, "AutoExecute", {Text = "Auto Execute Script"}, function(v) Config.AutoExecute = v if v then RunAutoExecute() end end)
AddFeatureToggle(MenuBox, "AutoReconnect", {Text = "Auto Reconnect"}, function(v) Config.AutoReconnect = v if v then AutoReconnectLoop() end end)
AddFeatureToggle(MenuBox, "AutoHideUi", {Text = "Auto Hide UI"}, function(v) Config.AutoHideUi = v if v then AutoHideUiLoop() end end)
AddFeatureToggle(MenuBox, "AntiAfk", {Text = "Anti AFK"}, function(v) Config.AntiAfk = v if v then AntiAfkLoop() end end)
AddFeatureToggle(MenuBox, "NoGameplayPaused", {Text = "No Gameplay Paused"}, function(v) Config.NoGameplayPaused = v if v then NoPauseLoop() end end)
MenuBox:AddDivider()
MenuBox:AddButton({Text = "Stop All Features", Func = function()
	Config.FarmActive = false Config.CollectActive = false Config.OpenActive = false
	Config.UpgradeSlimeActive = false Config.UpgradeJumpActive = false Config.RebirthActive = false
	Config.PurchaseFloorActive = false Config.SellAllActive = false Config.AutoReconnect = false
	Config.AutoHideUi = false Config.AntiAfk = false Config.NoGameplayPaused = false
	for _, t in Library.Toggles do if t.Value then t:SetValue(false) end end
	Notify("Script", "All features stopped", "Warning")
end, Risky = true})

local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")
local RefreshConfigList
local ConfigNameInput = ConfigBox:AddInput("ConfigName", {Text = "Config name", Placeholder = "Type a config name...", ClearTextOnFocus = true})
ConfigBox:AddButton({Text = "Create config", Func = function()
	local n = SanitizeConfigName(ConfigNameInput.Value)
	if not n then Notify("Config", "Enter a valid name first", "Warning") return end
	if ConfigExists(n) then Notify("Config", "'" .. n .. "' already exists", "Warning") return end
	if SaveConfigData(n) then CurrentConfig = n RefreshConfigList(n) Notify("Config", "Config '" .. n .. "' created", "Success")
	else Notify("Config", "Config saving not supported", "Error") end
end})
ConfigBox:AddDivider()
local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {Text = "Config list", Values = { "---" }, Default = "---", Callback = function(v) CurrentConfig = v == "---" and nil or v end})
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
ConfigBox:AddButton({Text = "Load config", Func = function() local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end if LoadConfig(n, false) then Notify("Config", "Config '" .. n .. "' loaded", "Success") end end})
ConfigBox:AddButton({Text = "Overwrite config", Func = function() local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end if SaveConfigData(n) then Notify("Config", "Config '" .. n .. "' overwritten", "Success") else Notify("Config", "Config saving not supported", "Error") end end})
ConfigBox:AddButton({Text = "Delete config", Func = function()
	local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end
	pcall(function() delfile(ConfigPath(n)) end)
	if GetAutoloadName() == n then ClearAutoload() end
	CurrentConfig = nil RefreshConfigList() UpdateAutoloadLabel() Notify("Config", "Config '" .. n .. "' deleted", "Warning")
end, Risky = true})
ConfigBox:AddButton({Text = "Refresh list", Func = function() RefreshConfigList() Notify("Config", "Config list refreshed", "Info") end})
ConfigBox:AddButton({Text = "Set as autoload", Func = function() local n = CurrentConfig if not n then Notify("Config", "Select a config first", "Warning") return end if SetAutoload(n) then UpdateAutoloadLabel() Notify("Config", "Autoload set to '" .. n .. "'", "Success") end end})
ConfigBox:AddButton({Text = "Reset autoload", Func = function() ClearAutoload() UpdateAutoloadLabel() Notify("Config", "Autoload cleared", "Info") end})
ConfigBox:AddDivider()
AddFeatureToggle(ConfigBox, "AutoSave", {Text = "Auto Save Config"}, function(v) Config.AutoSave = v end)

-- ===== STARTUP =====

ApplyTheme(Themes[Config.ThemeName])
Library:SetFont(Enum.Font[Config.FontName])

task.delay(1, function()
	local an = GetAutoloadName()
	if an and ConfigExists(an) then CurrentConfig = an if LoadConfig(an, true) then Notify("Config", "Autoloaded '" .. an .. "'", "Success") end end
	RunAutoExecute() UpdateAutoloadLabel() RefreshConfigList()
end)

Notify("AntiGodHub", "Loaded", "Success")
