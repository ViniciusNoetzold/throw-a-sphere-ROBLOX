--!strict
-- Functional blockout coordinates. Final imported art must keep these interaction anchors.
return {
    HubPosition = Vector3.new(0, 0, 35), HubRadius = 155, PlayerCapacity = 8,
    TradingPosition = Vector3.new(-225, 0, 35),
    EventPosition = Vector3.new(0, 0.15, -65), BossPosition = Vector3.new(45, 0.15, -65),
    ZoneSize = 200, TileSize = 25, SanctuaryRadius = 34, InteractionDistance = 14,
    BiomeOrder = {"PradariaSolar", "FlorestaNeon", "CanionVulcanico", "AbismoGlacial", "RuinasAncestrais", "VazioCosmico"},
    Biomes = {
        PradariaSolar = {Position = Vector3.new(0, 0, -20), Colors = {Color3.fromRGB(76,217,43), Color3.fromRGB(63,192,34)}},
        FlorestaNeon = {Position = Vector3.new(250, 0, -20), Colors = {Color3.fromRGB(15,23,42), Color3.fromRGB(21,72,86)}},
        CanionVulcanico = {Position = Vector3.new(500, 0, -20), Colors = {Color3.fromRGB(69,10,10), Color3.fromRGB(185,28,28)}},
        AbismoGlacial = {Position = Vector3.new(750, 0, -20), Colors = {Color3.fromRGB(186,230,253), Color3.fromRGB(56,189,248)}},
        RuinasAncestrais = {Position = Vector3.new(1000, 0, -20), Colors = {Color3.fromRGB(245,208,111), Color3.fromRGB(174,126,57)}},
        VazioCosmico = {Position = Vector3.new(1250, 0, -20), Colors = {Color3.fromRGB(27,25,71), Color3.fromRGB(38,36,96)}},
    },
}
