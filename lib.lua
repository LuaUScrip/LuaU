-- AntiGod UI Library v1.0.0
-- GitHub: https://github.com/LuaUScrip/LuaU
-- For use with loadstring on GitHub
-- 
-- Usage:
-- local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/LuaUScrip/LuaU/refs/heads/main/lib.lua"))()
-- local window = UI:CreateWindow("AntiGodHub")

local AntiGodUI = {}
AntiGodUI.__index = AntiGodUI

-- Color presets
local Colors = {
    Black = Color3.fromRGB(0, 0, 0),
    White = Color3.fromRGB(255, 255, 255),
    DarkGray = Color3.fromRGB(17, 24, 39),
    Gray = Color3.fromRGB(31, 41, 55),
    LightGray = Color3.fromRGB(55, 65, 81),
    Blue = Color3.fromRGB(59, 130, 246),
    Red = Color3.fromRGB(220, 38, 38),
}

-- Create a new UI window
function AntiGodUI:CreateWindow(title, options)
    options = options or {}
    
    local Window = {
        Title = title or "AntiGodHub",
        Subtitle = options.Subtitle or "YouTube: AntiGodHub",
        Size = options.Size or UDim2.new(0, 400, 0, 600),
        Position = options.Position or UDim2.new(0.5, -200, 0.5, -300),
        Draggable = options.Draggable ~= false,
        Resizable = options.Resizable ~= false,
        Visible = true,
        Callbacks = {},
        Elements = {},
    }
    
    setmetatable(Window, self)
    self.__index = self
    
    Window:CreateUI()
    return Window
end

-- Create the main UI
function AntiGodUI:CreateUI()
    -- Create parent frame
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiGodHub"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = game.CoreGui
    self.ScreenGui = screenGui
    
    -- Main window frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = self.Size
    mainFrame.Position = self.Position
    mainFrame.BackgroundColor3 = Colors.Black
    mainFrame.BorderColor3 = Colors.LightGray
    mainFrame.BorderSizePixel = 2
    mainFrame.Parent = screenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    self.MainFrame = mainFrame
    
    -- Header
    self:CreateHeader(mainFrame)
    
    -- Content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundColor3 = Colors.Black
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 12)
    contentCorner.Parent = contentFrame
    
    self.ContentFrame = contentFrame
    
    -- Scroll frame for content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ScrollFrame"
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.Position = UDim2.new(0, 0, 0, 0)
    scrollFrame.BackgroundColor3 = Colors.Black
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = Colors.LightGray
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = contentFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 12)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 24)
    padding.PaddingRight = UDim.new(0, 24)
    padding.PaddingTop = UDim.new(0, 16)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.Parent = scrollFrame
    
    self.ScrollFrame = scrollFrame
    
    -- Footer
    self:CreateFooter(mainFrame)
    
    -- Make draggable if enabled
    if self.Draggable then
        self:MakeDraggable(mainFrame)
    end
end

-- Create header with title and minimize button
function AntiGodUI:CreateHeader(parent)
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 50)
    headerFrame.Position = UDim2.new(0, 0, 0, 0)
    headerFrame.BackgroundColor3 = Colors.DarkGray
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = parent
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = headerFrame
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(0.8, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 24, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Colors.White
    titleLabel.TextSize = 20
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = self.Title
    titleLabel.Parent = headerFrame
    
    -- Minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 32, 0, 32)
    minimizeButton.Position = UDim2.new(1, -40, 0, 9)
    minimizeButton.BackgroundColor3 = Colors.Gray
    minimizeButton.BorderColor3 = Colors.LightGray
    minimizeButton.BorderSizePixel = 1
    minimizeButton.TextColor3 = Colors.LightGray
    minimizeButton.TextSize = 18
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.Text = "−"
    minimizeButton.Parent = headerFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = minimizeButton
    
    minimizeButton.MouseButton1Click:Connect(function()
        self:Minimize()
    end)
end

-- Create footer
function AntiGodUI:CreateFooter(parent)
    local footerFrame = Instance.new("Frame")
    footerFrame.Name = "Footer"
    footerFrame.Size = UDim2.new(1, 0, 0, 40)
    footerFrame.Position = UDim2.new(0, 0, 1, -40)
    footerFrame.BackgroundColor3 = Colors.DarkGray
    footerFrame.BorderColor3 = Colors.LightGray
    footerFrame.BorderSizePixel = 1
    footerFrame.Parent = parent
    
    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, 12)
    footerCorner.Parent = footerFrame
    
    local footerLabel = Instance.new("TextLabel")
    footerLabel.Size = UDim2.new(1, 0, 1, 0)
    footerLabel.BackgroundTransparency = 1
    footerLabel.TextColor3 = Colors.LightGray
    footerLabel.TextSize = 12
    footerLabel.Font = Enum.Font.Gotham
    footerLabel.Text = self.Subtitle
    footerLabel.Parent = footerFrame
end

-- Add checkbox
function AntiGodUI:AddCheckbox(label, callback)
    local checkboxFrame = Instance.new("Frame")
    checkboxFrame.Name = label
    checkboxFrame.Size = UDim2.new(1, 0, 0, 50)
    checkboxFrame.BackgroundColor3 = Colors.DarkGray
    checkboxFrame.BorderColor3 = Colors.LightGray
    checkboxFrame.BorderSizePixel = 1
    checkboxFrame.Parent = self.ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = checkboxFrame
    
    -- Checkbox box
    local checkBox = Instance.new("TextButton")
    checkBox.Name = "CheckBox"
    checkBox.Size = UDim2.new(0, 20, 0, 20)
    checkBox.Position = UDim2.new(0, 0, 0.5, -10)
    checkBox.BackgroundColor3 = Colors.Gray
    checkBox.BorderColor3 = Colors.LightGray
    checkBox.BorderSizePixel = 1
    checkBox.TextSize = 0
    checkBox.Parent = checkboxFrame
    
    local checkCorner = Instance.new("UICorner")
    checkCorner.CornerRadius = UDim.new(0, 4)
    checkCorner.Parent = checkBox
    
    -- Checkmark
    local checkMark = Instance.new("TextLabel")
    checkMark.Name = "CheckMark"
    checkMark.Size = UDim2.new(1, 0, 1, 0)
    checkMark.BackgroundTransparency = 1
    checkMark.TextColor3 = Colors.Blue
    checkMark.TextSize = 14
    checkMark.Font = Enum.Font.GothamBold
    checkMark.Text = "✓"
    checkMark.Visible = false
    checkMark.Parent = checkBox
    
    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Name = "Label"
    labelText.Size = UDim2.new(0.8, 0, 1, 0)
    labelText.Position = UDim2.new(0, 30, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = Colors.White
    labelText.TextSize = 14
    labelText.Font = Enum.Font.Gotham
    labelText.Text = label
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = checkboxFrame
    
    local isChecked = false
    
    checkBox.MouseButton1Click:Connect(function()
        isChecked = not isChecked
        checkMark.Visible = isChecked
        
        if callback then
            callback(isChecked)
        end
        
        self.Callbacks[label] = isChecked
    end)
    
    table.insert(self.Elements, {
        Type = "Checkbox",
        Label = label,
        Frame = checkboxFrame,
        IsChecked = function() return isChecked end,
    })
    
    return checkboxFrame
end

-- Add slider
function AntiGodUI:AddSlider(label, min, max, default, callback)
    min = min or 0
    max = max or 200
    default = default or 100
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = label
    sliderFrame.Size = UDim2.new(1, 0, 0, 80)
    sliderFrame.BackgroundColor3 = Colors.DarkGray
    sliderFrame.BorderColor3 = Colors.LightGray
    sliderFrame.BorderSizePixel = 1
    sliderFrame.Parent = self.ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = sliderFrame
    
    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.5, 0, 0, 20)
    labelText.Position = UDim2.new(0, 0, 0, 8)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = Colors.White
    labelText.TextSize = 14
    labelText.Font = Enum.Font.Gotham
    labelText.Text = label
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = sliderFrame
    
    -- Value display
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.5, 0, 0, 20)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = Colors.White
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = tostring(default)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    -- Slider background
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -16, 0, 8)
    sliderBg.Position = UDim2.new(0, 8, 0, 40)
    sliderBg.BackgroundColor3 = Colors.Gray
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = sliderFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = sliderBg
    
    -- Slider thumb
    local sliderThumb = Instance.new("TextButton")
    sliderThumb.Name = "Thumb"
    sliderThumb.Size = UDim2.new(0, 20, 0, 20)
    sliderThumb.Position = UDim2.new(0, -5, 0.5, -10)
    sliderThumb.BackgroundColor3 = Colors.White
    sliderThumb.BorderColor3 = Colors.Blue
    sliderThumb.BorderSizePixel = 2
    sliderThumb.TextSize = 0
    sliderThumb.Parent = sliderBg
    
    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = UDim.new(1, 0)
    thumbCorner.Parent = sliderThumb
    
    local currentValue = default
    local dragging = false
    
    local function updateSlider(input)
        local relativePos = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
        local percentage = relativePos / sliderBg.AbsoluteSize.X
        currentValue = math.round(min + (max - min) * percentage)
        
        sliderThumb.Position = UDim2.new(percentage, -10, 0.5, -10)
        valueLabel.Text = tostring(currentValue)
        
        if callback then
            callback(currentValue)
        end
        
        self.Callbacks[label] = currentValue
    end
    
    sliderThumb.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input, gameProcessed)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    sliderBg.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
        end
    end)
    
    table.insert(self.Elements, {
        Type = "Slider",
        Label = label,
        Frame = sliderFrame,
        GetValue = function() return currentValue end,
    })
    
    return sliderFrame
end

-- Add text input
function AntiGodUI:AddTextInput(label, placeholder, callback)
    local inputFrame = Instance.new("Frame")
    inputFrame.Name = label
    inputFrame.Size = UDim2.new(1, 0, 0, 60)
    inputFrame.BackgroundColor3 = Colors.DarkGray
    inputFrame.BorderColor3 = Colors.LightGray
    inputFrame.BorderSizePixel = 1
    inputFrame.Parent = self.ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inputFrame
    
    -- Label
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(1, 0, 0, 18)
    labelText.Position = UDim2.new(0, 0, 0, 4)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = Colors.White
    labelText.TextSize = 12
    labelText.Font = Enum.Font.Gotham
    labelText.Text = label
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = inputFrame
    
    -- Input box
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -16, 0, 28)
    textBox.Position = UDim2.new(0, 8, 0, 26)
    textBox.BackgroundColor3 = Colors.Gray
    textBox.BorderColor3 = Colors.LightGray
    textBox.BorderSizePixel = 1
    textBox.TextColor3 = Colors.White
    textBox.TextSize = 14
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = placeholder or ""
    textBox.PlaceholderColor3 = Colors.LightGray
    textBox.Parent = inputFrame
    
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = textBox
    
    textBox.FocusLost:Connect(function(enterPressed)
        if callback then
            callback(textBox.Text)
        end
        self.Callbacks[label] = textBox.Text
    end)
    
    table.insert(self.Elements, {
        Type = "TextInput",
        Label = label,
        Frame = inputFrame,
        GetValue = function() return textBox.Text end,
    })
    
    return inputFrame
end

-- Add button
function AntiGodUI:AddButton(label, callback)
    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = label
    buttonFrame.Size = UDim2.new(1, 0, 0, 42)
    buttonFrame.BackgroundColor3 = Colors.Gray
    buttonFrame.BorderColor3 = Colors.LightGray
    buttonFrame.BorderSizePixel = 2
    buttonFrame.TextColor3 = Colors.White
    buttonFrame.TextSize = 14
    buttonFrame.Font = Enum.Font.GothamBold
    buttonFrame.Text = label
    buttonFrame.Parent = self.ScrollFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = buttonFrame
    
    local mouseEnter = false
    buttonFrame.MouseEnter:Connect(function()
        mouseEnter = true
        buttonFrame.BackgroundColor3 = Colors.LightGray
    end)
    
    buttonFrame.MouseLeave:Connect(function()
        mouseEnter = false
        buttonFrame.BackgroundColor3 = Colors.Gray
    end)
    
    buttonFrame.MouseButton1Click:Connect(function()
        buttonFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        
        if callback then
            callback()
        end
        
        wait(0.1)
        buttonFrame.BackgroundColor3 = mouseEnter and Colors.LightGray or Colors.Gray
    end)
    
    table.insert(self.Elements, {
        Type = "Button",
        Label = label,
        Frame = buttonFrame,
    })
    
    return buttonFrame
end

-- Make window draggable
function AntiGodUI:MakeDraggable(frame)
    local dragging = false
    local dragStart
    local frameStart
    
    frame.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local header = frame:FindFirstChild("Header")
            if header and input.Position.Y - frame.AbsolutePosition.Y < header.AbsoluteSize.Y then
                dragging = true
                dragStart = input.Position
                frameStart = frame.Position
            end
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input, gameProcessed)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = frameStart + UDim2.new(0, delta.X, 0, delta.Y)
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Minimize window
function AntiGodUI:Minimize()
    self.MainFrame.Visible = not self.MainFrame.Visible
end

-- Destroy window
function AntiGodUI:Destroy()
    self.ScreenGui:Destroy()
end

-- Get callback value
function AntiGodUI:GetValue(label)
    return self.Callbacks[label]
end

-- Set all values
function AntiGodUI:SetValues(values)
    for label, value in pairs(values) do
        self.Callbacks[label] = value
    end
end

-- Get all values
function AntiGodUI:GetAllValues()
    return self.Callbacks
end

return AntiGodUI
