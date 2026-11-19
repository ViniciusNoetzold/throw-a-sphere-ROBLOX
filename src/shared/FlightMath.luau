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
    local base = 120 + math.clamp(strength, 0, 10000) * 7 + math.clamp(level, 1, 100) * 4
        + math.log10(math.clamp(orbPower, 1, 18000) + 1) * 60
    return math.clamp(base * (0.35 + 0.9 * math.clamp(power, 0, 1)) * (if titan then 1.35 else 1), 60, 1800)
end
function FlightMath.Reachable(distance: number, unlocked: {[string]: boolean}, order: {string}, zoneLength: number): (number, string)
    local last = 1
    for index = 2, #order do
        if unlocked[order[index]] ~= true then break end
        last = index
    end
    local limited = math.min(distance, last * zoneLength - 1)
    return limited, order[math.clamp(math.floor(limited / zoneLength) + 1, 1, last)]
end
function FlightMath.Species(creatures: {[string]: any}, biome: string, weights: {[string]: number}, roll: number): (string?, number)
    local pool, total = {}, 0
    for id, definition in creatures do
        if definition.Biome == biome then
            local weight = weights[definition.Rarity] or 0
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
