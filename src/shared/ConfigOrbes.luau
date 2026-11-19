--!strict
export type OrbDef = { Id: string, Name: string, Power: number, RareBoost: number, Price: number, Tier: number?, Color: Color3, IsMaster: boolean?, IsPrismatic: boolean? }
local Orbs: { [string]: OrbDef } = {
	Comum = { Id = "Comum", Tier = 1, Name = "Orbe Comum", Power = 10, RareBoost = 1, Price = 25, Color = Color3.fromRGB(96,165,250) },
	Esmeralda = { Id = "Esmeralda", Tier = 2, Name = "Orbe Esmeralda", Power = 25, RareBoost = 1.25, Price = 180, Color = Color3.fromRGB(34,197,94) },
	Rubi = { Id = "Rubi", Tier = 3, Name = "Orbe Rubi", Power = 75, RareBoost = 1.55, Price = 1500, Color = Color3.fromRGB(239,68,68) },
	Safira = { Id = "Safira", Tier = 4, Name = "Orbe Safira", Power = 220, RareBoost = 1.9, Price = 15000, Color = Color3.fromRGB(56,189,248) },
	Runica = { Id = "Runica", Tier = 5, Name = "Orbe Rúnica", Power = 800, RareBoost = 2.4, Price = 200000, Color = Color3.fromRGB(250,204,21) },
	Hextech = { Id = "Hextech", Tier = 6, Name = "Orbe Hextech", Power = 3500, RareBoost = 3.1, Price = 4000000, Color = Color3.fromRGB(34,211,238) },
	Cosmica = { Id = "Cosmica", Tier = 7, Name = "Orbe Cósmica", Power = 18000, RareBoost = 4.2, Price = 120000000, Color = Color3.fromRGB(168,85,247) },
	Mestre = { Id = "Mestre", Name = "Orbe Mestre Suprema", Power = 1e9, RareBoost = 5.4, Price = 0, Color = Color3.fromRGB(244,114,182), IsMaster = true },
	Prismatica = { Id = "Prismatica", Name = "Orbe Prismática Eterna", Power = 25, RareBoost = 1.65, Price = 0, Color = Color3.fromRGB(197,116,255), IsPrismatic = true },
}
return Orbs
