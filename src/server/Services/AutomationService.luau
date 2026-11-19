--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigProgression"))

local AutomationService = {}
local context: any
local lastRequests: {[Player]: number} = {}
local modes = {Throw = true, Train = true, Fusion = true}
local function permissions(player: Player): any
    local benefits = context.Monetization.GetBenefits(player)
    return {Throw = benefits.AutoThrow == true, Train = benefits.AutoThrow == true or benefits.GroupMember == true, Fusion = benefits.MegaCollector == true}
end

function AutomationService.SetMode(player: Player, mode: any, enabled: any): (boolean, string)
    if type(mode) ~= "string" or not modes[mode] or type(enabled) ~= "boolean" then return false, "Modo automático inválido." end
    if not context.Data.IsLoaded(player) or context.Data.IsBusy(player) then return false, "Aguarde concluir sua ação." end
    local now = os.clock()
    if now - (lastRequests[player] or -math.huge) < 0.3 then return false, "Aguarde concluir sua ação." end
    lastRequests[player] = now
    local profile = context.Data.Get(player)
    if enabled and not permissions(player)[mode] then return false, "Você ainda não possui acesso a este modo automático." end
    profile.AutomationSettings[mode] = enabled
    context.Data.MarkDirty(player)
    context.Data.Sync(player)
    return true, if enabled then "Modo automático ativado." else "Modo automático desativado."
end

function AutomationService.TickPlayer(player: Player)
    if not context.Data.IsLoaded(player) then return end
    local profile = context.Data.Get(player)
    if not profile or context.Data.IsBusy(player) then return end
    local granted = permissions(player)
    local settings = profile.AutomationSettings
    for mode in modes do
        if settings[mode] and not granted[mode] then settings[mode] = false; context.Data.MarkDirty(player) end
    end
    if settings.Train and context.World.IsInSanctuary(player) and not (context.Training and context.Training.IsTraining(player)) then context.Progression.Train(player) end
    if context.Data.IsBusy(player) then return end
    if settings.Throw then
        if context.Flight then context.Flight.AutoThrow(player)
        else
            local biome = context.Biomes.GetCurrentBiome(player)
            local target, hitPosition = context.Spawn.FindAutoTarget(player, biome)
            if target and hitPosition then context.Capture.TryThrow(player, target, hitPosition) end
        end
    end
    if context.Data.IsBusy(player) then return end
    if settings.Fusion and context.Fusion then
        local selected = context.Fusion.FindAutomaticSelection(player)
        if selected then context.Fusion.Fuse(player, selected) end
    end
end

function AutomationService.Init(ctx: any)
    context = ctx
    ctx.Remotes:WaitForChild("SetAutoMode").OnServerEvent:Connect(function(player: Player, mode: any, enabled: any)
        local success, message = AutomationService.SetMode(player, mode, enabled)
        ctx.Remotes.ActionFeedback:FireClient(player, {Message = message, Kind = if success then "Success" else "Error"})
    end)
    ctx.Data.AddSnapshotProvider(function(player: Player, profile: any)
        local allowed = permissions(player)
        local settings = profile.AutomationSettings
        return {Automation = {Throw = settings.Throw == true, Train = settings.Train == true, Fusion = settings.Fusion == true,
            CanThrow = allowed.Throw, CanTrain = allowed.Train, CanFusion = allowed.Fusion}}
    end)
    Players.PlayerRemoving:Connect(function(player: Player) lastRequests[player] = nil end)
    task.spawn(function()
        while true do
            task.wait(Rules.AutomationTickSeconds)
            for _, player in Players:GetPlayers() do
                local ok, message = pcall(AutomationService.TickPlayer, player)
                if not ok then warn("[AutomationService] A player tick failed:", message) end
            end
        end
    end)
end

return AutomationService
