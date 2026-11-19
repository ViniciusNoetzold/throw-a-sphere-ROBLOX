--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Drops = {}
local ctx: any
local rules: any
local random = Random.new()
local active: {[string]: any} = {}
local lastCraft: {[Player]: number} = {}
local folder: Folder?
local function finite(value: any): boolean return type(value) == "number" and value == value and math.abs(value) < math.huge end
local function erase(record: any)
    active[record.Id] = nil
    if record.Part then record.Part:Destroy() end
end
function Drops.Spawn(player: Player, position: Vector3, reward: any): string?
    if not ctx.Data.Get(player) or not finite(reward.Coins or 0) or (reward.Coins or 0) < 0 then return nil end
    local masters = reward.MasterOrbs or 0
    if not finite(masters) or masters < 0 or masters % 1 ~= 0 or masters > 100 then return nil end
    local coins = math.min(rules.MaxCoinsPerDrop, reward.Coins or 0)
    if coins == 0 and masters == 0 then return nil end
    local count, oldest = 0, nil
    for _, record in active do
        if record.Owner == player then count += 1; if not oldest or record.ExpiresAt < oldest.ExpiresAt then oldest = record end end
    end
    local expires = Workspace:GetServerTimeNow() + rules.Lifetime
    if count >= rules.MaxActivePerPlayer and oldest then
        oldest.Coins = math.min(rules.MaxCoinsPerDrop, oldest.Coins + coins)
        oldest.MasterOrbs += masters
        oldest.ExpiresAt = expires
        return oldest.Id
    end
    local id = HttpService:GenerateGUID(false)
    local record = {Id = id, Owner = player, Position = position, Coins = coins, MasterOrbs = masters, ExpiresAt = expires}
    active[id] = record
    if not ctx.DisableVisuals then
        local part = Instance.new("Part")
        part.Name, part.Shape, part.Size = "Loot", Enum.PartType.Ball, Vector3.new(1.4,1.4,1.4)
        part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
        part.Material, part.Color = Enum.Material.Neon, if masters > 0 then Color3.fromRGB(255,100,190) else Color3.fromRGB(255,215,65)
        part.Position = position + Vector3.new(0,1.5,0)
        part:SetAttribute("DropId", id)
        part:SetAttribute("OwnerUserId", player.UserId)
        part:SetAttribute("ExpiresAt", expires)
        part.Parent, record.Part = folder, part
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText, prompt.ObjectText, prompt.MaxActivationDistance = "Coletar", "Sua recompensa", rules.PickupRange
        prompt.RequiresLineOfSight, prompt.Parent = false, part
        prompt.Triggered:Connect(function(who) Drops.Collect(who, id) end)
    end
    return id
end
local function collect(player: Player, id: string, automatic: boolean): boolean
    local record = active[id]
    if not record or record.Owner ~= player or record.ExpiresAt <= Workspace:GetServerTimeNow() or ctx.Data.IsBusy(player) then return false end
    local profile = ctx.Data.Get(player)
    if not profile then return false end
    if not automatic then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 or (root.Position - record.Position).Magnitude > rules.PickupRange then return false end
    end
    local owner = "Drop:" .. id
    if not ctx.Data.TryLock(player, owner) then return false end
    erase(record) -- Claim is single-use before any callbacks or snapshots.
    if record.Coins > 0 then ctx.Data.AddCoins(player, record.Coins) end
    profile.Orbs.Mestre = (profile.Orbs.Mestre or 0) + record.MasterOrbs
    ctx.Data.MarkDirty(player)
    ctx.Data.Unlock(player, owner)
    ctx.Data.Sync(player)
    return true
end
function Drops.Collect(player: Player, id: any): boolean
    return type(id) == "string" and #id <= 80 and collect(player, id, false) or false
end
function Drops.AwardFailureFragments(player: Player): number
    local profile = ctx.Data.Get(player)
    if not profile then return 0 end
    local amount = random:NextInteger(rules.FailureFragmentsMin, rules.FailureFragmentsMax)
    local previous = profile.OrbFragments or 0
    profile.OrbFragments = math.min(1e9, previous + amount)
    ctx.Data.MarkDirty(player)
    return profile.OrbFragments - previous
end
function Drops.OnCapture(player: Player, record: any, position: Vector3, isBoss: boolean?): string?
    local seconds = if isBoss then rules.BossCoinSeconds else rules.CaptureCoinSeconds
    local coins = math.max(5, math.floor(record.IncomePerSec * seconds))
    local masters = if random:NextNumber() < rules.MasterChance then 1 else 0
    return Drops.Spawn(player, position, {Coins = coins, MasterOrbs = masters})
end
function Drops.CraftOrbFragments(player: Player): (boolean, string)
    if not ctx.Data.IsLoaded(player) or ctx.Data.IsBusy(player) or os.clock() < (lastCraft[player] or 0) then return false, "Aguarde concluir sua ação." end
    lastCraft[player] = os.clock() + 0.4
    if not ctx.Data.TryLock(player, "CraftFragments") then return false, "Aguarde concluir sua ação." end
    local profile = ctx.Data.Get(player)
    if not profile or (profile.OrbFragments or 0) < rules.CraftCost then ctx.Data.Unlock(player, "CraftFragments"); return false, "Precisa de 10 fragmentos para criar uma Orbe Comum." end
    if (profile.Orbs.Comum or 0) >= 1e9 then ctx.Data.Unlock(player, "CraftFragments"); return false, "Seu estoque de Orbes Comuns está no limite." end
    profile.OrbFragments -= rules.CraftCost
    profile.Orbs.Comum = (profile.Orbs.Comum or 0) + 1
    ctx.Data.MarkDirty(player)
    local saved = ctx.Data.SaveNow(player)
    if not saved then ctx.Data.Freeze(player, "Não foi possível salvar a criação da orbe com segurança.") end
    ctx.Data.Unlock(player, "CraftFragments")
    if not saved then return false, "Salvamento indisponível." end
    ctx.Data.Sync(player)
    return true, "10 fragmentos viraram uma Orbe Comum!"
end
function Drops.Tick()
    local timestamp = Workspace:GetServerTimeNow()
    for id, record in active do
        if record.ExpiresAt <= timestamp or not record.Owner.Parent then erase(record); continue end
        local profile = ctx.Data.Get(record.Owner)
        if not profile then continue end
        local benefits = ctx.Monetization.GetBenefits(record.Owner)
        local automatic = benefits.MegaCollector == true or (profile.Level >= 3 and ctx.World.IsAtSanctuary(record.Owner))
        if automatic then collect(record.Owner, id, true) end
    end
end
function Drops.GetSnapshot(player: Player, profile: any): any
    local list = {}
    for id, record in active do if record.Owner == player and record.ExpiresAt > Workspace:GetServerTimeNow() then table.insert(list, {Id = id, Coins = record.Coins, MasterOrbs = record.MasterOrbs, ExpiresAt = record.ExpiresAt, Position = record.Position}) end end
    return {OrbFragments = profile.OrbFragments or 0, DropInfo = {ActiveCount = #list, Drops = list, CraftCost = rules.CraftCost, MasterChance = rules.MasterChance, AutoUnlocked = profile.Level >= 3, MegaCollector = ctx.Monetization.GetBenefits(player).MegaCollector == true}}
end
function Drops.Init(context: any)
    ctx = context
    rules = ctx.DropConfig or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigDrops"))
    if not ctx.DisableVisuals then folder = Instance.new("Folder"); folder.Name, folder.Parent = "ThrowASphereDrops", Workspace end
    for name, action in {CraftOrbFragments = Drops.CraftOrbFragments, CollectDrop = Drops.Collect} do
        local remote = ctx.Remotes:FindFirstChild(name)
        if remote then remote.OnServerEvent:Connect(function(player, id)
            local success, message = action(player, id)
            local feedback = ctx.Remotes:FindFirstChild("ActionFeedback")
            if feedback and message then feedback:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"}) end
        end) end
    end
    ctx.Data.AddSnapshotProvider(Drops.GetSnapshot)
    Players.PlayerRemoving:Connect(function(player) lastCraft[player] = nil; for _, record in active do if record.Owner == player then erase(record) end end end)
    if not ctx.DisableLoops then task.spawn(function() while true do task.wait(0.5); Drops.Tick() end end) end
end
return Drops
