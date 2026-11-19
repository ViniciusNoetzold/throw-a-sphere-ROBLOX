--!strict
-- Native source models stay in ServerStorage. Only occupied gym annexes are cloned.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local TrainingRules = require(Shared.ConfigTraining)
local Layout = require(Shared.ConfigWorld)
local Config = require(Shared.Config)

local WorldArt = {}
type Gym = {Folder: Folder, Pivot: CFrame, Anchor: BasePart, Art: Model?, ArtLevel: number?}
local gyms: {[Model]: Gym} = {}
local ctx: any
local helpers: any
local root: Folder?
local reserveEntry: Vector3?
local reserveCenter = Vector3.new(-430, 0, 35)

-- The authored pack has 21 stages named 01..200; the existing academy caps at
-- 100. This visual-only mapping exposes every stage without changing XP/saves.
function WorldArt.GetGymArtLevel(academyLevel: number): number
    local progress = math.clamp((academyLevel - 1) / math.max(1, TrainingRules.MaxLevel - 1), 0, 1)
    local stage = math.floor(progress * 20 + 1e-7)
    return if stage == 0 then 1 else stage * 10
end

local function prepare(model: Model)
    for _, item in model:GetDescendants() do
        if item:IsA("BasePart") then
            item.Anchored, item.CanTouch = true, false
        end
    end
end

local function fit(model: Model, maxSize: Vector3)
    local _, size = model:GetBoundingBox()
    local scale = math.min(1, maxSize.X / math.max(size.X, .1), maxSize.Z / math.max(size.Z, .1))
    if scale < 1 then model:ScaleTo(model:GetScale() * scale) end
end

local function marker(model: Model, name: string): CFrame?
    local found = model:FindFirstChild(name, true)
    if found and found:IsA("Attachment") then return found.WorldCFrame end
    if found and found:IsA("BasePart") then return found.CFrame end
    return nil
end

local function canTravel(player: Player): boolean
    return ctx ~= nil and ctx.Data ~= nil and ctx.Data.IsLoaded(player) and not ctx.Data.IsBusy(player)
        and not (ctx.Training and ctx.Training.IsTraining(player))
        and not (ctx.Flight and ctx.Flight.IsActive(player))
end

local function travel(player: Player, destination: Vector3)
    if not canTravel(player) then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local body = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not humanoid or humanoid.Health <= 0 or not body or not body:IsA("BasePart") then return end
    character:PivotTo(CFrame.lookAt(destination, destination - Vector3.zAxis * 10))
    body.AssemblyLinearVelocity, body.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
end

function WorldArt.GetTrainingAnchor(lot: Model): BasePart?
    local gym = gyms[lot]
    return if gym and gym.Art then gym.Anchor else nil
end

function WorldArt.GetReservePosition(): Vector3? return reserveEntry end

function WorldArt.UpdateGym(lot: Model, academyLevel: number): boolean
    local gym = gyms[lot]
    if not gym then return false end
    local level = WorldArt.GetGymArtLevel(academyLevel)
    if gym.ArtLevel == level and gym.Art and gym.Art.Parent then return true end
    local templates = ServerStorage:FindFirstChild("ImportedGyms")
    local template = templates and templates:FindFirstChild(string.format("GaragemNivel%02d", level))
    if not template or not template:IsA("Model") then return false end
    local art = template:Clone()
    art.Name = "NativeGym"
    prepare(art)
    fit(art, Vector3.new(128, 40, 128))
    art:PivotTo(gym.Pivot)
    local line = marker(art, "LinhaArremesso") or marker(art, "PivoArremesso")
    if not line then art:Destroy(); return false end
    -- The interaction/training anchor is independent of the art instance. A
    -- level-up can replace geometry while an active repetition retains its anchor.
    gym.Anchor.CFrame = line
    art:SetAttribute("SourceArtLevel", level)
    if gym.Art then gym.Art:Destroy() end
    gym.Art, gym.ArtLevel = art, level
    art.Parent = gym.Folder
    gym.Folder:SetAttribute("AcademyLevel", academyLevel)
    gym.Folder:SetAttribute("SourceArtLevel", level)
    return true
end

function WorldArt.ReleaseGym(lot: Model)
    local gym = gyms[lot]
    if not gym then return end
    if gym.Art then gym.Art:Destroy() end
    gym.Art, gym.ArtLevel = nil, nil
    gym.Folder:SetAttribute("AcademyLevel", nil)
    gym.Folder:SetAttribute("SourceArtLevel", nil)
end

function WorldArt.RegisterGym(lot: Model, index: number)
    if not root or not helpers or gyms[lot] or not ServerStorage:FindFirstChild("ImportedGyms") then return end
    local center = Vector3.new(-255 + ((index - 1) % 4) * 170, 0, 365 + math.floor((index - 1) / 4) * 180)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = "AcademyAnnex_" .. index, root
    folder:SetAttribute("SanctuaryIndex", index)
    helpers.Part(folder, "Foundation", Vector3.new(140, 3, 140), center + Vector3.new(0, -1.6, 0), Color3.fromRGB(82, 99, 91))
    local pivot = CFrame.new(center + Vector3.new(6, .1, 47))
    local entry = center + Vector3.new(0, 4, 58)
    helpers.ProtectArea(folder, center, Vector3.new(140, 1, 140), entry, Color3.fromRGB(103, 159, 111))
    local anchor = helpers.Part(folder, "TrainingAnchor", Vector3.new(.2, .2, .2), pivot.Position, Color3.new())
    anchor.Transparency, anchor.CanCollide, anchor.CanTouch, anchor.CanQuery = 1, false, false, false
    gyms[lot] = {Folder = folder, Pivot = pivot, Anchor = anchor}
    helpers.Station(folder, "ReturnToSanctuary", center + Vector3.new(0, .8, 61), Color3.fromRGB(92, 214, 163), "VOLTAR AO SANTUÁRIO", function(player: Player)
        travel(player, ctx.World.GetSanctuaryReturnPosition(player) or ctx.World.GetHubPosition())
    end)
    helpers.Station(folder, "AcademyPanel", center + Vector3.new(14, .8, 61), Color3.fromRGB(255, 183, 73), "TREINAR NA ACADEMIA", function(player: Player)
        if ctx.World.GetSanctuary(player) == lot then ctx.Remotes.OpenPanel:FireClient(player, "Academia") end
    end)
    local platform = lot.PrimaryPart
    if platform then
        helpers.Station(lot, "VisitAcademy", platform.Position + Vector3.new(-13, .45, -18), Color3.fromRGB(255, 183, 73), "VISITAR ACADEMIA", function(player: Player)
            if ctx.World.GetSanctuary(player) ~= lot then return end
            travel(player, entry)
        end)
    end
end

local function reserveSamples(reserve: Model)
    local available: {string} = {}
    local sources = Shared:FindFirstChild("CreatureMeshes")
    if not sources then return end
    for id in Config.Creatures do
        if sources:FindFirstChild(id) and (not ctx.AuthoredCreatures or ctx.AuthoredCreatures[id]) then table.insert(available, id) end
    end
    table.sort(available)
    -- Prefer one authored species per biome, then fill to eight; these are
    -- display actors, never SpawnService creatures or sanctuary income records.
    local selected: {string}, used: {[string]: boolean} = {}, {}
    for _, biome in Layout.BiomeOrder do
        for _, id in available do
            if Config.Creatures[id].Biome == biome and not used[id] then
                table.insert(selected, id); used[id] = true; break
            end
        end
    end
    for _, id in available do
        if #selected >= 8 then break end
        if not used[id] then table.insert(selected, id); used[id] = true end
    end
    local display = Instance.new("Folder")
    display.Name, display.Parent = "ReserveCreatures", reserve
    for index, id in selected do
        local at = marker(reserve, string.format("PosicaoPokemon%02d", index))
        if not at then continue end
        local home = at.Position + Vector3.new(0, 1.5, 0)
        local actor = Instance.new("Model")
        actor.Name = id
        actor:SetAttribute("ReserveDisplay", true)
        actor:SetAttribute("PenHome", home)
        actor:SetAttribute("WalkPhase", index * 2.399963)
        actor:SetAttribute("ArtScale", .8)
        local body = helpers.Part(actor, "Body", Vector3.one, home, Color3.new())
        local head = helpers.Part(actor, "Head", Vector3.one, home + Vector3.new(0, .6, -.9), Color3.new())
        for _, item in {body, head} do
            item.Transparency, item.CanCollide, item.CanTouch, item.CanQuery = 1, false, false, false
        end
        actor.PrimaryPart = body
        helpers.Label(head, Config.Creatures[id].Name, Vector3.new(0, 1.5, 0))
        actor.Parent = display
        CollectionService:AddTag(actor, "SanctuaryWalker")
    end
end

function WorldArt.Init(world: Folder, context: any, builders: any)
    if root then return end
    root, ctx, helpers = world, context or {}, builders
    local source = ServerStorage:FindFirstChild("ImportedReserve")
    if not source or not source:IsA("Model") then return end
    local reserve = source:Clone()
    reserve.Name = "NaturalReserve"
    prepare(reserve)
    fit(reserve, Vector3.new(128, 40, 128))
    reserve:PivotTo(CFrame.new(reserveCenter + Vector3.new(0, .1, 49)))
    helpers.Part(world, "ReserveFoundation", Vector3.new(144, 4, 128), reserveCenter + Vector3.new(0, -5.1, 0), Color3.fromRGB(110, 91, 64))
    local entry = marker(reserve, "EntradaSantuario")
    reserveEntry = (if entry then entry.Position else reserveCenter + Vector3.new(0, .1, 44)) + Vector3.new(0, 4, 0)
    helpers.ProtectArea(reserve, reserveCenter, Vector3.new(144, 1, 128), reserveEntry, Color3.fromRGB(119, 173, 91))
    reserve.Parent = world
    reserveSamples(reserve)
    helpers.Station(world, "VisitReserve", Vector3.new(-42, .8, 173), Color3.fromRGB(104, 208, 123), "RESERVA NATURAL\nVISITAR CRIATURAS", function(player: Player)
        if reserveEntry then travel(player, reserveEntry) end
    end)
    helpers.Station(reserve, "ReturnToHub", reserveCenter + Vector3.new(0, .8, 52), Color3.fromRGB(104, 208, 123), "VOLTAR AO HUB", function(player: Player)
        travel(player, ctx.World.GetHubPosition())
    end)
end

return WorldArt
