--!strict
-- Pure rules, runnable in the official Luau CLI without Roblox services.
local CaptureMath = {}

function CaptureMath.GetXPRequiredForLevel(level: number): number
	return math.floor(100 * math.clamp(level, 1, 100) ^ 1.6)
end

function CaptureMath.GetMaxThrowRange(strength: number, level: number): number
	return 40 + math.max(0, strength) * 0.5 + math.clamp(level, 1, 100) * 2
end

function CaptureMath.CalculateShakeProbability(power: number, aim: number, luck: number, difficulty: number, master: boolean?): number
	if master then return 1 end
	local ratio = math.max(0, power * aim * luck) / math.max(1, difficulty)
	return math.min(1, ratio ^ (1 / 3))
end

function CaptureMath.GetAimBonus(critical: boolean, distance: number): number
	if distance > 90 then return if critical then 1.85 else 1.25 end
	return if critical then 1.5 else 1
end

return table.freeze(CaptureMath)
