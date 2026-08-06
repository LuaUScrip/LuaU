local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CONFIG = {
	AutoFarmFast = false,
	AutoRebirth = false,
	AutoBuyEgg = false,
	SelectedEgg = "NoviceEgg",
}

local EggOptions = {
	"NoviceEgg [400 Wins]",
	"WarriorEgg [12K]",
	"HeroEgg [225K]",
	"LimitedEgg [6.5M]",
	"MysteryEgg [200M]"
}

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

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmFast", {
	Text = "Auto Farm Fast",
	Default = false,
	Tooltip = "Automatically farm fast",
	Callback = function(Value)
		CONFIG.AutoFarmFast = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmFast do
					pcall(function()
						local Event = ReplicatedStorage.Remotes.ClickRequest
						Event:FireServer()
					end)
					task.wait(0.000001)
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
						local Event = ReplicatedStorage.Remotes.RebirthRequest
						Event:FireServer()
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

local EggGroup = Tabs.Main:AddRightGroupbox("Egg", "star")

EggGroup:AddDropdown("EggSelect", {
	Values = EggOptions,
	Default = 1,
	Text = "Select Egg",
	Tooltip = "Choose which egg to buy",
	Searchable = false,
	Callback = function(Value)
		local selected = Value
		if selected:find("NoviceEgg") then
			CONFIG.SelectedEgg = "NoviceEgg"
		elseif selected:find("WarriorEgg") then
			CONFIG.SelectedEgg = "WarriorEgg"
		elseif selected:find("HeroEgg") then
			CONFIG.SelectedEgg = "HeroEgg"
		elseif selected:find("LimitedEgg") then
			CONFIG.SelectedEgg = "LimitedEgg"
		elseif selected:find("MysteryEgg") then
			CONFIG.SelectedEgg = "MysteryEgg"
		end
	end,
})

EggGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg",
	Default = false,
	Tooltip = "Automatically buy selected egg",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = ReplicatedStorage.Remotes.BuyEggEvent
						Event:FireServer(CONFIG.SelectedEgg, 1)
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Loot Evolution")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/1/2026")
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Fast")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")

local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. (LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Yes Premium" or "No Premium"))

local DiscordGroup = Tabs.Player:AddRightGroupbox("Community Support", "users")

DiscordGroup:AddLabel("Join our Discord server for support and script updates!", true)

DiscordGroup:AddButton({
	Text = "Copy Discord Link",
	Func = function()
		setclipboard("https://discord.gg/jdJvZm6VdK")
	end,
	Tooltip = "Copy Discord invite link to clipboard",
})

DiscordGroup:AddLabel("Link: discord.gg/jdJvZm6VdK", true)
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
	Default = 20,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

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
SaveManager:SetFolder("AntiGodHub/LootEvolution")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
