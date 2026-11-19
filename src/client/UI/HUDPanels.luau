--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local meshFolder = Shared:WaitForChild("CreatureMeshes")
local GameplayMath = require(Shared:WaitForChild("GameplayMath"))
local Numbers = require(Shared:WaitForChild("NumberFormatter"))
local W = require(script.Parent:WaitForChild("HUDWidgets"))
local Icons = require(script.Parent:WaitForChild("HUDIcons"))
local Gameplay = require(script.Parent:WaitForChild("GameplayPanels"))
local OrbVisual = require(script.Parent.Parent:WaitForChild("Throw"):WaitForChild("OrbVisual"))
local C = W.Colors

local Panels = {}
Panels.Machines = require(Shared:WaitForChild("ConfigTraining")).Machines
Panels.OrbOrder = {"Comum", "Esmeralda", "Rubi", "Safira", "Runica", "Hextech", "Cosmica", "Mestre"}
Panels.MenuItems = {
    {Id = "Bestiario", Icon = "Book", Name = "Bestiário", Color = C.Blue},
    {Id = "Loja", Icon = "Shop", Name = "Loja Robux", Color = C.Pink},
    {Id = "Fusao", Icon = "Fusion", Name = "Fusão", Color = C.Purple},
    {Id = "Diario", Icon = "Gift", Name = "Presentes", Color = C.Gold},
    {Id = "Rebirth", Icon = "Rebirth", Name = "Rebirth", Color = C.Green},
    {Id = "Ranking", Icon = "Trophy", Name = "Ranking", Color = C.Orange},
    {Id = "Criaturas", Icon = "Paw", Name = "Criaturas", Color = C.Green},
    {Id = "Orbes", Icon = "Orb", Name = "Orbes", Color = C.Blue},
    {Id = "Auto", Icon = "Bolt", Name = "Auto", Color = C.Gold},
    {Id = "Codigos", Icon = "Ticket", Name = "Códigos", Color = C.Purple},
}
Panels.Titles = {
    Bestiario = "BESTIÁRIO", Loja = "LOJA ROBUX", Fusao = "FUSÃO 5 → 1", Diario = "DIÁRIO & PRESENTES",
    Rebirth = "REBIRTH", Ranking = "PLACARES", Criaturas = "MINHAS CRIATURAS", Orbes = "EVOLUÇÃO DE ORBES",
    Auto = "AUTO-ARREMESSO", Codigos = "CÓDIGOS", Menu = "EXPLORE SEU SANTUÁRIO",
    Biomas = "BIOMAS & PRAÇA DE TROCAS", GrupoVIP = "GRUPO & VIP", Trocas = "TROCAS SEGURAS", Leiloes = "LEILÕES POR MOEDAS",
    Consumiveis = "CONSUMÍVEIS & POÇÕES", Academia = "ACADEMIA", Resgates = "RESGATES DA PISTA",
}

local function hint(parent: Instance, content: string, color: Color3?): TextLabel
    local label = W.Label(parent, "PanelHint", content, UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 42), 12, color or C.Muted, true)
    label.TextWrapped = true
    return label
end

local ELEMENT_ICONS: {[string]: string} = {Fogo = "Fire", Agua = "Water", Planta = "Leaf", Raio = "Bolt", Gelo = "Ice", Terra = "Earth", Cosmico = "Cosmic"}

local function card(parent: Instance, name: string, height: number, accent: Color3): Frame
    local row = W.Frame(parent, name, UDim2.new(), UDim2.new(1, -2, 0, height), C.Card)
    row.BackgroundColor3 = Color3.new(1, 1, 1)
    W.Gradient(row, accent:Lerp(C.Ink, 0.67), C.Panel)
    W.Pattern(row, accent, 8, 1)
    local edge = Instance.new("Frame")
    edge.Name = "CollectionAccent"
    edge.Position = UDim2.fromOffset(4, 14)
    edge.Size = UDim2.new(0, 3, 1, -28)
    edge.BackgroundColor3 = accent
    edge.BorderSizePixel = 0
    edge.Parent = row
    W.Round(edge, 2)
    local sheen = Instance.new("Frame")
    sheen.Name = "CardGleam"
    sheen.Position = UDim2.fromOffset(17, 3)
    sheen.Size = UDim2.new(1, -34, 0, 2)
    sheen.BackgroundColor3 = C.White
    sheen.BackgroundTransparency = 0.72
    sheen.BorderSizePixel = 0
    sheen.Parent = row
    return row
end

local function badge(parent: Instance, color: Color3, iconId: string): Frame
    local icon = W.Frame(parent, "Icon", UDim2.fromOffset(13, 14), UDim2.fromOffset(58, 58), C.White)
    icon.ClipsDescendants = true
    local round = icon:FindFirstChildOfClass("UICorner")
    if round then round.CornerRadius = UDim.new(0.5, 0) end
    W.Gradient(icon, color:Lerp(C.White, 0.17), color:Lerp(C.Ink, 0.2))
    local inset = Instance.new("Frame")
    inset.Name = "InnerRing"
    inset.Position = UDim2.fromScale(0.1, 0.1)
    inset.Size = UDim2.fromScale(0.8, 0.8)
    inset.BackgroundTransparency = 1
    inset.Parent = icon
    W.Round(inset, 28)
    local ring = W.Outline(inset, 1.2, C.White)
    ring.Transparency = 0.54
    local art = Instance.new("Frame")
    art.Name = "Pictogram"
    art.Position = UDim2.fromScale(0.22, 0.22)
    art.Size = UDim2.fromScale(0.56, 0.56)
    art.BackgroundTransparency = 1
    art.Parent = icon
    Icons.Draw(art, iconId, C.White)
    local gleam = Instance.new("Frame")
    gleam.Name = "MedallionGleam"
    gleam.Position = UDim2.fromScale(0.3, 0.07)
    gleam.Size = UDim2.fromScale(0.35, 0.05)
    gleam.BackgroundColor3 = C.White
    gleam.BackgroundTransparency = 0.2
    gleam.BorderSizePixel = 0
    gleam.Rotation = -12
    gleam.Parent = icon
    W.Round(gleam, 4)
    return icon
end

function Panels.Render(parent: GuiObject, kind: string, state: any, actions: any)
    if kind == "Menu" then
        hint(parent, "Todos os sistemas do seu santuário • M abre este menu.")
        local list = W.List(parent, "NavigationList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
        local menuItems = table.clone(Panels.MenuItems)
        for _, item in {{Id = "Biomas", Icon = "Earth", Name = "Biomas & Viagem", Color = C.Blue},
            {Id = "Missoes", Icon = "Book", Name = "Missões diárias", Color = C.Green},
            {Id = "Consumiveis", Icon = "Cosmic", Name = "Consumíveis & Poções", Color = C.Purple},
            {Id = "GrupoVIP", Icon = "Gift", Name = "Grupo & VIP", Color = C.Gold},
            {Id = "Trocas", Icon = "Rebirth", Name = "Trocas de criaturas", Color = C.Blue},
            {Id = "Leiloes", Icon = "Shop", Name = "Leilões por moedas", Color = C.Pink}} do table.insert(menuItems, item) end
        for index, item in menuItems do
            local button = W.Button(list, item.Id, item.Name, UDim2.new(), UDim2.new(1, -2, 0, 52), item.Color, 17)
            local caption = button:FindFirstChild("Caption") :: TextLabel
            caption.Position = UDim2.fromOffset(58, 0)
            caption.Size = UDim2.new(1, -66, 1, 0)
            caption.TextXAlignment = Enum.TextXAlignment.Left
            local icon = Instance.new("Frame")
            icon.Name = "NavigationIcon"
            icon.Position = UDim2.fromOffset(14, 10)
            icon.Size = UDim2.fromOffset(32, 32)
            icon.BackgroundTransparency = 1
            icon.Parent = button
            Icons.Draw(icon, item.Icon, C.White)
            button.LayoutOrder = index
            button.Activated:Connect(function() actions.Open(item.Id) end)
        end
        return
    end

    if kind == "Bestiario" then
        local tab = actions.Session.BestiaryTab or "Catalog"
        Gameplay.Tabs(parent, {{Id = "Catalog", Name = "CATÁLOGO"}, {Id = "Rewards", Name = "BÔNUS POR BIOMA"}}, tab, function(id)
            actions.Session.BestiaryTab = id; actions.Refresh()
        end)
        local body = Instance.new("Frame")
        body.Name = "BestiaryBody"
        body.Position = UDim2.fromOffset(0, 52)
        body.Size = UDim2.new(1, 0, 1, -52)
        body.BackgroundTransparency = 1
        body.Parent = parent
        parent = body
        if tab == "Rewards" then Gameplay.Render(parent, "BestiarioRewards", state, actions); return end
        local ordered = {}
        local discovered = 0
        for _, definition in Config.Creatures do
            local own = state and state.Bestiary and state.Bestiary[definition.Id]
            if not meshFolder:FindFirstChild(definition.Id) then continue end
            table.insert(ordered, definition)
            if own then discovered += 1 end
        end
        table.sort(ordered, function(a, b) return a.Difficulty < b.Difficulty end)
        hint(parent, string.format("%d / %d descobertas • Explore biomas, eventos e evoluções por fusão.", discovered, #ordered))
        local list = W.List(parent, "BestiaryList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
        for index, definition in ordered do
            local owned = state and state.Bestiary and state.Bestiary[definition.Id] == true
            local accent = if owned then definition.BodyColor else C.Purple
            local row = card(list, definition.Id, 94, accent)
            row.LayoutOrder = index
            badge(row, if owned then definition.BodyColor else C.Card, if owned then ELEMENT_ICONS[definition.Element] or "Paw" else "Lock")
            local title = W.Label(row, "Name", definition.Name, UDim2.fromOffset(83, 8), UDim2.new(1, -95, 0, 24), 18, if owned then C.White else C.Muted)
            title.TextTruncate = Enum.TextTruncate.AtEnd
            W.Label(row, "Details", definition.Element .. " • " .. definition.Rarity, UDim2.fromOffset(83, 32), UDim2.new(1, -95, 0, 18), 11, if owned then accent:Lerp(C.White, 0.45) else C.Muted, true)
            W.Label(row, "Income", "$" .. Numbers.Format(definition.BaseIncomePerSec) .. "/s base", UDim2.fromOffset(83, 51), UDim2.new(1, -95, 0, 21), 15, if owned then C.Green else C.Muted)
            W.Label(row, "Discovery", (if owned then "DESCOBERTA" else "NÃO DESCOBERTA") .. " • " .. (if Config.Biomes[definition.Biome] then Config.Biomes[definition.Biome].Name else "Eventos globais"), UDim2.fromOffset(83, 74), UDim2.new(1, -95, 0, 14), 9, C.Muted, true)
        end
        return
    end

    if kind == "Criaturas" then
        local captures = if state then state.CapturedCreatures or {} else {}
        local slots = if state then state.SanctuarySlots or {} else {}
        local capacity = if state then state.SlotCapacity or GameplayMath.BaseSanctuarySlots else GameplayMath.BaseSanctuarySlots
        local session = actions.Session
        local tab = session.CreaturesTab or "Pen"
        local replace = session.ReplaceCreature
        Gameplay.Tabs(parent, {
            {Id = "Pen", Name = "CURRAL " .. #slots .. "/" .. capacity},
            {Id = "Inventory", Name = "INVENTÁRIO " .. math.max(0, #captures - #slots)},
        }, tab, function(id)
            session.CreaturesTab, session.ReplaceCreature, session.SellCreature = id, nil, nil
            actions.Refresh()
        end)
        local collectionCount = #captures .. "/" .. (if state then state.InventoryCapacity or 500 else 500)
        local reserved = if state then state.InventoryReservedSlots or 0 else 0
        local summary = if replace then "Escolha qual criatura sai do curral." else "Coleção " .. collectionCount
        if not replace and reserved > 0 then summary ..= " • " .. reserved .. " vagas reservadas em comércio" end
        W.Label(parent, "Collection", summary, UDim2.fromOffset(8, 47), UDim2.new(1, -16, 0, 24), 12, C.Muted, true)
        local top = 76
        if tab == "Pen" then
            if replace then
                local cancel = W.Button(parent, "CancelReplacement", "CANCELAR TROCA", UDim2.fromOffset(4, top), UDim2.new(1, -8, 0, 41), C.Orange, 12)
                cancel.Activated:Connect(function()
                    session.CreaturesTab, session.ReplaceCreature = "Inventory", nil
                    actions.Refresh()
                end)
            else
                local best = W.Button(parent, "EquipBest", "ADICIONAR MELHORES", UDim2.fromOffset(4, top), UDim2.new(.51, -8, 0, 41), C.Green, 12)
                best.Activated:Connect(function() actions.Send("ManageCreature", "Best") end)
                local cost = state and state.Progression and state.Progression.NextSlotCost or 0
                local buy = W.Button(parent, "BuySlot", if capacity >= 24 then "MÁX. 24 ESPAÇOS" else "+1 ESPAÇO · $" .. Numbers.Format(cost),
                    UDim2.new(.51, 4, 0, top), UDim2.new(.49, -8, 0, 41), C.Gold, 11)
                buy.Active, buy.Selectable = capacity < 24 and cost > 0, capacity < 24 and cost > 0
                buy.Activated:Connect(function() if cost > 0 and capacity < 24 then actions.Send("BuySanctuarySlot") end end)
            end
            top += 48
        end
        local list = W.List(parent, "CreatureList", UDim2.fromOffset(0, top), UDim2.new(1, 0, 1, -top))
        local equipped: {[string]: boolean} = {}
        for _, uid in slots do equipped[uid] = true end
        local displayed = 0
        for _, creature in captures do
            local uid = creature.Uid
            local active = equipped[uid] == true
            if active ~= (tab == "Pen") then continue end
            displayed += 1
            local definition = Config.Creatures[creature.CreatureId]
            local hasArt = meshFolder:FindFirstChild(creature.CreatureId) ~= nil
            local accent = if definition then definition.BodyColor else C.Purple
            local row = card(list, "Creature_" .. uid, 132, accent)
            row.LayoutOrder = displayed
            badge(row, accent, if definition then ELEMENT_ICONS[definition.Element] or "Paw" else "Paw")
            local name = W.Label(row, "Name", if definition then definition.Name else creature.CreatureId, UDim2.fromOffset(83, 9), UDim2.new(1, -95, 0, 23), 17)
            name.TextTruncate = Enum.TextTruncate.AtEnd
            local mutation = if creature.Mutation == "ArcoIris" then "Shiny" else creature.Mutation
            local size = if creature.Size == "Titanica" then "Titânica" else creature.Size
            W.Label(row, "Variant", mutation .. " • " .. size .. (if hasArt then "" else " • ARTE PENDENTE"),
                UDim2.fromOffset(83, 35), UDim2.new(1, -95, 0, 18), 11, C.Muted, true).TextTruncate = Enum.TextTruncate.AtEnd
            W.Label(row, "Income", "$" .. Numbers.Format(creature.IncomePerSec) .. "/s", UDim2.fromOffset(83, 54), UDim2.new(1, -95, 0, 21), 15, C.Green)
            if active then
                local move = W.Button(row, "PenAction", if replace then "SUBSTITUIR ESTA" else "GUARDAR", UDim2.new(.51, 0, 0, 80), UDim2.new(.49, -12, 0, 41), C.Orange, 11)
                move.Activated:Connect(function()
                    if replace then
                        session.ReplaceCreature = nil
                        actions.Send("ManageCreature", "Replace", replace, uid)
                        actions.Refresh()
                    else
                        actions.EquipSanctuary(uid)
                    end
                end)
            else
                if hasArt then
                    local equip = W.Button(row, "EquipCreature", if #slots < capacity then "PÔR NO CURRAL" else "SUBSTITUIR", UDim2.fromOffset(12, 80), UDim2.new(.5, -16, 0, 41), C.Green, 11)
                    equip.Activated:Connect(function()
                        if #slots < capacity then actions.EquipSanctuary(uid); return end
                        session.CreaturesTab, session.ReplaceCreature, session.SellCreature = "Pen", uid, nil
                        actions.Refresh()
                    end)
                end
                local confirm = session.SellCreature == uid
                local price = "$" .. Numbers.Format(GameplayMath.GetCreatureSalePrice(creature.IncomePerSec))
                local sell = W.Button(row, "SellCreature", if confirm then "CONFIRMAR " .. price else "VENDER " .. price,
                    UDim2.new(.5, 4, 0, 80), UDim2.new(.5, -16, 0, 41), if confirm then C.Pink else C.Orange, 11)
                sell.Activated:Connect(function()
                    if confirm then
                        session.SellCreature = nil
                        actions.Send("ManageCreature", "Sell", uid)
                    else
                        session.SellCreature = uid
                    end
                    actions.Refresh()
                end)
            end
        end
        if displayed == 0 then
            hint(list, if tab == "Pen" then "As capturas ocupam as vagas do curral automaticamente." else "Criaturas guardadas e capturas excedentes ficam aqui.")
        end
        return
    end

    if kind == "Resgates" then
        local list = W.List(parent, "RewardList", UDim2.new(), UDim2.fromScale(1, 1))
        local rewards = (state and state.DropInfo or {}).Drops or {}
        if #rewards == 0 then
            hint(list, "As recompensas das capturas aparecem aqui.", C.Muted)
        end
        for index, reward in rewards do
            local row = card(list, "Drop_" .. index, 66, C.Green)
            row.LayoutOrder = index
            local value = "+$" .. Numbers.Format(reward.Coins)
            if reward.MasterOrbs > 0 then value ..= " · Mestre ×" .. Numbers.Format(reward.MasterOrbs) end
            local label = W.Label(row, "Value", value, UDim2.fromOffset(16, 9), UDim2.new(.59, -12, 1, -18), 15, C.Green)
            label.TextWrapped = true
            local claim = W.Button(row, "Claim", "PEGAR", UDim2.new(.62, 0, 0, 11), UDim2.new(.38, -9, 0, 44), C.Green, 12)
            claim.Activated:Connect(function() actions.Send("CollectDrop", reward.Id) end)
        end
        return
    end

    if kind == "Academia" then
        local data = state and state.Training
        if not data then hint(parent, "Carregando seu treino…"); return end
        local list = W.List(parent, "Academy", UDim2.new(), UDim2.fromScale(1, 1))
        local tier = data.MachineTier or 1
        local current = card(list, "CurrentMachine", 112, C.Orange)
        current.LayoutOrder = 1
        W.Label(current, "Name", data.MachineName, UDim2.fromOffset(14, 6), UDim2.new(1, -28, 0, 28), 19)
        W.Label(current, "Gain", "Máquina " .. tier .. " · +" .. data.Gain .. " força e +" .. data.XPPerRep .. " XP / repetição", UDim2.fromOffset(14, 35), UDim2.new(1, -28, 0, 23), 12, C.Green)
        local start = W.Button(current, "Start", "COMEÇAR TREINO", UDim2.fromOffset(12, 61), UDim2.new(1, -24, 0, 43), C.Orange, 13)
        start.Activated:Connect(function() actions.Close(); actions.Send("StartTraining") end)
        local upgrade = card(list, "NextMachine", 157, C.Blue)
        upgrade.LayoutOrder = 2
        local nextMachine = Panels.Machines[tier + 1]
        local maxed = data.Level >= data.MaxLevel
        local xp = if maxed then "NÍVEL MÁXIMO" else Numbers.Format(data.XP) .. " / " .. Numbers.Format(data.RequiredXP) .. " XP"
        W.Label(upgrade, "Level", "Nv. " .. data.Level .. "  ·  " .. xp, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 23), 14, C.Blue)
        local progress = W.Frame(upgrade, "XP", UDim2.fromOffset(14, 31), UDim2.new(1, -28, 0, 9), C.Ink)
        local fraction = if maxed then 1 else math.clamp(data.XP / math.max(data.RequiredXP, 1), 0, 1)
        W.Frame(progress, "Fill", UDim2.new(), UDim2.fromScale(fraction, 1), C.Blue)
        local stats = data.NextMachineStats
        if nextMachine and stats then
            W.Label(upgrade, "Next", nextMachine.Name .. " · Nv. " .. nextMachine.Level, UDim2.fromOffset(14, 46), UDim2.new(1, -28, 0, 21), 14)
            W.Label(upgrade, "Gain", "Força " .. data.Gain .. " → " .. stats.Force .. "  ·  XP " .. data.XPPerRep .. " → " .. stats.XP .. " / rep", UDim2.fromOffset(14, 68), UDim2.new(1, -28, 0, 20), 12, C.Green)
            local ready = data.Level >= nextMachine.Level and state.Coins >= nextMachine.Cost
            local title = if data.Level < nextMachine.Level then "LIBERA NO NÍVEL " .. nextMachine.Level
                elseif not ready then "FALTAM MOEDAS · $" .. Numbers.Format(nextMachine.Cost)
                else "EVOLUIR · $" .. Numbers.Format(nextMachine.Cost)
            local button = W.Button(upgrade, "Upgrade", title, UDim2.fromOffset(12, 103), UDim2.new(1, -24, 0, 43), if ready then C.Green else C.Card, 12)
            button.Active, button.Selectable = ready, ready
            button.Activated:Connect(function() if ready then actions.Send("UpgradeTrainingMachine", tier + 1) end end)
        else
            W.Label(upgrade, "Max", "Sua máquina chegou ao nível máximo!", UDim2.fromOffset(14, 56), UDim2.new(1, -28, 0, 32), 14, C.Green)
        end
        return
    end

    if kind == "Orbes" then
        local fragments = state and state.OrbFragments or 0
        hint(parent, "Orbes evoluídas têm uso livre. Fragmentos para desconto: " .. Numbers.Format(fragments))
        local tier = state and state.OrbTier or 1
        local list = W.List(parent, "OrbList", UDim2.fromOffset(0, 46), UDim2.new(1, 0, 1, -46))
        local order = table.clone(Panels.OrbOrder)
        if state and state.Benefits and state.Benefits.EternalPrism then table.insert(order, "Prismatica") end
        for index, id in order do
            local orb = Config.Orbs[id]
            local count = state and (state.Orbs or {})[id] or 0
            local active = state and state.EquippedOrb == id
            local permanent = orb.Tier and orb.Tier <= tier
            local nextTier = orb.Tier and orb.Tier == tier + 1
            local canEquip = permanent or orb.IsPrismatic or count > 0
            local row = card(list, id, 124, orb.Color)
            row.LayoutOrder = index
            local medallion = badge(row, orb.Color, "Orb")
            local pictogram = medallion:FindFirstChild("Pictogram")
            if pictogram then pictogram:Destroy() end
            local preview = Instance.new("ViewportFrame")
            preview.Name, preview.Size = "OrbModel", UDim2.fromScale(1, 1)
            preview.BackgroundTransparency, preview.Parent = 1, medallion
            preview.Ambient, preview.LightColor = Color3.fromRGB(175, 187, 204), Color3.new(1, 1, 1)
            local camera = Instance.new("Camera")
            camera.FieldOfView, camera.CFrame, camera.Parent = 35, CFrame.lookAt(Vector3.new(1.14, .96, -1.65), Vector3.zero), preview
            preview.CurrentCamera = camera
            local model = OrbVisual.Create(orb.Color, 1, id)
            model.Parent = preview
            W.Label(row, "Name", orb.Name, UDim2.fromOffset(83, 9), UDim2.new(1, -95, 0, 25), 17, if active then C.Gold else C.White)
            local status = if permanent or orb.IsPrismatic then "Uso livre" elseif count > 0 then "Bônus ×" .. Numbers.Format(count) else "Bloqueada"
            W.Label(row, "State", status .. " · Poder " .. Numbers.Format(orb.Power) .. " · Raros ×" .. Numbers.Format(orb.RareBoost, 2),
                UDim2.fromOffset(83, 35), UDim2.new(1, -95, 0, 21), 11, C.Muted).TextTruncate = Enum.TextTruncate.AtEnd
            if nextTier then
                local price, used = GameplayMath.GetOrbEvolutionPrice(orb.Price, fragments)
                local ready = state and state.Coins >= price
                local cost = "$" .. Numbers.Format(price) .. (if used > 0 then " ✦" else "")
                local evolve = W.Button(row, "Evolve", "EVOLUIR " .. cost, UDim2.fromOffset(12, 72), UDim2.new(if canEquip then .54 else 1, -24, 0, 44), if ready then C.Green else C.Card, 12)
                evolve.Active, evolve.Selectable = ready == true, ready == true
                evolve.Activated:Connect(function() if ready then actions.Send("EvolveOrb", orb.Tier) end end)
            end
            if canEquip then
                local left = if nextTier then .54 else 0
                local equip = W.Button(row, "Equip", if active then "EQUIPADA" else "EQUIPAR", UDim2.new(left, 12, 0, 72), UDim2.new(1 - left, -24, 0, 44), if active then C.Gold else C.Blue, 12)
                equip.Activated:Connect(function() if not active then actions.EquipOrb(id) end end)
            end
        end
        return
    end

    hint(parent, "Escolha uma opção no menu do santuário.")
end

return Panels
