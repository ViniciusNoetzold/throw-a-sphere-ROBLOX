--!strict
-- This is a preview catalog, not a source of live Roblox prices or entitlements.
-- Enable an entry only after its server-side fulfillment has been implemented and tested.
export type ShopItem = {
	Key: string,
	Name: string,
	Description: string,
	Kind: "GamePass" | "Product",
	Category: "Gamepasses" | "Orbes" | "Boosts",
	Id: number,
	PlannedPrice: number,
	FulfillmentReady: boolean,
	Glyph: string,
	Theme: string,
}

local items: { ShopItem } = {
	{ Key = "StarterPack", Name = "Pacote Inicial", Description = "Criatura Épica Dourada, 10 Orbes Rubi, 50K moedas e 20 min de sorte 2x.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 49, FulfillmentReady = false, Glyph = "INÍCIO", Theme = "Gold" },
	{ Key = "TitanArms", Name = "Braços de Titã", Description = "Treino com ganho de força 2x e alcance máximo +35%.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 149, FulfillmentReady = false, Glyph = "2x", Theme = "Orange" },
	{ Key = "AutoThrow", Name = "Auto-Arremesso & Treino", Description = "Arremesse no bioma atual e treine automaticamente na base.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 179, FulfillmentReady = false, Glyph = "AUTO", Theme = "Cyan" },
	{ Key = "DoubleCoins", Name = "2x Moedas", Description = "Renda dobrada no santuário e nas recompensas offline.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 199, FulfillmentReady = false, Glyph = "$ 2x", Theme = "Green" },
	{ Key = "DoubleLuck", Name = "2x Sorte", Description = "Mais sorte nas capturas, mutações e tamanhos raros.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 249, FulfillmentReady = false, Glyph = "SORTE", Theme = "Green" },
	{ Key = "GiantSanctuary", Name = "Santuário Gigante", Description = "Oito espaços extras para suas criaturas e sinergias.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 299, FulfillmentReady = false, Glyph = "+8", Theme = "Blue" },
	{ Key = "GoldenVIP", Name = "VIP Dourado", Description = "Tag VIP, aura, baú diário, +25% moedas e +25% XP.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 399, FulfillmentReady = false, Glyph = "VIP", Theme = "Gold" },
	{ Key = "FusionXP", Name = "Fusão Instantânea & 2x XP", Description = "XP dobrado e fusão usando quatro criaturas em vez de cinco.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 349, FulfillmentReady = false, Glyph = "XP 2x", Theme = "Violet" },
	{ Key = "TripleThrow", Name = "Arremesso Triplo", Description = "Lance três orbes em leque para capturar até três criaturas.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 599, FulfillmentReady = false, Glyph = "3x", Theme = "Pink" },
	{ Key = "EternalPrism", Name = "Orbe Prismática Eterna", Description = "Orbe infinita com sorte 10x e brilho arco-íris.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 799, FulfillmentReady = false, Glyph = "10x", Theme = "Violet" },
	{ Key = "MegaCollector", Name = "Mega Coletor & Auto-Fusão", Description = "Coleta de drops e moedas à distância e fusão de comuns automática.", Kind = "GamePass", Category = "Gamepasses", Id = 0, PlannedPrice = 1199, FulfillmentReady = false, Glyph = "MEGA", Theme = "Cyan" },
	{ Key = "MasterOrb1", Name = "1 Orbe Mestre Suprema", Description = "Uma orbe especial com captura garantida.", Kind = "Product", Category = "Orbes", Id = 0, PlannedPrice = 79, FulfillmentReady = false, Glyph = "x1", Theme = "Pink" },
	{ Key = "MasterOrb3", Name = "3 Orbes Mestre Suprema", Description = "Três orbes especiais com captura garantida.", Kind = "Product", Category = "Orbes", Id = 0, PlannedPrice = 199, FulfillmentReady = false, Glyph = "x3", Theme = "Violet" },
	{ Key = "MasterOrb10", Name = "10 Orbes Mestre Suprema", Description = "Dez orbes especiais com captura garantida.", Kind = "Product", Category = "Orbes", Id = 0, PlannedPrice = 549, FulfillmentReady = false, Glyph = "x10", Theme = "Gold" },
	{ Key = "GlobalLuckTotem", Name = "Totem Global de Sorte", Description = "Sorte 5x para toda a sala durante 15 minutos.", Kind = "Product", Category = "Boosts", Id = 0, PlannedPrice = 199, FulfillmentReady = false, Glyph = "5x", Theme = "Green" },
	{ Key = "SummonEvent", Name = "Invocar Chefe / Eclipse", Description = "Ative um chefe de zona ou um evento de eclipse.", Kind = "Product", Category = "Boosts", Id = 0, PlannedPrice = 249, FulfillmentReady = false, Glyph = "LUA", Theme = "Violet" },
	{ Key = "PotionPack", Name = "Pacote de Poções", Description = "Sorte 3x e moedas 3x durante 30 minutos.", Kind = "Product", Category = "Boosts", Id = 0, PlannedPrice = 99, FulfillmentReady = false, Glyph = "3x", Theme = "Cyan" },
	{ Key = "SanctuarySlot", Name = "Slot Extra de Santuário", Description = "Adicione um espaço individual ao seu santuário.", Kind = "Product", Category = "Boosts", Id = 0, PlannedPrice = 69, FulfillmentReady = false, Glyph = "+1", Theme = "Blue" },
	{ Key = "SkipFusion", Name = "Pular Tempo de Fusão", Description = "Conclua a espera de uma fusão em andamento.", Kind = "Product", Category = "Boosts", Id = 0, PlannedPrice = 39, FulfillmentReady = false, Glyph = "TEMPO", Theme = "Orange" },
}

return {
	SalesEnabled = false,
	Items = items,
}
