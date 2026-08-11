-- +1 Fire Per Click | Obsidian UI (Clean)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Configuration
local CONFIG = {
	AutoFarmWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoRollTitle = false,
	AutoUpgrade = false,
	AutoBuyBestEgg = false,
}

-- Win Position
local WinPosition = CFrame.new(7.73985863, 0.0223433971, 2504.81812, -1, 0, 0, 0, 1, 0, 0, 0, -1) + Vector3.new(0, 3, 0)

-- Upgrade List
local UpgradeList = {
	"SpeedUpgrade",
	"PetLuck",
	"PetSlot",
	"TitleLuck"
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
						if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
							local hrp = player.Character.HumanoidRootPart
							hrp.CFrame = WinPosition
							hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
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
						local Event = ReplicatedStorage:FindFirstChild("FireEvents"):FindFirstChild("AddPower")
						if Event then
							Event:FireServer()
						end
					end)
					task.wait(0.00000001)
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
						local Event = ReplicatedStorage:FindFirstChild("FireEvents"):FindFirstChild("DoRebirth")
						if Event then
							Event:FireServer()
						end
					end)
					task.wait(0.001)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoRollTitle", {
	Text = "Auto Roll Title",
	Default = false,
	Tooltip = "Automatically roll titles",
	Callback = function(Value)
		CONFIG.AutoRollTitle = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRollTitle do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("TitleRemotes"):FindFirstChild("RollTitle")
						if Event then
							Event:InvokeServer("Normal")
						end
					end)
					task.wait(0.00001)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Automatically buy all upgrades",
	Callback = function(Value)
		CONFIG.AutoUpgrade = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgrade do
					pcall(function()
						for _, upgrade in ipairs(UpgradeList) do
							local Event = ReplicatedStorage:FindFirstChild("ShopEvents"):FindFirstChild("BuyUpgrade")
							if Event then
								Event:FireServer(upgrade, "wins")
								task.wait(0.01)
							end
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoBuyBestEgg", {
	Text = "Auto Buy Best Egg",
	Default = false,
	Tooltip = "Automatically buy best egg",
	Callback = function(Value)
		CONFIG.AutoBuyBestEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyBestEgg do
					pcall(function()
						local eggResource = ReplicatedStorage:FindFirstChild("Resources")
						if eggResource then
							eggResource = eggResource:FindFirstChild("Eggs")
							if eggResource then
								local moltenEgg = eggResource:FindFirstChild("Molten")
								if moltenEgg then
									local Event = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Eggs"):FindFirstChild("BuyEgg")
									if Event then
										Event:InvokeServer(moltenEgg)
									end
								end
							end
						end
					end)
					task.wait(0.001)
				end
			end)
		end
	end,
})

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Fire Per Click")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/11/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Roll Title")
FeaturesGroup:AddLabel("✓ Auto Upgrade")
FeaturesGroup:AddLabel("✓ Auto Buy Best Egg")

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
SaveManager:SetFolder("AntiGodHub/FirePerClick")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")