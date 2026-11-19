--!strict
-- run_capture_tests.py injects the production modules at the two markers.
-- Mocks exercise the actual RemoteEvent handler without needing Roblox Studio.
local CaptureMath = (function()
--[[INJECT_CAPTURE_MATH]]
end)()
local GameplayMath = (function()
--[[INJECT_GAMEPLAY_MATH]]
end)()
local VariantMath = (function()
--[[INJECT_CAPTURE_VARIANTS]]
end)()

local Vector3 = {}
local vectorMeta = {}
function Vector3.new(x: number, y: number, z: number): any
	return setmetatable({X = x, Y = y, Z = z, __type = "Vector3"}, vectorMeta)
end
vectorMeta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMeta.__mul = function(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
vectorMeta.__div = function(a, b) return Vector3.new(a.X / b, a.Y / b, a.Z / b) end
vectorMeta.__index = function(value, key)
	if key == "Magnitude" then return math.sqrt(value.X ^ 2 + value.Y ^ 2 + value.Z ^ 2) end
	if key == "Unit" then return value / value.Magnitude end
	if key == "Dot" then return function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end end
	return nil
end
local function typeof(value: any): string
	return if type(value) == "table" and rawget(value, "__type") then rawget(value, "__type") else type(value)
end
local function signal(): any
	local listeners = {}
	return {
		Connect = function(_, callback) table.insert(listeners, callback) end,
		Fire = function(_, ...) for _, listener in ipairs(listeners) do listener(...) end end,
	}
end

local current: any = {}
local serial = 0
local Config = {
	Orbs = {Comum = {Power = 10, Color = "Blue"}, Mestre = {Power = 1, Color = "Gold", IsMaster = true}, Rubi = {Power = 10, Color = "Red"}, Prismatica = {Power = 25, Color = "Violet", IsPrismatic = true}},
	Creatures = {Pyrokit = {Name = "Pyrokit", Difficulty = 20, BaseXP = 40, BaseIncomePerSec = 12, Element = "Fogo"}},
	Mutations = {{Name="Normal",Weight=80,Multiplier=1},{Name="Dourada",Weight=15,Multiplier=2},{Name="Cristal",Weight=5,Multiplier=3.5}},
	Sizes = {{Name="Normal",Weight=80,Multiplier=1},{Name="Grande",Weight=20,Multiplier=1.5}},
	Constants = {CaptureLockSeconds = 4.5, ThrowCooldownSeconds = 4.5},
	GetMaxThrowRange = CaptureMath.GetMaxThrowRange,
	CalculateShakeProbability = CaptureMath.CalculateShakeProbability,
	GetAimBonus = CaptureMath.GetAimBonus,
}
local require = function(_module: any): any return Config end
local Random = {new = function()
	return {NextNumber = function()
		current.RandomCalls += 1
		return current.Rolls[current.RandomCalls] or 0
	end}
end}
local RaycastParams = {new = function() return {} end}
local Enum = {RaycastFilterType = {Exclude = "Exclude"}}
local os = {clock = function() return current.Now end, time = function() return 1800000000 end}
local serviceMap: any = {
	Players = {PlayerRemoving = signal()},
	ReplicatedStorage = {WaitForChild = function(self) return self end},
	Workspace = {Raycast = function()
		current.Raycasts += 1
		return if current.RaycastSequence then current.RaycastSequence[current.Raycasts] else current.RaycastResult
	end},
	HttpService = {GenerateGUID = function() serial += 1; return "uid-" .. serial end},
}
local game = {GetService = function(_, name) return serviceMap[name] end}

local CaptureService = (function()
--[[INJECT_CAPTURE_SERVICE]]
end)()

local request = {OnServerEvent = signal()}
local results = {FireAllClients = function(_, payload) table.insert(current.Results, payload) end}
local feedback = {FireClient = function(_, _player, payload) table.insert(current.Feedback, payload) end}
local remotesByName = {RequestThrow = request, ThrowResult = results, ActionFeedback = feedback}
local remotes = {WaitForChild = function(_, name) return remotesByName[name] end}
local data = {
	Get = function(player) return if player == current.Player then current.Profile else nil end,
	Sync = function() current.Syncs += 1 end,
	MarkDirty = function() current.Dirties += 1 end,
	IsBusy = function() return current.Busy == true end,
}
local spawn = {
	Get = function(target)
		if target == current.Target and not current.Wild.PendingCaptured then return current.Wild end
		for _, entry in current.Extras or {} do if entry.Model == target and not entry.Record.PendingCaptured then return entry.Record end end
		return nil
	end,
	Lock = function(_target, _userId)
		current.LockCalls += 1
		if _target == current.Target then
			if current.Locked then return false end
			current.Locked = true
		end
		return true
	end,
	Resolve = function(_target, captured)
		if _target == current.Target then current.Wild.PendingCaptured = captured end
		for _, entry in current.Extras or {} do if entry.Model == _target then entry.Record.PendingCaptured = captured end end
		table.insert(current.Resolved, captured)
	end,
	GetAll = function()
		local result = {{Model = current.Target, Record = current.Wild}}
		for _, entry in current.Extras or {} do table.insert(result, entry) end
		return result
	end,
}
local progression = {GrantXP = function(_player, amount)
	if current.ApplyXPBenefits then amount = math.floor(amount * GameplayMath.GetXPMultiplier(current.Profile, current.Benefits, 1800000000)) end
	current.Profile.XP += amount
	if current.Profile.XP >= 100 then current.Profile.Level += 1; current.Profile.XP -= 100 end
	return false, amount
end}
local sanctuary = {
	CanCapture = function() return not current.InventoryFull end,
	AddCapture = function(_, record)
		if current.AddRejected then return false end
		table.insert(current.Captures, record)
		return true
	end,
}
CaptureService.Init(data, spawn, progression, sanctuary, remotes, {
	Gameplay = GameplayMath, Variants = VariantMath, Data = data,
	Biomes = {CanAccess = function() return not current.BiomeLocked end},
	Monetization = {GetBenefits = function() return current.Benefits or {} end},
	Weather = {GetLuckMultiplier = function() return current.GlobalLuck or 1 end},
	Rewards = {OnProgress = function(_, kind, amount) table.insert(current.ProgressEvents, {Kind = kind, Amount = amount}) end},
})

local function setup(): any
	serial += 1
	local root = {Position = Vector3.new(0, 2, 0), IsA = function(_, class) return class == "BasePart" end}
	local humanoid = {Health = 100}
	local character = {
		FindFirstChild = function(_, name) return if name == "HumanoidRootPart" then root else nil end,
		FindFirstChildWhichIsA = function(_, class) return if class == "Humanoid" then humanoid else nil end,
	}
	local target: any = {__type = "Instance", Parent = {}, PrimaryPart = {Position = Vector3.new(0, 1, -20)}}
	target.IsA = function(_, class) return class == "Model" end
	target.GetBoundingBox = function()
		return {PointToObjectSpace = function(_, point) return point - target.PrimaryPart.Position end}, Vector3.new(4, 6, 4)
	end
	local hitPart = {Name = "Head", IsDescendantOf = function(_, candidate) return candidate == target end}
	current = {
		Now = 100, Player = {UserId = serial, Character = character}, Target = target,
		Profile = {Coins = 150, XP = 0, Level = 1, Rebirths = 0, ThrowStrength = 10, PityBonus = 0,
			ComboStreak = 0, EquippedOrb = "Comum", Orbs = {Comum = 3, Mestre = 1, Rubi = 3, Prismatica = 0}},
		Wild = {CreatureId = "Pyrokit", Mutation = "Dourada", Size = "Grande", IncomePerSec = 36, PendingCaptured = false},
		Hit = Vector3.new(0, 3, -20), RaycastResult = {Instance = hitPart, Position = Vector3.new(0, 3, -20)},
		Humanoid = humanoid, Rolls = {}, RandomCalls = 0, Raycasts = 0, LockCalls = 0,
		Locked = false, Results = {}, Feedback = {}, Resolved = {}, Captures = {}, ProgressEvents = {}, Syncs = 0, Dirties = 0,
	}
	return current
end
local function fire(...)
	request.OnServerEvent:Fire(current.Player, ...)
end
local total = 0
local function check(name: string, test: () -> ())
	setup()
	local success, problem = pcall(test)
	assert(success, name .. ": " .. tostring(problem))
	total += 1
	print("PASS " .. name)
end
local function unchanged(expected: number?)
	assert(current.Profile.Orbs.Comum == (expected or 3), "rejected request consumed an orb")
	assert(#current.Captures == 0, "rejected request granted a creature")
	assert(#current.Results == 0, "rejected request broadcast an animation")
	assert(current.Profile.XP == 0, "rejected request granted XP")
end
local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-9, string.format("expected %.12f, got %.12f", b, a))
end

check("rejects non-Instance target", function() fire({}, current.Hit); unchanged() end)
check("rejects missing target", function() fire(nil, current.Hit); unchanged() end)
check("rejects non-Vector3 position", function() fire(current.Target, "spoof"); unchanged() end)
check("rejects NaN coordinates", function() fire(current.Target, Vector3.new(0 / 0, 3, -20)); unchanged() end)
check("rejects infinite coordinates", function() fire(current.Target, Vector3.new(math.huge, 3, -20)); unchanged() end)
check("rejects unregistered model", function()
	fire({__type = "Instance", IsA = function() return true end}, current.Hit); unchanged()
end)
check("rejects points outside target bounds", function() fire(current.Target, Vector3.new(50, 3, -20)); unchanged(); assert(current.Raycasts == 0) end)
check("rejects out-of-range target", function()
	current.Target.PrimaryPart.Position = Vector3.new(0, 1, -100)
	fire(current.Target, Vector3.new(0, 3, -100)); unchanged(); assert(current.Raycasts == 0)
end)
check("rejects dead character", function() current.Humanoid.Health = 0; fire(current.Target, current.Hit); unchanged() end)
check("rejects depleted inventory", function() current.Profile.Orbs.Comum = 0; fire(current.Target, current.Hit); unchanged(0) end)
check("rejects full creature inventory", function() current.InventoryFull = true; fire(current.Target, current.Hit); unchanged(); assert(current.LockCalls == 0) end)
check("rejects blocked line of sight", function() current.RaycastResult = nil; fire(current.Target, current.Hit); unchanged(); assert(current.Raycasts == 1) end)
check("rejects another creature blocking sight", function()
	current.RaycastResult.Instance.IsDescendantOf = function() return false end
	fire(current.Target, current.Hit); unchanged()
end)
check("catch lock contention never consumes stock", function()
	current.Locked = true; fire(current.Target, current.Hit); unchanged(); assert(current.LockCalls == 1)
	assert(current.Feedback[1].Kind == "Error")
end)
check("success consumes exactly one orb and preserves rolled variant", function()
	fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Comum == 2 and #current.Captures == 1)
	local captured = current.Captures[1]
	assert(captured.Mutation == "Dourada" and captured.Size == "Grande" and captured.IncomePerSec == 36)
	assert(captured.CreatureId == "Pyrokit" and type(captured.Uid) == "string")
	assert(current.Profile.XP == 40 and current.Profile.ComboStreak == 1 and current.Profile.PityBonus == 0)
	assert(current.Results[1].Captured and current.Results[1].ShakesPassed == 3)
	assert(current.Wild.PendingCaptured and current.RandomCalls == 3)
	near(current.Results[1].Probability, 0.75 ^ (1 / 3))
end)
check("first failed shake grants 35 percent XP plus actual critical", function()
	current.Rolls = {0.99}; current.Profile.ComboStreak = 6
	fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Comum == 2 and #current.Captures == 0)
	assert(current.Profile.XP == 29 and current.Profile.ComboStreak == 0)
	near(current.Profile.PityBonus, 0.05)
	assert(not current.Results[1].Captured and current.Results[1].ShakesPassed == 0 and current.RandomCalls == 1)
end)
check("second shake is independent", function()
	current.Rolls = {0, 0.99}; fire(current.Target, current.Hit)
	assert(current.Results[1].ShakesPassed == 1 and current.RandomCalls == 2 and #current.Captures == 0)
end)
check("third shake is independent", function()
	current.Rolls = {0, 0, 0.99}; fire(current.Target, current.Hit)
	assert(current.Results[1].ShakesPassed == 2 and current.RandomCalls == 3 and #current.Captures == 0)
end)
check("ignores spoofed client critical flag", function()
	current.RaycastResult.Instance.Name = "Body"; current.Rolls = {0.99}
	fire(current.Target, current.Hit, true)
	assert(not current.Results[1].IsCritical and current.Profile.XP == 14)
	near(current.Results[1].Probability, 0.5 ^ (1 / 3))
end)
check("server head hit remains critical with false client flag", function()
	fire(current.Target, current.Hit, false); assert(current.Results[1].IsCritical)
end)
check("Master is guaranteed without relying on random endpoints", function()
	current.Profile.EquippedOrb = "Mestre"; current.Rolls = {1, 1, 1}
	fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Mestre == 0 and current.Results[1].Captured)
	assert(current.Results[1].Probability == 1 and current.RandomCalls == 0)
end)
check("fever applies 50 percent luck and double XP", function()
	current.Profile.ComboStreak = 10; fire(current.Target, current.Hit)
	assert(current.Results[1].Probability == 1 and current.Profile.XP == 80 and current.Profile.ComboStreak == 10)
end)
check("level-up metadata follows server XP grant", function()
	current.Profile.XP = 80; fire(current.Target, current.Hit)
	assert(current.Profile.Level == 2 and current.Results[1].NewLevel == 2 and current.Results[1].LeveledUp)
end)
check("cooldown rejects second throw without consuming another orb", function()
	fire(current.Target, current.Hit); current.Now += 0.2; fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Comum == 2 and #current.Results == 1 and #current.Captures == 1)
	assert(#current.Feedback == 1 and current.Feedback[1].Kind == "Error")
end)
check("remote spam throttle precedes expensive work", function()
	fire({}, current.Hit); fire(current.Target, current.Hit)
	unchanged(); assert(current.Raycasts == 0)
	current.Now += 0.16; fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Comum == 2 and current.Raycasts == 1)
end)
check("failed inventory insertion refunds consumed orb", function()
	current.AddRejected = true; fire(current.Target, current.Hit)
	unchanged(); assert(current.Resolved[1] == false and current.Syncs == 1)
end)

check("busy transaction rejects capture before lock or consumption", function()
	current.Busy = true; fire(current.Target, current.Hit); unchanged(); assert(current.LockCalls == 0 and current.Raycasts == 0)
end)
check("locked biome rejects capture before lock or consumption", function()
	current.BiomeLocked = true; fire(current.Target, current.Hit); unchanged(); assert(current.LockCalls == 0 and current.Raycasts == 0)
end)
check("Prismatic requires verified benefit even if inventory is spoofed", function()
	current.Profile.EquippedOrb = "Prismatica"; current.Profile.Orbs.Prismatica = 999
	fire(current.Target, current.Hit); unchanged(); assert(current.Profile.Orbs.Prismatica == 999 and current.LockCalls == 0)
end)
check("verified eternal Prismatic consumes no stock", function()
	current.Profile.EquippedOrb = "Prismatica"; current.Benefits = {EternalPrism = true}
	fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Prismatica == 0 and #current.Captures == 1 and current.Results[1].Probability == 1)
end)
check("Rubi applies ten percent against fire", function()
	current.Profile.EquippedOrb = "Rubi"; fire(current.Target, current.Hit)
	near(current.Results[1].Probability, 0.825 ^ (1 / 3))
end)
check("premium variant bonus grants actual upgraded income without rewriting the shared target",function()
	current.Benefits={DoubleLuck=true}
	current.Wild.MutationRoll,current.Wild.SizeRoll,current.Wild.VariantLuck=0.94,0.9,1
	fire(current.Target,current.Hit)
	assert(current.Captures[1].Mutation=="Cristal" and current.Captures[1].IncomePerSec==63)
	assert(current.Wild.Mutation=="Dourada" and current.Results[1].MutationName=="Cristal" and current.Results[1].VariantBonus.MutationFrom=="Dourada")
end)
check("Fever and XP benefits are applied once each", function()
	current.Profile.ComboStreak = 10; current.Benefits = {FusionXP = true}; current.ApplyXPBenefits = true
	fire(current.Target, current.Hit)
	assert(current.Results[1].XPGained == 160 and current.Profile.TotalCaptures == 1)
	assert(current.ProgressEvents[1].Kind == "Captures" and current.ProgressEvents[2].Kind == "Criticals")
end)
check("Triple Throw validates and consumes at most three targets in one cooldown", function()
	current.Benefits = {TripleThrow = true}
	current.Extras, current.RaycastSequence = {}, {current.RaycastResult}
	for _, x in {-5, 5, 7} do
		local model = {__type = "Instance", Parent = {}, PrimaryPart = {Position = Vector3.new(x, 1, -20)}}
		model.IsA = function(_, class) return class == "Model" end
		model.GetBoundingBox = function() return {PointToObjectSpace = function(_, point) return point - model.PrimaryPart.Position end}, Vector3.new(4,6,4) end
		local part = {Name = "Body", IsDescendantOf = function(_, candidate) return candidate == model end}
		table.insert(current.Extras, {Model = model, Record = {CreatureId = "Pyrokit", Mutation = "Normal", Size = "Normal", IncomePerSec = 12}})
		table.insert(current.RaycastSequence, {Instance = part, Position = model.PrimaryPart.Position})
	end
	fire(current.Target, current.Hit)
	assert(current.Profile.Orbs.Comum == 0 and #current.Results == 3 and #current.Captures == 3)
	current.Now += 0.2; fire(current.Target, current.Hit)
	assert(#current.Results == 3, "burst cooldown must also apply to the next manual request")
end)

print(string.format("CaptureService: %d meaningful handler tests passed.", total))
