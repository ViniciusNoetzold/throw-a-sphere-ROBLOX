--!strict
local NumberFormatter = require("../src/shared/NumberFormatter")
local checks = 0
local function expect(value: number, expected: string, decimals: number?)
	local actual = NumberFormatter.Format(value, decimals)
	assert(actual == expected, string.format("Format(%s, %s): expected %s, got %s", tostring(value), tostring(decimals), expected, actual))
	checks += 1
end

expect(0, "0")
expect(-0.00001, "0")
expect(150, "150")
expect(12.34, "12.3")
expect(12.34, "12.34", 2)
expect(12.30, "12.3", 3)
expect(-12500, "-12.5K")
expect(89121e24, "89.1Oc")
expect(999.94, "999.9")
expect(999.96, "1K")
expect(999940, "999.9K")
expect(999960, "1M")
expect(999499, "999K", 0)
expect(999500, "1M", 0)
expect(999999999, "1B", 2)
expect(1e57, "1Ocd")
expect(1.2345e57, "1.23Ocd", 2)
expect(9.9996e59, "1e60")
expect(1e60, "1e60")
expect(1.234e63, "1.23e63", 2)
expect(-1e100, "-1e100")
expect(1.7e308, "1.7e308")
expect(0 / 0, "—")
expect(math.huge, "∞")
expect(-math.huge, "-∞")
expect(12.3456, "12.346", 20)
expect(12.3456, "12", -20)
expect(12.34, "12.3", 0 / 0)
expect(12.34, "12.3", math.huge)

local expectedTiers = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd",
}
for tier, suffix in expectedTiers do
	local power = 10 ^ (tier * 3)
	expect(power, "1" .. suffix)
	expect(power * 14.2, "14.2" .. suffix)
	expect(-power, "-1" .. suffix)
end

print(string.format("PASS: %d Big Number cases (all tiers through Ocd, rounding, signs and non-finite values)", checks))
