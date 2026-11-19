--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Biomes = {}
local ctx: any
local nextTravel: {[Player]: number} = {}
local nextUnlock: {[Player]: number} = {}

local function feedback(player: Player, message: string, errorKind: boolean?)
    local remote = ctx.Remotes:FindFirstChild("ActionFeedback")
    if remote then remote:FireClient(player, {Message = message, Kind = if errorKind then "Error" else "Success"}) end
end
function Biomes.CountBestiary(profile: any): number
    local count = 0
    for id, discovered in profile.Bestiary or {} do if discovered == true and Config.Creatures[id] then count += 1 end end
    return count
end
function Biomes.CanAccess(player: Player, id: string): boolean
    local profile = ctx.Data.Get(player)
    if not profile then return false end
    if id == "Hub" or id == "PradariaSolar" then return true end
    if id == "TradingPlaza" then return profile.Level >= 15 end
    local definition = Config.Biomes[id]
    return definition ~= nil and definition.Enabled == true and (profile.UnlockedBiomes or {})[id] == true
end
function Biomes.Unlock(player: Player, id: any): boolean
    if typeof(id) ~= "string" or #id > 40 or ctx.Data.IsBusy(player) then return false end
    local profile, definition = ctx.Data.Get(player), Config.Biomes[id]
    if not profile or not definition or not definition.Enabled then return false end
    if Biomes.CanAccess(player, id) then return true end
    local now = os.clock()
    if now < (nextUnlock[player] or 0) then return false end
    nextUnlock[player] = now + 0.4
    if profile.Level < definition.RequiredLevel or Biomes.CountBestiary(profile) < definition.RequiredBestiary then
        feedback(player, string.format("Precisa de nível %d e %d espécies descobertas.", definition.RequiredLevel, definition.RequiredBestiary), true)
        return false
    end
    if profile.Coins < definition.Cost then feedback(player, "Moedas insuficientes para abrir este bioma.", true); return false end
    -- This transaction never yields, so two requests cannot debit the same unlock twice.
    profile.Coins -= definition.Cost
    profile.UnlockedBiomes[id] = true
    ctx.Data.MarkDirty(player)
    ctx.Data.Sync(player)
    feedback(player, definition.Name .. " desbloqueado!")
    return true
end
function Biomes.Travel(player: Player, id: any): boolean
    if typeof(id) ~= "string" or #id > 40 or ctx.Data.IsBusy(player) then return false end
    if not Biomes.CanAccess(player, id) then feedback(player, "Desbloqueie o destino primeiro. A praça de trocas exige nível 15.", true); return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    local now = os.clock()
    if now < (nextTravel[player] or 0) then return false end
    local destination = if id == "Hub" then ctx.World.GetHubPosition() elseif id == "TradingPlaza" then ctx.World.GetTradingPosition() else ctx.World.GetBiomePosition(id)
    if not destination then return false end
    nextTravel[player] = now + 0.8
    character:PivotTo(CFrame.new(destination))
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    player:SetAttribute("CurrentBiome", id)
    ctx.Data.Sync(player)
    return true
end
function Biomes.GetCurrentBiome(player: Player): string
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return if root and root:IsA("BasePart") then ctx.World.GetBiomeAtPosition(root.Position) else "Hub"
end
function Biomes.IsInTradingPlaza(player: Player): boolean return Biomes.CanAccess(player, "TradingPlaza") and Biomes.GetCurrentBiome(player) == "TradingPlaza" end
function Biomes.ClaimNeonResearch(player: Player): boolean
    if not Biomes.CanAccess(player, "FlorestaNeon") or Biomes.GetCurrentBiome(player) ~= "FlorestaNeon" then return false end
    local profile = ctx.Data.Get(player)
    local key = "NeonResearch"
    if profile.OneTimeGrants[key] then
        feedback(player, "Pesquisa concluída. As criaturas daqui são para observação. Arremesse na faixa para capturar.")
        return false
    end
    if not ctx.Data.TryLock(player, key) then return false end
    profile.OneTimeGrants[key] = true
    local strength = math.min(20, math.max(0, 10000 - profile.ThrowStrength))
    profile.ThrowStrength += strength
    local _, gained = ctx.Progression.GrantXP(player, 80)
    ctx.Data.MarkDirty(player)
    local saved = ctx.Data.SaveNow(player)
    if not saved then ctx.Data.Freeze(player, "Salvamento da pesquisa indisponível.") end
    ctx.Data.Unlock(player, key)
    if not saved then return false end
    ctx.Data.Sync(player)
    feedback(player, "Pesquisa Neon concluída • +" .. strength .. " força e +" .. gained .. " XP. Volte à faixa para capturar.")
    return true
end
-- Internal rebirth hook: its caller already owns the profile transaction lock.
function Biomes.ReturnToMeadow(player: Player): boolean
    local character = player.Character
    local destination = ctx.World.GetBiomePosition("PradariaSolar")
    if not character or not destination or not ctx.Data.Get(player) then return false end
    character:PivotTo(CFrame.new(destination))
    player:SetAttribute("CurrentBiome", "PradariaSolar")
    return true
end
function Biomes.Init(context: any)
    ctx = context
    for _, item in {{"UnlockBiome", Biomes.Unlock}, {"TravelToBiome", Biomes.Travel}} do
        local remote = ctx.Remotes:FindFirstChild(item[1])
        if remote then remote.OnServerEvent:Connect(item[2]) end
    end
    if ctx.Data.AddSnapshotProvider then ctx.Data.AddSnapshotProvider(function(player) return {CurrentBiome = Biomes.GetCurrentBiome(player)} end) end
    Players.PlayerRemoving:Connect(function(player) nextTravel[player], nextUnlock[player] = nil, nil end)
end
return Biomes
