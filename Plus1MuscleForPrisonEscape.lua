-- +1 Muscle For Prison Escape | Obsidian UI (Clean)
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
	AutoTrainFast = false,
	AutoRebirth = false,
	AutoSellAll = false,
	AutoUpgrade = false,
	AutoBuyWeapon = false,
	AutoBuyAura = false,
	AutoClaimQuest = false,
	AutoClaimEvent = false,
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

-- Auto Train Fast
task.spawn(function()
	while task.wait(0.0000001) do
		pcall(function()
			if CONFIG.AutoTrainFast then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Power = Event:FindFirstChild("Power")
					if Power then
						Power:FireServer("GainPowerBatch", math.huge, math.huge)
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
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local PlayerF = Event:FindFirstChild("PlayerF")
					if PlayerF then
						PlayerF:InvokeServer("Rebirth")
					end
				end
			end
		end)
	end
end)

-- Auto Sell All
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoSellAll then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local TreasureF = Event:FindFirstChild("TreasureF")
					if TreasureF then
						TreasureF:InvokeServer("SellAllTreasures")
					end
				end
			end
		end)
	end
end)

-- Auto Upgrade
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoUpgrade then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Upgrade = Event:FindFirstChild("Upgrade")
					if Upgrade then
						local upgrades = {"CarryBagNum", "Speed", "Lucky"}
						for _, upgrade in ipairs(upgrades) do
							Upgrade:FireServer("Upgrade", upgrade)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Weapon
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyWeapon then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Weapon = Event:FindFirstChild("Weapon")
					if Weapon then
						local ranges = {{101, 112}, {201, 210}, {301, 310}}
						for _, range in ipairs(ranges) do
							for i = range[1], range[2] do
								Weapon:FireServer("RequestEquipOrBuy", i)
							end
						end
					end
				end
			end
		end)
	end
end)

-- Auto Buy Aura
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoBuyAura then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Aura = Event:FindFirstChild("Aura")
					if Aura then
						for i = 1, 10 do
							Aura:FireServer("RequestEquipOrBuy", i)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Claim Quest
task.spawn(function()
	while task.wait() do
		pcall(function()
			if CONFIG.AutoClaimQuest then
				local Event = ReplicatedStorage:FindFirstChild("Remote")
				if Event then
					local Season = Event:FindFirstChild("Season")
					if Season then
						for i = 1, 10 do
							Season:FireServer("ClaimQuest", i)
						end
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
	Text = "Teleport To Best Area",
	Func = function()
		pcall(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = CFrame.new(71760, -107, -1160)
			end
		end)
	end,
	Tooltip = "Teleport to best area",
})

FarmingGroup:AddToggle("AutoTrainFast", {
	Text = "Auto Train Fast",
	Default = false,
	Tooltip = "Automatically train fast",
	Callback = function(Value)
		CONFIG.AutoTrainFast = Value
	end,
})

FarmingGroup:AddToggle("AutoSellAll", {
	Text = "Auto Sell All",
	Default = false,
	Tooltip = "Automatically sell all treasures",
	Callback = function(Value)
		CONFIG.AutoSellAll = Value
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

UpgradeGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Automatically upgrade all types",
	Callback = function(Value)
		CONFIG.AutoUpgrade = Value
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

UpgradeGroup:AddToggle("AutoBuyWeapon", {
	Text = "Auto Buy Weapon",
	Default = false,
	Tooltip = "Automatically buy all weapons",
	Callback = function(Value)
		CONFIG.AutoBuyWeapon = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyAura", {
	Text = "Auto Buy Aura",
	Default = false,
	Tooltip = "Automatically buy all auras",
	Callback = function(Value)
		CONFIG.AutoBuyAura = Value
	end,
})

UpgradeGroup:AddToggle("AutoClaimQuest", {
	Text = "Auto Claim Quest",
	Default = false,
	Tooltip = "Automatically claim all quests",
	Callback = function(Value)
		CONFIG.AutoClaimQuest = Value
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Muscle For Prison Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Teleport To Best Area")
FeaturesGroup:AddLabel("✓ Auto Train Fast")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Sell All")
FeaturesGroup:AddLabel("✓ Auto Upgrade")
FeaturesGroup:AddLabel("✓ Auto Buy Weapon")
FeaturesGroup:AddLabel("✓ Auto Buy Aura")
FeaturesGroup:AddLabel("✓ Auto Claim Quest")
FeaturesGroup:AddLabel("✓ Auto Claim Event")

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
SaveManager:SetFolder("AntiGodHub/MuscleForPrisonEscape")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
