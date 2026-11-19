--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Weather = {}
local ctx: any
local settings: any
local active: any = nil
local serial, rotation, nextEventAt = 0, 0, 0
local totemEndsAt, totemMultiplier, totemOwner = 0, 1, ""

local function now(): number return Workspace:GetServerTimeNow() end
function Weather.GetLuckMultiplier(): number
    return (if active and active.EndsAt > now() then active.LuckMultiplier else 1) * (if totemEndsAt > now() then totemMultiplier else 1)
end
function Weather.GetState(): any
    return {
        Id = if active then active.Id else "", EventId = if active then active.EventId else "",
        Name = if active then active.Name else "SEM EVENTO ATIVO", StartedAt = if active then active.StartedAt else 0,
        EndsAt = if active then active.EndsAt else 0, NextAt = nextEventAt,
        LuckMultiplier = Weather.GetLuckMultiplier(), TotemEndsAt = totemEndsAt, TotemOwner = totemOwner,
        Boss = if ctx and ctx.Boss then ctx.Boss.GetState() else nil,
    }
end
Weather.GetSnapshot = Weather.GetState
function Weather.Broadcast()
    local remote = ctx and ctx.Remotes:FindFirstChild("WorldStateUpdate")
    if remote then remote:FireAllClients(Weather.GetState()) end
end
function Weather.Start(eventId: string?): boolean
    if active then return false end
    rotation = rotation % #settings.Order + 1
    local key = eventId or settings.Order[rotation]
    local definition = settings.Definitions[key]
    if not definition then return false end
    serial += 1
    local timestamp = now()
    active = {Id = "Event_" .. serial, EventId = key, Name = definition.Name, StartedAt = timestamp, EndsAt = timestamp + settings.Duration, LuckMultiplier = definition.LuckMultiplier}
    nextEventAt = timestamp + settings.Interval
    if definition.SpecialCreatureId then
        local layout = ctx.WorldConfig or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))
        ctx.Spawn.Spawn(definition.SpecialCreatureId, layout.EventPosition, {BiomeId = "PradariaSolar", Kind = "Event", EventId = active.Id, ExpiresAt = active.EndsAt, NoRespawn = true})
    end
    if ctx.Boss then ctx.Boss.Start(active.Id, definition.BossCreatureId, active.EndsAt) end
    Weather.Broadcast()
    return true
end
function Weather.Step(timestamp: number?)
    local current = timestamp or now()
    if active and current >= active.EndsAt then
        local id = active.Id
        active = nil
        ctx.Spawn.RemoveEvent(id)
        if ctx.Boss then ctx.Boss.EndEvent(id) end
        Weather.Broadcast()
    end
    if not active and current >= nextEventAt then Weather.Start() end
end
function Weather.ActivateGlobalLuck(player: Player, multiplier: number?, duration: number?): boolean
    if not ctx.Data.Get(player) then return false end
    local strength = multiplier or settings.TotemMultiplier
    local seconds = duration or settings.TotemDuration
    if strength ~= strength or seconds ~= seconds or strength < 1 or seconds <= 0 or seconds == math.huge then return false end
    strength = math.clamp(strength, 1, settings.TotemMultiplier)
    seconds = math.min(seconds, settings.TotemDuration)
    local timestamp = now()
    if totemEndsAt >= timestamp + settings.MaxTotemSeconds then return false end
    totemEndsAt = math.min(timestamp + settings.MaxTotemSeconds, math.max(timestamp, totemEndsAt) + seconds)
    totemMultiplier, totemOwner = math.max(totemMultiplier, strength), player.DisplayName
    Weather.Broadcast()
    return true
end
function Weather.UseTotem(player: Player): boolean return Weather.ActivateGlobalLuck(player, settings.TotemMultiplier, settings.TotemDuration) end
function Weather.SummonEvent(player: Player, eventId: string?): boolean
    if not ctx.Data.Get(player) then return false end
    return Weather.Start(eventId)
end
function Weather.Init(context: any)
    ctx = context
    settings = ctx.EventConfig or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigEvents"))
    nextEventAt = now() + settings.Interval
    if ctx.Data.AddSnapshotProvider then ctx.Data.AddSnapshotProvider(function() return {Weather = Weather.GetState()} end) end
    local request = ctx.Remotes:FindFirstChild("RequestWorldState")
    local lastRequest: {[Player]: number} = {}
    if request then request.OnServerEvent:Connect(function(player)
        if not ctx.Data.Get(player) or now() - (lastRequest[player] or 0) < 1 then return end
        lastRequest[player] = now()
        local remote = ctx.Remotes:FindFirstChild("WorldStateUpdate")
        if remote then remote:FireClient(player, Weather.GetState()) end
    end) end
    if not ctx.DisableLoops then task.spawn(function() while true do task.wait(1); Weather.Step(); Weather.Broadcast() end end) end
end
return Weather
