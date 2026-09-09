-- Script Path: game:GetService("ReplicatedStorage").Framework.Features.Upgrades.Upgrades
-- Took 0.01s to decompile.
-- Executor: Delta (1.1.736.1408)

local v1 = game:GetService("ReplicatedStorage")
require(v1.Framework.Features.Buffs.BuffsConfig)
local v2 = require(v1.Framework.Other.Images)
local v3 = {
    ["Start"] = {
        ["image"] = "rbxassetid://134481568703786",
        ["price"] = 0
    }
}
local v4 = {
    ["image"] = nil,
    ["price"] = 250,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money I"] = v4
local v5 = {
    ["image"] = nil,
    ["price"] = 5000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money II"] = v5
local v6 = {
    ["image"] = nil,
    ["price"] = 100000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.35,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money III"] = v6
local v7 = {
    ["image"] = nil,
    ["price"] = 2000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.4,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money IV"] = v7
local v8 = {
    ["image"] = nil,
    ["price"] = 40000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.4,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money V"] = v8
local v9 = {
    ["image"] = nil,
    ["price"] = 800000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money VI"] = v9
local v10 = {
    ["image"] = nil,
    ["price"] = 15000000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money VII"] = v10
local v11 = {
    ["image"] = nil,
    ["price"] = 300000000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money VIII"] = v11
local v12 = {
    ["image"] = nil,
    ["price"] = 6000000000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money IX"] = v12
local v13 = {
    ["image"] = nil,
    ["price"] = 120000000000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.75,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money X"] = v13
local v14 = {
    ["image"] = nil,
    ["price"] = 2500000000000000,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 0.75,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money XI"] = v14
local v15 = {
    ["image"] = nil,
    ["price"] = 5e16,
    ["buffs"] = nil,
    ["image"] = v2.Money,
    ["buffs"] = {
        ["Money Multiplier"] = {
            ["amount"] = 1,
            ["bucket"] = "percentage"
        }
    }
}
v3["Money XII"] = v15
local v16 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 500,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 0.25,
            ["bucket"] = "base"
        }
    }
}
v3["Luck I"] = v16
local v17 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 10000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 0.5,
            ["bucket"] = "base"
        }
    }
}
v3["Luck II"] = v17
local v18 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 200000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 0.5,
            ["bucket"] = "base"
        }
    }
}
v3["Luck III"] = v18
local v19 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 4000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 1,
            ["bucket"] = "base"
        }
    }
}
v3["Luck IV"] = v19
local v20 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 80000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 1,
            ["bucket"] = "base"
        }
    }
}
v3["Luck V"] = v20
local v21 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 1500000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 1,
            ["bucket"] = "base"
        }
    }
}
v3["Luck VI"] = v21
local v22 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 30000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Luck VII"] = v22
local v23 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 600000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Luck VIII"] = v23
local v24 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 12000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Luck IX"] = v24
local v25 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 250000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Luck X"] = v25
local v26 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 5000000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Luck XI"] = v26
local v27 = {
    ["image"] = "rbxassetid://131133222141302",
    ["price"] = 1e17,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 4,
            ["bucket"] = "base"
        }
    }
}
v3["Luck XII"] = v27
local v28 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 1e16,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune I"] = v28
local v29 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 2.5e17,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune II"] = v29
local v30 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 1e18,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune III"] = v30
local v31 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 2e19,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune IV"] = v31
local v32 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 5e20,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 3,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune V"] = v32
local v33 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 1e22,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 4,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune VI"] = v33
local v34 = {
    ["image"] = "rbxassetid://103591109190173",
    ["price"] = 2e23,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Luck"] = {
            ["amount"] = 5,
            ["bucket"] = "base"
        }
    }
}
v3["Fortune VII"] = v34
local v35 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 1000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.2,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage I"] = v35
local v36 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 20000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage II"] = v36
local v37 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 400000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.35,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage III"] = v37
local v38 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 8000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage IV"] = v38
local v39 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 160000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.65,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage V"] = v39
local v40 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 3000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 0.8,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage VI"] = v40
local v41 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 60000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 1,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage VII"] = v41
local v42 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 1200000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 1.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage VIII"] = v42
local v43 = {
    ["image"] = "rbxassetid://133003586374441",
    ["price"] = 25000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Damage Multiplier"] = {
            ["amount"] = 1.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Damage IX"] = v43
local v44 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 1000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed I"] = v44
local v45 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 100000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed II"] = v45
local v46 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 10000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed III"] = v46
local v47 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 1000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed IV"] = v47
local v48 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 100000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed V"] = v48
local v49 = {
    ["image"] = "rbxassetid://134761194266606",
    ["price"] = 1e16,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Roll Duration"] = {
            ["amount"] = -0.15,
            ["bucket"] = "base"
        }
    }
}
v3["Roll Speed VI"] = v49
local v50 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 500000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 0.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell I"] = v50
local v51 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 10000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell II"] = v51
local v52 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 200000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 0.75,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell III"] = v52
local v53 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 4000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 1,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell IV"] = v53
local v54 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 80000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 1.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell V"] = v54
local v55 = {
    ["image"] = "rbxassetid://118330449034393",
    ["price"] = 1500000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Sell Multiplier"] = {
            ["amount"] = 1.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Sell VI"] = v55
local v56 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 2500,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 5,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage I"] = v56
local v57 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 50000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 5,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage II"] = v57
local v58 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 1000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage III"] = v58
local v59 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 20000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage IV"] = v59
local v60 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 400000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage V"] = v60
local v61 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 8000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage VI"] = v61
local v62 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 160000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage VII"] = v62
local v63 = {
    ["image"] = "rbxassetid://81367451806234",
    ["price"] = 3000000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Unit Storage"] = {
            ["amount"] = 10,
            ["bucket"] = "base"
        }
    }
}
v3["Unit Storage VIII"] = v63
local v64 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 1000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.2,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health I"] = v64
local v65 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 20000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health II"] = v65
local v66 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 400000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.35,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health III"] = v66
local v67 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 8000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.5,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health IV"] = v67
local v68 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 160000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.65,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health V"] = v68
local v69 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 3000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 0.8,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health VI"] = v69
local v70 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 60000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 1,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health VII"] = v70
local v71 = {
    ["image"] = "rbxassetid://76695823642344",
    ["price"] = 1200000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Health Multiplier"] = {
            ["amount"] = 1.25,
            ["bucket"] = "percentage"
        }
    }
}
v3["Health VIII"] = v71
local v72 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 250000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed I"] = v72
local v73 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 5000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed II"] = v73
local v74 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 100000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed III"] = v74
local v75 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 2000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed IV"] = v75
local v76 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 40000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed V"] = v76
local v77 = {
    ["image"] = "rbxassetid://112002461760953",
    ["price"] = 800000000000,
    ["buffs"] = nil,
    ["buffs"] = {
        ["Walkspeed"] = {
            ["amount"] = 2,
            ["bucket"] = "base"
        }
    }
}
v3["Walkspeed VI"] = v77
return v3

-- Script Path: game:GetService("ReplicatedStorage").Framework.Features.Upgrades.UpgradeService
-- Took 0.01s to decompile.
-- Executor: Delta (1.1.736.1408)

local v1 = game:GetService("ReplicatedStorage")
local v_u_2 = require(v1.Framework.Features.Data.DataService)
local v_u_3 = require(v1.Framework.Features.Notifications.NotificationService)
local v4 = require(v1.Packages.Network)
local v_u_5 = require(v1.Framework.Features.Upgrades.TreeStructure)
local v_u_6 = require(v1.Framework.Features.Upgrades.Upgrades)
v4.Server.CreateSignal(v1.Network, "BuyUpgrade"):Connect(function(p7, p8)
    -- upvalues: (copy) v_u_6, (copy) v_u_2, (copy) v_u_5, (copy) v_u_3
    local v_u_9 = v_u_6[p8]
    if v_u_9 then
        local v10 = v_u_2[p7]
        if v10.Upgrades[p8]() then
            return
        else
            local v11 = v_u_5.GetParent(p8)
            if v11 and (v11 ~= "Start" and not v10.Upgrades[v11]()) then
                return
            elseif v10.Money() < v_u_9.price then
                v_u_3.SendTextNotification(p7, {
                    ["message"] = "You don\'t have enough money to buy this upgrade!",
                    ["notificationType"] = "error"
                })
            else
                v10.Money(function(p12)
                    -- upvalues: (copy) v_u_9
                    return p12 - v_u_9.price
                end)
                v10.Upgrades[p8](true)
            end
        end
    else
        return
    end
end)
return {}


-- Script Path: game:GetService("ReplicatedStorage").Framework.Features.Upgrades.UpgradeController
-- Took 0.03s to decompile.
-- Executor: Delta (1.1.736.1408)

local v1 = game:GetService("ReplicatedStorage")
local v2 = game:GetService("RunService")
local v3 = game:GetService("UserInputService")
local v4 = v1.Packages
local v_u_5 = require(v1.Framework.Features.Buffs.BuffsConfig)
local v_u_6 = require(v1.Framework.Features.Data.DataController)
local v_u_7 = require(v4.NumberFormatter)
local v_u_8 = require(v1.Framework.Features.UI.HUDController)
local v_u_9 = require(v1.Framework.Features.Upgrades.TreeStructure)
local v_u_10 = require(v1.Framework.Features.UI.TooltipController)
local v_u_11 = require(v1.Framework.Features.UI.UIReferences)
local v12 = require(v1.Framework.Features.UI.Indicator)
local v_u_13 = require(v1.Framework.Features.Upgrades.Upgrades)
local v_u_14 = require(v1.Framework.Features.UI.Components.Button)
local v_u_15 = require(v1.Framework.Other.Images)
local v16 = require(v1.Packages.Network)
local v17 = require(v1.Packages.State)
local v_u_18 = require(v4.Ripple)
local v_u_19 = require(v4.Maid)
local v_u_20 = v1.Assets.UI.Tooltip
local v_u_21 = v_u_11.Root.Upgrades.Screen
local v_u_22 = v_u_21.Template
v_u_22.Visible = false
local _, v23 = v_u_14.init(v_u_11.Root.HUD.Bottom.Upgrades)
local v_u_24 = v12(v_u_11.Root.HUD.Bottom.Upgrades)
local _, v_u_25 = v_u_14.init(v_u_11.Root.Upgrades.Close)
local v_u_26 = v16.Client.GetSignal(v1.Network, "BuyUpgrade")
local v_u_27 = false
local v_u_28 = v_u_19.new()
local v_u_29 = v_u_18.createSpring(1, {
    ["dampingRatio"] = 1,
    ["frequency"] = 1.25,
    ["start"] = true
})
local v_u_30 = {
    ["Open"] = v17.new(v_u_27)
}
local v_u_31 = Vector2.zero
local v_u_32 = false
local v_u_33 = nil
local v_u_34 = Vector2.zero
local v_u_35 = v_u_21.Position
local v_u_36 = v_u_21.Position
local v_u_37 = v_u_21.UIScale.Scale
v_u_21.Active = true
local function v43() -- name: updateIndicator
    -- upvalues: (copy) v_u_6, (copy) v_u_9, (copy) v_u_13, (copy) v_u_24
    local v_u_38 = 0
    local v_u_39 = v_u_6.Money()
    local function v_u_42(p40) -- name: checkChildren
        -- upvalues: (ref) v_u_9, (ref) v_u_6, (copy) v_u_42, (copy) v_u_39, (ref) v_u_13, (ref) v_u_38
        for _, v41 in v_u_9.GetChildren(p40) do
            if v_u_6.Upgrades[v41]() then
                v_u_42(v41)
            elseif v_u_39 >= v_u_13[v41].price then
                v_u_38 = v_u_38 + 1
            end
        end
    end
    v_u_42("Start")
    v_u_24.reset()
    v_u_24.add(v_u_38)
end
local function v78() -- name: openTree
    -- upvalues: (ref) v_u_28, (copy) v_u_19, (copy) v_u_21, (copy) v_u_36, (copy) v_u_37, (copy) v_u_9, (copy) v_u_6, (copy) v_u_13, (copy) v_u_14, (copy) v_u_22, (copy) v_u_7, (copy) v_u_15, (copy) v_u_5, (copy) v_u_20, (copy) v_u_10, (copy) v_u_26, (copy) v_u_18, (copy) v_u_25, (copy) v_u_29, (copy) v_u_11, (copy) v_u_8, (ref) v_u_27, (copy) v_u_30
    v_u_28:Destroy()
    v_u_28 = v_u_19.new()
    v_u_21.Position = v_u_36
    v_u_21.UIScale.Scale = v_u_37
    local v_u_44 = {}
    local function v_u_77() -- name: refreshTree
        -- upvalues: (ref) v_u_9, (ref) v_u_6, (ref) v_u_13, (copy) v_u_44, (ref) v_u_14, (ref) v_u_22, (ref) v_u_7, (ref) v_u_15, (ref) v_u_21, (ref) v_u_5, (ref) v_u_20, (ref) v_u_28, (ref) v_u_10, (ref) v_u_26, (copy) v_u_77, (ref) v_u_18
        local v_u_45 = {
            ["Start"] = "Owned"
        }
        local function v_u_49(p46) -- name: revealChildren
            -- upvalues: (ref) v_u_9, (ref) v_u_6, (copy) v_u_45, (copy) v_u_49
            for _, v47 in v_u_9.GetChildren(p46) do
                if v_u_6.Upgrades[v47]() then
                    v_u_45[v47] = "Owned"
                    v_u_49(v47)
                else
                    v_u_45[v47] = "Available"
                    for _, v48 in v_u_9.GetChildren(v47) do
                        v_u_45[v48] = v_u_45[v48] or "Preview"
                    end
                end
            end
        end
        v_u_49("Start")
        for v_u_50, v51 in v_u_45 do
            local v_u_52 = v_u_13[v_u_50]
            local v_u_53 = v_u_44[v_u_50]
            if v_u_53 == nil then
                local v54, v55 = v_u_9.GetPosition(v_u_50, UDim2.fromScale(0.5, 0.5))
                if v54 then
                    local _, v_u_56 = v_u_14.init(v_u_22:Clone())
                    local v57 = v_u_56.Tile
                    v57.TextLabel.Text = v_u_50
                    v57.Price.TextLabel.Text = v_u_7.FormatCompact(v_u_52.price, 1)
                    v57.Price.ImageLabel.Image = v_u_15.Money
                    v_u_56.Position = v54
                    v_u_56.Interactable = true
                    v_u_56.Active = true
                    v_u_56.Visible = true
                    v_u_56.Parent = v_u_21
                    if v_u_52.buffs then
                        local v58 = {}
                        for v59, v60 in v_u_52.buffs do
                            local v61 = v_u_5.GetBuff(v59)
                            local v62 = v_u_20.buff:Clone()
                            v62.ImageLabel.Image = v61.image or v_u_52.image
                            v62.Title.Text = v_u_5.FormatAmount(v59, v60.bucket, v60.amount)
                            local v63 = v_u_20.Title:Clone()
                            v63.TextXAlignment = Enum.TextXAlignment.Center
                            v63.Text = v_u_50
                            table.insert(v58, v63)
                            local v64 = v_u_20.padding
                            table.insert(v58, v64:Clone())
                            table.insert(v58, v62)
                        end
                        v_u_28:Add(v_u_10.bind(v_u_56, {
                            ["elements"] = v58
                        }))
                    end
                    v_u_53 = {
                        ["template"] = nil,
                        ["tile"] = nil,
                        ["state"] = nil,
                        ["priceConn"] = nil,
                        ["template"] = v_u_56,
                        ["tile"] = v57,
                        ["state"] = v51
                    }
                    v_u_44[v_u_50] = v_u_53
                    v_u_56.Activated:Connect(function()
                        -- upvalues: (ref) v_u_53, (ref) v_u_26, (copy) v_u_50
                        if v_u_53.state == "Available" then
                            v_u_26:Fire(v_u_50)
                        end
                    end)
                    if v_u_50 ~= "Start" then
                        v_u_28:Add(v_u_6.Upgrades[v_u_50].Changed(v_u_77))
                    end
                    v_u_28:Add(function()
                        -- upvalues: (ref) v_u_53
                        if v_u_53.priceConn then
                            v_u_53.priceConn()
                        end
                    end)
                    v_u_28:Add(v_u_56)
                    v_u_56.UIScale.Scale = 0
                    local v65 = v_u_18.createSpring(0, {
                        ["frequency"] = nil,
                        ["dampingRatio"] = 0.65,
                        ["start"] = true,
                        ["frequency"] = 3.5 / (v55 + 1)
                    })
                    v_u_28:Add(v65:onChange(function(p66)
                        -- upvalues: (copy) v_u_56
                        v_u_56.UIScale.Scale = p66
                    end))
                    v_u_28:Add(v65:onComplete(function(p67)
                        -- upvalues: (ref) v_u_53, (copy) v_u_56
                        if p67 == 1 and v_u_53.state == "Available" then
                            v_u_56.Interactable = true
                        end
                    end))
                    v_u_28:Add(v65)
                    v65:setGoal(1)
                    goto l7
                end
            else
                ::l7::
                local v68 = v_u_53.template
                local v_u_69 = v_u_53.tile
                v_u_53.state = v51
                v68.Interactable = true
                if v_u_53.priceConn then
                    v_u_53.priceConn()
                    v_u_53.priceConn = nil
                end
                v_u_69.ImageLabel.Image = v_u_52.image
                v_u_69.TextLabel.Visible = true
                if v51 == "Owned" then
                    v_u_69.Image = "rbxassetid://121829442861416"
                    v_u_69.Price.Visible = false
                elseif v51 == "Available" then
                    v_u_69.Image = "rbxassetid://118987660331960"
                    v_u_69.Price.Visible = true
                    local function v73() -- name: updPrice
                        -- upvalues: (ref) v_u_6, (copy) v_u_69, (copy) v_u_52
                        local v70 = v_u_6.Money()
                        local v71 = v_u_69.Price.TextLabel
                        local v72
                        if v_u_52.price <= v70 then
                            v72 = Color3.fromRGB(78, 255, 78)
                        else
                            v72 = Color3.fromRGB(255, 76, 76)
                        end
                        v71.TextColor3 = v72
                    end
                    v_u_53.priceConn = v_u_6.Money.Changed(v73)
                    local v74 = v_u_6.Money()
                    local v75 = v_u_69.Price.TextLabel
                    local v76
                    if v_u_52.price <= v74 then
                        v76 = Color3.fromRGB(78, 255, 78)
                    else
                        v76 = Color3.fromRGB(255, 76, 76)
                    end
                    v75.TextColor3 = v76
                else
                    v_u_69.Image = "rbxassetid://118987660331960"
                    v_u_69.ImageLabel.Image = "rbxassetid://77741969834251"
                    v_u_69.TextLabel.Visible = false
                    v68.Interactable = false
                    v_u_69.Price.Visible = false
                end
            end
        end
    end
    v_u_77()
    v_u_21.Visible = true
    v_u_25.Visible = true
    v_u_29:setGoal(0.3)
    v_u_11.Root.Upgrades.DarkBackground.Visible = true
    v_u_8.hideAll("tree", {
        ["noAnimation"] = true
    })
    v_u_27 = true
    v_u_30.Open(true)
end
local function v79() -- name: closeTree
    -- upvalues: (ref) v_u_32, (ref) v_u_33, (ref) v_u_31, (ref) v_u_28, (copy) v_u_29, (copy) v_u_8, (copy) v_u_21, (copy) v_u_25, (ref) v_u_27, (copy) v_u_30
    v_u_32 = false
    v_u_33 = nil
    v_u_31 = Vector2.zero
    v_u_28:Destroy()
    v_u_29:setGoal(1)
    v_u_8.showAll("tree")
    v_u_21.Visible = false
    v_u_25.Visible = false
    v_u_27 = false
    v_u_30.Open(false)
end
v_u_21.InputBegan:Connect(function(p80)
    -- upvalues: (ref) v_u_27, (ref) v_u_32, (ref) v_u_33, (ref) v_u_34, (ref) v_u_35, (copy) v_u_21
    if v_u_27 then
        if p80.UserInputType == Enum.UserInputType.MouseButton1 or p80.UserInputType == Enum.UserInputType.Touch then
            v_u_32 = true
            v_u_33 = p80
            v_u_34 = Vector2.new(p80.Position.X, p80.Position.Y)
            v_u_35 = v_u_21.Position
        end
    else
        return
    end
end)
v3.InputChanged:Connect(function(p81)
    -- upvalues: (ref) v_u_31, (ref) v_u_27, (ref) v_u_32, (ref) v_u_33, (ref) v_u_34, (copy) v_u_21, (ref) v_u_35
    if p81.KeyCode == Enum.KeyCode.Thumbstick2 then
        local v82 = Vector2.new(p81.Position.X, -p81.Position.Y)
        if v82.Magnitude < 0.15 then
            v82 = Vector2.zero
        end
        v_u_31 = v82
    end
    if v_u_27 then
        if v_u_32 then
            local v83 = p81.UserInputType == Enum.UserInputType.MouseMovement
            local v84
            if p81.UserInputType == Enum.UserInputType.Touch then
                v84 = p81 == v_u_33
            else
                v84 = false
            end
            if v83 or v84 then
                local v85 = Vector2.new(p81.Position.X, p81.Position.Y) - v_u_34
                v_u_21.Position = v_u_35 + UDim2.fromOffset(v85.X, v85.Y)
            end
        end
        if p81.UserInputType == Enum.UserInputType.MouseWheel then
            local v86 = v_u_21.UIScale.Scale * 1.1 ^ p81.Position.Z
            v_u_21.UIScale.Scale = math.clamp(v86, 0.5, 1.75)
        end
    end
end)
v3.InputBegan:Connect(function(p87)
    -- upvalues: (ref) v_u_27, (copy) v_u_21
    if v_u_27 then
        if p87.KeyCode == Enum.KeyCode.ButtonR1 then
            local v88 = v_u_21.UIScale
            local v89 = v_u_21.UIScale.Scale * 1.1
            v88.Scale = math.clamp(v89, 0.5, 1.75)
        elseif p87.KeyCode == Enum.KeyCode.ButtonL1 then
            local v90 = v_u_21.UIScale
            local v91 = v_u_21.UIScale.Scale / 1.1
            v90.Scale = math.clamp(v91, 0.5, 1.75)
        end
    else
        return
    end
end)
v2.RenderStepped:Connect(function(p92)
    -- upvalues: (ref) v_u_27, (ref) v_u_31, (copy) v_u_21
    if v_u_27 and v_u_31 ~= Vector2.zero then
        local v93 = v_u_21
        v93.Position = v93.Position + UDim2.fromOffset(v_u_31.X * 650 * p92, v_u_31.Y * 650 * p92)
    end
end)
v3.InputEnded:Connect(function(p94)
    -- upvalues: (ref) v_u_33, (ref) v_u_32
    local v95 = p94.UserInputType == Enum.UserInputType.MouseButton1
    local v96
    if p94.UserInputType == Enum.UserInputType.Touch then
        v96 = p94 == v_u_33
    else
        v96 = false
    end
    if v95 or v96 then
        v_u_32 = false
        v_u_33 = nil
    end
end)
v_u_29:onChange(function(p97)
    -- upvalues: (copy) v_u_11
    v_u_11.Root.Upgrades.DarkBackground.Transparency = p97
end)
v23.Activated:Connect(v78)
v_u_25.Activated:Connect(v79)
v_u_6.Money.Changed(v43)
v_u_6.Upgrades.Observe(v43)
local v_u_98 = 0
local v_u_99 = v_u_6.Money()
local function v_u_102(p100) -- name: checkChildren
    -- upvalues: (copy) v_u_9, (copy) v_u_6, (copy) v_u_102, (copy) v_u_99, (copy) v_u_13, (ref) v_u_98
    for _, v101 in v_u_9.GetChildren(p100) do
        if v_u_6.Upgrades[v101]() then
            v_u_102(v101)
        elseif v_u_99 >= v_u_13[v101].price then
            v_u_98 = v_u_98 + 1
        end
    end
end
v_u_102("Start")
v_u_24.reset()
v_u_24.add(v_u_98)
return v_u_30
