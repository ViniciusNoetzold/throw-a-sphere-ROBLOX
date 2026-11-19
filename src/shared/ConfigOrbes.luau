--!strict
export type OrbDef = { Id: string, Name: string, Power: number, Price: number, Color: Color3, IsMaster: boolean?, IsPrismatic: boolean? }
local Orbs: { [string]: OrbDef } = {
	Comum = { Id = "Comum", Name = "Orbe Comum", Power = 10, Price = 25, Color = Color3.fromRGB(96,165,250) },
	Esmeralda = { Id = "Esmeralda", Name = "Orbe Esmeralda", Power = 25, Price = 180, Color = Color3.fromRGB(34,197,94) },
	Rubi = { Id = "Rubi", Name = "Orbe Rubi", Power = 75, Price = 1500, Color = Color3.fromRGB(239,68,68) },
	Safira = { Id = "Safira", Name = "Orbe Safira", Power = 220, Price = 15000, Color = Color3.fromRGB(56,189,248) },
	Runica = { Id = "Runica", Name = "Orbe Rúnica", Power = 800, Price = 200000, Color = Color3.fromRGB(250,204,21) },
	Hextech = { Id = "Hextech", Name = "Orbe Hextech", Power = 3500, Price = 4000000, Color = Color3.fromRGB(34,211,238) },
	Cosmica = { Id = "Cosmica", Name = "Orbe Cósmica", Power = 18000, Price = 120000000, Color = Color3.fromRGB(168,85,247) },
	Mestre = { Id = "Mestre", Name = "Orbe Mestre Suprema", Power = 1e9, Price = 0, Color = Color3.fromRGB(244,114,182), IsMaster = true },
	Prismatica = { Id = "Prismatica", Name = "Orbe Prismática Eterna", Power = 25, Price = 0, Color = Color3.fromRGB(197,116,255), IsPrismatic = true },
}
return Orbs
