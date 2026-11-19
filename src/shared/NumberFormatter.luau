--!strict
-- Display only: economy values stay numeric and authoritative on the server.
local NumberFormatter = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
	"Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd",
}

local function trimFraction(text: string): string
	return (text:gsub("(%..-)0+$", "%1"):gsub("%.$", ""))
end

local function precision(decimals: number?): number
	if decimals == nil or decimals ~= decimals or math.abs(decimals) == math.huge then
		return 1
	end
	return math.clamp(math.floor(decimals), 0, 3)
end

local function scientific(amount: number, digits: number): string
	local text = string.format("%." .. digits .. "e", amount)
	local mantissa, exponent = text:match("^(.-)e([%+%-]?%d+)$")
	if not mantissa or not exponent then
		return text
	end
	return trimFraction(mantissa) .. "e" .. tostring(tonumber(exponent))
end

function NumberFormatter.Format(value: number, decimals: number?): string
	if value ~= value then return "—" end
	if value == math.huge then return "∞" end
	if value == -math.huge then return "-∞" end

	local digits = precision(decimals)
	local amount = math.abs(value)
	local sign = if value < 0 then "-" else ""
	local tier = 1
	while amount >= 1000 and tier < #SUFFIXES do
		amount /= 1000
		tier += 1
	end
	local factor = 10 ^ digits
	local rounded = math.floor(amount * factor + 0.5) / factor
	-- The rounded display may cross a tier even when the original number did not.
	-- This also tolerates binary floating-point error at exact powers of 1000.
	if rounded >= 1000 then
		if tier == #SUFFIXES then return sign .. scientific(math.abs(value), digits) end
		amount /= 1000
		tier += 1
		rounded = math.floor(amount * factor + 0.5) / factor
	end
	if rounded == 0 then sign = "" end -- Avoid displaying negative zero.
	return sign .. trimFraction(string.format("%." .. digits .. "f", rounded)) .. SUFFIXES[tier]
end

return NumberFormatter
