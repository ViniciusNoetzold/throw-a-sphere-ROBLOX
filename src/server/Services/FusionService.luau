--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("ConfigProgression"))

local FusionService = {}
local context: any
local lastRequests: {[Player]: number} = {}
local function benefits(player: Player): any return context.Monetization.GetBenefits(player) end
local function feedback(player: Player, message: string, success: boolean)
    context.Remotes.ActionFeedback:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"})
end

function FusionService.GetRequiredCount(player: Player): number
    return if benefits(player).FusionXP then Rules.FusionPassCount else Rules.FusionCount
end

function FusionService.Fuse(player: Player, uids: any): (boolean, string)
    local data = context.Data
    if not data.IsLoaded(player) or data.IsBusy(player) then return false, "Aguarde concluir sua ação." end
    local now = os.clock()
    if now - (lastRequests[player] or -math.huge) < 0.4 then return false, "Aguarde a máquina de fusão." end
    lastRequests[player] = now
    if type(uids) ~= "table" then return false, "Selecione suas criaturas." end
    local required = FusionService.GetRequiredCount(player)
    local seen: {[string]: boolean} = {}
    local count = 0
    for index, uid in pairs(uids) do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > required or type(uid) ~= "string" or #uid > 80 or seen[uid] then return false, "Seleção de fusão inválida." end
        seen[uid] = true
        count += 1
    end
    if count ~= required then return false, "Escolha " .. required .. " criaturas idênticas." end
    local profile = data.Get(player)
    if not profile or profile.Level < Rules.FusionLevel then return false, "A fusão desbloqueia no nível " .. Rules.FusionLevel .. "." end
    if (profile.FusionReadyAt or 0) > os.time() then return false, "A máquina está recarregando." end
    local selected = {}
    for _, record in profile.CapturedCreatures do if seen[record.Uid] then table.insert(selected, record) end end
    if #selected ~= required then return false, "Uma criatura selecionada não está no seu inventário." end
    local first = selected[1]
    for _, record in selected do
        if record.CreatureId ~= first.CreatureId or record.Mutation ~= first.Mutation or record.Size ~= first.Size then return false, "Use a mesma espécie, mutação e tamanho." end
    end
    local recipe, definition = Rules.FusionRecipes[first.Mutation], Config.Creatures[first.CreatureId]
    if not recipe or not definition then return false, "Esta mutação não possui uma fusão superior." end
    local inventoryCount = if data.GetInventoryCount then data.GetInventoryCount(profile) else #profile.CapturedCreatures
    if inventoryCount - required + 1 > (Config.Constants.MaxInventoryCreatures or 500) then return false, "Libere espaço reservado antes de concluir esta fusão." end
    local sizeMultiplier: number? = nil
    for _, size in Config.Sizes do if size.Name == first.Size then sizeMultiplier = size.Multiplier end end
    if not sizeMultiplier then return false, "O tamanho desta criatura não pode ser fundido." end
    if not data.TryLock(player, "Fusion") then return false, "Aguarde concluir sua ação." end
    local ok, message = pcall(function()
        local kept = {}
        for _, record in profile.CapturedCreatures do if not seen[record.Uid] then table.insert(kept, record) end end
        local keptSlots = {}
        for _, uid in profile.SanctuarySlots do if not seen[uid] then table.insert(keptSlots, uid) end end
        profile.CapturedCreatures, profile.SanctuarySlots = kept, keptSlots
        local output = {
            Uid = HttpService:GenerateGUID(false), CreatureId = first.CreatureId,
            Mutation = recipe.Mutation, Size = first.Size, FusionStage = recipe.Stage,
            IncomePerSec = math.floor(definition.BaseIncomePerSec * (sizeMultiplier :: number) * recipe.Multiplier), CapturedAt = os.time(),
        }
        assert(context.Sanctuary.AddCapture(player, output), "Fusion output could not be added")
        profile.FusionReadyAt = os.time() + (if benefits(player).FusionXP then Rules.FusionPassCooldownSeconds else Rules.FusionCooldownSeconds)
        if context.Rewards then context.Rewards.OnProgress(player, "Fusions", 1) end
        data.MarkDirty(player)
    end)
    if not ok then
        data.Unlock(player, "Fusion")
        data.Freeze(player, "A fusão foi interrompida para proteger seus dados.")
        warn("[FusionService]", message)
        return false, "Não foi possível concluir esta fusão com segurança."
    end
    local saved = data.SaveNow(player)
    data.Unlock(player, "Fusion")
    if not saved then data.Freeze(player, "Não foi possível salvar sua fusão com segurança."); return false, "Salvamento indisponível." end
    data.Sync(player)
    return true, definition.Name .. " " .. recipe.Mutation .. " fundida!"
end

function FusionService.FindAutomaticSelection(player: Player): {string}?
    local profile = context.Data.Get(player)
    if not profile or profile.Level < Rules.FusionLevel or (profile.FusionReadyAt or 0) > os.time() then return nil end
    -- Auto-fusion never consumes displayed creatures; manual selection stays explicit.
    local displayed: {[string]: boolean} = {}
    for _, uid in profile.SanctuarySlots do displayed[uid] = true end
    local groups: {[string]: {string}} = {}
    local required = FusionService.GetRequiredCount(player)
    for _, record in profile.CapturedCreatures do
        local definition = Config.Creatures[record.CreatureId]
        if definition and definition.Rarity == "Comum" and record.Mutation == "Normal" and not displayed[record.Uid] then
            local key = record.CreatureId .. ":" .. record.Mutation .. ":" .. record.Size
            local group = groups[key] or {}
            groups[key] = group
            table.insert(group, record.Uid)
            if #group == required then return group end
        end
    end
    return nil
end

function FusionService.Init(ctx: any)
    context = ctx
    ctx.Remotes:WaitForChild("FuseCreatures").OnServerEvent:Connect(function(player: Player, uids: any)
        local success, message = FusionService.Fuse(player, uids)
        feedback(player, message, success)
    end)
    ctx.Data.AddSnapshotProvider(function(player: Player, profile: any)
        return {Fusion = {RequiredCount = FusionService.GetRequiredCount(player), ReadyAt = profile.FusionReadyAt or 0, Unlocked = profile.Level >= Rules.FusionLevel}}
    end)
    Players.PlayerRemoving:Connect(function(player: Player) lastRequests[player] = nil end)
end

return FusionService
