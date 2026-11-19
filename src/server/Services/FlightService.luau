--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Rules = require(Shared.ConfigFlight)
local Reveals = require(Shared.ConfigReveal)
local Events = require(Shared.ConfigEvents)
local Math = require(Shared.FlightMath)
local Variants = require(Shared.VariantMath)
local Flight = {}
local ctx: any
local sessions: {[Player]: any} = {}
local requests: {[Player]: number} = {}
local lastEncounters: {[Player]: string} = {}
local decisions: {[Player]: string} = {}
local rng = Random.new()
function Flight.IsActive(player: Player): boolean return sessions[player] ~= nil end

local function send(player: Player, payload: any)
    if player.Parent then ctx.Remotes.FlightUpdate:FireClient(player, payload) end
end
local function ready(player: Player): (any, BasePart?)
    local profile = ctx.Data.Get(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not profile or not ctx.Data.IsLoaded(player) or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return nil, nil end
    return profile, root
end
local function isReusable(profile: any, orb: any, benefits: any): boolean
    return (orb.IsPrismatic and benefits.EternalPrism == true)
        or (orb.Tier ~= nil and orb.Tier <= (profile.OrbTier or 0))
end
local function eligible(player: Player, profile: any): (boolean, any)
    local orb = Config.Orbs[profile.EquippedOrb]
    local benefits = ctx.Monetization.GetBenefits(player)
    if not orb or (orb.IsPrismatic and not benefits.EternalPrism) then return false, benefits end
    if not isReusable(profile, orb, benefits) and (profile.Orbs[profile.EquippedOrb] or 0) < 1 then return false, benefits end
    return ctx.Sanctuary.CanCapture(player), benefits
end
local function releaseStance(entry: any)
    local root = entry.Root
    if root and root.Parent then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = entry.WasAnchored
    end
    local humanoid = entry.Humanoid
    if humanoid and humanoid.Parent then humanoid.AutoRotate = entry.WasAutoRotate end
end

function Flight.Prepare(player: Player, automatic: boolean?): boolean
    local now = Workspace:GetServerTimeNow()
    if now < (requests[player] or 0) then return false end
    requests[player] = now + 0.15
    if sessions[player] or ctx.Data.IsBusy(player) or (ctx.Training and ctx.Training.IsTraining(player)) then return false end
    local profile, root = ready(player)
    if not profile or not root then return false end
    if not Math.AtLine(root.Position, Rules.LinePosition, Rules.LineWidth, Rules.LineDepth) then return false end
    if not eligible(player, profile) then
        requests[player] = now + 1
        send(player, {State = "Blocked", Message = "Confira a orbe equipada e o espaço na coleção."})
        return false
    end
    if not automatic and profile.AutomationSettings and profile.AutomationSettings.Throw
        and ctx.Monetization.GetBenefits(player).AutoThrow then return false end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not humanoid then return false end
    local entry = {
        Id = HttpService:GenerateGUID(false), State = "Charging", StartedAt = now,
        Character = character, Root = root, WasAnchored = root.Anchored,
        Humanoid = humanoid, WasAutoRotate = humanoid.AutoRotate,
        Automatic = automatic == true,
    }
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    root.Anchored, humanoid.AutoRotate = true, false
    if CFrame then character:PivotTo(CFrame.lookAt(root.Position, root.Position + Rules.Direction)) end
    sessions[player] = entry
    decisions[player] = nil
    send(player, {State = "Charging", Id = entry.Id, StartedAt = now, Period = Rules.MeterPeriod})
    task.delay(Rules.ChargeTimeout, function() if sessions[player] == entry and entry.State == "Charging" then Flight.Cancel(player, entry.Id) end end)
    return true
end
function Flight.Cancel(player: Player, id: any): boolean
    local entry = sessions[player]
    if not entry or type(id) ~= "string" or #id > 80 or id ~= entry.Id then return false end
    -- Rollback is only allowed before resolution; a client can never refund an awarded drop.
    local profile = ctx.Data.Get(player)
    if entry.State == "Flying" then
        if profile and entry.Consumed then profile.Orbs[entry.OrbId] = (profile.Orbs[entry.OrbId] or 0) + entry.Count end
        ctx.Data.Unlock(player, entry.Owner)
        player:SetAttribute("FlightInProgress", false)
        ctx.Data.MarkDirty(player)
        ctx.Data.Sync(player)
    elseif entry.State == "Resolving" then return false end
    sessions[player] = nil
    releaseStance(entry)
    send(player, {State = "Cancelled", Id = id})
    return true
end
local function finish(player: Player, entry: any)
    if sessions[player] ~= entry or entry.State ~= "Flying" then return end
    local profile, root = ready(player)
    if not profile or not root or player.Character ~= entry.Character then Flight.Cancel(player, entry.Id); return end
    entry.State = "Resolving"
    local drops = {}
    local ok, result = pcall(function()
        local benefits = ctx.Monetization.GetBenefits(player)
        local bundle, best, totalXP = {}, nil, 0
        local previous = lastEncounters[player]
        local quality = entry.Power * .55 + entry.ZoneProgress * .45
        for _ = 1, entry.Count do
            -- Species is rolled here, after the flight. Never accepted from a client.
            local secret = rng:NextNumber() < Events.SecretSpawnChance
            local id, chance = Math.Species(ctx.EncounterCreatures or Config.Creatures, entry.BiomeId, Events.SpeciesWeights, rng:NextNumber(), quality, previous)
            if secret then id, chance = "Omnisfera", Events.SecretSpawnChance else chance *= 1 - Events.SecretSpawnChance end
            assert(id, "Biome has no eligible creatures")
            previous = id
            local definition = Config.Creatures[id]
            local orb = Config.Orbs[entry.OrbId]
            local strengthBonus = math.min(.6, entry.Strength / (20 + entry.ZoneIndex * 14) * .32)
            local aim = 1 + entry.Power * .35 + entry.ZoneProgress * .15 + strengthBonus + (if entry.Perfect then .2 else 0)
            local luck = ctx.Gameplay.GetLuck(profile, benefits, ctx.Weather.GetLuckMultiplier(), os.time())
            local elemental = if (entry.OrbId == "Rubi" and definition.Element == "Fogo") or (entry.OrbId == "Safira" and (definition.Element == "Agua" or definition.Element == "Gelo")) then 1.1 else 1
            local probability = Config.CalculateShakeProbability(orb.Power * elemental, aim, luck, definition.Difficulty, orb.IsMaster)
            local shakes = 0
            for shake = 1, 3 do if probability >= 1 or rng:NextNumber() < probability then shakes = shake else break end end
            local captured = shakes == 3
            local mutation = Variants.FromQuantile(Config.Mutations, luck, rng:NextNumber())
            local size = Variants.FromQuantile(Config.Sizes, luck, rng:NextNumber())
            local income = math.floor(definition.BaseIncomePerSec * mutation.Multiplier * size.Multiplier)
            local xp = if captured then definition.BaseXP else math.max(5, math.floor(definition.BaseXP * 0.35)) + (if entry.Perfect then 15 else 0)
            local fragments = 0
            if captured then
                local record = {Uid = HttpService:GenerateGUID(false), CreatureId = id, Mutation = mutation.Name, Size = size.Name, IncomePerSec = income, CapturedAt = os.time(), FusionStage = 0}
                assert(ctx.Sanctuary.AddCapture(player, record), "Reserved inventory capacity was lost")
                table.insert(drops, record)
                profile.TotalCaptures += 1
                profile.PityBonus = 0
                ctx.Rewards.OnProgress(player, "Captures", 1)
            else
                profile.PityBonus = math.min(1, profile.PityBonus + 0.05)
                fragments = ctx.Drops.AwardFailureFragments(player)
            end
            if entry.Perfect then ctx.Rewards.OnProgress(player, "Criticals", 1) end
            local _, gained = ctx.Progression.GrantXP(player, xp)
            totalXP += gained
            local item = {Thrower = player, CreatureId = id, CreatureName = definition.Name, Rarity = definition.Rarity,
                Captured = captured, ShakesPassed = shakes, MutationName = mutation.Name, SizeName = size.Name,
                IncomePerSec = income, XPGained = gained, FragmentsGained = fragments, Probability = probability, SpawnChance = chance}
            table.insert(bundle, item)
            if not best or Reveals[item.Rarity].Rank > Reveals[best.Rarity].Rank then best = item end
        end
        best = table.clone(best)
        best.Bundle, best.XPGained = bundle, totalXP
        best.FlightId, best.HitPos, best.StartPos = entry.Id, entry.EndPos, entry.StartPos
        best.OrbColor, best.Distance, best.BiomeId, best.OrbId = entry.Color, entry.Distance, entry.BiomeId, entry.OrbId
        best.IsCritical, best.IsLongShot = entry.Perfect, false
        best.NewLevel, best.LeveledUp = profile.Level, profile.Level > entry.Level
        best.PresentationDuration = 2.1 + Reveals[best.Rarity].Duration
        return best
    end)
    player:SetAttribute("FlightInProgress", false)
    if not ok then
        -- A partial award must never be refunded or retried. Preserve it and freeze writes.
        sessions[player] = nil
        releaseStance(entry)
        ctx.Data.Freeze(player, "Não foi possível concluir a revelação com segurança. Entre novamente.")
        send(player, {State = "Cancelled", Id = entry.Id})
        warn("[FlightService] Resolution failed:", result)
        return
    end
    ctx.Data.MarkDirty(player)
    local saved = ctx.Data.SaveNow(player)
    if not saved then
        sessions[player] = nil
        releaseStance(entry)
        ctx.Data.Freeze(player, "Não foi possível salvar o resultado do arremesso.")
        send(player, {State = "Cancelled", Id = entry.Id})
        return
    end
    lastEncounters[player] = result.CreatureId
    ctx.Data.Unlock(player, entry.Owner)
    entry.State = "Revealing"
    for _, record in drops do
        local dropped, problem = pcall(ctx.Drops.OnCapture, player, record, entry.StartPos)
        if not dropped then warn("[FlightService] Drop visual failed:", problem) end
    end
    ctx.Data.Sync(player)
    send(player, {State = "Landed", Id = entry.Id, Result = result, Automatic = entry.Automatic})
    ctx.Remotes.ThrowResult:FireAllClients(result)
    task.delay(result.PresentationDuration + 0.3, function()
        if sessions[player] == entry then
            sessions[player] = nil
            releaseStance(entry)
            if not entry.Automatic then decisions[player] = entry.Id end
            send(player, {State = "Ready", Id = entry.Id})
        end
    end)
end
function Flight.Launch(player: Player, id: any, automatic: boolean?): boolean
    local entry = sessions[player]
    if not entry or entry.State ~= "Charging" or type(id) ~= "string" or #id > 80 or id ~= entry.Id then return false end
    local now = Workspace:GetServerTimeNow()
    local elapsed = now - entry.StartedAt
    if elapsed < 0.1 then send(player, {State = "Charging", Id = entry.Id, StartedAt = entry.StartedAt, Period = Rules.MeterPeriod}); return false end
    if elapsed > Rules.ChargeTimeout or ctx.Data.IsBusy(player) then Flight.Cancel(player, id); return false end
    local profile, root = ready(player)
    if not profile or not root or entry.Character ~= player.Character or not Math.AtLine(root.Position,Rules.LinePosition,Rules.LineWidth,Rules.LineDepth) then Flight.Cancel(player, id); return false end
    local valid, benefits = eligible(player, profile)
    if not valid then Flight.Cancel(player, id); return false end
    local owner = "Flight:" .. entry.Id
    if not ctx.Data.TryLock(player, owner) then Flight.Cancel(player, id); return false end
    local orbId, orb = profile.EquippedOrb, Config.Orbs[profile.EquippedOrb]
    local infinite = isReusable(profile, orb, benefits)
    local capacity = Config.Constants.MaxInventoryCreatures - ctx.Data.GetInventoryCount(profile)
    local count = math.min(if benefits.TripleThrow then 3 else 1, capacity, if infinite then 3 else profile.Orbs[orbId])
    local power = if automatic then 0.75 else Math.Power(elapsed, Rules.MeterPeriod)
    local distance = math.min(Rules.MaxDistance or Rules.ZoneLength * #ctx.Layout.BiomeOrder, Math.Distance(profile.ThrowStrength, profile.Level, orb.Power, power, benefits.TitanArms))
    local biome, zoneIndex, zoneProgress = Math.Zone(distance, ctx.Layout.BiomeOrder, Rules.ZoneLength)
    entry.State, entry.Owner, entry.OrbId, entry.Consumed, entry.Count = "Flying", owner, orbId, not infinite, count
    entry.Power, entry.Perfect, entry.Distance, entry.BiomeId = power, power >= Rules.PerfectThreshold, distance, biome
    entry.Strength, entry.ZoneIndex, entry.ZoneProgress = profile.ThrowStrength, zoneIndex, zoneProgress
    entry.StartPos, entry.EndPos, entry.Color = root.Position + Vector3.new(0, 2, 0), Rules.LaunchOrigin + Rules.Direction * distance, orb.Color
    entry.Level = profile.Level
    entry.Duration = Rules.WindupSeconds + math.clamp(3.5 + distance / 500, Rules.MinFlightSeconds, Rules.MaxFlightSeconds)
    if player.Character and CFrame then player.Character:PivotTo(CFrame.lookAt(root.Position,root.Position+Rules.Direction)) end
    if not infinite then profile.Orbs[orbId] -= count end
    player:SetAttribute("FlightInProgress", true)
    ctx.Data.MarkDirty(player)
    ctx.Data.Sync(player, true)
    send(player, {State = "Flying", Id = id, StartedAt = now, Duration = entry.Duration, StartPos = entry.StartPos,
        EndPos = entry.EndPos, Power = power, Perfect = entry.Perfect, Distance = distance, BiomeId = biome, Color = orb.Color, OrbId = orbId, Count = count})
    ctx.Remotes.ThrowWindup:FireAllClients({Thrower=player,Power=power,Style=Math.ThrowStyle(power),StartedAt=now})
    task.delay(entry.Duration, function() finish(player, entry) end)
    return true
end
function Flight.AutoThrow(player: Player): boolean
    if not ctx.Monetization.GetBenefits(player).AutoThrow then return false end
    if not Flight.Prepare(player, true) then return false end
    local entry = sessions[player]
    task.delay(0.2, function() if sessions[player] == entry then Flight.Launch(player, entry.Id, true) end end)
    return true
end
function Flight.Choose(player: Player, id: any, choice: any): boolean
    if type(id) ~= "string" or #id > 80 or decisions[player] ~= id or sessions[player] then return false end
    if choice ~= "Retry" and choice ~= "Base" then return false end
    local profile, root = ready(player)
    if not profile or not root or ctx.Data.IsBusy(player) or (ctx.Training and ctx.Training.IsTraining(player)) then return false end
    if not Math.AtLine(root.Position, Rules.LinePosition, Rules.LineWidth, Rules.LineDepth) then return false end
    if choice == "Base" then
        local position = ctx.World.GetSanctuaryReturnPosition(player)
        if not position or not player.Character then return false end
        player.Character:PivotTo(CFrame.new(position))
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        player:SetAttribute("CurrentBiome", "Hub")
    end
    decisions[player] = nil
    send(player, {State = "ChoiceAccepted", Id = id, Choice = choice})
    return true
end
function Flight.Init(context: any)
    ctx = context
    ctx.Layout = ctx.Layout or require(Shared.ConfigWorld)
    ctx.Remotes.PrepareThrow.OnServerEvent:Connect(function(player) Flight.Prepare(player) end)
    ctx.Remotes.LaunchThrow.OnServerEvent:Connect(function(player, id) Flight.Launch(player, id, false) end)
    ctx.Remotes.CancelThrow.OnServerEvent:Connect(function(player, id)
        local entry = sessions[player]
        -- Flight cannot be cancelled/refunded remotely after launch.
        if entry and entry.State == "Charging" then Flight.Cancel(player, id) end
    end)
    ctx.Remotes.ChooseAfterThrow.OnServerEvent:Connect(function(player, id, choice)
        if decisions[player] == id and id ~= nil and not Flight.Choose(player, id, choice) then
            send(player, {State = "ChoiceRejected", Id = id})
        end
    end)
    local function bind(player: Player)
        player.CharacterRemoving:Connect(function()
            decisions[player] = nil
            local entry = sessions[player]
            if entry then Flight.Cancel(player, entry.Id) end
        end)
    end
    Players.PlayerAdded:Connect(bind)
    for _, player in Players:GetPlayers() do bind(player) end
    Players.PlayerRemoving:Connect(function(player)
        local entry = sessions[player]
        if entry then Flight.Cancel(player, entry.Id) end
        requests[player], decisions[player], lastEncounters[player] = nil, nil, nil
    end)
end
return Flight
