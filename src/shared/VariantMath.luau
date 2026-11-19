--!strict
local Variants = {}
function Variants.FromQuantile(items: {any}, luck: number, quantile: number): any
    local total = 0
    for _, item in items do total += item.Weight * (if item.Name == "Normal" then 1 else luck) end
    local point, accumulated = math.clamp(quantile, 0, 1 - 1e-12) * total, 0
    for _, item in items do
        accumulated += item.Weight * (if item.Name == "Normal" then 1 else luck)
        if point < accumulated then return item end
    end
    return items[#items]
end
function Variants.GetPersonalLuck(profile: any, benefits: any, now: number): number
    local multiplier = if benefits.DoubleLuck then 2 else 1
    local boost = profile.Boosts and profile.Boosts.Luck
    if boost and boost.ExpiresAt > now then multiplier *= math.max(1, boost.Multiplier) end
    if profile.EquippedOrb == "Prismatica" and benefits.EternalPrism then multiplier *= 10 end
    return multiplier
end
function Variants.Apply(record: any, mutations: {any}, sizes: {any}, baseIncome: number, personalLuck: number): (any, any)
    local result = {Mutation = record.Mutation, Size = record.Size, IncomePerSec = record.IncomePerSec}
    if personalLuck <= 1 or type(record.MutationRoll) ~= "number" or type(record.SizeRoll) ~= "number" then return result, nil end
    local luck = (record.VariantLuck or 1) * personalLuck
    local mutation = Variants.FromQuantile(mutations, luck, record.MutationRoll)
    local size = Variants.FromQuantile(sizes, luck, record.SizeRoll)
    if mutation.Name == record.Mutation and size.Name == record.Size then return result, nil end
    result.Mutation, result.Size = mutation.Name, size.Name
    result.IncomePerSec = math.floor(baseIncome * mutation.Multiplier * size.Multiplier)
    return result, {MutationFrom = record.Mutation, SizeFrom = record.Size, LuckMultiplier = personalLuck}
end
return Variants
