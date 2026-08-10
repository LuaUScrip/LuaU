-- Brainrot | Obsidian UI (Clean)
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
	AutoFarmBrainrots = false,
	AutoTrain = false,
	AutoSellAll = false,
	AutoRebirth = false,
	AutoBuyEquipWeb = false,
	AutoBuyWebSkin = false,
}

-- Web List
local WebList = {
	"SandBag",
	"Rock",
	"Boulder",
	"Car",
	"Train",
	"Ship",
	"Skyscraper",
	"Moon",
	"Earth",
	"Neptune",
	"Saturn",
	"Sun",
	"Black Hole"
}

-- Web Skin List
local WebSkinList = {
	"Electric",
	"Aquatic",
	"Crimson",
	"Ice Fire",
	"Galaxy",
	"Abyss",
	"Congueror",
	"Loki",
	"Venom",
	"Kings Crown"
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

FarmingGroup:AddToggle("AutoFarmBrainrots", {
	Text = "Auto Farm Brainrots",
	Default = false,
	Tooltip = "Automatically farm brainrots",
	Callback = function(Value)
		CONFIG.AutoFarmBrainrots = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoFarmBrainrots do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("WebSwingRoll")
						if Event then
							Event:InvokeServer(math.huge)
						end
						
						local Event2 = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("WebSwingRollFinish")
						if Event2 then
							Event2:FireServer()
						end
					end)
					task.wait(0.001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically train with TrainingTool",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						if player.Backpack:FindFirstChild("TrainingTool") then
							player.Backpack.TrainingTool.Parent = player.Character
						end
						
						local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("TrainingOrbHit")
						if Event then
							Event:FireServer()
						end
					end)
					task.wait(0.01)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoSellAll", {
	Text = "Auto Sell All",
	Default = false,
	Tooltip = "Automatically sell all brainrots",
	Callback = function(Value)
		CONFIG.AutoSellAll = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSellAll do
					pcall(function()
						local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("SellRemote")
						if Event then
							Event:InvokeServer("SellAll")
						end
					end)
					task.wait(0.5)
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
						local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("Rebirth")
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

-- Main Tab - Right Side (Upgrades)
local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoBuyEquipWeb", {
	Text = "Auto Buy & Equip Web",
	Default = false,
	Tooltip = "Automatically buy and equip all webs",
	Callback = function(Value)
		CONFIG.AutoBuyEquipWeb = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEquipWeb do
					pcall(function()
						for _, web in ipairs(WebList) do
							local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("TrainingToolAction")
							if Event then
								Event:InvokeServer("Buy", web)
								task.wait(0.2)
								Event:InvokeServer("Equip", web)
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

UpgradeGroup:AddToggle("AutoBuyWebSkin", {
	Text = "Auto Buy Web Skin",
	Default = false,
	Tooltip = "Automatically buy all web skins",
	Callback = function(Value)
		CONFIG.AutoBuyWebSkin = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyWebSkin do
					pcall(function()
						for _, skin in ipairs(WebSkinList) do
							local Event = ReplicatedStorage:FindFirstChild("Utilities"):FindFirstChild("TypedRemote"):FindFirstChild("UnlockWebSkin")
							if Event then
								Event:InvokeServer(skin)
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

InfoGroup:AddLabel("Game Name : Web Swing For Lucky Blocks")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/10/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Brainrots")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Sell All")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy & Equip Web")
FeaturesGroup:AddLabel("✓ Auto Buy Web Skin")

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
SaveManager:SetFolder("AntiGodHub/Brainrot")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")