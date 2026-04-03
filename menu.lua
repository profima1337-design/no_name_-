-- // LocalScript в StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local camera = workspace.CurrentCamera

-- Флаг: можно ли открывать меню RightShift
local CanToggle = true

-- Звуки
local OpenSound = Instance.new("Sound")
OpenSound.SoundId = "rbxassetid://9118823104"
OpenSound.Volume = 1
OpenSound.Parent = SoundService

local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://9118823104"
ClickSound.Volume = 0.7
ClickSound.Parent = SoundService

local ToggleSound = Instance.new("Sound")
ToggleSound.SoundId = "rbxassetid://7149516996"
ToggleSound.Volume = 0.6
ToggleSound.Parent = SoundService

local SwitchSound = Instance.new("Sound")
SwitchSound.SoundId = "rbxassetid://6026984224"
SwitchSound.Volume = 0.5
SwitchSound.Parent = SoundService

-- Blur эффект
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

-- Переменные для Fly / Fling / NoClip
local flying = false
local flinging = false
local noClip = false
local flySpeed = 50
local flingSpeed = 500

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Фикс физики
local function ResetCharacterPhysics()
    local char = LocalPlayer.Character
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BodyMover") or obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyPosition") then
            obj:Destroy()
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Anchored = false
        end
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    flying = false
    flinging = false
    noClip = false
    ResetCharacterPhysics()
end)

-- Fly
local function enableFly()
    if flying then return end
    flying = true

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.P = 5000
    bodyVelocity.Parent = rootPart

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not flying or not character or not rootPart or not rootPart.Parent then
            flying = false
            if connection then connection:Disconnect() end
            if bodyVelocity then bodyVelocity:Destroy() end
            ResetCharacterPhysics()
            return
        end

        local moveDirection = Vector3.new()

        if UIS:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit * flySpeed
        end

        bodyVelocity.Velocity = moveDirection
    end)
end

local function disableFly()
    flying = false
    ResetCharacterPhysics()
end

-- Fling
local function enableFling()
    if flinging then return end
    flinging = true

    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = rootPart

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not flinging or not character or not rootPart or not rootPart.Parent then
            flinging = false
            if connection then connection:Disconnect() end
            if bodyVelocity then bodyVelocity:Destroy() end
            ResetCharacterPhysics()
            return
        end

        bodyVelocity.Velocity = camera.CFrame.LookVector * flingSpeed
    end)
end

local function disableFling()
    flinging = false
    ResetCharacterPhysics()
end

-- NoClip
local function enableNoClip()
    if noClip then return end
    noClip = true

    local connection
    connection = RunService.Stepped:Connect(function()
        if not noClip or not character then
            if connection then connection:Disconnect() end
            return
        end

        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

local function disableNoClip()
    noClip = false
    ResetCharacterPhysics()
end

-- Ctrl + Click TP
local CtrlTpEnabled = false
local TELEPORT_OFFSET = Vector3.new(0, 3, 0)

local function teleportTo(position)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    char:MoveTo(position + TELEPORT_OFFSET)
end

mouse.Button1Down:Connect(function()
    if not CtrlTpEnabled then return end

    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then
        local targetPosition = mouse.Hit and mouse.Hit.p
        if targetPosition then
            teleportTo(targetPosition)
        end
    end
end)

-- TP Tool (только себе)
local function GiveTpTool()
    local player = LocalPlayer
    local mouseLocal = player:GetMouse()

    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "TP Tool (Click TP)"

    tool.Activated:Connect(function()
        local pos = mouseLocal.Hit.Position + Vector3.new(0, 3, 0)
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            player.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
        end
    end)

    tool.Parent = player.Backpack
end

-- ESP переменные
local ESPEnabled = false
local ESPRadius = 1000
local ESPConnections = {}
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ProfimaESP"
ESPFolder.Parent = workspace

-- AIM переменные
local aimbotEnabled = false
local aimFov = 100
local aimParts = {"Head"}
local smoothing = 0.05
local wallCheck = true
local rainbowFov = false
local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)
local hue = 0
local rainbowSpeed = 0.005
local fovVisible = true

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Color = circleColor
fovCircle.Visible = false

local currentTarget = nil
local currentTargetPart = nil

local function checkWall(targetCharacter)
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetHead then return true end

    local origin = camera.CFrame.Position
    local direction = (targetHead.Position - origin).Unit * (targetHead.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, raycastParams)
    return result and result.Instance ~= nil
end

local function getClosestPart(character)
    local closestPart = nil
    local shortestCursorDistance = aimFov

    for _, partName in ipairs(aimParts) do
        local part = character:FindFirstChild(partName)
        if part then
            local partPos, onScreen = camera:WorldToViewportPoint(part.Position)
            if onScreen and partPos.Z > 0 then
                local screenPos = Vector2.new(partPos.X, partPos.Y)
                local cursorDistance = (screenPos - Vector2.new(mouse.X, mouse.Y)).Magnitude

                if cursorDistance < shortestCursorDistance then
                    shortestCursorDistance = cursorDistance
                    closestPart = part
                end
            end
        end
    end

    return closestPart
end

local function getTarget()
    local nearestPlayer = nil
    local closestPart = nil
    local shortestCursorDistance = aimFov

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = getClosestPart(player.Character)
            if targetPart then
                local screenPos = camera:WorldToViewportPoint(targetPart.Position)
                local cursorDistance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude

                if cursorDistance < shortestCursorDistance then
                    if not wallCheck or not checkWall(player.Character) then
                        shortestCursorDistance = cursorDistance
                        nearestPlayer = player
                        closestPart = targetPart
                    end
                end
            end
        end
    end

    return nearestPlayer, closestPart
end

local function smooth(from, to)
    return from:Lerp(to, smoothing)
end

local function aimAt(player, part)
    if player and part then
        local targetCFrame = CFrame.new(camera.CFrame.Position, part.Position)
        camera.CFrame = smooth(camera.CFrame, targetCFrame)
    end
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        fovCircle.Visible = fovVisible
        fovCircle.Radius = aimFov
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)

        if rainbowFov then
            hue = hue + rainbowSpeed
            if hue > 1 then hue = 0 end
            fovCircle.Color = Color3.fromHSV(hue, 1, 1)
        else
            if currentTarget then
                fovCircle.Color = targetedCircleColor
            else
                fovCircle.Color = circleColor
            end
        end

        local target, targetPart = getTarget()
        currentTarget = target
        currentTargetPart = targetPart

        if currentTarget and currentTargetPart and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            aimAt(currentTarget, currentTargetPart)
        end
    else
        fovCircle.Visible = false
        currentTarget = nil
        currentTargetPart = nil
    end
end)

-- ESP функции
local function clearESPForPlayer(player)
    if player.Character then
        local char = player.Character
        local highlight = char:FindFirstChild("ESPHighlight")
        if highlight then highlight:Destroy() end
        if char:FindFirstChild("Head") then
            local head = char.Head
            local tag = head:FindFirstChild("NameTag")
            if tag then tag:Destroy() end
        end
    end
end

local function createHighlight(player)
    if player.Character and not player.Character:FindFirstChild("ESPHighlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.Adornee = player.Character
        highlight.Parent = player.Character
    end
end

local function createNameTag(player)
    if player.Character and player.Character:FindFirstChild("Head") and not player.Character.Head:FindFirstChild("NameTag") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "NameTag"
        billboard.Adornee = player.Character.Head
        billboard.Size = UDim2.new(0, 130, 0, 25)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = player.Character.Head

        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TagLabel"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = Color3.new(1, 1, 1)
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextScaled = true
        textLabel.TextStrokeTransparency = 0.6
        textLabel.Text = ""
        textLabel.Parent = billboard
    end
end

local function updateNameTag(player)
    if not ESPEnabled then return end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    if player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild("NameTag") and player.Character:FindFirstChild("Humanoid") and player.Character.PrimaryPart then
        local distance = (LocalPlayer.Character.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
        if distance <= ESPRadius then
            local tag = player.Character.Head.NameTag.TagLabel
            local health = math.floor(player.Character.Humanoid.Health)
            tag.Text = player.Name .. " | " .. string.format("%.0f", distance).."m | ❤️"..health
            player.Character.Head.NameTag.Enabled = true
            if player.Character:FindFirstChild("ESPHighlight") then
                player.Character.ESPHighlight.Enabled = true
            end
        else
            if player.Character.Head:FindFirstChild("NameTag") then
                player.Character.Head.NameTag.Enabled = false
            end
            if player.Character:FindFirstChild("ESPHighlight") then
                player.Character.ESPHighlight.Enabled = false
            end
        end
    end
end

local function updateHighlight(player)
    if not ESPEnabled then return end
    if player.Character and player.Character:FindFirstChild("ESPHighlight") and player.Character:FindFirstChild("Humanoid") then
        if player.Character.Humanoid.Health <= 0 then
            player.Character.ESPHighlight.FillColor = Color3.fromRGB(120, 0, 0)
        else
            player.Character.ESPHighlight.FillColor = Color3.fromRGB(255, 0, 0)
        end
    end
end

local function setupESP(player)
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.1)
            if ESPEnabled then
                createHighlight(player)
                createNameTag(player)
            end
        end)
        if player.Character and ESPEnabled then
            createHighlight(player)
            createNameTag(player)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupESP(player)
end

Players.PlayerAdded:Connect(function(player)
    setupESP(player)
end)

RunService.Heartbeat:Connect(function()
    if ESPEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character and player.Character:FindFirstChild("Humanoid") then
                    updateNameTag(player)
                    updateHighlight(player)
                end
            end
        end
    end
end)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 700, 0, 430)
MainFrame.Position = UDim2.new(0.5, -350, 1.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Visible = true

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 16)

local MainGradient = Instance.new("UIGradient", MainFrame)
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 200))
}
MainGradient.Rotation = 45

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 255, 220)
MainStroke.Transparency = 0.4

-- Тень ближе
local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.6

-- Верхняя панель (убраны серые квадраты)
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, -20, 0, 45)
TopBar.Position = UDim2.new(0, 10, 0, 5)
TopBar.BackgroundTransparency = 1
TopBar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Profima Client"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 28
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleStroke = Instance.new("UIStroke", Title)
TitleStroke.Thickness = 1
TitleStroke.Color = Color3.fromRGB(0, 0, 0)

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.AutoButtonColor = false

local CloseCorner = Instance.new("UICorner", CloseBtn)
CloseCorner.CornerRadius = UDim.new(1, 0)

local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Thickness = 1.5
CloseStroke.Color = Color3.fromRGB(255, 200, 200)
CloseStroke.Transparency = 0.2

CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
end)

CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
end)

-- Левая панель (убраны серые квадраты)
local LeftPanel = Instance.new("Frame", MainFrame)
LeftPanel.Size = UDim2.new(0, 170, 1, -70)
LeftPanel.Position = UDim2.new(0, 15, 0, 60)
LeftPanel.BackgroundTransparency = 1
LeftPanel.BorderSizePixel = 0

local LeftStroke = Instance.new("UIStroke", LeftPanel)
LeftStroke.Thickness = 1.5
LeftStroke.Color = Color3.fromRGB(0, 255, 220)
LeftStroke.Transparency = 0.6

-- Иконки разделов
local icons = {
    ["Об меню"] = "rbxassetid://3926305904",
    ["TP"] = "rbxassetid://3926307971",
    ["Noclip & Fly"] = "rbxassetid://3926305904",
    ["ESP & AIM"] = "rbxassetid://3926307971",
    ["Test 2"] = "rbxassetid://3926305904",
    ["Test 3"] = "rbxassetid://3926307971",
}

local sections = {"Об меню", "TP", "Noclip & Fly", "ESP & AIM", "Test 2", "Test 3"}
local buttons = {}

for i, name in ipairs(sections) do
    local btn = Instance.new("TextButton", LeftPanel)
    btn.Size = UDim2.new(1, -20, 0, 38)
    btn.Position = UDim2.new(0, 10, 0, (i - 1) * 45 + 10)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.2
    btn.Text = "    " .. name
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 18
    btn.AutoButtonColor = false
    btn.TextXAlignment = Enum.TextXAlignment.Left

    local c = Instance.new("UICorner", btn)
    c.CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(0, 255, 220)
    stroke.Transparency = 0.8

    local icon = Instance.new("ImageLabel", btn)
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Position = UDim2.new(0, 8, 0.5, -10)
    icon.BackgroundTransparency = 1
    icon.Image = icons[name]

    buttons[name] = {Button = btn, Stroke = stroke}
end

-- Правая панель (убраны серые квадраты)
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -210, 1, -80)
Content.Position = UDim2.new(0, 195, 0, 60)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0

local ContentStroke = Instance.new("UIStroke", Content)
ContentStroke.Thickness = 1.5
ContentStroke.Color = Color3.fromRGB(0, 255, 220)
ContentStroke.Transparency = 0.5

-- Об меню
local AboutText = Instance.new("TextLabel", Content)
AboutText.Size = UDim2.new(1, -30, 1, -30)
AboutText.Position = UDim2.new(0, 15, 0, 15)
AboutText.BackgroundTransparency = 1
AboutText.TextWrapped = true
AboutText.Text = "Добро пожаловать в Profima Client.\n\nСлева выбери раздел, чтобы управлять функциями."
AboutText.TextColor3 = Color3.fromRGB(230, 230, 230)
AboutText.Font = Enum.Font.Gotham
AboutText.TextSize = 22
AboutText.TextXAlignment = Enum.TextXAlignment.Left
AboutText.TextYAlignment = Enum.TextYAlignment.Top

-- TP раздел
local TpFrame = Instance.new("Frame", Content)
TpFrame.Size = UDim2.new(1, 0, 1, 0)
TpFrame.BackgroundTransparency = 1
TpFrame.Visible = false

local TpTitle = Instance.new("TextLabel", TpFrame)
TpTitle.Size = UDim2.new(1, -30, 0, 30)
TpTitle.Position = UDim2.new(0, 15, 0, 15)
TpTitle.BackgroundTransparency = 1
TpTitle.Text = "TP"
TpTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
TpTitle.Font = Enum.Font.GothamBold
TpTitle.TextSize = 24
TpTitle.TextXAlignment = Enum.TextXAlignment.Left

local GiveBtn = Instance.new("TextButton", TpFrame)
GiveBtn.Size = UDim2.new(0, 220, 0, 40)
GiveBtn.Position = UDim2.new(0, 15, 0, 60)
GiveBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 150)
GiveBtn.Text = "Выдать TP Tool"
GiveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GiveBtn.Font = Enum.Font.GothamBold
GiveBtn.TextSize = 20
GiveBtn.AutoButtonColor = false

local GiveCorner = Instance.new("UICorner", GiveBtn)
GiveCorner.CornerRadius = UDim.new(0, 10)

local GiveStroke = Instance.new("UIStroke", GiveBtn)
GiveStroke.Thickness = 1.5
GiveStroke.Color = Color3.fromRGB(0, 255, 220)
GiveStroke.Transparency = 0.3

GiveBtn.MouseEnter:Connect(function()
    TweenService:Create(GiveBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 230, 170)}):Play()
end)

GiveBtn.MouseLeave:Connect(function()
    TweenService:Create(GiveBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
end)

GiveBtn.MouseButton1Click:Connect(function()
    ClickSound:Play()
    GiveTpTool()
end)

local Desc1 = Instance.new("TextLabel", TpFrame)
Desc1.Size = UDim2.new(1, -30, 0, 25)
Desc1.Position = UDim2.new(0, 15, 0, 105)
Desc1.BackgroundTransparency = 1
Desc1.Text = "Выдаёт инструмент для телепортации по клику."
Desc1.TextColor3 = Color3.fromRGB(200, 200, 200)
Desc1.Font = Enum.Font.Gotham
Desc1.TextSize = 16
Desc1.TextXAlignment = Enum.TextXAlignment.Left

local Line1 = Instance.new("Frame", TpFrame)
Line1.Size = UDim2.new(1, -30, 0, 2)
Line1.Position = UDim2.new(0, 15, 0, 135)
Line1.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
Line1.BackgroundTransparency = 0.4

local CtrlLabel = Instance.new("TextLabel", TpFrame)
CtrlLabel.Size = UDim2.new(0, 250, 0, 30)
CtrlLabel.Position = UDim2.new(0, 15, 0, 150)
CtrlLabel.BackgroundTransparency = 1
CtrlLabel.Text = "Ctrl + Click to TP"
CtrlLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
CtrlLabel.Font = Enum.Font.Gotham
CtrlLabel.TextSize = 20
CtrlLabel.TextXAlignment = Enum.TextXAlignment.Left

local ToggleBackTP = Instance.new("Frame", TpFrame)
ToggleBackTP.Size = UDim2.new(0, 60, 0, 26)
ToggleBackTP.Position = UDim2.new(0, 260, 0, 150)
ToggleBackTP.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleBackTP.BackgroundTransparency = 0.2
ToggleBackTP.BorderSizePixel = 0

local ToggleBackTPCorner = Instance.new("UICorner", ToggleBackTP)
ToggleBackTPCorner.CornerRadius = UDim.new(1, 0)

local ToggleStrokeTP = Instance.new("UIStroke", ToggleBackTP)
ToggleStrokeTP.Thickness = 1.5
ToggleStrokeTP.Color = Color3.fromRGB(0, 255, 220)
ToggleStrokeTP.Transparency = 0.5

local ToggleCircleTP = Instance.new("Frame", ToggleBackTP)
ToggleCircleTP.Size = UDim2.new(0, 22, 0, 22)
ToggleCircleTP.Position = UDim2.new(0, 2, 0.5, -11)
ToggleCircleTP.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
ToggleCircleTP.BorderSizePixel = 0

local ToggleCircleTPCorner = Instance.new("UICorner", ToggleCircleTP)
ToggleCircleTPCorner.CornerRadius = UDim.new(1, 0)

local ToggleCircleTPStroke = Instance.new("UIStroke", ToggleCircleTP)
ToggleCircleTPStroke.Thickness = 1.5
ToggleCircleTPStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleCircleTPStroke.Transparency = 0.2

local ToggleBtnTP = Instance.new("TextButton", ToggleBackTP)
ToggleBtnTP.Size = UDim2.new(1, 0, 1, 0)
ToggleBtnTP.BackgroundTransparency = 1
ToggleBtnTP.Text = ""
ToggleBtnTP.AutoButtonColor = false

local Desc2 = Instance.new("TextLabel", TpFrame)
Desc2.Size = UDim2.new(1, -30, 0, 25)
Desc2.Position = UDim2.new(0, 15, 0, 185)
Desc2.BackgroundTransparency = 1
Desc2.Text = "Телепортирует при удержании CTRL и клике мышью."
Desc2.TextColor3 = Color3.fromRGB(200, 200, 200)
Desc2.Font = Enum.Font.Gotham
Desc2.TextSize = 16
Desc2.TextXAlignment = Enum.TextXAlignment.Left

local function SetTpToggle(state)
    CtrlTpEnabled = state
    ToggleSound:Play()
    if state then
        TweenService:Create(ToggleBackTP, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(ToggleCircleTP, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(ToggleBackTP, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(ToggleCircleTP, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetTpToggle(false)

ToggleBtnTP.MouseButton1Click:Connect(function()
    SetTpToggle(not CtrlTpEnabled)
end)

-- Noclip & Fly раздел
local NFFrame = Instance.new("Frame", Content)
NFFrame.Size = UDim2.new(1, 0, 1, 0)
NFFrame.BackgroundTransparency = 1
NFFrame.Visible = false

local NFTitle = Instance.new("TextLabel", NFFrame)
NFTitle.Size = UDim2.new(1, -30, 0, 30)
NFTitle.Position = UDim2.new(0, 15, 0, 15)
NFTitle.BackgroundTransparency = 1
NFTitle.Text = "Noclip & Fly"
NFTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
NFTitle.Font = Enum.Font.GothamBold
NFTitle.TextSize = 24
NFTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Fly toggle
local FlyLabel = Instance.new("TextLabel", NFFrame)
FlyLabel.Size = UDim2.new(0, 200, 0, 30)
FlyLabel.Position = UDim2.new(0, 15, 0, 60)
FlyLabel.BackgroundTransparency = 1
FlyLabel.Text = "Fly"
FlyLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
FlyLabel.Font = Enum.Font.Gotham
FlyLabel.TextSize = 20
FlyLabel.TextXAlignment = Enum.TextXAlignment.Left

local FlyBack = Instance.new("Frame", NFFrame)
FlyBack.Size = UDim2.new(0, 60, 0, 26)
FlyBack.Position = UDim2.new(0, 260, 0, 60)
FlyBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FlyBack.BackgroundTransparency = 0.2
FlyBack.BorderSizePixel = 0

local FlyBackCorner = Instance.new("UICorner", FlyBack)
FlyBackCorner.CornerRadius = UDim.new(1, 0)

local FlyStroke = Instance.new("UIStroke", FlyBack)
FlyStroke.Thickness = 1.5
FlyStroke.Color = Color3.fromRGB(0, 255, 220)
FlyStroke.Transparency = 0.5

local FlyCircle = Instance.new("Frame", FlyBack)
FlyCircle.Size = UDim2.new(0, 22, 0, 22)
FlyCircle.Position = UDim2.new(0, 2, 0.5, -11)
FlyCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
FlyCircle.BorderSizePixel = 0

local FlyCircleCorner = Instance.new("UICorner", FlyCircle)
FlyCircleCorner.CornerRadius = UDim.new(1, 0)

local FlyCircleStroke = Instance.new("UIStroke", FlyCircle)
FlyCircleStroke.Thickness = 1.5
FlyCircleStroke.Color = Color3.fromRGB(255, 255, 255)
FlyCircleStroke.Transparency = 0.2

local FlyBtn = Instance.new("TextButton", FlyBack)
FlyBtn.Size = UDim2.new(1, 0, 1, 0)
FlyBtn.BackgroundTransparency = 1
FlyBtn.Text = ""
FlyBtn.AutoButtonColor = false

-- NoClip toggle
local NCLabel = Instance.new("TextLabel", NFFrame)
NCLabel.Size = UDim2.new(0, 200, 0, 30)
NCLabel.Position = UDim2.new(0, 15, 0, 100)
NCLabel.BackgroundTransparency = 1
NCLabel.Text = "NoClip"
NCLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
NCLabel.Font = Enum.Font.Gotham
NCLabel.TextSize = 20
NCLabel.TextXAlignment = Enum.TextXAlignment.Left

local NCBack = Instance.new("Frame", NFFrame)
NCBack.Size = UDim2.new(0, 60, 0, 26)
NCBack.Position = UDim2.new(0, 260, 0, 100)
NCBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
NCBack.BackgroundTransparency = 0.2
NCBack.BorderSizePixel = 0

local NCBackCorner = Instance.new("UICorner", NCBack)
NCBackCorner.CornerRadius = UDim.new(1, 0)

local NCStroke = Instance.new("UIStroke", NCBack)
NCStroke.Thickness = 1.5
NCStroke.Color = Color3.fromRGB(0, 255, 220)
NCStroke.Transparency = 0.5

local NCCircle = Instance.new("Frame", NCBack)
NCCircle.Size = UDim2.new(0, 22, 0, 22)
NCCircle.Position = UDim2.new(0, 2, 0.5, -11)
NCCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
NCCircle.BorderSizePixel = 0

local NCCircleCorner = Instance.new("UICorner", NCCircle)
NCCircleCorner.CornerRadius = UDim.new(1, 0)

local NCCircleStroke = Instance.new("UIStroke", NCCircle)
NCCircleStroke.Thickness = 1.5
NCCircleStroke.Color = Color3.fromRGB(255, 255, 255)
NCCircleStroke.Transparency = 0.2

local NCBtn = Instance.new("TextButton", NCBack)
NCBtn.Size = UDim2.new(1, 0, 1, 0)
NCBtn.BackgroundTransparency = 1
NCBtn.Text = ""
NCBtn.AutoButtonColor = false

-- Fling toggle
local FLabel = Instance.new("TextLabel", NFFrame)
FLabel.Size = UDim2.new(0, 200, 0, 30)
FLabel.Position = UDim2.new(0, 15, 0, 140)
FLabel.BackgroundTransparency = 1
FLabel.Text = "Fling"
FLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
FLabel.Font = Enum.Font.Gotham
FLabel.TextSize = 20
FLabel.TextXAlignment = Enum.TextXAlignment.Left

local FBack = Instance.new("Frame", NFFrame)
FBack.Size = UDim2.new(0, 60, 0, 26)
FBack.Position = UDim2.new(0, 260, 0, 140)
FBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FBack.BackgroundTransparency = 0.2
FBack.BorderSizePixel = 0

local FBackCorner = Instance.new("UICorner", FBack)
FBackCorner.CornerRadius = UDim.new(1, 0)

local FStroke = Instance.new("UIStroke", FBack)
FStroke.Thickness = 1.5
FStroke.Color = Color3.fromRGB(0, 255, 220)
FStroke.Transparency = 0.5

local FCircle = Instance.new("Frame", FBack)
FCircle.Size = UDim2.new(0, 22, 0, 22)
FCircle.Position = UDim2.new(0, 2, 0.5, -11)
FCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
FCircle.BorderSizePixel = 0

local FCircleCorner = Instance.new("UICorner", FCircle)
FCircleCorner.CornerRadius = UDim.new(1, 0)

local FCircleStroke = Instance.new("UIStroke", FCircle)
FCircleStroke.Thickness = 1.5
FCircleStroke.Color = Color3.fromRGB(255, 255, 255)
FCircleStroke.Transparency = 0.2

local FBtn = Instance.new("TextButton", FBack)
FBtn.Size = UDim2.new(1, 0, 1, 0)
FBtn.BackgroundTransparency = 1
FBtn.Text = ""
FBtn.AutoButtonColor = false

local function SetFlyToggle(state)
    ToggleSound:Play()
    if state then
        enableFly()
        TweenService:Create(FlyBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(FlyCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        disableFly()
        TweenService:Create(FlyBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(FlyCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

local function SetNCToggle(state)
    ToggleSound:Play()
    if state then
        enableNoClip()
        TweenService:Create(NCBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(NCCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        disableNoClip()
        TweenService:Create(NCBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(NCCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

local function SetFlingToggle(state)
    ToggleSound:Play()
    if state then
        enableFling()
        TweenService:Create(FBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(FCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        disableFling()
        TweenService:Create(FBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(FCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetFlyToggle(false)
SetNCToggle(false)
SetFlingToggle(false)

FlyBtn.MouseButton1Click:Connect(function()
    SetFlyToggle(not flying)
end)

NCBtn.MouseButton1Click:Connect(function()
    SetNCToggle(not noClip)
end)

FBtn.MouseButton1Click:Connect(function()
    SetFlingToggle(not flinging)
end)

-- ESP & AIM раздел
local EAFrame = Instance.new("Frame", Content)
EAFrame.Size = UDim2.new(1, 0, 1, 0)
EAFrame.BackgroundTransparency = 1
EAFrame.Visible = false

local EATitle = Instance.new("TextLabel", EAFrame)
EATitle.Size = UDim2.new(1, -30, 0, 30)
EATitle.Position = UDim2.new(0, 15, 0, 15)
EATitle.BackgroundTransparency = 1
EATitle.Text = "ESP & AIM"
EATitle.TextColor3 = Color3.fromRGB(230, 230, 230)
EATitle.Font = Enum.Font.GothamBold
EATitle.TextSize = 24
EATitle.TextXAlignment = Enum.TextXAlignment.Left

-- ESP toggle
local ESPLabel = Instance.new("TextLabel", EAFrame)
ESPLabel.Size = UDim2.new(0, 200, 0, 30)
ESPLabel.Position = UDim2.new(0, 15, 0, 60)
ESPLabel.BackgroundTransparency = 1
ESPLabel.Text = "ESP"
ESPLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
ESPLabel.Font = Enum.Font.Gotham
ESPLabel.TextSize = 20
ESPLabel.TextXAlignment = Enum.TextXAlignment.Left

local ESPBack = Instance.new("Frame", EAFrame)
ESPBack.Size = UDim2.new(0, 60, 0, 26)
ESPBack.Position = UDim2.new(0, 260, 0, 60)
ESPBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ESPBack.BackgroundTransparency = 0.2
ESPBack.BorderSizePixel = 0

local ESPBackCorner = Instance.new("UICorner", ESPBack)
ESPBackCorner.CornerRadius = UDim.new(1, 0)

local ESPStroke = Instance.new("UIStroke", ESPBack)
ESPStroke.Thickness = 1.5
ESPStroke.Color = Color3.fromRGB(0, 255, 220)
ESPStroke.Transparency = 0.5

local ESPCircle = Instance.new("Frame", ESPBack)
ESPCircle.Size = UDim2.new(0, 22, 0, 22)
ESPCircle.Position = UDim2.new(0, 2, 0.5, -11)
ESPCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
ESPCircle.BorderSizePixel = 0

local ESPCircleCorner = Instance.new("UICorner", ESPCircle)
ESPCircleCorner.CornerRadius = UDim.new(1, 0)

local ESPCircleStroke = Instance.new("UIStroke", ESPCircle)
ESPCircleStroke.Thickness = 1.5
ESPCircleStroke.Color = Color3.fromRGB(255, 255, 255)
ESPCircleStroke.Transparency = 0.2

local ESPBtn = Instance.new("TextButton", ESPBack)
ESPBtn.Size = UDim2.new(1, 0, 1, 0)
ESPBtn.BackgroundTransparency = 1
ESPBtn.Text = ""
ESPBtn.AutoButtonColor = false

-- ESP Radius slider
local ESPRadiusLabel = Instance.new("TextLabel", EAFrame)
ESPRadiusLabel.Size = UDim2.new(0, 200, 0, 25)
ESPRadiusLabel.Position = UDim2.new(0, 15, 0, 95)
ESPRadiusLabel.BackgroundTransparency = 1
ESPRadiusLabel.Text = "ESP Radius: " .. ESPRadius
ESPRadiusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ESPRadiusLabel.Font = Enum.Font.Gotham
ESPRadiusLabel.TextSize = 16
ESPRadiusLabel.TextXAlignment = Enum.TextXAlignment.Left

local ESPRadiusBack = Instance.new("Frame", EAFrame)
ESPRadiusBack.Size = UDim2.new(0, 260, 0, 6)
ESPRadiusBack.Position = UDim2.new(0, 15, 0, 125)
ESPRadiusBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ESPRadiusBack.BorderSizePixel = 0

local ESPRadiusBackCorner = Instance.new("UICorner", ESPRadiusBack)
ESPRadiusBackCorner.CornerRadius = UDim.new(1, 0)

local ESPRadiusFill = Instance.new("Frame", ESPRadiusBack)
ESPRadiusFill.Size = UDim2.new(ESPRadius / 3000, 0, 1, 0)
ESPRadiusFill.Position = UDim2.new(0, 0, 0, 0)
ESPRadiusFill.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
ESPRadiusFill.BorderSizePixel = 0

local ESPRadiusFillCorner = Instance.new("UICorner", ESPRadiusFill)
ESPRadiusFillCorner.CornerRadius = UDim.new(1, 0)

local draggingRadius = false

ESPRadiusBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingRadius = true
    end
end)

ESPRadiusBack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingRadius = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingRadius and input.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = (input.Position.X - ESPRadiusBack.AbsolutePosition.X) / ESPRadiusBack.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        ESPRadius = math.floor(rel * 3000)
        ESPRadiusFill.Size = UDim2.new(rel, 0, 1, 0)
        ESPRadiusLabel.Text = "ESP Radius: " .. ESPRadius
    end
end)

local function SetESPToggle(state)
    ESPEnabled = state
    ToggleSound:Play()
    if state then
        TweenService:Create(ESPBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(ESPCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                createHighlight(player)
                createNameTag(player)
            end
        end
    else
        TweenService:Create(ESPBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(ESPCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                clearESPForPlayer(player)
            end
        end
    end
end

SetESPToggle(false)

ESPBtn.MouseButton1Click:Connect(function()
    SetESPToggle(not ESPEnabled)
end)

-- Разделитель между ESP и AIM
local LineEA = Instance.new("Frame", EAFrame)
LineEA.Size = UDim2.new(1, -30, 0, 2)
LineEA.Position = UDim2.new(0, 15, 0, 155)
LineEA.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
LineEA.BackgroundTransparency = 0.4

-- AIM toggle
local AIMLabel = Instance.new("TextLabel", EAFrame)
AIMLabel.Size = UDim2.new(0, 200, 0, 30)
AIMLabel.Position = UDim2.new(0, 15, 0, 170)
AIMLabel.BackgroundTransparency = 1
AIMLabel.Text = "Aimbot"
AIMLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
AIMLabel.Font = Enum.Font.Gotham
AIMLabel.TextSize = 20
AIMLabel.TextXAlignment = Enum.TextXAlignment.Left

local AIMBack = Instance.new("Frame", EAFrame)
AIMBack.Size = UDim2.new(0, 60, 0, 26)
AIMBack.Position = UDim2.new(0, 260, 0, 170)
AIMBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AIMBack.BackgroundTransparency = 0.2
AIMBack.BorderSizePixel = 0

local AIMBackCorner = Instance.new("UICorner", AIMBack)
AIMBackCorner.CornerRadius = UDim.new(1, 0)

local AIMStroke = Instance.new("UIStroke", AIMBack)
AIMStroke.Thickness = 1.5
AIMStroke.Color = Color3.fromRGB(0, 255, 220)
AIMStroke.Transparency = 0.5

local AIMCircle = Instance.new("Frame", AIMBack)
AIMCircle.Size = UDim2.new(0, 22, 0, 22)
AIMCircle.Position = UDim2.new(0, 2, 0.5, -11)
AIMCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
AIMCircle.BorderSizePixel = 0

local AIMCircleCorner = Instance.new("UICorner", AIMCircle)
AIMCircleCorner.CornerRadius = UDim.new(1, 0)

local AIMCircleStroke = Instance.new("UIStroke", AIMCircle)
AIMCircleStroke.Thickness = 1.5
AIMCircleStroke.Color = Color3.fromRGB(255, 255, 255)
AIMCircleStroke.Transparency = 0.2

local AIMBtn = Instance.new("TextButton", AIMBack)
AIMBtn.Size = UDim2.new(1, 0, 1, 0)
AIMBtn.BackgroundTransparency = 1
AIMBtn.Text = ""
AIMBtn.AutoButtonColor = false

local function SetAIMToggle(state)
    aimbotEnabled = state
    ToggleSound:Play()
    if state then
        TweenService:Create(AIMBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(AIMCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(AIMBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(AIMCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetAIMToggle(false)

AIMBtn.MouseButton1Click:Connect(function()
    SetAIMToggle(not aimbotEnabled)
end)

-- Aim FOV slider
local FOVLabel = Instance.new("TextLabel", EAFrame)
FOVLabel.Size = UDim2.new(0, 200, 0, 25)
FOVLabel.Position = UDim2.new(0, 15, 0, 205)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "Aimbot FOV: " .. aimFov
FOVLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextSize = 16
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left

local FOVBack = Instance.new("Frame", EAFrame)
FOVBack.Size = UDim2.new(0, 260, 0, 6)
FOVBack.Position = UDim2.new(0, 15, 0, 235)
FOVBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
FOVBack.BorderSizePixel = 0

local FOVBackCorner = Instance.new("UICorner", FOVBack)
FOVBackCorner.CornerRadius = UDim.new(1, 0)

local FOVFill = Instance.new("Frame", FOVBack)
FOVFill.Size = UDim2.new(aimFov / 1000, 0, 1, 0)
FOVFill.Position = UDim2.new(0, 0, 0, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
FOVFill.BorderSizePixel = 0

local FOVFillCorner = Instance.new("UICorner", FOVFill)
FOVFillCorner.CornerRadius = UDim.new(1, 0)

local draggingFOV = false

FOVBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFOV = true
    end
end)

FOVBack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFOV = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingFOV and input.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = (input.Position.X - FOVBack.AbsolutePosition.X) / FOVBack.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        aimFov = math.floor(rel * 1000)
        FOVFill.Size = UDim2.new(rel, 0, 1, 0)
        FOVLabel.Text = "Aimbot FOV: " .. aimFov
    end
end)

-- FOV Visibility toggle
local FOVVisLabel = Instance.new("TextLabel", EAFrame)
FOVVisLabel.Size = UDim2.new(0, 200, 0, 30)
FOVVisLabel.Position = UDim2.new(0, 15, 0, 255)
FOVVisLabel.BackgroundTransparency = 1
FOVVisLabel.Text = "FOV Visibility"
FOVVisLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
FOVVisLabel.Font = Enum.Font.Gotham
FOVVisLabel.TextSize = 18
FOVVisLabel.TextXAlignment = Enum.TextXAlignment.Left

local FOVVisBack = Instance.new("Frame", EAFrame)
FOVVisBack.Size = UDim2.new(0, 60, 0, 26)
FOVVisBack.Position = UDim2.new(0, 260, 0, 255)
FOVVisBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FOVVisBack.BackgroundTransparency = 0.2
FOVVisBack.BorderSizePixel = 0

local FOVVisBackCorner = Instance.new("UICorner", FOVVisBack)
FOVVisBackCorner.CornerRadius = UDim.new(1, 0)

local FOVVisStroke = Instance.new("UIStroke", FOVVisBack)
FOVVisStroke.Thickness = 1.5
FOVVisStroke.Color = Color3.fromRGB(0, 255, 220)
FOVVisStroke.Transparency = 0.5

local FOVVisCircle = Instance.new("Frame", FOVVisBack)
FOVVisCircle.Size = UDim2.new(0, 22, 0, 22)
FOVVisCircle.Position = UDim2.new(0, 2, 0.5, -11)
FOVVisCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
FOVVisCircle.BorderSizePixel = 0

local FOVVisCircleCorner = Instance.new("UICorner", FOVVisCircle)
FOVVisCircleCorner.CornerRadius = UDim.new(1, 0)

local FOVVisCircleStroke = Instance.new("UIStroke", FOVVisCircle)
FOVVisCircleStroke.Thickness = 1.5
FOVVisCircleStroke.Color = Color3.fromRGB(255, 255, 255)
FOVVisCircleStroke.Transparency = 0.2

local FOVVisBtn = Instance.new("TextButton", FOVVisBack)
FOVVisBtn.Size = UDim2.new(1, 0, 1, 0)
FOVVisBtn.BackgroundTransparency = 1
FOVVisBtn.Text = ""
FOVVisBtn.AutoButtonColor = false

local function SetFOVVis(state)
    fovVisible = state
    ToggleSound:Play()
    if state then
        TweenService:Create(FOVVisBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(FOVVisCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(FOVVisBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(FOVVisCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetFOVVis(true)

FOVVisBtn.MouseButton1Click:Connect(function()
    SetFOVVis(not fovVisible)
end)

-- Wall Check toggle
local WCLabel = Instance.new("TextLabel", EAFrame)
WCLabel.Size = UDim2.new(0, 200, 0, 30)
WCLabel.Position = UDim2.new(0, 15, 0, 290)
WCLabel.BackgroundTransparency = 1
WCLabel.Text = "Wall Check"
WCLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
WCLabel.Font = Enum.Font.Gotham
WCLabel.TextSize = 18
WCLabel.TextXAlignment = Enum.TextXAlignment.Left

local WCBack = Instance.new("Frame", EAFrame)
WCBack.Size = UDim2.new(0, 60, 0, 26)
WCBack.Position = UDim2.new(0, 260, 0, 290)
WCBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
WCBack.BackgroundTransparency = 0.2
WCBack.BorderSizePixel = 0

local WCBackCorner = Instance.new("UICorner", WCBack)
WCBackCorner.CornerRadius = UDim.new(1, 0)

local WCStroke = Instance.new("UIStroke", WCBack)
WCStroke.Thickness = 1.5
WCStroke.Color = Color3.fromRGB(0, 255, 220)
WCStroke.Transparency = 0.5

local WCCircle = Instance.new("Frame", WCBack)
WCCircle.Size = UDim2.new(0, 22, 0, 22)
WCCircle.Position = UDim2.new(0, 2, 0.5, -11)
WCCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
WCCircle.BorderSizePixel = 0

local WCCircleCorner = Instance.new("UICorner", WCCircle)
WCCircleCorner.CornerRadius = UDim.new(1, 0)

local WCCircleStroke = Instance.new("UIStroke", WCCircle)
WCCircleStroke.Thickness = 1.5
WCCircleStroke.Color = Color3.fromRGB(255, 255, 255)
WCCircleStroke.Transparency = 0.2

local WCBtn = Instance.new("TextButton", WCBack)
WCBtn.Size = UDim2.new(1, 0, 1, 0)
WCBtn.BackgroundTransparency = 1
WCBtn.Text = ""
WCBtn.AutoButtonColor = false

local function SetWCToggle(state)
    wallCheck = state
    ToggleSound:Play()
    if state then
        TweenService:Create(WCBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(WCCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(WCBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(WCCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetWCToggle(true)

WCBtn.MouseButton1Click:Connect(function()
    SetWCToggle(not wallCheck)
end)

-- Smoothing slider
local SmoothLabel = Instance.new("TextLabel", EAFrame)
SmoothLabel.Size = UDim2.new(0, 200, 0, 25)
SmoothLabel.Position = UDim2.new(0, 15, 0, 325)
SmoothLabel.BackgroundTransparency = 1
SmoothLabel.Text = "Smoothing: " .. math.floor((1 - smoothing) * 100)
SmoothLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SmoothLabel.Font = Enum.Font.Gotham
SmoothLabel.TextSize = 16
SmoothLabel.TextXAlignment = Enum.TextXAlignment.Left

local SmoothBack = Instance.new("Frame", EAFrame)
SmoothBack.Size = UDim2.new(0, 260, 0, 6)
SmoothBack.Position = UDim2.new(0, 15, 0, 355)
SmoothBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SmoothBack.BorderSizePixel = 0

local SmoothBackCorner = Instance.new("UICorner", SmoothBack)
SmoothBackCorner.CornerRadius = UDim.new(1, 0)

local SmoothFill = Instance.new("Frame", SmoothBack)
local smoothPercent = (1 - smoothing)
SmoothFill.Size = UDim2.new(smoothPercent, 0, 1, 0)
SmoothFill.Position = UDim2.new(0, 0, 0, 0)
SmoothFill.BackgroundColor3 = Color3.fromRGB(0, 255, 220)
SmoothFill.BorderSizePixel = 0

local SmoothFillCorner = Instance.new("UICorner", SmoothFill)
SmoothFillCorner.CornerRadius = UDim.new(1, 0)

local draggingSmooth = false

SmoothBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSmooth = true
    end
end)

SmoothBack.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSmooth = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if draggingSmooth and input.UserInputType == Enum.UserInputType.MouseMovement then
        local rel = (input.Position.X - SmoothBack.AbsolutePosition.X) / SmoothBack.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        smoothing = 1 - rel
        SmoothFill.Size = UDim2.new(rel, 0, 1, 0)
        SmoothLabel.Text = "Smoothing: " .. math.floor(rel * 100)
    end
end)

-- FOV Color (просто две кнопки: базовый и таргет)
local FOVColorLabel = Instance.new("TextLabel", EAFrame)
FOVColorLabel.Size = UDim2.new(0, 200, 0, 25)
FOVColorLabel.Position = UDim2.new(0, 300, 0, 205)
FOVColorLabel.BackgroundTransparency = 1
FOVColorLabel.Text = "FOV Color"
FOVColorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FOVColorLabel.Font = Enum.Font.Gotham
FOVColorLabel.TextSize = 16
FOVColorLabel.TextXAlignment = Enum.TextXAlignment.Left

local BaseColorBtn = Instance.new("TextButton", EAFrame)
BaseColorBtn.Size = UDim2.new(0, 40, 0, 20)
BaseColorBtn.Position = UDim2.new(0, 300, 0, 235)
BaseColorBtn.BackgroundColor3 = circleColor
BaseColorBtn.Text = ""
BaseColorBtn.AutoButtonColor = false

local BaseColorCorner = Instance.new("UICorner", BaseColorBtn)
BaseColorCorner.CornerRadius = UDim.new(0, 6)

local TargetColorBtn = Instance.new("TextButton", EAFrame)
TargetColorBtn.Size = UDim2.new(0, 40, 0, 20)
TargetColorBtn.Position = UDim2.new(0, 350, 0, 235)
TargetColorBtn.BackgroundColor3 = targetedCircleColor
TargetColorBtn.Text = ""
TargetColorBtn.AutoButtonColor = false

local TargetColorCorner = Instance.new("UICorner", TargetColorBtn)
TargetColorCorner.CornerRadius = UDim.new(0, 6)

BaseColorBtn.MouseButton1Click:Connect(function()
    circleColor = Color3.fromRGB(0, 255, 255)
    fovCircle.Color = circleColor
    BaseColorBtn.BackgroundColor3 = circleColor
end)

TargetColorBtn.MouseButton1Click:Connect(function()
    targetedCircleColor = Color3.fromRGB(0, 255, 0)
    TargetColorBtn.BackgroundColor3 = targetedCircleColor
end)

-- Rainbow FOV toggle
local RFLabel = Instance.new("TextLabel", EAFrame)
RFLabel.Size = UDim2.new(0, 200, 0, 30)
RFLabel.Position = UDim2.new(0, 300, 0, 260)
RFLabel.BackgroundTransparency = 1
RFLabel.Text = "Rainbow FOV"
RFLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
RFLabel.Font = Enum.Font.Gotham
RFLabel.TextSize = 18
RFLabel.TextXAlignment = Enum.TextXAlignment.Left

local RFBack = Instance.new("Frame", EAFrame)
RFBack.Size = UDim2.new(0, 60, 0, 26)
RFBack.Position = UDim2.new(0, 300, 0, 290)
RFBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
RFBack.BackgroundTransparency = 0.2
RFBack.BorderSizePixel = 0

local RFBackCorner = Instance.new("UICorner", RFBack)
RFBackCorner.CornerRadius = UDim.new(1, 0)

local RFStroke = Instance.new("UIStroke", RFBack)
RFStroke.Thickness = 1.5
RFStroke.Color = Color3.fromRGB(0, 255, 220)
RFStroke.Transparency = 0.5

local RFCircle = Instance.new("Frame", RFBack)
RFCircle.Size = UDim2.new(0, 22, 0, 22)
RFCircle.Position = UDim2.new(0, 2, 0.5, -11)
RFCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
RFCircle.BorderSizePixel = 0

local RFCircleCorner = Instance.new("UICorner", RFCircle)
RFCircleCorner.CornerRadius = UDim.new(1, 0)

local RFCircleStroke = Instance.new("UIStroke", RFCircle)
RFCircleStroke.Thickness = 1.5
RFCircleStroke.Color = Color3.fromRGB(255, 255, 255)
RFCircleStroke.Transparency = 0.2

local RFBtn = Instance.new("TextButton", RFBack)
RFBtn.Size = UDim2.new(1, 0, 1, 0)
RFBtn.BackgroundTransparency = 1
RFBtn.Text = ""
RFBtn.AutoButtonColor = false

local function SetRFToggle(state)
    rainbowFov = state
    ToggleSound:Play()
    if state then
        TweenService:Create(RFBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(0, 200, 150)}):Play()
        TweenService:Create(RFCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    else
        TweenService:Create(RFBack, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
        TweenService:Create(RFCircle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0.5, -11), BackgroundColor3 = Color3.fromRGB(200, 200, 200)}):Play()
    end
end

SetRFToggle(false)

RFBtn.MouseButton1Click:Connect(function()
    SetRFToggle(not rainbowFov)
end)

-- Подсветка кнопок слева
local function HighlightButton(name)
    for sec, data in pairs(buttons) do
        local btn = data.Button
        local stroke = data.Stroke

        if sec == name then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                BackgroundTransparency = 0.05,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()

            TweenService:Create(stroke, TweenInfo.new(0.15), {
                Transparency = 0.1
            }):Play()
        else
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                BackgroundTransparency = 0.2,
                TextColor3 = Color3.fromRGB(220, 220, 220)
            }):Play()

            TweenService:Create(stroke, TweenInfo.new(0.15), {
                Transparency = 0.8
            }):Play()
        end
    end
end

local function ShowSection(name)
    AboutText.Visible = false
    TpFrame.Visible = false
    NFFrame.Visible = false
    EAFrame.Visible = false

    if name == "Об меню" then
        AboutText.Visible = true
    elseif name == "TP" then
        TpFrame.Visible = true
    elseif name == "Noclip & Fly" then
        NFFrame.Visible = true
    elseif name == "ESP & AIM" then
        EAFrame.Visible = true
    end

    HighlightButton(name)
    SwitchSound:Play()
end

for name, data in pairs(buttons) do
    data.Button.MouseButton1Click:Connect(function()
        ShowSection(name)
    end)
end

ShowSection("Об меню")

-- Анимация появления
task.wait(0.1)
ResetCharacterPhysics()
OpenSound:Play()
TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 12}):Play()
TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -350, 0.5, -215),
    BackgroundTransparency = 0.25
}):Play()

-- Закрытие крестиком
CloseBtn.MouseButton1Click:Connect(function()
    CanToggle = false

    TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 0}):Play()
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -350, 1.2, 0),
        BackgroundTransparency = 0.6
    }):Play()

    task.wait(0.35)
    MainFrame.Visible = false
end)

-- RightShift скрыть/показать
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift and CanToggle then
        if MainFrame.Visible then
            TweenService:Create(Blur, TweenInfo.new(0.3), {Size = 0}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -350, 1.2, 0),
                BackgroundTransparency = 0.6
            }):Play()

            task.wait(0.35)
            MainFrame.Visible = false
        else
            MainFrame.Visible = true
            OpenSound:Play()
            TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 12}):Play()
            TweenService:Create(MainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, -350, 0.5, -215),
                BackgroundTransparency = 0.25
            }):Play()
        end
    end
end)

-- Перетаскивание окна
local dragging = false
local dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
