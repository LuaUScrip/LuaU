-- Load Obsidian GUI Library
local LibraryURL = "https://raw.githubusercontent.com/yudhiprb1-afk/LIB/refs/heads/main/Library.lua"
local Library = loadstring(game:HttpGet(LibraryURL))()

if not Library then
    warn("ERROR: Failed to load library")
    return
end

-- Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Track character respawn
Player.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Lucky Blocks List
local LuckyBlocksList = {
    "OG Lucky Block",
    "Champions Lucky Block",
    "Spain Lucky Block",
    "Icons Lucky Block",
    "Japan Lucky Block",
}

-- Configuration
local Config = {
    HomePosition = Vector3.new(198, 3, 280),
    SelectedLuckyBlock = {},
    FarmActive = false,
    BuyUpgradesActive = false,
    BuySelectedUpgradesActive = false,
    UpgradeFloorsActive = false,
    UpgradeSoccerActive = false,
    SoccerSlots = {},
    OpenActive = false,
    CollectActive = false,
    RebirthActive = false,
    SellAllActive = false,
    BuyGearActive = false,
    BuyAllGearActive = false,
    SelectedGears = {},
    SelectedUpgrades = {},
    FontPreset = "White + Emerald",
    AutoSave = false,
    AutoExecute = false,
    AutoReconnect = false,
    AutoHideUi = false,
    AntiAfk = false,
    NoGameplayPaused = false,
    ThemeName = "Emerald Green",
    FontName = "Cartoon",
    MenuBind = "G",
    CustomColors = {
        AccentColor = Color3.fromRGB(96, 216, 118),
        FontColor = Color3.fromRGB(255, 255, 255),
        BackgroundColor = Color3.fromRGB(8, 16, 10),
        MainColor = Color3.fromRGB(16, 28, 20),
        OutlineColor = Color3.fromRGB(30, 58, 40),
    },
    -- Social links (edit these!)
    DiscordLink = "https://discord.gg/jdJvZm6VdK",
    YouTubeLink = "https://youtube.com/@antigodhub",
    TikTokLink = "https://tiktok.com/@antigodhub",
}

local SettingsRefs = {}
local SuppressUI = false

-- Helper: Copy text to clipboard (executor-safe)
local function CopyToClipboard(Text)
    local Success = pcall(setclipboard, Text)
    if not Success then
        Success = pcall(toclipboard, Text)
    end
    return Success
end

-- Notification text colors (green like the Status values)
local NotifyColors = {
    Success = Color3.fromRGB(96, 216, 118),
    Warning = Color3.fromRGB(255, 176, 80),
    Error = Color3.fromRGB(255, 96, 96),
}

-- Helper: Show a notification (simple, single-line style)
local function Notify(Title, Description, Type)
    pcall(function()
        if type(Title) == "string" and #Title > 60 then
            Title = Title:sub(1, 57) .. "..."
        end
        if Description == nil or Description == "" then
            Description = " " -- placeholder so the card stays a single line
        elseif type(Description) == "string" and #Description > 60 then
            Description = Description:sub(1, 57) .. "..."
        end
        Type = Type or "Info"
        Library:Notify({
            Title = Title,
            Description = Description,
            Time = 4,
            Type = Type,
            DescriptionColor = NotifyColors[Type],
        })
    end)
end

-- Helper: Get Lucky Block by name
local function GetLuckyBlock(BlockName)
    local success, result = pcall(function()
        return Workspace.Live.Slimes[BlockName].RootPart
    end)
    return success and result or nil
end

-- Helper: Get selected Lucky Block
local function GetSelectedLuckyBlock()
    return GetLuckyBlock(Config.SelectedLuckyBlock)
end

-- Helper: Teleport with safety
local function Teleport(Position)
    if not HumanoidRootPart or not HumanoidRootPart.Parent then
        return false
    end

    local safePos = Position + Vector3.new(0, 3, 0)
    HumanoidRootPart.CFrame = CFrame.new(safePos)
    RunService.RenderStepped:Wait()
    return true
end

-- Helper: Fire proximity prompt safely
local function FirePrompt(Prompt)
    if not Prompt then return false end

    pcall(function()
        Prompt.HoldDuration = 0
        RunService.RenderStepped:Wait()
        fireproximityprompt(Prompt)
    end)
    return true
end

-- FARM FUNCTION: Teleport -> Fire -> Teleport Back
local function FarmLuckyBlock()
    if not HumanoidRootPart or not HumanoidRootPart.Parent then
        return
    end

    pcall(function()
        -- Farm all selected lucky blocks
        for _, BlockName in Config.SelectedLuckyBlock do
            local LuckyBlock = GetLuckyBlock(BlockName)
            if LuckyBlock then
                -- Teleport to block
                Teleport(LuckyBlock.Position)
                RunService.RenderStepped:Wait(2)

                -- Fire proximity prompt
                local Prompt = LuckyBlock:FindFirstChild("StealPrompt")
                if Prompt then
                    FirePrompt(Prompt)
                end

                RunService.RenderStepped:Wait(0.3)
            end
        end

        -- Teleport back home
        Teleport(Config.HomePosition)
    end)
end

-- UPGRADE: Buy Jump
local function BuyJumpUpgrade()
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Buy Speed Upgrade")
        Event:FireServer(3)
    end)
end

-- UPGRADE: Buy Carry
local function BuyCarryUpgrade()
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Upgrade Carry Limit")
        Event:FireServer()
    end)
end

-- Per-session purchase tracking (stops the "You already own this." spam
-- from re-buying owned items every cycle)
local GearAttempted = {}
local FloorAttempted = {}
local function ResetPurchaseTracking()
    GearAttempted = {}
    FloorAttempted = {}
end

-- GEAR: Buy Gear (skips gears already attempted this session)
local function BuyGear(GearId)
    if GearAttempted[GearId] then
        return
    end
    GearAttempted[GearId] = true
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Buy Gear")
        Event:FireServer(tostring(GearId), "Buy")
    end)
end

-- UPGRADE: Buy all upgrades (jump + carry)
local function BuyAllUpgrades()
    BuyJumpUpgrade()
    RunService.RenderStepped:Wait(0.1)
    BuyCarryUpgrade()
end

-- UPGRADE: Buy only the upgrades selected in the dropdown
local function BuySelectedUpgrades()
    for _, Upgrade in Config.SelectedUpgrades do
        if Upgrade == "Jump" then
            BuyJumpUpgrade()
        elseif Upgrade == "Carry" then
            BuyCarryUpgrade()
        end
        RunService.RenderStepped:Wait(0.1)
    end
end

-- GEAR: Buy a list of gears
local function BuyGearList(GearIds)
    for _, GearId in GearIds do
        BuyGear(GearId)
        RunService.RenderStepped:Wait(0.5)
    end
end

-- UPGRADE: Buy a floor (10-70, skips floors already attempted this session)
local function UpgradeFloor(FloorId)
    if FloorAttempted[FloorId] then
        return
    end
    FloorAttempted[FloorId] = true
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Purchase Floor")
        Event:InvokeServer(FloorId)
    end)
end

-- UPGRADE: Upgrade a soccer/slime slot (1-70)
local function UpgradeSoccerSlot(SlotId)
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Upgrade Slime")
        Event:FireServer(tostring(SlotId))
    end)
end

-- REBIRTH: fire the Rebirth remote
local function DoRebirth()
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Rebirth")
        Event:FireServer()
    end)
end

-- BLOCKS: Open Lucky Blocks
local function OpenLuckyBlocks(Count)
    for i = 1, Count do
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Open Lucky Block")
            Event:FireServer(tostring(i))
            RunService.RenderStepped:Wait(1)
        end)
    end
end

-- CASH: Collect Earnings
local function CollectEarnings(Count)
    for i = 1, Count do
        pcall(function()
            local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Collect Earnings")
            Event:FireServer(tostring(i))
            RunService.RenderStepped:Wait(1)
        end)
    end
end

-- CASH: Sell All
local function SellAllSlimes()
    pcall(function()
        local Event = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Network"):WaitForChild("Remotes"):WaitForChild("Sell All Slimes")
        Event:FireServer()
    end)
end

-- THEME MANAGER
local function MakeTheme(Accent, Background, Main, Outline, Font)
    return {
        AccentColor = Accent,
        BackgroundColor = Background,
        MainColor = Main,
        OutlineColor = Outline,
        FontColor = Font,
    }
end

local Themes = {
    ["Obsidian (Default)"] = MakeTheme(
        Color3.fromRGB(125, 85, 255),
        Color3.fromRGB(15, 15, 15),
        Color3.fromRGB(25, 25, 25),
        Color3.fromRGB(40, 40, 40),
        Color3.fromRGB(255, 255, 255)
    ),
    ["Midnight Blue"] = MakeTheme(
        Color3.fromRGB(96, 165, 255),
        Color3.fromRGB(8, 10, 16),
        Color3.fromRGB(18, 22, 32),
        Color3.fromRGB(38, 46, 64),
        Color3.fromRGB(255, 255, 255)
    ),
    ["Blood Red"] = MakeTheme(
        Color3.fromRGB(255, 76, 76),
        Color3.fromRGB(16, 8, 8),
        Color3.fromRGB(28, 14, 14),
        Color3.fromRGB(64, 30, 30),
        Color3.fromRGB(255, 255, 255)
    ),
    ["Emerald Green"] = MakeTheme(
        Color3.fromRGB(96, 216, 118),
        Color3.fromRGB(8, 16, 10),
        Color3.fromRGB(16, 28, 20),
        Color3.fromRGB(30, 58, 40),
        Color3.fromRGB(255, 255, 255)
    ),
    ["Sunset Orange"] = MakeTheme(
        Color3.fromRGB(255, 148, 60),
        Color3.fromRGB(18, 12, 8),
        Color3.fromRGB(32, 22, 12),
        Color3.fromRGB(64, 46, 26),
        Color3.fromRGB(255, 255, 255)
    ),
}

local ThemeNames = {}
for Name in Themes do
    table.insert(ThemeNames, Name)
end

local function CloneColors(Scheme)
    local Clone = {}
    for Key, Value in Scheme do
        Clone[Key] = Value
    end
    return Clone
end

local function ApplyTheme(Scheme)
    for Key, Value in Scheme do
        if Library.Scheme[Key] ~= nil then
            Library.Scheme[Key] = Value
        end
    end
    Library:UpdateColorsUsingRegistry()
end

local function ApplyColorOverride(Key, Color)
    if Library.Scheme[Key] ~= nil then
        Library.Scheme[Key] = Color
        Library:UpdateColorsUsingRegistry()
    end
end

local function ApplyCustomColors()
    for Key, Color in Config.CustomColors do
        ApplyColorOverride(Key, Color)
    end
end

-- Fonts
local FontNames = {
    "Code", "Gotham", "Roboto", "Cartoon", "Arial",
    "SourceSans", "FredokaOne", "SpaceGrotesk", "Montserrat", "TitilliumWeb", "Nunito",
}

-- Font Color Presets (10 combos that look good on Emerald Green)
local FontPresets = {
    { Name = "White + Emerald", Accent = Color3.fromRGB(96, 216, 118) },
    { Name = "White + Sky Blue", Accent = Color3.fromRGB(79, 195, 247) },
    { Name = "White + Gold", Accent = Color3.fromRGB(255, 213, 79) },
    { Name = "White + Rose", Accent = Color3.fromRGB(255, 107, 107) },
    { Name = "White + Violet", Accent = Color3.fromRGB(179, 136, 255) },
    { Name = "White + Teal", Accent = Color3.fromRGB(77, 208, 196) },
    { Name = "White + Coral", Accent = Color3.fromRGB(255, 138, 101) },
    { Name = "White + Lavender", Accent = Color3.fromRGB(206, 147, 216) },
    { Name = "White + Cyan", Accent = Color3.fromRGB(77, 208, 225) },
    { Name = "White + Lime", Accent = Color3.fromRGB(174, 213, 129) },
}
local FontPresetNames = {}
for _, Preset in FontPresets do
    table.insert(FontPresetNames, Preset.Name)
end

-- Soccer slot options (Soccer 1 .. Soccer 70)
local SoccerSlotOptions = {}
for i = 1, 70 do
    table.insert(SoccerSlotOptions, "Soccer " .. i)
end

-- CONFIG SAVE / LOAD (named configs)
local ConfigsDir = "LuckyBlocksFarm/Configs"
local AutoloadPath = "LuckyBlocksFarm/Autoload.json"
local CurrentConfig = nil -- name of the config currently selected

local function SanitizeConfigName(Name)
    if type(Name) ~= "string" then
        return nil
    end
    local Clean = Name:gsub("[^%w _%-%.]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    if Clean == "" or Clean == "---" then
        return nil
    end
    return Clean
end

local function ConfigPath(Name)
    return ConfigsDir .. "/" .. Name .. ".json"
end

local function GetConfigList()
    local List = {}
    if not listfiles then
        return List
    end
    pcall(function()
        makefolder("LuckyBlocksFarm")
        makefolder(ConfigsDir)
        for _, Path in listfiles(ConfigsDir) do
            if Path:sub(-5) == ".json" then
                local Name = Path:match("([^/\\]+)%.json$")
                if Name and Name ~= "---" then
                    table.insert(List, Name)
                end
            end
        end
    end)
    table.sort(List)
    return List
end

local function ConfigExists(Name)
    Name = SanitizeConfigName(Name)
    if not Name or not isfile then
        return false
    end
    return isfile(ConfigPath(Name))
end

local function SaveConfigData(Name)
    if not writefile then
        return false
    end
    Name = SanitizeConfigName(Name)
    if not Name then
        return false
    end
    pcall(function()
        makefolder("LuckyBlocksFarm")
        makefolder(ConfigsDir)
        local Data = {
            Toggles = {},
            ThemeName = Config.ThemeName,
            FontName = Config.FontName,
            FontPreset = Config.FontPreset,
            MenuBind = Config.MenuBind,
            SelectedLuckyBlock = Config.SelectedLuckyBlock or {},
            SelectedUpgrades = Config.SelectedUpgrades or {},
            SelectedGears = Config.SelectedGears or {},
            SoccerSlots = Config.SoccerSlots or {},
            Colors = {},
        }
        for Key, Color in Config.CustomColors do
            Data.Colors[Key] = {
                math.floor(Color.R * 255),
                math.floor(Color.G * 255),
                math.floor(Color.B * 255),
            }
        end
        for Id, Toggle in Library.Toggles do
            Data.Toggles[Id] = Toggle.Value
        end
        writefile(ConfigPath(Name), HttpService:JSONEncode(Data))
    end)
    return true
end

-- Autoload helpers
local function GetAutoloadName()
    if not isfile or not readfile then
        return nil
    end
    if not isfile(AutoloadPath) then
        return nil
    end
    local Success, Data = pcall(function()
        return HttpService:JSONDecode(readfile(AutoloadPath))
    end)
    if Success and type(Data) == "table" and type(Data.Name) == "string" then
        return SanitizeConfigName(Data.Name)
    end
    return nil
end

local function SetAutoload(Name)
    if not writefile then
        return false
    end
    Name = SanitizeConfigName(Name)
    if not Name then
        return false
    end
    pcall(function()
        makefolder("LuckyBlocksFarm")
        writefile(AutoloadPath, HttpService:JSONEncode({ Name = Name }))
    end)
    return true
end

local function ClearAutoload()
    pcall(function()
        if isfile and isfile(AutoloadPath) then
            delfile(AutoloadPath)
        end
    end)
    return true
end

local LoadConfig
local SaveQueued = false
local function ScheduleSave()
    if not Config.AutoSave then
        return
    end
    if not CurrentConfig then
        return
    end
    if SaveQueued then
        return
    end
    SaveQueued = true
    task.delay(1, function()
        SaveQueued = false
        SaveConfigData(CurrentConfig)
    end)
end

local function SyncColorPickers()
    local PickerMap = {
        AccentColor = "ThemeAccent",
        FontColor = "ThemeFontColor",
        BackgroundColor = "ThemeBackground",
        MainColor = "ThemeMain",
        OutlineColor = "ThemeOutline",
    }
    for Key, Idx in PickerMap do
        local Picker = Library.Options[Idx]
        if Picker and Picker.SetValueRGB then
            Picker:SetValueRGB(Config.CustomColors[Key])
        end
    end
end

LoadConfig = function(Name, Silent)
    Name = SanitizeConfigName(Name)
    if not Name then
        return false
    end
    if not isfile or not readfile then
        if not Silent then
            Notify("Config", "Config loading not supported on this executor", "Error")
        end
        return false
    end
    if not isfile(ConfigPath(Name)) then
        if not Silent then
            Notify("Config", "Config '" .. Name .. "' not found", "Warning")
        end
        return false
    end

    local Success, Data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigPath(Name)))
    end)
    if not Success or type(Data) ~= "table" then
        if not Silent then
            Notify("Config", "Failed to read configuration", "Error")
        end
        return false
    end

    SuppressUI = true

    -- Theme
    if type(Data.ThemeName) == "string" and Themes[Data.ThemeName] then
        Config.ThemeName = Data.ThemeName
        ApplyTheme(Themes[Data.ThemeName])
    end

    -- Custom colors
    if type(Data.Colors) == "table" then
        for Key, RGB in Data.Colors do
            if Config.CustomColors[Key] ~= nil and type(RGB) == "table" then
                local R, G, B = RGB[1], RGB[2], RGB[3]
                if type(R) == "number" and type(G) == "number" and type(B) == "number" then
                    Config.CustomColors[Key] = Color3.fromRGB(R, G, B)
                end
            end
        end
        ApplyCustomColors()
    end

    -- Font
    if type(Data.FontName) == "string" and Enum.Font[Data.FontName] then
        Config.FontName = Data.FontName
        Library:SetFont(Enum.Font[Data.FontName])
    end

    -- Font preset
    if type(Data.FontPreset) == "string" then
        for _, Preset in FontPresets do
            if Preset.Name == Data.FontPreset then
                Config.FontPreset = Preset.Name
                break
            end
        end
    end

    -- Menu bind
    if type(Data.MenuBind) == "string" and Data.MenuBind ~= "None" then
        Config.MenuBind = Data.MenuBind
    end

    -- Selected Lucky Blocks (multi-select)
    if type(Data.SelectedLuckyBlock) == "table" then
        local Valid = {}
        for _, Block in Data.SelectedLuckyBlock do
            if table.find(LuckyBlocksList, Block) then
                table.insert(Valid, Block)
            end
        end
        Config.SelectedLuckyBlock = Valid
    end

    -- Selected Upgrades (multi-select)
    if type(Data.SelectedUpgrades) == "table" then
        Config.SelectedUpgrades = Data.SelectedUpgrades
    end

    -- Selected Gears (multi-select)
    if type(Data.SelectedGears) == "table" then
        Config.SelectedGears = Data.SelectedGears
    end

    -- Soccer slots (multi-select)
    if type(Data.SoccerSlots) == "table" then
        local Valid = {}
        for _, Opt in Data.SoccerSlots do
            if table.find(SoccerSlotOptions, Opt) then
                table.insert(Valid, Opt)
            end
        end
        Config.SoccerSlots = Valid
    end

    -- Toggles (fires each toggle's callback, starting its loop if enabled)
    if type(Data.Toggles) == "table" then
        for Id, Value in Data.Toggles do
            local Toggle = Library.Toggles[Id]
            if Toggle and type(Value) == "boolean" then
                Toggle:SetValue(Value)
            end
        end
    end

    -- Sync UI elements
    if SettingsRefs.ThemeDropdown then
        SettingsRefs.ThemeDropdown:SetValue(Config.ThemeName)
    end
    if SettingsRefs.FontDropdown then
        SettingsRefs.FontDropdown:SetValue(Config.FontName)
    end
    if SettingsRefs.FontPresetDropdown then
        SettingsRefs.FontPresetDropdown:SetValue(Config.FontPreset)
    end
    if SettingsRefs.LuckyBlockDropdown then
        SettingsRefs.LuckyBlockDropdown:SetValue(Config.SelectedLuckyBlock or {})
    end
    SyncColorPickers()
    if SettingsRefs.MenuBindPicker then
        SettingsRefs.MenuBindPicker:SetValue({ Config.MenuBind, "Press" })
    end
    if SettingsRefs.SoccerSlotDropdown then
        SettingsRefs.SoccerSlotDropdown:SetValue(Config.SoccerSlots or {})
    end
    if SettingsRefs.UpgradeDropdown then
        SettingsRefs.UpgradeDropdown:SetValue(Config.SelectedUpgrades or {})
    end
    if SettingsRefs.GearDropdown then
        SettingsRefs.GearDropdown:SetValue(Config.SelectedGears or {})
    end

    SuppressUI = false

    CurrentConfig = Name
    return true
end

-- Helper: toggle with optional notification + auto-save
local function AddFeatureToggle(Box, Id, Info, OnToggle)
    return Box:AddToggle(Id, {
        Text = Info.Text,
        Default = false,
        Tooltip = Info.Tooltip,
        Callback = function(Value)
            if OnToggle then
                OnToggle(Value)
            end
            -- Only notify for real features (Info.Notify), and never while loading a config
            -- Simple one-line style: "Auto Farm On" / "Auto Farm Off"
            if Info.Notify and not SuppressUI then
                Notify(Info.Text .. " " .. (Value and "On" or "Off"), "", Value and "Success" or "Warning")
            end
            ScheduleSave()
        end,
    })
end

-- AUTO FEATURES
local function RunAutoExecute()
    task.delay(3, function()
        if Config.AutoExecute then
            local AutoFarm = Library.Toggles.AutoFarm
            if AutoFarm and not AutoFarm.Value then
                AutoFarm:SetValue(true)
            end
        end
    end)
end

local function AutoReconnectLoop()
    task.spawn(function()
        while Config.AutoReconnect do
            task.wait(0.5)
            pcall(function()
                local RobloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
                local DFrame = RobloxGui and RobloxGui:FindFirstChild("DisconnectedFrame")
                if DFrame and DFrame.Visible then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                end
            end)
        end
    end)
end

local function AutoHideUiLoop()
    task.spawn(function()
        local OpenFor = 0
        while Config.AutoHideUi do
            task.wait(1)
            if Library.Toggled then
                OpenFor = OpenFor + 1
                if OpenFor >= 30 then
                    Library:Toggle(false)
                    OpenFor = 0
                end
            else
                OpenFor = 0
            end
        end
    end)
end

local function AntiAfkLoop()
    task.spawn(function()
        while Config.AntiAfk do
            task.wait(600)
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end

local function NoPauseLoop()
    task.spawn(function()
        while Config.NoGameplayPaused do
            task.wait(20)
            pcall(function()
                local Char = Player.Character
                local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
                if HRP then
                    HRP.AssemblyLinearVelocity = HRP.AssemblyLinearVelocity + Vector3.new(0, 1.5, 0)
                end
            end)
        end
    end)
end

-- Anti AFK also answers Roblox's idle kick prompt
Players.LocalPlayer.Idled:Connect(function()
    if Config.AntiAfk then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

-- Create Main Window
local Window = Library:CreateWindow({
    Title = "AntiGodHub",
    Icon = 125265885440515,
    Footer = {
        { Text = "Discord", Copyable = true, OnClick = function() CopyToClipboard(Config.DiscordLink) end },
        { Text = " | " },
        { Text = "AntiGodHub", Copyable = true },
    },
    CornerRadius = 20,
    AutoShow = true,
    ShowMobileButtons = false, -- keep the library from adding its own Toggle/Lock pair (mobile) so only ours shows
    Minimizable = true,
    Resizable = true,
    Animations = {
        ToggleWindow = true,
        TabSwitch = true,
        Groupbox = true,
        Dropdown = true,
    },
})

-- The Menu Bind keypicker below handles toggling, so disable the library's built-in
-- bind. Important: nil (not Enum.KeyCode.None) - None matches every mouse click
-- because Input.KeyCode is None for non-keyboard inputs, which would make any
-- click toggle the window open/closed.
Library.ToggleKeybind = nil

-- Floating Toggle + Lock buttons
local ToggleButton = Library:AddDraggableButton("Toggle", function()
    Library:Toggle()
end, true, true)

local LockButton = Library:AddDraggableButton("Lock", function(self)
    Library.CantDragForced = not Library.CantDragForced
    self:SetText(Library.CantDragForced and "Unlock" or "Lock")
end, true, true)

ToggleButton.Button.AnchorPoint = Vector2.new(0, 0)
ToggleButton.Button.Position = UDim2.fromOffset(6, 6)
LockButton.Button.AnchorPoint = Vector2.new(0, 0)
LockButton.Button.Position = UDim2.fromOffset(ToggleButton.Button.Size.X.Offset + 12, 6)

-- Create Tabs
local Tabs = {
    Info = Window:AddTab({ Name = "Info", Icon = "info" }),
    Main = Window:AddTab({ Name = "Main", Icon = "house" }),
    Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

-- Main sub-tabs
local MainTabs = {
    Eggs = Tabs.Main:AddSubTab({ Name = "Farming", Icon = "star" }),
    Slimes = Tabs.Main:AddSubTab({ Name = "Upgrade", Icon = "trending-up" }),
    Shop = Tabs.Main:AddSubTab({ Name = "Shop", Icon = "shopping-cart" }),
}

-- INFO TAB
local StatusBox = Tabs.Info:AddLeftGroupbox("Status", "user")

StatusBox:AddLabel({ Text = 'USER - <font color="#60d888">' .. Player.Name .. '</font>' })
StatusBox:AddLabel({ Text = 'STATUS - <font color="#60d888">Keyless</font>' })

-- Executor name + version (simple: Executor - Delta 1.1.733.988)
local ExecutorName = "Unknown"
local ExecutorVersion = "Unknown"
pcall(function()
    if identifyexecutor then
        -- Delta (and others) return the version as a SECOND return value:
        -- identifyexecutor() -> "Delta", "1.1.733.988"
        local Name, Version = identifyexecutor()
        if type(Name) == "table" then
            ExecutorName = tostring(Name[1] or Name.Name or Name["Name"] or "Unknown")
            ExecutorVersion = tostring(Name[2] or Name.Version or Name["Version"] or "Unknown")
        else
            ExecutorName = tostring(Name)
            if Version ~= nil and tostring(Version) ~= "" then
                ExecutorVersion = tostring(Version)
            end
        end
    elseif getexecutorname then
        ExecutorName = tostring(getexecutorname())
    end
    if ExecutorVersion == "Unknown" then
        pcall(function()
            if getexecutorversion then
                ExecutorVersion = tostring(getexecutorversion())
            end
        end)
    end
end)

local ExecutorDisplay = ExecutorName
if ExecutorVersion ~= "Unknown" and ExecutorVersion ~= "" then
    ExecutorDisplay = ExecutorName .. " " .. ExecutorVersion
end
StatusBox:AddLabel({ Text = 'EXECUTOR - <font color="#60d888">' .. ExecutorDisplay .. '</font>' })
StatusBox:AddDivider()
local SessionLabel = StatusBox:AddLabel({ Text = 'SESSION - <font color="#60d888">0m 0s</font>' })

-- Updates Box (below Status)
local UpdatesBox = Tabs.Info:AddLeftGroupbox("Updates", "rotate-ccw")

UpdatesBox:AddLabel({ Text = '<font color="#60d888">● Up to date</font>' })
UpdatesBox:AddLabel({ Text = '<font color="#8a8a8a"> Last Updated 8/18/2026</font>' })

-- Game Info Box
local InfoGameBox = Tabs.Info:AddRightGroupbox("Game Info", "gamepad-2")

local Green = "#60d888"
local GameNameLabel = InfoGameBox:AddLabel({ Text = 'GAME - <font color="' .. Green .. '">Loading...</font>' })
InfoGameBox:AddLabel({ Text = 'PLACE ID - <font color="' .. Green .. '">' .. tostring(game.PlaceId) .. '</font>' })

local JobId = tostring(game.JobId)
local ShortJobId = #JobId > 18 and JobId:sub(1, 18) .. "..." or JobId
InfoGameBox:AddLabel({ Text = 'SERVER - <font color="' .. Green .. '">' .. ShortJobId .. '</font>' })

-- Fetch game name (async, wrapped in pcall)
task.spawn(function()
    local Success, Info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if Success and Info and Info.Name then
        pcall(function()
            -- strip emojis so the full name fits in the card
            local CleanName = tostring(Info.Name):gsub("[^%z\1-\127]", "")
            GameNameLabel:SetText('GAME - <font color="#60d888">' .. CleanName .. ' [' .. game.PlaceId .. ']</font>')
        end)
    else
        pcall(function()
            GameNameLabel:SetText('GAME - <font color="#60d888">Unknown</font>')
        end)
    end
end)

-- Live session timer
local ScriptStartTime = os.clock()
task.spawn(function()
    while true do
        local Elapsed = os.clock() - ScriptStartTime
        local Mins = math.floor(Elapsed / 60)
        local Secs = math.floor(Elapsed % 60)
        pcall(function()
            SessionLabel:SetText('SESSION - <font color="#60d888">' .. Mins .. 'm ' .. Secs .. 's</font>')
        end)
        task.wait(1)
    end
end)

-- Copy Place ID button
InfoGameBox:AddButton({
    Text = "Copy Place ID",
    Func = function()
        CopyToClipboard(tostring(game.PlaceId))
    end,
    Tooltip = "Copy Place ID"
})

-- Copy Join Script button
InfoGameBox:AddButton({
    Text = "Copy Join Script",
    Func = function()
        local JoinScript = string.format(
            'game:GetService("TeleportService"):TeleportToPlaceInstance(%d, %q, game:GetService("Players").LocalPlayer)',
            game.PlaceId, JobId
        )
        CopyToClipboard(JoinScript)
    end,
    Tooltip = "Copy Join Script"
})

-- Socials Box (below Game Info)
local SocialsBox = Tabs.Info:AddRightGroupbox("Socials", "link")

SocialsBox:AddButton({
    Text = "Discord",
    Func = function()
        CopyToClipboard(Config.DiscordLink)
    end,
    Tooltip = "Discord"
})

SocialsBox:AddButton({
    Text = "YouTube",
    Func = function()
        CopyToClipboard(Config.YouTubeLink)
    end,
    Tooltip = "YouTube"
})

SocialsBox:AddButton({
    Text = "TikTok",
    Func = function()
        CopyToClipboard(Config.TikTokLink)
    end,
    Tooltip = "TikTok"
})

-- Features Box (below Socials, simple feature list)
local FeaturesBox = Tabs.Info:AddRightGroupbox("Features", "list")

FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Farm Lucky Blocks</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Collect Cash</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Rebirth</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Sell All</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Open Lucky Blocks</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy All Upgrades</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy Selected Upgrades</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Upgrade Floors</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Upgrade Soccer</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy All Gear</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Buy Selected Gear</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Quick Actions</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Theme Manager</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Config Autoload</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Execute Script</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Reconnect</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Auto Hide UI</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">Anti AFK</font>' })
FeaturesBox:AddLabel({ Text = '<font color="#60d888">No Gameplay Paused</font>' })

-- MAIN > FARMING TAB
local FarmBox = MainTabs.Eggs:AddLeftGroupbox("Auto Farm", "star")

-- Lucky Block Selection Dropdown
local LuckyBlockDropdown = FarmBox:AddDropdown("LuckyBlockSelect", {
    Text = "Select LuckyBlock",
    Values = LuckyBlocksList,
    Multi = true,
    Default = Config.SelectedLuckyBlock,
    MaxVisibleDropdownItems = 8,
    Callback = function(Selected)
        Config.SelectedLuckyBlock = {}
        for Block, Active in Selected do
            if Active then
                table.insert(Config.SelectedLuckyBlock, Block)
            end
        end
        if not SuppressUI then
            ScheduleSave()
        end
    end,
})
SettingsRefs.LuckyBlockDropdown = LuckyBlockDropdown

FarmBox:AddDivider()

AddFeatureToggle(FarmBox, "AutoFarm", {
    Text = "Auto Farm",
    Tooltip = "Auto Farm Loop",
    Notify = true,
}, function(Value)
    Config.FarmActive = Value
    if Value then
        task.spawn(function()
            while Config.FarmActive do
                FarmLuckyBlock()
                RunService.RenderStepped:Wait(90)
            end
        end)
    end
end)

AddFeatureToggle(FarmBox, "AutoCollect", {
    Text = "Auto Collect Cash",
    Tooltip = "Auto Collect Cash",
    Notify = true,
}, function(Value)
    Config.CollectActive = Value
    if Value then
        task.spawn(function()
            while Config.CollectActive do
                CollectEarnings(70)
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(FarmBox, "AutoRebirth", {
    Text = "Auto Rebirth",
    Tooltip = "Auto Rebirth",
    Notify = true,
}, function(Value)
    Config.RebirthActive = Value
    if Value then
        task.spawn(function()
            while Config.RebirthActive do
                DoRebirth()
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(FarmBox, "AutoSellAll", {
    Text = "Auto Sell All",
    Tooltip = "Auto Sell All",
    Notify = true,
}, function(Value)
    Config.SellAllActive = Value
    if Value then
        task.spawn(function()
            while Config.SellAllActive do
                SellAllSlimes()
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(FarmBox, "AutoOpen", {
    Text = "Auto Open Lucky Blocks",
    Tooltip = "Auto Open Lucky Blocks",
    Notify = true,
}, function(Value)
    Config.OpenActive = Value
    if Value then
        task.spawn(function()
            while Config.OpenActive do
                OpenLuckyBlocks(70)
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

local QuickBox = MainTabs.Eggs:AddRightGroupbox("Quick Actions", "zap")

QuickBox:AddButton({
    Text = "Collect Cash",
    Func = function()
        CollectEarnings(70)
    end,
    Tooltip = "Collect Cash"
})

QuickBox:AddButton({
    Text = "Rebirth",
    Func = function()
        DoRebirth()
    end,
    Tooltip = "Rebirth"
})

QuickBox:AddButton({
    Text = "Sell All Items",
    Func = function()
        SellAllSlimes()
    end,
    Tooltip = "Sell All Items"
})

QuickBox:AddButton({
    Text = "Open Lucky Blocks",
    Func = function()
        OpenLuckyBlocks(50)
    end,
    Tooltip = "Open Lucky Blocks"
})

-- MAIN > UPGRADE TAB
local UpgradeBox = MainTabs.Slimes:AddLeftGroupbox("Upgrades", "zap")

local UpgradeDropdown = UpgradeBox:AddDropdown("UpgradeList", {
    Text = "Select Upgrade",
    Values = { "Jump", "Carry" },
    Multi = true,
    Default = Config.SelectedUpgrades,
    MaxVisibleDropdownItems = 8,
    Callback = function(Selected)
        Config.SelectedUpgrades = {}
        for Upgrade, Active in Selected do
            if Active then
                table.insert(Config.SelectedUpgrades, Upgrade)
            end
        end
        ScheduleSave()
    end,
})
SettingsRefs.UpgradeDropdown = UpgradeDropdown

UpgradeBox:AddDivider()

AddFeatureToggle(UpgradeBox, "AutoUpgrades", {
    Text = "Auto Buy All Upgrades",
    Tooltip = "Auto Buy All Upgrades",
    Notify = true,
}, function(Value)
    Config.BuyUpgradesActive = Value
    if Value then
        task.spawn(function()
            while Config.BuyUpgradesActive do
                BuyAllUpgrades()
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(UpgradeBox, "AutoBuySelectedUpgrades", {
    Text = "Auto Buy Selected Upgrades",
    Tooltip = "Auto Buy Selected Upgrades",
    Notify = true,
}, function(Value)
    Config.BuySelectedUpgradesActive = Value
    if Value then
        task.spawn(function()
            while Config.BuySelectedUpgradesActive do
                BuySelectedUpgrades()
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

local FloorsSoccerBox = MainTabs.Slimes:AddRightGroupbox("Floors & Soccer", "zap")

local SoccerSlotDropdown = FloorsSoccerBox:AddDropdown("SoccerSlot", {
    Text = "Select Soccer",
    Values = SoccerSlotOptions,
    Multi = true,
    Default = Config.SoccerSlots,
    MaxVisibleDropdownItems = 8,
    Callback = function(Selected)
        Config.SoccerSlots = {}
        for Slot, Active in Selected do
            if Active then
                table.insert(Config.SoccerSlots, Slot)
            end
        end
        ScheduleSave()
    end,
})
SettingsRefs.SoccerSlotDropdown = SoccerSlotDropdown

FloorsSoccerBox:AddDivider()

AddFeatureToggle(FloorsSoccerBox, "AutoSoccer", {
    Text = "Auto Upgrade Soccer",
    Tooltip = "Auto Upgrade Soccer",
    Notify = true,
}, function(Value)
    Config.UpgradeSoccerActive = Value
    if Value then
        task.spawn(function()
            while Config.UpgradeSoccerActive do
                for _, Slot in Config.SoccerSlots do
                    UpgradeSoccerSlot(tonumber(Slot:match("%d+")) or 1)
                    RunService.RenderStepped:Wait(0.5)
                end
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(FloorsSoccerBox, "AutoFloors", {
    Text = "Auto Upgrade Floors",
    Tooltip = "Auto Upgrade Floors",
    Notify = true,
}, function(Value)
    Config.UpgradeFloorsActive = Value
    if Value then
        task.spawn(function()
            while Config.UpgradeFloorsActive do
                for i = 10, 70 do
                    UpgradeFloor(i)
                    RunService.RenderStepped:Wait(0.5)
                end
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

-- MAIN > SHOP TAB
local GearBox = MainTabs.Shop:AddLeftGroupbox("Gear", "shopping-bag")

local GearOptions = {}
for i = 1, 25 do
    table.insert(GearOptions, tostring(i))
end

local GearDropdown = GearBox:AddDropdown("GearList", {
    Text = "Select Gear",
    Values = GearOptions,
    Multi = true,
    Default = Config.SelectedGears,
    MaxVisibleDropdownItems = 8,
    Callback = function(Selected)
        Config.SelectedGears = {}
        for Gear, Active in Selected do
            if Active then
                table.insert(Config.SelectedGears, Gear)
            end
        end
        ScheduleSave()
    end,
})
SettingsRefs.GearDropdown = GearDropdown

GearBox:AddDivider()

AddFeatureToggle(GearBox, "AutoBuyGear", {
    Text = "Auto Buy Selected Gear",
    Tooltip = "Auto Buy Selected Gear",
    Notify = true,
}, function(Value)
    Config.BuyGearActive = Value
    if Value then
        task.spawn(function()
            while Config.BuyGearActive do
                BuyGearList(Config.SelectedGears)
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

AddFeatureToggle(GearBox, "AutoBuyAllGear", {
    Text = "Auto Buy All Gear",
    Tooltip = "Auto Buy All Gear",
    Notify = true,
}, function(Value)
    Config.BuyAllGearActive = Value
    if Value then
        task.spawn(function()
            while Config.BuyAllGearActive do
                for i = 1, 25 do
                    BuyGear(tostring(i))
                    RunService.RenderStepped:Wait(0.5)
                end
                RunService.RenderStepped:Wait(180)
            end
        end)
    end
end)

-- SETTINGS > THEME MANAGER
local ThemeBox = Tabs.Settings:AddLeftGroupbox("Theme Manager", "palette")

local ThemeDropdown = ThemeBox:AddDropdown("Theme", {
    Text = "Theme",
    Values = ThemeNames,
    Default = Config.ThemeName,
    Callback = function(Value)
        Config.ThemeName = Value
        ApplyTheme(Themes[Value])
        if not SuppressUI then
            Config.CustomColors = CloneColors(Themes[Value])
            SyncColorPickers()
            Notify("Theme", "Theme set to " .. Value, "Success")
            ScheduleSave()
        end
    end,
})
SettingsRefs.ThemeDropdown = ThemeDropdown

ThemeBox:AddDivider()

ThemeBox:AddLabel("Accent Color"):AddColorPicker("ThemeAccent", {
    Default = Config.CustomColors.AccentColor,
    Title = "Accent Color",
    Callback = function(Color)
        Config.CustomColors.AccentColor = Color
        ApplyColorOverride("AccentColor", Color)
        ScheduleSave()
    end,
})

ThemeBox:AddLabel("Font Color"):AddColorPicker("ThemeFontColor", {
    Default = Config.CustomColors.FontColor,
    Title = "Font Color",
    Callback = function(Color)
        Config.CustomColors.FontColor = Color
        ApplyColorOverride("FontColor", Color)
        ScheduleSave()
    end,
})

ThemeBox:AddLabel("Background Color"):AddColorPicker("ThemeBackground", {
    Default = Config.CustomColors.BackgroundColor,
    Title = "Background Color",
    Callback = function(Color)
        Config.CustomColors.BackgroundColor = Color
        ApplyColorOverride("BackgroundColor", Color)
        ScheduleSave()
    end,
})

ThemeBox:AddLabel("Main Color"):AddColorPicker("ThemeMain", {
    Default = Config.CustomColors.MainColor,
    Title = "Main Color",
    Callback = function(Color)
        Config.CustomColors.MainColor = Color
        ApplyColorOverride("MainColor", Color)
        ScheduleSave()
    end,
})

ThemeBox:AddLabel("Outline Color"):AddColorPicker("ThemeOutline", {
    Default = Config.CustomColors.OutlineColor,
    Title = "Outline Color",
    Callback = function(Color)
        Config.CustomColors.OutlineColor = Color
        ApplyColorOverride("OutlineColor", Color)
        ScheduleSave()
    end,
})

ThemeBox:AddDivider()

local FontDropdown = ThemeBox:AddDropdown("Font", {
    Text = "Font",
    Values = FontNames,
    Default = Config.FontName,
    Callback = function(Value)
        Config.FontName = Value
        Library:SetFont(Enum.Font[Value])
        if not SuppressUI then
            ScheduleSave()
        end
    end,
})
SettingsRefs.FontDropdown = FontDropdown


local FontPresetDropdown = ThemeBox:AddDropdown("FontPreset", {
    Text = "Font Color Preset",
    Values = FontPresetNames,
    Default = Config.FontPreset,
    Visible = false, -- hidden; presets still apply from the saved config
    Callback = function(Value)
        Config.FontPreset = Value
        for _, Preset in FontPresets do
            if Preset.Name == Value then
                Config.CustomColors.FontColor = Color3.fromRGB(255, 255, 255)
                Config.CustomColors.AccentColor = Preset.Accent
                ApplyColorOverride("FontColor", Color3.fromRGB(255, 255, 255))
                ApplyColorOverride("AccentColor", Preset.Accent)
                SyncColorPickers()
                break
            end
        end
        if not SuppressUI then
            ScheduleSave()
        end
    end,
})
SettingsRefs.FontPresetDropdown = FontPresetDropdown


ThemeBox:AddButton({
    Text = "Reset Theme",
    Func = function()
        Config.ThemeName = "Emerald Green"
        Config.FontPreset = "White + Emerald"
        Config.CustomColors = CloneColors(Themes["Emerald Green"])
        ApplyTheme(Themes["Emerald Green"])
        ThemeDropdown:SetValue("Emerald Green")
        FontPresetDropdown:SetValue("White + Emerald")
        SyncColorPickers()
        Notify("Theme", "Theme reset to Emerald Green", "Info")
        ScheduleSave()
    end,
})

-- SETTINGS > MENU GROUP (top of the right column)
local MenuBox = Tabs.Settings:AddRightGroupbox("Menu Group", "menu")

MenuBox:AddLabel("Menu Bind"):AddKeyPicker("MenuBind", {
    Default = Config.MenuBind,
    Mode = "Press",
    Text = "Toggle UI",
    Callback = function()
        Library:Toggle()
    end,
    ChangedCallback = function(NewKey)
        if typeof(NewKey) == "EnumItem" then
            Config.MenuBind = NewKey.Name
        end
        ScheduleSave()
    end,
})
SettingsRefs.MenuBindPicker = Library.Options.MenuBind

MenuBox:AddDivider()

AddFeatureToggle(MenuBox, "AutoExecute", {
    Text = "Auto Execute Script",
    Tooltip = "Auto Execute Script",
}, function(Value)
    Config.AutoExecute = Value
    if Value then
        RunAutoExecute()
    end
end)

AddFeatureToggle(MenuBox, "AutoReconnect", {
    Text = "Auto Reconnect to Game",
    Tooltip = "Auto Reconnect to Game",
}, function(Value)
    Config.AutoReconnect = Value
    if Value then
        AutoReconnectLoop()
    end
end)

AddFeatureToggle(MenuBox, "AutoHideUi", {
    Text = "Auto Hide UI",
    Tooltip = "Auto Hide UI",
}, function(Value)
    Config.AutoHideUi = Value
    if Value then
        AutoHideUiLoop()
    end
end)

AddFeatureToggle(MenuBox, "AntiAfk", {
    Text = "Anti AFK",
    Tooltip = "Anti AFK",
}, function(Value)
    Config.AntiAfk = Value
    if Value then
        AntiAfkLoop()
    end
end)

AddFeatureToggle(MenuBox, "NoGameplayPaused", {
    Text = "No Gameplay Paused",
    Tooltip = "No Gameplay Paused",
}, function(Value)
    Config.NoGameplayPaused = Value
    if Value then
        NoPauseLoop()
    end
end)

MenuBox:AddDivider()

MenuBox:AddButton({
    Text = "Stop All Features",
    Func = function()
        Config.FarmActive = false
        Config.BuyUpgradesActive = false
        Config.UpgradeFloorsActive = false
        Config.UpgradeSoccerActive = false
        Config.OpenActive = false
        Config.CollectActive = false
        Config.RebirthActive = false
        Config.SellAllActive = false
        Config.BuySelectedUpgradesActive = false
        Config.BuyGearActive = false
        Config.BuyAllGearActive = false
        Config.AutoReconnect = false
        Config.AutoHideUi = false
        Config.AntiAfk = false
        Config.NoGameplayPaused = false
        for Id, Toggle in Library.Toggles do
            if Toggle.Value then
                Toggle:SetValue(false)
            end
        end
        Notify("Script", "All features stopped", "Warning")
    end,
    Risky = true
})

-- SETTINGS > CONFIGURATION
local ConfigBox = Tabs.Settings:AddRightGroupbox("Configuration", "save")

local RefreshConfigList

local ConfigNameInput = ConfigBox:AddInput("ConfigName", {
    Text = "Config name",
    Placeholder = "Type a config name...",
    ClearTextOnFocus = true,
})

ConfigBox:AddButton({
    Text = "Create config",
    Func = function()
        local Name = SanitizeConfigName(ConfigNameInput.Value)
        if not Name then
            Notify("Config", "Enter a valid config name first", "Warning")
            return
        end
        if ConfigExists(Name) then
            Notify("Config", "'" .. Name .. "' already exists", "Warning")
            return
        end
        if SaveConfigData(Name) then
            CurrentConfig = Name
            RefreshConfigList(Name)
            Notify("Config", "Config '" .. Name .. "' created", "Success")
        else
            Notify("Config", "Config saving not supported on this executor", "Error")
        end
    end,
    Tooltip = "Create config"
})

ConfigBox:AddDivider()

local ConfigListDropdown = ConfigBox:AddDropdown("ConfigList", {
    Text = "Config list",
    Values = { "---" },
    Default = "---",
    Callback = function(Value)
        CurrentConfig = Value == "---" and nil or Value
    end,
})
SettingsRefs.ConfigListDropdown = ConfigListDropdown

local AutoloadLabel = ConfigBox:AddLabel({ Text = 'Current autoload config: <font color="#60d888">none</font>' })

RefreshConfigList = function(SelectName)
    local Values = { "---" }
    for _, Name in GetConfigList() do
        table.insert(Values, Name)
    end
    ConfigListDropdown:SetValues(Values)
    local Choice = SelectName or CurrentConfig or "---"
    if not table.find(Values, Choice) then
        Choice = "---"
    end
    ConfigListDropdown:SetValue(Choice)
    CurrentConfig = Choice == "---" and nil or Choice
end

local function UpdateAutoloadLabel()
    local Name = GetAutoloadName()
    local Text = 'Current autoload config: <font color="#60d888">none</font>'
    if Name then
        Text = 'Current autoload config: <font color="#60d888">' .. Name .. '</font>'
    end
    AutoloadLabel:SetText(Text)
end

ConfigBox:AddButton({
    Text = "Load config",
    Func = function()
        local Name = CurrentConfig
        if not Name then
            Notify("Config", "Select a config from the list first", "Warning")
            return
        end
        if LoadConfig(Name, false) then
            Notify("Config", "Config '" .. Name .. "' loaded", "Success")
        end
    end,
    Tooltip = "Load config"
})

ConfigBox:AddButton({
    Text = "Overwrite config",
    Func = function()
        local Name = CurrentConfig
        if not Name then
            Notify("Config", "Select a config from the list first", "Warning")
            return
        end
        if SaveConfigData(Name) then
            Notify("Config", "Config '" .. Name .. "' overwritten", "Success")
        else
            Notify("Config", "Config saving not supported on this executor", "Error")
        end
    end,
    Tooltip = "Overwrite config"
})

ConfigBox:AddButton({
    Text = "Delete config",
    Func = function()
        local Name = CurrentConfig
        if not Name then
            Notify("Config", "Select a config from the list first", "Warning")
            return
        end
        pcall(function()
            delfile(ConfigPath(Name))
        end)
        if GetAutoloadName() == Name then
            ClearAutoload()
        end
        CurrentConfig = nil
        RefreshConfigList()
        UpdateAutoloadLabel()
        Notify("Config", "Config '" .. Name .. "' deleted", "Warning")
    end,
    Tooltip = "Delete config",
    Risky = true
})

ConfigBox:AddButton({
    Text = "Refresh list",
    Func = function()
        RefreshConfigList()
        Notify("Config", "Config list refreshed", "Info")
    end,
    Tooltip = "Refresh list"
})

ConfigBox:AddButton({
    Text = "Set as autoload",
    Func = function()
        local Name = CurrentConfig
        if not Name then
            Notify("Config", "Select a config from the list first", "Warning")
            return
        end
        if SetAutoload(Name) then
            UpdateAutoloadLabel()
            Notify("Config", "Autoload set to '" .. Name .. "'", "Success")
        end
    end,
    Tooltip = "Set as autoload"
})

ConfigBox:AddButton({
    Text = "Reset autoload",
    Func = function()
        ClearAutoload()
        UpdateAutoloadLabel()
        Notify("Config", "Autoload cleared", "Info")
    end,
    Tooltip = "Reset autoload"
})

ConfigBox:AddDivider()

AddFeatureToggle(ConfigBox, "AutoSave", {
    Text = "Auto Save Config",
    Tooltip = "Auto Save Config",
}, function(Value)
    Config.AutoSave = Value
end)

-- Apply default theme on startup
ApplyTheme(Themes[Config.ThemeName])

-- Autoload config on start (silent), then run auto execute
task.delay(1, function()
    local AutoloadName = GetAutoloadName()
    if AutoloadName and ConfigExists(AutoloadName) then
        CurrentConfig = AutoloadName
        if LoadConfig(AutoloadName, true) then
            Notify("Config", "Autoloaded '" .. AutoloadName .. "'", "Success")
        end
    end
    RunAutoExecute()
end)

Notify("AntiGodHub", "Script loaded", "Success")