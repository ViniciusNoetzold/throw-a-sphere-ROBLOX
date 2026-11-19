--!strict
-- Local copies share one original Blender mesh per species, including in ViewportFrames.
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local shared = ReplicatedStorage:WaitForChild("Shared")
local sources = shared:WaitForChild("CreatureMeshes")
local variants = require(shared.ConfigMutacoes)

type Geometry = {Vertices: {number}, Faces: {number}, Colors: {number}}
type MeshData = Geometry & {Palettes: {[string]: {number}}?, Shapes: {[string]: Geometry}?, Scales: {[string]: number}?, ReferenceScale: number?}
type Template = {Part: MeshPart, RetainedMesh: EditableMesh?, Texture: EditableImage, Users: number, IdleSince: number}
type LoadState = {Loading: boolean, Attempts: number, RetryAt: number, Retryable: boolean, Done: BindableEvent}
type WorldDisplay = {Model: Model, Id: string, Scale: number, RootHeight: number, MaxExtent: number?, Distance: number}
local CreatureArt = {}
local templates: {[string]: Template} = {}
local loads: {[string]: LoadState} = {}
local MAX_LOAD_ATTEMPTS, RETRY_COOLDOWN = 3, 5
local scales: {[string]: {[string]: number}} = {}
local referenceScales: {[string]: number} = {}
local displays: {[Model]: WorldDisplay} = {}
local MAX_WORLD_DISPLAYS = 16

-- The source pack has Blender materials rather than image files. Rasterize the
-- original palette into a padded UV atlas so every displayed mesh has a texture.
local function atlas(mesh: EditableMesh, texture: EditableImage, rgb: {number}, grid: number): {{number}}
    local cell, edge = 8, grid * 8
    local pixels = buffer.create(edge * edge * 4)
    local uvs = {}
    for slot = 0, #rgb / 3 - 1 do
        local x, y = (slot % grid) * cell, math.floor(slot / grid) * cell
        local r, g, b = rgb[slot * 3 + 1], rgb[slot * 3 + 2], rgb[slot * 3 + 3]
        for row = y, y + cell - 1 do
            for column = x, x + cell - 1 do
                local index = (row * edge + column) * 4
                buffer.writeu8(pixels, index, math.floor(r * 255 + .5))
                buffer.writeu8(pixels, index + 1, math.floor(g * 255 + .5))
                buffer.writeu8(pixels, index + 2, math.floor(b * 255 + .5))
                buffer.writeu8(pixels, index + 3, 255)
            end
        end
        table.insert(uvs, {
            mesh:AddUV(Vector2.new((x + 3) / edge, (y + 3) / edge)),
            mesh:AddUV(Vector2.new((x + 5) / edge, (y + 3) / edge)),
            mesh:AddUV(Vector2.new((x + 4) / edge, (y + 5) / edge)),
        })
    end
    texture:WritePixelsBuffer(Vector2.zero, Vector2.new(edge, edge), pixels)
    return uvs
end

local function load(source: ModuleScript, palette: string?)
    local key = if palette then source.Name .. ":" .. palette else source.Name
    if templates[key] then return end
    local state = loads[key]
    if state then
        -- CreateMeshPartAsync/baking may yield. All consumers await the same result,
        -- including a reveal that starts while a world instance is loading.
        if state.Loading then state.Done.Event:Wait(); return end
        if not state.Retryable or state.Attempts >= MAX_LOAD_ATTEMPTS or os.clock() < state.RetryAt then return end
    else
        state = {Loading = false, Attempts = 0, RetryAt = 0, Retryable = false, Done = Instance.new("BindableEvent")}
        loads[key] = state
    end
    state.Loading, state.Attempts = true, state.Attempts + 1
    local mesh: EditableMesh? = nil
    local image: EditableImage? = nil
    local createdPart: MeshPart? = nil
    local memoryUnavailable = false
    local ok, problem = pcall(function()
        local data: MeshData = HttpService:JSONDecode(require(source))
        scales[source.Name] = data.Scales or {}
        referenceScales[source.Name] = data.ReferenceScale
        local geometry = (if palette and data.Shapes then data.Shapes[palette] else nil) or data
        local paletteColors = if palette and data.Palettes then data.Palettes[palette] else nil
        if palette and geometry == data and not paletteColors then return end
        local editable = AssetService:CreateEditableMesh()
        if not editable then memoryUnavailable = true; error("Mesh memory unavailable") end
        mesh = editable
        local vertices: {number}, positions: {Vector3} = {}, {}
        for i = 1, #geometry.Vertices, 3 do
            local position = Vector3.new(geometry.Vertices[i], geometry.Vertices[i + 1], geometry.Vertices[i + 2])
            table.insert(positions, position)
            table.insert(vertices, editable:AddVertex(position))
        end
        local rgb = paletteColors or geometry.Colors
        local grid = math.ceil(math.sqrt(#rgb / 3))
        local texture = AssetService:CreateEditableImage({Size = Vector2.one * grid * 8})
        if not texture then memoryUnavailable = true; error("Texture memory unavailable") end
        image = texture
        local uvs = atlas(editable, texture, rgb, grid)
        local normals: {[Vector3]: number} = {}
        for i = 1, #geometry.Faces, 4 do
            local a, b, c, material = geometry.Faces[i], geometry.Faces[i + 1], geometry.Faces[i + 2], geometry.Faces[i + 3]
            local normal = (positions[b] - positions[a]):Cross(positions[c] - positions[a])
            if normal.Magnitude < 1e-8 then continue end
            local unit = normal.Unit
            local normalId = normals[unit]
            if not normalId then normalId = editable:AddNormal(unit); normals[unit] = normalId end
            local triangle = editable:AddTriangle(vertices[a], vertices[b], vertices[c])
            editable:SetFaceUVs(triangle, uvs[material])
            editable:SetFaceNormals(triangle, {normalId, normalId, normalId})
        end
        local content = Content.fromObject(editable)
        local baked, result, opaque = pcall(function()
            return AssetService:CreateDataModelContentAsync(content)
        end)
        local options = {CollisionFidelity = Enum.CollisionFidelity.Box}
        local part: MeshPart? = nil
        if baked and result == Enum.CreateContentResult.Success then
            local success, value = pcall(function() return AssetService:CreateMeshPartAsync(opaque, options) end)
            if success then part = value; editable:Destroy(); mesh = nil end
        end
        local template = part or AssetService:CreateMeshPartAsync(content, options)
        createdPart = template
        template.Name = "OriginalMesh"
        template.TextureContent = Content.fromObject(texture)
        template:SetAttribute("ArtPalette", palette)
        template.Color = Color3.new(1, 1, 1)
        template.Material = Enum.Material.SmoothPlastic
        template.Anchored = true
        template.CanCollide, template.CanQuery, template.CanTouch = false, false, false
        templates[key] = {Part = template, RetainedMesh = mesh, Texture = texture, Users = 0, IdleSince = os.clock()}
    end)
    if not ok then
        if createdPart then createdPart:Destroy() end
        if mesh then mesh:Destroy() end
        if image then image:Destroy() end
        warn("[CreatureArt]", source.Name, problem)
    end
    local message = string.lower(tostring(problem))
    state.Loading = false
    state.Retryable = not ok and (memoryUnavailable or string.find(message, "memory", 1, true) ~= nil or string.find(message, "budget", 1, true) ~= nil)
    state.RetryAt = os.clock() + RETRY_COOLDOWN
    state.Done:Fire()
end

function CreatureArt.Size(id: string, name: any, fallback: number, mutation: any?): number
    local authored = scales[id]
    local reference = referenceScales[id]
    if name == "Enorme" or mutation == "Dourada" or mutation == "ArcoIris" then
        return reference or (authored and authored.Enorme) or math.max(1.85, fallback)
    end
    if name == "Titanica" and reference then return math.max(reference * 1.2, fallback) end
    return if authored and type(name) == "string" then authored[name] or fallback else fallback
end

function CreatureArt.Get(id: string, mutation: string?): MeshPart?
    local source = sources:FindFirstChild(id)
    if not source or not source:IsA("ModuleScript") then return nil end
    local variantPart: Template? = nil
    if mutation == "Dourada" or mutation == "ArcoIris" then
        load(source, mutation)
        variantPart = templates[id .. ":" .. mutation]
    end
    if not variantPart and not templates[id] then load(source) end
    local template = variantPart or templates[id]
    if not template then return nil end
    local mesh = template.Part:Clone()
    template.Users += 1
    mesh.Destroying:Connect(function()
        template.Users -= 1
        if template.Users == 0 then template.IdleSince = os.clock() end
    end)
    if not variantPart and mutation and mutation ~= "Normal" then
        for _, style in variants.Mutations do
            if style.Name == mutation then mesh.Color = Color3.new(1, 1, 1):Lerp(style.Color, .55); break end
        end
    end
    return mesh
end

local function releaseIdle()
    local now = os.clock()
    for key, template in templates do
        if template.Users == 0 and now - template.IdleSince >= 1 then
            templates[key] = nil
            template.Part:Destroy()
            template.Texture:Destroy()
            if template.RetainedMesh then template.RetainedMesh:Destroy() end
            local state = loads[key]
            if state then state.Attempts, state.Retryable, state.RetryAt = 0, true, 0 end
        end
    end
end

function CreatureArt.ShowOn(model: Model, id: string, scale: number, rootHeight: number, maxExtent: number?): MeshPart?
    local root = model.PrimaryPart
    if not root or not model.Parent then return nil end
    local mutation = model:GetAttribute("Mutation")
    local mesh = CreatureArt.Get(id, if typeof(mutation) == "string" then mutation else nil)
    if not mesh then return nil end
    local existing = model:FindFirstChild("OriginalMesh")
    if not model.Parent or (existing and existing:GetAttribute("ArtPalette") == mesh:GetAttribute("ArtPalette")) then
        mesh:Destroy()
        return nil
    end
    if existing then existing:Destroy() end
    scale = CreatureArt.Size(id, model:GetAttribute("Size"), scale, mutation)
    if maxExtent then scale = math.min(scale, maxExtent / math.max(mesh.Size.X, mesh.Size.Y, mesh.Size.Z)) end
    mesh.Size *= scale
    mesh.CFrame = root.CFrame * CFrame.new(0, mesh.Size.Y / 2 - rootHeight, 0)
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then part.LocalTransparencyModifier = 1 end
        if part:IsA("BillboardGui") then
            part.Adornee = mesh
            part.StudsOffset = Vector3.new(0, mesh.Size.Y / 2 + .7, 0)
        end
    end
    mesh.Parent = model
    return mesh
end

function CreatureArt.TrackOn(model: Model, id: string, scale: number, rootHeight: number, maxExtent: number?, distance: number)
    displays[model] = {Model = model, Id = id, Scale = scale, RootHeight = rootHeight, MaxExtent = maxExtent, Distance = distance}
end

local function hideOn(model: Model)
    local mesh = model:FindFirstChild("OriginalMesh")
    if not mesh then return end
    for _, item in model:GetDescendants() do
        if item:IsA("BillboardGui") and item.Adornee == mesh then
            item.Adornee = model:FindFirstChild("Head") or model.PrimaryPart
        end
    end
    mesh:Destroy()
end

function CreatureArt.UntrackOn(model: Model)
    displays[model] = nil
    hideOn(model)
end

-- The pack is available in every biome, but EditableMesh memory belongs to this
-- client. Load the closest actors first and free meshes when their last clone leaves.
task.spawn(function()
    while script.Parent do
        task.wait(.35)
        releaseIdle()
        local camera = Workspace.CurrentCamera
        if not camera then continue end
        local eye = camera.CFrame.Position
        local nearby = {}
        for model, display in displays do
            local pivot = model.PrimaryPart
            if not model.Parent then
                displays[model] = nil
            elseif pivot then
                local distance = (pivot.Position - eye).Magnitude
                local alreadyVisible = model:FindFirstChild("OriginalMesh") ~= nil
                if distance <= display.Distance + (if alreadyVisible then 15 else 0) then
                    table.insert(nearby, {Display = display, Distance = distance})
                else
                    hideOn(model)
                end
            end
        end
        table.sort(nearby, function(a, b) return a.Distance < b.Distance end)
        for index = MAX_WORLD_DISPLAYS + 1, #nearby do hideOn(nearby[index].Display.Model) end
        local loadsThisUpdate = 0
        for index = 1, math.min(MAX_WORLD_DISPLAYS, #nearby) do
            local display = nearby[index].Display
            local model = display.Model
            if model.Parent and displays[model] == display and not model:FindFirstChild("OriginalMesh") then
                local mesh = CreatureArt.ShowOn(model, display.Id, display.Scale, display.RootHeight, display.MaxExtent)
                if mesh then
                    if displays[model] ~= display then hideOn(model) end
                    loadsThisUpdate += 1
                    if loadsThisUpdate >= 2 then break end
                end
            end
        end
    end
end)

return CreatureArt
