-- +1 Muscle To Slap Fight | Obsidian UI (Clean)
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
	AutoFight = false,
	AutoFarmWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoBuyEgg = false,
	AutoEquipPet = false,
	AutoClaimOnlineReward = false,
	AutoSpinWheel = false,
	AutoClaimRandomBoost = false,
	AutoUpgrade = false,
	SelectedEgg = 101,
}

local FightList = {101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410}

local EggOptions = {
	"Egg 1 [101]",
	"Egg 2 [102]",
	"Egg 3 [201]",
	"Egg 4 [202]",
	"Egg 5 [301]",
	"Egg 6 [302]",
	"Egg 7 [401]",
	"Egg 8 [402]",
}
local EggList = {101, 102, 201, 202, 301, 302, 401, 402}

local UpgradeOptions = {
	"WalkSpeed",
	"WinBuff",
	"EquipPet",
	"Lucky"
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

FarmingGroup:AddToggle("AutoFight", {
	Text = "Auto Fight",
	Default = false,
	Tooltip = "Automatically fight enemies (101-110, 201-210, 301-310, 401-410)",
	Callback = function(Value)
		CONFIG.AutoFight = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFight do
					for _, enemyID in ipairs(FightList) do
						if not CONFIG.AutoFight then break end
						pcall(function()
							local Event = ReplicatedStorage.Remote.Battle
							Event:FireServer("RecordVictory", enemyID)
						end)
						task.wait(0.5)
					end
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically claim rewards",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmWins do
					pcall(function()
						local Event = ReplicatedStorage.Remote.BattleF
						Event:InvokeServer("ClaimReward", 410, false)
					end)
					task.wait(0.00001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local Event = ReplicatedStorage.Remote.Power
						Event:FireServer("GainFromMovement")
					end)
					task.wait(0.00000001)
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
						local Event = ReplicatedStorage.Remote.PlayerF
						Event:InvokeServer("Rebirth")
					end)
					task.wait(2)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoSpinWheel", {
	Text = "Auto Spin Wheels",
	Default = false,
	Tooltip = "Automatically spin wheels",
	Callback = function(Value)
		CONFIG.AutoSpinWheel = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSpinWheel do
					pcall(function()
						local Event = ReplicatedStorage.Remote.Spin
						Event:FireServer("PlayerSpin")
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoClaimRandomBoost", {
	Text = "Auto Claim Random Boost",
	Default = false,
	Tooltip = "Automatically claim daily random boost",
	Callback = function(Value)
		CONFIG.AutoClaimRandomBoost = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoClaimRandomBoost do
					pcall(function()
						local Event = ReplicatedStorage.Remote.Item
						Event:FireServer("ClaimDailyRandomBoost")
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddDropdown("EggSelect", {
	Values = EggOptions,
	Default = 1,
	Text = "Select Egg",
	Tooltip = "Choose which egg to roll",
	Searchable = false,
	Callback = function(Value)
		local index = tonumber(string.match(Value, "%d+"))
		CONFIG.SelectedEgg = EggList[index]
	end,
})

UpgradeGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Tooltip = "Automatically roll selected egg",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = ReplicatedStorage.Remote.Pet
						Event:FireServer("RollEggOnce", CONFIG.SelectedEgg, 1, false)
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoEquipPet", {
	Text = "Auto Equip Best Pet",
	Default = false,
	Tooltip = "Automatically equip best pet",
	Callback = function(Value)
		CONFIG.AutoEquipPet = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoEquipPet do
					pcall(function()
						local Event = ReplicatedStorage.Remote.Pet
						Event:FireServer("EquipBest")
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDivider()

UpgradeGroup:AddToggle("AutoClaimOnlineReward", {
	Text = "Auto Claim Online Reward",
	Default = false,
	Tooltip = "Automatically claim all online rewards (1-15)",
	Callback = function(Value)
		CONFIG.AutoClaimOnlineReward = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoClaimOnlineReward do
					for reward = 1, 15 do
						if not CONFIG.AutoClaimOnlineReward then break end
						pcall(function()
							local Event = ReplicatedStorage.Remote.Online
							Event:FireServer("CliamReward", reward)
						end)
						task.wait(0.3)
					end
					task.wait(0.5)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDivider()

UpgradeGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Automatically upgrade all stats (WalkSpeed, WinBuff, EquipPet, Lucky)",
	Callback = function(Value)
		CONFIG.AutoUpgrade = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgrade do
					for _, upgrade in ipairs(UpgradeOptions) do
						if not CONFIG.AutoUpgrade then break end
						pcall(function()
							local Event = ReplicatedStorage.Remote.Upgrade
							Event:FireServer("Upgrade", upgrade)
						end)
						task.wait(0.2)
					end
					task.wait(0.3)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Muscle To Slap Fight")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Fight")
FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Spin Wheels")
FeaturesGroup:AddLabel("✓ Auto Claim Random Boost")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")
FeaturesGroup:AddLabel("✓ Auto Equip Best Pet")
FeaturesGroup:AddLabel("✓ Auto Claim Rewards")
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
SaveManager:SetFolder("AntiGodHub/MuscleToSlapFight")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
