-- ============================================================
--  AURA HUB  |  Interface moderna com detalhes de aura
--  Biblioteca: LinoriaLib (UI)
--  Recursos: ESP, Aimbot, Fly, Speed, Jump, Noclip, Kill Aura
-- ============================================================

-- Carregamento da biblioteca de interface
local repo = 'https://raw.githubusercontent.com/Progoonerfrfr/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  JANELA PRINCIPAL
-- ============================================================
local Window = Library:CreateWindow({
    Title = 'Aura Hub',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

-- Abas
local Tabs = {
    Main = Window:AddTab('Principal'),
    Combat = Window:AddTab('Combate'),
    Visuals = Window:AddTab('Visual'),
    Movement = Window:AddTab('Movimento'),
    Misc = Window:AddTab('Diversos'),
    ['UI Settings'] = Window:AddTab('Interface'),
}

-- ============================================================
--  ABA PRINCIPAL (Aura do Personagem)
-- ============================================================
local MainLeft = Tabs.Main:AddLeftGroupbox('Aura do Jogador')
local MainRight = Tabs.Main:AddRightGroupbox('Aura Global')

-- Aura local (partículas ao redor do personagem)
local auraActive = false
local auraPart = nil

local function createAura()
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

    local attachment = Instance.new('Attachment', auraPart)
    attachment.Position = Vector3.new(0, 0, 0)

    local particle = Instance.new('ParticleEmitter', attachment)
    particle.Texture = 'rbxassetid://243660364' -- textura de brilho
    particle.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 255)),
    })
    particle.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 2),
        NumberSequenceKeypoint.new(1, 0),
    })
    particle.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    particle.Lifetime = NumberRange.new(0.8, 1.5)
    particle.Rate = 20
    particle.Speed = NumberRange.new(1, 3)
    particle.SpreadAngle = Vector2.new(180, 180)
    particle.Rotation = NumberRange.new(0, 360)

    RunService.RenderStepped:Connect(function()
        if auraPart and auraPart.Parent then
            auraPart.CFrame = hrp.CFrame
        end
    end)
end

local function removeAura()
    if auraPart then
        auraPart:Destroy()
        auraPart = nil
    end
end

MainLeft:AddToggle('AuraLocal', {
    Text = 'Aura Pessoal (Partículas)',
    Default = false,
    Tooltip = 'Ativa uma aura de partículas coloridas ao redor do seu personagem',
    Callback = function(v)
        auraActive = v
        if v then
            createAura()
        else
            removeAura()
        end
    end,
})

-- Cor da aura (color picker)
local auraColor = Color3.fromRGB(0, 255, 255)
MainLeft:AddLabel('Cor da Aura'):AddColorPicker('AuraColor', {
    Default = auraColor,
    Title = 'Escolha a cor da aura',
    Transparency = 0,
    Callback = function(color)
        auraColor = color
        if auraPart then
            local particle = auraPart:FindFirstChildOfClass('Attachment') and auraPart:FindFirstChildOfClass('Attachment'):FindFirstChildOfClass('ParticleEmitter')
            if particle then
                particle.Color = ColorSequence.new(color)
            end
        end
    end,
})

-- Aura global (todos os jogadores)
local globalAura = false
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
                    if part and part.Parent then
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
            local aura = plr.Character:FindFirstChild('GlobalAura')
            if aura then aura:Destroy() end
        end
    end
end

MainRight:AddToggle('GlobalAura', {
    Text = 'Aura Global (Todos os Jogadores)',
    Default = false,
    Tooltip = 'Aplica uma aura visual em todos os jogadores',
    Callback = function(v)
        globalAura = v
        if v then
            applyGlobalAura()
        else
            removeGlobalAura()
        end
    end,
})

-- ============================================================
--  ABA COMBATE (Aimbot & Kill Aura)
-- ============================================================
local CombatLeft = Tabs.Combat:AddLeftGroupbox('Aimbot')
local CombatRight = Tabs.Combat:AddRightGroupbox('Kill Aura')

-- Aimbot
local aimbotEnabled = false
local aimbotFOV = 120
local aimbotSmoothness = 0.2
local aimbotPart = 'Head'
local target = nil

local fovCircle = Drawing.new('Circle')
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Radius = aimbotFOV
fovCircle.Filled = false
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Transparency = 0.6

local function getClosestPlayer()
    local closest = nil
    local shortest = math.huge
    local mousePos = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass('Humanoid')
            local part = plr.Character:FindFirstChild(aimbotPart)
            if hum and hum.Health > 0 and part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortest and dist <= aimbotFOV then
                        shortest = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local function aimAt(plr)
    if not plr or not plr.Character then return end
    local part = plr.Character:FindFirstChild(aimbotPart)
    if not part then return end

    local targetPos = part.Position
    local camPos = Camera.CFrame.Position
    local direction = (targetPos - camPos).Unit

    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(camPos, camPos + direction)
    Camera.CFrame = currentCFrame:Lerp(targetCFrame, aimbotSmoothness)
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        local mousePos = UserInputService:GetMouseLocation()
        fovCircle.Position = mousePos
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = true
        fovCircle.Color = Color3.fromRGB(0, 255, 255)

        local closest = getClosestPlayer()
        if closest then
            aimAt(closest)
        end
    else
        fovCircle.Visible = false
    end
end)

CombatLeft:AddToggle('AimbotEnabled', {
    Text = 'Aimbot',
    Default = false,
    Tooltip = 'Ativa a mira automática no jogador mais próximo',
    Callback = function(v) aimbotEnabled = v end,
})

CombatLeft:AddSlider('AimbotFOV', {
    Text = 'FOV (Campo de Visão)',
    Default = 120,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Suffix = 'px',
    Callback = function(v) aimbotFOV = v end,
})

CombatLeft:AddSlider('AimbotSmooth', {
    Text = 'Suavidade',
    Default = 0.2,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Suffix = '',
    Callback = function(v) aimbotSmoothness = v end,
})

CombatLeft:AddDropdown('AimbotPart', {
    Text = 'Parte Alvo',
    Values = {'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso'},
    Default = 1,
    Callback = function(v) aimbotPart = v end,
})

-- Kill Aura
local killAuraEnabled = false
local killAuraRange = 20

local function killAura()
    if not killAuraEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass('Humanoid')
            local targetHrp = plr.Character:FindFirstChild('HumanoidRootPart')
            if hum and hum.Health > 0 and targetHrp then
                local dist = (hrp.Position - targetHrp.Position).Magnitude
                if dist <= killAuraRange then
                    -- Dano direto via ferramenta (se existir) ou toque
                    local tool = char:FindFirstChildOfClass('Tool')
                    if tool then
                        tool:Activate()
                    end
                    -- Dano por toque (simulação)
                    local explosion = Instance.new('Explosion')
                    explosion.Position = targetHrp.Position
                    explosion.BlastRadius = 2
                    explosion.BlastPressure = 0
                    explosion.DestroyJointRadiusPercent = 0
                    explosion.Parent = workspace
                    task.wait(0.1)
                    explosion:Destroy()
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if killAuraEnabled then
        killAura()
    end
end)

CombatRight:AddToggle('KillAura', {
    Text = 'Kill Aura',
    Default = false,
    Tooltip = 'Ataca automaticamente jogadores próximos',
    Callback = function(v) killAuraEnabled = v end,
})

CombatRight:AddSlider('KillAuraRange', {
    Text = 'Alcance',
    Default = 20,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Suffix = 'studs',
    Callback = function(v) killAuraRange = v end,
})

-- ============================================================
--  ABA VISUAL (ESP)
-- ============================================================
local VisualsLeft = Tabs.Visuals:AddLeftGroupbox('ESP')
local VisualsRight = Tabs.Visuals:AddRightGroupbox('Configurações ESP')

local espEnabled = false
local espBoxes = {}
local espNames = {}

local function createESP(plr)
    if plr == LocalPlayer then return end
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    -- Caixa
    local box = Drawing.new('Square')
    box.Thickness = 2
    box.Color = Color3.fromRGB(0, 255, 255)
    box.Filled = false
    box.Visible = false
    espBoxes[plr] = box

    -- Nome
    local name = Drawing.new('Text')
    name.Size = 16
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Center = true
    name.Outline = true
    name.Visible = false
    espNames[plr] = name
end

local function updateESP()
    for plr, box in pairs(espBoxes) do
        if not espEnabled or not plr.Character then
            box.Visible = false
            if espNames[plr] then espNames[plr].Visible = false end
        else
            local char = plr.Character
            local hrp = char:FindFirstChild('HumanoidRootPart')
            local head = char:FindFirstChild('Head')
            if hrp and head then
                local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                local rootPos, _ = Camera:WorldToViewportPoint(hrp.Position)

                if onScreen then
                    local height = math.abs(headPos.Y - rootPos.Y) * 2
                    local width = height * 0.6
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                    box.Visible = true

                    if espNames[plr] then
                        local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') and (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                        espNames[plr].Text = string.format('%s [%d]', plr.Name, math.floor(dist))
                        espNames[plr].Position = Vector2.new(headPos.X, headPos.Y - 20)
                        espNames[plr].Visible = true
                    end
                else
                    box.Visible = false
                    if espNames[plr] then espNames[plr].Visible = false end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(updateESP)

VisualsLeft:AddToggle('ESP', {
    Text = 'ESP (Caixas e Nomes)',
    Default = false,
    Tooltip = 'Mostra caixas e nomes sobre os jogadores',
    Callback = function(v)
        espEnabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then createESP(plr) end
            end
        else
            for _, box in pairs(espBoxes) do box.Visible = false end
            for _, name in pairs(espNames) do name.Visible = false end
        end
    end,
})

-- Atualizar ESP quando novos jogadores entrarem
Players.PlayerAdded:Connect(function(plr)
    if espEnabled then
        plr.CharacterAdded:Connect(function()
            task.wait(1)
            createESP(plr)
        end)
    end
end)

-- Cor do ESP
VisualsRight:AddLabel('Cor do ESP'):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(0, 255, 255),
    Title = 'Cor da caixa',
    Callback = function(color)
        for _, box in pairs(espBoxes) do
            box.Color = color
        end
    end,
})

-- ============================================================
--  ABA MOVIMENTO (Fly, Speed, Jump, Noclip)
-- ============================================================
local MoveLeft = Tabs.Movement:AddLeftGroupbox('Movimento')
local MoveRight = Tabs.Movement:AddRightGroupbox('Voo')

-- Speed
local speedEnabled = false
local speedValue = 50

MoveLeft:AddToggle('SpeedToggle', {
    Text = 'Speed Hack',
    Default = false,
    Callback = function(v)
        speedEnabled = v
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                hum.WalkSpeed = v and speedValue or 16
            end
        end
    end,
})

MoveLeft:AddSlider('SpeedValue', {
    Text = 'Velocidade',
    Default = 50,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(v)
        speedValue = v
        if speedEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum then hum.WalkSpeed = v end
            end
        end
    end,
})

-- Jump
local jumpEnabled = false
local jumpValue = 100

MoveLeft:AddToggle('JumpToggle', {
    Text = 'Jump Power',
    Default = false,
    Callback = function(v)
        jumpEnabled = v
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = v and jumpValue or 50
            end
        end
    end,
})

MoveLeft:AddSlider('JumpValue', {
    Text = 'Força do Salto',
    Default = 100,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(v)
        jumpValue = v
        if jumpEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass('Humanoid')
                if hum then hum.JumpPower = v end
            end
        end
    end,
})

-- Infinite Jump
local infJumpEnabled = false
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass('Humanoid')
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

MoveLeft:AddToggle('InfJump', {
    Text = 'Salto Infinito',
    Default = false,
    Callback = function(v) infJumpEnabled = v end,
})

-- Noclip
local noclipEnabled = false
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA('BasePart') then
                    part.CanCollide = false
                end
            end
        end
    end
end)

MoveLeft:AddToggle('Noclip', {
    Text = 'Noclip',
    Default = false,
    Callback = function(v) noclipEnabled = v end,
})

-- Fly
local flyEnabled = false
local flySpeed = 50
local flyBV = nil
local flyBG = nil
local flyConn = nil

local function enableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    flyBV = Instance.new('BodyVelocity')
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new('BodyGyro')
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 1000
    flyBG.D = 50
    flyBG.Parent = hrp

    local controls = {f=0, b=0, l=0, r=0, u=0, d=0}
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

    flyConn = RunService.RenderStepped:Connect(function()
        if flyEnabled and hrp and hrp.Parent then
            local camCF = Camera.CFrame
            local moveDir = (camCF.LookVector * controls.f + camCF.RightVector * controls.r + Vector3.new(0, controls.u, 0))
            if moveDir.Magnitude > 0 then
                flyBV.Velocity = moveDir.Unit * flySpeed
            else
                flyBV.Velocity = Vector3.zero
            end
            flyBG.CFrame = camCF
        end
    end)
end

local function disableFly()
    if flyBV then flyBV:Destroy() end
    if flyBG then flyBG:Destroy() end
    if flyConn then flyConn:Disconnect() end
    flyBV = nil
    flyBG = nil
    flyConn = nil
end

MoveRight:AddToggle('FlyToggle', {
    Text = 'Fly (Voo)',
    Default = false,
    Tooltip = 'Ative e use WASD + Q/E para voar',
    Callback = function(v)
        flyEnabled = v
        if v then enableFly() else disableFly() end
    end,
})

MoveRight:AddSlider('FlySpeed', {
    Text = 'Velocidade do Voo',
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(v) flySpeed = v end,
})

-- ============================================================
--  ABA DIVERSOS (Teleporte, etc.)
-- ============================================================
local MiscLeft = Tabs.Misc:AddLeftGroupbox('Teleporte')
local MiscRight = Tabs.Misc:AddRightGroupbox('Jogadores')

-- Teleporte para jogador
local selectedPlayer = nil
local playerList = {}
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        table.insert(playerList, plr.Name)
    end
end

MiscLeft:AddDropdown('TPPlayer', {
    Text = 'Jogador',
    Values = playerList,
    Default = 1,
    Callback = function(v) selectedPlayer = v end,
})

MiscLeft:AddButton('Teleportar para Jogador', function()
    if selectedPlayer then
        local targetPlr = Players:FindFirstChild(selectedPlayer)
        if targetPlr and targetPlr.Character then
            local hrp = targetPlr.Character:FindFirstChild('HumanoidRootPart')
            if hrp and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- Atualizar lista de jogadores
Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        table.insert(playerList, plr.Name)
    end
end)

-- ============================================================
--  CONFIGURAÇÕES DE INTERFACE (Temas e Salvamento)
-- ============================================================
local UISettings = Tabs['UI Settings']
local UILeft = UISettings:AddLeftGroupbox('Temas')
local UIRight = UISettings:AddRightGroupbox('Configurações')

-- Gerenciador de temas
ThemeManager:SetLibrary(Library)
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- Gerenciador de salvamento
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

-- ============================================================
--  NOTIFICAÇÃO DE CARREGAMENTO
-- ============================================================
Library:Notify({
    Title = 'Aura Hub',
    Content = 'Carregado com sucesso! Aproveite.',
    Duration = 5,
    Image = 'rbxassetid://243660364',
})

-- ============================================================
--  FINALIZAÇÃO
-- ============================================================
print('Aura Hub carregado.')
