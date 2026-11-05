--[[
================================================================================
  NEXUS-7 :: RECON + BASE-GEN + STEALTH ENGINE (UI EDITION v7.1)
  ------------------------------------------------------------------------------
  - Compatível com Celular e PC.
  - UI responsiva com Toggle, Console e Copiar.
  - Anti-freeze: Loops pesados usam task.wait().
  - FIX: Fallback de UI (gethui -> CoreGui -> PlayerGui) para nunca falhar.
================================================================================
]]

-- ============================================================================
-- 1. PROTEÇÃO E CONFIGURAÇÃO INICIAL
-- ============================================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")

local CONFIG = {
    Debug = true,
    Stealth = {
        Enabled = true,
        SpoofWalkSpeed = 16,
        SpoofJumpPower = 50,
        SpoofGravity = 196.2,
        SourceSignatures = {"nexus", "NEXUS", "Nexus", "recon_", "_gen", "stealth_"},
        BlockedPatterns = {
            "anticheat", "anti_cheat", "AntiCheat", "anti-cheat", "iac", "IAC", 
            "adonis", "Adonis", "Kick", "kick", "Ban", "ban", "Detect", "detect", 
            "Report", "report", "Monitor", "monitor", "Watch", "watch", "Flag", "flag"
        }
    },
    Recon = {
        MaxDescendants = 15000,
        HighValueTokens = {
            "Buy", "Purchase", "Claim", "Reward", "Give", "Grant", "Add", "Set", 
            "Update", "Save", "Load", "Cash", "Coin", "Money", "Gem", "Robux", 
            "Item", "Inventory", "Trade", "Admin", "Command", "Spawn", "Teleport", 
            "Kill", "Damage", "Stat", "Level", "Exp", "Skill", "Power", "Boost"
        }
    }
}

local NEXUS_LOGS = {}
local updateUIConsole = nil

-- ============================================================================
-- 2. SISTEMA DE LOG E CONSOLE
-- ============================================================================
local function logToConsole(msg)
    local text = tostring(msg)
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s] %s", timestamp, text)
    table.insert(NEXUS_LOGS, formatted)
    print("[NEXUS-7] " .. text)
    if updateUIConsole then updateUIConsole() end
end

local function getConsoleText()
    return table.concat(NEXUS_LOGS, "\n")
end

-- ============================================================================
-- 3. INTERFACE GRÁFICA (UI) - MOBILE E PC
-- ============================================================================
local function getSafeParent()
    -- Tenta usar o gethui (padrão de executores modernos)
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    
    -- Tenta o CoreGui
    local ok, cgui = pcall(function() return game:GetService("CoreGui") end)
    if ok and cgui then 
        -- Testa se consegue ler (alguns jogos bloqueiam)
        local readOk = pcall(function() return cgui.Name end)
        if readOk then return cgui end
    end
    
    -- Fallback final: PlayerGui (sempre funciona)
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

    -- Frame Principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 220, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -110, 0.5, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true 
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Título
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Title.BackgroundTransparency = 0.5
    Title.Text = "NEXUS-7 PANEL"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = Title

    -- Botão Toggle
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ToggleBtn.Position = UDim2.new(0.05, 0, 0, 40)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
    ToggleBtn.Text = "Stealth: ON"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamSemibold
    ToggleBtn.TextSize = 12
    ToggleBtn.Parent = MainFrame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 4)
    ToggleCorner.Parent = ToggleBtn

    -- Botão Console
    local ConsoleBtn = Instance.new("TextButton")
    ConsoleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ConsoleBtn.Position = UDim2.new(0.05, 0, 0, 80)
    ConsoleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    ConsoleBtn.Text = "Abrir Console"
    ConsoleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConsoleBtn.Font = Enum.Font.GothamSemibold
    ConsoleBtn.TextSize = 12
    ConsoleBtn.Parent = MainFrame

    local ConsoleCorner = Instance.new("UICorner")
    ConsoleCorner.CornerRadius = UDim.new(0, 4)
    ConsoleCorner.Parent = ConsoleBtn

    -- Botão Copiar
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0.9, 0, 0, 30)
    CopyBtn.Position = UDim2.new(0.05, 0, 0, 120)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    CopyBtn.Text = "Copiar Console"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamSemibold
    CopyBtn.TextSize = 12
    CopyBtn.Parent = MainFrame

    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(0, 4)
    CopyCorner.Parent = CopyBtn

    -- Painel do Console
    local ConsoleFrame = Instance.new("Frame")
    ConsoleFrame.Name = "ConsoleFrame"
    ConsoleFrame.Size = UDim2.new(0.95, 0, 0, 0)
    ConsoleFrame.Position = UDim2.new(0.025, 0, 0, 160)
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
    ConsoleText.TextSize = 11
    ConsoleText.TextWrapped = true
    ConsoleText.Text = "-- Console vazio --"
    ConsoleText.Parent = ScrollFrame

    -- Lógica para arrastar no Celular
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Lógica dos Botões
    local consoleOpen = false
    
    ToggleBtn.MouseButton1Click:Connect(function()
        CONFIG.Stealth.Enabled = not CONFIG.Stealth.Enabled
        if CONFIG.Stealth.Enabled then
            ToggleBtn.Text = "Stealth: ON"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
            logToConsole("Camuflagem ativada.")
        else
            ToggleBtn.Text = "Stealth: OFF"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            logToConsole("Camuflagem desativada.")
        end
    end)

    ConsoleBtn.MouseButton1Click:Connect(function()
        consoleOpen = not consoleOpen
        if consoleOpen then
            ConsoleFrame.Visible = true
            ConsoleFrame:TweenSize(UDim2.new(0.95, 0, 0, 150), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            MainFrame:TweenSize(UDim2.new(0, 220, 0, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            ConsoleBtn.Text = "Fechar Console"
            ConsoleText.Text = getConsoleText() == "" and "-- Console vazio --" or getConsoleText()
        else
            ConsoleBtn.Text = "Abrir Console"
            ConsoleFrame:TweenSize(UDim2.new(0.95, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true, function()
                ConsoleFrame.Visible = false
            end)
            MainFrame:TweenSize(UDim2.new(0, 220, 0, 160), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        end
    end)

    CopyBtn.MouseButton1Click:Connect(function()
        local textToCopy = getConsoleText()
        if textToCopy == "" then textToCopy = "Nenhum log gerado ainda." end
        
        if setclipboard then
            setclipboard(textToCopy)
            CopyBtn.Text = "Copiado!"
            task.wait(1)
            CopyBtn.Text = "Copiar Console"
        elseif toclipboard then
            toclipboard(textToCopy)
            CopyBtn.Text = "Copiado!"
            task.wait(1)
            CopyBtn.Text = "Copiar Console"
        else
            logToConsole("ERRO: Executor sem suporte a clipboard.")
            CopyBtn.Text = "Falhou!"
        end
    end)

    return function()
        if consoleOpen then
            ConsoleText.Text = getConsoleText()
        end
    end
end

-- Cria a UI e captura possíveis erros
local success, uiReturn = pcall(createUI)
if success then
    updateUIConsole = uiReturn
    print("[NEXUS-7] Interface criada com sucesso.")
else
    warn("[NEXUS-7] ERRO AO CRIAR UI: " .. tostring(uiReturn))
end

-- ============================================================================
-- 4. MÓDULO STEALTH
-- ============================================================================
local Stealth = {}
local function hasExecutor()
    return type(getrawmetatable) == "function" and type(checkcaller) == "function"
end

local function makeWritable(mt)
    if type(setreadonly) == "function" then pcall(setreadonly, mt, false) end
    if type(make_writeable) == "function" then pcall(make_writeable, mt) end
end

function Stealth.spoofGameMetatable()
    if not hasExecutor() then return end
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end
    
    local oldIndex = mt.__index
    makeWritable(mt)
    
    mt.__index = function(self, key)
        if checkcaller() then return oldIndex(self, key) end
        if CONFIG.Stealth.Enabled then
            if key == "WalkSpeed" or key == "JumpPower" then
                local okH, isH = pcall(function() return self:IsA("Humanoid") end)
                if okH and isH then
                    return key == "WalkSpeed" and CONFIG.Stealth.SpoofWalkSpeed or CONFIG.Stealth.SpoofJumpPower
                end
            elseif key == "Gravity" then
                local okW, isW = pcall(function() return self:IsA("Workspace") end)
                if okW and isW then return CONFIG.Stealth.SpoofGravity end
            end
        end
        return oldIndex(self, key)
    end
    if type(setreadonly) == "function" then pcall(setreadonly, mt, true) end
    logToConsole("Spoof de metatable instalado.")
end

function Stealth.installGCGuard()
    if type(getgc) ~= "function" or not hasExecutor() then return end
    local ourRefs = {}
    for _, v in pairs(Stealth) do if type(v) == "function" then ourRefs[v] = true end end

    local original = getgc
    pcall(function()
        getgc = function(includeTables)
            local all = original(includeTables)
            if checkcaller() or type(all) ~= "table" then return all end
            local out = {}
            local count = 0
            for i, obj in pairs(all) do
                count = count + 1
                if count % 1000 == 0 then task.wait() end 
                
                if ourRefs[obj] then
                    -- skip
                elseif type(obj) == "function" then
                    local okInfo, info = pcall(debug.getinfo, obj)
                    if not okInfo or not info or not info.source then
                        out[i] = obj
                    else
                        local isOurs = false
                        for _, sig in ipairs(CONFIG.Stealth.SourceSignatures) do
                            if string.find(string.lower(info.source), string.lower(sig), 1, true) then
                                isOurs = true; break
                            end
                        end
                        if not isOurs then out[i] = obj end
                    end
                else
                    out[i] = obj
                end
            end
            return out
        end
    end)
    logToConsole("GC Guard instalado.")
end

-- ============================================================================
-- 5. MÓDULO RECON
-- ============================================================================
local Recon = {}

function Recon.findRemotes()
    local remotes, seen = {}, {}
    local services = {
        ReplicatedStorage, ReplicatedFirst, Workspace, Players,
        game:GetService("StarterGui"), game:GetService("StarterPack")
    }

    for _, svc in ipairs(services) do
        local ok, desc = pcall(function() return svc:GetDescendants() end)
        if ok and desc then
            local count = 0
            for _, d in ipairs(desc) do
                count = count + 1
                if count % 500 == 0 then task.wait() end 
                if count > CONFIG.Recon.MaxDescendants then break end
                
                if not seen[d] and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent")) then
                    seen[d] = true
                    table.insert(remotes, d)
                end
            end
        end
    end
    return remotes
end

function Recon.score(remote)
    local score = 0
    local name = remote.Name or ""
    for _, tok in ipairs(CONFIG.Recon.HighValueTokens) do
        if string.find(string.lower(name), string.lower(tok), 1, true) then score = score + 25 end
    end
    if remote.Parent == ReplicatedStorage then score = score + 10 end
    if remote:IsA("RemoteFunction") then score = score + 5 end
    return score
end

-- ============================================================================
-- 6. GERADOR DE BASE
-- ============================================================================
local function generateBase(remotes)
    local L = {"--[[ NEXUS-7 :: AUTO-GENERATED BASE ]]", ""}
    table.insert(L, "local REMOTES = {}")
    for _, r in ipairs(remotes) do
        local path, p = {}, r
        while p and p ~= game do table.insert(path, 1, string.format('["%s"]', p.Name)); p = p.Parent end
        local expr = "game" .. table.concat(path)
        if path[1] == '["ReplicatedStorage"]' then
            expr = "ReplicatedStorage" .. table.concat(path, "", 2)
        end
        table.insert(L, string.format("REMOTES[%q] = %s -- score=%d", r.Name, expr, r._nexus_score or 0))
    end
    table.insert(L, "\nlocal function fire(name, ...)")
    table.insert(L, "    local r = REMOTES[name]")
    table.insert(L, "    if r then r:FireServer(...) end")
    table.insert(L, "end")
    return table.concat(L, "\n")
end

-- ============================================================================
-- 7. ATIVAÇÃO PRINCIPAL
-- ============================================================================
task.spawn(function()
    task.wait(1) -- Espera a UI carregar 100%
    logToConsole("Iniciando varredura NEXUS-7...")
    
    if CONFIG.Stealth.Enabled then
        Stealth.spoofGameMetatable()
        Stealth.installGCGuard()
    end

    logToConsole("Escaneando remotes...")
    local remotes = Recon.findRemotes()
    logToConsole(string.format("Encontrados %d remotes.", #remotes))

    for _, r in ipairs(remotes) do
        r._nexus_score = Recon.score(r)
    end
    
    table.sort(remotes, function(a, b) return (a._nexus_score or 0) > (b._nexus_score or 0) end)

    logToConsole("Gerando base script...")
    local baseScript = generateBase(remotes)
    
    logToConsole("=== INICIO DA BASE GERADA ===")
    logToConsole(baseScript)
    logToConsole("=== FIM DA BASE GERADA ===")

    if writefile then
        pcall(function()
            local report = { game = game.Name, placeId = game.PlaceId, remotes = {} }
            for _, r in ipairs(remotes) do
                table.insert(report.remotes, { name = r.Name, score = r._nexus_score })
            end
            writefile("nexus7_report.json", HttpService:JSONEncode(report))
            logToConsole("Relatório JSON salvo na workspace do executor.")
        end)
    end

    logToConsole("Concluído! O jogo não travou.")
end)
