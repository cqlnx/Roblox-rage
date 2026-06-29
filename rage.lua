local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local workspaceCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Lighting = game:GetService("Lighting")

local Settings = {
    ESP = true,
    Aimbot = true,
    Triggerbot = true,
    Hitmarkers = true,
    FOV = 120,
    Transparency = 0.3,
    GlowColor = Color3.fromRGB(128, 0, 255),
    ESPColor = Color3.fromRGB(0, 255, 255),
    TargetColor = Color3.fromRGB(255, 0, 0),
    SpinSpeed = 25,
}

local menuOpen = false
local isShiftLock = false
local cameraYaw = 0
local cameraPitch = 0
local enabled = false
local currentTarget = nil
local lastShotTime = 0
local targetHealthCache = {}
local spinAngle = 0
local mouseDown = false
local draggingSlider = false
local dragItemIndex = 0

local viewportSize = workspaceCamera.ViewportSize
local centerX = viewportSize.X / 2
local centerY = viewportSize.Y / 2

-- SPLASH SCREEN
local splashActive = true
local splashStart = tick()

local splashBg = Drawing.new("Square")
splashBg.Visible = true
splashBg.Color = Color3.fromRGB(10, 10, 20)
splashBg.Filled = true
splashBg.Transparency = 0
splashBg.Size = Vector2.new(viewportSize.X, viewportSize.Y)
splashBg.Position = Vector2.new(0, 0)

local splashText = Drawing.new("Text")
splashText.Visible = true
splashText.Color = Color3.fromRGB(128, 0, 255)
splashText.Size = 64
splashText.Center = true
splashText.Outline = true
splashText.OutlineColor = Color3.fromRGB(0, 0, 0)
splashText.Position = Vector2.new(centerX, centerY - 10)
splashText.Text = "NIGHTFALL"
splashText.Transparency = 0

local splashSub = Drawing.new("Text")
splashSub.Visible = true
splashSub.Color = Color3.fromRGB(150, 150, 180)
splashSub.Size = 16
splashSub.Center = true
splashSub.Outline = true
splashSub.OutlineColor = Color3.fromRGB(0, 0, 0)
splashSub.Position = Vector2.new(centerX, centerY + 40)
splashSub.Text = "v2.0"
splashSub.Transparency = 0

local loaded = false

local function updateSplash()
    if not splashActive then return end
    
    local elapsed = tick() - splashStart
    local alpha = 0
    
    if elapsed < 1 then
        alpha = elapsed
    elseif elapsed < 3 then
        alpha = 1
    elseif elapsed < 4 then
        alpha = 1 - (elapsed - 3)
    else
        splashActive = false
        loaded = true
        splashBg.Visible = false
        splashText.Visible = false
        splashSub.Visible = false
        splashBg:Remove()
        splashText:Remove()
        splashSub:Remove()
        RunService:UnbindFromRenderStep("SplashScreenStep")
        tooltip.Visible = true
        return
    end
    
    splashBg.Transparency = alpha * 0.95
    splashText.Transparency = alpha
    splashSub.Transparency = alpha
end

RunService:BindToRenderStep("SplashScreenStep", Enum.RenderPriority.Camera.Value, updateSplash)

local tooltip = Drawing.new("Text")
tooltip.Visible = false
tooltip.Color = Color3.fromRGB(150, 150, 150)
tooltip.Size = 12
tooltip.Position = Vector2.new(viewportSize.X - 240, viewportSize.Y - 25)
tooltip.Center = false
tooltip.Outline = true
tooltip.OutlineColor = Color3.fromRGB(0, 0, 0)
tooltip.Text = "[R.SHIFT] Enable  [F1] Menu"

-- MENU
local menuVisible = false
local selectedItem = 1
local menuAnim = 0
local menuX = 0
local menuY = 0
local menuWidth = 320
local menuHeight = 420

local menuBg = Drawing.new("Square")
menuBg.Visible = false
menuBg.Color = Color3.fromRGB(20, 20, 30)
menuBg.Filled = true
menuBg.Transparency = 0.92
menuBg.Thickness = 1

local menuBorder = Drawing.new("Square")
menuBorder.Visible = false
menuBorder.Color = Color3.fromRGB(128, 0, 255)
menuBorder.Filled = false
menuBorder.Thickness = 2

local menuTitle = Drawing.new("Text")
menuTitle.Visible = false
menuTitle.Color = Color3.fromRGB(128, 0, 255)
menuTitle.Size = 22
menuTitle.Center = true
menuTitle.Outline = true
menuTitle.OutlineColor = Color3.fromRGB(0, 0, 0)
menuTitle.Text = "NIGHTFALL MENU"

local menuOptions = {}
local sliderBars = {}
local sliderHandles = {}
local colorPreviews = {}
local itemRects = {}

for i = 1, 10 do
    menuOptions[i] = Drawing.new("Text")
    menuOptions[i].Visible = false
    menuOptions[i].Size = 15
    menuOptions[i].Center = false
    menuOptions[i].Outline = true
    menuOptions[i].OutlineColor = Color3.fromRGB(0, 0, 0)
    
    sliderBars[i] = Drawing.new("Line")
    sliderBars[i].Visible = false
    sliderBars[i].Color = Color3.fromRGB(60, 60, 80)
    sliderBars[i].Thickness = 4
    
    sliderHandles[i] = Drawing.new("Circle")
    sliderHandles[i].Visible = false
    sliderHandles[i].Color = Color3.fromRGB(128, 0, 255)
    sliderHandles[i].Radius = 6
    sliderHandles[i].Filled = true
    sliderHandles[i].Thickness = 1
    
    colorPreviews[i] = Drawing.new("Square")
    colorPreviews[i].Visible = false
    colorPreviews[i].Filled = true
    colorPreviews[i].Thickness = 1
    colorPreviews[i].Size = Vector2.new(20, 16)
    
    itemRects[i] = {x = 0, y = 0, w = 0, h = 28}
end

-- COLOR PICKER
local colorPickerActive = false
local colorPickerIndex = 0
local colorPickerX = 0
local colorPickerY = 0
local colorPickerWidth = 220
local colorPickerHeight = 200
local colorDragIndex = 0
local colorKeys = {"GlowColor", "ESPColor", "TargetColor"}

local cpBg = Drawing.new("Square")
cpBg.Visible = false
cpBg.Color = Color3.fromRGB(25, 25, 40)
cpBg.Filled = true
cpBg.Transparency = 0.95
cpBg.Size = Vector2.new(colorPickerWidth, colorPickerHeight)

local cpBorder = Drawing.new("Square")
cpBorder.Visible = false
cpBorder.Color = Color3.fromRGB(128, 0, 255)
cpBorder.Filled = false
cpBorder.Thickness = 2
cpBorder.Size = Vector2.new(colorPickerWidth, colorPickerHeight)

local cpTitle = Drawing.new("Text")
cpTitle.Visible = false
cpTitle.Color = Color3.fromRGB(255, 255, 255)
cpTitle.Size = 14
cpTitle.Center = true
cpTitle.Outline = true
cpTitle.OutlineColor = Color3.fromRGB(0, 0, 0)
cpTitle.Text = "Pick Color"

local cpSliders = {}
local cpHandles = {}
local cpLabels = {}
local cpRects = {}

for i = 1, 3 do
    cpSliders[i] = Drawing.new("Line")
    cpSliders[i].Visible = false
    cpSliders[i].Thickness = 4
    
    cpHandles[i] = Drawing.new("Circle")
    cpHandles[i].Visible = false
    cpHandles[i].Radius = 6
    cpHandles[i].Filled = true
    cpHandles[i].Thickness = 1
    
    cpLabels[i] = Drawing.new("Text")
    cpLabels[i].Visible = false
    cpLabels[i].Size = 12
    cpLabels[i].Center = false
    cpLabels[i].Outline = true
    cpLabels[i].OutlineColor = Color3.fromRGB(0, 0, 0)
    
    cpRects[i] = {x = 0, y = 0, w = 0, h = 0}
end
cpLabels[1].Text = "R:"
cpLabels[2].Text = "G:"
cpLabels[3].Text = "B:"

local function getMenuItems()
    return {
        {label = "ESP", type = "toggle", value = Settings.ESP},
        {label = "Aimbot", type = "toggle", value = Settings.Aimbot},
        {label = "Triggerbot", type = "toggle", value = Settings.Triggerbot},
        {label = "Hitmarkers", type = "toggle", value = Settings.Hitmarkers},
        {label = "FOV: " .. Settings.FOV, type = "slider", value = Settings.FOV, min = 60, max = 120},
        {label = "Transparency: " .. math.floor(Settings.Transparency * 100) .. "%", type = "slider", value = Settings.Transparency, min = 0, max = 1},
        {label = "Spin Speed: " .. Settings.SpinSpeed, type = "slider", value = Settings.SpinSpeed, min = 0, max = 100},
        {label = "Glow Color", type = "color", value = Settings.GlowColor},
        {label = "ESP Color", type = "color", value = Settings.ESPColor},
        {label = "Target Color", type = "color", value = Settings.TargetColor},
    }
end

local function isInRect(mx, my, rx, ry, rw, rh)
    return mx >= rx and mx <= rx + rw and my >= ry and my <= ry + rh
end

local function drawColorPicker()
    if not colorPickerActive then
        cpBg.Visible = false
        cpBorder.Visible = false
        cpTitle.Visible = false
        for i = 1, 3 do
            cpSliders[i].Visible = false
            cpHandles[i].Visible = false
            cpLabels[i].Visible = false
        end
        return
    end
    
    local cpX = colorPickerX
    local cpY = colorPickerY
    
    cpBg.Visible = true
    cpBg.Position = Vector2.new(cpX, cpY)
    
    cpBorder.Visible = true
    cpBorder.Position = Vector2.new(cpX, cpY)
    
    cpTitle.Visible = true
    cpTitle.Position = Vector2.new(cpX + colorPickerWidth/2, cpY + 20)
    
    -- FIXED: Aligned main-menu index mapping offset safely (8, 9, 10 mapped to 1, 2, 3)[cite: 2]
    local colorKey = colorKeys[colorPickerIndex - 7]
    if not colorKey then return end
    local color = Settings[colorKey]
    if not color then return end
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    
    for i = 1, 3 do
        local labelX = cpX + 15
        local labelY = cpY + 45 + (i - 1) * 40
        
        cpLabels[i].Visible = true
        cpLabels[i].Position = Vector2.new(labelX, labelY)
        
        local barX = cpX + 45
        local barY = labelY + 8
        local barW = 150
        
        cpRects[i] = {x = barX - 10, y = barY - 12, w = barW + 20, h = 24}
        
        cpSliders[i].Visible = true
        cpSliders[i].From = Vector2.new(barX, barY)
        cpSliders[i].To = Vector2.new(barX + barW, barY)
        
        -- FIXED: Synchronized thematic styling colors cleanly across backgrounds, lines, and text[cite: 2]
        if i == 1 then
            local redStyle = Color3.fromRGB(255, 70, 70)
            cpSliders[i].Color = Color3.fromRGB(80, 40, 40)
            cpHandles[i].Color = redStyle
            cpLabels[i].Color = redStyle
        elseif i == 2 then
            local greenStyle = Color3.fromRGB(70, 255, 70)
            cpSliders[i].Color = Color3.fromRGB(40, 80, 40)
            cpHandles[i].Color = greenStyle
            cpLabels[i].Color = greenStyle
        else
            local blueStyle = Color3.fromRGB(135, 206, 250) -- Vibrant layout blue (matches handles to labels)
            cpSliders[i].Color = Color3.fromRGB(40, 50, 90)
            cpHandles[i].Color = blueStyle
            cpLabels[i].Color = blueStyle
        end
        
        local val = i == 1 and r or (i == 2 and g or b)
        local percent = val / 255
        local handleX = barX + (barW * percent)
        
        cpHandles[i].Visible = true
        cpHandles[i].Position = Vector2.new(handleX, barY)
    end
end

local function drawMenu()
    if not menuVisible then
        menuBg.Visible = false
        menuBorder.Visible = false
        menuTitle.Visible = false
        for i = 1, 10 do
            menuOptions[i].Visible = false
            sliderBars[i].Visible = false
            sliderHandles[i].Visible = false
            colorPreviews[i].Visible = false
        end
        drawColorPicker()
        return
    end
    
    menuAnim = math.min(menuAnim + 0.1, 1)
    local scale = 0.8 + 0.2 * menuAnim
    
    local scaledWidth = menuWidth * scale
    local scaledHeight = menuHeight * scale
    menuX = (viewportSize.X / 2 - scaledWidth/2)
    menuY = (viewportSize.Y / 2 - scaledHeight/2)
    
    menuBg.Visible = true
    menuBg.Position = Vector2.new(menuX, menuY)
    menuBg.Size = Vector2.new(scaledWidth, scaledHeight)
    
    menuBorder.Visible = true
    menuBorder.Position = Vector2.new(menuX, menuY)
    menuBorder.Size = Vector2.new(scaledWidth, scaledHeight)
    
    menuTitle.Visible = true
    menuTitle.Position = Vector2.new(viewportSize.X / 2, menuY + 25)
    
    local items = getMenuItems()
    local itemY = menuY + 55
    
    for i, item in ipairs(items) do
        local opt = menuOptions[i]
        opt.Visible = true
        local isSelected = (i == selectedItem)
        local color = isSelected and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(200, 200, 200)
        
        itemRects[i] = {x = menuX + 5, y = itemY - 2, w = menuWidth - 10, h = 28}
        
        if item.type == "toggle" then
            local status = item.value and "[ON]" or "[OFF]"
            opt.Text = (isSelected and "> " or "  ") .. item.label .. " " .. status
            opt.Position = Vector2.new(menuX + 20, itemY)
            opt.Color = color
            itemY = itemY + 30
        elseif item.type == "slider" then
            local label = item.label
            opt.Text = (isSelected and "> " or "  ") .. label
            opt.Position = Vector2.new(menuX + 20, itemY)
            opt.Color = color
            
            local barX = menuX + 140
            local barY = itemY + 10
            local barWidth = 140
            
            sliderBars[i].Visible = true
            sliderBars[i].From = Vector2.new(barX, barY)
            sliderBars[i].To = Vector2.new(barX + barWidth, barY)
            
            local percent = (item.value - item.min) / (item.max - item.min)
            local handleX = barX + (barWidth * percent)
            
            sliderHandles[i].Visible = true
            sliderHandles[i].Position = Vector2.new(handleX, barY)
            sliderHandles[i].Color = isSelected and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(128, 0, 255)
            
            itemY = itemY + 30
        elseif item.type == "color" then
            opt.Text = (isSelected and "> " or "  ") .. item.label
            opt.Position = Vector2.new(menuX + 20, itemY)
            opt.Color = color
            
            local previewX = menuX + 180
            local previewY = itemY + 2
            
            colorPreviews[i].Visible = true
            colorPreviews[i].Position = Vector2.new(previewX, previewY)
            colorPreviews[i].Color = item.value
            
            itemY = itemY + 30
        end
    end
    
    drawColorPicker()
end

local CAMERA_OFFSET = Vector3.new(0, 2.5, 8)
local SENSITIVITY = 0.5
local TOGGLE_KEY = Enum.KeyCode.RightShift

local hitmarkers = {}
local espBoxes = {}

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

local function createESP()
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Settings.ESPColor
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 1
    
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Settings.ESPColor
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
    if not Settings.ESP then
        if espBoxes[player] then
            local esp = espBoxes[player]
            esp.box.Visible = false
            esp.name.Visible = false
            esp.health.Visible = false
            esp.healthBg.Visible = false
            esp.distance.Visible = false
        end
        return
    end
    
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
    
    local currentHealth = humanoid.Health
    local prevHealth = targetHealthCache[player] or currentHealth
    if Settings.Hitmarkers and player == currentTarget and currentHealth < prevHealth and currentHealth > 0 then
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
    
    local espBox = esp.box
    espBox.Visible = true
    espBox.Position = Vector2.new(centerX - width/2, centerY - height/2)
    espBox.Size = Vector2.new(width, height)
    espBox.Color = isTarget and Settings.TargetColor or Settings.ESPColor
    espBox.Thickness = isTarget and 3 or 2
    espBox.Transparency = isTarget and 0.8 or 1
    
    local espName = esp.name
    espName.Visible = true
    espName.Text = player.Name
    espName.Position = Vector2.new(centerX, headPos.Y - 20)
    espName.Color = isTarget and Settings.TargetColor or Settings.ESPColor
    
    local healthBg = esp.healthBg
    healthBg.Visible = true
    local barWidth = width
    local barX = centerX - barWidth/2
    local barY = centerY + height/2 + 4
    healthBg.From = Vector2.new(barX, barY)
    healthBg.To = Vector2.new(barX + barWidth, barY)
    
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
    espDist.Color = isTarget and Settings.TargetColor or Color3.fromRGB(200, 200, 200)
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
            part.LocalTransparencyModifier = Settings.Transparency
            part.Color = Settings.GlowColor
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
    Lighting.ColorShift_Top = Settings.GlowColor
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
    if not Settings.Aimbot then return nil end
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
    if not Settings.Triggerbot then return end
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
    if gameProcessed then return end
    if menuVisible then return end
    if not isShiftLock then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        cameraYaw = cameraYaw - (input.Delta.X * SENSITIVITY)
        cameraPitch = math.clamp(cameraPitch + (input.Delta.Y * SENSITIVITY), -75, 75)
    end
end

local function handleMouseClick(mousePos)
    if not menuVisible then return end
    
    local mx, my = mousePos.X, mousePos.Y
    
    if colorPickerActive then
        local cpX = colorPickerX
        local cpY = colorPickerY
        
        if not isInRect(mx, my, cpX, cpY, colorPickerWidth, colorPickerHeight) then
            colorPickerActive = false
            return
        end
        
        for i = 1, 3 do
            local labelY = cpY + 45 + (i - 1) * 40
            local barY = labelY + 8
            local barX = cpX + 45
            local barW = 150
            
            if isInRect(mx, my, barX - 10, barY - 12, barW + 20, 24) then
                colorDragIndex = i
                draggingSlider = true
                return
            end
        end
        return
    end
    
    for i = 1, 10 do
        local rect = itemRects[i]
        if rect and isInRect(mx, my, rect.x, rect.y, rect.w, rect.h) then
            selectedItem = i
            local items = getMenuItems()
            local item = items[i]
            
            if item.type == "toggle" then
                local toggles = {"ESP", "Aimbot", "Triggerbot", "Hitmarkers"}
                if i <= 4 then
                    Settings[toggles[i]] = not Settings[toggles[i]]
                end
            elseif item.type == "slider" then
                local barX = menuX + 140
                local barY = rect.y + 12
                local barW = 140
                
                if isInRect(mx, my, barX - 10, barY - 10, barW + 20, 20) then
                    draggingSlider = true
                    dragItemIndex = i
                    local percent = math.clamp((mx - barX) / barW, 0, 1)
                    if i == 5 then
                        Settings.FOV = math.floor(item.min + (item.max - item.min) * percent)
                        workspaceCamera.FieldOfView = Settings.FOV
                    elseif i == 6 then
                        local val = item.min + (item.max - item.min) * percent
                        Settings.Transparency = math.floor(val * 100) / 100
                    elseif i == 7 then
                        Settings.SpinSpeed = math.floor(item.min + (item.max - item.min) * percent)
                    end
                end
            elseif item.type == "color" then
                colorPickerActive = true
                colorPickerIndex = i
                colorPickerX = menuX + menuWidth + 10
                colorPickerY = menuY + 10
                if colorPickerX + colorPickerWidth > viewportSize.X then
                    colorPickerX = menuX - colorPickerWidth - 10
                end
                if colorPickerY + colorPickerHeight > viewportSize.Y then
                    colorPickerY = viewportSize.Y - colorPickerHeight - 10
                end
                if colorPickerY < 10 then colorPickerY = 10 end
                colorDragIndex = 0
            end
            break
        end
    end
end

local function handleMouseMove(mousePos)
    local mx, my = mousePos.X, mousePos.Y
    
    if colorPickerActive and draggingSlider and colorDragIndex > 0 then
        local cpX = colorPickerX
        local cpY = colorPickerY
        local labelY = cpY + 45 + (colorDragIndex - 1) * 40
        local barY = labelY + 8
        local barX = cpX + 45
        local barW = 150
        
        local percent = math.clamp((mx - barX) / barW, 0, 1)
        local val = math.floor(percent * 255)
        
        -- FIXED: Index math offset safely maps 8-10 down to array targets 1-3[cite: 2]
        local colorKey = colorKeys[colorPickerIndex - 7]
        if not colorKey then return end
        local currentColor = Settings[colorKey]
        if not currentColor then return end
        local r, g, b = currentColor.R * 255, currentColor.G * 255, currentColor.B * 255
        
        if colorDragIndex == 1 then r = val
        elseif colorDragIndex == 2 then g = val
        else b = val end
        
        Settings[colorKey] = Color3.fromRGB(r, g, b)
        return
    end
    
    if menuVisible and draggingSlider and dragItemIndex > 0 then
        local items = getMenuItems()
        local item = items[dragItemIndex]
        if item and item.type == "slider" then
            local barX = menuX + 140
            local barW = 140
            
            local percent = math.clamp((mx - barX) / barW, 0, 1)
            if dragItemIndex == 5 then
                Settings.FOV = math.floor(item.min + (item.max - item.min) * percent)
                workspaceCamera.FieldOfView = Settings.FOV
            elseif dragItemIndex == 6 then
                local val = item.min + (item.max - item.min) * percent
                Settings.Transparency = math.floor(val * 100) / 100
            elseif dragItemIndex == 7 then
                Settings.SpinSpeed = math.floor(item.min + (item.max - item.min) * percent)
            end
        end
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = true
        if menuVisible then
            handleMouseClick(UserInputService:GetMouseLocation())
        end
        return
    end
    
    if input.KeyCode == Enum.KeyCode.F1 then
        if loaded then
            menuVisible = not menuVisible
            if menuVisible then
                menuAnim = 0
                selectedItem = 1
                colorPickerActive = false
                draggingSlider = false
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = true
            else
                colorPickerActive = false
                draggingSlider = false
                UserInputService.MouseBehavior = isShiftLock and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
                UserInputService.MouseIconEnabled = not isShiftLock
            end
        end
        return
    end
    
    if menuVisible then
        if input.KeyCode == Enum.KeyCode.Up then
            selectedItem = math.max(1, selectedItem - 1)
        elseif input.KeyCode == Enum.KeyCode.Down then
            selectedItem = math.min(10, selectedItem + 1)
        elseif input.KeyCode == Enum.KeyCode.Left then
            local items = getMenuItems()
            local item = items[selectedItem]
            if item then
                if item.type == "slider" then
                    if selectedItem == 5 then
                        Settings.FOV = math.max(item.min, Settings.FOV - 5)
                        workspaceCamera.FieldOfView = Settings.FOV
                    elseif selectedItem == 6 then
                        Settings.Transparency = math.max(item.min, Settings.Transparency - 0.05)
                    elseif selectedItem == 7 then
                        Settings.SpinSpeed = math.max(item.min, Settings.SpinSpeed - 5)
                    end
                elseif item.type == "toggle" then
                    local toggles = {"ESP", "Aimbot", "Triggerbot", "Hitmarkers"}
                    if selectedItem <= 4 then
                        Settings[toggles[selectedItem]] = false
                    end
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Right then
            local items = getMenuItems()
            local item = items[selectedItem]
            if item then
                if item.type == "slider" then
                    if selectedItem == 5 then
                        Settings.FOV = math.min(item.max, Settings.FOV + 5)
                        workspaceCamera.FieldOfView = Settings.FOV
                    elseif selectedItem == 6 then
                        Settings.Transparency = math.min(item.max, Settings.Transparency + 0.05)
                    elseif selectedItem == 7 then
                        Settings.SpinSpeed = math.min(item.max, Settings.SpinSpeed + 5)
                    end
                elseif item.type == "toggle" then
                    local toggles = {"ESP", "Aimbot", "Triggerbot", "Hitmarkers"}
                    if selectedItem <= 4 then
                        Settings[toggles[selectedItem]] = true
                    end
                end
            end
        elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
            local toggles = {"ESP", "Aimbot", "Triggerbot", "Hitmarkers"}
            if selectedItem <= 4 then
                Settings[toggles[selectedItem]] = not Settings[toggles[selectedItem]]
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            menuVisible = false
            colorPickerActive = false
            draggingSlider = false
            UserInputService.MouseBehavior = isShiftLock and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = not isShiftLock
        end
        return
    end
    
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
            workspaceCamera.FieldOfView = Settings.FOV
            setupLighting()
            applyHVHStyle()
            tooltip.Visible = false
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
            currentTarget = nil
            clearESP()
            resetLighting()
            removeHVHStyle()
            for _, h in ipairs(hitmarkers) do
                for _, l in ipairs(h.lines) do l.Visible = false end
            end
            hitmarkers = {}
            tooltip.Visible = true
        end
    end
end

local function onInputEnded(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mouseDown = false
        draggingSlider = false
        dragItemIndex = 0
        colorDragIndex = 0
    end
end

local function updateCamera()
    viewportSize = workspaceCamera.ViewportSize
    centerX = viewportSize.X / 2
    centerY = viewportSize.Y / 2
    
    if not loaded then
        return
    end
    
    if tooltip.Visible then
        tooltip.Position = Vector2.new(viewportSize.X - 240, viewportSize.Y - 25)
    end
    
    -- FIXED: Removed "and not draggingSlider" tracking block so sliders follow mouse dynamically[cite: 2]
    if menuVisible and mouseDown then
        local mousePos = UserInputService:GetMouseLocation()
        handleMouseMove(mousePos)
    end
    
    if menuVisible then
        drawMenu()
    else
        menuBg.Visible = false
        menuBorder.Visible = false
        menuTitle.Visible = false
        for i = 1, 10 do
            menuOptions[i].Visible = false
            sliderBars[i].Visible = false
            sliderHandles[i].Visible = false
            colorPreviews[i].Visible = false
        end
        colorPickerActive = false
        drawColorPicker()
    end
    
    if not isShiftLock then
        if enabled then
            enabled = false
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
        workspaceCamera.FieldOfView = Settings.FOV
        
        spinAngle = (spinAngle + Settings.SpinSpeed) % 360
        
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
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                updateESP(plr)
            end
        end
        
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
                        part.LocalTransparencyModifier = Settings.Transparency
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
                    part.LocalTransparencyModifier = Settings.Transparency
                end
            end
            rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
        end
    end
end

UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)
UserInputService.InputChanged:Connect(onInputChanged)

RunService:UnbindFromRenderStep("DroneCam")
RunService:BindToRenderStep("DroneCam", Enum.RenderPriority.Camera.Value, updateCamera)
