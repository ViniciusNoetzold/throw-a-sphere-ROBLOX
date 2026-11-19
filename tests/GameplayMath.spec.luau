--!strict
local Math = require("../src/shared/GameplayMath")
local tests = 0
local function equal(actual: number, expected: number)
	tests += 1
	assert(math.abs(actual - expected) < 0.000001, string.format("expected %s, got %s", expected, actual))
end
local profile: any = {Level = 1, ThrowStrength = 10, Rebirths = 0, PityBonus = 0, ComboStreak = 0,
	ExtraSanctuarySlots = 0, EquippedOrb = "Comum", BestiaryRewardClaimed = {}, Boosts = {}, LastSeen = 1000}
equal(Math.GetSlotCapacity(profile, {}), 6)
profile.Level = 15
equal(Math.GetSlotCapacity(profile, {GiantSanctuary = true, GroupMember = true}), 17)
profile.ExtraSanctuarySlots = 100
equal(Math.GetSlotCapacity(profile, {GiantSanctuary = true}), 24)
equal(Math.GetTrainingGain(profile, {}), 1)
equal(Math.GetTrainingGain(profile, {TitanArms = true}), 2)
profile.Level = 1
equal(Math.GetRange(profile, {}), 47)
equal(Math.GetRange(profile, {TitanArms = true}), 63.45)
equal(Math.GetLuck(profile, {}, 1, 1000), 1)
profile.ComboStreak = 10
equal(Math.GetLuck(profile, {DoubleLuck = true}, 5, 1000), 15)
equal(Math.GetXPMultiplier(profile, {}, 1000), 1) -- Fever is not counted twice.
profile.EquippedOrb = "Prismatica"
equal(Math.GetLuck(profile, {EternalPrism = true}, 1, 1000), 15)
equal(Math.GetLuck(profile, {}, 1, 1000), 1.5) -- Orb string alone grants nothing.
profile.BestiaryRewardClaimed.PradariaSolar = true
profile.BestiaryRewardClaimed.Unclaimed = false
profile.ComboStreak = 0
equal(Math.GetLuck(profile, {GroupMember = true}, 1, 1000), 1.2)
profile.Boosts.Luck = {Multiplier = 3, ExpiresAt = 1100}
equal(Math.GetLuck(profile, {}, 1, 1099), 3.3)
equal(Math.GetLuck(profile, {}, 1, 1100), 1.1)
profile.Rebirths = 2
profile.Boosts.Coins = {Multiplier = 3, ExpiresAt = 1100}
profile.Boosts.XP = {Multiplier = 2, ExpiresAt = 1200}
equal(Math.GetIncomeMultiplier(profile, {DoubleCoins = true, GoldenVIP = true}, 1099), 22.5)
equal(Math.GetXPMultiplier(profile, {FusionXP = true, GoldenVIP = true}, 1100), 10)
equal(Math.GetOfflineIncome(profile, 10, 200, {}, 1200), 12000) -- 100s boosted + 100s regular, rebirth3x.
equal(Math.GetOfflineIncome(profile, 10, 200, {DoubleCoins = true, GoldenVIP = true}, 1200), 30000)
profile.Rebirths = 0
equal(Math.GetOfflineIncome(profile, 1, 100000, {}, 101000), 29000) -- First 8h include the initial 100s boost.
equal(Math.GetOfflineIncome(profile, 10, -1, {}, 1200), 0)
equal(Math.GetOfflineIncome(profile, 10, 200, {}, 900), 0)
print(string.format("GameplayMath: %d scenarios passed", tests))
