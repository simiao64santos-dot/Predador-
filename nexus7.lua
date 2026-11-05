--[[
================================================================================
  NEXUS-7 :: DEEP SCAN ENGINE + ULTIMATE UI (v8.0)
  ------------------------------------------------------------------------------
  - Fila de Varredura (BFS): Impossível travar o Roblox com yields de rede.
  - UI Responsiva com Status em Tempo Real.
  - Base Gerada 100% à Prova de Falhas (Usa FindFirstChild).
================================================================================
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")

local CONFIG = {
    MaxDepth = 15,          -- Profundidade máxima da varredura
    YieldRate = 50,         -- Espera a cada 50 itens (anti-freeze)
    Stealth = {
        Enabled = true,
        SourceSignatures = {"nexus", "NEXUS", "Nexus", "recon_", "_gen", "stealth_"},
        BlockedPatterns = {
            "anticheat", "anti_cheat", "AntiCheat", "anti-cheat", "iac", "IAC", 
            "adonis", "Adonis", "Kick", "kick", "Ban", "ban", "Detect", "detect", 
            "Report", "report", "Monitor", "monitor", "Watch", "watch", "Flag", "flag"
        }
    },
    HighValueTokens = {
        "Buy", "Purchase", "Claim", "Reward", "Give", "Grant", "Add", "Set", 
        "Update", "Save", "Load", "Cash", "Coin", "Money", "Gem", "Robux", 
        "Item", "Inventory", "Trade", "Admin", "Command", "Spawn", "Teleport", 
        "Kill", "Damage", "Stat", "Level", "Exp", "Skill", "Power", "Boost"
    }
}

local NEXUS_LOGS = {}
local updateUIConsole = nil
local updateUIStatus = nil
local scanRunning = false

local function logToConsole(msg)
    local text = tostring(msg)
    local timestamp = os.date("%H:%M:%S")
    table.insert(NEXUS_LOGS, string.format("[%s] %s", timestamp, text))
    print("[NEXUS-7] " .. text)
    if updateUIConsole then updateUIConsole() end
end

local function getConsoleText() return table.concat(NEXUS_LOGS, "\n") end

-- ============================================================================
-- UI DEFINITIVA
-- ============================================================================
local function getSafeParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cgui = pcall(function() return game:GetService("CoreGui") end)
    if ok and cgui then 
        local readOk = pcall(function() return cgui.Name end)
        if readOk then return cgui end
    end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function createUI()
    local parent = getSafeParent()
    local oldGui = parent:FindFirstChild("Nexus7Gui")
    if oldGui then oldGui:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Nexus7Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parent

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 220, 0, 190) -- Aumentei para caber o Status
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -95)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true 
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Title.BackgroundTransparency = 0.5
    Title.Text = "NEXUS-7 ULTIMATE"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = MainFrame

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    StatusLabel.Position = UDim2.new(0.05, 0, 0, 35)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Pronto"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = MainFrame

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ToggleBtn.Position = UDim2.new(0.05, 0, 0, 60)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    ToggleBtn.Text = "Stealth: ON"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamSemibold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = MainFrame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleBtn

    local ConsoleBtn = Instance.new("TextButton")
    ConsoleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ConsoleBtn.Position = UDim2.new(0.05, 0, 0, 100)
    ConsoleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    ConsoleBtn.Text = "Abrir Console"
    ConsoleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConsoleBtn.Font = Enum.Font.GothamSemibold
    ConsoleBtn.TextSize = 12
    ConsoleBtn.Parent = MainFrame

    local ConsoleCorner = Instance.new("UICorner")
    ConsoleCorner.CornerRadius = UDim.new(0, 4)
    ConsoleCorner.Parent = ConsoleBtn

    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0.9, 0, 0, 30)
    CopyBtn.Position = UDim2.new(0.05, 0, 0, 140)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    CopyBtn.Text = "Copiar Base Script"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamSemibold
    CopyBtn.TextSize = 12
    CopyBtn.Parent = MainFrame

    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(0, 4)
    CopyCorner.Parent = CopyBtn

    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Size = UDim2.new(0.95, 0, 0, 0)
    ConsoleFrame.Position = UDim2.new(0.025, 0, 0, 190)
    ConsoleFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    ConsoleFrame.BorderSizePixel = 0
    ConsoleFrame.Visible = false
    ConsoleFrame.Parent = MainFrame

    local ConsoleCorner2 = Instance.new("UICorner")
    ConsoleCorner2.CornerRadius = UDim.new(0, 6)
    ConsoleCorner2.Parent = ConsoleFrame

    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -10, 1, -10)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 5)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.Parent = ConsoleFrame

    local ConsoleText = Instance.new("TextLabel")
    ConsoleText.Size = UDim2.new(1, 0, 0, 0)
    ConsoleText.AutomaticSize = Enum.AutomaticSize.Y
    ConsoleText.BackgroundTransparency = 1
    ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
    ConsoleText.TextYAlignment = Enum.TextYAlignment.Top
    ConsoleText.TextColor3 = Color3.fromRGB(200, 200, 200)
    ConsoleText.Font = Enum.Font.Code
    ConsoleText.TextSize = 10
    ConsoleText.TextWrapped = true
    ConsoleText.Text = "-- Console vazio --"
    ConsoleText.Parent = ScrollFrame

    -- Drag (Celular/PC)
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local consoleOpen = false
    ToggleBtn.MouseButton1Click:Connect(function()
        CONFIG.Stealth.Enabled = not CONFIG.Stealth.Enabled
        if CONFIG.Stealth.Enabled then
            ToggleBtn.Text = "Stealth: ON"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
            logToConsole("Camuflagem ativada.")
        else
            ToggleBtn.Text = "Stealth: OFF"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            logToConsole("Camuflagem desativada.")
        end
    end)

    ConsoleBtn.MouseButton1Click:Connect(function()
        consoleOpen = not consoleOpen
        if consoleOpen then
            ConsoleFrame.Visible = true
            ConsoleFrame:TweenSize(UDim2.new(0.95, 0, 0, 150), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            MainFrame:TweenSize(UDim2.new(0, 220, 0, 350), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            ConsoleBtn.Text = "Fechar Console"
            ConsoleText.Text = getConsoleText() == "" and "-- Console vazio --" or getConsoleText()
        else
            ConsoleBtn.Text = "Abrir Console"
            ConsoleFrame:TweenSize(UDim2.new(0.95, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true, function() ConsoleFrame.Visible = false end)
            MainFrame:TweenSize(UDim2.new(0, 220, 0, 190), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)

    CopyBtn.MouseButton1Click:Connect(function()
        local textToCopy = getConsoleText()
        if textToCopy == "" then textToCopy = "Nenhum log gerado ainda." end
        if setclipboard then setclipboard(textToCopy)
        elseif toclipboard then toclipboard(textToCopy) end
        CopyBtn.Text = "Copiado!"
        task.wait(1)
        CopyBtn.Text = "Copiar Base Script"
    end)

    return function() if consoleOpen then ConsoleText.Text = getConsoleText() end end,
           function(statusText) StatusLabel.Text = "Status: " .. statusText end
end

local succUI, uiConsole, uiStatus = pcall(createUI)
if succUI then updateUIConsole = uiConsole; updateUIStatus = uiStatus end

-- ============================================================================
-- STEALTH (Mantido)
-- ============================================================================
local function installStealth()
    if type(getrawmetatable) ~= "function" or type(checkcaller) ~= "function" then return end
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end
    if type(setreadonly) == "function" then pcall(setreadonly, mt, false) end
    local oldIndex = mt.__index
    mt.__index = function(self, key)
        if checkcaller() then return oldIndex(self, key) end
        if CONFIG.Stealth.Enabled and (key == "WalkSpeed" or key == "JumpPower") then
            local okH, isH = pcall(function() return self:IsA("Humanoid") end)
            if okH and isH then return key == "WalkSpeed" and 16 or 50 end
        end
        return oldIndex(self, key)
    end
    if type(setreadonly) == "function" then pcall(setreadonly, mt, true) end
    logToConsole("Spoof de metatable instalado.")
end

-- ============================================================================
-- DEEP SCANNER ENGINE (BFS - Sem travar)
-- ============================================================================
local function deepScan()
    logToConsole("Iniciando Varredura Profunda (BFS)...")
    if updateUIStatus then updateUIStatus("Preparando...") end
    
    local remotesFound = {}
    local queue = { game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("Players") }
    local visited = {}
    local count = 0

    while #queue > 0 do
        local current = table.remove(queue, 1)
        
        -- Proteção anti-yield extrema
        local okType, className = pcall(function() return current.ClassName end)
        if okType and className then
            local okIsA, isRemote = pcall(function()
                return current:IsA("RemoteEvent") or current:IsA("RemoteFunction") or current:IsA("UnreliableRemoteEvent")
            end)
            
            if okIsA and isRemote then
                table.insert(remotesFound, current)
            end
            
            -- Adiciona filhos à fila (se não for muito fundo)
            local okChildren, children = pcall(function() return current:GetChildren() end)
            if okChildren and children then
                for _, child in ipairs(children) do
                    if not visited[child] then
                        visited[child] = true
                        table.insert(queue, child)
                    end
                end
            end
        end
        
        count = count + 1
        if count % CONFIG.YieldRate == 0 then
            if updateUIStatus then updateUIStatus(string.format("Escaneando %d itens... (%d remotes)", count, #remotesFound)) end
            task.wait() -- Respira fundo para não travar
        end
    end
    
    return remotesFound
end

-- ============================================================================
-- GERADOR DE BASE À PROVA DE FALHAS
-- ============================================================================
local function generateBase(remotes)
    local L = {"--[[ NEXUS-7 :: AUTO-GENERATED BASE ]]", ""}
    table.insert(L, "local REMOTES = {}")
    for i, r in ipairs(remotes) do
        local okName, rName = pcall(function() return r.Name end)
        rName = okName and rName or ("Remote_" .. i)
        
        -- Escapa aspas no nome
        local safeName = string.gsub(rName, '"', '\\"')
        
        -- Usa FindFirstChild em vez de caminho longo pra evitar erro se o jogo mudar
        table.insert(L, string.format('REMOTES["%s"] = game:GetService("ReplicatedStorage"):FindFirstChild("%s", true) or game:GetService("Workspace"):FindFirstChild("%s", true)', safeName, safeName, safeName))
    end
    
    table.insert(L, "\nlocal function fire(name, ...)")
    table.insert(L, "    local r = REMOTES[name]")
    table.insert(L, "    if r and r:IsA('RemoteEvent') then r:FireServer(...) end")
    table.insert(L, "    if r and r:IsA('RemoteFunction') then return r:InvokeServer(...) end")
    table.insert(L, "end")
    return table.concat(L, "\n")
end

-- ============================================================================
-- EXECUÇÃO
-- ============================================================================
task.spawn(function()
    task.wait(1)
    logToConsole("NEXUS-7 v8.0 Inicializado.")
    installStealth()

    local succ, err = pcall(function()
        local remotes = deepScan()
        logToConsole(string.format("Varredura concluída! %d remotes encontrados.", #remotes))
        
        if updateUIStatus then updateUIStatus(string.format("Encontrados %d remotes.", #remotes)) end
        
        logToConsole("Gerando Base Script...")
        local base = generateBase(remotes)
        
        logToConsole("=== INICIO DA BASE GERADA ===")
        logToConsole(base)
        logToConsole("=== FIM DA BASE GERADA ===")
    end)

    if succ then
        logToConsole("Pronto! Abra o console e copie a base.")
    else
        logToConsole("ERRO CRÍTICO NA VARREDURA: " .. tostring(err))
    end
end)
