--!strict
-- Disposable blockout. Replace the generated models with the art from steps 3/4.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormatter"))
local Layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))

local WorldService = {}
local worldFolder: Folder? = nil
local lots: {Model} = {}
local owners: {[Player]: number} = {}
local displaySignatures: {[Player]: string} = {}
local ctx: any

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
	billboard.Size = UDim2.fromOffset(220, 60)
	billboard.StudsOffset = offset
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 38
	billboard.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 14
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.15
	textLabel.TextWrapped = true
	textLabel.Text = text
	textLabel.Parent = billboard
	return textLabel
end

local function station(parent: Instance, name: string, position: Vector3, color: Color3, content: string, action: (Player) -> ())
	local anchor = part(parent, name, Vector3.new(10, 0.8, 8), position, color)
	label(anchor, content, Vector3.new(0, 5, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name, prompt.ActionText, prompt.ObjectText = "Interact", "Usar", content:gsub("\n.*", "")
	prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.HoldDuration = 14, false, 0.2
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 or (root.Position - anchor.Position).Magnitude > 19 then return end
		if ctx and ctx.Data and (not ctx.Data.IsLoaded(player) or ctx.Data.IsBusy(player)) then return end
		action(player)
	end)
end

function WorldService.Init(context: any?)
	ctx = context or ctx
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
	label(spawn, "PRADARIA SOLAR\nPrepare o lançamento e pare a barra de força", Vector3.new(0, 5, 0))

	local lotPositions = {
		Vector3.new(-68, 0, -55), Vector3.new(-74, 0, -17), Vector3.new(-64, 0, 30),
		Vector3.new(64, 0, 30), Vector3.new(74, 0, -17), Vector3.new(68, 0, -55),
	}
	for index, position in ipairs(lotPositions) do
		local lot = Instance.new("Model")
		lot.Name = "Sanctuary_" .. index
		lot:SetAttribute("OwnerUserId", 0)
		lot.Parent = folder
		local platform = part(lot, "Platform", Vector3.new(30, 0.6, 30), position + Vector3.new(0, 0.4, 0), Color3.fromRGB(65, 86, 113))
		lot.PrimaryPart = platform
		local sign = part(lot, "Sign", Vector3.new(12, 3, 0.5), position + Vector3.new(0, 4, 11), Color3.fromRGB(25, 37, 62))
		label(sign, "SANTUÁRIO LIVRE", Vector3.new(0, 2, 0))
		local display = Instance.new("Folder")
		display.Name = "Creatures"
		display.Parent = lot
		for slot = 1, 24 do
			local column = (slot - 1) % 6
			local row = math.floor((slot - 1) / 6)
			local pedestal = part(lot, "Slot_" .. slot, Vector3.new(4.1, 0.6, 4.5), position + Vector3.new((column - 2.5) * 4.8, 1, row * 5.5 - 8), Color3.fromRGB(148, 163, 184))
			pedestal:SetAttribute("SlotIndex", slot)
			pedestal.Transparency = if slot <= 6 then 0 else 0.7
		end
		table.insert(lots, lot)
		station(lot, "PersonalTraining", position + Vector3.new(0, 1, -14), Color3.fromRGB(255,158,65), "TREINO PESSOAL", function(player)
			if ctx and ctx.Training then ctx.Training.Start(player,false)
			elseif ctx and ctx.Progression and WorldService.IsAtSanctuary(player) then ctx.Progression.Train(player) end
		end)
		-- Functional gym blockout. The user will replace these parts with final equipment.
		for _,side in {-1,1} do
			local post=part(lot,"GymPost",Vector3.new(.5,6,.5),position+Vector3.new(side*3,4,-14),Color3.fromRGB(90,110,140))
			post.CanCollide=false
		end
		local bar=part(lot,"GymBar",Vector3.new(7,.5,.5),position+Vector3.new(0,7,-14),Color3.fromRGB(255,200,70))
		bar.CanCollide=false
	end
	local tutorial = part(folder, "TutorialBoard", Vector3.new(26, 8, 1), Vector3.new(0, 5, 114), Color3.fromRGB(27, 40, 72))
	label(tutorial, "THROW A SPHERE!\nCapture → Santuário → $/s\nCompre orbes e treine no painel", Vector3.new(0, 1, 0))
	for index, id in Layout.BiomeOrder do
		local center, colors = Layout.Biomes[id].Position, Layout.Biomes[id].Colors
		local zone = Instance.new("Folder")
		zone.Name, zone.Parent = id, folder
		if index > 1 then
			for x = -4, 3 do for z = -4, 3 do
				part(zone, "Tile", Vector3.new(25, 1, 25), center + Vector3.new(x * 25 + 12.5, -0.5, z * 25 + 12.5), colors[(x + z) % 2 + 1])
			end end
		end
		local destination = id
		station(folder, "Portal_" .. id, Vector3.new(-78 + (index - 1) * 31, 0.8, 80), colors[2], Config.Biomes[id].Name .. "\n$" .. NumberFormatter.Format(Config.Biomes[id].Cost) .. " • " .. Config.Biomes[id].RequiredBestiary .. " espécies", function(player)
			if not ctx or not ctx.Biomes then return end
			if ctx.Biomes.CanAccess(player, destination) or ctx.Biomes.Unlock(player, destination) then ctx.Biomes.Travel(player, destination) end
		end)
		station(zone, "ReturnPortal", center + Vector3.new(0, 0.8, 75), colors[1], "VOLTAR AO HUB", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "Hub") end end)
		task.wait()
	end
	for _, info in {{"Orbes", -75}, {"Fusao", -45}, {"Diario", -15}, {"Rebirth", 15}, {"Loja", 45}, {"Bestiario", 75}} do
		local panelId = info[1] :: string
		station(folder, "Station_" .. panelId, Vector3.new(info[2] :: number, 0.8, 105), Color3.fromRGB(175,119,255), string.upper(panelId), function(player)
			local remote = ctx and ctx.Remotes:FindFirstChild("OpenPanel")
			if remote then remote:FireClient(player, panelId) end
		end)
	end
	station(folder, "TradingPortal", Vector3.new(-100, 0.8, 65), Color3.fromRGB(74,193,255), "PRAÇA DE TROCAS\nNÍVEL 15", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "TradingPlaza") end end)
	part(folder, "TradingFloor", Vector3.new(85, 1, 85), Layout.TradingPosition + Vector3.new(0, -0.5, 0), Color3.fromRGB(43,117,154))
	station(folder, "TradingDesk", Layout.TradingPosition, Color3.fromRGB(255,212,63), "TROCAS E LEILÕES", function(player)
		local remote = ctx and ctx.Remotes:FindFirstChild("OpenPanel")
		if remote then remote:FireClient(player, "Trocas") end
	end)
	station(folder, "TradingReturn", Layout.TradingPosition + Vector3.new(0, 0.8, 30), Color3.fromRGB(74,193,255), "VOLTAR AO HUB", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "Hub") end end)
end

function WorldService.GetSanctuary(player: Player): Model? return if owners[player] then lots[owners[player]] else nil end
function WorldService.IsAtSanctuary(player: Player): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local lot = WorldService.GetSanctuary(player)
	return root ~= nil and root:IsA("BasePart") and lot ~= nil and lot.PrimaryPart ~= nil and (root.Position - lot.PrimaryPart.Position).Magnitude <= Layout.SanctuaryRadius
end
WorldService.IsInSanctuary = WorldService.IsAtSanctuary
function WorldService.GetHubPosition(): Vector3 return Layout.HubPosition + Vector3.new(0, 4, 0) end
function WorldService.GetTradingPosition(): Vector3 return Layout.TradingPosition + Vector3.new(0, 4, 0) end
function WorldService.GetBiomePosition(id: string): Vector3?
	return if Layout.Biomes[id] then Layout.Biomes[id].Position + Vector3.new(0, 4, 35) else nil
end
function WorldService.GetBiomeAtPosition(position: Vector3): string
	if (Vector3.new(position.X, 0, position.Z) - Layout.TradingPosition).Magnitude <= 45 then return "TradingPlaza" end
	for _, id in Layout.BiomeOrder do
		local center = Layout.Biomes[id].Position
		if math.abs(position.X - center.X) <= 100 and math.abs(position.Z - center.Z) <= 100 then return id end
	end
	return "Hub"
end
function WorldService.GetSpawnPoints(id: string): {Vector3}
	local center, points = Layout.Biomes[id].Position, {}
	for _, offset in {Vector3.new(-30,0.15,5), Vector3.new(0,0.15,-5), Vector3.new(30,0.15,5), Vector3.new(-42,0.15,-28), Vector3.new(0,0.15,-38), Vector3.new(42,0.15,-28)} do table.insert(points, center + offset) end
	return points
end
function WorldService.GetFolder(): Folder? return worldFolder end
function WorldService.GetPodiumFolder(): Folder?
	if not worldFolder then return nil end
	local existing = worldFolder:FindFirstChild("Podium")
	if existing and existing:IsA("Folder") then return existing end
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "Podium", worldFolder
	return folder
end
WorldService.Label = label

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
	local playerBenefits = if ctx and ctx.Monetization then ctx.Monetization.GetBenefits(player) else {}
	local capacity = if ctx and ctx.Sanctuary then ctx.Sanctuary.GetSlotCapacity(profile, playerBenefits) else Config.Constants.BaseSanctuarySlots + (if profile.Level >= 5 then 1 else 0) + (if profile.Level >= 15 then 1 else 0)
	if textLabel then
		textLabel.Text = string.format("%s\n$%s/s • %d/%d slots", player.DisplayName, NumberFormatter.Format(profile.IncomePerSec or 0), #profile.SanctuarySlots, capacity)
	end
	for slot = 1, 24 do
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
			label(head, string.format("%s\n%s • %s\n$%s/s", definition.Name, record.Mutation, record.Size, NumberFormatter.Format(record.IncomePerSec)), Vector3.new(0, 2.6, 0))
		end
	end
end

return WorldService
