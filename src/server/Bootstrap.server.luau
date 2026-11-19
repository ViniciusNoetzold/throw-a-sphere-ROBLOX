--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = script.Parent.Services
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ctx: any = {
    Remotes = Remotes,
    Gameplay = require(ReplicatedStorage.Shared.GameplayMath),
    Data = require(Services.DataService),
    World = require(Services.WorldService),
    Spawn = require(Services.SpawnService),
    Sanctuary = require(Services.SanctuaryService),
    Progression = require(Services.ProgressionService),
    Capture = require(Services.CaptureService),
    Flight = require(Services.FlightService),
    Training = require(Services.TrainingService),
    Biomes = require(Services.BiomeService),
    Weather = require(Services.WeatherEventService),
    Boss = require(Services.BossService),
    Rewards = require(Services.RewardService),
    Fusion = require(Services.FusionService),
    Automation = require(Services.AutomationService),
    Monetization = require(Services.MonetizationService),
    Trade = require(Services.TradeService),
    Auctions = require(Services.AuctionService),
    Leaderboards = require(Services.LeaderboardPodiumService),
    Drops = require(Services.DropService),
}

-- Register every callback before asynchronous profile loads start.
-- Recover transactions before benefits, offline income and world assignment.
ctx.World.Init(ctx)
require(Services.FlightWorldService).Init(ctx)
ctx.Biomes.Init(ctx)
ctx.Boss.Init(ctx)
ctx.Weather.Init(ctx)
ctx.Spawn.Init(ctx)
ctx.Trade.Init(ctx)
ctx.Auctions.Init(ctx)
ctx.Monetization.Init(ctx)
ctx.Sanctuary.Init(ctx.Data, ctx.World, ctx)
ctx.Progression.Init(ctx.Data, ctx.Sanctuary, Remotes, ctx)
ctx.Rewards.Init(ctx)
ctx.Fusion.Init(ctx)
ctx.Capture.Init(ctx)
ctx.Flight.Init(ctx)
ctx.Training.Init(ctx)
ctx.Automation.Init(ctx)
ctx.Drops.Init(ctx)
ctx.Leaderboards.Init(ctx)
ctx.Data.AddSnapshotProvider(function(player: Player, profile: any)
    local benefits = ctx.Monetization.GetBenefits(player)
    return {
        EffectiveLuck = ctx.Gameplay.GetLuck(profile, benefits, ctx.Weather.GetLuckMultiplier(), os.time()),
        MaxRange = ctx.Gameplay.GetRange(profile, benefits),
        SlotCapacity = ctx.Gameplay.GetSlotCapacity(profile, benefits),
    }
end)
ctx.Data.Init(Remotes)
print("[ThrowASphere] Base integrada: captura, progressão, recompensas, mundo e economia.")
