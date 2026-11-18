--!strict
--[[
    03_Client_MiraParabolica_Beam_e_Animacoes.luau
    Coloque em: StarterPlayer/StarterPlayerScripts/MiraArremesso (LocalScript)

    Funcionalidades implementadas:
    1. Ao segurar o Botão Esquerdo do Mouse (ou toque), desenha um arco parabólico suave com Parts/Beam
    2. Calcula em tempo real se a mira está dentro do Alcance Máximo e se acerta o topo/cabeça (Crítico 1.5x)
    3. Ao soltar o botão, envia o alvo ao Servidor via RemoteEvent
    4. Recebe ThrowResult e executa:
       - Voo em curva de Bézier com Trail luminoso
       - Sucção da criatura para dentro da Orbe
       - Animação tensa de 1 a 3 balançadas com faíscas e inclinação (-28° a +28°)
       - Explosão de vitória (Capturado!) ou quebra da Orbe (+XP de consolação)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("ConfigOrbesCriaturas"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestThrow = Remotes:WaitForChild("RequestThrow") :: RemoteEvent
local ThrowResult = Remotes:WaitForChild("ThrowResult") :: RemoteEvent

-- ============================================================================
-- ARCO VISUAL DE MIRA PARABÓLICA (PONTOS + ALVO NO CHÃO)
-- ============================================================================
local AIM_SEGMENTS = 18
local isAiming = false
local aimFolder = Instance.new("Folder")
aimFolder.Name = "MiraParabolicaVisual"
aimFolder.Parent = Workspace

local arcDots: { Part } = {}
for i = 1, AIM_SEGMENTS do
    local dot = Instance.new("Part")
    dot.Name = "ArcDot_" .. tostring(i)
    dot.Anchored = true
    dot.CanCollide = false
    dot.CanQuery = false
    dot.Material = Enum.Material.Neon
    dot.Shape = Enum.PartType.Ball
    dot.Size = Vector3.new(0.45, 0.45, 0.45)
    dot.Transparency = 1
    dot.Parent = aimFolder
    table.insert(arcDots, dot)
end

local targetRing = Instance.new("Part")
targetRing.Name = "TargetRing"
targetRing.Anchored = true
targetRing.CanCollide = false
targetRing.CanQuery = false
targetRing.Material = Enum.Material.Neon
targetRing.Shape = Enum.PartType.Cylinder
targetRing.Size = Vector3.new(0.18, 4.2, 4.2)
targetRing.CFrame = CFrame.Angles(0, 0, math.rad(90))
targetRing.Transparency = 1
targetRing.Parent = aimFolder

local function hideAimArc()
    for _, dot in ipairs(arcDots) do
        dot.Transparency = 1
    end
    targetRing.Transparency = 1
end

local function bezierQuad(p0: Vector3, p1: Vector3, p2: Vector3, t: number): Vector3
    local u = 1 - t
    return (u * u) * p0 + (2 * u * t) * p1 + (t * t) * p2
end

local function raycastAimTarget(): (Vector3?, Model?, boolean)
    local mouseLoc = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mouseLoc.X, mouseLoc.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local char = LocalPlayer.Character
    params.FilterDescendantsInstances = if char then { char, aimFolder } else { aimFolder }

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 400, params)
    if not result then
        return nil, nil, false
    end

    local hitPart = result.Instance
    local model = hitPart:FindFirstAncestorOfClass("Model")
    local wildFolder = Workspace:FindFirstChild("CriaturasSelvagens")

    if model and wildFolder and model:IsDescendantOf(wildFolder) then
        local isCritHead = (hitPart.Name == "Head") or (result.Position.Y > (model.PrimaryPart and model.PrimaryPart.Position.Y + 1.1 or 999))
        return result.Position, model, isCritHead
    end

    return result.Position, nil, false
end

RunService.RenderStepped:Connect(function()
    if not isAiming then
        hideAimArc()
        return
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not root then
        hideAimArc()
        return
    end

    local hitPos, targetModel, isCrit = raycastAimTarget()
    if not hitPos then
        hideAimArc()
        return
    end

    local startPos = root.Position + Vector3.new(1.2, 2.2, 0)
    local dist = (startPos - hitPos).Magnitude
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    local lvlVal = ls and ls:FindFirstChild("Nivel") :: IntValue?
    local maxRange = Config.GetMaxThrowRange(10, if lvlVal then lvlVal.Value else 1)

    local inRange = dist <= maxRange
    local color = if not inRange then Color3.fromRGB(239, 68, 68)
        elseif targetModel and isCrit then Color3.fromRGB(250, 204, 21) -- Ouro = Crítico 1.5x!
        elseif targetModel then Color3.fromRGB(74, 222, 128) -- Verde = Alvo válido
        else Color3.fromRGB(56, 189, 248) -- Azul = Solo

    local midPos = (startPos + hitPos) * 0.5 + Vector3.new(0, math.clamp(dist * 0.35, 6, 45), 0)

    for i, dot in ipairs(arcDots) do
        local t = i / AIM_SEGMENTS
        dot.Position = bezierQuad(startPos, midPos, hitPos, t)
        dot.Color = color
        dot.Transparency = 0.25
    end

    targetRing.CFrame = CFrame.new(hitPos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
    targetRing.Color = color
    targetRing.Transparency = 0.3
end)

-- ============================================================================
-- INPUT DE ARREMESSO (SEGURAR E SOLTAR)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not isAiming then return end
        isAiming = false
        hideAimArc()

        local hitPos, targetModel, isCrit = raycastAimTarget()
        if hitPos and targetModel then
            RequestThrow:FireServer(targetModel, hitPos, isCrit)
        end
    end
end)

-- ============================================================================
-- ANIMAÇÃO DE VOO DA ORBE + 3 BALANÇADAS DE TENSÃO
-- ============================================================================
local function createVisualOrb(color: Color3, pos: Vector3): Part
    local orb = Instance.new("Part")
    orb.Name = "VisualCaptureOrb"
    orb.Anchored = true
    orb.CanCollide = false
    orb.Shape = Enum.PartType.Ball
    orb.Size = Vector3.new(1.5, 1.5, 1.5)
    orb.Material = Enum.Material.Neon
    orb.Color = color
    orb.Position = pos

    -- Rastro luminoso durante o voo
    local a0 = Instance.new("Attachment", orb)
    a0.Position = Vector3.new(0, 0.4, 0)
    local a1 = Instance.new("Attachment", orb)
    a1.Position = Vector3.new(0, -0.4, 0)

    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
    trail.Lifetime = 0.35
    trail.Parent = orb

    orb.Parent = Workspace
    return orb
end

local function setModelVisibility(model: Model, hidden: boolean)
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Transparency = if hidden then 1 else 0
        elseif desc:IsA("BillboardGui") then
            desc.Enabled = not hidden
        end
    end
end

ThrowResult.OnClientEvent:Connect(function(data)
    local startPos: Vector3 = data.StartPos
    local hitPos: Vector3 = data.HitPos
    local targetModel: Model? = data.TargetModel
    local orbColor: Color3 = data.OrbColor

    local orb = createVisualOrb(orbColor, startPos)
    local dist = (startPos - hitPos).Magnitude
    local midPos = (startPos + hitPos) * 0.5 + Vector3.new(0, math.clamp(dist * 0.35, 6, 45), 0)

    -- 1. Voo da Orbe pela curva de Bézier (~0.45s)
    local flightTime = math.clamp(dist / 140, 0.32, 0.75)
    local elapsed = 0
    while elapsed < flightTime do
        local dt = RunService.Heartbeat:Wait()
        elapsed += dt
        local alpha = math.min(1, elapsed / flightTime)
        orb.CFrame = CFrame.new(bezierQuad(startPos, midPos, hitPos, alpha)) * CFrame.Angles(alpha * 8, alpha * 5, 0)
    end

    -- 2. Absorção da Criatura (esconde criatura temporariamente e cai no chão)
    if targetModel and targetModel.Parent then
        setModelVisibility(targetModel, true)
    end
    local restPos = hitPos + Vector3.new(0, 0.75, 0)
    orb.CFrame = CFrame.new(restPos)

    -- 3. As 3 Balançadas de Tensão (para no exato giro onde falhar)
    local shakesToPlay = if data.Captured then 3 else math.min(3, data.ShakesPassed + 1)
    for s = 1, shakesToPlay do
        task.wait(0.28)
        local leftCF = CFrame.new(restPos) * CFrame.Angles(0, 0, math.rad(28))
        local rightCF = CFrame.new(restPos) * CFrame.Angles(0, 0, math.rad(-28))
        local centerCF = CFrame.new(restPos)

        local t1 = TweenService:Create(orb, TweenInfo.new(0.11, Enum.EasingStyle.Quad), { CFrame = leftCF })
        t1:Play(); t1.Completed:Wait()
        local t2 = TweenService:Create(orb, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { CFrame = rightCF })
        t2:Play(); t2.Completed:Wait()
        local t3 = TweenService:Create(orb, TweenInfo.new(0.11, Enum.EasingStyle.Back), { CFrame = centerCF })
        t3:Play(); t3.Completed:Wait()
    end

    -- 4. Resultado Final (Trava Dourada vs Quebra da Orbe)
    if data.Captured then
        orb.Color = Color3.fromRGB(250, 204, 21)
        orb.Size = Vector3.new(1.9, 1.9, 1.9)
        if data.Thrower == LocalPlayer then
            print(string.format(
                "[CAPTURADO!] +%d/s | Mutação: %s | Tamanho: %s | +%d XP (Nível %d)",
                data.IncomePerSec, data.MutationName, data.SizeName, data.XPGained, data.NewLevel
            ))
        end
        task.wait(0.8)
    else
        orb.Color = Color3.fromRGB(148, 163, 184)
        if targetModel and targetModel.Parent then
            setModelVisibility(targetModel, false)
        end
        if data.Thrower == LocalPlayer then
            print(string.format("[ESCAPOU!] Ganhou +%d XP de consolação e +5%% Pity de Sorte!", data.XPGained))
        end
        task.wait(0.35)
    end

    orb:Destroy()
end)
