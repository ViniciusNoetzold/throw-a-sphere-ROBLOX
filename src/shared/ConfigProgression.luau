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
    TrainerRanks = {
        {Level = 1, Name = "Iniciante"}, {Level = 20, Name = "Aprendiz"}, {Level = 50, Name = "Treinador"},
        {Level = 125, Name = "Veterano"}, {Level = 200, Name = "Mestre"}, {Level = 400, Name = "Grão-Mestre"},
        {Level = 650, Name = "Treinador Supremo"}, {Level = 900, Name = "Lenda das Orbes"},
        {Level = 1000, Name = "Lenda Suprema"},
    },
    FusionRecipes = {
        Normal = { Mutation = "Dourada", Multiplier = 3, Stage = 1 },
        Dourada = { Mutation = "Cristal", Multiplier = 6, Stage = 2 },
        Cristal = { Mutation = "ArcoIris", Multiplier = 15, Stage = 3 },
    },
}

function ConfigProgression.GetTrainerRank(level: number): string
    local ranks = ConfigProgression.TrainerRanks
    for index = #ranks, 2, -1 do
        if level >= ranks[index].Level then return ranks[index].Name end
    end
    return ranks[1].Name
end

function ConfigProgression.GetExtraSlotCost(purchasedSlots: number): number
    return math.floor(ConfigProgression.ExtraSlotBaseCost * ConfigProgression.ExtraSlotCostGrowth ^ math.clamp(purchasedSlots, 0, 24))
end

return ConfigProgression
