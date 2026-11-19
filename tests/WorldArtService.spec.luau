--!strict
-- Lifecycle/ownership assertions against the production native-art service.
local vector = {}
local Vector3 = {}
function Vector3.new(x, y, z) return setmetatable({X = x or 0, Y = y or 0, Z = z or 0}, vector) end
vector.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vector.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vector.__mul = function(a, b) return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
Vector3.one, Vector3.zero, Vector3.zAxis = Vector3.new(1, 1, 1), Vector3.new(), Vector3.new(0, 0, 1)
local CFrame = {new = function(v) return {Position = v} end, lookAt = function(v) return {Position = v} end}
local Color3 = {new = function() return {} end, fromRGB = function() return {} end}
local nodes = {}
local cloneCount = 0
local function node(class, name)
    local n = {ClassName = class, Name = name or class, Children = {}, Attributes = {}}
    function n:IsA(kind) return self.ClassName == kind or (kind == "BasePart" and self.ClassName == "Part") end
    function n:SetAttribute(k, v) self.Attributes[k] = v end
    function n:GetAttribute(k) return self.Attributes[k] end
    function n:FindFirstChild(k, recursive)
        for _, child in self.Children do
            if not child.Destroyed and child.Name == k then return child end
            if recursive then local found = child:FindFirstChild(k, true); if found then return found end end
        end
        return nil
    end
    n.WaitForChild = n.FindFirstChild
    function n:GetDescendants()
        local result = {}
        local function visit(parent)
            for _, child in parent.Children do if not child.Destroyed then table.insert(result, child); visit(child) end end
        end
        visit(self)
        return result
    end
    function n:Destroy() self.Destroyed = true; self.Parent = nil end
    function n:GetBoundingBox() return CFrame.new(Vector3.zero), Vector3.new(33.16, 16, 116.16) end
    function n:GetScale() return 1 end
    function n:ScaleTo(scale) self.Scale = scale end
    function n:PivotTo(cf)
        self.Pivot = cf
        for _, item in self:GetDescendants() do
            if item:IsA("Attachment") then item.WorldCFrame = CFrame.new(cf.Position + Vector3.new(0, .105, 0)) end
        end
    end
    function n:Clone()
        cloneCount += 1
        local copy = node(self.ClassName, self.Name)
        local p = node("Part", "PivoArremesso")
        p.Parent = copy; table.insert(copy.Children, p)
        if not self.BadMarker then
            local m = node("Attachment", "LinhaArremesso")
            m.WorldCFrame = CFrame.new(Vector3.zero)
            m.Parent = p; table.insert(p.Children, m)
        else
            p.Name = "MissingPivot"
        end
        return copy
    end
    table.insert(nodes, n)
    return n
end
local Instance = {new = node}
local storage = node("Folder", "ServerStorage")
local templates = node("Folder", "ImportedGyms")
table.insert(storage.Children, templates)
local artLevels = {1}
for level = 10, 200, 10 do table.insert(artLevels, level) end
for _, level in artLevels do table.insert(templates.Children, node("Model", string.format("GaragemNivel%02d", level))) end
local shared = node("Folder", "Shared")
shared.ConfigTraining, shared.ConfigWorld, shared.Config = "training", "world", "config"
local rs = node("Folder", "ReplicatedStorage")
table.insert(rs.Children, shared)
local rules = {MaxLevel = 100}
local configs = {training = rules, world = {BiomeOrder = {}}, config = {Creatures = {}}}
local game = {GetService = function(_, name)
    return if name == "ServerStorage" then storage elseif name == "ReplicatedStorage" then rs else {AddTag = function() end}
end}
local require = function(key) return configs[key] end
local function loadService()
--[[WORLD_ART]]
end
local service = loadService()
local floor = node("Part", "Platform")
floor.Position = Vector3.zero
local first, second = node("Model", "Lot1"), node("Model", "Lot2")
first.PrimaryPart, second.PrimaryPart = floor, floor
local world = node("Folder", "World")
local interactions = {}
local busy, loaded, flying, training = false, true, false, false
local ownerLot, teleported = first, nil
local body = node("Part", "HumanoidRootPart")
local player = {Character = {FindFirstChild = function() return body end, FindFirstChildOfClass = function() return {Health = 100} end,
    PivotTo = function(_, destination) teleported = destination.Position end}}
local context = {Data = {IsLoaded = function() return loaded end, IsBusy = function() return busy end},
    Training = {IsTraining = function() return training end}, Flight = {IsActive = function() return flying end},
    World = {GetSanctuary = function() return ownerLot end, GetSanctuaryReturnPosition = function() return Vector3.new(5, 4, 23) end,
        GetHubPosition = function() return Vector3.new(0, 4, 35) end}, Remotes = {OpenPanel = {FireClient = function() end}}}
local builders = {
    Part = function(parent, name, size, position)
        local p = node("Part", name)
        p.Size, p.Position, p.CFrame, p.Parent = size, position, CFrame.new(position), parent
        table.insert(parent.Children, p)
        return p
    end,
    ProtectArea = function() end,
    Station = function(parent, name, _, _, _, callback) interactions[parent.Name .. "/" .. name] = callback end,
}
service.Init(world, context, builders)
service.RegisterGym(first, 1)
service.RegisterGym(second, 2)
local checks = 0
local function test(name, run) run(); checks += 1; print("PASS " .. name) end
test("every authored gym stage is reachable within unchanged academy levels", function()
    local seen = {}
    for level = 1, rules.MaxLevel do seen[service.GetGymArtLevel(level)] = true end
    for _, level in artLevels do assert(seen[level], tostring(level)) end
    assert(service.GetGymArtLevel(-50) == 1 and service.GetGymArtLevel(1000) == 200)
end)
test("empty annexes never clone all source models", function()
    assert(cloneCount == 0 and not service.GetTrainingAnchor(first) and not service.GetTrainingAnchor(second))
end)
test("one native model and stable training marker per occupied lot", function()
    assert(service.UpdateGym(first, 1))
    assert(cloneCount == 1 and service.GetTrainingAnchor(first))
    local anchor = service.GetTrainingAnchor(first)
    assert(service.UpdateGym(first, 5) and cloneCount == 1)
    assert(service.UpdateGym(first, 100) and cloneCount == 2)
    assert(service.GetTrainingAnchor(first) == anchor)
    local live = 0
    for _, n in nodes do if n.Name == "NativeGym" and n.Parent and not n.Destroyed then live += 1 end end
    assert(live == 1)
end)
test("missing or invalid source retains the current usable gym", function()
    local template = templates:FindFirstChild("GaragemNivel10")
    template.Name = "Hidden"
    local anchor, before = service.GetTrainingAnchor(first), cloneCount
    assert(not service.UpdateGym(first, 6) and service.GetTrainingAnchor(first) == anchor and cloneCount == before)
    template.Name, template.BadMarker = "GaragemNivel10", true
    assert(not service.UpdateGym(first, 6) and service.GetTrainingAnchor(first) == anchor)
    template.BadMarker = nil
end)
test("different lots use independent native clones", function()
    assert(service.UpdateGym(second, 50))
    assert(service.GetTrainingAnchor(first) ~= service.GetTrainingAnchor(second))
    for _, source in templates.Children do assert(not source.Destroyed and not source.Parent) end
end)
test("annex access belongs to the server assigned lot", function()
    ownerLot, teleported = second, nil
    interactions["Lot1/VisitAcademy"](player)
    assert(not teleported)
    ownerLot = first
    interactions["Lot1/VisitAcademy"](player)
    assert(teleported and teleported.X == -255 and teleported.Z == 423)
end)
test("busy unloaded flying or training players cannot teleport", function()
    for _, flag in {"busy", "loaded", "flying", "training"} do
        busy, loaded, flying, training = flag == "busy", flag ~= "loaded", flag == "flying", flag == "training"
        teleported = nil
        interactions["Lot1/VisitAcademy"](player)
        assert(not teleported, flag)
    end
    busy, loaded, flying, training = false, true, false, false
end)
test("every annex has an exit to the caller's own sanctuary", function()
    teleported = nil
    interactions["AcademyAnnex_1/ReturnToSanctuary"](player)
    assert(teleported and teleported.X == 5 and teleported.Z == 23)
end)
test("release destroys the active clone without touching other lots or templates", function()
    local secondAnchor = service.GetTrainingAnchor(second)
    service.ReleaseGym(first)
    assert(not service.GetTrainingAnchor(first) and service.GetTrainingAnchor(second) == secondAnchor)
    assert(service.UpdateGym(first, 1))
    for _, source in templates.Children do assert(not source.Destroyed) end
end)
print("WorldArtService: " .. checks .. " stage, lifecycle, ownership and travel scenarios passed")
