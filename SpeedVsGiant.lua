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
	AutoUpgradeSpeed = false,
	AutoBuyBestEgg = false,
	CustomMoneyValue = 100,
}

local FARM_WINS_POS1 = CFrame.new(-9585, 3, 230)
local FARM_WINS_POS2 = CFrame.new(-9585, 3, 7537)

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoFarmWins then
			pcall(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character.HumanoidRootPart.CFrame = FARM_WINS_POS1
					task.wait(1)
					LocalPlayer.Character.HumanoidRootPart.CFrame = FARM_WINS_POS2
					task.wait(1)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.0000001) do
		if CONFIG.AutoUpgradeSpeed then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
				if Event then
					local PlateUpgrade = Event:FindFirstChild("PlateUpgrade")
					if PlateUpgrade then
						PlateUpgrade:FireServer()
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoBuyBestEgg then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteFunctions")
				if Event then
					local EggOpened = Event:FindFirstChild("EggOpened")
					if EggOpened then
						EggOpened:InvokeServer("SecondLostJungleCapsule", {})
					end
				end
			end)
		end
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

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Farm wins automatically",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddToggle("AutoBuyBestEgg", {
	Text = "Auto Buy Best Egg",
	Default = false,
	Tooltip = "Buy best egg automatically",
	Callback = function(Value)
		CONFIG.AutoBuyBestEgg = Value
	end,
})

FarmingGroup:AddInput("CustomMoneyValue", {
	Default = "PUT AMOUNT",
	Numeric = true,
	Finished = true,
	Text = "Money Amount",
	Tooltip = "Enter custom money value",
	Callback = function(Value)
		CONFIG.CustomMoneyValue = tonumber(Value) or 100
	end,
})

FarmingGroup:AddButton({
	Text = "Add Money",
	Func = function()
		pcall(function()
			local Event = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
			if Event then
				local MoneyPickedUp = Event:FindFirstChild("MoneyPickedUp")
				if MoneyPickedUp then
					MoneyPickedUp:FireServer(CONFIG.CustomMoneyValue)
				end
			end
		end)
	end,
	Tooltip = "Add custom amount of money",
})

FarmingGroup:AddToggle("AutoUpgradeSpeed", {
	Text = "Auto Upgrade Speed",
	Default = false,
	Tooltip = "Automatically upgrade speed",
	Callback = function(Value)
		CONFIG.AutoUpgradeSpeed = Value
	end,
})

local InfoGroup = Tabs.Main:AddRightGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Speed Vs Giant")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/8/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Buy Best Egg")
FeaturesGroup:AddLabel("✓ Add Money")
FeaturesGroup:AddLabel("✓ Auto Upgrade Speed")

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
SaveManager:SetFolder("AntiGodHub/PullPerStep")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")