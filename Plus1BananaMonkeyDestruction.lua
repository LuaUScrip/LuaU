local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = workspace

local CONFIG = {
	AutoDestroy = false,
	AutoTrainFast = false,
	AutoUpgrade = false,
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

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Farming", "cpu")

FarmingGroup:AddToggle("AutoDestroy", {
	Text = "Auto Destroy",
	Default = false,
	Tooltip = "Automatically destroy with punch",
	Callback = function(Value)
		CONFIG.AutoDestroy = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoDestroy do
					pcall(function()
						if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
							local pos = LocalPlayer.Character.HumanoidRootPart.Position
							local Event = ReplicatedStorage.Shared.Events.Destruction_Punch
							Event:FireServer(table.unpack({
								[1] = 2,
								[2] = pos,
							}))
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrainFast", {
	Text = "Auto Train Fast",
	Default = false,
	Tooltip = "Teleport to training area and train",
	Callback = function(Value)
		CONFIG.AutoTrainFast = Value
		if Value then
			task.spawn(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-38, 305, 1)
					task.wait(0.2)
				end
				while CONFIG.AutoTrainFast do
					pcall(function()
						local TrainingZone = Workspace.LobbyArea.TrainingArea.Tier1B.Zone
						if TrainingZone then
							local Event = ReplicatedStorage.Shared.Events.Training_Punch
							Event:FireServer(TrainingZone)
						end
					end)
					task.wait(0.0001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Auto buy all upgrades",
	Callback = function(Value)
		CONFIG.AutoUpgrade = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgrade do
					pcall(function()
						local Event = ReplicatedStorage.Shared.Events.Upgrade_Buy
						Event:FireServer("BananaEarnings")
						Event:FireServer("CashEarnings")
						Event:FireServer("MoveSpeed")
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Destroy")
FeaturesGroup:AddLabel("✓ Auto Train Fast")
FeaturesGroup:AddLabel("✓ Auto Upgrade")

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Banana Monkey Destruction")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/2/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

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
	Tooltip = "Copy Discord invite link to clipboard",
})

DiscordGroup:AddLabel("Link: discord.gg/jdJvZm6VdK", true)
DiscordGroup:AddDivider()
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
SaveManager:SetFolder("AntiGodHub/TrainingSimulator")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
