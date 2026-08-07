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
	AutoBuyTitle = false,
}

-- Title List
local TitleList = {
	"Rookie Racer",
	"Speed Starter",
	"Road Rocket",
	"Turbo Driver",
	"Drift Star",
	"Nitro Racer",
	"Track Ace",
	"Racing Pro",
	"Speed Hero",
	"Nitro Champion",
	"Supercar Elite",
	"Hypercar Hero",
	"Road Royalty"
}

-- Train Treadmills based on Rebirths
local TrainTreadmills = {
	[0] = "Normal",
	[2] = "Gold",
	[4] = "Green",
	[6] = "Purple",
	[10] = "Red",
	[15] = "CandyApple",
	[20] = "CandyPurple",
	[50] = "Cherry",
}

local function GetRebirths()
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			return rebirths.Value
		end
	end
	return 0
end

local function GetTrainTreadmill()
	local rebirthCount = GetRebirths()
	local selectedTrain = TrainTreadmills[0]
	
	if rebirthCount >= 2 then
		selectedTrain = TrainTreadmills[2]
	end
	if rebirthCount >= 4 then
		selectedTrain = TrainTreadmills[4]
	end
	if rebirthCount >= 6 then
		selectedTrain = TrainTreadmills[6]
	end
	if rebirthCount >= 10 then
		selectedTrain = TrainTreadmills[10]
	end
	if rebirthCount >= 15 then
		selectedTrain = TrainTreadmills[15]
	end
	if rebirthCount >= 20 then
		selectedTrain = TrainTreadmills[20]
	end
	if rebirthCount >= 50 then
		selectedTrain = TrainTreadmills[50]
	end
	
	return selectedTrain
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
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("RequestWin")
						if Event then
							Event:InvokeServer("Section30", "WinCollect")
						end
					end)
					task.wait(0.01)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train based on Rebirths",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local trainTreadmill = GetTrainTreadmill()
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("TreadmillState")
						if Event and trainTreadmill then
							Event:FireServer(true, trainTreadmill, false)
						end
					end)
					task.wait(0.00001)
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
						local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("RequestRebirth")
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

-- Main Tab - Right Side (Titles)
local TitleGroup = Tabs.Main:AddRightGroupbox("Auto Title", "star")

TitleGroup:AddToggle("AutoBuyTitle", {
	Text = "Auto Buy Title",
	Default = false,
	Tooltip = "Automatically buy all titles",
	Callback = function(Value)
		CONFIG.AutoBuyTitle = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyTitle do
					pcall(function()
						for _, title in ipairs(TitleList) do
							local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("RequestTitleAction")
							if Event then
								Event:InvokeServer("BuyWins", title)
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

InfoGroup:AddLabel("Game Name : Cars Vs Tape")
InfoGroup:AddLabel("Developer : AntiGod")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Title")

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
