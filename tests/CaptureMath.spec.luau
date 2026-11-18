--!strict
local Math = require("../src/shared/CaptureMath")
local function close(a: number, b: number)
	assert(math.abs(a-b) < 1e-9, string.format("%f ~= %f", a, b))
end
local p = Math.CalculateShakeProbability(25, 1.5, 1.2, 90, false)
close(p ^ 3, 0.5) -- Three independent checks yield the documented total chance.
close(Math.CalculateShakeProbability(0, 1, 1, 10, false), 0)
close(Math.CalculateShakeProbability(999, 1, 1, 10, false), 1)
close(Math.CalculateShakeProbability(0, 1, 1, 1e9, true), 1)
close(Math.GetAimBonus(false, 90), 1)
close(Math.GetAimBonus(false, 90.01), 1.25)
close(Math.GetAimBonus(true, 90), 1.5)
close(Math.GetAimBonus(true, 91), 1.85)
assert(Math.GetXPRequiredForLevel(1) == 100)
assert(Math.GetXPRequiredForLevel(2) > Math.GetXPRequiredForLevel(1))
assert(Math.GetMaxThrowRange(10, 1) == 47)
assert(Math.GetMaxThrowRange(10, 2) == 49)
print("PASS: capture formula, guarantees, critical/long shot boundaries, XP and range")
