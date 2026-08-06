-- +1 Pickaxe Swing Escape | Obsidian UI (Clean)
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
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Anti-AFK
player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

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

-- Configuration
local CONFIG = {
	AutoWins = false,
	SelectedWorld = "World 1",
	AutoFarmPickaxe = false,
	SelectedFarm = "Dummy 1",
	AutoBuyTrail = false,
	AutoRebirth = false,
}

local TrailList = {"Orange", "Green", "Blue", "Purple", "White", "Black", "Rainbow", "Lava", "Inferno"}

local WorldPositions = {
	["World 1"] = Vector3.new(1208, 6, 163),
	["World 2"] = Vector3.new(1472, 6, 490),
	["World 3"] = Vector3.new(687, 6, 849)
}

local FarmData = {
	["Dummy 1"] = {
		position = Vector3.new(-54, 6, 237),
		hitbox = "Workspace.Dummy1.Starter.Hitbox"
	},
	["Dummy 2"] = {
		position = Vector3.new(-54, 6, 564),
		hitbox = "Workspace.Dummy2.Starter.Hitbox"
	},
	["Dummy 3"] = {
		position = Vector3.new(-54, 6, 922),
		hitbox = "Workspace.Dummy3.Starter.Hitbox"
	}
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

-- Main Tab - Left Side (Auto Wins & Farm)
local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddDropdown("WorldSelect", {
	Values = {"World 1", "World 2", "World 3"},
	Default = 1,
	Text = "Select World",
	Tooltip = "Choose which world to farm",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedWorld = Value
	end,
})

FarmingGroup:AddToggle("AutoWins", {
	Text = "Auto Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoWins do
					pcall(function()
						local char = player.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local pos = WorldPositions[CONFIG.SelectedWorld]
							local rootPart = char.HumanoidRootPart
							
							rootPart.CFrame = CFrame.new(pos)
							task.wait(0.2)
							
							rootPart.CFrame = CFrame.new(pos) * CFrame.new(rootPart.CFrame.LookVector * 10)
							task.wait(0.2)
							
							rootPart.CFrame = CFrame.new(pos)
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmingGroup:AddDivider()

FarmingGroup:AddDropdown("FarmSelect", {
	Values = {"Dummy 1", "Dummy 2", "Dummy 3"},
	Default = 1,
	Text = "Select Farm",
	Tooltip = "Choose which dummy to farm",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedFarm = Value
	end,
})

FarmingGroup:AddToggle("AutoFarmPickaxe", {
	Text = "Auto Farm Pickaxe",
	Default = false,
	Tooltip = "Automatically farm pickaxe",
	Callback = function(Value)
		CONFIG.AutoFarmPickaxe = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmPickaxe do
					pcall(function()
						local char = player.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local farmData = FarmData[CONFIG.SelectedFarm]
							char.HumanoidRootPart.CFrame = CFrame.new(farmData.position)
						end
						
						local dummyNum = string.match(CONFIG.SelectedFarm, "%d+")
						local hitbox = Workspace["Dummy" .. dummyNum].Starter.Hitbox
						
						local Event = ReplicatedStorage.Remotes.DamageBlock
						Event:InvokeServer(hitbox)
					end)
					task.wait(0.000001)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades & Info)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrade", "star")

UpgradeGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyTrail do
					for _, trail in ipairs(TrailList) do
						if not CONFIG.AutoBuyTrail then break end
						pcall(function()
							local Event = ReplicatedStorage.Remotes.BuyTrail
							Event:InvokeServer(trail)
						end)
						task.wait(0.3)
					end
					task.wait(0.5)
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
						local Event = ReplicatedStorage.Remotes.Rebirth
						Event:InvokeServer()
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Pickaxe Swing Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Wins")
FeaturesGroup:AddLabel("✓ Auto Farm Pickaxe")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Multi-World Support")
FeaturesGroup:AddLabel("✓ Anti-AFK Protection")

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
SaveManager:SetFolder("AntiGodHub/PickaxeSwing")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
