--!strict
-- HUD funcional do passo 1. Interface final e monetização ficam para o passo 2.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild("StateUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent
local feedback = remotes:WaitForChild("ActionFeedback") :: RemoteEvent
local throwResult = remotes:WaitForChild("ThrowResult") :: RemoteEvent
local buyOrb = remotes:WaitForChild("BuyOrb") :: RemoteEvent
local equipOrb = remotes:WaitForChild("EquipOrb") :: RemoteEvent
local train = remotes:WaitForChild("TrainThrowPower") :: RemoteEvent
local equipSanctuary = remotes:WaitForChild("EquipToSanctuary") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "ThrowASphere_BaseHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local dark = Color3.fromRGB(20, 29, 43)
local ink = Color3.fromRGB(239, 246, 255)
local muted = Color3.fromRGB(172, 195, 215)
local accent = Color3.fromRGB(107, 237, 162)

local function corner(parent: GuiObject, radius: number)
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, radius)
    round.Parent = parent
end

local function text(parent: Instance, name: string, content: string, position: UDim2, size: UDim2, fontSize: number): TextLabel
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Text = content
    label.TextSize = fontSize
    label.Font = Enum.Font.GothamMedium
    label.TextColor3 = ink
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function button(parent: Instance, name: string, content: string, position: UDim2, size: UDim2): TextButton
    local item = Instance.new("TextButton")
    item.Name = name
    item.Position = position
    item.Size = size
    item.BackgroundColor3 = Color3.fromRGB(41, 60, 79)
    item.BorderSizePixel = 0
    item.Text = content
    item.TextSize = 13
    item.Font = Enum.Font.GothamBold
    item.TextColor3 = ink
    item.AutoButtonColor = true
    item.Parent = parent
    corner(item, 8)
    return item
end

local panel = Instance.new("Frame")
panel.Name = "StatsAndControls"
panel.Position = UDim2.fromOffset(12, 12)
panel.Size = UDim2.fromOffset(330, 258)
panel.BackgroundColor3 = dark
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Active = true
panel.Parent = gui
corner(panel, 12)
local scale = Instance.new("UIScale")
scale.Parent = panel

local title = text(panel, "Title", "JOGUE UMA ORBE!", UDim2.fromOffset(14, 12), UDim2.fromOffset(290, 22), 18)
title.Font = Enum.Font.GothamBlack
title.TextColor3 = accent
local modeLabel = text(panel, "Mode", "Carregando seus dados...", UDim2.fromOffset(14, 38), UDim2.fromOffset(302, 18), 11)
modeLabel.TextColor3 = muted
local coinsLabel = text(panel, "Coins", "$150   |   $0/s", UDim2.fromOffset(14, 64), UDim2.fromOffset(302, 24), 21)
local levelLabel = text(panel, "Level", "Nível 1   ·   0 / 100 XP", UDim2.fromOffset(14, 96), UDim2.fromOffset(302, 19), 14)
local bar = Instance.new("Frame")
bar.Name = "XPBar"
bar.Position = UDim2.fromOffset(14, 121)
bar.Size = UDim2.fromOffset(302, 6)
bar.BackgroundColor3 = Color3.fromRGB(48, 63, 79)
bar.BorderSizePixel = 0
bar.Parent = panel
corner(bar, 3)
local fill = Instance.new("Frame")
fill.Name = "XPFill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = accent
fill.BorderSizePixel = 0
fill.Parent = bar
corner(fill, 3)
local rangeLabel = text(panel, "Range", "Alcance 47 studs   ·   Combo x0", UDim2.fromOffset(14, 135), UDim2.fromOffset(302, 18), 12)
rangeLabel.TextColor3 = muted
local orbLabel = text(panel, "Orb", "Orbe Comum  ×25", UDim2.fromOffset(14, 161), UDim2.fromOffset(250, 20), 14)
local cycleButton = button(panel, "NextOrb", ">", UDim2.fromOffset(277, 155), UDim2.fromOffset(39, 31))
local equipButton = button(panel, "EquipOrb", "Equipar", UDim2.fromOffset(14, 193), UDim2.fromOffset(88, 29))
local buyButton = button(panel, "BuyOrb", "+1  $25", UDim2.fromOffset(110, 193), UDim2.fromOffset(96, 29))
local trainButton = button(panel, "Train", "Treinar +1", UDim2.fromOffset(214, 193), UDim2.fromOffset(102, 29))
local inventoryButton = button(panel, "Inventory", "Santuário / criaturas", UDim2.fromOffset(14, 230), UDim2.fromOffset(302, 20))
inventoryButton.BackgroundTransparency = 1
inventoryButton.TextColor3 = muted

local notice = text(gui, "Feedback", "Segure e solte sobre uma criatura para arremessar.", UDim2.new(0.5, 0, 1, -74), UDim2.new(0.92, 0, 0, 55), 14)
notice.AnchorPoint = Vector2.new(0.5, 0)
notice.TextXAlignment = Enum.TextXAlignment.Center
notice.TextWrapped = true
notice.TextStrokeTransparency = 0.35
notice.TextStrokeColor3 = Color3.fromRGB(12, 20, 30)

local inventory = Instance.new("Frame")
inventory.Name = "SanctuaryInventory"
inventory.AnchorPoint = Vector2.new(0.5, 0.5)
inventory.Position = UDim2.fromScale(0.5, 0.5)
inventory.Size = UDim2.new(0.9, 0, 0.72, 0)
inventory.BackgroundColor3 = dark
inventory.BorderSizePixel = 0
inventory.Visible = false
inventory.Active = true
inventory.ZIndex = 20
inventory.Parent = gui
corner(inventory, 12)
local maxSize = Instance.new("UISizeConstraint")
maxSize.MaxSize = Vector2.new(560, 440)
maxSize.Parent = inventory
local inventoryTitle = text(inventory, "Title", "CRIATURAS DO SANTUÁRIO", UDim2.fromOffset(16, 12), UDim2.new(1, -66, 0, 25), 16)
inventoryTitle.ZIndex = 21
inventoryTitle.Font = Enum.Font.GothamBold
local closeButton = button(inventory, "Close", "X", UDim2.new(1, -44, 0, 10), UDim2.fromOffset(30, 30))
closeButton.ZIndex = 21
local inventoryHint = text(inventory, "Hint", "Toque para colocar ou retirar. Até 6 criaturas geram $/s.", UDim2.fromOffset(16, 45), UDim2.new(1, -32, 0, 30), 12)
inventoryHint.TextColor3 = muted
inventoryHint.TextWrapped = true
inventoryHint.ZIndex = 21
local list = Instance.new("ScrollingFrame")
list.Name = "CreatureList"
list.Position = UDim2.fromOffset(12, 83)
list.Size = UDim2.new(1, -24, 1, -95)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 21
list.Parent = inventory
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local orbOrder = {"Comum", "Esmeralda", "Rubi", "Safira", "Runica", "Hextech", "Cosmica", "Mestre"}
local selectedIndex = 1
local state: any = nil
local noticeVersion = 0
local offlineShown = false
local inventorySignature = ""

local function number(value: number): string
    local suffixes = {"", "K", "M", "B", "T", "Qa", "Qi"}
    local tier = 1
    local amount = math.max(0, value)
    while amount >= 1000 and tier < #suffixes do
        amount /= 1000
        tier += 1
    end
    return if tier == 1 then string.format("%.0f", amount) else string.format("%.1f%s", amount, suffixes[tier])
end

local function showNotice(message: string, isError: boolean?)
    noticeVersion += 1
    local version = noticeVersion
    notice.Text = message
    notice.TextColor3 = if isError then Color3.fromRGB(255, 151, 140) else ink
    task.delay(5, function()
        if version ~= noticeVersion then return end
        notice.Text = "Mira verde: corpo · Dourada: cabeça · Vermelha: fora de alcance"
        notice.TextColor3 = ink
    end)
end

local function renderOrb()
    local id = orbOrder[selectedIndex]
    local definition = Config.Orbs[id]
    local quantity = if state and state.Orbs then state.Orbs[id] or 0 else 0
    local equipped = state and state.EquippedOrb == id
    orbLabel.Text = string.format("%s  ×%d", definition.Name, quantity)
    equipButton.Text = if equipped then "Equipada" else "Equipar"
    equipButton.TextColor3 = if equipped then accent else ink
    buyButton.Text = if definition.IsMaster then "Drop raro" else "+1  $" .. number(definition.Price)
    buyButton.Active = not definition.IsMaster
    buyButton.AutoButtonColor = not definition.IsMaster
    buyButton.TextColor3 = if definition.IsMaster then muted else ink
end

local function renderInventory()
    if not state then return end
    local signatureParts: {string} = {}
    for _, creature in state.CapturedCreatures or {} do table.insert(signatureParts, creature.Uid) end
    table.insert(signatureParts, "slots")
    for _, uid in state.SanctuarySlots or {} do table.insert(signatureParts, uid) end
    local signature = table.concat(signatureParts, ":")
    if signature == inventorySignature and #list:GetChildren() > 1 then return end
    inventorySignature = signature
    for _, child in list:GetChildren() do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    local slots: {[string]: boolean} = {}
    for _, uid in state.SanctuarySlots or {} do slots[uid] = true end
    local creatures = state.CapturedCreatures or {}
    if #creatures == 0 then
        local empty = text(list, "Empty", "Capture sua primeira criatura na pradaria!", UDim2.new(), UDim2.new(1, -6, 0, 50), 13)
        empty.TextWrapped = true
        empty.ZIndex = 22
        return
    end
    for index, creature in creatures do
        local definition = Config.Creatures[creature.CreatureId]
        local creatureName = if definition then definition.Name else creature.CreatureId
        local item = button(list, "Creature_" .. index,
            string.format("%s %s · %s / %s · $%s/s", if slots[creature.Uid] then "[NA BASE]" else "[GUARDADA]",
                creatureName, creature.Mutation, creature.Size, number(creature.IncomePerSec)),
            UDim2.new(), UDim2.new(1, -6, 0, 55))
        item.TextWrapped = true
        item.TextSize = 12
        item.LayoutOrder = index
        item.ZIndex = 22
        item.TextColor3 = if slots[creature.Uid] then accent else ink
        local uid = creature.Uid
        item.Activated:Connect(function() equipSanctuary:FireServer(uid) end)
    end
end

stateUpdate.OnClientEvent:Connect(function(snapshot: any)
    if typeof(snapshot) ~= "table" then return end
    state = snapshot
    coinsLabel.Text = "$" .. number(snapshot.Coins or 0) .. "   |   $" .. number(snapshot.IncomePerSec or 0) .. "/s"
    local required = snapshot.XPRequired or Config.GetXPRequiredForLevel(snapshot.Level or 1)
    local level = snapshot.Level or 1
    local slotCapacity = Config.Constants.BaseSanctuarySlots + (if level >= 5 then 1 else 0) + (if level >= 15 then 1 else 0)
    inventoryHint.Text = string.format("Toque para colocar ou retirar. Até %d criaturas geram $/s.", slotCapacity)
    levelLabel.Text = string.format("Nível %d   ·   %s / %s XP", snapshot.Level or 1, number(snapshot.XP or 0), number(required))
    fill.Size = UDim2.fromScale(math.clamp((snapshot.XP or 0) / math.max(1, required), 0, 1), 1)
    rangeLabel.Text = string.format("Alcance %.0f studs   ·   Combo x%d", snapshot.MaxRange or 47, snapshot.ComboStreak or 0)
    modeLabel.Text = if snapshot.DataMode == "StudioMemory" then "TESTE LOCAL · dados não são salvos" else "Dados persistentes · salvamento automático"
    renderOrb()
    if inventory.Visible then renderInventory() end
    if not offlineShown and (snapshot.OfflineReward or 0) > 0 then
        offlineShown = true
        showNotice("Bem-vindo de volta! Seu santuário gerou $" .. number(snapshot.OfflineReward) .. " offline.")
    end
end)

feedback.OnClientEvent:Connect(function(message: any)
    if typeof(message) == "string" then showNotice(message)
    elseif typeof(message) == "table" and typeof(message.Message) == "string" then
        showNotice(message.Message, message.Kind == "Error")
    end
end)

throwResult.OnClientEvent:Connect(function(data: any)
    if typeof(data) ~= "table" or data.Thrower ~= player then return end
    local prefix = if data.IsCritical then "CRÍTICO! " else ""
    showNotice(prefix .. "Orbe lançada... aguardando as balançadas.")
    task.delay(3, function()
        if data.Captured then
            showNotice(string.format("CAPTURADO! %s / %s · +%s XP", data.MutationName or "Normal", data.SizeName or "Normal", number(data.XPGained or 0)))
        else
            showNotice("Escapou! +" .. number(data.XPGained or 0) .. " XP e +5% de sorte acumulada.")
        end
    end)
end)

cycleButton.Activated:Connect(function()
    selectedIndex = selectedIndex % #orbOrder + 1
    renderOrb()
end)
equipButton.Activated:Connect(function() equipOrb:FireServer(orbOrder[selectedIndex]) end)
buyButton.Activated:Connect(function()
    local id = orbOrder[selectedIndex]
    if not Config.Orbs[id].IsMaster then buyOrb:FireServer(id, 1) end
end)
trainButton.Activated:Connect(function() train:FireServer() end)
inventoryButton.Activated:Connect(function()
    inventory.Visible = not inventory.Visible
    if inventory.Visible then renderInventory() end
end)
closeButton.Activated:Connect(function() inventory.Visible = false end)

local function resize()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    scale.Scale = math.clamp(math.min(camera.ViewportSize.X / 800, camera.ViewportSize.Y / 650), 0.67, 1)
end
local cameraConnection: RBXScriptConnection? = nil
local function bindCamera()
    if cameraConnection then cameraConnection:Disconnect() end
    local camera = Workspace.CurrentCamera
    if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
bindCamera()
renderOrb()
requestState:FireServer()
