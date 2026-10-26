Local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "การอยู่รอดของคนพเนจร[V10] | playpro_100",
    LoadingTitle = "กำลังโหลดระบบทั้งหมด...",
    LoadingSubtitle = "โดย playpro_100",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "WandererSurvivalHub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera

local Tab1 = Window:CreateTab("ต่อสู้และมองเห็น", 4483362458)

local AimbotEnabled = false
local AimDistance = 100
local currentLockedTarget = nil

Tab1:CreateSection("ระบบล็อกหัว (เฉพาะผู้เล่น) & กระสุนพิเศษ")

Tab1:CreateToggle({
    Name = "ล็อกหัว (เฉพาะผู้เล่นเท่านั้น)",
    CurrentValue = false,
    Callback = function(Value)
        AimbotEnabled = Value
    end,
})

Tab1:CreateSlider({
    Name = "ระยะล็อกเป้า (เมตร)",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = 100,
    Callback = function(Value)
        AimDistance = Value
    end,
})

local SilentAimEnabled = false
Tab1:CreateToggle({
    Name = "กระสุนตรง (ยิงยังไงก็โดนหัว)",
    CurrentValue = false,
    Callback = function(Value)
        SilentAimEnabled = Value
    end,
})

local FOVCircleEnabled = false
local FOVRadius = 150
_G.FOVCircleColor = Color3.fromRGB(255, 255, 255)

local fovDrawing = Drawing.new("Circle")
fovDrawing.Thickness = 1.5
fovDrawing.NumSides = 64
fovDrawing.Filled = false
fovDrawing.Visible = false

Tab1:CreateToggle({
    Name = "แสดงวงกลมระยะล็อก (FOV Circle)",
    CurrentValue = false,
    Callback = function(Value)
        FOVCircleEnabled = Value
        fovDrawing.Visible = Value
    end,
})

Tab1:CreateSlider({
    Name = "ขนาดวงกลม FOV",
    Range = {50, 400},
    Increment = 5,
    CurrentValue = 150,
    Callback = function(Value)
        FOVRadius = Value
        fovDrawing.Radius = Value
    end,
})

Tab1:CreateColorPicker({
    Name = "ปรับสีวงกลม FOV",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        _G.FOVCircleColor = Value
        fovDrawing.Color = Value
    end
})

RunService.RenderStepped:Connect(function()
    if FOVCircleEnabled then
        fovDrawing.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovDrawing.Radius = FOVRadius
        fovDrawing.Color = _G.FOVCircleColor
        fovDrawing.Visible = true
    else
        fovDrawing.Visible = false
    end
end)

local function GetClosestTarget()
    local closestTarget = nil
    local shortestDist = AimDistance
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    local possibleTargets = {}

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            table.insert(possibleTargets, player.Character)
        end
    end

    for _, char in pairs(possibleTargets) do
        if char:FindFirstChild("Head") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local head = char.Head
            local vector, onScreen = Camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
                local screenDist = (Vector2.new(vector.X, vector.Y) - screenCenter).Magnitude
                local worldDist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude) or 999
                
                if worldDist <= AimDistance and screenDist <= FOVRadius then
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    
                    local raycastResult = Workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * worldDist, raycastParams)
                    if not raycastResult or raycastResult.Instance:IsDescendantOf(char) then
                        if worldDist < shortestDist then
                            shortestDist = worldDist
                            closestTarget = head
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

RunService.RenderStepped:Connect(function()
    currentLockedTarget = GetClosestTarget()
    
    if AimbotEnabled and currentLockedTarget and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetCFrame = CFrame.new(Camera.CFrame.Position, currentLockedTarget.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 0.25)
    end
end)

pcall(function()
    local oldIndex
    oldIndex = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if SilentAimEnabled and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList") then
            if currentLockedTarget then
                local origin = args[1]
                if typeof(origin) == "Vector3" then
                    local newDir = (currentLockedTarget.Position - origin).Unit * 1000
                    args[2] = newDir
                    return oldIndex(self, unpack(args))
                end
            end
        end
        return oldIndex(self, ...)
    end)
end)

Tab1:CreateSection("ระบบมองทะลุ (ESP ชื่อ & เลือด)")

local ESPEnabled = false
local ESPNameEnabled = true
local ESPHealthEnabled = true

local espDrawings = {}
_G.ESPNameColor = Color3.fromRGB(255, 255, 255)
_G.ESPHealthColor = Color3.fromRGB(0, 255, 0)

Tab1:CreateToggle({
    Name = "เปิดระบบ ESP ชื่อและเลือด",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            for _, drawings in pairs(espDrawings) do
                if drawings.Name then drawings.Name:Remove() end
                if drawings.Health then drawings.Health:Remove() end
            end
            espDrawings = {}
        end
    end,
})

Tab1:CreateToggle({
    Name = "แสดงชื่อผู้เล่น",
    CurrentValue = true,
    Callback = function(Value)
        ESPNameEnabled = Value
    end,
})

Tab1:CreateToggle({
    Name = "แสดงเลือดผู้เล่น",
    CurrentValue = true,
    Callback = function(Value)
        ESPHealthEnabled = Value
    end,
})

Tab1:CreateColorPicker({
    Name = "ปรับสีชื่อ",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        _G.ESPNameColor = Value
    end
})

Tab1:CreateColorPicker({
    Name = "ปรับสีเลือด",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(Value)
        _G.ESPHealthColor = Value
    end
})

Players.PlayerRemoving:Connect(function(player)
    if espDrawings[player] then
        if espDrawings[player].Name then espDrawings[player].Name:Remove() end
        if espDrawings[player].Health then espDrawings[player].Health:Remove() end
        espDrawings[player] = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                local rootPart = player.Character.HumanoidRootPart
                local humanoid = player.Character.Humanoid
                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local dist = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)
                    local health = math.floor(humanoid.Health)
                    local maxHealth = math.floor(humanoid.MaxHealth)
                    
                    if not espDrawings[player] then
                        local nameText = Drawing.new("Text")
                        nameText.Center = true
                        nameText.Outline = true
                        nameText.Font = Drawing.Fonts.UI
                        nameText.Size = 16

                        local healthText = Drawing.new("Text")
                        healthText.Center = true
                        healthText.Outline = true
                        healthText.Font = Drawing.Fonts.UI
                        healthText.Size = 14

                        espDrawings[player] = {Name = nameText, Health = healthText}
                    end
                    
                    local drawings = espDrawings[player]
                    
                    if ESPNameEnabled then
                        drawings.Name.Text = string.format("%s [%dm]", player.Name, dist)
                        drawings.Name.Color = _G.ESPNameColor
                        local headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.5, 0))
                        drawings.Name.Position = Vector2.new(headPos.X, headPos.Y)
                        drawings.Name.Visible = true
                    else
                        drawings.Name.Visible = false
                    end

                    if ESPHealthEnabled then
                        drawings.Health.Text = string.format("HP: %d/%d", health, maxHealth)
                        drawings.Health.Color = _G.ESPHealthColor
                        local headPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.5, 0))
                        drawings.Health.Position = Vector2.new(headPos.X, headPos.Y + 16)
                        drawings.Health.Visible = true
                    else
                        drawings.Health.Visible = false
                    end
                else
                    if espDrawings[player] then
                        espDrawings[player].Name.Visible = false
                        espDrawings[player].Health.Visible = false
                    end
                end
            else
                if espDrawings[player] then
                    espDrawings[player].Name.Visible = false
                    espDrawings[player].Health.Visible = false
                end
            end
        end
    else
        for _, drawings in pairs(espDrawings) do
            if drawings.Name then drawings.Name.Visible = false end
            if drawings.Health then drawings.Health.Visible = false end
        end
    end
end)

local Tab2 = Window:CreateTab("ฟังก์ชันเสริม", 4483362458)

Tab2:CreateSection("การเคลื่อนไหว")

Tab2:CreateToggle({
    Name = "วิ่งไว 1.5x",
    CurrentValue = false,
    Callback = function(Value)
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Value then
                humanoid.WalkSpeed = 16 * 1.5
            else
                humanoid.WalkSpeed = 16
            end
        end
    end,
})

Tab2:CreateSection("สิ่งแวดล้อม (ทำให้แมพสว่างเห็นง่าย)")

Tab2:CreateSlider({
    Name = "ปรับแสงแมพสว่าง (%) [100% = ปกติ, 210% = สว่างสุด]",
    Range = {0, 210},
    Increment = 5,
    CurrentValue = 100,
    Callback = function(Value)
        local factor = Value / 100
        Lighting.Brightness = 3 * factor
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = (Value <= 100)
        local ambientValue = math.clamp(255 * factor, 0, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(ambientValue, ambientValue, ambientValue)
    end,
})

Rayfield:LoadConfiguration()
