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
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

LocalPlayer.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	task.wait(0.1)
	VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

local CONFIG = {
	AutoCoin = false,
	AutoUpgrade = false,
	AutoSellAll = false,
	AutoBuyCoin = false,
	VIP = false,
	BOOST = false,
	FastThrow = false,
}

local FIXED_POSITION = Vector3.new(-1162.8552246094, 0.72600001096725, 73.239318847656)
local coinLandedCount = 0
local selectedCoin = "Basic Coin"

local CoinList = {
	"Basic Coin", "Copper Coin", "Fortune Coin", "Fire Coin", "Volt Coin",
	"Aether Coin", "Starlight Coin", "Galaxy Coin", "Void Coin", "Chronos Coin",
	"Eclipse Coin", "Mirage Coin", "Obsidia Coin", "Tempest Coin", "Soul Coin",
	"Paradox Coin", "Miracle Coin", "Nexus Coin", "Apex Coin", "Infinity Coin",
	"Grace Coin", "Dominion Coin", "Empyrean Coin", "Atlas Coin", "Judgement Coin",
	"Hercules Coin", "Helios Coin", "Nyx Coin", "Titan Coin", "Zeus Coin", "Runic Coin", "Amethyst Coin", "Merlin Coin", "Eldritch Coin", "Avalon Coin", "Dragonheart Coin", "Phoenix Coin",
}

local function GetJobID()
	return game.JobId
end

local function GetPlayerCount()
	return #Players:GetPlayers()
end

local function GetPremiumStatus()
	if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
		return "Yes Premium"
	else
		return "No Premium"
	end
end

local function ServerHop()
	local PlaceId = game.PlaceId
	local JobId = game.JobId
	local ApiUrl = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/0?sortOrder=Asc&limit=100"
	
	local success, result = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(ApiUrl))
	end)
	
	if not success or not result or not result.data then
		warn("Failed to fetch server list. Retrying...")
		return false
	end
	
	for _, server in ipairs(result.data) do
		if server.id ~= JobId and tonumber(server.playing) < tonumber(server.maxPlayers) then
			local teleportSuccess, errorMsg = pcall(function()
				TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
			end)
			
			if teleportSuccess then
				return true
			else
				warn("Teleport failed: " .. tostring(errorMsg))
			end
		end
	end
	
	warn("No available servers found to hop to.")
	return false
end

local function Rejoin()
	task.wait(0.5)
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

local function SetPlayerAttribute(attribute, value)
	pcall(function()
		LocalPlayer:SetAttribute(attribute, value)
	end)
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
	Settings = Window:AddTab("UI Settings", "settings"),
}

local FarmingGroup = Tabs.Main:AddLeftGroupbox("Auto Farm", "cpu")

FarmingGroup:AddDropdown("CoinSelect", {
	Values = CoinList,
	Default = 1,
	Text = "Select Coin",
	Tooltip = "Choose which coin to throw",
	Searchable = true,
	Callback = function(Value)
		selectedCoin = Value
	end,
})

FarmingGroup:AddToggle("AutoCoin", {
	Text = "Auto Coin",
	Default = false,
	Tooltip = "Automatically throws coins",
	Callback = function(Value)
		CONFIG.AutoCoin = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoCoin do
					pcall(function()
						task.wait()
						local LandedEvent = game:GetService("ReplicatedStorage").Assets.Events.CoinLanded
						coinLandedCount = coinLandedCount + 1
						LandedEvent:FireServer(math.huge, FIXED_POSITION, selectedCoin, nil, nil, coinLandedCount)
					end)
					task.wait()
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoBuyCoin", {
	Text = "Auto Buy Coin",
	Default = false,
	Tooltip = "Automatically buys all coins in list",
	Callback = function(Value)
		CONFIG.AutoBuyCoin = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoBuyCoin do
					pcall(function()
						for _, coin in ipairs(CoinList) do
							local Event = game:GetService("ReplicatedStorage").Assets.Events.BuyCoin
							Event:FireServer(coin)
							task.wait(0.1)
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Tooltip = "Automatically upgrades all multipliers",
	Callback = function(Value)
		CONFIG.AutoUpgrade = Value
		if Value then
			task.spawn(function()
				local upgradeList = {"Luck Multiplier", "Value Multiplier", "Throw Speed"}
				while CONFIG.AutoUpgrade do
					pcall(function()
						for _, upgrade in ipairs(upgradeList) do
							local Event = game:GetService("ReplicatedStorage").Assets.Events.RequestUpgrade
							Event:FireServer(upgrade)
							task.wait(0.01)
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

FarmingGroup:AddToggle("AutoSellAll", {
	Text = "Auto Sell All",
	Default = false,
	Tooltip = "Automatically sells all coins",
	Callback = function(Value)
		CONFIG.AutoSellAll = Value
		if Value then
			task.spawn(function()
				while CONFIG.AutoSellAll do
					pcall(function()
						local Event = game:GetService("ReplicatedStorage").Assets.Events.SellAll
						Event:FireServer()
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

local BetaFeaturesGroup = Tabs.Main:AddRightGroupbox("BETA FEATURES", "zap")

BetaFeaturesGroup:AddToggle("FastThrow", {
	Text = "Fast Throw [Manual]",
	Default = false,
	Tooltip = "Super Fast Throw",
	Callback = function(Value)
		CONFIG.FastThrow = Value
		if Value then
			SetPlayerAttribute("ThrowSpeedLevel", 999)
		else
			SetPlayerAttribute("ThrowSpeedLevel", 0)
		end
	end,
})

BetaFeaturesGroup:AddToggle("VIP", {
	Text = "VIP",
	Default = false,
	Tooltip = "Enable VIP attribute",
	Callback = function(Value)
		CONFIG.VIP = Value
		SetPlayerAttribute("VIP", Value)
	end,
})

BetaFeaturesGroup:AddToggle("BOOST", {
	Text = "BOOST",
	Default = false,
	Tooltip = "Enable all beta boost features",
	Callback = function(Value)
		CONFIG.BOOST = Value
		SetPlayerAttribute("MoreLuck", Value)
		SetPlayerAttribute("IsMod", Value)
		SetPlayerAttribute("IsAdmin", Value)
		SetPlayerAttribute("InsaneLuck", Value)
		SetPlayerAttribute("DynamicCoinOwned", Value)
		SetPlayerAttribute("DragonBooth", Value)
		SetPlayerAttribute("BetterPlacement", Value)
		SetPlayerAttribute("CC", Value)
		SetPlayerAttribute("DoubleCash", Value)
	end,
})

local ServerGroup = Tabs.Main:AddRightGroupbox("Server Info", "server")

local JobIDLabel = ServerGroup:AddLabel("Job ID: " .. GetJobID())
local PlayerCountLabel = ServerGroup:AddLabel("Players: " .. GetPlayerCount() .. "/20")

task.spawn(function()
	while task.wait(1) do
		if Library.Unloaded then break end
		JobIDLabel:SetText("Job ID: " .. GetJobID())
		PlayerCountLabel:SetText("Players: " .. GetPlayerCount() .. "/20")
	end
end)

ServerGroup:AddDivider()

ServerGroup:AddButton({
	Text = "ServerHop",
	Func = function()
		ServerHop()
	end,
	Tooltip = "Teleport to another server",
})

ServerGroup:AddButton({
	Text = "Rejoin Server",
	Func = function()
		Rejoin()
	end,
	Tooltip = "Rejoin the current server",
})

ServerGroup:AddButton({
	Text = "Copy Job ID",
	Func = function()
		setclipboard(GetJobID())
	end,
	Tooltip = "Copy current Job ID to clipboard",
})

local InfoGroup = Tabs.Main:AddLeftGroupbox("Script Info", "book")

InfoGroup:AddLabel("Game Name : Throw A Coin")
InfoGroup:AddLabel("Developer : LuaU")
InfoGroup:AddLabel("Last Updated : 8/9/2026")
InfoGroup:AddDivider()
InfoGroup:AddLabel("YouTube : AntiGodHub")

local FeaturesGroup = Tabs.Main:AddRightGroupbox("Features", "star")

FeaturesGroup:AddLabel("✓ Auto Coin Throw")
FeaturesGroup:AddLabel("✓ Auto Buy Coin")
FeaturesGroup:AddLabel("✓ Auto Upgrade All")
FeaturesGroup:AddLabel("✓ Auto Sell All")
FeaturesGroup:AddLabel("✓ Server Hopping")
FeaturesGroup:AddLabel("✓ Anti AFK")
FeaturesGroup:AddLabel("✓ Beta Features")

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
SaveManager:SetFolder("AntiGodHub/ThrowACoin")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
