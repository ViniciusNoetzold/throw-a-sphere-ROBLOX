--!strict
-- Pure benefit rules. Pass ownership is supplied by the server, never by a remote.
local GameplayMath = {}

local function nonnegative(value: any, fallback: number?): number
	return if type(value) == "number" and value == value and value < math.huge and value >= 0 then value else fallback or 0
end

local function has(benefits: any, key: string): boolean
	return type(benefits) == "table" and benefits[key] == true
end

local function boost(profile: any, key: string, now: number): number
	local item = profile.Boosts and profile.Boosts[key]
	if type(item) ~= "table" or nonnegative(item.ExpiresAt) <= now then return 1 end
	return math.max(1, nonnegative(item.Multiplier, 1))
end

function GameplayMath.GetSlotCapacity(profile: any, benefits: any): number
	local level = nonnegative(profile.Level, 1)
	return math.min(24, 6 + (if level >= 5 then 1 else 0) + (if level >= 15 then 1 else 0)
		+ math.floor(nonnegative(profile.ExtraSanctuarySlots)) + (if has(benefits, "GiantSanctuary") then 8 else 0)
		+ (if has(benefits, "GroupMember") then 1 else 0))
end

function GameplayMath.GetTrainingGain(_profile: any, benefits: any): number
	return if has(benefits, "TitanArms") then 2 else 1
end

function GameplayMath.GetRange(profile: any, benefits: any): number
	return (40 + nonnegative(profile.ThrowStrength) * 0.5 + math.clamp(nonnegative(profile.Level, 1), 1, 100) * 2)
		* (if has(benefits, "TitanArms") then 1.35 else 1)
end

function GameplayMath.GetLuck(profile: any, benefits: any, globalLuck: number?, now: number?): number
	local completed = 0
	for _, claimed in profile.BestiaryRewardClaimed or {} do if claimed == true then completed += 1 end end
	local base = 1 + (math.clamp(nonnegative(profile.Level, 1), 1, 100) - 1) * 0.015
		+ math.clamp(nonnegative(profile.PityBonus), 0, 1) + nonnegative(profile.Rebirths) * 0.5
		+ completed * 0.1 + (if has(benefits, "GroupMember") then 0.1 else 0)
	return base * (if nonnegative(profile.ComboStreak) >= 10 then 1.5 else 1)
		* (if has(benefits, "DoubleLuck") then 2 else 1) * boost(profile, "Luck", now or os.time())
		* math.max(1, nonnegative(globalLuck, 1))
		* (if profile.EquippedOrb == "Prismatica" and has(benefits, "EternalPrism") then 10 else 1)
end

function GameplayMath.GetIncomeMultiplier(profile: any, benefits: any, now: number?): number
	return (1 + nonnegative(profile.Rebirths)) * (if has(benefits, "DoubleCoins") then 2 else 1)
		* (if has(benefits, "GoldenVIP") then 1.25 else 1) * boost(profile, "Coins", now or os.time())
end

function GameplayMath.GetXPMultiplier(profile: any, benefits: any, now: number?): number
	-- CaptureService owns Fever's extra 2x; applying it here would count it twice.
	return (1 + nonnegative(profile.Rebirths) * 0.5) * (if has(benefits, "FusionXP") then 2 else 1)
		* (if has(benefits, "GoldenVIP") then 1.25 else 1) * boost(profile, "XP", now or os.time())
end

function GameplayMath.GetOfflineIncome(profile: any, baseSynergyIncome: number, elapsed: number, benefits: any, now: number?): number
	local finish = now or os.time()
	local start = math.min(finish, nonnegative(profile.LastSeen, finish - nonnegative(elapsed)))
	local seconds = math.min(28800, nonnegative(elapsed), math.max(0, finish - start))
	local item = profile.Boosts and profile.Boosts.Coins
	local boostedSeconds, multiplier = 0, 1
	if type(item) == "table" then
		multiplier = math.max(1, nonnegative(item.Multiplier, 1))
		boostedSeconds = math.clamp(nonnegative(item.ExpiresAt) - start, 0, seconds)
	end
	local permanent = (1 + nonnegative(profile.Rebirths)) * (if has(benefits, "DoubleCoins") then 2 else 1)
		* (if has(benefits, "GoldenVIP") then 1.25 else 1)
	return math.floor(nonnegative(baseSynergyIncome) * permanent * (seconds + boostedSeconds * (multiplier - 1)))
end

return table.freeze(GameplayMath)
