local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Configuration
local CONFIG = {
	AutoFarmCoin = false,
	AutoFarmWins = false,
	AutoBuyCar = false,
	AutoBuyTrail = false,
	AutoClaimOnlineReward = false,
	AutoSpinWheels = false,
	AutoClaimEvent = false,
	AutoEquipBestPet = false,
}

-- Auto Farm Coin
task.spawn(function()
	while task.wait(0.3) do
		pcall(function()
			if CONFIG.AutoFarmCoin then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Race = Event:FindFirstChild("Race")
					if Race then
						Race:FireServer("RaceStartClimb", Vector3.new(-105.20733642578, 6.799599647522, -405.67901611328))
						task.wait()
						Race:FireServer("RaceEndClimb", Vector3.new(-103.59597015381, 5015.7109375, 8262.7783203125))
						task.wait()
						Race:FireServer("RaceClaimCoins", math.huge)
					end
				end
			end
		end)
	end
end)

-- Auto Farm Wins
task.spawn(function()
	while task.wait(0.3) do
		pcall(function()
			if CONFIG.AutoFarmWins then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Race = Event:FindFirstChild("Race")
					if Race then
						Race:FireServer("RaceStartClimb", Vector3.new(-105.20733642578, 6.799599647522, -405.67901611328))
						task.wait()
						Race:FireServer("RaceEndClimb", Vector3.new(-103.59597015381, 5015.7109375, 8262.7783203125))
						task.wait()
						Race:FireServer("ToTop")
						task.wait()
						Race:FireServer("RaceClaimTrophy")
					end
				end
			end
		end)
	end
end)

-- Auto Buy Car
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			if CONFIG.AutoBuyCar then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local CarF = Event:FindFirstChild("CarF")
					if CarF then
						for i = 1, 100 do
							CarF:InvokeServer("BuyCar", i)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Trail
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			if CONFIG.AutoBuyTrail then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local TrailF = Event:FindFirstChild("TrailF")
					if TrailF then
						for i = 1, 100 do
							TrailF:InvokeServer("BuyTrail", i)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Claim Online Reward
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			if CONFIG.AutoClaimOnlineReward then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Online = Event:FindFirstChild("Online")
					if Online then
						for i = 1, 12 do
							Online:FireServer("CliamReward", i)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Spin Wheels
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if CONFIG.AutoSpinWheels then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Spin = Event:FindFirstChild("Spin")
					if Spin then
						Spin:FireServer("PlayerSpin")
					end
				end
			end
		end)
	end
end)

-- Auto Claim Event
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoClaimEvent then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local EventRemote = Event:FindFirstChild("Event")
					if EventRemote then
						EventRemote:FireServer("ClaimEventReward")
					end
				end
			end
		end)
	end
end)

-- Auto Equip Best Pet
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoEquipBestPet then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Pet = Event:FindFirstChild("Pet")
					if Pet then
						Pet:FireServer("EquipBest")
					end
				end
			end
		end)
	end
end)

-- UI Creation
local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Footer = "Version: 2.0 - YouTube AntiGodHub Subscribe",
	Icon = nil,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "star"),
	Player = Window:AddTab("Player", "user"),
	Settings = Window:AddTab("UI Settings", "settings"),
}

-- Main Tab - Left Side (Farming)
local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmCoin", {
	Text = "Auto Farm Coin",
	Default = false,
	Tooltip = "Automatically farm coins",
	Callback = function(Value)
		CONFIG.AutoFarmCoin = Value
	end,
})

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddToggle("AutoSpinWheels", {
	Text = "Auto Spin Wheels",
	Default = false,
	Tooltip = "Automatically spin wheels",
	Callback = function(Value)
		CONFIG.AutoSpinWheels = Value
	end,
})

FarmingGroup:AddToggle("AutoClaimEvent", {
	Text = "Auto Claim Event",
	Default = false,
	Tooltip = "Automatically claim event rewards",
	Callback = function(Value)
		CONFIG.AutoClaimEvent = Value
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddToggle("AutoBuyCar", {
	Text = "Auto Buy Car",
	Default = false,
	Tooltip = "Automatically buy all cars",
	Callback = function(Value)
		CONFIG.AutoBuyCar = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
	end,
})

UpgradeGroup:AddToggle("AutoClaimOnlineReward", {
	Text = "Auto Claim Online Reward",
	Default = false,
	Tooltip = "Automatically claim online rewards",
	Callback = function(Value)
		CONFIG.AutoClaimOnlineReward = Value
	end,
})

UpgradeGroup:AddToggle("AutoEquipBestPet", {
	Text = "Auto Equip Best Pet",
	Default = false,
	Tooltip = "Automatically equip best pet",
	Callback = function(Value)
		CONFIG.AutoEquipBestPet = Value
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Drive Car And Slide")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/3/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Coin")
FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Buy Car")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Claim Online Reward")
FeaturesGroup:AddLabel("✓ Auto Spin Wheels")
FeaturesGroup:AddLabel("✓ Auto Claim Event")
FeaturesGroup:AddLabel("✓ Auto Equip Best Pet")

-- Player Tab - Player Information
local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. player.Name)
PlayerInfoGroup:AddLabel("User ID : " .. player.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. (player.MembershipType == Enum.MembershipType.Premium and "Yes Premium" or "No Premium"))

-- Player Tab - Discord Support
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

-- UI Settings Tab
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
	Default = 20,
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

-- Theme & Save System
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("AntiGodHub")
SaveManager:SetFolder("AntiGodHub/KatanaEvolution")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
