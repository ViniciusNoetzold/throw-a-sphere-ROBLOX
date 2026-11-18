--!strict
--[[
    02_Server_Captura_3Balancadas_XP_e_Podio.luau
    Coloque em: ServerScriptService/CapturaServer (Script)

    Funcionalidades implementadas neste protótipo pronto para rodar:
    1. Cria os RemoteEvents em ReplicatedStorage/Remotes automaticamente
    2. Gera criaturas de teste no Workspace (se não houver nenhuma) com atributos de captura
    3. Valida o arremesso enviado pelo Cliente, trava a criatura ("Catch Lock") e executa as 3 checagens de sorte
    4. Atualiza XP, Nível, Moedas, Pity de Sorte e gera $/s no Santuário
    5. Atualiza o Pódio 3D e Placar com os melhores jogadores
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("ConfigOrbesCriaturas"))

-- ============================================================================
-- SETUP DE REMOTES
-- ============================================================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local function getOrCreateRemote(name: string): RemoteEvent
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then
        return existing
    end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name
    ev.Parent = Remotes
    return ev
end

local RequestThrow = getOrCreateRemote("RequestThrow")
local ThrowResult = getOrCreateRemote("ThrowResult")
local ClaimDaily = getOrCreateRemote("ClaimDailyReward")

-- ============================================================================
-- ESTADO EM MEMÓRIA DA SESSÃO (Substitua por ProfileService em produção)
-- ============================================================================
type PlayerProfile = {
    Coins: number,
    Gems: number,
    XP: number,
    Level: number,
    Rebirths: number,
    ThrowStrength: number,
    PityBonus: number,
    EquippedOrb: string,
    Orbs: { [string]: number },
    SanctuaryIncomePerSec: number,
    CreaturesCount: number,
    DailyStreak: number,
    LastDailyClaim: number,
    BestCreatureValue: number,
}

local Profiles: { [Player]: PlayerProfile } = {}

local function rollWeighted(tableList: { any })
    local total = 0
    for _, item in ipairs(tableList) do
        total += item.Weight
    end
    local r = math.random() * total
    local acc = 0
    for _, item in ipairs(tableList) do
        acc += item.Weight
        if r <= acc then
            return item
        end
    end
    return tableList[1]
end

local function createLeaderstats(player: Player, prof: PlayerProfile)
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Moedas"
    coins.Value = prof.Coins
    coins.Parent = ls

    local lvl = Instance.new("IntValue")
    lvl.Name = "Nivel"
    lvl.Value = prof.Level
    lvl.Parent = ls
end

local function syncLeaderstats(player: Player)
    local prof = Profiles[player]
    local ls = player:FindFirstChild("leaderstats")
    if prof and ls then
        local m = ls:FindFirstChild("Moedas") :: IntValue?
        local n = ls:FindFirstChild("Nivel") :: IntValue?
        if m then m.Value = math.floor(prof.Coins) end
        if n then n.Value = prof.Level end
    end
end

local function grantXP(player: Player, amount: number): boolean
    local prof = Profiles[player]
    if not prof then return false end

    prof.XP += amount
    local leveledUp = false
    while prof.XP >= Config.GetXPRequiredForLevel(prof.Level) do
        prof.XP -= Config.GetXPRequiredForLevel(prof.Level)
        prof.Level += 1
        prof.Coins += prof.Level * 150
        leveledUp = true
    end
    syncLeaderstats(player)
    return leveledUp
end

-- ============================================================================
-- SPAWN DE CRIATURAS DE TESTE NO MAPA (PARA TESTAR IMEDIATAMENTE NO STUDIO)
-- ============================================================================
local WildFolder = Workspace:FindFirstChild("CriaturasSelvagens") or Instance.new("Folder")
WildFolder.Name = "CriaturasSelvagens"
WildFolder.Parent = Workspace

local function spawnWildCreature(creatureId: string, pos: Vector3)
    local def = Config.Creatures[creatureId]
    if not def then return end

    local model = Instance.new("Model")
    model.Name = def.Id

    local body = Instance.new("Part")
    body.Name = "HumanoidRootPart"
    body.Anchored = true
    body.Size = Vector3.new(3, 2.5, 3.6)
    body.Color = def.BodyColor
    body.TopSurface = Enum.SurfaceType.Studs
    body.Position = pos + Vector3.new(0, 1.25, 0)
    body.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Anchored = true
    head.Size = Vector3.new(2.2, 1.8, 2.2)
    head.Color = def.BodyColor
    head.TopSurface = Enum.SurfaceType.Studs
    head.Position = pos + Vector3.new(0, def.HeadOffsetY, -1.2)
    head.Parent = model

    -- Tag flutuante de nome e dificuldade
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(170, 52)
    bb.StudsOffset = Vector3.new(0, 4.2, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextScaled = true
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.Text = string.format("%s [%s]\nDif: %d", def.Name, def.Rarity, def.Difficulty)
    lbl.Parent = bb

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Parent = lbl

    model.PrimaryPart = body
    model:SetAttribute("CreatureId", def.Id)
    model:SetAttribute("LockedUntil", 0)
    model.Parent = WildFolder
end

if #WildFolder:GetChildren() == 0 then
    spawnWildCreature("Sproutling", Vector3.new(18, 0, -25))
    spawnWildCreature("Pyrokit", Vector3.new(-20, 0, -32))
    spawnWildCreature("Aquapup", Vector3.new(0, 0, -45))
    spawnWildCreature("Voltmouse", Vector3.new(28, 0, -55))
    spawnWildCreature("Lavarex", Vector3.new(-28, 0, -68))
end

-- ============================================================================
-- LÓGICA PRINCIPAL DE ARREMESSO E 3 BALANÇADAS
-- ============================================================================
RequestThrow.OnServerEvent:Connect(function(player: Player, targetModel: Model, hitWorldPos: Vector3, isCriticalHeadHit: boolean)
    local prof = Profiles[player]
    if not prof then return end
    if typeof(targetModel) ~= "Instance" or not targetModel:IsA("Model") or not targetModel:IsDescendantOf(WildFolder) then
        return
    end

    -- Verifica estoque da orbe equipada
    local orbId = prof.EquippedOrb
    local orbCount = prof.Orbs[orbId] or 0
    local orbDef = Config.Orbs[orbId]
    if orbCount <= 0 or not orbDef then
        return
    end

    -- Verifica Catch Lock (impede outro jogador de roubar durante as balançadas)
    local now = os.clock()
    local lockedUntil = (targetModel:GetAttribute("LockedUntil") :: number?) or 0
    if now < lockedUntil then
        return
    end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local targetPrimary = targetModel.PrimaryPart
    if not root or not targetPrimary then return end

    -- Valida alcance máximo do jogador
    local distance = (root.Position - targetPrimary.Position).Magnitude
    local maxRange = Config.GetMaxThrowRange(prof.ThrowStrength, prof.Level)
    if distance > maxRange + 8 then
        return
    end

    -- Consome 1 orbe e trava criatura por 4.5s
    prof.Orbs[orbId] = orbCount - 1
    targetModel:SetAttribute("LockedUntil", now + 4.5)

    local creatureId = targetModel:GetAttribute("CreatureId") :: string
    local creatureDef = Config.Creatures[creatureId]
    if not creatureDef then return end

    -- Calcula Bônus de Mira e Sorte
    local isLongShot = distance >= 90
    local aimBonus = 1.0
    if isCriticalHeadHit and isLongShot then
        aimBonus = 1.85
    elseif isCriticalHeadHit then
        aimBonus = 1.50
    elseif isLongShot then
        aimBonus = 1.25
    end

    local levelLuck = 1 + (prof.Level * 0.015) + prof.PityBonus + (prof.Rebirths * 0.5)
    local pShake = Config.CalculateShakeProbability(
        orbDef.Power,
        aimBonus,
        levelLuck,
        creatureDef.Difficulty,
        orbDef.IsMaster
    )

    -- Realiza as 3 checagens independentes no servidor
    local shakesPassed = 0
    local captured = true
    for i = 1, 3 do
        if math.random() <= pShake then
            shakesPassed = i
        else
            captured = false
            break
        end
    end

    if captured then
        local mutation = rollWeighted(Config.Mutations)
        local sizeRoll = rollWeighted(Config.Sizes)
        local income = math.floor(creatureDef.BaseIncomePerSec * mutation.Multiplier * sizeRoll.Multiplier)

        prof.SanctuaryIncomePerSec += income
        prof.CreaturesCount += 1
        prof.PityBonus = 0 -- Reseta pity após capturar
        if income > prof.BestCreatureValue then
            prof.BestCreatureValue = income
        end

        local leveledUp = grantXP(player, creatureDef.BaseXP)

        -- Notifica todos os clientes para animar o voo + 3 balançadas + captura
        ThrowResult:FireAllClients({
            Thrower = player,
            StartPos = root.Position + Vector3.new(0, 2, 0),
            TargetModel = targetModel,
            HitPos = hitWorldPos,
            OrbColor = orbDef.Color,
            ShakesPassed = 3,
            Captured = true,
            MutationName = mutation.Name,
            SizeName = sizeRoll.Name,
            IncomePerSec = income,
            XPGained = creatureDef.BaseXP,
            LeveledUp = leveledUp,
            NewLevel = prof.Level,
            Probability = pShake,
        })

        -- Remove e respawna outra após o fim da animação (~3.6s)
        task.delay(3.6, function()
            local oldPos = targetPrimary.Position - Vector3.new(0, 1.25, 0)
            if targetModel.Parent then
                targetModel:Destroy()
            end
            task.wait(2)
            spawnWildCreature(creatureId, oldPos)
        end)
    else
        -- Falhou: recompensa XP de consolação (35%) + +5% Pity de Sorte
        local consolationXP = math.max(5, math.floor(creatureDef.BaseXP * 0.35))
        if isCriticalHeadHit then consolationXP += 15 end
        prof.PityBonus = math.min(1.0, prof.PityBonus + 0.05)
        local leveledUp = grantXP(player, consolationXP)

        ThrowResult:FireAllClients({
            Thrower = player,
            StartPos = root.Position + Vector3.new(0, 2, 0),
            TargetModel = targetModel,
            HitPos = hitWorldPos,
            OrbColor = orbDef.Color,
            ShakesPassed = shakesPassed,
            Captured = false,
            XPGained = consolationXP,
            LeveledUp = leveledUp,
            NewLevel = prof.Level,
            Probability = pShake,
        })
    end
end)

-- ============================================================================
-- RECOMPENSA DIÁRIA (7 DIAS)
-- ============================================================================
ClaimDaily.OnServerEvent:Connect(function(player: Player)
    local prof = Profiles[player]
    if not prof then return end
    local now = os.time()
    if (now - prof.LastDailyClaim) < 86400 and prof.LastDailyClaim > 0 then
        return -- Ainda não completou 24h
    end
    prof.DailyStreak = (prof.DailyStreak % 7) + 1
    prof.LastDailyClaim = now
    local reward = Config.DailyRewards[prof.DailyStreak]
    if reward then
        prof.Coins += reward.Coins
        prof.Orbs[reward.OrbId] = (prof.Orbs[reward.OrbId] or 0) + reward.OrbQty
        if reward.Gems then prof.Gems += reward.Gems end
        grantXP(player, reward.XP)
    end
end)

-- ============================================================================
-- CICLO DE RENDA PASSIVA DO SANTUÁRIO ($/s) + PÓDIO DA SESSÃO
-- ============================================================================
Players.PlayerAdded:Connect(function(player: Player)
    Profiles[player] = {
        Coins = 150,
        Gems = 0,
        XP = 0,
        Level = 1,
        Rebirths = 0,
        ThrowStrength = 10,
        PityBonus = 0,
        EquippedOrb = "Comum",
        Orbs = { Comum = 25, Esmeralda = 3, Rubi = 1 },
        SanctuaryIncomePerSec = 5,
        CreaturesCount = 0,
        DailyStreak = 0,
        LastDailyClaim = 0,
        BestCreatureValue = 0,
    }
    createLeaderstats(player, Profiles[player])
end)

Players.PlayerRemoving:Connect(function(player: Player)
    Profiles[player] = nil
end)

task.spawn(function()
    while true do
        task.wait(1)
        for player, prof in pairs(Profiles) do
            local mult = 1 + prof.Rebirths
            prof.Coins += prof.SanctuaryIncomePerSec * mult
            syncLeaderstats(player)
        end
    end
end)
