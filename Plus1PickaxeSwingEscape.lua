-- +1 Pickaxe Swing Escape | Obsidian UI (Clean) - FIXED
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

-- Check LocalPlayer
local player = Players:WaitForChild("LocalPlayer", 5) or Players.LocalPlayer
if not player then
	warn("LocalPlayer not found!")
	return
end

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
	AutoBuyTrail = false,
	AutoRebirth = false,
	AutoTrain = false,
	AutoSpinAura = false,
	AutoBuyEgg = false,
	AutoSpinWheel = false,
}

local TrailList = {"Orange", "Green", "Blue", "Purple", "White", "Black", "Rainbow", "Lava", "Inferno"}

-- Auto Wins CFrame Positions (World 1-4)
local WinsPositions = {
	[1] = CFrame.new(1207.4928, 2.3514998, 162.360077, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	[2] = CFrame.new(1471.84619, 2.32284594, 489.527283, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	[3] = CFrame.new(1769.15625, 2.32284594, 847.527283, 0, 0, -1, 0, 1, 0, 1, 0, 0),
	[4] = CFrame.new(1769.20007, 5.47183275, 1221.01465, 0, 0, -1, 0, 1, 0, 1, 0, 0),
}

-- Auto Train Positions by World & Rebirths
local TrainPositions = {
	[1] = {
		[0] = Vector3.new(-55, 6, 237),
		[1] = Vector3.new(-55, 6, 227),
		[3] = Vector3.new(-55, 6, 213),
	},
	[2] = {
		[3] = Vector3.new(-55, 6, 565),
		[5] = Vector3.new(-55, 6, 555),
		[7] = Vector3.new(-55, 6, 540),
	},
	[3] = {
		[7] = Vector3.new(-55, 6, 922),
		[12] = Vector3.new(-55, 6, 910),
		[18] = Vector3.new(-55, 6, 897),
	},
	[4] = {
		[12] = Vector3.new(-55, 6, 1295),
		[16] = Vector3.new(-55, 6, 1284),
		[22] = Vector3.new(-55, 6, 1271),
	},
}

-- Function to get closest train position based on CurrentWorld & Rebirths
local function GetClosestTrainPosition()
	if not player then return nil end
	
	local currentWorld = player:GetAttributes().CurrentWorld or 1
	local currentRebirths = player:GetAttributes().Rebirths or 0
	
	if not TrainPositions[currentWorld] then
		return nil
	end
	
	local worldPositions = TrainPositions[currentWorld]
	local closestRebirth = nil
	local closestPos = nil
	local highestRebirth = nil
	local highestPos = nil
	
	-- Find closest rebirth tier <= current rebirths AND track highest tier available
	for rebirth, pos in pairs(worldPositions) do
		-- Track highest rebirth tier in this world
		if highestRebirth == nil or rebirth > highestRebirth then
			highestRebirth = rebirth
			highestPos = pos
		end
		
		-- Find closest tier to your rebirths
		if rebirth <= currentRebirths then
			if closestRebirth == nil or rebirth > closestRebirth then
				closestRebirth = rebirth
				closestPos = pos
			end
		end
	end
	
	-- If current rebirths exceeds all tiers, use the highest tier in this world
	if closestPos == nil then
		return highestPos
	end
	
	return closestPos
end

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

-- Main Tab - Left Side (Auto Wins)
local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically farm wins based on CurrentWorld attribute",
	Callback = function(Value)
		CONFIG.AutoWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoWins do
					pcall(function()
						local char = player.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local currentWorld = player:GetAttributes().CurrentWorld or 1
							local winsPos = WinsPositions[currentWorld]
							
							if winsPos then
								char.HumanoidRootPart.CFrame = winsPos * CFrame.new(0, 5, 0)
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
	Tooltip = "Auto train in current world at closest rebirth tier",
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local char = player.Character
						if char and char:FindFirstChild("HumanoidRootPart") then
							local trainPos = GetClosestTrainPosition()
							if trainPos then
								char.HumanoidRootPart.CFrame = CFrame.new(trainPos)
							end
						end
					end)
					task.wait(0.05)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyTrail", {
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
						local Event = ReplicatedStorage.Remotes.Rebirth
						Event:InvokeServer()
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoSpinAura", {
	Text = "Auto Spin Aura [OP]",
	Default = false,
	Tooltip = "Spin until MythicPityRolls = 999",
	Callback = function(Value)
		CONFIG.AutoSpinAura = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSpinAura do
					pcall(function()
						local mythicPity = player:GetAttributes().MythicPityRolls or 0
						if mythicPity < 999 then
							local Event = ReplicatedStorage.Remotes.SpinAura
							Event:InvokeServer(false)
						else
							CONFIG.AutoSpinAura = false
						end
					end)
					task.wait(0.00000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyEgg", {
	Text = "Auto Buy Egg [W4]",
	Default = false,
	Tooltip = "Automatically buy Lucky Eggs",
	Callback = function(Value)
		CONFIG.AutoBuyEgg = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyEgg do
					pcall(function()
						local Event = ReplicatedStorage.Remotes.Hatch
						Event:InvokeServer("Lucky Egg", "One")
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoSpinWheel", {
	Text = "Auto Spin Wheel",
	Default = false,
	Tooltip = "Automatically spin wheel",
	Callback = function(Value)
		CONFIG.AutoSpinWheel = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSpinWheel do
					pcall(function()
						local Event = ReplicatedStorage.Remotes.SpinRequest
						Event:InvokeServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

-- Main Tab - Right Side (Script Info & Features)
local InfoGroup = Tabs.Main:AddRightGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Pickaxe Swing Escape")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/9/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Spin Aura")
FeaturesGroup:AddLabel("✓ Auto Buy Egg")
FeaturesGroup:AddLabel("✓ Auto Spin Wheel")
FeaturesGroup:AddLabel("✓ Anti AFK")

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