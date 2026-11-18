--!strict
--[[
    01_Shared_Config_Orbes_Criaturas_e_Formula.luau
    Coloque em: ReplicatedStorage/Shared/ConfigOrbesCriaturas (ModuleScript)

    Contém:
    - Catálogo das 8 Orbes de Captura
    - Amostra configurável das Criaturas (Geração 1)
    - Mutações e Tamanhos
    - Recompensas Diárias (7 Dias) e Fórmula de Nível/XP
    - Função oficial compartilhada da Fórmula de Captura (3 Balançadas)
]]

local Config = {}

export type OrbDef = {
    Id: string,
    Name: string,
    Power: number,
    Price: number,
    Color: Color3,
    IsMaster: boolean?,
}

Config.Orbs = {
    Comum = { Id = "Comum", Name = "Orbe Comum", Power = 10, Price = 25, Color = Color3.fromRGB(96, 165, 250) },
    Esmeralda = { Id = "Esmeralda", Name = "Orbe Esmeralda", Power = 25, Price = 180, Color = Color3.fromRGB(34, 197, 94) },
    Rubi = { Id = "Rubi", Name = "Orbe Rubi", Power = 75, Price = 1500, Color = Color3.fromRGB(239, 68, 68) },
    Safira = { Id = "Safira", Name = "Orbe Safira", Power = 220, Price = 15000, Color = Color3.fromRGB(56, 189, 248) },
    Runica = { Id = "Runica", Name = "Orbe Rúnica", Power = 800, Price = 200000, Color = Color3.fromRGB(250, 204, 21) },
    Hextech = { Id = "Hextech", Name = "Orbe Hextech", Power = 3500, Price = 4000000, Color = Color3.fromRGB(34, 211, 238) },
    Cosmica = { Id = "Cosmica", Name = "Orbe Cósmica", Power = 18000, Price = 120000000, Color = Color3.fromRGB(168, 85, 247) },
    Mestre = { Id = "Mestre", Name = "Orbe Mestre Suprema", Power = 999999999, Price = 0, Color = Color3.fromRGB(244, 114, 182), IsMaster = true },
}

export type CreatureDef = {
    Id: string,
    Name: string,
    Element: "Fogo" | "Agua" | "Planta" | "Raio" | "Gelo" | "Terra" | "Cosmico",
    Rarity: "Comum" | "Incomum" | "Rara" | "Epica" | "Mitica" | "Lendaria" | "Secreta",
    Biome: string,
    Difficulty: number,
    BaseIncomePerSec: number,
    BaseXP: number,
    BodyColor: Color3,
    HeadOffsetY: number, -- Altura do topo/cabeça para bônus crítico de 1.5x
}

Config.Creatures = {
    Pyrokit = { Id = "Pyrokit", Name = "Pyrokit (Brasa)", Element = "Fogo", Rarity = "Incomum", Biome = "PradariaSolar", Difficulty = 18, BaseIncomePerSec = 12, BaseXP = 40, BodyColor = Color3.fromRGB(249, 115, 22), HeadOffsetY = 2.6 },
    Aquapup = { Id = "Aquapup", Name = "Aquapup (Cristal)", Element = "Agua", Rarity = "Incomum", Biome = "PradariaSolar", Difficulty = 18, BaseIncomePerSec = 12, BaseXP = 40, BodyColor = Color3.fromRGB(56, 189, 248), HeadOffsetY = 2.4 },
    Sproutling = { Id = "Sproutling", Name = "Sproutling (Folha)", Element = "Planta", Rarity = "Comum", Biome = "PradariaSolar", Difficulty = 12, BaseIncomePerSec = 8, BaseXP = 25, BodyColor = Color3.fromRGB(74, 222, 128), HeadOffsetY = 2.2 },
    Voltmouse = { Id = "Voltmouse", Name = "Voltmouse (Raio)", Element = "Raio", Rarity = "Rara", Biome = "PradariaSolar", Difficulty = 35, BaseIncomePerSec = 28, BaseXP = 80, BodyColor = Color3.fromRGB(250, 204, 21), HeadOffsetY = 2.1 },
    Glowshroom = { Id = "Glowshroom", Name = "Glowshroom (Neon)", Element = "Planta", Rarity = "Rara", Biome = "FlorestaNeon", Difficulty = 85, BaseIncomePerSec = 75, BaseXP = 110, BodyColor = Color3.fromRGB(168, 85, 247), HeadOffsetY = 2.8 },
    Lavarex = { Id = "Lavarex", Name = "Lavarex (Magma)", Element = "Fogo", Rarity = "Epica", Biome = "CanionVulcanico", Difficulty = 420, BaseIncomePerSec = 450, BaseXP = 260, BodyColor = Color3.fromRGB(220, 38, 38), HeadOffsetY = 4.2 },
    Cryoyeti = { Id = "Cryoyeti", Name = "Cryoyeti (Glacial)", Element = "Gelo", Rarity = "Mitica", Biome = "AbismoGlacial", Difficulty = 2800, BaseIncomePerSec = 3200, BaseXP = 700, BodyColor = Color3.fromRGB(186, 230, 253), HeadOffsetY = 5.0 },
    Astraldragon = { Id = "Astraldragon", Name = "Astraldragon (Boss)", Element = "Cosmico", Rarity = "Lendaria", Biome = "VazioCosmico", Difficulty = 45000, BaseIncomePerSec = 65000, BaseXP = 2800, BodyColor = Color3.fromRGB(91, 33, 182), HeadOffsetY = 6.0 },
    Omnisfera = { Id = "Omnisfera", Name = "Omnisfera (Secreta)", Element = "Cosmico", Rarity = "Secreta", Biome = "Global", Difficulty = 220000, BaseIncomePerSec = 1000000, BaseXP = 15000, BodyColor = Color3.fromRGB(255, 255, 255), HeadOffsetY = 4.5 },
}

Config.Mutations = {
    { Name = "Normal",   Weight = 820, Multiplier = 1.0,  Color = Color3.fromRGB(255, 255, 255) },
    { Name = "Dourada",  Weight = 110, Multiplier = 2.0,  Color = Color3.fromRGB(250, 204, 21) },
    { Name = "Cristal",  Weight = 45,  Multiplier = 3.5,  Color = Color3.fromRGB(56, 189, 248) },
    { Name = "Abissal",  Weight = 18,  Multiplier = 6.0,  Color = Color3.fromRGB(126, 34, 206) },
    { Name = "ArcoIris", Weight = 7,   Multiplier = 12.0, Color = Color3.fromRGB(244, 114, 182) },
}

Config.Sizes = {
    { Name = "Normal",   Weight = 780, Scale = 1.0,  Multiplier = 1.0 },
    { Name = "Grande",   Weight = 150, Scale = 1.35, Multiplier = 1.5 },
    { Name = "Enorme",   Weight = 55,  Scale = 1.85, Multiplier = 2.5 },
    { Name = "Titanica", Weight = 15,  Scale = 2.6,  Multiplier = 5.0 },
}

Config.DailyRewards = {
    [1] = { Coins = 500,    OrbId = "Comum",     OrbQty = 10, XP = 100 },
    [2] = { Coins = 2500,   OrbId = "Esmeralda", OrbQty = 5,  XP = 250 },
    [3] = { Coins = 15000,  OrbId = "Rubi",      OrbQty = 5,  XP = 500 },
    [4] = { Coins = 40000,  OrbId = "Safira",    OrbQty = 4,  XP = 900, BonusCreature = "Voltmouse" },
    [5] = { Coins = 250000, OrbId = "Runica",    OrbQty = 3,  XP = 1500 },
    [6] = { Coins = 1000000,OrbId = "Hextech",   OrbQty = 3,  XP = 3000 },
    [7] = { Coins = 5000000,OrbId = "Mestre",    OrbQty = 1,  XP = 7500, Gems = 5 },
}

function Config.GetXPRequiredForLevel(level: number): number
    return math.floor(100 * (level ^ 1.6))
end

function Config.GetMaxThrowRange(throwStrength: number, level: number): number
    return 40 + (throwStrength * 0.5) + (level * 2)
end

-- Fórmula oficial: P = min(1, ((PoderOrbe * BonusMira * SorteJogador) / DificuldadeCriatura)^(1/3))
function Config.CalculateShakeProbability(
    orbPower: number,
    aimBonus: number,
    playerLuck: number,
    creatureDifficulty: number,
    isMaster: boolean?
): number
    if isMaster then
        return 1
    end
    local ratio = (orbPower * aimBonus * playerLuck) / math.max(1, creatureDifficulty)
    if ratio <= 0 then
        return 0
    end
    return math.min(1, ratio ^ (1 / 3))
end

return Config
