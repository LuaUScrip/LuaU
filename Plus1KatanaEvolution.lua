-- +1 Katana Evolution | Obsidian UI (Clean)
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

-- Egg Mapping
local EggMapping = {
	["Egg1 [350M]"] = "EliteEgg",
	["Egg2 [50T]"] = "MasterEgg",
}

-- Configuration
local CONFIG = {
	AutoFarmWins = false,
	AutoFarmDamage = false,
	AutoBuyEgg = false,
	AutoRebirth = false,
	AutoBuyForge = false,
	AutoWinsDropdown = "World 1",
	AutoBuyEggDropdown = "Egg1 [350M]",
}

-- Unpause Gameplay
task.spawn(function()
	while task.wait() do
		pcall(function()
			if player.GameplayPaused then
				player.GameplayPaused = false
			end
		end)
	end
end)

-- Auto Farm Wins
RunService.Heartbeat:Connect(function()
	if CONFIG.AutoFarmWins then
		pcall(function()
			if CONFIG.AutoWinsDropdown == "World 1" then
				local targetPart = Workspace:FindFirstChild("WinCollectors")
				if targetPart then
					local stage25 = targetPart:FindFirstChild("Stage25")
					if stage25 then
						local button = stage25:FindFirstChild("Button")
						if button and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							firetouchinterest(player.Character.HumanoidRootPart, button, 0)
							firetouchinterest(player.Character.HumanoidRootPart, button, 1)
						end
					end
				end
			elseif CONFIG.AutoWinsDropdown == "World 2" then
				local targetPart = Workspace:FindFirstChild("WinCollectors")
				if targetPart then
					local stage15 = targetPart:FindFirstChild("Stage15")
					if stage15 then
						local button = stage15:FindFirstChild("Button")
						if button and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							firetouchinterest(player.Character.HumanoidRootPart, button, 0)
							firetouchinterest(player.Character.HumanoidRootPart, button, 1)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Farm Damage
task.spawn(function()
	while task.wait(0.000001) do
		pcall(function()
			if CONFIG.AutoFarmDamage then
				local Event = ReplicatedStorage:FindFirstChild("Remotes")
				if Event then
					local SwingRequest = Event:FindFirstChild("SwingRequest")
					if SwingRequest then
						SwingRequest:FireServer()
					end
				end
			end
		end)
	end
end)

-- Auto Buy Egg
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyEgg then
				local Event = ReplicatedStorage:FindFirstChild("Remotes")
				if Event then
					local EggEvents = Event:FindFirstChild("EggEvents")
					if EggEvents then
						local eggName = EggMapping[CONFIG.AutoBuyEggDropdown]
						EggEvents:FireServer("PurchaseEgg", eggName, 1, nil)
					end
				end
			end
		end)
	end
end)

-- Auto Rebirth
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoRebirth then
				local Event = ReplicatedStorage:FindFirstChild("Remotes")
				if Event then
					local RebirthRequest = Event:FindFirstChild("RebirthRequest")
					if RebirthRequest then
						RebirthRequest:FireServer()
					end
				end
			end
		end)
	end
end)

-- Auto Buy Forge
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyForge then
				local Event = ReplicatedStorage:FindFirstChild("Remotes")
				if Event then
					local ForgeEvents = Event:FindFirstChild("ForgeEvents")
					if ForgeEvents then
						local items = {"Legendary", "Mythic"}
						for _, item in ipairs(items) do
							ForgeEvents:FireServer("BuyWithWins", item)
						end
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

FarmingGroup:AddDropdown("AutoWinsDropdown", {
	Values = {"World 1", "World 2"},
	Default = "World 1",
	Text = "Select World",
	Callback = function(Value)
		CONFIG.AutoWinsDropdown = Value
	end,
})

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddToggle("AutoFarmDamage", {
	Text = "Auto Farm Damage",
	Default = false,
	Tooltip = "Automatically farm damage",
	Callback = function(Value)
		CONFIG.AutoFarmDamage = Value
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddDropdown("AutoBuyEggDropdown", {
	Values = {"Egg1 [350M]", "Egg2 [50T]"},
	Default = "Egg1 [350M]",
	Text = "Select Egg",
	Callback = function(Value)
		CONFIG.AutoBuyEggDropdown = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Tooltip = "Automatically buy egg",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
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

UpgradeGroup:AddToggle("AutoBuyForge", {
	Text = "Auto Buy Items",
	Default = false,
	Tooltip = "Automatically buy all forge items",
	Callback = function(Value)
		CONFIG.AutoBuyForge = Value
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Katana Evolution")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Wins World")
FeaturesGroup:AddLabel("✓ Auto Farm Damage")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Items")

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
