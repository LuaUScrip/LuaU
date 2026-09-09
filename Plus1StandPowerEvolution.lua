local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemotesFolder")
local Configs = ReplicatedStorage:WaitForChild("Configs")

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

local function getHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function csvContains(csv, name)
	for word in string.gmatch(csv or "", "[^,]+") do
		if word == tostring(name) then return true end
	end
	return false
end

local function parseWinText(text)
	local numStr = text:match([[%d[%d%.]*]])
	if not numStr then return 0 end
	local num = tonumber(numStr) or 0
	if text:find("Dc") then num = num * 1e66
	elseif text:find("No") then num = num * 1e63
	elseif text:find("Oc") then num = num * 1e60
	elseif text:find("Sp") then num = num * 1e57
	elseif text:find("Sx") then num = num * 1e54
	elseif text:find("Qi") then num = num * 1e51
	elseif text:find("Qd") then num = num * 1e48
	elseif text:find("T") then num = num * 1e12
	elseif text:find("B") then num = num * 1e9
	elseif text:find("M") then num = num * 1e6
	elseif text:find("K") then num = num * 1e3
	end
	return num
end

local function loadConfig(name)
	local ok, data = pcall(function()
		return require(Configs:WaitForChild(name))
	end)
	if ok and type(data) == "table" then
		local items = {}
		for _, entry in ipairs(data) do
			if type(entry) == "table" and entry.Name then
				items[#items + 1] = entry
			end
		end
		return items
	end
	return {}
end

local function doFarmWins()
	local hrp = getHRP()
	if not hrp then return end
	local winsFolder = Workspace:FindFirstChild("World3") and Workspace.World3:FindFirstChild("Wins")
	if not winsFolder then return end
	local bestPad = nil
	local bestScore = -1
	for _, win in ipairs(winsFolder:GetChildren()) do
		pcall(function()
			local gui = win:FindFirstChild("BillboardGui")
			local label = gui and gui:FindFirstChild("TextLabel")
			if label then
				local score = parseWinText(label.Text)
				if score > bestScore then
					bestScore = score
					bestPad = win
				end
			end
		end)
	end
	if not bestPad then return end
	local touchPart = bestPad:GetChildren()[3]
	if not touchPart or not touchPart:IsA("BasePart") then return end
	pcall(function()
		firetouchinterest(hrp, touchPart, 0)
		task.wait(0.1)
		firetouchinterest(hrp, touchPart, 1)
	end)
end

local function doTrain()
	Remotes:WaitForChild("ClaimPowerGain"):FireServer()
end

local function doRebirth()
	Remotes:WaitForChild("Rebirth"):InvokeServer()
end

local function doBuyAllStands()
	local ranges = {{1, 15}, {2, 25}, {3, 25}}
	for _, r in ipairs(ranges) do
		for i = r[1], r[2] do
			pcall(function() Remotes:WaitForChild("PurchaseStand"):InvokeServer(i) end)
			task.wait(0.05)
		end
	end
end

local function doBuyAndEquipBestTrail()
	local data = loadConfig("Trails")
	if #data == 0 then return end
	local owned = LocalPlayer:GetAttribute("OwnedTrails") or ""
	local equipped = LocalPlayer:GetAttribute("EquippedTrail") or ""
	local firstUnowned = nil
	local bestOwned = nil
	local bestMult = 0
	for i = #data, 1, -1 do
		local item = data[i]
		if item.Requirement == "Robux" or item.Requirement == "Group" then
			-- skip non-purchasable
		else
			if csvContains(owned, item.Name) then
				if (item.Multiplier or 0) > bestMult then
					bestMult = item.Multiplier or 0
					bestOwned = item.Name
				end
			else
				if item.Wins and not firstUnowned then
					firstUnowned = item.Name
				end
			end
		end
	end
	if firstUnowned then
		pcall(function() Remotes:WaitForChild("PurchaseTrail"):InvokeServer(firstUnowned) end)
		task.wait(1)
		owned = LocalPlayer:GetAttribute("OwnedTrails") or ""
		for i = #data, 1, -1 do
			if csvContains(owned, data[i].Name) then
				if (data[i].Multiplier or 0) > bestMult then
					bestMult = data[i].Multiplier or 0
					bestOwned = data[i].Name
				end
			end
		end
	end
	if bestOwned and bestOwned ~= equipped then
		pcall(function() Remotes:WaitForChild("EquipTrail"):FireServer(bestOwned) end)
	end
end

local function doBuyAndEquipBestAura()
	local data = loadConfig("Auras")
	if #data == 0 then return end
	local owned = LocalPlayer:GetAttribute("OwnedAuras") or ""
	local equipped = LocalPlayer:GetAttribute("EquippedAura") or ""
	local firstUnowned = nil
	local bestOwned = nil
	local bestMult = 0
	for i = #data, 1, -1 do
		local item = data[i]
		if item.Requirement == "Robux" or item.Requirement == "Group" then
			-- skip non-purchasable
		else
			if csvContains(owned, item.Name) then
				if (item.Multiplier or 0) > bestMult then
					bestMult = item.Multiplier or 0
					bestOwned = item.Name
				end
			else
				if not firstUnowned then
					firstUnowned = item.Name
				end
			end
		end
	end
	if firstUnowned then
		pcall(function() Remotes:WaitForChild("PurchaseAura"):InvokeServer(firstUnowned) end)
		task.wait(1)
		owned = LocalPlayer:GetAttribute("OwnedAuras") or ""
		for i = #data, 1, -1 do
			if csvContains(owned, data[i].Name) then
				if (data[i].Multiplier or 0) > bestMult then
					bestMult = data[i].Multiplier or 0
					bestOwned = data[i].Name
				end
			end
		end
	end
	if bestOwned and bestOwned ~= equipped then
		pcall(function() Remotes:WaitForChild("EquipAura"):FireServer(bestOwned) end)
	end
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

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
	text = "Farm Wins",
	state = false,
	callback = function(s)
		running.farmWins = s
		if s then loop("farmWins", doFarmWins, 0.1) else stop("farmWins") end
	end,
})

ui:AddToggle({
	text = "Fast Train",
	state = false,
	callback = function(s)
		running.train = s
		if s then loop("train", doTrain, 0.00000001) else stop("train") end
	end,
})

ui:AddToggle({
	text = "Auto Rebirth",
	state = false,
	callback = function(s)
		running.rebirth = s
		if s then loop("rebirth", doRebirth, 0.5) else stop("rebirth") end
	end,
})

ui:AddToggle({
	text = "Buy Stands",
	state = false,
	callback = function(s)
		running.buyStand = s
		if s then loop("buyStand", doBuyAllStands, 0.2) else stop("buyStand") end
	end,
})

ui:AddToggle({
	text = "Buy Trail",
	state = false,
	callback = function(s)
		running.buyTrail = s
		if s then loop("buyTrail", doBuyAndEquipBestTrail, 2) else stop("buyTrail") end
	end,
})

ui:AddToggle({
	text = "Buy Aura",
	state = false,
	callback = function(s)
		running.buyAura = s
		if s then loop("buyAura", doBuyAndEquipBestAura, 2) else stop("buyAura") end
	end,
})

ui:AddButton({
	text = "King Of Hill",
	callback = function()
		local hrp = getHRP()
		if not hrp then return end
		hrp.CFrame = CFrame.new(9558, 130, 91)
		local existing = Workspace:FindFirstChild("FarmPlatform")
		if existing then existing:Destroy() end
		local part = Instance.new("Part")
		part.Name = "FarmPlatform"
		part.Size = Vector3.new(50, 1, 50)
		part.Anchored = true
		part.CanCollide = true
		part.Transparency = 1
		part.CFrame = CFrame.new(9558, 125, 91)
		part.Parent = Workspace
	end,
})

lib:Init()