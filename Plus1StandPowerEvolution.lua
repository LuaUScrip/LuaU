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
	AutoBuyLuckyBlock = false,
	AutoBuyStand = false,
	AutoBuyTrail = false,
	AutoBuyAura = false,
}

local LISTS = {
	Stands = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25},
	Trails = {"Yellow", "Blue", "Green", "Purple", "Red"},
	Auras = {"Fire", "Money", "Ice", "Water", "Light", "Cyberpunk", "Angel", "Binary", "Flame Crown"},
}

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

-- Auto Farm Wins - Teleport and freeze with AssemblyLinearVelocity
task.spawn(function()
	while task.wait(1) do
		if CONFIG.AutoFarmWins then
			pcall(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local targetCFrame = CFrame.new(3668.61865, 112.892197 + 3, -1246.05859) * CFrame.Angles(0, 0, 1)
					LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
					LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				end
			end)
		end
	end
end)

-- Auto Train - Claim Power Gain
task.spawn(function()
	while task.wait(0.00000001) do
		if CONFIG.AutoTrain then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.ClaimPowerGain
				Event:FireServer()
			end)
		end
	end
end)

-- Auto Rebirth
task.spawn(function()
	while task.wait(0.5) do
		if CONFIG.AutoRebirth then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.Rebirth
				Event:InvokeServer()
			end)
		end
	end
end)

-- Auto Buy Best Lucky Blocks
task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoBuyLuckyBlock then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.BuyLuckyBlockWithWins
				Event:FireServer("Ancient", 6)
			end)
		end
	end
end)

-- Auto Buy Stand - Buy all in list
task.spawn(function()
	while task.wait(0.2) do
		if CONFIG.AutoBuyStand then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.PurchaseStand
				for _, standId in ipairs(LISTS.Stands) do
					Event:InvokeServer(standId)
					task.wait(0.05)
				end
			end)
		end
	end
end)

-- Auto Buy Trail - Buy all in list
task.spawn(function()
	while task.wait(0.2) do
		if CONFIG.AutoBuyTrail then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.PurchaseTrail
				for _, trail in ipairs(LISTS.Trails) do
					Event:InvokeServer(trail)
					task.wait(0.05)
				end
			end)
		end
	end
end)

-- Auto Buy Aura - Buy all in list
task.spawn(function()
	while task.wait(0.2) do
		if CONFIG.AutoBuyAura then
			pcall(function()
				local Event = ReplicatedStorage.RemotesFolder.PurchaseAura
				for _, aura in ipairs(LISTS.Auras) do
					Event:InvokeServer(aura)
					task.wait(0.05)
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

Window:SetCornerRadius(20)

local Tabs = {
	Main = Window:AddTab("Main", "star"),
	Player = Window:AddTab("Player", "user"),
	Settings = Window:AddTab("UI Settings", "settings"),
}

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFarmWins", {
	Text = "Auto Farm Wins",
	Default = false,
	Tooltip = "Automatically farm wins",
	Callback = function(Value)
		CONFIG.AutoFarmWins = Value
	end,
})

FarmingGroup:AddToggle("AutoTrain", {
	Text = "Auto Train",
	Default = false,
	Tooltip = "Automatically claim power gains",
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

local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Purchases", "star")

UpgradeGroup:AddToggle("AutoBuyLuckyBlock", {
	Text = "Auto Buy Lucky Block",
	Default = false,
	Tooltip = "Automatically buy Ancient Lucky Blocks",
	Callback = function(Value)
		CONFIG.AutoBuyLuckyBlock = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyStand", {
	Text = "Auto Buy Stand",
	Default = false,
	Tooltip = "Automatically buy all stands (2-25)",
	Callback = function(Value)
		CONFIG.AutoBuyStand = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyTrail", {
	Text = "Auto Buy Trail",
	Default = false,
	Tooltip = "Automatically buy all trails",
	Callback = function(Value)
		CONFIG.AutoBuyTrail = Value
	end,
})

UpgradeGroup:AddToggle("AutoBuyAura", {
	Text = "Auto Buy Aura",
	Default = false,
	Tooltip = "Automatically buy all auras",
	Callback = function(Value)
		CONFIG.AutoBuyAura = Value
	end,
})

UpgradeGroup:AddDivider()

UpgradeGroup:AddButton({
	Text = "Teleport To King Of Hill",
	Func = function()
		pcall(function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3621, 130, 91)
				
				-- Create anchor locked part below character (invisible)
				local part = Instance.new("Part")
				part.Shape = Enum.PartType.Block
				part.Size = Vector3.new(10, 1, 10)
				part.CanCollide = false
				part.CFrame = CFrame.new(3621, 125, 91)
				part.Anchored = true
				part.Visible = false
				part.Name = "FarmPlatform"
				part.Parent = Workspace
			end
		end)
	end,
	Tooltip = "Teleport to King of Hill area",
})

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : +1 Stand Power Evolution")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/14/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Farm Wins")
FeaturesGroup:AddLabel("✓ Auto Train")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Buy Lucky Block")
FeaturesGroup:AddLabel("✓ Auto Buy Stand")
FeaturesGroup:AddLabel("✓ Auto Buy Trail")
FeaturesGroup:AddLabel("✓ Auto Buy Aura")
FeaturesGroup:AddLabel("✓ Anti-AFK")

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

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu Keybind"
})

local UtilityGroup = Tabs.Settings:AddRightGroupbox("Utility", "tools")

UtilityGroup:AddButton({
	Text = "Fix Camera",
	Func = function()
		pcall(function()
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
				local camera = Workspace.CurrentCamera
				camera.CFrame = LocalPlayer.Character.Head.CFrame + LocalPlayer.Character.Head.CFrame.LookVector * 5
				camera.Focus = LocalPlayer.Character.Head.CFrame
			end
		end)
	end,
	Tooltip = "Restore and fix camera position"
})

UtilityGroup:AddButton({
	Text = "Force Respawn",
	Func = function()
		pcall(function()
			if LocalPlayer.Character then
				local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.Health = 0
				end
			end
		end)
	end,
	Tooltip = "Force reset and respawn character"
})

UtilityGroup:AddDivider()

UtilityGroup:AddButton({
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
SaveManager:SetFolder("AntiGodHub/StandsOnline")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")