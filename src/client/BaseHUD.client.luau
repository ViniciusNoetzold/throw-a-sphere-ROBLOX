--!strict
-- Step 2: responsive simulator HUD. All economy and progression remain server-owned.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Progression = require(Shared:WaitForChild("ConfigProgression"))
local GameplayMath = require(Shared:WaitForChild("GameplayMath"))
local Numbers = require(Shared:WaitForChild("NumberFormatter"))
local UI = script.Parent:WaitForChild("UI")
local W = require(UI:WaitForChild("HUDWidgets"))
local Panels = require(UI:WaitForChild("HUDPanels"))
local ShopView = require(UI:WaitForChild("ShopView"))
local Icons = require(UI:WaitForChild("HUDIcons"))
local Gameplay = require(UI:WaitForChild("GameplayPanels"))
local Commerce = require(UI:WaitForChild("CommercePanels"))
local C = W.Colors
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateUpdate = remotes:WaitForChild("StateUpdate") :: RemoteEvent
local requestState = remotes:WaitForChild("RequestState") :: RemoteEvent
local feedback = remotes:WaitForChild("ActionFeedback") :: RemoteEvent
local throwResult = remotes:WaitForChild("ThrowResult") :: RemoteEvent
local equipOrb = remotes:WaitForChild("EquipOrb") :: RemoteEvent
local equipSanctuary = remotes:WaitForChild("EquipToSanctuary") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "ThrowASphere_HUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui:SetAttribute("ModalOpen", false)
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundTransparency = 1
root.Parent = gui

local state: any = nil
local currentPanel: string? = nil
local panelCleanup: (() -> ())? = nil
local panelSignature = ""
local offlineShown = false
local noticeVersion = 0
local bannerVersion = 0
local floatingCount = 0
local compact = false
local portrait = false
local random = Random.new()
local openPanel: (string) -> ()
local renderPanel: () -> ()
local getPanelSignature: (any) -> string
local session: any = {}
local stateReceivedAt = os.clock()
local worldWeather: any = nil

local heading = W.Label(root, "GameTitle", "THROW A SPHERE!", UDim2.fromOffset(14, 6), UDim2.fromOffset(260, 28), 25, C.Gold)
local dataMode = W.Label(root, "DataMode", "CARREGANDO SEU SANTUÁRIO...", UDim2.fromOffset(15, 36), UDim2.fromOffset(280, 18), 10, C.Muted, true)
local event = W.Frame(root, "Event", UDim2.new(0.5, 0, 0, 8), UDim2.fromOffset(180, 24), C.Panel)
event.AnchorPoint = Vector2.new(0.5, 0)
W.Outline(event, 1.5, C.Gold)
local eventTitle = W.Label(event, "EventTitle", "", UDim2.fromOffset(8, 0), UDim2.new(1, -16, 1, 0), 15, C.Gold)
eventTitle.TextXAlignment = Enum.TextXAlignment.Center
eventTitle.TextTruncate = Enum.TextTruncate.AtEnd
local eventProgress = Instance.new("Frame")
eventProgress.Name = "EventProgress"
eventProgress.Position = UDim2.new(0, 7, 1, -4)
eventProgress.Size = UDim2.new(0, 0, 0, 2)
eventProgress.BackgroundColor3 = C.Gold
eventProgress.BorderSizePixel = 0
eventProgress.Parent = event
local function updateEvent()
    local weather = worldWeather or (state and state.Weather)
    local timestamp = Workspace:GetServerTimeNow()
    local active = weather and (weather.EndsAt or 0) > timestamp
    event.Visible = root.AbsoluteSize.X >= 580 and (active == true or (weather and (weather.TotemEndsAt or 0) > timestamp) == true)
    if active then
        eventTitle.Text = (weather.Name or "Evento") .. " · " .. Gameplay.Time(weather.EndsAt - timestamp)
        local fraction = math.clamp((weather.EndsAt - timestamp) / math.max(1, weather.EndsAt - (weather.StartedAt or timestamp)), 0, 1)
        eventProgress.Size = UDim2.new(fraction, -14 * fraction, 0, 2)
    else
        eventTitle.Text = if weather and (weather.TotemEndsAt or 0) > timestamp
            then "Totem · " .. Gameplay.Time(weather.TotemEndsAt - timestamp) else ""
        eventProgress.Size = UDim2.fromOffset(0, 2)
    end
end
local leftMenu = Instance.new("Frame")
leftMenu.Name = "LeftMenu"
leftMenu.BackgroundTransparency = 1
leftMenu.Position = UDim2.fromOffset(12, 92)
leftMenu.Size = UDim2.fromOffset(176, 240)
leftMenu.Parent = root
local leftScale = Instance.new("UIScale")
leftScale.Parent = leftMenu
local rightMenu = Instance.new("Frame")
rightMenu.Name = "RightMenu"
rightMenu.AnchorPoint = Vector2.new(1, 0)
rightMenu.Position = UDim2.new(1, -12, 0, 92)
rightMenu.Size = UDim2.fromOffset(82, 328)
rightMenu.BackgroundTransparency = 1
rightMenu.Parent = root
local rightScale = Instance.new("UIScale")
rightScale.Parent = rightMenu
local menuButtons: {[string]: TextButton} = {}
local newDiscoveryBadge: TextLabel? = nil
for index, item in Panels.MenuItems do
    local isLeft = index <= 6
    local localIndex = if isLeft then index - 1 else index - 7
    local position = if isLeft then UDim2.fromOffset((localIndex % 2) * 94, math.floor(localIndex / 2) * 78) else UDim2.fromOffset(0, localIndex * 78)
    local button = W.Button(if isLeft then leftMenu else rightMenu, item.Id, item.Name, position, UDim2.fromOffset(82, 68), item.Color, 12)
    local caption = button:FindFirstChild("Caption") :: TextLabel
    caption.Position = UDim2.fromOffset(3, 39)
    caption.Size = UDim2.new(1, -6, 0, 25)
    local iconHost = Instance.new("Frame")
    iconHost.Name = "MenuIcon"
    iconHost.Position = UDim2.fromOffset(4, 0)
    iconHost.Size = UDim2.new(1, -8, 0, 42)
    iconHost.BackgroundTransparency = 1
    iconHost.Active = false
    iconHost.Parent = button
    Icons.Draw(iconHost, item.Icon, item.Color)
    button.Activated:Connect(function() openPanel(item.Id) end)
    menuButtons[item.Id] = button
    if item.Id == "Loja" then
        local glow = W.Outline(button, 1.5, C.Gold)
        TweenService:Create(glow, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.8}):Play()
    elseif item.Id == "Bestiario" then
        local badge = W.Label(button, "NewDiscovery", "!", UDim2.new(1, -15, 0, -7), UDim2.fromOffset(24, 24), 17)
        badge.BackgroundColor3 = C.Pink
        badge.TextXAlignment = Enum.TextXAlignment.Center
        badge.Visible = false
        W.Round(badge, 12)
        newDiscoveryBadge = badge
    elseif item.Id == "Auto" then
        local planned = W.Label(button, "Planned", "ACESSO", UDim2.new(1, -52, 0, -5), UDim2.fromOffset(58, 15), 8, C.Gold, true)
        planned.BackgroundColor3 = C.Ink
        planned.TextXAlignment = Enum.TextXAlignment.Center
        W.Round(planned, 6)
    end
end
local navigation = W.Button(root, "OpenMenu", "MENU", UDim2.fromOffset(10, 4), UDim2.fromOffset(78, 44), C.Purple, 12)
local navigationCaption = navigation:FindFirstChild("Caption") :: TextLabel
navigationCaption.Position = UDim2.fromOffset(28, 0)
navigationCaption.Size = UDim2.new(1, -30, 1, 0)
local navigationIcon = Instance.new("Frame")
navigationIcon.Name = "MenuIcon"
navigationIcon.Position = UDim2.fromOffset(4, 9)
navigationIcon.Size = UDim2.fromOffset(24, 26)
navigationIcon.BackgroundTransparency = 1
navigationIcon.Active = false
navigationIcon.Parent = navigation
Icons.Draw(navigationIcon, "Menu", C.Purple)
navigation.Visible = false
navigation.Activated:Connect(function() openPanel("Menu") end)
local rewardsButton = W.Button(root, "Rewards", "RESGATES", UDim2.fromOffset(96, 4), UDim2.fromOffset(100, 44), C.Green, 12)
rewardsButton.Activated:Connect(function() openPanel("Resgates") end)

local stats = W.Frame(root, "Stats", UDim2.new(0, 12, 1, -12), UDim2.fromOffset(238, 178), C.Panel)
stats.AnchorPoint = Vector2.new(0, 1)
W.Outline(stats, 1.5, C.Blue)
local statsScale = Instance.new("UIScale")
statsScale.Parent = stats
local function statusStrip(name: string, y: number, height: number, color: Color3): Frame
    local strip = Instance.new("Frame")
    strip.Name = name
    strip.Position = UDim2.fromOffset(7, y)
    strip.Size = UDim2.fromOffset(224, height)
    strip.BorderSizePixel = 0
    strip.Active = false
    strip.Parent = stats
    W.Round(strip, 8)
    W.Gradient(strip, color:Lerp(C.Ink, 0.55))
    local edge = W.Outline(strip, 1, color)
    edge.Transparency = 0.4
    return strip
end
statusStrip("StrengthSurface", 5, 26, C.Orange)
local coinsStrip = statusStrip("CoinsSurface", 33, 52, C.Green)
W.Pattern(coinsStrip, C.Green, 6, 1)
local strengthIconHost = Instance.new("Frame")
strengthIconHost.Name = "StrengthIcon"
strengthIconHost.Position = UDim2.fromOffset(9, 5)
strengthIconHost.Size = UDim2.fromOffset(25, 25)
strengthIconHost.BackgroundTransparency = 1
strengthIconHost.Active = false
strengthIconHost.Parent = stats
Icons.Draw(strengthIconHost, "Bolt", C.Orange)
local strengthLabel = W.Label(stats, "Strength", "FORÇA 10", UDim2.fromOffset(37, 6), UDim2.fromOffset(189, 24), 14, C.Orange)
local coinsLabel = W.Label(stats, "Coins", "$150", UDim2.fromOffset(12, 29), UDim2.fromOffset(214, 36), 32, C.Gold)
local incomeLabel = W.Label(stats, "Income", "+$0 /s NO SANTUÁRIO", UDim2.fromOffset(12, 66), UDim2.fromOffset(214, 19), 13, C.Green)
local gemsLabel = W.Label(stats, "Gems", "0 GEMAS  •  0 REBIRTHS", UDim2.fromOffset(12, 88), UDim2.fromOffset(214, 18), 11, C.Purple, true)
local xpBar = W.Frame(stats, "XPBar", UDim2.fromOffset(12, 111), UDim2.fromOffset(214, 24), C.Ink)
xpBar.ClipsDescendants = true
local xpFill = Instance.new("Frame")
xpFill.Name = "XPFill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = C.Blue
xpFill.BorderSizePixel = 0
xpFill.Parent = xpBar
W.Round(xpFill, 10)
W.Gradient(xpFill, C.Blue, C.Purple)
W.Pattern(xpFill, C.Blue, 8, 1)
local xpLabel = W.Label(xpBar, "Level", "NV. 1  •  0% XP", UDim2.fromOffset(4, 0), UDim2.new(1, -8, 1, 0), 12)
xpLabel.TextXAlignment = Enum.TextXAlignment.Center
local luckLabel = W.Label(stats, "Luck", "SORTE ×1.00", UDim2.fromOffset(12, 137), UDim2.fromOffset(214, 18), 10, C.Muted, true)
local rankLabel = W.Label(stats, "TrainerRank", "Iniciante", UDim2.fromOffset(12, 155), UDim2.fromOffset(214, 18), 11, C.Gold)

local hotbar = W.Frame(root, "Hotbar", UDim2.new(0.5, 0, 1, -12), UDim2.fromOffset(460, 86), C.Panel)
hotbar.AnchorPoint = Vector2.new(0.5, 1)
W.Outline(hotbar, 1.5, C.Gold)
local hotbarScale = Instance.new("UIScale")
hotbarScale.Parent = hotbar
local orbIcon = Instance.new("Frame")
orbIcon.Name = "OrbIcon"
orbIcon.Position = UDim2.fromOffset(10, 10)
orbIcon.Size = UDim2.fromOffset(44, 44)
orbIcon.BackgroundTransparency = 1
orbIcon.Active = false
orbIcon.Parent = hotbar
local orbArtwork = Icons.Draw(orbIcon, "Orb", C.Blue)
local orbLabel = W.Label(hotbar, "EquippedOrb", "ORBE COMUM", UDim2.fromOffset(64, 8), UDim2.fromOffset(174, 24), 16, C.Blue)
orbLabel.TextTruncate = Enum.TextTruncate.AtEnd
local orbPower = W.Label(hotbar, "OrbPower", "PODER 10", UDim2.fromOffset(64, 32), UDim2.fromOffset(174, 20), 11, C.Muted, true)
local trainButton = W.Button(hotbar, "Train", "ACADEMIA", UDim2.fromOffset(246, 10), UDim2.fromOffset(92, 36), C.Orange, 12)
trainButton.Activated:Connect(function() openPanel("Academia") end)
local swapButton = W.Button(hotbar, "SwapOrb", "EVOLUIR ORBE", UDim2.fromOffset(346, 10), UDim2.fromOffset(104, 36), C.Blue, 11)
swapButton.Activated:Connect(function() openPanel("Orbes") end)
local room = W.Frame(root, "Room", UDim2.new(1, -12, 1, -12), UDim2.fromOffset(172, 49), C.Panel)
room.AnchorPoint = Vector2.new(1, 1)
local roomLabel = W.Label(room, "Players", "SALA • 1 JOGADOR", UDim2.fromOffset(10, 4), UDim2.fromOffset(152, 22), 12, C.Green)
W.Label(room, "Biome", "Pradaria Solar", UDim2.fromOffset(10, 26), UDim2.fromOffset(152, 17), 11, C.Muted, true)

local notice = W.Label(root, "Feedback", "", UDim2.new(0.5, 0, 1, -112), UDim2.new(0.66, 0, 0, 42), 15)
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.TextXAlignment = Enum.TextXAlignment.Center
notice.TextWrapped = true
notice.ZIndex = 55
notice.Visible = false
local function showNotice(message: string, isError: boolean?)
    noticeVersion += 1
    local version = noticeVersion
    notice.Text = message
    notice.TextColor3 = if isError then C.Pink else C.White
    notice.Visible = true
    task.delay(4.5, function()
        if version ~= noticeVersion then return end
        notice.Text = ""
        notice.TextColor3 = C.Muted
        notice.Visible = false
    end)
end

local floatingLayer = Instance.new("Frame")
floatingLayer.Name = "FloatingNumbers"
floatingLayer.BackgroundTransparency = 1
floatingLayer.Size = UDim2.fromScale(1, 1)
floatingLayer.ZIndex = 30
floatingLayer.Parent = root
local function spawnFloatingNumber(value: string, color: Color3, size: number?)
    if floatingCount >= 14 then return end
    floatingCount += 1
    local x = random:NextNumber(0.38, 0.62)
    local y = random:NextNumber(0.47, 0.59)
    local label = W.Label(floatingLayer, "Popup", value, UDim2.fromScale(x, y), UDim2.fromOffset(340, 44), size or 24, color)
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Rotation = random:NextInteger(-6, 6)
    local scale = Instance.new("UIScale")
    scale.Scale = 0.4
    scale.Parent = label
    TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = if compact then 0.8 else 1}):Play()
    TweenService:Create(label, TweenInfo.new(1.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.fromScale(x + random:NextNumber(-0.035, 0.035), y - 0.15), Rotation = 0}):Play()
    task.delay(0.7, function()
        if not label.Parent then return end
        TweenService:Create(label, TweenInfo.new(0.45), {TextTransparency = 1}):Play()
        local stroke = label:FindFirstChildOfClass("UIStroke")
        if stroke then TweenService:Create(stroke, TweenInfo.new(0.45), {Transparency = 1}):Play() end
    end)
    Debris:AddItem(label, 1.3)
    task.delay(1.3, function() floatingCount = math.max(0, floatingCount - 1) end)
end

local banner = W.Frame(root, "RareCaptureBanner", UDim2.new(0.5, 0, 0, 88), UDim2.fromOffset(470, 58), C.Purple)
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Visible = false
banner.ZIndex = 35
W.Gradient(banner, C.Purple, C.Pink)
local avatar = Instance.new("ImageLabel")
avatar.Name = "PlayerAvatar"
avatar.BackgroundColor3 = C.Panel
avatar.Position = UDim2.fromOffset(8, 7)
avatar.Size = UDim2.fromOffset(44, 44)
avatar.Parent = banner
W.Round(avatar, 22)
local rareText = W.Label(banner, "Announcement", "", UDim2.fromOffset(60, 5), UDim2.new(1, -70, 1, -10), 15)
rareText.TextWrapped = true
local function showRareCapture(data: any)
    local definition = Config.Creatures[data.CreatureId]
    if not definition or not data.Captured then return end
    local rare = definition.Rarity == "Mitica" or definition.Rarity == "Lendaria" or definition.Rarity == "Secreta" or data.MutationName == "ArcoIris"
    if not rare then return end
    local thrower = data.Thrower
    if typeof(thrower) ~= "Instance" or not thrower:IsA("Player") then return end
    bannerVersion += 1
    local version = bannerVersion
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. thrower.UserId .. "&w=100&h=100"
    rareText.Text = thrower.DisplayName .. " capturou " .. definition.Name .. "!\n" .. definition.Rarity .. " • " .. tostring(data.MutationName or "Normal")
    banner.Visible = true
    task.delay(5, function() if version == bannerVersion then banner.Visible = false end end)
end

local backdrop = Instance.new("TextButton")
backdrop.Name = "ModalBackdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = C.Ink
backdrop.BackgroundTransparency = 0.25
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.ZIndex = 50
backdrop.Parent = root
local modal = W.Frame(backdrop, "Modal", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.86), C.Panel)
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Active = true
local modalConstraint = Instance.new("UISizeConstraint")
modalConstraint.MaxSize = Vector2.new(860, 620)
modalConstraint.Parent = modal
local modalTitle = W.Label(modal, "Title", "MINHAS CRIATURAS", UDim2.fromOffset(18, 10), UDim2.new(1, -84, 0, 36), 25, C.Gold)
modalTitle.TextTruncate = Enum.TextTruncate.AtEnd
local closeButton = W.Button(modal, "Close", "×", UDim2.new(1, -58, 0, 7), UDim2.fromOffset(44, 44), C.Pink, 25)
local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(14, 58)
content.Size = UDim2.new(1, -28, 1, -72)
content.BackgroundTransparency = 1
content.Parent = modal
local selectedBeforeModal: GuiObject? = nil
local panelGeneration = 0
local renderedPanel: string? = nil
local function clearPanel()
    panelGeneration += 1
    if panelCleanup then panelCleanup(); panelCleanup = nil end
    for _, child in content:GetChildren() do child:Destroy() end
end
local function closePanel()
    currentPanel = nil
    session.RebirthConfirmed = false
    session.SellCreature, session.ReplaceCreature = nil, nil
    gui:SetAttribute("ModalOpen", false)
    backdrop.Visible = false
    noticeVersion += 1
    notice.Text = ""
    notice.TextColor3 = C.Muted
    notice.Visible = false
    ContextActionService:UnbindAction("ThrowASphereCloseModal")
    renderedPanel = nil
    clearPanel()
    if selectedBeforeModal and selectedBeforeModal.Parent then GuiService.SelectedObject = selectedBeforeModal else GuiService.SelectedObject = nil end
    selectedBeforeModal = nil
end
backdrop.Activated:Connect(closePanel)
closeButton.Activated:Connect(closePanel)
local actions = {
    Notify = function(message: string) showNotice(message) end,
    Open = function(kind: string) openPanel(kind) end,
    EquipOrb = function(id: string) equipOrb:FireServer(id) end,
    EquipSanctuary = function(uid: string) equipSanctuary:FireServer(uid) end,
    Close = closePanel,
    Send = function(name: string, ...: any)
        local remote = remotes:FindFirstChild(name)
        if remote and remote:IsA("RemoteEvent") then remote:FireServer(...) else showNotice("Esta ação está carregando. Tente novamente em instantes.", true) end
    end,
    GetState = function() return state end,
    Refresh = function() renderPanel() end,
    Session = session,
    Elapsed = function() return math.max(0, os.clock() - stateReceivedAt) end,
}
renderPanel = function()
    if not currentPanel then return end
    local focusedTextBox = UserInputService:GetFocusedTextBox()
    local textFocusPath: {string} = {}
    local cursor, selectionStart = -1, -1
    if focusedTextBox and focusedTextBox:IsDescendantOf(content) and renderedPanel == currentPanel then
        cursor, selectionStart = focusedTextBox.CursorPosition, focusedTextBox.SelectionStart
        local target: Instance? = focusedTextBox
        while target and target ~= content do table.insert(textFocusPath, 1, target.Name); target = target.Parent end
    end
    local focusedPath: {string} = {}
    local selected: Instance? = GuiService.SelectedObject
    if selected and selected:IsDescendantOf(content) and renderedPanel == currentPanel then
        while selected and selected ~= content do
            table.insert(focusedPath, 1, selected.Name)
            selected = selected.Parent
        end
    end
    local previousList = if renderedPanel == currentPanel then content:FindFirstChildWhichIsA("ScrollingFrame", true) else nil
    local scrollPosition = if previousList then previousList.CanvasPosition else Vector2.zero
    local listName = if previousList then previousList.Name else nil
    clearPanel()
    local generation = panelGeneration
    if currentPanel == "Resgates" then
        local count = state and (state.DropInfo or {}).ActiveCount or 0
        modalConstraint.MaxSize = Vector2.new(388, math.clamp(95 + 76 * count, 155, 350))
    elseif currentPanel == "Academia" then
        modalConstraint.MaxSize = Vector2.new(416, 356)
    else
        modalConstraint.MaxSize = Vector2.new(860, 620)
    end
    modalTitle.Text = Panels.Titles[currentPanel] or currentPanel
    if currentPanel == "Loja" then panelCleanup = ShopView.Render(content, actions.Notify)
    elseif Gameplay.Handles(currentPanel) then panelCleanup = Gameplay.Render(content, currentPanel, state, actions)
    elseif currentPanel == "Trocas" or currentPanel == "Leiloes" or currentPanel == "GrupoVIP" then panelCleanup = Commerce.Render(content, currentPanel, state, actions)
    else panelCleanup = Panels.Render(content, currentPanel, state, actions) end
    renderedPanel = currentPanel
    if #textFocusPath > 0 then
        task.defer(function()
            if generation ~= panelGeneration then return end
            local restored: Instance? = content
            for _, name in textFocusPath do restored = if restored then restored:FindFirstChild(name) else nil end
            if restored and restored:IsA("TextBox") then
                restored:CaptureFocus()
                if cursor > 0 then restored.CursorPosition = math.min(cursor, #restored.Text + 1) end
                if selectionStart > 0 then restored.SelectionStart = math.min(selectionStart, #restored.Text + 1) end
            end
        end)
    end
    if scrollPosition.Y > 0 then
        task.delay(0.05, function()
            if generation ~= panelGeneration then return end
            local list = if listName then content:FindFirstChild(listName, true) else nil
            if list and list:IsA("ScrollingFrame") then list.CanvasPosition = scrollPosition end
        end)
    end
    if UserInputService.GamepadEnabled then
        local restored: Instance? = content
        for _, name in focusedPath do restored = if restored then restored:FindFirstChild(name) else nil end
        GuiService.SelectedObject = if restored and restored:IsA("GuiButton") then restored else closeButton
    end
end
openPanel = function(kind: string)
    local rewardAlias = kind == "Missoes" or kind == "Consumiveis"
    if rewardAlias then session.RewardsTab = if kind == "Missoes" then "Missions" else "Consumables"; kind = "Diario" end
    if currentPanel == kind and not rewardAlias then closePanel(); return end
    if currentPanel ~= "Rebirth" or kind ~= "Rebirth" then session.RebirthConfirmed = false end
    if not currentPanel then selectedBeforeModal = GuiService.SelectedObject end
    currentPanel = kind
    panelSignature = if state then getPanelSignature(state) else ""
    backdrop.Visible = true
    notice.Visible = false
    gui:SetAttribute("ModalOpen", true)
    ContextActionService:BindActionAtPriority("ThrowASphereCloseModal", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then closePanel() end
        return Enum.ContextActionResult.Sink
    end, false, Enum.ContextActionPriority.High.Value + 100, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
    if kind == "Bestiario" and newDiscoveryBadge then newDiscoveryBadge.Visible = false end
    renderPanel()
end

getPanelSignature = function(snapshot: any): string
    if not snapshot then return "loading" end
    if currentPanel and Gameplay.Handles(currentPanel) then return Gameplay.Signature(currentPanel, snapshot) end
    if currentPanel == "Trocas" or currentPanel == "Leiloes" or currentPanel == "GrupoVIP" then return Commerce.Signature(currentPanel, snapshot, session) end
    local parts: {string} = {}
    if currentPanel == "Criaturas" then
        return Gameplay.Stable({Captures = snapshot.CapturedCreatures, Slots = snapshot.SanctuarySlots, SlotCapacity = snapshot.SlotCapacity, Progression = snapshot.Progression, Reserved = snapshot.InventoryReservedSlots})
    elseif currentPanel == "Bestiario" then
        return Gameplay.Stable({Bestiary = snapshot.Bestiary, Claimed = snapshot.BestiaryRewardClaimed})
    elseif currentPanel == "Resgates" then
        return Gameplay.Stable((snapshot.DropInfo or {}).Drops)
    elseif currentPanel == "Academia" then
        local training = snapshot.Training or {}
        local rules = Panels.Machines
        local nextMachine = rules[(training.MachineTier or 1) + 1]
        return Gameplay.Stable({Training = training, CanAfford = nextMachine and snapshot.Coins >= nextMachine.Cost})
    elseif currentPanel == "Orbes" then
        table.insert(parts, tostring(snapshot.OrbTier))
        table.insert(parts, tostring(snapshot.OrbFragments or 0))
        local affordable = false
        for _, orb in Config.Orbs do
            if orb.Tier == (snapshot.OrbTier or 1) + 1 then
                affordable = snapshot.Coins >= GameplayMath.GetOrbEvolutionPrice(orb.Price, snapshot.OrbFragments or 0)
            end
        end
        table.insert(parts, tostring(affordable))
        table.insert(parts, tostring(snapshot.EquippedOrb))
        for _, id in Panels.OrbOrder do table.insert(parts, tostring((snapshot.Orbs or {})[id] or 0)) end
        table.insert(parts, tostring(snapshot.Benefits and snapshot.Benefits.EternalPrism))
    elseif currentPanel == "Loja" then
        return Gameplay.Stable({Benefits = snapshot.Benefits, SalesEnabled = snapshot.SalesEnabled})
    end
    return table.concat(parts, ":")
end

stateUpdate.OnClientEvent:Connect(function(snapshot: any)
    if typeof(snapshot) ~= "table" then return end
    local previous = state
    state = snapshot
    stateReceivedAt = os.clock()
    if snapshot.Weather then worldWeather = snapshot.Weather end
    local level = snapshot.Level or 1
    local required = snapshot.XPRequired or Config.GetXPRequiredForLevel(level)
    local percent = math.clamp((snapshot.XP or 0) / math.max(1, required), 0, 1)
    if level >= Config.Constants.MaxLevel then percent = 1 end
    coinsLabel.Text = "$" .. Numbers.Format(snapshot.Coins or 0)
    incomeLabel.Text = "+$" .. Numbers.Format(snapshot.IncomePerSec or 0) .. " /s NO SANTUÁRIO"
    strengthLabel.Text = "FORÇA " .. Numbers.Format(snapshot.ThrowStrength or 10)
    gemsLabel.Text = Numbers.Format(snapshot.Gems or 0) .. " GEMAS  •  " .. Numbers.Format(snapshot.Rebirths or 0) .. " REBIRTHS"
    xpLabel.Text = "NV. " .. level .. (if level >= Config.Constants.MaxLevel then "  •  NÍVEL MÁXIMO" else "  •  " .. math.floor(percent * 100) .. "% XP")
    rankLabel.Text = Progression.GetTrainerRank(level)
    TweenService:Create(xpFill, TweenInfo.new(0.2), {Size = UDim2.fromScale(percent, 1)}):Play()
    local luck = snapshot.EffectiveLuck or 1
    luckLabel.Text = string.format("SORTE ×%.2f", luck)
    dataMode.Text = if snapshot.DataMode == "StudioMemory" then "TESTE LOCAL • DADOS NÃO SÃO SALVOS" else "SALVAMENTO AUTOMÁTICO ATIVO"
    local orb = Config.Orbs[snapshot.EquippedOrb or "Comum"]
    if orb then
        local reusable = orb.Tier and orb.Tier <= (snapshot.OrbTier or 1)
        orbLabel.Text = string.upper(orb.Name) .. (if reusable then "" elseif orb.IsPrismatic and snapshot.Benefits and snapshot.Benefits.EternalPrism then " ∞" else " ×" .. Numbers.Format((snapshot.Orbs or {})[orb.Id] or 0))
        orbLabel.TextColor3 = orb.Color
        if not previous or previous.EquippedOrb ~= snapshot.EquippedOrb then
            orbArtwork:Destroy()
            orbArtwork = Icons.Draw(orbIcon, "Orb", orb.Color)
        end
        orbPower.Text = "PODER " .. Numbers.Format(orb.Power)
    end
    if previous then
        for id, discovered in snapshot.Bestiary or {} do
            if discovered and not (previous.Bestiary or {})[id] and newDiscoveryBadge and currentPanel ~= "Bestiario" then newDiscoveryBadge.Visible = true end
        end
    end
    local rewardCount = (snapshot.DropInfo or {}).ActiveCount or 0
    local rewardCaption = rewardsButton:FindFirstChild("Caption") :: TextLabel
    rewardCaption.Text = if rewardCount > 0 then "RESGATES (" .. rewardCount .. ")" else "RESGATES"
    local accessPill = menuButtons.Auto:FindFirstChild("Planned") :: TextLabel
    accessPill.Text = if snapshot.Automation and (snapshot.Automation.CanThrow or snapshot.Automation.CanTrain) then "LIBERADO" else "TRANCADO"
    local currentBiomeLabel = room:FindFirstChild("Biome") :: TextLabel
    currentBiomeLabel.Text = if Config.Biomes[snapshot.CurrentBiome] then Config.Biomes[snapshot.CurrentBiome].Name elseif snapshot.CurrentBiome == "TradingPlaza" then "Praça local de trocas" else "Praça central"
    updateEvent()
    if currentPanel then
        local signature = getPanelSignature(snapshot)
        if signature ~= panelSignature then panelSignature = signature; renderPanel() end
        Gameplay.Update(content, state, actions)
        if Commerce.Update then Commerce.Update(content, state, actions) end
    end
    if not offlineShown and (snapshot.OfflineReward or 0) > 0 then
        offlineShown = true
        showNotice("BEM-VINDO DE VOLTA! +$" .. Numbers.Format(snapshot.OfflineReward) .. " gerados offline.")
    end
end)
feedback.OnClientEvent:Connect(function(message: any)
    if typeof(message) == "string" then showNotice(message)
    elseif typeof(message) == "table" and typeof(message.Message) == "string" then showNotice(message.Message, message.Kind == "Error") end
end)
throwResult.OnClientEvent:Connect(function(data: any)
    if typeof(data) ~= "table" then return end
    task.delay(data.PresentationDuration or 3, function() showRareCapture(data) end)
    if data.Thrower ~= player then return end
    if data.IsCritical then spawnFloatingNumber("CRÍTICO 1.5×!", C.Gold, 28) end
    if data.IsLongShot then spawnFloatingNumber("TIRO LONGO 1.25×!", C.Blue, 23) end
    if data.IsBossHit then
        showNotice(if data.BossDefeated then "CHEFE DERROTADO! Recompensa dos participantes liberada." else "ACERTO NO CHEFE! Continue reduzindo a resistência.")
        return
    end
    showNotice(if data.FlightId then "A ORBE CHEGOU! Revelando o encontro..." else "ORBE LANÇADA! Aguarde as balançadas...")
    task.delay(data.PresentationDuration or 3, function()
        local atLevelCap = (data.NewLevel or 1) >= Config.Constants.MaxLevel and not data.LeveledUp
        local gainedXP = if atLevelCap then 0 else data.XPGained or 0
        if gainedXP > 0 then spawnFloatingNumber("+" .. Numbers.Format(gainedXP) .. " XP!", C.Blue, 25) end
        if data.Captured then
            showNotice("CAPTURADO! " .. tostring(data.CreatureName or "Criatura") .. " • " .. tostring(data.MutationName or "Normal") .. " / " .. tostring(data.SizeName or "Normal"))
            if typeof(data.VariantBonus) == "table" then spawnFloatingNumber("BÔNUS DE VARIANTE!", C.Purple, 23) end
        elseif atLevelCap then showNotice("ESCAPOU! Nível máximo • +5% de sorte acumulada.")
        else showNotice("ESCAPOU! +" .. Numbers.Format(gainedXP) .. " XP e +5% de sorte acumulada.") end
        if (data.FragmentsGained or 0) > 0 then spawnFloatingNumber("+" .. Numbers.Format(data.FragmentsGained) .. " FRAGMENTOS", C.Purple, 22) end
        if data.LeveledUp then spawnFloatingNumber("NÍVEL " .. Numbers.Format(data.NewLevel or 1) .. "!", C.Gold, 32) end
    end)
end)

local function updateRoom()
    local count = #Players:GetPlayers()
    roomLabel.Text = "SALA · " .. count .. "/8"
end
Players.PlayerAdded:Connect(updateRoom)
Players.PlayerRemoving:Connect(function() task.defer(updateRoom) end)
updateRoom()
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
    if currentPanel and (input.KeyCode == Enum.KeyCode.ButtonB or input.KeyCode == Enum.KeyCode.Escape) then closePanel(); return end
    if not gui.Enabled or processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.C then openPanel("Criaturas")
    elseif input.KeyCode == Enum.KeyCode.V then openPanel("Orbes")
    elseif input.KeyCode == Enum.KeyCode.G then openPanel("Resgates")
    elseif input.KeyCode == Enum.KeyCode.B then openPanel("Bestiario")
    elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.ButtonY then openPanel("Menu") end
end)

local function resize()
    local width, height = root.AbsoluteSize.X, root.AbsoluteSize.Y
    if width <= 0 or height <= 0 then return end
    compact = width < 980 or height < 430
    portrait = width < height
    local standardScale = if height < 620 then 0.86 else 1
    heading.Visible = false
    dataMode.Visible = false
    leftMenu.Visible = false
    navigation.Visible = true
    navigation.Position = UDim2.fromOffset(10, 4)
    leftScale.Scale = standardScale
    rightScale.Scale = if compact then 0.78 else standardScale
    rightMenu.Size = if compact then UDim2.fromOffset(176, 68) else UDim2.fromOffset(82, 308)
    rightMenu.Position = if compact then UDim2.new(1, -10, 0, 84) else UDim2.new(1, -12, 0, 92)
    for index, id in {"Criaturas", "Orbes", "Auto", "Codigos"} do
        menuButtons[id].Visible = not compact or index <= 2
        menuButtons[id].Position = if compact then UDim2.fromOffset((index - 1) * 94, 0) else UDim2.fromOffset(0, (index - 1) * 78)
    end
    statsScale.Scale = if compact then 0.59 else 0.76
    stats.AnchorPoint = if compact then Vector2.new(0, 0) else Vector2.new(0, 1)
    stats.Position = if compact then UDim2.fromOffset(10, 58) else UDim2.new(0, 12, 1, -12)
    local targetWidth = if compact then math.min(430, width - 32) else 460 * standardScale
    hotbarScale.Scale = targetWidth / 460
    hotbar.Size = UDim2.fromOffset(460, if compact then 72 else 58)
    trainButton.Size = UDim2.fromOffset(92, if compact then 44 / hotbarScale.Scale else 36)
    swapButton.Size = UDim2.fromOffset(104, if compact then 44 / hotbarScale.Scale else 36)
    local bottom = if compact and portrait then 160 else 12
    hotbar.Position = UDim2.new(0.5, 0, 1, -bottom)
    notice.Position = UDim2.new(0.5, 0, 1, -bottom - 94 * hotbarScale.Scale)
    notice.Size = UDim2.new(if compact then 0.9 else 0.65, 0, 0, if compact then 35 else 42)
    notice.TextSize = if compact then 12 else 15
    event.Size = UDim2.fromOffset(176, 24)
    eventTitle.TextSize = if compact and portrait then 10 else 13
    updateEvent()
    room.Visible = not compact and width > 1000
    modal.Size = if compact then UDim2.new(1, -16, 1, -16) else UDim2.fromScale(0.9, 0.86)
    modalTitle.TextSize = if compact then 20 else 25
    banner.Size = UDim2.fromOffset(math.min(470, width - 24), 58)
    if currentPanel then renderPanel() end
end
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize()
task.defer(resize)
task.spawn(function()
    while gui.Parent do
        task.wait(0.25)
        updateEvent()
        if currentPanel then
            Gameplay.Update(content, state, actions)
            if Commerce.Update then Commerce.Update(content, state, actions) end
        end
    end
end)
local worldStateUpdate = remotes:FindFirstChild("WorldStateUpdate")
if worldStateUpdate and worldStateUpdate:IsA("RemoteEvent") then worldStateUpdate.OnClientEvent:Connect(function(weather: any)
    if typeof(weather) == "table" then worldWeather = weather; if state then state.Weather = weather end; updateEvent() end
end) end
local openPanelRemote = remotes:WaitForChild("OpenPanel") :: RemoteEvent
local allowedPanels = {Menu = true, Bestiario = true, Loja = true, Fusao = true, Diario = true, Rebirth = true,
    Ranking = true, Criaturas = true, Orbes = true, Auto = true, Codigos = true, Biomas = true,
    Academia = true, Resgates = true, Missoes = true, Consumiveis = true, GrupoVIP = true, Trocas = true, Leiloes = true,
    VitrineOrbes = true}
openPanelRemote.OnClientEvent:Connect(function(panelId: any)
    if typeof(panelId) ~= "string" or not allowedPanels[panelId] then return end
    -- A station prompt requests an open panel, rather than toggling it closed.
    if currentPanel == panelId then return end
    openPanel(panelId)
end)
requestState:FireServer()
