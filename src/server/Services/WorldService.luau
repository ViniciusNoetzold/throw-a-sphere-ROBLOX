--!strict
-- Generated world and interaction anchors shared by all Roblox builds.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormatter"))
local Layout = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigWorld"))

local TrainingRules = require(ReplicatedStorage.Shared.ConfigTraining)
local WorldArt = require(script.Parent.WorldArtService)

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

local function retainingWall(parent: Instance, center: Vector3, length: number, inward: Vector3, tint: Color3)
    local stone = Color3.fromRGB(96, 91, 83):Lerp(tint, .26)
    local moss = Color3.fromRGB(102, 163, 73):Lerp(tint, .33)
    local axis = Vector3.yAxis:Cross(inward)
    local function block(name: string, size: Vector3, offset: Vector3, color: Color3, decor: boolean?): Part
        local position = center + axis * offset.X + Vector3.yAxis * offset.Y + inward * offset.Z
        local item = part(parent, name, size, position, color)
        item.CFrame = CFrame.lookAt(position, position + inward)
        if decor then item.CanCollide, item.CanTouch, item.CanQuery = false, false, false end
        return item
    end
    block("TerraceWall", Vector3.new(length, 27, 5), Vector3.new(0, 12.5, 0), stone)
    block("WallFooting", Vector3.new(length, 2.6, 7), Vector3.new(0, .7, .3), stone:Lerp(Color3.new(), .2))
    block("GrassRim", Vector3.new(length, 1.25, 6.7), Vector3.new(0, 26.35, -.35), moss)
    local panels = math.ceil(length / 20)
    local width = length / panels
    for row = 0, 1 do
        local step = if row == 0 then width else width * .5
        local offset = -length / 2
        local index = 0
        while offset < length / 2 - .1 do
            local span = math.min(step, length / 2 - offset)
            local shade = if (index + row) % 2 == 0 then .17 else .07
            local brick = block("StuddedBrick", Vector3.new(span - .13, 10.3, 1.05),
                Vector3.new(offset + span / 2, 7.45 + row * 10.7, 2.7), stone:Lerp(Color3.new(1, 1, 1), shade), true)
            brick.FrontSurface = Enum.SurfaceType.Studs
            offset += span
            step, index = width, index + 1
        end
    end
    for index = 1, math.ceil(length / 55) do
        local step = length / math.ceil(length / 55)
        local span = (index - .5) * step - length / 2
        local skyline = 31 + (index * 7) % 14
        block("EarthBank", Vector3.new(step + .05, skyline + 13, 24),
            Vector3.new(span, (skyline - 13) / 2, -15), stone:Lerp(moss, .27))
        block("BankGrass", Vector3.new(step + .11, 1.2, 24.15),
            Vector3.new(span, skyline + .35, -15), moss)
    end
end

local function protectArea(parent: Instance, center: Vector3, size: Vector3, returnAt: Vector3, tint: Color3, runwayOpening: boolean?)
    table.insert(safeAreas, {Center = center, Size = size, ReturnAt = returnAt})
    local guards = Instance.new("Folder")
    guards.Name, guards.Parent = "RetainingWalls", parent
    for _, side in {-1, 1} do
        local x = center.X + side * (size.X / 2 - 1)
        local z = center.Z + side * (size.Z / 2 - 1)
        retainingWall(guards, Vector3.new(x, 0, center.Z), size.Z, Vector3.new(-side, 0, 0), tint)
        if runwayOpening and side == -1 then
            local halfGap = 36
            local length = size.X / 2 - halfGap
            for _, flank in {-1, 1} do
                retainingWall(guards, Vector3.new(center.X + flank * (halfGap + length / 2), 0, z),
                    length, Vector3.zAxis, tint)
            end
        else
            retainingWall(guards, Vector3.new(center.X, 0, z), size.X, Vector3.new(0, 0, -side), tint)
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
	folder.Parent = Workspace
	worldFolder = folder
	WorldArt.Init(folder, ctx, {Part = part, Label = label, Station = station, ProtectArea = protectArea})
	local grass = Color3.fromRGB(92, 176, 70)
	part(folder, "Mainland", Vector3.new(1730, 48, 490), Vector3.new(525, -25, -11), Color3.fromRGB(111, 91, 65))
	local hubFloor = part(folder, "Foundation", Vector3.new(290, 1, 330), Vector3.new(0, -0.6, 20), grass)
	protectArea(folder, hubFloor.Position, hubFloor.Size, Layout.HubPosition + Vector3.new(0, 4, 0), grass, true)
	for x = -7, 6 do
		for z = -5, 7 do
			local color = if (x + z) % 2 == 0 then Color3.fromRGB(113, 190, 78) else grass
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
		local gymBase = position + Vector3.new(0, 1.25, -18)
		part(lot, "GymDeck", Vector3.new(11.5, .26, 9.3), gymBase, Color3.fromRGB(52, 57, 66)).CanCollide = false
		for _,side in {-1,1} do
			local post=part(lot,"GymPost",Vector3.new(.65,6,.65),position+Vector3.new(side*3,4,-18),Color3.fromRGB(90,110,140))
			post.CanCollide=false
			part(lot, "GymShoe", Vector3.new(2, .6, 2), gymBase + Vector3.new(side * 3, .38, 0), Color3.fromRGB(34, 40, 53)).CanCollide = false
			local grip = part(lot, "Grip", Vector3.new(.95, .64, .64), position + Vector3.new(side * 1.45, 7, -18), Color3.fromRGB(32, 36, 44))
			grip.Shape, grip.CanCollide = Enum.PartType.Cylinder, false
		end
		local bar=part(lot,"GymBar",Vector3.new(7,.5,.5),position+Vector3.new(0,7,-18),Color3.fromRGB(255,200,70))
		bar.CanCollide=false
		WorldArt.RegisterGym(lot, index)
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
			protectArea(zone, center, Vector3.new(Layout.ZoneSize, 1, Layout.ZoneSize), center + Vector3.new(0, 4, 35), colors[2])
		end
		if id == "FlorestaNeon" then
			station(zone, "NeonResearch", center + Vector3.new(0, .8, 15), Color3.fromRGB(98, 232, 183),
				"PESQUISA NEON\n+20 FORÇA E +80 XP NA PRIMEIRA VISITA", function(player)
					if ctx and ctx.Biomes then ctx.Biomes.ClaimNeonResearch(player) end
				end)
		end
		local destination = id
		local purpose = if id == "FlorestaNeon" then " • Pesquisa" else ""
		station(folder, "Portal_" .. id, Vector3.new(-78 + (index - 1) * 31, 0.8, 116), colors[2], Config.Biomes[id].Name .. purpose .. "\n$" .. NumberFormatter.Format(Config.Biomes[id].Cost) .. " • " .. Config.Biomes[id].RequiredBestiary .. " espécies", function(player)
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
	protectArea(tradingFloor, tradingFloor.Position, tradingFloor.Size, Layout.TradingPosition + Vector3.new(0, 4, 13), tradingFloor.Color)
	station(folder, "TradingDesk", Layout.TradingPosition, Color3.fromRGB(255,212,63), "TROCAS E LEILÕES", function(player)
		local remote = ctx and ctx.Remotes:FindFirstChild("OpenPanel")
		if remote then remote:FireClient(player, "Trocas") end
	end)
	station(folder, "TradingReturn", Layout.TradingPosition + Vector3.new(0, 0.8, 30), Color3.fromRGB(74,193,255), "VOLTAR AO HUB", function(player) if ctx and ctx.Biomes then ctx.Biomes.Travel(player, "Hub") end end)
	if not ctx or not ctx.DisableLoops then startFallProtection() end
end

function WorldService.GetSanctuary(player: Player): Model? return if owners[player] then lots[owners[player]] else nil end
function WorldService.GetTrainingAnchor(player: Player): BasePart?
	local lot = WorldService.GetSanctuary(player)
	return if lot then WorldArt.GetTrainingAnchor(lot) else nil
end
function WorldService.GetReservePosition(): Vector3? return WorldArt.GetReservePosition() end
function WorldService.UpdateAcademyArt(player: Player, academyLevel: number)
	local lot = WorldService.GetSanctuary(player)
	if lot then WorldArt.UpdateGym(lot, academyLevel) end
end
function WorldService.GetSanctuaryReturnPosition(player: Player): Vector3?
	local lot = WorldService.GetSanctuary(player)
	local platform = lot and lot.PrimaryPart
	return if platform then platform.Position + Vector3.new(0, 4, 23) else nil
end
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
	if id == "PradariaSolar" then return {} end
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
	WorldArt.ReleaseGym(lot)
	owners[player] = nil
	displaySignatures[player] = nil
end

local machineColors = {
    Color3.fromRGB(255, 193, 85), Color3.fromRGB(255, 121, 82), Color3.fromRGB(89, 204, 235),
    Color3.fromRGB(161, 106, 255), Color3.fromRGB(240, 114, 224),
    Color3.fromRGB(255, 113, 63), Color3.fromRGB(144, 160, 255), Color3.fromRGB(255, 224, 113),
}

function WorldService.UpdateTrainingMachine(player: Player, tier: number, name: string)
    local lot = WorldService.GetSanctuary(player)
    if not lot then return end
    local bar = lot:FindFirstChild("GymBar")
    local anchor = lot:FindFirstChild("PersonalTraining")
    if not anchor or anchor:GetAttribute("MachineTier") == tier then return end
    anchor:SetAttribute("MachineTier", tier)
    if bar and bar:IsA("BasePart") then
        local color = machineColors[tier]
        bar.Color = color
        bar.Material = if tier >= 6 then Enum.Material.Neon else Enum.Material.SmoothPlastic
        local previous = lot:FindFirstChild("MachineUpgradeArt")
        if previous then previous:Destroy() end
        local details = Instance.new("Folder")
        details.Name, details.Parent = "MachineUpgradeArt", lot
        for _, side in {-1, 1} do
            local plateCount = math.ceil(tier / 2)
            for index = 1, plateCount do
                local diameter = 1.4 + tier * .12 - index * .16
                local plate = part(details, "TrainingPlate", Vector3.new(.23, diameter, diameter),
                    bar.Position + Vector3.new(side * (2.18 + (index - 1) * .28), 0, 0), if index == 1 then color else color:Lerp(Color3.new(), index * .14))
                plate.Shape, plate.CanCollide, plate.CanQuery, plate.CanTouch = Enum.PartType.Cylinder, false, false, false
                plate.TopSurface = Enum.SurfaceType.Smooth
            end
            if tier >= 4 then
                local upright = part(details, "MachineLight", Vector3.new(.14, 4.5, .18),
                    bar.Position + Vector3.new(side * 3, -3, .4), color)
                upright.Material, upright.CanCollide, upright.CanTouch, upright.CanQuery = Enum.Material.Neon, false, false, false
            end
        end
    end
    local billboard = anchor:FindFirstChild("Label")
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
	WorldService.UpdateAcademyArt(player, profile.TrainingLevel or 1)
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
		if ctx and ctx.AuthoredCreatures and not ctx.AuthoredCreatures[record.CreatureId] then continue end
		local column, row = (slot - 1) % 6, math.floor((slot - 1) / 6)
		local home = platform.Position + Vector3.new((column - 2.5) * 5.8, 1.65, (row - 1.5) * 6.8 + 5)
		local model = Instance.new("Model")
		model.Name = record.CreatureId
		model:SetAttribute("CaptureUID", uid)
		model:SetAttribute("Mutation", record.Mutation)
		model:SetAttribute("Size", record.Size)
		for _, variant in Config.Sizes do
			if variant.Name == record.Size then model:SetAttribute("ArtScale", variant.Scale); break end
		end
		model:SetAttribute("PenHome", home)
		model:SetAttribute("WalkPhase", (slot * 2.399963) % (2 * math.pi))
		local function anchor(name: string, offset: Vector3): Part
			local piece = part(model, name, Vector3.one, home + offset, definition.BodyColor)
			piece.Transparency = 1
			piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
			return piece
		end
		model.PrimaryPart = anchor("Body", Vector3.zero)
		local head = anchor("Head", Vector3.new(0, .6, -.9))
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
