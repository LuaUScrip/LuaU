local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local running = {}
local loops = {}

local function loop(name, fn, wait_time)
	if loops[name] then return end
	loops[name] = true
	task.spawn(function()
		while loops[name] and running[name] do
			pcall(fn)
			task.wait(wait_time or 0.01)
		end
	end)
end

local function stop(name)
	loops[name] = false
end

LocalPlayer.Idled:Connect(function()
	pcall(function()
		VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
		task.wait(0.1)
		VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
	end)
end)

task.spawn(function()
	while true do
		pcall(function()
			if LocalPlayer.GameplayPaused then
				LocalPlayer.GameplayPaused = false
			end
		end)
		task.wait()
	end
end)

local POS1 = CFrame.new(-9585, 3, 230)
local POS2 = CFrame.new(-9585, 3, 7537)

local function doFarmWins()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = POS1
	task.wait(1)
	hrp.CFrame = POS2
	task.wait(1)
end

local function doBuyBestEgg()
	RemoteFunctions:WaitForChild("EggOpened"):InvokeServer("SecondLostJungleCapsule", {})
end

local function doUpgradeSpeed()
	RemoteEvents:WaitForChild("PlateUpgrade"):FireServer()
end

local function doAddMoney(amount)
	RemoteEvents:WaitForChild("MoneyPickedUp"):FireServer(tonumber(amount) or 100)
end

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
	text = "Auto Farm Wins",
	state = false,
	callback = function(s)
		running.farmWins = s
		if s then loop("farmWins", doFarmWins, 0.1) else stop("farmWins") end
	end,
})

ui:AddToggle({
	text = "Auto Buy Best Egg",
	state = false,
	callback = function(s)
		running.buyEgg = s
		if s then loop("buyEgg", doBuyBestEgg, 0.1) else stop("buyEgg") end
	end,
})

ui:AddToggle({
	text = "Auto Upgrade Speed",
	state = false,
	callback = function(s)
		running.upgradeSpeed = s
		if s then loop("upgradeSpeed", doUpgradeSpeed, 0.0000000001) else stop("upgradeSpeed") end
	end,
})

local moneyAmount = 100

ui:AddBox({
	text = "Money Amount",
	value = "100",
	callback = function(value)
		moneyAmount = tonumber(value) or 100
	end,
})

ui:AddButton({
	text = "Add Money",
	callback = function()
		pcall(function() doAddMoney(moneyAmount) end)
	end,
})

lib:Init()