--!strict
-- Pure rules: clients render the same meter, but only the server fixes its value.
local FlightMath = {}
function FlightMath.MeterPosition(elapsed: number, period: number): number
    return 0.5 - 0.5 * math.cos(math.max(0, elapsed) * math.pi * 2 / period)
end
function FlightMath.Power(elapsed: number, period: number): number
    return math.clamp(1 - math.abs(FlightMath.MeterPosition(elapsed,period) - 0.5) * 2,0,1)
end
function FlightMath.AtLine(position: any, origin: any, width: number, depth: number): boolean
    return math.abs(position.X-origin.X)<=width/2 and math.abs(position.Z-origin.Z)<=depth/2 and math.abs(position.Y-origin.Y)<=8
end
function FlightMath.ThrowStyle(power: number): string
    return if power<0.35 then "Weak" elseif power<0.8 then "Medium" else "Strong"
end
function FlightMath.Distance(strength: number, level: number, orbPower: number, power: number, titan: boolean?): number
    local strengthDistance = 250 * math.log(1 + math.clamp(strength, 0, 10000) / 26)
    local base = 135 + strengthDistance + math.clamp(level, 1, 100) * 4
        + math.log10(math.clamp(orbPower, 1, 18000) + 1) * 65
    return math.max(60, base * (0.38 + math.clamp(power, 0, 1)) * (if titan then 1.35 else 1))
end
function FlightMath.Zone(distance: number, order: {string}, zoneLength: number): (string, number, number)
    local band = math.clamp(math.floor(distance / zoneLength) + 1, 1, #order)
    local progress = math.clamp((distance - (band - 1) * zoneLength) / zoneLength, 0, 1)
    return order[band], band, progress
end
local rarityRanks: {[string]: number} = {Comum = 0, Incomum = 1, Rara = 2, Epica = 3, Mitica = 4, Lendaria = 5}
function FlightMath.Species(creatures: {[string]: any}, biome: string, weights: {[string]: number}, roll: number, quality: number?, previous: string?): (string?, number)
    local pool, total = {}, 0
    local boost = 1 + .55 * math.clamp(quality or 0, 0, 1)
    for id, definition in creatures do
        if definition.Biome == biome then
            local weight = (weights[definition.Rarity] or 0) * boost ^ (rarityRanks[definition.Rarity] or 0)
            if id == previous then weight *= .25 end
            if weight > 0 then table.insert(pool, {Id = id, Weight = weight}); total += weight end
        end
    end
    if total == 0 then return nil, 0 end
    table.sort(pool, function(a, b) return a.Id < b.Id end)
    local accumulated = 0
    for _, entry in pool do
        accumulated += entry.Weight
        if math.clamp(roll, 0, 1 - 1e-12) * total < accumulated then return entry.Id, entry.Weight / total end
    end
    return nil, 0
end
return table.freeze(FlightMath)
