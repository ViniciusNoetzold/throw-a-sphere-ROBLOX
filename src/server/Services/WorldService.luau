--!strict
-- Disposable blockout. Replace the generated models with the art from steps 3/4.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local WorldService = {}
local worldFolder: Folder? = nil
local lots: {Model} = {}
local owners: {[Player]: number} = {}
local displaySignatures: {[Player]: string} = {}

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Anchored = true
	item.Size = size
	item.Position = position
	item.Color = color
	item.TopSurface = Enum.SurfaceType.Studs
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function label(parent: BasePart, text: string, offset: Vector3): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Adornee = parent
	billboard.Size = UDim2.fromOffset(280, 78)
	billboard.StudsOffset = offset
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 130
	billboard.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 18
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.15
	textLabel.TextWrapped = true
	textLabel.Text = text
	textLabel.Parent = billboard
	return textLabel
end

function WorldService.Init()
	if worldFolder then return end
	local folder = Instance.new("Folder")
	folder.Name = "ThrowASphereWorld"
	folder:SetAttribute("GeneratedBlockout", true)
	folder.Parent = Workspace
	worldFolder = folder
	part(folder, "Foundation", Vector3.new(260, 1, 260), Vector3.new(0, -0.6, 0), Color3.fromRGB(63, 192, 34))
	for x = -6, 5 do
		for z = -6, 5 do
			local color = if (x + z) % 2 == 0 then Color3.fromRGB(76, 217, 43) else Color3.fromRGB(63, 192, 34)
			part(folder, "GrassTile", Vector3.new(16, 0.2, 16), Vector3.new(x * 16 + 8, 0, z * 16 + 8), color)
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PradariaSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 0.5, 10)
	spawn.Position = Vector3.new(0, 0.4, 20)
	spawn.Color = Color3.fromRGB(125, 211, 252)
	spawn.Parent = folder
	label(spawn, "PRADARIA SOLAR\nSegure para mirar; solte para lançar", Vector3.new(0, 5, 0))

	local lotPositions = {
		Vector3.new(-68, 0, -55), Vector3.new(-74, 0, -17), Vector3.new(-64, 0, 30),
		Vector3.new(64, 0, 30), Vector3.new(74, 0, -17), Vector3.new(68, 0, -55),
	}
	for index, position in ipairs(lotPositions) do
		local lot = Instance.new("Model")
		lot.Name = "Sanctuary_" .. index
		lot:SetAttribute("OwnerUserId", 0)
		lot.Parent = folder
		local platform = part(lot, "Platform", Vector3.new(26, 0.6, 24), position + Vector3.new(0, 0.4, 0), Color3.fromRGB(65, 86, 113))
		lot.PrimaryPart = platform
		local sign = part(lot, "Sign", Vector3.new(12, 3, 0.5), position + Vector3.new(0, 4, 11), Color3.fromRGB(25, 37, 62))
		label(sign, "SANTUÁRIO LIVRE", Vector3.new(0, 2, 0))
		local display = Instance.new("Folder")
		display.Name = "Creatures"
		display.Parent = lot
		for slot = 1, 8 do
			local column = (slot - 1) % 4
			local row = math.floor((slot - 1) / 4)
			local pedestal = part(lot, "Slot_" .. slot, Vector3.new(5, 0.6, 6), position + Vector3.new((column - 1.5) * 6, 1, row * 8 - 5), Color3.fromRGB(148, 163, 184))
			pedestal:SetAttribute("SlotIndex", slot)
			pedestal.Transparency = if slot <= 6 then 0 else 0.7
		end
		table.insert(lots, lot)
	end
	local tutorial = part(folder, "TutorialBoard", Vector3.new(26, 8, 1), Vector3.new(0, 5, 48), Color3.fromRGB(27, 40, 72))
	label(tutorial, "THROW A SPHERE!\nCapture → Santuário → $/s\nCompre orbes e treine no painel", Vector3.new(0, 1, 0))
end

function WorldService.AssignSanctuary(player: Player): Model?
	local existing = owners[player]
	if existing then return lots[existing] end
	for index, lot in ipairs(lots) do
		if lot:GetAttribute("OwnerUserId") == 0 then
			owners[player] = index
			lot:SetAttribute("OwnerUserId", player.UserId)
			player:SetAttribute("SanctuaryIndex", index)
			return lot
		end
	end
	return nil
end

function WorldService.ReleaseSanctuary(player: Player)
	local index = owners[player]
	if not index then return end
	local lot = lots[index]
	lot:SetAttribute("OwnerUserId", 0)
	local display = lot:FindFirstChild("Creatures")
	if display then display:ClearAllChildren() end
	local sign = lot:FindFirstChild("Sign")
	local billboard = sign and sign:FindFirstChild("Label")
	local textLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
	if textLabel then textLabel.Text = "SANTUÁRIO LIVRE" end
	owners[player] = nil
	displaySignatures[player] = nil
end

function WorldService.UpdateSanctuary(player: Player, profile: any)
	local index = owners[player]
	if not index then return end
	local lot = lots[index]
	local sign = lot:FindFirstChild("Sign")
	local billboard = sign and sign:FindFirstChild("Label")
	local textLabel = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
	local capacity = Config.Constants.BaseSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0)
	if textLabel then
		textLabel.Text = string.format("%s\n$%.1f/s • %d/%d slots", player.DisplayName, profile.IncomePerSec or 0, #profile.SanctuarySlots, capacity)
	end
	for slot = 1, 8 do
		local pedestal = lot:FindFirstChild("Slot_" .. slot)
		if pedestal and pedestal:IsA("BasePart") then pedestal.Transparency = if slot <= capacity then 0 else 0.7 end
	end
	local signature = table.concat(profile.SanctuarySlots, ":")
	if displaySignatures[player] == signature then return end
	displaySignatures[player] = signature
	local display = lot:FindFirstChild("Creatures")
	if not display then return end
	display:ClearAllChildren()
	local inventory: {[string]: any} = {}
	for _, record in ipairs(profile.CapturedCreatures) do inventory[record.Uid] = record end
	for slot, uid in ipairs(profile.SanctuarySlots) do
		local record = inventory[uid]
		local pedestal = lot:FindFirstChild("Slot_" .. slot)
		local definition = record and Config.Creatures[record.CreatureId]
		if record and definition and pedestal and pedestal:IsA("BasePart") then
			local model = Instance.new("Model")
			model.Name = record.CreatureId
			model.Parent = display
			local body = part(model, "Body", Vector3.new(2.7, 2, 2.5), pedestal.Position + Vector3.new(0, 1.4, 0), definition.BodyColor)
			body.CanCollide = false
			local head = part(model, "Head", Vector3.new(1.7, 1.4, 1.7), body.Position + Vector3.new(0, 1.5, -0.3), definition.BodyColor:Lerp(Color3.new(1, 1, 1), 0.2))
			head.CanCollide = false
			model.PrimaryPart = body
			label(head, string.format("%s\n%s • %s\n$%.1f/s", definition.Name, record.Mutation, record.Size, record.IncomePerSec), Vector3.new(0, 2.6, 0))
		end
	end
end

return WorldService
