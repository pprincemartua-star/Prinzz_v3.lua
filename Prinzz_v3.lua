--[[
    PRINZZ SOUTH BRONX MACRO V2.1
    Platform: Roblox Delta / Mobileador
    Theme: Crimson Red

    CHANGELOG v2.1:
    + Anti-Kick (metatable __namecall + hookfunction)
    + Anti-AFK (Idled hook)
    + Semua fitur v2 dipertahankan
]]

local Players     = game:GetService("Players")
local CoreGui     = game:GetService("CoreGui")
local UIS         = game:GetService("UserInputService")
local VIM         = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================================
--  ANTI-KICK & ANTI-AFK  (dijalankan paling awal)
-- ============================================================
local function setupAntiKick()
    -- Layer 1: blokir namecall "Kick"
    pcall(function()
        local mt = getrawmetatable(game)
        if not mt then return end
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "Kick" then
                warn("[PRINZZ] Kick attempt blocked (namecall)")
                return nil
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
    end)

    -- Layer 2: hook Kick function langsung
    pcall(function()
        local lp = Players.LocalPlayer
        if lp and lp.Kick then
            hookfunction(lp.Kick, function() end)
        end
    end)

    print("[PRINZZ] Anti-Kick aktif")
end

local function setupAntiAFK()
    local lp = Players.LocalPlayer
    lp.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
    print("[PRINZZ] Anti-AFK aktif")
end

setupAntiKick()
setupAntiAFK()

-- ============================================================
--  SETTINGS
-- ============================================================
local Settings = {
    Speed    = 0.5,
    Delay    = 0.2,
    Loop     = true,
    Enabled  = false,
    Mode     = "log",   -- "log" | "tap"
    TargetX  = 0,
    TargetY  = 0,
}

local player     = Players.LocalPlayer
local tapCount   = 0
local macroThread = nil

-- ============================================================
--  CLEANUP GUI LAMA
-- ============================================================
pcall(function()
    local old = CoreGui:FindFirstChild("PRINZZ_MACRO")
    if old then old:Destroy() end
end)
pcall(function()
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("PRINZZ_MACRO")
        if old then old:Destroy() end
    end
end)

-- ============================================================
--  GUI
-- ============================================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "PRINZZ_MACRO"
GUI.ResetOnSpawn = false
GUI.DisplayOrder = 999
local ok = pcall(function() GUI.Parent = CoreGui end)
if not ok then GUI.Parent = player:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(280, 400)
Frame.Position = UDim2.new(0.5, -140, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Parent = GUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = Frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(200, 25, 50)
stroke.Thickness = 2
stroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 42)
Title.BackgroundTransparency = 1
Title.Text = "PRINZZ SOUTH BRONX V2.1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Position = UDim2.fromOffset(10, 42)
Status.Size = UDim2.new(1, -20, 0, 22)
Status.BackgroundTransparency = 1
Status.Text = "STATUS: OFF"
Status.TextColor3 = Color3.fromRGB(255, 90, 90)
Status.Font = Enum.Font.GothamBold
Status.TextSize = 13
Status.Parent = Frame

local ModeLabel = Instance.new("TextLabel")
ModeLabel.Position = UDim2.fromOffset(10, 64)
ModeLabel.Size = UDim2.new(1, -20, 0, 22)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "MODE: LOG ONLY"
ModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ModeLabel.TextSize = 12
ModeLabel.Font = Enum.Font.Gotham
ModeLabel.Parent = Frame

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Position = UDim2.fromOffset(10, 86)
CounterLabel.Size = UDim2.new(1, -20, 0, 22)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "TAPS: 0"
CounterLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
CounterLabel.TextSize = 12
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.Parent = Frame

local Info = Instance.new("TextLabel")
Info.Position = UDim2.fromOffset(10, 108)
Info.Size = UDim2.new(1, -20, 0, 22)
Info.BackgroundTransparency = 1
Info.Text = "SPEED: 0.5s | DELAY: 0.2s"
Info.TextColor3 = Color3.fromRGB(150, 150, 150)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.Parent = Frame

local function CreateButton(name, text, y, callback)
    local Button = Instance.new("TextButton")
    Button.Name = name
    Button.Position = UDim2.fromOffset(12, y)
    Button.Size = UDim2.new(1, -24, 0, 34)
    Button.BackgroundColor3 = Color3.fromRGB(150, 20, 40)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 13
    Button.Font = Enum.Font.GothamBold
    Button.BorderSizePixel = 0
    Button.Parent = Frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = Button
    Button.MouseButton1Click:Connect(callback)
    return Button
end

-- ============================================================
--  MACRO ENGINE
-- ============================================================
local function stopMacro()
    Settings.Enabled = false
    if macroThread then
        task.cancel(macroThread)
        macroThread = nil
    end
end

local function tapAt(x, y)
    pcall(function()
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function runMacro()
    stopMacro()
    Settings.Enabled = true
    macroThread = task.spawn(function()
        while Settings.Enabled and GUI.Parent do
            tapCount = tapCount + 1
            CounterLabel.Text = "TAPS: " .. tapCount

            if Settings.Mode == "tap" then
                tapAt(Settings.TargetX, Settings.TargetY)
            else
                print(("[PRINZZ v2.1] Tap #%d (log-only mode)"):format(tapCount))
            end

            task.wait(Settings.Speed)
            task.wait(Settings.Delay)

            if not Settings.Loop then
                Settings.Enabled = false
                Status.Text = "STATUS: DONE (1x)"
                break
            end
        end
        if not Settings.Enabled then
            Status.Text = "STATUS: OFF"
        end
        macroThread = nil
    end)
end

-- ============================================================
--  BUTTONS
-- ============================================================
local Toggle = CreateButton("Toggle", "MACRO: OFF", 138, function()
    if Settings.Enabled then
        stopMacro()
        Toggle.Text = "MACRO: OFF"
    else
        tapCount = 0
        CounterLabel.Text = "TAPS: 0"
        runMacro()
        Toggle.Text = "MACRO: ON"
    end
end)

local LoopButton = CreateButton("Loop", "LOOP: ON", 176, function()
    Settings.Loop = not Settings.Loop
    LoopButton.Text = Settings.Loop and "LOOP: ON" or "LOOP: OFF"
end)

local ModeButton = CreateButton("Mode", "MODE: LOG ONLY", 214, function()
    if Settings.Mode == "log" then
        Settings.Mode = "tap"
        ModeButton.Text = "MODE: TAP TARGET"
        ModeLabel.Text = "MODE: TAP @ " .. Settings.TargetX .. "," .. Settings.TargetY
    else
        Settings.Mode = "log"
        ModeButton.Text = "MODE: LOG ONLY"
        ModeLabel.Text = "MODE: LOG ONLY"
    end
end)

CreateButton("SetTarget", "SET TAP TARGET", 252, function()
    Status.Text = "STATUS: TAP WHERE TO TARGET..."
    local conn
    conn = UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Settings.TargetX = input.Position.X
            Settings.TargetY = input.Position.Y
            ModeLabel.Text = "MODE: TAP @ " .. Settings.TargetX .. "," .. Settings.TargetY
            Status.Text = "STATUS: TARGET SET"
            conn:Disconnect()
        end
    end)
end)

CreateButton("Stop", "STOP MACRO", 290, function()
    stopMacro()
    Toggle.Text = "MACRO: OFF"
    Status.Text = "STATUS: OFF"
end)

CreateButton("Close", "CLOSE GUI", 328, function()
    stopMacro()
    GUI:Destroy()
end)

-- ============================================================
--  DRAG PANEL
-- ============================================================
local dragging, dragStart, startPosition = false, nil, nil
local dragConn = nil

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Frame.Position
        if dragConn then dragConn:Disconnect() end
        dragConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if dragConn then dragConn:Disconnect(); dragConn = nil end
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

print("PRINZZ SOUTH BRONX MACRO V2.1 (Anti-Kick + Anti-AFK) LOADED")