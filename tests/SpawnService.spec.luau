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
local task = {delay = function(seconds, callback) table.insert(scheduled, {Seconds = seconds, Run = callback}) end}
local models = {}
local Instance = {new = function(class)
	local object = {ClassName = class, Attributes = {}, Destroyed = false}
	object.SetAttribute = function(self, name, value) self.Attributes[name] = value end
	object.Destroy = function(self) self.Destroyed = true; self.Parent = nil end
	if class == "Model" then table.insert(models, object) end
	return object
end}
local now = 100
local workspace = {GetServerTimeNow = function() return now end}
local replicated = {WaitForChild = function(self) return self end}
local game = {GetService = function(_, name) return if name == "Workspace" then workspace else replicated end}
local Config = {
	Constants = {CaptureLockSeconds = 4.5},
	Mutations = {{Name = "Dourada", Weight = 1, Multiplier = 2, Color = color}},
	Sizes = {{Name = "Grande", Weight = 1, Scale = 1.35, Multiplier = 1.5}},
	Creatures = {},
}
for _, id in ipairs({"Sproutling", "Pyrokit", "Aquapup", "Voltmouse", "Fluffhop", "Buzzleaf"}) do
	Config.Creatures[id] = {Name = id, BodyColor = color, Rarity = "Comum", BaseIncomePerSec = 10}
end
local require = function() return Config end
local Random = {new = function() return {NextNumber = function() return 0.5 end} end}
local SpawnService = (function()
--[[INJECT_SPAWN_SERVICE]]
end)()

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
print("SpawnService: 6 lifecycle regression tests passed.")
