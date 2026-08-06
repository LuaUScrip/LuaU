-- Fishing Chef | Obsidian UI (Clean)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- Wait for remotes
local Fish = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("Fish")
local RF = Fish:WaitForChild("RF")
local RE = Fish:WaitForChild("RE")

local SellFishRemote = RE:WaitForChild("SellFish")
local DepositAllRemote = game:GetService("ReplicatedStorage").Packages.Knit.Services.FishStorage.RE.DepositAll
local BuyRodRemote = game:GetService("ReplicatedStorage").Packages.Knit.Services.PurchaseController.RF.BuyRod
local BuyKnifeRemote = game:GetService("ReplicatedStorage").Packages.Knit.Services.PurchaseController.RF.BuyKnife

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- Configuration
local CONFIG = {
	AutoFish = false,
	AutoSell = false,
	AutoDeposit = false,
}

local autoFish = false
local fishThread = nil
local autoSell = false
local sellThread = nil
local autoDeposit = false
local depositThread = nil

-- Thread functions
local function startFishLoop()
	fishThread = task.spawn(function()
		while autoFish do
			pcall(function() RF.CastRequest:InvokeServer(99999999999) end)
			task.wait(3)
			pcall(function() RF.MinigameResolved:InvokeServer(true) end)
			task.wait(1)
		end
	end)
end

local function startSellLoop()
	sellThread = task.spawn(function()
		while autoSell do
			for id = 1, 1000 do
				if not autoSell then break end
				pcall(function()
					SellFishRemote:FireServer({{ ID = id, Name = "fish", Weight = 9999999999 }})
				end)
				task.wait(0.002)
			end
		end
	end)
end

local function startDepositLoop()
	depositThread = task.spawn(function()
		while autoDeposit do
			pcall(function()
				DepositAllRemote:FireServer()
			end)
			task.wait(0.5)
		end
	end)
end

local function getAllRods()
	local rods = {
		"Spirit Cat Rod",
		"Glacier Rod",
		"Kitsune Rod",
		"Sea Dragon Rod",
		"Admin Rod",
		"Leviathan Spine Rod",
		"Moontuna Rod",
		"Dragon Rod",
		"Godzilla Rod",
	}
	
	for _, rod in ipairs(rods) do
		pcall(function()
			BuyRodRemote:InvokeServer(rod)
		end)
	end
end

local function getAllKnives()
	local knives = {
		"Kitsune Knife",
		"Tiger Cleaver",
		"Fire Dragon Knife",
		"Yin Yang Knife"
	}
	
	for _, knife in ipairs(knives) do
		pcall(function()
			BuyKnifeRemote:InvokeServer(knife)
		end)
	end
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

-- Main Tab - Left Side (Farming)
local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farming", "cpu")

FarmingGroup:AddToggle("AutoFish", {
	Text = "Auto Fish",
	Default = false,
	Tooltip = "Automatically fish",
	Callback = function(Value)
		autoFish = Value
		CONFIG.AutoFish = Value
		if Value then
			startFishLoop()
		else
			if fishThread then task.cancel(fishThread); fishThread = nil end
		end
	end,
})

FarmingGroup:AddToggle("AutoSell", {
	Text = "Auto Sell",
	Default = false,
	Tooltip = "Automatically sell fish",
	Callback = function(Value)
		autoSell = Value
		CONFIG.AutoSell = Value
		if Value then
			startSellLoop()
		else
			if sellThread then task.cancel(sellThread); sellThread = nil end
		end
	end,
})

FarmingGroup:AddToggle("AutoDeposit", {
	Text = "Auto Deposit Fish Stock",
	Default = false,
	Tooltip = "Automatically deposit fish stock",
	Callback = function(Value)
		autoDeposit = Value
		CONFIG.AutoDeposit = Value
		if Value then
			startDepositLoop()
		else
			if depositThread then task.cancel(depositThread); depositThread = nil end
		end
	end,
})

-- Main Tab - Right Side (Owner Features)
local OwnerGroup = Tabs.Main:AddRightGroupbox("Owner Features", "crown")

OwnerGroup:AddButton({
	Text = "Get All Rod",
	Func = function()
		getAllRods()
	end,
	Tooltip = "Purchase all best rods",
})

OwnerGroup:AddButton({
	Text = "Get All Knife",
	Func = function()
		getAllKnives()
	end,
	Tooltip = "Purchase all best knives",
})

OwnerGroup:AddDivider()

-- Custom Title Features
local titleFolder = Workspace:FindFirstChild(LocalPlayer.Name)
local titleModule = titleFolder and titleFolder:FindFirstChild("Title") or nil

if titleModule then
	local levelLoopConnection
	local nameLoopConnection
	local titleLoopConnection
	local rainbowLoopConnection

	OwnerGroup:AddInput("CustomLevel", {
		Default = "",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Text = "Custom Level",
		Placeholder = "Enter level...",
		Callback = function(Value)
			if Value == "" then
				if levelLoopConnection then
					levelLoopConnection:Disconnect()
					levelLoopConnection = nil
				end
				return
			end
			
			if levelLoopConnection then
				levelLoopConnection:Disconnect()
			end
			
			levelLoopConnection = RunService.Heartbeat:Connect(function()
				local levelElement = titleModule:FindFirstChild("PlayerLevel")
				if levelElement then
					levelElement.Text = Value
				end
			end)
		end,
	})

	OwnerGroup:AddInput("CustomName", {
		Default = "",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Text = "Custom Name",
		Placeholder = "Enter name...",
		Callback = function(Value)
			if Value == "" then
				if nameLoopConnection then
					nameLoopConnection:Disconnect()
					nameLoopConnection = nil
				end
				return
			end
			
			if nameLoopConnection then
				nameLoopConnection:Disconnect()
			end
			
			nameLoopConnection = RunService.Heartbeat:Connect(function()
				local nameElement = titleModule:FindFirstChild("PlayerName")
				if nameElement then
					nameElement.Text = Value
				end
			end)
		end,
	})

	OwnerGroup:AddInput("CustomTitle", {
		Default = "",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = true,
		Text = "Custom Title",
		Placeholder = "Enter title...",
		Callback = function(Value)
			if Value == "" then
				if titleLoopConnection then
					titleLoopConnection:Disconnect()
					titleLoopConnection = nil
				end
				return
			end
			
			if titleLoopConnection then
				titleLoopConnection:Disconnect()
			end
			
			titleLoopConnection = RunService.Heartbeat:Connect(function()
				local titleElement = titleModule:FindFirstChild("TitleName")
				if titleElement then
					titleElement.Text = Value
				end
			end)
		end,
	})

	local rainbowColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 127, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(148, 0, 211),
	}

	local rainbowSpeed = 0.02
	local rainbowProgress = 0

	OwnerGroup:AddToggle("RainbowTitle", {
		Text = "Rainbow Title",
		Default = false,
		Tooltip = "Enable rainbow effect on title",
		Callback = function(Value)
			if Value then
				if rainbowLoopConnection then
					rainbowLoopConnection:Disconnect()
				end
				
				rainbowProgress = 0
				rainbowLoopConnection = RunService.Heartbeat:Connect(function()
					local titleElement = titleModule:FindFirstChild("TitleName")
					if titleElement then
						rainbowProgress = (rainbowProgress + rainbowSpeed) % 7
						
						local colorIndex = math.floor(rainbowProgress) + 1
						local nextColorIndex = (colorIndex % 7) + 1
						local lerp = rainbowProgress - math.floor(rainbowProgress)
						
						local currentColor = rainbowColors[colorIndex]
						local nextColor = rainbowColors[nextColorIndex]
						
						local lerpedColor = Color3.new(
							currentColor.R + (nextColor.R - currentColor.R) * lerp,
							currentColor.G + (nextColor.G - currentColor.G) * lerp,
							currentColor.B + (nextColor.B - currentColor.B) * lerp
						)
						
						titleElement.TextColor3 = lerpedColor
					end
				end)
			else
				if rainbowLoopConnection then
					rainbowLoopConnection:Disconnect()
					rainbowLoopConnection = nil
				end
				local titleElement = titleModule:FindFirstChild("TitleName")
				if titleElement then
					titleElement.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	})

	LocalPlayer.CharacterRemoving:Connect(function()
		if levelLoopConnection then levelLoopConnection:Disconnect() end
		if nameLoopConnection then nameLoopConnection:Disconnect() end
		if titleLoopConnection then titleLoopConnection:Disconnect() end
		if rainbowLoopConnection then rainbowLoopConnection:Disconnect() end
		if fishThread then task.cancel(fishThread) end
		if sellThread then task.cancel(sellThread) end
		if depositThread then task.cancel(depositThread) end
	end)
end

-- Main Tab - Script Info (Left Bottom)
local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Fishing Chef")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/7/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub", true)

-- Main Tab - Features (Right Bottom)
local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Fish")
FeaturesGroup:AddLabel("✓ Auto Sell")
FeaturesGroup:AddLabel("✓ Auto Deposit")
FeaturesGroup:AddLabel("✓ Get All Rods")
FeaturesGroup:AddLabel("✓ Get All Knives")
FeaturesGroup:AddLabel("✓ Custom Level")
FeaturesGroup:AddLabel("✓ Custom Name")
FeaturesGroup:AddLabel("✓ Custom Title")
FeaturesGroup:AddLabel("✓ Rainbow Title")

-- Player Tab - Player Information
local PlayerInfoGroup = Tabs.Player:AddLeftGroupbox("Player Information", "user")

PlayerInfoGroup:AddLabel("Username : " .. LocalPlayer.Name)
PlayerInfoGroup:AddLabel("User ID : " .. LocalPlayer.UserId)
PlayerInfoGroup:AddLabel("Premium : " .. (LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Yes Premium" or "No Premium"))

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
SaveManager:SetFolder("AntiGodHub/FishingChef")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

task.wait(0.1)
ThemeManager:ApplyTheme("DarkWhite")
