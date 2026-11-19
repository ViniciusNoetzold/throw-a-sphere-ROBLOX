--!strict
-- Local copies share one original Blender mesh per species, including in ViewportFrames.
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sources = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CreatureMeshes")

type MeshData = {Vertices: {number}, Faces: {number}, Colors: {number}}
type Template = {Part: MeshPart, RetainedMesh: EditableMesh?}
local CreatureArt = {}
local templates: {[string]: Template} = {}
local attempted: {[string]: boolean} = {}
local loaded = Instance.new("BindableEvent")
CreatureArt.Loaded = loaded.Event

local function load(source: ModuleScript)
    if attempted[source.Name] then return end
    attempted[source.Name] = true
    local mesh: EditableMesh? = nil
    local ok, problem = pcall(function()
        local data: MeshData = HttpService:JSONDecode(require(source))
        local editable = AssetService:CreateEditableMesh()
        if not editable then error("Mesh memory unavailable") end
        mesh = editable
        local vertices: {number}, positions: {Vector3}, colors: {number} = {}, {}, {}
        for i = 1, #data.Vertices, 3 do
            local position = Vector3.new(data.Vertices[i], data.Vertices[i + 1], data.Vertices[i + 2])
            table.insert(positions, position)
            table.insert(vertices, editable:AddVertex(position))
        end
        for i = 1, #data.Colors, 3 do
            table.insert(colors, editable:AddColor(Color3.new(data.Colors[i], data.Colors[i + 1], data.Colors[i + 2]), 1))
        end
        local normals: {[Vector3]: number} = {}
        for i = 1, #data.Faces, 4 do
            local a, b, c, material = data.Faces[i], data.Faces[i + 1], data.Faces[i + 2], data.Faces[i + 3]
            local normal = (positions[b] - positions[a]):Cross(positions[c] - positions[a])
            if normal.Magnitude < 1e-8 then continue end
            local unit = normal.Unit
            local normalId = normals[unit]
            if not normalId then normalId = editable:AddNormal(unit); normals[unit] = normalId end
            local triangle = editable:AddTriangle(vertices[a], vertices[b], vertices[c])
            local colorId = colors[material]
            editable:SetFaceColors(triangle, {colorId, colorId, colorId})
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
        template.Name = "OriginalMesh"
        template.Color = Color3.new(1, 1, 1)
        template.Material = Enum.Material.SmoothPlastic
        template.Anchored = true
        template.CanCollide, template.CanQuery, template.CanTouch = false, false, false
        templates[source.Name] = {Part = template, RetainedMesh = mesh}
        loaded:Fire(source.Name)
    end)
    if not ok then
        if mesh then mesh:Destroy() end
        warn("[CreatureArt]", source.Name, problem)
    end
end

function CreatureArt.Get(id: string): MeshPart?
    local template = templates[id]
    return if template then template.Part:Clone() else nil
end

function CreatureArt.ShowOn(model: Model, id: string, scale: number, rootHeight: number): MeshPart?
    local root = model.PrimaryPart
    if not root or not model.Parent or model:FindFirstChild("OriginalMesh") then return nil end
    local mesh = CreatureArt.Get(id)
    if not mesh then return nil end
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

task.defer(function()
    for _, source in sources:GetChildren() do
        if source:IsA("ModuleScript") then load(source) end
        task.wait()
    end
end)

return CreatureArt
