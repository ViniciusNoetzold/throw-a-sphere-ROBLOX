--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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
}

local SpawnService = {}
local random = Random.new()
local registry: {[Model]: WildRecord} = {}
local wildFolder: Folder? = nil

local function rollWeighted(items: {any}): any
	local total = 0
	for _, item in ipairs(items) do total += item.Weight end
	local roll = random:NextNumber(0, total)
	local accumulated = 0
	for _, item in ipairs(items) do
		accumulated += item.Weight
		if roll < accumulated then return item end
	end
	return items[#items]
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

function SpawnService.Spawn(creatureId: string, position: Vector3): Model
	local definition = Config.Creatures[creatureId]
	assert(definition, "Unknown creature: " .. creatureId)
	local mutation = rollWeighted(Config.Mutations)
	local size = rollWeighted(Config.Sizes)
	local scale = size.Scale
	local model = Instance.new("Model")
	model.Name = creatureId
	local color = definition.BodyColor
	if mutation.Name ~= "Normal" and mutation.Color then color = color:Lerp(mutation.Color, 0.6) end
	local body = createPart(model, "Body", Vector3.new(3, 2, 2.5) * scale, position + Vector3.new(0, 1.1 * scale, 0), color)
	local head = createPart(model, "Head", Vector3.new(1.8, 1.5, 1.8) * scale, position + Vector3.new(0, 2.7 * scale, -0.4 * scale), color:Lerp(Color3.new(1, 1, 1), 0.18))
	for _, side in ipairs({-1, 1}) do
		local eye = createPart(model, "Eye", Vector3.new(0.22, 0.28, 0.12) * scale, head.Position + Vector3.new(side * 0.45 * scale, 0.12 * scale, -0.92 * scale), Color3.fromRGB(15, 23, 42))
		eye.CanQuery = false
	end
	model.PrimaryPart = body
	local income = math.floor(definition.BaseIncomePerSec * mutation.Multiplier * size.Multiplier)
	registry[model] = {
		CreatureId = creatureId, Mutation = mutation.Name, Size = size.Name,
		IncomePerSec = income, Scale = scale, SpawnPosition = position,
		LockedUntil = 0, LockedBy = nil, LockVersion = 0, PendingCaptured = false,
	}
	model:SetAttribute("CreatureId", creatureId)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("Size", size.Name)
	model:SetAttribute("IncomePerSec", income)
	model:SetAttribute("LockedUntil", 0)
	model:SetAttribute("CaptureOwner", 0)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CreatureLabel"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(230, 76)
	billboard.StudsOffset = Vector3.new(0, 2 * scale, 0)
	billboard.MaxDistance = 100
	billboard.Parent = head
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 15
	textLabel.Text = string.format("%s [%s]\n%s • %s\n$%d/s", definition.Name, definition.Rarity, mutation.Name, size.Name, income)
	textLabel.Parent = billboard
	model.Parent = wildFolder
	return model
end

function SpawnService.Init(_world: any)
	if wildFolder then return end
	local folder = Instance.new("Folder")
	folder.Name = "CriaturasSelvagens"
	folder.Parent = Workspace
	wildFolder = folder
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
	if not record or not model.Parent or record.PendingCaptured then return nil end
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
			task.delay(2, function()
				if wildFolder and wildFolder.Parent then SpawnService.Spawn(record.CreatureId, record.SpawnPosition) end
			end)
		else
			record.LockedUntil = 0
			record.LockedBy = nil
			if model.Parent then
				model:SetAttribute("LockedUntil", 0)
				model:SetAttribute("CaptureOwner", 0)
			end
		end
	end)
end

return SpawnService
