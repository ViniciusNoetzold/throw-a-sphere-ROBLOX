--!strict
--[[
    04_Client_UI_Completa_BigNumbers_e_LojaRobux.luau
    Coloque em: StarterPlayer/StarterPlayerScripts/UIController (LocalScript)

    Constrói automaticamente TODA a Interface do Jogo no estilo simulador viral do Roblox:
    - Formatador de Big Numbers até Ocd (K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc... Ocd)
    - Chuva de números flutuantes elásticos na tela (+Moedas, +Força, +XP, Crítico 1.5x, 1 in 1M)
    - HUD Completa: Eventos/Combo Fever no topo, botões laterais esquerda/direita,
      painel inferior de Big Numbers + XP, Hotbar central da Orbe e Loja Robux completa!
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- 1. FORMATADOR DE BIG NUMBERS (IGUAL AOS SIMULADORES DE SUCESSO)
-- ============================================================================
local SUFFIXES = {
    "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
    "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd"
}

local function FormatBigNumber(n: number): string
    if n < 1000 then
        return tostring(math.floor(n))
    end
    local tier = math.floor(math.log10(n) / 3)
    local suffix = SUFFIXES[tier + 1] or ("e" .. tostring(tier * 3))
    local scale = 10 ^ (tier * 3)
    local scaled = n / scale
    if scaled >= 100 then
        return string.format("%.0f%s", scaled, suffix)
    elseif scaled >= 10 then
        return string.format("%.1f%s", scaled, suffix)
    else
        return string.format("%.2f%s", scaled, suffix)
    end
end

-- ============================================================================
-- 2. CATÁLOGO DE MONETIZAÇÃO (SUBSTITUA PELOS SEUS GAMEPASS / PRODUCT IDs)
-- ============================================================================
local GAMEPASSES = {
    { Name = "Starter Pack",        Price = 49,   Desc = "Épico Dourado + 10x Rubi + 2x Sorte",   Color = Color3.fromRGB(34, 197, 94),   Id = 0, Badge = "INICIANTE" },
    { Name = "Braços de Titã 2x",   Price = 149,  Desc = "2x Força no treino + 35% Alcance",      Color = Color3.fromRGB(249, 115, 22),  Id = 0 },
    { Name = "Auto-Arremesso AFK",  Price = 179,  Desc = "Mira e arremessa sozinho sem parar",    Color = Color3.fromRGB(56, 189, 248),  Id = 0 },
    { Name = "2x Moedas ($/s)",     Price = 199,  Desc = "Dobra toda a renda do Santuário",       Color = Color3.fromRGB(250, 204, 21),  Id = 0 },
    { Name = "2x Sorte Permanente", Price = 249,  Desc = "Dobra chance de captura e mutações",    Color = Color3.fromRGB(74, 222, 128),  Id = 0, Badge = "POPULAR" },
    { Name = "Santuário +8 Slots",  Price = 299,  Desc = "+8 espaços para sinergias na base",     Color = Color3.fromRGB(168, 85, 247),  Id = 0 },
    { Name = "VIP Dourado",         Price = 399,  Desc = "Tag [VIP], +25% Moedas, +25% XP, Baú",    Color = Color3.fromRGB(234, 179, 8),   Id = 0 },
    { Name = "Arremesso Triplo",    Price = 599,  Desc = "Lança 3 Orbes em leque de uma vez",     Color = Color3.fromRGB(239, 68, 68),   Id = 0 },
    { Name = "Orbe Prismática 10x", Price = 799,  Desc = "Orbe infinita com 10x de Sorte!",       Color = Color3.fromRGB(244, 114, 182), Id = 0, Badge = "MELHOR" },
    { Name = "Mega Coletor + Fusão",Price = 1199, Desc = "Coleta e funde comuns automaticamente",  Color = Color3.fromRGB(139, 92, 246),  Id = 0 },
}

-- ============================================================================
-- 3. FUNÇÕES AUXILIARES DE ESTILO ROBLOX SIMULADOR
-- ============================================================================
local function addStroke(parent: GuiObject, thickness: number?, color: Color3?)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 2.6
    s.Color = color or Color3.new(0, 0, 0)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function addTextStroke(label: TextLabel | TextButton, thickness: number?)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 2.4
    s.Color = Color3.new(0, 0, 0)
    s.Parent = label
    return s
end

local function addCorner(parent: GuiObject, radius: number?)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function addBounceAnimation(btn: GuiButton)
    local origSize = btn.Size
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
            Size = UDim2.new(origSize.X.Scale * 1.06, origSize.X.Offset + 4, origSize.Y.Scale * 1.06, origSize.Y.Offset + 4)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Size = origSize }):Play()
    end)
end

-- ============================================================================
-- 4. CONSTRUÇÃO DA SCREENGUI PRINCIPAL
-- ============================================================================
local oldGui = PlayerGui:FindFirstChild("JogueUmaOrbeHUD")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "JogueUmaOrbeHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = PlayerGui

-- TOPO: Banner de Evento + Combo Fever
local topFrame = Instance.new("Frame")
topFrame.AnchorPoint = Vector2.new(0.5, 0)
topFrame.Position = UDim2.new(0.5, 0, 0, 10)
topFrame.Size = UDim2.fromOffset(440, 68)
topFrame.BackgroundTransparency = 1
topFrame.Parent = screenGui

local eventPill = Instance.new("Frame")
eventPill.Size = UDim2.new(1, 0, 0, 36)
eventPill.BackgroundColor3 = Color3.fromRGB(30, 27, 75)
eventPill.Parent = topFrame
addCorner(eventPill, 18)
addStroke(eventPill, 2.5, Color3.fromRGB(250, 204, 21))

local eventLabel = Instance.new("TextLabel")
eventLabel.Size = UDim2.fromScale(1, 1)
eventLabel.BackgroundTransparency = 1
eventLabel.Font = Enum.Font.FredokaOne
eventLabel.TextScaled = true
eventLabel.TextColor3 = Color3.fromRGB(254, 240, 138)
eventLabel.Text = "☄️ CHUVA DE METEOROS • 5x SORTE • 03:42"
eventLabel.Parent = eventPill
addTextStroke(eventLabel, 2)

local comboPill = Instance.new("Frame")
comboPill.AnchorPoint = Vector2.new(0.5, 0)
comboPill.Position = UDim2.new(0.5, 0, 0, 42)
comboPill.Size = UDim2.fromOffset(290, 26)
comboPill.BackgroundColor3 = Color3.fromRGB(153, 27, 27)
comboPill.Parent = topFrame
addCorner(comboPill, 13)
addStroke(comboPill, 2, Color3.fromRGB(249, 115, 22))

local comboLabel = Instance.new("TextLabel")
comboLabel.Size = UDim2.fromScale(1, 1)
comboLabel.BackgroundTransparency = 1
comboLabel.Font = Enum.Font.FredokaOne
comboLabel.TextScaled = true
comboLabel.TextColor3 = Color3.new(1, 1, 1)
comboLabel.Text = "🔥 COMBO FEVER x5 (+50% SORTE)"
comboLabel.Parent = comboPill
addTextStroke(comboLabel, 2)

-- FUNÇÃO PARA CRIAR BOTÕES LATERAIS ESTILIZADOS
local function createSideButton(parent: Instance, text: string, bg: Color3, hasAlert: boolean?): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(82, 82)
    btn.BackgroundColor3 = bg
    btn.Font = Enum.Font.FredokaOne
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextScaled = true
    btn.TextWrapped = true
    btn.Parent = parent
    addCorner(btn, 16)
    addStroke(btn, 3)
    addTextStroke(btn, 2.2)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.Parent = btn

    if hasAlert then
        local dot = Instance.new("TextLabel")
        dot.Size = UDim2.fromOffset(24, 24)
        dot.Position = UDim2.new(1, -18, 0, -6)
        dot.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
        dot.Font = Enum.Font.FredokaOne
        dot.Text = "!"
        dot.TextColor3 = Color3.new(1, 1, 1)
        dot.TextScaled = true
        dot.Parent = btn
        addCorner(dot, 12)
        addStroke(dot, 2)
    end

    addBounceAnimation(btn)
    return btn
end

-- LATERAL ESQUERDA (Grid 2 colunas)
local leftGridFrame = Instance.new("Frame")
leftGridFrame.AnchorPoint = Vector2.new(0, 0.5)
leftGridFrame.Position = UDim2.new(0, 14, 0.44, 0)
leftGridFrame.Size = UDim2.fromOffset(178, 270)
leftGridFrame.BackgroundTransparency = 1
leftGridFrame.Parent = screenGui

local leftGrid = Instance.new("UIGridLayout")
leftGrid.CellSize = UDim2.fromOffset(82, 82)
leftGrid.CellPadding = UDim2.fromOffset(10, 10)
leftGrid.Parent = leftGridFrame

local btnIndex = createSideButton(leftGridFrame, "📖\nIndex", Color3.fromRGB(37, 99, 235), false)
local btnShop = createSideButton(leftGridFrame, "🛒\nShop!", Color3.fromRGB(225, 29, 72), true)
local btnFuse = createSideButton(leftGridFrame, "🧬\nFusão", Color3.fromRGB(147, 51, 234), false)
local btnDaily = createSideButton(leftGridFrame, "🎁\nDiário", Color3.fromRGB(234, 179, 8), true)
local btnRebirth = createSideButton(leftGridFrame, "🔄\nRebirth", Color3.fromRGB(16, 185, 129), false)
local btnRank = createSideButton(leftGridFrame, "🏆\nPlacar", Color3.fromRGB(249, 115, 22), false)

-- LATERAL DIREITA
local rightGridFrame = Instance.new("Frame")
rightGridFrame.AnchorPoint = Vector2.new(1, 0.5)
rightGridFrame.Position = UDim2.new(1, -14, 0.48, 0)
rightGridFrame.Size = UDim2.fromOffset(88, 360)
rightGridFrame.BackgroundTransparency = 1
rightGridFrame.Parent = screenGui

local rightList = Instance.new("UIListLayout")
rightList.Padding = UDim.new(0, 10)
rightList.Parent = rightGridFrame

local btnPets = createSideButton(rightGridFrame, "🐾\nCriaturas", Color3.fromRGB(34, 197, 94), false)
local btnOrbs = createSideButton(rightGridFrame, "🔮\nOrbes", Color3.fromRGB(14, 165, 233), false)
local btnAuto = createSideButton(rightGridFrame, "⚡\nAuto 🔒", Color3.fromRGB(245, 158, 11), false)
local btnCodes = createSideButton(rightGridFrame, "🎟️\nCodes", Color3.fromRGB(99, 102, 241), false)

-- CANTO INFERIOR ESQUERDO: BIG NUMBERS + XP BAR
local statsPanel = Instance.new("Frame")
statsPanel.AnchorPoint = Vector2.new(0, 1)
statsPanel.Position = UDim2.new(0, 14, 1, -14)
statsPanel.Size = UDim2.fromOffset(300, 156)
statsPanel.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
statsPanel.BackgroundTransparency = 0.15
statsPanel.Parent = screenGui
addCorner(statsPanel, 16)
addStroke(statsPanel, 2.8, Color3.fromRGB(56, 189, 248))

local function makeStatRow(y: number, color: Color3, initialText: string): TextLabel
    local lbl = Instance.new("TextLabel")
    lbl.Position = UDim2.fromOffset(14, y)
    lbl.Size = UDim2.new(1, -28, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.FredokaOne
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.TextColor3 = color
    lbl.Text = initialText
    lbl.Parent = statsPanel
    addTextStroke(lbl, 2.2)
    return lbl
end

local lblStrength = makeStatRow(8, Color3.fromRGB(251, 146, 60), "💪 Força: 10 (45 studs)")
local lblCoins    = makeStatRow(40, Color3.fromRGB(74, 222, 128), "💰 $150 (+5/s)")
local lblGems     = makeStatRow(72, Color3.fromRGB(192, 132, 252), "💎 Gemas: 0 | 🔄 Rebirth: 0")

-- Barra de Nível / XP
local xpBg = Instance.new("Frame")
xpBg.Position = UDim2.fromOffset(14, 112)
xpBg.Size = UDim2.new(1, -28, 0, 30)
xpBg.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
xpBg.Parent = statsPanel
addCorner(xpBg, 10)
addStroke(xpBg, 2)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.fromScale(0.35, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
xpFill.Parent = xpBg
addCorner(xpFill, 10)

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.fromScale(1, 1)
xpText.BackgroundTransparency = 1
xpText.Font = Enum.Font.FredokaOne
xpText.TextScaled = true
xpText.TextColor3 = Color3.new(1, 1, 1)
xpText.Text = "NV. 1  •  35 / 100 XP (+1.5% Sorte)"
xpText.Parent = xpBg
addTextStroke(xpText, 2)

-- CENTRO INFERIOR: HOTBAR DA ORBE EQUIPADA + BOTÃO DE EMERGÊNCIA
local hotbar = Instance.new("Frame")
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -14)
hotbar.Size = UDim2.fromOffset(410, 74)
hotbar.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
hotbar.BackgroundTransparency = 0.12
hotbar.Parent = screenGui
addCorner(hotbar, 18)
addStroke(hotbar, 2.8, Color3.fromRGB(250, 204, 21))

local orbEquippedLabel = Instance.new("TextLabel")
orbEquippedLabel.Position = UDim2.fromOffset(14, 8)
orbEquippedLabel.Size = UDim2.fromOffset(220, 58)
orbEquippedLabel.BackgroundTransparency = 1
orbEquippedLabel.Font = Enum.Font.FredokaOne
orbEquippedLabel.TextScaled = true
orbEquippedLabel.TextXAlignment = Enum.TextXAlignment.Left
orbEquippedLabel.TextColor3 = Color3.fromRGB(125, 211, 252)
orbEquippedLabel.Text = "🔮 Orbe Comum\nEstoque: x25 (Poder 10)"
orbEquippedLabel.Parent = hotbar
addTextStroke(orbEquippedLabel, 2)

local btnMasterUrgent = Instance.new("TextButton")
btnMasterUrgent.Position = UDim2.fromOffset(244, 12)
btnMasterUrgent.Size = UDim2.fromOffset(154, 50)
btnMasterUrgent.BackgroundColor3 = Color3.fromRGB(236, 72, 153)
btnMasterUrgent.Font = Enum.Font.FredokaOne
btnMasterUrgent.TextScaled = true
btnMasterUrgent.TextColor3 = Color3.new(1, 1, 1)
btnMasterUrgent.Text = "★ ORBE MESTRE\n79 Robux (100%)"
btnMasterUrgent.Parent = hotbar
addCorner(btnMasterUrgent, 12)
addStroke(btnMasterUrgent, 2.5)
addTextStroke(btnMasterUrgent, 2)
addBounceAnimation(btnMasterUrgent)

-- ============================================================================
-- 5. MOTOR DE CHUVA DE NÚMEROS FLUTUANTES NA TELA (POPUPS)
-- ============================================================================
local function SpawnFloatingNumber(text: string, color: Color3, scaleMult: number?)
    local mult = scaleMult or 1.0
    local popup = Instance.new("TextLabel")
    popup.AnchorPoint = Vector2.new(0.5, 0.5)
    popup.Position = UDim2.new(0.5 + (math.random(-14, 14) / 100), 0, 0.48 + (math.random(-6, 6) / 100), 0)
    popup.Size = UDim2.fromOffset(math.floor(240 * mult), math.floor(48 * mult))
    popup.BackgroundTransparency = 1
    popup.Font = Enum.Font.FredokaOne
    popup.TextScaled = true
    popup.TextColor3 = color
    popup.Text = text
    popup.ZIndex = 20
    popup.Parent = screenGui
    addTextStroke(popup, 3)

    local targetPos = popup.Position + UDim2.new(0, 0, -0.14, 0)
    local tMove = TweenService:Create(popup, TweenInfo.new(1.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = targetPos,
        TextTransparency = 1,
    })
    tMove:Play()
    tMove.Completed:Connect(function()
        popup:Destroy()
    end)
end

-- ============================================================================
-- 6. MODAL DA LOJA DE ROBUX (GAMEPASSES)
-- ============================================================================
local shopModal = Instance.new("Frame")
shopModal.AnchorPoint = Vector2.new(0.5, 0.5)
shopModal.Position = UDim2.fromScale(0.5, 0.5)
shopModal.Size = UDim2.fromOffset(720, 480)
shopModal.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
shopModal.Visible = false
shopModal.ZIndex = 30
shopModal.Parent = screenGui
addCorner(shopModal, 20)
addStroke(shopModal, 3.5, Color3.fromRGB(250, 204, 21))

local shopHeader = Instance.new("TextLabel")
shopHeader.Position = UDim2.fromOffset(20, 12)
shopHeader.Size = UDim2.new(1, -90, 0, 44)
shopHeader.BackgroundTransparency = 1
shopHeader.Font = Enum.Font.FredokaOne
shopHeader.TextXAlignment = Enum.TextXAlignment.Left
shopHeader.TextScaled = true
shopHeader.TextColor3 = Color3.fromRGB(250, 204, 21)
shopHeader.Text = "🛒 LOJA VIP & GAMEPASSES (MELHORES PREÇOS!)"
shopHeader.ZIndex = 31
shopHeader.Parent = shopModal
addTextStroke(shopHeader, 2.4)

local btnCloseShop = Instance.new("TextButton")
btnCloseShop.Position = UDim2.new(1, -56, 0, 12)
btnCloseShop.Size = UDim2.fromOffset(42, 42)
btnCloseShop.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
btnCloseShop.Font = Enum.Font.FredokaOne
btnCloseShop.Text = "X"
btnCloseShop.TextScaled = true
btnCloseShop.TextColor3 = Color3.new(1, 1, 1)
btnCloseShop.ZIndex = 31
btnCloseShop.Parent = shopModal
addCorner(btnCloseShop, 12)
addStroke(btnCloseShop, 2.5)
addTextStroke(btnCloseShop, 2)

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Position = UDim2.fromOffset(18, 66)
shopScroll.Size = UDim2.new(1, -36, 1, -82)
shopScroll.BackgroundTransparency = 1
shopScroll.CanvasSize = UDim2.fromOffset(0, 820)
shopScroll.ScrollBarThickness = 8
shopScroll.ZIndex = 31
shopScroll.Parent = shopModal

local shopGrid = Instance.new("UIGridLayout")
shopGrid.CellSize = UDim2.fromOffset(325, 118)
shopGrid.CellPadding = UDim2.fromOffset(14, 14)
shopGrid.Parent = shopScroll

for _, gp in ipairs(GAMEPASSES) do
    local card = Instance.new("Frame")
    card.BackgroundColor3 = Color3.fromRGB(23, 35, 61)
    card.ZIndex = 32
    card.Parent = shopScroll
    addCorner(card, 14)
    addStroke(card, 2.5, gp.Color)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -24, 0, 28)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.FredokaOne
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextScaled = true
    title.TextColor3 = gp.Color
    title.Text = gp.Name .. (if gp.Badge then (" [" .. gp.Badge .. "]") else "")
    title.ZIndex = 33
    title.Parent = card
    addTextStroke(title, 2)

    local desc = Instance.new("TextLabel")
    desc.Position = UDim2.fromOffset(12, 38)
    desc.Size = UDim2.new(1, -138, 0, 68)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.GothamBold
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextWrapped = true
    desc.TextScaled = true
    desc.TextColor3 = Color3.fromRGB(226, 232, 240)
    desc.Text = gp.Desc
    desc.ZIndex = 33
    desc.Parent = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Position = UDim2.new(1, -118, 0.5, -18)
    buyBtn.Size = UDim2.fromOffset(106, 52)
    buyBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    buyBtn.Font = Enum.Font.FredokaOne
    buyBtn.TextScaled = true
    buyBtn.TextColor3 = Color3.new(1, 1, 1)
    buyBtn.Text = string.format("R$ %d", gp.Price)
    buyBtn.ZIndex = 33
    buyBtn.Parent = card
    addCorner(buyBtn, 12)
    addStroke(buyBtn, 2.2)
    addTextStroke(buyBtn, 2)
    addBounceAnimation(buyBtn)

    buyBtn.MouseButton1Click:Connect(function()
        if gp.Id > 0 then
            MarketplaceService:PromptGamePassPurchase(LocalPlayer, gp.Id)
        else
            SpawnFloatingNumber("Configure o GamePass ID para " .. gp.Name, Color3.fromRGB(250, 204, 21), 0.9)
        end
    end)
end

btnShop.MouseButton1Click:Connect(function()
    shopModal.Visible = not shopModal.Visible
end)
btnCloseShop.MouseButton1Click:Connect(function()
    shopModal.Visible = false
end)

-- ============================================================================
-- 7. SINCRONIZAÇÃO COM LEADERSTATS + RESULTADOS DE CAPTURA
-- ============================================================================
task.spawn(function()
    local ls = LocalPlayer:WaitForChild("leaderstats")
    local moedasVal = ls:WaitForChild("Moedas") :: IntValue
    local nivelVal = ls:WaitForChild("Nivel") :: IntValue

    local lastCoins = moedasVal.Value
    moedasVal:GetPropertyChangedSignal("Value"):Connect(function()
        local diff = moedasVal.Value - lastCoins
        lastCoins = moedasVal.Value
        lblCoins.Text = string.format("💰 $%s", FormatBigNumber(moedasVal.Value))
        if diff >= 5 then
            SpawnFloatingNumber("+$" .. FormatBigNumber(diff), Color3.fromRGB(74, 222, 128), 0.95)
        end
    end)

    nivelVal:GetPropertyChangedSignal("Value"):Connect(function()
        xpText.Text = string.format("NV. %d  •  Sorte +%d%%", nivelVal.Value, math.floor(nivelVal.Value * 1.5))
        SpawnFloatingNumber("LEVEL UP! NV. " .. tostring(nivelVal.Value), Color3.fromRGB(250, 204, 21), 1.35)
    end)
end)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowResult = Remotes:WaitForChild("ThrowResult") :: RemoteEvent
ThrowResult.OnClientEvent:Connect(function(data)
    if data.Thrower ~= LocalPlayer then return end
    if data.Captured then
        SpawnFloatingNumber("CAPTURADO! +$" .. FormatBigNumber(data.IncomePerSec) .. "/s", Color3.fromRGB(250, 204, 21), 1.3)
        task.delay(0.25, function()
            SpawnFloatingNumber("+" .. FormatBigNumber(data.XPGained) .. " XP!", Color3.fromRGB(56, 189, 248), 1.05)
        end)
    else
        SpawnFloatingNumber("ESCAPOU! +" .. tostring(data.XPGained) .. " XP | +5% SORTE", Color3.fromRGB(251, 146, 60), 1.0)
    end
end)

-- Demonstração imediata de Big Numbers ao entrar
task.delay(1.2, function()
    SpawnFloatingNumber("Bem-vindo! Capture e faça Big Numbers!", Color3.fromRGB(125, 211, 252), 1.1)
end)
