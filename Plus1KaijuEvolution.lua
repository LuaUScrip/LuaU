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
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	AutoFarmWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoEvolve = false,
	AutoBuyTrail = false,
	SelectedTrain = "Train 1",
}

-- Trail List
local TrailList = {
	"Ice",
	"BubbleGum",
	"Toxic",
	"Lava",
	"Robux"
}

-- Train Locations
local TrainLocations = {
	["Train 1"] = function()
		local part = workspace.Map.Treadmills:GetChildren()[6]:GetChildren()[3]
		return part and part.Position or nil
	end,
	["Train 2"] = function()
		local part = workspace.Map.Treadmills.Red.Part
		return part and part.Position or nil
	end,
	["Train 3"] = function()
		local part = workspace.Map.Treadmills.Green:GetChildren()[3]
		return part and part.Position or nil
	end,
	["Train 4"] = function()
		local part = workspace.Map.Treadmills.Blue:GetChildren()[2]
		return part and part.Position or nil
	end,
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
						local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
						if humanoidRootPart then
							humanoidRootPart.CFrame = CFrame.new(-225.24942, 17.3000069, 2757.70532, -1.1920929e-07, -0, -1.00000012, 0, 1, -0, 1.00000012, 0, -1.1920929e-07)
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

FarmingGroup:AddDropdown("TrainSelect", {
	Values = {"Train 1", "Train 2", "Train 3", "Train 4"},
	Default = 1,
	Text = "Select Train",
	Tooltip = "Choose which train to use",
	Searchable = false,
	Callback = function(Value)
		CONFIG.SelectedTrain = Value
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train at selected location",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local getPos = TrainLocations[CONFIG.SelectedTrain]
						if getPos then
							local pos = getPos()
							if pos then
								local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
								if humanoidRootPart then
									humanoidRootPart.CFrame = CFrame.new(pos)
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

FarmingGroup:AddToggle("AutoEvolve", {
	Text = "Auto Evolve",
	Default = false,
	Tooltip = "Automatically evolve pets",
	Callback = function(Value)
		CONFIG.AutoEvolve = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoEvolve do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RequestEvolve")
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

-- Main Tab - Right Side (Trails)
local TrailGroup = Tabs.Main:AddRightGroupbox("Auto Trail", "star")

TrailGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy and equip all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyTrail do
					pcall(function()
						for _, trail in ipairs(TrailList) do
							local BuyEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RequestBuyTrail")
							if BuyEvent then
								BuyEvent:InvokeServer(trail)
								task.wait(0.3)
							end
							local EquipEvent = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("RequestEquipTrail")
							if EquipEvent then
								EquipEvent:InvokeServer(trail)
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

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Kaiju Evolution")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/3/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train (4 Locations)")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Evolve")
FeaturesGroup:AddLabel("✓ Auto Buy Trail (5 Trails)")

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
