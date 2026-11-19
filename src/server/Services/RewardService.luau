--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("ConfigRecompensas"))

local RewardService = {}
local context: any
local lastRequests: {[Player]: {[string]: number}} = {}
local lastOnlineAt: {[Player]: number} = {}
local function dayKey(now: number): number return math.floor(now / 86400) end
local function finite(value: any): boolean return type(value) == "number" and value == value and math.abs(value) < math.huge end
local function allowed(player: Player, action: string): boolean
    if not context.Data.IsLoaded(player) or context.Data.IsBusy(player) then return false end
    local requests = lastRequests[player] or {}
    lastRequests[player] = requests
    if os.clock() - (requests[action] or -math.huge) < 0.4 then return false end
    requests[action] = os.clock()
    return true
end
local function resetMissionDay(profile: any, now: number)
    if profile.MissionDay == dayKey(now) then return end
    profile.MissionDay = dayKey(now)
    profile.MissionCounters = {Captures = 0, Criticals = 0, Fusions = 0}
    profile.MissionClaimed = {}
end
local function updateOnline(player: Player, profile: any, now: number)
    local previous = lastOnlineAt[player] or now
    lastOnlineAt[player] = now
    if profile.PlaytimeDay ~= dayKey(now) then
        profile.PlaytimeDay = dayKey(now)
        profile.PlaytimeClaimed = {}
        profile.OnlineSecondsToday = math.max(0, now - math.max(previous, profile.PlaytimeDay * 86400))
    else
        profile.OnlineSecondsToday += math.max(0, math.min(86400, now - previous))
    end
end
local function commit(player: Player, owner: string, mutation: (any) -> (boolean, string)): (boolean, string)
    local data = context.Data
    if not data.TryLock(player, owner) then return false, "Aguarde concluir a operação atual." end
    local ok, accepted, message = pcall(mutation, data.Get(player))
    if not ok then
        data.Unlock(player, owner)
        data.Freeze(player, "Uma recompensa foi interrompida para proteger seus dados.")
        warn("[RewardService]", accepted)
        return false, "Não foi possível concluir esta recompensa com segurança."
    end
    if not accepted then data.Unlock(player, owner); return false, message end
    local saved = data.SaveNow(player)
    data.Unlock(player, owner)
    if not saved then data.Freeze(player, "Não foi possível salvar esta recompensa com segurança."); return false, "Salvamento indisponível." end
    data.Sync(player)
    return true, message
end
local function integerMap(map: any, catalog: any): boolean
    if map == nil then return true end
    if type(map) ~= "table" then return false end
    for id, amount in pairs(map) do
        if type(id) ~= "string" or not catalog[id] or not finite(amount) or amount < 0 or amount % 1 ~= 0 then return false end
    end
    return true
end

function RewardService.CanGrant(profile: any, reward: any): (boolean, string)
    if not profile or type(reward) ~= "table" then return false, "Recompensa não disponível." end
    for _, key in {"Coins", "Gems", "XP", "WeeklyPets"} do
        local value = reward[key]
        if value ~= nil and (not finite(value) or value < 0 or value % 1 ~= 0) then return false, "Configuração de recompensa inválida." end
    end
    if not integerMap(reward.Orbs, Config.Orbs) or not integerMap(reward.Consumables, Rules.Consumables) then return false, "Itens de recompensa inválidos." end
    if reward.Creature then
        if type(reward.Creature) ~= "table" or not Config.Creatures[reward.Creature.Id] then return false, "Criatura de recompensa indisponível." end
        local count = if context.Data.GetInventoryCount then context.Data.GetInventoryCount(profile) else #profile.CapturedCreatures
        local available = not context.AuthoredCreatures or context.AuthoredCreatures[reward.Creature.Id]
        if available and count >= (Config.Constants.MaxInventoryCreatures or 500) then return false, "Libere espaço no inventário para receber esta criatura." end
        local foundMutation, foundSize = false, false
        for _, item in Config.Mutations do if item.Name == reward.Creature.Mutation then foundMutation = true end end
        for _, item in Config.Sizes do if item.Name == reward.Creature.Size then foundSize = true end end
        if not foundMutation or not foundSize then return false, "Variante de recompensa inválida." end
    end
    if reward.Titles ~= nil then
        if type(reward.Titles) ~= "table" then return false, "Título de recompensa inválido." end
        for name, enabled in reward.Titles do if type(name) ~= "string" or #name > 80 or enabled ~= true then return false, "Título de recompensa inválido." end end
    end
    return true, ""
end

-- Internal server API. The caller owns any needed transaction lock and save.
function RewardService.GrantReward(player: Player, reward: any): (boolean, string)
    local profile = context.Data.Get(player)
    local valid, message = RewardService.CanGrant(profile, reward)
    if not valid then return false, message end
    local coinAmount = (reward.Coins or 0) * (if reward.ScaleCoinsWithLevel then math.max(1, profile.Level) else 1)
    if coinAmount > 0 then context.Data.AddCoins(player, coinAmount) end
    profile.Gems += reward.Gems or 0
    profile.WeeklyPets += reward.WeeklyPets or 0
    for id, quantity in reward.Orbs or {} do profile.Orbs[id] = (profile.Orbs[id] or 0) + quantity end
    for id, quantity in reward.Consumables or {} do profile.Consumables[id] = (profile.Consumables[id] or 0) + quantity end
    for title in reward.Titles or {} do profile.Titles[title] = true end
    if reward.Creature and (not context.AuthoredCreatures or context.AuthoredCreatures[reward.Creature.Id]) then
        local definition = Config.Creatures[reward.Creature.Id]
        local mutationMultiplier, sizeMultiplier = 1, 1
        for _, item in Config.Mutations do if item.Name == reward.Creature.Mutation then mutationMultiplier = item.Multiplier end end
        for _, item in Config.Sizes do if item.Name == reward.Creature.Size then sizeMultiplier = item.Multiplier end end
        local record = {Uid = HttpService:GenerateGUID(false), CreatureId = definition.Id, Mutation = reward.Creature.Mutation,
            Size = reward.Creature.Size, IncomePerSec = math.floor(definition.BaseIncomePerSec * mutationMultiplier * sizeMultiplier), CapturedAt = os.time()}
        assert(context.Sanctuary.AddCapture(player, record), "Reward creature could not be added")
    end
    if (reward.XP or 0) > 0 then context.Progression.GrantXP(player, reward.XP) end
    context.Data.MarkDirty(player)
    return true, "Recompensa recebida!"
end

function RewardService.ClaimDaily(player: Player): (boolean, string)
    if not allowed(player, "Daily") then return false, "Aguarde concluir sua ação." end
    return commit(player, "DailyReward", function(profile)
        local now = os.time()
        if profile.LastDailyClaim > 0 and now - profile.LastDailyClaim < Rules.DailyIntervalSeconds then return false, "A recompensa diária ainda não está pronta." end
        local nextDay = if profile.LastDailyClaim == 0 or now - profile.LastDailyClaim >= Rules.StreakBreakSeconds then 1 else profile.DailyStreak % 7 + 1
        local success, message = RewardService.GrantReward(player, Rules.Daily[nextDay])
        if not success then return false, message end
        profile.DailyStreak, profile.LastDailyClaim = nextDay, now
        return true, "Recompensa diária " .. nextDay .. "/7 recebida!"
    end)
end

function RewardService.ClaimPlaytime(player: Player, rewardId: any): (boolean, string)
    if not finite(rewardId) or rewardId % 1 ~= 0 or not Rules.Playtime[rewardId] then return false, "Presente inválido." end
    if not allowed(player, "Playtime") then return false, "Aguarde concluir sua ação." end
    return commit(player, "PlaytimeReward", function(profile)
        updateOnline(player, profile, os.time())
        local id, reward = tostring(rewardId), Rules.Playtime[rewardId]
        if profile.PlaytimeClaimed[id] then return false, "Você já recebeu este presente hoje." end
        if profile.OnlineSecondsToday < reward.Seconds then return false, "Continue jogando para liberar este presente." end
        local success, message = RewardService.GrantReward(player, reward)
        if not success then return false, message end
        profile.PlaytimeClaimed[id] = true
        return true, "Presente de tempo de jogo recebido!"
    end)
end

function RewardService.OnProgress(player: Player, kind: string, amount: number?)
    local profile = context.Data.Get(player)
    if not profile then return end
    local aliases = {Capture = "Captures", Critical = "Criticals", Fusion = "Fusions"}
    local counter = aliases[kind] or kind
    if counter ~= "Captures" and counter ~= "Criticals" and counter ~= "Fusions" then return end
    local count = amount or 1
    if not finite(count) or count <= 0 or count % 1 ~= 0 then return end
    resetMissionDay(profile, os.time())
    if profile.Level < Rules.MissionLevel then return end
    profile.MissionCounters[counter] = (profile.MissionCounters[counter] or 0) + count
    context.Data.MarkDirty(player)
end

function RewardService.ClaimMission(player: Player, missionId: any): (boolean, string)
    if type(missionId) ~= "string" or not Rules.Missions[missionId] then return false, "Missão inválida." end
    if not allowed(player, "Mission") then return false, "Aguarde concluir sua ação." end
    return commit(player, "MissionReward", function(profile)
        resetMissionDay(profile, os.time())
        local mission = Rules.Missions[missionId]
        local requiredLevel = math.max(Rules.MissionLevel, mission.RequiredLevel or Rules.MissionLevel)
        if profile.Level < requiredLevel then return false, "Esta missão exige nível " .. requiredLevel .. "." end
        if profile.MissionClaimed[missionId] then return false, "Missão já resgatada hoje." end
        if (profile.MissionCounters[mission.Counter] or 0) < mission.Target then return false, "Complete o objetivo antes de resgatar." end
        local biome = if context.Biomes then context.Biomes.GetCurrentBiome(player) else "PradariaSolar"
        local orbId = Rules.BiomeOrbs[biome] or "Comum"
        local success, message = RewardService.GrantReward(player, {Orbs = {[orbId] = mission.OrbQuantity}, XP = mission.XP, Gems = mission.Gems})
        if not success then return false, message end
        profile.MissionClaimed[missionId] = true
        return true, "Missão concluída! Orbes, XP e gemas recebidos."
    end)
end

function RewardService.ClaimBestiary(player: Player, biomeId: any): (boolean, string)
    if type(biomeId) ~= "string" or not Config.Biomes[biomeId] then return false, "Bioma inválido." end
    if not allowed(player, "Bestiary") then return false, "Aguarde concluir sua ação." end
    return commit(player, "BestiaryReward", function(profile)
        if profile.BestiaryRewardClaimed[biomeId] then return false, "Bônus deste bioma já recebido." end
        local required = 0
        for id, definition in context.EncounterCreatures or Config.Creatures do
            if definition.Biome == biomeId then required += 1; if not profile.Bestiary[id] then return false, "Descubra todas as criaturas deste bioma." end end
        end
        if required == 0 then return false, "Este bioma ainda não possui uma coleção." end
        local success, message = RewardService.GrantReward(player, {Coins = Rules.BestiaryCoins[biomeId] or 0, Titles = {["Bestiario_" .. biomeId] = true}})
        if not success then return false, message end
        profile.BestiaryRewardClaimed[biomeId] = true
        return true, "Bestiário completo! +10% de sorte permanente e recompensa recebida."
    end)
end

function RewardService.RedeemCode(player: Player, codeText: any): (boolean, string)
    if type(codeText) ~= "string" or #codeText > 64 then return false, "Código inválido." end
    if not allowed(player, "Code") then return false, "Aguarde concluir sua ação." end
    local code = string.upper(codeText:match("^%s*(.-)%s*$") or "")
    local definition = Rules.Codes[code]
    if type(definition) ~= "table" then return false, "Este código não está ativo." end
    if definition.ExpiresAt ~= nil and not finite(definition.ExpiresAt) then return false, "Código temporariamente indisponível." end
    if definition.MinLevel ~= nil and (not finite(definition.MinLevel) or definition.MinLevel < 1 or definition.MinLevel % 1 ~= 0) then return false, "Código temporariamente indisponível." end
    return commit(player, "CodeReward", function(profile)
        if definition.ExpiresAt and os.time() >= definition.ExpiresAt then return false, "Este código expirou." end
        if profile.RedeemedCodes[code] then return false, "Você já resgatou este código." end
        if profile.Level < (definition.MinLevel or 1) then return false, "Seu nível ainda não libera este código." end
        local success, message = RewardService.GrantReward(player, definition.Reward or definition)
        if not success then return false, message end
        profile.RedeemedCodes[code] = true
        return true, "Código resgatado!"
    end)
end

function RewardService.ClaimGroup(player: Player): (boolean, string)
    if not allowed(player, "Group") then return false, "Aguarde concluir sua ação." end
    if not context.Monetization.GetBenefits(player).GroupMember then return false, "Entre no grupo oficial para liberar este bônus." end
    return commit(player, "GroupReward", function(profile)
        if profile.GroupRewardClaimed then return false, "Seu bônus de grupo já foi reconhecido." end
        profile.GroupRewardClaimed, profile.Titles.Grupo = true, true
        context.Sanctuary.Refresh(player)
        return true, "Bônus de grupo reconhecido: sorte, espaço extra e Auto-Treino!"
    end)
end

function RewardService.ClaimVIP(player: Player): (boolean, string)
    if not allowed(player, "VIP") then return false, "Aguarde concluir sua ação." end
    if not context.Monetization.GetBenefits(player).GoldenVIP then return false, "Este baú exige o passe VIP Dourado." end
    return commit(player, "VIPReward", function(profile)
        local timestamp = os.time()
        if (profile.VIPLastClaim or 0) > 0 and timestamp - profile.VIPLastClaim < Rules.VIP.IntervalSeconds then return false, "Seu próximo baú VIP ainda não está pronto." end
        local success, message = RewardService.GrantReward(player, Rules.VIP.Reward)
        if not success then return false, message end
        profile.VIPLastClaim = timestamp
        return true, "Baú VIP diário recebido!"
    end)
end

local function useGlobalEffect(player: Player, itemId: string, item: any): (boolean, string)
    local data = context.Data
    if not data.TryLock(player, "GlobalConsumable") then return false, "Aguarde concluir sua ação." end
    local profile = data.Get(player)
    if not profile or (profile.Consumables[itemId] or 0) < 1 then data.Unlock(player, "GlobalConsumable"); return false, "Você não possui este consumível." end
    profile.Consumables[itemId] -= 1
    if not data.SaveNow(player) then
        data.Unlock(player, "GlobalConsumable")
        data.Freeze(player, "Não foi possível salvar o uso deste item com segurança.")
        return false, "Salvamento indisponível; o efeito não foi ativado."
    end
    -- Global effects only run after the debit is durable. A rejected effect is
    -- refunded durably under the same lock, so no other operation can spend it.
    local ok, activated = pcall(function()
        if not context.Weather then return false end
        if item.Kind == "GlobalLuck" then return context.Weather.ActivateGlobalLuck(player, item.Multiplier, item.Duration) end
        return context.Weather.SummonEvent(player)
    end)
    if not ok or activated ~= true then
        profile.Consumables[itemId] += 1
        local refunded = data.SaveNow(player)
        data.Unlock(player, "GlobalConsumable")
        if not refunded then data.Freeze(player, "A devolução deste item está sendo protegida. Entre novamente."); return false, "Não foi possível confirmar a devolução com segurança." end
        data.Sync(player)
        return false, "O evento não pôde ser ativado. Seu consumível foi devolvido."
    end
    data.Unlock(player, "GlobalConsumable")
    data.Sync(player)
    return true, "Consumível global ativado!"
end

function RewardService.UseConsumable(player: Player, itemId: any): (boolean, string)
    if type(itemId) ~= "string" or not Rules.Consumables[itemId] then return false, "Consumível inválido." end
    if not allowed(player, "Consumable") then return false, "Aguarde concluir sua ação." end
    local definition = Rules.Consumables[itemId]
    if definition.Kind == "GlobalLuck" or definition.Kind == "SummonEvent" then return useGlobalEffect(player, itemId, definition) end
    return commit(player, "Consumable", function(profile)
        if (profile.Consumables[itemId] or 0) < 1 then return false, "Você não possui este consumível." end
        local item, now = Rules.Consumables[itemId], os.time()
        if item.Stat then
            local previous = profile.Boosts[item.Stat]
            local active = previous and previous.ExpiresAt > now
            if active and previous.Multiplier > item.Multiplier then return false, "Uma poção mais forte já está ativa." end
            local expires = if active and previous.Multiplier == item.Multiplier then previous.ExpiresAt + item.Duration else now + item.Duration
            profile.Boosts[item.Stat] = {Multiplier = item.Multiplier, ExpiresAt = expires}
        elseif item.Kind == "SkipFusion" then
            if (profile.FusionReadyAt or 0) <= now then return false, "A máquina de fusão já está pronta." end
            profile.FusionReadyAt = 0
        elseif item.Kind == "SanctuarySlot" then
            if context.Sanctuary.GetSlotCapacity(profile, context.Monetization.GetBenefits(player)) >= 24 then return false, "Você já tem 24 espaços. O token foi preservado." end
            profile.ExtraSanctuarySlots += 1
        else return false, "Consumível não disponível." end
        profile.Consumables[itemId] -= 1
        context.Sanctuary.Refresh(player)
        return true, "Consumível ativado!"
    end)
end

function RewardService.GetSnapshot(player: Player, profile: any): any
    local now = os.time()
    local currentDay = dayKey(now)
    local elapsed = math.max(0, now - (lastOnlineAt[player] or now))
    local seconds = if profile.PlaytimeDay == currentDay then profile.OnlineSecondsToday + elapsed else math.max(0, now - math.max(lastOnlineAt[player] or now, currentDay * 86400))
    local nextDay = if profile.LastDailyClaim == 0 or now - profile.LastDailyClaim >= Rules.StreakBreakSeconds then 1 else profile.DailyStreak % 7 + 1
    return {Rewards = {
        Daily = {NextDay = nextDay, CanClaim = profile.LastDailyClaim == 0 or now - profile.LastDailyClaim >= Rules.DailyIntervalSeconds, NextClaimAt = if profile.LastDailyClaim == 0 then 0 else profile.LastDailyClaim + Rules.DailyIntervalSeconds},
        Playtime = {DayKey = currentDay, Seconds = seconds, Claimed = if profile.PlaytimeDay == currentDay then profile.PlaytimeClaimed else {}},
        Missions = {DayKey = currentDay, Counters = if profile.MissionDay == currentDay then profile.MissionCounters else {Captures = 0, Criticals = 0, Fusions = 0}, Claimed = if profile.MissionDay == currentDay then profile.MissionClaimed else {}, Unlocked = profile.Level >= Rules.MissionLevel},
        VIP = {CanClaim = context.Monetization.GetBenefits(player).GoldenVIP == true and ((profile.VIPLastClaim or 0) == 0 or now - profile.VIPLastClaim >= Rules.VIP.IntervalSeconds), NextClaimAt = if (profile.VIPLastClaim or 0) == 0 then 0 else profile.VIPLastClaim + Rules.VIP.IntervalSeconds},
    }}
end

function RewardService.Init(ctx: any)
    context = ctx
    ctx.Data.OnLoaded(function(player: Player, profile: any)
        lastOnlineAt[player] = os.time()
        updateOnline(player, profile, os.time())
        resetMissionDay(profile, os.time())
    end)
    ctx.Data.OnRemoving(function(player: Player, profile: any)
        updateOnline(player, profile, os.time())
        lastOnlineAt[player], lastRequests[player] = nil, nil
    end)
    local actions = {ClaimDailyReward = RewardService.ClaimDaily, ClaimPlaytimeReward = RewardService.ClaimPlaytime,
        ClaimMissionReward = RewardService.ClaimMission, ClaimBestiaryReward = RewardService.ClaimBestiary,
        RedeemCode = RewardService.RedeemCode, UseConsumable = RewardService.UseConsumable, ClaimGroupReward = RewardService.ClaimGroup, ClaimVIPReward = RewardService.ClaimVIP}
    for name, action in actions do
        local remote = ctx.Remotes:FindFirstChild(name)
        if remote then remote.OnServerEvent:Connect(function(player: Player, id: any)
            local success, message = action(player, id)
            ctx.Remotes.ActionFeedback:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"})
        end) end
    end
    ctx.Data.AddSnapshotProvider(RewardService.GetSnapshot)
    task.spawn(function()
        while true do
            task.wait(1)
            for _, player in Players:GetPlayers() do
                local profile = ctx.Data.Get(player)
                if profile and not ctx.Data.IsBusy(player) then updateOnline(player, profile, os.time()); ctx.Data.MarkDirty(player) end
            end
        end
    end)
end

return RewardService
