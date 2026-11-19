--!strict
-- Explicit first playable balance decisions, separate from the original research.
return {
    Interval = 1200, Duration = 300, TotemMultiplier = 5, TotemDuration = 900, MaxTotemSeconds = 1800,
    SecretSpawnChance = 1e-6, RespawnSeconds = 2,
    SpeciesWeights = {Comum = 55, Incomum = 30, Rara = 12, Epica = 5, Mitica = 2, Lendaria = 1, Secreta = 0},
    Order = {"Meteoros", "Eclipse", "Tempestade"},
    Definitions = {
        Meteoros = {Name = "CHUVA DE METEOROS", LuckMultiplier = 2, SpecialCreatureId = "Meteorgon", BossCreatureId = "Meteorgon", Color = Color3.fromRGB(255,140,60)},
        Eclipse = {Name = "ECLIPSE", LuckMultiplier = 2, SpecialCreatureId = "Eclipsion", BossCreatureId = "Eclipsion", Color = Color3.fromRGB(166,100,255)},
        Tempestade = {Name = "TEMPESTADE ÁUREA", LuckMultiplier = 3, BossCreatureId = "Neonlynx", Color = Color3.fromRGB(255,217,75)},
    },
    Boss = {Stability = 100, MinDamage = 2, MaxDamage = 25, PowerScale = 1.5, CompensationIncomeSeconds = 60},
}
