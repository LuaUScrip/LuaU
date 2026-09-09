local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = function(name) return Remotes:WaitForChild(name) end

local running = {
	throwFast = false,
	sell = false,
	buyRock = false,
	upgrade = false,
	upgradeA = false,
	upgradeB = false,
	claimPotion = false,
}

local loops = {}

local function getRockList()
	local list = {}
	pcall(function()
		local MassTiers = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MassTiers")
		if MassTiers:IsA("ModuleScript") then
			local ok, data = pcall(require, MassTiers)
			if ok and type(data) == "table" then
				local src = data.List or data
				if type(src) == "table" then
					for _, item in ipairs(src) do
						if type(item) == "table" and item.Id then
							list[#list + 1] = { Id = item.Id, Name = item.Name or tostring(item.Id) }
						end
					end
				end
			end
		elseif MassTiers:IsA("Folder") then
			for _, child in ipairs(MassTiers:GetChildren()) do
				list[#list + 1] = { Id = child:GetAttribute("Id") or child.Name, Name = child.Name }
			end
		end
	end)
	return list
end

local PotionDropParts = {}
local function cachePotionDrops()
	PotionDropParts = {}
	pcall(function()
		local folder = Workspace:FindFirstChild("PotionDrops", true)
		if not folder then return end
		for _, child in ipairs(folder:GetChildren()) do
			local dp = child:FindFirstChild("default")
			if dp and dp:IsA("BasePart") then
				PotionDropParts[#PotionDropParts + 1] = dp
			elseif child:IsA("BasePart") then
				PotionDropParts[#PotionDropParts + 1] = child
			else
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("BasePart") then
						PotionDropParts[#PotionDropParts + 1] = sub
						break
					end
				end
			end
		end
	end)
end
task.spawn(cachePotionDrops)

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

local function doThrowFast()
	remote("Throw"):InvokeServer()
	task.wait(1)
	remote("RevealDone"):FireServer()
end

local function doSell()
	remote("SellAll"):FireServer()
end

local function doBuyRock()
	for _, rock in ipairs(getRockList()) do
		pcall(function() remote("BuyMass"):InvokeServer(rock.Id) end)
		task.wait(0.1)
	end
end

local function doUpgrade()
	remote("BuyUpgrade"):InvokeServer("Gravity", "max")
	remote("BuyUpgrade"):InvokeServer("Density", "max")
end

local function doUpgradeA()
	remote("BuyUpgrade"):InvokeServer("Gravity", "max")
end

local function doUpgradeB()
	remote("BuyUpgrade"):InvokeServer("Density", "max")
end

local function doClaimPotion()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	if #PotionDropParts == 0 then cachePotionDrops() end
	if #PotionDropParts == 0 then return end
	local saved = hrp.CFrame
	for _, drop in ipairs(PotionDropParts) do
		pcall(function()
			if drop and drop.Parent then
				hrp.CFrame = drop.CFrame + Vector3.new(0, 3, 0)
				task.wait(0.2)
				hrp.CFrame = drop.CFrame + Vector3.new(0, 0.5, 0)
				task.wait(0.3)
			end
		end)
	end
	hrp.CFrame = saved
end

-- Background: always running, no toggle
task.spawn(function()
	while true do
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
		task.wait(600)
	end
end)

LocalPlayer.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

task.spawn(function()
	while true do
		task.wait(20)
		pcall(function()
			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0)
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			local gui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
			local frame = gui and gui:FindFirstChild("DisconnectedFrame")
			if frame and frame.Visible then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
			end
		end)
	end
end)

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
	text = "Throw Rock",
	state = false,
	callback = function(s)
		running.throwFast = s
		if s then loop("throwFast", doThrowFast, 0.0001) else stop("throwFast") end
	end,
})

ui:AddToggle({
	text = "Sell All",
	state = false,
	callback = function(s)
		running.sell = s
		if s then loop("sell", doSell, 1) else stop("sell") end
	end,
})

ui:AddToggle({
	text = "Buy Rock",
	state = false,
	callback = function(s)
		running.buyRock = s
		if s then loop("buyRock", doBuyRock, 0.5) else stop("buyRock") end
	end,
})

ui:AddToggle({
	text = "Upgrade All",
	state = false,
	callback = function(s)
		running.upgrade = s
		if s then loop("upgrade", doUpgrade, 0.001) else stop("upgrade") end
	end,
})

ui:AddToggle({
	text = "Upgrade Luck",
	state = false,
	callback = function(s)
		running.upgradeA = s
		if s then loop("upgradeA", doUpgradeA, 0.001) else stop("upgradeA") end
	end,
})

ui:AddToggle({
	text = "Upgrade Value",
	state = false,
	callback = function(s)
		running.upgradeB = s
		if s then loop("upgradeB", doUpgradeB, 0.001) else stop("upgradeB") end
	end,
})

ui:AddToggle({
	text = "Collect Potion",
	state = false,
	callback = function(s)
		running.claimPotion = s
		if s then loop("claimPotion", doClaimPotion, 0.5) else stop("claimPotion") end
	end,
})

ui:AddButton({
	text = "Instant Unlock W2",
	callback = function()
		pcall(function() remote("TravelTo"):InvokeServer(2) end)
	end,
})

lib:Init()