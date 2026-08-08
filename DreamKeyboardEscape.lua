local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

task.spawn(function()
	while task.wait() do
		pcall(function()
			if LocalPlayer.GameplayPaused then
				LocalPlayer.GameplayPaused = false
			end
		end)
	end
end)

local CONFIG = {
	AutoFarmWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoBuyItems = false,
	AutoBuyEquipAura = false,
	AutoBuyEquipTrail = false,
}

local FARM_WINS_CFRAME = CFrame.new(-1062.0675, 1283.45386, -2731.64673, 0, 0, -1, 0, 1, 0, 1, 0, 0)

local AuraList = {
	"Bubble",
	"Water",
	"Lightning",
	"Spirit",
	"Flame",
	"Runic",
	"Shadow",
	"Idol",
	"Aqua",
	"Thunder",
	"StarEmperor",
	"Shaman",
	"Gilded",
	"UltraInstinct",
	"SeaKing",
	"ImaginaryTechnique",
	"DarkEsper",
	"AuroraStar",
	"JoyBoy"
}

local TrailList = {
	"OrangeTrail",
	"BlueTrail",
	"GreenTrail",
	"PurpleTrail",
	"RainbowTrail",
	"HeavenTrail",
	"JungleTrail"
}

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoFarmWins then
			pcall(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character.HumanoidRootPart.CFrame = FARM_WINS_CFRAME
					LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 3, 0)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.00000001) do
		if CONFIG.AutoTrain then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
				if Event then
					local AddSpeed = Event:FindFirstChild("AddSpeed")
					if AddSpeed then
						AddSpeed:FireServer()
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoRebirth then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
				if Event then
					local RequestRebirth = Event:FindFirstChild("RequestRebirth")
					if RequestRebirth then
						RequestRebirth:InvokeServer()
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoBuyItems then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
				if Event then
					local ItemAction = Event:FindFirstChild("ItemAction")
					if ItemAction then
						ItemAction:FireServer("BuyWins", "SpeedBoots3")
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoBuyEquipAura then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
				if Event then
					local AuraAction = Event:FindFirstChild("AuraAction")
					if AuraAction then
						for _, aura in ipairs(AuraList) do
							AuraAction:FireServer("BuyWins", aura)
							task.wait(0.05)
							AuraAction:FireServer("Equip", aura)
							task.wait(0.05)
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoBuyEquipTrail then
			pcall(function()
				local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
				if Event then
					local TrailAction = Event:FindFirstChild("TrailAction")
					if TrailAction then
						for _, trail in ipairs(TrailList) do
							TrailAction:FireServer("BuyWins", trail)
							task.wait(0.05)
							TrailAction:FireServer("Equip", trail)
							task.wait(0.05)
						end
					end
				end
			end)
		end
	end
end)

local Window = Library:CreateWindow({
	Title = "AntiGodHub",
	Footer = "Version: 2.0 - YouTube AntiGodHub Subscribe",
	Icon = nil,
	NotifySide = "Right",
	ShowCustomCursor = false,
})

local Tabs = {
	Main = Window:AddTab("Main", "star"),
	Player = Window:AddTab("Player", "user"),
	Settings = Window:AddTab("UI Settings", "settings"),
}

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Farm wins automatically",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Train automatically",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
	end,
})

FarmingGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Tooltip = "Automatically rebirth",
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
	end,
})

FarmingGroup:AddToggle("AutoBuyItems", {
	Text = "Auto Buy Items",
	Default = false,
	Tooltip = "Buy speed boots automatically",
	Callback = function(Value)
		CONFIG.AutoBuyItems = Value
	end,
})

FarmingGroup:AddToggle("AutoBuyEquipAura", {
	Text = "Auto Buy&Equip Aura",
	Default = false,
	Tooltip = "Buy and equip all auras automatically",
	Callback = function(Value)
		CONFIG.AutoBuyEquipAura = Value
	end,
})

FarmingGroup:AddToggle("AutoBuyEquipTrail", {
	Text = "Auto Buy&Equip Trail",
	Default = false,
	Tooltip = "Buy and equip all trails automatically",
	Callback = function(Value)
		CONFIG.AutoBuyEquipTrail = Value
	end,
})

local InfoGroup = Tabs.Main:AddRightGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Dream Keyboard Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/8/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Items")
FeaturesGroup:AddLabel("✓ Auto Buy&Equip Aura")
FeaturesGroup:AddLabel("✓ Auto Buy&Equip Trail")

local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. GetPremiumStatus())

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
ThemeManager:SetFolder("DreamHub")
SaveManager:SetFolder("DreamHub/Dream")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")