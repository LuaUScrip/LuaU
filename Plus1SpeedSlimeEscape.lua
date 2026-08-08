-- +1 Speed Slime Escape | Obsidian UI (Clean)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	AutoFarmWins = false,
	SelectedWorld = "World 1",
	AutoTrain = false,
	AutoRebirth = false,
	AutoBuyTrail = false,
	AutoBuyAura = false,
	AutoBuyBestItems = false,
	AutoEquipBestItems = false,
}

-- Win Positions
local WinPositions = {
	["World 1"] = CFrame.new(-499.937134, 582.330933, 7579.62256, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	["World 2"] = CFrame.new(-509.266724, 172.690475, 464.342407, -1, 0, 0, 0, 1, 0, 0, 0, -1),
}

-- Trail List
local TrailList = {
	"GreenTrail",
	"BlueTrail",
	"PurpleTrail",
	"RedTrail",
	"RainbowTrail",
	"CosmicTrail",
	"VoidTrail",
	"SupernovaTrail",
	"GodlikeTrail"
}

-- Aura List
local AuraList = {
	"GlowAura",
	"WindAura",
	"WaterAura",
	"FireAura",
	"ElectricAura",
	"CandyAura",
	"ChocolateAura",
	"StormAura"
}

local function GetRebirths()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("\240\159\148\132 Rebirth")
		if rebirths then
			return rebirths.Value
		end
	end
	return 0
end

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
							end
						end
					end)
					task.wait(0.1)
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
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("UpdateSpeed")
						if Event then
							Event:FireServer("Walking")
							task.wait(0.1)
							Event:FireServer("Treadmill")
						end
					end)
					task.wait(0.001)
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
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Rebirth")
						if Event then
							Event:FireServer()
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
							local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("BuyTrail")
							if Event then
								Event:InvokeServer(trail, "Wins")
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

UpgradeGroup:AddToggle("AutoBuyAura", {
	Text = "Auto Buy Aura",
	Default = false,
	Tooltip = "Automatically buy all auras",
	Callback = function(Value)
		CONFIG.AutoBuyAura = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyAura do
					pcall(function()
						for _, aura in ipairs(AuraList) do
							local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("BuyAura")
							if Event then
								Event:InvokeServer(aura, "Wins")
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

UpgradeGroup:AddToggle("AutoBuyBestItems", {
	Text = "Auto Buy Best Items",
	Default = false,
	Tooltip = "Automatically buy best items",
	Callback = function(Value)
		CONFIG.AutoBuyBestItems = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyBestItems do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("ItemsShopAction")
						if Event then
							Event:FireServer("BuyWins", "Mysterious")
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoEquipBestItems", {
	Text = "Auto Equip Best Items",
	Default = false,
	Tooltip = "Automatically equip best items",
	Callback = function(Value)
		CONFIG.AutoEquipBestItems = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoEquipBestItems do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("ItemAction")
						if Event then
							Event:FireServer("EquipBest")
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Speed Slime Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/8/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Buy Aura")
FeaturesGroup:AddLabel("✓ Auto Buy Best Items")
FeaturesGroup:AddLabel("✓ Auto Equip Best Items")

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
SaveManager:SetFolder("AntiGodHub/SpeedSlimeEscape")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")