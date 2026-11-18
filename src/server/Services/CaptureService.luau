--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CaptureService = {}
local random = Random.new()
local nextThrowAt: {[Player]: number} = {}
local nextRequestAt: {[Player]: number} = {}

local function finite(number: number): boolean
	return number == number and math.abs(number) < 1e6
end

local function validVector(value: any): boolean
	return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
end

function CaptureService.Init(dataService: any, spawnService: any, progressionService: any, sanctuaryService: any, remotes: any)
	local requestThrow = remotes:WaitForChild("RequestThrow") :: RemoteEvent
	local throwResult = remotes:WaitForChild("ThrowResult") :: RemoteEvent
	local feedback = remotes:WaitForChild("ActionFeedback") :: RemoteEvent
	local function reject(player: Player, message: string)
		feedback:FireClient(player, {Message = message, Kind = "Error", Success = false})
	end
	requestThrow.OnServerEvent:Connect(function(player: Player, target: any, hitPosition: any)
		-- Cheap per-player throttling comes before vector/geometry work.
		local now = os.clock()
		if now < (nextRequestAt[player] or 0) then return end
		nextRequestAt[player] = now + 0.15
		local profile = dataService.Get(player)
		if not profile then return end
		if now < (nextThrowAt[player] or 0) then
			reject(player, "Espere terminar as balançadas.")
			return
		end
		if typeof(target) ~= "Instance" or not target:IsA("Model") or not validVector(hitPosition) then return end
		local wild = spawnService.Get(target)
		if not wild then return end
		local definition = Config.Creatures[wild.CreatureId]
		local orb = Config.Orbs[profile.EquippedOrb]
		if not definition or not orb then return end
		local count = profile.Orbs[profile.EquippedOrb] or 0
		if count < 1 then reject(player, "Sem orbes equipadas. Compre mais no painel."); return end
		if not sanctuaryService.CanCapture(player) then reject(player, "Inventário cheio."); return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local primary = target.PrimaryPart
		if not root or not root:IsA("BasePart") or not primary or not humanoid or humanoid.Health <= 0 then return end
		local distance = (root.Position - primary.Position).Magnitude
		local range = Config.GetMaxThrowRange(profile.ThrowStrength, profile.Level)
		if distance > range then reject(player, "Fora de alcance. Aproxime-se ou treine sua força."); return end
		local boxFrame, boxSize = target:GetBoundingBox()
		local localHit = boxFrame:PointToObjectSpace(hitPosition)
		local half = boxSize / 2 + Vector3.new(0.5, 0.5, 0.5)
		if math.abs(localHit.X) > half.X or math.abs(localHit.Y) > half.Y or math.abs(localHit.Z) > half.Z then return end
		local startPosition = root.Position + Vector3.new(0, 1.5, 0)
		local direction = hitPosition - startPosition
		if direction.Magnitude < 0.1 then return end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {character :: Model}
		local result = Workspace:Raycast(startPosition, direction.Unit * (direction.Magnitude + 2), params)
		if not result or not result.Instance:IsDescendantOf(target) then
			reject(player, "A criatura está atrás de um obstáculo.")
			return
		end
		-- The server raycast determines the actual impact and critical hit;
		-- the client never supplies luck, damage, inventory, or a trusted bool.
		local critical = result.Instance.Name == "Head"
		local longShot = distance > 90
		local aimBonus = Config.GetAimBonus(critical, distance)
		local fever = (profile.ComboStreak or 0) >= 10
		local luck = (1 + (profile.Level - 1) * 0.015 + profile.PityBonus + profile.Rebirths * 0.5) * (if fever then 1.5 else 1)
		local chance = Config.CalculateShakeProbability(orb.Power, aimBonus, luck, definition.Difficulty, orb.IsMaster)
		-- No yielding between stock verification, catch lock and consumption.
		if not spawnService.Lock(target, player.UserId) then reject(player, "Outro jogador já está capturando esta criatura."); return end
		profile.Orbs[profile.EquippedOrb] = count - 1
		nextThrowAt[player] = now + Config.Constants.ThrowCooldownSeconds
		local passed = 0
		for shake = 1, 3 do
			if chance >= 1 or random:NextNumber() < chance then passed = shake else break end
		end
		local captured = passed == 3
		local xp = 0
		if captured then
			local record = {
				Uid = HttpService:GenerateGUID(false), CreatureId = wild.CreatureId,
				Mutation = wild.Mutation, Size = wild.Size, IncomePerSec = wild.IncomePerSec,
				CapturedAt = os.time(),
			}
			-- CanCapture was checked above and this section does not yield.
			local added = sanctuaryService.AddCapture(player, record)
			if not added then
				profile.Orbs[profile.EquippedOrb] += 1
				spawnService.Resolve(target, false)
				dataService.Sync(player)
				return
			end
			profile.PityBonus = 0
			profile.ComboStreak = math.min(10, (profile.ComboStreak or 0) + 1)
			xp = math.floor(definition.BaseXP * (if fever then 2 else 1) * (1 + profile.Rebirths * 0.5))
		else
			profile.PityBonus = math.min(1, profile.PityBonus + 0.05)
			profile.ComboStreak = 0
			xp = math.max(5, math.floor(definition.BaseXP * 0.35)) + (if critical then 15 else 0)
		end
		local oldLevel = profile.Level
		progressionService.GrantXP(player, xp)
		spawnService.Resolve(target, captured)
		dataService.MarkDirty(player)
		dataService.Sync(player)
		throwResult:FireAllClients({
			Thrower = player, StartPos = startPosition, TargetModel = target,
			HitPos = result.Position, OrbColor = orb.Color, ShakesPassed = passed,
			Captured = captured, MutationName = wild.Mutation, SizeName = wild.Size,
			CreatureName = definition.Name, CreatureId = wild.CreatureId,
			IncomePerSec = wild.IncomePerSec, XPGained = xp,
			LeveledUp = profile.Level > oldLevel, NewLevel = profile.Level,
			Probability = chance, IsCritical = critical, IsLongShot = longShot,
		})
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		nextThrowAt[player] = nil
		nextRequestAt[player] = nil
	end)
end

return CaptureService
