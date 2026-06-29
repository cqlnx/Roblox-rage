local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local workspaceCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

local isShiftLock = false
local cameraYaw = 0
local cameraPitch = 0
local enabled = false
local currentTarget = nil
local lastShotTime = 0
local aimAssist = false
local targetHealthCache = {}

local spinAngle = 0
local SPIN_SPEED = 25
local CAMERA_OFFSET = Vector3.new(0, 2.5, 8)
local SENSITIVITY = 0.5
local TOGGLE_KEY = Enum.KeyCode.RightShift

-- Hitmarker system
local hitmarkers = {}

local function createHitmarker()
    local size = 12
    local lines = {}
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Visible = true
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Thickness = 2
        lines[i] = line
    end
    local center = UserInputService:GetMouseLocation()
    lines[1].From = Vector2.new(center.X - size, center.Y - size)
    lines[1].To = Vector2.new(center.X - size/2, center.Y - size/2)
    lines[2].From = Vector2.new(center.X + size, center.Y - size)
    lines[2].To = Vector2.new(center.X + size/2, center.Y - size/2)
    lines[3].From = Vector2.new(center.X - size, center.Y + size)
    lines[3].To = Vector2.new(center.X - size/2, center.Y + size/2)
    lines[4].From = Vector2.new(center.X + size, center.Y + size)
    lines[4].To = Vector2.new(center.X + size/2, center.Y + size/2)
    return {lines = lines, time = tick()}
end

-- ESP System
local espBoxes = {}

local function createESP()
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 255)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Color3.fromRGB(0, 255, 255)
    name.Size = 13
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    local health = Drawing.new("Line")
    health.Visible = false
    health.Color = Color3.fromRGB(0, 255, 0)
    health.Thickness = 3
    
    local healthBg = Drawing.new("Line")
    healthBg.Visible = false
    healthBg.Color = Color3.fromRGB(50, 50, 50)
    healthBg.Thickness = 3
    
    local distance = Drawing.new("Text")
    distance.Visible = false
    distance.Color = Color3.fromRGB(255, 255, 255)
    distance.Size = 11
    distance.Center = true
    distance.Outline = true
    distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    return {box = box, name = name, health = health, healthBg = healthBg, distance = distance}
end

local function updateESP(player)
    if not espBoxes[player] then
        espBoxes[player] = createESP()
    end
    
    local esp = espBoxes[player]
    local character = player.Character
    if not character then
        esp.box.Visible = false
        esp.name.Visible = false
        esp.health.Visible = false
        esp.healthBg.Visible = false
        esp.distance.Visible = false
        return
    end
    
    local head = character:FindFirstChild("Head")
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not root or not humanoid then
        esp.box.Visible = false
        esp.name.Visible = false
        esp.health.Visible = false
        esp.healthBg.Visible = false
        esp.distance.Visible = false
        return
    end
    
    -- Track health changes for hitmarkers
    local currentHealth = humanoid.Health
    local prevHealth = targetHealthCache[player] or currentHealth
    if player == currentTarget and currentHealth < prevHealth and currentHealth > 0 then
        -- Damage dealt! Show hitmarker
        table.insert(hitmarkers, createHitmarker())
    end
    targetHealthCache[player] = currentHealth
    
    local headPos, headOnScreen = workspaceCamera:WorldToViewportPoint(head.Position)
    local rootPos, rootOnScreen = workspaceCamera:WorldToViewportPoint(root.Position)
    
    if not headOnScreen or not rootOnScreen then
        esp.box.Visible = false
        esp.name.Visible = false
        esp.health.Visible = false
        esp.healthBg.Visible = false
        esp.distance.Visible = false
        return
    end
    
    local height = math.abs(headPos.Y - rootPos.Y) * 2.2
    local width = height * 0.45
    local centerX = rootPos.X
    local centerY = (headPos.Y + rootPos.Y) / 2
    
    local isTarget = (player == currentTarget)
    
    -- Box with glow effect (target gets different color)
    local espBox = esp.box
    espBox.Visible = true
    espBox.Position = Vector2.new(centerX - width/2, centerY - height/2)
    espBox.Size = Vector2.new(width, height)
    
    if isTarget then
        espBox.Color = Color3.fromRGB(255, 0, 0)
        espBox.Thickness = 3
        espBox.Transparency = 0.8
    else
        espBox.Color = Color3.fromRGB(0, 255, 255)
        espBox.Thickness = 2
        espBox.Transparency = 1
    end
    
    -- Name (target gets red)
    local espName = esp.name
    espName.Visible = true
    espName.Text = player.Name
    espName.Position = Vector2.new(centerX, headPos.Y - 20)
    espName.Color = isTarget and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 255)
    
    -- Health bar background
    local healthBg = esp.healthBg
    healthBg.Visible = true
    local barWidth = width
    local barX = centerX - barWidth/2
    local barY = centerY + height/2 + 4
    healthBg.From = Vector2.new(barX, barY)
    healthBg.To = Vector2.new(barX + barWidth, barY)
    
    -- Health bar (target gets red tint)
    local healthBar = esp.health
    healthBar.Visible = true
    local healthPercent = math.clamp(currentHealth / humanoid.MaxHealth, 0, 1)
    healthBar.From = Vector2.new(barX, barY)
    healthBar.To = Vector2.new(barX + (barWidth * healthPercent), barY)
    
    if isTarget then
        healthBar.Color = healthPercent > 0.5 and Color3.fromRGB(255, 100, 100) or 
                          healthPercent > 0.25 and Color3.fromRGB(255, 200, 0) or 
                          Color3.fromRGB(255, 0, 0)
    else
        healthBar.Color = healthPercent > 0.5 and Color3.fromRGB(0, 255, 0) or 
                          healthPercent > 0.25 and Color3.fromRGB(255, 255, 0) or 
                          Color3.fromRGB(255, 0, 0)
    end
    
    -- Distance
    local espDist = esp.distance
    espDist.Visible = true
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local dist = (rootPart.Position - root.Position).Magnitude
        espDist.Text = math.floor(dist) .. "m"
    else
        espDist.Text = "?"
    end
    espDist.Position = Vector2.new(centerX, centerY + height/2 + 18)
    espDist.Color = isTarget and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(200, 200, 200)
end

local function clearESP()
    for player, esp in pairs(espBoxes) do
        esp.box.Visible = false
        esp.name.Visible = false
        esp.health.Visible = false
        esp.healthBg.Visible = false
        esp.distance.Visible = false
    end
    targetHealthCache = {}
end

local function applyHVHStyle()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0.3
            part.Color = Color3.fromRGB(128, 0, 255)
        end
    end
end

local function removeHVHStyle()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
            part.Color = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function setupLighting()
    Lighting.Brightness = 2
    Lighting.Ambient = Color3.fromRGB(80, 0, 120)
    Lighting.OutdoorAmbient = Color3.fromRGB(80, 0, 120)
    Lighting.ColorShift_Top = Color3.fromRGB(128, 0, 255)
    Lighting.ColorShift_Bottom = Color3.fromRGB(80, 0, 120)
    Lighting.GlobalShadows = false
end

local function resetLighting()
    Lighting.Brightness = 1
    Lighting.Ambient = Color3.fromRGB(127, 127, 127)
    Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.GlobalShadows = true
end

local function hasLineOfSight(targetPart)
    local origin = workspaceCamera.CFrame.Position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local direction = (targetPart.Position - origin)
    local result = workspace:Raycast(origin, direction, rayParams)
    if result and result.Instance then
        if not targetPart:IsDescendantOf(result.Instance) then
            return false
        end
    end
    return true
end

local function isValidTarget(player)
    if not player then return false end
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local head = player.Character:FindFirstChild("Head")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not head then return false end
    if not humanoid then return false end
    if humanoid.Health <= 0 then return false end
    if not hasLineOfSight(head) then return false end
    return true
end

local function getClosestPlayer360()
    local closest = nil
    local shortest = math.huge
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not playerPos then return nil end
    local origin = playerPos.Position
    for _, plr in ipairs(Players:GetPlayers()) do
        if isValidTarget(plr) then
            local head = plr.Character.Head
            local targetPos = head.Position
            local dist = (targetPos - origin).Magnitude
            if dist < shortest then
                shortest = dist
                closest = plr
            end
        end
    end
    return closest
end

local function safeTrigger()
    local currentTime = tick()
    if currentTime - lastShotTime < 0.08 then return end
    if not currentTarget or not currentTarget.Character then return end
    local head = currentTarget.Character:FindFirstChild("Head")
    if not head then return end
    
    local direction = (head.Position - workspaceCamera.CFrame.Position).Unit
    local lookVector = workspaceCamera.CFrame.LookVector
    local dot = direction:Dot(lookVector)
    local angle = math.acos(math.clamp(dot, -1, 1))
    
    if math.deg(angle) > 5.0 then return end
    
    lastShotTime = currentTime
    pcall(function()
        mouse1press()
        task.wait(0.015)
        mouse1release()
    end)
end

local function onInputChanged(input, gameProcessed)
    if not isShiftLock then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        cameraYaw = cameraYaw - (input.Delta.X * SENSITIVITY)
        cameraPitch = math.clamp(cameraPitch + (input.Delta.Y * SENSITIVITY), -75, 75)
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TOGGLE_KEY then
        isShiftLock = not isShiftLock
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if isShiftLock then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false
            if humanoid then humanoid.AutoRotate = false end
            if character and character.PrimaryPart then
                local _, y, _ = character.PrimaryPart.CFrame:ToOrientation()
                cameraYaw = math.deg(y)
                cameraPitch = 0
            end
            enabled = true
            workspaceCamera.FieldOfView = 120
            setupLighting()
            applyHVHStyle()
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
            if humanoid then humanoid.AutoRotate = true end
            workspaceCamera.CameraType = Enum.CameraType.Custom
            workspaceCamera.FieldOfView = 70
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0
                    end
                end
            end
            enabled = false
            aimAssist = false
            currentTarget = nil
            clearESP()
            resetLighting()
            removeHVHStyle()
            for _, h in ipairs(hitmarkers) do
                for _, l in ipairs(h.lines) do l.Visible = false end
            end
            hitmarkers = {}
        end
    end
end

local function updateCamera()
    if not isShiftLock then
        if enabled then
            enabled = false
            aimAssist = false
            currentTarget = nil
            clearESP()
        end
        return
    end
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if rootPart and humanoid and humanoid.Health > 0 then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        humanoid.AutoRotate = false
        workspaceCamera.CameraType = Enum.CameraType.Scriptable
        workspaceCamera.FieldOfView = 120
        
        spinAngle = (spinAngle + SPIN_SPEED) % 360
        
        local pureMouseRotation = CFrame.Angles(0, math.rad(cameraYaw), 0) * CFrame.Angles(math.rad(cameraPitch), 0, 0)
        local cameraPosition = rootPart.Position + pureMouseRotation:VectorToWorldSpace(CAMERA_OFFSET)
        
        local trackingHead = nil
        
        applyHVHStyle()
        
        if enabled then
            local dynamicTarget = getClosestPlayer360()
            if dynamicTarget and isValidTarget(dynamicTarget) then
                currentTarget = dynamicTarget
            else
                currentTarget = nil
            end
            
            if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
                local head = currentTarget.Character.Head
                local humanoidTarget = currentTarget.Character:FindFirstChildOfClass("Humanoid")
                if humanoidTarget and humanoidTarget.Health > 0 then
                    trackingHead = head
                else
                    currentTarget = nil
                end
            end
        end
        
        -- Update ESP for all players (this also checks health changes for hitmarkers)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updateESP(plr)
            end
        end
        
        -- Update hitmarkers (fade out)
        for i = #hitmarkers, 1, -1 do
            local h = hitmarkers[i]
            if tick() - h.time > 0.3 then
                for _, l in ipairs(h.lines) do l.Visible = false end
                table.remove(hitmarkers, i)
            else
                local alpha = 1 - ((tick() - h.time) / 0.3)
                for _, l in ipairs(h.lines) do
                    l.Color = Color3.fromRGB(255, 255 * alpha, 255 * alpha)
                end
            end
        end
        
        if trackingHead then
            local targetDir = (trackingHead.Position - rootPart.Position).Unit
            local mouseDir = pureMouseRotation.LookVector
            local dotProduct = targetDir:Dot(mouseDir)

            if dotProduct < 0.5 then
                workspaceCamera.CFrame = CFrame.lookAt(rootPart.Position + Vector3.new(0, 1.5, 0), trackingHead.Position)
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 1
                    end
                end
            else
                local lookAtCFrame = CFrame.lookAt(cameraPosition, trackingHead.Position)
                workspaceCamera.CFrame = workspaceCamera.CFrame:Lerp(lookAtCFrame, 0.25)
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.LocalTransparencyModifier = 0.3
                    end
                end
            end
            
            local x, y, _ = workspaceCamera.CFrame:ToOrientation()
            cameraYaw = math.deg(y)
            cameraPitch = math.clamp(math.deg(x), -75, 75)
            
            local lookAtEnemyCFrame = CFrame.lookAt(rootPart.Position, trackingHead.Position)
            local _, targetY, _ = lookAtEnemyCFrame:ToOrientation()
            rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, targetY, 0)
            
            safeTrigger()
        else
            local lookAtPosition = rootPart.Position + Vector3.new(0, CAMERA_OFFSET.Y, 0)
            workspaceCamera.CFrame = CFrame.lookAt(cameraPosition, lookAtPosition)
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.LocalTransparencyModifier = 0.3
                end
            end
            rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        end
    end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputChanged:Connect(onInputChanged)

RunService:UnbindFromRenderStep("DroneCam")
RunService:BindToRenderStep("DroneCam", Enum.RenderPriority.Camera.Value, updateCamera)