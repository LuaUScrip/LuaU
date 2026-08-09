local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- SUPPORTED GAMES
--==================================================

local SupportedGames = {
	{
		Name = "Throw A Coin",
		PlaceIds = {115681808123944, 72042130041700, 100875131717601, 81335362752013},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ThrowACoin.lua"
	},
	{
		Name = "+1 Loot Evolution",
		PlaceIds = {96033388567901},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LootEvolution.lua"
	},
	{
		Name = "+1 Pickaxe Swing Escape",
		PlaceIds = {82554996468034},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1PickaxeSwingEscape.lua"
	},
	{
		Name = "Spin A Fish",
		PlaceIds = {79776733008346},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/SpinAFish.lua"
	},
	{
		Name = "+1 Katana Evolution",
		PlaceIds = {84757653274750, 97295445262211},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KatanaEvolution.lua"
	},
	{
		Name = "+1 Muscle To Push Boulder",
		PlaceIds = {136107936984073},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleToPushBoulder.lua"
	},
	{
		Name = "Dog Race",
		PlaceIds = {119609933650338},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DogRace.lua"
	},
	{
		Name = "Fishing Chef",
		PlaceIds = {88599461076137},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/FishingChef.lua"
	},
	{
		Name = "+1 Ladder Per Click",
		PlaceIds = {82236511306295},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LadderPerClick.lua"
	},
	{
		Name = "+1 Followers Per Click",
		PlaceIds = {98695134949589},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1FollowersPerClick.lua"
	},
	{
		Name = "Climb Waterslide And Slide",
		PlaceIds = {139617346573330, 109025676702094, 111157217779261, 100407536317236, 87388097381958},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ClimbWaterslideAndSlide.lua"
	},
	{
		Name = "Climb The Universe",
		PlaceIds = {138651054092882},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ClimbTheUniverse.lua"
	},
	{
		Name = "Paper Plane Training",
		PlaceIds = {100026678532284},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/PaperPlaneTraining.lua"
	},
	{
		Name = "Dig To Earth Core",
		PlaceIds = {81440632616906, 97979682421289},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DigToEarthCore.lua"
	},
	{
		Name = "+1 Aura To Blast Bosses",
		PlaceIds = {116446981715997},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1AuraToBlastBosses.lua"
	},
	{
		Name = "+1 Backflip Obby Escape",
		PlaceIds = {86378115369061},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BackflipObbyEscape.lua"
	},
	{
		Name = "+1 Muscle To Slap Fighting",
		PlaceIds = {91456916859298},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleToSlapFight.lua"
	},
	{
		Name = "+1 Speed Per Click",
		PlaceIds = {134660056748270},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SpeedPerClick.lua"
	},
	{
		Name = "+1 Monkey Banana Destruction",
		PlaceIds = {83256791430098},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MonkeyBananaDestruction.lua"
	},
	{
		Name = "+1 Muscle For Prison Escape",
		PlaceIds = {99468092262114},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleForPrisonEscape.lua"
	},
	{
		Name = "Drive Car And Slide",
		PlaceIds = {137373587493425},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DriveCarAndSlide.lua"
	},
	{
		Name = "+1 Kaiju Power Per Click",
		PlaceIds = {114386067746582},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KaijuPowerPerClick.lua"
	},
	{
		Name = "+1 DoubleJump Bike Escape",
		PlaceIds = {74218191398494},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1DoubleJumpBikeEscape.lua"
	},
	{
		Name = "+1 BottleFlip Obby Escape",
		PlaceIds = {75626443136851},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BottleFlipObbyEscape.lua"
	},
	{
		Name = "+1 Pull Per Step",
		PlaceIds = {78579721506911},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1PullPerStep.lua"
	},
	{
		Name = "+1 Kaiju Evolution",
		PlaceIds = {122191623866866},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KaijuEvolution.lua"
	},
	{
		Name = "Cars Vs Tape",
		PlaceIds = {98393605725180},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/CarsVsTape.lua"
	},
	{
		Name = "Speed Vs Giant",
		PlaceIds = {90803345996188},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/SpeedVsGiant.lua"
	},
	{
		Name = "+1 Speed Slime Escape",
		PlaceIds = {135039703249004, 102674673429018},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SpeedSlimeEscape.lua"
	},
	{
		Name = "+1 Speed Slime Keyboard Escape",
		PlaceIds = {113900430381305, 96947338677734},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SlimeKeyboardEscape.lua"
	},
	{
		Name = "+1 Keyboard Escape Underwater",
		PlaceIds = {85800076296380},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KeyboardEscapeUnderwater.lua"
	},
	{
		Name = "Dream Keyboard Escape",
		PlaceIds = {129350834403009},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DreamKeyboardEscape.lua"
	},
	{
		Name = "+1 Loot Dungeon",
		PlaceIds = {118296732158153},
		URL = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LootDungeon.lua"
	}
}

--==================================================
-- COLORS
--==================================================

local COLORS = {
	Card = Color3.fromRGB(22, 22, 28),
	Text = Color3.fromRGB(245, 245, 250),
	SubText = Color3.fromRGB(155, 155, 165),
	Accent = Color3.fromRGB(220, 50, 50),
	Success = Color3.fromRGB(76, 175, 80),
	Error = Color3.fromRGB(210, 65, 75),
	Warning = Color3.fromRGB(255, 193, 7)
}

--==================================================
-- HELPERS
--==================================================

local function Create(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function AddCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
end

local function AddStroke(object, color)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Parent = object
	return stroke
end

--==================================================
-- CLEAN OLD GUI
--==================================================

local OldGui = PlayerGui:FindFirstChild("NotificationGui")

if OldGui then
	OldGui:Destroy()
end

--==================================================
-- NOTIFICATION GUI
--==================================================

local ScreenGui = Create("ScreenGui", {
	Name = "NotificationGui",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, PlayerGui)

local NotificationContainer = Create("Frame", {
	Name = "Notifications",
	Size = UDim2.fromOffset(320, 300),
	Position = UDim2.new(1, -330, 1, -310),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1000
}, ScreenGui)

Create("UIListLayout", {
	Padding = UDim.new(0, 8),
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	SortOrder = Enum.SortOrder.Bottom
}, NotificationContainer)

--==================================================
-- NOTIFICATION SYSTEM
--==================================================

local function Notify(title, message, notificationType)
	local notificationColor = COLORS.Accent

	if notificationType == "success" then
		notificationColor = COLORS.Success
	elseif notificationType == "error" then
		notificationColor = COLORS.Error
	elseif notificationType == "warning" then
		notificationColor = COLORS.Warning
	end

	local Frame = Create("Frame", {
		Size = UDim2.fromOffset(310, 80),
		BackgroundColor3 = COLORS.Card,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1001
	}, NotificationContainer)

	AddCorner(Frame, 10)

	local FrameStroke = AddStroke(Frame, notificationColor)
	FrameStroke.Transparency = 1

	local Indicator = Create("Frame", {
		Size = UDim2.fromOffset(4, 40),
		Position = UDim2.fromOffset(8, 20),
		BackgroundColor3 = notificationColor,
		BorderSizePixel = 0,
		ZIndex = 1002
	}, Frame)

	AddCorner(Indicator, 2)

	local Title = Create("TextLabel", {
		Size = UDim2.new(1, -30, 0, 20),
		Position = UDim2.fromOffset(20, 8),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = COLORS.Text,
		TextTransparency = 1,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 1002
	}, Frame)

	local Message = Create("TextLabel", {
		Size = UDim2.new(1, -30, 0, 40),
		Position = UDim2.fromOffset(20, 30),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = COLORS.SubText,
		TextTransparency = 1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 1002
	}, Frame)

	local FadeInfo = TweenInfo.new(
		0.3,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	TweenService:Create(Frame, FadeInfo, {
		BackgroundTransparency = 0
	}):Play()

	TweenService:Create(FrameStroke, FadeInfo, {
		Transparency = 0
	}):Play()

	TweenService:Create(Title, FadeInfo, {
		TextTransparency = 0
	}):Play()

	TweenService:Create(Message, FadeInfo, {
		TextTransparency = 0
	}):Play()

	task.delay(5, function()
		if not Frame.Parent then
			return
		end

		TweenService:Create(Frame, FadeInfo, {
			BackgroundTransparency = 1
		}):Play()

		TweenService:Create(FrameStroke, FadeInfo, {
			Transparency = 1
		}):Play()

		TweenService:Create(Title, FadeInfo, {
			TextTransparency = 1
		}):Play()

		TweenService:Create(Message, FadeInfo, {
			TextTransparency = 1
		}):Play()

		task.wait(0.3)

		if Frame.Parent then
			Frame:Destroy()
		end
	end)
end

--==================================================
-- FIND SUPPORTED GAME
--==================================================

local function FindSupportedGame(placeId)
	for _, gameData in ipairs(SupportedGames) do
		for _, id in ipairs(gameData.PlaceIds) do
			if id == placeId then
				return gameData
			end
		end
	end

	return nil
end

--==================================================
-- EXECUTE SCRIPT
--==================================================

local function ExecuteScript(scriptUrl, gameName)
	if not scriptUrl or scriptUrl == "" then
		Notify(
			"Not Available",
			gameName .. " script is not available yet.",
			"warning"
		)
		return
	end

	task.spawn(function()
		local fetchSuccess, scriptContent = pcall(function()
			return game:HttpGet(scriptUrl)
		end)

		if not fetchSuccess or not scriptContent or scriptContent == "" then
			Notify(
				"Fetch Error",
				"Failed to download " .. gameName .. ".",
				"error"
			)
			return
		end

		local executeSuccess, executeError = pcall(function()
			local ScriptFunction = loadstring(scriptContent)

			if not ScriptFunction then
				error("Unable to compile downloaded script.")
			end

			ScriptFunction()
		end)

		if executeSuccess then
			Notify(
				"Loaded",
				gameName .. " script is running.",
				"success"
			)
		else
			warn("[Loader] Execution Error:", executeError)

			Notify(
				"Execute Error",
				"Failed to execute " .. gameName .. ".",
				"error"
			)
		end
	end)
end

--==================================================
-- CHECK GAME
--==================================================

local function CheckAndExecute()
	local PlaceId = game.PlaceId
	local GameData = FindSupportedGame(PlaceId)

	if not GameData then
		Notify(
			"Unsupported",
			"This game is not supported yet.",
			"warning"
		)
		return
	end

	Notify(
		"Game Detected",
		GameData.Name .. " found! Loading script...",
		"success"
	)

	task.wait(1.5)

	ExecuteScript(
		GameData.URL,
		GameData.Name
	)
end

--==================================================
-- START
--==================================================

CheckAndExecute()

--==================================================
-- TELEPORT DETECTION
--==================================================

local LastPlaceId = game.PlaceId

RunService.Heartbeat:Connect(function()
	local CurrentPlaceId = game.PlaceId

	if CurrentPlaceId ~= LastPlaceId then
		LastPlaceId = CurrentPlaceId

		task.wait(1)

		CheckAndExecute()
	end
end)
