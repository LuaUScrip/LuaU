-- +1 Aura To Blast Bosses | Obsidian UI (Clean)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Configuration
local CONFIG = {
	AutoRaceWins = false,
	AutoBlast = false,
	AutoRebirth = false,
	AutoUpgradeStats = false,
	AutoTrain = false,
	AutoTreadmill = false,
	AutoEquipBestPet = false,
	AutoBuyEgg = false,
	SelectedEgg = "Egg1",
	SelectedTreadmill = "Train_1_1",
}

local WinPosition = Vector3.new(253, 241, 52)
local BossList = {}
for i = 1, 30 do
	table.insert(BossList, "Boss" .. i)
end

local EggList = {}
for i = 1, 6 do
	table.insert(EggList, "Egg" .. i)
end

local TreadmillList = {}
local TreadmillNames = {}
local worlds = {
	{name = "WORLD 1", prefix = "Train_1_", count = 5},
	{name = "WORLD 2", prefix = "Train_2_", count = 5},
	{name = "WORLD 3", prefix = "Train_3_", count = 5},
}

for _, world in ipairs(worlds) do
	for i = 1, world.count do
		local trainId = world.prefix .. i
		table.insert(TreadmillList, trainId)
		table.insert(TreadmillNames, "Train " .. i .. " [" .. world.name .. "]")
	end
end

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

FarmingGroup:AddToggle("AutoRaceWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically win races",
	Callback = function(Value)
		CONFIG.AutoRaceWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRaceWins do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Game.CRaceTouchWins
						Event:FireServer("10")
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBlast", {
	Text = "Auto Blast Bosses",
	Default = false,
	Tooltip = "Automatically blast all bosses (Boss1-Boss30)",
	Callback = function(Value)
		CONFIG.AutoBlast = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBlast do
					pcall(function()
						for _, boss in ipairs(BossList) do
							if not CONFIG.AutoBlast then break end
							local Event = ReplicatedStorage.Event.RemoteEvent.CToS.Game.CFinishRace
							Event:FireServer(true, boss)
							task.wait(2)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train character",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Game.CPlayerClick
						Event:FireServer()
					end)
					task.wait(0.0000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddDropdown("TreadmillSelector", {
	Values = TreadmillNames,
	Default = TreadmillNames[1],
	Text = "Select Treadmill",
	Callback = function(Value)
		for i, name in ipairs(TreadmillNames) do
			if name == Value then
				CONFIG.SelectedTreadmill = TreadmillList[i]
				break
			end
		end
	end,
})

FarmingGroup:AddToggle("AutoTreadmill", {
	Text = "Auto Treadmill",
	Default = false,
	Tooltip = "Automatically use treadmill",
	Callback = function(Value)
		CONFIG.AutoTreadmill = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTreadmill do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Game.CPlayerTrainClick
						Event:FireServer(CONFIG.SelectedTreadmill)
					end)
					task.wait()
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddDropdown("EggSelector", {
	Values = EggList,
	Default = "Egg1",
	Text = "Select Egg",
	Callback = function(Value)
		CONFIG.SelectedEgg = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Tooltip = "Automatically buy selected egg",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Luck.CPlayerDoLuck
						Event:FireServer(CONFIG.SelectedEgg, 1)
					end)
					task.wait()
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
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Pet.CEquipBestPet
						Event:FireServer()
					end)
					task.wait(10)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgradeStats", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Automatically upgrade all stats",
	Callback = function(Value)
		CONFIG.AutoUpgradeStats = Value
		if Value then
			task.spawn(function()
				local statList = {"LuckAdd", "WinsAdd", "PetEquipAdd", "SpeedAdd"}
				while CONFIG.AutoUpgradeStats do
					for _, stat in ipairs(statList) do
						if not CONFIG.AutoUpgradeStats then break end
						pcall(function()
							local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Base.CUpdataProperty
							Event:FireServer(stat, "wins")
						end)
						task.wait()
					end
					task.wait()
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Tooltip = "Automatically rebirth",
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRebirth do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Event.RemoteEvent.CToS.Game.CTryRebirth
						Event:FireServer()
					end)
					task.wait()
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Aura To Blast Bosses")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Blast Bosses")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Treadmill")
FeaturesGroup:AddLabel("✓ Auto Equip Best Pet")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")
FeaturesGroup:AddLabel("✓ Auto Upgrade")
FeaturesGroup:AddLabel("✓ Auto Rebirth")

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
SaveManager:SetFolder("AntiGodHub/AuraBlastBosses")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
