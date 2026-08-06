-- Dog Race | Obsidian UI (Clean)
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
	AutoTrain = false,
	SelectedTreadmill = "Treadmill_1_1",
	AutoRebirth = false,
	AutoBuyDog = false,
	AutoBuyPartner = false,
	AutoBuyUpgrade = false,
	AutoEquipBestPet = false,
	AutoBuyFruit = false,
	SelectedFruit = "Fruit_1",
	AutoBuyEgg = false,
	SelectedEgg = "Egg_1_1",
	AutoBuyCrate = false,
	SelectedCrate = "Crate_1",
	AutoBuyShoes = false,
	AutoBuyBird = false,
}

local RaceLocation = Vector3.new(1824.4993896484, 784.99096679688, -170384.1875)

-- Updated Treadmill Options with World labels
local TrainOptions = {}
local TrainOptionsMapped = {}
for area = 1, 3 do
	for treadmill = 1, 7 do
		local displayName = "Train " .. treadmill .. " [WORLD " .. area .. "]"
		local actualName = "Treadmill_" .. area .. "_" .. treadmill
		table.insert(TrainOptions, displayName)
		TrainOptionsMapped[displayName] = actualName
	end
end

local FruitOptions = {}
for i = 1, 10 do
	table.insert(FruitOptions, "Fruit " .. i)
end

-- Updated Egg Options with simpler naming + Jurassic Event
local EggOptions = {}
local EggOptionsMapped = {}
for row = 1, 3 do
	for col = 1, 3 do
		local displayName = "Egg " .. col .. " [WORLD " .. row .. "]"
		local actualName = "Egg_" .. row .. "_" .. col
		table.insert(EggOptions, displayName)
		EggOptionsMapped[displayName] = actualName
	end
end

-- Add Jurassic Event Eggs
for i = 1, 2 do
	local displayName = "Egg " .. i .. " [EVENT]"
	local actualName = "Egg_Jurassic_" .. i
	table.insert(EggOptions, displayName)
	EggOptionsMapped[displayName] = actualName
end

-- Updated Dog List: 101-108, 201-208, 301-308
local DogList = {}
for range = 1, 3 do
	for i = 1, 8 do
		table.insert(DogList, "Dog_" .. (range * 100 + i))
	end
end

-- Updated Partner List: 1-8
local PartnerList = {}
for i = 1, 8 do
	table.insert(PartnerList, "Partner_" .. i)
end

-- Updated Crate Options with World labels
local CrateOptions = {}
local CrateOptionsMapped = {}
for i = 1, 3 do
	local displayName = "Crate " .. i .. " [WORLD " .. i .. "]"
	local actualName = "Crate_" .. i
	table.insert(CrateOptions, displayName)
	CrateOptionsMapped[displayName] = actualName
end

-- Shoes Options: Shoes_101 to Shoes_111
local ShoesList = {}
for i = 101, 111 do
	table.insert(ShoesList, "Shoes_" .. i)
end

-- Bird Options: Bird_101 to Bird_108
local BirdList = {}
for i = 101, 108 do
	table.insert(BirdList, "Bird_" .. i)
end

local UpgradeList = {
	"Upgrade_TopSpeed",
	"Upgrade_Strength",
	"Upgrade_Acc",
	"Upgrade_Diamond_Num",
	"Upgrade_Diamond_Chance",
	"Upgrade_Luck",
	"Upgrade_StartSpeed"
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
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.FightService.RE.GetWinsEvent
						Event:FireServer("WinGate_16", RaceLocation)
					end)
					task.wait(0.000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddDropdown("TreadmillSelect", {
	Values = TrainOptions,
	Default = 1,
	Text = "Select Treadmill",
	Tooltip = "Choose which treadmill to train on",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedTreadmill = TrainOptionsMapped[Value]
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train on selected treadmill",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.TrainService.RE.RunTrain
						Event:FireServer(CONFIG.SelectedTreadmill)
					end)
					task.wait(0.01)
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
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.RebirthService.RF.Rebirth
						Event:InvokeServer()
					end)
					task.wait(2)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddToggle("AutoBuyShoes", {
	Text = "Auto Buy Shoes",
	Default = false,
	Tooltip = "Automatically buy all shoes (101-111)",
	Callback = function(Value)
		CONFIG.AutoBuyShoes = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyShoes do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.ShoeService.RE.BuyShoeEvent
						for _, shoes in ipairs(ShoesList) do
							Event:FireServer(shoes)
							task.wait(0.5)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyBird", {
	Text = "Auto Buy Birds",
	Default = false,
	Tooltip = "Automatically buy all birds (101-108)",
	Callback = function(Value)
		CONFIG.AutoBuyBird = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyBird do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.BirdService.RE.BuyBirdEvent
						for _, bird in ipairs(BirdList) do
							Event:FireServer(bird)
							task.wait(0.5)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyDog", {
	Text = "Auto Buy Dogs",
	Default = false,
	Tooltip = "Automatically buy all dogs (101-108, 201-208, 301-308)",
	Callback = function(Value)
		CONFIG.AutoBuyDog = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyDog do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.HorseService.RE.UnlockHorseEvent
						for _, dog in ipairs(DogList) do
							Event:FireServer(dog)
							task.wait(0.5)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyPartner", {
	Text = "Auto Buy Partners",
	Default = false,
	Tooltip = "Automatically buy all partners (1-8)",
	Callback = function(Value)
		CONFIG.AutoBuyPartner = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyPartner do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.PrincessService.RE.UnlockPrincess
						for _, partner in ipairs(PartnerList) do
							Event:FireServer(partner, "Wins")
							task.wait(0.5)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyUpgrade", {
	Text = "Auto Buy Upgrades",
	Default = false,
	Tooltip = "Automatically buy all upgrades",
	Callback = function(Value)
		CONFIG.AutoBuyUpgrade = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyUpgrade do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.UpgradeService.RE.Upgrade
						for _, upgrade in ipairs(UpgradeList) do
							Event:FireServer(upgrade)
						end
					end)
					task.wait(1)
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
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.PetService.RE.EquipBestPets
						Event:FireServer()
					end)
					task.wait(2)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDropdown("FruitSelect", {
	Values = FruitOptions,
	Default = 1,
	Text = "Select Fruit",
	Tooltip = "Choose which fruit to buy",
	Searchable = false,
	Callback = function(Value)
		local index = tonumber(string.match(Value, "%d+"))
		CONFIG.SelectedFruit = "Fruit_" .. index
	end,
})

UpgradeGroup:AddToggle("AutoBuyFruit", {
	Text = "Auto Buy Fruit",
	Default = false,
	Tooltip = "Automatically buy selected fruit",
	Callback = function(Value)
		CONFIG.AutoBuyFruit = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyFruit do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.FruitShopService.RE.BuyFruitEvent
						Event:FireServer(CONFIG.SelectedFruit)
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDropdown("EggSelect", {
	Values = EggOptions,
	Default = 1,
	Text = "Select Egg",
	Tooltip = "Choose which egg to hatch",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedEgg = EggOptionsMapped[Value]
	end,
})

UpgradeGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Tooltip = "Automatically hatch selected egg",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.EggHatchService.RE.Hatch
						Event:FireServer(CONFIG.SelectedEgg, 1)
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

UpgradeGroup:AddDropdown("CrateSelect", {
	Values = CrateOptions,
	Default = 1,
	Text = "Select Crate",
	Tooltip = "Choose which crate to buy",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedCrate = CrateOptionsMapped[Value]
	end,
})

UpgradeGroup:AddToggle("AutoBuyCrate", {
	Text = "Auto Buy Crate",
	Default = false,
	Tooltip = "Automatically buy selected crate",
	Callback = function(Value)
		CONFIG.AutoBuyCrate = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyCrate do
					pcall(function()
						local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.5.1"].knit.Services.ItemCrateService.RE.BuyCrateWithDiamonds
						Event:FireServer(CONFIG.SelectedCrate, 8)
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Dog Race")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Dogs")
FeaturesGroup:AddLabel("✓ Auto Buy Partners")
FeaturesGroup:AddLabel("✓ Auto Buy Upgrades")
FeaturesGroup:AddLabel("✓ Auto Equip Best Pet")
FeaturesGroup:AddLabel("✓ Auto Buy Fruit")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")
FeaturesGroup:AddLabel("✓ Auto Buy Crate")
FeaturesGroup:AddLabel("✓ Auto Buy Shoes")
FeaturesGroup:AddLabel("✓ Auto Buy Bird")

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
SaveManager:SetFolder("AntiGodHub/DogRace")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
