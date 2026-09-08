local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/OMG/refs/heads/main/LOL.lua"))()

local rs = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")

local remote = rs.Paper.Remotes.__remotefunction
local evt = rs.Paper.Remotes.__remoteevent
local eggs = ws.Eggs

local running = {
    eggs = false,
    deposit = false,
    cash = false,
    buy = false,
    merge = false,
    upgrade = false,
    rebirth = false,
}

local loops = {}

local function exec(cmd, amt)
    if amt then
        remote:InvokeServer(cmd, amt)
    else
        remote:InvokeServer(cmd)
    end
end

local function getEggs()
    if #eggs:GetChildren() == 0 then return end
    for _, egg in ipairs(eggs:GetChildren()) do
        pcall(function()
            evt:FireServer("Collect Egg", egg.Name)
            egg:Destroy()
        end)
    end
end

local function deposit()
    pcall(function()
        exec("Deposit Eggs")
    end)
end

local function getcash()
    pcall(function()
        exec("Collect Cash")
    end)
end

local function buychickens()
    pcall(function()
        exec("Buy Chickens", 1)
    end)
end

local function merge()
    pcall(function()
        exec("Merge Chickens")
    end)
end

local function upgrade()
    pcall(function()
        remote:InvokeServer("Upgrade Process Level")
    end)
end

local function birth()
    pcall(function()
        remote:InvokeServer("Rebirth")
    end)
end

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

local ui = lib:CreateWindow("AntiGodHub")

ui:AddToggle({
    text = "Collect Eggs",
    state = false,
    callback = function(s)
        running.eggs = s
        if s then loop("eggs", getEggs, 0.1) else stop("eggs") end
    end
})

ui:AddToggle({
    text = "Deposit Eggs",
    state = false,
    callback = function(s)
        running.deposit = s
        if s then loop("deposit", deposit, 0.1) else stop("deposit") end
    end
})

ui:AddToggle({
    text = "Collect Cash",
    state = false,
    callback = function(s)
        running.cash = s
        if s then loop("cash", getcash, 0.1) else stop("cash") end
    end
})

ui:AddToggle({
    text = "Buy Chickens",
    state = false,
    callback = function(s)
        running.buy = s
        if s then loop("buy", buychickens, 0.1) else stop("buy") end
    end
})

ui:AddToggle({
    text = "Merge Chickens",
    state = false,
    callback = function(s)
        running.merge = s
        if s then loop("merge", merge, 0.1) else stop("merge") end
    end
})

ui:AddToggle({
    text = "Upgrade Cash",
    state = false,
    callback = function(s)
        running.upgrade = s
        if s then loop("upgrade", upgrade, 0.1) else stop("upgrade") end
    end
})

ui:AddToggle({
    text = "Auto Rebirth",
    state = false,
    callback = function(s)
        running.rebirth = s
        if s then loop("rebirth", birth, 0.1) else stop("rebirth") end
    end
})

lib:Init()
