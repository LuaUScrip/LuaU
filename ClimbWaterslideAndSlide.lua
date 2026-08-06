local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local CONFIG = {
	LOOP_SPEED = 0.02,
	START_POS = Vector3.new(12.300000190735, 0.89713048934937, -2.6058521270752),
	END_POS = Vector3.new(12.300000190735, 5001.6743164062, -8659.013671875),
	COIN_REWARD = 1644444,
	InfWinsCoins = false,
	InfWinsTrophy = false,
	AutoBuyRaft = false,
	AutoBuyTrail = false,
}

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

FarmingGroup:AddToggle("InfWinsCoins", {
	Text = "Auto Farm Coins",
	Default = false,
	Callback = function(Value)
		CONFIG.InfWinsCoins = Value
		if Value then
			task.spawn(function()
				while CONFIG.InfWinsCoins do
					local Event = game:GetService("ReplicatedStorage").Remote.Race
					pcall(function()
						Event:FireServer("RaceStartClimb", CONFIG.START_POS)
					end)
					task.wait(CONFIG.LOOP_SPEED)
					pcall(function()
						Event:FireServer("RaceEndClimb", CONFIG.END_POS)
					end)
					task.wait(CONFIG.LOOP_SPEED)
					pcall(function()
						Event:FireServer("RaceClaimCoins", CONFIG.COIN_REWARD)
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("InfWinsTrophy", {
	Text = "Auto Farm Wins",
	Default = false,
	Callback = function(Value)
		CONFIG.InfWinsTrophy = Value
		if Value then
			task.spawn(function()
				while CONFIG.InfWinsTrophy do
					local Event = game:GetService("ReplicatedStorage").Remote.Race
					pcall(function()
						Event:FireServer("RaceStartClimb", CONFIG.START_POS)
					end)
					task.wait(CONFIG.LOOP_SPEED)
					pcall(function()
						Event:FireServer("RaceEndClimb", CONFIG.END_POS)
					end)
					task.wait(CONFIG.LOOP_SPEED)
					pcall(function()
						Event:FireServer("ToTop")
					end)
					task.wait(CONFIG.LOOP_SPEED)
					pcall(function()
						Event:FireServer("RaceClaimTrophy")
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyRaft", {
	Text = "Auto Buy Raft",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBuyRaft = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyRaft do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remote.RaftF
						for i = 1, 200 do
							Event:InvokeServer("BuyRaft", i)
							task.wait(0.05)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyTrail do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Remote.TrailF
						for i = 1, 200 do
							Event:InvokeServer("BuyTrail", i)
							task.wait(0.05)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

--==================================================
-- SCRIPT INFO
--==================================================

local InfoGroup = Tabs.Main:AddRightGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Climb Waterslide And Slide")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

--==================================================
-- FEATURES
--==================================================

local FeaturesGroup = Tabs.Main:AddLeftGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Inf Wins (Coins)")
FeaturesGroup:AddLabel("✓ Inf Wins (Trophy)")
FeaturesGroup:AddLabel("✓ Auto Buy Raft")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")

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
SaveManager:SetFolder("AntiGodHub/ClimbWaterslide")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

--==================================================
-- RESET ON CHARACTER DEATH
--==================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
	Character = newChar
	CONFIG.InfWinsCoins = false
	CONFIG.InfWinsTrophy = false
	CONFIG.AutoBuyRaft = false
	CONFIG.AutoBuyTrail = false
end)
