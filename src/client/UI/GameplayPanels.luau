--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local meshFolder = Shared:WaitForChild("CreatureMeshes")
local Rewards = require(Shared:WaitForChild("ConfigRecompensas"))
local Progression = require(Shared:WaitForChild("ConfigProgression"))
local Numbers = require(Shared:WaitForChild("NumberFormatter"))
local W = require(script.Parent:WaitForChild("HUDWidgets"))
local Icons = require(script.Parent:WaitForChild("HUDIcons"))
local C = W.Colors
local View = {}
local names = {PotionLuck2 = "Poção 2× Sorte", PotionCoins2 = "Poção 2× Moedas", PotionLuck3 = "Poção 3× Sorte", PotionCoins3 = "Poção 3× Moedas", GlobalLuckTotem = "Totem Global 5× Sorte", SummonEvent = "Invocar evento", SkipFusion = "Pular recarga de fusão", SanctuarySlot = "+1 espaço no santuário"}
local biomeOrder = {"PradariaSolar", "FlorestaNeon", "CanionVulcanico", "AbismoGlacial", "RuinasAncestrais", "VazioCosmico"}
local missionOrder = {"Capture15", "Critical3", "Fusion1"}

local function caption(button: TextButton, text: string)
    local label = button:FindFirstChild("Caption")
    if label and label:IsA("TextLabel") then label.Text = text end
end
function View.Time(seconds: number): string
    local amount = math.max(0, math.ceil(seconds))
    if amount >= 3600 then return string.format("%dh %02dm", math.floor(amount / 3600), math.floor(amount % 3600 / 60)) end
    return string.format("%02d:%02d", math.floor(amount / 60), amount % 60)
end
local function now(): number return Workspace:GetServerTimeNow() end
local function hint(parent: Instance, text: string, y: number?): TextLabel
    local label = W.Label(parent, "Hint", text, UDim2.fromOffset(4, y or 0), UDim2.new(1, -8, 0, 42), 12, C.Muted, true)
    label.TextWrapped = true
    return label
end
local function card(parent: Instance, id: string, height: number, color: Color3): Frame
    local row = W.Frame(parent, id, UDim2.new(), UDim2.new(1, -2, 0, height), C.Card)
    W.Gradient(row, color:Lerp(C.Ink, 0.7), C.Panel)
    return row
end
local function heading(row: Frame, text: string, detail: string, icon: string, color: Color3)
    local host = Instance.new("Frame")
    host.Name = "Pictogram"
    host.Position = UDim2.fromOffset(10, 9)
    host.Size = UDim2.fromOffset(40, 40)
    host.BackgroundTransparency = 1
    host.Parent = row
    Icons.Draw(host, icon, color)
    local title = W.Label(row, "Name", text, UDim2.fromOffset(61, 8), UDim2.new(1, -73, 0, 24), 17, color)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    local description = W.Label(row, "Description", detail, UDim2.fromOffset(61, 32), UDim2.new(1, -73, 0, 44), 11, C.White, true)
    description.TextWrapped = true
    description.TextYAlignment = Enum.TextYAlignment.Top
end
function View.Tabs(parent: GuiObject, entries: {any}, selected: string, choose: (string) -> ())
    for index, item in entries do
        local button = W.Button(parent, "Tab_" .. item.Id, item.Name, UDim2.new((index - 1) / #entries, 3, 0, 0), UDim2.new(1 / #entries, -6, 0, 44), if selected == item.Id then C.Gold else C.Purple, 11)
        button.Activated:Connect(function() choose(item.Id) end)
    end
end
local function panelBody(parent: GuiObject, name: string, top: number): Frame
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = UDim2.fromOffset(0, top)
    frame.Size = UDim2.new(1, 0, 1, -top)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    return frame
end
function View.RewardText(reward: any, level: number?): string
    local parts = {}
    if reward.Coins then table.insert(parts, "$" .. Numbers.Format(reward.Coins * (if reward.ScaleCoinsWithLevel then level or 1 else 1))) end
    if reward.XP then table.insert(parts, "+" .. Numbers.Format(reward.XP) .. " XP base") end
    if reward.Gems then table.insert(parts, "+" .. reward.Gems .. " gemas") end
    for id, count in reward.Orbs or {} do table.insert(parts, count .. "× " .. (if Config.Orbs[id] then Config.Orbs[id].Name else id)) end
    for id, count in reward.Consumables or {} do table.insert(parts, count .. "× " .. (names[id] or id)) end
    if reward.Creature and meshFolder:FindFirstChild(reward.Creature.Id) then
        table.insert(parts, Config.Creatures[reward.Creature.Id].Name .. " • " .. reward.Creature.Mutation)
    end
    if reward.WeeklyPets then table.insert(parts, "+1 companheiro semanal cosmético") end
    if reward.Titles then table.insert(parts, "Título Fiel") end
    return table.concat(parts, " • ")
end
local function rewardButton(row: Frame, name: string, text: string, send: () -> (), color: Color3?): TextButton
    local button = W.Button(row, name, text, UDim2.fromOffset(12, 90), UDim2.new(1, -24, 0, 44), color or C.Green, 12)
    button.Activated:Connect(send)
    return button
end

local function renderDaily(parent: GuiObject, state: any, actions: any)
    local daily = state and state.Rewards and state.Rewards.Daily or {NextDay = 1, CanClaim = false, NextClaimAt = 0}
    hint(parent, if (daily.NextClaimAt or 0) > now() then "Próximo resgate: " .. os.date("!%d/%m %H:%M UTC", daily.NextClaimAt) .. " • A cada 24 h." else "Um resgate a cada 24 h. Após 48 h sem resgatar, a sequência volta ao dia 1.")
    local list = W.List(parent, "DailyList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, reward in Rewards.Daily do
        local row = card(list, "Daily_" .. index, 146, if index == daily.NextDay then C.Gold else C.Purple)
        row.LayoutOrder = index
        heading(row, "DIA " .. index, View.RewardText(reward, state and state.Level or 1), "Gift", if index == 7 then C.Pink else C.Gold)
        local button = rewardButton(row, "ClaimDaily", "AGUARDANDO DIA " .. index, function() actions.Send("ClaimDailyReward") end)
        if index == daily.NextDay then
            button:SetAttribute("DailyClaim", true)
        else
            button.Active, button.Selectable = false, false
            caption(button, if state and index <= (state.DailyStreak or 0) and daily.NextDay ~= 1 then "RECEBIDO NESTE CICLO" else "AGUARDANDO DIA " .. index)
        end
    end
end
local function renderPlaytime(parent: GuiObject, state: any, actions: any)
    local timeLabel = hint(parent, "TEMPO ONLINE HOJE: 00:00 • Reinicia à meia-noite UTC.")
    timeLabel:SetAttribute("OnlineTime", true)
    local list = W.List(parent, "PlaytimeList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, reward in Rewards.Playtime do
        local row = card(list, "Playtime_" .. index, 146, C.Blue)
        row.LayoutOrder = index
        heading(row, "PRESENTE • " .. math.floor(reward.Seconds / 60) .. " MIN", View.RewardText(reward, state and state.Level or 1), "Gift", C.Blue)
        local button = rewardButton(row, "ClaimPlaytime", "AGUARDE", function() actions.Send("ClaimPlaytimeReward", index) end)
        button:SetAttribute("PlaytimeClaim", index)
    end
end
local function renderMissions(parent: GuiObject, state: any, actions: any)
    local missionState = state and state.Rewards and state.Rewards.Missions or {}
    hint(parent, if missionState.Unlocked then "Missões diárias • Progresso validado no servidor • Reiniciam à meia-noite UTC." else "MISSÕES BLOQUEADAS • Alcance o nível 5 para começar.")
    local list = W.List(parent, "MissionList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, id in missionOrder do
        local mission = Rewards.Missions[id]
        local count = math.min(mission.Target, (missionState.Counters or {})[mission.Counter] or 0)
        local claimed = (missionState.Claimed or {})[id] == true
        local row = card(list, id, 146, C.Green)
        row.LayoutOrder = index
        heading(row, mission.Name .. "  " .. count .. "/" .. mission.Target, mission.OrbQuantity .. " orbes do bioma atual • " .. mission.XP .. " XP base • " .. mission.Gems .. " gemas", if id == "Critical3" then "Bolt" elseif id == "Fusion1" then "Fusion" else "Paw", C.Green)
        local requiredLevel = mission.RequiredLevel or Rewards.MissionLevel
        local levelReady = state and (state.Level or 1) >= requiredLevel
        local ready = missionState.Unlocked and levelReady and count >= mission.Target and not claimed
        local button = rewardButton(row, "ClaimMission", if claimed then "RECEBIDO" elseif not levelReady then "EXIGE NÍVEL " .. requiredLevel elseif ready then "RESGATAR" else "COMPLETE O OBJETIVO", function() actions.Send("ClaimMissionReward", id) end)
        button.Active, button.Selectable = ready == true, ready == true
    end
end
local function renderConsumables(parent: GuiObject, state: any, actions: any)
    hint(parent, "Poções iguais estendem o tempo. Uma inferior não substitui uma mais forte ativa.")
    local list = W.List(parent, "ConsumableList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    local order = {"PotionLuck2", "PotionCoins2", "PotionLuck3", "PotionCoins3", "GlobalLuckTotem", "SummonEvent", "SkipFusion", "SanctuarySlot"}
    for index, id in order do
        local item = Rewards.Consumables[id]
        local quantity = state and (state.Consumables or {})[id] or 0
        local description = if item.Stat then tostring(item.Multiplier) .. "× " .. (if item.Stat == "Luck" then "sorte" else "moedas") .. " por " .. View.Time(item.Duration)
            elseif id == "GlobalLuckTotem" then "5× sorte global por 15 min. Beneficia todos nesta sala."
            elseif id == "SummonEvent" then "Invoca um evento climático quando o servidor permitir."
            elseif id == "SanctuarySlot" then "Libera um espaço adicional. No limite de 24, o token é preservado."
            else "Remove a recarga restante da máquina de fusão."
        local row = card(list, id, 166, C.Purple)
        row.LayoutOrder = index
        heading(row, (names[id] or id) .. "  ×" .. Numbers.Format(quantity), description, if id == "SkipFusion" then "Fusion" else "Cosmic", C.Purple)
        local boost = item.Stat and state and (state.Boosts or {})[item.Stat]
        local clock = W.Label(row, "ActiveBoost", "", UDim2.fromOffset(14, 76), UDim2.new(1, -28, 0, 22), 11, C.Gold, true)
        if boost and boost.ExpiresAt > now() then
            clock:SetAttribute("ClockAt", boost.ExpiresAt)
            clock:SetAttribute("ClockPrefix", "Ativo " .. boost.Multiplier .. "×: ")
            clock:SetAttribute("ClockReadyText", "Boost encerrado")
        else clock.Text = if item.Stat then "Nenhum boost desta categoria ativo" else "Consumível de uso único" end
        local button = rewardButton(row, "Use", if quantity > 0 then "USAR CONSUMÍVEL" else "SEM ESTOQUE", function() actions.Send("UseConsumable", id) end)
        button.Position = UDim2.fromOffset(12, 108)
        button.Active, button.Selectable = quantity > 0, quantity > 0
    end
end
local function renderRewards(parent: GuiObject, state: any, actions: any)
    local selected = actions.Session.RewardsTab or "Daily"
    View.Tabs(parent, {{Id = "Daily", Name = "7 DIAS"}, {Id = "Playtime", Name = "PRESENTES"}, {Id = "Missions", Name = "MISSÕES"}, {Id = "Consumables", Name = "ITENS"}}, selected, function(id)
        actions.Session.RewardsTab = id; actions.Refresh()
    end)
    local body = panelBody(parent, "RewardBody", 52)
    if selected == "Playtime" then renderPlaytime(body, state, actions)
    elseif selected == "Missions" then renderMissions(body, state, actions)
    elseif selected == "Consumables" then renderConsumables(body, state, actions)
    else renderDaily(body, state, actions) end
end
local function renderRebirth(parent: GuiObject, state: any, actions: any)
    local profile = state or {}
    local canRebirth = profile.Progression and profile.Progression.CanRebirth == true
    if not canRebirth then actions.Session.RebirthConfirmed = false end
    local confirm = actions.Session.RebirthConfirmed == true
    local list = W.List(parent, "RebirthList", UDim2.new(), UDim2.fromScale(1, 1))
    local row = card(list, "RebirthPreview", if confirm then 390 else 350, if confirm then C.Pink else C.Green)
    heading(row, if confirm then "CONFIRME SEU REBIRTH" else "RENASCER • NÍVEL 40", "+5 gemas e +1 rebirth: +100% renda, +50% sorte e +50% XP permanentes por rebirth.", "Rebirth", if confirm then C.Pink else C.Green)
    local details = W.Label(row, "ResetPreview", "VAI REINICIAR\nMoedas: $" .. Numbers.Format(profile.Coins or 0) .. " → $150\nNível " .. Numbers.Format(profile.Level or 1) .. " → 1 • XP → 0\nBiomas liberados → apenas Pradaria Solar\n\nVOCÊ MANTÉM\nForça, orbes, criaturas, bestiário, compras e resgates.", UDim2.fromOffset(16, 86), UDim2.new(1, -32, 0, 170), 13, C.White, true)
    details.TextWrapped = true
    details.TextYAlignment = Enum.TextYAlignment.Top
    local button = W.Button(row, "RebirthAction", if not canRebirth then "EXIGE NÍVEL 40" elseif confirm then "CONFIRMAR REBIRTH E REINICIAR" else "REVISAR REBIRTH", UDim2.fromOffset(14, 270), UDim2.new(1, -28, 0, 48), if confirm then C.Pink else C.Green, 12)
    button.Active, button.Selectable = canRebirth == true, canRebirth == true
    button.Activated:Connect(function()
        if confirm then actions.Session.RebirthConfirmed = false; actions.Send("RebirthRequest")
        else actions.Session.RebirthConfirmed = true; actions.Refresh() end
    end)
    if confirm then
        local cancel = W.Button(row, "CancelRebirth", "VOLTAR SEM REINICIAR", UDim2.fromOffset(14, 329), UDim2.new(1, -28, 0, 44), C.Blue, 12)
        cancel.Activated:Connect(function() actions.Session.RebirthConfirmed = false; actions.Refresh() end)
    end
end
local function renderFusion(parent: GuiObject, state: any, actions: any)
    local profile = state or {}
    local fusion = profile.Fusion or {RequiredCount = 5, ReadyAt = 0, Unlocked = false}
    local selected = actions.Session.FusionSelected or {}
    actions.Session.FusionSelected = selected
    local captures = profile.CapturedCreatures or {}
    local exists, count, reference = {}, 0, nil
    for _, record in captures do
        exists[record.Uid] = true
        if selected[record.Uid] then
            if count < fusion.RequiredCount then count += 1; reference = reference or record else selected[record.Uid] = nil end
        end
    end
    for uid in selected do if not exists[uid] then selected[uid] = nil end end
    hint(parent, if fusion.Unlocked then "Selecione a mesma espécie, mutação e tamanho. A fusão consome as criaturas selecionadas." else "A máquina de fusão desbloqueia no nível 10.")
    local fuse = W.Button(parent, "FuseSelected", "FUNDIR " .. count .. "/" .. fusion.RequiredCount, UDim2.fromOffset(4, 48), UDim2.new(0.66, -8, 0, 44), C.Purple, 12)
    fuse:SetAttribute("FusionAction", true)
    fuse:SetAttribute("SelectionCount", count)
    fuse.Activated:Connect(function()
        local ids = {}
        for _, record in (actions.GetState() or {}).CapturedCreatures or {} do if selected[record.Uid] then table.insert(ids, record.Uid) end end
        actions.Send("FuseCreatures", ids)
    end)
    local clear = W.Button(parent, "ClearFusion", "LIMPAR", UDim2.new(0.66, 4, 0, 48), UDim2.new(0.34, -8, 0, 44), C.Blue, 12)
    clear.Activated:Connect(function() actions.Session.FusionSelected = {}; actions.Refresh() end)
    local status = W.Label(parent, "FusionStatus", "Normal → Dourada 3× • Dourada → Cristal 6× • Cristal → Arco-Íris 15×", UDim2.fromOffset(5, 96), UDim2.new(1, -10, 0, 32), 10, C.Muted, true)
    status.TextWrapped = true
    local list = W.List(parent, "FusionList", UDim2.fromOffset(0, 132), UDim2.new(1, 0, 1, -132))
    if #captures == 0 then hint(list, "Capture criaturas para começar sua primeira fusão."); return end
    for index, record in captures do
        if Progression.FusionRecipes[record.Mutation] then
            local definition = Config.Creatures[record.CreatureId]
            local compatible = not reference or (record.CreatureId == reference.CreatureId and record.Mutation == reference.Mutation and record.Size == reference.Size)
            local row = card(list, record.Uid, 130, if selected[record.Uid] then C.Gold else C.Purple)
            row.LayoutOrder = index
            heading(row, if definition then definition.Name else record.CreatureId, record.Mutation .. " • " .. record.Size .. " • $" .. Numbers.Format(record.IncomePerSec) .. "/s", "Paw", if selected[record.Uid] then C.Gold else C.White)
            local toggle = W.Button(row, "Select", if selected[record.Uid] then "SELECIONADA • RETIRAR" elseif compatible then "SELECIONAR" else "COMBINAÇÃO DIFERENTE", UDim2.fromOffset(12, 78), UDim2.new(1, -24, 0, 44), if selected[record.Uid] then C.Gold else C.Blue, 11)
            toggle.Active, toggle.Selectable = fusion.Unlocked == true and compatible, fusion.Unlocked == true and compatible
            toggle.Activated:Connect(function()
                if selected[record.Uid] then selected[record.Uid] = nil
                elseif count >= fusion.RequiredCount then actions.Notify("A seleção já está completa."); return
                else selected[record.Uid] = true end
                actions.Refresh()
            end)
        end
    end
end
local function renderAuto(parent: GuiObject, state: any, actions: any)
    hint(parent, "As permissões são verificadas pelo servidor. Auto-Treino só funciona dentro do seu santuário.")
    local automation = state and state.Automation or {}
    local list = W.List(parent, "AutomationList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, item in {{Id = "Throw", Name = "Auto-Arremesso", Permission = "CanThrow", Description = "Usa seu estoque e mira em criaturas acessíveis no bioma atual.", Icon = "Orb"},
        {Id = "Train", Name = "Auto-Treino", Permission = "CanTrain", Description = "Treina na base com o mesmo intervalo do treino manual.", Icon = "Bolt"},
        {Id = "Fusion", Name = "Auto-Fusão", Permission = "CanFusion", Description = "Funde comuns normais não equipadas. Exige Mega Coletor.", Icon = "Fusion"}} do
        local available, enabled = automation[item.Permission] == true, automation[item.Id] == true
        local row = card(list, item.Id, 146, if available then C.Green else C.Purple)
        row.LayoutOrder = index
        heading(row, item.Name, item.Description, item.Icon, if available then C.Green else C.Gold)
        local button = rewardButton(row, "Toggle", if not available then "ACESSO INDISPONÍVEL • VER GRUPO/PASSES" elseif enabled then "ATIVADO • DESATIVAR" else "DESATIVADO • ATIVAR", function()
            if not available then actions.Open("GrupoVIP")
            else local latest = actions.GetState(); actions.Send("SetAutoMode", item.Id, not (latest and latest.Automation and latest.Automation[item.Id])) end
        end, if enabled then C.Orange else C.Green)
    end
end
local function renderCodes(parent: GuiObject, state: any, actions: any)
    local list = W.List(parent, "CodeList", UDim2.new(), UDim2.fromScale(1, 1))
    local row = card(list, "RedeemCode", 260, C.Purple)
    heading(row, "CÓDIGOS OFICIAIS", if next(Rewards.Codes) == nil then "Nenhum código ativo no momento. Não há prêmios fictícios neste campo." else "Digite um código oficial. Cada código pode ser resgatado uma vez por perfil.", "Ticket", C.Purple)
    local input = Instance.new("TextBox")
    input.Name = "CodeInput"
    input.Position = UDim2.fromOffset(14, 94)
    input.Size = UDim2.new(1, -28, 0, 48)
    input.BackgroundColor3 = C.Ink
    input.TextColor3 = C.White
    input.PlaceholderColor3 = C.Muted
    input.PlaceholderText = "Digite seu código"
    input.Text = actions.Session.CodeText or ""
    input.TextSize = 17
    input.Font = Enum.Font.GothamBold
    input.ClearTextOnFocus = false
    input.Parent = row
    W.Round(input, 10)
    W.Outline(input, 2, C.Purple)
    input:GetPropertyChangedSignal("Text"):Connect(function()
        if #input.Text > 64 then input.Text = input.Text:sub(1, 64) end
        actions.Session.CodeText = input.Text
    end)
    local redeem = W.Button(row, "Redeem", "RESGATAR CÓDIGO", UDim2.fromOffset(14, 158), UDim2.new(1, -28, 0, 48), C.Green, 13)
    redeem.Activated:Connect(function() actions.Send("RedeemCode", input.Text) end)
    local detail = W.Label(row, "CodePrivacy", "Sem diferença entre maiúsculas e minúsculas.", UDim2.fromOffset(14, 216), UDim2.new(1, -28, 0, 30), 11, C.Muted, true)
    detail.TextWrapped = true
end
local function renderBiomes(parent: GuiObject, state: any, actions: any)
    local profile = state or {}
    hint(parent, "Desbloqueios usam moedas e descobertas do Bestiário. A viagem é validada no servidor.")
    local list = W.List(parent, "BiomeList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, id in biomeOrder do
        local definition = Config.Biomes[id]
        local unlocked = id == "PradariaSolar" or (profile.UnlockedBiomes or {})[id]
        local row = card(list, id, 146, if unlocked then C.Green else C.Blue)
        row.LayoutOrder = index
        heading(row, definition.Name, "Nível " .. definition.RequiredLevel .. " • " .. definition.RequiredBestiary .. " espécies • " .. (if definition.Cost == 0 then "Grátis" else "$" .. Numbers.Format(definition.Cost)), "Earth", if unlocked then C.Green else C.Gold)
        local current = profile.CurrentBiome == id
        local button = rewardButton(row, "Travel", if current then "VOCÊ ESTÁ AQUI" elseif unlocked then "VIAJAR" else "DESBLOQUEAR POR $" .. Numbers.Format(definition.Cost), function()
            actions.Send(if unlocked then "TravelToBiome" else "UnlockBiome", id)
        end)
        button.Active, button.Selectable = not current, not current
    end
    local plaza = card(list, "TradingPlaza", 146, C.Pink)
    plaza.LayoutOrder = 20
    local localPlaza = not Config.Gameplay or Config.Gameplay.TradingPlaceId == 0
    heading(plaza, if localPlaza then "PRAÇA LOCAL DE TROCAS" else "TRADING PLAZA", "Exige nível 15 • Trocas em duas confirmações e leilões por moedas.", "Shop", C.Pink)
    local travel = rewardButton(plaza, "TravelPlaza", if (profile.Level or 1) >= 15 then "IR À PRAÇA DE TROCAS" else "EXIGE NÍVEL 15", function() actions.Send("TravelToBiome", "TradingPlaza") end)
    travel.Active, travel.Selectable = (profile.Level or 1) >= 15, (profile.Level or 1) >= 15
    local hub = card(list, "Hub", 104, C.Gold)
    hub.LayoutOrder = 21
    local returnButton = W.Button(hub, "ReturnHub", "VOLTAR À PRAÇA CENTRAL", UDim2.fromOffset(14, 28), UDim2.new(1, -28, 0, 48), C.Gold, 13)
    returnButton.Activated:Connect(function() actions.Send("TravelToBiome", "Hub") end)
end
local function renderBestiaryRewards(parent: GuiObject, state: any, actions: any)
    hint(parent, "Uma recompensa por bioma completo: +10% sorte permanente, moedas e título de coleção.")
    local list = W.List(parent, "BestiaryRewardsList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    for index, id in biomeOrder do
        local total, discovered = 0, 0
        for creatureId, definition in Config.Creatures do
            if definition.Biome ~= id or not meshFolder:FindFirstChild(creatureId) then continue end
            total += 1
            if state and (state.Bestiary or {})[creatureId] then discovered += 1 end
        end
        local claimed = state and (state.BestiaryRewardClaimed or {})[id]
        local row = card(list, id, 146, C.Gold)
        row.LayoutOrder = index
        heading(row, Config.Biomes[id].Name .. "  " .. discovered .. "/" .. total, "+10% sorte • $" .. Numbers.Format(Rewards.BestiaryCoins[id]) .. " • Título de coleção", "Book", C.Gold)
        local ready = total > 0 and discovered >= total and not claimed
        local button = rewardButton(row, "ClaimBestiary", if claimed then "RECEBIDO" elseif ready then "RESGATAR BÔNUS PERMANENTE" else "COMPLETE ESTE BESTIÁRIO", function() actions.Send("ClaimBestiaryReward", id) end)
        button.Active, button.Selectable = ready == true, ready == true
    end
end
local function renderRanking(parent: GuiObject, state: any, actions: any)
    local board = state and state.Leaderboards or {Mode = "Session", Boards = {}}
    local selected = actions.Session.RankingMetric or "Coins"
    View.Tabs(parent, {{Id = "Coins", Name = "MOEDAS"}, {Id = "Capture", Name = "CAPTURA"}, {Id = "Level", Name = "NÍVEL"}, {Id = "Bestiary", Name = "BESTIÁRIO"}}, selected, function(id) actions.Session.RankingMetric = id; actions.Refresh() end)
    local body = panelBody(parent, "RankingBody", 52)
    hint(body, if board.Mode == "Global" then "Ranking global • Valores sincronizados periodicamente; ordenação aproximada em números gigantes." elseif board.Mode == "SessionFallback" then "Ranking desta sala • Dados globais temporariamente indisponíveis." else "Ranking desta sala • Atualização periódica do servidor.")
    local list = W.List(body, "LeaderboardList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
    local entries = (board.Boards or {})[selected] or {}
    if #entries == 0 then hint(list, "Aguardando a primeira atualização do placar..."); return end
    for index, entry in entries do
        local value = if selected == "Coins" then "$" .. Numbers.Format(entry.Coins) elseif selected == "Capture" then "$" .. Numbers.Format(entry.Capture) .. "/s" elseif selected == "Level" then "NV. " .. Numbers.Format(entry.ActualLevel or 1) .. " • " .. Numbers.Format(entry.Rebirths or 0) .. " rebirths" else Numbers.Format(entry.Bestiary) .. " espécies descobertas"
        local row = card(list, "Rank_" .. index, 91, if index == 1 then C.Gold else C.Blue)
        row.LayoutOrder = index
        heading(row, "#" .. index .. "  " .. entry.DisplayName, value, "Trophy", if index == 1 then C.Gold else C.Blue)
    end
end

function View.Handles(kind: string): boolean
    return ({Diario = true, Consumiveis = true, Fusao = true, Rebirth = true, Auto = true, Codigos = true, Biomas = true, BestiarioRewards = true, Ranking = true})[kind] == true
end
function View.Render(parent: GuiObject, kind: string, state: any, actions: any)
    if kind == "Diario" then renderRewards(parent, state, actions)
    elseif kind == "Consumiveis" then renderConsumables(parent, state, actions)
    elseif kind == "Fusao" then renderFusion(parent, state, actions)
    elseif kind == "Rebirth" then renderRebirth(parent, state, actions)
    elseif kind == "Auto" then renderAuto(parent, state, actions)
    elseif kind == "Codigos" then renderCodes(parent, state, actions)
    elseif kind == "Biomas" then renderBiomes(parent, state, actions)
    elseif kind == "BestiarioRewards" then renderBestiaryRewards(parent, state, actions)
    elseif kind == "Ranking" then renderRanking(parent, state, actions) end
    View.Update(parent, state, actions)
end
function View.Update(parent: GuiObject, state: any, actions: any)
    if not state then return end
    local timestamp = now()
    local rewards = state.Rewards or {}
    for _, object in parent:GetDescendants() do
        if object:IsA("TextLabel") and object:GetAttribute("ClockAt") then
            local left = object:GetAttribute("ClockAt") - timestamp
            object.Text = if left > 0 then (object:GetAttribute("ClockPrefix") or "") .. View.Time(left) else object:GetAttribute("ClockReadyText") or "PRONTO"
        elseif object:IsA("TextLabel") and object:GetAttribute("OnlineTime") then
            local seconds = ((rewards.Playtime or {}).Seconds or 0) + actions.Elapsed()
            object.Text = "ONLINE HOJE: " .. View.Time(seconds) .. " • Reinicia à meia-noite UTC."
        elseif object:IsA("TextButton") and object:GetAttribute("DailyClaim") then
            local daily = rewards.Daily or {}
            local left = (daily.NextClaimAt or 0) - timestamp
            local ready = daily.CanClaim == true or (daily.NextClaimAt or 0) > 0 and left <= 0
            caption(object, if ready then "RESGATAR DIA " .. (daily.NextDay or 1) else "PRÓXIMO RESGATE EM " .. View.Time(left))
            object.Active, object.Selectable = ready, ready
        elseif object:IsA("TextButton") and object:GetAttribute("PlaytimeClaim") then
            local id = object:GetAttribute("PlaytimeClaim")
            local played = rewards.Playtime or {}
            local claimed = (played.Claimed or {})[tostring(id)] == true
            local left = Rewards.Playtime[id].Seconds - ((played.Seconds or 0) + actions.Elapsed())
            local ready = not claimed and left <= 0
            caption(object, if claimed then "RECEBIDO HOJE" elseif ready then "RESGATAR PRESENTE" else "LIBERA EM " .. View.Time(left))
            object.Active, object.Selectable = ready, ready
        elseif object:IsA("TextButton") and object:GetAttribute("FusionAction") then
            local fusion = state.Fusion or {}
            local left = (fusion.ReadyAt or 0) - timestamp
            local selected = object:GetAttribute("SelectionCount") or 0
            local count = fusion.RequiredCount or 5
            local ready = fusion.Unlocked == true and left <= 0 and selected == count
            caption(object, if not fusion.Unlocked then "NÍVEL 10 NECESSÁRIO" elseif left > 0 then "RECARGA " .. View.Time(left) else "FUNDIR " .. selected .. "/" .. count)
            object.Active, object.Selectable = ready, ready
        end
    end
end

local function stable(value: any): string
    if type(value) ~= "table" then return tostring(value) end
    local keys = {}
    for key in value do table.insert(keys, key) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    local parts = {}
    for _, key in keys do table.insert(parts, tostring(key) .. "=" .. stable(value[key])) end
    return "{" .. table.concat(parts, ";") .. "}"
end
View.Stable = stable
function View.Signature(kind: string, state: any): string
    if not state then return "loading" end
    if kind == "Diario" then
        local rewards = state.Rewards or {}
        return stable({Level = state.Level, Daily = rewards.Daily, Claims = (rewards.Playtime or {}).Claimed, Day = (rewards.Playtime or {}).DayKey, Missions = rewards.Missions, Consumables = state.Consumables, Boosts = state.Boosts})
    elseif kind == "Fusao" then return stable({Level = state.Level, Fusion = state.Fusion, Captures = state.CapturedCreatures})
    elseif kind == "Rebirth" then return stable({Level = state.Level, Rebirths = state.Rebirths, Progression = state.Progression})
    elseif kind == "Auto" then return stable(state.Automation)
    elseif kind == "Codigos" then return "codes"
    elseif kind == "Consumiveis" then return stable({Consumables = state.Consumables, Boosts = state.Boosts})
    elseif kind == "Biomas" then return stable({Level = state.Level, Unlocked = state.UnlockedBiomes, Bestiary = state.Bestiary, CurrentBiome = state.CurrentBiome})
    elseif kind == "Ranking" then return stable(state.Leaderboards)
    elseif kind == "BestiarioRewards" then return stable({Bestiary = state.Bestiary, Claimed = state.BestiaryRewardClaimed}) end
    return kind
end
return View
