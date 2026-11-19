--!strict
-- GDD rules plus explicit prototype balancing decisions; see docs/PROGRESSAO.md.
local ConfigProgression = {
    RebirthLevel = 40,
    RebirthGems = 5,
    RebirthStartingCoins = 150,
    FusionLevel = 10,
    FusionCount = 5,
    FusionPassCount = 4,
    FusionCooldownSeconds = 30,
    FusionPassCooldownSeconds = 0,
    ExtraSlotBaseCost = 10000,
    ExtraSlotCostGrowth = 2,
    MaxSanctuarySlots = 24,
    AutomationTickSeconds = 0.5,
    FusionRecipes = {
        Normal = { Mutation = "Dourada", Multiplier = 3, Stage = 1 },
        Dourada = { Mutation = "Cristal", Multiplier = 6, Stage = 2 },
        Cristal = { Mutation = "ArcoIris", Multiplier = 15, Stage = 3 },
    },
}

function ConfigProgression.GetExtraSlotCost(purchasedSlots: number): number
    return math.floor(ConfigProgression.ExtraSlotBaseCost * ConfigProgression.ExtraSlotCostGrowth ^ math.clamp(purchasedSlots, 0, 24))
end

return ConfigProgression
