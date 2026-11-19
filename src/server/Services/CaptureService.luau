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

function CaptureService.Init(dataService: any, spawnService: any?, progressionService: any?, sanctuaryService: any?, remotes: any?, context: any?)
	if dataService.Data and not spawnService then
		context = dataService
		dataService, spawnService, progressionService, sanctuaryService, remotes = context.Data, context.Spawn, context.Progression, context.Sanctuary, context.Remotes
	end
	local ctx = context
	local gameplay = if ctx then ctx.Gameplay or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayMath")) else nil
	local variants = if ctx then ctx.Variants or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VariantMath")) else nil
	function CaptureService.ApplyVariantBonus(player: Player, wild: any, creatureId: string?): (any, any)
		local profile = dataService.Get(player)
		local definition = Config.Creatures[creatureId or wild.CreatureId]
		if not profile or not definition or not variants or type(variants.Apply) ~= "function" then return wild, nil end
		local benefits = if ctx and ctx.Monetization then ctx.Monetization.GetBenefits(player) else {}
		return variants.Apply(wild, Config.Mutations, Config.Sizes, definition.BaseIncomePerSec, variants.GetPersonalLuck(profile, benefits, os.time()))
	end
	local requestThrow = remotes:WaitForChild("RequestThrow") :: RemoteEvent
	local throwResult = remotes:WaitForChild("ThrowResult") :: RemoteEvent
	local feedback = remotes:WaitForChild("ActionFeedback") :: RemoteEvent
	local function reject(player: Player, message: string)
		feedback:FireClient(player, {Message = message, Kind = "Error", Success = false})
	end
	local function perform(player: Player, target: any, hitPosition: any, burstExtra: boolean?): boolean?
		-- Cheap per-player throttling comes before vector/geometry work.
		local now = os.clock()
		if not burstExtra then
			if now < (nextRequestAt[player] or 0) then return end
			nextRequestAt[player] = now + 0.15
		end
		local profile = dataService.Get(player)
		if not profile then return end
		if dataService.IsBusy and dataService.IsBusy(player) then return end
		if not burstExtra and now < (nextThrowAt[player] or 0) then
			reject(player, "Espere terminar as balançadas.")
			return
		end
		if typeof(target) ~= "Instance" or not target:IsA("Model") or not validVector(hitPosition) then return end
		local wild = spawnService.Get(target)
		if not wild then return end
		if ctx and ctx.Biomes and not ctx.Biomes.CanAccess(player, wild.BiomeId or "PradariaSolar") then reject(player, "Desbloqueie este bioma antes de capturar suas criaturas."); return end
		local definition = Config.Creatures[wild.CreatureId]
		local orb = Config.Orbs[profile.EquippedOrb]
		if not definition or not orb then return end
		local benefits = if ctx and ctx.Monetization then ctx.Monetization.GetBenefits(player) else {}
		if orb.IsPrismatic and not benefits.EternalPrism then reject(player, "Esta orbe exige o passe Prismática Eterna."); return end
		local infinite = orb.IsPrismatic == true and benefits.EternalPrism == true
		local count = profile.Orbs[profile.EquippedOrb] or 0
		if count < 1 and not infinite then reject(player, "Sem orbes equipadas. Compre mais no painel."); return end
		if wild.Kind ~= "Boss" and not sanctuaryService.CanCapture(player) then reject(player, "Inventário cheio."); return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
		local primary = target.PrimaryPart
		if not root or not root:IsA("BasePart") or not primary or not humanoid or humanoid.Health <= 0 then return end
		local distance = (root.Position - primary.Position).Magnitude
		local range = if gameplay then gameplay.GetRange(profile, benefits) else Config.GetMaxThrowRange(profile.ThrowStrength, profile.Level)
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
		local elementBonus = if (profile.EquippedOrb == "Rubi" and definition.Element == "Fogo") or (profile.EquippedOrb == "Safira" and (definition.Element == "Agua" or definition.Element == "Gelo")) then 1.1 else 1
		if wild.Kind == "Boss" and ctx and ctx.Boss then
			if not ctx.Boss.CanHit(player, target) then return end
			if not infinite then profile.Orbs[profile.EquippedOrb] = count - 1 end
			nextThrowAt[player] = now + Config.Constants.ThrowCooldownSeconds
			local accepted, defeated = ctx.Boss.TryHit(player, target, orb.Power * aimBonus * elementBonus)
			if not accepted then if not infinite then profile.Orbs[profile.EquippedOrb] += 1 end; return end
			dataService.MarkDirty(player)
			dataService.Sync(player)
			throwResult:FireAllClients({Thrower = player, StartPos = startPosition, TargetModel = target, HitPos = result.Position, OrbColor = orb.Color, ShakesPassed = 0, Captured = false, IsBossHit = true, BossDefeated = defeated, CreatureName = definition.Name, CreatureId = wild.CreatureId, XPGained = 0, IsCritical = critical, IsLongShot = longShot})
			return true
		end
		local fever = (profile.ComboStreak or 0) >= 10
		local luck = if gameplay then gameplay.GetLuck(profile, benefits, if ctx.Weather then ctx.Weather.GetLuckMultiplier() else 1, os.time()) else (1 + (profile.Level - 1) * 0.015 + profile.PityBonus + profile.Rebirths * 0.5) * (if fever then 1.5 else 1)
		local chance = Config.CalculateShakeProbability(orb.Power * elementBonus, aimBonus, luck, definition.Difficulty, orb.IsMaster)
		-- No yielding between stock verification, catch lock and consumption.
		if not spawnService.Lock(target, player.UserId) then reject(player, "Outro jogador já está capturando esta criatura."); return end
		if not infinite then profile.Orbs[profile.EquippedOrb] = count - 1 end
		nextThrowAt[player] = now + Config.Constants.ThrowCooldownSeconds
		local passed = 0
		for shake = 1, 3 do
			if chance >= 1 or random:NextNumber() < chance then passed = shake else break end
		end
		local captured = passed == 3
		local xp = 0
		local award, variantBonus = wild, nil
		local fragments = 0
		if captured then
			award, variantBonus = CaptureService.ApplyVariantBonus(player, wild)
			local record = {
				Uid = HttpService:GenerateGUID(false), CreatureId = wild.CreatureId,
				Mutation = award.Mutation, Size = award.Size, IncomePerSec = award.IncomePerSec,
				CapturedAt = os.time(),
				FusionStage = 0,
			}
			-- CanCapture was checked above and this section does not yield.
			local added = sanctuaryService.AddCapture(player, record)
			if not added then
				if not infinite then profile.Orbs[profile.EquippedOrb] += 1 end
				spawnService.Resolve(target, false)
				dataService.Sync(player)
				return
			end
			profile.PityBonus = 0
			profile.ComboStreak = math.min(10, (profile.ComboStreak or 0) + 1)
			profile.TotalCaptures = (profile.TotalCaptures or 0) + 1
			xp = math.floor(definition.BaseXP * (if fever then 2 else 1) * (if gameplay then 1 else 1 + profile.Rebirths * 0.5))
			if ctx and ctx.Rewards then ctx.Rewards.OnProgress(player, "Captures", 1) end
			if ctx and ctx.Drops then ctx.Drops.OnCapture(player, record, result.Position) end
		else
			profile.PityBonus = math.min(1, profile.PityBonus + 0.05)
			profile.ComboStreak = 0
			xp = math.max(5, math.floor(definition.BaseXP * 0.35)) + (if critical then 15 else 0)
			if ctx and ctx.Drops then fragments = ctx.Drops.AwardFailureFragments(player) end
		end
		local oldLevel = profile.Level
		if critical and ctx and ctx.Rewards then ctx.Rewards.OnProgress(player, "Criticals", 1) end
		local _, grantedXP = progressionService.GrantXP(player, xp)
		if typeof(grantedXP) == "number" then xp = grantedXP end
		spawnService.Resolve(target, captured)
		dataService.MarkDirty(player)
		dataService.Sync(player)
		throwResult:FireAllClients({
			Thrower = player, StartPos = startPosition, TargetModel = target,
			HitPos = result.Position, OrbColor = orb.Color, ShakesPassed = passed,
			Captured = captured, MutationName = award.Mutation, SizeName = award.Size,
			CreatureName = definition.Name, CreatureId = wild.CreatureId,
			IncomePerSec = award.IncomePerSec, XPGained = xp, VariantBonus = variantBonus, FragmentsGained = fragments,
			LeveledUp = profile.Level > oldLevel, NewLevel = profile.Level,
			Probability = chance, IsCritical = critical, IsLongShot = longShot,
			SpawnChance = wild.SpawnChance,
		})
		return true
	end
	function CaptureService.TryThrow(player: Player, target: any, hitPosition: any): boolean
		local accepted = perform(player, target, hitPosition, false) == true
		if not accepted or not ctx or not ctx.Monetization or not ctx.Monetization.GetBenefits(player).TripleThrow then return accepted end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root or not target.PrimaryPart then return accepted end
		local forward = target.PrimaryPart.Position - root.Position
		if forward.Magnitude < 0.1 then return accepted end
		local candidates = {}
		for _, entry in spawnService.GetAll() do
			local model = entry.Model
			if model ~= target and model.PrimaryPart then
				local vector = model.PrimaryPart.Position - root.Position
				if vector.Magnitude > 0.1 and forward.Unit:Dot(vector.Unit) >= math.cos(math.rad(25)) then table.insert(candidates, {Model = model, Distance = vector.Magnitude}) end
			end
		end
		table.sort(candidates, function(a, b) return a.Distance < b.Distance end)
		local extras = 0
		for _, candidate in candidates do
			if perform(player, candidate.Model, candidate.Model.PrimaryPart.Position, true) then extras += 1 end
			if extras >= 2 then break end
		end
		return accepted
	end
	requestThrow.OnServerEvent:Connect(function(player: Player, target: any, hitPosition: any)
		-- The flight meter is the only public throw path in the new game loop.
		-- Legacy targeted mechanics remain callable internally for their regression suite.
		if ctx and ctx.Flight then return end
		CaptureService.TryThrow(player, target, hitPosition)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		nextThrowAt[player] = nil
		nextRequestAt[player] = nil
	end)
end

return CaptureService
