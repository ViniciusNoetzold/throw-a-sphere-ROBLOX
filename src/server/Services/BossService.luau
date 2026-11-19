--!strict
-- Cooperative resistance is server-owned. The final hit cannot steal other contributors' rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Boss = {}
local ctx: any
local settings: any
local active: any

function Boss.GetState(): any
    if not active then return {Active = false} end
    local contributors = 0
    for _ in active.Contributors do contributors += 1 end
    return {Active = not active.Defeated, Id = active.Id, CreatureId = active.CreatureId, Stability = active.Stability, MaxStability = settings.Stability, EndsAt = active.EndsAt, Contributors = contributors}
end
function Boss.Start(eventId: string, creatureId: string, endsAt: number): boolean
    if active and not active.Defeated then return false end
    local definition = Config.Creatures[creatureId]
    if not definition then return false end
    local layout = ctx.WorldConfig or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))
    local id = HttpService:GenerateGUID(false)
    local model = ctx.Spawn.Spawn(creatureId, layout.BossPosition, {BiomeId = "PradariaSolar", Kind = "Boss", BossId = id, EventId = eventId, ExpiresAt = endsAt, NoRespawn = true})
    active = {Id = id, EventId = eventId, CreatureId = creatureId, Model = model, Stability = settings.Stability, EndsAt = endsAt, Contributors = {}, Granted = {}, Defeated = false}
    local wild = if ctx.Spawn.Get then ctx.Spawn.Get(model) else nil
    active.Reward = {Mutation = if wild then wild.Mutation else "Normal", Size = if wild then wild.Size else "Normal", IncomePerSec = if wild then wild.IncomePerSec else definition.BaseIncomePerSec}
    if wild then active.Reward.MutationRoll, active.Reward.SizeRoll, active.Reward.VariantLuck = wild.MutationRoll, wild.SizeRoll, wild.VariantLuck end
    model:SetAttribute("BossStability", settings.Stability)
    model:SetAttribute("BossMaxStability", settings.Stability)
    return true
end
function Boss.CanHit(player: Player, model: Model): boolean
    return active ~= nil and not active.Defeated and active.Model == model and active.EndsAt > Workspace:GetServerTimeNow() and ctx.Data.Get(player) ~= nil
end

local function reward(encounter: any, player: Player, attempt: number)
    if encounter.Granted[player.UserId] or not ctx.Data.Get(player) then return end
    local owner = "BossReward:" .. encounter.Id
    if ctx.Data.IsBusy(player) or (ctx.Data.TryLock and not ctx.Data.TryLock(player, owner)) then
        if player.Parent then task.delay(1, function() reward(encounter, player, attempt + 1) end) end
        return
    end
    local profile = ctx.Data.Get(player)
    if not profile then if ctx.Data.Unlock then ctx.Data.Unlock(player, owner) end; return end
    local definition = Config.Creatures[encounter.CreatureId]
    local final = if ctx.Capture and ctx.Capture.ApplyVariantBonus then ctx.Capture.ApplyVariantBonus(player, encounter.Reward, encounter.CreatureId) else encounter.Reward
    local record = {Uid = HttpService:GenerateGUID(false), CreatureId = encounter.CreatureId, Mutation = final.Mutation, Size = final.Size, IncomePerSec = final.IncomePerSec, CapturedAt = os.time(), FusionStage = 0}
    local success, failure = pcall(function()
        -- Mark before callbacks: a second completion cannot grant this encounter twice.
        encounter.Granted[player.UserId] = true
        if ctx.Sanctuary.CanCapture(player) and ctx.Sanctuary.AddCapture(player, record) then
            profile.TotalCaptures = (profile.TotalCaptures or 0) + 1
            if ctx.Rewards then ctx.Rewards.OnProgress(player, "Captures", 1) end
        else
            ctx.Data.AddCoins(player, definition.BaseIncomePerSec * settings.CompensationIncomeSeconds)
            profile.Bestiary[encounter.CreatureId] = true
        end
        ctx.Progression.GrantXP(player, definition.BaseXP)
        ctx.Data.MarkDirty(player)
        if ctx.Drops and encounter.Model.PrimaryPart then ctx.Drops.OnCapture(player, record, encounter.Model.PrimaryPart.Position, true) end
    end)
    if ctx.Data.Unlock then ctx.Data.Unlock(player, owner) end
    if not success then warn("[Boss] Reward callback failed", failure); return end
    ctx.Data.Sync(player)
    local feedback = ctx.Remotes:FindFirstChild("ActionFeedback")
    if feedback then feedback:FireClient(player, {Message = "Chefe derrotado! Recompensa de contribuição recebida.", Kind = "Success"}) end
end
function Boss.TryHit(player: Player, model: Model, power: number): (boolean, boolean)
    if not Boss.CanHit(player, model) or power ~= power or power <= 0 or power == math.huge then return false, false end
    local encounter = active
    local damage = math.clamp(math.sqrt(power) * settings.PowerScale, settings.MinDamage, settings.MaxDamage)
    encounter.Contributors[player.UserId] = player
    encounter.Stability = math.max(0, encounter.Stability - damage)
    model:SetAttribute("BossStability", encounter.Stability)
    if encounter.Stability > 0 then return true, false end
    encounter.Defeated = true
    ctx.Spawn.Resolve(model, true)
    for _, contributor in encounter.Contributors do reward(encounter, contributor, 0) end
    if ctx.Weather then ctx.Weather.Broadcast() end
    return true, true
end
Boss.Damage = Boss.TryHit
function Boss.EndEvent(eventId: string)
    if active and active.EventId == eventId then
        ctx.Spawn.Retire(active.Model)
        active = nil
    end
end
function Boss.Init(context: any)
    ctx = context
    local config = ctx.EventConfig or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigEvents"))
    settings = config.Boss
    Players.PlayerRemoving:Connect(function(player)
        if active then active.Contributors[player.UserId] = nil end
    end)
end
return Boss
