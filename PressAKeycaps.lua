local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

setthreadidentity(8)

local networker = require(RS.Packages.Networker).client
local AtomKey = require(RS.Shared.Modules.Atoms.AtomKey)
local PlayerState = require(RS.Shared.Modules.Atoms.PlayerState)
local Keycaps = require(RS.Shared.Modules.Keycaps.Keycaps)
local GridLayout = require(RS.Shared.Modules.Keycaps.GridLayout)
local UpgradesConfig = require(RS.Shared.Modules.Config.UpgradesConfig)
local WorkersConfig = require(RS.Shared.Modules.Config.WorkersConfig)
local RebirthConfig = require(RS.Shared.Modules.Config.RebirthConfig)
local ZonesConfig = require(RS.Shared.Modules.Config.ZonesConfig)

local ch = {
	Workers = networker.new("Workers", {}),
	Upgrades = networker.new("Upgrades", {}),
	Rebirth = networker.new("Rebirth", {}),
	Unlock = networker.new("Unlock", {}),
	Zones = networker.new("Zones", {}),
}

local myKey = AtomKey.For(lp)

local cfg = {
	autoWalk = false,
	autoWorkers = false,
	autoRoll = false,
	autoBuy = false,
	autoUnlock = false,
	autoRebirth = false,
	antiAfk = true,
	autoUpgrade = false,
}

local state = {
	plotName = nil,
	keycaps = {},
	walkIdx = 0,
	rarityThreshold = 0,
}

local function fmt(n)
	n = tonumber(n) or 0
	local suffixes = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No" }
	local i = 0
	while n >= 1000 and i < #suffixes do
		n = n / 1000
		i = i + 1
	end
	if i == 0 then return string.format("%d", n) end
	return string.format("%.2f%s", n, suffixes[i])
end

local function getHrp()
	local c = lp.Character
	if not c then return nil end
	local h = c:FindFirstChildOfClass("Humanoid")
	local hrp = c:FindFirstChild("HumanoidRootPart")
	if not h or not hrp or h.Health <= 0 then return nil end
	return hrp
end

local function refreshPlot()
	local pn = PlayerState.PlotOwner()[myKey]
	state.plotName = pn
	state.keycaps = {}
	if not pn then return end
	local plots = workspace:FindFirstChild("MAP") and workspace.MAP:FindFirstChild("PLOTS")
	local plot = plots and plots:FindFirstChild(pn)
	local kcs = plot and plot:FindFirstChild("Keycaps")
	if not kcs then return end
	for _, m in ipairs(kcs:GetChildren()) do
		if m:IsA("Model") then
			local p = m:FindFirstChildWhichIsA("BasePart")
			if p then table.insert(state.keycaps, p.Position) end
		end
	end
end

local function pending()
	return PlayerState.PendingUnlock()[myKey] or {}
end

local function money()
	return PlayerState.Money()[myKey] or 0
end

local function doWalk()
	if #state.keycaps == 0 then
		refreshPlot()
		if #state.keycaps == 0 then return end
	end
	local c = lp.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return end
	state.walkIdx = state.walkIdx % #state.keycaps + 1
	local pos = state.keycaps[state.walkIdx]
	h:MoveTo(pos)
end

local function doBuyWorkers()
	local n = PlayerState.Workers()[myKey] or 0
	local reb = PlayerState.Rebirths()[myKey] or 0
	local maxW = math.min(WorkersConfig.BaseMax + RebirthConfig.ExtraWorkersFor(reb), #WorkersConfig.Prices)
	if n >= maxW then return end
	local cost = WorkersConfig.Prices[n + 1]
	if money() >= cost then
		ch.Workers:fire("BuyWorkers", 1)
	end
end

local function doRoll()
	if cfg.autoBuy or cfg.autoUnlock then return end
	ch.Unlock:fire("RequestRoll", state.plotName or PlayerState.PlotOwner()[myKey])
end

local function doUnlock()
	local owned = PlayerState.Zones()[myKey]
	if not owned then return end
	local idx = GridLayout.BuyableZones(owned)[1]
	if not idx then return end
	local reb = PlayerState.Rebirths()[myKey] or 0
	local maxZ = math.min(ZonesConfig.BaseUnlockable + RebirthConfig.ExtraZonesFor(reb), #ZonesConfig.Prices)
	if #owned >= maxZ then return end
	local cost = ZonesConfig.Prices[#owned]
	if cost and money() >= cost then
		ch.Zones:fire("BuyZone", idx)
	end
end

local function doBuy()
	local plot = state.plotName or PlayerState.PlotOwner()[myKey]
	if not plot then return end
	local p = pending()
	local claimed = false
	for slot, cap in ipairs(p) do
		if cap and cap ~= "" then
			local info = Keycaps.Get(cap)
			if info and info.MoneyPerPress >= state.rarityThreshold and money() >= (info.Price or 0) then
				ch.Unlock:fire("ClaimUnlock", slot)
				claimed = true
			end
		end
	end
	if not claimed then
		ch.Unlock:fire("RequestRoll", plot)
	end
end

local function doRebirth()
	local reb = PlayerState.Rebirths()[myKey] or 0
	local presses = PlayerState.CurrentPresses()[myKey] or 0
	local next = RebirthConfig.Next(reb)
	if next and presses >= next.Presses then
		ch.Rebirth:fire("Rebirth")
	end
end

local function doUpgrades()
	for _, name in ipairs(UpgradesConfig.Order) do
		ch.Upgrades:fire("BuyUpgrade", name)
		task.wait(0.2)
	end
end

local function doAntiAfk()
	local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then
		h.Jump = true
		task.wait(0.4)
		h.Jump = false
	end
end

local loops = {}

local function loop(name, fn, wait_time)
	if loops[name] then return end
	loops[name] = true
	task.spawn(function()
		while loops[name] and cfg[name] do
			pcall(fn)
			task.wait(wait_time or 0.1)
		end
		loops[name] = nil
	end)
end

local function stop(name)
	loops[name] = false
end

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
	text = "Auto Walk Keycaps",
	state = false,
	callback = function(s)
		cfg.autoWalk = s
		if s then loop("autoWalk", doWalk, 0.1) else stop("autoWalk") end
	end
})

ui:AddToggle({
	text = "Buy Workers",
	state = false,
	callback = function(s)
		cfg.autoWorkers = s
		if s then loop("autoWorkers", doBuyWorkers, 0.2) else stop("autoWorkers") end
	end
})

ui:AddToggle({
	text = "Auto Roll",
	state = false,
	callback = function(s)
		cfg.autoRoll = s
		if s then loop("autoRoll", doRoll, 0.2) else stop("autoRoll") end
	end
})

ui:AddToggle({
	text = "Buy Keycaps",
	state = false,
	callback = function(s)
		cfg.autoBuy = s
		if s then loop("autoBuy", doBuy, 0.1) else stop("autoBuy") end
	end
})

ui:AddToggle({
	text = "Unlock Keypads",
	state = false,
	callback = function(s)
		cfg.autoUnlock = s
		if s then loop("autoUnlock", doUnlock, 1) else stop("autoUnlock") end
	end
})

ui:AddToggle({
	text = "Auto Upgrade",
	state = false,
	callback = function(s)
		cfg.autoUpgrade = s
		if s then loop("autoUpgrade", doUpgrades, 0.3) else stop("autoUpgrade") end
	end
})

ui:AddToggle({
	text = "Auto Rebirth",
	state = false,
	callback = function(s)
		cfg.autoRebirth = s
		if s then loop("autoRebirth", doRebirth, 6) else stop("autoRebirth") end
	end
})

local function cleanup()
	cfg.autoWalk = false
	cfg.autoWorkers = false
	cfg.autoRoll = false
	cfg.autoBuy = false
	cfg.autoUnlock = false
	cfg.autoRebirth = false
	cfg.antiAfk = false
	cfg.autoUpgrade = false
	for name in pairs(loops) do
		loops[name] = false
	end
	pcall(function() lib.base:Destroy() end)
end

lib:Init()

refreshPlot()

cfg.antiAfk = true
loop("antiAfk", doAntiAfk, 90)