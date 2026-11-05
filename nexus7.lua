--[[
================================================================================
  NEXUS-7 :: ULTIMATE EDITION v9.0
  ------------------------------------------------------------------------------
  - UI Moderna (Abas: Main, Remotes, Console).
  - Executor Visual: Teste remotes com 1 clique.
  - Console Colorido com Auto-Scroll.
  - Deep Scan Engine (BFS) anti-crash.
================================================================================
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local CONFIG = {
    YieldRate = 50,
    Stealth = {
        Enabled = true,
        SourceSignatures = {"nexus", "NEXUS", "Nexus", "recon_", "_gen", "stealth_"},
        BlockedPatterns = {"anticheat", "anti_cheat", "AntiCheat", "iac", "adonis", "Kick", "Ban", "Detect", "Report", "Monitor", "Watch", "Flag"}
    }
}

local NEXUS_LOGS = {}
local UpdateUI = {}
local FoundRemotes = {}

-- ============================================================================
-- 1. SISTEMA DE LOG (ÚLTIMA GERAÇÃO)
-- ============================================================================
local function Log(msg, type)
    type = type or "info"
    local timestamp = os.date("%H:%M:%S")
    local color = Color3.fromRGB(200, 200, 200)
    if type == "success" then color = Color3.fromRGB(100, 255, 100) end
    if type == "warn" then color = Color3.fromRGB(255, 200, 100) end
    if type == "error" then color = Color3.fromRGB(255, 100, 100) end
    
    table.insert(NEXUS_LOGS, {text = string.format("[%s] %s", timestamp, tostring(msg)), color = color})
    print("[NEXUS-7] " .. tostring(msg))
    if UpdateUI.Console then UpdateUI.Console() end
end

-- ============================================================================
-- 2. INTERFACE MODERNA
-- ============================================================================
local function getSafeParent()
    if type(gethui) == "function" then local ok, hui = pcall(gethui); if ok and hui then return hui end end
    local ok, cgui = pcall(function() return game:GetService("CoreGui") end)
    if ok and cgui and pcall(function() return cgui.Name end) then return cgui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function createUI()
    local parent = getSafeParent()
    local old = parent:FindFirstChild("Nexus7Gui"); if old then old:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Nexus7Gui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = parent

    -- Frame Principal (Mais largo para caber as abas)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 320, 0, 240)
    MainFrame.Position = UDim2.new(0.5, -160, 0.5, -120)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner"); MainCorner.CornerRadius = UDim.new(0, 10); MainCorner.Parent = MainFrame
    local MainStroke = Instance.new("UIStroke"); MainStroke.Color = Color3.fromRGB(60, 60, 80); MainStroke.Thickness = 1.5; MainStroke.Parent = MainFrame

    -- Header (Título arrastável)
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Header.Parent = MainFrame
    local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 10); HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 1, 0); Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1; Title.Text = "NEXUS-7 ULTIMATE"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left; Title.Parent = Header

    -- Sistema de Arrastar (Mobile/PC)
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Sidebar (Botões de Aba)
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 80, 1, -30); Sidebar.Position = UDim2.new(0, 0, 0, 30)
    Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 32); Sidebar.BorderSizePixel = 0; Sidebar.Parent = MainFrame
    
    -- Container de Conteúdo
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -80, 1, -30); ContentFrame.Position = UDim2.new(0, 80, 0, 30)
    ContentFrame.BackgroundTransparency = 1; ContentFrame.Parent = MainFrame

    -- Variáveis de Controle
    local currentTab = "Main"
    local tabButtons = {}
    local pages = {}

    local function CreatePage(name)
        local page = Instance.new("Frame")
        page.Size = UDim2.new(1, 0, 1, 0); page.BackgroundTransparency = 1; page.Visible = false; page.Parent = ContentFrame
        pages[name] = page
        return page
    end

    local MainPage = CreatePage("Main")
    local RemotesPage = CreatePage("Remotes")
    local ConsolePage = CreatePage("Console")

    -- Função de trocar aba
    local function SwitchTab(name)
        currentTab = name
        for n, p in pairs(pages) do p.Visible = (n == name) end
        for n, btn in pairs(tabButtons) do
            if n == name then btn.BackgroundColor3 = Color3.fromRGB(50, 50, 70) else btn.BackgroundColor3 = Color3.fromRGB(25, 25, 32) end
        end
    end

    -- Criar botões da Sidebar
    for i, tab in ipairs({"Main", "Remotes", "Console"}) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35); btn.Position = UDim2.new(0, 5, 0, 5 + (i-1)*40)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 32); btn.Text = tab; btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 11; btn.Parent = Sidebar
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
        tabButtons[tab] = btn
        btn.MouseButton1Click:Connect(function() SwitchTab(tab) end)
    end

    -- ==================== PÁGINA MAIN ====================
    local ScanBtn = Instance.new("TextButton")
    ScanBtn.Size = UDim2.new(0.9, 0, 0, 40); ScanBtn.Position = UDim2.new(0.05, 0, 0, 20)
    ScanBtn.BackgroundColor3 = Color3.fromRGB(80, 150, 255); ScanBtn.Text = "Iniciar Escaneamento"
    ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ScanBtn.Font = Enum.Font.GothamBold; ScanBtn.TextSize = 12; ScanBtn.Parent = MainPage
    local ScanCorner = Instance.new("UICorner"); ScanCorner.CornerRadius = UDim.new(0, 6); ScanCorner.Parent = ScanBtn

    local StatusLbl = Instance.new("TextLabel")
    StatusLbl.Size = UDim2.new(0.9, 0, 0, 30); StatusLbl.Position = UDim2.new(0.05, 0, 0, 70)
    StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "Status: Aguardando..."; StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLbl.Font = Enum.Font.Gotham; StatusLbl.TextSize = 11; StatusLbl.TextXAlignment = Enum.TextXAlignment.Left; StatusLbl.Parent = MainPage

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30); ToggleBtn.Position = UDim2.new(0.05, 0, 0, 110)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80); ToggleBtn.Text = "Stealth: ON"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.Font = Enum.Font.GothamSemibold; ToggleBtn.TextSize = 12; ToggleBtn.Parent = MainPage
    local ToggleCorner = Instance.new("UICorner"); ToggleCorner.CornerRadius = UDim.new(0, 6); ToggleCorner.Parent = ToggleBtn

    ToggleBtn.MouseButton1Click:Connect(function()
        CONFIG.Stealth.Enabled = not CONFIG.Stealth.Enabled
        if CONFIG.Stealth.Enabled then
            ToggleBtn.Text = "Stealth: ON"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80); Log("Camuflagem ativada.", "success")
        else
            ToggleBtn.Text = "Stealth: OFF"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); Log("Camuflagem desativada.", "warn")
        end
    end)

    -- ==================== PÁGINA REMOTES ====================
    local RemoteScroll = Instance.new("ScrollingFrame")
    RemoteScroll.Size = UDim2.new(1, -10, 1, -10); RemoteScroll.Position = UDim2.new(0, 5, 0, 5)
    RemoteScroll.BackgroundTransparency = 1; RemoteScroll.ScrollBarThickness = 4
    RemoteScroll.CanvasSize = UDim2.new(0, 0, 0, 0); RemoteScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; RemoteScroll.Parent = RemotesPage
    
    local RemoteList = Instance.new("UIListLayout")
    RemoteList.Padding = UDim.new(0, 5); RemoteList.SortOrder = Enum.SortOrder.LayoutOrder; RemoteList.Parent = RemoteScroll

    -- ==================== PÁGINA CONSOLE ====================
    local ConsoleScroll = Instance.new("ScrollingFrame")
    ConsoleScroll.Size = UDim2.new(1, -10, 1, -40); ConsoleScroll.Position = UDim2.new(0, 5, 0, 5)
    ConsoleScroll.BackgroundTransparency = 1; ConsoleScroll.ScrollBarThickness = 4
    ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0); ConsoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; ConsoleScroll.Parent = ConsolePage
    
    local ConsoleText = Instance.new("TextLabel")
    ConsoleText.Size = UDim2.new(1, 0, 0, 0); ConsoleText.AutomaticSize = Enum.AutomaticSize.Y
    ConsoleText.BackgroundTransparency = 1; ConsoleText.TextXAlignment = Enum.TextXAlignment.Left
    ConsoleText.TextYAlignment = Enum.TextYAlignment.Top; ConsoleText.TextColor3 = Color3.fromRGB(200, 200, 200)
    ConsoleText.Font = Enum.Font.Code; ConsoleText.TextSize = 10; ConsoleText.TextWrapped = true; ConsoleText.Parent = ConsoleScroll

    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0.3, 0, 0, 25); ClearBtn.Position = UDim2.new(0.7, -5, 1, -30)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40); ClearBtn.Text = "Limpar"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ClearBtn.Font = Enum.Font.GothamBold; ClearBtn.TextSize = 10; ClearBtn.Parent = ConsolePage
    local ClearCorner = Instance.new("UICorner"); ClearCorner.CornerRadius = UDim.new(0, 4); ClearCorner.Parent = ClearBtn

    ClearBtn.MouseButton1Click:Connect(function()
        NEXUS_LOGS = {}
        UpdateUI.Console()
    end)

    -- Inicializa Aba Main
    SwitchTab("Main")

    -- Funções de Atualização da UI
    UpdateUI.Console = function()
        local finalRichText = ""
        for _, log in ipairs(NEXUS_LOGS) do
            local hexColor = log.color:ToHex()
            finalRichText = finalRichText .. string.format('<font color="#%s">%s</font>\n', hexColor, log.text)
        end
        ConsoleText.Text = finalRichText
        task.defer(function() ConsoleScroll.CanvasPosition = Vector2.new(0, ConsoleScroll.AbsoluteCanvasSize.Y) end)
    end

    UpdateUI.Status = function(txt)
        StatusLbl.Text = "Status: " .. txt
    end

    UpdateUI.AddRemoteButton = function(remote, index)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -5, 0, 35); btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = remote.Name .. " (" .. remote.ClassName .. ")"; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 10; btn.Parent = RemoteScroll
        btn.LayoutOrder = index
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            Log("Tentando disparar: " .. remote.Name, "info")
            local success, err = pcall(function()
                if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                    remote:FireServer(nil)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(nil)
                end
            end)
            if success then
                Log("Sucesso ao disparar " .. remote.Name, "success")
            else
                Log("Erro em " .. remote.Name .. ": " .. tostring(err), "error")
            end
        end)
    end

    -- Libera o botão de Scan
    UpdateUI.EnableScan = function(enabled)
        ScanBtn.Active = enabled
        ScanBtn.AutoButtonColor = enabled
        ScanBtn.Text = enabled and "Iniciar Escaneamento" or "Escaneando..."
        ScanBtn.BackgroundColor3 = enabled and Color3.fromRGB(80, 150, 255) or Color3.fromRGB(80, 80, 80)
    end
end

pcall(createUI)

-- ============================================================================
-- 3. STEALTH BÁSICO
-- ============================================================================
local function InstallStealth()
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
    Log("Spoof de metatable instalado.", "success")
end

-- ============================================================================
-- 4. DEEP SCANNER
-- ============================================================================
local function DeepScan()
    Log("Iniciando Deep Scan (BFS)...", "info")
    UpdateUI.Status("Preparando...")
    
    local remotes = {}
    local queue = {game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("Players")}
    local visited = {}
    local count = 0

    while #queue > 0 do
        local current = table.remove(queue, 1)
        local ok, isRemote = pcall(function() return current:IsA("RemoteEvent") or current:IsA("RemoteFunction") or current:IsA("UnreliableRemoteEvent") end)
        
        if ok and isRemote then
            table.insert(remotes, current)
        end
        
        local okC, children = pcall(function() return current:GetChildren() end)
        if okC and children then
            for _, child in ipairs(children) do
                if not visited[child] then
                    visited[child] = true
                    table.insert(queue, child)
                end
            end
        end
        
        count = count + 1
        if count % CONFIG.YieldRate == 0 then
            UpdateUI.Status(string.format("Lendo %d itens... (%d remotes)", count, #remotes))
            task.wait()
        end
    end
    return remotes
end

-- ============================================================================
-- 5. INICIALIZAÇÃO
-- ============================================================================
task.spawn(function()
    task.wait(1)
    Log("NEXUS-7 v9.0 Inicializado. Bem-vindo.", "success")
    InstallStealth()
    
    -- Conecta o botão de scan
    if UpdateUI.EnableScan then
        -- Hack para conectar o evento do botão após a UI ser criada
        local parent = getSafeParent()
        local gui = parent:FindFirstChild("Nexus7Gui")
        if gui then
            local mainFrame = gui:FindFirstChild("Frame")
            -- Localiza o botão de scan via busca profunda (apenas para conectar)
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextButton") and desc.Text == "Iniciar Escaneamento" then
                    desc.MouseButton1Click:Connect(function()
                        if ScanRunning then return end
                        ScanRunning = true
                        UpdateUI.EnableScan(false)
                        
                        local found = DeepScan()
                        UpdateUI.Status(string.format("Concluído! %d remotes encontrados.", #found))
                        Log(string.format("Varredura concluída. %d remotes.", #found), "success")
                        
                        for i, r in ipairs(found) do
                            UpdateUI.AddRemoteButton(r, i)
                        end
                        
                        ScanRunning = false
                        UpdateUI.EnableScan(true)
                    end)
                    break
                end
            end
        end
    end
end)
