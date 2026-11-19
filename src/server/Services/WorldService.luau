--!strict
-- Disposable blockout. Replace the generated models with the art from steps 3/4.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormatter"))
local Layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))

local TrainingRules = require(ReplicatedStorage.Shared.ConfigTraining)

local WorldService = {}
local worldFolder: Folder? = nil
local lots: {Model} = {}
local owners: {[Player]: number} = {}
local displaySignatures: {[Player]: string} = {}
local ctx: any

type SafeArea = {Center: Vector3, Size: Vector3, ReturnAt: Vector3}
local safeAreas: {SafeArea} = {}

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

local function protectArea(parent: Instance, center: Vector3, size: Vector3, returnAt: Vector3)
    table.insert(safeAreas, {Center = center, Size = size, ReturnAt = returnAt})
    local guards = Instance.new("Folder")
    guards.Name, guards.Parent = "EdgeGuards", parent
    local trim = Color3.fromRGB(189, 221, 156)
    local tall = 24
    for _, side in {-1, 1} do
        local x = center.X + side * (size.X / 2 - .65)
        local z = center.Z + side * (size.Z / 2 - .65)
        for _, edge in {
            {Position = Vector3.new(x, 0, center.Z), Size = Vector3.new(1.3, tall, size.Z)},
            {Position = Vector3.new(center.X, 0, z), Size = Vector3.new(size.X, tall, 1.3)},
        } do
            local guard = part(guards, "BoundaryWall", edge.Size, edge.Position + Vector3.new(0, tall / 2, 0), trim)
            guard.Transparency, guard.CanQuery, guard.CanTouch, guard.CastShadow = 1, false, false, false
            local curb = part(guards, "BoundaryTrim", Vector3.new(edge.Size.X, 1.15, edge.Size.Z), edge.Position + Vector3.new(0, .55, 0), trim)
            curb.CanCollide, curb.CanTouch, curb.CanQuery = false, false, false
            curb.TopSurface = Enum.SurfaceType.Smooth
        end
    end
end

local function startFallProtection()
    local returnPoints: {[Player]: {Character: Model, Point: Vector3}} = {}
    Players.PlayerRemoving:Connect(function(player) returnPoints[player] = nil end)
    task.spawn(function()
        while worldFolder and worldFolder.Parent do
            task.wait(.12)
            for _, player in Players:GetPlayers() do
                local character = player.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then continue end
                local position = root.Position
                if position.Y < -7 then
                    local saved = returnPoints[player]
                    local destination = if saved and saved.Character == character then saved.Point else WorldService.GetHubPosition()
                    character:PivotTo(CFrame.new(destination))
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                elseif position.Y < 12 then
                    for _, area in safeAreas do
                        if math.abs(position.X - area.Center.X) < area.Size.X / 2 - 2
                            and math.abs(position.Z - area.Center.Z) < area.Size.Z / 2 - 2 then
                            local saved = returnPoints[player]
                            if not saved or saved.Character ~= character or saved.Point ~= area.ReturnAt then
                                returnPoints[player] = {Character = character, Point = area.ReturnAt}
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
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
	local hubFloor = part(folder, "Foundation", Vector3.new(290, 1, 330), Vector3.new(0, -0.6, 20), Color3.fromRGB(63, 192, 34))
	protectArea(folder, hubFloor.Position, hubFloor.Size, Layout.HubPosition + Vector3.new(0, 4, 0))
	for x = -7, 6 do
		for z = -5, 7 do
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
	label(spawn, "PRADARIA SOLAR", Vector3.new(0, 5, 0))

	for index = 1, Layout.PlayerCapacity do
		local side = if index % 2 == 1 then -1 else 1
		local position = Vector3.new(side * 91, 0, -68 + math.floor((index - 1) / 2) * 52)
		local lot = Instance.new("Model")
		lot.Name = "Sanctuary_" .. index
		lot:SetAttribute("OwnerUserId", 0)
		lot.Parent = folder
		local platform = part(lot, "Platform", Vector3.new(44, 0.8, 49), position + Vector3.new(0, 0.35, 0), Color3.fromRGB(93, 189, 101))
		lot.PrimaryPart = platform
		local sign = part(lot, "Sign", Vector3.new(12, 3, 0.5), position + Vector3.new(9, 2.4, 22), Color3.fromRGB(25, 37, 62))
		sign.CanCollide = false
		label(sign, "SANTUÁRIO LIVRE", Vector3.new(0, 2, 0))
		local display = Instance.new("Folder")
		display.Name = "Creatures"
		display.Parent = lot
		local pen = Instance.new("Model")
		pen.Name, pen.Parent = "CreaturePen", lot
		local wool = Color3.fromRGB(255, 231, 177)
		local wood = Color3.fromRGB(159, 104, 66)
		local grass = part(pen, "Grass", Vector3.new(39, 0.3, 31), position + Vector3.new(0, 0.85, 5), Color3.fromRGB(125, 210, 104))
		grass.TopSurface = Enum.SurfaceType.Smooth
		for _, direction in {-1, 1} do
			for _, y in {1.7, 3.2} do
				part(pen, "SideRail", Vector3.new(.55, .65, 31), position + Vector3.new(direction * 19.5, y, 5), wool)
			end
			for _, z in {-10.5, 0, 10, 20.5} do
				part(pen, "FencePost", Vector3.new(1.1, 3.6, 1.1), position + Vector3.new(direction * 19.5, 2.5, z), wood)
			end
		end
		for _, y in {1.7, 3.2} do
			part(pen, "BackRail", Vector3.new(39, .65, .55), position + Vector3.new(0, y, -10.5), wool)
			for _, sideOfGate in {-1, 1} do
				part(pen, "FrontRail", Vector3.new(16, .65, .55), position + Vector3.new(sideOfGate * 11.5, y, 20.5), wool)
			end
		end
		table.insert(lots, lot)
		station(lot, "PersonalTraining", position + Vector3.new(0, 1, -18), Color3.fromRGB(255,158,65), "ACADEMIA", function(player)
			if ctx and ctx.Training and WorldService.GetSanctuary(player) == lot then ctx.Remotes.OpenPanel:FireClient(player, "Academia")
			elseif ctx and ctx.Progression and WorldService.IsAtSanctuary(player) then ctx.Progression.Train(player) end
		end)
		-- Functional gym blockout. The user will replace these parts with final equipment.
		for _,side in {-1,1} do
			local post=part(lot,"GymPost",Vector3.new(.5,6,.5),position+Vector3.new(side*3,4,-18),Color3.fromRGB(90,110,140))
			post.CanCollide=false
		end
		local bar=part(lot,"GymBar",Vector3.new(7,.5,.5),position+Vector3.new(0,7,-18),Color3.fromRGB(255,200,70))
		bar.CanCollide=false
	end
	local tutorial = part(folder, "TutorialBoard", Vector3.new(26, 8, 1), Vector3.new(0, 5, 173), Color3.fromRGB(27, 40, 72))
	label(tutorial, "THROW A SPHERE!\nCapture → Santuário → $/s\nEvolua sua orbe e treine na academia", Vector3.new(0, 1, 0))
	for index, id in Layout.BiomeOrder do
		local center, colors = Layout.Biomes[id].Position, Layout.Biomes[id].Colors
		local zone = Instance.new("Folder")
		zone.Name, zone.Parent = id, folder
		if index > 1 then
			for x = -4, 3 do for z = -4, 3 do
				part(zone, "Tile", Vector3.new(25, 1, 25), center + Vector3.new(x * 25 + 12.5, -0.5, z * 25 + 12.5), colors[(x + z) % 2 + 1])
			end end
			protectArea(zone, center, Vector3.new(Layout.ZoneSize, 1, Layout.ZoneSize), center + Vector3.new(0, 4, 35))
		end
		local destination = id
		station(folder, "Portal_" .. id, Vector3.new(-78 + (index - 1) * 31, 0.8, 116), colors[2], Config.Biomes[id].Name .. "\n$" .. NumberFormatter.Format(Config.Biomes[id].Cost) .. " • " .. Config.Biomes[id].RequiredBestiary .. " espécies", function(player)
			if not ctx or not ctx.Biomes then return end
			if ctx.Biomes.CanAccess(player, destination) or ctx.Biomes.Unlock(player, destination) then ctx.Biomes.Travel(player, destination) end
		end)
		station(zone, "ReturnPortal", center + Vector3.new(0, 0.8, 75), colors[1], "VOLTAR AO HUB", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "Hub") end end)
		task.wait()
	end
	for _, info in {{"Orbes", -75}, {"Fusao", -45}, {"Diario", -15}, {"Rebirth", 15}, {"Loja", 45}, {"Bestiario", 75}} do
		local panelId = info[1] :: string
		station(folder, "Station_" .. panelId, Vector3.new(info[2] :: number, 0.8, 148), Color3.fromRGB(175,119,255), string.upper(panelId), function(player)
			local remote = ctx and ctx.Remotes:FindFirstChild("OpenPanel")
			if remote then remote:FireClient(player, panelId) end
		end)
	end
	station(folder, "TradingPortal", Vector3.new(-134, 0.8, 122), Color3.fromRGB(74,193,255), "PRAÇA DE TROCAS\nNÍVEL 15", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "TradingPlaza") end end)
	local tradingFloor = part(folder, "TradingFloor", Vector3.new(85, 1, 85), Layout.TradingPosition + Vector3.new(0, -0.5, 0), Color3.fromRGB(43,117,154))
	protectArea(tradingFloor, tradingFloor.Position, tradingFloor.Size, Layout.TradingPosition + Vector3.new(0, 4, 13))
	station(folder, "TradingDesk", Layout.TradingPosition, Color3.fromRGB(255,212,63), "TROCAS E LEILÕES", function(player)
		local remote = ctx and ctx.Remotes:FindFirstChild("OpenPanel")
		if remote then remote:FireClient(player, "Trocas") end
	end)
	station(folder, "TradingReturn", Layout.TradingPosition + Vector3.new(0, 0.8, 30), Color3.fromRGB(74,193,255), "VOLTAR AO HUB", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "Hub") end end)
	if not ctx or not ctx.DisableLoops then startFallProtection() end
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
	WorldService.UpdateTrainingMachine(player, 1, TrainingRules.Machines[1].Name)
	owners[player] = nil
	displaySignatures[player] = nil
end

local machineColors = {
    Color3.fromRGB(255, 193, 85), Color3.fromRGB(255, 121, 82), Color3.fromRGB(89, 204, 235),
    Color3.fromRGB(161, 106, 255), Color3.fromRGB(240, 114, 224),
}

function WorldService.UpdateTrainingMachine(player: Player, tier: number, name: string)
    local lot = WorldService.GetSanctuary(player)
    if not lot then return end
    local bar = lot:FindFirstChild("GymBar")
    if bar and bar:IsA("BasePart") then
        bar.Color = machineColors[tier]
        bar.Material = if tier >= 4 then Enum.Material.Neon else Enum.Material.SmoothPlastic
    end
    local anchor = lot:FindFirstChild("PersonalTraining")
    local billboard = anchor and anchor:FindFirstChild("Label")
    local caption = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
    if caption then caption.Text = name .. " • Nv. " .. tier end
end

function WorldService.UpdateSanctuaryIncome(player: Player, shares: {[string]: number})
    local lot = WorldService.GetSanctuary(player)
    local display = lot and lot:FindFirstChild("Creatures")
    if not display then return end
    for _, model in display:GetChildren() do
        local uid = model:GetAttribute("CaptureUID")
        local head = model:FindFirstChild("Head")
        local billboard = head and head:FindFirstChild("Label")
        local caption = billboard and billboard:FindFirstChildWhichIsA("TextLabel")
        if uid and caption then
            local value = "+$" .. NumberFormatter.Format(shares[uid] or 0) .. "/s"
            if caption.Text ~= value then caption.Text = value end
        end
    end
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
	local machineTier = profile.TrainingMachine or 1
	WorldService.UpdateTrainingMachine(player, machineTier, TrainingRules.Machines[machineTier].Name)
	local signature = table.concat(profile.SanctuarySlots, ":")
	if displaySignatures[player] == signature then return end
	displaySignatures[player] = signature
	local display = lot:FindFirstChild("Creatures")
	if not display then return end
	display:ClearAllChildren()
	local inventory: {[string]: any} = {}
	for _, record in ipairs(profile.CapturedCreatures) do inventory[record.Uid] = record end
	local platform = lot.PrimaryPart
	if not platform then return end
	for slot, uid in ipairs(profile.SanctuarySlots) do
		local record = inventory[uid]
		local definition = record and Config.Creatures[record.CreatureId]
		if not definition or slot > capacity then continue end
		local column, row = (slot - 1) % 6, math.floor((slot - 1) / 6)
		local home = platform.Position + Vector3.new((column - 2.5) * 5.8, 1.65, (row - 1.5) * 6.8 + 5)
		local model = Instance.new("Model")
		model.Name = record.CreatureId
		model:SetAttribute("CaptureUID", uid)
		model:SetAttribute("PenHome", home)
		model:SetAttribute("WalkPhase", (slot * 2.399963) % (2 * math.pi))
		local function shape(name: string, size: Vector3, offset: Vector3, color: Color3): Part
			local piece = part(model, name, size, home + offset, color)
			piece.Shape = Enum.PartType.Ball
			piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
			return piece
		end
		model.PrimaryPart = shape("Body", Vector3.new(2.6, 1.8, 2.5), Vector3.zero, definition.BodyColor)
		local head = shape("Head", Vector3.new(1.75, 1.4, 1.55), Vector3.new(0, .6, -.9), definition.BodyColor:Lerp(Color3.new(1, 1, 1), .18))
		for _, side in {-1, 1} do
			shape("Eye", Vector3.new(.2, .24, .13), Vector3.new(side * .44, .76, -1.56), Color3.fromRGB(27, 25, 46))
			shape("Ear", Vector3.new(.36, .7, .4), Vector3.new(side * .56, 1.34, -.8), definition.BodyColor)
			shape(if side < 0 then "LeftFoot" else "RightFoot", Vector3.new(.67, .49, .85), Vector3.new(side * .62, -.72, -.45), definition.BodyColor)
		end
		local caption = label(head, "+$" .. NumberFormatter.Format(record.IncomePerSec) .. "/s", Vector3.new(0, 1.55, 0))
		caption.TextColor3 = Color3.fromRGB(151, 255, 113)
		caption.TextSize = 16
		local billboard = caption.Parent :: BillboardGui
		billboard.Size, billboard.MaxDistance = UDim2.fromOffset(95, 24), 33
		model.Parent = display
		CollectionService:AddTag(model, "SanctuaryWalker")
	end
end

return WorldService
