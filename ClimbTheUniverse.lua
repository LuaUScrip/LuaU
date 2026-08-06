local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local CONFIG = {
	AutoFarmCoin = false,
	AutoFarmWins = false,
	AutoBuyWing = false,
	AutoBuyEgg = false,
	SelectedEgg = "Egg1",
	AutoFarmGems = false,
}

local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Footer = "Version: 2.0 - YouTube: AntiGodHub",
	Icon = nil,
	NotifySide = "Right",
	ShowCustomCursor = false,
})

local Tabs = {
	Main = Window:AddTab("Main", "star"),
	Player = Window:AddTab("Player", "user"),
	Settings = Window:AddTab("Settings", "settings"),
}

--==================================================
-- AUTO FARMING
--==================================================

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmCoin", {
	Text = "Auto Farm Coin",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoFarmCoin = Value
	end,
})

task.spawn(function()
	while true do
		task.wait(0.1)
		if CONFIG.AutoFarmCoin then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage").REMOTES.ClimbSystem.Landed
				Event:FireServer(math.huge)
			end)
		end
	end
end)

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

task.spawn(function()
	while true do
		task.wait(0.1)
		if CONFIG.AutoFarmWins then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage").REMOTES.WinSystem.RequestWins
				Event:FireServer()
			end)
		end
	end
end)

FarmingGroup:AddToggle("AutoFarmGems", {
	Text = "Auto Farm Gems",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoFarmGems = Value
	end,
})

task.spawn(function()
	while true do
		task.wait(0.01)
		if CONFIG.AutoFarmGems then
			pcall(function()
				local hitbox = workspace.Map6.WinPlatform.gempodest.hitbox
				firetouchinterest(Character.HumanoidRootPart, hitbox, 0)
				task.wait(0.01)
				firetouchinterest(Character.HumanoidRootPart, hitbox, 1)
			end)
		end
	end
end)

FarmingGroup:AddToggle("AutoBuyWing", {
	Text = "Auto Buy Wings",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBuyWing = Value
	end,
})

task.spawn(function()
	while true do
		task.wait(0.1)
		if CONFIG.AutoBuyWing then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage").REMOTES.WingSystem.BuyWing
				for i = 1, 54 do
					Event:FireServer("wing_" .. i)
				end
			end)
		end
	end
end)

--==================================================
-- AUTO BUY EGGS
--==================================================

local EggGroup = Tabs.Main:AddRightGroupbox("Auto Buy Eggs", "gift")

local eggList = {}
for i = 1, 18 do
	table.insert(eggList, "Egg" .. i)
end

EggGroup:AddDropdown("EggSelect", {
	Values = eggList,
	Default = 1,
	Text = "Select Egg",
	Callback = function(Value)
		CONFIG.SelectedEgg = Value
	end,
})

EggGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
	end,
})

task.spawn(function()
	while true do
		task.wait(0.1)
		if CONFIG.AutoBuyEgg then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage").REMOTES.EggSystem.StartHatch
				Event:FireServer(CONFIG.SelectedEgg, "single")
			end)
		end
	end
end)

--==================================================
-- SCRIPT INFO
--==================================================

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Climb The Universe")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

--==================================================
-- FEATURES
--==================================================

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Coin")
FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Farm Gems")
FeaturesGroup:AddLabel("✓ Auto Buy Wings")
FeaturesGroup:AddLabel("✓ Auto Buy Eggs")

--==================================================
-- PLAYER TAB
--==================================================

local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. (LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Yes Premium" or "No Premium"))

local DiscordGroup = Tabs.Player:AddRightGroupbox("Community Support", "users")

DiscordGroup:AddLabel("Join our Discord server for support!", true)
DiscordGroup:AddDivider()

DiscordGroup:AddButton({
	Text = "Copy Discord Link",
	Func = function()
		setclipboard("https://discord.gg/jdJvZm6VdK")
	end,
})

DiscordGroup:AddLabel("discord.gg/jdJvZm6VdK", true)
DiscordGroup:AddDivider()
DiscordGroup:AddLabel("✓ Get Support", true)
DiscordGroup:AddLabel("✓ Script Updates", true)
DiscordGroup:AddLabel("✓ Feature Requests", true)
DiscordGroup:AddLabel("✓ Community Tips", true)

--==================================================
-- SETTINGS TAB
--==================================================

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
SaveManager:SetFolder("AntiGodHub/ClimbTheUniverse")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

--==================================================
-- RESET ON CHARACTER DEATH
--==================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	CONFIG.AutoFarmCoin = false
	CONFIG.AutoFarmWins = false
	CONFIG.AutoBuyWing = false
	CONFIG.AutoBuyEgg = false
	CONFIG.AutoFarmGems = false
end)
