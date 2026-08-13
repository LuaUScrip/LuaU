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
	AutoFishFast = false,
	AutoTrainFast = false,
	AutoUpgradeAquarium = false,
	AutoRebirth = false,
	AutoCollectCash = false,
	AutoClaimLuckyBlock = false,
	AutoEventFrostWyrm = false,
	TrainCounter = 1,
}

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

-- Auto Fish Fast - All events fire together
task.spawn(function()
	while task.wait(0.1) do
		if CONFIG.AutoFishFast then
			pcall(function()
				local castEvent = ReplicatedStorage["shared/network@globalEvents"].castFishingHook
				castEvent:FireServer({
					direction = Vector3.new(0, 0, 1),
					startPosition = Vector3.new(-798.77557373047, 106.3980178833, -786.09997558594),
					utilizedPowerFraction = math.huge,
					peakBias = 0.30,
					skillCheckStrength = math.huge
				})
				
				local qteEvent = ReplicatedStorage["shared/network@globalEvents"].hookQteTapResult
				qteEvent:FireServer(true)
				
				local landedEvent = ReplicatedStorage["shared/network@globalEvents"].hookLanded
				landedEvent:FireServer(Vector3.new(-798.77557373047, 62.685684204102, 2000.2264404297))
				
				local slapEvent = ReplicatedStorage["shared/network@globalEvents"].analyticsApexSlapSuccess
				slapEvent:FireServer()
				
				local dragEvent = ReplicatedStorage["shared/network@globalEvents"].analyticsApexHoldDragSuccess
				dragEvent:FireServer()
				
				local cameraEvent = ReplicatedStorage["shared/network@globalEvents"].cameraReturnedToPier
				cameraEvent:FireServer()
			end)
		end
	end
end)

-- Auto Train Fast - Single fire
task.spawn(function()
	while task.wait(0.01) do
		if CONFIG.AutoTrainFast then
			pcall(function()
				local Event = ReplicatedStorage["shared/network@globalFunctions"].trainingSkillcheckBonus
				Event:FireServer(CONFIG.TrainCounter)
				CONFIG.TrainCounter = CONFIG.TrainCounter + 1
			end)
		end
	end
end)

-- Auto Upgrade Aquarium - All events fire together
task.spawn(function()
	while task.wait(1) do
		if CONFIG.AutoUpgradeAquarium then
			pcall(function()
				local upgradeEvent = ReplicatedStorage["shared/network@globalFunctions"].upgradeAquarium
				upgradeEvent:FireServer(0)
				
				local confirmEvent = ReplicatedStorage["shared/network@globalFunctions"].confirmAquariumUpgrade
				confirmEvent:FireServer(0)
			end)
		end
	end
end)

-- Auto Rebirth - Single fire
task.spawn(function()
	while task.wait(1) do
		if CONFIG.AutoRebirth then
			pcall(function()
				local Event = ReplicatedStorage["shared/network@globalFunctions"].performRebirth
				Event:FireServer(0)
			end)
		end
	end
end)

-- Auto Collect Cash - Single fire
task.spawn(function()
	while task.wait(1) do
		if CONFIG.AutoCollectCash then
			pcall(function()
				local Event = ReplicatedStorage["shared/network@globalFunctions"].collectPlotMoney
				Event:FireServer(999999, "11196979266")
			end)
		end
	end
end)

-- Auto Claim Lucky Block - Single fire
task.spawn(function()
	while task.wait(1) do
		if CONFIG.AutoClaimLuckyBlock then
			pcall(function()
				local luckyBlock = Workspace:FindFirstChild("LuckyBlock")
				if luckyBlock then
					if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						LocalPlayer.Character.HumanoidRootPart.CFrame = luckyBlock.CFrame + Vector3.new(0, 3, 0)
						
						local proximityPrompt = luckyBlock:FindFirstChildOfClass("ProximityPrompt")
						if proximityPrompt then
							proximityPrompt:InputHoldBegin()
							proximityPrompt:InputHoldEnd()
						end
					end
				end
			end)
		end
	end
end)

-- Auto Event Frost Wyrm - All events fire together
task.spawn(function()
	while task.wait(0.001) do
		if CONFIG.AutoEventFrostWyrm then
			pcall(function()
				local slapEvent = ReplicatedStorage["shared/network@globalEvents"].analyticsApexSlapSuccess
				slapEvent:FireServer()
				
				local dragEvent = ReplicatedStorage["shared/network@globalEvents"].analyticsApexHoldDragSuccess
				dragEvent:FireServer()
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

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFishFast", {
	Text = "Auto Fish Fast",
	Default = false,
	Tooltip = "Automatically fish fast",
	Callback = function(Value)
		CONFIG.AutoFishFast = Value
	end,
})

FarmingGroup:AddToggle("AutoTrainFast", {
	Text = "Auto Train Fast",
	Default = false,
	Tooltip = "Automatically train fast (incremental)",
	Callback = function(Value)
		CONFIG.AutoTrainFast = Value
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

FarmingGroup:AddToggle("AutoCollectCash", {
	Text = "Auto Collect Cash",
	Default = false,
	Tooltip = "Automatically collect cash",
	Callback = function(Value)
		CONFIG.AutoCollectCash = Value
	end,
})

local UpgradeGroup = Tabs.Main:AddRightGroupbox("Auto Upgrades", "star")

UpgradeGroup:AddToggle("AutoUpgradeAquarium", {
	Text = "Auto Upgrade Aquarium",
	Default = false,
	Tooltip = "Automatically upgrade aquarium",
	Callback = function(Value)
		CONFIG.AutoUpgradeAquarium = Value
	end,
})

UpgradeGroup:AddToggle("AutoClaimLuckyBlock", {
	Text = "Auto Claim Lucky Block",
	Default = false,
	Tooltip = "Automatically claim lucky block",
	Callback = function(Value)
		CONFIG.AutoClaimLuckyBlock = Value
	end,
})

UpgradeGroup:AddToggle("AutoEventFrostWyrm", {
	Text = "Auto Event Frost Wyrm",
	Default = false,
	Tooltip = "Automatically farm frost wyrm event",
	Callback = function(Value)
		CONFIG.AutoEventFrostWyrm = Value
	end,
})

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Be A Fish Bait")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/5/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Fish Fast")
FeaturesGroup:AddLabel("✓ Auto Train Fast")
FeaturesGroup:AddLabel("✓ Auto Upgrade Aquarium")
FeaturesGroup:AddLabel("✓ Auto Rebirth")
FeaturesGroup:AddLabel("✓ Auto Collect Cash")
FeaturesGroup:AddLabel("✓ Auto Claim Lucky Block")
FeaturesGroup:AddLabel("✓ Auto Event Frost Wyrm")
FeaturesGroup:AddLabel("✓ Anti-AFK Protection")

local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. GetPremiumStatus())
PlayerInfoGroup:AddLabel("Train Counter : " .. CONFIG.TrainCounter)

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
	Default = 20,
	Min = 20,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(20)
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
SaveManager:SetFolder("AntiGodHub/FishingSimulator")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")