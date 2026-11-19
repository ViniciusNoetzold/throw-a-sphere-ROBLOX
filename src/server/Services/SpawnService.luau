--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormatter"))

export type WildRecord = {
	CreatureId: string,
	Mutation: string,
	Size: string,
	IncomePerSec: number,
	Scale: number,
	SpawnPosition: Vector3,
	LockedUntil: number,
	LockedBy: number?,
	LockVersion: number,
	PendingCaptured: boolean,
	BiomeId: string?, Kind: string?, EventId: string?, BossId: string?, ExpiresAt: number?,
	SpawnChance: number?, NoRespawn: boolean?, Retiring: boolean?,
	MutationRoll: number?, SizeRoll: number?, VariantLuck: number?,
}

local SpawnService = {}
local random = Random.new()
local registry: {[Model]: WildRecord} = {}
local wildFolder: Folder? = nil
local ctx: any
local settings: any
local gameplay: any

local function rollWeighted(items: {any}, luck: number?): (any, number)
	local total = 0
	local factor = luck or 1
	for _, item in ipairs(items) do total += item.Weight * (if item.Name ~= "Normal" then factor else 1) end
	local roll = random:NextNumber(0, total)
	local accumulated = 0
	for _, item in ipairs(items) do
		accumulated += item.Weight * (if item.Name ~= "Normal" then factor else 1)
		if roll < accumulated then return item, roll / total end
	end
	return items[#items], 1 - 1e-12
end

local function createPart(model: Model, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.CanCollide = false
	item.Size = size
	item.Position = position
	item.Color = color
	item.TopSurface = Enum.SurfaceType.Studs
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = model
	return item
end

function SpawnService.Spawn(creatureId: string, position: Vector3, options: any?): Model?
	if ctx and ctx.AuthoredCreatures and not ctx.AuthoredCreatures[creatureId] then return nil end
	options = options or {}
	local definition = Config.Creatures[creatureId]
	assert(definition, "Unknown creature: " .. creatureId)
	local luck = if ctx and ctx.Weather then ctx.Weather.GetLuckMultiplier() else 1
	local mutation, mutationRoll = rollWeighted(Config.Mutations, luck)
	local size, sizeRoll = rollWeighted(Config.Sizes, luck)
	local scale = size.Scale
	local model = Instance.new("Model")
	model.Name = creatureId
	local color = definition.BodyColor
	if mutation.Name ~= "Normal" and mutation.Color then color = color:Lerp(mutation.Color, 0.6) end
	local body = createPart(model, "Body", Vector3.new(3, 2, 2.5) * scale, position + Vector3.new(0, 1.1 * scale, 0), color)
	local head = createPart(model, "Head", Vector3.new(1.8, 1.5, 1.8) * scale, position + Vector3.new(0, 2.7 * scale, -0.4 * scale), color:Lerp(Color3.new(1, 1, 1), 0.18))
	body.Transparency, head.Transparency = 1, 1
	model.PrimaryPart = body
	local income = math.floor(definition.BaseIncomePerSec * mutation.Multiplier * size.Multiplier)
	registry[model] = {
		CreatureId = creatureId, Mutation = mutation.Name, Size = size.Name,
		IncomePerSec = income, Scale = scale, SpawnPosition = position,
		LockedUntil = 0, LockedBy = nil, LockVersion = 0, PendingCaptured = false,
		BiomeId = options.BiomeId or definition.Biome or "PradariaSolar", Kind = options.Kind or "Wild",
		EventId = options.EventId, BossId = options.BossId, ExpiresAt = options.ExpiresAt,
		SpawnChance = options.SpawnChance, NoRespawn = options.NoRespawn == true,
		MutationRoll = mutationRoll, SizeRoll = sizeRoll, VariantLuck = luck,
	}
	model:SetAttribute("CreatureId", creatureId)
	model:SetAttribute("ArtScale", scale)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("Size", size.Name)
	model:SetAttribute("IncomePerSec", income)
	model:SetAttribute("LockedUntil", 0)
	model:SetAttribute("CaptureOwner", 0)
	model:SetAttribute("BiomeId", registry[model].BiomeId)
	model:SetAttribute("Kind", registry[model].Kind)
	if options.ExpiresAt then model:SetAttribute("ExpiresAt", options.ExpiresAt) end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CreatureLabel"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(230, 76)
	billboard.StudsOffset = Vector3.new(0, 2 * scale, 0)
	billboard.MaxDistance = 24
	billboard.Enabled = options.Kind == "Boss"
	billboard.Parent = head
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 15
	textLabel.Text = string.format("%s [%s]\n%s • %s\n$%s/s", definition.Name, definition.Rarity, mutation.Name, size.Name, NumberFormatter.Format(income))
	textLabel.Parent = billboard
	model.Parent = wildFolder
	return model
end

function SpawnService.ChooseSpecies(biomeId: string): (string?, number?)
	if ctx and ctx.EncounterPools then
		local groups = ctx.EncounterPools[biomeId]
		if not groups then return nil, nil end
		return ctx.FlightMath.Encounter(groups, ctx.FlightRules.RarityDenominators, random)
	end
	local secretChance = settings and settings.SecretSpawnChance or 0
	if secretChance > 0 and random:NextNumber() < secretChance then return "Omnisfera", secretChance end
	local pool, total = {}, 0
	for id, definition in (ctx and ctx.EncounterCreatures) or Config.Creatures do
		if definition.Biome == biomeId then
			local weight = settings.SpeciesWeights[definition.Rarity] or 1
			total += weight
			table.insert(pool, {Id = id, Weight = weight})
		end
	end
	table.sort(pool, function(a, b) return a.Id < b.Id end)
	if total <= 0 then return nil, nil end
	local roll, accumulated = random:NextNumber(0, total), 0
	for _, item in pool do
		accumulated += item.Weight
		if roll < accumulated then return item.Id, (1 - secretChance) * item.Weight / total end
	end
	return pool[#pool].Id, (1 - secretChance) * pool[#pool].Weight / total
end

function SpawnService.Init(worldOrContext: any, context: any?)
	ctx = context or (if worldOrContext.Data then worldOrContext else nil)
	if wildFolder then return end
	local folder = Instance.new("Folder")
	folder.Name = "CriaturasSelvagens"
	folder.Parent = Workspace
	wildFolder = folder
	if ctx then
		settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigEvents"))
		gameplay = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameplayMath"))
		local layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))
		for _, biomeId in layout.BiomeOrder do
			local species = {}
			if ctx.EncounterPools then
				local groups = ctx.EncounterPools[biomeId]
				if biomeId == "FlorestaNeon" then
					-- Display a representative cross-section, including large silhouettes.
					for _, id in {"Floradine", "Flutterwing", "Lancewasp", "Jungleking", "Velvetlynx", "Dustwing"} do
						if ctx.AuthoredCreatures[id] then table.insert(species, id) end
					end
				end
				if #species == 0 then species = groups.Comum or {} end
			else
				for id, definition in Config.Creatures do
					if definition.Biome == biomeId then table.insert(species, id) end
				end
				table.sort(species)
			end
			for index, position in ctx.World.GetSpawnPoints(biomeId) do
				if #species > 0 then SpawnService.Spawn(species[(index - 1) % #species + 1], position, {BiomeId = biomeId}) end
			end
			task.wait()
		end
		if not ctx.DisableLoops then task.spawn(function()
			while true do
				task.wait(0.5)
				local timestamp = Workspace:GetServerTimeNow()
				for model, record in registry do
					if model.Parent and model.PrimaryPart and not record.PendingCaptured and not record.Retiring and record.Kind == "Wild" and record.LockedUntil <= timestamp then
						local offset = Vector3.new(math.sin(timestamp * 0.3 + record.SpawnPosition.X) * 4, 0, math.cos(timestamp * 0.3 + record.SpawnPosition.Z) * 4)
						local destination = record.SpawnPosition + offset
						local displacement = Vector3.new(destination.X - model.PrimaryPart.Position.X, 0, destination.Z - model.PrimaryPart.Position.Z)
						model:PivotTo(model:GetPivot() + displacement)
					end
				end
			end
		end) end
		return
	end
	local initial = {
		{"Sproutling", Vector3.new(-18, 0.15, -2)},
		{"Pyrokit", Vector3.new(0, 0.15, -9)},
		{"Aquapup", Vector3.new(18, 0.15, -2)},
		{"Voltmouse", Vector3.new(-27, 0.15, -15)},
		{"Fluffhop", Vector3.new(0, 0.15, -23)},
		{"Buzzleaf", Vector3.new(27, 0.15, -15)},
	}
	for _, entry in ipairs(initial) do
		SpawnService.Spawn(entry[1] :: string, entry[2] :: Vector3)
	end
end

function SpawnService.Get(model: Model): WildRecord?
	local record = registry[model]
	if not record or not model.Parent or record.PendingCaptured or record.Retiring then return nil end
	if record.ExpiresAt and Workspace:GetServerTimeNow() >= record.ExpiresAt then return nil end
	return record
end

function SpawnService.Lock(model: Model, userId: number): boolean
	local record = SpawnService.Get(model)
	local now = Workspace:GetServerTimeNow()
	if not record or record.LockedUntil > now then return false end
	record.LockedUntil = now + Config.Constants.CaptureLockSeconds
	record.LockedBy = userId
	record.LockVersion += 1
	model:SetAttribute("LockedUntil", record.LockedUntil)
	model:SetAttribute("CaptureOwner", userId)
	return true
end

function SpawnService.Resolve(model: Model, captured: boolean)
	local record = registry[model]
	if not record then return end
	local lockVersion = record.LockVersion
	-- Retain visual model during the animation, but make successful captures
	-- unavailable to every future request immediately.
	record.PendingCaptured = captured
	task.delay(Config.Constants.CaptureLockSeconds, function()
		-- A delayed unlock from a failed attempt must not release a newer lock
		-- acquired after this attempt's timeout.
		if registry[model] ~= record or record.LockVersion ~= lockVersion then return end
		if captured then
			registry[model] = nil
			model:Destroy()
				if not record.NoRespawn then task.delay(2, function()
					if wildFolder and wildFolder.Parent then
						local id, chance = record.CreatureId, nil
						if ctx and record.BiomeId then id, chance = SpawnService.ChooseSpecies(record.BiomeId) end
						if id then SpawnService.Spawn(id, record.SpawnPosition, {BiomeId = record.BiomeId, SpawnChance = chance}) end
					end
				end) end
		else
			record.LockedUntil = 0
			record.LockedBy = nil
			if model.Parent then
				model:SetAttribute("LockedUntil", 0)
				model:SetAttribute("CaptureOwner", 0)
			end
			if record.Retiring then SpawnService.Retire(model) end
		end
	end)
end

function SpawnService.GetAll(): {{Model: Model, Record: WildRecord}}
	local result = {}
	for model, record in registry do if SpawnService.Get(model) then table.insert(result, {Model = model, Record = record}) end end
	return result
end
function SpawnService.Retire(model: Model)
	local record = registry[model]
	if not record then return end
	record.Retiring, record.NoRespawn = true, true
	local remaining = record.LockedUntil - Workspace:GetServerTimeNow()
	if record.PendingCaptured or remaining > 0 then
		task.delay(math.max(0.2, remaining + 0.2), function() if registry[model] == record then SpawnService.Retire(model) end end)
		return
	end
	registry[model] = nil
	model:Destroy()
end
function SpawnService.RemoveEvent(eventId: string)
	for model, record in registry do if record.EventId == eventId then SpawnService.Retire(model) end end
end
function SpawnService.FindAutoTarget(player: Player, biomeId: string?): (Model?, Vector3?)
	if not ctx then return nil, nil end
	local profile = ctx.Data.Get(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not profile or not root or not root:IsA("BasePart") then return nil, nil end
	local benefits = if ctx.Monetization then ctx.Monetization.GetBenefits(player) else {}
	local range = gameplay.GetRange(profile, benefits)
	local nearest, best = nil, math.huge
	for _, entry in SpawnService.GetAll() do
		local model, record = entry.Model, entry.Record
		if model.PrimaryPart and (not biomeId or record.BiomeId == biomeId) and (not ctx.Biomes or ctx.Biomes.CanAccess(player, record.BiomeId or "PradariaSolar")) and record.LockedUntil <= Workspace:GetServerTimeNow() then
			local distance = (root.Position - model.PrimaryPart.Position).Magnitude
			if distance <= range and distance < best then nearest, best = model, distance end
		end
	end
	return nearest, if nearest and nearest.PrimaryPart then nearest.PrimaryPart.Position else nil
end

return SpawnService
