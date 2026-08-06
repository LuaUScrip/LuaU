local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local CONFIG = {
	AutoFarmLadder = false,
	AutoFarmWins = false,
	AutoRebirth = false,
	AutoClaimQuest = false,
	AutoSpinWheel = false,
	AutoBuyEgg = false,
	AutoEquipPet = false,
	AutoUpgradeShop = false,
	AutoUpgradeBoost = false,
	AutoUpgradeLadder = false,
	AutoUpgradeWins = false,
	AutoUpgradeLuck = false,
}

local function TeleportCharacter(x, y, z)
	if Character and Character:FindFirstChild("HumanoidRootPart") then
		Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z)
	end
end

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
	Settings = Window:AddTab("Settings", "settings"),
}

--==================================================
-- AUTO FARM
--==================================================

local FarmGroup = Tabs.Main:AddLeftGroupbox("Auto Farm", "cpu")

FarmGroup:AddToggle("AutoFarmLadder", {
	Text = "Auto Farm Ladder",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoFarmLadder = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmLadder do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.ClickEvent
						Event:FireServer()
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

FarmGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmWins do
					pcall(function()
						TeleportCharacter(-574, 4240, -23)
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRebirth do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.RequestRebirth
						Event:FireServer()
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmGroup:AddToggle("AutoClaimQuest", {
	Text = "Auto Claim Quest",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoClaimQuest = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoClaimQuest do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.ClaimQuest
						Event:InvokeServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmGroup:AddToggle("AutoSpinWheel", {
	Text = "Auto Spin Wheel",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoSpinWheel = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSpinWheel do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.SpinWheel
						Event:InvokeServer()
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

--==================================================
-- EGGS & PETS
--==================================================

local EggGroup = Tabs.Main:AddRightGroupbox("Eggs & Pets", "gift")

EggGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Best Egg",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.OpenEgg
						Event:InvokeServer("Gold")
					end)
					task.wait(0.3)
				end
			end)
		end
	end,
})

EggGroup:AddToggle("AutoEquipPet", {
	Text = "Auto Equip Best Pet",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoEquipPet = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoEquipPet do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.PetAction
						Event:InvokeServer("EquipAll")
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

--==================================================
-- AUTO UPGRADES
--==================================================

local UpgradeGroup = Tabs.Main:AddLeftGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoUpgradeShop", {
	Text = "Auto Upgrade Shop",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoUpgradeShop = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgradeShop do
					pcall(function()
						local Event1 = game:GetService("ReplicatedStorage").Remotes.RequestUpgrade
						Event1:FireServer("Speed")
						
						local Event2 = game:GetService("ReplicatedStorage").Remotes.RequestUpgrade
						Event2:FireServer("PetEquip")
					end)
					task.wait(0.3)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgradeBoost", {
	Text = "Auto Upgrade Boost",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoUpgradeBoost = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgradeBoost do
					pcall(function()
						local Event1 = game:GetService("ReplicatedStorage").Remotes.RequestBoost
						Event1:FireServer("Ladder")
						
						local Event2 = game:GetService("ReplicatedStorage").Remotes.RequestBoost
						Event2:FireServer("Wins")
						
						local Event3 = game:GetService("ReplicatedStorage").Remotes.RequestBoost
						Event3:FireServer("Luck")
					end)
					task.wait(0.3)
				end
			end)
		end
	end,
})

--==================================================
-- FEATURES
--==================================================

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Ladder")
FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Eggs")
FeaturesGroup:AddLabel("✓ Auto Equip Pet")
FeaturesGroup:AddLabel("✓ Auto Upgrades")
FeaturesGroup:AddLabel("✓ Auto Spin Wheel")

--==================================================
-- GAME INFO
--==================================================

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Ladder Per Click")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

--==================================================
-- PLAYER TAB
--==================================================

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
})

DiscordGroup:AddLabel("discord.gg/jdJvZm6VdK", true)
DiscordGroup:AddDivider()
DiscordGroup:AddLabel("✓ Get Support", true)
DiscordGroup:AddLabel("✓ Script Updates", true)
DiscordGroup:AddLabel("✓ Feature Requests", true)
DiscordGroup:AddLabel("✓ Community Tips", true)

--==================================================
-- SETTINGS TAB
--==================================================

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
SaveManager:SetFolder("AntiGodHub/LadderPerClick")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

--==================================================
-- RESET ON CHARACTER DEATH
--==================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	CONFIG.AutoFarmLadder = false
	CONFIG.AutoFarmWins = false
	CONFIG.AutoRebirth = false
	CONFIG.AutoClaimQuest = false
	CONFIG.AutoSpinWheel = false
	CONFIG.AutoBuyEgg = false
	CONFIG.AutoEquipPet = false
	CONFIG.AutoUpgradeShop = false
	CONFIG.AutoUpgradeBoost = false
	CONFIG.AutoUpgradeLadder = false
	CONFIG.AutoUpgradeWins = false
	CONFIG.AutoUpgradeLuck = false
end)
