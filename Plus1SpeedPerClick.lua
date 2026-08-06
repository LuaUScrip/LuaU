-- +1 Speed Per Click | Obsidian UI (Clean)
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
	["Egg1"] = "NightmareTen",
	["Egg2"] = "HeroTen",
}

-- Configuration
local CONFIG = {
	AutoInstantWins = false,
	AutoTrain = false,
	AutoBuyCar = false,
	AutoBuyTrainer = false,
	DupeWins = false,
	AutoBuyRobuxEgg = false,
	GiveRobuxCoin = false,
	BuyAllGamepasses = false,
	AutoBuyRobuxEggDropdown = "Egg1",
	AutoBuyDivineLuckyBlock = false,
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

-- Auto Instant Wins
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoInstantWins then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local ThrowReward = RemoteEventStorage:FindFirstChild("ThrowReward")
							if ThrowReward then
								ThrowReward:FireServer(1000000)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Train
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoTrain then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local ClickEnergy = RemoteEventStorage:FindFirstChild("ClickEnergy")
							local TrainingBoostClick = RemoteEventStorage:FindFirstChild("TrainingBoostClick")
							if ClickEnergy then
								ClickEnergy:FireServer()
							end
							if TrainingBoostClick then
								TrainingBoostClick:FireServer()
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Car
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyCar then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local CarAction = RemoteEventStorage:FindFirstChild("CarAction")
							if CarAction then
								CarAction:FireServer("Micro Hatch", "UnlockAll")
								CarAction:FireServer("Micro Hatch", "EquipBest")
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Trainer
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyTrainer then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local TrainerAction = RemoteEventStorage:FindFirstChild("TrainerAction")
							if TrainerAction then
								TrainerAction:FireServer("Noob", "UnlockAll")
								TrainerAction:FireServer("Noob", "EquipBest")
							end
						end
					end
				end
			end
		end)
	end
end)

-- Dupe Wins
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.DupeWins then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local BuyWithTickets = RemoteEventStorage:FindFirstChild("BuyWithTickets")
							if BuyWithTickets then
								BuyWithTickets:FireServer("GodCashPack", 300)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Robux Egg
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyRobuxEgg then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local BuyWithTickets = RemoteEventStorage:FindFirstChild("BuyWithTickets")
							if BuyWithTickets then
								local eggName = EggMapping[CONFIG.AutoBuyRobuxEggDropdown]
								BuyWithTickets:FireServer(eggName, 400)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Give Robux Coin
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.GiveRobuxCoin then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local ClaimDailyReward = RemoteEventStorage:FindFirstChild("ClaimDailyReward")
							local ResetDailyStreak = RemoteEventStorage:FindFirstChild("ResetDailyStreak")
							if ClaimDailyReward then
								ClaimDailyReward:FireServer(player)
							end
							if ResetDailyStreak then
								ResetDailyStreak:FireServer(player)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Buy All Gamepasses
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.BuyAllGamepasses then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local BuyWithTickets = RemoteEventStorage:FindFirstChild("BuyWithTickets")
							if BuyWithTickets then
								local gamepasses = {
									{"Gamepass_VIP", 150},
									{"Gamepass_FastHatch", 30},
									{"Gamepass_Max Rebirth", 250},
									{"Gamepass_AutoRebirth", 50},
									{"Gamepass_MorePet", 125},
									{"Gamepass_ExtraMorePet", 750},
									{"Gamepass_SixEgg", 150},
									{"Gamepass_TwelveEgg", 400},
									{"Gamepass_ShinyHunter", 150},
									{"Gamepass_LuckyEggs", 50},
									{"Gamepass_UltraLuckyEggs", 100},
									{"Gamepass_OPAuto", 100},
									{"Gamepass_MagicEggs", 150},
									{"Gamepass_x2Training", 100},
									{"Gamepass_x2Energy", 30},
									{"Gamepass_x2Cash", 40},
									{"Gamepass_PetStorage", 20},
									{"Gamepass_ExtraPetStorage", 40},
									{"Gamepass_Golden100", 300},
									{"Gamepass_Rainbow100", 600},
									{"Gamepass_x2Rebirth", 180},
									{"Gamepass_ExtraSpeed", 10},
									{"Gamepass_Darkmatter100", 1000},
									{"Gamepass_OPRunBoost", 50},
									{"Gamepass_ExtraJump", 10},
								}
								for _, gamepass in ipairs(gamepasses) do
									BuyWithTickets:FireServer(gamepass[1], gamepass[2])
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Divine Lucky Block
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyDivineLuckyBlock then
				local Event = ReplicatedStorage:FindFirstChild("Packages")
				if Event then
					local Network = Event:FindFirstChild("Network")
					if Network then
						local RemoteEventStorage = Network:FindFirstChild("RemoteEventStorage")
						if RemoteEventStorage then
							local BuyWithTickets = RemoteEventStorage:FindFirstChild("BuyWithTickets")
							if BuyWithTickets then
								BuyWithTickets:FireServer("DivineLuckyOne", 150)
							end
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

FarmingGroup:AddToggle("AutoInstantWins", {
	Text = "Auto Instant Wins",
	Default = false,
	Tooltip = "Automatically get instant wins",
	Callback = function(Value)
		CONFIG.AutoInstantWins = Value
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddToggle("AutoBuyCar", {
	Text = "Auto Buy Car",
	Default = false,
	Tooltip = "Automatically buy and equip car",
	Callback = function(Value)
		CONFIG.AutoBuyCar = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyTrainer", {
	Text = "Auto Buy Trainer",
	Default = false,
	Tooltip = "Automatically buy and equip trainer",
	Callback = function(Value)
		CONFIG.AutoBuyTrainer = Value
	end,
})

UpgradeGroup:AddToggle("DupeWins", {
	Text = "Dupe Wins",
	Default = false,
	Tooltip = "Duplicate wins",
	Callback = function(Value)
		CONFIG.DupeWins = Value
	end,
})

UpgradeGroup:AddToggle("GiveRobuxCoin", {
	Text = "Give Robux Coin",
	Default = false,
	Tooltip = "Claim daily reward and reset streak",
	Callback = function(Value)
		CONFIG.GiveRobuxCoin = Value
	end,
})

UpgradeGroup:AddToggle("BuyAllGamepasses", {
	Text = "Buy All Gamepasses",
	Default = false,
	Tooltip = "Automatically buy all gamepasses",
	Callback = function(Value)
		CONFIG.BuyAllGamepasses = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyDivineLuckyBlock", {
	Text = "Auto Buy Divine Lucky Block",
	Default = false,
	Tooltip = "Automatically buy divine lucky block",
	Callback = function(Value)
		CONFIG.AutoBuyDivineLuckyBlock = Value
	end,
})

UpgradeGroup:AddDropdown("AutoBuyRobuxEggDropdown", {
	Values = {"Egg1", "Egg2"},
	Default = "Egg1",
	Text = "Select Egg",
	Callback = function(Value)
		CONFIG.AutoBuyRobuxEggDropdown = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyRobuxEgg", {
	Text = "Auto Buy Robux Egg",
	Default = false,
	Tooltip = "Automatically buy robux egg",
	Callback = function(Value)
		CONFIG.AutoBuyRobuxEgg = Value
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Speed Per Click")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Instant Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Buy Car")
FeaturesGroup:AddLabel("✓ Auto Buy Trainer")
FeaturesGroup:AddLabel("✓ Dupe Wins")
FeaturesGroup:AddLabel("✓ Auto Buy Robux Egg")
FeaturesGroup:AddLabel("✓ Give Robux Coin")
FeaturesGroup:AddLabel("✓ Buy All Gamepasses")
FeaturesGroup:AddLabel("✓ Divine Lucky Block")

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
SaveManager:SetFolder("AntiGodHub/SpeedPerClick")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
