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
    local strengthDistance = 235 * math.log(1 + math.clamp(strength, 0, 10000) / 34)
    local base = 118 + strengthDistance + math.clamp(level, 1, 100) * 4
        + math.log10(math.clamp(orbPower, 1, 18000) + 1) * 48
    return math.max(60, base * (0.38 + math.clamp(power, 0, 1)) * (if titan then 1.35 else 1))
end
function FlightMath.Limit(raw: number, order: {string}, length: number, maximum: number, level: number, milestones: {any}?, pools: {[string]: any}?): (number, number)
    local last = 1
    for index = 2, #order do
        local goal = milestones and milestones[index]
        if goal and level < goal.Level then break end
        if pools and (not pools[order[index]] or not pools[order[index]].Comum) then break end
        last = index
    end
    local boundary = if last == #order then maximum else last * length - 1
    return math.min(raw, boundary), last
end
function FlightMath.LevelDistance(unlockedBand: number, zoneLength: number, power: number): number
    return (unlockedBand - 1) * zoneLength * (.25 + .75 * math.clamp(power, 0, 1))
end
function FlightMath.Zone(distance: number, order: {string}, zoneLength: number): (string, number, number)
    local band = math.clamp(math.floor(distance / zoneLength) + 1, 1, #order)
    local progress = math.clamp((distance - (band - 1) * zoneLength) / zoneLength, 0, 1)
    return order[band], band, progress
end
function FlightMath.RareBoost(distance: number, maximum: number, accuracy: number, orbBoost: number?): number
    local progress = math.clamp(distance / maximum, 0, 1)
    return (1 + 2.8 * progress ^ .9) * (1 + .20 * math.clamp(accuracy, 0, 1)) * (orbBoost or 1)
end
local rarityRanks: {[string]: number} = {Comum = 0, Incomum = 1, Rara = 2, Epica = 3, Mitica = 4, Lendaria = 5}
local rarestFirst = {"Secreta", "Lendaria", "Mitica", "Epica", "Rara", "Incomum"}

function FlightMath.BuildPools(creatures: {[string]: any}, order: {string}, extras: {[string]: {string}}): {[string]: {[string]: {string}}}
    local result = {}
    for _, biome in order do
        local groups: {[string]: {string}} = {}
        local seen: {[string]: boolean} = {}
        local function include(id: string, rarity: string)
            if seen[id] then return end
            seen[id] = true
            if not groups[rarity] then groups[rarity] = {} end
            table.insert(groups[rarity], id)
        end
        for id, definition in creatures do
            if definition.Biome == biome or definition.Rarity == "Secreta" then include(id, definition.Rarity) end
        end
        for _, id in extras[biome] or {} do
            local definition = creatures[id]
            if definition then include(id, definition.Rarity) end
        end
        for _, ids in groups do table.sort(ids) end
        result[biome] = groups
    end
    return result
end

-- Factor very rare checks into independent rolls below 1 in a million each.
-- This keeps huge denominators attainable even on a random generator with finite precision.
local function passes(probability: number, rng: Random): boolean
    while probability < .000001 do
        if rng:NextNumber() >= .000001 then return false end
        probability *= 1000000
    end
    return rng:NextNumber() < probability
end

function FlightMath.Encounter(groups: {[string]: {string}}, denominators: {[string]: number}, rng: Random, rareBoost: number?, previous: string?): (string?, number)
    local ids = groups.Comum
    if not ids then return nil, 0 end
    local remaining, probability = 1, 1
    for _, rarity in rarestFirst do
        local group = groups[rarity]
        local denominator = denominators[rarity]
        if group and denominator then
            local chance = math.min(.35, (rareBoost or 1) / denominator)
            if passes(chance, rng) then
                ids, probability = group, chance
                break
            end
            remaining *= 1 - chance
        end
    end
    local total = #ids - (if previous and table.find(ids, previous) then .75 else 0)
    local point = rng:NextNumber() * total
    for index, id in ids do
        local weight = if id == previous then .25 else 1
        if point < weight or index == #ids then return id, remaining * probability * weight / total end
        point -= weight
    end
    return nil, 0
end

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
