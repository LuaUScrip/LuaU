local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			if LocalPlayer.GameplayPaused then
				LocalPlayer.GameplayPaused = false
			end
		end)
	end
end)

local CONFIG = {
	AutoFarmWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoBuyTrail = false,
	AutoBuyAura = false,
}

local FARM_WINS_CFRAME = CFrame.new(-71469.2266, 1902.47852, 5.01947784, 0, 0, 1, 0, 1, -0, -1, 0, 0)

local TrainLocations = {
	"Train 1",
}

local Train1Positions = {
	CFrame.new(958.237671, 1900.99084, -80.1433105, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.237671, 1900.99072, -69.5934448, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.637329, 1900.99072, -58.4453278, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.237671, 1900.99072, -48.6434402, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.637329, 1900.99072, -35.0460815, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.237671, 1900.99072, -22.7663593, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.684204, 1901.14978, 8.28601933, 0, 0, 1, 0, 1, -0, -1, 0, 0),
	CFrame.new(958.684204, 1901.14978, 22.4087429, 0, 0, 1, 0, 1, -0, -1, 0, 0),
}

local selectedTrain = "Train 1"

local TrailList = {
	"WhiteTrail", "BlueTrail", "YellowTrail", "GreenTrail", "RedTrail",
	"OrangeTrail", "PinkTrail", "PurpleTrail", "BrownTrail", "BlackTrail",
	"BlackAndWhiteTrail", "RainbowTrail", "RedAndBlackTrail", "LavenderTrail",
	"GreenAndBlackTrail", "PastelRainbowTrail", "LimeTrail", "GalaxyTrail",
}

local AuraList = {
	"SmokeAura", "FireworksAura", "LightningAura", "SolarAura", "RoyalAura",
	"AbyssAura", "EmeraldAura", "SakuraAura", "FlameAura", "WaterAura",
	"FrostAura", "ShadowAura", "UnChainedAura", "KnowledgeAura", "BinaryAura",
	"DiscoAura", "ToxicAura", "GalaxyAura",
}

local function GetJobID()
	return game.JobId
end

local function GetPlayerCount()
	return #Players:GetPlayers()
end

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

-- Auto Farm Wins
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if CONFIG.AutoFarmWins then
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character.HumanoidRootPart.CFrame = FARM_WINS_CFRAME
				end
			end
		end)
	end
end)

-- Auto Train
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if CONFIG.AutoTrain then
				if selectedTrain == "Train 1" then
					for _, trainCFrame in ipairs(Train1Positions) do
						if CONFIG.AutoTrain and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
							LocalPlayer.Character.HumanoidRootPart.CFrame = trainCFrame
							task.wait(0.5)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Rebirth
task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if CONFIG.AutoRebirth then
				local Event = ReplicatedStorage:FindFirstChild("GameSystems")
				if Event then
					local Remotes = Event:FindFirstChild("Remotes")
					if Remotes then
						local RequestRebirth = Remotes:FindFirstChild("RequestRebirth")
						if RequestRebirth then
							RequestRebirth:FireServer()
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Trail
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if CONFIG.AutoBuyTrail then
				local Event = ReplicatedStorage:FindFirstChild("GameSystems")
				if Event then
					local Remotes = Event:FindFirstChild("Remotes")
					if Remotes then
						local RequestTrailAction = Remotes:FindFirstChild("RequestTrailAction")
						if RequestTrailAction then
							for _, trail in ipairs(TrailList) do
								RequestTrailAction:FireServer(trail, "BuyWithWins")
								task.wait(0.1)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Aura
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if CONFIG.AutoBuyAura then
				local Event = ReplicatedStorage:FindFirstChild("GameSystems")
				if Event then
					local Remotes = Event:FindFirstChild("Remotes")
					if Remotes then
						local RequestAuraAction = Remotes:FindFirstChild("RequestAuraAction")
						if RequestAuraAction then
							for _, aura in ipairs(AuraList) do
								RequestAuraAction:FireServer(aura, "BuyWithWins")
								task.wait(0.1)
							end
						end
					end
				end
			end
		end)
	end
end)

local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Footer = "Version: 2.0 - YouTube AntiGodHub Subscribe",
	Icon = nil,
	NotifySide = "Right",
	ShowCustomCursor = false,
})

local Tabs = {
	Main = Window:AddTab("Main", "star"),
	Player = Window:AddTab("Player", "user"),
	Settings = Window:AddTab("UI Settings", "settings"),
}

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddDropdown("TrainSelect", {
	Values = TrainLocations,
	Default = 1,
	Text = "Select Train",
	Tooltip = "Choose train location",
	Callback = function(Value)
		selectedTrain = Value
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train at selected location",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
	end,
})

local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyAura", {
	Text = "Auto Buy Aura",
	Default = false,
	Tooltip = "Automatically buy all auras",
	Callback = function(Value)
		CONFIG.AutoBuyAura = Value
	end,
})

UpgradeGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Tooltip = "Automatically rebirth",
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
	end,
})

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Double Jump Bike Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Buy Aura")
FeaturesGroup:AddLabel("✓ Auto Rebirth")

local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. GetPremiumStatus())

local DiscordGroup = Tabs.Player:AddRightGroupbox("Community Support", "users")

DiscordGroup:AddLabel("Join our Discord server for support and script updates!", true)
DiscordGroup:AddDivider()

DiscordGroup:AddButton({
	Text = "Copy Discord Link",
	Func = function()
		setclipboard("https://discord.gg/jdJvZm6VdK")
	end,
	Tooltip = "Copy Discord invite link to clipboard",
})

DiscordGroup:AddLabel("Link: discord.gg/jdJvZm6VdK", true)
DiscordGroup:AddDivider()
DiscordGroup:AddLabel("✓ Get Support", true)
DiscordGroup:AddLabel("✓ Script Updates", true)
DiscordGroup:AddLabel("✓ Feature Requests", true)
DiscordGroup:AddLabel("✓ Community Tips", true)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = {"Left", "Right"},
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = 10,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu Keybind"
})

MenuGroup:AddButton({
	Text = "Unload Script",
	Func = function()
		Library:Unload()
	end,
	Tooltip = "Unload the entire script"
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("AntiGodHub")
SaveManager:SetFolder("AntiGodHub/DoubleJumpBikeEscape")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
