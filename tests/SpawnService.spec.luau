--!strict
-- Runs the unchanged production module with a deterministic scheduler/instance layer.
local Vector3 = {}
local vectorMeta = {}
function Vector3.new(x, y, z) return setmetatable({X = x, Y = y, Z = z}, vectorMeta) end
vectorMeta.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__mul = function(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
local color = {Lerp = function(self) return self end}
local Color3 = {new = function() return color end, fromRGB = function() return color end}
local Enum = {SurfaceType = {Studs = "Studs", Smooth = "Smooth"}, Font = {GothamBold = "GothamBold"}}
local UDim2 = {fromOffset = function() return {} end, fromScale = function() return {} end}
local scheduled = {}
local task = {wait = function() end, delay = function(seconds, callback) table.insert(scheduled, {Seconds = seconds, Run = callback}) end}
local models = {}
local labels = {}
local Instance = {new = function(class)
	local object = {ClassName = class, Attributes = {}, Destroyed = false}
	object.SetAttribute = function(self, name, value) self.Attributes[name] = value end
	object.Destroy = function(self) self.Destroyed = true; self.Parent = nil end
	if class == "Model" then table.insert(models, object) end
	if class == "TextLabel" then table.insert(labels, object) end
	return object
end}
local now = 100
local workspace = {GetServerTimeNow = function() return now end}
local shared = {WaitForChild = function(_, name) return name end}
local replicated = {WaitForChild = function() return shared end}
local game = {GetService = function(_, name) return if name == "Workspace" then workspace else replicated end}
local Config = {
	Constants = {CaptureLockSeconds = 4.5},
	Mutations = {{Name = "Dourada", Weight = 1, Multiplier = 2, Color = color}},
	Sizes = {{Name = "Grande", Weight = 1, Scale = 1.35, Multiplier = 1.5}},
	Creatures = {},
}
for _, id in ipairs({"Sproutling", "Pyrokit", "Aquapup", "Voltmouse", "Fluffhop", "Buzzleaf"}) do
	Config.Creatures[id] = {Name = id, BodyColor = color, Rarity = "Comum", BaseIncomePerSec = 10, Biome = "PradariaSolar"}
end
local NumberFormatter = (function()
--[[INJECT_NUMBER_FORMATTER]]
end)()
local require = function(module)
	if module == "Config" then return Config end
	if module == "NumberFormatter" then return NumberFormatter end
	if module == "ConfigEvents" then return {SecretSpawnChance = 1e-6, SpeciesWeights = {Comum = 55}} end
	if module == "ConfigWorld" then return {BiomeOrder = {"PradariaSolar"}} end
	if module == "GameplayMath" then return {} end
	error("Unexpected dependency: " .. tostring(module))
end
local rolls = {}
local Random = {new = function() return {NextNumber = function() return if #rolls > 0 then table.remove(rolls, 1) else 0.5 end} end}
local function productionSpawn()
--[[INJECT_SPAWN_SERVICE]]
end
local SpawnService = productionSpawn()

SpawnService.Init({})
assert(#models == 6, "initial blockout must contain six starter creatures")
SpawnService.Init({})
assert(#models == 6, "Init must be idempotent")
print("PASS six initial species and idempotent initialization")

local target = models[1]
local record = SpawnService.Get(target)
assert(record and record.Mutation == "Dourada" and record.Size == "Grande")
assert(record.IncomePerSec == 30 and target.Attributes.IncomePerSec == 30)
print("PASS mutation and size are rolled before capture and multiply income")

assert(SpawnService.Lock(target, 101))
assert(not SpawnService.Lock(target, 202), "another player must not acquire an active lock")
assert(record.LockedBy == 101 and target.Attributes.CaptureOwner == 101)
print("PASS active catch lock excludes other players")

SpawnService.Resolve(target, false)
local oldUnlock = scheduled[#scheduled].Run
now += 4.6
assert(SpawnService.Lock(target, 202), "expired lock should allow a new attempt")
local newVersion = record.LockVersion
oldUnlock()
assert(record.LockVersion == newVersion and record.LockedUntil > now)
assert(record.LockedBy == 202 and target.Attributes.CaptureOwner == 202, "stale callback released a newer lock")
print("PASS delayed failure callback cannot clear a newer catch lock")

SpawnService.Resolve(target, false)
now += 4.6
scheduled[#scheduled].Run()
assert(record.LockedUntil == 0 and record.LockedBy == nil and target.Attributes.CaptureOwner == 0)
assert(SpawnService.Get(target) == record and not target.Destroyed)
print("PASS failed capture restores the original wild creature")

local captured = models[2]
assert(SpawnService.Lock(captured, 303))
SpawnService.Resolve(captured, true)
assert(SpawnService.Get(captured) == nil, "successful creature must be removed from capture eligibility immediately")
assert(not SpawnService.Lock(captured, 404), "pending success must reject another player")
assert(not captured.Destroyed, "visual model should survive for its animation")
local finishCapture = scheduled[#scheduled]
assert(finishCapture.Seconds == 4.5)
finishCapture.Run()
assert(captured.Destroyed and SpawnService.Get(captured) == nil)
local respawn = scheduled[#scheduled]
assert(respawn.Seconds == 2)
respawn.Run()
assert(#models == 7 and SpawnService.Get(models[7]).CreatureId == "Pyrokit")
print("PASS success eligibility, animation lifetime, and delayed respawn")
Config.Creatures.Sproutling.BaseIncomePerSec = 5e56
local highIncome = SpawnService.Spawn("Sproutling", Vector3.new(0, 0, 0))
assert(SpawnService.Get(highIncome).IncomePerSec == highIncome.Attributes.IncomePerSec)
assert(labels[#labels].Text:find("$1.5Ocd/s", 1, true), "large wild income must use the real Big Number formatter")
assert(labels[1].Text:find("$30/s", 1, true), "small income must remain legible")
print("PASS production formatter abbreviates large billboard income without changing numeric attributes")
local expiring = SpawnService.Spawn("Pyrokit", Vector3.new(0,0,0), {EventId = "event-test", NoRespawn = true})
assert(SpawnService.Lock(expiring, 111))
SpawnService.RemoveEvent("event-test")
assert(not expiring.Destroyed and SpawnService.Get(expiring) == nil, "expired locked event must stop accepting requests but preserve its animation")
local retire = scheduled[#scheduled]
now += 5
retire.Run()
assert(expiring.Destroyed, "event retires after its catch lock expires")
print("PASS event expiry respects an active catch lock")

local modern = productionSpawn()
modern.Init({Data = {}, DisableLoops = true, World = {GetSpawnPoints = function() return {Vector3.new(0,0,0)} end}})
rolls = {0.0000005}
local secretId, secretChance = modern.ChooseSpecies("PradariaSolar")
assert(secretId == "Omnisfera" and secretChance == 1e-6, "secret roll and reported probability must match")
rolls = {1e-6, 0.5}
local normalId, normalChance = modern.ChooseSpecies("PradariaSolar")
assert(normalId ~= "Omnisfera" and math.abs(normalChance - (1 - 1e-6) / 6) < 1e-12, "secret threshold must be exclusive; normal weights must be normalized")
print("PASS real one-in-a-million replacement roll and normalized species chance")
print("SpawnService: 9 lifecycle/display/event regression tests passed.")
