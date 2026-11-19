--!strict
local Math = require(script.Parent.CaptureMath)
local Variants = require(script.Parent.ConfigMutacoes)
local TrainingRules = require(script.Parent.ConfigTraining)
local TrainingMath = require(script.Parent.TrainingMath)
local GameplayMath = require(script.Parent.GameplayMath)
return {
	Orbs = require(script.Parent.ConfigOrbes),
	Creatures = require(script.Parent.ConfigCriaturas),
	Biomes = require(script.Parent.ConfigBiomas),
	Mutations = Variants.Mutations,
	Sizes = Variants.Sizes,
	Gameplay = require(script.Parent.ConfigGameplay),
	GetXPRequiredForLevel = Math.GetXPRequiredForLevel,
	GetMaxThrowRange = Math.GetMaxThrowRange,
	CalculateShakeProbability = Math.CalculateShakeProbability,
	GetAimBonus = Math.GetAimBonus,
	ReconcileTrainingXP = function(profile: any)
		TrainingMath.AddXP(profile, 0, TrainingRules)
	end,
	Constants = {
		MaxLevel = 100, BaseSanctuarySlots = GameplayMath.BaseSanctuarySlots, MaxOfflineSeconds = 28800,
		DataStoreName = "ThrowASphere_v1", StudioPersistence = false,
		AutoSaveSeconds = 60, SessionLeaseSeconds = 180,
		InitialCoins = 150, InitialOrbs = 25, InitialThrowStrength = 10,
		CaptureLockSeconds = 4.5, ThrowCooldownSeconds = 4.5,
		TrainingCoins = 5, TrainingStrength = 1,
		MaxTrainingLevel = TrainingRules.MaxLevel, MaxTrainingMachine = #TrainingRules.Machines,
		MaxInventoryCreatures = 500, MaxSanctuarySlots = 24,
	},
}
