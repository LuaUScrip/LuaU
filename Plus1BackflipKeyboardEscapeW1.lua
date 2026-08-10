-- +1 Backflip Keyboard Escape | Obsidian UI (Clean)
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
	AutoRebirth = false,
	AutoBuyEquipTrail = false,
	AutoBuyEquipAura = false,
}

-- Win Position
local WinPosition = CFrame.new(-6510.71289, 266.467041, -15756.5098, 0, 0, 1, 0, 1, -0, -1, 0, 0) + Vector3.new(0, 3, 0)

-- Train Positions based on Rebirths
local TrainPositions = {
	[0] = CFrame.new(74.4850082, 2.64596319, -46.2890091, 0, 0, 1, 0, 1, -0, -1, 0, 0) * CFrame.Angles(0, math.pi, 0) + Vector3.new(0, 3, 0),
	[1] = CFrame.new(74.6633606, 2.64596415, -32.2890091, 0, 0, 1, 0, 1, -0, -1, 0, 0) * CFrame.Angles(0, math.pi, 0) + Vector3.new(0, 3, 0),
	[3] = CFrame.new(74.6633606, 2.64596415, -18.2890091, 0, 0, 1, 0, 1, -0, -1, 0, 0) * CFrame.Angles(0, math.pi, 0) + Vector3.new(0, 3, 0),
}

-- Trail List
local TrailList = {
	"OrangeTrail",
	"BlueTrail",
	"GreenTrail",
	"PurpleTrail",
	"RainbowTrail",
	"WhiteTrail",
	"BlackTrail",
	"MoonTrail",
	"NovaTrail",
	"GoldenTrail",
	"DiamondTrail",
	"BubbleTrail",
	"MythicTrail",
	"ColorfulTrail",
	"CrimsonTrail",
	"PrismaticTrail"
}

-- Aura List
local AuraList = {
	"Fire",
	"Water",
	"Blue",
	"Red",
	"Purple",
	"White",
	"Evil",
	"Fire & Ice",
	"Rose",
	"Sukuna",
	"Cosmic King",
	"Dark King",
	"Candy",
	"Aurora",
	"Rainbow",
	"Void",
	"Gojo"
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

local function GetTrainPosition()
	local rebirthCount = GetRebirths()
	local selectedPos = TrainPositions[0]
	
	if rebirthCount >= 3 then
		selectedPos = TrainPositions[3]
	elseif rebirthCount >= 1 then
		selectedPos = TrainPositions[1]
	else
		selectedPos = TrainPositions[0]
	end
	
	return selectedPos
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
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local hrp = player.Character.HumanoidRootPart
							hrp.CFrame = WinPosition
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
							
							local touchPart = workspace:FindFirstChild("GiveWins")
							if touchPart then
								touchPart = touchPart:FindFirstChild("Button14")
								if touchPart then
									touchPart = touchPart:FindFirstChild("Touch")
									if touchPart then
										firetouchinterest(hrp, touchPart, 0)
										task.wait(0.05)
										firetouchinterest(hrp, touchPart, 1)
									end
								end
							end
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
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local hrp = player.Character.HumanoidRootPart
							local trainPos = GetTrainPosition()
							hrp.CFrame = trainPos
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end
					end)
					task.wait(0.05)
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
						local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("Rebirth")
						if Event then
							Event = Event:FindFirstChild("Request")
							if Event then
								Event:InvokeServer()
							end
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

UpgradeGroup:AddToggle("AutoBuyEquipTrail", {
	Text = "Auto Buy & Equip Trail",
	Default = false,
	Tooltip = "Automatically buy and equip all trails",
	Callback = function(Value)
		CONFIG.AutoBuyEquipTrail = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEquipTrail do
					pcall(function()
						for _, trail in ipairs(TrailList) do
							local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("TrailAction")
							if Event then
								Event:FireServer("BuyWins", trail)
								task.wait(0.2)
								Event:FireServer("Equip", trail)
								task.wait(0.2)
							end
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyEquipAura", {
	Text = "Auto Buy & Equip Aura",
	Default = false,
	Tooltip = "Automatically buy and equip all auras",
	Callback = function(Value)
		CONFIG.AutoBuyEquipAura = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEquipAura do
					pcall(function()
						for _, aura in ipairs(AuraList) do
							local Event = ReplicatedStorage:FindFirstChild("Events"):FindFirstChild("AuraAction")
							if Event then
								Event:FireServer("BuyWins", aura)
								task.wait(0.2)
								Event:FireServer("Equip", aura)
								task.wait(0.2)
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

InfoGroup:AddLabel("Game Name : +1 Backflip Keyboard Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/10/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy & Equip Trail")
FeaturesGroup:AddLabel("✓ Auto Buy & Equip Aura")

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
SaveManager:SetFolder("AntiGodHub/BackflipKeyboardEscape")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
