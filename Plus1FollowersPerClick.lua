local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local CONFIG = {
	AutoBattleTap = false,
	AutoWins = false,
	AutoTrain = false,
	AutoRebirth = false,
	AutoUpgradeAll = false,
	AutoRollTitle = false,
}

-- Train Positions by World & Rebirth
local TrainPositions = {
	[1] = {
		[0] = Vector3.new(1622, 20, 2888),
		[1] = Vector3.new(1622, 20, 2913),
		[2] = Vector3.new(1622, 20, 2937),
		[8] = Vector3.new(1648, 22, 2922),
	},
	[2] = {
		[6] = Vector3.new(3913, 20, 2871),
		[8] = Vector3.new(3913, 20, 2895),
		[10] = Vector3.new(3913, 20, 2920),
		[12] = Vector3.new(3913, 20, 2943),
		[15] = Vector3.new(3913, 20, 2967),
		[18] = Vector3.new(3913, 20, 2991),
	},
	[3] = {
		[12] = Vector3.new(6372, 20, 2871),
		[15] = Vector3.new(6372, 29, 2895),
		[18] = Vector3.new(6372, 20, 2920),
		[20] = Vector3.new(6372, 20, 2943),
		[23] = Vector3.new(6372, 20, 2967),
		[26] = Vector3.new(6372, 20, 2991),
	},
}

-- Function to get the correct WinPart based on World attribute
local function GetWinPart()
	if not LocalPlayer then return nil end
	
	local currentWorld = LocalPlayer:GetAttributes().World or 1
	local winParts = {
		[1] = workspace.Worlds.World1.Map.Win.Lane21.WinPart,
		[2] = workspace.Worlds.World2.Map.Win.Lane21.WinPart,
		[3] = workspace.Worlds.World3.Map.Win.Lane20.WinPart,
	}
	
	return winParts[currentWorld]
end

-- Function to get closest train position based on World & Rebirth
local function GetClosestTrainPosition()
	local success, result = pcall(function()
		if not LocalPlayer then return nil end
		
		-- Get current world from attributes
		local currentWorld = LocalPlayer:GetAttributes().World
		if not currentWorld or currentWorld == 0 then
			currentWorld = 1
		end
		
		-- Get current rebirth from nRebirth
		local currentRebirths = 0
		if LocalPlayer:FindFirstChild("nRebirth") then
			currentRebirths = LocalPlayer.nRebirth.Value
		end
		
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
	end)
	
	if success then
		return result
	end
	return nil
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
-- AUTO FARMING
--==================================================

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoBattleTap", {
	Text = "Auto Battle Tap",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBattleTap = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBattleTap do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.Events.BattleTap
						Event:FireServer()
					end)
					task.wait(0.0000000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoWins", {
	Text = "Auto Wins",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoWins = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoWins do
					pcall(function()
						local winPart = GetWinPart()
						if winPart then
							local currentChar = LocalPlayer.Character
							if currentChar and currentChar:FindFirstChild("HumanoidRootPart") then
								firetouchinterest(winPart, currentChar.HumanoidRootPart, 0)
								task.wait(0.001)
								firetouchinterest(winPart, currentChar.HumanoidRootPart, 1)
							end
						end
					end)
					task.wait(0.00000001)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoTrain = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoTrain do
					pcall(function()
						local currentChar = LocalPlayer.Character
						if not currentChar then
							return
						end
						
						local HRP = currentChar:FindFirstChild("HumanoidRootPart")
						if HRP then
							local trainPos = GetClosestTrainPosition()
							if trainPos then
								-- Teleport to train position
								HRP.CFrame = CFrame.new(trainPos)
								task.wait(0.1)
								
								-- Freeze position
								HRP.Velocity = Vector3.new(0, 0, 0)
								HRP.AssemblyVelocity = Vector3.new(0, 0, 0)
								task.wait(0.1)
								
								-- Fire click event
								pcall(function()
									local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
									if remotes then
										local events = remotes:FindFirstChild("Events")
										if events then
											local clickRemote = events:FindFirstChild("ClickRemote")
											if clickRemote then
												clickRemote:FireServer()
											end
										end
									end
								end)
							end
						end
					end)
					task.wait(0.000000001)
				end
			end)
		else
			-- Unfreeze when toggled off
			pcall(function()
				local currentChar = LocalPlayer.Character
				if currentChar then
					local HRP = currentChar:FindFirstChild("HumanoidRootPart")
					if HRP then
						HRP.AssemblyVelocity = Vector3.new(0, 0, 0)
					end
				end
			end)
		end
	end,
})

--==================================================
-- AUTO UPGRADES
--==================================================

local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoRebirth = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRebirth do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.Events.RebirthRemote
						Event:FireServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoUpgradeAll", {
	Text = "Auto Upgrade",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoUpgradeAll = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoUpgradeAll do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.Events.BuyUpgrade
						Event:FireServer("Aura Luck", "Win")
						Event:FireServer("Walk Speed", "Win")
						Event:FireServer("Title Luck", "Win")
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

UpgradeGroup:AddToggle("AutoRollTitle", {
	Text = "Auto Roll Title",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoRollTitle = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoRollTitle do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remotes.Events.TitleRoll
						Event:FireServer("Normal")
					end)
					task.wait(0.0000000001)
				end
			end)
		end
	end,
})

--==================================================
-- SCRIPT INFO
--==================================================

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Followers Per Click")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/14/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

--==================================================
-- FEATURES
--==================================================

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Battle Tap")
FeaturesGroup:AddLabel("✓ Auto Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Upgrade")
FeaturesGroup:AddLabel("✓ Auto Roll Title")

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
SaveManager:SetFolder("AntiGodHub/FollowersPerClick")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

--==================================================
-- RESET ON CHARACTER DEATH
--==================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	CONFIG.AutoBattleTap = false
	CONFIG.AutoWins = false
	CONFIG.AutoTrain = false
	CONFIG.AutoRebirth = false
	CONFIG.AutoUpgradeAll = false
	CONFIG.AutoRollTitle = false
end)
