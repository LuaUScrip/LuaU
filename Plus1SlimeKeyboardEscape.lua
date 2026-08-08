-- Game | Obsidian UI (Clean)
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
	AutoFarmWins = false,
	SelectedWorld = "World 1",
	AutoRebirth = false,
	AutoBuyTrail = false,
	AutoBuyBestEgg = false,
	AutoEquipBestPet = false,
	SelectedEgg = "[WORLD 1]",
}

-- Win Positions
local WinPositions = {
	["World 1"] = CFrame.new(1322.14233, 193.503555, -4760.36621, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	["World 2"] = CFrame.new(-1340.90515, 239.281464, 6438.05811, -1, 0, 0, 0, 1, 0, 0, 0, -1),
}

-- Egg List with World Labels
local EggList = {
	"[WORLD 1]",
	"[WORLD 2]",
}

-- Egg Name Mapping
local EggNames = {
	["[WORLD 1]"] = "legendary_egg",
	["[WORLD 2]"] = "alien_egg",
}

-- Trail List
local TrailList = {
	"GreenTrail",
	"BlueTrail",
	"PurpleTrail",
	"RedTrail",
	"RainbowTrail",
	"GalaxyTrail",
	"CosmicTrail",
	"VoidTrail",
	"SupernovaTrail",
	"GodlyTrail",
	"InfinityTrail"
}

-- Bypass Gameplay Pause
task.spawn(function()
	while task.wait() do
		pcall(function()
			if player.GameplayPaused then
				player.GameplayPaused = false
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

FarmingGroup:AddDropdown("WorldSelect", {
	Values = {"World 1", "World 2"},
	Default = 1,
	Text = "Select World",
	Tooltip = "Choose which world to farm",
	Callback = function(Value)
		CONFIG.SelectedWorld = Value
	end,
})

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmWins do
					pcall(function()
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local winCFrame = WinPositions[CONFIG.SelectedWorld]
							if winCFrame then
								player.Character.HumanoidRootPart.CFrame = winCFrame
								player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
								
								local touchPart = workspace:FindFirstChild("GiveWins")
								if touchPart then
									touchPart = touchPart:FindFirstChild("Button14")
									if touchPart then
										touchPart = touchPart:FindFirstChild("Touch")
										if touchPart then
											firetouchinterest(player.Character.HumanoidRootPart, touchPart, 0)
											task.wait(0.05)
											firetouchinterest(player.Character.HumanoidRootPart, touchPart, 1)
										end
									end
								end
							end
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
						local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RequestRebirth")
						if Event then
							Event:InvokeServer()
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyTrail do
					pcall(function()
						for _, trail in ipairs(TrailList) do
							local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("TrailAction")
							if Event then
								Event:FireServer("BuyWins", trail)
								task.wait(0.3)
							end
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDropdown("EggSelect", {
	Values = EggList,
	Default = 1,
	Text = "Select Egg",
	Tooltip = "Choose which egg to buy",
	Callback = function(Value)
		CONFIG.SelectedEgg = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyBestEgg", {
	Text = "Auto Buy Best Egg",
	Default = false,
	Tooltip = "Automatically buy best egg",
	Callback = function(Value)
		CONFIG.AutoBuyBestEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyBestEgg do
					pcall(function()
						local eggName = EggNames[CONFIG.SelectedEgg]
						local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("OpenEgg")
						if Event and eggName then
							Event:InvokeServer(eggName)
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoEquipBestPet", {
	Text = "Auto Equip Best Pet",
	Default = false,
	Tooltip = "Automatically equip best pet",
	Callback = function(Value)
		CONFIG.AutoEquipBestPet = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoEquipBestPet do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("InventoryAction")
						if Event then
							Event:InvokeServer("EquipBest")
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Slime Keyboard Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/8/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Buy Best Egg")
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
SaveManager:SetFolder("AntiGodHub/Game")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")