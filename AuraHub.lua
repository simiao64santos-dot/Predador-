-- ============================================================
--  AURA HUB MOBILE  |  Interface moderna com aura
--  Compatível com celular (Delta, Arceus X, Fluxus Mobile)
--  Compatível com PC (fallback automático)
-- ============================================================

local repo = 'https://raw.githubusercontent.com/Progoonerfrfr/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Detecção de plataforma
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
--  JANELA PRINCIPAL
-- ============================================================
local Window = Library:CreateWindow({
    Title = 'Aura Hub' .. (isMobile and ' [Mobile]' or ''),
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Main = Window:AddTab('Aura'),
    Combat = Window:AddTab('Combate'),
    Visuals = Window:AddTab('Visual'),
    Movement = Window:AddTab('Movimento'),
    Misc = Window:AddTab('Diversos'),
    ['UI Settings'] = Window:AddTab('Interface'),
}

-- ============================================================
--  BOTÃO FLUTUANTE PARA ABRIR/FECHAR MENU (MOBILE)
-- ============================================================
if isMobile then
    local menuBtnGui = Instance.new("ScreenGui")
    menuBtnGui.Name = "AuraMenuBtn"
    menuBtnGui.ResetOnSpawn = false
    pcall(function() menuBtnGui.Parent = game:GetService("CoreGui") end)
    if not menuBtnGui.Parent then menuBtnGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local menuBtn = Instance.new("TextButton")
    menuBtn.Size = UDim2.new(0, 50, 0, 50)
    menuBtn.Position = UDim2.new(0, 10, 0, 10)
    menuBtn.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    menuBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
    menuBtn.Text = "AH"
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.TextSize = 20
    menuBtn.BorderSizePixel = 0
    menuBtn.Parent = menuBtnGui

    local c = Instance.new("UICorner", menuBtn); c.CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", menuBtn); s.Color = Color3.fromRGB(0, 255, 255); s.Thickness = 2

    menuBtn.MouseButton1Click:Connect(function()
        local ok = pcall(function() Library:Toggle() end)
        if not ok then
            pcall(function()
                Library.Open = not Library.Open
                Library:Update()
            end)
        end
    end)
end

-- ============================================================
--  ABA AURA
-- ============================================================
local MainLeft = Tabs.Main:AddLeftGroupbox('Aura do Jogador')
local MainRight = Tabs.Main:AddRightGroupbox('Aura Global')

local auraPart = nil

local function createAura(color)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    auraPart = Instance.new('Part')
    auraPart.Name = 'AuraPart'
    auraPart.Size = Vector3.new(4, 4, 4)
    auraPart.Transparency = 1
    auraPart.CanCollide = false
    auraPart.Massless = true
    auraPart.Parent = char
    auraPart.CFrame = hrp.CFrame

    local att = Instance.new('Attachment', auraPart)
    local pe = Instance.new('ParticleEmitter', att)
    pe.Texture = 'rbxassetid://243660364'
    pe.Color = ColorSequence.new(color)
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    pe.Lifetime = NumberRange.new(0.8, 1.5)
    pe.Rate = 20
    pe.Speed = NumberRange.new(1, 3)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Rotation = NumberRange.new(0, 360)

    RunService.RenderStepped:Connect(function()
        if auraPart and auraPart.Parent and hrp.Parent then
            auraPart.CFrame = hrp.CFrame
        end
    end)
end

local function removeAura()
    if auraPart then auraPart:Destroy() auraPart = nil end
end

local auraColor = Color3.fromRGB(0, 255, 255)

MainLeft:AddToggle('AuraLocal', {
    Text = 'Aura Pessoal (Partículas)',
    Default = false,
    Callback = function(v)
        if v then createAura(auraColor) else removeAura() end
    end,
})

MainLeft:AddLabel('Cor da Aura'):AddColorPicker('AuraColor', {
    Default = auraColor,
    Title = 'Escolha a cor da aura',
    Callback = function(color)
        auraColor = color
        if auraPart then
            local att = auraPart:FindFirstChildOfClass('Attachment')
            local pe = att and att:FindFirstChildOfClass('ParticleEmitter')
            if pe then pe.Color = ColorSequence.new(color) end
        end
    end,
})

local function applyGlobalAura()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
            if hrp and not hrp:FindFirstChild('GlobalAura') then
                local part = Instance.new('Part')
                part.Name = 'GlobalAura'
                part.Size = Vector3.new(3, 3, 3)
                part.Transparency = 1
                part.CanCollide = false
                part.Massless = true
                part.Parent = plr.Character
                part.CFrame = hrp.CFrame
                local att = Instance.new('Attachment', part)
                local pe = Instance.new('ParticleEmitter', att)
                pe.Texture = 'rbxassetid://243660364'
                pe.Color = ColorSequence.new(Color3.fromRGB(255, 100, 255))
                pe.Size = NumberSequence.new(1.5)
                pe.Transparency = NumberSequence.new(0.5)
                pe.Lifetime = NumberRange.new(0.5, 1)
                pe.Rate = 15
                pe.Speed = NumberRange.new(0.5, 2)
                pe.SpreadAngle = Vector2.new(180, 180)
                RunService.RenderStepped:Connect(function()
                    if part and part.Parent and hrp.Parent then
                        part.CFrame = hrp.CFrame
                    end
                end)
            end
        end
    end
end

local function removeGlobalAura()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local a = plr.Character:FindFirstChild('GlobalAura')
            if a then a:Destroy() end
        end
    end
end

MainRight:AddToggle('GlobalAura', {
    Text = 'Aura Global (Todos)',
    Default = false,
    Callback = function(v)
        if v then applyGlobalAura() else removeGlobalAura() end
    end,
})

-- ============================================================
--  ABA COMBATE (Aimbot Mobile)
-- ============================================================
local CombatLeft = Tabs.Combat:AddLeftGroupbox('Aimbot')
local CombatRight = Tabs.Combat:AddRightGroupbox('Kill Aura')

local aimbotEnabled = false
local aimbotFOV = isMobile and 180 or 120
local aimbotSmoothness = isMobile and 0.35 or 0.2
local aimbotPart = 'Head'

local fovCircle = Drawing.new('Circle')
fovCircle.Visible = false
fovCircle.Thickness = 2
fovCircle.NumSides = 64
fovCircle.Radius = aimbotFOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(0, 255, 255)
fovCircle.Transparency = 0.6

local function getReferencePoint()
    if isMobile then
        local vp = Camera.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    else
        return UserInputService:GetMouseLocation()
    end
end

local function getClosestPlayer()
    local closest, shortest = nil, math.huge
    local ref = getReferencePoint()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass('Humanoid')
            local part = plr.Character:FindFirstChild(aimbotPart)
            if hum and hum.Health > 0 and part then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - ref).Magnitude
                    if dist < shortest and dist <= aimbotFOV then
                        shortest, closest = dist, plr
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        fovCircle.Position = getReferencePoint()
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = true

        local t = getClosestPlayer()
        if t and t.Character then
            local part = t.Character:FindFirstChild(aimbotPart)
            if part then
                local camPos = Camera.CFrame.Position
                local dir = (part.Position - camPos).Unit
                local targetCF = CFrame.new(camPos, camPos + dir)
                Camera.CFrame = Camera.CFrame:Lerp(targetCF, aimbotSmoothness)
            end
        end
    else
        fovCircle.Visible = false
    end
end)

CombatLeft:AddToggle('AimbotEnabled', {
    Text = 'Aimbot',
    Default = false,
    Tooltip = 'Mira automática no jogador mais próximo do centro',
    Callback = function(v) aimbotEnabled = v end,
})

CombatLeft:AddSlider('AimbotFOV', {
    Text = 'FOV',
    Default = aimbotFOV,
    Min = 10, Max = 500, Rounding = 0, Suffix = 'px',
    Callback = function(v) aimbotFOV = v end,
})

CombatLeft:AddSlider('AimbotSmooth', {
    Text = 'Suavidade',
    Default = aimbotSmoothness,
    Min = 0.02, Max = 1, Rounding = 2,
    Callback = function(v) aimbotSmoothness = v end,
})

CombatLeft:AddDropdown('AimbotPart', {
    Text = 'Parte Alvo',
    Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
    Default = 1,
    Callback = function(v) aimbotPart = v end,
})

-- Kill Aura (ativa tool automaticamente)
local killAuraEnabled = false
local killAuraRange = 20

RunService.Heartbeat:Connect(function()
    if not killAuraEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    local tool = char:FindFirstChildOfClass('Tool')

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass('Humanoid')
            local thrp = plr.Character:FindFirstChild('HumanoidRootPart')
            if hum and hum.Health > 0 and thrp then
                if (hrp.Position - thrp.Position).Magnitude <= killAuraRange then
                    if tool then
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end
end)

CombatRight:AddToggle('KillAura', {
    Text = 'Kill Aura',
    Default = false,
    Tooltip = 'Ativa ferramentas automaticamente perto de jogadores',
    Callback = function(v) killAuraEnabled = v end,
})

CombatRight:AddSlider('KillAuraRange', {
    Text = 'Alcance',
    Default = 20, Min = 5, Max = 100, Rounding = 0, Suffix = 'studs',
    Callback = function(v) killAuraRange = v end,
})

-- ============================================================
--  ABA VISUAL (ESP)
-- ============================================================
local VisualsLeft = Tabs.Visuals:AddLeftGroupbox('ESP')
local VisualsRight = Tabs.Visuals:AddRightGroupbox('Configurações')

local espEnabled = false
local espBoxes, espNames = {}, {}

local function createESP(plr)
    if plr == LocalPlayer then return end
    if espBoxes[plr] then return end
    local okBox, box = pcall(function() return Drawing.new('Square') end)
    local okTxt, txt = pcall(function() return Drawing.new('Text') end)
    if not okBox or not okTxt then return end
    box.Thickness = 2
    box.Color = Color3.fromRGB(0, 255, 255)
    box.Filled = false
    box.Visible = false
    espBoxes[plr] = box
    txt.Size = 14
    txt.Color = Color3.fromRGB(255, 255, 255)
    txt.Center = true
    txt.Outline = true
    txt.Visible = false
    espNames[plr] = txt
end

RunService.RenderStepped:Connect(function()
    for plr, box in pairs(espBoxes) do
        local visible = false
        if espEnabled and plr.Character then
            local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
            local head = plr.Character:FindFirstChild('Head')
            if hrp and head then
                local hp, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                local rp = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local h = math.abs(hp.Y - rp.Y) * 2
                    local w = h * 0.6
                    box.Size = Vector2.new(w, h)
                    box.Position = Vector2.new(hp.X - w / 2, hp.Y)
                    box.Visible = true
                    visible = true
                    if espNames[plr] then
                        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
                        local dist = myHrp and (myHrp.Position - hrp.Position).Magnitude or 0
                        espNames[plr].Text = string.format('%s [%d]', plr.Name, math.floor(dist))
                        espNames[plr].Position = Vector2.new(hp.X, hp.Y - 18)
                        espNames[plr].Visible = true
                    end
                end
            end
        end
        if not visible then
            box.Visible = false
            if espNames[plr] then espNames[plr].Visible = false end
        end
    end
end)

VisualsLeft:AddToggle('ESP', {
    Text = 'ESP (Caixas e Nomes)',
    Default = false,
    Callback = function(v)
        espEnabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then createESP(plr) end
            end
        else
            for _, b in pairs(espBoxes) do b.Visible = false end
            for _, n in pairs(espNames) do n.Visible = false end
        end
    end,
})

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if espEnabled then createESP(plr) end
    end)
end)

VisualsRight:AddLabel('Cor do ESP'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Cor da caixa',
    Callback = function(color)
        for _, b in pairs(espBoxes) do b.Color = color end
    end,
})

-- ============================================================
--  ABA MOVIMENTO
-- ============================================================
local MoveLeft = Tabs.Movement:AddLeftGroupbox('Movimento')
local MoveRight = Tabs.Movement:AddRightGroupbox('Voo')

-- Speed
local speedEnabled, speedValue = false, 50
MoveLeft:AddToggle('SpeedToggle', {
    Text = 'Speed Hack', Default = false,
    Callback = function(v)
        speedEnabled = v
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if hum then hum.WalkSpeed = v and speedValue or 16 end
    end,
})
MoveLeft:AddSlider('SpeedValue', {
    Text = 'Velocidade', Default = 50, Min = 16, Max = 300, Rounding = 0,
    Callback = function(v)
        speedValue = v
        if speedEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hum then hum.WalkSpeed = v end
        end
    end,
})

-- Jump
local jumpEnabled, jumpValue = false, 100
MoveLeft:AddToggle('JumpToggle', {
    Text = 'Jump Power', Default = false,
    Callback = function(v)
        jumpEnabled = v
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v and jumpValue or 50
        end
    end,
})
MoveLeft:AddSlider('JumpValue', {
    Text = 'Força do Salto', Default = 100, Min = 50, Max = 500, Rounding = 0,
    Callback = function(v)
        jumpValue = v
        if jumpEnabled then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass('Humanoid')
            if hum then hum.JumpPower = v end
        end
    end,
})

-- Infinite Jump (works with mobile jump button)
local infJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass('Humanoid')
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
MoveLeft:AddToggle('InfJump', {
    Text = 'Salto Infinito', Default = false,
    Callback = function(v) infJumpEnabled = v end,
})

-- Noclip
local noclipEnabled = false
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA('BasePart') then p.CanCollide = false end
            end
        end
    end
end)
MoveLeft:AddToggle('Noclip', {
    Text = 'Noclip', Default = false,
    Callback = function(v) noclipEnabled = v end,
})

-- ============================================================
--  FLY (com botões mobile)
-- ============================================================
local flyEnabled, flySpeed = false, 50
local flyBV, flyBG, flyConn = nil, nil, nil
local controls = {f=0, b=0, l=0, r=0, u=0, d=0}
local flyButtonsGui = nil

local function createFlyButtons()
    if flyButtonsGui then flyButtonsGui:Destroy() end
    flyButtonsGui = Instance.new("ScreenGui")
    flyButtonsGui.Name = "AuraFlyGui"
    flyButtonsGui.ResetOnSpawn = false
    pcall(function() flyButtonsGui.Parent = game:GetService("CoreGui") end)
    if not flyButtonsGui.Parent then flyButtonsGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local function makeBtn(text, pos, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 55, 0, 55)
        btn.Position = pos
        btn.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        btn.BackgroundTransparency = 0.4
        btn.TextColor3 = Color3.fromRGB(0, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 22
        btn.BorderSizePixel = 0
        btn.Parent = flyButtonsGui
        local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 12)
        local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(0, 255, 255); s.Thickness = 2
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                controls[key] = 1
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
                or input.UserInputType == Enum.UserInputType.MouseButton1 then
                controls[key] = 0
            end
        end)
    end

    -- Layout em cruz no canto inferior esquerdo
    makeBtn("↑", UDim2.new(0, 75, 1, -275), "u")
    makeBtn("W", UDim2.new(0, 75, 1, -215), "f")
    makeBtn("A", UDim2.new(0, 15, 1, -215), "l")
    makeBtn("S", UDim2.new(0, 75, 1, -155), "b")
    makeBtn("D", UDim2.new(0, 135, 1, -215), "r")
    makeBtn("↓", UDim2.new(0, 75, 1, -95), "d")
end

local function destroyFlyButtons()
    if flyButtonsGui then flyButtonsGui:Destroy() flyButtonsGui = nil end
    controls.f = 0 controls.b = 0 controls.l = 0 controls.r = 0 controls.u = 0 controls.d = 0
end

local function enableFly()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    flyBV = Instance.new('BodyVelocity')
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new('BodyGyro')
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1000 flyBG.D = 50
    flyBG.Parent = hrp

    if isMobile then
        createFlyButtons()
    else
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.W then controls.f = 1 end
            if input.KeyCode == Enum.KeyCode.S then controls.b = -1 end
            if input.KeyCode == Enum.KeyCode.A then controls.l = -1 end
            if input.KeyCode == Enum.KeyCode.D then controls.r = 1 end
            if input.KeyCode == Enum.KeyCode.E then controls.u = 1 end
            if input.KeyCode == Enum.KeyCode.Q then controls.d = -1 end
        end)
        UserInputService.InputEnded:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == Enum.KeyCode.W then controls.f = 0 end
            if input.KeyCode == Enum.KeyCode.S then controls.b = 0 end
            if input.KeyCode == Enum.KeyCode.A then controls.l = 0 end
            if input.KeyCode == Enum.KeyCode.D then controls.r = 0 end
            if input.KeyCode == Enum.KeyCode.E then controls.u = 0 end
            if input.KeyCode == Enum.KeyCode.Q then controls.d = 0 end
        end)
    end

    flyConn = RunService.RenderStepped:Connect(function()
        if flyEnabled and hrp and hrp.Parent then
            local camCF = Camera.CFrame
            local dir = camCF.LookVector * controls.f
                      + camCF.RightVector * controls.r
                      + camCF.LookVector * -controls.b
                      + camCF.RightVector * -controls.l
                      + Vector3.new(0, controls.u, 0)
                      + Vector3.new(0, -controls.d, 0)
            flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
            flyBG.CFrame = camCF
        end
    end)
end

local function disableFly()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    if flyConn then flyConn:Disconnect() end
    flyBV, flyBG, flyConn = nil, nil, nil
    destroyFlyButtons()
end

MoveRight:AddToggle('FlyToggle', {
    Text = 'Fly (Voo)', Default = false,
    Tooltip = isMobile and 'Use os botões na tela para voar' or 'Use WASD + Q/E',
    Callback = function(v)
        flyEnabled = v
        if v then enableFly() else disableFly() end
    end,
})

MoveRight:AddSlider('FlySpeed', {
    Text = 'Velocidade do Voo', Default = 50, Min = 10, Max = 300, Rounding = 0,
    Callback = function(v) flySpeed = v end,
})

-- ============================================================
--  ABA DIVERSOS
-- ============================================================
local MiscLeft = Tabs.Misc:AddLeftGroupbox('Teleporte')
local MiscRight = Tabs.Misc:AddRightGroupbox('Jogadores')

local playerList = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then table.insert(playerList, plr.Name) end
end
if #playerList == 0 then playerList = {'(vazio)'} end

MiscLeft:AddDropdown('TPPlayer', {
    Text = 'Jogador', Values = playerList, Default = 1,
    Callback = function(v) _G.selectedPlayer = v end,
})

MiscLeft:AddButton('Teleportar para Jogador', function()
    local target = _G.selectedPlayer and Players:FindFirstChild(_G.selectedPlayer)
    if target and target.Character and LocalPlayer.Character then
        local thrp = target.Character:FindFirstChild('HumanoidRootPart')
        local lhrp = LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if thrp and lhrp then
            lhrp.CFrame = thrp.CFrame + Vector3.new(0, 3, 0)
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then table.insert(playerList, plr.Name) end
end)

-- ============================================================
--  INTERFACE (Temas + Save)
-- ============================================================
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title = 'Aura Hub' .. (isMobile and ' [Mobile]' or ''),
    Content = 'Carregado com sucesso!',
    Duration = 5,
    Image = 'rbxassetid://243660364',
})

print('[Aura Hub] Carregado. Plataforma: ' .. (isMobile and 'Mobile' or 'PC'))
