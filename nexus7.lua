--[[
================================================================================
  NEXUS-7 :: RECON + BASE-GEN + STEALTH ENGINE          (single-file Luau asset)
  ------------------------------------------------------------------------------
  Ao ativar, ele:
    1. Instala a camuflagem (spoof de propriedades, namecall guard, GC guard,
       debug.getinfo guard, spoof de identidade do executor).
    2. Enumera todos os RemoteEvent / RemoteFunction / BindableEvent /
       UnreliableRemoteEvent alcançáveis.
    3. Pontua cada remote (tokens de alto valor, parent, profundidade, tipo).
    4. Sonda rate-limit dos remotes de alto valor (modo seguro: ignora
       qualquer nome que bata com a lista de anti-cheat).
    5. Emite relatório (console + JSON via writefile) E gera um script-base
       com todos os remotes prontos para uso.

  Uso:
    - Executor : cole / loadstring e rode.
    - Studio   : cole num LocalScript; a camada stealth degrada
                 graciosamente (sem primitivas de executor -> é ignorada).
================================================================================
]]

if not game then return warn("[NEXUS-7] Ambiente Roblox necessário") end

--============================================================= SERVIÇOS
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local Workspace         = game:GetService("Workspace")
local HttpService       = game:GetService("HttpService")
local LocalPlayer       = Players.LocalPlayer

--============================================================= CONFIG
local CONFIG = {
    Version = "7.0.1",
    Debug   = true,

    Stealth = {
        Enabled         = true,
        SpoofWalkSpeed  = 16,
        SpoofJumpPower  = 50,
        SpoofGravity    = 196.2,

        -- assinaturas que o nosso código deixa nas fontes (para o GC guard)
        SourceSignatures = {
            "nexus", "NEXUS", "Nexus", "recon_", "_gen", "stealth_",
        },

        -- qualquer remote cujo nome contenha um destes é tratado como
        -- hostil: nunca é sondado e o disparo vindo do jogo é engolido.
        BlockedPatterns = {
            "anticheat", "anti_cheat", "AntiCheat", "anti-cheat",
            "iac", "IAC", "Iac",
            "adonis", "Adonis",
            "Kick", "kick", "Ban", "ban",
            "Detect", "detect", "Report", "report",
            "Monitor", "monitor", "Watch", "watch",
            "Flag", "flag", "Suspicious",
        },

        GuardNamecall   = true,
        HideFromGetGC   = true,
        HideFromGetInfo = true,
    },

    Recon = {
        MaxDescendantsPerService = 25000,
        LiveProbe                = true,
        SafeProbe                = true,
        RateLimitProbes          = 40,
        HighValueTokens = {
            "Buy", "Purchase", "Claim", "Reward", "Give", "Grant",
            "Add", "Set", "Update", "Save", "Load", "Cash", "Coin",
            "Money", "Gem", "Robux", "Item", "Inventory", "Trade",
            "Admin", "Command", "Spawn", "Teleport", "Kill", "Damage",
            "Stat", "Level", "Exp", "Skill", "Power", "Boost",
        },
        DangerousTokens = {
            "Kick", "Ban", "Detect", "Report", "Flag", "Watch", "Monitor",
        },
    },

    Output = {
        PrintToConsole = true,
        FilePath       = "nexus7_report.json",
        BasePath       = "nexus7_base.lua",
    },
}

--============================================================= UTIL
local function log(fmt, ...)
    if CONFIG.Debug then
        print(("[NEXUS-7] " .. fmt):format(...))
    end
end

local function nc(fn)
    if type(newcclosure) == "function" then
        local ok, wrapped = pcall(newcclosure, fn)
        if ok and wrapped then return wrapped end
    end
    return fn
end

local function truncate(s, n)
    s = tostring(s or "")
    n = n or 80
    if #s > n then return s:sub(1, n - 3) .. "..." end
    return s
end

local function matchesAny(str, patterns)
    if not str then return false end
    local lower = string.lower(str)
    for _, p in ipairs(patterns) do
        if string.find(lower, string.lower(p), 1, true) then return true, p end
    end
    return false
end

local function makeWritable(mt)
    if type(setreadonly) == "function" then pcall(setreadonly, mt, false) end
    if type(make_writeable) == "function" then pcall(make_writeable, mt) end
end

--============================================================= STEALTH
local Stealth = {}
Stealth._installed = {}

local function hasExecutor()
    return type(getrawmetatable) == "function"
       and type(checkcaller)      == "function"
end

function Stealth.spoofGameMetatable()
    if not hasExecutor() then
        log("Primitivas de executor ausentes; spoof de metatable ignorado")
        return
    end
    local ok, mt = pcall(getrawmetatable, game)
    if not ok or not mt then return end

    local oldIndex = mt.__index
    makeWritable(mt)

    mt.__index = nc(function(self, key)
        -- chamadas do executor veem valores reais
        if checkcaller() then
            return oldIndex(self, key)
        end

        -- camuflagem: o jogo lê valores "limpos"
        if key == "WalkSpeed" or key == "JumpPower" then
            local okH, isH = pcall(function() return self:IsA("Humanoid") end)
            if okH and isH then
                if key == "WalkSpeed" then return CONFIG.Stealth.SpoofWalkSpeed end
                if key == "JumpPower" then return CONFIG.Stealth.SpoofJumpPower end
            end
        elseif key == "Gravity" then
            local okW, isW = pcall(function() return self:IsA("Workspace") end)
            if okW and isW then return CONFIG.Stealth.SpoofGravity end
        end

        return oldIndex(self, key)
    end)

    if type(setreadonly) == "function" then pcall(setreadonly, mt, true) end
    Stealth._installed.metatable = true
    log("Spoof de metatable instalado (WalkSpeed/JumpPower/Gravity)")
end

function Stealth.installNamecallGuard()
    if not CONFIG.Stealth.GuardNamecall then return end
    if not hasExecutor() or type(hookmetamethod) ~= "function"
       or type(getnamecallmethod) ~= "function" then
        log("Namecall guard indisponível")
        return
    end

    local ok, old = pcall(hookmetamethod, game, "__namecall", nc(function(self, ...)
        local method = getnamecallmethod()
        if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
            local name = (typeof(self) == "Instance") and self.Name or ""
            local hit, pat = matchesAny(name, CONFIG.Stealth.BlockedPatterns)
            if hit then
                log("Bloqueado disparo do jogo -> %s (match=%s)", tostring(name), tostring(pat))
                return
            end
        end
        return old(self, ...)
    end))

    if ok then
        Stealth._installed.namecall = true
        log("Namecall guard instalado")
    end
end

function Stealth.installGCGuard()
    if not CONFIG.Stealth.HideFromGetGC then return end
    if type(getgc) ~= "function" or not hasExecutor() then
        log("GC guard indisponível")
        return
    end

    local ourRefs = {}
    for _, v in pairs(Stealth) do
        if type(v) == "function" then ourRefs[v] = true end
    end

    local original = getgc
    local ok = pcall(function()
        getgc = nc(function(includeTables)
            local all = original(includeTables)
            if checkcaller() or type(all) ~= "table" then return all end
            local out = {}
            for i, obj in pairs(all) do
                if ourRefs[obj] then
                    -- skip
                elseif type(obj) == "function" then
                    local okInfo, info = pcall(debug.getinfo, obj)
                    if not okInfo or not info or not info.source
                       or not matchesAny(info.source, CONFIG.Stealth.SourceSignatures) then
                        out[i] = obj
                    end
                else
                    out[i] = obj
                end
            end
            return out
        end)
    end)
    if ok then
        Stealth._installed.gc = true
        log("GC guard instalado")
    end
end

function Stealth.installInfoGuard()
    if not CONFIG.Stealth.HideFromGetInfo then return end
    if type(debug) ~= "table" or type(debug.getinfo) ~= "function" or not hasExecutor() then
        log("debug.getinfo guard indisponível")
        return
    end
    local original = debug.getinfo
    local ok = pcall(function()
        debug.getinfo = nc(function(target, what)
            local info = original(target, what)
            if checkcaller() then return info end
            if type(info) == "table" and info.source
               and matchesAny(info.source, CONFIG.Stealth.SourceSignatures) then
                return nil
            end
            return info
        end)
    end)
    if ok then
        Stealth._installed.info = true
        log("debug.getinfo guard instalado")
    end
end

function Stealth.spoofExecutorIdentity()
    if type(getgenv) ~= "function" then return end
    local env = getgenv()
    if type(env) ~= "table" then return end
    pcall(function()
        env.identifyexecutor = nc(function() return "Roblox", "1.0.0" end)
        env.getexecutorname  = nc(function() return "Roblox" end)
    end)
    Stealth._installed.identity = true
    log("Identidade do executor mascarada")
end

function Stealth.installAll()
    if not CONFIG.Stealth.Enabled then
        log("Stealth desativado por config")
        return
    end
    Stealth.spoofGameMetatable()
    Stealth.installNamecallGuard()
    Stealth.installGCGuard()
    Stealth.installInfoGuard()
    Stealth.spoofExecutorIdentity()
end

--============================================================= RECON
local Recon = {}

function Recon.findRemotes()
    local remotes, seen = {}, {}
    local services = {
        ReplicatedStorage, ReplicatedFirst, Workspace, Players,
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("Lighting"),
        game:GetService("SoundService"),
        game:GetService("Chat"),
        game:GetService("Teams"),
    }

    for _, svc in ipairs(services) do
        local ok, desc = pcall(function() return svc:GetDescendants() end)
        if ok and desc then
            local n = 0
            for _, d in ipairs(desc) do
                n = n + 1
                if n > CONFIG.Recon.MaxDescendantsPerService then break end
                if not seen[d] and (
                    d:IsA("RemoteEvent")
                    or d:IsA("RemoteFunction")
                    or d:IsA("UnreliableRemoteEvent")
                    or d:IsA("BindableEvent")
                ) then
                    seen[d] = true
                    remotes[#remotes + 1] = d
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        local ok, desc = pcall(function() return plr:GetDescendants() end)
        if ok and desc then
            for _, d in ipairs(desc) do
                if not seen[d] and (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then
                    seen[d] = true
                    remotes[#remotes + 1] = d
                end
            end
        end
    end

    return remotes
end

function Recon.score(remote)
    local score, reasons = 0, {}
    local name = remote.Name or ""

    for _, tok in ipairs(CONFIG.Recon.HighValueTokens) do
        if string.find(string.lower(name), string.lower(tok), 1, true) then
            score = score + 25
            reasons[#reasons + 1] = "token:" .. tok
        end
    end

    if matchesAny(name, CONFIG.Recon.DangerousTokens) then
        score = score - 60
        reasons[#reasons + 1] = "danger_token"
    end

    if remote.Parent == ReplicatedStorage then
        score = score + 10
        reasons[#reasons + 1] = "parent:ReplicatedStorage"
    end

    if remote.Parent and matchesAny(remote.Parent.Name,
        {"Remotes", "Remote", "Networking", "Network", "Events", "Comm", "Packets"}) then
        score = score + 8
        reasons[#reasons + 1] = "parent_group"
    end

    if remote:IsA("RemoteFunction") then
        score = score + 5
        reasons[#reasons + 1] = "RemoteFunction"
    elseif remote:IsA("UnreliableRemoteEvent") then
        score = score + 3
        reasons[#reasons + 1] = "Unreliable"
    end

    local depth, p = 0, remote
    while p and p ~= game do depth = depth + 1; p = p.Parent end
    if depth <= 4 then
        score = score + 5
        reasons[#reasons + 1] = "shallow"
    end

    return score, reasons
end

function Recon.probeRateLimit(remote)
    if not remote:IsA("RemoteEvent") and not remote:IsA("UnreliableRemoteEvent") then
        return nil
    end
    if CONFIG.Recon.SafeProbe and matchesAny(remote.Name, CONFIG.Stealth.BlockedPatterns) then
        return { skipped = true, reason = "danger_token" }
    end

    local n   = CONFIG.Recon.RateLimitProbes
    local t0  = os.clock()
    local okN = 0
    for _ = 1, n do
        if pcall(function() remote:FireServer() end) then okN = okN + 1 end
    end
    local dt = os.clock() - t0

    return {
        fired       = n,
        ok          = okN,
        elapsed     = dt,
        perCall     = dt / n,
        rateLimited = okN < n,
    }
end

--============================================================= BASE GEN
local function generateBase(remotes)
    local L = {}
    local function w(s) L[#L + 1] = s or "" end

    w("--[[ NEXUS-7 :: AUTO-GENERATED BASE ]=================================")
    w(("  Game      : %s"):format(game.Name))
    w(("  PlaceId   : %s"):format(tostring(game.PlaceId)))
    w(("  JobId     : %s"):format(tostring(game.JobId)))
    w(("  Generated : %s"):format(os.date("!%Y-%m-%dT%H:%M:%SZ")))
    w(("  Remotes   : %d"):format(#remotes))
    w("]=====================================================================]")
    w("")
    w("local Players           = game:GetService(\"Players\")")
    w("local ReplicatedStorage = game:GetService(\"ReplicatedStorage\")")
    w("local LocalPlayer       = Players.LocalPlayer")
    w("")
    w("local REMOTES = {}")
    w("")
    for _, r in ipairs(remotes) do
        local path, p = {}, r
        while p and p ~= game do
            table.insert(path, 1, ("[\"%s\"]"):format(tostring(p.Name):gsub("\"", "\\\"")))
            p = p.Parent
        end
        local expr
        if path[1] == "[\"ReplicatedStorage\"]" then
            expr = "ReplicatedStorage" .. table.concat(path, "", 2)
        else
            expr = "game" .. table.concat(path)
        end
        w(("REMOTES[%q] = %s -- score=%d %s"):format(
            r.Name, expr, r._nexus_score or 0,
            table.concat(r._nexus_reasons or {}, ",")))
    end
    w("")
    w("local function fire(name, ...)")
    w("    local r = REMOTES[name]")
    w("    if not r then return warn(\"[BASE] remote inexistente: \" .. tostring(name)) end")
    w("    if r:IsA(\"RemoteEvent\") or r:IsA(\"UnreliableRemoteEvent\") then")
    w("        return r:FireServer(...)")
    w("    elseif r:IsA(\"RemoteFunction\") then")
    w("        return r:InvokeServer(...)")
    w("    end")
    w("end")
    w("")
    w("local function invoke(name, ...)")
    w("    local r = REMOTES[name]")
    w("    if not r or not r:IsA(\"RemoteFunction\") then return nil end")
    w("    local ok, res = pcall(function() return r:InvokeServer(...) end)")
    w("    return ok and res or nil")
    w("end")
    w("")
    w("-- ===== Entrypoints de alto valor (skeletons auto-gerados) =====")
    for _, r in ipairs(remotes) do
        local sc = r._nexus_score or 0
        if sc >= 25 then
            w(("-- [[ %s ]]  score=%d  (%s)"):format(
                r.Name, sc, table.concat(r._nexus_reasons or {}, ",")))
            if r:IsA("RemoteFunction") then
                w(("-- local ok, res = invoke(%q, ...)"):format(r.Name))
            else
                w(("-- fire(%q, ...)"):format(r.Name))
            end
        end
    end
    w("")
    w("return { REMOTES = REMOTES, fire = fire, invoke = invoke }")
    return table.concat(L, "\n")
end

--============================================================= REPORTER
local Reporter = {}

function Reporter.print(report)
    print("=====================================================")
    print("  NEXUS-7 :: REPORT")
    print("=====================================================")
    print(("  Game    : %s"):format(report.game))
    print(("  PlaceId : %s"):format(report.placeId))
    print(("  Remotes : %d  | CRIT:%d  HIGH:%d  MED:%d  LOW:%d"):format(
        #report.remotes, report.counts.critical, report.counts.high,
        report.counts.medium, report.counts.low))
    print("-----------------------------------------------------")
    for _, r in ipairs(report.remotes) do
        local tag = r.score >= 60 and "CRIT"
                 or r.score >= 35 and "HIGH"
                 or r.score >= 15 and "MED "
                 or "LOW "
        local probe = ""
        if r.probe and r.probe.rateLimited then probe = " [RATE-LIMITED]" end
        print(("[%s] %-48s score=%3d  %s%s"):format(
            tag, truncate(r.path, 48), r.score,
            table.concat(r.reasons or {}, ","), probe))
    end
    print("=====================================================")
end

function Reporter.saveJSON(report)
    if type(writefile) ~= "function" then return false end
    return pcall(function()
        writefile(CONFIG.Output.FilePath, HttpService:JSONEncode(report))
    end)
end

function Reporter.saveBase(base)
    if type(writefile) ~= "function" then return false end
    return pcall(function() writefile(CONFIG.Output.BasePath, base) end)
end

--============================================================= ATIVAÇÃO
local NEXUS = {
    Stealth  = Stealth,
    Recon    = Recon,
    Reporter = Reporter,
    Config   = CONFIG,
}

function NEXUS.activate()
    log("Boot NEXUS-7 v%s", CONFIG.Version)

    -- 1. camuflagem
    Stealth.installAll()

    -- 2. recon
    local remotes = Recon.findRemotes()
    log("%d remotes descobertos", #remotes)

    -- 3. pontuação
    for _, r in ipairs(remotes) do
        local sc, reasons = Recon.score(r)
        r._nexus_score   = sc
        r._nexus_reasons = reasons
    end
    table.sort(remotes, function(a, b)
        return (a._nexus_score or 0) > (b._nexus_score or 0)
    end)

    -- 4. sondagem opcional (com jitter para não criar padrão de tempo)
    local probes = {}
    if CONFIG.Recon.LiveProbe then
        for _, r in ipairs(remotes) do
            local sc = r._nexus_score or 0
            if sc >= 25 and not matchesAny(r.Name, CONFIG.Stealth.BlockedPatterns) then
                probes[r.Name] = Recon.probeRateLimit(r)
                task.wait(0.05 + math.random() * 0.10)
            end
        end
    end

    -- 5. relatório
    local report = {
        game      = game.Name,
        placeId   = tostring(game.PlaceId),
        jobId     = tostring(game.JobId),
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        counts    = { critical = 0, high = 0, medium = 0, low = 0 },
        remotes   = {},
    }

    for _, r in ipairs(remotes) do
        local path, p = {}, r
        while p and p ~= game do table.insert(path, 1, p.Name); p = p.Parent end

        local sc = r._nexus_score or 0
        if     sc >= 60 then report.counts.critical = report.counts.critical + 1
        elseif sc >= 35 then report.counts.high     = report.counts.high + 1
        elseif sc >= 15 then report.counts.medium   = report.counts.medium + 1
        else                report.counts.low      = report.counts.low + 1 end

        table.insert(report.remotes, {
            name      = r.Name,
            path      = table.concat(path, "."),
            className = r.ClassName,
            score     = sc,
            reasons   = r._nexus_reasons,
            probe     = probes[r.Name],
        })
    end

    if CONFIG.Output.PrintToConsole then Reporter.print(report) end
    Reporter.saveJSON(report)

    -- 6. base gerada
    local base = generateBase(remotes)
    Reporter.saveBase(base)
    print("\n===== BASE GERADA =====\n" .. base .. "\n=======================\n")

    NEXUS.lastReport = report
    NEXUS.lastBase   = base
    return report, base
end

-- expõe a API no ambiente do executor
if type(getgenv) == "function" then
    local env = getgenv()
    if type(env) == "table" then env.NEXUS7 = NEXUS end
end

return NEXUS.activate()
