--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("ConfigProgression"))
local GameplayMath = require(Shared:WaitForChild("GameplayMath"))

local ProgressionService = {}
local dataService: any
local sanctuaryService: any
local context: any = nil
local lastActions: {[Player]: {[string]: number}} = {}
local remotes: any
local function benefits(player: Player): any
    return if context and context.Monetization then context.Monetization.GetBenefits(player) else {}
end
local function allowed(player: Player, action: string, cooldown: number): boolean
    if not dataService.IsLoaded(player) or (dataService.IsBusy and dataService.IsBusy(player)) then return false end
    local actions = lastActions[player] or {}
    lastActions[player] = actions
    local now = os.clock()
    if now - (actions[action] or -math.huge) < cooldown then return false end
    actions[action] = now
    return true
end
local function feedback(player: Player, message: string, kind: string?)
    (remotes:WaitForChild("ActionFeedback") :: RemoteEvent):FireClient(player, {Message = message, Kind = kind or "Error"})
end
local function addCoins(player: Player, profile: any, amount: number)
    if dataService.AddCoins then dataService.AddCoins(player, amount) else profile.Coins += amount end
end
local function commit(player: Player, owner: string, mutation: (any) -> (boolean, string)): (boolean, string)
    if not dataService.TryLock or not dataService.TryLock(player, owner) then return false, "Aguarde concluir a operação atual." end
    local profile = dataService.Get(player)
    local ok, accepted, message = pcall(mutation, profile)
    if not ok then
        dataService.Unlock(player, owner)
        dataService.Freeze(player, "Não foi possível concluir esta operação com segurança.")
        warn("[Progression] Transaction failed:", accepted)
        return false, "Operação interrompida para proteger seus dados."
    end
    if not accepted then dataService.Unlock(player, owner); return false, message end
    local saved = dataService.SaveNow(player)
    dataService.Unlock(player, owner)
    if not saved then dataService.Freeze(player, "Não foi possível salvar seu progresso com segurança."); return false, "Salvamento indisponível." end
    dataService.Sync(player)
    return true, message
end

function ProgressionService.GrantXP(player: Player, amount: number): (boolean, number)
    local profile = dataService.Get(player)
    if not profile or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then return false, 0 end
    if profile.Level >= Config.Constants.MaxLevel then profile.XP = 0; return false, 0 end
    local multiplier = if GameplayMath.GetXPMultiplier then GameplayMath.GetXPMultiplier(profile, benefits(player), os.time()) else 1
    local requested = math.floor(amount * multiplier)
    if requested ~= requested or requested == math.huge then return false, 0 end
    local remaining = -(profile.XP or 0)
    for level = profile.Level, Config.Constants.MaxLevel - 1 do remaining += Config.GetXPRequiredForLevel(level) end
    local gained = math.min(requested, math.max(0, remaining))
    profile.XP += gained
    local leveled = false
    while profile.Level < Config.Constants.MaxLevel and profile.XP >= Config.GetXPRequiredForLevel(profile.Level) do
        profile.XP -= Config.GetXPRequiredForLevel(profile.Level)
        profile.Level += 1
        addCoins(player, profile, profile.Level * 25)
        leveled = true
    end
    if profile.Level == Config.Constants.MaxLevel then profile.XP = 0 end
    if profile.Titles then
        if profile.Level >= 10 then profile.Titles.Cacador = true end
        if profile.Level >= 25 then profile.Titles.MestreDasOrbes = true end
    end
    if leveled then sanctuaryService.Refresh(player) end
    dataService.MarkDirty(player)
    return leveled, gained
end

function ProgressionService.Train(player: Player): (boolean, string)
    if not allowed(player, "TrainThrowPower", 0.5) then return false, "Aguarde o próximo treino." end
    local profile = dataService.Get(player)
    if not profile then return false, "Carregando seus dados." end
    local gain = if GameplayMath.GetTrainingGain then GameplayMath.GetTrainingGain(profile, benefits(player)) else Config.Constants.TrainingStrength or 1
    profile.ThrowStrength = math.min(10000, profile.ThrowStrength + gain)
    addCoins(player, profile, Config.Constants.TrainingCoins or 5)
    dataService.MarkDirty(player)
    dataService.Sync(player)
    return true, "Treino concluído."
end

function ProgressionService.Rebirth(player: Player): (boolean, string)
    if not allowed(player, "Rebirth", 1) then return false, "Aguarde concluir sua ação." end
    return commit(player, "Rebirth", function(profile)
        if not profile or profile.Level < Rules.RebirthLevel then return false, "Rebirth exige nível " .. Rules.RebirthLevel .. "." end
        profile.Rebirths += 1
        profile.Gems += Rules.RebirthGems
        profile.Level, profile.XP, profile.Coins = 1, 0, Rules.RebirthStartingCoins
        profile.PityBonus, profile.ComboStreak = 0, 0
        profile.UnlockedBiomes = {PradariaSolar = true}
        local capacity = sanctuaryService.GetSlotCapacity(profile, benefits(player))
        while #profile.SanctuarySlots > capacity do table.remove(profile.SanctuarySlots) end
        sanctuaryService.Refresh(player)
        if context and context.Biomes and context.Biomes.ReturnToMeadow then context.Biomes.ReturnToMeadow(player) end
        return true, "Rebirth concluído! +5 gemas e bônus permanentes."
    end)
end

function ProgressionService.BuySlot(player: Player): (boolean, string)
    if not allowed(player, "BuySlot", 0.5) then return false, "Aguarde concluir sua ação." end
    return commit(player, "BuySlot", function(profile)
        if not profile then return false, "Carregando seus dados." end
        local capacity = sanctuaryService.GetSlotCapacity(profile, benefits(player))
        if capacity >= Rules.MaxSanctuarySlots then return false, "Seu santuário já tem 24 espaços." end
        local cost = Rules.GetExtraSlotCost(profile.ExtraSanctuarySlots or 0)
        if profile.Coins < cost then return false, "Moedas insuficientes para este espaço." end
        profile.Coins -= cost
        profile.ExtraSanctuarySlots = (profile.ExtraSanctuarySlots or 0) + 1
        sanctuaryService.Refresh(player)
        return true, "Mais um espaço liberado no santuário!"
    end)
end

function ProgressionService.Init(service: any, sanctuary: any, remoteFolder: any, ctx: any?)
    dataService, sanctuaryService, remotes, context = service, sanctuary, remoteFolder, ctx
    local buyRemote = remotes:WaitForChild("BuyOrb") :: RemoteEvent
    local equipRemote = remotes:WaitForChild("EquipOrb") :: RemoteEvent
    local trainRemote = remotes:WaitForChild("TrainThrowPower") :: RemoteEvent
    buyRemote.OnServerEvent:Connect(function(player: Player, id: any, quantity: any)
        if typeof(id) ~= "string" or typeof(quantity) ~= "number" or quantity ~= quantity or quantity % 1 ~= 0 or quantity < 1 or quantity > 100 then return end
        if not allowed(player, "BuyOrb", 0.25) then return end
        local profile, orb = dataService.Get(player), Config.Orbs[id]
        if not profile or not orb or orb.IsMaster or orb.Price <= 0 then feedback(player, "Esta orbe não está disponível por moedas."); return end
        local price = orb.Price * quantity
        if profile.Coins < price then feedback(player, "Moedas insuficientes. Capture criaturas ou treine para ganhar moedas."); return end
        profile.Coins -= price
        profile.Orbs[id] = (profile.Orbs[id] or 0) + quantity
        dataService.MarkDirty(player)
        dataService.Sync(player)
        feedback(player, string.format("Comprou %dx %s!", quantity, orb.Name), "Success")
    end)
    equipRemote.OnServerEvent:Connect(function(player: Player, id: any)
        if typeof(id) ~= "string" or not allowed(player, "EquipOrb", 0.2) then return end
        local profile = dataService.Get(player)
        local orb = Config.Orbs[id]
        local infinite = orb and orb.IsPrismatic and benefits(player).EternalPrism == true
        if not profile or not orb or ((profile.Orbs[id] or 0) < 1 and not infinite) then feedback(player, "Você precisa ter essa orbe no inventário."); return end
        profile.EquippedOrb = id
        dataService.MarkDirty(player)
        dataService.Sync(player)
    end)
    trainRemote.OnServerEvent:Connect(function(player: Player) ProgressionService.Train(player) end)
    for name, action in {RebirthRequest = ProgressionService.Rebirth, BuySanctuarySlot = ProgressionService.BuySlot} do
        local remote = remotes:FindFirstChild(name)
        if remote then remote.OnServerEvent:Connect(function(player: Player)
            local success, message = action(player)
            feedback(player, message, if success then "Success" else "Error")
        end) end
    end
    if service.AddSnapshotProvider then service.AddSnapshotProvider(function(player: Player, profile: any)
        local capacity = sanctuaryService.GetSlotCapacity(profile, benefits(player))
        return {Progression = {RebirthLevel = Rules.RebirthLevel, RebirthGems = Rules.RebirthGems, CanRebirth = profile.Level >= Rules.RebirthLevel,
            SlotCapacity = capacity, NextSlotCost = if capacity < Rules.MaxSanctuarySlots then Rules.GetExtraSlotCost(profile.ExtraSanctuarySlots or 0) else 0}}
    end) end
    Players.PlayerRemoving:Connect(function(player: Player) lastActions[player] = nil end)
end

return ProgressionService
