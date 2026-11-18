--!strict
--[[
    RobloxStudio_TerrenoXadrez_e_Mutacoes.luau
    Exemplo completo para recriar o estilo visual e mecânico dos jogos:
    - Throw a Seed / Throw Food For Animals / Steal An Egg / +1 Ride Pets to Fight

    Como usar no Roblox Studio:
    1. Cole este script dentro de ServerScriptService (Script comum).
    2. (Opcional) Substitua STUD_TEXTURE_ID pelo Asset ID da sua textura enviada ao Roblox
       (por exemplo, `textura_stud_quadrado_topo_color.png` desta pasta).
    3. Execute com Play/Run para ver:
       - Piso xadrez bicolor com relevo/studs;
       - Árvore Voxel construída por código (Parts + WedgeParts);
       - Animação elástica de germinação (TweenService);
       - Sistema de Mutações (Normal, Gold, Diamond, Emerald, Ruby, Rainbow);
       - BillboardGui com nome e ganho por segundo ($/s).
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- CONFIGURAÇÃO GLOBAL
-- ============================================================================
local CONFIG = {
    GridRows = 8,
    GridCols = 8,
    TileSize = 8, -- 8x8 studs por quadrado do xadrez (4x4 studs por bloco)
    ColorA = Color3.fromHex("#4CD92B"), -- Grama clara
    ColorB = Color3.fromHex("#3FC022"), -- Grama média
    -- Se subir a textura `textura_stud_quadrado_topo_color.png` para o Roblox,
    -- troque o ID abaixo pelo seu rbxassetid://SEU_ID
    StudTextureId = "",
    StudsPerTile = 4,
}

export type MutationName = "Normal" | "Gold" | "Diamond" | "Emerald" | "Ruby" | "Rainbow"

local MUTATIONS: { [MutationName]: { Multiplier: number, Color: Color3, Material: Enum.Material } } = {
    Normal  = { Multiplier = 1,   Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.SmoothPlastic },
    Gold    = { Multiplier = 2,   Color = Color3.fromRGB(255, 204, 21),  Material = Enum.Material.Foil },
    Diamond = { Multiplier = 3,   Color = Color3.fromRGB(56, 189, 248),  Material = Enum.Material.Glass },
    Emerald = { Multiplier = 5,   Color = Color3.fromRGB(34, 197, 94),   Material = Enum.Material.Neon },
    Ruby    = { Multiplier = 10,  Color = Color3.fromRGB(239, 68, 68),   Material = Enum.Material.Neon },
    Rainbow = { Multiplier = 20,  Color = Color3.fromRGB(168, 85, 247),  Material = Enum.Material.SmoothPlastic },
}

-- ============================================================================
-- 1. GERADOR DE TERRENO XADREZ COM STUDS
-- ============================================================================
local function applyClassicStudSurface(part: BasePart)
    -- No Roblox clássico (ou via SurfaceType), TopSurface = Studs cria pinos nativos,
    -- mas jogos modernos costumam aplicar Texture ou MaterialVariant para controle total.
    part.TopSurface = Enum.SurfaceType.Studs
    part.BottomSurface = Enum.SurfaceType.Inlet

    if CONFIG.StudTextureId ~= "" then
        for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
            local tex = Instance.new("Texture")
            tex.Face = face
            tex.Texture = CONFIG.StudTextureId
            tex.StudsPerTileU = CONFIG.StudsPerTile
            tex.StudsPerTileV = CONFIG.StudsPerTile
            tex.Transparency = 0.72
            tex.Parent = part
        end
    end
end

local function createCheckeredGround(origin: Vector3): Folder
    local existing = Workspace:FindFirstChild("DemoTerrenoXadrez")
    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "DemoTerrenoXadrez"
    folder.Parent = Workspace

    for row = 0, CONFIG.GridRows - 1 do
        for col = 0, CONFIG.GridCols - 1 do
            local tile = Instance.new("Part")
            tile.Name = string.format("Tile_%d_%d", row, col)
            tile.Anchored = true
            tile.Size = Vector3.new(CONFIG.TileSize, 2, CONFIG.TileSize)
            tile.Position = origin + Vector3.new(
                (col - CONFIG.GridCols / 2) * CONFIG.TileSize,
                -1,
                (row - CONFIG.GridRows / 2) * CONFIG.TileSize
            )
            tile.Material = Enum.Material.SmoothPlastic
            tile.Color = if (row + col) % 2 == 0 then CONFIG.ColorA else CONFIG.ColorB
            applyClassicStudSurface(tile)
            tile.Parent = folder
        end
    end

    return folder
end

-- ============================================================================
-- 2. CONSTRUTOR DE ÁRVORE VOXEL MODULAR (ESTILO THROW A SEED)
-- ============================================================================
local function createVoxelTree(name: string, basePos: Vector3, scaleFactor: number): Model
    local model = Instance.new("Model")
    model.Name = name

    -- Base branca estilo "Inlet" vista nos pinheiros reais
    local rootBase = Instance.new("Part")
    rootBase.Name = "RootBase"
    rootBase.Anchored = true
    rootBase.Size = Vector3.new(4, 0.8, 4)
    rootBase.Color = Color3.fromRGB(226, 232, 240)
    rootBase.Position = basePos + Vector3.new(0, 0.4, 0)
    rootBase.TopSurface = Enum.SurfaceType.Studs
    rootBase.BottomSurface = Enum.SurfaceType.Inlet
    rootBase.Parent = model

    -- Tronco segmentado com leve inclinação
    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Anchored = true
    trunk.Size = Vector3.new(1.8, 5, 1.8)
    trunk.Color = Color3.fromRGB(120, 72, 42)
    trunk.CFrame = CFrame.new(basePos + Vector3.new(0, 2.9, 0))
    trunk.TopSurface = Enum.SurfaceType.Studs
    trunk.Parent = model

    -- 3 Camadas empilhadas de copa em blocos + frutas douradas
    local canopyLayers = {
        { y = 5.6, size = Vector3.new(5.5, 1.8, 5.5), color = Color3.fromRGB(34, 197, 94) },
        { y = 7.2, size = Vector3.new(4.2, 1.6, 4.2), color = Color3.fromRGB(46, 213, 115) },
        { y = 8.6, size = Vector3.new(2.6, 1.4, 2.6), color = Color3.fromRGB(74, 222, 128) },
    }

    for idx, layer in ipairs(canopyLayers) do
        local block = Instance.new("Part")
        block.Name = "Canopy_" .. tostring(idx)
        block.Anchored = true
        block.Size = layer.size
        block.Color = layer.color
        block.CFrame = CFrame.new(basePos + Vector3.new(0, layer.y, 0))
            * CFrame.Angles(0, math.rad(idx * 12), 0)
        block.TopSurface = Enum.SurfaceType.Studs
        block.Parent = model
    end

    -- Frutas cúbicas estilizadas (como na Golden Apple Tree)
    local fruitOffsets = {
        Vector3.new(2.4, 4.8, 1.5),
        Vector3.new(-2.2, 5.2, -1.6),
        Vector3.new(1.6, 6.8, -2.0),
    }
    for i, off in ipairs(fruitOffsets) do
        local fruit = Instance.new("Part")
        fruit.Name = "Fruit_" .. tostring(i)
        fruit.Anchored = true
        fruit.Size = Vector3.new(1.1, 1.1, 1.1)
        fruit.Color = Color3.fromRGB(250, 204, 21)
        fruit.Material = Enum.Material.SmoothPlastic
        fruit.Position = basePos + off
        fruit.TopSurface = Enum.SurfaceType.Studs
        fruit.Parent = model
    end

    model.PrimaryPart = rootBase
    model.Parent = Workspace
    model:ScaleTo(scaleFactor)
    return model
end

-- ============================================================================
-- 3. APLICAÇÃO DE MUTAÇÃO + HIGHLIGHT + BILLBOARDGUI ($/S)
-- ============================================================================
local function applyMutationAndBillboard(model: Model, plantTitle: string, baseIncome: number, mutationName: MutationName)
    local mut = MUTATIONS[mutationName]
    local finalIncome = math.floor(baseIncome * mut.Multiplier)

    if mutationName ~= "Normal" then
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") and desc.Name ~= "RootBase" then
                desc.Material = mut.Material
                if mutationName ~= "Rainbow" then
                    desc.Color = desc.Color:Lerp(mut.Color, 0.7)
                end
            end
        end

        -- Contorno brilhante estilo jogo incremental do Roblox
        local highlight = Instance.new("Highlight")
        highlight.FillTransparency = 0.78
        highlight.OutlineTransparency = 0.1
        highlight.FillColor = mut.Color
        highlight.OutlineColor = mut.Color
        highlight.Parent = model

        if mutationName == "Rainbow" then
            task.spawn(function()
                local hue = 0
                while model.Parent do
                    hue = (hue + 0.006) % 1
                    local c = Color3.fromHSV(hue, 0.85, 1)
                    highlight.FillColor = c
                    highlight.OutlineColor = c
                    for _, desc in ipairs(model:GetDescendants()) do
                        if desc:IsA("BasePart") and desc.Name ~= "RootBase" then
                            desc.Color = c
                        end
                    end
                    RunService.Heartbeat:Wait()
                end
            end)
        end
    end

    -- BillboardGui flutuante idêntico ao padrão ($/s)
    local anchor = model.PrimaryPart
    if anchor then
        local gui = Instance.new("BillboardGui")
        gui.Name = "IncomeTag"
        gui.Size = UDim2.fromOffset(190, 62)
        gui.StudsOffset = Vector3.new(0, 11, 0)
        gui.AlwaysOnTop = true
        gui.Parent = anchor

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 0.55)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.FredokaOne
        label.TextScaled = true
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Text = if mutationName == "Normal" then plantTitle else string.format("[%s] %s", mutationName, plantTitle)
        label.Parent = gui

        local stroke1 = Instance.new("UIStroke")
        stroke1.Thickness = 2.5
        stroke1.Color = Color3.new(0, 0, 0)
        stroke1.Parent = label

        local cash = Instance.new("TextLabel")
        cash.Position = UDim2.fromScale(0, 0.52)
        cash.Size = UDim2.fromScale(1, 0.48)
        cash.BackgroundTransparency = 1
        cash.Font = Enum.Font.FredokaOne
        cash.TextScaled = true
        cash.TextColor3 = Color3.fromRGB(74, 222, 128)
        cash.Text = string.format("$%d/s", finalIncome)
        cash.Parent = gui

        local stroke2 = Instance.new("UIStroke")
        stroke2.Thickness = 2.5
        stroke2.Color = Color3.new(0, 0, 0)
        stroke2.Parent = cash
    end
end

-- ============================================================================
-- 4. ANIMAÇÃO ELÁSTICA DE BROTAMENTO (SPROUT TWEEN)
-- ============================================================================
local function playSproutAnimation(model: Model, targetScale: number)
    model:ScaleTo(0.05)
    local numValue = Instance.new("NumberValue")
    numValue.Value = 0.05

    local conn = numValue:GetPropertyChangedSignal("Value"):Connect(function()
        if model.Parent then
            model:ScaleTo(numValue.Value)
        end
    end)

    local tween = TweenService:Create(
        numValue,
        TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Value = targetScale }
    )
    tween:Play()
    tween.Completed:Connect(function()
        conn:Disconnect()
        numValue:Destroy()
    end)
end

-- ============================================================================
-- DEMONSTRAÇÃO NA CENA
-- ============================================================================
createCheckeredGround(Vector3.new(0, 0, 0))

local t1 = createVoxelTree("Demo_AppleTree_Normal", Vector3.new(-14, 0, 0), 1.0)
applyMutationAndBillboard(t1, "Golden Apple Tree", 120, "Normal")
playSproutAnimation(t1, 1.0)

local t2 = createVoxelTree("Demo_AppleTree_Gold", Vector3.new(0, 0, 0), 1.25)
applyMutationAndBillboard(t2, "Golden Apple Tree", 120, "Gold")
playSproutAnimation(t2, 1.25)

local t3 = createVoxelTree("Demo_AppleTree_Rainbow", Vector3.new(16, 0, 0), 1.55)
applyMutationAndBillboard(t3, "Celestial Tree", 500, "Rainbow")
playSproutAnimation(t3, 1.55)
