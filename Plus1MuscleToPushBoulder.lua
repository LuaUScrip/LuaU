-- +1 Muscle To Push Boulder | Obsidian UI (Clean)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	AutoFarmStrength = false,
	AutoBuyDumbbell = false,
	AutoRebirth = false,
	AutoBuyPet = false,
	AutoBuyAura = false,
	AutoUpgradeLuck = false,
	AutoUpgradeSpeed = false,
}

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

FarmingGroup:AddButton({
	Text = "INF WINS [CLICK 1 TIME]",
	Func = function()
		local Event = ReplicatedStorage.Packages.Net["RF/ClientRollEgg"]
		Event:InvokeServer("Heaven Egg", -9e+99, {})
	end,
	Tooltip = "Get infinite wins instantly",
})

FarmingGroup:AddDivider()

FarmingGroup:AddToggle("AutoFarmStrength", {
	Text = "Auto Farm Strength",
	Default = false,
	Tooltip = "Automatically train strength",
	Callback = function(Value)
		CONFIG.AutoFarmStrength = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmStrength do
					pcall(function()
						ReplicatedStorage.Packages.Net["RE/ClientTrain"]:FireServer()
					end)
					task.wait(0.000000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyDumbbell", {
	Text = "Auto Buy Dumbbell",
	Default = false,
	Tooltip = "Automatically buy all dumbbells (1-46)",
	Callback = function(Value)
		CONFIG.AutoBuyDumbbell = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyDumbbell do
					pcall(function()
						for i = 1, 46 do
							ReplicatedStorage.Packages.Net["RE/BuyDumbbell"]:FireServer("Dumbbell" .. i)
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Tooltip = "Automatically rebirth",
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRebirth do
					pcall(function()
						ReplicatedStorage.Packages.Net["RE/Rebirth"]:FireServer()
					end)
					task.wait(0.01)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrade)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddToggle("AutoBuyPet", {
	Text = "Auto Buy Best Pet",
	Default = false,
	Tooltip = "Automatically buy best pet (Heaven Egg)",
	Callback = function(Value)
		CONFIG.AutoBuyPet = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyPet do
					pcall(function()
						ReplicatedStorage.Packages.Net["RF/ClientRollEgg"]:InvokeServer("Heaven Egg", 1, {})
					end)
					task.wait(0.2)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyAura", {
	Text = "Auto Buy Best Aura",
	Default = false,
	Tooltip = "Automatically buy best aura (Abyss Aura)",
	Callback = function(Value)
		CONFIG.AutoBuyAura = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyAura do
					pcall(function()
						ReplicatedStorage.Packages.Net["RE/ActionAura"]:FireServer("Abyss Aura")
					end)
					task.wait(0.2)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgradeLuck", {
	Text = "Auto Upgrade Luck",
	Default = false,
	Tooltip = "Automatically upgrade luck",
	Callback = function(Value)
		CONFIG.AutoUpgradeLuck = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgradeLuck do
					pcall(function()
						ReplicatedStorage.Packages.Net["RE/UpgradeLuck"]:FireServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgradeSpeed", {
	Text = "Auto Upgrade Speed",
	Default = false,
	Tooltip = "Automatically upgrade speed",
	Callback = function(Value)
		CONFIG.AutoUpgradeSpeed = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgradeSpeed do
					pcall(function()
						ReplicatedStorage.Packages.Net["RE/UpgradeSpeed"]:FireServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Muscle To Push Boulder")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Inf Wins")
FeaturesGroup:AddLabel("✓ Auto Farm Strength")
FeaturesGroup:AddLabel("✓ Auto Buy Dumbbell")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Best Pet")
FeaturesGroup:AddLabel("✓ Auto Buy Best Aura")
FeaturesGroup:AddLabel("✓ Auto Upgrade")

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
SaveManager:SetFolder("AntiGodHub/MuscleBouldeer")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
