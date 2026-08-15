local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==================================================
-- CONFIG - 100 SCRIPTS
--==================================================

local SupportedGames = {
	{name = "Throw A Coin", placeIds = {115681808123944, 72042130041700, 100875131717601, 81335362752013}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ThrowACoin.lua"},
	{name = "+1 Loot Evolution", placeIds = {96033388567901}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LootEvolution.lua"},
	{name = "+1 Pickaxe Swing Escape", placeIds = {82554996468034}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1PickaxeSwingEscape.lua"},
	{name = "Spin A Fish", placeIds = {79776733008346}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/SpinAFish.lua"},
	{name = "+1 Katana Evolution", placeIds = {84757653274750, 97295445262211}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KatanaEvolution.lua"},
	{name = "+1 Muscle To Push Boulder", placeIds = {136107936984073}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleToPushBoulder.lua"},
	{name = "Dog Race", placeIds = {119609933650338}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DogRace.lua"},
	{name = "Fishing Chef", placeIds = {88599461076137}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/FishingChef.lua"},
	{name = "+1 Ladder Per Click", placeIds = {82236511306295}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LadderPerClick.lua"},
	{name = "+1 Followers Per Click", placeIds = {98695134949589}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1FollowersPerClick.lua"},
	{name = "Climb Waterslide And Slide", placeIds = {139617346573330, 109025676702094, 111157217779261, 100407536317236, 87388097381958}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ClimbWaterslideAndSlide.lua"},
	{name = "Climb The Universe", placeIds = {138651054092882}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/ClimbTheUniverse.lua"},
	{name = "Paper Plane Training", placeIds = {100026678532284}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/PaperPlaneTraining.lua"},
	{name = "Dig To Earth Core", placeIds = {81440632616906, 97979682421289}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DigToEarthCore.lua"},
	{name = "+1 Aura To Blast Bosses", placeIds = {116446981715997}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1AuraToBlastBosses.lua"},
	{name = "+1 Backflip Obby Escape", placeIds = {86378115369061}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BackflipObbyEscape.lua"},
	{name = "+1 Muscle To Slap Fighting", placeIds = {91456916859298}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleToSlapFight.lua"},
	{name = "+1 Speed Per Click", placeIds = {134660056748270}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SpeedPerClick.lua"},
	{name = "+1 Monkey Banana Destruction", placeIds = {83256791430098}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MonkeyBananaDestruction.lua"},
	{name = "+1 Muscle For Prison Escape", placeIds = {99468092262114}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1MuscleForPrisonEscape.lua"},
	{name = "Drive Car And Slide", placeIds = {137373587493425}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DriveCarAndSlide.lua"},
	{name = "+1 Kaiju Power Per Click", placeIds = {114386067746582}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KaijuPowerPerClick.lua"},
	{name = "+1 DoubleJump Bike Escape", placeIds = {74218191398494}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1DoubleJumpBikeEscape.lua"},
	{name = "+1 BottleFlip Obby Escape", placeIds = {75626443136851}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BottleFlipObbyEscape.lua"},
	{name = "+1 Pull Per Step", placeIds = {78579721506911}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1PullPerStep.lua"},
	{name = "+1 Kaiju Evolution", placeIds = {122191623866866}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KaijuEvolution.lua"},
	{name = "Cars Vs Tape", placeIds = {98393605725180}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/CarsVsTape.lua"},
	{name = "Speed Vs Giant", placeIds = {90803345996188}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/SpeedVsGiant.lua"},
	{name = "+1 Speed Slime Escape", placeIds = {135039703249004, 102674673429018}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SpeedSlimeEscape.lua"},
	{name = "+1 Speed Sime Keyboard Escape", placeIds = {113900430381305, 96947338677734}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1SlimeKeyboardEscape.lua"},
	{name = "+1 Keyboard Escape Underwater", placeIds = {85800076296380}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1KeyboardEscapeUnderwater.lua"},
	{name = "Dream Keyboard Escape", placeIds = {129350834403009}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/DreamKeyboardEscape.lua"},
	{name = "+1 Loot Dungeon", placeIds = {118296732158153}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1LootDungeon.lua"},
	{name = "+1 Backflip Keyboard Escape", placeIds = {102553576537621}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BackflipKeyboardEscapeW1.lua"},
	{name = "+1 Backflip Keyboard Escape", placeIds = {77764718018334}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1BackflipKeyboardEscapeW2.lua"},
	{name = "Web Swing For Lucky Blocks", placeIds = {86455914125987}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/WebSwingForLuckyBlock.lua"},
	{name = "+1 Fire Per Click", placeIds = {70970180473702}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1FirePerClick.lua"},
	{name = "Be A Fish Bait", placeIds = {99702578544768}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/BeAFishBait.lua"},
	{name = "+1 Stand Power Evolution", placeIds = {82598548574073}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/Plus1StandPowerEvolution.lua"},
	{name = "Jump To Steal Soccer Player", placeIds = {133294838637122}, url = "https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/JumpToStealPlayer.lua"},
	{name = "Script 41", placeIds = {0}, url = nil},
	{name = "Script 42", placeIds = {0}, url = nil},
	{name = "Script 43", placeIds = {0}, url = nil},
	{name = "Script 44", placeIds = {0}, url = nil},
	{name = "Script 45", placeIds = {0}, url = nil},
	{name = "Script 46", placeIds = {0}, url = nil},
	{name = "Script 47", placeIds = {0}, url = nil},
	{name = "Script 48", placeIds = {0}, url = nil},
	{name = "Script 49", placeIds = {0}, url = nil},
	{name = "Script 50", placeIds = {0}, url = nil},
	{name = "Script 51", placeIds = {0}, url = nil},
	{name = "Script 52", placeIds = {0}, url = nil},
	{name = "Script 53", placeIds = {0}, url = nil},
	{name = "Script 54", placeIds = {0}, url = nil},
	{name = "Script 55", placeIds = {0}, url = nil},
	{name = "Script 56", placeIds = {0}, url = nil},
	{name = "Script 57", placeIds = {0}, url = nil},
	{name = "Script 58", placeIds = {0}, url = nil},
	{name = "Script 59", placeIds = {0}, url = nil},
	{name = "Script 60", placeIds = {0}, url = nil},
	{name = "Script 61", placeIds = {0}, url = nil},
	{name = "Script 62", placeIds = {0}, url = nil},
	{name = "Script 63", placeIds = {0}, url = nil},
	{name = "Script 64", placeIds = {0}, url = nil},
	{name = "Script 65", placeIds = {0}, url = nil},
	{name = "Script 66", placeIds = {0}, url = nil},
	{name = "Script 67", placeIds = {0}, url = nil},
	{name = "Script 68", placeIds = {0}, url = nil},
	{name = "Script 69", placeIds = {0}, url = nil},
	{name = "Script 70", placeIds = {0}, url = nil},
	{name = "Script 71", placeIds = {0}, url = nil},
	{name = "Script 72", placeIds = {0}, url = nil},
	{name = "Script 73", placeIds = {0}, url = nil},
	{name = "Script 74", placeIds = {0}, url = nil},
	{name = "Script 75", placeIds = {0}, url = nil},
	{name = "Script 76", placeIds = {0}, url = nil},
	{name = "Script 77", placeIds = {0}, url = nil},
	{name = "Script 78", placeIds = {0}, url = nil},
	{name = "Script 79", placeIds = {0}, url = nil},
	{name = "Script 80", placeIds = {0}, url = nil},
	{name = "Script 81", placeIds = {0}, url = nil},
	{name = "Script 82", placeIds = {0}, url = nil},
	{name = "Script 83", placeIds = {0}, url = nil},
	{name = "Script 84", placeIds = {0}, url = nil},
	{name = "Script 85", placeIds = {0}, url = nil},
	{name = "Script 86", placeIds = {0}, url = nil},
	{name = "Script 87", placeIds = {0}, url = nil},
	{name = "Script 88", placeIds = {0}, url = nil},
	{name = "Script 89", placeIds = {0}, url = nil},
	{name = "Script 90", placeIds = {0}, url = nil},
	{name = "Script 91", placeIds = {0}, url = nil},
	{name = "Script 92", placeIds = {0}, url = nil},
	{name = "Script 93", placeIds = {0}, url = nil},
	{name = "Script 94", placeIds = {0}, url = nil},
	{name = "Script 95", placeIds = {0}, url = nil},
	{name = "Script 96", placeIds = {0}, url = nil},
	{name = "Script 97", placeIds = {0}, url = nil},
	{name = "Script 98", placeIds = {0}, url = nil},
	{name = "Script 99", placeIds = {0}, url = nil},
	{name = "Script 100", placeIds = {0}, url = nil},
}

--==================================================
-- COLORS
--==================================================

local CARD = Color3.fromRGB(22, 22, 28)
local TEXT = Color3.fromRGB(245, 245, 250)
local SUBTEXT = Color3.fromRGB(155, 155, 165)
local ACCENT = Color3.fromRGB(220, 50, 50)
local SUCCESS = Color3.fromRGB(76, 175, 80)
local ERROR = Color3.fromRGB(210, 65, 75)
local WARNING = Color3.fromRGB(255, 193, 7)

--==================================================
-- HELPER FUNCTIONS
--==================================================

local function Create(className, properties, parent)
	local object = Instance.new(className)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	object.Parent = parent
	return object
end

local function Corner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
end

local function Stroke(object, color)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(48, 48, 58)
	stroke.Thickness = 1
	stroke.Parent = object
	return stroke
end

local old = PlayerGui:FindFirstChild("NotificationGui")
if old then
	old:Destroy()
end

--==================================================
-- NOTIFICATION SYSTEM
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
	SortOrder = Enum.SortOrder.LayoutOrder
}, NotificationContainer)

local function Notify(title, message, notificationType)
	local notificationColor = ACCENT
	if notificationType == "success" then
		notificationColor = SUCCESS
	elseif notificationType == "error" then
		notificationColor = ERROR
	elseif notificationType == "warning" then
		notificationColor = WARNING
	end

	local Frame = Create("Frame", {
		Size = UDim2.fromOffset(310, 80),
		BackgroundColor3 = CARD,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1001
	}, NotificationContainer)

	Corner(Frame, 10)
	local FrameStroke = Stroke(Frame, notificationColor)
	FrameStroke.Transparency = 1

	-- Colored indicator bar
	local Indicator = Create("Frame", {
		Size = UDim2.fromOffset(4, 40),
		Position = UDim2.fromOffset(8, 20),
		BackgroundColor3 = notificationColor,
		BorderSizePixel = 0,
		ZIndex = 1002
	}, Frame)
	Corner(Indicator, 2)

	local Title = Create("TextLabel", {
		Size = UDim2.new(1, -22, 0, 20),
		Position = UDim2.fromOffset(18, 8),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = TEXT,
		TextTransparency = 1,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 1002
	}, Frame)

	local Message = Create("TextLabel", {
		Size = UDim2.new(1, -22, 0, 40),
		Position = UDim2.fromOffset(18, 30),
		BackgroundTransparency = 1,
		Text = message,
		TextColor3 = SUBTEXT,
		TextTransparency = 1,
		TextSize = 12,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		ZIndex = 1002
	}, Frame)

	TweenService:Create(Frame, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(FrameStroke, TweenInfo.new(0.3), { Transparency = 0 }):Play()
	TweenService:Create(Title, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	TweenService:Create(Message, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()

	task.delay(5, function()
		if not Frame or not Frame.Parent then return end
		TweenService:Create(Frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(FrameStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		TweenService:Create(Title, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		TweenService:Create(Message, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		task.wait(0.3)
		if Frame then Frame:Destroy() end
	end)
end

--==================================================
-- FIND SUPPORTED GAME BY PLACE ID
--==================================================

local function FindSupportedGame(placeId)
	for _, supportedGame in ipairs(SupportedGames) do
		for _, id in ipairs(supportedGame.placeIds) do
			if id == placeId then
				return supportedGame
			end
		end
	end
	return nil
end

--==================================================
-- EXECUTE SCRIPT
--==================================================

local function ExecuteScript(scriptUrl, gameName)
	if not scriptUrl then
		Notify("Not Available", gameName .. " script not available yet", "warning")
		return
	end

	task.spawn(function()
		local fetchSuccess, scriptContent = pcall(function()
			return game:HttpGet(scriptUrl)
		end)

		if not fetchSuccess or not scriptContent then
			Notify("Fetch Error", "Failed to download script. Check your connection", "error")
			return
		end

		local execSuccess = pcall(function()
			local func = loadstring(scriptContent)
			if func then 
				func() 
			else 
				error("Script loaded but returned nil") 
			end
		end)

		if execSuccess then
			Notify("Loaded", gameName .. " script is running", "success")
		else
			Notify("Execute Error", "Script execution failed", "error")
		end
	end)
end

--==================================================
-- MAIN LOGIC
--==================================================

local function CheckAndExecute()
	local currentPlaceId = game.PlaceId
	print("Current Place ID: " .. tostring(currentPlaceId))
	
	local supportedGame = FindSupportedGame(currentPlaceId)
	
	if not supportedGame then
		Notify("Unsupported", "This game is not supported yet", "warning")
		print("Game not supported")
		return
	end

	print("Supported game found: " .. supportedGame.name)
	Notify("Game Detected", supportedGame.name .. " found! Loading script...", "success")
	task.wait(1.5)
	ExecuteScript(supportedGame.url, supportedGame.name)
end

CheckAndExecute()

--==================================================
-- TELEPORT DETECTION
--==================================================

local lastPlaceId = game.PlaceId

RunService.Heartbeat:Connect(function()
	if game.PlaceId ~= lastPlaceId then
		lastPlaceId = game.PlaceId
		print("Teleported to Place ID: " .. tostring(game.PlaceId))
		task.wait(1)
		CheckAndExecute()
	end
end)
